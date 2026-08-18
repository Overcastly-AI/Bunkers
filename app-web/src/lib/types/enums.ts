/**
 * ENUMS — transcribed from `supabase/schema.sql` §2 (`create type core.*`).
 *
 * These are not invented. Every union below is the exact label list of a
 * PostgreSQL enum in the DDL, in DDL order, because the ordinal order of
 * several of them is load-bearing (`core.grade_rank`, the class order that
 * `api.candidate_detail` sorts by).
 *
 * If the DDL changes, this file changes. Nothing else in the app may hold a
 * literal grade or class string.
 */

/* ------------------------------------------------------------------ *
 * core.proposition_class — the closed twelve-class enum (SCHEMA.md §4)
 * ------------------------------------------------------------------ */

export const PROPOSITION_CLASSES = [
  "EXIST",
  "EXTENT",
  "HARDEN",
  "CONTROL",
  "FUNCTION",
  "STATUS",
  "LOCATE",
  "FEATURE",
  "PROGRAM",
  "IDENTITY",
  "ORIGIN",
  "TYPOLOGY",
] as const;
export type PropositionClass = (typeof PROPOSITION_CLASSES)[number];

/**
 * The FIXED RENDER ORDER. Not the DDL order — this is the order
 * `api.candidate_detail` sorts propositions into (`array_position(array[...])`)
 * and the order DESIGN.md §8.1 fixes for the stave column. Position stability
 * is what makes the grade matrix comparable across entries: FUNC is always the
 * seventh row.
 */
export const PROPOSITION_CLASS_ORDER = [
  "EXIST",
  "LOCATE",
  "EXTENT",
  "TYPOLOGY",
  "HARDEN",
  "CONTROL",
  "FUNCTION",
  "STATUS",
  "FEATURE",
  "PROGRAM",
  "IDENTITY",
  "ORIGIN",
] as const satisfies readonly PropositionClass[];

/**
 * DESIGN.md §6.1 ① — fixed 4-character class tags, so staves align into a
 * column and class becomes a scannable left edge.
 */
export const CLASS_TAG: Record<PropositionClass, string> = {
  EXIST: "EXST",
  EXTENT: "EXTN",
  HARDEN: "HRDN",
  CONTROL: "CTRL",
  FUNCTION: "FUNC",
  STATUS: "STAT",
  LOCATE: "LOCT",
  FEATURE: "FEAT",
  PROGRAM: "PROG",
  IDENTITY: "IDNT",
  ORIGIN: "ORIG",
  TYPOLOGY: "TYPO",
};

/**
 * SCHEMA.md §4 / GRADING.md: PROGRAM and ORIGIN are `clamp_exempt` by trigger.
 * DESIGN.md §8.1 renders them below the labelled rule reading
 * `UNCLAMPED — THESE DO NOT DESCRIBE THE STRUCTURE`.
 */
export const CLAMP_EXEMPT_CLASSES = ["PROGRAM", "ORIGIN"] as const satisfies
  readonly PropositionClass[];

export function isClampExempt(c: PropositionClass): boolean {
  return (CLAMP_EXEMPT_CLASSES as readonly PropositionClass[]).includes(c);
}

/* ------------------------------------------------------------------ *
 * core.grade
 * ------------------------------------------------------------------ */

export const GRADES = ["A", "B", "C", "D", "E", "F", "R", "X"] as const;
export type Grade = (typeof GRADES)[number];

/** The six RANKED bands. R and X are unranked epistemic objects (GRADING.md §1.4). */
export const RANKED_GRADES = ["A", "B", "C", "D", "E", "F"] as const;
export type RankedGrade = (typeof RANKED_GRADES)[number];

export function isRanked(g: Grade): g is RankedGrade {
  return (RANKED_GRADES as readonly Grade[]).includes(g);
}

export const REFUTATION_STATES = ["R0", "R1", "R2", "R3"] as const;
export type RefutationState = (typeof REFUTATION_STATES)[number];

