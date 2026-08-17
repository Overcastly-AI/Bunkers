-- =====================================================================
-- BUNKERS REGISTER — FINAL SCHEMA
-- PostgreSQL 15+ / PostGIS 3.x (Supabase).  Implements BES v0.2
-- Defects present in BOTH were repaired here and are marked  [FIX-BOTH].
-- =====================================================================

create extension if not exists postgis;
create extension if not exists pg_trgm;
create extension if not exists btree_gist;

-- ---------------------------------------------------------------------
-- Schemas. PostgREST is pointed at `api` ONLY; core/ingest/registry have no
create schema if not exists registry;   -- reviewed-write curated tables
create schema if not exists core;       -- canonical evidence, grades
create schema if not exists ingest;     -- acquisition + adjudication plumbing
create schema if not exists api;        -- the published projection

comment on schema core   is 'Canonical evidence graph. Never exposed to PostgREST.';
comment on schema ingest is 'Acquisition and adjudication plumbing. No anon policy on any table: default-deny.';
comment on schema api    is 'Published projection. The only schema PostgREST serves.';

-- Roles: create if absent so the file runs on a bare cluster as well as on
-- Supabase, where these already exist.
do $$
begin
  if not exists (select 1 from pg_roles where rolname='anon') then
    create role anon nologin noinherit; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then
    create role authenticated nologin noinherit; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then
    create role service_role nologin noinherit bypassrls; end if;
end $$;

revoke all on schema core, ingest, registry from public;
grant usage on schema api to anon, authenticated, service_role;
grant usage on schema core, registry to anon, authenticated;  -- security_invoker views
grant usage on schema core, registry, ingest to service_role;

-- =====================================================================
-- 1. CLOSED VOCABULARIES.  An agent may not invent a value in any of these.
-- =====================================================================

create type core.proposition_class as enum (
  'EXIST','EXTENT','HARDEN','CONTROL','FUNCTION','STATUS','LOCATE',
  'FEATURE','PROGRAM','IDENTITY','ORIGIN','TYPOLOGY');

-- A..F is a ladder. R and X are NOT low grades — they are different
-- epistemic objects (BES §7.2, §8) and are deliberately unranked.
create type core.grade as enum ('A','B','C','D','E','F','R','X');

create type core.refutation_state as enum ('R0','R1','R2','R3');
create type core.null_state as enum
  ('UNTESTED','SURVIVING','DOMINANT','INSUFFICIENT','EXCLUDED');
create type core.silence_reading as enum
  ('INFORMATIVE','UNINFORMATIVE','RECORD-DESTROYED','UNSEARCHED');
create type core.base_rate_reading as enum ('COMMON','UNCOMMON','RARE','VERY-RARE');
create type core.reference_class as enum ('RC1','RC2','RC3','RC4','RC5','RC6');

create type core.origin_tier as enum ('T1','T2','T3','T4','T5','PENDING');
create type core.channel as enum
  ('ORIGIN-HOST','FAITHFUL-MIRROR','CURATED-ARCHIVE','AGGREGATOR','ADVERSARY-WRITABLE');
create type core.causal_provenance as enum
  ('UNSOLICITED','SOLICITED-3P','SOLICITED-BY-CLAIMANT','SELF-PUBLISHED','CROWD-EDITED');
create type core.corpus_era as enum
  ('PRE-2022','POST-2022-ATTRIBUTED','POST-2022-UNATTRIBUTED','UNKNOWN');

create type core.receipt_state as enum ('VERIFIED','UNRESOLVED','DEAD','NEGATIVE');
create type core.evidence_sign as enum ('SUPPORTS','UNDERCUTS','NEUTRAL');
create type core.evidence_scope as enum ('INSTANCE','CLASS','ADJACENT');
create type core.property_locus as enum ('CLAIM-PROPERTY','PLACE-PROPERTY');
create type core.diagnosticity_source as enum ('CATALOG','GATE','MATRIX','DEFAULT');
create type core.evidence_membership as enum ('V','U','INERT','V0');

create type core.entity_level as enum ('program','site','structure');
create type core.entity_relation_kind as enum
  ('PARENT-OF','PART-OF','ADJACENT-TO','ALIAS-OF','MERGED-INTO','DISTINCT-FROM',
   'SUCCESSOR-OF','CONFUSED-WITH');

-- [FIX-BOTH] `place_name_only` is new. Proposal A forced a claimed-only entry
-- to carry an uncertainty POLYGON; proposal B forced it to carry a POINT.
create type core.locate_precision as enum (
  'surveyed',          -- instrument or control-point match
  'approximate_1km',
  'approximate_10km',
  'regional',          -- an explicit uncertainty polygon
  'admin_area',        -- resolved only to a county/state polygon
  'claimed_only',      -- a coordinate was ASSERTED by a source; never a pin
  'place_name_only',   -- a place NAME was claimed; no coordinate exists at all
  'non_located');      -- documented; coordinates genuinely unknown

create type core.geometry_representation as enum
  ('point','uncertainty_circle','region_polygon','admin_polygon','none');

create type core.status_value as enum (
  'active','standby','decommissioned','converted','sealed','demolished',
  'proposed','studied','cancelled','never-built','unknown');

create type core.typology as enum (
  'unknown-anomaly','cog-coop','military-hardened','missile-silo',
  'civil-defense-shelter','relay-comms','archive-storage','corporate-data',
  'private-shelter','research','mine-conversion','urban-in-building');

create type core.transition_cause as enum (
  'NEW-DISCLOSURE','NEW-SEARCH','NEW-VERIFICATION','RE-ANALYSIS','REFUTATION',
  'STATUS-CHANGE','CANDIDATE-SET-CHANGE','SCORER-CHANGE','TABLE-VERSION-CHANGE',
  'RESCORE-NOISE','REGISTER-ECHO','MERGE','SPLIT','CLAMP','INITIAL');

create type core.publication_state as enum ('INTERNAL','PUBLISHED','WITHDRAWN');
create type core.x_level as enum ('X0','X1','X2','X3','KNOWN-NOT-RELEASED');
create type core.ea_expectedness as enum ('E0','E1','E2','E3');
create type core.ea_alternative   as enum ('A0','A1','A2','A3');
create type core.search_outcome   as enum ('POSITIVE','NEGATIVE','UNSEARCHED','ERROR');

create domain core.sha256 as bytea check (value is null or octet_length(value) = 32);
create domain core.iso_country as char(2) check (value ~ '^[A-Z]{2}$');

-- =====================================================================
-- 2. IMMUTABLE HELPERS — used in constraints, generated columns, indexes.
-- =====================================================================

create or replace function core.grade_rank(g core.grade)
returns smallint language sql immutable parallel safe as $$
  select case g when 'A' then 7 when 'B' then 6 when 'C' then 5
                when 'D' then 4 when 'E' then 3 when 'F' then 2
                else null end::smallint
$$;

create or replace function core.rank_grade(r smallint)
returns core.grade language sql immutable parallel safe as $$
  select case r when 7 then 'A' when 6 then 'B' when 5 then 'C'
                when 4 then 'D' when 3 then 'E' when 2 then 'F'
                else null end::core.grade
$$;

-- min() over the ladder. R and X are unranked and dominate: they are not
-- points on the scale, so they are not clampable and not cappable.
create or replace function core.grade_min(a core.grade, b core.grade)
returns core.grade language sql immutable parallel safe as $$
  select case
    when a is null then b
    when b is null then a
    when core.grade_rank(a) is null then a
    when core.grade_rank(b) is null then b
    else core.rank_grade(least(core.grade_rank(a), core.grade_rank(b)))
  end
$$;

-- Deterministic normalisation for alias matching (subject binding, BES §2.3)
-- and fact_key canonicalisation. Code, not judgement. `unaccent` is not
-- guaranteed installed, so the Latin-1 range is folded explicitly.
create or replace function core.norm_token(t text)
returns text language sql immutable parallel safe as $$
  select nullif(btrim(regexp_replace(
           lower(translate(t,
             'ÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝàáâãäåçèéêëìíîïñòóôõöùúûüýÿ',
             'AAAAAACEEEEIIIINOOOOOUUUUYaaaaaaceeeeiiiinooooouuuuyy')),
           '[^a-z0-9]+',' ','g')), '')
$$;

-- The E/A fallback matrix (BES §4.4). Ceiling D3 by construction: D4 is
-- unreachable by inference and requires the §3.4 gate. The firewall is
create or replace function core.ea_matrix(e core.ea_expectedness, a core.ea_alternative)
returns table (sign core.evidence_sign, magnitude smallint)
language sql immutable parallel safe as $$
  select m.s::core.evidence_sign, m.mag::smallint from (values
    ('E3','A3','NEUTRAL',0),('E3','A2','NEUTRAL',0),('E3','A1','SUPPORTS',1),('E3','A0','SUPPORTS',3),
    ('E2','A3','NEUTRAL',0),('E2','A2','NEUTRAL',0),('E2','A1','SUPPORTS',1),('E2','A0','SUPPORTS',3),
    ('E1','A3','UNDERCUTS',1),('E1','A2','UNDERCUTS',1),('E1','A1','NEUTRAL',0),('E1','A0','SUPPORTS',2),
    ('E0','A3','UNDERCUTS',3),('E0','A2','UNDERCUTS',3),('E0','A1','UNDERCUTS',2),('E0','A0','NEUTRAL',0)
  ) as m(ee,aa,s,mag) where m.ee = e::text and m.aa = a::text
$$;

create or replace function core.x_level_magnitude(x core.x_level)
returns smallint language sql immutable parallel safe as $$
  select case x when 'X3' then 3 when 'X2' then 2 when 'X1' then 1 else 0 end::smallint
$$;

-- Traversal budgets, in one place so an operator can tune them without
-- editing five functions. See core.trace_origin for why they exist.
create or replace function core.traversal_node_budget() returns integer
language sql immutable parallel safe as $$ select 20000 $$;

-- =====================================================================
-- 3. REGISTRY — the curated, versioned, reviewed-write tables.
-- BES Part 12.1: every quantity in the model is a receipt from deterministic
-- =====================================================================

create table registry.table_version (
  table_version_id  bigint generated always as identity primary key,
  table_name        text not null check (table_name in
                      ('tier','diagnosticity','erp','candidate_set','rubric','base_rate')),
  version           text not null,
  issued_at         timestamptz not null default now(),
  issued_by         text not null,
  supersedes_id     bigint references registry.table_version(table_version_id),
  rederivation_note text,          -- BES §12.5
  is_current        boolean not null default false,
  unique (table_name, version)
);
create unique index table_version_one_current
  on registry.table_version(table_name) where is_current;

-- Country-agnostic base (ratified decision §5.1): country and administrative
-- geography are ROWS, never columns. A UK register is new rows, not a migration.
create table registry.country (
  country_code   core.iso_country primary key,
  name           text not null,
  register_scope text not null default 'planned'
                   check (register_scope in ('active','planned','out-of-scope'))
);

create table registry.admin_area (
  admin_area_id bigint generated always as identity primary key,
  country_code  core.iso_country not null references registry.country(country_code),
  level         smallint not null check (level between 1 and 3),
  code          text not null,
  name          text not null,
  parent_id     bigint references registry.admin_area(admin_area_id),
  geom          geometry(MultiPolygon,4326),
  centroid      geometry(Point,4326),
  unique (country_code, level, code)
);
create index admin_area_geom_gix on registry.admin_area using gist (geom);

-- ---------------------------------------------------------------------
-- TABLE 1 — the source registry / tier ladder (BES §3.1).
create table registry.corpus (
  corpus_id      bigint generated always as identity primary key,
  slug           text not null unique,
  name           text not null,
  beat           text not null,
  url            text not null,
  host           text not null,
  country_code   core.iso_country references registry.country(country_code),

  -- carried verbatim from the five W0 registry JSON files
  holdings       text,
  legacy_p_tier  text check (legacy_p_tier in ('P1','P2','P3','P4','P5')),
  access_method  text,
  format         text,
  value          text check (value in ('critical','high','moderate','low')),
  rate_limits    text,
  robots_posture text,
  search_technique text,
  notes          text,

  host_tier      core.origin_tier not null default 'PENDING',
  content_tier   core.origin_tier not null default 'PENDING',
  default_channel core.channel not null default 'ORIGIN-HOST',
  default_causal core.causal_provenance not null default 'UNSOLICITED',
  adversary_writable  boolean not null default false,
  transparent_compiler boolean not null default false,  -- BES §5.1.3 conduit
  tier_trap      boolean not null default false,        -- a hop, never a terminus
  machine_generated_blocklist boolean not null default false,

  -- degraded-verification mode (BES §2.6): per-host egress is probed on a
  -- schedule and published. Three of the five W0 registries reported .gov/.mil
  -- egress blocked, so this is an operational precondition, not a footnote.
  egress_state   text not null default 'UNPROBED'
                   check (egress_state in ('REACHABLE','BLOCKED','THROTTLED','UNPROBED')),
  egress_probed_at timestamptz,
  faithful_mirror_of bigint references registry.corpus(corpus_id),

  tier_version_id bigint not null references registry.table_version(table_version_id),
  reviewed_by    text not null,
  reviewed_at    timestamptz not null default now(),

  constraint corpus_blocklist_is_t5
    check (not machine_generated_blocklist or content_tier = 'T5'),
  -- An anonymously writable host cannot deliver content above T4 as itself.
  constraint corpus_adversary_writable_tier
    check (not adversary_writable or content_tier in ('T4','T5','PENDING'))
);
create index corpus_host_idx on registry.corpus(host);
create index corpus_beat_idx on registry.corpus(beat);

create table registry.egress_probe (
  probe_id    bigint generated always as identity primary key,
  corpus_id   bigint not null references registry.corpus(corpus_id),
  probed_at   timestamptz not null default now(),
  http_status integer,
  reachable   boolean not null,
  latency_ms  integer,
  note        text
);
create index egress_probe_corpus_idx on registry.egress_probe(corpus_id, probed_at desc);

-- VERIFIER's validators. "Do not construct identifiers; enumerate them"
-- becomes a stored grammar, not a note in a prompt.
create table registry.identifier_grammar (
  identifier_class  text primary key,
  country_code      core.iso_country references registry.country(country_code),
  description       text not null,
  pattern           text not null,               -- anchored POSIX regex
  issuing_authority_host text not null,
  resolver_url_template  text not null,
  faithful_mirror_hosts  text[] not null default '{}',
  issuer_metadata_fields text[] not null default '{}',
  is_known_not_released  boolean not null default false,  -- DTIC ADB prefix
  notes             text
);

-- ---------------------------------------------------------------------
-- TABLE 2 — the diagnosticity catalog (BES §4.3) and the null set (§4.5).
-- ---------------------------------------------------------------------
create table registry.null_hypothesis (
  null_code   char(3) primary key,               -- A01..A12, extensible
  label       text not null,
  description text not null,
  is_fabrication_null boolean not null default false,   -- A11
  base_rate_note text
);

create table registry.diagnosticity_catalog (
  catalog_id       bigint generated always as identity primary key,
  typology_profile core.typology not null,
  observation_key  text not null,
  observation_label text not null,
  null_code        char(3) references registry.null_hypothesis(null_code), -- null = any
  sign             core.evidence_sign not null default 'SUPPORTS',
  magnitude        smallint not null check (magnitude between 0 and 3),
  null_excluding   boolean not null default false,  -- feeds §4.6 derivation
  property_locus_default core.property_locus,
  universal_d0     boolean not null default false,
  rationale        text not null,
  diag_version_id  bigint not null references registry.table_version(table_version_id),
  reviewed_by      text not null,
  reviewed_at      timestamptz not null default now(),
  unique (typology_profile, observation_key, null_code, diag_version_id),
  -- D4 is not assignable by catalog fiat. It is the §3.4 gate and nothing else.
  constraint catalog_universal_d0_is_zero check (not universal_d0 or magnitude = 0),
  constraint catalog_d0_not_null_excluding check (magnitude > 0 or not null_excluding)
);
create index diag_catalog_lookup
  on registry.diagnosticity_catalog(typology_profile, observation_key, diag_version_id);

-- ---------------------------------------------------------------------
-- TABLE 3 — expected-record profiles (BES §6.3). Absence of a record is
-- evidence only where the presence of that record would have been expected.
-- ---------------------------------------------------------------------
create table registry.erp_profile (
  erp_profile_id   bigint generated always as identity primary key,
  profile_key      text not null,
  country_code     core.iso_country references registry.country(country_code),
  description      text not null,
  x_level          core.x_level not null,
  applies_to_classes    core.proposition_class[] not null default '{}',
  applies_to_typologies core.typology[] not null default '{}',
  -- Which side of the two bars a negative on this profile speaks to (§10.2).
  property_locus   core.property_locus not null default 'CLAIM-PROPERTY',
  era_from         date,
  era_to           date,
  authority_note   text,
  silence_override core.silence_reading,
  destroying_event text,                 -- 'NPRC fire, 12 July 1973, ~16-18M files'
  corpus_id        bigint references registry.corpus(corpus_id),
  counts_toward_sci boolean not null default true,
  erp_version_id   bigint not null references registry.table_version(table_version_id),
  reviewed_by      text not null,
  reviewed_at      timestamptz not null default now(),
  unique (profile_key, erp_version_id),
  -- BES §6.2: X0 produces NO ROW — an absence, not a zero. X0 profiles are
  -- therefore excluded from the SCI denominator by construction.
  constraint erp_x0_not_in_sci check (x_level <> 'X0' or counts_toward_sci = false)
);
create index erp_profile_lookup on registry.erp_profile(erp_version_id, x_level);

create table registry.canonical_search_set (
  search_set_id     bigint generated always as identity primary key,
  proposition_class core.proposition_class not null,
  country_code      core.iso_country references registry.country(country_code),
  erp_profile_id    bigint not null references registry.erp_profile(erp_profile_id),
  required          boolean not null default true,
  unique (proposition_class, country_code, erp_profile_id)
);

-- ---------------------------------------------------------------------
-- TABLE 4 — candidate sets (BES §9.2 C1c). M <= 3N. Adding a candidate
create table registry.candidate_set (
  candidate_set_id bigint generated always as identity primary key,
  slug             text not null unique,
  label            text not null,
  program_proposition_id uuid,           -- FK added after core.proposition
  documented_instance_count integer not null check (documented_instance_count > 0),  -- N
  denominator_note text not null,
  published_at     timestamptz,
  set_version_id   bigint not null references registry.table_version(table_version_id),
  reviewed_by      text not null
);

