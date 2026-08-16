-- =====================================================================
-- BUNKERS REGISTER — PART 7: ops schema (adjudication + telemetry)
-- Never granted to anon. RLS on, zero policies.
-- =====================================================================

create table ops.agent_run (
  agent_run_id   uuid primary key default gen_random_uuid(),
  agent          text not null,     -- ARCHIVIST, CARTOGRAPHER, VERIFIER, REFUTER...
  tier           int not null check (tier between 1 and 3),
  model_id       text not null,
  model_family   text not null,     -- §9: a SECOND FAMILY is architectural
  lineage_id     uuid references lineage(lineage_id),   -- §5.1.2 collapse
  workflow       text not null,     -- W1, W2, W4
  started_at     timestamptz not null default now(),
  finished_at    timestamptz,
  candidates_examined int not null default 0,
  candidates_returned int not null default 0,
  -- §12: NULL RETURNS FROM TIER 1. "I looked and there is nothing here"
  -- is a first-class output, counted and rewarded.
  null_returns   int not null default 0,
  region_scope   text,
  notes          text
);

create table ops.null_return (
  null_return_id uuid primary key default gen_random_uuid(),
  agent_run_id   uuid not null references ops.agent_run(agent_run_id) on delete cascade,
  examined_label text not null,
  examined_geom  geometry(Point,4326),
  rejection_reason text not null,
  matched_null_hypothesis text references null_hypothesis(code),
  created_at     timestamptz not null default now()
);
create index on ops.null_return using gist (examined_geom);

-- §12.4 THE CANARY PROGRAMME. Fabricated facility names with zero corpus
-- presence, injected every cycle. Any citation returned is a directly
-- measured hallucination against known ground truth.
create table ops.canary (
  canary_id      uuid primary key default gen_random_uuid(),
  fabricated_name text not null unique,
  injected_at    timestamptz not null default now(),
  retired_at     timestamptz,
  entity_id      uuid references entity(entity_id),   -- the shadow candidate
  expected_grade grade_band not null default 'F'
);

create table ops.canary_hit (
  canary_hit_id  uuid primary key default gen_random_uuid(),
  canary_id      uuid not null references ops.canary(canary_id) on delete cascade,
  agent_run_id   uuid references ops.agent_run(agent_run_id),
  returned_identifier text,
  identifier_class identifier_class,
  resolved       boolean not null default false,
  observed_at    timestamptz not null default now()
);

-- §12.2 rolling 10% blind double-scoring by a DIFFERENT model family.
create table ops.double_scoring (
  double_scoring_id uuid primary key default gen_random_uuid(),
  proposition_id  uuid not null references proposition(proposition_id) on delete cascade,
  scorer_a_model  text not null, scorer_a_family text not null, grade_a grade_band not null,
  scorer_b_model  text not null, scorer_b_family text not null, grade_b grade_band not null,
  condition_agreement jsonb not null default '{}'::jsonb,  -- per-CONDITION, not per-grade
  agreed         boolean generated always as (grade_a = grade_b) stored,
  scored_at      timestamptz not null default now(),
  constraint different_families check (scorer_a_family <> scorer_b_family)
);

-- §12.5 table re-derivation: what a version change actually moved, isolated.
create table ops.table_rederivation (
  rederivation_id uuid primary key default gen_random_uuid(),
  table_name     text not null,
  from_version   text not null,
  to_version     text not null,
  proposition_id uuid references proposition(proposition_id),
  grade_old_table grade_band,
  grade_new_table grade_band,
  delta_attributable_to_table boolean not null default true,
  performed_at   timestamptz not null default now()
);

-- CURATOR's reviewed-write queue (§6). An agent may PROPOSE a row;
-- assignment is a reviewed write.
create table ops.curation_proposal (
  proposal_id    uuid primary key default gen_random_uuid(),
  target_table   text not null check (target_table in
                   ('tier','diagnosticity','erp','candidate_set','null_hypothesis','typology')),
  payload        jsonb not null,
  proposed_by    text not null,
  proposed_at    timestamptz not null default now(),
  state          text not null default 'pending'
                 check (state in ('pending','accepted','rejected','superseded')),
  reviewer       text,
  reviewed_at    timestamptz,
  review_note    text
);
create index on ops.curation_proposal (state, target_table);

