-- =====================================================================
-- BUNKERS REGISTER — PART 4: signed evidence, receipts, search receipts
-- Requirement 2: observations SUPPORT or UNDERCUT a specific proposition,
-- with magnitude and diagnosticity against a NAMED alternative.
-- Refutation is data, not absence of data.
-- =====================================================================

-- =====================================================================
-- 8. SEARCH RECEIPTS (§7.1) — absence is not citable without a receipt
--    for the absence. Declared BEFORE evidence because negative searches
--    generate signed evidence rows.
-- =====================================================================

create table search_receipt (
  search_receipt_id uuid primary key default gen_random_uuid(),
  proposition_id  uuid not null references proposition(proposition_id) on delete cascade,
  erp_profile_id  uuid references erp_profile(erp_profile_id),
  source_id       uuid references source(source_id),
  query_string    text not null,
  corpus          text not null,
  corpus_version  text,
  corpus_as_of    date,
  executed_at     timestamptz not null default clock_timestamp(),
  executed_by     text not null,
  result_count    int not null default 0,
  outcome         search_outcome not null,
  -- §2.6: if no host in a canonical corpus is reachable the search returns
  -- UNSEARCHED, not NEGATIVE, and the SCI falls accordingly.
  egress_at_execution egress_status,
  raw_response_sha sha256_hex,
  is_published    boolean not null default false,
  constraint search_negative_requires_zero
    check (outcome <> 'NEGATIVE' or result_count = 0)
);
create index search_receipt_prop_ix on search_receipt (proposition_id, outcome);
create index search_receipt_erp_ix  on search_receipt (erp_profile_id);

comment on table search_receipt is
  'Fleet blocker #2 (SILENCE agent). Feeds the SCI (§7.2), the X band, the ERP '
  'machinery (§6) and refutation R3. Null returns are the model''s fuel, not a chore.';

-- =====================================================================
-- 9. EVIDENCE — one row = one signed observation on ONE proposition
-- =====================================================================

create table evidence (
  evidence_id     uuid primary key default gen_random_uuid(),
  proposition_id  uuid not null references proposition(proposition_id) on delete cascade,
  document_id     uuid references document(document_id),
  -- Expected-record negatives (§6.2) are evidence with no document.
  derived_from_search_receipt_id uuid references search_receipt(search_receipt_id),

  ---------------------------------------------------------------------
  -- RESOLVE-OR-DIE (§2.2). VERIFIED requires ALL of: grammar, resolution,
  -- HTTP 200, hashed bytes, deterministic span location, issuer metadata
  -- match, subject binding. Anything else is UNRESOLVED = tier V0:
  -- arithmetically inert on every condition, retained and DISPLAYED.
  ---------------------------------------------------------------------
  receipt_state   receipt_state not null default 'UNRESOLVED',
  retrieval_id    uuid references retrieval(retrieval_id),
  quoted_span     text,
  span_start_offset int,
  span_end_offset   int,
  quote_check     boolean,          -- deterministic, non-LLM

  -- §2.3 SUBJECT BINDING. Failure downgrades scope INSTANCE -> CLASS,
  -- which removes the row from V. Enforced by trigger, not by trust.
  subject_binding_span text,
  subject_binding_alias_id uuid references entity_alias(alias_id),
  subject_binding_pass boolean not null default false,

  ---------------------------------------------------------------------
  -- SIGN, SCOPE, LOCUS — the four columns that do most of the work
  ---------------------------------------------------------------------
  sign            evidence_sign not null,
  scope           evidence_scope not null default 'CLASS',
  property_locus  property_locus not null,
  diagnosticity   diag_level not null default 0,
  -- convenience for filters/aggregates: negative when the row undercuts
  signed_diagnosticity smallint generated always as
    (case sign when 'SUPPORTS' then diagnosticity::int
               when 'UNDERCUTS' then -diagnosticity::int
               else 0 end) stored,

  -- provenance mirrors (denormalised from `document` at write time so V(P)
  -- membership is a single-table index scan; kept in sync by trigger)
  origin_tier     origin_tier not null default 'PENDING',
  channel         channel_kind not null default 'ORIGIN_HOST',
  causal_provenance causal_provenance not null default 'UNSOLICITED',
  corpus_era      corpus_era not null default 'UNKNOWN',
  self_attesting  boolean not null default false,
  register_echo_quarantined boolean not null default false,
  lineage_id      uuid references lineage(lineage_id),

  -- §5.5 fact-key merge: rows sharing fact_key collapse to one for L-counting
  fact_key        text not null,
  superseded_by_evidence_id uuid references evidence(evidence_id),

  ---------------------------------------------------------------------
  -- DIAGNOSTICITY PROVENANCE (§4.3 catalog first, §4.4 E/A matrix fallback)
  ---------------------------------------------------------------------
  diagnosticity_catalog_id uuid references diagnosticity_catalog(catalog_id),
  ea_expected_under_h   ea_level,
  ea_expected_under_alt ea_level,
  ea_proposed_catalog_extension boolean not null default false,

  -- §4.6 "cannot produce" written test, derived: catalog row is null-excluding
  -- for this proposition's null, OR the E/A assignment put A at A0/A1.
  null_excluding  boolean not null default false,
  -- This row affirmatively DOCUMENTS the named alternative (drives DOMINANT).
  documents_null  boolean not null default false,
  -- E0 under H: content improbable under the proposition (drives R2).
  improbable_under_h boolean generated always as
    (ea_expected_under_h = 0) stored,

  ---------------------------------------------------------------------
  -- §3.4 EXPLICIT-STATEMENT GATE. A D4 item is defined as (a)..(f) holding.
  -- Stored as six booleans so reliability is measured per CONDITION (§12.1).
  ---------------------------------------------------------------------
  gate_a_tier_t1_t2        boolean not null default false,
  gate_b_receipt_verified  boolean not null default false,
  gate_c_scope_instance    boolean not null default false,
  gate_d_states_on_face    boolean not null default false,
  gate_e_authority_over_fact boolean not null default false,
  gate_f_unsolicited_unchallenged boolean not null default false,
  gate_pass boolean generated always as
    (gate_a_tier_t1_t2 and gate_b_receipt_verified and gate_c_scope_instance
     and gate_d_states_on_face and gate_e_authority_over_fact
     and gate_f_unsolicited_unchallenged) stored,

  ---------------------------------------------------------------------
  -- A1-alt direct observation (§9.2), EXIST/EXTENT/LOCATE/FEATURE only
  ---------------------------------------------------------------------
  direct_observation      boolean not null default false,
  lawful_physical_access  boolean not null default false,
  georef_control_point_match boolean not null default false,
  attestation_id          uuid references attestation(attestation_id),

  -- Refutation proposal (§8). REFUTER proposes; the grade function adjudicates.
  refutation_class refutation_class,
  rebutted        boolean not null default false,
  rebuttal_note   text,

  -- §2.6 forgery pricing input (A6)
  mirror_only     boolean not null default false,

  scorer_model_id text,
  scorer_model_family text,
  note            text,
  created_at      timestamptz not null default clock_timestamp(),
  is_published    boolean not null default false,

  ---------------------------------------------------------------------
  constraint evidence_has_a_root check (
    document_id is not null or derived_from_search_receipt_id is not null),
  -- A verified receipt REQUIRES the full chain (§2.2). No exceptions.
  constraint evidence_verified_requires_receipt check (
    receipt_state <> 'VERIFIED' or (
      retrieval_id is not null
      and quote_check is true
      and span_start_offset is not null
      and span_end_offset is not null
      and span_end_offset > span_start_offset
      and subject_binding_pass is true)),
  -- Subject-binding failure cannot coexist with INSTANCE scope (§2.3).
  constraint evidence_binding_gates_scope check (
    scope <> 'INSTANCE' or subject_binding_pass is true),
  -- Diagnosticity must be catalogued or matrix-derived. Nothing is free.
  constraint evidence_diag_provenance check (
    diagnosticity = 0
    or diagnosticity_catalog_id is not null
    or (ea_expected_under_h is not null and ea_expected_under_alt is not null)),
  -- §4.4 The matrix ceiling is D3. D4 is unreachable by inference.
  constraint evidence_matrix_ceiling check (
    diagnosticity < 4 or gate_pass),
  -- Expected-record negatives are always UNDERCUTS (§6.2).
  constraint evidence_erp_negative_is_undercut check (
    derived_from_search_receipt_id is null or sign = 'UNDERCUTS')
);