create table registry.candidate_set_member (
  candidate_set_id bigint not null references registry.candidate_set(candidate_set_id),
  entity_id        uuid not null,        -- FK added after core.entity
  added_at         timestamptz not null default now(),
  added_by         text not null,
  removed_at       timestamptz,          -- nothing is deleted
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

-- Reference-class base rates (BES §6.5). PUBLICATION ONLY. This table is
-- never read by the grading arithmetic, and that separation is exactly what
-- lets BES return F on the hallucination canary where a Bayesian prior
-- returns B.
create table registry.base_rate (
  proposition_class core.proposition_class not null,
  reference_class   core.reference_class not null,
  function_set      text not null default 'n/a'
                      check (function_set in ('sensitive','mundane','n/a')),
  reading           core.base_rate_reading not null,
  published_note    text,
  primary key (proposition_class, reference_class, function_set)
);

create table registry.rubric_version (
  rubric_version text primary key,
  ratified_at    timestamptz,
  notes          text
);

create table registry.scorer_model (
  scorer_model_id text primary key,
  model_family    text not null,
  vendor          text,
  role            text not null check (role in
                    ('DISCOVERY','PROPOSER','VERIFIER','SILENCE','LINEAGE',
                     'REFUTER','ASSESSOR','RESOLVER','CURATOR','REVIEWER')),
  first_used_at   timestamptz not null default now()
);
comment on column registry.scorer_model.model_family is
  'Agent independence is NOT source independence. N prompts over one set of weights is one witness speaking N times. This column is what collapses them to one lineage (BES §5.1.2).';

-- =====================================================================
-- 4. ENTITIES — containers, never graded (BES §1.1).
--    A site page renders N badges, never one.
-- =====================================================================

create table core.entity (
  entity_id      uuid primary key default gen_random_uuid(),
  slug           text not null unique,
  entity_level   core.entity_level not null default 'site',
  canonical_name text not null,
  parent_entity_id uuid references core.entity(entity_id),
  country_code   core.iso_country not null references registry.country(country_code),
  admin_area_id  bigint references registry.admin_area(admin_area_id),

  -- Typology is a GRADED PROPOSITION, not a filter (BES §1.2). This column is
  -- a cached read of the TYPOLOGY proposition; it defaults to unknown-anomaly
  -- and cannot change without a TYPOLOGY proposition clearing band C, which
  -- the trigger below enforces.
  typology_cached core.typology not null default 'unknown-anomaly',
  typology_proposition_id uuid,

  reference_class core.reference_class,   -- publication only, never arithmetic

  first_ingested_at timestamptz not null default now(),
  last_touched_at   timestamptz not null default now(),
  discovered_by     text,
  discovery_run_id  bigint,

  publication_state core.publication_state not null default 'INTERNAL',
  published_at      timestamptz,
  withdrawn_reason  text,

  -- BES §12.4 canary programme. Rotating fabricated facility names with zero
  -- corpus presence are injected into the discovery queue every cycle; any
  is_canary      boolean not null default false,

  constraint entity_published_has_date
    check (publication_state <> 'PUBLISHED' or published_at is not null),
  constraint entity_canary_never_published
    check (not is_canary or publication_state <> 'PUBLISHED'),
  constraint entity_no_self_parent check (parent_entity_id <> entity_id)
);
create index entity_parent_idx  on core.entity(parent_entity_id);
create index entity_country_idx on core.entity(country_code);
create index entity_pub_idx     on core.entity(publication_state)
  where publication_state = 'PUBLISHED';
create index entity_name_trgm   on core.entity using gin (canonical_name gin_trgm_ops);

-- Alias sets. RESOLVER maintains them; VERIFIER's subject-binding check
-- (BES §2.3) string-matches against them. Entity resolution is therefore a
-- VERIFICATION INPUT, not a bookkeeping convenience.
create table core.entity_alias (
  alias_id   bigint generated always as identity primary key,
  entity_id  uuid not null references core.entity(entity_id) on delete restrict,
  alias_kind text not null check (alias_kind in
               ('facility-name','installation-plus-building','codename','identifier',
                'coordinate-string','local-vernacular','misspelling','rpuid',
                'parcel-id','mine-id','iris-number')),
  alias_text text not null,
  alias_norm text generated always as (core.norm_token(alias_text)) stored,
  -- A codename is admissible for subject binding only when backed by an
  -- IDENTITY proposition at band C or better (BES §2.3).
  identity_proposition_id uuid,
  admissible_for_binding boolean not null default true,
  added_by   text not null,
  added_at   timestamptz not null default now(),
  retired_at timestamptz,
  unique (entity_id, alias_kind, alias_text)
);
create index entity_alias_norm_idx on core.entity_alias(alias_norm) where retired_at is null;
create index entity_alias_trgm     on core.entity_alias using gin (alias_norm gin_trgm_ops);

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
create index entity_identifier_lookup
  on core.entity_identifier(identifier_class, value_canonical);

-- BES §11.1: coordinate proximity and name similarity FLAG, never merge.
-- DISTINCT-FROM is seeded from the calibration set so Manzano Base and
-- KUMMSC are asserted apart and can never silently re-merge.
create table core.entity_relation (
  relation_id    bigint generated always as identity primary key,
  from_entity_id uuid not null references core.entity(entity_id) on delete restrict,
  to_entity_id   uuid not null references core.entity(entity_id) on delete restrict,
  kind           core.entity_relation_kind not null,
  identity_proposition_id uuid,
  asserted_by    text not null,
  asserted_at    timestamptz not null default now(),
  retracted_at   timestamptz,
  note           text,
  check (from_entity_id <> to_entity_id),
  unique (from_entity_id, to_entity_id, kind)
);
create index entity_relation_from on core.entity_relation(from_entity_id, kind);
create index entity_relation_to   on core.entity_relation(to_entity_id, kind);

-- Merges and splits are versioned and REVERSIBLE. If a merge RAISES a grade,
-- the merge is doing evidentiary work it has not justified and is rejected.
create table core.entity_merge_event (
  merge_event_id bigint generated always as identity primary key,
  kind           text not null check (kind in ('MERGE','SPLIT','UNMERGE')),
  surviving_entity_id uuid not null references core.entity(entity_id),
  absorbed_entity_id  uuid not null references core.entity(entity_id),
  identity_proposition_id uuid,
  identity_grade_at_merge core.grade,
  grade_before   jsonb not null default '{}'::jsonb,
  grade_after    jsonb not null default '{}'::jsonb,
  raised_a_grade boolean not null default false,
  rejected       boolean not null default false,
  rejected_reason text,
  performed_by   text not null,
  performed_at   timestamptz not null default now(),
  reversed_by_event_id bigint references core.entity_merge_event(merge_event_id),
  constraint merge_raising_grade_is_rejected
    check (not raised_a_grade or rejected)
);

-- Audit trail of a typology actually changing (BES §1.2).
create table core.entity_typology_history (
  id             bigint generated always as identity primary key,
  entity_id      uuid not null references core.entity(entity_id) on delete restrict,
  typology_from  core.typology,
  typology_to    core.typology not null,
  proposition_id uuid,
  grade_at_change core.grade,
  changed_at     timestamptz not null default now(),
  cause          core.transition_cause not null
);
create index entity_typology_history_idx on core.entity_typology_history(entity_id, changed_at desc);

-- =====================================================================
-- 5. GEOMETRIC UNCERTAINTY IS FIRST-CLASS (requirement 7).
-- A precise pin manufactured from imprecise evidence is the register
-- [FIX-BOTH] `place_name_only` carries a claimed NAME and no shape at all.
-- =====================================================================
create table core.geometry_assertion (
  geometry_assertion_id uuid primary key default gen_random_uuid(),
  entity_id  uuid not null references core.entity(entity_id) on delete restrict,
  locate_proposition_id uuid,
  precision  core.locate_precision not null,

  point_geom   geometry(Point,4326),
  uncertainty_radius_m double precision check (uncertainty_radius_m > 0),
  region_geom  geometry(MultiPolygon,4326),
  admin_area_id bigint references registry.admin_area(admin_area_id),
  claimed_place_name text,          -- place_name_only: the words, nothing more

  -- Provenance on every fact, geometry included.
  source_observation_id uuid,
  derivation text not null check (derivation in
    ('instrument-survey','control-point-match','parcel-record','quadrangle-read',
     'lidar-derived','georeferenced-imagery','gazetteer','narrative-description',
     'asserted-by-source','admin-area-fallback')),
  asserted_by   text not null,
  asserted_at   timestamptz not null default now(),
  superseded_at timestamptz,
  superseded_by uuid references core.geometry_assertion(geometry_assertion_id),
  is_preferred  boolean not null default false,
  note          text,

  -- The shape a precision level is ALLOWED to carry. `else false` rather than
  -- an exhaustive CASE: proposal B's version returned NULL for any enum value
  -- added later, and a NULL check constraint PASSES. A new precision level
  -- must fail loudly until it is given a rule here.
  constraint geometry_shape_matches_precision check (
    case precision
      when 'surveyed'         then point_geom is not null and region_geom is null
      when 'approximate_1km'  then point_geom is not null and region_geom is null
      when 'approximate_10km' then point_geom is not null and region_geom is null
      when 'claimed_only'     then point_geom is not null and region_geom is null
      when 'regional'         then region_geom is not null and point_geom is null
      when 'admin_area'       then admin_area_id is not null
                                   and point_geom is null and region_geom is null
      when 'place_name_only'  then claimed_place_name is not null
                                   and point_geom is null and region_geom is null
      when 'non_located'      then point_geom is null and region_geom is null
                                   and admin_area_id is null
      else false
    end
  ),
  -- A surveyed point without a stated uncertainty is a lie of omission.
  constraint geometry_point_has_uncertainty check (
    point_geom is null or precision = 'surveyed' or uncertainty_radius_m is not null)
);
create unique index geometry_one_preferred
  on core.geometry_assertion(entity_id) where is_preferred and superseded_at is null;
create index geometry_point_gix  on core.geometry_assertion using gist (point_geom);
create index geometry_region_gix on core.geometry_assertion using gist (region_geom);
create index geometry_entity_idx on core.geometry_assertion(entity_id) where superseded_at is null;

comment on table core.geometry_assertion is
  'Never force a misleading point. Competing assertions coexist; core.render_geometry picks by rule and a point is emitted only when the LOCATE proposition itself reaches band C.';

-- =====================================================================
-- 6. PROPOSITIONS ARE FIRST-CLASS (requirement 1).
-- The unit of grading is a PROPOSITION, not a place. "The hole is certain,
-- =====================================================================

create table core.claim (
  claim_id     uuid primary key default gen_random_uuid(),
  claim_text   text not null,
  claim_norm   text generated always as (core.norm_token(claim_text)) stored,
  entity_id    uuid references core.entity(entity_id),
  -- Semantic clustering is on the ASSERTION, not the wording: paraphrase and
  -- machine regeneration share no strings and cite nothing; they share a claim.
  cluster_key  text,
  first_appearance_document_id uuid,
  first_appearance_date        date,
  first_appearance_confidence  text check (first_appearance_confidence in
                                 ('receipted','inferred','unknown')),
  created_at   timestamptz not null default now()
);
create index claim_cluster_idx on core.claim(cluster_key);
create index claim_norm_trgm   on core.claim using gin (claim_norm gin_trgm_ops);

create table core.proposition (
  proposition_id uuid primary key default gen_random_uuid(),
  entity_id      uuid not null references core.entity(entity_id) on delete restrict,
  class          core.proposition_class not null,

  subject_entity_id uuid references core.entity(entity_id),
  object_entity_id  uuid references core.entity(entity_id),   -- IDENTITY B side
  claim_id          uuid references core.claim(claim_id),     -- ORIGIN subject

  predicate_args jsonb not null default '{}'::jsonb,
  -- Normalised writer-supplied key: guarantees one row per distinct assertion.
  predicate_key  text not null,
  statement_text text not null,
  as_of_date     date,
  valid_period   daterange,

  -- BES §4.1: an observation contributes in proportion to its power to
  -- discriminate the proposition from the NAMED alternative, so there is
  -- always a named alternative. Not nullable.
  null_code      char(3) not null references registry.null_hypothesis(null_code),
  -- A11 is a MANDATORY CO-NULL on any proposition whose positive support
  -- includes a T5 lineage; both scorings run and the LOWER grade publishes.
  co_null_code   char(3) references registry.null_hypothesis(null_code),

  typology_profile core.typology not null default 'unknown-anomaly',
  reference_class  core.reference_class,
  function_set     text not null default 'n/a'
                     check (function_set in ('sensitive','mundane','n/a')),

  parent_proposition_id uuid references core.proposition(proposition_id),
  clamp_exempt   boolean not null default false,
  candidate_set_id bigint references registry.candidate_set(candidate_set_id),

  -- version pins (BES §12.3)
  rubric_version text not null default 'BES-0.2.0'
                   references registry.rubric_version(rubric_version),

  created_at     timestamptz not null default now(),
  created_by     text not null,
  publication_state core.publication_state not null default 'INTERNAL',
  published_at   timestamptz,
  withdrawn_reason text,

  constraint proposition_no_self_parent check (parent_proposition_id <> proposition_id),
  constraint proposition_identity_has_object
    check (class <> 'IDENTITY' or object_entity_id is not null),
  constraint proposition_origin_has_claim
    check (class <> 'ORIGIN' or claim_id is not null),
  constraint proposition_published_has_date
    check (publication_state <> 'PUBLISHED' or published_at is not null),
  constraint proposition_valid_range
    check (valid_period is null or not isempty(valid_period))
);

-- One EXIST proposition per entity per as-of date: the clamp parent must be
-- unambiguous, or the monotone clamp is not well defined.
create unique index proposition_one_exist
  on core.proposition(entity_id, coalesce(as_of_date,'0001-01-01'::date))
  where class = 'EXIST';
create unique index proposition_identity_uix
  on core.proposition(entity_id, class, predicate_key,
                      coalesce(as_of_date,'0001-01-01'::date));
create index proposition_entity_idx on core.proposition(entity_id, class);
create index proposition_parent_idx on core.proposition(parent_proposition_id);
create index proposition_class_idx  on core.proposition(class);
create index proposition_args_gin   on core.proposition using gin (predicate_args jsonb_path_ops);
create index proposition_pub_idx    on core.proposition(publication_state)
  where publication_state = 'PUBLISHED';
create index proposition_candset_idx on core.proposition(candidate_set_id)
  where candidate_set_id is not null;

comment on table core.proposition is
  'The atomic graded unit (BES §1.1). PROGRAM and ORIGIN are clamp-exempt: that exemption is what makes DUCC (PROGRAM A / EXIST R) and Dulce (ORIGIN A / FUNCTION R) representable at all.';

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

-- An agent may not invent a class and may not emit an under-specified
-- proposition. Closed vocabularies inside the jsonb are checked, not trusted.
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
    raise exception 'proposition class % requires predicate_args keys %',
      new.class, req;
  end if;

  if new.class = 'STATUS' and not exists (
       select 1 from unnest(enum_range(null::core.status_value)) s
        where s::text = new.predicate_args->>'status') then
    raise exception 'STATUS.status "%" not in closed vocabulary',
      new.predicate_args->>'status';
  end if;
  if new.class = 'TYPOLOGY' and not exists (
       select 1 from unnest(enum_range(null::core.typology)) t
        where t::text = new.predicate_args->>'typology') then
    raise exception 'TYPOLOGY.typology "%" not in closed vocabulary',
      new.predicate_args->>'typology';
  end if;
  return new;
end $$;
create trigger proposition_validate_args
  before insert or update of class, predicate_args on core.proposition
  for each row execute function core.validate_predicate_args();

-- Close the deferred FKs now that both sides exist.
alter table registry.candidate_set add constraint candidate_set_program_fk
  foreign key (program_proposition_id) references core.proposition(proposition_id);
alter table registry.candidate_set_member add constraint candidate_set_member_entity_fk
  foreign key (entity_id) references core.entity(entity_id);
alter table core.entity add constraint entity_typology_prop_fk
  foreign key (typology_proposition_id) references core.proposition(proposition_id);
alter table core.entity_alias add constraint entity_alias_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.entity_relation add constraint entity_relation_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.entity_merge_event add constraint merge_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.entity_typology_history add constraint typology_history_prop_fk
  foreign key (proposition_id) references core.proposition(proposition_id);
alter table core.geometry_assertion add constraint geometry_locate_prop_fk
  foreign key (locate_proposition_id) references core.proposition(proposition_id);

-- Per-proposition ERP applicability. Grafted from proposal A: proposal B
-- derived the SCI denominator from the proposition CLASS alone, which cannot
create table core.proposition_erp (
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  erp_profile_id bigint not null references registry.erp_profile(erp_profile_id),
  applicable     boolean not null default true,
  resolved_x     core.x_level not null,
  resolution_note text,
  searched       boolean not null default false,
  search_receipt_id uuid,
  primary key (proposition_id, erp_profile_id)
);
create index proposition_erp_applicable
  on core.proposition_erp(proposition_id) where applicable;

-- =====================================================================
-- 7. DOCUMENTS, RECEIPTS, AND RESOLVE-OR-DIE (requirement 3).
-- "Every claim carries a citation" is satisfied 100% of the time by a
-- =====================================================================

create table core.source_document (
  document_id  uuid primary key default gen_random_uuid(),
  corpus_id    bigint references registry.corpus(corpus_id),

  title        text,
  issuing_body text,            -- who authored it, not who hosts it
  author_name  text,
  document_date date,
  url          text,

  identifier   text,
  identifier_class text references registry.identifier_grammar(identifier_class),
  identifier_canonical text,

  -- Dimension 1: institutional origin. The tier of a document is the tier of
  -- its AUTHOR. PENDING scores as T4 for all conditions until reviewed
  -- (BES §3.2) — it can support C and D, never A or B. That removes the
  -- incentive to route around the review queue under unbounded ingest.
  origin_tier  core.origin_tier not null default 'PENDING',
  tier_assigned_by text,
  tier_reviewed boolean not null default false,

  -- Dimension 2: causal provenance. Evidence created AFTER, and BECAUSE OF,
  -- a claim is not evidence for the claim.
  causal_provenance core.causal_provenance not null default 'UNSOLICITED',

  -- Dimension 3: corpus era. COMPUTED from Wayback CDX, domain registration
  -- and pre-2022 capture history — never judged.
  corpus_era   core.corpus_era not null default 'UNKNOWN',
  first_observed_date date,
  domain_registered_date date,
  earliest_cdx_capture date,
  has_named_author boolean,
  byline_history_found boolean,

  channel      core.channel not null default 'ORIGIN-HOST',

  -- BES §2.5, the E/F discriminator both submitted models got wrong. An
  -- artifact authored by the claimant, whose probative content IS the claim,
  self_attesting boolean not null default false,
  self_attesting_rationale text,

  -- BES §5.1.8 self-exclusion: a source whose first observation postdates the
  -- register's own publication of that candidate is quarantined — retained,
  -- displayed, zero lineages, zero conditions.
  register_echo_quarantined boolean not null default false,
  register_echo_reason text,

  -- INTERPRETATION INHERITS THE TIER OF WHOEVER ASSERTED IT (BES §3.1).
  -- "This quad shows an adit at 38.744,-104.848" is an ASSERTION by an agent,
  -- hence T5, until a second model family confirms and the era-correct symbol
  -- standard is cited. Proposal A had no equivalent rule.
  authored_by_agent boolean not null default false,
  agent_model_family text,
  second_family_confirmed boolean not null default false,
  standard_citation text,

  -- BES §5.1.3/4: a transparent compiler is a CONDUIT — its primaries are the
  -- lineages and the compiler is neither counted nor penalised.
  is_compiler  boolean not null default false,
  compiler_transparent boolean,

  lineage_id   bigint,          -- FK added in the lineage section
  created_at   timestamptz not null default now(),
  publication_state core.publication_state not null default 'INTERNAL',

  constraint document_agent_interpretation_is_t5
    check (not authored_by_agent or second_family_confirmed or origin_tier = 'T5'),
  constraint document_self_attest_has_reason
    check (not self_attesting or self_attesting_rationale is not null),
  constraint document_identifier_class_pair
    check ((identifier is null) = (identifier_class is null))
);
create index document_corpus_idx     on core.source_document(corpus_id);
create index document_identifier_idx on core.source_document(identifier_class, identifier_canonical);
create index document_lineage_idx    on core.source_document(lineage_id);
create index document_era_idx        on core.source_document(corpus_era);
create index document_tier_idx       on core.source_document(origin_tier);
create index document_family_idx     on core.source_document(agent_model_family)
  where agent_model_family is not null;
create index document_date_idx       on core.source_document(document_date);

-- Cache-and-revalidate, never cache-once. N receipts per document over time;
-- content hash diffed on schedule; drift is a signal, not an error.
create table core.retrieval_receipt (
  receipt_id   uuid primary key default gen_random_uuid(),
  document_id  uuid not null references core.source_document(document_id) on delete restrict,

  requested_url text not null,
  resolved_url  text,
  http_status   integer,
  sha256_of_bytes core.sha256,
  byte_length   bigint,
  content_type  text,
  retrieved_at  timestamptz not null default now(),

  grammar_pass  boolean not null default false,
  resolved_at_issuer boolean not null default false,
  mirror_only   boolean not null default false,      -- BES §2.6 / CAP-6
  mirror_host   text,
  issuer_metadata_match boolean not null default false,
  issuer_metadata_diff  jsonb,

  receipt_state core.receipt_state not null default 'UNRESOLVED',

  -- The verifier is deterministic code. Where a model is unavoidable it MUST
  -- be a different family from the discoverer: an LLM verifying an LLM shares
  -- the priors that produced the error.
  verifier_kind text not null default 'code' check (verifier_kind in ('code','model')),
  verifier_model_id text references registry.scorer_model(scorer_model_id),
  discoverer_model_family text,
  verifier_model_family   text,

  previous_receipt_id uuid references core.retrieval_receipt(receipt_id),
  content_drifted boolean not null default false,
  drift_alerted_at timestamptz,
  robots_allowed boolean,
  failure_reason text,

  -- RESOLVE-OR-DIE as a constraint rather than a note (BES §2.2).
  constraint receipt_verified_requires_everything check (
    receipt_state <> 'VERIFIED' or (
      grammar_pass
      and (resolved_at_issuer or mirror_only)
      and http_status = 200
      and sha256_of_bytes is not null
      and issuer_metadata_match)),
  constraint receipt_mirror_has_host check (not mirror_only or mirror_host is not null),
  constraint receipt_verifier_family_differs check (
    verifier_kind = 'code' or discoverer_model_family is null
    or verifier_model_family is distinct from discoverer_model_family)
);
create index receipt_document_idx on core.retrieval_receipt(document_id, retrieved_at desc);
create index receipt_state_idx    on core.retrieval_receipt(receipt_state);
create index receipt_drift_idx    on core.retrieval_receipt(document_id) where content_drifted;

-- Verbatim spans located at character offsets by deterministic non-LLM code.
-- Two kinds: what the document SAYS, and the SUBJECT-BINDING token proving
create table core.quoted_span (
  span_id    uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references core.retrieval_receipt(receipt_id) on delete restrict,
  span_kind  text not null check (span_kind in ('PROBATIVE','SUBJECT-BINDING')),
  quoted_text text not null,
  span_start_offset bigint not null check (span_start_offset >= 0),
  span_end_offset   bigint not null,
  quote_check boolean not null default false,     -- deterministic, non-LLM
  matched_alias_id  bigint references core.entity_alias(alias_id),
  matched_entity_id uuid references core.entity(entity_id),
  check (span_end_offset > span_start_offset),
  -- A passing subject-binding span must name WHICH alias it matched.
  constraint binding_span_names_its_alias
    check (span_kind <> 'SUBJECT-BINDING' or not quote_check or matched_alias_id is not null)
);
create index quoted_span_receipt_idx on core.quoted_span(receipt_id, span_kind);

-- Untrusted identifiers extracted from fetched text go HERE, never into a
-- citation (BES §2.7). Fetched text enters the pipeline as structurally
-- bounded DATA, never as free prose in a scoring prompt. Promotion requires
-- independent resolution at the issuing authority.
create table ingest.lead (
  lead_id     uuid primary key default gen_random_uuid(),
  identifier  text not null,
  identifier_class text references registry.identifier_grammar(identifier_class),
  extracted_from_document_id uuid references core.source_document(document_id),
  extracted_from_host text,
  is_adversary_writable_origin boolean not null default true,
  state       text not null default 'new'
                check (state in ('new','resolving','promoted','rejected')),
  promoted_document_id uuid references core.source_document(document_id),
  promoted_at timestamptz,
  rejected_reason text,
  created_at  timestamptz not null default now()
);
create index lead_state_idx on ingest.lead(state);
create index lead_identifier_idx on ingest.lead(identifier_class, identifier);

-- ---------------------------------------------------------------------
-- SEARCH RECEIPTS. Absence is not citable without a receipt for the absence.
-- ---------------------------------------------------------------------
create table core.search_log (
  search_log_id uuid primary key default gen_random_uuid(),
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  opened_at  timestamptz not null default now(),
  closed_at  timestamptz,
  opened_by  text not null
);
create index search_log_prop_idx on core.search_log(proposition_id);

create table core.search_receipt (
  search_receipt_id uuid primary key default gen_random_uuid(),
  search_log_id  uuid references core.search_log(search_log_id) on delete restrict,
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  erp_profile_id bigint references registry.erp_profile(erp_profile_id),
  corpus_id      bigint references registry.corpus(corpus_id),

  query_string   text not null,
  corpus_version text,
  corpus_as_of   date,
  executed_at    timestamptz not null default clock_timestamp(),
  executed_by    text not null,
  result_count   integer not null default 0 check (result_count >= 0),
  http_status    integer,
  results_sha256 core.sha256,        -- the receipt for the absence itself

  -- BES §2.6: if no host in a canonical corpus is reachable the search returns
  -- UNSEARCHED, not NEGATIVE, and the SCI falls accordingly. Conflating the
  -- two is how a blocked egress becomes a manufactured refutation.
  outcome        core.search_outcome not null,
  unsearched_reason text,
  egress_at_execution text,
  constraint search_negative_has_zero check (outcome <> 'NEGATIVE' or result_count = 0),
  constraint search_unsearched_has_reason
    check (outcome <> 'UNSEARCHED' or unsearched_reason is not null)
);
create index search_receipt_prop_idx on core.search_receipt(proposition_id, outcome);
create index search_receipt_erp_idx  on core.search_receipt(proposition_id, erp_profile_id);

alter table core.proposition_erp add constraint proposition_erp_receipt_fk
  foreign key (search_receipt_id) references core.search_receipt(search_receipt_id);

-- =====================================================================
-- 8. THE ATOM: SIGNED OBSERVATIONS (requirement 2).
-- One row = one signed observation of one artifact against ONE proposition,
-- =====================================================================

create table core.observation (
  observation_id uuid primary key default gen_random_uuid(),
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  document_id    uuid references core.source_document(document_id) on delete restrict,
  receipt_id     uuid references core.retrieval_receipt(receipt_id) on delete restrict,
  probative_span_id uuid references core.quoted_span(span_id),
  binding_span_id   uuid references core.quoted_span(span_id),

  -- Rows derived from a receipted NEGATIVE search carry no document. Negatives
  -- are signed, so they live in this table and the arithmetic never forks.
  derived_from_search_receipt_id uuid references core.search_receipt(search_receipt_id),

  observation_key text,         -- diagnosticity catalog key
  statement      text not null,

  ---- the signed magnitude ----
  sign      core.evidence_sign not null,
  magnitude smallint not null check (magnitude between 0 and 4),
  signed_weight smallint generated always as (
    magnitude * case sign when 'SUPPORTS' then 1 when 'UNDERCUTS' then -1 else 0 end
  ) stored,
  diagnosticity_source core.diagnosticity_source not null,
  catalog_id bigint references registry.diagnosticity_catalog(catalog_id),
  ea_expectedness core.ea_expectedness,
  ea_alternative  core.ea_alternative,
  ea_proposed_catalog_extension boolean not null default false,

  ---- the six §3.4 explicit-statement gate conditions, stored separately so
  ---- reliability is measured per CONDITION (BES §12.1) ----
  gate_a_tier        boolean not null default false,  -- T1 or T2
  gate_b_receipt     boolean not null default false,  -- VERIFIED + subject binding
  gate_c_instance    boolean not null default false,  -- scope INSTANCE
  gate_d_on_its_face boolean not null default false,  -- span states the proposition
  gate_e_authority   boolean not null default false,  -- issuer has AUTHORITY OVER THE FACT
  gate_f_unsolicited boolean not null default false,
  gate_pass boolean generated always as (
    gate_a_tier and gate_b_receipt and gate_c_instance
    and gate_d_on_its_face and gate_e_authority and gate_f_unsolicited) stored,

  scope          core.evidence_scope not null default 'CLASS',
  property_locus core.property_locus not null,
  subject_binding_pass boolean not null default false,

  -- BES §5.5: rows sharing a fact_key within a proposition collapse to one
  -- for lineage counting. Stops "this was an AT&T Long Lines station" entering
  -- as four lineages through four record types.
  fact_key text,

  -- §4.6 "cannot produce" written test, derived by trigger from the catalog
  -- row or the E/A ordinals — never asserted.
  null_excluding boolean not null default false,
  -- This row affirmatively DOCUMENTS the named alternative (drives DOMINANT).
  documents_null boolean not null default false,
  -- E0 under H: content improbable under the proposition (an R2 input).
  improbable_under_h boolean generated always as (ea_expectedness = 'E0') stored,

  ---- denormalised provenance, kept in sync by trigger; the mirrors are NOT
  ---- independently writable, the trigger always wins ----
  prov_receipt_state core.receipt_state not null default 'UNRESOLVED',
  prov_origin_tier   core.origin_tier not null default 'PENDING',
  prov_channel       core.channel not null default 'AGGREGATOR',
  prov_causal        core.causal_provenance not null default 'UNSOLICITED',
  prov_corpus_era    core.corpus_era not null default 'UNKNOWN',
  prov_self_attesting boolean not null default false,
  prov_echo_quarantined boolean not null default false,

  -- Nothing is deleted: a superseded row is retained and displayed as inert.
  superseded_by_observation_id uuid references core.observation(observation_id),

  ---- THE MEMBERSHIP SETS V AND U (BES §2.4), computed, never asserted ----
  membership core.evidence_membership generated always as (
    case
      when superseded_by_observation_id is not null then 'INERT'::core.evidence_membership
      when prov_receipt_state <> 'VERIFIED' then 'V0'::core.evidence_membership
      when scope <> 'INSTANCE'
        or prov_channel = 'ADVERSARY-WRITABLE'
        or prov_causal not in ('UNSOLICITED','SOLICITED-3P')
        or prov_corpus_era = 'POST-2022-UNATTRIBUTED'
        or prov_self_attesting
        or prov_echo_quarantined
        or sign = 'NEUTRAL' then 'INERT'::core.evidence_membership
      when sign = 'SUPPORTS' then 'V'::core.evidence_membership
      else 'U'::core.evidence_membership
    end) stored,

  -- Why a row is inert, rendered on the entry page beside it. The register
  -- shows its own exclusions; hiding them would be the same sin one level up.
  exclusion_reason text generated always as (
    case
      when superseded_by_observation_id is not null then 'SUPERSEDED: replaced by a later observation; retained and displayed'
      when prov_receipt_state <> 'VERIFIED' then 'V0-UNRESOLVED: the receipt did not resolve to bytes; arithmetically inert, retained and displayed'
      when scope = 'ADJACENT' then 'ADJACENT: proximity is not support'
      when scope = 'CLASS'    then 'CLASS-SCOPE: establishes the typology, not this instance'
      when prov_channel = 'ADVERSARY-WRITABLE' then 'ADVERSARY-WRITABLE: an anonymous party can write the cited field'
      when prov_causal = 'SOLICITED-BY-CLAIMANT' then 'SOLICITED-BY-CLAIMANT: evidence created after, and because of, the claim'
      when prov_causal = 'SELF-PUBLISHED' then 'SELF-PUBLISHED: a resolving DOI is not an editorial assertion'
      when prov_causal = 'CROWD-EDITED' then 'CROWD-EDITED: a lead, never evidence'
      when prov_corpus_era = 'POST-2022-UNATTRIBUTED' then 'POST-2022-UNATTRIBUTED: zero lineages, zero conditions'
      when prov_self_attesting then 'SELF-ATTESTING: the author is the claimant and the content is the claim; graded under ORIGIN instead'
      when prov_echo_quarantined then 'REGISTER-ECHO: first observed after the register itself published this candidate'
      when sign = 'NEUTRAL' then 'NEUTRAL: the named alternative predicts this just as strongly'
      else null end) stored,

  ---- testimony (BES §5.4) ----
  is_testimony boolean not null default false,
  witness_resolvable boolean,
  attestation_custody text check (attestation_custody in
    ('signed-or-recorded-interview','bylined-quotation','deposition',
     'numbered-oral-history-accession','claimant-assertion-only','unknown')),

  ---- refutation proposal (BES §8). REFUTER proposes; core.derive_refutation
  ---- adjudicates. An agent writing 'R3' here does not produce an R grade.
  refutation_class text check (refutation_class in
    ('R1-ORIGIN-FABRICATED','R2-AFFIRMATIVELY-INCONSISTENT','R3-CONTRADICTED')),
  rebutted     boolean not null default false,
  rebutted_by_observation_id uuid references core.observation(observation_id),
  rebuttal_note text,

  ---- A1-alt direct observation (BES §9.2), EXIST/EXTENT/LOCATE/FEATURE only
  direct_observation boolean not null default false,
  lawful_physical_access boolean not null default false,
  georef_control_point_match boolean not null default false,

  asserted_by text not null,
  asserted_model_id text references registry.scorer_model(scorer_model_id),
  asserted_at timestamptz not null default clock_timestamp(),
  publication_state core.publication_state not null default 'INTERNAL',
  notes text,

  ---- constraints that carry real weight ----
  constraint observation_has_provenance
    check (document_id is not null or derived_from_search_receipt_id is not null),
  -- D4 is the §3.4 gate and nothing else. All six conditions or it is not D4.
  constraint observation_d4_is_the_gate
    check (magnitude < 4 or (gate_a_tier and gate_b_receipt and gate_c_instance
                             and gate_d_on_its_face and gate_e_authority and gate_f_unsolicited)),
  constraint observation_matrix_ceiling
    check (diagnosticity_source <> 'MATRIX' or magnitude <= 3),
  constraint observation_matrix_has_ordinals
    check (diagnosticity_source <> 'MATRIX'
           or (ea_expectedness is not null and ea_alternative is not null)),
  constraint observation_catalog_has_catalog_id
    check (diagnosticity_source <> 'CATALOG' or catalog_id is not null),
  constraint observation_default_is_d0
    check (diagnosticity_source <> 'DEFAULT' or magnitude = 0),
  -- BES §2.3: subject-binding failure downgrades scope INSTANCE -> CLASS.
  constraint observation_binding_gates_instance
    check (scope <> 'INSTANCE' or subject_binding_pass),
  constraint observation_negative_is_undercut
    check (derived_from_search_receipt_id is null or sign = 'UNDERCUTS'),
  -- Testimony reaching D3 requires BOTH resolvability AND custody (§5.4).
  constraint observation_testimony_custody check (
    not is_testimony or magnitude < 3
    or (witness_resolvable and attestation_custody in
        ('signed-or-recorded-interview','bylined-quotation','deposition',
         'numbered-oral-history-accession'))),
  constraint observation_no_self_supersede
    check (superseded_by_observation_id <> observation_id)
);

create index observation_prop_idx on core.observation(proposition_id);
-- The hot path: building V and U for one proposition.
create index observation_v_idx on core.observation(proposition_id, magnitude desc)
  where membership = 'V';
create index observation_u_idx on core.observation(proposition_id, magnitude desc)
  where membership = 'U';
create index observation_claimprop_idx on core.observation(proposition_id)
  where membership = 'V' and property_locus = 'CLAIM-PROPERTY';
create index observation_doc_idx     on core.observation(document_id);
create index observation_factkey_idx on core.observation(proposition_id, fact_key);
create index observation_key_idx     on core.observation(observation_key);
create index observation_refut_idx   on core.observation(proposition_id, refutation_class)
  where refutation_class is not null;
create index observation_created_brin on core.observation using brin (asserted_at);

comment on column core.observation.membership is
  'V / U / INERT / V0, generated from the seven exclusions of BES §2.4. Never written by an agent. This column is the anti-gaming ledger in one place.';

-- ---------------------------------------------------------------------
-- Provenance sync + the derived booleans. The trigger always wins.
-- ---------------------------------------------------------------------
create or replace function core.sync_observation_provenance() returns trigger
language plpgsql as $$
declare d core.source_document; r core.retrieval_receipt; c registry.diagnosticity_catalog;
        pnull char(3);
begin
  if new.document_id is not null then
    select * into d from core.source_document where document_id = new.document_id;
    new.prov_origin_tier      := d.origin_tier;
    new.prov_channel          := d.channel;
    new.prov_causal           := d.causal_provenance;
    new.prov_corpus_era       := d.corpus_era;
    new.prov_self_attesting   := d.self_attesting;
    new.prov_echo_quarantined := d.register_echo_quarantined;
  end if;

  if new.receipt_id is not null then
    select * into r from core.retrieval_receipt where receipt_id = new.receipt_id;
    new.prov_receipt_state := r.receipt_state;
  elsif new.derived_from_search_receipt_id is not null then
    -- A completed, receipted negative search IS a verified observation — of
    -- an absence. It is verified about the SEARCH, not about a document.
    new.prov_receipt_state := 'VERIFIED';
    new.prov_causal        := 'UNSOLICITED';
    new.prov_channel       := 'ORIGIN-HOST';
    new.prov_corpus_era    := 'PRE-2022';
    new.prov_self_attesting := false;
  else
    new.prov_receipt_state := 'UNRESOLVED';
  end if;

  -- BES §2.3: binding failure demotes scope. Enforced, not requested.
  if not new.subject_binding_pass and new.scope = 'INSTANCE' then
    new.scope := 'CLASS';
  end if;

  -- BES §3.2: a PENDING source scores as T4 — it may support C and D, never
  -- A or B. Clamping the magnitude is how that becomes arithmetic.
  if new.prov_origin_tier = 'PENDING' and new.magnitude > 2 then
    new.magnitude := 2;
    new.diagnosticity_source := 'DEFAULT';
    new.catalog_id := null;
    new.ea_expectedness := null; new.ea_alternative := null;
  end if;

  -- §4.6 "cannot produce": the catalog row is null-excluding for THIS
  -- proposition's null, or the E/A assignment placed A at A0/A1, or the row
  select null_code into pnull from core.proposition where proposition_id = new.proposition_id;
  if new.catalog_id is not null then
    select * into c from registry.diagnosticity_catalog where catalog_id = new.catalog_id;
    new.null_excluding := coalesce(c.null_excluding,false)
                          and (c.null_code is null or c.null_code = pnull);
  elsif new.ea_alternative is not null then
    new.null_excluding := new.ea_alternative in ('A0','A1');
  else
    new.null_excluding := false;
  end if;
  if new.magnitude = 4 and new.gate_d_on_its_face and new.gate_e_authority then
    new.null_excluding := true;
  end if;

  return new;
end $$;
create trigger observation_sync_provenance
  before insert or update on core.observation
  for each row execute function core.sync_observation_provenance();

-- A tier reassignment is an evidence event and must move every grade that
-- depended on it. Touching the rows re-fires the sync trigger above and the
-- regrade enqueue trigger defined later.
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

-- NOTHING IS DELETED (requirement 10, operating rule §6).
create or replace function core.forbid_delete() returns trigger
language plpgsql as $$
begin
  raise exception
    'DELETE forbidden on %.%: the register keeps its negatives. Use publication_state, superseded_by, or a retraction column.',
    tg_table_schema, tg_table_name;
end $$;

do $$
declare t text;
begin
  foreach t in array array['entity','proposition','observation','source_document',
                           'retrieval_receipt','quoted_span','search_receipt','claim',
                           'geometry_assertion','grade_event'] loop
    if to_regclass('core.'||t) is not null then
      execute format('create trigger %I_no_delete before delete on core.%I
                      for each statement execute function core.forbid_delete()', t, t);
    end if;
  end loop;
end $$;

-- =====================================================================
-- 9. THE CITATION GRAPH, LINEAGES, AND ORIGIN TRACING
--    (requirements 4 and 5).
-- [FIX-BOTH]  TERMINATION.  Both proposals wrote their traversals as
--     depth 4 ->      9,111 rows,    18 ms
--     depth 5 ->     73,911 rows,   163 ms
--     depth 6 ->    592,311 rows, 1,595 ms
--     depth 8 ->  did not complete within a 25-second statement timeout
-- Same fixture, same depth 25: 251 rows, 1.5 ms.
-- =====================================================================

create table core.lineage (
  lineage_id bigint generated always as identity primary key,
  label      text,
  terminus_document_id uuid references core.source_document(document_id),
  terminus_kind text not null default 'document' check (terminus_kind in
    ('document','witness','agent-model-family','compiler','negative-search','unknown')),
  -- BES §5.1.2: all findings from agents sharing a base model are ONE lineage,
  -- capped at 1 by construction. N prompts over one set of weights is one
  -- witness speaking N times in different words.
  agent_model_family text,
  first_appearance_date date,
  is_quarantined boolean not null default false,
  quarantine_reason text,
  computed_at timestamptz not null default now(),
  computation_version text not null default 'lineage-0.2.0'
);
create unique index lineage_one_per_model_family
  on core.lineage(agent_model_family) where agent_model_family is not null;

alter table core.source_document add constraint document_lineage_fk
  foreign key (lineage_id) references core.lineage(lineage_id);

create table core.lineage_membership (
  document_id uuid not null references core.source_document(document_id) on delete restrict,
  lineage_id  bigint not null references core.lineage(lineage_id),
  rule_applied text not null check (rule_applied in
    ('same-author-org-publication','model-family-collapse',
     'transparent-compiler-passthrough','opaque-compiler-terminus',
     'replication-not-independence','semantic-cluster','counterfactual-same',
     'counterfactual-distinct','self-exclusion-quarantine','default-same-under-uncertainty')),
  decided_by text not null,
  decided_at timestamptz not null default now(),
  quorum_votes jsonb not null default '[]'::jsonb,
  disagreement boolean not null default false,
  primary key (document_id, lineage_id)
);
create index lineage_membership_lineage_idx on core.lineage_membership(lineage_id);

-- Directed, cyclic, typed. Self-loops are rejected; longer cycles are real.
create table core.document_citation (
  citation_id bigint generated always as identity primary key,
  citing_document_id uuid not null references core.source_document(document_id) on delete restrict,
  cited_document_id  uuid not null references core.source_document(document_id) on delete restrict,

  edge_kind text not null check (edge_kind in
    ('explicit-citation','mirror-of','replication','paraphrase',
     'semantic-derivation','compiler-exposes','quotes-testimony')),
  detection_method text not null check (detection_method in
    ('explicit-reference','minhash-shingle','semantic-cluster','wayback-cdx-digest',
     'first-observation-dating','manual','quorum')),
  similarity double precision check (similarity between 0 and 1),

  -- BES §5.1.7, one of exactly two surviving judgement calls in the model.
  -- "Would this source have produced this claim if the prior source had never
  -- existed?" Default under uncertainty is SAME lineage.
  counterfactual_verdict text not null default 'same-lineage'
    check (counterfactual_verdict in ('same-lineage','independent','undetermined')),
  quorum_votes jsonb not null default '[]'::jsonb,
  quorum_disagreement boolean not null default false,

  -- compiler-exposes does NOT collapse: a critical edition citing forty
  -- Signal Agency documents is forty lineages, and the compiler is neither
  -- counted nor penalised (BES §5.1.3).
  collapses_lineage boolean generated always as (
    edge_kind <> 'compiler-exposes' and counterfactual_verdict <> 'independent') stored,

  asserted_by text not null,
  asserted_at timestamptz not null default now(),
  retracted_at timestamptz,
  note text,
  check (citing_document_id <> cited_document_id),
  unique (citing_document_id, cited_document_id, edge_kind)
);
create index citation_citing_idx on core.document_citation(citing_document_id)
  where retracted_at is null;
create index citation_cited_idx on core.document_citation(cited_document_id)
  where retracted_at is null;
create index citation_collapse_idx
  on core.document_citation(citing_document_id, cited_document_id)
  where collapses_lineage and retracted_at is null;

-- ---------------------------------------------------------------------
-- ORIGIN TRACE. Cycle-safe AND path-explosion-safe.
-- Returns one row per (document, depth-first-reached), never one row per path.
-- ---------------------------------------------------------------------
create or replace function core.trace_origin(
  p_document_id uuid,
  p_max_depth   integer default 24)
returns table (
  depth integer,
  document_id uuid,
  title text,
  origin_tier core.origin_tier,
  document_date date,
  first_observed_date date,
  reached_via text,
  closes_cycle boolean,
  is_terminus boolean)
language sql stable parallel safe as $$
  with recursive walk (depth, node, via) as (
      select 0, p_document_id, null::text
    union                                  -- UNION, never UNION ALL: dedup on
                                           -- (depth,node,via) bounds the working
                                           -- set at |V| x max_depth
      select w.depth + 1, dc.cited_document_id, dc.edge_kind
        from walk w
        join core.document_citation dc
          on dc.citing_document_id = w.node
         and dc.retracted_at is null
       where w.depth < p_max_depth
  ),
  -- keep the SHALLOWEST reach of each node: that is the trace the reader wants
  shallowest as (
    select distinct on (node) node, depth, via
      from walk order by node, depth
  )
  select s.depth, s.node, d.title, d.origin_tier, d.document_date,
         d.first_observed_date, s.via,
         -- an edge from this node back into the already-reached set is a cycle
         exists (select 1 from core.document_citation dc
                  where dc.citing_document_id = s.node and dc.retracted_at is null
                    and dc.cited_document_id in (select node from shallowest)),
         not exists (select 1 from core.document_citation dc
                      where dc.citing_document_id = s.node and dc.retracted_at is null)
    from shallowest s
    join core.source_document d on d.document_id = s.node
   order by s.depth
$$;

comment on function core.trace_origin is
  'Backward traversal of the cyclic citation graph. Terminates on THREE independent grounds: UNION deduplication on the node (bounds the working set at |V| x depth), the depth cap, and the absence of path arrays in the recursive term. A UNION ALL + CYCLE formulation of the same walk does not complete at depth 8 on a 40-node cluster.';

-- The path to the origin, reconstructed OUTSIDE the recursion. Bounded by
-- p_max_depth iterations of single-row lookups, so it cannot explode.
create or replace function core.origin_path(
  p_from uuid, p_to uuid, p_max_depth integer default 24)
returns uuid[] language plpgsql stable as $$
declare cur uuid := p_from; acc uuid[] := array[p_from]; nxt uuid; i int := 0;
begin
  while cur is distinct from p_to and i < p_max_depth loop
    select dc.cited_document_id into nxt
      from core.document_citation dc
      join core.trace_origin(p_from, p_max_depth) t on t.document_id = dc.cited_document_id
     where dc.citing_document_id = cur and dc.retracted_at is null
       and not (dc.cited_document_id = any(acc))     -- never revisit: cycle-safe
     order by t.depth limit 1;
    exit when nxt is null;
    acc := acc || nxt; cur := nxt; i := i + 1;
  end loop;
  return acc;
end $$;

-- The earliest traceable appearance of a claim: the ORIGIN proposition's
-- factual content. Prefers a receipted document date; falls back to first
create or replace function core.claim_origin(p_claim_id uuid, p_max_depth integer default 24)
returns table (
  document_id uuid, title text, origin_tier core.origin_tier,
  effective_date date, dating_basis text, is_graph_terminus boolean,
  reached_via_cycle boolean)
language sql stable as $$
  with seeds as (
    select distinct o.document_id
      from core.observation o
      join core.proposition p on p.proposition_id = o.proposition_id
     where p.claim_id = p_claim_id and o.document_id is not null
  ),
  walked as (
    select distinct on (t.document_id) t.*
      from seeds s cross join lateral core.trace_origin(s.document_id, p_max_depth) t
     order by t.document_id, t.depth
  )
  select w.document_id, w.title, w.origin_tier,
         coalesce(w.document_date, w.first_observed_date),
         case when w.document_date is not null then 'document-date'
              when w.first_observed_date is not null then 'first-observation'
              else 'undated' end,
         w.is_terminus, w.closes_cycle
    from walked w
   where w.is_terminus or w.closes_cycle
   order by coalesce(w.document_date, w.first_observed_date) nulls last
$$;

-- ---------------------------------------------------------------------
-- CONNECTED COMPONENTS over the collapsing subgraph. THIS is how
create or replace function core.lineage_components(p_document_ids uuid[])
returns table (document_id uuid, component_root uuid)
language sql stable parallel safe as $$
  with recursive
  -- Lineage identity is UNDIRECTED even though citation is not: if B copied
  -- A, they are one lineage whichever end you start from.
  undirected as (
    select citing_document_id a, cited_document_id b
      from core.document_citation where collapses_lineage and retracted_at is null
    union all
    select cited_document_id, citing_document_id
      from core.document_citation where collapses_lineage and retracted_at is null
  ),
  reach (seed, node) as (
      select d, d from unnest(p_document_ids) d
    union
      select r.seed, u.b from reach r join undirected u on u.a = r.node
  )
  -- The component root is the minimum reachable id: stable, order-independent,
  -- and identical for every member of a component.
  select r.seed, min(r.node::text)::uuid from reach r group by r.seed
$$;

-- L(Dk): distinct INDEPENDENT LINEAGES holding >=1 V-member observation at
-- magnitude >= k. Four collapses happen here and the ORDER MATTERS:
create or replace function core.independent_lineages(
  p_proposition_id uuid, p_min_magnitude smallint default 2)
returns table (
  lineage_key text, lineage_kind text, best_magnitude smallint,
  observation_count integer, has_claim_property boolean,
  has_place_null_excluding boolean,
  best_tier core.origin_tier, representative_document_id uuid,
  representative_title text)
language sql stable as $$
  with v as (
    select o.observation_id, o.document_id, o.fact_key, o.magnitude, o.property_locus,
           o.null_excluding, o.derived_from_search_receipt_id, o.asserted_at,
           d.agent_model_family, d.title, o.prov_origin_tier as tier
      from core.observation o
      left join core.source_document d on d.document_id = o.document_id
     where o.proposition_id = p_proposition_id
       and o.membership = 'V'
       and o.magnitude >= p_min_magnitude
  ),
  merged as (       -- 2. fact-key merge: keep the strongest row per fact
    select distinct on (coalesce(fact_key, observation_id::text)) *
      from v
     order by coalesce(fact_key, observation_id::text), magnitude desc, asserted_at
  ),
  comp as (
    select * from core.lineage_components(
      (select coalesce(array_agg(distinct document_id)
                filter (where document_id is not null), '{}') from merged))
  ),
  keyed as (
    select m.*,
           case
             when m.agent_model_family is not null
               then 'model-family:' || m.agent_model_family   -- 3. dominates all
             when c.component_root is not null
               then 'component:' || c.component_root::text    -- 4. graph component
             when m.derived_from_search_receipt_id is not null
               then 'negative-search:' || m.derived_from_search_receipt_id::text
             else 'orphan:' || m.observation_id::text end as lkey,
           case when m.agent_model_family is not null then 'agent-model-family'
                when m.derived_from_search_receipt_id is not null then 'negative-search'
                else 'document' end as lkind
      from merged m left join comp c on c.document_id = m.document_id
  )
  select k.lkey, min(k.lkind), max(k.magnitude)::smallint, count(*)::integer,
         bool_or(k.property_locus = 'CLAIM-PROPERTY'),
         bool_or(k.property_locus = 'PLACE-PROPERTY' and k.null_excluding),
         min(k.tier),
         (array_agg(k.document_id order by k.magnitude desc))[1],
         (array_agg(k.title order by k.magnitude desc))[1]
    from keyed k group by k.lkey
$$;

create or replace function core.lineage_count(p_proposition_id uuid, p_min_magnitude smallint default 2)
returns integer language sql stable as $$
  select count(*)::integer from core.independent_lineages(p_proposition_id, p_min_magnitude)
$$;

-- Lineages carrying a CLAIM-PROPERTY row at this magnitude: A1's second
-- clause needs "two D3 rows in two independent lineages, BOTH claim-property",
-- which proposal B relaxed to two D3 lineages plus two claim-property rows
-- anywhere. That relaxation lets one lineage supply both claim rows.
create or replace function core.lineage_count_claim(p_proposition_id uuid, p_min_magnitude smallint default 2)
returns integer language sql stable as $$
  select count(*)::integer from core.independent_lineages(p_proposition_id, p_min_magnitude)
   where has_claim_property
$$;

-- ---------------------------------------------------------------------
-- CITOGENESIS (BES §5.3, CAP-3). A T3+ publication resting on unattributable
create table core.citogenesis_loop (
  loop_id bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  laundering_document_id uuid not null references core.source_document(document_id),
  t5_root_document_id uuid references core.source_document(document_id),
  loop_path uuid[] not null default '{}',
  detected_by text not null,
  detected_at timestamptz not null default now(),
  state text not null default 'suspected' check (state in ('suspected','confirmed','cleared')),
  narrative text not null,
  collapsed_into_lineage_id bigint references core.lineage(lineage_id)
);
create index citogenesis_prop_idx on core.citogenesis_loop(proposition_id) where state = 'confirmed';

create or replace function core.detect_citogenesis(p_proposition_id uuid, p_max_depth integer default 16)
returns table (
  laundering_document_id uuid, laundering_tier core.origin_tier,
  t5_root_document_id uuid, depth integer, closes_cycle boolean)
language sql stable as $$
  with launderers as (
    select distinct o.document_id, d.origin_tier
      from core.observation o
      join core.source_document d on d.document_id = o.document_id
     where o.proposition_id = p_proposition_id and d.origin_tier in ('T1','T2','T3')
  ),
  walked as (
    select l.document_id launder_id, l.origin_tier launder_tier, t.*
      from launderers l
      cross join lateral core.trace_origin(l.document_id, p_max_depth) t
     where t.depth > 0
  )
  select w.launder_id, w.launder_tier, w.document_id, w.depth, w.closes_cycle
    from walked w
   where w.origin_tier = 'T5' and (w.is_terminus or w.closes_cycle)
$$;

-- ---------------------------------------------------------------------
-- ATTESTATION CUSTODY (BES §5.4). The lineage terminus is whoever is
create table core.witness (
  witness_id bigint generated always as identity primary key,
  display_name text not null,
  -- The resolvability gate: independently locatable in a record that PREDATES
  -- the claim and was created for an UNRELATED purpose.
  resolvable boolean not null default false,
  resolving_record_kind text check (resolving_record_kind in
    ('payroll','unit-history','union-roll','obituary','court-filing',
     'property-record','census','directory','none')),
  resolving_record_document_id uuid references core.source_document(document_id),
  resolving_record_predates_claim boolean,
  resolving_record_unrelated_purpose boolean,
  adjudicated_by text,
  adjudicated_at timestamptz,
  note text
);

create table core.attestation (
  attestation_id bigint generated always as identity primary key,
  witness_id bigint not null references core.witness(witness_id),
  observation_id uuid not null references core.observation(observation_id) on delete restrict,
  custody text not null check (custody in
    ('signed-or-recorded-interview','bylined-quotation','deposition',
     'numbered-oral-history-accession','claimant-assertion-only','unknown')),
  custody_document_id uuid references core.source_document(document_id),
  -- who is ASSERTING this attestation: the lineage terminus
  asserting_document_id uuid not null references core.source_document(document_id),
  recorded_at date,
  note text
);
create index attestation_obs_idx on core.attestation(observation_id);
create index attestation_witness_idx on core.attestation(witness_id);

-- The two surviving judgement calls (BES §5.1.7, §4.4), both quorum-
-- adjudicated across model families and both logged. Disagreement is data.
create table core.judgement_log (
  judgement_id bigint generated always as identity primary key,
  kind text not null check (kind in ('lineage-counterfactual','ea-ordinal')),
  citation_id bigint references core.document_citation(citation_id),
  observation_id uuid references core.observation(observation_id),
  decision text not null,
  models_voting text[] not null default '{}',
  model_families text[] not null default '{}',
  disagreed boolean not null default false,
  defaulted_to_same_lineage boolean not null default false,
  decided_at timestamptz not null default now()
);
create index judgement_log_obs_idx on core.judgement_log(observation_id);

-- =====================================================================
-- 10. REFUTATION, NULL STATE, SEARCH COMPLETENESS
-- R is NOT F. F means nothing verified favours the claim. R means something
-- =====================================================================

-- REFUTER proposes; the register adjudicates. Proposal B read `state` off
-- this row and returned R if any affirmative observation was attached — an
create table core.refutation (
  refutation_id bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  proposed_state core.refutation_state not null check (proposed_state <> 'R0'),
  basis_observation_ids uuid[] not null default '{}',
  authority_document_id uuid references core.source_document(document_id),
  post_dating_impossibility jsonb,   -- claim_date vs evidence_date, machine-checkable
  participant_admission_document_id uuid references core.source_document(document_id),
  disinformation_operation_note text,
  narrative text not null,
  asserted_by text not null,
  asserted_at timestamptz not null default now(),
  -- Any R resting entirely on R2 is re-reviewed on a schedule (BES §8.5), and
  -- the register publishes its R-rate and R-reversal rate as telemetry.
  next_review_due date,
  reversed_at timestamptz,
  reversed_reason text
);
create index refutation_prop_idx on core.refutation(proposition_id) where reversed_at is null;

-- The alternative-hypothesis disposition table, published on every entry page.
create table core.alternative_disposition (
  disposition_id bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  null_code char(3) not null references registry.null_hypothesis(null_code),
  is_selected boolean not null default false,   -- the STRONGEST SURVIVING alternative
  disposition text not null check (disposition in
    ('selected-strongest','weaker-than-selected','excluded-by-evidence',
     'documented-dominant','not-applicable')),
  reasoning text not null,
  excluding_observation_ids uuid[] not null default '{}',
  assessed_by text not null,
  assessed_at timestamptz not null default now(),
  unique (proposition_id, null_code)
);
create unique index alternative_one_selected
  on core.alternative_disposition(proposition_id) where is_selected;

-- ---------------------------------------------------------------------
-- DERIVED null_state (BES §4.6). Not an agent assertion.
-- ---------------------------------------------------------------------
create or replace function core.derive_null_state(p_proposition_id uuid)
returns core.null_state language plpgsql stable as $$
declare has_d3 boolean; has_d2 boolean; documented boolean; explains_all boolean;
begin
  -- UNTESTED means the null was never adjudicated, not merely never typed.
  if not exists (select 1 from core.alternative_disposition
                  where proposition_id = p_proposition_id and is_selected) then
    return 'UNTESTED';
  end if;

  select exists (select 1 from core.observation o
                  where o.proposition_id = p_proposition_id
                    and o.membership = 'V' and o.magnitude >= 3 and o.null_excluding)
    into has_d3;
  if has_d3 then return 'EXCLUDED'; end if;

  select exists (select 1 from core.observation o
                  where o.proposition_id = p_proposition_id
                    and o.membership = 'V' and o.magnitude >= 2 and o.null_excluding)
    into has_d2;
  if has_d2 then return 'INSUFFICIENT'; end if;

  -- DOMINANT requires the null to be ITSELF affirmatively documented by >=1
  -- verified T1/T2 row, and to account for every row in V. SubTropolis has
  -- this; a candidate whose mundane explanation is merely plausible does not.
  select exists (select 1 from core.observation o
                  where o.proposition_id = p_proposition_id
                    and o.documents_null and o.prov_receipt_state = 'VERIFIED'
                    and o.prov_origin_tier in ('T1','T2'))
    into documented;
  select not exists (select 1 from core.observation o
                      where o.proposition_id = p_proposition_id
                        and o.membership = 'V' and o.null_excluding)
    into explains_all;

  return case when documented and explains_all then 'DOMINANT' else 'SURVIVING' end;
end $$;

-- ---------------------------------------------------------------------
-- SEARCH COMPLETENESS INDEX (BES §7.2).
-- [FIX-B] Denominator zero. Proposal B returned NULL, and its caller did
create or replace function core.search_completeness(p_proposition_id uuid)
returns table (numerator integer, denominator integer, sci numeric)
language sql stable as $$
  with applicable as (
    select pe.erp_profile_id, pe.searched
      from core.proposition_erp pe
     where pe.proposition_id = p_proposition_id
       and pe.applicable
       and pe.resolved_x in ('X1','X2','X3')
  ),
  searched as (
    select distinct a.erp_profile_id
      from applicable a
     where a.searched
        or exists (select 1 from core.search_receipt sr
                    where sr.proposition_id = p_proposition_id
                      and sr.erp_profile_id = a.erp_profile_id
                      and sr.outcome in ('POSITIVE','NEGATIVE'))
  )
  select (select count(*) from searched)::integer,
         (select count(*) from applicable)::integer,
         case when (select count(*) from applicable) = 0 then 1.000
              else round((select count(*) from searched)::numeric
                       / (select count(*) from applicable), 3) end
$$;

-- The published silence reading (BES §6.4), rendered verbatim beside the grade.
create or replace function core.silence_reading(p_proposition_id uuid)
returns core.silence_reading language sql stable as $$
  select case
    when exists (select 1 from core.proposition_erp pe
                  join registry.erp_profile ep using (erp_profile_id)
                 where pe.proposition_id = p_proposition_id and pe.applicable
                   and ep.silence_override = 'RECORD-DESTROYED')
      then 'RECORD-DESTROYED'::core.silence_reading
    -- Every applicable claim-property record class is X0: no public record of
    -- this class would be expected. The absence is not evidence against.
    when not exists (select 1 from core.proposition_erp pe
                      where pe.proposition_id = p_proposition_id and pe.applicable
                        and pe.resolved_x in ('X1','X2','X3'))
      then 'UNINFORMATIVE'::core.silence_reading
    when (select coalesce(sci,0) from core.search_completeness(p_proposition_id)) = 0
      then 'UNSEARCHED'::core.silence_reading
    when exists (select 1 from core.search_receipt sr
                  join registry.erp_profile ep using (erp_profile_id)
                 where sr.proposition_id = p_proposition_id and sr.outcome = 'NEGATIVE'
                   and ep.x_level in ('X1','X2','X3'))
      then 'INFORMATIVE'::core.silence_reading
    else 'UNSEARCHED'::core.silence_reading
  end
$$;

-- ---------------------------------------------------------------------
-- DERIVED REFUTATION STATE (BES §8 + the §8.4 gate).
create or replace function core.derive_refutation(p_proposition_id uuid)
returns core.refutation_state language plpgsql stable as $$
declare r3 boolean; r2 boolean; r1 boolean;
        u_r2_lineages integer; ns core.null_state; support_lineages integer;
begin
  -- R3 CONTRADICTED: >=1 verified, instance-scope, subject-bound, unsolicited
  -- row from a party with AUTHORITY OVER THE FACT directly stating the
  -- negation, or documenting non-construction, non-funding or cancellation.
  select exists (
    select 1 from core.observation o
     where o.proposition_id = p_proposition_id
       and o.refutation_class = 'R3-CONTRADICTED'
       and o.prov_receipt_state = 'VERIFIED'
       and o.scope = 'INSTANCE'
       and o.subject_binding_pass
       and o.prov_causal in ('UNSOLICITED','SOLICITED-3P')
       and o.gate_e_authority
       and o.derived_from_search_receipt_id is null      -- §8.4 affirmative gate
       and not o.rebutted
       and exists (select 1 from core.refutation rf
                    where rf.proposition_id = p_proposition_id and rf.reversed_at is null
                      and o.observation_id = any(rf.basis_observation_ids))
  ) into r3;
  if r3 then return 'R3'; end if;

  -- R2 AFFIRMATIVELY INCONSISTENT: >=2 INDEPENDENT-LINEAGE verified UNDERCUTS
  -- rows at D2+ whose content is improbable under the proposition (E0 under H),
  -- PLUS null_state = DOMINANT. Independence here is the graph property, not
  -- a count of rows.
  ns := core.derive_null_state(p_proposition_id);
  select count(distinct coalesce(c.component_root::text, o.observation_id::text))
    into u_r2_lineages
    from core.observation o
    left join lateral core.lineage_components(array[o.document_id]) c
           on c.document_id = o.document_id
   where o.proposition_id = p_proposition_id
     and o.membership = 'U' and o.magnitude >= 2
     and coalesce(o.improbable_under_h,false)
     and o.derived_from_search_receipt_id is null        -- §8.4 affirmative gate
     and not o.rebutted;
  r2 := coalesce(u_r2_lineages,0) >= 2 and ns = 'DOMINANT'
        and exists (select 1 from core.refutation rf
                     where rf.proposition_id = p_proposition_id
                       and rf.reversed_at is null and rf.proposed_state = 'R2');
  if r2 then return 'R2'; end if;

  -- R1 ORIGIN FABRICATED: the claim's SOLE origin lineage is shown fabricated
  -- — a participant admission, a documented disinformation or forgery
  -- operation, or a post-dating impossibility. Deterministic where the last.
  select core.lineage_count(p_proposition_id, 0::smallint) into support_lineages;
  select exists (
    select 1 from core.observation o
     where o.proposition_id = p_proposition_id
       and o.refutation_class = 'R1-ORIGIN-FABRICATED'
       and o.prov_receipt_state = 'VERIFIED'
       and o.derived_from_search_receipt_id is null      -- §8.4 affirmative gate
       and not o.rebutted
  ) into r1;
  if r1 and coalesce(support_lineages,0) <= 1 then return 'R1'; end if;

  return 'R0';
end $$;

-- =====================================================================
-- 11. GRADE(P) — the algorithm (BES §9.4).
-- Order is load-bearing: refutation first (it overrides all bands), then the
-- =====================================================================

create or replace function core.evaluate_proposition(p_proposition_id uuid)
returns jsonb language plpgsql stable as $$
declare
  p core.proposition; ent core.entity;
  n_v int; n_u int; n_v0 int; n_vclaim int; n_inert int;
  v_d4c int; v_d3c int; v_d2c int; v_d1 int; v_d0 int;
  l_d2 int; l_d3 int; l_d3_claim int; l_d2_place_excl int;
  has_t1t2 boolean; unrebutted_d3_u boolean;
  a1 boolean; a1alt boolean; a2 boolean; a3 boolean; a4 boolean; a5 boolean; a6 boolean;
  b1 boolean; b2 boolean; b3 boolean; b4 boolean;
  c1a boolean; c1b boolean; c1c boolean; c2 boolean; c3 boolean;
  d1 boolean; d2c boolean; e1 boolean; e2 boolean;
  ns core.null_state; refstate core.refutation_state;
  awarded core.grade; final core.grade; caps text[] := '{}';
  v_sci numeric; sci_num int; sci_den int;
  mirror_a1 boolean; place_w int; claim_w int;
  citogen boolean; limiting text; ceil core.grade; ceil_reason text;
  cs_m int; cs_n int; all_claim_x0 boolean; marginal boolean;
  cond jsonb;
begin
  select * into p from core.proposition where proposition_id = p_proposition_id;
  if p is null then raise exception 'no such proposition %', p_proposition_id; end if;
  select * into ent from core.entity where entity_id = p.entity_id;

  ---------------------------------------------------------------------
  -- Step 3 (§9.4): build V and U; compute the counts the bands are made of.
  ---------------------------------------------------------------------
  select count(*) filter (where membership='V'),
         count(*) filter (where membership='U'),
         count(*) filter (where membership='V0'),
         count(*) filter (where membership='INERT'),
         count(*) filter (where membership='V' and property_locus='CLAIM-PROPERTY'),
         count(*) filter (where membership='V' and property_locus='CLAIM-PROPERTY' and magnitude>=4),
         count(*) filter (where membership='V' and property_locus='CLAIM-PROPERTY' and magnitude>=3),
         count(*) filter (where membership='V' and property_locus='CLAIM-PROPERTY' and magnitude>=2),
         count(*) filter (where membership='V' and magnitude>=1),
         count(*) filter (where membership='V' and magnitude=0),
         bool_or(membership='V' and prov_origin_tier in ('T1','T2')),
         coalesce(sum(magnitude) filter (where membership='V' and property_locus='PLACE-PROPERTY'),0),
         coalesce(sum(magnitude) filter (where membership='V' and property_locus='CLAIM-PROPERTY'),0)
    into n_v, n_u, n_v0, n_inert, n_vclaim, v_d4c, v_d3c, v_d2c, v_d1, v_d0,
         has_t1t2, place_w, claim_w
    from core.observation where proposition_id = p_proposition_id;

  l_d2       := core.lineage_count(p_proposition_id, 2::smallint);
  l_d3       := core.lineage_count(p_proposition_id, 3::smallint);
  l_d3_claim := core.lineage_count_claim(p_proposition_id, 3::smallint);

  -- C1b: >=2 independent lineages of PLACE-PROPERTY rows at D2+ that the
  -- named null cannot JOINTLY account for. "Cannot account for" is the
  -- null_excluding test, carried per lineage rather than per row so four
  -- copies of one quadrangle reading remain one lineage.
  select count(*) into l_d2_place_excl
    from core.independent_lineages(p_proposition_id, 2::smallint) il
   where il.has_place_null_excluding;

  ns := core.derive_null_state(p_proposition_id);
  select numerator, denominator, sci into sci_num, sci_den, v_sci
    from core.search_completeness(p_proposition_id);

  -- An unrebutted verified UNDERCUTS at D3+ blocks A, B and C alike.
  -- Rebuttal is EXPLICIT (proposal A) or a stronger same-fact V row (B).
  select exists (
    select 1 from core.observation o
     where o.proposition_id = p_proposition_id and o.membership='U' and o.magnitude>=3
       and not o.rebutted
       and not exists (select 1 from core.observation x
                        where x.proposition_id = p_proposition_id and x.membership='V'
                          and x.fact_key is not null and x.fact_key = o.fact_key
                          and x.magnitude >= o.magnitude)
  ) into unrebutted_d3_u;

  citogen := exists (select 1 from core.citogenesis_loop
                      where proposition_id = p_proposition_id and state='confirmed');

  ---------------------------------------------------------------------
  -- Step 1: REFUTATION, checked FIRST, overriding all bands.
  ---------------------------------------------------------------------
  refstate := core.derive_refutation(p_proposition_id);

  ---------------------------------------------------------------------
  -- Step 5: the bands. The bands ARE the conditions.
  a1 := (v_d4c >= 1) or (l_d3_claim >= 2);

  a1alt := p.class in ('EXIST','EXTENT','LOCATE','FEATURE')
    and (select count(*) from core.observation o
          join core.attestation at on at.observation_id = o.observation_id
          join core.witness w on w.witness_id = at.witness_id
         where o.proposition_id = p_proposition_id and o.membership='V'
           and o.direct_observation and o.lawful_physical_access
           and o.georef_control_point_match and w.resolvable
           and at.custody in ('signed-or-recorded-interview','bylined-quotation',
                              'deposition','numbered-oral-history-accession')) >= 2
    and exists (select 1 from core.observation o
                 where o.proposition_id = p_proposition_id and o.membership='V'
                   and o.prov_origin_tier='T1' and o.property_locus='PLACE-PROPERTY');

  a2 := not exists (select 1 from core.observation o
                     where o.proposition_id = p_proposition_id and o.membership='V'
                       and o.magnitude>=3
                       and (not o.subject_binding_pass or o.prov_receipt_state<>'VERIFIED'));
  a3 := (ns = 'EXCLUDED');
  a4 := not unrebutted_d3_u;
  a5 := not exists (select 1 from core.observation o
                     where o.proposition_id = p_proposition_id and o.membership='V'
                       and o.magnitude>=3
                       and o.prov_causal not in ('UNSOLICITED','SOLICITED-3P'));

  -- A6 forgery pricing. Forging a document onto a public mirror is cheap;
  -- forging one into cia.gov, govinfo.gov or a county recorder's index with
  -- matching issuer metadata is not.
  select coalesce(bool_or(rr.mirror_only),false) into mirror_a1
    from core.observation o join core.retrieval_receipt rr on rr.receipt_id = o.receipt_id
   where o.proposition_id = p_proposition_id and o.membership='V' and o.magnitude>=3;
  a6 := (not mirror_a1) or l_d2 >= 2;

  b1 := (l_d3 >= 2) or (l_d2 >= 3 and has_t1t2);
  b2 := ns in ('EXCLUDED','INSUFFICIENT');
  b3 := not unrebutted_d3_u;
  b4 := n_vclaim >= 1;

  c1a := v_d2c >= 1;
  c1b := l_d2_place_excl >= 2;
  -- C1c candidate-set rule: C is the CEILING of this path.
  select cs.documented_instance_count, registry.candidate_set_m(cs.candidate_set_id)
    into cs_n, cs_m
    from registry.candidate_set cs where cs.candidate_set_id = p.candidate_set_id;
  c1c := p.candidate_set_id is not null
     and registry.candidate_set_dilution_ok(p.candidate_set_id)
     and exists (select 1 from registry.candidate_set cs
                  join core.proposition_rollup pr
                    on pr.proposition_id = cs.program_proposition_id
                 where cs.candidate_set_id = p.candidate_set_id and pr.grade in ('A','B'))
     and exists (select 1 from core.observation o
                  where o.proposition_id = p_proposition_id and o.membership='V'
                    and o.scope='INSTANCE' and o.property_locus='CLAIM-PROPERTY'
                    and o.magnitude>=1);
  c2 := ns <> 'UNTESTED';
  c3 := not unrebutted_d3_u;

  d1  := (v_d1 >= 1) or (v_d0 >= 2);
  d2c := ns in ('SURVIVING','DOMINANT','UNTESTED');
  e1  := n_v > 0;
  e2  := not exists (select 1 from core.observation o
                      where o.proposition_id = p_proposition_id
                        and o.membership='V' and o.magnitude>=2);

  if refstate <> 'R0' then
    awarded := 'R';
  else
    awarded := case
      when (a1 or a1alt) and a2 and a3 and a4 and a5 and a6 then 'A'
      when b1 and b2 and b3 and b4                          then 'B'
      when (c1a or c1b or c1c) and c2 and c3                then 'C'
      when d1 and d2c                                       then 'D'
      when e1 and e2                                        then 'E'
      else 'F' end::core.grade;
  end if;

  cond := jsonb_build_object(
    'R', jsonb_build_object('state', refstate,
         'note','R is not F. F means nothing verified favours the claim; R means something affirmatively resolves against it.'),
    'A', jsonb_build_object('A1',a1,'A1-alt',a1alt,'A2',a2,'A3',a3,'A4',a4,'A5',a5,'A6',a6),
    'B', jsonb_build_object('B1',b1,'B2',b2,'B3',b3,'B4',b4),
    'C', jsonb_build_object('C1a',c1a,'C1b',c1b,'C1c',c1c,'C2',c2,'C3',c3),
    'D', jsonb_build_object('D1',d1,'D2cond',d2c),
    'E', jsonb_build_object('E1',e1,'E2',e2));

  ---------------------------------------------------------------------
  -- Step 6: the CAPS (§9.3). Caps only lower. R and X are unranked and are
  -- not capped — they are not points on the ladder.
  ---------------------------------------------------------------------
  final := awarded;
  if core.grade_rank(awarded) is not null then
    if l_d2 <= 1 and not (a1 or a1alt) then
      caps := caps || 'CAP-1'::text; final := core.grade_min(final,'C'); end if;

    -- CAP-2 splits by proposition class. A function, control or hardening
    -- claim carried entirely by attributes of the PLACE has no support for
    if n_vclaim = 0 then
      if p.class in ('EXIST','EXTENT','LOCATE','FEATURE','TYPOLOGY') then
        caps := caps || 'CAP-2a'::text; final := core.grade_min(final,'D');
      else
        caps := caps || 'CAP-2b'::text; final := core.grade_min(final,'E');
      end if;
    end if;

    if citogen then caps := caps || 'CAP-3'::text; final := core.grade_min(final,'E'); end if;

    if n_v > 0 and not exists (
         select 1 from core.observation o
          join core.source_document d on d.document_id = o.document_id
         where o.proposition_id = p_proposition_id and o.membership='V'
           and coalesce(d.document_date, d.first_observed_date) <= date '2022-11-30') then
      caps := caps || 'CAP-4'::text; final := core.grade_min(final,'D'); end if;

    if n_v = 0 then caps := caps || 'CAP-5'::text; final := core.grade_min(final,'F'); end if;
    if mirror_a1 and not a6 then caps := caps || 'CAP-6'::text; final := core.grade_min(final,'B'); end if;
    if ns = 'UNTESTED' then caps := caps || 'CAP-7'::text; final := core.grade_min(final,'D'); end if;

    if c1c and not (c1a or c1b) then
      caps := caps || 'CAP-C1c'::text; final := core.grade_min(final,'C'); end if;
  end if;

  ---------------------------------------------------------------------
  -- Step 2 (applied here, after R short-circuits): the SCI floor.
  if coalesce(v_sci,0) < 0.5 and final in ('D','E','F') then
    final := 'X';
    caps := caps || 'SCI-FLOOR'::text;
  end if;

  ---------------------------------------------------------------------
  -- Steps 9-11: limiting condition, ceiling, marginal flag.
  ---------------------------------------------------------------------
  limiting := case final
    when 'A' then null
    when 'B' then case when not (a1 or a1alt) then 'A1 (no dispositive record; no two D3 claim-property lineages)'
                       when not a2 then 'A2 (an identifier did not resolve or did not bind to the subject)'
                       when not a3 then 'A3 (null_state is not EXCLUDED)'
                       when not a4 then 'A4 (unrebutted D3+ undercut)'
                       when not a5 then 'A5 (a D3+ row is solicited by the claimant)'
                       else 'A6 (mirror-only band-A item without independent corroboration)' end
    when 'C' then case when not b1 then 'B1 (independent lineage count)'
                       when not b2 then 'B2 (null_state)'
                       when not b3 then 'B3 (unrebutted D3+ undercut)'
                       else 'B4 (no claim-property row in V)' end
    when 'D' then case when not (c1a or c1b or c1c) then 'C1 (no D2+ claim-property row; no two null-excluding place lineages)'
                       when not c2 then 'C2 (null untested)'
                       else 'C3 (unrebutted D3+ undercut)' end
    when 'E' then case when not d1 then 'D1 (nothing above D0)' else 'D2cond (null_state precludes D)' end
    when 'F' then case when not e1 then 'E1 (V is empty)' else 'E2 (V holds a D2+ row but no band is satisfied)' end
    when 'X' then format('INSUFFICIENT SEARCH (SCI %s of %s profiles)', sci_num, sci_den)
    when 'R' then 'refuted: ' || refstate::text
    else null end;
  if array_length(caps,1) is not null and final is distinct from awarded then
    limiting := coalesce(limiting,'') || ' [capped by ' || array_to_string(caps,', ') || ']';
  end if;

  -- The ceiling: the best grade this proposition could reach on the evidence
  -- classes that could exist at all. at_ceiling is what lets the register say
  -- "B, and B is the most this record could ever support" rather than implying
  -- the researcher simply stopped early.
  select not exists (select 1 from core.proposition_erp pe
                      where pe.proposition_id = p_proposition_id and pe.applicable
                        and pe.resolved_x in ('X1','X2','X3'))
    into all_claim_x0;
  if citogen then
    ceil := 'E'; ceil_reason := 'citogenesis confirmed (CAP-3)';
  elsif coalesce(all_claim_x0,false) and n_vclaim = 0 then
    ceil := case when p.class in ('EXIST','EXTENT','LOCATE','FEATURE','TYPOLOGY')
                 then 'D'::core.grade else 'E'::core.grade end;
    ceil_reason := 'no claim-property record class is expected to exist for a facility '
                || 'of this type, in this period, under this authority (every applicable '
                || 'expected-record profile resolves to X0)';
  else
    ceil := 'A'; ceil_reason := null;
  end if;

  marginal := (l_d2 = 2 and final='B') or (l_d3 = 2 and final in ('A','B'))
    or (l_d2 = 1 and final='C')
    or exists (select 1 from core.judgement_log jl
                where jl.disagreed or jl.defaulted_to_same_lineage
                  and jl.observation_id in (select observation_id from core.observation
                                             where proposition_id = p_proposition_id));

  return jsonb_build_object(
    'grade', final, 'awarded_band', awarded, 'applied_caps', to_jsonb(caps),
    'refutation_state', refstate, 'null_state', ns, 'null_code', p.null_code,
    'conditions', cond,
    'l_d2', l_d2, 'l_d3', l_d3, 'l_d3_claim', l_d3_claim,
    'v_count', n_v, 'u_count', n_u, 'v0_count', n_v0, 'inert_count', n_inert,
    'v_claim_count', n_vclaim, 'v_d4_claim', v_d4c, 'v_d3_claim', v_d3c, 'v_d2_claim', v_d2c,
    'sci', v_sci, 'sci_numerator', sci_num, 'sci_denominator', sci_den,
    'place_derived_weight', place_w, 'claim_derived_weight', claim_w,
    'silence_reading', core.silence_reading(p_proposition_id),
    'base_rate_reading', (select br.reading from registry.base_rate br
                           where br.proposition_class = p.class
                             and br.reference_class = coalesce(p.reference_class, ent.reference_class, 'RC6')
                             and br.function_set = p.function_set),
    'ceiling', ceil, 'ceiling_reason', ceil_reason,
    'at_ceiling', (final = ceil),
    'citogenesis', citogen, 'mirror_only_a1', mirror_a1,
    'limiting_condition', limiting, 'marginal_flag', coalesce(marginal,false));
end $$;

comment on function core.evaluate_proposition is
  'GRADE(P) per BES §9.4. Pure and stable: given the rows, the answer is the same for everyone, forever. Returns the full condition vector, never just a letter, because the decomposition IS the product.';

-- =====================================================================
-- 12. GRADES ARE EVENTS (requirement 6), AND THE ROLLUP IS A CACHE.
-- There is NO grade column on core.proposition. A grade is an append-only
-- =====================================================================

create table core.grade_event (
  grade_event_id uuid primary key default gen_random_uuid(),
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  seq bigint generated always as identity,
  -- clock_timestamp(), NOT now(): now() is transaction-constant, so two
  -- regrades inside one ingest transaction would be indistinguishable by time
  -- and the history would be unreconstructible at sub-transaction resolution.
  occurred_at timestamptz not null default clock_timestamp(),

  grade_from core.grade,
  grade      core.grade not null,          -- after caps AND clamp
  awarded_band core.grade not null,        -- before caps and clamp
  grade_pre_clamp core.grade not null,     -- after caps, before clamp
  applied_caps text[] not null default '{}',
  clamped_by_proposition_id uuid references core.proposition(proposition_id),

  condition_results jsonb not null,
  ceiling core.grade, ceiling_reason text,
  at_ceiling boolean not null default false,
  limiting_condition text,
  marginal_flag boolean not null default false,

  refutation_state core.refutation_state not null default 'R0',
  null_state core.null_state not null,
  null_code char(3) not null references registry.null_hypothesis(null_code),
  silence_reading core.silence_reading not null,
  base_rate_reading core.base_rate_reading,
  reference_class core.reference_class,
  citogenesis boolean not null default false,

  l_d2 integer not null default 0, l_d3 integer not null default 0,
  v_count integer not null default 0, u_count integer not null default 0,
  v_claim_count integer not null default 0, v0_count integer not null default 0,
  sci_numerator integer, sci_denominator integer, sci numeric,
  place_derived_weight integer not null default 0,
  claim_derived_weight integer not null default 0,

  transition_cause core.transition_cause not null,
  transition_note text,
  -- §11.2: instrument drift is suppressed from the public confidence chart.
  -- The chart shows evidence events, not instrument drift.
  is_instrument_drift boolean generated always as
    (transition_cause in ('SCORER-CHANGE','TABLE-VERSION-CHANGE','RESCORE-NOISE')) stored,

  -- what moved it (requirement 6)
  triggering_observation_ids uuid[] not null default '{}',

  scorer_model_id text references registry.scorer_model(scorer_model_id),
  scorer_model_family text,
  rubric_version text not null references registry.rubric_version(rubric_version),
  tier_version_id bigint references registry.table_version(table_version_id),
  diagnosticity_version_id bigint references registry.table_version(table_version_id),
  erp_version_id bigint references registry.table_version(table_version_id),
  candidate_set_version_id bigint references registry.table_version(table_version_id),

  -- Reconstruction key: md5 over the ordered (observation, membership,
  -- signed_weight) tuple set. Two events with the same hash saw the same
  -- evidence; a grade change with an unchanged hash is instrument drift, and
  -- the transition_cause had better say so.
  evidence_state_hash text not null,

  -- The FULL input witness, so a past grade is reconstructible even after the
  -- curated tables are re-derived and re-versioned (BES §12.5).
  snapshot jsonb not null,

  computed_at timestamptz not null default now(),
  is_published boolean not null default false,
  published_at timestamptz,
  is_blind_double_score boolean not null default false,
  double_score_of_id uuid references core.grade_event(grade_event_id),

  constraint grade_x_has_low_sci
    check (grade <> 'X' or sci is null or sci < 0.5),
  constraint grade_published_has_date
    check (not is_published or published_at is not null)
);
create index grade_event_prop_seq  on core.grade_event(proposition_id, seq desc);
create index grade_event_published on core.grade_event(proposition_id, published_at desc)
  where is_published;
create index grade_event_cause_idx on core.grade_event(transition_cause);
create index grade_event_time_brin on core.grade_event using brin (occurred_at);

-- Append-only. History that can be edited is not history. The only permitted
-- mutation is the publication pair, and the trigger PROVES it by diffing the
-- whole row rather than trusting a column list.
create or replace function core.grade_event_immutable() returns trigger
language plpgsql as $$
begin
  -- Generated columns are computed after BEFORE-row triggers, so
  -- new.is_instrument_drift is still null here while old's is populated. It
  -- is excluded from the diff for that reason and not as a loophole: it is a
  -- pure function of transition_cause, which the diff does cover.
  if tg_op = 'UPDATE'
     and (to_jsonb(new) - 'is_published' - 'published_at' - 'is_instrument_drift')
       = (to_jsonb(old) - 'is_published' - 'published_at' - 'is_instrument_drift') then
    return new;
  end if;
  raise exception 'core.grade_event is append-only (attempted % on %)', tg_op, old.grade_event_id;
end $$;
create trigger grade_event_no_mutate before update on core.grade_event
  for each row execute function core.grade_event_immutable();

-- The exact evidence set in scope at scoring time. THIS is what makes "show
-- what evidence moved it and when" answerable rather than merely asserted.
create table core.grade_event_observation (
  grade_event_id uuid not null references core.grade_event(grade_event_id) on delete restrict,
  observation_id uuid not null references core.observation(observation_id) on delete restrict,
  membership_at_scoring core.evidence_membership not null,
  signed_weight_at_scoring smallint not null,
  lineage_key_at_scoring text,
  primary key (grade_event_id, observation_id)
);
create index grade_event_obs_obs on core.grade_event_observation(observation_id);

-- The materialised read model. Every public read hits this and the map view;
-- neither walks the evidence graph.
create table core.proposition_rollup (
  proposition_id uuid primary key references core.proposition(proposition_id) on delete restrict,
  entity_id uuid not null references core.entity(entity_id) on delete restrict,
  class core.proposition_class not null,

  grade core.grade not null default 'X',
  grade_pre_clamp core.grade not null default 'X',
  awarded_band core.grade not null default 'X',
  grade_rank smallint,
  clamped_by_proposition_id uuid references core.proposition(proposition_id),

  ceiling core.grade, ceiling_reason text,
  at_ceiling boolean not null default false,
  limiting_condition text,
  marginal_flag boolean not null default false,
  applied_caps text[] not null default '{}',

  refutation_state core.refutation_state not null default 'R0',
  null_state core.null_state not null default 'UNTESTED',
  silence_reading core.silence_reading not null default 'UNSEARCHED',
  base_rate_reading core.base_rate_reading,
  reference_class core.reference_class,
  citogenesis boolean not null default false,

  sci numeric, sci_numerator integer, sci_denominator integer,
  l_d2 integer not null default 0, l_d3 integer not null default 0,
  v_count integer not null default 0, u_count integer not null default 0,
  v_claim_count integer not null default 0, v0_count integer not null default 0,
  inert_count integer not null default 0,
  -- §10.2 TWO BARS, ALWAYS: a reader sees at a glance how much of the grade
  -- is the mountain and how much is the claim.
  place_derived_weight integer not null default 0,
  claim_derived_weight integer not null default 0,

  condition_results jsonb not null default '{}'::jsonb,
  -- The evidence set this cached grade was computed from. A grade_event is
  -- written only when the grade MOVES, so the event's hash goes stale the
  evidence_state_hash text not null default '',
  computed_at timestamptz not null default now(),
  current_grade_event_id uuid references core.grade_event(grade_event_id),
  is_published boolean not null default false
);
create index prop_rollup_entity_idx on core.proposition_rollup(entity_id);
create index prop_rollup_grade_idx  on core.proposition_rollup(grade);
create index prop_rollup_rank_idx   on core.proposition_rollup(grade_rank desc);
create index prop_rollup_class_idx  on core.proposition_rollup(class, grade);
create index prop_rollup_pub_idx    on core.proposition_rollup(is_published) where is_published;

comment on table core.proposition_rollup is
  'Materialised read model, fully recomputable from core.observation via core.recompute_proposition(). The grade is never stored knowledge, only cached knowledge.';

-- The register's own publication log. Feeds §5.1.8 self-exclusion and the
-- §11.3 ratchet.
create table core.publication_log (
  publication_log_id bigint generated always as identity primary key,
  entity_id uuid not null references core.entity(entity_id),
  proposition_id uuid references core.proposition(proposition_id),
  published_at timestamptz not null default now(),
  event text not null check (event in ('FIRST-PUBLISH','REPUBLISH','WITHDRAW')),
  actor text not null default 'curator',
  note text
);
create index publication_log_entity on core.publication_log(entity_id, published_at);

create table core.clamp_event (
  clamp_event_id bigint generated always as identity primary key,
  grade_event_id uuid not null references core.grade_event(grade_event_id),
  child_proposition_id uuid not null references core.proposition(proposition_id),
  parent_proposition_id uuid not null references core.proposition(proposition_id),
  grade_before core.grade not null,
  grade_after core.grade not null,
  clamped_at timestamptz not null default now()
);
create index clamp_event_child_idx on core.clamp_event(child_proposition_id);

-- Dirty queue (requirement 10). Ingest writes observations; triggers enqueue;
-- a worker drains. Nothing recomputes the whole table, and a bulk sweep pays
-- one grade computation per touched proposition, not N.
create table ingest.regrade_queue (
  proposition_id uuid primary key references core.proposition(proposition_id) on delete restrict,
  enqueued_at timestamptz not null default now(),
  reason core.transition_cause not null default 'NEW-VERIFICATION',
  -- Parents must be regraded before children or the monotone clamp reads a
  -- stale parent. Lower priority number drains first.
  priority smallint not null default 100,
  attempts integer not null default 0,
  last_error text
);
create index regrade_queue_order on ingest.regrade_queue(priority, enqueued_at);

-- =====================================================================
-- 13. RECOMPUTE, CLAMP, RATCHET, DRAIN.
-- =====================================================================

-- The reconstruction key: a hash over the ordered (observation, membership,
-- signed_weight) tuple set. Two gradings with the same hash saw the same
-- evidence, so a grade change with an unchanged hash is instrument drift and
-- the transition_cause had better say so.
create or replace function core.evidence_state_hash(p_proposition_id uuid)
returns text language sql stable as $$
  select md5(coalesce(string_agg(
           observation_id::text||':'||membership::text||':'||signed_weight::text,
           ',' order by observation_id), ''))
    from core.observation where proposition_id = p_proposition_id
$$;

-- The EXIST proposition of an entity: the clamp parent, and unambiguous by
-- the proposition_one_exist unique index.
create or replace function core.clamp_parent(p_proposition_id uuid)
returns uuid language sql stable as $$
  select coalesce(p.parent_proposition_id,
                  (select x.proposition_id from core.proposition x
                    where x.entity_id = p.entity_id and x.class = 'EXIST'
                      and x.proposition_id <> p.proposition_id
                    order by x.created_at limit 1))
    from core.proposition p where p.proposition_id = p_proposition_id
$$;

-- Recompute one proposition and upsert its rollup. Pure read + one upsert.
-- O(observations on THIS proposition), never O(table).
create or replace function core.recompute_proposition(p_proposition_id uuid)
returns jsonb language plpgsql as $$
declare
  ev jsonb; p core.proposition; parent uuid; parent_grade core.grade;
  pre_clamp core.grade; final core.grade; clamped_by uuid; ehash text;
begin
  select * into p from core.proposition where proposition_id = p_proposition_id;
  ev := core.evaluate_proposition(p_proposition_id);
  pre_clamp := (ev->>'grade')::core.grade;
  final := pre_clamp;

  -- THE MONOTONE CLAMP (BES §1.4). A published child grade may not exceed its
  -- parent's. PROGRAM and ORIGIN are EXEMPT — that exemption is what makes
  if not p.clamp_exempt and p.class <> 'EXIST' then
    parent := core.clamp_parent(p_proposition_id);
    if parent is not null then
      select grade into parent_grade from core.proposition_rollup where proposition_id = parent;
      if parent_grade is not null and core.grade_min(pre_clamp, parent_grade) is distinct from pre_clamp then
        final := core.grade_min(pre_clamp, parent_grade);
        clamped_by := parent;
      end if;
    end if;
  end if;

  insert into core.proposition_rollup as pr (
    proposition_id, entity_id, class, grade, grade_pre_clamp, awarded_band, grade_rank,
    clamped_by_proposition_id, ceiling, ceiling_reason, at_ceiling, limiting_condition,
    marginal_flag, applied_caps, refutation_state, null_state, silence_reading,
    base_rate_reading, reference_class, citogenesis, sci, sci_numerator, sci_denominator,
    l_d2, l_d3, v_count, u_count, v_claim_count, v0_count, inert_count,
    place_derived_weight, claim_derived_weight, condition_results,
    evidence_state_hash, computed_at)
  values (
    p_proposition_id, p.entity_id, p.class, final, pre_clamp,
    (ev->>'awarded_band')::core.grade, core.grade_rank(final), clamped_by,
    (ev->>'ceiling')::core.grade, ev->>'ceiling_reason',
    (final = (ev->>'ceiling')::core.grade), ev->>'limiting_condition',
    (ev->>'marginal_flag')::boolean,
    array(select jsonb_array_elements_text(ev->'applied_caps')),
    (ev->>'refutation_state')::core.refutation_state,
    (ev->>'null_state')::core.null_state,
    (ev->>'silence_reading')::core.silence_reading,
    nullif(ev->>'base_rate_reading','')::core.base_rate_reading,
    coalesce(p.reference_class, (select reference_class from core.entity where entity_id = p.entity_id)),
    (ev->>'citogenesis')::boolean,
    nullif(ev->>'sci','')::numeric, (ev->>'sci_numerator')::int, (ev->>'sci_denominator')::int,
    (ev->>'l_d2')::int, (ev->>'l_d3')::int, (ev->>'v_count')::int, (ev->>'u_count')::int,
    (ev->>'v_claim_count')::int, (ev->>'v0_count')::int, (ev->>'inert_count')::int,
    (ev->>'place_derived_weight')::int, (ev->>'claim_derived_weight')::int,
    ev->'conditions', core.evidence_state_hash(p_proposition_id), now())
  on conflict (proposition_id) do update set
    grade=excluded.grade, grade_pre_clamp=excluded.grade_pre_clamp,
    awarded_band=excluded.awarded_band, grade_rank=excluded.grade_rank,
    clamped_by_proposition_id=excluded.clamped_by_proposition_id,
    ceiling=excluded.ceiling, ceiling_reason=excluded.ceiling_reason,
    at_ceiling=excluded.at_ceiling, limiting_condition=excluded.limiting_condition,
    marginal_flag=excluded.marginal_flag, applied_caps=excluded.applied_caps,
    refutation_state=excluded.refutation_state, null_state=excluded.null_state,
    silence_reading=excluded.silence_reading, base_rate_reading=excluded.base_rate_reading,
    reference_class=excluded.reference_class, citogenesis=excluded.citogenesis,
    sci=excluded.sci, sci_numerator=excluded.sci_numerator,
    sci_denominator=excluded.sci_denominator,
    l_d2=excluded.l_d2, l_d3=excluded.l_d3, v_count=excluded.v_count,
    u_count=excluded.u_count, v_claim_count=excluded.v_claim_count,
    v0_count=excluded.v0_count, inert_count=excluded.inert_count,
    place_derived_weight=excluded.place_derived_weight,
    claim_derived_weight=excluded.claim_derived_weight,
    condition_results=excluded.condition_results,
    evidence_state_hash=excluded.evidence_state_hash, computed_at=now();

  return ev || jsonb_build_object('grade', final, 'grade_pre_clamp', pre_clamp,
                                  'clamped_by', clamped_by);
end $$;

-- Recompute, and if the grade moved, append an immutable event.
-- §11.3 THE ASYMMETRY: a grade may RISE only on newly verified evidence whose
-- [FIX-B] Proposal B's ratchet blocked the rise if ANY counted observation
create or replace function core.apply_grade(
  p_proposition_id uuid,
  p_cause core.transition_cause default 'NEW-VERIFICATION',
  p_scorer text default null,
  p_note text default null,
  p_blind_double boolean default false)
returns core.grade language plpgsql as $$
declare
  ev jsonb; prev core.grade; prev_event uuid; final core.grade;
  first_pub timestamptz; trig uuid[]; ehash text; new_id uuid; fam text;
  p core.proposition; ratchet_ok boolean := true;
begin
  select * into p from core.proposition where proposition_id = p_proposition_id;
  select grade, current_grade_event_id into prev, prev_event
    from core.proposition_rollup where proposition_id = p_proposition_id;

  ev := core.recompute_proposition(p_proposition_id);
  final := (ev->>'grade')::core.grade;

  -- Which observations arrived since the last grade event: these are what
  -- moved it, and these are what the ratchet judges.
  select coalesce(array_agg(o.observation_id),'{}') into trig
    from core.observation o
   where o.proposition_id = p_proposition_id
     and o.asserted_at > coalesce(
           (select max(occurred_at) from core.grade_event
             where proposition_id = p_proposition_id and not is_blind_double_score),
           '-infinity'::timestamptz);

  if prev is not null
     and core.grade_rank(final) is not null and core.grade_rank(prev) is not null
     and core.grade_rank(final) > core.grade_rank(prev)
     and p_cause not in ('SCORER-CHANGE','TABLE-VERSION-CHANGE','RESCORE-NOISE',
                         'NEW-DISCLOSURE','MERGE','SPLIT')
  then
    select min(pl.published_at) into first_pub
      from core.publication_log pl
     where pl.entity_id = p.entity_id and pl.event = 'FIRST-PUBLISH';
    if first_pub is not null then
      ratchet_ok := exists (
        select 1 from core.observation o
        join core.source_document d on d.document_id = o.document_id
        where o.observation_id = any(trig)
          and o.membership = 'V'
          and d.document_date is not null
          and d.document_date <= first_pub::date
          -- §5.1.8: the register's own echo can never lift its own grade.
          and not d.register_echo_quarantined);
    end if;
  end if;

  if not ratchet_ok then
    update core.proposition_rollup
       set grade = prev, grade_rank = core.grade_rank(prev),
           limiting_condition = coalesce(limiting_condition,'')
             || ' [§11.3 ratchet: upward movement withheld — no newly verified '
             || 'supporting document predates the register''s own publication]'
     where proposition_id = p_proposition_id;
    return prev;
  end if;

  ehash := core.evidence_state_hash(p_proposition_id);
  select model_family into fam from registry.scorer_model where scorer_model_id = p_scorer;

  if prev is distinct from final or prev is null or p_blind_double then
    insert into core.grade_event (
      proposition_id, grade_from, grade, awarded_band, grade_pre_clamp, applied_caps,
      clamped_by_proposition_id, condition_results, ceiling, ceiling_reason, at_ceiling,
      limiting_condition, marginal_flag, refutation_state, null_state, null_code,
      silence_reading, base_rate_reading, reference_class, citogenesis,
      l_d2, l_d3, v_count, u_count, v_claim_count, v0_count,
      sci_numerator, sci_denominator, sci, place_derived_weight, claim_derived_weight,
      transition_cause, transition_note, triggering_observation_ids,
      scorer_model_id, scorer_model_family, rubric_version, evidence_state_hash,
      snapshot, is_blind_double_score)
    values (
      p_proposition_id, prev, final, (ev->>'awarded_band')::core.grade,
      (ev->>'grade_pre_clamp')::core.grade,
      array(select jsonb_array_elements_text(ev->'applied_caps')),
      nullif(ev->>'clamped_by','')::uuid, ev->'conditions',
      (ev->>'ceiling')::core.grade, ev->>'ceiling_reason', (ev->>'at_ceiling')::boolean,
      ev->>'limiting_condition', (ev->>'marginal_flag')::boolean,
      (ev->>'refutation_state')::core.refutation_state,
      (ev->>'null_state')::core.null_state, p.null_code,
      (ev->>'silence_reading')::core.silence_reading,
      nullif(ev->>'base_rate_reading','')::core.base_rate_reading,
      coalesce(p.reference_class,(select reference_class from core.entity where entity_id=p.entity_id)),
      (ev->>'citogenesis')::boolean,
      (ev->>'l_d2')::int, (ev->>'l_d3')::int, (ev->>'v_count')::int, (ev->>'u_count')::int,
      (ev->>'v_claim_count')::int, (ev->>'v0_count')::int,
      (ev->>'sci_numerator')::int, (ev->>'sci_denominator')::int, nullif(ev->>'sci','')::numeric,
      (ev->>'place_derived_weight')::int, (ev->>'claim_derived_weight')::int,
      p_cause, p_note, trig, p_scorer, fam, p.rubric_version, ehash,
      ev, p_blind_double)
    returning grade_event_id into new_id;

    -- Snapshot the evidence set. This is what makes the event reconstructable
    -- after the curated tables are re-derived.
    insert into core.grade_event_observation
      (grade_event_id, observation_id, membership_at_scoring, signed_weight_at_scoring)
    select new_id, observation_id, membership, signed_weight
      from core.observation where proposition_id = p_proposition_id;

    if not p_blind_double then
      update core.proposition_rollup set current_grade_event_id = new_id
       where proposition_id = p_proposition_id;

      if nullif(ev->>'clamped_by','') is not null then
        insert into core.clamp_event (grade_event_id, child_proposition_id,
                                      parent_proposition_id, grade_before, grade_after)
        values (new_id, p_proposition_id, (ev->>'clamped_by')::uuid,
                (ev->>'grade_pre_clamp')::core.grade, final);
      end if;

      -- A parent's move invalidates every child's clamp. Re-queue them.
      if p.class = 'EXIST' then
        insert into ingest.regrade_queue (proposition_id, reason, priority)
        select x.proposition_id, 'CLAMP', 200
          from core.proposition x
         where x.entity_id = p.entity_id and not x.clamp_exempt and x.class <> 'EXIST'
        on conflict (proposition_id) do update set enqueued_at = now();
      end if;
    end if;
  end if;

  delete from ingest.regrade_queue where proposition_id = p_proposition_id;
  return final;
end $$;

-- Enqueue on every write that can move a grade. Parents get priority so the
-- clamp never reads a stale parent within one drain.
create or replace function core.enqueue_regrade() returns trigger
language plpgsql as $$
declare pid uuid; cls core.proposition_class;
begin
  -- Publishing an entity flips publication_state on every one of its
  -- observations. That is a visibility change, not an evidence change, and
  if tg_op = 'UPDATE'
     and (to_jsonb(new) - 'publication_state') = (to_jsonb(old) - 'publication_state') then
    return coalesce(new, old);
  end if;

  pid := coalesce(
    case tg_table_name when 'proposition' then coalesce(new.proposition_id, old.proposition_id)
         else null end,
    (to_jsonb(coalesce(new,old))->>'proposition_id')::uuid);
  if pid is null then return coalesce(new, old); end if;
  select class into cls from core.proposition where proposition_id = pid;
  insert into ingest.regrade_queue (proposition_id, reason, priority)
  values (pid,
          case tg_table_name
            when 'search_receipt' then 'NEW-SEARCH'::core.transition_cause
            when 'refutation' then 'REFUTATION'::core.transition_cause
            else 'NEW-VERIFICATION'::core.transition_cause end,
          case when cls = 'EXIST' then 10 else 100 end)
  on conflict (proposition_id) do update set enqueued_at = now(),
    priority = least(ingest.regrade_queue.priority, excluded.priority);
  return coalesce(new, old);
end $$;

create trigger observation_regrade after insert or update on core.observation
  for each row execute function core.enqueue_regrade();
create trigger search_receipt_regrade after insert or update on core.search_receipt
  for each row execute function core.enqueue_regrade();
create trigger proposition_erp_regrade after insert or update on core.proposition_erp
  for each row execute function core.enqueue_regrade();
create trigger refutation_regrade after insert or update on core.refutation
  for each row execute function core.enqueue_regrade();
create trigger alt_disposition_regrade after insert or update on core.alternative_disposition
  for each row execute function core.enqueue_regrade();
create trigger citogenesis_regrade after insert or update on core.citogenesis_loop
  for each row execute function core.enqueue_regrade();

-- Adding a candidate DILUTES every member (BES §9.2 C1c): M moves for the
-- whole set, so the whole set is re-queued with cause CANDIDATE-SET-CHANGE.
create or replace function core.enqueue_candidate_set_regrade() returns trigger
language plpgsql as $$
begin
  insert into ingest.regrade_queue (proposition_id, reason, priority)
  select p.proposition_id, 'CANDIDATE-SET-CHANGE', 150
    from core.proposition p
   where p.candidate_set_id = coalesce(new.candidate_set_id, old.candidate_set_id)
  on conflict (proposition_id) do update set enqueued_at = now();
  return coalesce(new, old);
end $$;
create trigger candidate_set_member_regrade
  after insert or update on registry.candidate_set_member
  for each row execute function core.enqueue_candidate_set_regrade();

-- Drain to CONVERGENCE, in passes.
-- A single pass is not enough and the reason is subtle: regrading a parent
create or replace function core.drain_regrade_queue(p_limit integer default 500,
                                                    p_scorer text default null,
                                                    p_max_passes integer default 8)
returns integer language plpgsql as $$
declare n integer := 0; pass integer := 0; did integer; q record;
begin
  loop
    pass := pass + 1;
    did := 0;
    for q in select * from ingest.regrade_queue
              where attempts < 3
              order by priority, enqueued_at limit p_limit loop
      begin
        perform core.apply_grade(q.proposition_id, q.reason, p_scorer);
        n := n + 1; did := did + 1;
      exception when others then
        update ingest.regrade_queue
           set attempts = attempts + 1, last_error = sqlerrm
         where proposition_id = q.proposition_id;
      end;
    end loop;
    exit when did = 0 or pass >= p_max_passes;
  end loop;
  return n;
end $$;

-- ---------------------------------------------------------------------
-- RECONSTRUCTION (requirement 6). Any past grade, from stored data, with
-- the evidence that moved it.
-- ---------------------------------------------------------------------
create or replace function core.grade_as_of(p_proposition_id uuid, p_at timestamptz)
returns core.grade language sql stable as $$
  select coalesce((select grade from core.grade_event
                    where proposition_id = p_proposition_id and occurred_at <= p_at
                      and not is_blind_double_score
                    order by occurred_at desc, seq desc limit 1), 'X'::core.grade)
$$;

create or replace function core.entity_as_of(p_entity_id uuid, p_at timestamptz)
returns table (proposition_id uuid, class core.proposition_class,
               statement_text text, grade core.grade)
language sql stable as $$
  select p.proposition_id, p.class, p.statement_text,
         core.grade_as_of(p.proposition_id, p_at)
    from core.proposition p
   where p.entity_id = p_entity_id and p.created_at <= p_at
   order by p.class
$$;

create or replace function core.grade_history(p_proposition_id uuid,
                                              p_include_drift boolean default false)
returns table (
  seq bigint, occurred_at timestamptz, grade_from core.grade, grade core.grade,
  direction text, transition_cause core.transition_cause,
  is_instrument_drift boolean, disclosure_annotation text,
  limiting_condition text, moved_by jsonb, counts jsonb)
language sql stable as $$
  select ge.seq, ge.occurred_at, ge.grade_from, ge.grade,
         case when ge.grade_from is null then 'initial'
              when core.grade_rank(ge.grade) is null
                or core.grade_rank(ge.grade_from) is null then 'state-change'
              when core.grade_rank(ge.grade) > core.grade_rank(ge.grade_from) then 'up'
              when core.grade_rank(ge.grade) < core.grade_rank(ge.grade_from) then 'down'
              else 'flat' end,
         ge.transition_cause, ge.is_instrument_drift,
         case ge.transition_cause
           when 'NEW-DISCLOSURE' then 'the publication record changed; the world did not'
           when 'STATUS-CHANGE'  then 'the world changed'
           when 'REFUTATION'     then 'affirmative disconfirmation landed'
           when 'CANDIDATE-SET-CHANGE' then 'the denominator moved; adding candidates dilutes'
           when 'CLAMP' then 'the parent proposition moved; this grade may not exceed it'
           else null end,
         ge.limiting_condition,
         coalesce((select jsonb_agg(jsonb_build_object(
                     'observation_id', o.observation_id, 'sign', o.sign,
                     'magnitude', o.magnitude, 'membership', o.membership,
                     'document', d.title, 'tier', o.prov_origin_tier))
                   from core.observation o
                   left join core.source_document d on d.document_id = o.document_id
                   where o.observation_id = any(ge.triggering_observation_ids)),
                  '[]'::jsonb),
         jsonb_build_object('l_d2',ge.l_d2,'l_d3',ge.l_d3,'v',ge.v_count,
                            'u',ge.u_count,'v_claim',ge.v_claim_count,'v0',ge.v0_count,
                            'sci',ge.sci,'evidence_state_hash',ge.evidence_state_hash)
    from core.grade_event ge
   where ge.proposition_id = p_proposition_id
     and not ge.is_blind_double_score
     -- §11.2: instrument drift is suppressed from the public confidence chart
     -- by default. It stays retrievable, because hiding it entirely would be
     -- the same sin one level up.
     and (p_include_drift or not ge.is_instrument_drift)
   order by ge.seq
$$;

-- =====================================================================
-- 14. PUBLICATION — one deliberate, transactional, GATED act (requirement 3).
-- "Every claim carries a citation" is satisfied 100% of the time by a
-- =====================================================================

create or replace function core.assert_publishable(p_entity_id uuid)
returns void language plpgsql as $$
declare bad record; n integer; ent core.entity;
begin
  select * into ent from core.entity where entity_id = p_entity_id;
  if ent is null then raise exception 'no such entity %', p_entity_id; end if;

  -- A canary is a fabricated facility name with zero corpus presence, injected
  -- to measure hallucination against known ground truth. It measures nothing
  -- if it is published.
  if ent.is_canary then
    raise exception 'entity % is a canary (BES §12.4) and may never be published', p_entity_id;
  end if;

  -- Every proposition must carry a current rollup computed from the evidence
  -- CURRENTLY on file. A stale grade is an unverified claim wearing a letter.
  for bad in
    select p.proposition_id, p.class
      from core.proposition p
      left join core.proposition_rollup pr using (proposition_id)
     where p.entity_id = p_entity_id and pr.proposition_id is null
  loop
    raise exception 'proposition % (%) has never been graded; publication refused',
      bad.proposition_id, bad.class;
  end loop;

  for bad in
    select pr.proposition_id, pr.evidence_state_hash as graded_hash,
           core.evidence_state_hash(pr.proposition_id) as live_hash
      from core.proposition_rollup pr
     where pr.entity_id = p_entity_id
       and pr.evidence_state_hash is distinct from core.evidence_state_hash(pr.proposition_id)
  loop
    raise exception
      'proposition %: the published grade was computed against a different evidence set than the one on file (graded %, live %). Drain the regrade queue before publishing.',
      bad.proposition_id, bad.graded_hash, bad.live_hash;
  end loop;

  -- THE STRUCTURAL GUARANTEE. No observation that counted toward a grade may
  -- lack a resolved-to-bytes receipt. `membership` is generated, so this can
  select count(*) into n
    from core.observation o
    left join core.retrieval_receipt rr on rr.receipt_id = o.receipt_id
   where o.proposition_id in (select proposition_id from core.proposition
                               where entity_id = p_entity_id)
     and o.membership in ('V','U')
     and o.derived_from_search_receipt_id is null
     and (rr.receipt_id is null or rr.receipt_state <> 'VERIFIED');
  if n > 0 then
    raise exception
      '% counted observation(s) on this entity have no VERIFIED receipt. An unverified claim may not reach the public register (BES §2.2).', n;
  end if;

  -- A published entity must state where it is, or state that it does not know.
  if not exists (select 1 from core.geometry_assertion
                  where entity_id = p_entity_id and superseded_at is null) then
    raise exception
      'entity % has no geometry assertion. Publish a non_located or place_name_only assertion rather than omitting the question.', p_entity_id;
  end if;
end $$;

create or replace function ops_publish_entity(p_entity_id uuid, p_actor text default 'curator')
returns void language plpgsql security definer set search_path = core, registry, ingest, public as $$
declare first_time boolean;
begin
  perform core.assert_publishable(p_entity_id);

  select not exists (select 1 from core.publication_log
                      where entity_id = p_entity_id and event = 'FIRST-PUBLISH')
    into first_time;

  update core.entity e set publication_state = 'PUBLISHED',
         published_at = coalesce(e.published_at, now())
   where e.entity_id = p_entity_id;

  -- E, F, R and X propositions ARE published: they live in the claims register
  -- with their origin work, which is the product. Publication is not a quality
  -- gate; RENDERING is. An honestly mostly-X register is more credible than a
  -- dishonestly mostly-C one.
  update core.proposition pp set publication_state = 'PUBLISHED',
         published_at = coalesce(pp.published_at, now())
   where pp.entity_id = p_entity_id;
  update core.proposition_rollup set is_published = true where entity_id = p_entity_id;

  -- V0 and quarantined observations publish too, marked inert with their
  -- exclusion_reason. Suppressing them would hide the register's own failures
  -- and the confabulation rate it exists to publish.
  update core.observation o set publication_state = 'PUBLISHED'
   from core.proposition p
   where p.proposition_id = o.proposition_id and p.entity_id = p_entity_id;

  update core.grade_event ge set is_published = true,
         published_at = coalesce(ge.published_at, now())
   from core.proposition p
   where p.proposition_id = ge.proposition_id and p.entity_id = p_entity_id
     and not ge.is_blind_double_score;

  update core.source_document d set publication_state = 'PUBLISHED'
   where exists (select 1 from core.observation o join core.proposition p using (proposition_id)
                  where o.document_id = d.document_id and p.entity_id = p_entity_id);

  -- Publish the TRANSITIVE CITATION CLOSURE of those documents. Without it the
  -- origin trace truncates at the first unpublished hop and the register shows
  with recursive closure (node) as (
      select d.document_id from core.source_document d
       where d.publication_state = 'PUBLISHED'
    union
      select dc.cited_document_id from closure c
        join core.document_citation dc on dc.citing_document_id = c.node
       where dc.retracted_at is null
  )
  update core.source_document d set publication_state = 'PUBLISHED'
    from closure c where d.document_id = c.node and d.publication_state <> 'PUBLISHED';

  insert into core.publication_log (entity_id, event, actor)
  values (p_entity_id, case when first_time then 'FIRST-PUBLISH' else 'REPUBLISH' end, p_actor);
end $$;
revoke all on function ops_publish_entity(uuid,text) from public, anon, authenticated;

create or replace function ops_withdraw_entity(p_entity_id uuid, p_reason text,
                                               p_actor text default 'curator')
returns void language plpgsql security definer set search_path = core, public as $$
begin
  -- Nothing is deleted. Withdrawal flips state and logs the reason.
  update core.entity set publication_state = 'WITHDRAWN', withdrawn_reason = p_reason
   where entity_id = p_entity_id;
  update core.proposition set publication_state = 'WITHDRAWN', withdrawn_reason = p_reason
   where entity_id = p_entity_id;
  update core.proposition_rollup set is_published = false where entity_id = p_entity_id;
  insert into core.publication_log (entity_id, event, actor, note)
  values (p_entity_id, 'WITHDRAW', p_actor, p_reason);
end $$;
revoke all on function ops_withdraw_entity(uuid,text,text) from public, anon, authenticated;

-- TYPOLOGY cannot change without a TYPOLOGY proposition clearing band C, and
-- asserting a new typology instantiates the corresponding FUNCTION row, which
-- is then scored (BES §1.2). Relabelling a limestone mine "COG/COOP" is free;
-- making the relabel stick is not.
create or replace function core.guard_typology_change() returns trigger
language plpgsql as $$
declare g core.grade;
begin
  if new.typology_cached is distinct from old.typology_cached then
    if new.typology_cached = 'unknown-anomaly' then return new; end if;
    select pr.grade into g from core.proposition_rollup pr
      where pr.proposition_id = new.typology_proposition_id;
    if g is null or core.grade_rank(g) is null or core.grade_rank(g) < core.grade_rank('C') then
      raise exception
        'typology may not change to % without a TYPOLOGY proposition at band C or better (current: %)',
        new.typology_cached, coalesce(g::text,'ungraded');
    end if;
    insert into core.entity_typology_history
      (entity_id, typology_from, typology_to, proposition_id, grade_at_change, cause)
    values (new.entity_id, old.typology_cached, new.typology_cached,
            new.typology_proposition_id, g, 'RE-ANALYSIS');
  end if;
  return new;
end $$;
create trigger entity_typology_guard before update of typology_cached on core.entity
  for each row execute function core.guard_typology_change();

-- =====================================================================
-- 15. RENDERING UNCERTAINTY AND FAST VIEWPORT QUERIES (requirements 7, 9).
-- The map geometry is NOT the stored geometry. It is a function of the
-- =====================================================================

create or replace function core.render_geometry(p_entity_id uuid)
returns table (
  representation core.geometry_representation,
  geom geometry(Geometry,4326),
  precision_level core.locate_precision,
  locate_grade core.grade,
  uncertainty_radius_m double precision,
  claimed_place_name text,
  suppression_reason text)
language plpgsql stable as $$
declare ga core.geometry_assertion; lg core.grade; aa registry.admin_area; rad double precision;
begin
  select * into ga from core.geometry_assertion
   where entity_id = p_entity_id and is_preferred and superseded_at is null;
  if ga is null then
    select * into ga from core.geometry_assertion
     where entity_id = p_entity_id and superseded_at is null
     order by array_position(enum_range(null::core.locate_precision), precision) limit 1;
  end if;
  if ga is null then
    return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
                        null::core.locate_precision, null::core.grade, null::double precision,
                        null::text, 'no geometry assertion on file';
    return;
  end if;

  select pr.grade into lg
    from core.proposition p join core.proposition_rollup pr using (proposition_id)
   where p.entity_id = p_entity_id and p.class = 'LOCATE'
   order by pr.computed_at desc limit 1;

  -- NON-LOCATED is documented-but-unlocated; PLACE-NAME-ONLY is a claimed name
  -- with no coordinate at all. Both are epistemically real states and both
  -- belong in the claims register, not on the map. Neither invents a shape.
  if ga.precision = 'non_located' then
    return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
      ga.precision, lg, null::double precision, null::text,
      'non-located: documented, coordinates genuinely unknown';
    return;
  end if;
  if ga.precision = 'place_name_only' then
    return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
      ga.precision, lg, null::double precision, ga.claimed_place_name,
      'place name claimed, no coordinate asserted by any source';
    return;
  end if;

  -- THE HARD GATE. A point requires BOTH a precise assertion AND a LOCATE
  -- proposition graded C or better. Everything else degrades to an area.
  if ga.point_geom is not null
     and ga.precision in ('surveyed','approximate_1km')
     and coalesce(core.grade_rank(lg),0) >= core.grade_rank('C') then
    return query select 'point'::core.geometry_representation, ga.point_geom::geometry(Geometry,4326),
      ga.precision, lg, ga.uncertainty_radius_m, null::text, null::text;
    return;
  end if;

  if ga.point_geom is not null then
    rad := coalesce(ga.uncertainty_radius_m,
             case ga.precision when 'approximate_1km' then 1000
                               when 'approximate_10km' then 10000
                               else 25000 end);
    return query select 'uncertainty_circle'::core.geometry_representation,
      st_buffer(ga.point_geom::geography, rad)::geometry(Geometry,4326),
      ga.precision, lg, rad, null::text,
      case when coalesce(core.grade_rank(lg),0) < core.grade_rank('C')
           then 'LOCATE proposition below band C: rendered as uncertainty, never as a pin'
           else 'coordinate precision below approximate_1km' end;
    return;
  end if;

  if ga.region_geom is not null then
    return query select 'region_polygon'::core.geometry_representation,
      ga.region_geom::geometry(Geometry,4326), ga.precision, lg,
      null::double precision, null::text, null::text;
    return;
  end if;

  if ga.admin_area_id is not null then
    select * into aa from registry.admin_area where admin_area_id = ga.admin_area_id;
    return query select 'admin_polygon'::core.geometry_representation,
      aa.geom::geometry(Geometry,4326), ga.precision, lg,
      null::double precision, null::text, 'located only to administrative area';
    return;
  end if;

  return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
    ga.precision, lg, null::double precision, null::text, 'no renderable shape';
end $$;

-- ---------------------------------------------------------------------
-- The map projection. A materialised view because viewport queries must not
create materialized view api.map_feature as
select
  e.entity_id, e.slug, e.canonical_name, e.entity_level, e.country_code,
  e.typology_cached as typology,
  pr.grade      as exist_grade,
  pr.grade_rank as exist_rank,
  pr.at_ceiling, pr.marginal_flag, pr.ceiling, pr.silence_reading,
  pr.base_rate_reading, pr.limiting_condition,
  rg.representation, rg.precision_level as locate_precision, rg.locate_grade,
  rg.uncertainty_radius_m, rg.suppression_reason,
  rg.geom,
  st_transform(rg.geom, 3857) as geom_3857,
  -- The clustering anchor. A guaranteed-interior point, not a centroid, so it
  -- is inside concave uncertainty polygons.
  st_pointonsurface(rg.geom) as label_point,
  st_transform(st_pointonsurface(rg.geom), 3857) as label_point_3857,
  (select count(*) from core.proposition_rollup r2
    where r2.entity_id = e.entity_id and r2.is_published)              as proposition_count,
  (select count(*) from core.proposition_rollup r3
    where r3.entity_id = e.entity_id and r3.is_published and r3.grade='R') as refuted_count,
  (select count(*) from core.proposition_rollup r4
    where r4.entity_id = e.entity_id and r4.is_published and r4.grade='X') as unassessed_count,
  pr.computed_at as graded_at
from core.entity e
join core.proposition p
  on p.entity_id = e.entity_id and p.class = 'EXIST'
 and p.publication_state = 'PUBLISHED'
join core.proposition_rollup pr
  on pr.proposition_id = p.proposition_id and pr.is_published
cross join lateral core.render_geometry(e.entity_id) rg
where e.publication_state = 'PUBLISHED'
  and e.is_canary = false                       -- canaries never publish
  and rg.geom is not null
  and rg.representation <> 'none'
  -- BES §10.3: nothing below band D renders as a map pin. E, F, R and X live
  -- in the claims register with their origin work.
  and coalesce(core.grade_rank(pr.grade),0) >= core.grade_rank('D');

create unique index map_feature_pk        on api.map_feature(entity_id);
create index map_feature_gix              on api.map_feature using gist (geom);
create index map_feature_gix_3857         on api.map_feature using gist (geom_3857);
create index map_feature_label_gix        on api.map_feature using gist (label_point);
create index map_feature_rank_idx         on api.map_feature(exist_rank desc);
create index map_feature_typology_idx     on api.map_feature(typology);
create index map_feature_country_idx      on api.map_feature(country_code);
create index map_feature_slug_idx         on api.map_feature(slug);

comment on materialized view api.map_feature is
  'Published map projection. The WHERE clause is the security boundary: materialised views do not enforce RLS. geom_3857 is stored and indexed so vector-tile queries are index scans — transforming per row at query time is a sequential scan of the whole register on every tile.';

-- ---------------------------------------------------------------------
-- Server-side clustering, pre-aggregated per zoom bucket.
-- [FIX-B] Two corrections to proposal B's version:
create materialized view api.map_cluster as
with z as (select generate_series(2,9) as zoom),
snapped as (
  select z.zoom,
         st_snaptogrid(f.label_point_3857, 40075016.686 / (2 ^ z.zoom) / 4) as cell,
         f.entity_id, f.exist_rank, f.typology, f.country_code
    from api.map_feature f cross join z
)
select zoom,
       st_x(cell)::bigint as cell_x,
       st_y(cell)::bigint as cell_y,
       count(*)::integer  as feature_count,
       max(exist_rank)    as best_exist_rank,
       core.rank_grade(max(exist_rank)) as best_exist_grade,
       mode() within group (order by typology) as modal_typology,
       min(country_code)  as country_code,
       st_transform(st_centroid(st_collect(cell)), 4326) as centroid,
       st_transform(st_envelope(st_collect(cell)), 4326) as bbox,
       (array_agg(entity_id order by exist_rank desc))[1:25] as sample_entity_ids
  from snapped group by zoom, cell;

create unique index map_cluster_pk  on api.map_cluster(zoom, cell_x, cell_y);
create index map_cluster_gix        on api.map_cluster using gist (centroid);
create index map_cluster_zoom_idx   on api.map_cluster(zoom, best_exist_rank desc);

-- Viewport RPC: clusters when zoomed out, features when zoomed in. One round
-- trip, no client-side clustering, no whole-table scan at any zoom.
create or replace function api.map_viewport(
  west double precision, south double precision,
  east double precision, north double precision,
  zoom integer,
  min_grade core.grade default 'D',
  typologies core.typology[] default null,
  countries text[] default null)
returns jsonb language sql stable parallel safe security invoker as $$
  with bbox as (select st_makeenvelope(west, south, east, north, 4326) as g)
  select case when zoom <= 9 then
    jsonb_build_object('mode','clusters','zoom',zoom,
      'clusters', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'cell', jsonb_build_array(c.cell_x, c.cell_y),
                 'count', c.feature_count, 'best_grade', c.best_exist_grade,
                 'modal_typology', c.modal_typology,
                 'lon', st_x(c.centroid), 'lat', st_y(c.centroid),
                 'sample', c.sample_entity_ids))
          from api.map_cluster c, bbox
         where c.zoom = map_viewport.zoom
           and c.centroid && bbox.g
           and c.best_exist_rank >= core.grade_rank(min_grade)
           and (countries is null or c.country_code = any(countries))), '[]'::jsonb))
  else
    jsonb_build_object('mode','features','zoom',zoom,
      'features', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'entity_id', f.entity_id, 'slug', f.slug, 'name', f.canonical_name,
                 'entity_level', f.entity_level,
                 'exist_grade', f.exist_grade, 'typology', f.typology,
                 -- The client is told WHAT it is being given. A region feature
                 -- carries a polygon and no point; there is no code path that
                 -- emits a coordinate for a candidate below LOCATE band C.
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
                 'at_ceiling', f.at_ceiling, 'marginal', f.marginal_flag,
                 'geometry', st_asgeojson(f.geom)::jsonb))
          from api.map_feature f, bbox
         where f.geom && bbox.g
           and f.exist_rank >= core.grade_rank(min_grade)
           and (typologies is null or f.typology = any(typologies))
           and (countries is null or f.country_code = any(countries))
         limit 2000), '[]'::jsonb))
  end
