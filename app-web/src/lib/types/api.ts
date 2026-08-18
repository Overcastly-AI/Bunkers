/**
 * API ROW TYPES — derived column-for-column from the `api.*` views in
 * `supabase/schema.sql` §18 (THE PUBLISHED PROJECTION).
 *
 * `api` is the only schema PostgREST serves (SCHEMA.md §1). These types are
 * therefore the entire read surface of the register, and nothing in the UI may
 * read a shape that is not one of them. Where a column is `not null` in the DDL
 * the field is non-optional here; where the view left-joins, it is `| null`.
 *
 * Nullability notes worth keeping:
 *  - `api.proposition_badge` LEFT JOINs `core.grade_event`, so every
 *    `transition_cause` / `rubric_version` / `scorer_model_id` /
 *    `evidence_state_hash` field is nullable — a proposition that has never
 *    moved has no current grade event.
 *  - `api.evidence_row` LEFT JOINs the document, corpus, receipt, both quoted
 *    spans, the search receipt and the ERP profile. A negative-search row has
 *    no document at all; a V0 row has no verified receipt. Every one of those
 *    fields is nullable and the UI must render the absence (DESIGN.md §10.2),
 *    never hide the row.
 */

import type {
  BaseRateReading,
  CausalProvenance,
  Channel,
  CorpusEra,
  Diagnosticity,
  DiagnosticitySource,
  EaAlternative,
  EaExpectedness,
  EntityLevel,
  EvidenceMembership,
  EvidenceScope,
  EvidenceSign,
  GeometryRepresentation,
  Grade,
  LocatePrecision,
  NullState,
  OriginTier,
  PropertyLocus,
  PropositionClass,
  ReceiptState,
  ReferenceClass,
  RefutationState,
  SearchOutcome,
  SilenceReading,
  TransitionCause,
  Typology,
  XLevel,
} from "./enums";

/** GeoJSON as PostGIS `st_asgeojson(...)::jsonb` emits it. */
export type GeoJsonGeometry =
  | { type: "Point"; coordinates: [number, number] }
  | { type: "Polygon"; coordinates: [number, number][][] }
  | { type: "MultiPolygon"; coordinates: [number, number][][][] };

/* ====================================================================== *
 * api.proposition_badge
 * "The proposition table that LEADS every entry page (BES §10.1)."
 * One row per proposition. THE atom of the interface: one row -> one stave.
 * ====================================================================== */

export interface PropositionBadge {
  proposition_id: string;
  entity_id: string;
  entity_slug: string;
  entity_name: string;

  class: PropositionClass;
  /** The proposition as a SENTENCE. DESIGN.md §13.2 line 2 renders it in Sans italic. */
  statement_text: string;
  predicate_args: Record<string, unknown>;
  as_of_date: string;

  /** The published grade, after clamp and caps. */
  grade: Grade;
  /** `core.grade_rank` — 6..1 for A..F, null for the unranked R and X. */
  grade_rank: number | null;
  awarded_band: Grade;
  grade_pre_clamp: Grade;
  applied_caps: string[];
  clamped_by_proposition_id: string | null;

  ceiling: Grade | null;
  ceiling_reason: string | null;
  at_ceiling: boolean;

  /** Printed IN FULL PROSE beside the ladder span (DESIGN.md §19, refusal 7). */
  limiting_condition: string | null;
  marginal_flag: boolean;

  refutation_state: RefutationState;
  null_state: NullState;
  null_code: string;
  null_label: string;

  silence_reading: SilenceReading;
  /** Generated verbatim by the view (BES §6.4) so the reader never infers it. */
  silence_prose: string;

  base_rate_reading: BaseRateReading | null;
  reference_class: ReferenceClass | null;
  citogenesis: boolean;

  /** SCI = k/n, rendered literally as n cells with k filled (DESIGN.md §6.1 ⑤). */
  sci: number | null;
  sci_numerator: number | null;
  sci_denominator: number | null;

  /** Independent lineage counts — countable pips, never a bar (DESIGN.md §6.1 ④). */
  l_d2: number;
  l_d3: number;

  v_count: number;
  u_count: number;
  v0_count: number;
  v_claim_count: number;
  inert_count: number;

  /** BES §10.2 TWO BARS, ALWAYS: how much of this grade is the mountain. */
  place_derived_weight: number;
  claim_derived_weight: number;

  condition_results: Record<string, boolean | null>;
  graded_at: string;

  /* LEFT JOIN core.grade_event — null until the grade has moved at least once. */
  transition_cause: TransitionCause | null;
  rubric_version: string | null;
  scorer_model_id: string | null;
  evidence_state_hash: string | null;
}

