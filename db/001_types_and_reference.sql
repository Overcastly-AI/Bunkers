-- =====================================================================
-- BUNKERS REGISTER — PART 1: extensions, schemas, types, curated tables
-- Target: PostgreSQL 15+ / PostGIS 3.x (Supabase)
-- Implements: BES v0.2 "Tiered Sufficiency with Signed Evidence"
-- Philosophy: proposition-centric with materialised rollups.
-- =====================================================================

create extension if not exists postgis;
create extension if not exists pgcrypto;

-- ops = adjudication / fleet / telemetry state. NEVER granted to anon.
create schema if not exists ops;

comment on schema ops is
  'Adjudication and fleet state. No grants to anon/authenticated. RLS on, zero permissive policies.';

-- =====================================================================
-- 1. TYPES
-- =====================================================================

-- Grade ladder. Ordered ASCENDING so LEAST()/GREATEST() implement the caps
-- (§9.3) and the monotone clamp (§1.4) natively on the enum.
--   X = not assessed, R = refuted, then F..A.
-- X sorts below R deliberately: clamping a child to an unassessed parent must
-- yield "not assessed", not "unsupported".
create type grade_band as enum ('X','R','F','E','D','C','B','A');

create type proposition_class as enum (
  'EXIST','EXTENT','HARDEN','CONTROL','FUNCTION','STATUS',
  'LOCATE','FEATURE','PROGRAM','IDENTITY','ORIGIN','TYPOLOGY');

create type entity_level as enum ('program','site','structure');

-- §10.4: non_located (documented, coordinates genuinely unknown) is
-- epistemically distinct from claimed_only (a coordinate asserted by a claim).
create type location_precision as enum
  ('surveyed','approximate','regional','claimed_only','non_located');

-- How the map is permitted to draw the entity. Derived, never asserted (§10.3).
create type render_mode as enum ('point','region','list_only');

create type status_value as enum (
  'active','standby','decommissioned','converted','sealed','demolished',
  'proposed','studied','cancelled','never_built','unknown');

create type receipt_state as enum ('VERIFIED','UNRESOLVED','DEAD','NEGATIVE');

-- §3.1. PENDING = uncatalogued source; scored as T4 (§3.2).
create type origin_tier as enum ('T1','T2','T3','T4','T5','PENDING');

create type channel_kind as enum
  ('ORIGIN_HOST','FAITHFUL_MIRROR','CURATED_ARCHIVE','AGGREGATOR','ADVERSARY_WRITABLE');

create type causal_provenance as enum
  ('UNSOLICITED','SOLICITED_3P','SOLICITED_BY_CLAIMANT','SELF_PUBLISHED','CROWD_EDITED');

create type evidence_scope as enum ('INSTANCE','CLASS','ADJACENT');
create type property_locus as enum ('CLAIM_PROPERTY','PLACE_PROPERTY');
create type evidence_sign  as enum ('SUPPORTS','UNDERCUTS','NEUTRAL');

create type corpus_era as enum
  ('PRE_WEB','PRE_2022','POST_2022_ATTRIBUTED','POST_2022_UNATTRIBUTED','UNKNOWN');

create type null_state as enum
  ('UNTESTED','SURVIVING','DOMINANT','INSUFFICIENT','EXCLUDED');

create type silence_reading as enum
  ('INFORMATIVE','UNINFORMATIVE','RECORD_DESTROYED','UNSEARCHED');

create type base_rate_reading as enum ('COMMON','UNCOMMON','RARE','VERY_RARE');
create type reference_class   as enum ('RC1','RC2','RC3','RC4','RC5','RC6');
create type refutation_state  as enum ('R0','R1','R2','R3');

create type refutation_class as enum
  ('R1_ORIGIN_FABRICATED','R2_AFFIRMATIVELY_INCONSISTENT','R3_CONTRADICTED');

-- §11.2. The three instrument-drift causes are suppressed from the public chart.
create type transition_cause as enum (
  'INITIAL','NEW_DISCLOSURE','NEW_SEARCH','NEW_VERIFICATION','RE_ANALYSIS',
  'REFUTATION','STATUS_CHANGE','CANDIDATE_SET_CHANGE','SCORER_CHANGE',
  'TABLE_VERSION_CHANGE','RESCORE_NOISE','REGISTER_ECHO','MERGE','SPLIT','CLAMP');

create type search_outcome as enum
  ('HIT','NEGATIVE','UNSEARCHED','BLOCKED','RECORD_DESTROYED');

-- §2.6 degraded-verification mode: per-host egress is published, not assumed.
create type egress_status as enum
  ('OK','BLOCKED','MIRROR_ONLY','ROBOTS_DISALLOWED','RATE_LIMITED','UNPROBED');

