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
