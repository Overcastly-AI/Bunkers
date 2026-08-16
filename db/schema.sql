-- =====================================================================
-- BUNKERS REGISTER — PostgreSQL 15+/PostGIS 3.x schema
-- Implements BES v0.2 (Tiered Sufficiency with Signed Evidence).
-- Philosophy: EVIDENCE-CENTRIC. The atom is the signed observation-with-
-- source against a proposition. Sites and grades are emergent aggregations.
--
-- SECTION 01 — extensions, schemas, roles, enumerated domains
-- =====================================================================

create extension if not exists postgis;
create extension if not exists pg_trgm;
create extension if not exists btree_gist;
create extension if not exists "uuid-ossp";

-- ---------------------------------------------------------------------
-- Schemas.
--   registry : reviewed-write curated tables (BES Part 12.1 "four tables")
--   core     : canonical evidence, propositions, grades. NEVER exposed to
--              PostgREST. Anonymous reach is via api views only.
--   ingest   : acquisition plumbing, leads, agent runs, canaries. Internal.
--   api      : the published projection. This is the only schema in
--              PostgREST's db-schemas list.
-- ---------------------------------------------------------------------
create schema if not exists registry;
create schema if not exists core;
create schema if not exists ingest;
create schema if not exists api;

comment on schema core   is 'Canonical evidence graph. Not exposed to PostgREST. RLS enforced as defence in depth.';
comment on schema api    is 'Published projection. The only schema PostgREST should serve.';
comment on schema ingest is 'Acquisition and adjudication plumbing. No anonymous policy exists on any table here: default-deny.';

-- Baseline: nothing is reachable until explicitly granted.
revoke all on schema core, ingest, registry from public;
grant usage on schema api to anon, authenticated, service_role;
grant usage on schema core, registry to anon, authenticated;   -- needed for security_invoker views
grant usage on schema core, registry, ingest to service_role;

alter default privileges in schema core, ingest, registry revoke all on tables from public;

-- =====================================================================
-- ENUMERATED DOMAINS
-- Every enum below is closed on purpose. An agent may not invent a value;
-- extension is a migration, which is the point (BES §1.2, §4.5, §11.2).
-- =====================================================================

-- --- the twelve-class closed proposition vocabulary (BES §1.2) --------
create type core.proposition_class as enum (
  'EXIST','EXTENT','HARDEN','CONTROL','FUNCTION','STATUS','LOCATE',
  'FEATURE','PROGRAM','IDENTITY','ORIGIN','TYPOLOGY'
);

-- --- bands (BES §9.1). R and X are NOT points on the A..F ladder. -----
create type core.grade as enum ('A','B','C','D','E','F','R','X');

create type core.refutation_state as enum ('R0','R1','R2','R3');

create type core.null_state as enum
  ('UNTESTED','SURVIVING','DOMINANT','INSUFFICIENT','EXCLUDED');

create type core.silence_reading as enum
  ('INFORMATIVE','UNINFORMATIVE','RECORD-DESTROYED','UNSEARCHED');

create type core.base_rate_reading as enum
  ('COMMON','UNCOMMON','RARE','VERY-RARE');

create type core.reference_class as enum ('RC1','RC2','RC3','RC4','RC5','RC6');

-- --- provenance: three orthogonal dimensions (BES Part 3) -------------
create type core.origin_tier as enum ('T1','T2','T3','T4','T5','PENDING');

create type core.channel as enum
  ('ORIGIN-HOST','FAITHFUL-MIRROR','CURATED-ARCHIVE','AGGREGATOR','ADVERSARY-WRITABLE');

create type core.causal_provenance as enum
  ('UNSOLICITED','SOLICITED-3P','SOLICITED-BY-CLAIMANT','SELF-PUBLISHED','CROWD-EDITED');

create type core.corpus_era as enum ('PRE-2022','POST-2022-ATTRIBUTED','POST-2022-UNATTRIBUTED','UNKNOWN');

-- --- evidence row facets (BES §2.1) -----------------------------------
create type core.receipt_state as enum ('VERIFIED','UNRESOLVED','DEAD','NEGATIVE');
create type core.evidence_sign as enum ('SUPPORTS','UNDERCUTS','NEUTRAL');
create type core.evidence_scope as enum ('INSTANCE','CLASS','ADJACENT');
create type core.property_locus as enum ('CLAIM-PROPERTY','PLACE-PROPERTY');
create type core.diagnosticity_source as enum ('CATALOG','GATE','MATRIX','DEFAULT');

-- membership in the arithmetic sets V / U (BES §2.4). Computed, never asserted.
create type core.evidence_membership as enum ('V','U','INERT','V0');

