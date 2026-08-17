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
