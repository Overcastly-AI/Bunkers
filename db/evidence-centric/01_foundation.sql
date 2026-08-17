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