export const NULL_STATES = [
  "UNTESTED",
  "SURVIVING",
  "DOMINANT",
  "INSUFFICIENT",
  "EXCLUDED",
] as const;
export type NullState = (typeof NULL_STATES)[number];

export const SILENCE_READINGS = [
  "INFORMATIVE",
  "UNINFORMATIVE",
  "RECORD-DESTROYED",
  "UNSEARCHED",
] as const;
export type SilenceReading = (typeof SILENCE_READINGS)[number];

export const BASE_RATE_READINGS = [
  "COMMON",
  "UNCOMMON",
  "RARE",
  "VERY-RARE",
] as const;
export type BaseRateReading = (typeof BASE_RATE_READINGS)[number];

export const REFERENCE_CLASSES = ["RC1", "RC2", "RC3", "RC4", "RC5", "RC6"] as const;
export type ReferenceClass = (typeof REFERENCE_CLASSES)[number];

/* ------------------------------------------------------------------ *
 * Source / document enums
 * ------------------------------------------------------------------ */

export const ORIGIN_TIERS = ["T1", "T2", "T3", "T4", "T5", "PENDING"] as const;
export type OriginTier = (typeof ORIGIN_TIERS)[number];

export const CHANNELS = [
  "ORIGIN-HOST",
  "FAITHFUL-MIRROR",
  "CURATED-ARCHIVE",
  "AGGREGATOR",
  "ADVERSARY-WRITABLE",
] as const;
export type Channel = (typeof CHANNELS)[number];

export const CAUSAL_PROVENANCES = [
  "UNSOLICITED",
  "SOLICITED-3P",
  "SOLICITED-BY-CLAIMANT",
  "SELF-PUBLISHED",
  "CROWD-EDITED",
] as const;
export type CausalProvenance = (typeof CAUSAL_PROVENANCES)[number];

export const CORPUS_ERAS = [
  "PRE-2022",
  "POST-2022-ATTRIBUTED",
  "POST-2022-UNATTRIBUTED",
  "UNKNOWN",
] as const;
export type CorpusEra = (typeof CORPUS_ERAS)[number];

export const RECEIPT_STATES = ["VERIFIED", "UNRESOLVED", "DEAD", "NEGATIVE"] as const;
export type ReceiptState = (typeof RECEIPT_STATES)[number];

/* ------------------------------------------------------------------ *
 * Observation enums
 * ------------------------------------------------------------------ */

export const EVIDENCE_SIGNS = ["SUPPORTS", "UNDERCUTS", "NEUTRAL"] as const;
export type EvidenceSign = (typeof EVIDENCE_SIGNS)[number];

export const EVIDENCE_SCOPES = ["INSTANCE", "CLASS", "ADJACENT"] as const;
export type EvidenceScope = (typeof EVIDENCE_SCOPES)[number];

export const PROPERTY_LOCI = ["CLAIM-PROPERTY", "PLACE-PROPERTY"] as const;
export type PropertyLocus = (typeof PROPERTY_LOCI)[number];

export const DIAGNOSTICITY_SOURCES = ["CATALOG", "GATE", "MATRIX", "DEFAULT"] as const;
export type DiagnosticitySource = (typeof DIAGNOSTICITY_SOURCES)[number];

/**
 * core.evidence_membership — GENERATED STORED in the database. An agent cannot
 * write it and neither can this application: `deriveMembership()` in
 * `src/lib/seed/membership.ts` recompiles the seven §2.4 exclusions the same
 * way the generated column does.
 */
export const EVIDENCE_MEMBERSHIPS = ["V", "U", "INERT", "V0"] as const;
export type EvidenceMembership = (typeof EVIDENCE_MEMBERSHIPS)[number];

/** Diagnosticity is a five-stop discrete ordinal, D0…D4. Never interpolated. */
export const DIAGNOSTICITIES = [0, 1, 2, 3, 4] as const;
export type Diagnosticity = (typeof DIAGNOSTICITIES)[number];

