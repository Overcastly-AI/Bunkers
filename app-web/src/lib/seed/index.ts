/**
 * THE SEED — assembled, contained, and marked.
 *
 * DESIGN.md §18.3: "The 34 calibration cases ship as specimen sheets, rendered
 * through the exact same components. This is what makes the launch feel alive
 * rather than broken, and it is precisely what a survey instrument does before
 * fieldwork: IT MEASURES A KNOWN STANDARD AND PUBLISHES THE READING."
 *
 * SPECIMEN CONTAINMENT IS STRICT, "because a project whose entire premise is
 * the separation of established from claimed cannot afford fixtures being
 * mistaken for entries." Six mechanisms are specified and all six are
 * implemented here rather than left to the UI:
 *
 *   1. separate URL namespace `/calibration/[case]`, never `/e/…`
 *   2. `noindex, nofollow`
 *   3. a persistent header rule on every specimen sheet
 *   4. a full-height hatched left margin rule running the length of the page
 *   5. the marker embedded in EVERY stave aria-label on the page
 *   6. excluded from every count on `/`, from `/telemetry`, and from the plate
 *   + no provenance beacon is emitted (`buildCandidateDetail` returns null)
 *
 * The register-facing exports of this module are EMPTY BY CONSTRUCTION. There
 * is no code path from `SPECIMENS` to `REGISTER_ENTRIES`; they are different
 * arrays and the repository interface keeps them on different methods. That is
 * the difference between containment and a convention.
 *
 * DESIGN.md §21.9 records the residual risk honestly: "Publishing 34 specimen
 * sheets risks fixtures being screenshotted as findings. Six containment
 * mechanisms are specified and NONE OF THEM CLOSES IT FULLY."
 */

import type {
  CandidateDetail,
  ClaimsRegisterRow,
  GradeEvent,
  LineageProfile,
  MapFeature,
  RegisterEntryRow,
  RegisterState,
  SilenceRow,
} from "../types/api";
import {
  buildCandidateDetail,
  buildClaimsRows,
  buildLineage,
  buildMapFeature,
  buildMovement,
  buildRegisterRow,
  buildSilence,
  specimenId,
} from "./build";
import { CASES, KNOWN_WRONG, RATIFICATION_ITEM_R3, SUITE_ASSERTIONS } from "./cases";
import { ACKNOWLEDGED_ENTITIES } from "./entities/acknowledged";
import { CLAIMS_ENTITIES } from "./entities/claims";
import { CONTESTED_ENTITIES } from "./entities/contested";
import type { SpecCase, SpecEntity } from "./types";

export { CASES, KNOWN_WRONG, RATIFICATION_ITEM_R3, SUITE_ASSERTIONS };
export type { SpecCase, SpecEntity };

/* ------------------------------------------------------------------ *
 * Containment
 * ------------------------------------------------------------------ */

export interface SpecimenContainment {
  /** Mechanism 1. The specimen namespace. Never `/e/…`. */
  href: string;
  /** Mechanism 2. */
  robots: "noindex, nofollow";
  /** Mechanism 3. Printed as a persistent header rule on the sheet. */
  header_rule: string;
  /** Mechanism 4. The full-height hatched margin rule, 6px, url(#hatch45). */
  hatched_margin: true;
  /** Mechanism 5. Prefixed to EVERY stave aria-label on the page. */
  aria_prefix: string;
  /** Mechanism 6. */
  excluded_from: readonly ["/", "/telemetry", "/plate", "all counts"];
  /** No provenance beacon is emitted for a specimen. */
  provenance_beacon: null;
}

export function containmentFor(caseId: string): SpecimenContainment {
  return {
    href: `/calibration/${caseId}`,
    robots: "noindex, nofollow",
    header_rule:
      `SPECIMEN — CALIBRATION CASE ${caseId}. Expected value under BES v0.2, not a register entry. ` +
      `No candidate has been graded.`,
    hatched_margin: true,
    aria_prefix: `Specimen, calibration case ${caseId}, not a register entry.`,
    excluded_from: ["/", "/telemetry", "/plate", "all counts"],
    provenance_beacon: null,
  };
}

/* ------------------------------------------------------------------ *
 * The specimen sheets
 * ------------------------------------------------------------------ */