-- V(P) membership is the hottest predicate in the system. This partial index
-- IS the definition of V (§2.4) and makes it an index-only scan.
create index evidence_v_membership_ix on evidence
  (proposition_id, diagnosticity desc, lineage_id)
  where receipt_state = 'VERIFIED'
    and sign = 'SUPPORTS'
    and scope = 'INSTANCE'
    and causal_provenance in ('UNSOLICITED','SOLICITED_3P')
    and corpus_era <> 'POST_2022_UNATTRIBUTED'
    and channel <> 'ADVERSARY_WRITABLE'
    and self_attesting = false
    and register_echo_quarantined = false
    and superseded_by_evidence_id is null;

create index evidence_u_membership_ix on evidence
  (proposition_id, diagnosticity desc, lineage_id)
  where receipt_state = 'VERIFIED' and sign = 'UNDERCUTS';

create index evidence_prop_ix     on evidence (proposition_id);
create index evidence_doc_ix      on evidence (document_id);
create index evidence_factkey_ix  on evidence (proposition_id, fact_key);
create index evidence_lineage_ix  on evidence (lineage_id);
create index evidence_pub_ix      on evidence (is_published) where is_published;
create index evidence_refut_ix    on evidence (proposition_id, refutation_class)
  where refutation_class is not null;

comment on column evidence.receipt_state is
  'UNRESOLVED = tier V0: arithmetically inert on every condition, retained and '
  'displayed. The format-valid-but-unresolvable rate is published per agent as '
  'confabulation telemetry (§2.2, §12.4).';

alter table lineage_decision add constraint lineage_decision_evidence_fk
  foreign key (evidence_id) references evidence(evidence_id);

-- =====================================================================
-- 10. ERP APPLICABILITY — which record classes are EXPECTED for this
--     proposition. Drives SCI (§7.2), silence_reading (§6.4), ceiling.
-- =====================================================================

create table proposition_erp (
  proposition_id uuid not null references proposition(proposition_id) on delete cascade,
  erp_profile_id uuid not null references erp_profile(erp_profile_id),
  applicable     boolean not null default true,
  resolved_x     x_level not null,
  searched       boolean not null default false,
  search_receipt_id uuid references search_receipt(search_receipt_id),
  primary key (proposition_id, erp_profile_id)
);
create index on proposition_erp (proposition_id) where applicable;

-- =====================================================================
-- 11. CANONICAL SEARCH SETS (§7.1) — country-scoped, so expansion is
--     additive (req. 8): a new country is new rows, not a migration.
-- =====================================================================

create table canonical_corpus (
  canonical_corpus_id uuid primary key default gen_random_uuid(),
  country        iso_country not null,
  class          proposition_class not null,
  source_id      uuid not null references source(source_id),
  required       boolean not null default true,
  note           text,
  unique (country, class, source_id)
);