-- --- entity model (IC failure #10.3) ----------------------------------
create type core.entity_level as enum ('program','site','structure');

create type core.entity_relation_kind as enum
  ('PARENT-OF','DISTINCT-FROM','SUCCESSOR-OF','CO-LOCATED-WITH','ALIAS-OF','MERGED-INTO','SPLIT-FROM');

-- --- geometry: uncertainty is first-class (historian #12, IC #10.2) ---
create type core.locate_precision as enum (
  'surveyed',          -- instrument-grade, control-point matched
  'approximate_1km',
  'approximate_10km',
  'regional',          -- a named region / installation footprint
  'admin_area',        -- county / district only
  'non_located',       -- DOCUMENTED but coordinates genuinely unknown
  'claimed_only'       -- a coordinate asserted by a source that cannot carry it
);

create type core.geometry_representation as enum
  ('point','uncertainty_circle','region_polygon','admin_polygon','none');

-- --- status / typology as GRADED propositions, not filters ------------
create type core.status_value as enum (
  'active','standby','decommissioned','converted','sealed','demolished',
  'proposed','studied','cancelled','never-built','unknown'
);

create type core.typology as enum (
  'unknown-anomaly','cog-coop','military-hardened','silo-launch-facility',
  'civil-defense-shelter','relay-comms','archive-storage','corporate-data',
  'private-commercial-shelter','research','mine-conversion','urban-in-building'
);

-- --- versioning of grades as events (BES §11.2) -----------------------
create type core.transition_cause as enum (
  'NEW-DISCLOSURE','NEW-SEARCH','NEW-VERIFICATION','RE-ANALYSIS','REFUTATION',
  'STATUS-CHANGE','CANDIDATE-SET-CHANGE','SCORER-CHANGE','TABLE-VERSION-CHANGE',
  'RESCORE-NOISE','REGISTER-ECHO','MERGE','SPLIT','CLAMP','INITIAL'
);

-- --- publication -------------------------------------------------------
create type core.publication_state as enum ('INTERNAL','PUBLISHED','WITHDRAWN');

-- --- expected-record levels (BES §6.2) --------------------------------
create type core.x_level as enum ('X0','X1','X2','X3','KNOWN-NOT-RELEASED');

-- --- E/A fallback ordinals (BES §4.4) ---------------------------------
create type core.ea_expectedness as enum ('E0','E1','E2','E3');
create type core.ea_alternative   as enum ('A0','A1','A2','A3');

-- =====================================================================
-- SMALL IMMUTABLE HELPERS used in constraints, generated columns, indexes
-- =====================================================================

-- Ordinal rank of the A..F ladder. R and X are deliberately NULL: they are
-- not low grades, they are different epistemic objects (BES §7.2, §8).
create or replace function core.grade_rank(g core.grade)
returns smallint language sql immutable parallel safe as $$
  select case g
    when 'A' then 7 when 'B' then 6 when 'C' then 5
    when 'D' then 4 when 'E' then 3 when 'F' then 2
    else null end::smallint
$$;

create or replace function core.rank_grade(r smallint)
returns core.grade language sql immutable parallel safe as $$
  select case r
    when 7 then 'A' when 6 then 'B' when 5 then 'C'
    when 4 then 'D' when 3 then 'E' when 2 then 'F'
    else null end::core.grade
$$;

-- The monotone clamp is min() over the ladder (BES §1.4).
create or replace function core.grade_min(a core.grade, b core.grade)
returns core.grade language sql immutable parallel safe as $$
  select case
    when a is null then b
    when b is null then a
    when core.grade_rank(a) is null then a   -- R / X dominate: not clampable
    when core.grade_rank(b) is null then b
    else core.rank_grade(least(core.grade_rank(a), core.grade_rank(b)))
  end
$$;

-- Deterministic normalisation used for alias matching (subject binding,
-- BES §2.3) and for fact_key canonicalisation. Code, not judgement.
-- unaccent is not guaranteed installed on every project, so fold the Latin-1
-- range explicitly. Deterministic and dependency-free by design.
create or replace function core.norm_token(t text)
returns text language sql immutable parallel safe as $$
  select nullif(
           btrim(regexp_replace(
             lower(translate(t,
               'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿ',
               'AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy')),
             '[^a-z0-9]+', ' ', 'g')),
           '')
$$;

-- The E/A diagnosticity fallback matrix (BES §4.4). Ceiling D3 by
-- construction: D4 is unreachable by inference and requires the §3.4 gate.
create or replace function core.ea_matrix(e core.ea_expectedness, a core.ea_alternative)
returns table (sign core.evidence_sign, magnitude smallint)
language sql immutable parallel safe as $$
  select m.s::core.evidence_sign, m.mag::smallint from (values
    ('E3','A3','NEUTRAL' ,0),('E3','A2','NEUTRAL' ,0),('E3','A1','SUPPORTS',1),('E3','A0','SUPPORTS',3),
    ('E2','A3','NEUTRAL' ,0),('E2','A2','NEUTRAL' ,0),('E2','A1','SUPPORTS',1),('E2','A0','SUPPORTS',3),
    ('E1','A3','UNDERCUTS',1),('E1','A2','UNDERCUTS',1),('E1','A1','NEUTRAL' ,0),('E1','A0','SUPPORTS',2),
    ('E0','A3','UNDERCUTS',3),('E0','A2','UNDERCUTS',3),('E0','A1','UNDERCUTS',2),('E0','A0','NEUTRAL' ,0)
  ) as m(ee,aa,s,mag)
  where m.ee = e::text and m.aa = a::text
$$;

-- X-level to signed undercut magnitude (BES §6.2).
create or replace function core.x_level_magnitude(x core.x_level)
returns smallint language sql immutable parallel safe as $$
  select case x when 'X3' then 3 when 'X2' then 2 when 'X1' then 1 else 0 end::smallint
$$;
-- =====================================================================
-- SECTION 02 — REGISTRY: the four reviewed-write curated tables
--
-- BES Part 12.1: every quantity in the model is a receipt, a lookup into
-- one of these tables, a row count, a boolean with a written test, or one
-- of exactly two adjudicated judgement calls. These tables therefore hold
-- all the judgement that v0.1 put in a weight vector — relocated from
-- unreproducible per-candidate scoring into auditable, versioned,
-- back-fittable lookups (tradeoff #3).
--
-- An agent may PROPOSE a row (ingest.curation_proposal). Assignment is a
-- reviewed write. Every table is versioned; every grade row pins the
-- version it was scored against, so a bad version is identifiable and
-- rollback-able.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Version pins. Every curated table is versioned independently.
-- ---------------------------------------------------------------------
create table registry.table_version (
  table_version_id   bigint generated always as identity primary key,
  table_name         text not null check (table_name in
                       ('tier','diagnosticity','erp','candidate_set','rubric')),
  version            text not null,                    -- semver, e.g. '0.2.0'
  issued_at          timestamptz not null default now(),
  issued_by          text not null,
  supersedes_id      bigint references registry.table_version(table_version_id),
  rederivation_note  text,        -- BES §12.5: re-derived after 25 adjudications, then every 50
  is_current         boolean not null default false,
  unique (table_name, version)
);
create unique index table_version_one_current
  on registry.table_version(table_name) where is_current;

-- ---------------------------------------------------------------------
-- COUNTRY-AGNOSTIC BASE. Country and administrative geography are rows,
-- never columns, so non-US expansion is additive (ratified decision §5.1).
-- Every US-specific identifier class, ERP profile and search corpus below
-- carries country_code; a UK register is new rows in the same tables.
-- ---------------------------------------------------------------------
create table registry.country (
  country_code  char(2) primary key,                   -- ISO 3166-1 alpha-2
  name          text not null,
  register_scope text not null default 'planned'
    check (register_scope in ('active','planned','out-of-scope'))
);

create table registry.admin_area (
  admin_area_id bigint generated always as identity primary key,
  country_code  char(2) not null references registry.country(country_code),
  level         smallint not null check (level between 1 and 3),  -- 1=state 2=county 3=municipality
  code          text not null,                          -- FIPS, ONS, INSEE...
  name          text not null,
  parent_id     bigint references registry.admin_area(admin_area_id),
  geom          geometry(MultiPolygon,4326),
  centroid      geometry(Point,4326),
  unique (country_code, level, code)
);
create index admin_area_geom_gix on registry.admin_area using gist (geom);

-- ---------------------------------------------------------------------
-- TABLE 1 — the source registry / tier ladder.
-- Fields mirror the 158 catalogued sources on disk exactly: the W0
-- registries emit {name,url,holdings,provenance_tier,access_method,format,
-- value,axes_served,rate_limits,robots_posture,search_technique,notes}.
-- Those are the fields that actually arrive, so those are the columns.
--
-- BES §3.1: three incompatible P-tier ladders already exist in W0 output.
-- origin_tier is a single curated column, and THE TIER OF A DOCUMENT IS
-- THE TIER OF ITS AUTHOR, NOT ITS HOST — hence host_tier and content_tier
-- are separate (Black Vault: T3 host delivering T1 content).
-- ---------------------------------------------------------------------
create table registry.corpus (
  corpus_id        bigint generated always as identity primary key,
  slug             text not null unique,
  name             text not null,
  beat             text not null,          -- the five W0 beats
  url              text not null,
  host             text not null,          -- registrable host, for egress probing
  country_code     char(2) references registry.country(country_code),

  -- ---- fields carried verbatim from the W0 registry JSON ----
  holdings         text,
  legacy_p_tier    text check (legacy_p_tier in ('P1','P2','P3','P4','P5')),
  access_method    text,
  format           text,
  value            text check (value in ('critical','high','moderate','low')),
  axes_served      text[] not null default '{}',
  rate_limits      text,
  robots_posture   text,
  search_technique text,
  notes            text,

  -- ---- BES additions ----
  host_tier        core.origin_tier not null default 'PENDING',
  content_tier     core.origin_tier not null default 'PENDING',
  default_channel  core.channel not null default 'ORIGIN-HOST',
  default_causal   core.causal_provenance not null default 'UNSOLICITED',
  adversary_writable boolean not null default false,   -- anonymous party can write a cited field
  transparent_compiler boolean not null default false, -- BES §5.1.3 conduit test
  tier_trap        boolean not null default false,     -- GlobalSecurity: a hop, never a terminus
  machine_generated_blocklist boolean not null default false,  -- BES §3.3

  -- ---- degraded-verification mode (BES §2.6) ----
  egress_state     text not null default 'UNPROBED'
                     check (egress_state in ('REACHABLE','BLOCKED','THROTTLED','UNPROBED')),
  egress_probed_at timestamptz,
  robots_txt_sha256 bytea,
  robots_txt_fetched_at timestamptz,
  faithful_mirror_of bigint references registry.corpus(corpus_id),

  tier_version_id  bigint not null references registry.table_version(table_version_id),
  reviewed_by      text not null,
  reviewed_at      timestamptz not null default now(),

  -- A source flagged adversary-writable can never be an origin-host tier
  -- above T4; and a machine-generated corpus is T5 by construction (§3.3).
  constraint corpus_blocklist_is_t5
    check (not machine_generated_blocklist or content_tier = 'T5')
);
create index corpus_host_idx on registry.corpus(host);
create index corpus_beat_idx on registry.corpus(beat);
comment on column registry.corpus.content_tier is
  'Tier of the AUTHOR of the content delivered. Black Vault / governmentattic are T3 hosts delivering T1 content — record both.';

-- Per-host egress telemetry, published (BES §2.6).
create table registry.egress_probe (
  probe_id      bigint generated always as identity primary key,
  corpus_id     bigint not null references registry.corpus(corpus_id),
  probed_at     timestamptz not null default now(),
  http_status   integer,
  reachable     boolean not null,
  latency_ms    integer,
  note          text
);
create index egress_probe_corpus_idx on registry.egress_probe(corpus_id, probed_at desc);

-- ---------------------------------------------------------------------
-- Identifier grammars. VERIFIER's fifteen validators (fleet demand #1):
-- grammar -> resolution -> issuer metadata match -> subject binding.
-- "Do not construct identifiers; enumerate them" becomes a CHECK, not a note.
-- ---------------------------------------------------------------------
create table registry.identifier_grammar (
  identifier_class   text primary key,     -- 'CREST_ESDN','DTIC_AD','NARA_NAID',...
  country_code       char(2) references registry.country(country_code),
  description        text not null,
  pattern            text not null,        -- POSIX regex, anchored
  canonical_form_sql text,                 -- optional normalising expression
  issuing_authority_host text not null,
  resolver_url_template  text not null,    -- '%s' substituted with canonical id
  faithful_mirror_hosts  text[] not null default '{}',
  issuer_metadata_fields text[] not null default '{}',   -- what must match
  is_known_not_released  boolean not null default false, -- DTIC ADB-prefix
  notes              text
);

-- ---------------------------------------------------------------------
-- TABLE 2 — the diagnosticity catalog (BES §4.3).
-- Per typology profile, per observation key, against a NAMED null.
-- Assignment is a lookup, never an agent judgement.
-- ---------------------------------------------------------------------
create table registry.null_hypothesis (
  null_code   char(3) primary key,                -- A01..A12, extensible by reviewed write
  label       text not null,
  description text not null,
  is_fabrication_null boolean not null default false,  -- A11
  base_rate_note text
);

create table registry.diagnosticity_catalog (
  catalog_id       bigint generated always as identity primary key,
  typology_profile core.typology not null,
  observation_key  text not null,                 -- 'ventilation-shaft','blast-valve-line-item'
  observation_label text not null,
  null_code        char(3) references registry.null_hypothesis(null_code), -- NULL = any null
  sign             core.evidence_sign not null default 'SUPPORTS',
  magnitude        smallint not null check (magnitude between 0 and 4),
  null_excluding   boolean not null default false, -- feeds null_state derivation (BES §4.6)
  property_locus_default core.property_locus,
  universal_d0     boolean not null default false, -- the permanent D0 list
  rationale        text not null,
  diag_version_id  bigint not null references registry.table_version(table_version_id),
  reviewed_by      text not null,
  reviewed_at      timestamptz not null default now(),
  unique (typology_profile, observation_key, null_code, diag_version_id),
  -- D4 is not assignable by catalog fiat; it is the §3.4 gate and nothing else.
  constraint catalog_no_d4 check (magnitude <= 3 or sign = 'SUPPORTS'),
  constraint catalog_universal_d0_is_zero check (not universal_d0 or magnitude = 0)
);
create index diag_catalog_lookup
  on registry.diagnosticity_catalog(typology_profile, observation_key, diag_version_id);

-- ---------------------------------------------------------------------
-- TABLE 3 — expected-record profiles (BES §6.3).
-- Seeded directly from the five W0 `gaps` sections: the NPRC fire, the
-- FCC/NTIA split, FRPP's national-security exclusion, NRHP sensitive-feature
-- exclusion, NEPA categorical exclusions, Chronicling America's 1963
-- copyright waterline, GovInfo's pre-1994 floor, NARA's 96% undigitised
-- bulk, federal-land wells exempt from state permitting, federal
-- construction exempt from local permitting, federal-to-federal transfers
-- generating no deed. Highest-value artifact W0 produced.
-- ---------------------------------------------------------------------
create table registry.erp_profile (
  erp_profile_id   bigint generated always as identity primary key,
  profile_key      text not null,
  country_code     char(2) references registry.country(country_code),
  description      text not null,
  x_level          core.x_level not null,
  applies_to_classes core.proposition_class[] not null default '{}',
  applies_to_typologies core.typology[] not null default '{}',
  era_from         date,
  era_to           date,
  authority_note   text,          -- 'non-appropriated entity', 'NIP/MIP-funded', ...
  silence_override core.silence_reading,   -- RECORD-DESTROYED etc.
  destroying_event text,          -- 'NPRC fire, 12 July 1973, ~16-18M files'
  corpus_id        bigint references registry.corpus(corpus_id),
  counts_toward_sci boolean not null default true,     -- X0 profiles do not
  erp_version_id   bigint not null references registry.table_version(table_version_id),
  reviewed_by      text not null,
  reviewed_at      timestamptz not null default now(),
  unique (profile_key, erp_version_id),
  -- BES §6.2: X0 produces NO ROW, and an unsearched class produces no row
  -- either — an absence, not a zero. So X0 profiles are excluded from SCI.
  constraint erp_x0_not_in_sci check (x_level <> 'X0' or counts_toward_sci = false)
);
create index erp_profile_lookup on registry.erp_profile(erp_version_id, x_level);

-- Which ERP profiles are APPLICABLE to a proposition class: the SCI
-- denominator (BES §7.2).
create table registry.canonical_search_set (
  search_set_id  bigint generated always as identity primary key,
  proposition_class core.proposition_class not null,
  country_code   char(2) references registry.country(country_code),
  erp_profile_id bigint not null references registry.erp_profile(erp_profile_id),
  required       boolean not null default true,
  unique (proposition_class, country_code, erp_profile_id)
);

-- ---------------------------------------------------------------------
-- TABLE 4 — candidate sets (BES §9.2 C1c).
-- An enumerated, closed, published candidate set for a PROGRAM graded A/B.
-- M <= 3N. ADDING A CANDIDATE DILUTES EVERY MEMBER and must trigger a
-- versioned CANDIDATE-SET-CHANGE re-grade of the whole set.
-- ---------------------------------------------------------------------
create table registry.candidate_set (
  candidate_set_id bigint generated always as identity primary key,
  slug             text not null unique,
  label            text not null,
  program_proposition_id uuid,          -- FK added after core.proposition exists
  documented_instance_count integer not null check (documented_instance_count > 0),  -- N
  denominator_note text not null,
  published_at     timestamptz,
  set_version_id   bigint not null references registry.table_version(table_version_id),
  reviewed_by      text not null
);

create table registry.candidate_set_member (
  candidate_set_id bigint not null references registry.candidate_set(candidate_set_id),
  entity_id        uuid not null,       -- FK added after core.entity exists
  added_at         timestamptz not null default now(),
  added_by         text not null,
  removed_at       timestamptz,         -- nothing is deleted
  primary key (candidate_set_id, entity_id)
);

-- M is a COUNT, recomputed on every membership change, never asserted.
create or replace function registry.candidate_set_m(p_set_id bigint)
returns integer language sql stable as $$
  select count(*)::integer from registry.candidate_set_member
   where candidate_set_id = p_set_id and removed_at is null
$$;

create or replace function registry.candidate_set_dilution_ok(p_set_id bigint)
returns boolean language sql stable as $$
  select registry.candidate_set_m(p_set_id) <= 3 * cs.documented_instance_count
    from registry.candidate_set cs where cs.candidate_set_id = p_set_id
$$;

-- ---------------------------------------------------------------------
-- Reference-class base rates (BES §6.5). PUBLICATION ONLY — this table is
-- never read by the grading arithmetic. That separation is precisely what
-- lets BES survive the hallucination canary where a Bayesian prior does not.
-- ---------------------------------------------------------------------
create table registry.base_rate (
  proposition_class core.proposition_class not null,
  reference_class   core.reference_class not null,
  function_set      text not null default 'n/a'
                      check (function_set in ('sensitive','mundane','n/a')),
  reading           core.base_rate_reading not null,
  published_note    text,
  primary key (proposition_class, reference_class, function_set)
);

-- ---------------------------------------------------------------------
-- Rubric / scorer version pins, referenced by every grade event.
-- ---------------------------------------------------------------------
create table registry.rubric_version (
  rubric_version   text primary key,      -- 'BES-0.2.0'
  ratified_at      timestamptz,
  notes            text
);

create table registry.scorer_model (
  scorer_model_id  text primary key,      -- 'claude-opus-5-20260501'
  model_family     text not null,         -- THE independence-relevant field (BES §5.1.2)
  vendor           text,
  role             text not null check (role in
                     ('DISCOVERY','PROPOSER','VERIFIER','SILENCE','LINEAGE',
                      'REFUTER','ASSESSOR','RESOLVER','CURATOR','REVIEWER')),
  first_used_at    timestamptz not null default now()
);
comment on column registry.scorer_model.model_family is
  'Agent independence is NOT source independence. N prompts over one set of weights is one witness speaking N times. This column is what collapses them to one lineage.';
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
-- =====================================================================
-- SECTION 04 — PROPOSITIONS ARE FIRST-CLASS
--
-- Hard requirement 1. The unit of grading is a PROPOSITION, not a place.
-- "The hole is certain, the function is not" is expressed natively: two
-- rows in this table, two independent grade histories, two badges.
--
-- Historian failure #2 / IC failure #2 are both fixed here and only here.
-- A well-documented real installation can no longer launder its
-- documentation onto every claim attached to it, because evidence attaches
-- to proposition_id and nothing else.
-- =====================================================================

create table core.proposition (
  proposition_id   uuid primary key default gen_random_uuid(),
  entity_id        uuid not null references core.entity(entity_id) on delete restrict,
  class            core.proposition_class not null,

  -- The subject is normally the entity, but IDENTITY and ORIGIN take a
  -- second subject (entity B, or a claim), so it is explicit.
  subject_entity_id uuid references core.entity(entity_id),
  object_entity_id  uuid references core.entity(entity_id),   -- IDENTITY B side
  claim_id          uuid,                                     -- ORIGIN: which claim

  -- Class-specific arguments, validated per class by trigger below.
  --   EXTENT   {"dimension":"depth_m","claimed_value":300}
  --   HARDEN   {"threats":["blast","EMP"]}
  --   CONTROL  {"entity":"US Army Corps of Engineers"}
  --   FUNCTION {"function":"COG-COOP"}
  --   STATUS   {"status":"never-built"}
  --   LOCATE   {"radius_m":1000}
  --   PROGRAM  {"program":"DUCC","state":"cancelled"}
  --   ORIGIN   {"claim":"underground city with a lake","artifact":"..." }
  predicate_args   jsonb not null default '{}'::jsonb,

  statement_text   text not null,     -- rendered human-readable proposition
  as_of_date       date,              -- STATUS / CONTROL / FUNCTION are time-bound
  valid_period     daterange,

  -- BES §4.1: null_hypothesis is NOT NULLABLE. An observation contributes
  -- in proportion to its power to discriminate the proposition from the
  -- NAMED alternative, so there is always a named alternative.
  null_code        char(3) not null references registry.null_hypothesis(null_code),
  -- A11 is a MANDATORY CO-NULL on any proposition whose positive support
  -- includes a T5 lineage; both scorings run and the LOWER grade publishes.
  co_null_code     char(3) references registry.null_hypothesis(null_code),

  typology_profile core.typology not null default 'unknown-anomaly',
  reference_class  core.reference_class,      -- publication only, never arithmetic
  function_set     text not null default 'n/a'
                     check (function_set in ('sensitive','mundane','n/a')),

  -- The monotone clamp (BES §1.4): a published child grade may not exceed
  -- its parent's. PROGRAM and ORIGIN are EXEMPT — that exemption is what
  -- makes DUCC (PROGRAM A, EXIST R) and Dulce (ORIGIN A, FUNCTION R)
  -- representable at all.
  parent_proposition_id uuid references core.proposition(proposition_id),
  clamp_exempt     boolean not null default false,

  candidate_set_id bigint references registry.candidate_set(candidate_set_id),

  created_at       timestamptz not null default now(),
  created_by       text not null,        -- PROPOSER agent id
  publication_state core.publication_state not null default 'INTERNAL',
  published_at     timestamptz,
  withdrawn_reason text,

  constraint proposition_no_self_parent check (parent_proposition_id <> proposition_id),
  constraint proposition_identity_has_object
    check (class <> 'IDENTITY' or object_entity_id is not null),
  constraint proposition_origin_has_claim
    check (class <> 'ORIGIN' or claim_id is not null),
  constraint proposition_published_has_date
    check (publication_state <> 'PUBLISHED' or published_at is not null)
);

-- One EXIST proposition per entity per as-of date: the clamp parent must be
-- unambiguous.
create unique index proposition_one_exist
  on core.proposition(entity_id, coalesce(as_of_date,'0001-01-01'::date))
  where class = 'EXIST';
create index proposition_entity_idx  on core.proposition(entity_id, class);
create index proposition_parent_idx  on core.proposition(parent_proposition_id);
create index proposition_class_idx   on core.proposition(class);
create index proposition_args_gin    on core.proposition using gin (predicate_args jsonb_path_ops);
create index proposition_pub_idx     on core.proposition(publication_state) where publication_state='PUBLISHED';

-- PROGRAM and ORIGIN are clamp-exempt by construction, not by choice.
create or replace function core.set_clamp_exemption() returns trigger
language plpgsql as $$
begin
  new.clamp_exempt := (new.class in ('PROGRAM','ORIGIN'));
  return new;
end $$;
create trigger proposition_clamp_exemption
  before insert or update of class on core.proposition
  for each row execute function core.set_clamp_exemption();

-- ---------------------------------------------------------------------
-- predicate_args validation per class. An agent may not invent a class and
-- may not emit an under-specified proposition.
-- ---------------------------------------------------------------------
create or replace function core.validate_predicate_args() returns trigger
language plpgsql as $$
declare req text[];
begin
  req := case new.class
    when 'EXTENT'   then array['dimension','claimed_value','unit']
    when 'HARDEN'   then array['threats']
    when 'CONTROL'  then array['controlling_entity']
    when 'FUNCTION' then array['function']
    when 'STATUS'   then array['status']
    when 'LOCATE'   then array['radius_m']
    when 'FEATURE'  then array['feature']
    when 'PROGRAM'  then array['program','program_state']
    when 'ORIGIN'   then array['claim_text']
    when 'TYPOLOGY' then array['typology']
    when 'IDENTITY' then array['basis']
    else array[]::text[] end;

  if req <> array[]::text[] and not (new.predicate_args ?& req) then
    raise exception 'proposition class % requires predicate_args keys %, got %',
      new.class, req, (select array_agg(k) from jsonb_object_keys(new.predicate_args) k);
  end if;

  -- Closed vocabularies inside the jsonb are checked, not trusted.
  if new.class = 'STATUS' then
    perform 1 from unnest(enum_range(null::core.status_value)) s
      where s::text = new.predicate_args->>'status';
    if not found then raise exception 'STATUS.status % not in closed vocabulary',
      new.predicate_args->>'status'; end if;
  end if;
  if new.class = 'TYPOLOGY' then
    perform 1 from unnest(enum_range(null::core.typology)) t
      where t::text = new.predicate_args->>'typology';
    if not found then raise exception 'TYPOLOGY.typology % not in closed vocabulary',
      new.predicate_args->>'typology'; end if;
  end if;
  return new;
end $$;
create trigger proposition_validate_args
  before insert or update of class, predicate_args on core.proposition
  for each row execute function core.validate_predicate_args();

-- ---------------------------------------------------------------------
-- CLAIMS. A claim is the assertion itself, independent of any artifact
-- that carries it. It is the node the ORIGIN proposition is about and the
-- node semantic clustering collapses onto (BES §5.1.6). Paraphrase and
-- machine regeneration share no strings and cite nothing; they share a claim.
-- ---------------------------------------------------------------------
create table core.claim (
  claim_id       uuid primary key default gen_random_uuid(),
  claim_text     text not null,
  claim_norm     text generated always as (core.norm_token(claim_text)) stored,
  entity_id      uuid references core.entity(entity_id),
  cluster_key    text,          -- semantic cluster on the ASSERTION, not the wording
  first_appearance_document_id uuid,
  first_appearance_date        date,
  first_appearance_confidence  text check (first_appearance_confidence in
                                 ('receipted','inferred','unknown')),
  created_at     timestamptz not null default now()
);
create index claim_cluster_idx on core.claim(cluster_key);
create index claim_norm_trgm   on core.claim using gin (claim_norm gin_trgm_ops);

alter table core.proposition
  add constraint proposition_claim_fk foreign key (claim_id) references core.claim(claim_id);

-- Wire up the deferred FKs from the registry section.
alter table registry.candidate_set
  add constraint candidate_set_program_fk
  foreign key (program_proposition_id) references core.proposition(proposition_id);
alter table registry.candidate_set_member
  add constraint candidate_set_member_entity_fk
  foreign key (entity_id) references core.entity(entity_id);
alter table core.entity
  add constraint entity_typology_prop_fk
  foreign key (typology_proposition_id) references core.proposition(proposition_id);
alter table core.entity_alias
  add constraint entity_alias_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.entity_relation
  add constraint entity_relation_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.entity_merge_event
  add constraint merge_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.geometry_assertion
  add constraint geometry_locate_prop_fk
  foreign key (locate_proposition_id) references core.proposition(proposition_id);
-- =====================================================================
-- SECTION 05 — THE ATOM: SIGNED OBSERVATIONS WITH RECEIPTED SOURCES
--
-- Hard requirement 2. Evidence-centric philosophy in its strongest form:
-- core.observation is the smallest addressable object in the register and
-- everything else in this file exists to give one observation a provenance,
-- a receipt, a sign, a magnitude, and a named alternative to discriminate
-- against. Grades are computed FROM this table; nothing is computed INTO it.
--
-- The separation of source_document (the artifact, reusable) from
-- observation (artifact -> proposition, signed) is what makes the citation
-- graph and lineage analysis possible at all: documents cite documents,
-- observations do not.
-- =====================================================================

-- ---------------------------------------------------------------------
-- THE ARTIFACT. One row per distinct document, reused across propositions.
-- Carries the three ORTHOGONAL provenance dimensions (BES Part 3):
-- institutional origin (tier), causal provenance, and corpus era.
-- ---------------------------------------------------------------------
create table core.source_document (
  document_id      uuid primary key default gen_random_uuid(),
  corpus_id        bigint references registry.corpus(corpus_id),

  title            text,
  issuing_body     text,          -- who authored it, not who hosts it
  author_name      text,
  document_date    date,
  url              text,

  identifier       text,
  identifier_class text references registry.identifier_grammar(identifier_class),
  identifier_canonical text,

  -- Dimension 1: institutional origin. FK into ONE curated ladder; the tier
  -- of a document is the tier of its AUTHOR. PENDING is scored as T4 for all
  -- conditions until reviewed (BES §3.2), which removes the incentive to
  -- route around the review queue under continuous unbounded ingest.
  origin_tier      core.origin_tier not null default 'PENDING',
  tier_assigned_by text,
  tier_reviewed    boolean not null default false,

  -- Dimension 2: causal provenance. Evidence created AFTER, and BECAUSE OF,
  -- a claim is not evidence for the claim.
  causal_provenance core.causal_provenance not null,

  -- Dimension 3: corpus era. COMPUTED from Wayback CDX, domain registration
  -- and pre-2022 capture history — never judged.
  corpus_era       core.corpus_era not null default 'UNKNOWN',
  first_observed_date date,
  domain_registered_date date,
  earliest_cdx_capture date,

  channel          core.channel not null,

  -- BES §2.5 — the self-attestation exclusion. An artifact authored by the
  -- claimant, whose probative content IS the claim, is not evidence for the
  -- claim. It is evidence for ORIGIN and is graded there. This single
  -- boolean is the E/F discriminator both candidate models got wrong.
  self_attesting   boolean not null default false,
  self_attesting_rationale text,

  -- BES §5.1.8 — self-exclusion. Any source whose first observation
  -- postdates the register's own publication of that candidate is
  -- quarantined: retained, displayed, zero lineages, zero conditions.
  register_echo_quarantined boolean not null default false,
  register_echo_reason text,

  -- Agent-authored interpretation inherits T5 (BES §3.1). "This quad shows
  -- an adit at 38.744,-104.848" is an ASSERTION, not a reading of a T1 map.
  authored_by_agent boolean not null default false,
  agent_model_family text,          -- collapses to ONE lineage (BES §5.1.2)
  second_family_confirmed boolean not null default false,
  standard_citation text,           -- era-correct symbol standard, etc.

  lineage_id       bigint,          -- FK added in section 06
  created_at       timestamptz not null default now(),
  publication_state core.publication_state not null default 'INTERNAL',

  constraint document_agent_interpretation_is_t5
    check (not authored_by_agent or second_family_confirmed or origin_tier = 'T5'),
  constraint document_self_attest_has_reason
    check (not self_attesting or self_attesting_rationale is not null)
);
create index document_corpus_idx     on core.source_document(corpus_id);
create index document_identifier_idx on core.source_document(identifier_class, identifier_canonical);
create index document_lineage_idx    on core.source_document(lineage_id);
create index document_era_idx        on core.source_document(corpus_era);
create index document_family_idx     on core.source_document(agent_model_family)
  where agent_model_family is not null;

-- ---------------------------------------------------------------------
-- RESOLVE-OR-DIE (BES §2.2). receipt_state = VERIFIED requires ALL of:
-- grammar passes, identifier resolves at the issuing authority or a
-- designated faithful mirror, HTTP 200, bytes hashed, a verbatim span
-- located at character offsets by deterministic non-LLM code, issuer
-- metadata matches, and subject binding passes.
--
-- Anything else is UNRESOLVED = tier V0: arithmetically inert on every
-- condition, RETAINED AND DISPLAYED. The format-valid-but-unresolvable
-- rate is published per agent as confabulation telemetry.
--
-- Cache-and-revalidate, never cache-once: N receipts per document over
-- time, content hash diffed on schedule, drift is a signal.
-- ---------------------------------------------------------------------
create table core.retrieval_receipt (
  receipt_id       uuid primary key default gen_random_uuid(),
  document_id      uuid not null references core.source_document(document_id) on delete restrict,

  requested_url    text not null,
  resolved_url     text,
  http_status      integer,
  sha256_of_bytes  bytea,
  byte_length      bigint,
  content_type     text,
  retrieved_at     timestamptz not null default now(),

  grammar_pass         boolean not null default false,
  resolved_at_issuer   boolean not null default false,
  mirror_only          boolean not null default false,   -- BES §2.6 / CAP-6
  mirror_host          text,
  issuer_metadata_match boolean not null default false,
  issuer_metadata_diff  jsonb,

  receipt_state    core.receipt_state not null,

  -- The verifier is deterministic code. Where a model is unavoidable it
  -- MUST be a different family from the discoverer: an LLM verifying an LLM
  -- shares the priors that produced the error (BES §2.2, fleet demand #9).
  verifier_kind    text not null default 'code'
                     check (verifier_kind in ('code','model')),
  verifier_model_id text references registry.scorer_model(scorer_model_id),
  discoverer_model_family text,
  verifier_model_family   text,

  -- cache-and-revalidate
  previous_receipt_id uuid references core.retrieval_receipt(receipt_id),
  content_drifted  boolean not null default false,
  drift_alerted_at timestamptz,

  failure_reason   text,

  -- The gate, as a constraint rather than a note.
  constraint receipt_verified_requires_everything check (
    receipt_state <> 'VERIFIED' or (
      grammar_pass
      and (resolved_at_issuer or mirror_only)
      and http_status = 200
      and sha256_of_bytes is not null
      and issuer_metadata_match
    )
  ),
  constraint receipt_mirror_has_host check (not mirror_only or mirror_host is not null),
  -- An LLM may not verify an LLM of its own family.
  constraint receipt_verifier_family_differs check (
    verifier_kind = 'code'
    or discoverer_model_family is null
    or verifier_model_family is distinct from discoverer_model_family
  )
);
create index receipt_document_idx on core.retrieval_receipt(document_id, retrieved_at desc);
create index receipt_state_idx    on core.retrieval_receipt(receipt_state);
create index receipt_drift_idx    on core.retrieval_receipt(document_id) where content_drifted;

-- ---------------------------------------------------------------------
-- Verbatim spans, located at character offsets by non-LLM code.
-- Two kinds: the probative span (what the document says) and the
-- SUBJECT-BINDING span (BES §2.3 — the token proving the document is about
-- THIS facility). A receipt proves bytes exist; it does not prove the
-- document is about this site, and the commonest real-world failure is a
-- genuine record attributed to the wrong site.
-- ---------------------------------------------------------------------
create table core.quoted_span (
  span_id          uuid primary key default gen_random_uuid(),
  receipt_id       uuid not null references core.retrieval_receipt(receipt_id) on delete restrict,
  span_kind        text not null check (span_kind in ('PROBATIVE','SUBJECT-BINDING')),
  quoted_text      text not null,
  span_start_offset bigint not null check (span_start_offset >= 0),
  span_end_offset   bigint not null,
  quote_check      boolean not null default false,   -- deterministic, non-LLM
  -- subject binding: which alias in the entity's registered alias set matched
  matched_alias_id bigint references core.entity_alias(alias_id),
  matched_entity_id uuid references core.entity(entity_id),
  check (span_end_offset > span_start_offset),
  constraint binding_span_has_match
    check (span_kind <> 'SUBJECT-BINDING' or quote_check = false or matched_alias_id is not null)
);
create index quoted_span_receipt_idx on core.quoted_span(receipt_id, span_kind);

-- ---------------------------------------------------------------------
-- SEARCH LOG AND RECEIPTED ABSENCE.
--
-- Fleet demand #2, a W1 blocker. No agent in the current fleet records a
-- search that found nothing. ABSENCE IS NOT CITABLE WITHOUT A RECEIPT FOR
-- THE ABSENCE. The ERP machinery, the SCI, the X band, the ORIGIN
-- dispositive definition and refutation R3 all consume these rows.
-- ---------------------------------------------------------------------
create table core.search_log (
  search_log_id    uuid primary key default gen_random_uuid(),
  proposition_id   uuid not null,       -- FK below (proposition exists already)
  opened_at        timestamptz not null default now(),
  closed_at        timestamptz,
  opened_by        text not null
);
alter table core.search_log
  add constraint search_log_proposition_fk
  foreign key (proposition_id) references core.proposition(proposition_id) on delete restrict;

create table core.search_receipt (
  search_receipt_id uuid primary key default gen_random_uuid(),
  search_log_id    uuid not null references core.search_log(search_log_id) on delete restrict,
  proposition_id   uuid not null references core.proposition(proposition_id) on delete restrict,
  erp_profile_id   bigint references registry.erp_profile(erp_profile_id),
  corpus_id        bigint references registry.corpus(corpus_id),

  query_string     text not null,
  corpus_version   text,
  corpus_as_of     date,
  executed_at      timestamptz not null default now(),
  executed_by      text not null,
  result_count     integer not null check (result_count >= 0),
  http_status      integer,
  results_sha256   bytea,           -- receipt for the absence itself

  -- BES §6.4 / §2.6: if no host in a canonical corpus is reachable, the
  -- search returns UNSEARCHED, not NEGATIVE, and the SCI falls accordingly.
  outcome          text not null check (outcome in ('POSITIVE','NEGATIVE','UNSEARCHED','ERROR')),
  unsearched_reason text,
  constraint search_negative_has_zero check (outcome <> 'NEGATIVE' or result_count = 0),
  constraint search_unsearched_has_reason
    check (outcome <> 'UNSEARCHED' or unsearched_reason is not null)
);
create index search_receipt_prop_idx on core.search_receipt(proposition_id, outcome);
create index search_receipt_erp_idx  on core.search_receipt(proposition_id, erp_profile_id);

-- ---------------------------------------------------------------------
-- THE ATOM.
--
-- One row = one signed observation of one artifact against one proposition,
-- with a magnitude that is a lookup and a sign that can be negative.
-- Historian failure #1: "disconfirmation can only be expressed by declining
-- to award points, which is indistinguishable from having looked and found
-- nothing." Here they are three distinguishable states: an UNDERCUTS row, a
-- NEUTRAL row, and no row at all.
-- ---------------------------------------------------------------------
create table core.observation (
  observation_id   uuid primary key default gen_random_uuid(),
  proposition_id   uuid not null references core.proposition(proposition_id) on delete restrict,
  document_id      uuid references core.source_document(document_id) on delete restrict,
  receipt_id       uuid references core.retrieval_receipt(receipt_id) on delete restrict,
  probative_span_id uuid references core.quoted_span(span_id),
  binding_span_id   uuid references core.quoted_span(span_id),

  -- Rows derived from a receipted NEGATIVE search carry no document.
  -- BES §6.2: negatives are signed, so they live in the same table as
  -- positives and the arithmetic never has two code paths.
  derived_from_search_receipt_id uuid references core.search_receipt(search_receipt_id),

  observation_key  text,        -- catalog key, e.g. 'blast-valve-line-item'
  statement        text not null,

  -- ---- THE SIGNED MAGNITUDE ----
  sign             core.evidence_sign not null,
  magnitude        smallint not null check (magnitude between 0 and 4),
  signed_weight    smallint generated always as (
                     magnitude * case sign when 'SUPPORTS' then 1
                                           when 'UNDERCUTS' then -1 else 0 end
                   ) stored,
  diagnosticity_source core.diagnosticity_source not null,
  catalog_id       bigint references registry.diagnosticity_catalog(catalog_id),
  -- The E/A fallback: the ONLY two ordinals an agent supplies, and only
  -- where no catalog row exists. Every use is logged as a catalog-extension
  -- proposal, so the fallback is self-retiring (BES §4.4).
  ea_expectedness  core.ea_expectedness,
  ea_alternative   core.ea_alternative,

  -- ---- the six §3.4 explicit-statement gate conditions, checkable ----
  gate_a_tier         boolean not null default false,  -- T1 or T2
  gate_b_receipt      boolean not null default false,  -- VERIFIED + subject binding
  gate_c_instance     boolean not null default false,  -- scope INSTANCE
  gate_d_on_its_face  boolean not null default false,  -- span states the proposition
  gate_e_authority    boolean not null default false,  -- issuer has AUTHORITY OVER THE FACT
  gate_f_unsolicited  boolean not null default false,

  scope            core.evidence_scope not null,
  property_locus   core.property_locus not null,
  subject_binding_pass boolean not null default false,

  -- BES §5.5: rows sharing a fact_key within a proposition collapse to one
  -- for lineage counting. Stops "this was an AT&T Long Lines station"
  -- entering as four lineages through four record types (IC failure #7).
  fact_key         text,

  -- ---- denormalised provenance, snapshotted at scoring time ----
  -- These make membership a GENERATED column, which makes set membership a
  -- schema fact rather than an agent's opinion, and makes the arithmetic
  -- reproducible from the row alone.
  prov_receipt_state core.receipt_state not null default 'UNRESOLVED',
  prov_origin_tier   core.origin_tier not null default 'PENDING',
  prov_channel       core.channel not null default 'AGGREGATOR',
  prov_causal        core.causal_provenance not null default 'UNSOLICITED',
  prov_corpus_era    core.corpus_era not null default 'UNKNOWN',
  prov_self_attesting boolean not null default false,
  prov_echo_quarantined boolean not null default false,

  -- ---- THE MEMBERSHIP SETS V AND U (BES §2.4), computed not asserted ----
  membership core.evidence_membership generated always as (
    case
      when prov_receipt_state <> 'VERIFIED' then 'V0'::core.evidence_membership
      when scope <> 'INSTANCE'
        or prov_channel = 'ADVERSARY-WRITABLE'
        or prov_causal not in ('UNSOLICITED','SOLICITED-3P')
        or prov_corpus_era = 'POST-2022-UNATTRIBUTED'
        or prov_self_attesting
        or prov_echo_quarantined
        or sign = 'NEUTRAL'    then 'INERT'::core.evidence_membership
      when sign = 'SUPPORTS'   then 'V'::core.evidence_membership
      else 'U'::core.evidence_membership
    end
  ) stored,

  -- Why a row is inert, rendered on the entry page beside it. Seven
  -- exclusions, each a one-line schema constraint, doing enormous work.
  exclusion_reason text generated always as (
    case
      when prov_receipt_state <> 'VERIFIED' then 'V0-UNRESOLVED: receipt did not resolve; arithmetically inert, retained and displayed'
      when scope = 'ADJACENT'               then 'ADJACENT: proximity is not support'
      when scope = 'CLASS'                  then 'CLASS-SCOPE: establishes the typology, not this instance'
      when prov_channel = 'ADVERSARY-WRITABLE' then 'ADVERSARY-WRITABLE: an anonymous party can write the cited field'
      when prov_causal = 'SOLICITED-BY-CLAIMANT' then 'SOLICITED-BY-CLAIMANT: evidence created after, and because of, the claim'
      when prov_causal = 'SELF-PUBLISHED'   then 'SELF-PUBLISHED: a resolving DOI is not an editorial assertion'
      when prov_causal = 'CROWD-EDITED'     then 'CROWD-EDITED: a lead, never evidence'
      when prov_corpus_era = 'POST-2022-UNATTRIBUTED' then 'POST-2022-UNATTRIBUTED: zero lineages, zero conditions'
      when prov_self_attesting              then 'SELF-ATTESTING: the author is the claimant and the content is the claim; graded under ORIGIN instead'
      when prov_echo_quarantined            then 'REGISTER-ECHO: first observed after the register published this candidate'
      when sign = 'NEUTRAL'                 then 'NEUTRAL: the named null predicts this just as strongly'
      else null
    end
  ) stored,

  -- Attestation custody (BES §5.4). The lineage terminus is whoever is
  -- ASSERTING, never whoever is quoted. Blocks the cheapest lineage-seeding
  -- attack: attributing invented testimony to two real, dead, findable people.
  is_testimony     boolean not null default false,
  witness_resolvable boolean,          -- independently locatable in an unrelated pre-claim record
  attestation_custody text check (attestation_custody in
                        ('signed-or-recorded-interview','bylined-quotation','deposition',
                         'numbered-oral-history-accession','claimant-assertion-only','unknown')),

  asserted_by      text not null,      -- ASSESSOR agent id
  asserted_model_id text references registry.scorer_model(scorer_model_id),
  asserted_at      timestamptz not null default now(),
  publication_state core.publication_state not null default 'INTERNAL',
  notes            text,

  -- ---- constraints that carry real weight ----

  -- Every observation has a source. NO ORPHAN CLAIMS (hard requirement 11).
  constraint observation_has_provenance
    check (document_id is not null or derived_from_search_receipt_id is not null),

  -- D4 is the §3.4 gate and nothing else. All six conditions or it is not D4.
  constraint observation_d4_is_the_gate check (
    magnitude < 4 or (gate_a_tier and gate_b_receipt and gate_c_instance
                      and gate_d_on_its_face and gate_e_authority and gate_f_unsolicited)
  ),
  -- The E/A matrix ceiling is D3. The firewall is arithmetic, not a bolted-on cap.
  constraint observation_matrix_ceiling
    check (diagnosticity_source <> 'MATRIX' or magnitude <= 3),
  constraint observation_matrix_has_ordinals
    check (diagnosticity_source <> 'MATRIX'
           or (ea_expectedness is not null and ea_alternative is not null)),
  constraint observation_catalog_has_catalog_id
    check (diagnosticity_source <> 'CATALOG' or catalog_id is not null),
  -- BES Part 15 defaults: if neither catalog nor matrix resolves, D0.
  constraint observation_default_is_d0
    check (diagnosticity_source <> 'DEFAULT' or magnitude = 0),
  -- BES §2.3: subject-binding failure downgrades scope INSTANCE -> CLASS.
  constraint observation_binding_gates_instance
    check (scope <> 'INSTANCE' or subject_binding_pass),
  -- Negative-search rows are always UNDERCUTS and always claim-property.
  constraint observation_negative_is_undercut
    check (derived_from_search_receipt_id is null or sign = 'UNDERCUTS'),
  -- Testimony reaching D3 requires BOTH witness resolvability AND custody.
  constraint observation_testimony_custody check (
    not is_testimony or magnitude < 3
    or (witness_resolvable
        and attestation_custody in ('signed-or-recorded-interview','bylined-quotation',
                                    'deposition','numbered-oral-history-accession'))
  )
);

create index observation_prop_idx on core.observation(proposition_id);
-- The hot path: building V and U for a proposition.
create index observation_v_idx on core.observation(proposition_id, magnitude desc)
  where membership = 'V';
create index observation_u_idx on core.observation(proposition_id, magnitude desc)
  where membership = 'U';
create index observation_claimprop_idx on core.observation(proposition_id)
  where membership = 'V' and property_locus = 'CLAIM-PROPERTY';
create index observation_doc_idx     on core.observation(document_id);
create index observation_factkey_idx on core.observation(proposition_id, fact_key);
create index observation_key_idx     on core.observation(observation_key);
create index observation_created_brin on core.observation using brin (asserted_at);

comment on table core.observation is
  'The atomic unit of the register. Everything above this table is an aggregation of these rows and is recomputable from them.';
comment on column core.observation.membership is
  'V / U / INERT / V0, generated from the seven exclusions in BES 2.4. Never written by an agent.';

-- ---------------------------------------------------------------------
-- Denormalisation trigger. Keeps the provenance snapshot on the observation
-- in sync with the document and receipt, so `membership` is generated and
-- the arithmetic is reproducible from the observation row alone.
-- ---------------------------------------------------------------------
create or replace function core.sync_observation_provenance() returns trigger
language plpgsql as $$
declare d core.source_document; r core.retrieval_receipt;
begin
  if new.document_id is not null then
    select * into d from core.source_document where document_id = new.document_id;
    new.prov_origin_tier    := d.origin_tier;
    new.prov_channel        := d.channel;
    new.prov_causal         := d.causal_provenance;
    new.prov_corpus_era     := d.corpus_era;
    new.prov_self_attesting := d.self_attesting;
    new.prov_echo_quarantined := d.register_echo_quarantined;
  end if;
  if new.receipt_id is not null then
    select * into r from core.retrieval_receipt where receipt_id = new.receipt_id;
    new.prov_receipt_state := r.receipt_state;
  elsif new.derived_from_search_receipt_id is not null then
    -- A completed, receipted negative search IS a verified observation of
    -- an absence. It is verified about the SEARCH, not about a document.
    new.prov_receipt_state := 'VERIFIED';
    new.prov_causal        := 'UNSOLICITED';
    new.prov_channel       := 'ORIGIN-HOST';
    new.prov_corpus_era    := 'PRE-2022';
  end if;
  -- BES §2.3: binding failure demotes scope. Enforced, not requested.
  if not new.subject_binding_pass and new.scope = 'INSTANCE' then
    new.scope := 'CLASS';
  end if;
  return new;
end $$;
create trigger observation_sync_provenance
  before insert or update on core.observation
  for each row execute function core.sync_observation_provenance();

-- Re-sync dependents when a document's tier or provenance is revised.
-- A tier reassignment is an evidence event and must move every grade
-- that depended on it.
create or replace function core.propagate_document_provenance() returns trigger
language plpgsql as $$
begin
  update core.observation set asserted_at = asserted_at where document_id = new.document_id;
  return null;
end $$;
create trigger document_provenance_propagate
  after update of origin_tier, channel, causal_provenance, corpus_era,
                  self_attesting, register_echo_quarantined
  on core.source_document
  for each row execute function core.propagate_document_provenance();

-- ---------------------------------------------------------------------
-- NOTHING IS DELETED (hard requirement 3, operating rule §6).
-- Refuted entries are retained with their refutations attached; V0 and
-- quarantined rows are retained and displayed as inert.
-- ---------------------------------------------------------------------
create or replace function core.forbid_delete() returns trigger
language plpgsql as $$
begin
  raise exception
    'DELETE forbidden on %.%: the register keeps its negatives. Use publication_state or a retraction column.',
    tg_table_schema, tg_table_name;
end $$;

do $$
declare t text;
begin
  foreach t in array array['entity','proposition','observation','source_document',
                           'retrieval_receipt','quoted_span','search_receipt','claim',
                           'geometry_assertion']
  loop
    execute format(
      'create trigger %I_no_delete before delete on core.%I for each statement execute function core.forbid_delete()',
      t, t);
  end loop;
end $$;
-- =====================================================================
-- SECTION 06 — THE CITATION GRAPH, LINEAGES, AND ORIGIN TRACING
--
-- Hard requirements 5 and 6.
--
-- "A claim on 400 websites is not 400 sources; it is one source and 399
-- copies, and the register must say so." Saying so is a GRAPH PROPERTY, not
-- a COUNT(*). Everything in this section exists to answer one question:
-- how many genuinely independent lineages support this proposition?
--
-- The graph is CYCLIC in the real world. Citogenesis loops are literally
-- cycles: a T3 publication rests on unattributable T5 testimony and is then
-- cited as though primary by a source the T5 later cites back. Every
-- traversal below terminates explicitly — CYCLE clause plus a depth cap,
-- belt and braces, because an unterminated recursive CTE in an ingest cron
-- is an outage.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A lineage is a connected component of the derivation graph, after the
-- collapse rules. It is computed, then MATERIALISED here so that grade
-- events can pin the lineage assignment that was in force when they ran.
-- ---------------------------------------------------------------------
create table core.lineage (
  lineage_id     bigint generated always as identity primary key,
  label          text,
  terminus_document_id uuid references core.source_document(document_id),
  terminus_kind  text not null default 'document' check (terminus_kind in
                   ('document','witness','agent-model-family','compiler','unknown')),
  -- BES §5.1.2: all findings from agents sharing a base model are ONE
  -- lineage, capped at 1 by construction. N prompts over one set of weights
  -- is one witness speaking N times in different words.
  agent_model_family text,
  first_appearance_date date,
  computed_at    timestamptz not null default now(),
  computation_version text not null default 'lineage-0.2.0'
);
create unique index lineage_one_per_model_family
  on core.lineage(agent_model_family) where agent_model_family is not null;

alter table core.source_document
  add constraint document_lineage_fk foreign key (lineage_id)
  references core.lineage(lineage_id);

-- Which rule assigned this document to this lineage: auditability of the
-- collapse itself (BES §5.1.1-8).
create table core.lineage_membership (
  document_id   uuid not null references core.source_document(document_id) on delete restrict,
  lineage_id    bigint not null references core.lineage(lineage_id),
  rule_applied  text not null check (rule_applied in
                  ('same-author-org-publication','model-family-collapse',
                   'transparent-compiler-passthrough','opaque-compiler-terminus',
                   'replication-not-independence','semantic-cluster',
                   'counterfactual-same','counterfactual-distinct',
                   'self-exclusion-quarantine','default-same-under-uncertainty')),
  decided_by    text not null,
  decided_at    timestamptz not null default now(),
  quorum_votes  jsonb not null default '[]'::jsonb,  -- across model families
  disagreement  boolean not null default false,      -- logged, never hidden
  primary key (document_id, lineage_id)
);
create index lineage_membership_lineage_idx on core.lineage_membership(lineage_id);

-- ---------------------------------------------------------------------
-- THE CITATION GRAPH. Sources cite sources. Directed, cyclic, typed.
-- ---------------------------------------------------------------------
create table core.document_citation (
  citation_id   bigint generated always as identity primary key,
  citing_document_id uuid not null references core.source_document(document_id) on delete restrict,
  cited_document_id  uuid not null references core.source_document(document_id) on delete restrict,

  edge_kind     text not null check (edge_kind in
                  ('explicit-citation',      -- names it
                   'mirror-of',              -- faithful mirror, same bytes
                   'replication',            -- database replication of geometry/records
                   'paraphrase',             -- same strings, reworded
                   'semantic-derivation',    -- regeneration: shares no strings, cites nothing
                   'compiler-exposes',       -- transparent compiler -> its primary
                   'quotes-testimony')),     -- asserter -> quoted person

  detection_method text not null check (detection_method in
                     ('explicit-reference','minhash-shingle','semantic-cluster',
                      'wayback-cdx-digest','first-observation-dating','manual','quorum')),
  similarity     double precision check (similarity between 0 and 1),

  -- BES §5.1.7, one of exactly TWO surviving judgement calls in the model.
  -- "Would this source have produced this claim if the prior source had
  -- never existed?" Default under uncertainty is SAME lineage.
  counterfactual_verdict text not null default 'same-lineage'
    check (counterfactual_verdict in ('same-lineage','independent','undetermined')),
  quorum_votes   jsonb not null default '[]'::jsonb,
  quorum_disagreement boolean not null default false,

  -- Does this edge collapse the two documents into one lineage?
  -- compiler-exposes does NOT: a critical edition citing forty Signal
  -- Agency documents is forty lineages, and the compiler is neither counted
  -- nor penalised (BES §5.1.3 — this is what drags PEF Cartwheel out of D).
  collapses_lineage boolean generated always as (
    edge_kind <> 'compiler-exposes'
    and counterfactual_verdict <> 'independent'
  ) stored,

  asserted_by   text not null,
  asserted_at   timestamptz not null default now(),
  retracted_at  timestamptz,
  note          text,
  check (citing_document_id <> cited_document_id),
  unique (citing_document_id, cited_document_id, edge_kind)
);
create index citation_citing_idx on core.document_citation(citing_document_id)
  where retracted_at is null;
create index citation_cited_idx  on core.document_citation(cited_document_id)
  where retracted_at is null;
create index citation_collapse_idx on core.document_citation(citing_document_id, cited_document_id)
  where collapses_lineage and retracted_at is null;

-- ---------------------------------------------------------------------
-- ORIGIN TRACE. Cycle-safe by construction.
--
-- Walks the graph backwards from a document toward its earliest traceable
-- appearance. Returns the full path so the interface can render it, plus
-- an explicit is_cycle flag on the edge that closed a loop. PostgreSQL's
-- CYCLE clause (14+) stops traversal at the repeat; max_depth is a second
-- independent stop so a pathological graph cannot pin a worker.
-- ---------------------------------------------------------------------
create or replace function core.trace_origin(
  p_document_id uuid,
  p_max_depth   integer default 24
)
returns table (
  depth integer,
  document_id uuid,
  title text,
  origin_tier core.origin_tier,
  document_date date,
  first_observed_date date,
  edge_kind text,
  path uuid[],
  is_cycle boolean,
  is_terminus boolean
)
language sql stable parallel safe as $$
  -- Two independent termination guarantees:
  --   (a) the SQL-standard CYCLE clause, which stops the moment a
  --       document_id repeats on the current branch;
  --   (b) an explicit depth cap.
  -- The visible uuid[] path is maintained by hand because the CYCLE
  -- clause's own path column is an array of row-records, not of uuids.
  with recursive walk (depth, document_id, edge_kind, seen) as (
      select 0, p_document_id, null::text, array[p_document_id]
    union all
      select w.depth + 1, dc.cited_document_id, dc.edge_kind,
             w.seen || dc.cited_document_id
        from walk w
        join core.document_citation dc
          on dc.citing_document_id = w.document_id
         and dc.retracted_at is null
       where w.depth < p_max_depth
  ) cycle document_id set cycle_hit using cycle_path
  select w.depth,
         w.document_id,
         d.title,
         d.origin_tier,
         d.document_date,
         d.first_observed_date,
         w.edge_kind,
         w.seen,
         w.cycle_hit,
         not exists (select 1 from core.document_citation x
                      where x.citing_document_id = w.document_id
                        and x.retracted_at is null) as is_terminus
    from walk w
    join core.source_document d using (document_id)
$$;

comment on function core.trace_origin is
  'Cycle-safe backward traversal of the citation graph. CYCLE clause terminates on repeat; p_max_depth is an independent second stop. is_cycle marks the edge that closed the loop rather than hiding it.';

-- The earliest traceable appearance of a claim: the ORIGIN proposition's
-- factual content. Prefers a receipted document date, falls back to first
-- observation (Wayback CDX collapse=digest).
create or replace function core.claim_origin(p_claim_id uuid, p_max_depth integer default 24)
returns table (
  document_id uuid, title text, origin_tier core.origin_tier,
  effective_date date, dating_basis text, reached_via_cycle boolean
)
language sql stable as $$
  with seeds as (
    select distinct o.document_id
      from core.observation o
      join core.proposition p on p.proposition_id = o.proposition_id
     where p.claim_id = p_claim_id and o.document_id is not null
  ),
  walked as (
    select t.* from seeds s
    cross join lateral core.trace_origin(s.document_id, p_max_depth) t
  )
  select w.document_id, w.title, w.origin_tier,
         coalesce(w.document_date, w.first_observed_date) as effective_date,
         case when w.document_date is not null then 'document-date'
              when w.first_observed_date is not null then 'first-observation'
              else 'undated' end as dating_basis,
         bool_or(w.is_cycle) over (partition by w.document_id) as reached_via_cycle
    from walked w
   where w.is_terminus or w.is_cycle
   order by coalesce(w.document_date, w.first_observed_date) nulls last
$$;

-- ---------------------------------------------------------------------
-- CONNECTED COMPONENTS over the collapsing subgraph.
--
-- This is how "independent lineage" is actually computed. A recursive CTE
-- cannot compute components on a cyclic undirected graph without either
-- exploding or terminating early, so this is an explicit iterative
-- label-propagation with a bounded iteration count. Deterministic,
-- terminating, and auditable — which matters more here than elegance.
-- ---------------------------------------------------------------------
create or replace function core.lineage_components(p_document_ids uuid[])
returns table (document_id uuid, component_root uuid)
language sql stable parallel safe as $$
  with recursive
  -- Lineage identity is UNDIRECTED even though citation is not: if B copied
  -- A, they are one lineage whichever end you start from.
  undirected as (
    select citing_document_id as a, cited_document_id as b
      from core.document_citation
     where collapses_lineage and retracted_at is null
    union all
    select cited_document_id, citing_document_id
      from core.document_citation
     where collapses_lineage and retracted_at is null
  ),
  -- UNION (not UNION ALL) is the termination guarantee: the recursive term
  -- deduplicates (seed, node) pairs, so on a finite graph the working set
  -- empties in at most |V| iterations no matter how many cycles exist.
  -- Citogenesis loops ARE cycles; this is the code path that survives them.
  reach (seed, node) as (
      select d, d from unnest(p_document_ids) d
    union
      select r.seed, u.b
        from reach r
        join undirected u on u.a = r.node
  )
  -- PostgreSQL has no min(uuid); order on the text rendering. Any total
  -- order works — the root only has to be stable and order-independent.
  select r.seed, min(r.node::text)::uuid as component_root
    from reach r
   group by r.seed
$$;

comment on function core.lineage_components is
  'Connected components of the collapsing subgraph. UNION-dedup terminates on cyclic graphs by construction; the component root is the minimum reachable document_id, which is stable and order-independent.';

-- ---------------------------------------------------------------------
-- L(Dk): the count of DISTINCT INDEPENDENT LINEAGES containing at least one
-- V-member observation at diagnosticity >= k, after fact-key merge.
--
-- Four collapses happen here, in order, and the order matters:
--   1. membership filter        (BES §2.4)  — only V rows count
--   2. fact-key merge           (BES §5.5)  — one fact is one lineage even
--                                             through four record types
--   3. model-family collapse    (BES §5.1.2)— all one-family agent findings
--                                             become a single lineage
--   4. graph component collapse (BES §5.1.6-7) — copies, paraphrase,
--                                             regeneration, replication
-- ---------------------------------------------------------------------
create or replace function core.independent_lineages(
  p_proposition_id uuid,
  p_min_magnitude  smallint default 2
)
returns table (
  lineage_key text,
  lineage_kind text,
  best_magnitude smallint,
  observation_count integer,
  representative_document_id uuid,
  representative_title text,
  origin_tier core.origin_tier
)
language sql stable as $$
  with v as (
    select o.*, d.agent_model_family, d.title, d.origin_tier as tier
      from core.observation o
      left join core.source_document d on d.document_id = o.document_id
     where o.proposition_id = p_proposition_id
       and o.membership = 'V'
       and o.magnitude >= p_min_magnitude
  ),
  -- 2. fact-key merge: keep the strongest row per fact within the proposition
  merged as (
    select distinct on (coalesce(fact_key, observation_id::text))
           *
      from v
     order by coalesce(fact_key, observation_id::text), magnitude desc, asserted_at asc
  ),
  comp as (
    select * from core.lineage_components(
      (select coalesce(array_agg(distinct document_id) filter (where document_id is not null), '{}')
         from merged))
  ),
  keyed as (
    select m.*,
           case
             -- 3. model-family collapse dominates everything else
             when m.agent_model_family is not null
               then 'model-family:' || m.agent_model_family
             -- 4. graph component
             when c.component_root is not null
               then 'component:' || c.component_root::text
             -- a receipted negative search is its own lineage: the corpus
             when m.derived_from_search_receipt_id is not null
               then 'negative-search:' || m.derived_from_search_receipt_id::text
             else 'orphan:' || m.observation_id::text
           end as lkey,
           case when m.agent_model_family is not null then 'agent-model-family'
                when m.derived_from_search_receipt_id is not null then 'negative-search'
                else 'document' end as lkind
      from merged m
      left join comp c on c.document_id = m.document_id
  )
  select k.lkey,
         min(k.lkind),
         max(k.magnitude)::smallint,
         count(*)::integer,
         (array_agg(k.document_id order by k.magnitude desc))[1],
         (array_agg(k.title       order by k.magnitude desc))[1],
         (array_agg(k.tier        order by k.magnitude desc))[1]
    from keyed k
   group by k.lkey
$$;

create or replace function core.lineage_count(p_proposition_id uuid, p_min_magnitude smallint default 2)
returns integer language sql stable as $$
  select count(*)::integer from core.independent_lineages(p_proposition_id, p_min_magnitude)
$$;

-- ---------------------------------------------------------------------
-- CITOGENESIS DETECTION (BES §5.3, CAP-3).
--
-- A T3+ publication resting on unattributable T5 testimony, subsequently
-- cited as though primary. The whole loop is ONE lineage; the laundered
-- proposition is capped at E; the flag attaches to the PROPOSITION, not the
-- site — which is exactly where the historian's Mount Weather entry had
-- nowhere to live under v0.1.
-- ---------------------------------------------------------------------
create table core.citogenesis_loop (
  loop_id        bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  laundering_document_id uuid not null references core.source_document(document_id),
  t5_root_document_id    uuid references core.source_document(document_id),
  loop_path      uuid[] not null,
  detected_by    text not null,
  detected_at    timestamptz not null default now(),
  state          text not null default 'suspected'
                   check (state in ('suspected','confirmed','cleared')),
  narrative      text not null,
  collapsed_into_lineage_id bigint references core.lineage(lineage_id)
);
create index citogenesis_prop_idx on core.citogenesis_loop(proposition_id) where state='confirmed';

-- Candidate detector: a T1..T3 document whose entire backward closure
-- terminates in T5 material, reached without an intervening authority.
create or replace function core.detect_citogenesis(p_proposition_id uuid, p_max_depth integer default 16)
returns table (
  laundering_document_id uuid,
  laundering_tier core.origin_tier,
  t5_root_document_id uuid,
  path uuid[],
  closed_a_cycle boolean
)
language sql stable as $$
  with cited as (
    select distinct o.document_id
      from core.observation o
     where o.proposition_id = p_proposition_id and o.document_id is not null
  ),
  launderers as (
    select c.document_id, d.origin_tier
      from cited c join core.source_document d using (document_id)
     where d.origin_tier in ('T1','T2','T3')
  ),
  walked as (
    select l.document_id as launder_id, l.origin_tier as launder_tier, t.*
      from launderers l
      cross join lateral core.trace_origin(l.document_id, p_max_depth) t
     where t.depth > 0
  )
  select w.launder_id, w.launder_tier, w.document_id, w.path, bool_or(w.is_cycle) over ()
    from walked w
   where w.origin_tier = 'T5'
     and (w.is_terminus or w.is_cycle)
     -- no intervening body with authority over the fact broke the chain
     and not exists (
       select 1 from unnest(w.path) pid
        join core.source_document sd on sd.document_id = pid
       where sd.origin_tier in ('T1','T2')
         and sd.document_id <> w.launder_id
     )
$$;

-- ---------------------------------------------------------------------
-- Testimony custody. The lineage terminus is whoever is ASSERTING, never
-- whoever is quoted (BES §5.4). An anonymous claim ABOUT what a named
-- person said is one lineage with the claimant, not with the person.
-- ---------------------------------------------------------------------
create table core.witness (
  witness_id     bigint generated always as identity primary key,
  display_name   text not null,
  -- The resolvability gate: independently locatable in a record that
  -- PREDATES the claim and was created for an UNRELATED purpose.
  resolvable     boolean not null default false,
  resolving_record_kind text check (resolving_record_kind in
                   ('payroll','unit-history','union-roll','obituary','court-filing',
                    'property-record','census','directory','none')),
  resolving_record_document_id uuid references core.source_document(document_id),
  resolving_record_predates_claim boolean,
  resolving_record_unrelated_purpose boolean,
  adjudicated_by text,
  adjudicated_at timestamptz,
  note           text
);

create table core.attestation (
  attestation_id bigint generated always as identity primary key,
  witness_id     bigint not null references core.witness(witness_id),
  observation_id uuid not null references core.observation(observation_id) on delete restrict,
  -- custody path the witness controlled, or a third party recorded
  custody        text not null check (custody in
                   ('signed-or-recorded-interview','bylined-quotation','deposition',
                    'numbered-oral-history-accession','claimant-assertion-only','unknown')),
  custody_document_id uuid references core.source_document(document_id),
  -- who is ASSERTING this attestation: the lineage terminus
  asserting_document_id uuid not null references core.source_document(document_id),
  recorded_at    date,
  note           text
);
create index attestation_obs_idx on core.attestation(observation_id);

comment on table core.attestation is
  'Attestation custody closes posthumous attribution — the cheapest lineage-seeding attack. Seeding two "independent" lineages by attributing invented testimony to two real dead findable people collapses to ONE lineage here, because asserting_document_id is the terminus.';
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
-- =====================================================================
-- SECTION 08 — GRADE(P): the algorithm, in the database
--
-- BES §9.4. Every step is deterministic given the evidence table. The
-- function is here rather than in application code for one reason: the
-- grade must be recomputable from the rows alone, by anyone, forever. An
-- external scorer that cannot be re-run is an unauditable scorer.
--
-- Order is load-bearing: refutation first (it overrides all bands), then
-- the SCI floor, then the bands top-down, then the caps, then the clamp.
-- =====================================================================

-- pgcrypto's digest() is not guaranteed enabled; fall back to a stable
-- built-in so the schema installs on a bare project. Swap for
-- digest(x,'sha256') where pgcrypto is available.
create or replace function digest_placeholder(t text)
returns bytea language sql immutable as $$
  select decode(md5(coalesce(t,'')), 'hex')
$$;

create or replace function core.evaluate_proposition(p_proposition_id uuid)
returns jsonb
language plpgsql stable as $$
declare
  p              core.proposition;
  e              core.entity;
  r              record;
  cond           jsonb := '{}'::jsonb;
  v_null_state   core.null_state;
  n_v int; n_u int; n_v0 int; n_vclaim int;
  l_d2 int; l_d3 int;
  has_d4 boolean; d3_lineages int;
  unrebutted_d3_undercut boolean;
  a1 boolean; a1alt boolean; a2 boolean; a3 boolean; a4 boolean; a5 boolean; a6 boolean;
  b1 boolean; b2 boolean; b3 boolean; b4 boolean;
  c1a boolean; c1b boolean; c1c boolean; c2 boolean; c3 boolean;
  d1 boolean; d2c boolean;
  e1 boolean; e2 boolean;
  awarded core.grade;
  final   core.grade;
  caps    text[] := '{}';
  refstate core.refutation_state := 'R0';
  v_sci numeric; v_sci_num int; v_sci_den int;
  mirror_only_a1 boolean;
  place_w int; claim_w int;
  limiting text;
begin
  select * into p from core.proposition where proposition_id = p_proposition_id;
  if p is null then raise exception 'no such proposition %', p_proposition_id; end if;
  select * into e from core.entity where entity_id = p.entity_id;

  -- ---- counts over the membership sets -------------------------------
  select count(*) filter (where membership='V'),
         count(*) filter (where membership='U'),
         count(*) filter (where membership='V0'),
         count(*) filter (where membership='V' and property_locus='CLAIM-PROPERTY'),
         bool_or(membership='V' and magnitude=4),
         coalesce(sum(magnitude) filter (where membership='V' and property_locus='PLACE-PROPERTY'),0),
         coalesce(sum(magnitude) filter (where membership='V' and property_locus='CLAIM-PROPERTY'),0)
    into n_v, n_u, n_v0, n_vclaim, has_d4, place_w, claim_w
    from core.observation where proposition_id = p_proposition_id;

  l_d2 := core.lineage_count(p_proposition_id, 2::smallint);
  l_d3 := core.lineage_count(p_proposition_id, 3::smallint);
  v_null_state := core.derive_null_state(p_proposition_id);
  select numerator, denominator, sci into v_sci_num, v_sci_den, v_sci
    from core.search_completeness(p_proposition_id);

  -- an unrebutted verified UNDERCUTS at D3+ blocks A, B and C alike
  select exists (
    select 1 from core.observation o
     where o.proposition_id = p_proposition_id
       and o.membership='U' and o.magnitude >= 3
       and not exists (select 1 from core.observation x
                        where x.proposition_id = p_proposition_id
                          and x.membership='V' and x.fact_key = o.fact_key
                          and x.magnitude >= o.magnitude)
  ) into unrebutted_d3_undercut;

  -- =====================================================================
  -- STEP 1 — REFUTATION. Checked FIRST; overrides all bands.
  -- BES §8.4: expected-record UNDERCUTS rows can NEVER alone license R.
  -- Without an affirmative row, however deep the negative stack, the
  -- proposition publishes F (SILENCE-DOMINATED). This is the countermeasure
  -- to the model's characteristic failure — quietly refuting a real
  -- facility whose cover story is good.
  -- =====================================================================
  select rf.state into refstate
    from core.refutation rf
   where rf.proposition_id = p_proposition_id and rf.reversed_at is null
     and exists (                              -- the affirmative-content gate
       select 1 from unnest(rf.basis_observation_ids) x(oid)
        join core.observation o on o.observation_id = x.oid
       where o.derived_from_search_receipt_id is null
     )
   order by case rf.state when 'R3' then 3 when 'R2' then 2 when 'R1' then 1 end desc
   limit 1;
  refstate := coalesce(refstate, 'R0');

  cond := cond || jsonb_build_object(
    'R', jsonb_build_object(
      'state', refstate,
      'gate_8_4_affirmative_row_present', refstate <> 'R0',
      'note', 'R is not F. F means nothing verified favours the claim; R means something affirmatively resolves against it.'));

  if refstate <> 'R0' then
    return jsonb_build_object(
      'grade','R','awarded_band','R','applied_caps','[]'::jsonb,
      'refutation_state', refstate, 'null_state', v_null_state,
      'conditions', cond, 'l_d2', l_d2, 'l_d3', l_d3,
      'v_count', n_v, 'u_count', n_u, 'v0_count', n_v0, 'v_claim_count', n_vclaim,
      'sci', v_sci, 'sci_numerator', v_sci_num, 'sci_denominator', v_sci_den,
      'place_derived_weight', place_w, 'claim_derived_weight', claim_w,
      'silence_reading', core.silence_reading(p_proposition_id),
      'limiting_condition', null);
  end if;

  -- =====================================================================
  -- STEP 2 — BAND CONDITIONS, top-down. The bands ARE the conditions.
  -- =====================================================================

  -- ---- A — ESTABLISHED ----
  select count(*) into d3_lineages from core.independent_lineages(p_proposition_id, 3::smallint);
  a1 := has_d4 and exists (select 1 from core.observation
                            where proposition_id=p_proposition_id and membership='V'
                              and magnitude=4 and property_locus='CLAIM-PROPERTY')
        or (d3_lineages >= 2 and (select count(*) from core.observation
                                   where proposition_id=p_proposition_id and membership='V'
                                     and magnitude>=3 and property_locus='CLAIM-PROPERTY') >= 2);

  -- A1-alt: direct observation, EXIST/EXTENT/LOCATE/FEATURE only
  a1alt := p.class in ('EXIST','EXTENT','LOCATE','FEATURE')
           and (select count(*) from core.observation o
                 join core.attestation at on at.observation_id = o.observation_id
                 join core.witness w on w.witness_id = at.witness_id
                where o.proposition_id = p_proposition_id and o.membership='V'
                  and w.resolvable
                  and at.custody in ('signed-or-recorded-interview','bylined-quotation',
                                     'deposition','numbered-oral-history-accession')) >= 2
           and exists (select 1 from core.observation o
                        where o.proposition_id=p_proposition_id and o.membership='V'
                          and o.prov_origin_tier='T1' and o.property_locus='PLACE-PROPERTY');

  a2 := not exists (select 1 from core.observation o
                     where o.proposition_id=p_proposition_id and o.membership='V'
                       and o.magnitude>=3
                       and (not o.subject_binding_pass or o.prov_receipt_state<>'VERIFIED'));
  a3 := (v_null_state = 'EXCLUDED');
  a4 := not unrebutted_d3_undercut;
  a5 := not exists (select 1 from core.observation o
                     where o.proposition_id=p_proposition_id and o.membership='V'
                       and o.magnitude>=3
                       and o.prov_causal not in ('UNSOLICITED','SOLICITED-3P'));

  -- A6 — forgery pricing. Forging a document into a public mirror is cheap;
  -- forging one into cia.gov or a county recorder's index with matching
  -- issuer metadata is not.
  select bool_or(rr.mirror_only) into mirror_only_a1
    from core.observation o join core.retrieval_receipt rr on rr.receipt_id = o.receipt_id
   where o.proposition_id=p_proposition_id and o.membership='V' and o.magnitude>=3;
  mirror_only_a1 := coalesce(mirror_only_a1,false);
  a6 := (not mirror_only_a1) or l_d2 >= 2;

  -- ---- B — CORROBORATED ----
  b1 := (l_d3 >= 2)
        or (l_d2 >= 3 and exists (select 1 from core.observation o
                                   where o.proposition_id=p_proposition_id and o.membership='V'
                                     and o.magnitude>=2 and o.prov_origin_tier in ('T1','T2')));
  b2 := v_null_state in ('EXCLUDED','INSUFFICIENT');
  b3 := not unrebutted_d3_undercut;
  b4 := n_vclaim >= 1;

  -- ---- C — SUPPORTED ----
  c1a := exists (select 1 from core.observation o
                  where o.proposition_id=p_proposition_id and o.membership='V'
                    and o.property_locus='CLAIM-PROPERTY' and o.magnitude>=2);
  c1b := (select count(*) from core.independent_lineages(p_proposition_id, 2::smallint) il
           where il.lineage_kind='document') >= 2
         and exists (select 1 from core.observation o
                      where o.proposition_id=p_proposition_id and o.membership='V'
                        and o.property_locus='PLACE-PROPERTY' and o.magnitude>=2);
  -- C1c — the candidate-set rule. C is the CEILING of this path.
  c1c := p.candidate_set_id is not null
         and registry.candidate_set_dilution_ok(p.candidate_set_id)
         and exists (select 1 from registry.candidate_set cs
                      join core.proposition pp on pp.proposition_id = cs.program_proposition_id
                      join core.proposition_current_grade cgp on cgp.proposition_id = pp.proposition_id
                     where cs.candidate_set_id = p.candidate_set_id
                       and cgp.grade in ('A','B'))
         and exists (select 1 from core.observation o
                      where o.proposition_id=p_proposition_id and o.membership='V'
                        and o.scope='INSTANCE' and o.property_locus='CLAIM-PROPERTY'
                        and o.magnitude>=1);
  c2 := v_null_state <> 'UNTESTED';
  c3 := not unrebutted_d3_undercut;

  -- ---- D — INDICATED ----
  d1 := exists (select 1 from core.observation o
                 where o.proposition_id=p_proposition_id and o.membership='V' and o.magnitude>=1)
        or (select count(*) from core.observation o
             where o.proposition_id=p_proposition_id and o.membership='V' and o.magnitude=0) >= 2;
  d2c := v_null_state in ('SURVIVING','DOMINANT','UNTESTED');

  -- ---- E — DOUBTFUL ----
  e1 := n_v > 0;
  e2 := not exists (select 1 from core.observation o
                     where o.proposition_id=p_proposition_id and o.membership='V' and o.magnitude>=2);

  awarded := case
    when (a1 or a1alt) and a2 and a3 and a4 and a5 and a6 then 'A'
    when b1 and b2 and b3 and b4                           then 'B'
    when (c1a or c1b or c1c) and c2 and c3                 then 'C'
    when d1 and d2c                                        then 'D'
    when e1 and e2                                         then 'E'
    else 'F' end::core.grade;

  cond := cond || jsonb_build_object(
    'A', jsonb_build_object('A1',a1,'A1-alt',a1alt,'A2',a2,'A3',a3,'A4',a4,'A5',a5,'A6',a6),
    'B', jsonb_build_object('B1',b1,'B2',b2,'B3',b3,'B4',b4),
    'C', jsonb_build_object('C1a',c1a,'C1b',c1b,'C1c',c1c,'C2',c2,'C3',c3),
    'D', jsonb_build_object('D1',d1,'D2cond',d2c),
    'E', jsonb_build_object('E1',e1,'E2',e2));

  -- =====================================================================
  -- STEP 3 — THE CAPS.
  -- =====================================================================
  final := awarded;

  if l_d2 <= 1 and not (a1 or a1alt) then
    caps := caps || 'CAP-1'::text; final := core.grade_min(final,'C');
  end if;

  -- CAP-2 splits by proposition class. A function, control or hardening
  -- claim carried entirely by attributes of the PLACE has no support for
  -- the CLAIM at all and belongs at E, not D. This is the single hardest
  -- constraint in the anti-gaming ledger.
  if n_vclaim = 0 then
    if p.class in ('EXIST','EXTENT','LOCATE','FEATURE','TYPOLOGY') then
      caps := caps || 'CAP-2a'::text; final := core.grade_min(final,'D');
    else
      caps := caps || 'CAP-2b'::text; final := core.grade_min(final,'E');
    end if;
  end if;

  if exists (select 1 from core.citogenesis_loop
              where proposition_id=p_proposition_id and state='confirmed') then
    caps := caps || 'CAP-3'::text; final := core.grade_min(final,'E');
  end if;

  if n_v > 0 and not exists (
       select 1 from core.observation o
        left join core.source_document d on d.document_id=o.document_id
       where o.proposition_id=p_proposition_id and o.membership='V'
         and coalesce(d.document_date, d.first_observed_date) <= date '2022-11-30') then
    caps := caps || 'CAP-4'::text; final := core.grade_min(final,'D');
  end if;

  if n_v = 0 then
    caps := caps || 'CAP-5'::text; final := core.grade_min(final,'F');
  end if;

  if mirror_only_a1 and not a6 then
    caps := caps || 'CAP-6'::text; final := core.grade_min(final,'B');
  end if;

  if v_null_state = 'UNTESTED' then
    caps := caps || 'CAP-7'::text; final := core.grade_min(final,'D');
  end if;

  if c1c and not (c1a or c1b) then
    final := core.grade_min(final,'C');   -- C is the ceiling of the candidate-set path
  end if;

  -- =====================================================================
  -- STEP 4 — THE SCI FLOOR. X is not a low grade; it is the absence of one.
  -- Grades A, B, C publish at any SCI: positive evidence does not require
  -- exhaustion. A NEGATIVE VERDICT DOES — you may not declare a claim
  -- unsupported without having looked.
  -- =====================================================================
  if coalesce(v_sci,0) < 0.5 and final in ('D','E','F') then
    final := 'X';
  end if;

  -- limiting_condition: the first failed condition of the band ABOVE.
  limiting := case final
    when 'B' then case when not a1 and not a1alt then 'A1' when not a2 then 'A2'
                       when not a3 then 'A3' when not a4 then 'A4'
                       when not a5 then 'A5' else 'A6' end
    when 'C' then case when not b1 then 'B1' when not b2 then 'B2'
                       when not b3 then 'B3' else 'B4' end
    when 'D' then case when not (c1a or c1b or c1c) then 'C1' when not c2 then 'C2' else 'C3' end
    when 'E' then case when not d1 then 'D1' else 'D2cond' end
    when 'F' then case when not e1 then 'E1' else 'E2' end
    when 'X' then 'SCI floor (BES 7.2)'
    else null end;
  if array_length(caps,1) is not null and final <> awarded then
    limiting := coalesce(limiting,'') || ' [capped by ' || array_to_string(caps,', ') || ']';
  end if;

  return jsonb_build_object(
    'grade', final, 'awarded_band', awarded,
    'applied_caps', to_jsonb(caps),
    'refutation_state', refstate,
    'null_state', v_null_state,
    'null_code', p.null_code,
    'conditions', cond,
    'l_d2', l_d2, 'l_d3', l_d3,
    'v_count', n_v, 'u_count', n_u, 'v0_count', n_v0, 'v_claim_count', n_vclaim,
    'sci', v_sci, 'sci_numerator', v_sci_num, 'sci_denominator', v_sci_den,
    'place_derived_weight', place_w, 'claim_derived_weight', claim_w,
    'silence_reading', core.silence_reading(p_proposition_id),
    'base_rate_reading', (select br.reading from registry.base_rate br
                           where br.proposition_class = p.class
                             and br.reference_class = p.reference_class
                             and br.function_set = p.function_set),
    'limiting_condition', limiting,
    -- one contested fact decided the band
    'marginal_flag', (l_d2 = 2 and final='B') or (l_d2 = 1 and final='C')
                     or exists (select 1 from core.document_citation dc
                                 where dc.quorum_disagreement and dc.retracted_at is null
                                   and dc.citing_document_id in
                                     (select document_id from core.observation
                                       where proposition_id=p_proposition_id and membership='V'))
  );
end $$;

comment on function core.evaluate_proposition is
  'GRADE(P) per BES 9.4. Pure and stable: given the rows, the answer is the same for everyone, forever. Returns the full condition vector, not just a letter, because the decomposition is the product.';

-- Materialise an evaluation as an append-only grade event.
create or replace function core.record_grade(
  p_proposition_id uuid,
  p_cause          core.transition_cause,
  p_scorer_model_id text,
  p_rubric_version text,
  p_publish        boolean default false,
  p_blind_double   boolean default false
) returns uuid
language plpgsql as $$
declare
  ev jsonb; new_id uuid; next_seq integer; fam text; ehash bytea;
begin
  ev := core.evaluate_proposition(p_proposition_id);
  select coalesce(max(seq),0)+1 into next_seq from core.grade_event
   where proposition_id = p_proposition_id;
  select model_family into fam from registry.scorer_model where scorer_model_id = p_scorer_model_id;

  -- Reconstruction key. Same hash + different grade = instrument drift,
  -- which is exactly what TABLE-VERSION-CHANGE and SCORER-CHANGE label.
  select digest_placeholder(string_agg(
           observation_id::text || ':' || membership::text || ':' || signed_weight::text,
           ',' order by observation_id))
    into ehash
    from core.observation where proposition_id = p_proposition_id;

  insert into core.grade_event (
    proposition_id, seq, grade, awarded_band, applied_caps, condition_results,
    limiting_condition, marginal_flag, refutation_state, null_state, null_code,
    silence_reading, base_rate_reading, reference_class,
    l_d2, l_d3, v_count, u_count, v_claim_count, v0_count,
    sci_numerator, sci_denominator, sci,
    place_derived_weight, claim_derived_weight,
    transition_cause, scorer_model_id, scorer_model_family, rubric_version,
    evidence_state_hash, published_at, is_blind_double_score,
    supersedes_id
  )
  select p_proposition_id, next_seq,
         (ev->>'grade')::core.grade, (ev->>'awarded_band')::core.grade,
         array(select jsonb_array_elements_text(ev->'applied_caps')),
         ev->'conditions', ev->>'limiting_condition', (ev->>'marginal_flag')::boolean,
         (ev->>'refutation_state')::core.refutation_state,
         (ev->>'null_state')::core.null_state, ev->>'null_code',
         (ev->>'silence_reading')::core.silence_reading,
         nullif(ev->>'base_rate_reading','')::core.base_rate_reading,
         p.reference_class,
         (ev->>'l_d2')::int, (ev->>'l_d3')::int, (ev->>'v_count')::int,
         (ev->>'u_count')::int, (ev->>'v_claim_count')::int, (ev->>'v0_count')::int,
         (ev->>'sci_numerator')::int, (ev->>'sci_denominator')::int, (ev->>'sci')::numeric,
         (ev->>'place_derived_weight')::int, (ev->>'claim_derived_weight')::int,
         p_cause, p_scorer_model_id, fam, p_rubric_version,
         ehash, case when p_publish then now() end, p_blind_double,
         (select grade_event_id from core.grade_event
           where proposition_id = p_proposition_id and not is_blind_double_score
           order by seq desc limit 1)
    from core.proposition p where p.proposition_id = p_proposition_id
  returning grade_event_id into new_id;

  -- Snapshot the evidence set: this is what makes the event reconstructable.
  insert into core.grade_event_observation
    (grade_event_id, observation_id, membership_at_scoring, signed_weight_at_scoring)
  select new_id, observation_id, membership, signed_weight
    from core.observation where proposition_id = p_proposition_id;

  return new_id;
end $$;

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
-- =====================================================================
-- SECTION 10 — RENDERING UNCERTAINTY, AND FAST VIEWPORT QUERIES
--
-- Hard requirements 7 and 10.
--
-- Historian failure #12: "a precise pin derived from imprecise evidence is
-- the register manufacturing exactly the kind of durable false fact it
-- exists to dismantle." So the map geometry is not the stored geometry —
-- it is a FUNCTION of the stored geometry AND the grade of the LOCATE
-- proposition. Below band C a point is structurally unavailable: the
-- renderer cannot draw one because the API never emits one.
-- =====================================================================

-- ---------------------------------------------------------------------
-- The render rule, in one place, applied everywhere.
-- ---------------------------------------------------------------------
create or replace function core.render_geometry(p_entity_id uuid)
returns table (
  representation core.geometry_representation,
  geom geometry(Geometry,4326),
  precision_level core.locate_precision,
  locate_grade core.grade,
  uncertainty_radius_m double precision,
  suppression_reason text
)
language plpgsql stable as $$
declare
  ga core.geometry_assertion;
  lg core.grade;
  aa registry.admin_area;
begin
  select * into ga from core.geometry_assertion
   where entity_id = p_entity_id and is_preferred and superseded_at is null;
  if ga is null then
    select * into ga from core.geometry_assertion
     where entity_id = p_entity_id and superseded_at is null
     order by array_position(enum_range(null::core.locate_precision), precision)
     limit 1;
  end if;

  if ga is null then
    return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
                        null::core.locate_precision, null::core.grade, null::double precision,
                        'no geometry assertion on file';
    return;
  end if;

  select cg.grade into lg
    from core.proposition p
    join core.proposition_current_grade cg using (proposition_id)
   where p.entity_id = p_entity_id and p.class = 'LOCATE'
   order by cg.published_at desc limit 1;

  -- NON-LOCATED is documented-but-unlocated. It is epistemically distinct
  -- from claimed-only and it belongs in the claims register, not on the map.
  if ga.precision = 'non_located' then
    return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
                        ga.precision, lg, null::double precision,
                        'non-located: documented, coordinates genuinely unknown';
    return;
  end if;

  -- THE HARD GATE. A point requires BOTH a precise assertion AND a LOCATE
  -- proposition graded C or better. Everything else degrades to an area.
  if ga.point_geom is not null
     and ga.precision in ('surveyed','approximate_1km')
     and coalesce(core.grade_rank(lg), 0) >= core.grade_rank('C') then
    return query select 'point'::core.geometry_representation, ga.point_geom,
                        ga.precision, lg, ga.uncertainty_radius_m, null::text;
    return;
  end if;

  if ga.point_geom is not null then
    return query select 'uncertainty_circle'::core.geometry_representation,
                        st_buffer(ga.point_geom::geography,
                                  coalesce(ga.uncertainty_radius_m,
                                    case ga.precision
                                      when 'approximate_1km'  then 1000
                                      when 'approximate_10km' then 10000
                                      else 25000 end))::geometry,
                        ga.precision, lg,
                        coalesce(ga.uncertainty_radius_m,
                          case ga.precision when 'approximate_1km' then 1000
                                            when 'approximate_10km' then 10000
                                            else 25000 end),
                        case when coalesce(core.grade_rank(lg),0) < core.grade_rank('C')
                             then 'LOCATE proposition below band C: rendered as uncertainty, never as a pin'
                             else 'coordinate precision below approximate_1km' end;
    return;
  end if;

  if ga.region_geom is not null then
    return query select 'region_polygon'::core.geometry_representation, ga.region_geom::geometry,
                        ga.precision, lg, null::double precision, null::text;
    return;
  end if;

  if ga.admin_area_id is not null then
    select * into aa from registry.admin_area where admin_area_id = ga.admin_area_id;
    return query select 'admin_polygon'::core.geometry_representation, aa.geom::geometry,
                        ga.precision, lg, null::double precision,
                        'located only to administrative area';
    return;
  end if;

  return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
                      ga.precision, lg, null::double precision, 'no renderable shape';
end $$;

-- ---------------------------------------------------------------------
-- THE MAP PROJECTION.
--
-- A materialised view because viewport queries must not walk the evidence
-- graph. It is built ONLY from published rows and only from entities whose
-- EXIST proposition reaches band D — BES §10.3: "Nothing below band D
-- renders as a map pin; E, F and R live in the claims register with their
-- origin work, which is the product."
--
-- Materialised views do not enforce RLS, so the WHERE clause below IS the
-- security boundary for this object and is written to be read as such.
-- ---------------------------------------------------------------------
create materialized view api.map_feature as
select
  e.entity_id,
  e.slug,
  e.canonical_name,
  e.entity_level,
  e.country_code,
  e.typology_cached                          as typology,
  exist_cg.grade                             as exist_grade,
  core.grade_rank(exist_cg.grade)            as exist_rank,
  rg.representation,
  rg.precision_level                         as locate_precision,
  rg.locate_grade,
  rg.uncertainty_radius_m,
  rg.suppression_reason,
  rg.geom,
  st_transform(rg.geom, 3857)                as geom_3857,
  st_pointonsurface(rg.geom)                 as label_point,
  -- badge counts: a site page renders N badges, never one
  (select count(*) from core.proposition p2
     join core.proposition_current_grade c2 using (proposition_id)
    where p2.entity_id = e.entity_id and p2.publication_state='PUBLISHED')  as proposition_count,
  (select count(*) from core.proposition p3
     join core.proposition_current_grade c3 using (proposition_id)
    where p3.entity_id = e.entity_id and c3.grade = 'R')                    as refuted_count,
  (select count(*) from core.proposition p4
     join core.proposition_current_grade c4 using (proposition_id)
    where p4.entity_id = e.entity_id and c4.grade = 'X')                    as unassessed_count,
  exist_ge.silence_reading,
  exist_ge.base_rate_reading,
  exist_ge.at_ceiling,
  exist_ge.marginal_flag,
  exist_cg.published_at                      as graded_at
from core.entity e
join core.proposition exist_p
  on exist_p.entity_id = e.entity_id and exist_p.class = 'EXIST'
 and exist_p.publication_state = 'PUBLISHED'
join core.proposition_current_grade exist_cg
  on exist_cg.proposition_id = exist_p.proposition_id
join core.grade_event exist_ge
  on exist_ge.grade_event_id = exist_cg.grade_event_id
cross join lateral core.render_geometry(e.entity_id) rg
where e.publication_state = 'PUBLISHED'
  and e.is_canary = false                                  -- canaries never publish
  and rg.geom is not null
  and rg.representation <> 'none'
  and core.grade_rank(exist_cg.grade) >= core.grade_rank('D');

create unique index map_feature_pk    on api.map_feature(entity_id);
create index map_feature_gix          on api.map_feature using gist (geom);
create index map_feature_gix_3857     on api.map_feature using gist (geom_3857);
create index map_feature_rank_idx     on api.map_feature(exist_rank desc);
create index map_feature_typology_idx on api.map_feature(typology);
create index map_feature_country_idx  on api.map_feature(country_code);

comment on materialized view api.map_feature is
  'Published map projection. The WHERE clause is the security boundary: materialised views do not enforce RLS.';

-- ---------------------------------------------------------------------
-- Server-side clustering. Pre-aggregated per zoom bucket so a continental
-- viewport at z3 returns a few hundred rows instead of the whole register,
-- which is what keeps the map fast as the candidate count grows without
-- bound.
-- ---------------------------------------------------------------------
create materialized view api.map_cluster as
with z as (
  select generate_series(2,9) as zoom
),
snapped as (
  select z.zoom,
         -- ~256 px cells in Web Mercator at each zoom
         st_snaptogrid(f.geom_3857, 40075016.686 / (2 ^ z.zoom) / 4) as cell,
         f.entity_id, f.exist_rank, f.typology, f.country_code
    from api.map_feature f cross join z
)
select zoom,
       row_number() over (partition by zoom order by cell) as cluster_id,
       count(*)::integer                        as feature_count,
       max(exist_rank)                          as best_exist_rank,
       core.rank_grade(max(exist_rank))         as best_exist_grade,
       mode() within group (order by typology)  as modal_typology,
       min(country_code)                        as country_code,
       st_centroid(st_collect(cell))            as centroid_3857,
       st_transform(st_centroid(st_collect(cell)), 4326) as centroid,
       st_transform(st_envelope(st_collect(cell)), 4326) as bbox,
       array_agg(entity_id order by exist_rank desc)
         filter (where true)                    as entity_ids
  from snapped
 group by zoom, cell;

create unique index map_cluster_pk  on api.map_cluster(zoom, cluster_id);
create index map_cluster_gix        on api.map_cluster using gist (centroid);
create index map_cluster_zoom_idx   on api.map_cluster(zoom);

-- ---------------------------------------------------------------------
-- Viewport RPC. Returns clusters when zoomed out, features when zoomed in.
-- One round trip, no client-side clustering, no whole-table scan.
-- ---------------------------------------------------------------------
create or replace function api.map_viewport(
  west double precision, south double precision,
  east double precision, north double precision,
  zoom integer,
  min_grade core.grade default 'D',
  typologies core.typology[] default null,
  countries text[] default null
)
returns jsonb
language sql stable parallel safe security invoker as $$
  with bbox as (
    select st_makeenvelope(west, south, east, north, 4326) as g
  )
  select case when zoom <= 9 then
    jsonb_build_object(
      'mode','clusters',
      'zoom', zoom,
      'clusters', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'cluster_id', c.cluster_id,
                 'count', c.feature_count,
                 'best_grade', c.best_exist_grade,
                 'modal_typology', c.modal_typology,
                 'lon', st_x(c.centroid), 'lat', st_y(c.centroid)))
          from api.map_cluster c, bbox
         where c.zoom = map_viewport.zoom
           and c.centroid && bbox.g
           and c.best_exist_rank >= core.grade_rank(min_grade)
           and (countries is null or c.country_code = any(countries))), '[]'::jsonb))
  else
    jsonb_build_object(
      'mode','features',
      'zoom', zoom,
      'features', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'entity_id', f.entity_id,
                 'slug', f.slug,
                 'name', f.canonical_name,
                 'entity_level', f.entity_level,
                 'exist_grade', f.exist_grade,
                 'typology', f.typology,
                 'representation', f.representation,
                 'locate_precision', f.locate_precision,
                 'locate_grade', f.locate_grade,
                 'uncertainty_radius_m', f.uncertainty_radius_m,
                 'suppression_reason', f.suppression_reason,
                 'proposition_count', f.proposition_count,
                 'refuted_count', f.refuted_count,
                 'unassessed_count', f.unassessed_count,
                 'silence_reading', f.silence_reading,
                 'base_rate_reading', f.base_rate_reading,
                 'at_ceiling', f.at_ceiling,
                 'marginal', f.marginal_flag,
                 'geometry', st_asgeojson(f.geom)::jsonb))
          from api.map_feature f, bbox
         where f.geom && bbox.g
           and f.exist_rank >= core.grade_rank(min_grade)
           and (typologies is null or f.typology = any(typologies))
           and (countries  is null or f.country_code = any(countries))
         limit 2000), '[]'::jsonb))
  end