create type entity_relation_kind as enum
  ('PARENT_OF','DISTINCT_FROM','SUCCEEDS','COLOCATED_WITH','CANDIDATE_FOR');

create type citation_edge_kind as enum
  ('CITES','QUOTES','MIRRORS','PARAPHRASES','REGENERATES','TRANSLATES',
   'ATTRIBUTES_TESTIMONY','COMPILES');

-- The fifteen identifier grammars VERIFIER must validate (fleet demand #1).
create type identifier_class as enum (
  'CREST_ESDN','DTIC_AD','NARA_NAID','GAO_REPORT','FEDREG_CITE','GOVINFO_PKG',
  'FCC_ASR','FCC_ULS','FPDS_PIID','FRUS_DOC','USGS_QUAD','COUNTY_PARCEL',
  'MSHA_MINE_ID','AFHRA_IRIS','DOI','IA_IDENTIFIER','RPUID','OTHER');

create type acquisition_method as enum (
  'REST_API','BULK_FILE','SITEMAP_CRAWL','HTML_SCRAPE','S3_STAGED','OAI_PMH',
  'FTP','MANUAL_ONSITE','WAYBACK_CDX','THIRD_PARTY_MIRROR','GIT_CLONE');

-- Ordinal domains. smallint (not enum) so >= comparisons are free.
create domain diag_level as smallint check (value between 0 and 4);   -- §4.2 D0..D4
create domain x_level    as smallint check (value between 0 and 3);   -- §6.2 X0..X3
create domain ea_level   as smallint check (value between 0 and 3);   -- §4.4 E0..E3 / A0..A3
create domain iso_country as char(2) check (value ~ '^[A-Z]{2}$');    -- req. 8
create domain sha256_hex as char(64) check (value ~ '^[0-9a-f]{64}$');

-- =====================================================================
-- 2. VERSIONED CURATED TABLES (§12.1: "four reviewed-write tables")
--    Every grade row pins the version of each table it was scored against.
-- =====================================================================

create table table_version (
  table_version_id  uuid primary key default gen_random_uuid(),
  table_name        text not null check (table_name in
                      ('tier','diagnosticity','erp','candidate_set','rubric')),
  version           text not null,
  effective_from    timestamptz not null default now(),
  superseded_at     timestamptz,
  derivation_note   text,
  unique (table_name, version)
);
comment on table table_version is
  '§12.3/§12.5. A grade is not comparable across versions without re-scoring the baseline.';

-- ---- Tier ladder (§3.1). One table, not three. -----------------------
create table tier_definition (
  tier         origin_tier primary key,
  definition   text not null,
  max_band_supported grade_band not null,     -- PENDING/T4 cannot support A or B
  notes        text
);

-- ---- The 158 catalogued sources (fleet demand #6, req. 11) -----------
-- A source is a CORPUS/HOST. The tier of a DOCUMENT is the tier of its
-- AUTHOR (§3.1), carried on `document`, not here.
create table source (
  source_id          uuid primary key default gen_random_uuid(),
  slug               text not null unique,
  name               text not null,
  beat               text,                       -- the five W0 registry beats
  url                text,
  country            iso_country,                -- null = multinational/global
  host_tier          origin_tier not null default 'PENDING' references tier_definition(tier),
  default_channel    channel_kind not null default 'ORIGIN_HOST',
  default_causal_provenance causal_provenance not null default 'UNSOLICITED',
  is_adversary_writable boolean not null default false,
  -- acquisition: exactly the fields the registries actually carry
  acquisition_methods acquisition_method[] not null default '{}',
  format_notes       text,
  rate_limit_note    text,
  robots_posture     text,
  robots_fetched_at  timestamptz,
  search_technique   text,
  identifier_classes identifier_class[] not null default '{}',
  holdings           text,
  gaps_note          text,                       -- seeds the ERP table (§6.3)
  value_rating       text check (value_rating in ('critical','high','medium','low')),
  registry_payload   jsonb not null default '{}'::jsonb,   -- verbatim W0 row
  is_blocklisted     boolean not null default false,       -- §3.3 machine-gen corpora
  blocklist_reason   text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index on source (host_tier);
create index on source (beat);
create index on source using gin (identifier_classes);

-- Per-host egress reality (§2.6, fleet blocker #0). Probed on a schedule and
-- PUBLISHED, so the register discloses its own reach.
create table source_host (
  source_host_id uuid primary key default gen_random_uuid(),
  source_id      uuid not null references source(source_id) on delete cascade,
  hostname       text not null,
  is_issuing_authority boolean not null default true,   -- false => mirror
  mirror_of_host_id uuid references source_host(source_host_id),
  egress         egress_status not null default 'UNPROBED',
  last_probe_at  timestamptz,
  last_probe_http int,
  robots_txt_sha sha256_hex,
  unique (source_id, hostname)
);
create index on source_host (egress);

-- ---- Enumerated alternative hypotheses (§4.5) ------------------------
-- A table, not an enum: "extensible by reviewed write".
create table null_hypothesis (
  code        text primary key check (code ~ '^A[0-9]{2}$'),
  label       text not null,
  description text,
  is_fabrication_null boolean not null default false,   -- A11
  base_rate_note text,
  retired_at  timestamptz
);

-- ---- Typology profiles: select the diagnosticity catalog (§4.3) ------
create table typology_profile (
  code        text primary key,
  label       text not null,
  description text,
  default_reference_class reference_class,
  refuter_prior text not null default 'default_open'
                check (refuter_prior in ('default_refute','default_open')),  -- §8.5
  country_scope iso_country                                   -- null = universal
);

-- ---- Diagnosticity catalog (§4.3). Lookup, not agent judgement. ------
create table diagnosticity_catalog (
  catalog_id       uuid primary key default gen_random_uuid(),
  version          text not null,
  typology_code    text references typology_profile(code),    -- null = universal
  observation_key  text not null,                             -- e.g. 'ventilation_shaft'
  observation_label text not null,
  applies_to_classes proposition_class[] not null default '{}', -- empty = all
  diagnosticity    diag_level not null,
  sign             evidence_sign not null default 'SUPPORTS',
  -- §4.6 "cannot produce" has a written test: this is the written test.
  null_excluding_for text[] not null default '{}',            -- null_hypothesis codes
  gate_eligible    boolean not null default false,            -- may reach D4 via §3.4
  anchor_note      text,
  retired_at       timestamptz,
  unique (version, typology_code, observation_key)
);
create index on diagnosticity_catalog (observation_key);
create index on diagnosticity_catalog (version) where retired_at is null;

-- §4.4 E/A fallback matrix. Materialised as data so the ceiling (D3) and the
-- negative cells are enforced arithmetically, not by a bolted-on cap.
create table ea_matrix (
  expected_under_h   ea_level not null,      -- E3..E0
  expected_under_alt ea_level not null,      -- A3..A0
  diagnosticity      diag_level not null,
  sign               evidence_sign not null,
  primary key (expected_under_h, expected_under_alt)
);

-- ---- Expected-record profiles (§6.3). The highest-value W0 artifact. --
create table erp_profile (
  erp_profile_id  uuid primary key default gen_random_uuid(),
  version         text not null,
  code            text not null,
  label           text not null,
  country         iso_country not null default 'US',
  x               x_level not null,                       -- X3..X0
  -- X0 has four distinguishable causes; the register renders them differently.
  x0_reason       text check (x0_reason in
                    ('STRUCTURALLY_ABSENT','RECORD_DESTROYED','NEVER_EXISTED','WITHHELD')),
  destroying_event text,                                  -- e.g. 'NPRC fire, 12 July 1973'
  -- applicability: which propositions this record class is expected for
  applies_to_classes proposition_class[] not null default '{}',
  applies_to_typologies text[] not null default '{}',
  applies_to_property_locus property_locus,               -- null = either
  era_from        date,
  era_to          date,
  source_id       uuid references source(source_id),
  known_to_exist_not_released boolean not null default false,  -- DTIC ADB prefix
  note            text,
  retired_at      timestamptz,
  unique (version, code, country)
);
create index on erp_profile (version, country) where retired_at is null;
create index on erp_profile using gin (applies_to_classes);

-- ---- Candidate sets (§9.2 C1c). Adding a candidate dilutes every member. --
create table candidate_set (
  candidate_set_id uuid primary key default gen_random_uuid(),
  version          text not null,
  label            text not null,
  program_proposition_id uuid,           -- FK added in Part 2 (circular)
  documented_instance_count int not null check (documented_instance_count > 0),  -- N
  is_closed_published boolean not null default false,
  denominator_note text,
  created_at       timestamptz not null default now()
);

-- ---- Reference-class base rates (§6.5). Published, never arithmetic. ----
create table base_rate_table (
  version           text not null,
  reference_class   reference_class not null,
  class             proposition_class not null,
  function_set      text not null default 'na'
                    check (function_set in ('sensitive','mundane','na')),
  reading           base_rate_reading not null,
  published_note    text,
  primary key (version, reference_class, class, function_set)
);