/* ====================================================================== *
 * api.evidence_row
 * "Every evidence row with its receipt, tier, provenance and diagnosticity,
 *  INCLUDING V0 and quarantined rows shown as inert with the reason."
 * ====================================================================== */

export interface EvidenceRow {
  observation_id: string;
  proposition_id: string;
  statement: string;
  observation_key: string;

  sign: EvidenceSign;
  magnitude: Diagnosticity;
  /** GENERATED: magnitude x sign. Always carries an explicit sign in the UI. */
  signed_weight: number;
  /** GENERATED STORED. Never asserted — see `deriveMembership`. */
  membership: EvidenceMembership;
  /** GENERATED. Occupies the position the quoted span would occupy. */
  exclusion_reason: string | null;

  diagnosticity_source: DiagnosticitySource;
  ea_expectedness: EaExpectedness | null;
  ea_alternative: EaAlternative | null;

  scope: EvidenceScope;
  property_locus: PropertyLocus;
  subject_binding_pass: boolean;
  fact_key: string | null;

  null_excluding: boolean;
  documents_null: boolean;
  /** The §3.4 D4 gate: all six conditions, or the row cannot be D4. */
  gate_pass: boolean;
  gate_conditions: {
    a_tier: boolean;
    b_receipt: boolean;
    c_instance: boolean;
    d_on_its_face: boolean;
    e_authority: boolean;
    f_unsolicited: boolean;
  };

  refutation_class: RefutationState | null;
  rebutted: boolean;
  rebuttal_note: string | null;

  /* LEFT JOIN core.source_document */
  document_id: string | null;
  title: string | null;
  issuing_body: string | null;
  author_name: string | null;
  document_date: string | null;
  url: string | null;
  identifier: string | null;
  identifier_class: string | null;
  origin_tier: OriginTier | null;
  channel: Channel | null;
  causal_provenance: CausalProvenance | null;
  corpus_era: CorpusEra | null;
  self_attesting: boolean | null;
  self_attesting_rationale: string | null;
  register_echo_quarantined: boolean | null;
  lineage_id: string | null;

  /* LEFT JOIN registry.corpus */
  corpus_name: string | null;
  corpus_host: string | null;
  adversary_writable: boolean | null;
  egress_state: string | null;

  /* LEFT JOIN core.retrieval_receipt */
  receipt_state: ReceiptState | null;
  resolved_url: string | null;
  http_status: number | null;
  /** Truncated and click-to-copy in the receipt row: the reproducibility claim. */
  sha256: string | null;
  retrieved_at: string | null;
  mirror_only: boolean | null;
  issuer_metadata_match: boolean | null;
  content_drifted: boolean | null;

  /* LEFT JOIN core.quoted_span — THE PAYLOAD. Serif, and Serif is only this. */
  quoted_text: string | null;
  span_start_offset: number | null;
  span_end_offset: number | null;
  quote_check: string | null;
  binding_quote: string | null;

  /* LEFT JOIN core.search_receipt — the negative side */
  negative_search_query: string | null;
  negative_search_corpus_date: string | null;
  negative_search_result_count: number | null;

  /* LEFT JOIN registry.erp_profile */
  expected_record_profile: string | null;
  expected_record_level: XLevel | null;
}

/* ====================================================================== *
 * api.alternative_table — the alternative-hypothesis disposition table
 * ====================================================================== */

export interface AlternativeRow {
  proposition_id: string;
  null_code: string;
  label: string;
  description: string;
  is_selected: boolean;
  disposition: NullState;
  reasoning: string | null;
  excluding_observation_ids: string[];
}

/* ====================================================================== *
 * api.claims_register — E, F, R and X WITH their origin work
 * ====================================================================== */

export interface ClaimsRegisterRow {
  proposition_id: string;
  entity_id: string;
  slug: string;
  canonical_name: string;
  class: PropositionClass;
  statement_text: string;
  grade: Extract<Grade, "E" | "F" | "R" | "X">;
  limiting_condition: string | null;
  silence_reading: SilenceReading;
  refutation_state: RefutationState;
  citogenesis: boolean;
  base_rate_reading: BaseRateReading | null;
  ceiling: Grade | null;
  at_ceiling: boolean;

  /* LEFT JOIN core.claim — the claim and where it came from. `/claims` sorts
     on first_appearance_date ASCENDING, which turns band F into a chronology
     of American underground folklore (DESIGN.md §8.3). */
  claim_text: string | null;
  first_appearance_date: string | null;
  first_appearance_confidence: string | null;

  refutations:
    | { state: RefutationState; narrative: string; next_review_due: string | null }[]
    | null;
  origin_propositions: { class: PropositionClass; grade: Grade }[] | null;
}

/* ====================================================================== *
 * api.map_feature — the published map projection.
 * The WHERE clause is the security boundary: canaries excluded, and nothing
 * below band D renders at all (BES §10.3).
 * ====================================================================== */

