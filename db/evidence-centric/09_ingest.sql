-- =====================================================================
-- SECTION 09 — INGEST, ADJUDICATION STATE, AND TELEMETRY
--
-- Everything in this schema is INTERNAL. No RLS policy for anon exists on
-- any table here, so the default is deny and unpublished adjudication state
-- cannot leak (hard requirement 9). Continuous unbounded ingest lives here:
-- candidates are provisional forever, nothing is deleted, and the queue is
-- never expected to drain.
-- =====================================================================

create table ingest.agent_run (
  run_id        bigint generated always as identity primary key,
  workflow      text not null check (workflow in ('W0','W1','W2','W3','W4')),
  agent         text not null,     -- ARCHIVIST, CARTOGRAPHER, VERIFIER, SILENCE, ...
  scorer_model_id text references registry.scorer_model(scorer_model_id),
  model_family  text,
  started_at    timestamptz not null default now(),
  finished_at   timestamptz,
  scope_note    text,
  candidates_examined integer not null default 0,
  candidates_returned integer not null default 0,
  -- BES fleet demand #12: every discovery agent must report sites examined
  -- and REJECTED, with reasons. Null returns are the base-rate denominator
  -- and the only genuine confirmation-bias control in a find-rewarded fleet.
  candidates_rejected integer not null default 0,
  identifiers_emitted integer not null default 0,
  identifiers_resolved integer not null default 0,
  status        text not null default 'running' check (status in ('running','ok','failed','aborted'))
);
create index agent_run_agent_idx on ingest.agent_run(agent, started_at desc);

-- The null return itself, as a first-class row.
create table ingest.null_return (
  null_return_id bigint generated always as identity primary key,
  run_id        bigint not null references ingest.agent_run(run_id),
  examined_label text not null,
  examined_geom geometry(Point,4326),
  admin_area_id bigint references registry.admin_area(admin_area_id),
  rejection_reason text not null,
  rejected_null_code char(3) references registry.null_hypothesis(null_code),
  examined_at   timestamptz not null default now()
);
create index null_return_geom_gix on ingest.null_return using gist (examined_geom);

-- Untrusted identifiers extracted from fetched text NEVER go to a citation
-- table. They go here and must be independently resolved at the issuing
-- authority before any observation may cite them (BES §2.7).
create table ingest.lead (
  lead_id       bigint generated always as identity primary key,
  run_id        bigint references ingest.agent_run(run_id),
  source_host   text,
  source_url    text,
  raw_text      text not null,
  extracted_identifier text,
  identifier_class text references registry.identifier_grammar(identifier_class),
  adversary_writable_origin boolean not null default false,
  injection_suspected boolean not null default false,
  state         text not null default 'new'
                  check (state in ('new','resolving','resolved','dead','rejected')),
  promoted_document_id uuid references core.source_document(document_id),
  created_at    timestamptz not null default now()
);
create index lead_state_idx on ingest.lead(state);
comment on table ingest.lead is
  'Fetched text enters the pipeline as structurally bounded DATA, never as free prose in a scoring prompt. A prompt-injected identifier in a Wikimapia description lands here and dies here unless it resolves at the issuer.';

-- Reviewed-write queue for the four curated tables. An agent may PROPOSE.
create table ingest.curation_proposal (
  proposal_id   bigint generated always as identity primary key,
  target_table  text not null check (target_table in
                  ('tier','diagnosticity','erp','candidate_set','null_hypothesis','identifier_grammar')),
  proposed_row  jsonb not null,
  rationale     text not null,
  -- Every E/A matrix assignment is logged as a catalog-extension proposal,
  -- so the fallback is self-retiring (BES §4.4).
  originating_observation_id uuid references core.observation(observation_id),
  proposed_by   text not null,
  proposed_at   timestamptz not null default now(),
  state         text not null default 'pending'
                  check (state in ('pending','accepted','rejected','superseded')),
  reviewed_by   text,
  reviewed_at   timestamptz,
  review_note   text
);
create index curation_proposal_state on ingest.curation_proposal(state, target_table);

