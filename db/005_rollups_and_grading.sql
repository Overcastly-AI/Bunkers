-- =====================================================================
-- BUNKERS REGISTER — PART 5: materialised rollups, grade events,
--                            and the BES v0.2 grading algorithm (§9.4)
-- Requirement 4: versioned grades as events; any past grade reconstructible.
-- =====================================================================

-- =====================================================================
-- 12. PROPOSITION ROLLUP — the materialised read model.
--     One row per proposition. Every public read hits this table and
--     nothing else. Recomputed from raw evidence by bes_recompute();
--     the rollup is a CACHE, never the source of truth.
-- =====================================================================

create table proposition_rollup (
  proposition_id  uuid primary key references proposition(proposition_id) on delete cascade,
  entity_id       uuid not null references entity(entity_id) on delete cascade,
  class           proposition_class not null,

  -- published grade = post-cap, post-clamp (§1.4, §9.3)
  grade           grade_band not null default 'X',
  grade_pre_clamp grade_band not null default 'X',
  awarded_band    grade_band not null default 'X',
  ceiling         grade_band not null default 'A',
  at_ceiling      boolean not null default false,
  ceiling_reason  text,
  limiting_condition text,
  marginal_flag   boolean not null default false,

  refutation_state refutation_state not null default 'R0',
  null_state      null_state not null default 'UNTESTED',
  silence_reading silence_reading not null default 'UNSEARCHED',
  base_rate_reading base_rate_reading,
  reference_class reference_class,

  -- §7.2 search completeness, published on every row
  sci             numeric(4,3) not null default 0,
  sci_numerator   int not null default 0,
  sci_denominator int not null default 0,
  sci_below_floor boolean not null default true,

  -- the counts the bands are literally made of (§9.2)
  v_total         int not null default 0,
  v_claim         int not null default 0,
  v_d4            int not null default 0,
  v_d3            int not null default 0,
  v_d2            int not null default 0,
  v_d1            int not null default 0,
  v_d0            int not null default 0,
  l_d2            int not null default 0,
  l_d3            int not null default 0,
  u_d3_unrebutted int not null default 0,
  v0_unresolved   int not null default 0,   -- displayed as inert
  quarantined     int not null default 0,

  -- §10.2 TWO BARS, ALWAYS
  place_derived_count int not null default 0,
  claim_derived_count int not null default 0,

  caps_applied    text[] not null default '{}',
  citogenesis     boolean not null default false,
  mirror_only_a1  boolean not null default false,

  scorer_model_id text,
  rubric_version  text,
  tier_table_version text,
  diagnosticity_table_version text,
  erp_table_version text,

  computed_at     timestamptz not null default now(),
  is_published    boolean not null default false,
  inputs          jsonb not null default '{}'::jsonb   -- full recompute witness
);
create index proposition_rollup_entity_ix on proposition_rollup (entity_id);
create index proposition_rollup_grade_ix  on proposition_rollup (grade);
create index proposition_rollup_pub_ix    on proposition_rollup (is_published) where is_published;
create index proposition_rollup_class_ix  on proposition_rollup (class, grade);

comment on table proposition_rollup is
  'Materialised read model. Recomputable in full from evidence at any time via '
  'bes_recompute_proposition(). If this table were dropped it could be rebuilt '
  'exactly; the grade is never STORED knowledge, only cached knowledge.';

-- =====================================================================
-- 13. GRADE EVENTS — append-only, immutable. Requirement 4.
-- =====================================================================

create table grade_event (
  grade_event_id  uuid primary key default gen_random_uuid(),
  proposition_id  uuid not null references proposition(proposition_id) on delete cascade,
  seq             bigint generated always as identity,
  -- clock_timestamp(), NOT now(): now() is transaction-constant, so two
  -- regrades inside one ingest transaction would be indistinguishable by time
  -- and the history would be unreconstructible at sub-transaction resolution.
  occurred_at     timestamptz not null default clock_timestamp(),

  grade_from      grade_band,
  grade_to        grade_band not null,
  cause           transition_cause not null,
  -- §11.2: instrument drift is suppressed from the public confidence chart.
  is_instrument_drift boolean generated always as
    (cause in ('SCORER_CHANGE','TABLE_VERSION_CHANGE','RESCORE_NOISE')) stored,

  -- what moved it (req. 4: "show what evidence moved it and when")
  triggering_evidence_ids uuid[] not null default '{}',
  triggering_search_receipt_ids uuid[] not null default '{}',
  narrative       text,

  -- full snapshot of every input, so a past grade is reconstructible even
  -- after the curated tables are re-derived (§12.5)
  snapshot        jsonb not null,
  scorer_model_id text,
  rubric_version  text not null,
  tier_table_version text,
  diagnosticity_table_version text,
  erp_table_version text,

  is_published    boolean not null default false
);
create index grade_event_prop_time_ix on grade_event (proposition_id, occurred_at desc);
create index grade_event_seq_ix       on grade_event (seq);
create index grade_event_cause_ix     on grade_event (cause);
create index grade_event_pub_ix       on grade_event (is_published) where is_published;