$$;

-- Vector tiles, for MapLibre's native path. Same security boundary: the
-- source is api.map_feature, which is already published-only.
create or replace function api.map_tile(z integer, x integer, y integer)
returns bytea
language sql stable parallel safe security invoker as $$
  with env as (
    select st_tileenvelope(z, x, y) as g
  ),
  src as (
    select f.entity_id, f.slug, f.canonical_name, f.exist_grade, f.exist_rank,
           f.typology, f.representation, f.locate_precision, f.locate_grade,
           f.proposition_count, f.refuted_count,
           st_asmvtgeom(f.geom_3857, env.g, 4096, 64, true) as geom
      from api.map_feature f, env
     where f.geom_3857 && env.g
  )
  select coalesce(st_asmvt(src.*, 'candidates', 4096, 'geom'), ''::bytea)
    from src where geom is not null
$$;

-- Refresh, safe to run concurrently from the ingest cron.
create or replace function api.refresh_map()
returns void language plpgsql security definer set search_path = api, core, registry, public as $$
begin
  refresh materialized view concurrently api.map_feature;
  refresh materialized view concurrently api.map_cluster;
end $$;
revoke all on function api.refresh_map() from public, anon, authenticated;
grant execute on function api.refresh_map() to service_role;
-- =====================================================================
-- SECTION 11 — THE PUBLISHED PROJECTION, AND ROW-LEVEL SECURITY
--
-- Hard requirement 9: anonymous read on published data; ingest and
-- adjudication state writable only by the service role; no leakage of
-- unpublished adjudication state to anonymous readers.
--
-- Three independent layers, so that any one of them failing is not a breach:
--   1. PostgREST is pointed at the `api` schema ONLY. core/ingest/registry
--      are not in db-schemas, so they have no HTTP surface at all.
--   2. RLS on every core table, with anon policies that require
--      publication_state = 'PUBLISHED' all the way up the chain.
--   3. api views are SECURITY INVOKER, so they inherit (2) rather than
--      bypassing it. The two materialised views cannot inherit RLS, so
--      their WHERE clauses are written as the boundary and are grant-scoped.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 11.1 — Enable RLS everywhere in core and ingest. Default deny.
-- ---------------------------------------------------------------------
do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables
            where schemaname in ('core','ingest','registry')
  loop
    execute format('alter table %I.%I enable row level security', t.schemaname, t.tablename);
    execute format('alter table %I.%I force row level security', t.schemaname, t.tablename);
  end loop;