$$;

-- Vector tiles for MapLibre's native path. The bbox test is against the
-- STORED geom_3857 so the GiST index is usable; transforming inside the
-- predicate would force a sequential scan on every tile request.
create or replace function api.map_tile(z integer, x integer, y integer)
returns bytea language sql stable parallel safe security invoker as $$
  with env as (select st_tileenvelope(z, x, y) as g),
  src as (
    select f.entity_id, f.slug, f.canonical_name, f.exist_grade, f.exist_rank,
           f.typology, f.representation, f.locate_precision, f.locate_grade,
           f.proposition_count, f.refuted_count, f.unassessed_count,
           st_asmvtgeom(f.geom_3857, env.g, 4096, 64, true) as geom
      from api.map_feature f, env
     where f.geom_3857 && env.g)
  select coalesce(st_asmvt(src.*, 'candidates', 4096, 'geom'), ''::bytea)
    from src where geom is not null
$$;

create or replace function api.refresh_map() returns void
language plpgsql security definer set search_path = api, core, registry, public as $$
declare n_pub integer; n_feat integer;
begin
  refresh materialized view concurrently api.map_feature;
  refresh materialized view concurrently api.map_cluster;
  -- A refresh that silently produced nothing is the failure mode of a
  -- SECURITY DEFINER refresh under FORCE ROW LEVEL SECURITY: the definer sees
  -- zero rows and the map goes blank without an error. Fail loudly instead.
  select count(*) into n_pub from core.proposition_rollup
   where is_published and grade in ('A','B','C','D');
  select count(*) into n_feat from api.map_feature;
  if n_pub > 0 and n_feat = 0 then
    raise exception
      'api.refresh_map produced 0 features while % published propositions are at band D or better. The refreshing role cannot see core.* — check RLS/BYPASSRLS on the definer.', n_pub;
  end if;
