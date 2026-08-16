-- =====================================================================
-- BUNKERS REGISTER — PART 3: documents, receipts, citation graph, lineage
-- Requirements 5, 6, 11.
-- =====================================================================

-- =====================================================================
-- 5. LINEAGE — the independence unit (§5, req. 6)
--    Independence is deduplication BEFORE counting. A lineage is a causal
--    cluster of artifacts, not a document count.
-- =====================================================================

create table lineage (
  lineage_id     uuid primary key default gen_random_uuid(),
  label          text not null,
  -- The terminus is whoever is ASSERTING, never whoever is quoted (§5.4).
  terminus_document_id uuid,                        -- FK below
  kind           text not null default 'documentary' check (kind in
                   ('documentary','testimonial','agent_fleet','crowd_map',
                    'machine_generated','compiler_opaque')),
  -- §5.1.2: all findings from agents sharing a base model are ONE lineage.
  model_family   text,
  first_observed_date date,
  earliest_document_id uuid,
  is_quarantined boolean not null default false,    -- §5.1.8 self-exclusion
  quarantine_reason text,
  created_at     timestamptz not null default now()
);
create unique index lineage_model_family_uix on lineage (model_family)
  where model_family is not null;
comment on index lineage_model_family_uix is
  '§5.1.2 enforced by construction: one lineage per base model family, capped at 1. '
  'N prompts over one set of weights is one witness speaking N times.';

-- =====================================================================
-- 6. DOCUMENTS — the artifact. Author-tiered, host-independent (§3.1).
-- =====================================================================