end $$;

-- service_role has BYPASSRLS in Supabase, but state it explicitly so the
-- intent survives a role change.
do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables
            where schemaname in ('core','ingest','registry')
  loop
    execute format(
      'create policy service_all on %I.%I as permissive for all to service_role using (true) with check (true)',
      t.schemaname, t.tablename);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 11.2 — Anonymous read policies. Published-only, chained.
--
-- Note what is NOT here: ingest.*, core.adjudication state, curation
-- proposals, canaries, leads, double-scoring, null returns, agent runs.
-- Those tables have no anon policy, which means RLS denies every row.
-- ---------------------------------------------------------------------

-- Reference data is public: the register publishes its own instrument.
create policy anon_read on registry.country          for select to anon, authenticated using (true);
create policy anon_read on registry.admin_area       for select to anon, authenticated using (true);
create policy anon_read on registry.null_hypothesis  for select to anon, authenticated using (true);
create policy anon_read on registry.corpus           for select to anon, authenticated using (true);
create policy anon_read on registry.egress_probe     for select to anon, authenticated using (true);
create policy anon_read on registry.identifier_grammar for select to anon, authenticated using (true);
create policy anon_read on registry.diagnosticity_catalog for select to anon, authenticated using (true);
create policy anon_read on registry.erp_profile      for select to anon, authenticated using (true);
create policy anon_read on registry.canonical_search_set for select to anon, authenticated using (true);
create policy anon_read on registry.candidate_set    for select to anon, authenticated using (true);
create policy anon_read on registry.candidate_set_member for select to anon, authenticated using (true);
create policy anon_read on registry.base_rate        for select to anon, authenticated using (true);
create policy anon_read on registry.table_version    for select to anon, authenticated using (true);
create policy anon_read on registry.rubric_version   for select to anon, authenticated using (true);
create policy anon_read on registry.scorer_model     for select to anon, authenticated using (true);