end $$;
revoke all on function api.refresh_map() from public, anon, authenticated;

-- =====================================================================
-- 16. INGEST AND TELEMETRY. No anon policy exists on ANY table in this
--     schema, so RLS denies every row. Naming a lead, a canary or an
-- =====================================================================

create table ingest.agent_run (
  run_id bigint generated always as identity primary key,
  agent text not null, scorer_model_id text references registry.scorer_model(scorer_model_id),
  workflow text not null, started_at timestamptz not null default now(),
  finished_at timestamptz, candidates_returned integer, observations_written integer,
  identifiers_emitted integer, identifiers_resolved integer,
  notes text
);
create index agent_run_agent_idx on ingest.agent_run(agent, started_at desc);

-- Null returns are the model's fuel, not a chore: a region examined and found
-- empty is a finding, and the COMPLETENESS CRITIC reads these.
create table ingest.null_return (
  null_return_id bigint generated always as identity primary key,
  run_id bigint references ingest.agent_run(run_id),
  examined_geom geometry(MultiPolygon,4326),
  examined_theme text, corpora_searched text[] not null default '{}',
  found_nothing boolean not null default true,
  recorded_at timestamptz not null default now()
);
create index null_return_geom_gix on ingest.null_return using gist (examined_geom);

-- BES §12.4. Rotating fabricated facility names with zero corpus presence.
-- Any citation returned for a canary is a directly measured hallucination
-- against known ground truth, published beside the register's grades.
create table ingest.canary (
  canary_id bigint generated always as identity primary key,
  fabricated_name text not null unique,
  entity_id uuid references core.entity(entity_id),
  injected_at timestamptz not null default now(),
  retired_at timestamptz, cycle_label text
);