create table document (
  document_id     uuid primary key default gen_random_uuid(),
  source_id       uuid references source(source_id),      -- host/corpus
  lineage_id      uuid references lineage(lineage_id),

  title           text,
  author          text,
  issuing_authority text,          -- the body with authority over the fact (§3.4e)
  document_date   date,
  published_date  date,

  -- THREE ORTHOGONAL PROVENANCE DIMENSIONS (§3)
  origin_tier     origin_tier not null default 'PENDING'
                    references tier_definition(tier),      -- AUTHOR tier
  channel         channel_kind not null default 'ORIGIN_HOST',
  causal_provenance causal_provenance not null default 'UNSOLICITED',
  corpus_era      corpus_era not null default 'UNKNOWN',

  -- identifier + grammar (VERIFIER, fleet demand #1)
  identifier       text,
  identifier_class identifier_class,
  grammar_pass     boolean,
  issuer_metadata_match boolean,

  -- §2.5 self-attestation: author IS the claimant and content IS the claim.
  self_attesting  boolean not null default false,
  self_attesting_reason text,

  -- §3.3 corpus_era is COMPUTED from these, never judged.
  first_observed_date date,
  wayback_first_capture date,
  domain_registered_date date,
  has_named_author boolean,
  byline_history_found boolean,

  -- §5.1.8: quarantined if first observed after the register published the claim.
  register_echo_quarantined boolean not null default false,

  -- §5.1.3/4 compiler transparency: does it expose pullable primaries?
  is_compiler      boolean not null default false,
  compiler_transparent boolean,

  is_published    boolean not null default false,
  created_at      timestamptz not null default now(),

  constraint document_identifier_class_pair
    check ((identifier is null) = (identifier_class is null))
);
create index document_source_ix     on document (source_id);
create index document_lineage_ix    on document (lineage_id);
create index document_identifier_ix on document (identifier_class, identifier);
create index document_tier_ix       on document (origin_tier);
create index document_era_ix        on document (corpus_era);
create index document_pub_ix        on document (is_published) where is_published;

alter table lineage add constraint lineage_terminus_fk
  foreign key (terminus_document_id) references document(document_id);
alter table lineage add constraint lineage_earliest_fk
  foreign key (earliest_document_id) references document(document_id);

-- §2.7 CACHE-AND-REVALIDATE. Never cache-once. One row per fetch; drift is
-- a signal. Quoted-span offsets in `evidence` point at a specific retrieval,
-- because character offsets are only meaningful against specific bytes.
create table retrieval (
  retrieval_id   uuid primary key default gen_random_uuid(),
  document_id    uuid not null references document(document_id) on delete cascade,
  source_host_id uuid references source_host(source_host_id),
  requested_url  text not null,
  resolved_url   text,
  http_status    int,
  sha256_of_bytes sha256_hex,
  content_length bigint,
  content_type   text,
  retrieved_at   timestamptz not null default now(),
  -- §2.6: resolved at a designated faithful mirror rather than the issuer.
  mirror_only    boolean not null default false,
  fetcher        text not null default 'VERIFIER',
  robots_allowed boolean,
  drift_from_retrieval_id uuid references retrieval(retrieval_id),
  is_published   boolean not null default false
);
create index retrieval_doc_ix   on retrieval (document_id, retrieved_at desc);
create index retrieval_hash_ix  on retrieval (sha256_of_bytes);
create index retrieval_drift_ix on retrieval (drift_from_retrieval_id)
  where drift_from_retrieval_id is not null;

-- Untrusted identifiers extracted from fetched text go HERE, never to a
-- citation (§2.7, fleet demand #10). Promotion requires independent
-- resolution at the issuing authority.
create table ops_lead (
  lead_id       uuid primary key default gen_random_uuid(),
  identifier    text not null,
  identifier_class identifier_class,
  extracted_from_document_id uuid references document(document_id),
  extracted_from_host text,
  is_adversary_writable_origin boolean not null default true,
  promoted_document_id uuid references document(document_id),
  promoted_at   timestamptz,
  rejected_reason text,
  created_at    timestamptz not null default now()
);
create index on ops_lead (identifier_class, identifier);

-- =====================================================================
-- 7. CITATION GRAPH (req. 5) — sources cite sources; graph is CYCLIC.
-- =====================================================================

create table citation (
  citation_id     uuid primary key default gen_random_uuid(),
  citing_document_id uuid not null references document(document_id) on delete cascade,
  cited_document_id  uuid not null references document(document_id) on delete cascade,
  edge_kind       citation_edge_kind not null default 'CITES',
  -- How the edge was established. MinHash is a pre-filter only (§5.1.6);
  -- semantic clustering on the ASSERTION is the load-bearing detector.
  detected_by     text not null default 'manual' check (detected_by in
                    ('manual','minhash_shingle','semantic_cluster','explicit_reference',
                     'wayback_diff','db_replication','model_quorum')),
  confidence      numeric check (confidence between 0 and 1),
  -- §5.1.7 counterfactual test, the surviving judgement call.
  counterfactual_same_lineage boolean,
  quorum_models   text[] not null default '{}',
  quorum_disagreed boolean not null default false,
  first_observed_date date,
  is_published    boolean not null default false,
  created_at      timestamptz not null default now(),
  check (citing_document_id <> cited_document_id),
  unique (citing_document_id, cited_document_id, edge_kind)
);
create index citation_citing_ix on citation (citing_document_id);
create index citation_cited_ix  on citation (cited_document_id);

comment on table citation is
  'Directed, CYCLIC. Self-loops are rejected by CHECK; longer cycles are real '
  '(citogenesis loops) and MUST be traversed with the SQL:2023 CYCLE clause. '
  'See 007_queries.sql: every recursive traversal in this codebase carries '
  'both CYCLE detection and a hard depth cap.';

-- The substrate for ORIGIN tracing: which documents carry which claim.
-- ORIGIN(claim K first appears in artifact Z at date D) is graded against this.
create table document_claim (
  document_claim_id uuid primary key default gen_random_uuid(),
  document_id     uuid not null references document(document_id) on delete cascade,
  claim_key       text not null,             -- normalised assertion, not wording
  claim_text      text,
  first_observed_date date,
  wayback_first_capture date,
  semantic_cluster_id uuid,
  is_published    boolean not null default false,
  unique (document_id, claim_key)
);
create index document_claim_key_ix on document_claim (claim_key);
create index document_claim_first_ix on document_claim (claim_key, first_observed_date);

-- §5.4 ATTESTATION CUSTODY. Blocks the cheapest lineage-seeding attack:
-- attributing invented testimony to two real, dead, findable people.
create table attestation (
  attestation_id  uuid primary key default gen_random_uuid(),
  document_id     uuid not null references document(document_id) on delete cascade,
  witness_name    text not null,
  -- resolvability gate (§5.4): independently locatable in a record that
  -- PREDATES the claim and was created for an UNRELATED purpose.
  resolver_document_id uuid references document(document_id),
  resolver_predates_claim boolean,
  resolver_unrelated_purpose boolean,
  witness_resolvable boolean generated always as
    (coalesce(resolver_predates_claim,false) and coalesce(resolver_unrelated_purpose,false)) stored,
  -- custody: an anonymous claim ABOUT what a named person said is one lineage
  -- with the CLAIMANT, not with the person.
  custody_path    text check (custody_path in
                    ('signed_interview','recorded_interview','bylined_quotation',
                     'deposition','oral_history_accession','none')),
  custody_receipt_document_id uuid references document(document_id),
  custody_pass    boolean generated always as
    (custody_path is not null and custody_path <> 'none') stored,
  -- the lineage terminus is the ASSERTER unless custody passes
  effective_lineage_id uuid references lineage(lineage_id),
  is_published    boolean not null default false
);
create index on attestation (document_id);
create index on attestation (lower(witness_name));

-- §5.1.7 log. Two of only two judgement calls left in the model; both are
-- quorum-adjudicated across model families and both are logged.
create table lineage_decision (
  decision_id    uuid primary key default gen_random_uuid(),
  kind           text not null check (kind in ('counterfactual','ea_ordinal')),
  document_a_id  uuid references document(document_id),
  document_b_id  uuid references document(document_id),
  evidence_id    uuid,                      -- FK added in Part 4
  decision       text not null,
  models_voting  text[] not null,
  model_families text[] not null,
  disagreed      boolean not null default false,
  defaulted_to_same_lineage boolean not null default false,   -- §15 default
  decided_at     timestamptz not null default now()
);