-- Append-only enforcement: history that can be edited is not history.
-- The single permitted mutation is the publication flag, and the trigger
-- proves it is the only field that moved by diffing the whole row.
create or replace function bes_grade_event_immutable() returns trigger
language plpgsql as $$
begin
  -- NOTE: generated columns are computed AFTER before-row triggers, so
  -- new.is_instrument_drift is still NULL here while old's is populated.
  -- It is excluded from the diff for that reason, not as a loophole: it is
  -- a pure function of `cause`, which the diff does cover.
  if TG_OP = 'UPDATE'
     and (to_jsonb(new) - 'is_published' - 'is_instrument_drift')
       = (to_jsonb(old) - 'is_published' - 'is_instrument_drift') then
    return new;
  end if;
  raise exception 'grade_event is append-only (attempted % on %)', TG_OP, old.grade_event_id;
end $$;

create trigger grade_event_no_update before update or delete on grade_event
  for each row execute function bes_grade_event_immutable();

-- The register's own publication log. Feeds §5.1.8 self-exclusion and the
-- §11.3 ratchet: a grade may RISE only on evidence whose document date
-- precedes the register's publication of the candidate.
create table register_publication_log (
  publication_id uuid primary key default gen_random_uuid(),
  entity_id      uuid references entity(entity_id) on delete cascade,
  proposition_id uuid references proposition(proposition_id) on delete cascade,
  published_at   timestamptz not null default now(),
  action         text not null check (action in ('PUBLISH','WITHDRAW','REPUBLISH')),
  actor          text not null,
  check (entity_id is not null or proposition_id is not null)
);
create index on register_publication_log (entity_id, published_at);

-- =====================================================================
-- 14. ENTITY ROLLUP — the map read model (req. 10)
-- =====================================================================

create table entity_rollup (
  entity_id       uuid primary key references entity(entity_id) on delete cascade,
  exist_grade     grade_band not null default 'X',
  locate_grade    grade_band not null default 'X',
  best_grade      grade_band not null default 'X',
  worst_grade     grade_band not null default 'X',
  proposition_count int not null default 0,
  refuted_count   int not null default 0,
  unassessed_count int not null default 0,

  -- §10.3 PUBLICATION GATES, derived. The client cannot draw a pin the
  -- evidence does not support because the RPC will not emit one.
  render_mode     render_mode not null default 'list_only',
  render_geom     geometry(Geometry,4326),        -- point OR polygon, per render_mode
  anchor_geom     geometry(Point,4326),           -- clustering only
  location_precision location_precision not null default 'non_located',
  uncertainty_radius_m numeric,

  typology_code   text,
  country         iso_country,
  badges          jsonb not null default '[]'::jsonb,   -- [{class,grade,statement,...}]
  headline        text,
  computed_at     timestamptz not null default now(),
  is_published    boolean not null default false
);
create index entity_rollup_anchor_gix on entity_rollup using gist (anchor_geom)
  where is_published;
create index entity_rollup_render_gix on entity_rollup using gist (render_geom)
  where is_published;
create index entity_rollup_grade_ix   on entity_rollup (exist_grade) where is_published;
create index entity_rollup_country_ix on entity_rollup (country, exist_grade);
create index entity_rollup_typology_ix on entity_rollup (typology_code);

-- Dirty queue. Ingest writes evidence; the queue defers recompute so a bulk
-- sweep does not pay N grade computations per proposition.
create table ops_regrade_queue (
  proposition_id uuid primary key references proposition(proposition_id) on delete cascade,
  enqueued_at    timestamptz not null default now(),
  reason         transition_cause not null default 'NEW_VERIFICATION',
  attempts       int not null default 0,
  last_error     text
);

-- =====================================================================
-- 15. THE GRADING ALGORITHM (§9.4)
-- =====================================================================

create type bes_grade_result as (
  awarded_band     grade_band,
  grade_pre_clamp  grade_band,
  grade            grade_band,
  ceiling          grade_band,
  ceiling_reason   text,
  at_ceiling       boolean,
  limiting_condition text,
  marginal_flag    boolean,
  refutation_state refutation_state,
  null_state       null_state,
  silence_reading  silence_reading,
  base_rate_reading base_rate_reading,
  sci              numeric,
  caps_applied     text[],
  inputs           jsonb
);