-- Raw ingest landing zone. Fetched text enters the pipeline as structurally
-- bounded DATA, never as free prose in a scoring prompt (§2.7, demand #10).
create table ops.ingest_payload (
  payload_id     uuid primary key default gen_random_uuid(),
  retrieval_id   uuid references retrieval(retrieval_id) on delete cascade,
  extracted_fields jsonb not null,
  extractor      text not null,
  extractor_is_llm boolean not null default false,
  prompt_injection_scan_passed boolean,
  created_at     timestamptz not null default now()
);

-- Adversarial calibration + the frozen 32-entry regression set (§12.7).
create table ops.calibration_case (
  case_id        text primary key,
  lens           text not null check (lens in ('historian','intelligence_analyst','bes','red_team')),
  label          text not null,
  entity_slug    text,
  class          proposition_class,
  expected_grade grade_band,
  expected_note  text,
  is_load_bearing_pair boolean not null default false,
  pair_with      text references ops.calibration_case(case_id)
);

create table ops.calibration_run (
  run_id         uuid primary key default gen_random_uuid(),
  case_id        text not null references ops.calibration_case(case_id),
  observed_grade grade_band,
  passed         boolean,
  rubric_version text not null,
  ran_at         timestamptz not null default now()
);

alter table ops.agent_run          enable row level security;
alter table ops.null_return        enable row level security;
alter table ops.canary             enable row level security;
alter table ops.canary_hit         enable row level security;
alter table ops.double_scoring     enable row level security;
alter table ops.table_rederivation enable row level security;
alter table ops.curation_proposal  enable row level security;
alter table ops.ingest_payload     enable row level security;
alter table ops.calibration_case   enable row level security;
alter table ops.calibration_run    enable row level security;
-- No policies: deny-all for anon/authenticated. service_role has BYPASSRLS.

-- =====================================================================
-- PUBLISHED TELEMETRY (§12.4). The register states its own measured
-- fabrication rate. These are the ONLY ops facts that reach anon, and
-- they are aggregates with no candidate identity in them.
-- =====================================================================

create view public.telemetry_confabulation
with (security_invoker = false) as
select
  ar.agent,
  ar.model_family,
  count(*) filter (where e.receipt_state = 'UNRESOLVED') as format_valid_unresolvable,
  count(*) as citations_emitted,
  round(100.0 * count(*) filter (where e.receipt_state='UNRESOLVED')
        / nullif(count(*),0), 2) as unresolvable_pct
from ops.agent_run ar
join evidence e on e.scorer_model_id = ar.model_id
group by ar.agent, ar.model_family;

create view public.telemetry_canary as
select date_trunc('month', ch.observed_at) as month,
       count(distinct ch.canary_id) as canaries_cited,
       count(*) as fabricated_citations,
       count(*) filter (where ch.resolved) as fabricated_citations_that_resolved
from ops.canary_hit ch group by 1 order by 1 desc;

create view public.telemetry_band_occupancy as
select class, grade, count(*) as n,
       round(100.0*count(*)/sum(count(*)) over (partition by class),2) as pct
from proposition_rollup where is_published group by class, grade order by class, grade desc;

comment on view public.telemetry_band_occupancy is
  '§12.6 band-occupancy discipline: the modal entry must be X or D. '
  'If C exceeds ~15% of graded propositions the diagnosticity catalog is leaking.';

create view public.telemetry_refutation as
select count(*) filter (where refutation_state <> 'R0') as r_total,
       count(*) filter (where refutation_state = 'R2')  as r2_total,
       (select count(*) from grade_event
         where grade_from = 'R' and grade_to <> 'R')     as r_reversals
from proposition_rollup where is_published;

create view public.telemetry_egress as
select s.name as source, sh.hostname, sh.is_issuing_authority, sh.egress, sh.last_probe_at
from source_host sh join source s using (source_id) order by s.name;

comment on view public.telemetry_egress is
  '§2.6. The register discloses its own reach rather than silently producing '
  'low grades that look like findings.';

grant select on public.telemetry_confabulation, public.telemetry_canary,
  public.telemetry_band_occupancy, public.telemetry_refutation, public.telemetry_egress
to anon, authenticated;