create table ingest.confabulation_event (
  event_id bigint generated always as identity primary key,
  agent text not null, scorer_model_id text,
  canary_id bigint references ingest.canary(canary_id),
  identifier text, identifier_class text,
  kind text not null check (kind in
    ('format-valid-unresolvable','canary-citation','subject-binding-failure',
     'issuer-metadata-mismatch','quote-not-found','dead-link')),
  observation_id uuid references core.observation(observation_id),
  detected_at timestamptz not null default now(), note text
);
create index confabulation_agent_idx on ingest.confabulation_event(agent, detected_at desc);

-- BES §12.2: rolling 10% blind double-scoring by a DIFFERENT model family,
-- with per-condition agreement published.
create table ingest.double_scoring (
  double_id bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id),
  primary_event_id uuid not null references core.grade_event(grade_event_id),
  blind_event_id uuid not null references core.grade_event(grade_event_id),
  agreed boolean, condition_agreement jsonb not null default '{}'::jsonb,
  scored_at timestamptz not null default now(),
  constraint double_scoring_different_family check (primary_event_id <> blind_event_id)
);

-- An agent may PROPOSE a curated row. Assignment is a reviewed write.
create table ingest.curation_proposal (
  proposal_id bigint generated always as identity primary key,
  target_table text not null check (target_table in
    ('corpus','diagnosticity_catalog','erp_profile','null_hypothesis',
     'candidate_set','identifier_grammar','base_rate')),
  payload jsonb not null, proposed_by text not null,
  proposed_at timestamptz not null default now(),
  state text not null default 'pending' check (state in ('pending','accepted','rejected')),
  reviewed_by text, reviewed_at timestamptz, review_note text,
  -- Every E/A matrix use is logged here so the fallback is self-retiring
  -- (BES §4.4): PRIOR-KEEPER adjudicates them into the catalog on review.
  source_observation_id uuid references core.observation(observation_id)
);
create index curation_proposal_state on ingest.curation_proposal(state, target_table);