-- ---------------------------------------------------------------------
-- V(P) and U(P) as a view (§2.4). Seven exclusions, each a one-line
-- predicate, doing enormous work. Fact-key merge (§5.5) applied here:
-- rows sharing fact_key collapse to one, keeping the strongest.
-- ---------------------------------------------------------------------
create or replace view v_evidence_merged as
select distinct on (e.proposition_id, e.sign, e.fact_key) e.*
from evidence e
where e.receipt_state = 'VERIFIED'
  and e.scope = 'INSTANCE'
  and e.causal_provenance in ('UNSOLICITED','SOLICITED_3P')
  and e.corpus_era <> 'POST_2022_UNATTRIBUTED'
  and e.channel <> 'ADVERSARY_WRITABLE'
  and e.self_attesting = false
  and e.register_echo_quarantined = false
  and e.superseded_by_evidence_id is null
order by e.proposition_id, e.sign, e.fact_key,
         e.diagnosticity desc,
         array_position(array['T1','T2','T3','T4','T5','PENDING']::text[], e.origin_tier::text),
         e.created_at;

comment on view v_evidence_merged is
  'V(P) = this view filtered to sign=SUPPORTS; U(P) = sign=UNDERCUTS. '
  '§5.5 fact-key merge is the DISTINCT ON: one underlying fact entering through '
  'four record types is one lineage, not four (IC failure #7).';

-- ---------------------------------------------------------------------
-- bes_recompute_proposition — the whole algorithm, deterministic given
-- the evidence table. Pure read + single rollup UPSERT.
-- ---------------------------------------------------------------------
create or replace function bes_recompute_proposition(p_id uuid)
returns bes_grade_result
language plpgsql
as $$
declare
  p               proposition%rowtype;
  r               bes_grade_result;
  -- counts
  v_total int := 0; v_claim int := 0;
  v_d4 int := 0; v_d3 int := 0; v_d2 int := 0; v_d1 int := 0; v_d0 int := 0;
  l_d2 int := 0; l_d3 int := 0;
  l_d3_claim int := 0; l_d2_place_excl int := 0;
  u_d3 int := 0; u_r2_lineages int := 0;
  v0 int := 0; quarantined int := 0;
  place_n int := 0; claim_n int := 0;
  has_d4_claim boolean := false;
  has_t1t2_lineage boolean := false;
  a1_ok boolean := false; a1alt_ok boolean := false;
  a6_ok boolean := false; mirror_a1 boolean := false;
  ns              null_state := 'UNTESTED';
  rs              refutation_state := 'R0';
  awarded         grade_band := 'F';
  capped          grade_band;
  clamped         grade_band;
  parent_grade    grade_band;
  caps            text[] := '{}';
  limiting        text;
  marginal        boolean := false;
  sci_num int := 0; sci_den int := 0; sci numeric := 0;
  sil             silence_reading := 'UNSEARCHED';
  br              base_rate_reading;
  ceil            grade_band := 'A';
  ceil_reason     text;
  citogen         boolean := false;
  cs_m int; cs_n int;
  origin_lineages int := 0;
  all_claim_erp_x0 boolean := false;
  ev_ids uuid[];