-- BES §12.2: rolling 10% blind double-scoring by a DIFFERENT model family;
-- per-condition agreement published. Reference-class assignment and the
-- lineage counterfactual are measured first, being the two softest inputs.
create table ingest.double_scoring (
  double_scoring_id bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id),
  primary_grade_event_id uuid not null references core.grade_event(grade_event_id),
  blind_grade_event_id   uuid not null references core.grade_event(grade_event_id),
  primary_family text not null,
  blind_family   text not null,
  grades_agree   boolean not null,
  condition_agreement jsonb not null,   -- per-condition, not per-grade
  sampled_at     timestamptz not null default now(),
  check (primary_family <> blind_family)
);

-- BES §12.4 — the canary programme. Rotating fabricated facility names with
-- zero corpus presence. Any citation returned for a canary is a directly
-- measured hallucination against known ground truth.
create table ingest.canary (
  canary_id     bigint generated always as identity primary key,
  entity_id     uuid not null references core.entity(entity_id),
  fabricated_name text not null,
  injected_at   timestamptz not null default now(),
  retired_at    timestamptz,
  cycle_label   text not null
);

create table ingest.confabulation_event (
  event_id      bigint generated always as identity primary key,
  run_id        bigint references ingest.agent_run(run_id),
  agent         text not null,
  model_family  text,
  canary_id     bigint references ingest.canary(canary_id),
  kind          text not null check (kind in
                  ('canary-citation','format-valid-unresolvable','issuer-metadata-mismatch',
                   'subject-binding-failure','fabricated-quote-offset')),
  identifier    text,
  identifier_class text,
  detail        jsonb,
  detected_at   timestamptz not null default now()
);
create index confabulation_agent_idx on ingest.confabulation_event(agent, detected_at desc);

-- Adjudication work queue. Continuous, unbounded, never expected to drain.
create table ingest.adjudication_task (
  task_id       bigint generated always as identity primary key,
  proposition_id uuid references core.proposition(proposition_id),
  entity_id     uuid references core.entity(entity_id),
  stage         text not null check (stage in
                  ('PROPOSE','VERIFY','SILENCE','LINEAGE','REFUTE','ASSESS','CURATE','REVIEW')),
  priority      integer not null default 100,
  state         text not null default 'queued'
                  check (state in ('queued','running','blocked','done','abandoned')),
  blocked_on    text,
  created_at    timestamptz not null default now(),
  claimed_by    text,
  claimed_at    timestamptz,
  completed_at  timestamptz
);
create index adjudication_queue_idx on ingest.adjudication_task(state, priority, created_at)
  where state in ('queued','blocked');

-- Published telemetry. BES: "a register that states its own measured
-- fabrication rate is more credible than one that implies none."
create or replace view ingest.telemetry_agent as
  select r.agent,
         r.model_family,
         count(*)                                            as runs,
         sum(r.candidates_returned)                          as returned,
         sum(r.candidates_rejected)                          as rejected,
         sum(r.identifiers_emitted)                          as identifiers_emitted,
         sum(r.identifiers_resolved)                         as identifiers_resolved,
         case when sum(r.identifiers_emitted) > 0
              then round(1 - sum(r.identifiers_resolved)::numeric
                             / sum(r.identifiers_emitted), 4) end
                                                             as unresolvable_rate,
         (select count(*) from ingest.confabulation_event ce
           where ce.agent = r.agent and ce.kind = 'canary-citation') as canary_citations
    from ingest.agent_run r
   group by r.agent, r.model_family;

create or replace view ingest.telemetry_bands as
  select cg.grade,
         count(*) as n,
         round(100.0 * count(*) / nullif(sum(count(*)) over (),0), 2) as pct,
         -- BES §12.6: the ladder is calibrated so the modal entry is X or D.
         -- If C-band occupancy exceeds ~15%, the diagnosticity catalog is
         -- leaking and is re-audited.
         case when cg.grade = 'C'
                   and 100.0*count(*)/nullif(sum(count(*)) over (),0) > 15
              then 'C-BAND AUDIT TRIGGERED' end as alert
    from core.proposition_current_grade cg
   group by cg.grade;

create or replace view ingest.telemetry_refutation as
  select count(*) filter (where cg.grade = 'R')                       as r_count,
         count(*) filter (where rf.reversed_at is not null)           as r_reversals,
         count(*) filter (where rf.state = 'R2' and rf.reversed_at is null) as r2_standing,
         count(*) filter (where rf.state = 'R2' and rf.next_review_due < current_date) as r2_overdue_review
    from core.proposition_current_grade cg
    full join core.refutation rf on rf.proposition_id = cg.proposition_id;