export interface MapFeature {
  entity_id: string;
  slug: string;
  canonical_name: string;
  entity_level: EntityLevel;
  country_code: string;
  typology: Typology | null;

  exist_grade: Grade;
  exist_rank: number | null;
  at_ceiling: boolean;
  marginal_flag: boolean;
  ceiling: Grade | null;
  silence_reading: SilenceReading;
  base_rate_reading: BaseRateReading | null;
  limiting_condition: string | null;

  representation: GeometryRepresentation;
  locate_precision: LocatePrecision;
  locate_grade: Grade | null;
  uncertainty_radius_m: number | null;
  suppression_reason: string | null;

  geom: GeoJsonGeometry | null;

  /**
   * `label_point_3857` IS DELIBERATELY ABSENT FROM THIS TYPE.
   *
   * It exists in the materialised view as a clustering anchor and it is
   * "a rendering-internal quantity [that] is never painted" (DESIGN.md §0.2,
   * §8.2, §19 refusal 4). Omitting it from the read surface means no component
   * can paint it by accident. Clustering reads `api.map_cluster`, which has
   * already consumed it server-side.
   */

  proposition_count: number;
  refuted_count: number;
  unassessed_count: number;
  graded_at: string;
}

/* ====================================================================== *
 * api.map_cluster — server-side clustering, cell id stable across REFRESH
 * ====================================================================== */

export interface MapCluster {
  zoom: number;
  cell_x: number;
  cell_y: number;
  feature_count: number;
  best_exist_rank: number | null;
  best_exist_grade: Grade | null;
  modal_typology: Typology | null;
  country_code: string;
  centroid: GeoJsonGeometry;
  bbox: GeoJsonGeometry;
  sample_entity_ids: string[];
}

/* ====================================================================== *
 * api.methodology_coverage — instrument honesty, published
 * ====================================================================== */

export interface MethodologyCoverageRow {
  slug: string;
  name: string;
  beat: string | null;
  host: string;
  host_tier: OriginTier;
  content_tier: OriginTier;
  value: string | null;
  robots_posture: string | null;
  rate_limits: string | null;
  /** NEGATIVE and UNSEARCHED are never conflated; this is what separates them. */
  egress_state: string;
  egress_probed_at: string | null;
  adversary_writable: boolean;
  tier_trap: boolean;
  machine_generated_blocklist: boolean;
}

/* ====================================================================== *
 * api.expected_record_table — the ERP table, published
 * ====================================================================== */

export interface ExpectedRecordRow {
  profile_key: string;
  description: string;
  x_level: XLevel;
  authority_note: string | null;
  silence_override: string | null;
  destroying_event: string | null;
  era_from: number | null;
  era_to: number | null;
}

/* ====================================================================== *
 * api.telemetry_* — the register about itself
 * ====================================================================== */

export interface TelemetryConfabulationRow {
  agent: string;
  identifiers_emitted: number | null;
  identifiers_resolved: number | null;
  unresolvable_rate: number | null;
}

export interface TelemetryBandOccupancyRow {
  class: PropositionClass;
  grade: Grade;
  n: number;
  pct: number | null;
}

export interface TelemetryRefutationRow {
  refuted: number;
  r2_only: number;
  graded: number;
  reversed: number;
}

/* ====================================================================== *
 * core.search_receipt, as `api.candidate_detail` projects it into
 * `propositions[].search_receipts`. §9 SEARCH LOG on the entry sheet:
 * "Long and boring, and it should be."
 * ====================================================================== */

export interface SearchReceipt {
  query: string;
  corpus_as_of: string | null;
  outcome: SearchOutcome;
  result_count: number | null;
  /** Not in the view's jsonb, but the ERP profile the search discharges. */
  erp_profile?: string | null;
  expected_record_level?: XLevel | null;
  egress_state?: string | null;
}

/* ====================================================================== *
 * api.candidate_detail(p_slug) — one round trip, the whole entry sheet.
 * ====================================================================== */

export interface CandidateEntity {
  entity_id: string;
  slug: string;
  name: string;
  entity_level: EntityLevel;
  country: string;
  typology: Typology | null;
  reference_class: ReferenceClass | null;

  geometry: GeoJsonGeometry | null;
  representation: GeometryRepresentation;
  locate_precision: LocatePrecision;
  uncertainty_radius_m: number | null;
  /** Set only for `place_name_only`: a name, not a place. Rendered in quotes. */
  claimed_place_name: string | null;
  suppression_reason: string | null;

  aliases: string[] | null;
  distinct_from: { entity_id: string; name: string; note: string | null }[] | null;
}