begin
  select * into p from proposition where proposition_id = p_id;
  if not found then raise exception 'no such proposition %', p_id; end if;

  ---------------------------------------------------------------------
  -- Step 3 (§9.4): build V, U; fact-key merged; compute the counts.
  ---------------------------------------------------------------------
  select
    count(*) filter (where sign='SUPPORTS'),
    count(*) filter (where sign='SUPPORTS' and property_locus='CLAIM_PROPERTY'),
    count(*) filter (where sign='SUPPORTS' and diagnosticity>=4),
    count(*) filter (where sign='SUPPORTS' and diagnosticity>=3),
    count(*) filter (where sign='SUPPORTS' and diagnosticity>=2),
    count(*) filter (where sign='SUPPORTS' and diagnosticity>=1),
    count(*) filter (where sign='SUPPORTS' and diagnosticity=0),
    count(*) filter (where sign='SUPPORTS' and property_locus='PLACE_PROPERTY'),
    count(*) filter (where sign='SUPPORTS' and property_locus='CLAIM_PROPERTY'),
    count(distinct lineage_id) filter (where sign='SUPPORTS' and diagnosticity>=2),
    count(distinct lineage_id) filter (where sign='SUPPORTS' and diagnosticity>=3),
    count(distinct lineage_id) filter (where sign='SUPPORTS' and diagnosticity>=3
                                        and property_locus='CLAIM_PROPERTY'),
    count(distinct lineage_id) filter (where sign='SUPPORTS' and diagnosticity>=2
                                        and property_locus='PLACE_PROPERTY'
                                        and null_excluding),
    count(*) filter (where sign='UNDERCUTS' and diagnosticity>=3 and not rebutted),
    count(distinct lineage_id) filter (where sign='UNDERCUTS' and diagnosticity>=2
                                        and coalesce(improbable_under_h,false)
                                        and derived_from_search_receipt_id is null),
    bool_or(sign='SUPPORTS' and diagnosticity>=4 and property_locus='CLAIM_PROPERTY'
            and gate_pass),
    bool_or(sign='SUPPORTS' and origin_tier in ('T1','T2'))
  into v_total, v_claim, v_d4, v_d3, v_d2, v_d1, v_d0,
       place_n, claim_n, l_d2, l_d3, l_d3_claim, l_d2_place_excl,
       u_d3, u_r2_lineages, has_d4_claim, has_t1t2_lineage
  from v_evidence_merged where proposition_id = p_id;

  select count(*) filter (where receipt_state='UNRESOLVED'),
         count(*) filter (where register_echo_quarantined
                             or corpus_era='POST_2022_UNATTRIBUTED')
    into v0, quarantined
  from evidence where proposition_id = p_id;

  ---------------------------------------------------------------------
  -- Step 4: DERIVE null_state (§4.6). Not an agent assertion.
  ---------------------------------------------------------------------
  if p.null_hypothesis_code is null then
    ns := 'UNTESTED';
  elsif exists (select 1 from v_evidence_merged
                where proposition_id=p_id and sign='SUPPORTS'
                  and diagnosticity>=3 and null_excluding) then
    ns := 'EXCLUDED';
  elsif exists (select 1 from v_evidence_merged
                where proposition_id=p_id and sign='SUPPORTS'
                  and diagnosticity>=2 and null_excluding) then
    ns := 'INSUFFICIENT';
  elsif exists (select 1 from evidence
                where proposition_id=p_id and documents_null
                  and receipt_state='VERIFIED' and origin_tier in ('T1','T2')) then
    ns := 'DOMINANT';
  else
    ns := 'SURVIVING';
  end if;

  ---------------------------------------------------------------------
  -- SCI (§7.2) and the silence reading (§6.4)
  ---------------------------------------------------------------------
  select count(*) filter (where applicable and resolved_x >= 1),
         count(*) filter (where applicable and resolved_x >= 1 and searched)
    into sci_den, sci_num
  from proposition_erp where proposition_id = p_id;
  sci := case when sci_den = 0 then 1.0 else round(sci_num::numeric / sci_den, 3) end;

  select bool_and(resolved_x = 0) into all_claim_erp_x0
  from proposition_erp pe
  join erp_profile ep using (erp_profile_id)
  where pe.proposition_id = p_id and pe.applicable
    and coalesce(ep.applies_to_property_locus,'CLAIM_PROPERTY') = 'CLAIM_PROPERTY';

  if exists (select 1 from proposition_erp pe join erp_profile ep using (erp_profile_id)
             where pe.proposition_id=p_id and pe.applicable and ep.x0_reason='RECORD_DESTROYED') then
    sil := 'RECORD_DESTROYED';
  elsif sci_den = 0 or coalesce(all_claim_erp_x0,false) then
    sil := 'UNINFORMATIVE';
  elsif sci_num = 0 then
    sil := 'UNSEARCHED';
  else
    sil := 'INFORMATIVE';
  end if;

  ---------------------------------------------------------------------
  -- Step 1: REFUTATION, checked FIRST, overriding all bands (§8).
  -- §8.4 gate: expected-record negatives can NEVER alone license R —
  -- every branch below requires derived_from_search_receipt_id IS NULL.
  ---------------------------------------------------------------------
  select count(distinct lineage_id) into origin_lineages
  from v_evidence_merged where proposition_id=p_id and sign='SUPPORTS';

  if exists (select 1 from evidence
             where proposition_id=p_id
               and refutation_class='R3_CONTRADICTED'
               and receipt_state='VERIFIED' and scope='INSTANCE'
               and subject_binding_pass
               and causal_provenance in ('UNSOLICITED','SOLICITED_3P')
               and gate_e_authority_over_fact
               and derived_from_search_receipt_id is null
               and not rebutted) then
    rs := 'R3';
  elsif u_r2_lineages >= 2 and ns = 'DOMINANT'
        and exists (select 1 from evidence where proposition_id=p_id
                    and refutation_class='R2_AFFIRMATIVELY_INCONSISTENT'
                    and derived_from_search_receipt_id is null and not rebutted) then
    rs := 'R2';
  elsif origin_lineages <= 1
        and exists (select 1 from evidence
                    where proposition_id=p_id
                      and refutation_class='R1_ORIGIN_FABRICATED'
                      and receipt_state='VERIFIED'
                      and derived_from_search_receipt_id is null
                      and not rebutted) then
    rs := 'R1';
  else
    rs := 'R0';
  end if;

  ---------------------------------------------------------------------
  -- Step 5: bands, top-down; first band whose conditions ALL hold wins.
  ---------------------------------------------------------------------
  if rs <> 'R0' then
    awarded := 'R';
    limiting := 'refuted: ' || rs::text;
  else
    -- A1 / A1-alt
    a1_ok := has_d4_claim or (l_d3_claim >= 2);
    if p.class in ('EXIST','EXTENT','LOCATE','FEATURE') then
      select count(distinct e.lineage_id) >= 2
        into a1alt_ok
      from v_evidence_merged e
      left join attestation a on a.attestation_id = e.attestation_id
      where e.proposition_id=p_id and e.sign='SUPPORTS'
        and e.direct_observation and e.lawful_physical_access
        and e.georef_control_point_match
        and coalesce(a.witness_resolvable,false) and coalesce(a.custody_pass,false);
      a1alt_ok := coalesce(a1alt_ok,false)
        and exists (select 1 from v_evidence_merged
                    where proposition_id=p_id and sign='SUPPORTS'
                      and origin_tier='T1' and property_locus='PLACE_PROPERTY');
    end if;

    -- A6 forgery pricing: A1 row resolved at the issuing authority itself,
    -- or mirror-only WITH an independent D2+ corroborating lineage.
    select bool_or(not mirror_only), bool_or(mirror_only)
      into a6_ok, mirror_a1
    from v_evidence_merged
    where proposition_id=p_id and sign='SUPPORTS'
      and ((diagnosticity>=4 and gate_pass) or diagnosticity>=3)
      and property_locus='CLAIM_PROPERTY';
    a6_ok := coalesce(a6_ok,false) or (coalesce(mirror_a1,false) and l_d2 >= 2);

    if (a1_ok or a1alt_ok) and ns='EXCLUDED' and u_d3=0 and a6_ok then
      awarded := 'A';
    elsif (l_d3 >= 2 or (l_d2 >= 3 and has_t1t2_lineage))
          and ns in ('EXCLUDED','INSUFFICIENT') and u_d3=0 and v_claim >= 1 then
      awarded := 'B';
      limiting := case
        when not (a1_ok or a1alt_ok) then 'A1 (no dispositive record; no two D3 claim-property lineages)'
        when ns <> 'EXCLUDED' then 'A3 (null_state not EXCLUDED)'
        when u_d3 > 0 then 'A4 (unrebutted D3+ undercut)'
        else 'A6 (mirror-only A1 without independent corroboration)' end;
    else
      -- C1c candidate-set rule
      select cs.documented_instance_count,
             (select count(*) from candidate_set_member m
               where m.candidate_set_id=cs.candidate_set_id and m.removed_at is null)
        into cs_n, cs_m
      from candidate_set cs where cs.candidate_set_id = p.candidate_set_id;

      if ((v_claim >= 1 and exists (select 1 from v_evidence_merged
              where proposition_id=p_id and sign='SUPPORTS'
                and property_locus='CLAIM_PROPERTY' and diagnosticity>=2))
          or l_d2_place_excl >= 2
          or (p.candidate_set_id is not null and cs_m is not null
              and cs_m <= 3*cs_n
              and exists (select 1 from candidate_set cs2
                          join proposition_rollup pr on pr.proposition_id = cs2.program_proposition_id
                          where cs2.candidate_set_id = p.candidate_set_id
                            and pr.grade in ('A','B'))
              and exists (select 1 from v_evidence_merged
                          where proposition_id=p_id and sign='SUPPORTS'
                            and property_locus='CLAIM_PROPERTY' and diagnosticity>=1)))
         and ns <> 'UNTESTED' and u_d3 = 0 then
        awarded := 'C';
        limiting := case when l_d3 < 2 and l_d2 < 3 then 'B1 (independent lineage count)'
                         when ns not in ('EXCLUDED','INSUFFICIENT') then 'B2 (null_state)'
                         when v_claim = 0 then 'B4 (no claim-property row in V)'
                         else 'B3 (unrebutted D3+ undercut)' end;
      elsif (v_d1 >= 1 or v_d0 >= 2) and ns in ('SURVIVING','DOMINANT','UNTESTED') then
        awarded := 'D';
        limiting := 'C1 (no D2+ claim-property row; no two null-excluding place lineages)';
      elsif v_total > 0 and v_d2 = 0 then
        awarded := 'E';
        limiting := 'D1/D2cond (nothing discriminating, or null_state precludes D)';
      else
        -- §9.2 F: "V = ∅, OR all higher bands and E fail".
        -- SPEC GAP, implemented literally and flagged: a single D3+
        -- PLACE-property row with null_state EXCLUDED satisfies no band and
        -- lands at F. Recorded in `inputs.spec_gap` rather than silently
        -- smoothed; CAP-2a would cap it at D anyway, and caps only lower.
        awarded := 'F';
        limiting := case when v_total = 0 then 'E1 (V is empty)'
                         else 'E2 (V[D2+] non-empty but no band satisfied)' end;
      end if;
    end if;
  end if;

  ---------------------------------------------------------------------
  -- Step 2 (deferred, per §9.4 note): SCI floor. Step 1's R short-circuits,
  -- so an R is never withheld; the shortfall is published as a flag instead.
  ---------------------------------------------------------------------
  if sci < 0.5 and awarded in ('D','E','F') then
    awarded := 'X';
    limiting := format('INSUFFICIENT SEARCH (SCI %s)', sci);
  end if;

  ---------------------------------------------------------------------
  -- Step 6: CAPS (§9.3). LEAST() on the ordered enum.
  ---------------------------------------------------------------------
  capped := awarded;
  if awarded not in ('X','R') then
    if l_d2 <= 1 and not (a1_ok or a1alt_ok) then
      capped := least(capped,'C'); caps := caps || 'CAP-1'::text; end if;
    if v_claim = 0 and p.class in ('EXIST','EXTENT','LOCATE','FEATURE','TYPOLOGY') then
      capped := least(capped,'D'); caps := caps || 'CAP-2a'::text; end if;
    if v_claim = 0 and p.class in ('HARDEN','CONTROL','FUNCTION','PROGRAM','IDENTITY','ORIGIN') then
      capped := least(capped,'E'); caps := caps || 'CAP-2b'::text; end if;

    select exists (select 1 from evidence e
                   where e.proposition_id=p_id and e.origin_tier in ('T1','T2','T3')
                     and exists (select 1 from citation c
                                 join document d5 on d5.document_id=c.cited_document_id
                                 where c.citing_document_id=e.document_id
                                   and d5.origin_tier='T5'))
      into citogen;
    if citogen then capped := least(capped,'E'); caps := caps || 'CAP-3'::text; end if;

    if v_total > 0 and not exists (
         select 1 from v_evidence_merged vm join document d on d.document_id=vm.document_id
         where vm.proposition_id=p_id and vm.sign='SUPPORTS'
           and d.document_date < date '2022-11-30') then
      capped := least(capped,'D'); caps := caps || 'CAP-4'::text; end if;
    if v_total = 0 then capped := least(capped,'F'); caps := caps || 'CAP-5'::text; end if;
    if coalesce(mirror_a1,false) and not a6_ok then
      capped := least(capped,'B'); caps := caps || 'CAP-6'::text; end if;
    if p.null_hypothesis_code is null then
      capped := least(capped,'D'); caps := caps || 'CAP-7'::text; end if;
  end if;

  ---------------------------------------------------------------------
  -- Step 7: MONOTONE CLAMP (§1.4). PROGRAM and ORIGIN are exempt — that
  -- exemption is what makes DUCC (PROGRAM A, EXIST R) representable.
  ---------------------------------------------------------------------
  clamped := capped;
  if not p.clamp_exempt then
    select pr.grade into parent_grade
    from proposition_rollup pr
    where pr.proposition_id = coalesce(
            p.parent_proposition_id,
            (select proposition_id from proposition
              where entity_id = p.entity_id and class='EXIST'
              order by created_at limit 1));
    if parent_grade is not null and parent_grade < capped
       and p.class <> 'EXIST' then
      clamped := parent_grade;
      caps := caps || 'CLAMP'::text;
    end if;
  end if;

  ---------------------------------------------------------------------
  -- Steps 9-11: marginal flag, ceiling, base-rate reading
  ---------------------------------------------------------------------
  marginal := (l_d2 = 2 and awarded = 'B')
           or (l_d3 = 2 and awarded in ('A','B'))
           or exists (select 1 from lineage_decision ld
                      join evidence e on e.evidence_id = ld.evidence_id
                      where e.proposition_id=p_id and (ld.disagreed or ld.defaulted_to_same_lineage));

  if citogen then
    ceil := 'E'; ceil_reason := 'citogenesis confirmed (CAP-3)';
  elsif coalesce(all_claim_erp_x0,false) and v_claim = 0 then
    ceil := case when p.class in ('EXIST','EXTENT','LOCATE','FEATURE','TYPOLOGY')
                 then 'D'::grade_band else 'E'::grade_band end;
    ceil_reason := 'no claim-property record class is expected to exist for this '
                || 'facility type, period and authority (all applicable ERP profiles X0)';
  else
    ceil := 'A'; ceil_reason := null;
  end if;

  select btr.reading into br
  from base_rate_table btr
  where btr.version = coalesce(p.base_rate_table_version,'BR-0.2.0')
    and btr.reference_class = coalesce(p.reference_class, e_ref(p.entity_id))
    and btr.class = p.class
    and btr.function_set = coalesce(p.predicate_args->>'function_set','na')
  limit 1;

  select array_agg(evidence_id) into ev_ids
  from evidence where proposition_id = p_id
    and created_at > coalesce((select max(occurred_at) from grade_event
                               where proposition_id=p_id), '-infinity'::timestamptz);

  r := (awarded, capped, clamped, ceil, ceil_reason, clamped = ceil,
        limiting, marginal, rs, ns, sil, br, sci, caps,
        jsonb_build_object(
          'v_total',v_total,'v_claim',v_claim,'v_d4',v_d4,'v_d3',v_d3,'v_d2',v_d2,
          'v_d1',v_d1,'v_d0',v_d0,'l_d2',l_d2,'l_d3',l_d3,'l_d3_claim',l_d3_claim,
          'u_d3_unrebutted',u_d3,'r2_lineages',u_r2_lineages,'v0_unresolved',v0,
          'quarantined',quarantined,'place_derived',place_n,'claim_derived',claim_n,
          'a1',a1_ok,'a1alt',a1alt_ok,'a6',a6_ok,'mirror_a1',coalesce(mirror_a1,false),
          'sci_num',sci_num,'sci_den',sci_den,'citogenesis',citogen,
          'candidate_set_M',cs_m,'candidate_set_N',cs_n,
          'origin_lineages',origin_lineages,
          'spec_gap', (awarded='F' and v_d2 > 0),
          'triggering_evidence', to_jsonb(coalesce(ev_ids,'{}'::uuid[]))
        ))::bes_grade_result;

  ---------------------------------------------------------------------
  -- UPSERT the materialised rollup.
  ---------------------------------------------------------------------
  insert into proposition_rollup as pr (
    proposition_id, entity_id, class, grade, grade_pre_clamp, awarded_band,
    ceiling, at_ceiling, ceiling_reason, limiting_condition, marginal_flag,
    refutation_state, null_state, silence_reading, base_rate_reading, reference_class,
    sci, sci_numerator, sci_denominator, sci_below_floor,
    v_total, v_claim, v_d4, v_d3, v_d2, v_d1, v_d0, l_d2, l_d3,
    u_d3_unrebutted, v0_unresolved, quarantined,
    place_derived_count, claim_derived_count, caps_applied, citogenesis,
    mirror_only_a1, rubric_version, tier_table_version,
    diagnosticity_table_version, erp_table_version, computed_at, inputs)
  values (
    p_id, p.entity_id, p.class, r.grade, r.grade_pre_clamp, r.awarded_band,
    r.ceiling, r.at_ceiling, r.ceiling_reason, r.limiting_condition, r.marginal_flag,
    r.refutation_state, r.null_state, r.silence_reading, r.base_rate_reading,
    coalesce(p.reference_class, e_ref(p.entity_id)),
    r.sci, sci_num, sci_den, r.sci < 0.5,
    v_total, v_claim, v_d4, v_d3, v_d2, v_d1, v_d0, l_d2, l_d3,
    u_d3, v0, quarantined, place_n, claim_n, r.caps_applied, citogen,
    coalesce(mirror_a1,false), p.rubric_version, p.tier_table_version,
    p.diagnosticity_table_version, p.erp_table_version, now(), r.inputs)
  on conflict (proposition_id) do update set
    grade=excluded.grade, grade_pre_clamp=excluded.grade_pre_clamp,
    awarded_band=excluded.awarded_band, ceiling=excluded.ceiling,
    at_ceiling=excluded.at_ceiling, ceiling_reason=excluded.ceiling_reason,
    limiting_condition=excluded.limiting_condition, marginal_flag=excluded.marginal_flag,
    refutation_state=excluded.refutation_state, null_state=excluded.null_state,
    silence_reading=excluded.silence_reading, base_rate_reading=excluded.base_rate_reading,
    reference_class=excluded.reference_class,
    sci=excluded.sci, sci_numerator=excluded.sci_numerator,
    sci_denominator=excluded.sci_denominator, sci_below_floor=excluded.sci_below_floor,
    v_total=excluded.v_total, v_claim=excluded.v_claim, v_d4=excluded.v_d4,
    v_d3=excluded.v_d3, v_d2=excluded.v_d2, v_d1=excluded.v_d1, v_d0=excluded.v_d0,
    l_d2=excluded.l_d2, l_d3=excluded.l_d3, u_d3_unrebutted=excluded.u_d3_unrebutted,
    v0_unresolved=excluded.v0_unresolved, quarantined=excluded.quarantined,
    place_derived_count=excluded.place_derived_count,
    claim_derived_count=excluded.claim_derived_count,
    caps_applied=excluded.caps_applied, citogenesis=excluded.citogenesis,
    mirror_only_a1=excluded.mirror_only_a1, computed_at=now(), inputs=excluded.inputs;

  return r;