create table ingest.adjudication_task (
  task_id bigint generated always as identity primary key,
  entity_id uuid references core.entity(entity_id),
  proposition_id uuid references core.proposition(proposition_id),
  stage text not null check (stage in ('LINEAGE','REFUTER','RESOLVER','ASSESSOR','REVIEW')),
  state text not null default 'queued' check (state in ('queued','running','done','failed')),
  priority smallint not null default 100,
  created_at timestamptz not null default now(), completed_at timestamptz, note text
);
create index adjudication_queue_idx on ingest.adjudication_task(state, priority, created_at)
  where state in ('queued','running');

create table ingest.calibration_case (
  case_id text primary key, label text not null,
  expected_grade core.grade, expected_note text,
  proposition_class core.proposition_class, source_lens text
);
create table ingest.calibration_run (
  run_id bigint generated always as identity primary key,
  case_id text not null references ingest.calibration_case(case_id),
  returned_grade core.grade, passed boolean, ran_at timestamptz not null default now(),
  detail jsonb
);

-- =====================================================================
-- 17. ROW LEVEL SECURITY (requirement 8).
-- Three independent layers, so that any one failing is not a breach:
-- =====================================================================

do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables
            where schemaname in ('core','ingest','registry') loop
    execute format('alter table %I.%I enable row level security', t.schemaname, t.tablename);
    execute format(
      'create policy service_all on %I.%I as permissive for all to service_role using (true) with check (true)',
      t.schemaname, t.tablename);
  end loop;