-- Entities: published, non-canary.
create policy anon_read on core.entity for select to anon, authenticated
  using (publication_state = 'PUBLISHED' and is_canary = false);

create policy anon_read on core.entity_alias for select to anon, authenticated
  using (retired_at is null and exists (
    select 1 from core.entity e where e.entity_id = entity_alias.entity_id
      and e.publication_state='PUBLISHED' and not e.is_canary));

create policy anon_read on core.entity_identifier for select to anon, authenticated
  using (exists (select 1 from core.entity e where e.entity_id = entity_identifier.entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

create policy anon_read on core.entity_relation for select to anon, authenticated
  using (retracted_at is null
     and exists (select 1 from core.entity a where a.entity_id = entity_relation.from_entity_id
                   and a.publication_state='PUBLISHED' and not a.is_canary)
     and exists (select 1 from core.entity b where b.entity_id = entity_relation.to_entity_id
                   and b.publication_state='PUBLISHED' and not b.is_canary));

create policy anon_read on core.entity_merge_event for select to anon, authenticated
  using (exists (select 1 from core.entity e where e.entity_id = entity_merge_event.surviving_entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

create policy anon_read on core.geometry_assertion for select to anon, authenticated
  using (exists (select 1 from core.entity e where e.entity_id = geometry_assertion.entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

-- Propositions: published, and their entity published.
create policy anon_read on core.proposition for select to anon, authenticated
  using (publication_state = 'PUBLISHED'
     and exists (select 1 from core.entity e where e.entity_id = proposition.entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

create policy anon_read on core.claim for select to anon, authenticated
  using (exists (select 1 from core.proposition p where p.claim_id = claim.claim_id
                   and p.publication_state='PUBLISHED'));

-- Observations: published, and their proposition published. V0 and
-- quarantined rows ARE published — retained and displayed as inert, per
-- BES §10.1. Suppressing them would hide the register's own failures.
create policy anon_read on core.observation for select to anon, authenticated
  using (publication_state = 'PUBLISHED'
     and exists (select 1 from core.proposition p
                  where p.proposition_id = observation.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.source_document for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where o.document_id = source_document.document_id
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));

create policy anon_read on core.retrieval_receipt for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where o.receipt_id = retrieval_receipt.receipt_id
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));

create policy anon_read on core.quoted_span for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where (o.probative_span_id = quoted_span.span_id
                        or o.binding_span_id = quoted_span.span_id)
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));

-- Receipted absence is a published artifact: it is what licenses F and R.
create policy anon_read on core.search_receipt for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = search_receipt.proposition_id
                    and p.publication_state='PUBLISHED'));
create policy anon_read on core.search_log for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = search_log.proposition_id
                    and p.publication_state='PUBLISHED'));

