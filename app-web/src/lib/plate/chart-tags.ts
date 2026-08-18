/**
 * CHART ABBREVIATIONS — PA · PD · ED · Rep.
 *
 * DESIGN.md §8.2 and §9.3 channel 5. "A two-character text label survives zoom,
 * print, greyscale and screenshot when a stroke style might not."
 *
 * These are set beside every uncertain feature and beside NOTHING that is
 * `exact` (§8.2). The absence of a tag is therefore itself informative, which
 * is why `chartTags()` returns an empty array rather than a `"—"` placeholder:
 * a placeholder would occupy the position of a claim.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * WHICH TAGS THE PLATE CAN ACTUALLY ASSERT, AND WHICH IT CANNOT.
 *
 * `api.map_feature` carries the EXIST rollup and the geometry, so `ED` and `PA`
 * are computable from one returned row apiece. It carries neither the competing
 * geometry assertion set nor the LOCATE proposition's evidence profile, so `PD`
 * and `Rep` are NOT computable from a plate row alone.
 *
 * Rule Zero says a mark that cannot be traced to a row is a bug — so this
 * module will not guess them. `PD` and `Rep` are emitted only when the caller
 * supplies the rows they are read from, which happens on SELECTION, where the
 * panel has already fetched the competing assertions (§8.2, "competing geometry
 * is drawn all at once") and the proposition badges. On an unselected feature
 * the plate prints the two tags it can prove and stays silent about the two it
 * cannot. Silence is the correct rendering of an unqueried quantity; this is
 * the same rule §8.5 applies to an unsearched record class, which "prints
 * `— not searched` and NO ZERO, because a zero is a claim."
 * ─────────────────────────────────────────────────────────────────────────────
 */

import type { MapFeature } from "../types/api";
import { gradeRank } from "../types/grade";

export type ChartTag = "ED" | "PD" | "PA" | "Rep";

export const CHART_TAG_EXPANSION: Record<ChartTag, string> = {
  ED: "existence doubtful",
  PD: "position doubtful",
  PA: "position approximate",
  Rep: "reported",
};

export const CHART_TAG_CONDITION: Record<ChartTag, string> = {
  ED: "The EXIST proposition stands at D or below. Doubt about the thing.",
  PD: "Two or more non-superseded sources place this entity in conflicting positions. Doubt about the place.",
  PA: "The position is asserted to within a radius, or has been degraded to one. Not a fixed point.",
  Rep: "Supporting observations exist, but none reaches diagnosticity 2. Reported, not confirmed.",
};

export const INT1_CITATION =
  "International Hydrographic Organization, Chart Specifications of the IHO (INT 1), " +
  "and NOAA/NGA, U.S. Chart No. 1: Symbols, Abbreviations and Terms, 13th ed. " +
  "Section B (Positions) and the abbreviations PA, PD, ED, Rep.";

/**
 * Rows a caller may supply so that `PD` and `Rep` can be proved. Both are
 * optional and both are counts of rows, never judgements.
 */
export interface TagEvidence {
  /**
   * The number of non-superseded `core.geometry_assertion` rows for this
   * entity that place it in a DIFFERENT position from the preferred one.
   * Zero and `undefined` are different: zero means the set was queried and
   * agreed; undefined means it was not queried, and no `PD` is emitted either
   * way — but a caller that passes 0 has published a fact and a caller that
   * omits it has not.
   */
  conflictingAssertions?: number;
  /** `v_count` on the LOCATE proposition — supporting observations retained. */
  locateVCount?: number;
  /**
   * The highest diagnosticity present among those supporting observations.
   * `Rep` fires when support exists but nothing reaches D2.
   */
  locateMaxDiagnosticity?: number;
}

export function chartTags(f: MapFeature, evidence: TagEvidence = {}): ChartTag[] {
  const tags: ChartTag[] = [];

  /* ED — doubt about the THING. One column of one row: the EXIST rollup. */
  const exist = gradeRank(f.exist_grade);
  if (exist !== null && exist <= gradeRank("D")!) tags.push("ED");

  /* PD — doubt about the PLACE. Only when the assertion set was queried. */
  if ((evidence.conflictingAssertions ?? 0) > 0) tags.push("PD");

  /* PA — position approximate. Two independent grounds, either sufficient. */
  const approximate =
    f.locate_precision === "approximate_1km" ||
    f.locate_precision === "approximate_10km" ||
    f.representation === "uncertainty_circle";
  if (approximate) tags.push("PA");

  /* Rep — reported, not confirmed. Requires the LOCATE evidence profile. */
  if (
    evidence.locateVCount !== undefined &&
    evidence.locateVCount > 0 &&
    evidence.locateMaxDiagnosticity !== undefined &&
    evidence.locateMaxDiagnosticity < 2
  ) {
    tags.push("Rep");
  }

  return tags;
}

/**
 * The tags this feature's row could not answer, named so the panel can say so
 * rather than implying the question was asked. Returned as prose fragments,
 * because §8.6's rule generalises: an unqueried quantity renders as words, not
 * as an empty mark that reads like a negative result.
 */
export function unprovableTags(evidence: TagEvidence = {}): ChartTag[] {
  const out: ChartTag[] = [];
  if (evidence.conflictingAssertions === undefined) out.push("PD");
  if (evidence.locateVCount === undefined || evidence.locateMaxDiagnosticity === undefined) {
    out.push("Rep");
  }
  return out;
}
