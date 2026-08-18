/**
 * SEED SPEC TYPES — the authoring shape for the calibration specimens.
 *
 * This is deliberately NOT the api.* shape. It is the smaller set of facts a
 * case in `docs/CALIBRATION.md` actually states; everything else in the api
 * row is DERIVED from these by `build.ts`, exactly as the database derives it:
 *
 *   membership, exclusion_reason, signed_weight   generated columns (SCHEMA §5)
 *   v_count, u_count, v0_count, inert_count       counted from the rows
 *   v_claim_count                                 counted from the rows
 *   place_derived_weight, claim_derived_weight    summed from the rows
 *   sci                                           k/n, with the §7.2 correction
 *
 * The point of the split is Rule Zero. An author writing this file CANNOT
 * write a count that no row supports, because there is no field to write it in.
 * A stave compartment that would otherwise be a free-text number is instead a
 * consequence of the observation array beneath it.
 *
 * What IS declared by hand: the grade, the ceiling, the caps, the limiting
 * condition, the lineage counts and the null state. Those are the fixture's
 * EXPECTED VALUES under BES v0.2 — they are what the suite asserts, and
 * deriving them here would mean the fixture grades itself.
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
  EvidenceScope,
  EvidenceSign,
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
} from "../types/enums";
import type { GeoJsonGeometry } from "../types/api";

/* ------------------------------------------------------------------ */
/* Observations                                                        */
/* ------------------------------------------------------------------ */

export interface SpecDocument {
  title: string;
  issuing_body?: string;
  author_name?: string;
  document_date?: string;
  identifier?: string;
  identifier_class?: string;
  url?: string;
  origin_tier: OriginTier;
  channel?: Channel;
  causal_provenance?: CausalProvenance;
  corpus_era?: CorpusEra;
  corpus_name?: string;
  corpus_host?: string;
  adversary_writable?: boolean;
  egress_state?: string;
  /** BES §2.5: the claimant asserting the claim. Routes to ORIGIN, out of V. */
  self_attesting?: boolean;
  self_attesting_rationale?: string;
  /** P-05: first observed after the register published this candidate. */
  register_echo_quarantined?: boolean;
  /** Siglum for the lineage spine and `/sources`. */
  siglum?: string;
}

export interface SpecReceipt {
  state: ReceiptState;
  resolved_url?: string;
  http_status?: number;
  sha256?: string;
  retrieved_at?: string;
  mirror_only?: boolean;
  issuer_metadata_match?: boolean;
  content_drifted?: boolean;
  /** UNRESOLVED splits three ways and the words are never collapsed (§10.2). */
  unresolved_kind?: "NOTFOUND" | "UNREACHABLE" | "AMBIGUOUS";
}

export interface SpecQuote {
  /** Serif, and Serif is ONLY this, anywhere on the site. */
  text: string;
  start: number;
  end: number;
  check?: string;
}

export interface SpecObservation {
  /** Stable local ref: `e1`, `e14`. Becomes the reference-gutter code. */
  key: string;
  statement: string;
  sign: EvidenceSign;
  magnitude: Diagnosticity;
  scope: EvidenceScope;
  property_locus: PropertyLocus;
  /** Enforced, not requested: false demotes INSTANCE -> CLASS (SCHEMA §5). */
  subject_binding_pass?: boolean;
  /** §5.5 fact-key merging: rows sharing a key collapse for L-counting. */
  fact_key?: string;
  diagnosticity_source?: DiagnosticitySource;
  ea_expectedness?: EaExpectedness;
  ea_alternative?: EaAlternative;
  null_excluding?: boolean;
  documents_null?: boolean;
  /** The six §3.4 conditions. All six, or the row cannot be D4. */
  gate?: Partial<{
    a_tier: boolean;
    b_receipt: boolean;
    c_instance: boolean;
    d_on_its_face: boolean;
    e_authority: boolean;
    f_unsolicited: boolean;
  }>;
  refutation_class?: RefutationState;
  rebutted?: boolean;
  rebuttal_note?: string;
  superseded?: boolean;
  document?: SpecDocument;
  receipt?: SpecReceipt;
  quote?: SpecQuote;
  binding_quote?: string;
  /** A negative search receipt: the evidence for an argument from silence. */
  negative_search?: {
    query: string;
    corpus_as_of?: string;
    result_count: number;
    erp_profile?: string;
    expected_record_level?: XLevel;
  };
  lineage_id?: string;
}

/* ------------------------------------------------------------------ */
/* Lineage                                                             */
/* ------------------------------------------------------------------ */

export interface SpecLineageNode {
  siglum: string;
  label: string;
  document_date?: string;
  origin_tier: OriginTier;
  collapses?: boolean;
  edge_kind?: "descent" | "contamination" | "rests-on";
  depth?: number;
  resolved?: boolean;
  citogenesis?: boolean;
  closes_cycle?: string;
  note?: string;
}

export interface SpecLineageBlock {
  origin: SpecLineageNode;
  descendants?: SpecLineageNode[];
  downstream_count?: number;
  dating_basis?: "document date" | "first observation" | "undated";
}

export interface SpecLineage {
  document_count: number;
  lineage_count: number;
  verdict: string;
  blocks?: SpecLineageBlock[];
  citogenesis_note?: string;
}

/* ------------------------------------------------------------------ */
/* Propositions                                                        */
/* ------------------------------------------------------------------ */

