-- =====================================================================
-- BUNKERS REGISTER — PART 2: entities, geometry-with-uncertainty,
--                            propositions (the atomic graded unit)
-- =====================================================================

-- =====================================================================
-- 3. ENTITIES — containers, never graded (§1.1)
-- =====================================================================

-- Country-agnostic (req. 8): jurisdictions are rows, not columns, and
-- expansion is INSERTs into jurisdiction + erp_profile + canonical_corpus.
create table jurisdiction (
  jurisdiction_id uuid primary key default gen_random_uuid(),
  country         iso_country not null,
  level           text not null check (level in ('country','admin1','admin2','local')),
  code            text not null,             -- ISO-3166-2, FIPS county, etc.
  name            text not null,
  parent_id       uuid references jurisdiction(jurisdiction_id),
  geom            geometry(MultiPolygon,4326),
  unique (country, level, code)
);
create index on jurisdiction using gist (geom);
create index on jurisdiction (parent_id);

create table entity (
  entity_id        uuid primary key default gen_random_uuid(),
  slug             text not null unique,
  display_name     text not null,
  entity_level     entity_level not null default 'site',   -- §10.4, IC #10
  parent_entity_id uuid references entity(entity_id),
  country          iso_country not null,
  jurisdiction_id  uuid references jurisdiction(jurisdiction_id),

  ---------------------------------------------------------------------
  -- GEOMETRIC UNCERTAINTY IS FIRST-CLASS (req. 7).
  -- Two geometries, never one. `extent_geom` is the honest uncertainty
  -- region and is REQUIRED for anything located. `point_geom` may only
  -- exist where the evidence actually supports a point.
  ---------------------------------------------------------------------
  location_precision location_precision not null default 'non_located',
  point_geom       geometry(Point,4326),
  extent_geom      geometry(Polygon,4326),
  uncertainty_radius_m numeric check (uncertainty_radius_m >= 0),
  geom_source_note text,

  -- Clustering/viewport anchor ONLY. Never rendered as a pin by the client;
  -- the map RPC refuses to emit it as a point unless render_mode = 'point'.
  anchor_geom      geometry(Point,4326)
                   generated always as
                   (coalesce(point_geom, st_pointonsurface(extent_geom))) stored,

  typology_code    text references typology_profile(code),  -- DEFAULT unknown-anomaly
  reference_class  reference_class,
  first_seen_at    timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  is_published     boolean not null default false,
  published_at     timestamptz,
  withdrawn_at     timestamptz,
  notes            text,

  -- A point may not exist below 'approximate' precision (§10.3, historian #12).
  constraint entity_point_requires_precision check (
    (location_precision in ('surveyed','approximate') and point_geom is not null)
    or (location_precision in ('regional','claimed_only','non_located') and point_geom is null)
  ),
  -- Anything not 'non_located' must carry an explicit uncertainty region.
  constraint entity_extent_required check (
    (location_precision = 'non_located' and extent_geom is null)
    or (location_precision <> 'non_located' and extent_geom is not null)
  ),
  constraint entity_no_self_parent check (parent_entity_id <> entity_id)
);

create index entity_anchor_gix   on entity using gist (anchor_geom);
create index entity_extent_gix   on entity using gist (extent_geom);
create index entity_published_ix on entity (is_published) where is_published;
create index entity_parent_ix    on entity (parent_entity_id);
create index entity_country_ix   on entity (country);
create index entity_name_trgm_ix on entity (lower(display_name));

comment on column entity.anchor_geom is
  'Viewport/clustering anchor derived from the uncertainty region. NOT a location claim. '
  'st_pointonsurface is used rather than st_centroid so the anchor is guaranteed inside '
  'concave uncertainty polygons.';

-- Alias sets. RESOLVER owns these; VERIFIER''s subject-binding check (§2.3)
-- string-matches against them. Entity resolution is a VERIFICATION INPUT.
create table entity_alias (
  alias_id      uuid primary key default gen_random_uuid(),
  entity_id     uuid not null references entity(entity_id) on delete cascade,
  alias         text not null,
  alias_kind    text not null check (alias_kind in
                  ('name','codename','installation_building','rpuid','parcel_id',
                   'mine_id','coordinate','fac_number','iris_number','other')),
  -- A codename binds only via a graded IDENTITY proposition at C+ (§2.3).
  requires_identity_proposition_id uuid,
  normalized    text generated always as (lower(regexp_replace(alias,'[^a-zA-Z0-9]+','','g'))) stored,
  source_note   text,
  unique (entity_id, alias, alias_kind)
);
create index entity_alias_norm_ix on entity_alias (normalized);

-- §11.1 / §10.4. DISTINCT_FROM is seeded from the calibration set so
-- Manzano Base and KUMMSC can never silently re-merge.
create table entity_relation (
  relation_id  uuid primary key default gen_random_uuid(),
  from_entity_id uuid not null references entity(entity_id) on delete cascade,
  to_entity_id   uuid not null references entity(entity_id) on delete cascade,
  kind         entity_relation_kind not null,
  -- A merge requires an IDENTITY proposition at band C+ (FK set below).
  identity_proposition_id uuid,
  asserted_by  text,
  note         text,
  created_at   timestamptz not null default now(),
  check (from_entity_id <> to_entity_id),
  unique (from_entity_id, to_entity_id, kind)
);
create index on entity_relation (to_entity_id, kind);

-- Merges and splits are versioned and REVERSIBLE (§11.1). Evidence never pools:
-- rows keep their original entity binding, recorded here.
create table entity_merge_event (
  merge_event_id uuid primary key default gen_random_uuid(),
  kind           text not null check (kind in ('MERGE','SPLIT','REVERT')),
  surviving_entity_id uuid not null references entity(entity_id),
  absorbed_entity_id  uuid not null references entity(entity_id),
  identity_proposition_id uuid,
  identity_grade_at_merge grade_band,
  grade_raised_by_merge boolean not null default false,   -- §11.1: if true, REJECT
  reverts_event_id uuid references entity_merge_event(merge_event_id),
  performed_at   timestamptz not null default now(),
  performed_by   text not null,
  rationale      text not null
);

-- =====================================================================
-- 4. PROPOSITIONS — the atomic graded unit (req. 1)
-- =====================================================================

create table proposition (
  proposition_id   uuid primary key default gen_random_uuid(),
  entity_id        uuid not null references entity(entity_id) on delete restrict,
  class            proposition_class not null,

  -- The subject may be narrower than the entity (a structure inside a site).
  subject_entity_id uuid references entity(entity_id),
  predicate_args   jsonb not null default '{}'::jsonb,
  -- Normalised, writer-supplied. Guarantees one row per distinct assertion.
  predicate_key    text not null,
  statement        text not null,          -- rendered English, for the finding aid

  as_of_date       date,
  valid_from       date,
  valid_to         date,

  -- §1.3 mandatory fields ------------------------------------------------
  null_hypothesis_code text references null_hypothesis(code),   -- NOT NULLABLE in effect;
                                                                -- absence => null_state UNTESTED => CAP-7
  typology_code    text references typology_profile(code),
  reference_class  reference_class,                             -- publication only (§6.5)
  parent_proposition_id uuid references proposition(proposition_id),
  clamp_exempt     boolean generated always as
                     (class in ('PROGRAM','ORIGIN')) stored,     -- §1.4

  candidate_set_id uuid references candidate_set(candidate_set_id),

  -- table pins (§12.3)
  rubric_version            text not null default 'BES-0.2.0',
  tier_table_version        text,
  diagnosticity_table_version text,
  erp_table_version         text,
  base_rate_table_version   text,

  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  is_published     boolean not null default false,
  published_at     timestamptz,

  constraint prop_no_self_parent check (parent_proposition_id <> proposition_id),
  constraint prop_valid_range check (valid_to is null or valid_from is null or valid_to >= valid_from)
);

-- One row per distinct assertion. Expression uniqueness => unique INDEX.
create unique index proposition_identity_uix on proposition
  (entity_id, class, predicate_key, coalesce(as_of_date,'0001-01-01'::date));

create index proposition_entity_ix  on proposition (entity_id, class);
create index proposition_class_ix   on proposition (class);
create index proposition_parent_ix  on proposition (parent_proposition_id);
create index proposition_pub_ix     on proposition (is_published) where is_published;
create index proposition_args_gix   on proposition using gin (predicate_args jsonb_path_ops);

comment on table proposition is
  'The atomic graded unit. A site page renders N badges, never one (§1.1). '
  '"The hole is certain, the function is not" is one entity with EXIST=A and FUNCTION=E.';

-- Deferred FKs that close the circular references.
alter table candidate_set
  add constraint candidate_set_program_fk
  foreign key (program_proposition_id) references proposition(proposition_id);

alter table entity_alias
  add constraint entity_alias_identity_fk
  foreign key (requires_identity_proposition_id) references proposition(proposition_id);

alter table entity_relation
  add constraint entity_relation_identity_fk
  foreign key (identity_proposition_id) references proposition(proposition_id);

alter table entity_merge_event
  add constraint entity_merge_identity_fk
  foreign key (identity_proposition_id) references proposition(proposition_id);

-- Membership of an entity in a candidate set (§9.2 C1c). M = count of members.
-- Adding a member recomputes M for every member: CANDIDATE_SET_CHANGE.
create table candidate_set_member (
  candidate_set_id uuid not null references candidate_set(candidate_set_id) on delete cascade,
  entity_id        uuid not null references entity(entity_id) on delete cascade,
  added_at         timestamptz not null default now(),
  removed_at       timestamptz,
  primary key (candidate_set_id, entity_id)
);
create index on candidate_set_member (entity_id) where removed_at is null;

-- TYPOLOGY is a graded proposition, not a filter (§1.2). This is the
-- audit trail of a typology actually changing, which requires band C+.
create table entity_typology_history (
  id             bigserial primary key,
  entity_id      uuid not null references entity(entity_id) on delete cascade,
  typology_code  text not null references typology_profile(code),
  proposition_id uuid references proposition(proposition_id),
  grade_at_change grade_band,
  changed_at     timestamptz not null default now(),
  cause          transition_cause not null
);
create index on entity_typology_history (entity_id, changed_at desc);
