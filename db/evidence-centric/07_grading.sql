-- =====================================================================
-- SECTION 07 — GRADES ARE EVENTS, AND THE BANDS ARE THE CONDITIONS
--
-- Hard requirement 4. The register must reconstruct any past grade and show
-- what evidence moved it and when. There is therefore NO grade column on
-- core.proposition. A grade is an append-only event with the full condition
-- vector, the pinned table versions, and the exact observation set that was
-- in scope when it ran.
--
-- BES §9.1: "Because the bands ARE the conditions — ESTABLISHED is *defined*
-- as A1-A6 hold — the label and the mathematics are one instrument, and
-- v0.1's central failure cannot recur." That is why condition_results below
-- is a first-class jsonb and why reliability is measured per condition:
-- "did A2 pass?" is far more reproducible than "is DOC 78 or 84?"
-- =====================================================================

-- ---------------------------------------------------------------------
-- REFUTATION IS DATA (hard requirement 2, historian failure #1).
-- R means something affirmatively resolves against the proposition. It is
-- not the absence of evidence — that is F. These rows are what an R grade
-- points at, and they are retained forever with the entry.
-- ---------------------------------------------------------------------
create table core.refutation (
  refutation_id  bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  state          core.refutation_state not null check (state <> 'R0'),

  -- R3 requires a party with AUTHORITY OVER THE FACT directly stating the
  -- negation. R2 requires >=2 independent-lineage D2+ undercuts that are
  -- improbable under the proposition PLUS null_state = DOMINANT. R1 is a
  -- machine-checkable fabrication finding.
  basis_observation_ids uuid[] not null default '{}',
  authority_document_id uuid references core.source_document(document_id),
  post_dating_impossibility jsonb,     -- claim_date vs evidence_date, deterministic
  participant_admission_document_id uuid references core.source_document(document_id),
  disinformation_operation_note text,

  narrative      text not null,
  asserted_by    text not null,        -- REFUTER
  asserted_at    timestamptz not null default now(),
  -- Any R resting entirely on R2 is re-reviewed on a schedule (BES §8.5).
  next_review_due date,
  reversed_at    timestamptz,
  reversed_reason text
);
create index refutation_prop_idx on core.refutation(proposition_id) where reversed_at is null;

-- The alternative-hypothesis disposition table, published on every entry
-- page. IC failure #6: "that table is the single most valuable artifact the
-- register could show a skeptical reader."
create table core.alternative_disposition (
  disposition_id bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  null_code      char(3) not null references registry.null_hypothesis(null_code),
  is_selected    boolean not null default false,   -- the STRONGEST SURVIVING alternative
  disposition    text not null check (disposition in
                   ('selected-strongest','weaker-than-selected','excluded-by-evidence',
                    'documented-dominant','not-applicable')),
  reasoning      text not null,
  excluding_observation_ids uuid[] not null default '{}',
  assessed_by    text not null,        -- REFUTER
  assessed_at    timestamptz not null default now(),
  unique (proposition_id, null_code)
);
create unique index alternative_one_selected
  on core.alternative_disposition(proposition_id) where is_selected;

-- ---------------------------------------------------------------------
-- DERIVED null_state (BES §4.6). TIERED left this as an unwritten judgement
-- carrying two of five band conditions. It is now a function of the rows.
-- ---------------------------------------------------------------------
create or replace function core.derive_null_state(p_proposition_id uuid)
returns core.null_state language plpgsql stable as $$
declare
  v_null char(3);
  has_d3_unexplained boolean;
  has_d2_unexplained boolean;
  null_documented    boolean;
begin
  select null_code into v_null from core.proposition where proposition_id = p_proposition_id;
  if v_null is null then return 'UNTESTED'; end if;
  if not exists (select 1 from core.alternative_disposition
                  where proposition_id = p_proposition_id and is_selected) then
    return 'UNTESTED';
  end if;

  -- "Cannot produce" has a written test, in three parts:
  --   (i)  the catalog row is marked null-excluding for this null; or
  --   (ii) the E/A assignment placed A at A0 or A1; or
  --   (iii) the row satisfies the §3.4 explicit-statement gate (D4).
  -- (iii) is not in BES §4.6 as written and it must be: a record whose
  -- issuer has authority over the fact and which states the proposition on
  -- its face is, by construction, not producible by the named alternative.
  -- Without it, documentary sufficiency cannot reach A — a conclusive
  -- primary document would stall at C on A3 — which is the exact defect the
  -- rebuild exists to kill (historian fatal #6).
  select exists (
    select 1 from core.observation o
    left join registry.diagnosticity_catalog dc on dc.catalog_id = o.catalog_id
    where o.proposition_id = p_proposition_id
      and o.membership = 'V' and o.magnitude >= 3
      and (coalesce(dc.null_excluding,false)
           or o.ea_alternative in ('A0','A1')
           or (o.magnitude = 4 and o.gate_d_on_its_face and o.gate_e_authority))
  ) into has_d3_unexplained;

  select exists (
    select 1 from core.observation o
    left join registry.diagnosticity_catalog dc on dc.catalog_id = o.catalog_id
    where o.proposition_id = p_proposition_id
      and o.membership = 'V' and o.magnitude >= 2
      and (coalesce(dc.null_excluding,false)
           or o.ea_alternative in ('A0','A1')
           or (o.magnitude = 4 and o.gate_d_on_its_face and o.gate_e_authority))
  ) into has_d2_unexplained;

  if has_d3_unexplained then return 'EXCLUDED'; end if;
  if has_d2_unexplained then return 'INSUFFICIENT'; end if;

  -- DOMINANT requires the null to be itself affirmatively documented by at
  -- least one verified T1/T2 row. SubTropolis has this; a candidate whose
  -- mundane explanation is merely plausible does not.
  select exists (
    select 1 from core.alternative_disposition ad
    join lateral unnest(ad.excluding_observation_ids) x(oid) on true
    join core.observation o on o.observation_id = x.oid
    where ad.proposition_id = p_proposition_id
      and ad.disposition = 'documented-dominant'
      and o.prov_receipt_state = 'VERIFIED'
      and o.prov_origin_tier in ('T1','T2')
  ) into null_documented;

  return case when null_documented then 'DOMINANT' else 'SURVIVING' end;
end $$;

-- ---------------------------------------------------------------------
-- SEARCH COMPLETENESS INDEX (BES §7.2).
-- SCI = receipted searches over X>=1 applicable profiles / applicable profiles.
-- Grades A/B/C publish at any SCI: positive evidence does not require
-- exhaustion. A NEGATIVE VERDICT DOES — so D/E/F/R below SCI 0.5 becomes X.
-- ---------------------------------------------------------------------
create or replace function core.search_completeness(p_proposition_id uuid)
returns table (numerator integer, denominator integer, sci numeric)
language sql stable as $$
  with p as (select * from core.proposition where proposition_id = p_proposition_id),
  applicable as (
    select distinct css.erp_profile_id
      from p
      join core.entity e on e.entity_id = p.entity_id
      join registry.canonical_search_set css
        on css.proposition_class = p.class
       and (css.country_code is null or css.country_code = e.country_code)
      join registry.erp_profile ep on ep.erp_profile_id = css.erp_profile_id
     where ep.counts_toward_sci and ep.x_level <> 'X0'
  ),
  searched as (
    select distinct sr.erp_profile_id
      from core.search_receipt sr
     where sr.proposition_id = p_proposition_id
       and sr.outcome in ('POSITIVE','NEGATIVE')     -- UNSEARCHED does not count
       and sr.erp_profile_id in (select erp_profile_id from applicable)
  )
  select (select count(*) from searched)::integer,
         (select count(*) from applicable)::integer,
         case when (select count(*) from applicable) = 0 then null
              else round((select count(*) from searched)::numeric
                       / (select count(*) from applicable), 3) end
$$;

-- ---------------------------------------------------------------------
-- SILENCE READING (BES §6.4). Published verbatim beside the grade.
-- "No public record of this class would be expected for a facility of this
-- type in this period under this authority. The absence is not evidence
-- against." — historian failure #3 and #13, answered.
-- ---------------------------------------------------------------------
create or replace function core.silence_reading(p_proposition_id uuid)
returns core.silence_reading language sql stable as $$
  select case
    when exists (select 1 from core.search_receipt sr
                  join registry.erp_profile ep using (erp_profile_id)
                 where sr.proposition_id = p_proposition_id
                   and ep.silence_override = 'RECORD-DESTROYED')
      then 'RECORD-DESTROYED'::core.silence_reading
    when (select coalesce(sci,0) from core.search_completeness(p_proposition_id)) < 0.5
      then 'UNSEARCHED'::core.silence_reading
    when exists (select 1 from core.search_receipt sr
                  join registry.erp_profile ep using (erp_profile_id)
                 where sr.proposition_id = p_proposition_id
                   and sr.outcome = 'NEGATIVE' and ep.x_level in ('X1','X2','X3'))
      then 'INFORMATIVE'::core.silence_reading
    else 'UNINFORMATIVE'::core.silence_reading
  end
$$;

-- ---------------------------------------------------------------------
-- THE GRADE EVENT. Append-only. One row per scoring run.
-- ---------------------------------------------------------------------
create table core.grade_event (
  grade_event_id   uuid primary key default gen_random_uuid(),
  proposition_id   uuid not null references core.proposition(proposition_id) on delete restrict,
  seq              integer not null,
  supersedes_id    uuid references core.grade_event(grade_event_id),

  grade            core.grade not null,             -- after caps and clamp
  awarded_band     core.grade,                      -- before caps and clamp
  applied_caps     text[] not null default '{}',    -- CAP-1..CAP-7
  clamped_by_proposition_id uuid references core.proposition(proposition_id),

  -- Every condition of every band, pass/fail, with the inputs it read.
  -- Reliability is measured HERE, at condition level (BES §12.1).
  condition_results jsonb not null,

  ceiling          core.grade,
  at_ceiling       boolean not null default false,
  limiting_condition text,                          -- first failed condition of the band above
  marginal_flag    boolean not null default false,  -- one contested fact decided the band

  refutation_state core.refutation_state not null default 'R0',
  null_state       core.null_state not null,
  null_code        char(3) not null references registry.null_hypothesis(null_code),

  -- published beside the grade, NEVER in the arithmetic (BES §6.5)
  silence_reading  core.silence_reading not null,
  base_rate_reading core.base_rate_reading,
  reference_class  core.reference_class,

  -- the counted quantities, snapshotted
  l_d2             integer not null default 0,
  l_d3             integer not null default 0,
  v_count          integer not null default 0,
  u_count          integer not null default 0,
  v_claim_count    integer not null default 0,
  v0_count         integer not null default 0,
  sci_numerator    integer,
  sci_denominator  integer,
  sci              numeric,

  -- two-bar decomposition (BES §10.2): how much of this grade is the mountain
  place_derived_weight integer not null default 0,
  claim_derived_weight integer not null default 0,

  transition_cause core.transition_cause not null,
  transition_note  text,

  -- version pinning: no grade is comparable across versions without
  -- re-scoring the baseline (BES §12.3)
  scorer_model_id  text references registry.scorer_model(scorer_model_id),
  scorer_model_family text,
  rubric_version   text not null references registry.rubric_version(rubric_version),
  tier_version_id  bigint references registry.table_version(table_version_id),
  diagnosticity_version_id bigint references registry.table_version(table_version_id),
  erp_version_id   bigint references registry.table_version(table_version_id),
  candidate_set_version_id bigint references registry.table_version(table_version_id),

  -- reconstruction key: hash of the ordered (observation_id, membership,
  -- signed_weight) tuple set. Two events with the same hash saw the same
  -- evidence; a grade change with an unchanged hash is instrument drift.
  evidence_state_hash bytea not null,

  computed_at      timestamptz not null default now(),
  published_at     timestamptz,
  is_blind_double_score boolean not null default false,
  double_score_of_id uuid references core.grade_event(grade_event_id),

  unique (proposition_id, seq),
  constraint grade_x_has_low_sci
    check (grade <> 'X' or sci is null or sci < 0.5),
  -- Nothing that is not published can be read by an anonymous client; this
  -- makes that state explicit rather than implicit.
  constraint grade_published_has_date
    check (published_at is null or published_at >= computed_at - interval '1 second')
);
create index grade_event_prop_seq on core.grade_event(proposition_id, seq desc);
create index grade_event_published on core.grade_event(proposition_id, published_at desc)
  where published_at is not null;
create index grade_event_cause_idx on core.grade_event(transition_cause);
create index grade_event_time_brin on core.grade_event using brin (computed_at);

-- The exact evidence set in scope at scoring time. THIS is what makes
-- "show what evidence moved it and when" answerable rather than asserted.
create table core.grade_event_observation (
  grade_event_id   uuid not null references core.grade_event(grade_event_id) on delete restrict,
  observation_id   uuid not null references core.observation(observation_id) on delete restrict,
  membership_at_scoring core.evidence_membership not null,
  signed_weight_at_scoring smallint not null,
  lineage_key_at_scoring text,
  counted_toward   text[] not null default '{}',   -- which conditions it satisfied
  primary key (grade_event_id, observation_id)
);
create index grade_event_obs_obs on core.grade_event_observation(observation_id);

-- Cached pointer to the current published grade. Denormalised for the map
-- and detail queries; maintained by trigger, never written by hand.
create table core.proposition_current_grade (
  proposition_id   uuid primary key references core.proposition(proposition_id) on delete restrict,
  grade_event_id   uuid not null references core.grade_event(grade_event_id),
  grade            core.grade not null,
  grade_rank       smallint,
  published_at     timestamptz not null
);
create index prop_current_grade_rank on core.proposition_current_grade(grade_rank desc);

create or replace function core.refresh_current_grade() returns trigger
language plpgsql as $$
begin
  if new.published_at is null or new.is_blind_double_score then return null; end if;
  insert into core.proposition_current_grade
    (proposition_id, grade_event_id, grade, grade_rank, published_at)
  values (new.proposition_id, new.grade_event_id, new.grade,
          core.grade_rank(new.grade), new.published_at)
  on conflict (proposition_id) do update
    set grade_event_id = excluded.grade_event_id,
        grade          = excluded.grade,
        grade_rank     = excluded.grade_rank,
        published_at   = excluded.published_at
    where excluded.published_at >= core.proposition_current_grade.published_at;
  return null;
end $$;
create trigger grade_event_refresh_current
  after insert or update of published_at on core.grade_event
  for each row execute function core.refresh_current_grade();

-- ---------------------------------------------------------------------
-- GRADE HISTORY RECONSTRUCTION.
-- "The register shows how a candidate's grade moved and why." Disclosure
-- movement renders visually distinct from evidence movement, and instrument
-- drift is suppressed from the public chart entirely (BES §11.2).
-- ---------------------------------------------------------------------
create or replace function core.grade_at(p_proposition_id uuid, p_at timestamptz)
returns core.grade_event language sql stable as $$
  select * from core.grade_event
   where proposition_id = p_proposition_id
     and published_at is not null and published_at <= p_at
     and not is_blind_double_score
   order by published_at desc, seq desc
   limit 1
$$;

create or replace function core.grade_history(p_proposition_id uuid)
returns table (
  seq integer,
  grade core.grade,
  previous_grade core.grade,
  direction text,
  transition_cause core.transition_cause,
  suppress_from_public_chart boolean,
  disclosure_annotation text,
  published_at timestamptz,
  observations_added integer,
  observations_removed integer,
  limiting_condition text
)
language sql stable as $$
  with ev as (
    select ge.*,
           lag(ge.grade) over w as prev_grade,
           lag(ge.grade_event_id) over w as prev_id
      from core.grade_event ge
     where ge.proposition_id = p_proposition_id
       and ge.published_at is not null and not ge.is_blind_double_score
    window w as (order by ge.seq)
  )
  select e.seq, e.grade, e.prev_grade,
         case
           when e.prev_grade is null then 'initial'
           when core.grade_rank(e.grade) is null or core.grade_rank(e.prev_grade) is null then 'state-change'
           when core.grade_rank(e.grade) > core.grade_rank(e.prev_grade) then 'up'
           when core.grade_rank(e.grade) < core.grade_rank(e.prev_grade) then 'down'
           else 'flat' end,
         e.transition_cause,
         -- Instrument drift is never shown as an evidence event.
         e.transition_cause in ('SCORER-CHANGE','TABLE-VERSION-CHANGE','RESCORE-NOISE'),
         case when e.transition_cause = 'NEW-DISCLOSURE'
              then 'the publication record changed; the world did not'
              else null end,
         e.published_at,
         (select count(*)::integer from core.grade_event_observation a
           where a.grade_event_id = e.grade_event_id
             and (e.prev_id is null or not exists (
                   select 1 from core.grade_event_observation b
                    where b.grade_event_id = e.prev_id
                      and b.observation_id = a.observation_id))),
         (select count(*)::integer from core.grade_event_observation b
           where e.prev_id is not null and b.grade_event_id = e.prev_id
             and not exists (select 1 from core.grade_event_observation a
                              where a.grade_event_id = e.grade_event_id
                                and a.observation_id = b.observation_id)),
         e.limiting_condition
    from ev e order by e.seq
$$;

-- ---------------------------------------------------------------------
-- THE ASYMMETRY (BES §11.3). A grade may RISE only on newly verified
-- evidence whose own document date PRECEDES the register's publication of
-- the candidate. Downward movement carries no such restriction. The failure
-- mode is inflation, so the ratchet runs one way against it.
-- ---------------------------------------------------------------------
create table core.publication_log (
  publication_log_id bigint generated always as identity primary key,
  entity_id      uuid not null references core.entity(entity_id),
  proposition_id uuid references core.proposition(proposition_id),
  published_at   timestamptz not null default now(),
  event          text not null check (event in ('FIRST-PUBLISH','REPUBLISH','WITHDRAW')),
  note           text
);
create index publication_log_entity on core.publication_log(entity_id, published_at);

create or replace function core.enforce_upward_ratchet() returns trigger
language plpgsql as $$
declare
  prev core.grade;
  first_pub timestamptz;
  bad integer;
begin
  select grade into prev from core.grade_event
   where proposition_id = new.proposition_id and seq < new.seq
     and not is_blind_double_score
   order by seq desc limit 1;

  if prev is null or core.grade_rank(new.grade) is null or core.grade_rank(prev) is null then
    return new;
  end if;
  if core.grade_rank(new.grade) <= core.grade_rank(prev) then
    return new;   -- downward and flat are unrestricted
  end if;

  select min(pl.published_at) into first_pub
    from core.publication_log pl
    join core.proposition p on p.entity_id = pl.entity_id
   where p.proposition_id = new.proposition_id and pl.event = 'FIRST-PUBLISH';
  if first_pub is null then return new; end if;

  -- Any counted observation whose document post-dates our own publication,
  -- and which is not a verified T1/T2 whose own document date precedes it,
  -- cannot be what raised the grade.
  --
  -- NB: this reads core.observation directly, NOT the grade_event_observation
  -- snapshot. This trigger runs BEFORE INSERT on core.grade_event, and
  -- core.record_grade writes the snapshot rows AFTERWARDS — so the snapshot
  -- is empty at this point and reading it would silently disable the ratchet.
  select count(*) into bad
    from core.observation o
    join core.source_document d on d.document_id = o.document_id
   where o.proposition_id = new.proposition_id
     and o.membership = 'V'
     and coalesce(d.document_date, d.first_observed_date, 'infinity'::date) > first_pub::date
     and not (d.origin_tier in ('T1','T2')
              and d.document_date is not null and d.document_date <= first_pub::date);

  if bad > 0 and new.transition_cause not in ('NEW-DISCLOSURE','SPLIT','MERGE') then
    raise exception
      'upward ratchet: % observations postdate the register''s own publication of this candidate; a grade may rise only on evidence whose document date precedes it (BES 11.3)', bad;
  end if;
  return new;
end $$;
create trigger grade_event_ratchet
  before insert on core.grade_event
  for each row execute function core.enforce_upward_ratchet();

-- ---------------------------------------------------------------------
-- THE MONOTONE CLAMP (BES §1.4), applied at publish time.
-- grade_pub(child) = min(grade(child), grade(EXIST)). PROGRAM and ORIGIN
-- are exempt: that exemption is what makes DUCC (PROGRAM A / EXIST R) and
-- Dulce (ORIGIN A / FUNCTION R) representable.
-- ---------------------------------------------------------------------
create table core.clamp_event (
  clamp_event_id bigint generated always as identity primary key,
  grade_event_id uuid not null references core.grade_event(grade_event_id),
  child_proposition_id  uuid not null references core.proposition(proposition_id),
  parent_proposition_id uuid not null references core.proposition(proposition_id),
  grade_before   core.grade not null,
  grade_after    core.grade not null,
  clamped_at     timestamptz not null default now()
);

create or replace function core.published_grade(p_proposition_id uuid)
returns core.grade language plpgsql stable as $$
declare g core.grade; pg core.grade; exempt boolean; ent uuid;
begin
  select cg.grade, p.clamp_exempt, p.entity_id
    into g, exempt, ent
    from core.proposition p
    left join core.proposition_current_grade cg using (proposition_id)
   where p.proposition_id = p_proposition_id;
  if g is null then return 'X'; end if;
  if exempt then return g; end if;

  select cg.grade into pg
    from core.proposition p
    join core.proposition_current_grade cg using (proposition_id)
   where p.entity_id = ent and p.class = 'EXIST'
   order by cg.published_at desc limit 1;

  return coalesce(core.grade_min(g, pg), g);
end $$;