end $$;

-- Reference data is public by design: the register publishes its own
-- instrument, with an explicit warning that the rubric is a public
-- optimisation target (BES §13).
create policy anon_read on registry.country            for select to anon, authenticated using (true);
create policy anon_read on registry.admin_area         for select to anon, authenticated using (true);
create policy anon_read on registry.null_hypothesis    for select to anon, authenticated using (true);
create policy anon_read on registry.corpus             for select to anon, authenticated using (true);
create policy anon_read on registry.egress_probe       for select to anon, authenticated using (true);
create policy anon_read on registry.identifier_grammar for select to anon, authenticated using (true);
create policy anon_read on registry.diagnosticity_catalog for select to anon, authenticated using (true);
create policy anon_read on registry.erp_profile        for select to anon, authenticated using (true);
create policy anon_read on registry.canonical_search_set for select to anon, authenticated using (true);
create policy anon_read on registry.candidate_set      for select to anon, authenticated using (true);
create policy anon_read on registry.candidate_set_member for select to anon, authenticated using (true);
create policy anon_read on registry.base_rate          for select to anon, authenticated using (true);
create policy anon_read on registry.table_version      for select to anon, authenticated using (true);
create policy anon_read on registry.rubric_version     for select to anon, authenticated using (true);
create policy anon_read on registry.scorer_model       for select to anon, authenticated using (true);

-- A reusable published-entity test. Written once so a new child table cannot
-- accidentally get a weaker predicate than its siblings.
create or replace function core.entity_is_public(p_entity_id uuid)
returns boolean language sql stable security definer set search_path = core, public as $$
  select exists (select 1 from core.entity e
                  where e.entity_id = p_entity_id
                    and e.publication_state = 'PUBLISHED' and not e.is_canary)
$$;
create or replace function core.proposition_is_public(p_proposition_id uuid)
returns boolean language sql stable security definer set search_path = core, public as $$
  select exists (select 1 from core.proposition p join core.entity e using (entity_id)
                  where p.proposition_id = p_proposition_id
                    and p.publication_state = 'PUBLISHED'
                    and e.publication_state = 'PUBLISHED' and not e.is_canary)
$$;
create or replace function core.document_is_public(p_document_id uuid)
returns boolean language sql stable security definer set search_path = core, public as $$
  select exists (select 1 from core.source_document d
                  where d.document_id = p_document_id
                    and d.publication_state = 'PUBLISHED')
$$;

create policy anon_read on core.entity for select to anon, authenticated
  using (publication_state = 'PUBLISHED' and is_canary = false);
create policy anon_read on core.entity_alias for select to anon, authenticated
  using (retired_at is null and core.entity_is_public(entity_id));
create policy anon_read on core.entity_identifier for select to anon, authenticated
  using (core.entity_is_public(entity_id));
create policy anon_read on core.entity_relation for select to anon, authenticated
  using (retracted_at is null and core.entity_is_public(from_entity_id)
         and core.entity_is_public(to_entity_id));
create policy anon_read on core.entity_merge_event for select to anon, authenticated
  using (core.entity_is_public(surviving_entity_id));
create policy anon_read on core.entity_typology_history for select to anon, authenticated
  using (core.entity_is_public(entity_id));
create policy anon_read on core.geometry_assertion for select to anon, authenticated
  using (core.entity_is_public(entity_id));
create policy anon_read on core.proposition for select to anon, authenticated
  using (publication_state = 'PUBLISHED' and core.entity_is_public(entity_id));
create policy anon_read on core.proposition_rollup for select to anon, authenticated
  using (is_published and core.proposition_is_public(proposition_id));
create policy anon_read on core.proposition_erp for select to anon, authenticated
  using (core.proposition_is_public(proposition_id));
create policy anon_read on core.claim for select to anon, authenticated
  using (exists (select 1 from core.proposition p where p.claim_id = claim.claim_id
                   and core.proposition_is_public(p.proposition_id)));

-- V0 and quarantined observations ARE published, marked inert with their
-- exclusion_reason. Suppressing them would hide the register's own failures.
create policy anon_read on core.observation for select to anon, authenticated
  using (publication_state = 'PUBLISHED' and core.proposition_is_public(proposition_id));
create policy anon_read on core.source_document for select to anon, authenticated
  using (publication_state = 'PUBLISHED');
create policy anon_read on core.retrieval_receipt for select to anon, authenticated
  using (core.document_is_public(document_id));
create policy anon_read on core.quoted_span for select to anon, authenticated
  using (exists (select 1 from core.retrieval_receipt rr
                  where rr.receipt_id = quoted_span.receipt_id
                    and core.document_is_public(rr.document_id)));
create policy anon_read on core.search_receipt for select to anon, authenticated
  using (core.proposition_is_public(proposition_id));
create policy anon_read on core.search_log for select to anon, authenticated
  using (core.proposition_is_public(proposition_id));

-- ---------------------------------------------------------------------
-- [FIX-B] Three genuine anonymous-read leaks in the evidence-centric
create policy anon_read on core.witness for select to anon, authenticated
  using (exists (select 1 from core.attestation a
                  join core.observation o on o.observation_id = a.observation_id
                 where a.witness_id = witness.witness_id
                   and o.publication_state = 'PUBLISHED'
                   and core.proposition_is_public(o.proposition_id)));
create policy anon_read on core.attestation for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  where o.observation_id = attestation.observation_id
                    and o.publication_state = 'PUBLISHED'
                    and core.proposition_is_public(o.proposition_id)));
create policy anon_read on core.lineage for select to anon, authenticated
  using (exists (select 1 from core.source_document d
                  where d.lineage_id = lineage.lineage_id
                    and d.publication_state = 'PUBLISHED'));
create policy anon_read on core.lineage_membership for select to anon, authenticated
  using (core.document_is_public(document_id));
create policy anon_read on core.document_citation for select to anon, authenticated
  using (retracted_at is null
         and core.document_is_public(citing_document_id)
         and core.document_is_public(cited_document_id));
create policy anon_read on core.judgement_log for select to anon, authenticated
  using (observation_id is not null
         and exists (select 1 from core.observation o
                      where o.observation_id = judgement_log.observation_id
                        and o.publication_state = 'PUBLISHED'));
create policy anon_read on core.citogenesis_loop for select to anon, authenticated
  using (state = 'confirmed' and core.proposition_is_public(proposition_id));

-- Grades: PUBLISHED events only. An unpublished grade event is precisely the
-- adjudication state requirement 8 forbids leaking, and a blind double-score
-- must never be visible or the blind is not blind.
create policy anon_read on core.grade_event for select to anon, authenticated
  using (is_published and not is_blind_double_score
         and core.proposition_is_public(proposition_id));
create policy anon_read on core.grade_event_observation for select to anon, authenticated
  using (exists (select 1 from core.grade_event g
                  where g.grade_event_id = grade_event_observation.grade_event_id
                    and g.is_published and not g.is_blind_double_score
                    and core.proposition_is_public(g.proposition_id)));
create policy anon_read on core.clamp_event for select to anon, authenticated
  using (core.proposition_is_public(child_proposition_id));
create policy anon_read on core.publication_log for select to anon, authenticated
  using (core.entity_is_public(entity_id));

-- Refutations and their disposition tables publish WITH the entry: a register
-- that can show why a famous claim is hollow is more useful than one that
-- quietly omits it. But a DRAFT refutation on an unpublished candidate is
-- adjudication state and stays private.
create policy anon_read on core.refutation for select to anon, authenticated
  using (core.proposition_is_public(proposition_id));
create policy anon_read on core.alternative_disposition for select to anon, authenticated
  using (core.proposition_is_public(proposition_id));

-- Grants: SELECT only, and only where a policy exists to protect it.
-- No INSERT/UPDATE/DELETE grant exists for anon or authenticated anywhere.
do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables
            where schemaname in ('core','registry') loop
    if exists (select 1 from pg_policies pp
                where pp.schemaname = t.schemaname and pp.tablename = t.tablename
                  and pp.policyname = 'anon_read') then
      execute format('grant select on %I.%I to anon, authenticated', t.schemaname, t.tablename);
    end if;
  end loop;
end $$;

grant all on all tables in schema core, registry, ingest to service_role;
grant all on all sequences in schema core, registry, ingest to service_role;

-- =====================================================================
-- 18. THE PUBLISHED PROJECTION. All SECURITY INVOKER, so §17 is the single
--     source of truth and no view can bypass it.
-- =====================================================================

-- The proposition table that LEADS every entry page (BES §10.1).
create view api.proposition_badge with (security_invoker = true) as
select
  p.proposition_id, p.entity_id, e.slug as entity_slug, e.canonical_name as entity_name,
  p.class, p.statement_text, p.predicate_args, p.as_of_date,
  pr.grade, pr.grade_rank, pr.awarded_band, pr.grade_pre_clamp, pr.applied_caps,
  pr.clamped_by_proposition_id,
  pr.ceiling, pr.ceiling_reason, pr.at_ceiling,
  pr.limiting_condition, pr.marginal_flag,
  pr.refutation_state, pr.null_state, p.null_code, nh.label as null_label,
  pr.silence_reading,
  -- BES §6.4, rendered verbatim so the reader is never left to infer it.
  case pr.silence_reading
    when 'UNINFORMATIVE' then 'No public record of this class would be expected for a facility of this type in this period under this authority. The absence is not evidence against.'
    when 'RECORD-DESTROYED' then 'The record class that would have carried this evidence no longer exists.'
    when 'UNSEARCHED' then 'Not yet searched.'
    else 'Searched; negative receipts logged.' end as silence_prose,
  pr.base_rate_reading, pr.reference_class, pr.citogenesis,
  pr.sci, pr.sci_numerator, pr.sci_denominator,
  pr.l_d2, pr.l_d3, pr.v_count, pr.u_count, pr.v0_count, pr.v_claim_count, pr.inert_count,
  -- §10.2 TWO BARS, ALWAYS: how much of this grade is the mountain.
  pr.place_derived_weight, pr.claim_derived_weight,
  pr.condition_results, pr.computed_at as graded_at,
  ge.transition_cause, ge.rubric_version, ge.scorer_model_id, ge.evidence_state_hash