end $$;

-- Reference-class helper: entity-level default when the proposition does not
-- override. §6.5: "if ambiguous, take the class giving the lowest reading."
create or replace function e_ref(p_entity uuid) returns reference_class
language sql stable as $$
  select coalesce((select reference_class from entity where entity_id=p_entity),'RC6'::reference_class);
$$;

-- ---------------------------------------------------------------------
-- bes_apply_grade — recompute, and if the published grade moved, append an
-- immutable grade_event. §11.3: upward movement is ratcheted.
-- ---------------------------------------------------------------------
create or replace function bes_apply_grade(
  p_id uuid,
  p_cause transition_cause default 'NEW_VERIFICATION',
  p_scorer text default null,
  p_narrative text default null)
returns grade_band
language plpgsql as $$
declare
  r bes_grade_result;
  prev grade_band;
  ratchet_blocked boolean := false;
  trig uuid[];
  pub_at timestamptz;
begin
  select grade into prev from proposition_rollup where proposition_id = p_id;
  r := bes_recompute_proposition(p_id);

  -- §11.3 THE ASYMMETRY. A grade may RISE only on NEWLY VERIFIED EVIDENCE
  -- WHOSE OWN DOCUMENT DATE PRECEDES the register's publication of the
  -- candidate. Downward movement carries no such restriction. The failure
  -- mode is inflation, so the ratchet runs one way against it.
  --
  -- The test is on the TRIGGERING rows, not on V as a whole: a candidate
  -- whose original 1961 deed predates publication must not thereby license
  -- every post-publication blog post to raise its grade. That weaker reading
  -- is precisely the self-citation ratchet the register is defending against.
  if prev is not null and r.grade > prev
     and p_cause not in ('SCORER_CHANGE','TABLE_VERSION_CHANGE','RESCORE_NOISE')
  then
    select min(rpl.published_at) into pub_at
    from register_publication_log rpl
    join proposition pp on pp.proposition_id = p_id
    where rpl.entity_id = pp.entity_id and rpl.action='PUBLISH';

    if pub_at is not null then
      select array_agg(x::uuid) into trig
      from jsonb_array_elements_text(r.inputs->'triggering_evidence') t(x);

      if trig is null or array_length(trig,1) is null or not exists (
        select 1 from evidence e
        join document d on d.document_id = e.document_id
        where e.evidence_id = any(trig)
          and e.receipt_state = 'VERIFIED'
          and e.sign = 'SUPPORTS'
          and d.document_date < pub_at::date
          -- §5.1.8: the register's own echo can never lift its own grade.
          and not d.register_echo_quarantined)
      then
        ratchet_blocked := true;
      end if;
    end if;
  end if;

  if ratchet_blocked then
    update proposition_rollup set grade = prev,
      limiting_condition = coalesce(limiting_condition,'') ||
        ' [§11.3 ratchet: upward movement blocked, no supporting document predates publication]'
    where proposition_id = p_id;
    return prev;
  end if;

  if prev is distinct from r.grade then
    insert into grade_event (
      proposition_id, grade_from, grade_to, cause, narrative,
      triggering_evidence_ids, snapshot, scorer_model_id, rubric_version,
      tier_table_version, diagnosticity_table_version, erp_table_version)
    select p_id, prev, r.grade, p_cause, p_narrative,
           coalesce((select array_agg(x::uuid) from jsonb_array_elements_text(
                      r.inputs->'triggering_evidence') t(x)),'{}'::uuid[]),
           to_jsonb(r) || jsonb_build_object('counts', r.inputs),
           p_scorer, pp.rubric_version, pp.tier_table_version,
           pp.diagnosticity_table_version, pp.erp_table_version
    from proposition pp where pp.proposition_id = p_id;
  end if;

  delete from ops_regrade_queue where proposition_id = p_id;
  return r.grade;