export interface SpecSilenceRow {
  record_class: string;
  expected_record_level: XLevel;
  searched: boolean;
  outcome?: SearchOutcome;
  result_count?: number;
  receipt?: string;
  egress_state?: string;
}

export interface SpecAlternative {
  null_code: string;
  label: string;
  description: string;
  is_selected?: boolean;
  disposition: NullState;
  reasoning?: string;
  excluding?: string[];
}

export interface SpecMovement {
  occurred_at: string;
  from?: Grade;
  to: Grade;
  cause: TransitionCause;
  note?: string;
}

export interface SpecProposition {
  /** `p-EXIST-1` — stable, derived from data, never from DOM order. */
  ref: string;
  class: PropositionClass;
  /** The proposition as a SENTENCE. The reader must see a sentence. */
  statement: string;
  predicate_args?: Record<string, unknown>;
  as_of_date?: string;

  /* --- the expected values the calibration suite asserts --- */
  grade: Grade;
  grade_pre_clamp?: Grade;
  awarded_band?: Grade;
  ceiling?: Grade;
  ceiling_reason?: string;
  at_ceiling?: boolean;
  limiting_condition?: string;
  applied_caps?: string[];
  marginal_flag?: boolean;
  clamped_by?: string;
  refutation_state?: RefutationState;
  null_code: string;
  null_label: string;
  null_state: NullState;
  silence_reading?: SilenceReading;
  base_rate_reading?: BaseRateReading;
  reference_class?: ReferenceClass;
  citogenesis?: boolean;
  /** [numerator, denominator]. n = 0 is COMPLETE (SCI 1.000), never zero. */
  sci: [number, number];
  l_d2?: number;
  l_d3?: number;
  condition_results?: Record<string, boolean | null>;
  /** X — VERIFICATION PENDING: unverified leads and the band they could reach. */
  verification_debt?: { leads: number; max_reachable: Grade };

  observations?: SpecObservation[];
  alternatives?: SpecAlternative[];
  silence?: SpecSilenceRow[];
  searches?: {
    query: string;
    corpus_as_of?: string;
    outcome: SearchOutcome;
    result_count?: number;
    erp_profile?: string;
    egress_state?: string;
  }[];
  lineage?: SpecLineage;
  movement?: SpecMovement[];
  /** Margin references into `/limits`, e.g. ["L-3"]. */
  see_limits?: string[];
}

/* ------------------------------------------------------------------ */
/* Entities                                                            */
/* ------------------------------------------------------------------ */

export interface SpecGeometry {
  precision: LocatePrecision;
  /** Present only where the precision earns one. `surveyed` earns a centre. */
  point?: [number, number];
  /** Ground-truth radius in metres, drawn at TRUE ground scale, never scaled. */
  radius_m?: number;
  polygon?: [number, number][];
  /** `place_name_only`: a name, not a place. Rendered in quotes, no geometry. */
  claimed_place_name?: string;
  suppression_reason?: string;
  /** Competing assertions are drawn ALL AT ONCE. Never averaged. */
  competing?: {
    origin_tier: OriginTier;
    label: string;
    point?: [number, number];
    radius_m?: number;
    polygon?: [number, number][];
    superseded?: boolean;
  }[];
  /** Chart tags beside uncertain features: PA / PD / ED / Rep (IHO INT-1). */
  chart_tags?: ("PA" | "PD" | "ED" | "Rep")[];
}

export interface SpecEntity {
  slug: string;
  name: string;
  entity_level: EntityLevel;
  country?: string;
  jurisdiction: string;
  typology?: Typology;
  reference_class?: ReferenceClass;
  reference_class_basis?: string;
  aliases?: string[];
  former_designations?: string[];
  /** Seeded from CALIBRATION P-06 so two facilities can never silently merge. */
  distinct_from?: { slug: string; name: string; note: string }[];
  /** F-05 / P-02. A canary is never publishable; three independent blocks. */
  is_canary?: boolean;
  geometry: SpecGeometry;
  propositions: SpecProposition[];
  notes?: string[];
}

/* ------------------------------------------------------------------ */
/* Cases                                                               */
/* ------------------------------------------------------------------ */

export type CaseMarker =
  | "REPRODUCED"
  | "REVIEWER-CONFLICT"
  | "KNOWN-DIVERGENCE"
  | "MARGINAL"
  | "PAIR-NOT-LETTER"
  | "PIPELINE";

export interface SpecCase {
  /** `A-02`, `R-05`, `P-01`. The specimen sheet URL is /calibration/<case_id>. */
  case_id: string;
  title: string;
  /** The band the summary table files it under. Not a grade of the case. */
  band: "A" | "B" | "C" | "D" | "E" | "F" | "R" | "X" | "PIPELINE";
  marker: CaseMarker;
  /** The expected outcome, verbatim from the CALIBRATION summary table. */
  expected: string;
  sources: string;
  /** Which entity this case is about. Pipeline cases may have none. */
  entity_slug?: string;
  /** Which propositions on that entity the case asserts. */
  proposition_refs?: string[];
  /** What the case guards — the reason it is in the suite at all. */
  demonstrates: string;
  /** Recorded disagreements and declared divergences, in full. */
  notes?: string[];
  /** Cases that must be read beside this one. */
  paired_with?: string[];
}
