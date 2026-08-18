/**
 * THE STAVE MODEL — one row of `api.proposition_badge` resolved into the marks
 * DESIGN.md §6 draws, and nothing else.
 *
 * RULE ZERO IS ENFORCED HERE, not in the component. Every field below is either
 * a column of the badge row or a `filter().length` over the observation array
 * the same page prints underneath. There is no averaging, no aggregation, no
 * interpolation and no default that invents a value: where the register has
 * nothing, this returns `null` and the component draws nothing.
 *
 * Two consequences worth stating because they will look like omissions:
 *
 *  - THE DEBT-CEILING SQUARE IS DRAWN ONLY WHERE A VALUE EXISTS. `api
 *    .proposition_badge` has no verification-debt column in the current DDL, so
 *    the index matrix — which reads badges — never draws one. The entry sheet
 *    reads `api.candidate_detail`, which composes it, and draws it there. A
 *    mark that cannot be traced to a returned value is a bug (§0), so its
 *    absence in the index is the correct behaviour rather than a gap.
 *  - THE EVIDENCE BAR IS BUILT FROM COUNTS, NEVER FROM A DISTRIBUTION. The
 *    badge carries `v_count`, `u_count`, `v_claim_count`, `inert_count` and
 *    `v0_count`. Tick heights need per-row diagnosticity, which only the
 *    evidence array has; when the array is absent the bar renders the counts it
 *    does have at the diagnosticity floor and says so in the aria-label rather
 *    than inventing a height.
 */

import type { EvidenceRow, PropositionBadge } from "../types/api";
import type {
  Diagnosticity,
  Grade,
  PropertyLocus,
  PropositionClass,
  SilenceReading,
} from "../types/enums";
import { CLASS_TAG, RANKED_GRADES, isRanked } from "../types/enums";
import { BAND_WORD, gradeRank } from "../types/grade";

/* ------------------------------------------------------------------ *
 * The ladder
 * ------------------------------------------------------------------ */

/** A→F, top to bottom on the tick, left to right on the full stave. */
export const LADDER: readonly Grade[] = RANKED_GRADES;

export interface LadderModel {
  /** Null when the grade is unranked — the A–F region then renders bare. */
  gradeStop: number | null;
  /** The structural maximum. Null when the register states no ceiling. */
  ceilingStop: number | null;
  /** The band reachable if outstanding verification debt resolves. */
  debtStop: number | null;
  /** `■┤` — the terminal bar abuts the square. A distinct, learnable shape. */
  atCeiling: boolean;
  /** Stops strictly above the grade, up to and including the ceiling. */
  unreached: number[];
  /** The detached, unranked cell this proposition occupies, if any. */
  offRail: "R" | "X" | null;
}

/** Index of a grade on the ladder, 0 = A … 5 = F. Null for R and X. */
export function ladderIndex(g: Grade | null): number | null {
  if (g === null || !isRanked(g)) return null;
  return LADDER.indexOf(g);
}

export function ladderModel(
  grade: Grade,
  ceiling: Grade | null,
  atCeiling: boolean,
  debtCeiling: Grade | null,
): LadderModel {
  const offRail = grade === "R" ? "R" : grade === "X" ? "X" : null;
  const gradeStop = ladderIndex(grade);
  const ceilingStop = ladderIndex(ceiling);
  const debtStop = ladderIndex(debtCeiling);

  /**
   * The one permitted interval on the site (§19). Both endpoints are computed
   * by the SQL; this only names the stops between them so a renderer can hatch
   * them. It never invents an intermediate position, and it returns nothing at
   * all when either endpoint is unranked.
   */
  const unreached: number[] = [];
  if (gradeStop !== null && ceilingStop !== null && ceilingStop < gradeStop) {
    for (let i = ceilingStop; i < gradeStop; i++) unreached.push(i);
  }

  return { gradeStop, ceilingStop, debtStop, atCeiling, unreached, offRail };
}

/* ------------------------------------------------------------------ *
 * The evidence bar — two storeys, four quadrants, one row per tick
 * ------------------------------------------------------------------ */