/** One proposition with everything hanging off it, as the RPC nests it. */
export interface PropositionDetail extends PropositionBadge {
  evidence: EvidenceRow[];
  alternatives: AlternativeRow[];
  search_receipts: SearchReceipt[];
}

export interface CandidateDetail {
  entity: CandidateEntity;
  /** N badges, never one. Ordered by PROPOSITION_CLASS_ORDER. */
  propositions: PropositionDetail[];
  provenance_beacon: {
    rubric: string;
    generated_at: string;
    note: string;
  } | null;
}

/* ====================================================================== *
 * Lineage — `core.trace_origin` / `core.claim_origin` / `core.lineage_count`,
 * granted to anon and rendered by DESIGN.md §12 as the descent spine.
 * Not an api.* view; a set of SECURITY INVOKER functions on core.
 * ====================================================================== */

export interface LineageNode {
  document_id: string;
  siglum: string;
  label: string;
  document_date: string | null;
  origin_tier: OriginTier;
  /** GENERATED on the citation edge: this witness adds no independent lineage. */
  collapses_lineage: boolean;
  /** DESIGN.md §12.2: solid `|-` descent, dashed `|:` contamination. */
  edge_kind: "descent" | "contamination" | "rests-on";
  depth: number;
  resolved: boolean;
  citogenesis: boolean;
  /** `closes_cycle` from core.trace_origin — marked, never hidden. */
  closes_cycle: string | null;
  note: string | null;
}

export interface LineageBlock {
  /** One block per INDEPENDENT lineage. A reader counting blocks is counting L. */
  lineage_index: number;
  origin: LineageNode;
  descendants: LineageNode[];
  /** The collapsed row: "41 downstream appearances - 1 lineage". */
  downstream_count: number;
  /** `core.claim_origin()` labels its own dating basis; never an invented terminus. */
  dating_basis: "document date" | "first observation" | "undated";
}

export interface LineageProfile {
  proposition_id: string;
  document_count: number;
  lineage_count: number;
  /** documents - lineages. The honest replacement for a contamination score. */
  collapse_delta: number;
  /** DESIGN.md §12.1, Sans --t-lede, always first. */
  verdict_sentence: string;
  blocks: LineageBlock[];
  citogenesis_note: string | null;
}

/* ====================================================================== *
 * Silence — DESIGN.md §8.5, the ERP profiles applicable to THIS proposition.
 * `RECORD CLASS · EXPECTED (X) · SEARCHED · RESULT · RECEIPT`
 * ====================================================================== */

export interface SilenceRow {
  proposition_id: string;
  record_class: string;
  expected_record_level: XLevel;
  /** An unsearched class prints "— not searched" and NO ZERO: a zero is a claim. */
  searched: boolean;
  outcome: SearchOutcome | null;
  result_count: number | null;
  receipt: string | null;
  egress_state: string | null;
  /** X0 prints the verbatim sentence; the absence is not evidence against. */
  prose: string | null;
}

/* ====================================================================== *
 * Grade movement — `core.grade_history`. §10 MOVEMENT renders a STEP chart.
 * ====================================================================== */

export interface GradeEvent {
  grade_event_id: string;
  proposition_id: string;
  occurred_at: string;
  grade_from: Grade | null;
  grade_to: Grade;
  transition_cause: TransitionCause;
  rubric_version: string;
  evidence_state_hash: string;
  note: string | null;
}

/* ====================================================================== *
 * STATE OF THE REGISTER — DESIGN.md §13.1(a). Every count reads its real
 * value, which today is 0. Nothing here is a stand-in.
 * ====================================================================== */

export interface RegisterState {
  candidates_published: number;
  propositions_graded: number;
  documents_in_citation_graph: number;
  sources_catalogued: number;
  hosts_in_access_schedule: number;
  hosts_reachable: number;
  measured_confabulation_rate: number | null;
  rubric_version: string;
  tier_version: string;
  diagnosticity_version: string;
  erp_version: string;
  typology_version: string;
  last_grading_run: string | null;
  /** D-006, verbatim. Stated on `/`, in the standing foot, and at /limits. */
  verification_posture: string;
  /** The reason for zero, in the register's own vocabulary (DESIGN.md §18.2). */
  collection_state: string;
}

/** The register table row: `/` (DESIGN.md §13.1 d). No grade column exists. */
export interface RegisterEntryRow {
  entity_id: string;
  slug: string;
  ref: string;
  canonical_name: string;
  aliases: string[];
  jurisdiction: string;
  typology: Typology | null;
  locate_precision: LocatePrecision;
  /** Twelve fixed class cells. Each holds 0..n badges; absent classes render an
   *  empty rail. There is no composite and no slot for one. */
  matrix: Partial<Record<PropositionClass, PropositionBadge[]>>;
  sci: number | null;
  last_moved: string | null;
}