export interface SpecimenSheet {
  case: SpecCase;
  containment: SpecimenContainment;
  /** The entity and its full stave column, through the exact same components. */
  detail: CandidateDetail | null;
  /** Keyed by proposition_id. */
  lineage: Record<string, LineageProfile>;
  silence: Record<string, SilenceRow[]>;
  movement: Record<string, GradeEvent[]>;
  /** The rows this entity contributes to the claims register, if any. */
  claims: ClaimsRegisterRow[];
  /**
   * FIG. 1 — the locator figure, subject to the SAME publication gate as the
   * plate (`api.map_feature`'s WHERE clause). Null where the entity is a canary,
   * below band D, or has no renderable geometry. A specimen sheet does not get
   * to draw a mark the register would refuse to draw.
   */
  locator: MapFeature | null;
  /** Notes carried on the entity itself, distinct from the case notes. */
  entity_notes: string[];
  /**
   * §8.7 VERIFICATION DEBT, keyed by proposition_id: unverified leads and the
   * maximum band reachable if all of them resolve. It is NOT a column of
   * `api.proposition_badge` — the current DDL has none — so it travels beside
   * the badge rather than inside it, and the ladder's outline square is drawn
   * only where this map holds a value. A mark with no returned value behind it
   * is a bug (§0), so its absence elsewhere is correct rather than missing.
   */
  debt: Record<string, { leads: number; max_reachable: string }>;
  /** The row this entity contributes to a catalogue table. */
  register_row: RegisterEntryRow;
}

export const SPECIMEN_ENTITIES: SpecEntity[] = [
  ...ACKNOWLEDGED_ENTITIES,
  ...CONTESTED_ENTITIES,
  ...CLAIMS_ENTITIES,
];

const entityBySlug = new Map(SPECIMEN_ENTITIES.map((e) => [e.slug, e]));

/**
 * The catalogue ref for a specimen entity. It is THE CASE ID, not a synthetic
 * `US-PA-ADA-0007`-style register ref, because a specimen has no register ref
 * and minting one that looked like a register ref would defeat containment
 * mechanism 1 at the very first column a reader's eye lands on.
 *
 * An entity read from several angles carries several cases (Greenbrier carries
 * five); the lowest-sorting case id is the ref and the rest are cross-listed.
 */
function refForEntity(slug: string): string {
  const ids = CASES.filter((c) => c.entity_slug === slug)
    .map((c) => c.case_id)
    .sort();
  return ids[0] ?? slug;
}

function buildSheet(c: SpecCase): SpecimenSheet {
  const e = c.entity_slug ? entityBySlug.get(c.entity_slug) : undefined;
  if (!e) {
    return {
      case: c,
      containment: containmentFor(c.case_id),
      detail: null,
      lineage: {},
      silence: {},
      movement: {},
      claims: [],
      locator: null,
      entity_notes: [],
      debt: {},
      register_row: {
        entity_id: `pipeline:${c.case_id}`,
        slug: c.case_id,
        ref: c.case_id,
        canonical_name: c.title,
        aliases: [],
        jurisdiction: "—",
        typology: null,
        locate_precision: "non_located",
        matrix: {},
        sci: null,
        last_moved: null,
      },
    };
  }

  const lineage: Record<string, LineageProfile> = {};
  const silence: Record<string, SilenceRow[]> = {};
  const movement: Record<string, GradeEvent[]> = {};
  const debt: Record<string, { leads: number; max_reachable: string }> = {};
  for (const p of e.propositions) {
    const id = specimenId("prop", e.slug, p.ref);
    const l = buildLineage(e, p);
    if (l) lineage[id] = l;
    const s = buildSilence(e, p);
    if (s.length > 0) silence[id] = s;
    const m = buildMovement(e, p);
    if (m.length > 0) movement[id] = m;
    if (p.verification_debt) debt[id] = p.verification_debt;
  }

  return {
    case: c,
    containment: containmentFor(c.case_id),
    detail: buildCandidateDetail(e),
    lineage,
    silence,
    movement,
    claims: buildClaimsRows(e),
    locator: buildMapFeature(e),
    entity_notes: e.notes ?? [],
    debt,
    register_row: buildRegisterRow(e, refForEntity(e.slug)),
  };
}

export const SPECIMENS: SpecimenSheet[] = CASES.map(buildSheet);

const specimenByCase = new Map(SPECIMENS.map((s) => [s.case.case_id, s]));

export function specimenSheet(caseId: string): SpecimenSheet | null {
  return specimenByCase.get(caseId) ?? null;
}