export interface Tick {
  /** D0…D4. The height is a five-stop discrete ordinal, never a scale. */
  d: Diagnosticity;
  /** The observation this tick IS. One tick, one row, no exceptions. */
  key: string;
}

export interface EvidenceModel {
  /** V · CLAIM-PROPERTY — right of the baseline, upper storey. */
  vClaim: Tick[];
  /** V · PLACE-PROPERTY — right of the baseline, lower storey. */
  vPlace: Tick[];
  /** U · CLAIM-PROPERTY — left of the baseline, upper storey. */
  uClaim: Tick[];
  /** U · PLACE-PROPERTY — left of the baseline, lower storey. */
  uPlace: Tick[];
  /** INERT and V0. Retained, displayed, arithmetically inert: off the axis. */
  inert: number;
  /** True when the diagnosticity of each row was unavailable and heights are
   *  therefore uniform. Stated in the aria-label rather than implied. */
  heightsUnknown: boolean;
}

const DESCENDING = (a: Tick, b: Tick) => b.d - a.d;

/**
 * Sort: HIGHEST DIAGNOSTICITY NEAREST THE BASELINE, descending outward. A D4
 * row therefore sits against the axis and is visible instantly, which is the
 * point — D4 is the gate.
 */
export function evidenceModel(
  badge: PropositionBadge,
  rows?: readonly EvidenceRow[],
): EvidenceModel {
  if (rows && rows.length > 0) {
    const pick = (sign: "V" | "U", locus: PropertyLocus): Tick[] =>
      rows
        .filter((r) => r.membership === sign && r.property_locus === locus)
        .map((r) => ({ d: r.magnitude, key: r.observation_key }))
        .sort(DESCENDING);
    return {
      vClaim: pick("V", "CLAIM-PROPERTY"),
      vPlace: pick("V", "PLACE-PROPERTY"),
      uClaim: pick("U", "CLAIM-PROPERTY"),
      uPlace: pick("U", "PLACE-PROPERTY"),
      inert: rows.filter((r) => r.membership === "INERT" || r.membership === "V0")
        .length,
      heightsUnknown: false,
    };
  }

  /**
   * Counts only. `v_claim_count` is a returned column; `v_count −
   * v_claim_count` is the remaining V rows, which are by definition the
   * place-derived ones. No height is asserted, and `heightsUnknown` says so.
   */
  const fill = (n: number, tag: string): Tick[] =>
    Array.from({ length: Math.max(0, n) }, (_, i) => ({
      d: 0 as Diagnosticity,
      key: `${tag}${i + 1}`,
    }));

  return {
    vClaim: fill(badge.v_claim_count, "v-claim-"),
    vPlace: fill(badge.v_count - badge.v_claim_count, "v-place-"),
    uClaim: [],
    uPlace: fill(badge.u_count, "u-"),
    inert: badge.inert_count + badge.v0_count,
    heightsUnknown: true,
  };
}

/* ------------------------------------------------------------------ *
 * Lineage pips — literal, countable, lossless
 * ------------------------------------------------------------------ */

export interface PipModel {
  /** An independent lineage containing a D3+ row. */
  filled: number;
  /** A lineage reaching only D2. */
  open: number;
  total: number;
}

export function pipModel(badge: PropositionBadge): PipModel {
  const filled = Math.max(0, badge.l_d3);
  /** `core.lineage_count(p,2)` counts lineages reaching D2, which includes the
   *  D3 ones. The open pips are therefore the difference, never a second sum. */
  const open = Math.max(0, badge.l_d2 - badge.l_d3);
  return { filled, open, total: filled + open };
}

/* ------------------------------------------------------------------ *
 * SCI — k of n, drawn literally
 * ------------------------------------------------------------------ */

export interface SciModel {
  k: number;
  n: number;
  /** GRADING.md §7.2: nothing to search is COMPLETE. It must not look like 0. */
  emptyDenominator: boolean;
  /** The X-floor as a VISIBLE POSITION, not a colour. */
  thresholdAt: number;
  /** n > 9 collapses the strip to a Mono `k/n`. */
  collapse: boolean;
  value: number | null;
}