export const EA_EXPECTEDNESS = ["E0", "E1", "E2", "E3"] as const;
export type EaExpectedness = (typeof EA_EXPECTEDNESS)[number];

export const EA_ALTERNATIVES = ["A0", "A1", "A2", "A3"] as const;
export type EaAlternative = (typeof EA_ALTERNATIVES)[number];

export const SEARCH_OUTCOMES = ["POSITIVE", "NEGATIVE", "UNSEARCHED", "ERROR"] as const;
export type SearchOutcome = (typeof SEARCH_OUTCOMES)[number];

export const X_LEVELS = ["X0", "X1", "X2", "X3", "KNOWN-NOT-RELEASED"] as const;
export type XLevel = (typeof X_LEVELS)[number];

/* ------------------------------------------------------------------ *
 * Entity enums
 * ------------------------------------------------------------------ */

export const ENTITY_LEVELS = ["program", "site", "structure"] as const;
export type EntityLevel = (typeof ENTITY_LEVELS)[number];

export const ENTITY_RELATION_KINDS = [
  "PARENT-OF",
  "PART-OF",
  "ADJACENT-TO",
  "ALIAS-OF",
  "MERGED-INTO",
  "DISTINCT-FROM",
  "SUCCESSOR-OF",
  "CONFUSED-WITH",
] as const;
export type EntityRelationKind = (typeof ENTITY_RELATION_KINDS)[number];

export const TYPOLOGIES = [
  "unknown-anomaly",
  "cog-coop",
  "military-hardened",
  "missile-silo",
  "civil-defense-shelter",
  "relay-comms",
  "archive-storage",
  "corporate-data",
  "private-shelter",
  "research",
  "mine-conversion",
  "urban-in-building",
] as const;
export type Typology = (typeof TYPOLOGIES)[number];

export const STATUS_VALUES = [
  "active",
  "standby",
  "decommissioned",
  "converted",
  "sealed",
  "demolished",
  "proposed",
  "studied",
  "cancelled",
  "never-built",
  "unknown",
] as const;
export type StatusValue = (typeof STATUS_VALUES)[number];

export const PUBLICATION_STATES = ["INTERNAL", "PUBLISHED", "WITHDRAWN"] as const;
export type PublicationState = (typeof PUBLICATION_STATES)[number];

export const TRANSITION_CAUSES = [
  "NEW-DISCLOSURE",
  "NEW-SEARCH",
  "NEW-VERIFICATION",
  "RE-ANALYSIS",
  "REFUTATION",
  "STATUS-CHANGE",
  "CANDIDATE-SET-CHANGE",
  "SCORER-CHANGE",
  "TABLE-VERSION-CHANGE",
  "RESCORE-NOISE",
  "REGISTER-ECHO",
  "MERGE",
  "SPLIT",
  "CLAMP",
  "INITIAL",
] as const;
export type TransitionCause = (typeof TRANSITION_CAUSES)[number];

/** DESIGN.md §13.2 §10 — hidden by default behind a toggle that states the count. */
export const INSTRUMENT_DRIFT_CAUSES = [
  "SCORER-CHANGE",
  "TABLE-VERSION-CHANGE",
  "RESCORE-NOISE",
] as const satisfies readonly TransitionCause[];

/* ------------------------------------------------------------------ *
 * Geometry enums — the ones DESIGN.md §8.2 turns into marks
 * ------------------------------------------------------------------ */

export const LOCATE_PRECISIONS = [
  "surveyed",
  "approximate_1km",
  "approximate_10km",
  "regional",
  "admin_area",
  "claimed_only",
  "place_name_only",
  "non_located",
] as const;
export type LocatePrecision = (typeof LOCATE_PRECISIONS)[number];

export const GEOMETRY_REPRESENTATIONS = [
  "point",
  "uncertainty_circle",
  "region_polygon",
  "admin_polygon",
  "none",
] as const;
export type GeometryRepresentation = (typeof GEOMETRY_REPRESENTATIONS)[number];