/**
 * THE SPECIMEN CATALOGUE — the 30 entities, deduplicated, one row each.
 *
 * `SPECIMENS` is keyed by CASE, and an entity read from several angles appears
 * in several cases. A catalogue is keyed by ENTITY, so this collapses on slug
 * and keeps the lowest-sorting case id as the ref.
 *
 * This array exists so the calibration index can be rendered THROUGH THE EXACT
 * SAME COMPONENTS as `/` (DESIGN.md §18.3) — which is the whole point of
 * publishing specimens at all: "it measures a known standard and publishes the
 * reading." It is a separate array from `REGISTER_ENTRIES` and there is no code
 * path between them.
 */
export const SPECIMEN_REGISTER_ROWS: RegisterEntryRow[] = (() => {
  const seen = new Map<string, RegisterEntryRow>();
  for (const s of SPECIMENS) {
    if (!s.detail) continue;
    const slug = s.detail.entity.slug;
    if (!seen.has(slug)) seen.set(slug, s.register_row);
  }
  return [...seen.values()].sort((a, b) => a.ref.localeCompare(b.ref));
})();

/** The specimen claims rows, deduplicated by proposition and sorted by origin
 *  date ascending — band F as a chronology, not a graveyard. */
export const SPECIMEN_CLAIMS: ClaimsRegisterRow[] = (() => {
  const seen = new Map<string, ClaimsRegisterRow>();
  for (const s of SPECIMENS) {
    for (const c of s.claims) if (!seen.has(c.proposition_id)) seen.set(c.proposition_id, c);
  }
  return [...seen.values()];
})();

/** Which cases cover a given entity slug. Cross-listed on the specimen sheet. */
export function casesForEntity(slug: string): SpecCase[] {
  return CASES.filter((c) => c.entity_slug === slug);
}

/** The specimen sheet for an entity slug — the first case that carries it. */
export function specimenSheetForSlug(slug: string): SpecimenSheet | null {
  return SPECIMENS.find((s) => s.detail?.entity.slug === slug) ?? null;
}

/* ------------------------------------------------------------------ *
 * The register surface — empty, and empty by construction.
 * ------------------------------------------------------------------ */

/**
 * DESIGN.md §18.1: "The layout does not change when data arrives. No
 * placeholder component, no skeleton loader, no 'coming soon', no illustration,
 * no email capture, no timeline. Every count reads its real value, WHICH IS 0.
 * Nothing is a stand-in, so nothing has to be torn out later."
 */
export const REGISTER_ENTRIES: RegisterEntryRow[] = [];
export const REGISTER_CLAIMS: ClaimsRegisterRow[] = [];
export const REGISTER_MAP_FEATURES: MapFeature[] = [];

/**
 * STATE OF THE REGISTER. Every field is the register's real value today.
 * D-007: egress is denied in full, so the verification tier cannot resolve a
 * single citation to bytes, and by this register's own standard the whole of W0
 * is V0-UNRESOLVED.
 */
export const REGISTER_STATE: RegisterState = {
  candidates_published: 0,
  propositions_graded: 0,
  documents_in_citation_graph: 0,
  sources_catalogued: 158,
  hosts_in_access_schedule: 122,
  hosts_reachable: 0,
  measured_confabulation_rate: null,
  rubric_version: "BES-0.2.0",
  tier_version: "0.2.0",
  diagnosticity_version: "0.2.0",
  erp_version: "0.2.0",
  typology_version: "1",
  last_grading_run: null,
  /** D-006, verbatim. Stated here, in the standing foot, on `/`, and at /limits. */
  verification_posture:
    "This register's second line of defence is self-verification, not independent verification. That claim is absent, not merely weaker.",
  /** DESIGN.md §18.2, in the register's own vocabulary rather than in apology. */
  collection_state:
    "0 candidates. Collection has not begun. The grading model is ratified (BES v0.2). The schema is executable. Egress to 122 catalogued hosts is being provisioned; until it lands, no citation can be resolved to bytes, and by this register's own standard an unresolved citation is not evidence. Publishing graded candidates before then would mean publishing grades that were never verified. — D-007",
};

/**
 * The standing foot line (DESIGN.md §5). Composed from REGISTER_STATE so it
 * cannot drift from the counts it reports.
 */
export function standingFootLine(s: RegisterState = REGISTER_STATE): string {
  return [
    `rubric v${s.rubric_version.replace(/^BES-/, "").replace(/\.0$/, "")}`,
    `tier v3`,
    `diag v2`,
    `erp v${s.erp_version}`,
    `typology v${s.typology_version}`,
    `egress ${s.hosts_reachable}/${s.hosts_in_access_schedule}`,
    `confabulation ${s.measured_confabulation_rate ?? "—"}`,
    `candidates ${s.candidates_published}`,
    `verification: SELF — single model family, not independent`,
  ].join(" · ");
}