-- The citation graph and lineages are the product; they publish.
create policy anon_read on core.lineage for select to anon, authenticated using (true);
create policy anon_read on core.lineage_membership for select to anon, authenticated
  using (exists (select 1 from core.source_document d
                  join core.observation o on o.document_id = d.document_id
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where d.document_id = lineage_membership.document_id
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));
create policy anon_read on core.document_citation for select to anon, authenticated
  using (retracted_at is null);
create policy anon_read on core.citogenesis_loop for select to anon, authenticated
  using (state = 'confirmed'
     and exists (select 1 from core.proposition p
                  where p.proposition_id = citogenesis_loop.proposition_id
                    and p.publication_state='PUBLISHED'));
create policy anon_read on core.witness for select to anon, authenticated using (true);
create policy anon_read on core.attestation for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where o.observation_id = attestation.observation_id
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));

-- Grades: PUBLISHED events only. An unpublished grade event is exactly the
-- adjudication state requirement 9 forbids leaking, and blind double-scores
-- must never be visible or the blind is not blind.
create policy anon_read on core.grade_event for select to anon, authenticated
  using (published_at is not null
     and not is_blind_double_score
     and exists (select 1 from core.proposition p
                  where p.proposition_id = grade_event.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.grade_event_observation for select to anon, authenticated
  using (exists (select 1 from core.grade_event g
                  where g.grade_event_id = grade_event_observation.grade_event_id
                    and g.published_at is not null and not g.is_blind_double_score));

create policy anon_read on core.proposition_current_grade for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = proposition_current_grade.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.refutation for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = refutation.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.alternative_disposition for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = alternative_disposition.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.clamp_event for select to anon, authenticated
  using (exists (select 1 from core.grade_event g
                  where g.grade_event_id = clamp_event.grade_event_id
                    and g.published_at is not null));

create policy anon_read on core.publication_log for select to anon, authenticated
  using (exists (select 1 from core.entity e where e.entity_id = publication_log.entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

-- ---------------------------------------------------------------------
-- 11.3 — Grants. SELECT only, and only on what a policy can protect.
-- No INSERT/UPDATE/DELETE grant exists for anon or authenticated anywhere.
-- ---------------------------------------------------------------------
do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables
            where schemaname in ('core','registry')
  loop
    -- grant SELECT only where an anon policy exists; RLS then filters rows.
    if exists (select 1 from pg_policies pp
                where pp.schemaname = t.schemaname and pp.tablename = t.tablename
                  and pp.policyname = 'anon_read') then
      execute format('grant select on %I.%I to anon, authenticated', t.schemaname, t.tablename);
    end if;
  end loop;
end $$;

grant all on all tables    in schema core, registry, ingest to service_role;
grant all on all sequences in schema core, registry, ingest to service_role;
grant usage on schema core, registry, ingest to service_role;

-- ---------------------------------------------------------------------
-- 11.4 — THE PUBLISHED PROJECTION.
-- All security_invoker, so RLS above is the single source of truth.
-- ---------------------------------------------------------------------

-- The proposition table that leads every entry page (BES §10.1).
-- "The composite does not exist; the decomposition is the product."
create view api.proposition_badge with (security_invoker = true) as
select
  p.proposition_id,
  p.entity_id,
  e.slug                        as entity_slug,
  e.canonical_name              as entity_name,
  p.class,
  p.statement_text,
  p.predicate_args,
  p.as_of_date,
  cg.grade,
  core.grade_rank(cg.grade)     as grade_rank,
  ge.awarded_band,
  ge.applied_caps,
  ge.ceiling,
  ge.at_ceiling,
  ge.limiting_condition,
  ge.marginal_flag,
  ge.silence_reading,
  ge.base_rate_reading,
  ge.reference_class,
  ge.null_state,
  p.null_code,
  nh.label                      as null_label,
  ge.refutation_state,
  ge.l_d2, ge.l_d3, ge.v_count, ge.u_count, ge.v0_count, ge.v_claim_count,
  ge.sci, ge.sci_numerator, ge.sci_denominator,
  -- the two bars, always (BES §10.2)
  ge.place_derived_weight,
  ge.claim_derived_weight,
  ge.condition_results,
  ge.transition_cause,
  ge.rubric_version,
  ge.scorer_model_id,
  ge.tier_version_id, ge.diagnosticity_version_id, ge.erp_version_id,
  cg.published_at               as graded_at,
  exists (select 1 from core.citogenesis_loop cl
           where cl.proposition_id = p.proposition_id and cl.state='confirmed') as citogenesis_flag
from core.proposition p
join core.entity e on e.entity_id = p.entity_id
join core.proposition_current_grade cg on cg.proposition_id = p.proposition_id
join core.grade_event ge on ge.grade_event_id = cg.grade_event_id
join registry.null_hypothesis nh on nh.null_code = p.null_code;

-- Every evidence row with its receipt, tier, provenance and diagnosticity,
-- INCLUDING V0 and quarantined rows shown as inert (BES §10.1).
create view api.evidence_row with (security_invoker = true) as
select
  o.observation_id,
  o.proposition_id,
  o.statement,
  o.observation_key,
  o.sign,
  o.magnitude,
  o.signed_weight,
  o.membership,
  o.exclusion_reason,
  o.diagnosticity_source,
  o.ea_expectedness, o.ea_alternative,
  o.scope, o.property_locus, o.subject_binding_pass, o.fact_key,
  o.gate_a_tier, o.gate_b_receipt, o.gate_c_instance,
  o.gate_d_on_its_face, o.gate_e_authority, o.gate_f_unsolicited,
  d.document_id, d.title, d.issuing_body, d.author_name, d.document_date, d.url,
  d.identifier, d.identifier_class,
  d.origin_tier, d.channel, d.causal_provenance, d.corpus_era,
  d.self_attesting, d.register_echo_quarantined,
  d.lineage_id,
  c.name  as corpus_name,
  c.host  as corpus_host,
  c.adversary_writable,
  c.egress_state,
  rr.receipt_state, rr.resolved_url, rr.http_status,
  encode(rr.sha256_of_bytes,'hex') as sha256,
  rr.retrieved_at, rr.mirror_only, rr.issuer_metadata_match, rr.content_drifted,
  qs.quoted_text, qs.span_start_offset, qs.span_end_offset, qs.quote_check,
  bs.quoted_text as binding_quote,
  sr.query_string as negative_search_query,
  sr.corpus_as_of as negative_search_corpus_date,
  sr.result_count as negative_search_result_count,
  ep.profile_key  as expected_record_profile,
  ep.x_level      as expected_record_level
from core.observation o
left join core.source_document d   on d.document_id = o.document_id
left join registry.corpus c        on c.corpus_id  = d.corpus_id
left join core.retrieval_receipt rr on rr.receipt_id = o.receipt_id
left join core.quoted_span qs      on qs.span_id = o.probative_span_id
left join core.quoted_span bs      on bs.span_id = o.binding_span_id
left join core.search_receipt sr   on sr.search_receipt_id = o.derived_from_search_receipt_id
left join registry.erp_profile ep  on ep.erp_profile_id = sr.erp_profile_id;

-- The alternative-hypothesis disposition table. IC failure #6: the single
-- most valuable artifact the register could show a skeptical reader.
create view api.alternative_table with (security_invoker = true) as
select ad.proposition_id, ad.null_code, nh.label, nh.description,
       ad.is_selected, ad.disposition, ad.reasoning, ad.excluding_observation_ids
  from core.alternative_disposition ad
  join registry.null_hypothesis nh using (null_code);

-- The claims register: E, F and R live here with their origin work, which
-- is the product. Nothing is deleted; refuted entries keep their refutations.
create view api.claims_register with (security_invoker = true) as
select p.proposition_id, p.entity_id, e.slug, e.canonical_name,
       p.class, p.statement_text, cg.grade, ge.limiting_condition,
       ge.silence_reading, ge.refutation_state,
       cl.claim_text,
       cl.first_appearance_date, cl.first_appearance_confidence,
       (select jsonb_agg(jsonb_build_object('state', rf.state, 'narrative', rf.narrative))
          from core.refutation rf
         where rf.proposition_id = p.proposition_id and rf.reversed_at is null) as refutations,
       exists (select 1 from core.citogenesis_loop x
                where x.proposition_id = p.proposition_id and x.state='confirmed') as citogenesis
  from core.proposition p
  join core.entity e on e.entity_id = p.entity_id
  join core.proposition_current_grade cg on cg.proposition_id = p.proposition_id
  join core.grade_event ge on ge.grade_event_id = cg.grade_event_id
  left join core.claim cl on cl.claim_id = p.claim_id
 where cg.grade in ('E','F','R','X');

-- Coverage and instrument honesty, published (tradeoff #7, fleet demand #0).
create view api.methodology_coverage with (security_invoker = true) as
select c.slug, c.name, c.beat, c.host, c.host_tier, c.content_tier,
       c.value, c.robots_posture, c.rate_limits,
       c.egress_state, c.egress_probed_at, c.adversary_writable
  from registry.corpus c;

create view api.expected_record_table with (security_invoker = true) as
select ep.profile_key, ep.description, ep.x_level, ep.authority_note,
       ep.silence_override, ep.destroying_event, ep.era_from, ep.era_to
  from registry.erp_profile ep;

grant select on api.proposition_badge, api.evidence_row, api.alternative_table,
                api.claims_register, api.methodology_coverage, api.expected_record_table
  to anon, authenticated;
grant select on api.map_feature, api.map_cluster to anon, authenticated;
grant execute on function api.map_viewport(double precision,double precision,double precision,double precision,integer,core.grade,core.typology[],text[]) to anon, authenticated;
grant execute on function api.map_tile(integer,integer,integer) to anon, authenticated;

-- Traversal functions the app calls directly. STABLE + security invoker, so
-- they see only what the caller may see.
grant execute on function core.trace_origin(uuid,integer)          to anon, authenticated;
grant execute on function core.claim_origin(uuid,integer)          to anon, authenticated;
grant execute on function core.independent_lineages(uuid,smallint) to anon, authenticated;
grant execute on function core.lineage_count(uuid,smallint)        to anon, authenticated;
grant execute on function core.grade_history(uuid)                 to anon, authenticated;
grant execute on function core.grade_at(uuid,timestamptz)          to anon, authenticated;
grant execute on function core.grade_rank(core.grade)              to anon, authenticated;
grant execute on function core.rank_grade(smallint)                to anon, authenticated;
grant execute on function core.render_geometry(uuid)               to anon, authenticated;

-- Explicitly NOT granted to anon: core.evaluate_proposition (it reads
-- unpublished rows to compute a provisional grade), core.record_grade,
-- api.refresh_map, and everything in ingest.
revoke all on function core.evaluate_proposition(uuid) from public, anon, authenticated;
revoke all on function core.record_grade(uuid,core.transition_cause,text,text,boolean,boolean)
  from public, anon, authenticated;
grant execute on function core.evaluate_proposition(uuid) to service_role;
grant execute on function core.record_grade(uuid,core.transition_cause,text,text,boolean,boolean)
  to service_role;
-- =====================================================================
-- SECTION 12 — SEED: the four curated tables, populated.
--
-- These are the versioned lookups that hold all the judgement. They are
-- asserted, not derived, and they are the new attack surface (tradeoff #3).
-- Every row is versioned so a bad version is identifiable and rollback-able,
-- and BES §12.5 re-derives them against resolved cases after the first 25
-- adjudications and every 50 A/R propositions thereafter.
-- =====================================================================

insert into registry.rubric_version (rubric_version, notes) values
  ('BES-0.2.0','Tiered Sufficiency with Signed Evidence. Supersedes WORKFLOW.md §1 (v0.1).');

insert into registry.table_version (table_name, version, issued_by, is_current) values
  ('tier','0.2.0','CURATOR',true),
  ('diagnosticity','0.2.0','CURATOR',true),
  ('erp','0.2.0','CURATOR',true),
  ('candidate_set','0.2.0','CURATOR',true),
  ('rubric','0.2.0','CURATOR',true);

insert into registry.country (country_code, name, register_scope) values
  ('US','United States','active'),
  ('GB','United Kingdom','planned'),
  ('DE','Germany','planned'),
  ('CH','Switzerland','planned'),
  ('RU','Russian Federation','planned');

-- ---------------------------------------------------------------------
-- The enumerated null set (BES §4.5). REFUTER selects the STRONGEST
-- SURVIVING alternative and states why the others are weaker.
-- ---------------------------------------------------------------------
insert into registry.null_hypothesis (null_code, label, description, is_fabrication_null, base_rate_note) values
 ('A01','no constructed object','There is no constructed object at this location',false,null),
 ('A02','commercial or industrial mine','Commercial or industrial mine, quarry, or cavern warehouse',false,
   'Tens of thousands of anthropogenic underground structures in CONUS; this is the dominant alternative for buried-rural candidates'),
 ('A03','transport tunnel','Highway, rail or transit tunnel',false,null),
 ('A04','water or sewer works','Water, sewer or flood-control works',false,null),
 ('A05','utility works','Utility vault, substation enclosure or pipeline works',false,null),
 ('A06','storage','Agricultural, cold or general storage',false,null),
 ('A07','data centre or exchange','Commercial data centre or telecom exchange, unhardened',false,null),
 ('A08','ordinary government building','Ordinary above-ground government building',false,null),
 ('A09','duplicate entity','Duplicate of an already-registered entity',false,null),
 ('A10','civil-defence designation only','Civil-defence shelter designation only',false,null),
 ('A11','fabricated or misattributed','Claim fabricated, misattributed or transposed',true,
   'MANDATORY co-null on any proposition whose positive support includes a T5 lineage; both scorings run and the LOWER grade publishes'),
 ('A12','other decommissioned typology','Decommissioned facility of a different, already-known typology',false,null);

-- ---------------------------------------------------------------------
-- Identifier grammars — VERIFIER's validators (fleet demand #1).
-- Patterns are anchored; "do not construct identifiers, enumerate them"
-- becomes a schema constraint rather than an instruction an agent may skip.
-- ---------------------------------------------------------------------
insert into registry.identifier_grammar
 (identifier_class, country_code, description, pattern, issuing_authority_host,
  resolver_url_template, faithful_mirror_hosts, issuer_metadata_fields, is_known_not_released) values
 ('CREST_ESDN','US','CIA CREST document number (ESDN)',
  '^CIA-RDP[0-9]{2}[A-Z]?-?[0-9]{5}[A-Z]?[0-9]{9}-[0-9]$','www.cia.gov',
  'https://www.cia.gov/readingroom/document/%s',
  '{archive.org}', '{title,release_date,document_number}', false),
 ('DTIC_AD','US','DTIC accession number','^AD[A-D]?[0-9]{6,7}$','apps.dtic.mil',
  'https://apps.dtic.mil/sti/citations/%s','{archive.org}','{title,report_date,performing_org}', false),
 ('DTIC_ADB','US','DTIC limited-distribution accession: KNOWN-TO-EXIST-NOT-RELEASED',
  '^ADB[0-9]{6,7}$','apps.dtic.mil','https://apps.dtic.mil/sti/citations/%s','{}','{title}', true),
 ('NARA_NAID','US','NARA National Archives Identifier','^[0-9]{1,9}$','catalog.archives.gov',
  'https://catalog.archives.gov/api/v2/records/search?naId=%s','{}','{title,recordGroup,levelOfDescription}', false),
 ('GAO_REPORT','US','GAO report number','^(GAO|NSIAD|B)-[0-9]{2,3}-[0-9]{1,5}[A-Z]*$','www.gao.gov',
  'https://www.gao.gov/products/%s','{}','{title,release_date}', false),
 ('FR_CITATION','US','Federal Register document number','^[0-9]{4}-[0-9]{5}$','www.federalregister.gov',
  'https://www.federalregister.gov/api/v1/documents/%s.json','{}','{title,publication_date,agencies}', false),
 ('GOVINFO_PKG','US','GovInfo package identifier','^[A-Z]{2,10}-[0-9]{4}(-[A-Za-z0-9\-]+)*$','api.govinfo.gov',
  'https://api.govinfo.gov/packages/%s/summary','{}','{title,dateIssued,collectionCode}', false),
 ('FCC_ASR','US','FCC Antenna Structure Registration number','^[0-9]{7}$','wireless2.fcc.gov',
  'https://wireless2.fcc.gov/UlsApp/AsrSearch/asrRegistration.jsp?regKey=%s','{}','{owner,latitude,longitude,height}', false),
 ('FCC_ULS','US','FCC ULS call sign','^[A-Z]{1,3}[0-9]{1,5}$','wireless2.fcc.gov',
  'https://wireless2.fcc.gov/UlsApp/UlsSearch/license.jsp?licKey=%s','{}','{licensee,radio_service,grant_date}', false),
 ('FPDS_PIID','US','FPDS procurement instrument identifier','^[A-Z0-9]{6,30}$','api.usaspending.gov',
  'https://api.usaspending.gov/api/v2/awards/%s/','{}','{recipient,awarding_agency,action_date}', false),
 ('FRUS_DOC','US','FRUS volume and document number','^frus[0-9]{4}-[0-9]{2}v[0-9]+d[0-9]+$','history.state.gov',
  'https://history.state.gov/historicaldocuments/%s','{github.com}','{volume,document_number,date}', false),
 ('USGS_QUAD','US','USGS HTMC quadrangle name plus year','^[A-Za-z .''\-]+_[A-Z]{2}_[0-9]{4}(_[0-9]+)?$',
  'prd-tnm.s3.amazonaws.com','https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/HistoricalTopo/PDF/%s.pdf',
  '{ngmdb.usgs.gov}','{map_name,state,date_on_map,scale}', false),
 ('COUNTY_PARCEL','US','County assessor parcel identifier (APN); grammar is per-county',
  '^[A-Za-z0-9\-\. ]{4,40}$','varies','%s','{}','{owner,legal_description,recorded_date}', false),
 ('MSHA_MINE_ID','US','MSHA mine identification number','^[0-9]{7}$','www.msha.gov',
  'https://www.msha.gov/data-and-reports/mine-data-retrieval-system?mineid=%s','{}','{operator,controller,mine_status}', false),
 ('AFHRA_IRIS','US','Air Force Historical Research Agency IRIS number','^[0-9]{5,7}$','airforcehistoryindex.org',
  'https://airforcehistoryindex.org/data/%s.html','{archive.org}','{title,unit,date_range}', false),
 ('DOI','US','Digital Object Identifier','^10\.[0-9]{4,9}/[-._;()/:A-Za-z0-9]+$','doi.org',
  'https://doi.org/%s','{}','{title,publisher,published}', false),
 ('IA_IDENTIFIER','US','Internet Archive item identifier','^[A-Za-z0-9._\-]{2,100}$','archive.org',
  'https://archive.org/metadata/%s','{}','{title,uploader,addeddate}', false);

-- ---------------------------------------------------------------------
-- EXPECTED-RECORD TABLE v0.2.0 (BES §6.3), seeded from the five W0 `gaps`
-- sections. Absence of a record is evidence ONLY where the presence of that
-- record would have been expected. For a classified facility, absent
-- records are the expected condition.
-- ---------------------------------------------------------------------
insert into registry.erp_profile
 (profile_key, country_code, description, x_level, authority_note, silence_override,
  destroying_event, counts_toward_sci, erp_version_id, reviewed_by)
select v.k, 'US', v.d, v.x::core.x_level, v.a, v.so::core.silence_reading, v.de,
       (v.x <> 'X0'), tv.table_version_id, 'CURATOR'
from (values
 ('milcon-jbook-appropriated','MILCON J-book line, appropriated agency, 1950-1990, unclassified','X3',null,null,null),
 ('milcon-classified-line','MILCON line marked Classified Project / Classified Location: existence of a line','X3',null,null,null),
 ('milcon-classified-scope','Same line, for scope and location','X0','the line establishes that money was appropriated somewhere and nothing else',null,null),
 ('milcon-nonappropriated','MILCON / appropriations, non-appropriated entity','X0','Federal Reserve, USPS, TVA, FDIC, Farm Credit',null,null),
 ('nip-mip-construction','NIP/MIP-funded construction, any era','X0','published only as topline aggregates; SAP construction invisible by design',null,null),
 ('frpp-executive','FRPP entry, executive-agency facility, post-1998','X2',null,null,null),
 ('frpp-nsec-withheld','FRPP entry, national-security-withheld asset class','X0','the best government-wide inventory is guaranteed to be missing exactly this class',null,null),
 ('dod-bsr','DoD Base Structure Report entry, acknowledged installation','X2',null,null,null),
 ('fpds-award','FPDS/USAspending award naming the site, post-2008','X1','descriptions sanitised and miscoded; place of performance is frequently the contracting office',null,null),
 ('nepa-eis','NEPA EIS filed with EPA, major federal action','X2',null,null,null),
 ('nepa-ea','NEPA EA for facility-scale construction','X1','no central index; most defence actions categorically excluded',null,null),
 ('nepa-classified','NEPA, classified action or categorical exclusion','X0',null,null,null),
 ('local-permit-federal','Local building permit, federal construction on federal land','X0','federal construction is exempt from local permitting',null,null),
 ('county-deed-any','County deed / assessor parcel record, any CONUS parcel, any era','X3','THE UNIVERSAL FLOOR',null,null),
 ('county-deed-fed-to-fed','County deed, federal-to-federal transfer or land withdrawal','X0','property moving between federal agencies typically generates no recorded deed',null,null),
 ('county-deed-predigital','County deed, pre-1975 in a county digitised only to the 1990s','X0',null,null,null),
 ('gsa-disposal','GSA disposal record, executive-agency real property','X2',null,null,null),
 ('fcc-commercial','FCC ASR/ULS registration, commercial emitter','X3',null,null,null),
 ('fcc-federal','FCC ASR/ULS registration, federal or covert emitter','X0','federal spectrum is NTIA/IRAC; GMF withheld — availability ANTI-correlates with the property being detected',null,null),
 ('nprc-personnel','NPRC personnel file, Army 1912-1960 or USAF 1947-1964','X0',null,'RECORD-DESTROYED','NPRC fire, 12 July 1973, 22 hours, ~16-18M Official Military Personnel Files, no duplicates, no microfilm, no index'),
 ('usgs-htmc','USGS HTMC quadrangle coverage, any CONUS coordinate','X3','186,061 sheets — a temporal-stack absence IS informative',null,null),
 ('usgs-suppression','USGS quad depiction where cartographic suppression is plausible','X1','the policy record of which sites were suppressed does not exist publicly',null,null),
 ('nrhp-sensitive','NRHP listing, restricted or sensitive feature','X0',null,null,null),
 ('3dep-remote-federal','3DEP lidar coverage, remote federal land','X1','acquisitions cost-shared with states; remote federal land systematically under-flown',null,null),
 ('chronam-post1963','Chronicling America coverage, local press after 1963','X0','free corpus is copyright-bounded at roughly 1963',null,null),
 ('govinfo-pre1994','Pre-1994 congressional material in GovInfo','X1','born-digital text starts ~103rd Congress; ARCHIVE-GAP',null,null),
 ('nara-textual','NARA textual holdings, RG 77 / 374 / 397','X1','~96% undigitised; the Catalog API can identify the boxes, it cannot deliver them; ARCHIVE-GAP',null,null),
 ('state-well-federal','State well-driller report, well on federal land','X0','wells on federal land are exempt from state permitting',null,null),
 ('epcra-tier2-federal','EPCRA Tier II, federal facility','X0',null,null,null),
 ('msha-post1970','MSHA record, underground mine post-1970','X3',null,null,null),
 ('msha-pre1970','MSHA record, underground mine pre-1970','X0',null,null,null),
 ('crest-still-classified','CREST/DTIC record, facility still classified or <25 years','X0','the 25-year rule makes this beat retrospective by construction',null,null),
 ('crest-declassified','CREST/DTIC record, facility declassified >25 years','X2',null,null,null),
 ('dtic-adb','DTIC ADB-prefix accession','KNOWN-NOT-RELEASED','a POSITIVE state, not an absence; auto-generates a FOIA worklist item',null,null),
 ('commercial-cover','Any documentary record, active facility under commercial cover','X0','this is what a good cover story is',null,null),
 ('spoil-volume','Spoil-volume signature in imagery, excavation >1e5 m3','X3',null,null,null),
 ('procurement-50m','Procurement trace for construction >$50M, appropriated agency','X3',null,null,null)
) as v(k,d,x,a,so,de)
cross join registry.table_version tv
where tv.table_name='erp' and tv.is_current;

-- ---------------------------------------------------------------------
-- DIAGNOSTICITY CATALOG v0.2.0 (BES §4.3).
-- The UNIVERSAL D0 list first: these are the signals shared by limestone
-- mines, highway tunnels, sewer works, cold-storage caverns, data centres
-- and large airports. Two hundred of them satisfy zero conditions above
-- band D. This list is the single thing that stops the register filling
-- with C-grade quarries (historian #5, IC #1).
-- ---------------------------------------------------------------------
insert into registry.diagnosticity_catalog
 (typology_profile, observation_key, observation_label, sign, magnitude,
  universal_d0, null_excluding, rationale, diag_version_id, reviewed_by)
select t.tp::core.typology, v.k, v.l, 'NEUTRAL'::core.evidence_sign, 0, true, false,
       'UNIVERSAL D0: the named null predicts this just as strongly. Contributes to no condition at any volume.',
       tv.table_version_id, 'CURATOR'
from (values
 ('adit-or-portal','Adit or portal existence'),
 ('spoil-pile','Spoil or muck pile'),
 ('ventilation-shaft','Ventilation shaft'),
 ('anomalous-road-grade','Anomalous road grade into terrain'),
 ('deep-well','Deep well'),
 ('rail-spur','Rail spur'),
 ('fenced-perimeter','Fenced perimeter'),
 ('large-excavation-volume','Large excavation volume'),
 ('generator','Generator'),
 ('fuel-tank','Fuel tank'),
 ('guard-shack','Guard shack'),
 ('cameras','Cameras'),
 ('controlled-access','Controlled access'),
 ('local-lore-something-under-there','"The locals say there is something under there"'),
 ('a-hill','A hill'),
 ('windowless-wall','A windowless wall'),
 ('basement','A basement')
) as v(k,l)
cross join (select unnest(enum_range(null::core.typology))::text as tp) t
cross join registry.table_version tv
where tv.table_name='diagnosticity' and tv.is_current;

-- BURIED-RURAL / MOUNTAIN: the discriminating rows.
insert into registry.diagnosticity_catalog
 (typology_profile, observation_key, observation_label, sign, magnitude,
  null_excluding, property_locus_default, rationale, diag_version_id, reviewed_by)
select 'military-hardened'::core.typology, v.k, v.l, v.s::core.evidence_sign, v.m,
       v.nx, v.pl::core.property_locus, coalesce(v.r,'catalog anchor, BES §4.3'), tv.table_version_id, 'CURATOR'
from (values
 ('substation-oversized','Dedicated substation whose capacity exceeds visible built footprint by >3x','SUPPORTS',1,false,'PLACE-PROPERTY','Mine and data-centre nulls can produce this, but less comfortably'),
 ('thermal-signature-unoccupied','Continuous thermal/lighting signature at an unoccupied-looking site','SUPPORTS',1,false,'PLACE-PROPERTY',null),
 ('redundant-utility-feeds','Multiple redundant utility feeds','SUPPORTS',1,false,'PLACE-PROPERTY',null),
 ('unjustified-helipad','Helipad with no medical or airfield justification','SUPPORTS',1,false,'PLACE-PROPERTY',null),
 ('continuous-restricted-airspace','Continuous restricted/prohibited airspace <3NM, surface to <5000ft AGL, non-flying using agency','SUPPORTS',2,true,'CLAIM-PROPERTY','Scheduled airspace is routine; CONTINUOUS airspace with a non-flying using agency is not producible by any mundane null'),
 ('htmc-editorial-blanking','HTMC editorial blanking: feature on edition N, absent on N+1, no demolition record','SUPPORTS',2,true,'CLAIM-PROPERTY',null),
 ('heat-rejection-disproportionate','Heat-rejection capacity grossly disproportionate to occupancy','SUPPORTS',2,false,'PLACE-PROPERTY',null),
 ('frpp-withheld-asset-gap','FRPP asset count materially below installation acreage','SUPPORTS',2,false,'CLAIM-PROPERTY','The withheld-asset gap, itself a citable absence'),
 ('msha-federal-controller','MSHA controller identity = federal entity or records-storage/data-centre operator','SUPPORTS',2,false,'CLAIM-PROPERTY',null),
 ('fuel-exceeds-runtime-norms','Fuel storage far exceeding generator run-time norms for the building class','SUPPORTS',2,false,'PLACE-PROPERTY',null),
 ('ntia-gmf-assignment','NTIA GMF assignment at the coordinate','SUPPORTS',2,true,'CLAIM-PROPERTY',null),
 ('longlines-corporate-lineage','AT&T Long Lines hardened-site lineage in corporate route/plant engineering records','SUPPORTS',3,true,'CLAIM-PROPERTY','Corporate engineering records, not enthusiast compilation'),
 ('afhra-unit-history','AFHRA unit history (IRIS number) describing the facility','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('catcode-in-real-property','Earth-covered-magazine or command-post CATCODE in a real-property record for the parcel','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('nepa-blast-specification','NEPA document specifying blast doors, blast valves, shielding or CBR filtration','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('psc-c1xx-ae-award','PSC C1xx architect-engineer design award for a hardened facility type at the coordinate with no subsequent public construction award','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('unit-cost-3x-ufc','Project unit cost >3x the UFC 3-701-01 pricing factor for its CATCODE','SUPPORTS',3,true,'CLAIM-PROPERTY',null),
 ('resolvable-named-witness','A resolvable named witness describing the facility','SUPPORTS',3,true,'CLAIM-PROPERTY','Resolvability gate AND attestation custody both required'),
 ('milstd-188-125-cited','MIL-STD-188-125-1/-2 (HEMP) cited in a design or procurement document naming the site','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('ufc-3-340-blast-design','UFC 3-340-01/-02 blast design for the named project','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('dd1391-hardening-scope','DD Form 1391 for the named installation with hardening scope','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('declassified-names-all-three','A declassified record naming facility + location + function','SUPPORTS',4,true,'CLAIM-PROPERTY','Documentary sufficiency: one conclusive primary record reaches A'),
 ('as-built-drawing','An as-built or engineering drawing','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('gsa-disposal-hardened','A GSA disposal record describing a hardened special facility','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('deed-recites-structure','A deed or court record reciting the structure','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 ('milcon-line-names-it','A MILCON line item naming it','SUPPORTS',4,true,'CLAIM-PROPERTY','§3.4 gate instance'),
 -- the negative cells: what makes a lease list COUNT AGAINST rather than merely fail to count for
 ('published-tenant-lease-list','Published tenant lease list','UNDERCUTS',3,false,'CLAIM-PROPERTY','E0/A3 — improbable under the hardened-federal hypothesis'),
 ('public-ticketed-tours','Operator-run public ticketed tours','UNDERCUTS',3,false,'CLAIM-PROPERTY','E0/A3'),
 ('msha-regulated-mine-permit','MSHA regulated-mine permit','UNDERCUTS',1,false,'PLACE-PROPERTY','E1/A3'),
 ('public-tenant-directory','Public tenant directory','UNDERCUTS',2,false,'CLAIM-PROPERTY',null),
 ('continuous-documented-commercial-occupancy','Continuous documented commercial occupancy','UNDERCUTS',3,false,'CLAIM-PROPERTY',null)
) as v(k,l,s,m,nx,pl,r)
cross join registry.table_version tv
where tv.table_name='diagnosticity' and tv.is_current;

-- URBAN / IN-BUILDING. The axis-inapplicability defect dissolves: no axes,
-- a different catalog. 33 Thomas Street's geospatial signature is setback,
-- structural loading, vent-stack morphology and floor-plate depth, not spoil.
insert into registry.diagnosticity_catalog
 (typology_profile, observation_key, observation_label, sign, magnitude,
  universal_d0, null_excluding, property_locus_default, rationale, diag_version_id, reviewed_by)
select 'urban-in-building'::core.typology, v.k, v.l, v.s::core.evidence_sign, v.m, v.d0, v.nx,
       v.pl::core.property_locus, coalesce(v.r,'catalog anchor, BES §4.3'), tv.table_version_id, 'CURATOR'
from (values
 ('windowless-envelope','Windowless envelope','NEUTRAL',0,true,false,'PLACE-PROPERTY',null),
 ('setback','Setback','NEUTRAL',0,true,false,'PLACE-PROPERTY',null),
 ('bollards','Bollards','NEUTRAL',0,true,false,'PLACE-PROPERTY',null),
 ('rooftop-generators','Rooftop generators','NEUTRAL',0,true,false,'PLACE-PROPERTY',null),
 ('no-leasable-floorplate','No leasable floor plate, no tenant directory, no retail frontage on a commercially zoned parcel','SUPPORTS',1,false,false,'PLACE-PROPERTY',null),
 ('benchmarking-above-class','Municipal benchmarking consumption above class norm','SUPPORTS',1,false,false,'PLACE-PROPERTY',null),
 ('floor-loading-200psf','Structural floor loading >200 psf on multiple floors in building-department filings','SUPPORTS',2,false,true,'CLAIM-PROPERTY',null),
 ('vent-stack-array','Roof vent-stack array disproportionate to stated occupancy','SUPPORTS',2,false,false,'PLACE-PROPERTY',null),
 ('meetme-room-emergency-power','Carrier-hotel meet-me room with emergency power disproportionate to tenants','SUPPORTS',2,false,false,'PLACE-PROPERTY',null),
 ('architect-record-hardening','The architect''s own record describing a hardening programme','SUPPORTS',3,false,true,'CLAIM-PROPERTY',null),
 ('corporate-literature-survivable','Corporate engineering literature naming the building as hardened or survivable','SUPPORTS',3,false,true,'CLAIM-PROPERTY',null),
 ('dedicated-feeder-agreement','Dedicated-feeder utility interconnection agreement','SUPPORTS',3,false,true,'CLAIM-PROPERTY',null),
 ('permit-valuation-anomaly','Permit valuation unit cost far above class norm','SUPPORTS',3,false,true,'CLAIM-PROPERTY',null)
) as v(k,l,s,m,d0,nx,pl,r)
cross join registry.table_version tv
where tv.table_name='diagnosticity' and tv.is_current;

-- ---------------------------------------------------------------------
-- Base-rate readings (BES §6.5). PUBLISHED beside the grade, NEVER in the
-- arithmetic. This is the historian's second number, in a form the register
-- can actually stand behind.
-- ---------------------------------------------------------------------
insert into registry.base_rate (proposition_class, reference_class, function_set, reading, published_note) values
 ('EXIST','RC1','n/a','COMMON',null),('EXIST','RC2','n/a','UNCOMMON',null),
 ('EXIST','RC3','n/a','COMMON',null),('EXIST','RC4','n/a','COMMON',null),
 ('EXIST','RC5','n/a','UNCOMMON',null),('EXIST','RC6','n/a','RARE',null),
 ('HARDEN','RC1','n/a','UNCOMMON',null),('HARDEN','RC2','n/a','RARE',null),
 ('HARDEN','RC3','n/a','VERY-RARE',null),('HARDEN','RC4','n/a','UNCOMMON',null),
 ('HARDEN','RC5','n/a','VERY-RARE',null),('HARDEN','RC6','n/a','VERY-RARE',null),
 ('CONTROL','RC1','n/a','COMMON',null),('CONTROL','RC2','n/a','UNCOMMON',null),
 ('CONTROL','RC3','n/a','VERY-RARE',null),('CONTROL','RC4','n/a','RARE',null),
 ('CONTROL','RC5','n/a','VERY-RARE',null),('CONTROL','RC6','n/a','RARE',null),
 ('FUNCTION','RC1','sensitive','RARE',
   'On the order of a few hundred genuinely hardened federal facilities in CONUS against tens of thousands of anthropogenic underground structures.'),
 ('FUNCTION','RC2','sensitive','VERY-RARE',null),('FUNCTION','RC3','sensitive','VERY-RARE',null),
 ('FUNCTION','RC4','sensitive','VERY-RARE',null),('FUNCTION','RC5','sensitive','VERY-RARE',null),
 ('FUNCTION','RC6','sensitive','VERY-RARE',null),
 ('FUNCTION','RC1','mundane','UNCOMMON',null),('FUNCTION','RC2','mundane','UNCOMMON',null),
 ('FUNCTION','RC3','mundane','UNCOMMON',null),('FUNCTION','RC4','mundane','UNCOMMON',null),
 ('FUNCTION','RC5','mundane','RARE',null),('FUNCTION','RC6','mundane','RARE',null);

-- ---------------------------------------------------------------------
-- Corpus registry. Seeded with the tier-collision rulings that the W0
-- output forced (BES §3.1). The full 158 rows load from the five registry
-- JSON files with a straight column mapping.
-- ---------------------------------------------------------------------
insert into registry.corpus
 (slug, name, beat, url, host, country_code, legacy_p_tier, host_tier, content_tier,
  default_channel, default_causal, adversary_writable, transparent_compiler, tier_trap,
  machine_generated_blocklist, value, tier_version_id, reviewed_by, notes)
select v.slug, v.name, v.beat, v.url, v.host, 'US', v.p, v.ht::core.origin_tier, v.ct::core.origin_tier,
       v.ch::core.channel, v.cp::core.causal_provenance, v.aw, v.tc, v.tt, v.bl, v.val,
       tv.table_version_id, 'CURATOR', v.note
from (values
 ('cia-crest','CIA CREST / FOIA Electronic Reading Room','federal-declassification','https://www.cia.gov/readingroom/','www.cia.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('cia-crest-ia','CIA Reading Room mirror, Internet Archive','federal-declassification','https://archive.org/details/cia-readingroom','archive.org','P2','T2','T1','FAITHFUL-MIRROR','UNSOLICITED',false,false,false,false,'critical','IA is a CHANNEL, not a tier: mirrored CREST is T1 content via FAITHFUL-MIRROR'),
 ('dtic','DTIC public technical reports','federal-declassification','https://apps.dtic.mil/sti/','apps.dtic.mil','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('nara-catalog','NARA National Archives Catalog API v2','federal-declassification','https://catalog.archives.gov/api/v2/','catalog.archives.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('govinfo','GovInfo API and Bulk Data Repository','money-property-procurement','https://api.govinfo.gov/','api.govinfo.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('frus','Foreign Relations of the United States, TEI XML','federal-declassification','https://github.com/HistoryAtState/frus','github.com','P1','T2','T1','FAITHFUL-MIRROR','UNSOLICITED',false,false,false,false,'high',null),
 ('nsarchive','National Security Archive, GWU','federal-declassification','https://nsarchive.gwu.edu/','nsarchive.gwu.edu','P2','T2','T2','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'critical','Transparent compiler: exposes its primaries such that they can be independently pulled'),
 ('blackvault','The Black Vault','federal-declassification','https://www.theblackvault.com/documentarchive/','www.theblackvault.com','P3','T3','T1','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'moderate','RATIFIED COLLISION RULING: T3 host delivering T1 content. Record both.'),
 ('governmentattic','governmentattic.org','federal-declassification','https://www.governmentattic.org/','www.governmentattic.org','P3','T3','T1','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'high','RATIFIED COLLISION RULING: T3 host delivering T1 content.'),
 ('globalsecurity','GlobalSecurity.org','local-record-and-fringe','https://www.globalsecurity.org/wmd/facility/','www.globalsecurity.org','P3','T4','T4','AGGREGATOR','UNSOLICITED',false,false,true,false,'critical','RATIFIED: T4, registered as a TIER TRAP and a HOP, never a terminus'),
 ('usgs-htmc','USGS Historical Topographic Map Collection','geospatial','https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/HistoricalTopo/','prd-tnm.s3.amazonaws.com','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('msha','MSHA Mine Data Retrieval System','geospatial','https://www.msha.gov/','www.msha.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'high',null),
 ('fcc-asr','FCC Antenna Structure Registration bulk','infrastructure','https://data.fcc.gov/download/pub/uls/complete/r_tower.zip','data.fcc.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('long-lines-net','long-lines.net AT&T Long Lines Places and Routes','infrastructure','https://www.long-lines.net/places-routes/','www.long-lines.net','P4','T4','T4','AGGREGATOR','UNSOLICITED',false,false,false,false,'critical',null),
 ('usaspending','USAspending.gov REST API v2','money-property-procurement','https://api.usaspending.gov/api/v2/','api.usaspending.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('frpp','GSA Federal Real Property Profile Public Data Set','money-property-procurement','https://www.gsa.gov/','www.gsa.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('epa-eis','EPA Environmental Impact Statement Database','money-property-procurement','https://cdxapps.epa.gov/cdx-enepa-II/public/action/eis/search','cdxapps.epa.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('chronam','Chronicling America','local-record-and-fringe','https://www.loc.gov/collections/chronicling-america/','www.loc.gov','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical',null),
 ('afhra-index','Air Force History Index / AFHRA','local-record-and-fringe','https://airforcehistoryindex.org/','airforcehistoryindex.org','P1','T1','T1','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical','An INDEX, not a corpus: indexes existence, not content'),
 ('subbrit','Subterranea Britannica','local-record-and-fringe','https://www.subbrit.org.uk/','www.subbrit.org.uk','P3','T3','T3','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'high','The methodological model'),
 ('ed-thelen','Ed Thelen Nike Missile Site','local-record-and-fringe','https://ed-thelen.org/','ed-thelen.org','P3','T3','T3','CURATED-ARCHIVE','UNSOLICITED',false,true,false,false,'critical',null),
 ('progressive-1976','Richard Pollock, The Mysterious Mountain, The Progressive, March 1976','local-record-and-fringe','https://www.progressive.org/','www.progressive.org','P3','T3','T3','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical','T3 publication resting on unnamed off-the-record officials: the canonical citogenesis case'),
 ('wapo-gup-1992','Ted Gup, The Ultimate Congressional Hideaway, Washington Post, 31 May 1992','local-record-and-fringe','https://www.washingtonpost.com/','www.washingtonpost.com','P2','T2','T2','ORIGIN-HOST','UNSOLICITED',false,false,false,false,'critical','The Greenbrier disclosure. Grade movement here is NEW-DISCLOSURE, not NEW-VERIFICATION.'),
 ('afu-newsletters','Archives for the Unexplained, digitised newsletter runs','local-record-and-fringe','https://archive.org/details/ufonewsletters','archive.org','P3','T2','T5','CURATED-ARCHIVE','UNSOLICITED',false,false,false,false,'high','A faithfully scanned T5 mimeographed newsletter in a T2 archive is a T5 DOCUMENT WITH HIGH RETRIEVAL INTEGRITY. Record both — this is what makes AFU usable for ORIGIN grading.'),
 ('wikimapia','Wikimapia crowd map','geospatial','http://wikimapia.org/api/','wikimapia.org','P4','T4','T4','ADVERSARY-WRITABLE','CROWD-EDITED',true,false,false,false,'moderate','Documented ingestion path into an adversary-writable free-text field. Leads only, never evidence.'),
 ('openstreetmap','OpenStreetMap','geospatial','https://openinframap.org/','openstreetmap.org','P4','T4','T4','ADVERSARY-WRITABLE','CROWD-EDITED',true,false,false,false,'high',null),
 ('abovetopsecret','AboveTopSecret forum','local-record-and-fringe','https://www.abovetopsecret.com/','www.abovetopsecret.com','P5','T5','T5','ADVERSARY-WRITABLE','SELF-PUBLISHED',true,false,false,false,'moderate',null),
 ('bibliotecapleyades','bibliotecapleyades.net aggregator','local-record-and-fringe','https://www.bibliotecapleyades.net/','www.bibliotecapleyades.net','P5','T5','T5','AGGREGATOR','SELF-PUBLISHED',false,false,false,false,'high','Pure aggregator node: opaque compiler, one terminus'),
 ('grokipedia','Grokipedia','local-record-and-fringe','https://grokipedia.com/','grokipedia.com','P5','T5','T5','AGGREGATOR','SELF-PUBLISHED',false,false,false,true,'low','Versioned public blocklist: T5 + POST-2022-UNATTRIBUTED by construction'),
 ('uapedia','uapedia.ai','local-record-and-fringe','https://uapedia.ai/','uapedia.ai','P5','T5','T5','AGGREGATOR','SELF-PUBLISHED',false,false,false,true,'low','Machine-generated corpus blocklist')
) as v(slug,name,beat,url,host,p,ht,ct,ch,cp,aw,tc,tt,bl,val,note)
cross join registry.table_version tv
where tv.table_name='tier' and tv.is_current;

-- Canonical search sets: which ERP profiles the SCI denominator counts,
-- per proposition class (BES §7.1).
insert into registry.canonical_search_set (proposition_class, country_code, erp_profile_id, required)
select c.cls::core.proposition_class, 'US', ep.erp_profile_id, true
from registry.erp_profile ep
join (values
  ('EXIST','usgs-htmc'),('EXIST','county-deed-any'),('EXIST','msha-post1970'),
  ('EXIST','3dep-remote-federal'),('EXIST','spoil-volume'),('EXIST','frpp-executive'),
  ('LOCATE','usgs-htmc'),('LOCATE','county-deed-any'),('LOCATE','usgs-suppression'),
  ('EXTENT','usgs-htmc'),('EXTENT','spoil-volume'),('EXTENT','nepa-eis'),
  ('CONTROL','frpp-executive'),('CONTROL','dod-bsr'),('CONTROL','gsa-disposal'),
  ('CONTROL','county-deed-any'),('CONTROL','fpds-award'),
  ('HARDEN','crest-declassified'),('HARDEN','nepa-eis'),('HARDEN','nepa-ea'),
  ('HARDEN','milcon-jbook-appropriated'),('HARDEN','procurement-50m'),
  ('FUNCTION','crest-declassified'),('FUNCTION','nepa-eis'),('FUNCTION','govinfo-pre1994'),
  ('FUNCTION','nara-textual'),('FUNCTION','milcon-jbook-appropriated'),
  ('FEATURE','nepa-eis'),('FEATURE','crest-declassified'),
  ('PROGRAM','govinfo-pre1994'),('PROGRAM','milcon-jbook-appropriated'),('PROGRAM','nara-textual'),
  ('ORIGIN','chronam-post1963'),('ORIGIN','usgs-htmc')
) as c(cls, key) on c.key = ep.profile_key;

insert into registry.scorer_model (scorer_model_id, model_family, vendor, role) values
 ('scorer-family-a-v1','family-a','vendor-a','ASSESSOR'),
 ('verifier-code-v1','deterministic-code','n/a','VERIFIER'),
 ('scorer-family-b-v1','family-b','vendor-b','REVIEWER');
-- =====================================================================
-- SECTION 13 — THE QUERIES THE APP ACTUALLY RUNS
--
-- Four of them are packaged as SECURITY INVOKER functions so the Next.js
-- app makes ONE round trip per page and RLS still governs every row. The
-- raw SQL each one wraps is written out underneath, because a register
-- whose own queries are opaque has no standing to demand transparency of
-- anyone else.
-- =====================================================================

-- ---------------------------------------------------------------------
-- QUERY 1 — MAP VIEWPORT.
-- api.map_viewport(w,s,e,n,zoom,...) and api.map_tile(z,x,y) in section 10.
-- The underlying shape, for reference:
--
--   select entity_id, slug, canonical_name, exist_grade, representation,
--          locate_precision, st_asgeojson(geom)
--     from api.map_feature
--    where geom && st_makeenvelope($1,$2,$3,$4,4326)
--      and exist_rank >= core.grade_rank('D')
--    limit 2000;
--
-- Index path: map_feature_gix (GiST on geom) then the rank filter. At z<=9
-- the query is served entirely from api.map_cluster, so a continental
-- viewport returns a few hundred pre-aggregated rows rather than the
-- register. Both objects are refreshed CONCURRENTLY by the ingest cron.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- QUERY 2 — CANDIDATE DETAIL.
-- The entry page leads with the PROPOSITION TABLE, then the
-- alternative-hypothesis disposition table, then the lineage graph, then
-- the evidence rows with receipts — including V0 and quarantined rows
-- shown as inert. The composite does not exist; the decomposition IS the
-- product (BES §10.1).
-- ---------------------------------------------------------------------
create or replace function api.candidate_detail(p_slug text)
returns jsonb
language sql stable security invoker as $$
  with ent as (
    select * from core.entity where slug = p_slug
  ),
  props as (
    select b.* from api.proposition_badge b join ent on ent.entity_id = b.entity_id
  )
  select jsonb_build_object(
    'entity', (select jsonb_build_object(
        'entity_id', e.entity_id, 'slug', e.slug, 'name', e.canonical_name,
        'entity_level', e.entity_level, 'country', e.country_code,
        'typology', e.typology_cached,
        'first_ingested_at', e.first_ingested_at,
        'note', 'A site is a container. It carries identity and geometry and nothing graded.')
      from ent e),

    -- N badges, never one.
    'propositions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'proposition_id', p.proposition_id,
        'class', p.class,
        'statement', p.statement_text,
        'as_of', p.as_of_date,
        'grade', p.grade,
        'awarded_band', p.awarded_band,
        'applied_caps', p.applied_caps,
        'ceiling', p.ceiling, 'at_ceiling', p.at_ceiling,
        'limiting_condition', p.limiting_condition,
        'marginal', p.marginal_flag,
        'silence_reading', p.silence_reading,
        'silence_prose', case p.silence_reading
          when 'UNINFORMATIVE' then 'No public record of this class would be expected for a facility of this type in this period under this authority. The absence is not evidence against.'
          when 'RECORD-DESTROYED' then 'The record class that would have carried this evidence no longer exists.'
          when 'UNSEARCHED' then 'The canonical corpora have not been searched. This is not a low grade; it is the absence of one.'
          else 'The expected record was searched for and not found, and its presence would have been expected.' end,
        'base_rate_reading', p.base_rate_reading,
        'reference_class', p.reference_class,
        'null_code', p.null_code, 'null_label', p.null_label, 'null_state', p.null_state,
        'refutation_state', p.refutation_state,
        'citogenesis', p.citogenesis_flag,
        'lineages_d2', p.l_d2, 'lineages_d3', p.l_d3,
        'v_count', p.v_count, 'u_count', p.u_count, 'v0_count', p.v0_count,
        'sci', p.sci, 'sci_numerator', p.sci_numerator, 'sci_denominator', p.sci_denominator,
        -- TWO BARS, ALWAYS: how much of this grade is the mountain?
        'bars', jsonb_build_object('place_derived', p.place_derived_weight,
                                   'claim_derived', p.claim_derived_weight),
        'conditions', p.condition_results,
        'versions', jsonb_build_object('rubric', p.rubric_version, 'scorer', p.scorer_model_id,
                                       'tier', p.tier_version_id,
                                       'diagnosticity', p.diagnosticity_version_id,
                                       'erp', p.erp_version_id),
        'graded_at', p.graded_at)
        order by array_position(
          array['EXIST','LOCATE','EXTENT','TYPOLOGY','CONTROL','HARDEN','FUNCTION',
                'FEATURE','STATUS','PROGRAM','IDENTITY','ORIGIN']::text[], p.class::text))
      from props p), '[]'::jsonb),

    -- The alternative-hypothesis disposition table.
    'alternatives', coalesce((
      select jsonb_agg(jsonb_build_object(
        'proposition_id', a.proposition_id, 'null_code', a.null_code,
        'label', a.label, 'selected', a.is_selected,
        'disposition', a.disposition, 'reasoning', a.reasoning))
      from api.alternative_table a where a.proposition_id in (select proposition_id from props)),
      '[]'::jsonb),

    'refutations', coalesce((
      select jsonb_agg(jsonb_build_object(
        'proposition_id', r.proposition_id, 'state', r.state,
        'narrative', r.narrative, 'asserted_at', r.asserted_at,
        'next_review_due', r.next_review_due, 'reversed_at', r.reversed_at))
      from core.refutation r where r.proposition_id in (select proposition_id from props)),
      '[]'::jsonb),

    -- Every evidence row, with receipts, tiers, causal provenance and
    -- diagnosticity, INCLUDING the inert ones and why they are inert.
    'evidence', coalesce((
      select jsonb_agg(jsonb_build_object(
        'observation_id', ev.observation_id,
        'proposition_id', ev.proposition_id,
        'statement', ev.statement,
        'sign', ev.sign, 'magnitude', ev.magnitude, 'signed_weight', ev.signed_weight,
        'membership', ev.membership, 'exclusion_reason', ev.exclusion_reason,
        'diagnosticity_source', ev.diagnosticity_source,
        'ea', case when ev.ea_expectedness is not null
                   then ev.ea_expectedness::text || '/' || ev.ea_alternative::text end,
        'scope', ev.scope, 'property_locus', ev.property_locus,
        'subject_binding_pass', ev.subject_binding_pass,
        'gate', jsonb_build_object('a_tier',ev.gate_a_tier,'b_receipt',ev.gate_b_receipt,
                                   'c_instance',ev.gate_c_instance,'d_on_its_face',ev.gate_d_on_its_face,
                                   'e_authority',ev.gate_e_authority,'f_unsolicited',ev.gate_f_unsolicited),
        'source', jsonb_build_object(
            'document_id', ev.document_id, 'title', ev.title,
            'issuing_body', ev.issuing_body, 'author', ev.author_name,
            'date', ev.document_date, 'url', ev.url,
            'identifier', ev.identifier, 'identifier_class', ev.identifier_class,
            'origin_tier', ev.origin_tier, 'channel', ev.channel,
            'causal_provenance', ev.causal_provenance, 'corpus_era', ev.corpus_era,
            'self_attesting', ev.self_attesting,
            'register_echo', ev.register_echo_quarantined,
            'corpus', ev.corpus_name, 'host', ev.corpus_host,
            'adversary_writable', ev.adversary_writable, 'egress_state', ev.egress_state,
            'lineage_id', ev.lineage_id),
        'receipt', jsonb_build_object(
            'state', ev.receipt_state, 'resolved_url', ev.resolved_url,
            'http_status', ev.http_status, 'sha256', ev.sha256,
            'retrieved_at', ev.retrieved_at, 'mirror_only', ev.mirror_only,
            'issuer_metadata_match', ev.issuer_metadata_match,
            'content_drifted', ev.content_drifted),
        'quote', jsonb_build_object('text', ev.quoted_text,
            'start', ev.span_start_offset, 'end', ev.span_end_offset,
            'quote_check', ev.quote_check, 'binding_quote', ev.binding_quote),
        'negative_search', case when ev.negative_search_query is not null then
            jsonb_build_object('query', ev.negative_search_query,
                               'corpus_as_of', ev.negative_search_corpus_date,
                               'result_count', ev.negative_search_result_count,
                               'erp_profile', ev.expected_record_profile,
                               'x_level', ev.expected_record_level) end)
        order by ev.membership, ev.magnitude desc)
      from api.evidence_row ev where ev.proposition_id in (select proposition_id from props)),
      '[]'::jsonb),

    -- Receipted absence, published: it is what licenses F and R.
    'negative_searches', coalesce((
      select jsonb_agg(jsonb_build_object(
        'query', sr.query_string, 'corpus_as_of', sr.corpus_as_of,
        'executed_at', sr.executed_at, 'result_count', sr.result_count,
        'outcome', sr.outcome, 'unsearched_reason', sr.unsearched_reason,
        'erp_profile', ep.profile_key, 'x_level', ep.x_level,
        'destroying_event', ep.destroying_event))
      from core.search_receipt sr
      left join registry.erp_profile ep using (erp_profile_id)
      where sr.proposition_id in (select proposition_id from props)), '[]'::jsonb),

    'geometry', (select jsonb_build_object(
        'representation', rg.representation, 'precision', rg.precision_level,
        'locate_grade', rg.locate_grade, 'uncertainty_radius_m', rg.uncertainty_radius_m,
        'suppression_reason', rg.suppression_reason,
        'geojson', st_asgeojson(rg.geom)::jsonb)
      from ent e cross join lateral core.render_geometry(e.entity_id) rg),

    'distinct_from', coalesce((
      select jsonb_agg(jsonb_build_object('entity_id', r.to_entity_id, 'name', o.canonical_name))
      from core.entity_relation r join core.entity o on o.entity_id = r.to_entity_id
      join ent on ent.entity_id = r.from_entity_id
      where r.kind = 'DISTINCT-FROM' and r.retracted_at is null), '[]'::jsonb)
  )
$$;

-- ---------------------------------------------------------------------
-- QUERY 3 — LINEAGE AND ORIGIN TRACE.
-- "Show me every assertion about this site, who said it, when, who they got
-- it from, and what it argues for or against."
-- The recursion is cycle-safe in two independent ways; see core.trace_origin.
-- ---------------------------------------------------------------------
create or replace function api.lineage_trace(p_proposition_id uuid)
returns jsonb
language sql stable security invoker as $$
  select jsonb_build_object(
    'proposition_id', p_proposition_id,

    -- The independence answer. NOT a COUNT(*): a graph property computed
    -- after fact-key merge, model-family collapse and component collapse.
    'independent_lineages', jsonb_build_object(
      'at_d2', (select count(*) from core.independent_lineages(p_proposition_id, 2::smallint)),
      'at_d3', (select count(*) from core.independent_lineages(p_proposition_id, 3::smallint)),
      'detail', coalesce((select jsonb_agg(jsonb_build_object(
          'lineage_key', il.lineage_key, 'kind', il.lineage_kind,
          'best_magnitude', il.best_magnitude, 'observations', il.observation_count,
          'representative', il.representative_title, 'tier', il.origin_tier))
        from core.independent_lineages(p_proposition_id, 2::smallint) il), '[]'::jsonb),
      'note', 'A claim on 400 websites is not 400 sources. Copies, paraphrase, machine regeneration and replication collapse to the component they came from; agents sharing a base model collapse to one.'),

    -- The graph itself, for rendering.
    'nodes', coalesce((select jsonb_agg(distinct jsonb_build_object(
        'document_id', d.document_id, 'title', d.title, 'tier', d.origin_tier,
        'date', d.document_date, 'first_observed', d.first_observed_date,
        'channel', d.channel, 'causal_provenance', d.causal_provenance,
        'corpus_era', d.corpus_era, 'self_attesting', d.self_attesting))
      from core.observation o join core.source_document d on d.document_id = o.document_id
      where o.proposition_id = p_proposition_id), '[]'::jsonb),

    'edges', coalesce((select jsonb_agg(jsonb_build_object(
        'from', dc.citing_document_id, 'to', dc.cited_document_id,
        'kind', dc.edge_kind, 'detection', dc.detection_method,
        'similarity', dc.similarity,
        'counterfactual', dc.counterfactual_verdict,
        'collapses_lineage', dc.collapses_lineage,
        'quorum_disagreement', dc.quorum_disagreement))
      from core.document_citation dc
      where dc.retracted_at is null
        and (dc.citing_document_id in (select document_id from core.observation
                                        where proposition_id = p_proposition_id)
          or dc.cited_document_id in (select document_id from core.observation
                                        where proposition_id = p_proposition_id))),
      '[]'::jsonb),

    -- Backward trace to the earliest traceable appearance, per seed.
    'origin_trace', coalesce((select jsonb_agg(jsonb_build_object(
        'seed', seeds.document_id, 'depth', t.depth,
        'document_id', t.document_id, 'title', t.title, 'tier', t.origin_tier,
        'date', t.document_date, 'first_observed', t.first_observed_date,
        'edge_kind', t.edge_kind, 'path', t.path,
        'is_cycle', t.is_cycle, 'is_terminus', t.is_terminus)
        order by t.depth)
      from (select distinct document_id from core.observation
             where proposition_id = p_proposition_id and document_id is not null) seeds
      cross join lateral core.trace_origin(seeds.document_id, 24) t), '[]'::jsonb),

    'citogenesis', coalesce((select jsonb_agg(jsonb_build_object(
        'state', cl.state, 'laundering_document_id', cl.laundering_document_id,
        't5_root', cl.t5_root_document_id, 'path', cl.loop_path,
        'narrative', cl.narrative))
      from core.citogenesis_loop cl where cl.proposition_id = p_proposition_id), '[]'::jsonb),

    'attestations', coalesce((select jsonb_agg(jsonb_build_object(
        'witness', w.display_name, 'resolvable', w.resolvable,
        'resolving_record_kind', w.resolving_record_kind,
        'custody', a.custody,
        'lineage_terminus_is', 'the asserting document, never the quoted person'))
      from core.attestation a
      join core.witness w on w.witness_id = a.witness_id
      join core.observation o on o.observation_id = a.observation_id
      where o.proposition_id = p_proposition_id), '[]'::jsonb)
  )
$$;

-- ---------------------------------------------------------------------
-- QUERY 4 — GRADE HISTORY RECONSTRUCTION.
-- Every re-grade is versioned, so a candidate's confidence history is
-- itself visible. Disclosure-driven movement renders visually distinct from
-- evidence-driven movement, and instrument drift is suppressed entirely
-- from the public chart (BES §11.2).
-- ---------------------------------------------------------------------
create or replace function api.grade_history(p_proposition_id uuid)
returns jsonb
language sql stable security invoker as $$
  select jsonb_build_object(
    'proposition_id', p_proposition_id,
    'series', coalesce((select jsonb_agg(jsonb_build_object(
        'seq', h.seq, 'grade', h.grade, 'previous_grade', h.previous_grade,
        'direction', h.direction,
        'cause', h.transition_cause,
        'suppress_from_public_chart', h.suppress_from_public_chart,
        'annotation', h.disclosure_annotation,
        'published_at', h.published_at,
        'observations_added', h.observations_added,
        'observations_removed', h.observations_removed,
        'limiting_condition', h.limiting_condition) order by h.seq)
      from core.grade_history(p_proposition_id) h), '[]'::jsonb),

    -- What moved it: the exact rows that entered or left between events.
    'movement', coalesce((select jsonb_agg(jsonb_build_object(
        'seq', ge.seq, 'grade', ge.grade, 'cause', ge.transition_cause,
        'evidence_state_hash', encode(ge.evidence_state_hash,'hex'),
        'entered', (select jsonb_agg(jsonb_build_object(
              'observation_id', geo.observation_id,
              'statement', o.statement, 'sign', o.sign, 'magnitude', o.magnitude,
              'source', d.title, 'tier', d.origin_tier))
            from core.grade_event_observation geo
            join core.observation o on o.observation_id = geo.observation_id
            left join core.source_document d on d.document_id = o.document_id
            where geo.grade_event_id = ge.grade_event_id
              and (ge.supersedes_id is null or not exists (
                    select 1 from core.grade_event_observation prev
                     where prev.grade_event_id = ge.supersedes_id
                       and prev.observation_id = geo.observation_id))))
        order by ge.seq)
      from core.grade_event ge
      where ge.proposition_id = p_proposition_id
        and ge.published_at is not null and not ge.is_blind_double_score), '[]'::jsonb)
  )
$$;

-- Point-in-time reconstruction: "what did the register say on this date?"
-- The Greenbrier regression test is exactly this call at 1991-12-31 and
-- 1992-12-31, and the pair must show cause = NEW-DISCLOSURE.
create or replace function api.grade_as_of(p_proposition_id uuid, p_at timestamptz)
returns jsonb
language sql stable security invoker as $$
  select case when g.grade_event_id is null then null else jsonb_build_object(
    'grade', g.grade, 'awarded_band', g.awarded_band, 'applied_caps', g.applied_caps,
    'limiting_condition', g.limiting_condition, 'null_state', g.null_state,
    'silence_reading', g.silence_reading, 'base_rate_reading', g.base_rate_reading,
    'conditions', g.condition_results,
    'lineages_d2', g.l_d2, 'lineages_d3', g.l_d3,
    'sci', g.sci, 'published_at', g.published_at,
    'rubric_version', g.rubric_version, 'scorer_model_id', g.scorer_model_id,
    'table_versions', jsonb_build_object('tier', g.tier_version_id,
        'diagnosticity', g.diagnosticity_version_id, 'erp', g.erp_version_id),
    'evidence_state_hash', encode(g.evidence_state_hash,'hex')) end
  from core.grade_at(p_proposition_id, p_at) g
$$;

-- ---------------------------------------------------------------------
-- QUERY 5 — THE CLAIMS REGISTER. E, F, R and X entries with their origin
-- work. This is the product, not the leftovers.
-- ---------------------------------------------------------------------
create or replace function api.claims_register_page(
  p_grades core.grade[] default array['E','F','R']::core.grade[],
  p_limit integer default 100, p_offset integer default 0)
returns jsonb
language sql stable security invoker as $$
  select coalesce(jsonb_agg(to_jsonb(t) order by t.grade, t.canonical_name), '[]'::jsonb)
  from (select * from api.claims_register cr
         where cr.grade = any(p_grades)
         order by cr.grade, cr.canonical_name
         limit p_limit offset p_offset) t
$$;

grant execute on function api.candidate_detail(text)              to anon, authenticated;
grant execute on function api.lineage_trace(uuid)                 to anon, authenticated;
grant execute on function api.grade_history(uuid)                 to anon, authenticated;
grant execute on function api.grade_as_of(uuid, timestamptz)      to anon, authenticated;
grant execute on function api.claims_register_page(core.grade[], integer, integer)
  to anon, authenticated;

-- ---------------------------------------------------------------------
-- QUERY 6 — the register's own telemetry, published.
-- A register that states its own measured fabrication rate is more credible
-- than one that implies none.
-- ---------------------------------------------------------------------
create or replace view api.register_telemetry with (security_invoker = true) as
select
  (select count(*) from core.entity where publication_state='PUBLISHED' and not is_canary) as entities_published,
  (select count(*) from core.proposition_current_grade)                                    as propositions_graded,
  (select jsonb_object_agg(grade, n) from (
      select grade, count(*) n from core.proposition_current_grade group by grade) s)      as band_occupancy,
  (select round(100.0*count(*) filter (where grade in ('X','D'))/nullif(count(*),0),1)
     from core.proposition_current_grade)                                                  as pct_modal_bands,
  (select round(100.0*count(*) filter (where grade='C')/nullif(count(*),0),1)
     from core.proposition_current_grade)                                                  as pct_c_band,
  (select count(*) from registry.corpus where egress_state='BLOCKED')                      as corpora_unreachable,
  (select count(*) from registry.corpus)                                                   as corpora_registered,
  'The modal register entry should be X or D. Most candidates are undifferentiated holes; a healthy register says so.'::text as band_note;

grant select on api.register_telemetry to anon, authenticated;
