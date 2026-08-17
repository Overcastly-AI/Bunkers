-- =====================================================================
-- SECTION 03 — ENTITIES, ALIASES, RELATIONS, AND GEOMETRIC UNCERTAINTY
--
-- A site is a CONTAINER. It carries identity, geometry, and NOTHING GRADED
-- (BES §1.1). Every graded thing lives on a proposition row. A site page
-- renders N badges, never one.
-- =====================================================================

-- ---------------------------------------------------------------------
-- The container.
-- entity_level {program, site, structure} with parent-child relations is a
-- pre-freeze schema obligation (IC failure #10.3). Without it, Project Greek
-- Island / The Greenbrier / the West Virginia Wing bunker collapse together,
-- and the Camp Hero vs "Montauk Project" split entry is unrepresentable.
-- ---------------------------------------------------------------------
create table core.entity (
  entity_id       uuid primary key default gen_random_uuid(),
  slug            text not null unique,
  entity_level    core.entity_level not null,
  canonical_name  text not null,
  parent_entity_id uuid references core.entity(entity_id),
  country_code    char(2) not null references registry.country(country_code),
  admin_area_id   bigint references registry.admin_area(admin_area_id),

  -- Typology is a GRADED PROPOSITION, not a filter (BES §1.2). This column
  -- is a cached read of the TYPOLOGY proposition and may not be written
  -- directly; the default for every new candidate is unknown-anomaly and it
  -- cannot change without a TYPOLOGY proposition clearing band C.
  typology_cached core.typology not null default 'unknown-anomaly',
  typology_proposition_id uuid,

  first_ingested_at timestamptz not null default now(),
  last_touched_at   timestamptz not null default now(),
  discovered_by     text,                       -- agent id
  discovery_run_id  bigint,

  publication_state core.publication_state not null default 'INTERNAL',
  published_at      timestamptz,
  is_canary         boolean not null default false,   -- BES §12.4; never published
  withdrawn_reason  text,

  constraint entity_published_has_date
    check (publication_state <> 'PUBLISHED' or published_at is not null),
  -- A canary is a fabricated facility name injected into the discovery
  -- queue to measure hallucination against known ground truth. It must
  -- never reach the public projection.
  constraint entity_canary_never_published
    check (not is_canary or publication_state <> 'PUBLISHED'),
  constraint entity_no_self_parent check (parent_entity_id <> entity_id)
);
create index entity_parent_idx  on core.entity(parent_entity_id);
create index entity_country_idx on core.entity(country_code);
create index entity_pub_idx     on core.entity(publication_state) where publication_state = 'PUBLISHED';
create index entity_name_trgm    on core.entity using gin (canonical_name gin_trgm_ops);

-- ---------------------------------------------------------------------
-- Alias sets. RESOLVER maintains these; VERIFIER's subject-binding check
-- string-matches against them (BES §2.3). Entity resolution is therefore a
-- VERIFICATION INPUT, not a bookkeeping convenience (fleet demand #11).
-- ---------------------------------------------------------------------
create table core.entity_alias (
  alias_id     bigint generated always as identity primary key,
  entity_id    uuid not null references core.entity(entity_id) on delete restrict,
  alias_kind   text not null check (alias_kind in
                 ('facility-name','installation-plus-building','codename',
                  'identifier','coordinate-string','local-vernacular','misspelling')),
  alias_text   text not null,
  alias_norm   text generated always as (core.norm_token(alias_text)) stored,
  -- A codename is admissible for subject binding only when backed by an
  -- IDENTITY proposition at band C or better (BES §2.3).
  identity_proposition_id uuid,
  source_observation_id   uuid,
  admissible_for_binding  boolean not null default true,
  added_by     text not null,
  added_at     timestamptz not null default now(),
  retired_at   timestamptz,
  unique (entity_id, alias_kind, alias_text)
);
create index entity_alias_norm_idx  on core.entity_alias(alias_norm) where retired_at is null;
create index entity_alias_trgm      on core.entity_alias using gin (alias_norm gin_trgm_ops);

-- Typed identifiers. COUNTRY-AGNOSTIC: RPUID, MINE_ID, parcel ID, IRIS,
-- FCC ASR are ROWS keyed to registry.identifier_grammar, not columns.
-- A UK register adds grammar rows, not a migration.
create table core.entity_identifier (
  entity_identifier_id bigint generated always as identity primary key,
  entity_id        uuid not null references core.entity(entity_id) on delete restrict,
  identifier_class text not null references registry.identifier_grammar(identifier_class),
  value            text not null,
  value_canonical  text not null,
  resolved_at      timestamptz,
  resolves         boolean,
  asserted_by      text not null,
  unique (entity_id, identifier_class, value_canonical)
);
create index entity_identifier_lookup on core.entity_identifier(identifier_class, value_canonical);

-- ---------------------------------------------------------------------
-- Typed relations, including DISTINCT-FROM.
-- BES §11.1: coordinate proximity and name similarity FLAG, never merge.
-- A merge requires an IDENTITY proposition at band C+ backed by a named,
-- verified, instance-level source. Evidence never pools. Kirtland's Manzano
-- Base and KUMMSC must be assertable apart and must never silently re-merge.
-- ---------------------------------------------------------------------
create table core.entity_relation (
  relation_id   bigint generated always as identity primary key,
  from_entity_id uuid not null references core.entity(entity_id) on delete restrict,
  to_entity_id   uuid not null references core.entity(entity_id) on delete restrict,
  kind          core.entity_relation_kind not null,
  identity_proposition_id uuid,        -- required for ALIAS-OF / MERGED-INTO
  asserted_by   text not null,
  asserted_at   timestamptz not null default now(),
  retracted_at  timestamptz,
  note          text,
  check (from_entity_id <> to_entity_id),
  unique (from_entity_id, to_entity_id, kind)
);
create index entity_relation_from on core.entity_relation(from_entity_id, kind);
create index entity_relation_to   on core.entity_relation(to_entity_id, kind);

-- Merge and split are versioned and REVERSIBLE. Merge/split rates are
-- telemetry; a rising merge rate is an entity-resolution failure signature.
create table core.entity_merge_event (
  merge_event_id bigint generated always as identity primary key,
  kind          text not null check (kind in ('MERGE','SPLIT','UNMERGE')),
  surviving_entity_id uuid not null references core.entity(entity_id),
  absorbed_entity_id  uuid not null references core.entity(entity_id),
  identity_proposition_id uuid,
  identity_grade_at_merge core.grade,
  -- BES §11.1: if a merge RAISES a grade, the merge is doing evidentiary
  -- work it has not justified and is rejected. Recorded, then checked.
  grade_delta_check jsonb not null default '{}'::jsonb,
  rejected      boolean not null default false,
  rejected_reason text,
  performed_by  text not null,
  performed_at  timestamptz not null default now(),
  reversed_by_event_id bigint references core.entity_merge_event(merge_event_id)
);

-- ---------------------------------------------------------------------
-- GEOMETRIC UNCERTAINTY IS FIRST-CLASS.
--
-- Historian failure #12: a precise pin manufactured from imprecise evidence
-- is the register performing its own citogenesis at the interface layer.
-- IC failure #10.2: a facility documented in a declassified record whose
-- coordinates are genuinely unknown (NON-LOCATED) is not the same
-- epistemic object as one whose coordinates are asserted by a forum post
-- (CLAIMED-ONLY). The enum separates them.
--
-- Geometry is an ASSERTION with a source, exactly like every other fact —
-- there are no orphan coordinates. Multiple competing assertions may exist
-- simultaneously; the register picks a render geometry by rule, not by
-- overwrite, and keeps the losers visible.
-- ---------------------------------------------------------------------
create table core.geometry_assertion (
  geometry_assertion_id uuid primary key default gen_random_uuid(),
  entity_id       uuid not null references core.entity(entity_id) on delete restrict,
  locate_proposition_id uuid,           -- the LOCATE proposition this serves
  precision       core.locate_precision not null,

  -- Exactly one of these three carries the shape. Enforced below.
  point_geom      geometry(Point,4326),
  uncertainty_radius_m double precision check (uncertainty_radius_m > 0),
  region_geom     geometry(MultiPolygon,4326),
  admin_area_id   bigint references registry.admin_area(admin_area_id),

  -- Provenance on every fact (hard requirement 11): geometry included.
  source_observation_id uuid,
  derivation      text not null check (derivation in
                    ('instrument-survey','control-point-match','parcel-record',
                     'quadrangle-read','lidar-derived','georeferenced-imagery',
                     'gazetteer','narrative-description','asserted-by-source','centroid-fallback')),
  asserted_by     text not null,
  asserted_at     timestamptz not null default now(),
  superseded_at   timestamptz,
  is_preferred    boolean not null default false,

  constraint geometry_shape_matches_precision check (
    case precision
      when 'surveyed'        then point_geom is not null
      when 'approximate_1km' then point_geom is not null
      when 'approximate_10km'then point_geom is not null
      when 'claimed_only'    then point_geom is not null
      when 'regional'        then region_geom is not null
      when 'admin_area'      then admin_area_id is not null
      when 'non_located'     then point_geom is null and region_geom is null
    end
  ),
  -- NON-LOCATED means documented-but-unlocated. It may never carry a shape.
  constraint geometry_non_located_is_empty
    check (precision <> 'non_located'
           or (point_geom is null and region_geom is null and admin_area_id is null))
);
create unique index geometry_one_preferred
  on core.geometry_assertion(entity_id) where is_preferred and superseded_at is null;
create index geometry_point_gix  on core.geometry_assertion using gist (point_geom);
create index geometry_region_gix on core.geometry_assertion using gist (region_geom);
create index geometry_entity_idx on core.geometry_assertion(entity_id) where superseded_at is null;

comment on table core.geometry_assertion is
  'Never force a misleading point. precision drives representation; a point is only ever rendered when the LOCATE proposition has itself been graded C or better (core.render_geometry).';