export function sciModel(badge: PropositionBadge): SciModel | null {
  const k = badge.sci_numerator;
  const n = badge.sci_denominator;
  if (k === null || n === null) return null;
  return {
    k,
    n,
    emptyDenominator: n === 0,
    thresholdAt: n / 2,
    collapse: n > 9,
    value: badge.sci,
  };
}

/* ------------------------------------------------------------------ *
 * The flag gutter — five fixed slots, always present
 * ------------------------------------------------------------------ */

export const SILENCE_GLYPH: Record<SilenceReading, string> = {
  UNINFORMATIVE: "⌀",
  INFORMATIVE: "!",
  "RECORD-DESTROYED": "†",
  UNSEARCHED: "?",
};

export const SILENCE_WORD: Record<SilenceReading, string> = {
  UNINFORMATIVE: "uninformative",
  INFORMATIVE: "informative",
  "RECORD-DESTROYED": "record destroyed",
  UNSEARCHED: "unsearched",
};

export interface FlagSlot {
  glyph: string | null;
  /** The full words. A glyph is never the only rendering of a flag. */
  label: string;
}

/**
 * `∥` clamped · `≈` marginal · `⟳` citogenesis · silence reading · `⚑` capped.
 * AN EMPTY SLOT RENDERS AS A DOT so that absence is visible: a reader must be
 * able to tell "not clamped" from "this stave does not report clamping."
 */
export function flagSlots(badge: PropositionBadge): [FlagSlot, FlagSlot, FlagSlot, FlagSlot, FlagSlot] {
  const preRank = gradeRank(badge.grade_pre_clamp);
  const pubRank = gradeRank(badge.grade);
  const clamped =
    badge.clamped_by_proposition_id !== null ||
    (preRank !== null && pubRank !== null && pubRank < preRank);

  return [
    { glyph: clamped ? "∥" : null, label: clamped ? "clamped" : "not clamped" },
    {
      glyph: badge.marginal_flag ? "≈" : null,
      label: badge.marginal_flag
        ? "marginal — one contested fact decided this band"
        : "not marginal",
    },
    {
      glyph: badge.citogenesis ? "⟳" : null,
      label: badge.citogenesis ? "citogenesis confirmed" : "no citogenesis found",
    },
    {
      glyph: SILENCE_GLYPH[badge.silence_reading],
      label: `silence ${SILENCE_WORD[badge.silence_reading]}`,
    },
    {
      glyph: badge.applied_caps.length > 0 ? "⚑" : null,
      label:
        badge.applied_caps.length > 0
          ? `caps applied: ${badge.applied_caps.join(", ")}`
          : "no caps applied",
    },
  ];
}

/* ------------------------------------------------------------------ *
 * The whole stave
 * ------------------------------------------------------------------ */

export interface StaveModel {
  class: PropositionClass;
  tag: string;
  grade: Grade;
  band: string;
  ladder: LadderModel;
  evidence: EvidenceModel;
  pips: PipModel;
  sci: SciModel | null;
  flags: [FlagSlot, FlagSlot, FlagSlot, FlagSlot, FlagSlot];
  badge: PropositionBadge;
}

export function staveModel(
  badge: PropositionBadge,
  opts?: { evidence?: readonly EvidenceRow[]; debtCeiling?: Grade | null },
): StaveModel {
  return {
    class: badge.class,
    tag: CLASS_TAG[badge.class],
    grade: badge.grade,
    band: BAND_WORD[badge.grade],
    ladder: ladderModel(
      badge.grade,
      badge.ceiling,
      badge.at_ceiling,
      opts?.debtCeiling ?? null,
    ),
    evidence: evidenceModel(badge, opts?.evidence),
    pips: pipModel(badge),
    sci: sciModel(badge),
    flags: flagSlots(badge),
    badge,
  };
}