end $$;

-- ---------------------------------------------------------------------
-- GRADE RECONSTRUCTION (req. 4) — any past grade, from events alone.
-- ---------------------------------------------------------------------
create or replace function bes_grade_as_of(p_id uuid, p_at timestamptz)
returns grade_band
language sql stable as $$
  select coalesce(
    (select grade_to from grade_event
      where proposition_id = p_id and occurred_at <= p_at
      order by occurred_at desc, seq desc limit 1),
    'X'::grade_band);
$$;

-- Exact replay by event sequence, for the CI regression suite and for any
-- reader who needs "the grade immediately after event N", not "at time T".
create or replace function bes_grade_at_seq(p_id uuid, p_seq bigint)
returns grade_band
language sql stable as $$
  select coalesce(
    (select grade_to from grade_event
      where proposition_id = p_id and seq <= p_seq
      order by seq desc limit 1),
    'X'::grade_band);
$$;

-- Whole-entity snapshot at a past instant: the register reconstructing itself.
create or replace function bes_entity_as_of(p_entity uuid, p_at timestamptz)
returns table (proposition_id uuid, class proposition_class,
               statement text, grade grade_band)
language sql stable as $$
  select p.proposition_id, p.class, p.statement, bes_grade_as_of(p.proposition_id, p_at)
  from proposition p
  where p.entity_id = p_entity and p.created_at <= p_at
  order by p.class;
$$;