from core.proposition p
join core.entity e on e.entity_id = p.entity_id
join core.proposition_rollup pr on pr.proposition_id = p.proposition_id
join registry.null_hypothesis nh on nh.null_code = p.null_code
left join core.grade_event ge on ge.grade_event_id = pr.current_grade_event_id;

-- Every evidence row with its receipt, tier, provenance and diagnosticity,
-- INCLUDING V0 and quarantined rows shown as inert with the reason.
create view api.evidence_row with (security_invoker = true) as
select
  o.observation_id, o.proposition_id, o.statement, o.observation_key,
  o.sign, o.magnitude, o.signed_weight, o.membership, o.exclusion_reason,
  o.diagnosticity_source, o.ea_expectedness, o.ea_alternative,
  o.scope, o.property_locus, o.subject_binding_pass, o.fact_key,
  o.null_excluding, o.documents_null, o.gate_pass,
  jsonb_build_object('a_tier',o.gate_a_tier,'b_receipt',o.gate_b_receipt,
                     'c_instance',o.gate_c_instance,'d_on_its_face',o.gate_d_on_its_face,
                     'e_authority',o.gate_e_authority,'f_unsolicited',o.gate_f_unsolicited)
    as gate_conditions,
  o.refutation_class, o.rebutted, o.rebuttal_note,
  d.document_id, d.title, d.issuing_body, d.author_name, d.document_date, d.url,
  d.identifier, d.identifier_class,
  d.origin_tier, d.channel, d.causal_provenance, d.corpus_era,
  d.self_attesting, d.self_attesting_rationale, d.register_echo_quarantined, d.lineage_id,
  c.name as corpus_name, c.host as corpus_host, c.adversary_writable, c.egress_state,
  rr.receipt_state, rr.resolved_url, rr.http_status,
  encode(rr.sha256_of_bytes,'hex') as sha256, rr.retrieved_at,
  rr.mirror_only, rr.issuer_metadata_match, rr.content_drifted,
  qs.quoted_text, qs.span_start_offset, qs.span_end_offset, qs.quote_check,
  bs.quoted_text as binding_quote,
  sr.query_string as negative_search_query, sr.corpus_as_of as negative_search_corpus_date,
  sr.result_count as negative_search_result_count,
  ep.profile_key as expected_record_profile, ep.x_level as expected_record_level
from core.observation o
left join core.source_document d on d.document_id = o.document_id
left join registry.corpus c on c.corpus_id = d.corpus_id
left join core.retrieval_receipt rr on rr.receipt_id = o.receipt_id
left join core.quoted_span qs on qs.span_id = o.probative_span_id
left join core.quoted_span bs on bs.span_id = o.binding_span_id
left join core.search_receipt sr on sr.search_receipt_id = o.derived_from_search_receipt_id
left join registry.erp_profile ep on ep.erp_profile_id = sr.erp_profile_id;

-- The alternative-hypothesis disposition table: the single most valuable
-- artifact the register can show a skeptical reader.
create view api.alternative_table with (security_invoker = true) as
select ad.proposition_id, ad.null_code, nh.label, nh.description,
       ad.is_selected, ad.disposition, ad.reasoning, ad.excluding_observation_ids
  from core.alternative_disposition ad
  join registry.null_hypothesis nh using (null_code);

-- The claims register: E, F, R and X entries live here WITH their origin
-- work, which is the product. Nothing is deleted; refuted entries keep their
-- refutations attached.
create view api.claims_register with (security_invoker = true) as
select p.proposition_id, p.entity_id, e.slug, e.canonical_name,
       p.class, p.statement_text, pr.grade, pr.limiting_condition,
       pr.silence_reading, pr.refutation_state, pr.citogenesis,
       pr.base_rate_reading, pr.ceiling, pr.at_ceiling,
       cl.claim_text, cl.first_appearance_date, cl.first_appearance_confidence,
       (select jsonb_agg(jsonb_build_object('state', rf.proposed_state,
                                            'narrative', rf.narrative,
                                            'next_review_due', rf.next_review_due))
          from core.refutation rf
         where rf.proposition_id = p.proposition_id and rf.reversed_at is null) as refutations,
       (select jsonb_agg(jsonb_build_object('class', p2.class, 'grade', pr2.grade))
          from core.proposition p2 join core.proposition_rollup pr2 using (proposition_id)
         where p2.entity_id = e.entity_id and p2.class = 'ORIGIN') as origin_propositions
  from core.proposition p
  join core.entity e on e.entity_id = p.entity_id
  join core.proposition_rollup pr on pr.proposition_id = p.proposition_id
  left join core.claim cl on cl.claim_id = p.claim_id
 where pr.grade in ('E','F','R','X');

-- Instrument honesty, published (BES §12.4, §12.6, §2.6).
create view api.methodology_coverage with (security_invoker = true) as
select c.slug, c.name, c.beat, c.host, c.host_tier, c.content_tier, c.value,
       c.robots_posture, c.rate_limits, c.egress_state, c.egress_probed_at,
       c.adversary_writable, c.tier_trap, c.machine_generated_blocklist
  from registry.corpus c;

create view api.expected_record_table with (security_invoker = true) as
select ep.profile_key, ep.description, ep.x_level, ep.authority_note,
       ep.silence_override, ep.destroying_event, ep.era_from, ep.era_to
  from registry.erp_profile ep;

-- The register states its own measured fabrication rate. A register that does
-- so is more credible than one that implies none.
create view api.telemetry_confabulation with (security_invoker = true) as
select ar.agent,
       sum(ar.identifiers_emitted) as identifiers_emitted,
       sum(ar.identifiers_resolved) as identifiers_resolved,
       case when sum(ar.identifiers_emitted) > 0
            then round(1 - sum(ar.identifiers_resolved)::numeric
                           / sum(ar.identifiers_emitted), 4) end as unresolvable_rate
  from ingest.agent_run ar group by ar.agent;

create view api.telemetry_band_occupancy with (security_invoker = true) as
select pr.class, pr.grade, count(*) as n,
       round(100.0 * count(*) / nullif(sum(count(*)) over (), 0), 2) as pct
  from core.proposition_rollup pr where pr.is_published
 group by pr.class, pr.grade;

create view api.telemetry_refutation with (security_invoker = true) as
select count(*) filter (where pr.grade='R') as refuted,
       count(*) filter (where pr.refutation_state='R2') as r2_only,
       count(*) as graded,
       (select count(*) from core.refutation where reversed_at is not null) as reversed
  from core.proposition_rollup pr where pr.is_published;

grant select on api.proposition_badge, api.evidence_row, api.alternative_table,
                api.claims_register, api.methodology_coverage, api.expected_record_table,
                api.telemetry_confabulation, api.telemetry_band_occupancy,
                api.telemetry_refutation
  to anon, authenticated;
grant select on api.map_feature, api.map_cluster to anon, authenticated;

grant execute on function api.map_viewport(double precision,double precision,double precision,
  double precision,integer,core.grade,core.typology[],text[]) to anon, authenticated;
grant execute on function api.map_tile(integer,integer,integer) to anon, authenticated;
grant execute on function core.trace_origin(uuid,integer) to anon, authenticated;
grant execute on function core.origin_path(uuid,uuid,integer) to anon, authenticated;
grant execute on function core.claim_origin(uuid,integer) to anon, authenticated;
grant execute on function core.independent_lineages(uuid,smallint) to anon, authenticated;
grant execute on function core.lineage_count(uuid,smallint) to anon, authenticated;
grant execute on function core.lineage_count_claim(uuid,smallint) to anon, authenticated;
grant execute on function core.lineage_components(uuid[]) to anon, authenticated;
grant execute on function core.grade_history(uuid,boolean) to anon, authenticated;
grant execute on function core.grade_as_of(uuid,timestamptz) to anon, authenticated;
grant execute on function core.entity_as_of(uuid,timestamptz) to anon, authenticated;
grant execute on function core.render_geometry(uuid) to anon, authenticated;
grant execute on function core.grade_rank(core.grade), core.rank_grade(smallint),
                          core.grade_min(core.grade,core.grade) to anon, authenticated;

-- Explicitly NOT granted to anon: the grading and publication path. A public
-- caller must never be able to trigger a rescore — and an RLS-filtered input
-- set would produce a WRONG grade rather than an error, which is far worse
-- than a permission denial.
revoke all on function core.evaluate_proposition(uuid) from public, anon, authenticated;
revoke all on function core.recompute_proposition(uuid) from public, anon, authenticated;
revoke all on function core.apply_grade(uuid,core.transition_cause,text,text,boolean)
  from public, anon, authenticated;
revoke all on function core.drain_regrade_queue(integer,text,integer) from public, anon, authenticated;
revoke all on function core.derive_refutation(uuid) from public, anon, authenticated;
revoke all on function core.derive_null_state(uuid) from public, anon, authenticated;
revoke all on function core.assert_publishable(uuid) from public, anon, authenticated;
grant execute on function core.evaluate_proposition(uuid),
                          core.recompute_proposition(uuid),
                          core.apply_grade(uuid,core.transition_cause,text,text,boolean),
                          core.drain_regrade_queue(integer,text,integer),
                          core.assert_publishable(uuid),
                          api.refresh_map(),
                          ops_publish_entity(uuid,text),
                          ops_withdraw_entity(uuid,text,text) to service_role;

-- A candidate detail payload in one round trip: the proposition table, the
-- evidence rows with receipts, the alternatives, the search receipts.
create or replace function api.candidate_detail(p_slug text)
returns jsonb language sql stable security invoker as $$
  select jsonb_build_object(
    'entity', jsonb_build_object(
      'entity_id', e.entity_id, 'slug', e.slug, 'name', e.canonical_name,
      'entity_level', e.entity_level, 'country', e.country_code,
      'typology', e.typology_cached, 'reference_class', e.reference_class,
      'geometry', st_asgeojson(rg.geom)::jsonb,
      'representation', rg.representation,
      'locate_precision', rg.precision_level,
      'uncertainty_radius_m', rg.uncertainty_radius_m,
      'claimed_place_name', rg.claimed_place_name,
      'suppression_reason', rg.suppression_reason,
      'aliases', (select jsonb_agg(a.alias_text order by a.alias_text)
                    from core.entity_alias a
                   where a.entity_id = e.entity_id and a.retired_at is null),
      'distinct_from', (select jsonb_agg(jsonb_build_object(
                            'entity_id', x.entity_id, 'name', x.canonical_name, 'note', r.note))
                          from core.entity_relation r join core.entity x on x.entity_id = r.to_entity_id
                         where r.from_entity_id = e.entity_id and r.kind = 'DISTINCT-FROM'
                           and r.retracted_at is null)),
    -- N badges, never one.
    'propositions', coalesce((
      select jsonb_agg(to_jsonb(b) || jsonb_build_object(
               'evidence', coalesce((select jsonb_agg(to_jsonb(v) order by v.sign, v.magnitude desc)
                                       from api.evidence_row v
                                      where v.proposition_id = b.proposition_id), '[]'::jsonb),
               'alternatives', coalesce((select jsonb_agg(to_jsonb(alt))
                                           from api.alternative_table alt
                                          where alt.proposition_id = b.proposition_id), '[]'::jsonb),
               'search_receipts', coalesce((select jsonb_agg(jsonb_build_object(
                                     'query', sr.query_string, 'corpus_as_of', sr.corpus_as_of,
                                     'outcome', sr.outcome, 'result_count', sr.result_count)
                                     order by sr.executed_at)
                                   from core.search_receipt sr
                                  where sr.proposition_id = b.proposition_id), '[]'::jsonb))
             order by array_position(
               array['EXIST','LOCATE','EXTENT','TYPOLOGY','HARDEN','CONTROL','FUNCTION',
                     'STATUS','FEATURE','PROGRAM','IDENTITY','ORIGIN']::text[], b.class::text))
        from api.proposition_badge b where b.entity_id = e.entity_id), '[]'::jsonb),
    'provenance_beacon', jsonb_build_object(
      'rubric','BES v0.2', 'generated_at', now(),
      'note','Every grade is a statement about the record, not about the world.'))
    from core.entity e
    cross join lateral core.render_geometry(e.entity_id) rg
   where e.slug = p_slug
$$;
grant execute on function api.candidate_detail(text) to anon, authenticated;

-- =====================================================================
-- 19. SEED — the minimum curated content the model cannot run without.
--     The 158-source registry, the full diagnosticity catalog and the full
-- =====================================================================

insert into registry.rubric_version (rubric_version, ratified_at, notes) values
  ('BES-0.2.0', null, 'Tiered Sufficiency with Signed Evidence. Awaiting ratification.');

insert into registry.table_version (table_name, version, issued_by, is_current) values
  ('tier','0.2.0','W0',true), ('diagnosticity','0.2.0','W0',true),
  ('erp','0.2.0','W0',true), ('candidate_set','0.2.0','W0',true),
  ('base_rate','0.2.0','W0',true), ('rubric','0.2.0','W0',true);

insert into registry.country (country_code, name, register_scope) values
  ('US','United States','active'), ('GB','United Kingdom','planned'),
  ('DE','Germany','planned'), ('CH','Switzerland','planned'),
  ('RU','Russian Federation','planned'), ('CN','China','planned');

-- BES §4.5, the enumerated null set. REFUTER selects the STRONGEST SURVIVING
-- alternative and states why the others are weaker.
insert into registry.null_hypothesis (null_code, label, description, is_fabrication_null) values
 ('A01','no constructed object','No constructed object exists here at all',false),
 ('A02','commercial mine or cavern','Commercial or industrial mine, quarry, or cavern warehouse',false),
 ('A03','transport tunnel','Highway, rail or transit tunnel',false),
 ('A04','water or sewer works','Water, sewer or flood-control works',false),
 ('A05','utility vault','Utility vault, substation enclosure or pipeline works',false),
 ('A06','general storage','Agricultural, cold or general storage',false),
 ('A07','unhardened data centre','Commercial data centre or telecom exchange, unhardened',false),
 ('A08','ordinary government building','Ordinary above-ground government building',false),
 ('A09','duplicate entity','Duplicate of an already-registered entity',false),
 ('A10','civil-defence designation only','Civil-defence shelter designation only',false),
 ('A11','fabricated or misattributed','Claim fabricated, misattributed or transposed',true),
 ('A12','other known typology','Decommissioned facility of a different, already-known typology',false);

-- BES §6.5 base-rate readings. PUBLICATION ONLY — never read by the arithmetic.
insert into registry.base_rate (proposition_class, reference_class, function_set, reading, published_note)
select c::core.proposition_class, rc::core.reference_class, fs, r::core.base_rate_reading, note from (values
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
 ('FUNCTION','RC5','mundane','RARE',null),('FUNCTION','RC6','mundane','RARE',null)
) as v(c,rc,fs,r,note)
on conflict do nothing;

-- BES §4.3 UNIVERSAL D0, permanently, for every typology. These are the
-- signals shared by limestone mines, highway tunnels, sewer works,
-- cold-storage caverns, data centres and large airports. Two hundred of them
-- satisfy zero conditions above band D.
insert into registry.diagnosticity_catalog
  (typology_profile, observation_key, observation_label, sign, magnitude,
   universal_d0, rationale, diag_version_id, reviewed_by)
select t, k, l, 'SUPPORTS', 0, true,
       'BES §4.3 universal D0: shared by mines, tunnels, sewer works, cold storage, data centres and airports. The named alternative predicts it just as strongly.',
       (select table_version_id from registry.table_version
         where table_name='diagnosticity' and is_current), 'W0'
from unnest(enum_range(null::core.typology)) t
cross join (values
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
  ('local-lore','"The locals say there is something under there"'),
  ('a-hill','A hill'),
  ('windowless-wall','A windowless wall'),
  ('basement','A basement')
) as o(k,l);

-- A representative slice of the buried-rural/mountain catalog above D0.
insert into registry.diagnosticity_catalog
  (typology_profile, observation_key, observation_label, null_code, sign, magnitude,
   null_excluding, property_locus_default, rationale, diag_version_id, reviewed_by)
select 'military-hardened'::core.typology, k, l, nc::char(3), 'SUPPORTS'::core.evidence_sign,
       m::smallint, ne, pl::core.property_locus, r,
       (select table_version_id from registry.table_version
         where table_name='diagnosticity' and is_current), 'W0'
from (values
 ('dedicated-substation-3x','Dedicated substation exceeding visible footprint by >3x',null,1,false,'PLACE-PROPERTY',
  'BES §4.3 D1: mildly favours; a data centre produces this too.'),
 ('continuous-restricted-airspace','Continuous restricted airspace <3NM, non-flying using agency','A02',2,true,'PLACE-PROPERTY',
  'BES §4.4 anchor E3/A0 -> D3 territory; held at D2 as a place property. A mine does not obtain continuous SUA with a non-flying using agency.'),
 ('htmc-editorial-blanking','Feature present on quad edition N, absent on N+1, no demolition record','A02',2,true,'PLACE-PROPERTY',
  'BES §4.3 D2: cartographic suppression is not a mining practice.'),
 ('blast-valve-line-item','Blast valve or blast door line item in a filed permit','A02',3,true,'CLAIM-PROPERTY',
  'BES §4.4 published anchor: blast-valve line item in a filed permit -> E3/A0 -> D3.'),
 ('nepa-hardening-spec','NEPA document specifying blast doors, valves, shielding or CBR filtration','A02',3,true,'CLAIM-PROPERTY',
  'BES §4.3 D3: an environmental filing that specifies CBR filtration is not describing a quarry.'),
 ('afhra-unit-history','AFHRA unit history (IRIS number) describing the facility','A02',3,true,'CLAIM-PROPERTY',
  'BES §4.3 D3: institutional record naming the facility and its role.'),
 ('mine-permit-active','MSHA regulated-mine permit, active',null,1,false,'PLACE-PROPERTY',
  'BES §4.4 published anchor: MSHA regulated-mine permit, H = hardened -> E1/A3 -> -D1. Recorded as an UNDERCUTS row by the writer.')
) as o(k,l,nc,m,ne,pl,r);

-- BES §6.3, expected-record profiles. The highest-value artifact W0 produced:
-- the gaps sections of the five source registries, made arithmetic.
insert into registry.erp_profile
  (profile_key, country_code, description, x_level, applies_to_classes,
   property_locus, authority_note, silence_override, destroying_event,
   counts_toward_sci, erp_version_id, reviewed_by)
select k, 'US', d, x::core.x_level, cls::core.proposition_class[], pl::core.property_locus,
       an, so::core.silence_reading, de, (x <> 'X0'),
       (select table_version_id from registry.table_version where table_name='erp' and is_current), 'W0'
from (values
 ('county-deed-any-parcel','County deed / assessor parcel record, any CONUS parcel, any era','X3',
  '{EXIST,CONTROL,LOCATE}','PLACE-PROPERTY','The universal floor: every CONUS parcel has a record somewhere.',null,null),
 ('county-deed-fed-to-fed','County deed, federal-to-federal transfer or land withdrawal','X0',
  '{CONTROL}','PLACE-PROPERTY','Federal-to-federal transfers generate no county deed.',null,null),
 ('milcon-jbook-appropriated','MILCON J-book line, appropriated agency, 1950-1990, unclassified','X3',
  '{PROGRAM,HARDEN,FUNCTION}','CLAIM-PROPERTY','Appropriated agency.',null,null),
 ('milcon-non-appropriated','MILCON / appropriations, non-appropriated entity (Federal Reserve, USPS, TVA, FDIC)','X0',
  '{PROGRAM,HARDEN,FUNCTION}','CLAIM-PROPERTY','Non-appropriated entities do not appear in appropriations.',null,null),
 ('nip-mip-construction','NIP/MIP-funded construction, any era','X0',
  '{PROGRAM,HARDEN,FUNCTION}','CLAIM-PROPERTY','Intelligence construction is not line-itemed publicly.',null,null),
 ('frpp-executive-agency','FRPP entry, executive-agency facility, post-1998','X2',
  '{CONTROL,EXIST}','PLACE-PROPERTY',null,null,null),
 ('frpp-security-withheld','FRPP entry, national-security-withheld asset class','X0',
  '{CONTROL,EXIST}','PLACE-PROPERTY','Withheld by statute; availability anti-correlates with the property being detected.',null,null),
 ('fcc-asr-commercial','FCC ASR/ULS registration, commercial emitter','X3',
  '{FUNCTION,FEATURE}','CLAIM-PROPERTY',null,null,null),
 ('fcc-asr-federal','FCC ASR/ULS registration, federal or covert emitter','X0',
  '{FUNCTION,FEATURE}','CLAIM-PROPERTY','Federal spectrum is NTIA/IRAC; the GMF is withheld.',null,null),
 ('nprc-personnel-army','NPRC personnel file, Army 1912-1960 or USAF 1947-1964','X0',
  '{CONTROL,FUNCTION}','CLAIM-PROPERTY','Records destroyed.','RECORD-DESTROYED',
  'NPRC fire, 12 July 1973; approximately 16-18 million files; no duplicates, no index.'),
 ('usgs-htmc-coverage','USGS HTMC quadrangle coverage, any CONUS coordinate','X3',
  '{EXIST,LOCATE,EXTENT}','PLACE-PROPERTY','186,061 sheets, so a temporal-stack absence IS informative.',null,null),
 ('crest-dtic-declassified','CREST/DTIC record, facility declassified >25 years','X2',
  '{HARDEN,FUNCTION,FEATURE}','CLAIM-PROPERTY',null,null,null),
 ('crest-dtic-still-classified','CREST/DTIC record, facility still classified or <25 years','X0',
  '{HARDEN,FUNCTION,FEATURE}','CLAIM-PROPERTY','Absent records are the EXPECTED condition for a classified facility.',null,null),
 ('nepa-eis-major-action','NEPA EIS filed with EPA, major federal action','X2',
  '{HARDEN,FUNCTION,EXTENT}','CLAIM-PROPERTY',null,null,null),
 ('nepa-classified-or-catex','NEPA, classified action or categorical exclusion','X0',
  '{HARDEN,FUNCTION}','CLAIM-PROPERTY','Most defence actions are categorically excluded.',null,null),
 ('local-permit-federal-land','Local building permit, federal construction on federal land','X0',
  '{HARDEN,EXTENT}','CLAIM-PROPERTY','Federal construction is exempt from local permitting.',null,null),
 ('commercial-cover-any-record','Any documentary record, active facility under commercial cover','X0',
  '{FUNCTION,CONTROL,HARDEN}','CLAIM-PROPERTY','A working cover story is the absence of the record.',null,null)
) as v(k,d,x,cls,pl,an,so,de);

insert into registry.canonical_search_set (proposition_class, country_code, erp_profile_id)
select c, 'US', ep.erp_profile_id
  from registry.erp_profile ep
  cross join lateral unnest(ep.applies_to_classes) c
 where ep.country_code = 'US'
on conflict do nothing;

insert into registry.scorer_model (scorer_model_id, model_family, vendor, role) values
  ('bootstrap-curator','human','n/a','CURATOR');
