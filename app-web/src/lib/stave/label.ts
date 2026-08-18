/**
 * THE GENERATED ARIA SENTENCE — DESIGN.md §16.
 *
 * "Every stave is `role="img"` with a `<title>` and a generated full-sentence
 * `aria-label` … A SCREEN-READER USER RECEIVES MORE THAN A SIGHTED USER GETS
 * FROM THE THUMBNAIL."
 *
 * That is a specification, not a courtesy, and it is what makes the stave's
 * learning cost survivable: everything the six compartments encode is stated in
 * words here, including the two things the small sizes are honestly lossy about
 * (D0 vs D1 at micro, and `which` proposition in a compressed index cell).
 *
 * The sentence is deterministic. Same row in, same sentence out, so it is
 * quotable and diffable.
 */

import type { PropositionBadge } from "../types/api";
import { BAND_WORD } from "../types/grade";
import { SILENCE_WORD, type StaveModel } from "./model";

const WORD = [
  "no",
  "one",
  "two",
  "three",
  "four",
  "five",
  "six",
  "seven",
  "eight",
  "nine",
  "ten",
  "eleven",
  "twelve",
];

/** Small counts read as words; larger ones as figures. Never rounded. */
function n(x: number): string {
  return x >= 0 && x < WORD.length ? WORD[x]! : String(x);
}

function plural(x: number, one: string, many: string): string {
  return x === 1 ? one : many;
}

/** Sentences begin with a capital, including the ones that begin with a count
 *  word. A screen reader reads "Twelve verified…", not "twelve verified…". */
function sentence(s: string): string {
  return s.length === 0 ? s : s[0]!.toUpperCase() + s.slice(1);
}

/**
 * `EXIST: grade A, established, at ceiling.` — the head clause. R and X say
 * plainly that they are off the ranked scale, because that is the single most
 * misreadable thing on the glyph.
 */
function headClause(m: StaveModel): string {
  const b = m.badge;
  const band = BAND_WORD[b.grade].toLowerCase();
  if (b.grade === "R") {
    return `${b.class}: refuted. Off the ranked scale — refuted is not a low grade, it is a different epistemic object. Refutation state ${b.refutation_state}.`;
  }
  if (b.grade === "X") {
    return `${b.class}: not assessed. Off the ranked scale — this is the absence of an assessment, not a low grade.`;
  }
  const parts = [`${b.class}: grade ${b.grade}, ${band}`];
  /** `at ceiling` is the fact; naming the band twice would read as two values. */
  if (b.at_ceiling) parts.push("at ceiling");
  else if (b.ceiling) parts.push(`ceiling ${b.ceiling}, not reached`);
  return `${parts.join(", ")}.`;
}

function evidenceClause(m: StaveModel): string {
  const e = m.evidence;
  const out: string[] = [];
  const vTotal = e.vClaim.length + e.vPlace.length;

  if (vTotal === 0) {
    out.push("No verified supporting observations.");
  } else {
    const d4 = [...e.vClaim, ...e.vPlace].filter((t) => t.d === 4).length;
    const bits = [
      `${n(vTotal)} verified supporting ${plural(vTotal, "observation", "observations")}`,
    ];
    if (!e.heightsUnknown && d4 > 0) {
      bits.push(`${n(d4)} at diagnosticity 4`);
    }
    if (e.vClaim.length === vTotal) bits.push("all claim-derived");
    else if (e.vClaim.length === 0) bits.push("none claim-derived");
    else
      bits.push(
        `${n(e.vClaim.length)} claim-derived, ${n(e.vPlace.length)} place-derived`,
      );
    out.push(sentence(`${bits.join(", ")}.`));
  }

  const uTotal = e.uClaim.length + e.uPlace.length;
  out.push(
    uTotal === 0
      ? "No undercutting observations."
      : sentence(`${n(uTotal)} undercutting ${plural(uTotal, "observation", "observations")}.`),
  );

  if (e.inert > 0) {
    out.push(sentence(`${n(e.inert)} inert ${plural(e.inert, "row", "rows")} retained.`));
  }

  /** CAP-2b made audible, not only visible. */
  if (m.badge.v_claim_count === 0 && vTotal > 0) {
    out.push(
      "No claim-property observation: the upper storey of the evidence bar is empty.",
    );
  }
  if (e.heightsUnknown && vTotal + uTotal > 0) {
    out.push("Per-observation diagnosticity is not carried on this row.");
  }
  return out.join(" ");
}

function lineageClause(m: StaveModel): string {
  const p = m.pips;
  if (p.total === 0) return "No independent lineage.";
  const bits: string[] = [];
  if (p.filled > 0)
    bits.push(
      `${n(p.filled)} independent ${plural(p.filled, "lineage", "lineages")} at diagnosticity 3 or better`,
    );
  if (p.open > 0)
    bits.push(`${n(p.open)} reaching only diagnosticity 2`);
  return sentence(`${bits.join(", ")}.`);
}

function sciClause(m: StaveModel): string {
  if (!m.sci) return "Search completeness not reported.";
  if (m.sci.emptyDenominator)
    return "Search completeness complete on an empty denominator: no record class of this kind would be expected, so there was nothing to search.";
  return `Search completeness ${n(m.sci.k)} of ${n(m.sci.n)}.`;
}

function flagClause(m: StaveModel): string {
  const b = m.badge;
  const out: string[] = [];
  if (m.flags[0].glyph) out.push("Clamped by a parent proposition.");
  if (b.marginal_flag)
    out.push("Marginal: one contested fact decided this band.");
  if (b.citogenesis) out.push("Citogenesis confirmed.");
  out.push(`Silence reading ${SILENCE_WORD[b.silence_reading]}.`);
  out.push(
    b.applied_caps.length === 0
      ? "No caps applied."
      : `Caps applied: ${b.applied_caps.join(", ")}.`,
  );
  return out.join(" ");
}

/**
 * The full sentence. `prefix` carries the specimen containment marker, which
 * DESIGN.md §18 requires to be embedded in EVERY stave aria-label on a
 * calibration sheet — containment mechanism 5.
 */
export function staveLabel(m: StaveModel, prefix?: string): string {
  const parts = [
    headClause(m),
    evidenceClause(m),
    lineageClause(m),
    sciClause(m),
    flagClause(m),
  ];
  if (m.badge.limiting_condition) {
    parts.push(`Limiting condition: ${m.badge.limiting_condition}`);
  }
  const body = parts.join(" ");
  return prefix ? `${prefix} ${body}` : body;
}

/** The short form used on an index cell link, which must still name the band. */
export function tickLabel(badge: PropositionBadge, prefix?: string): string {
  const band = BAND_WORD[badge.grade];
  const head = `${badge.class}: grade ${badge.grade}, ${band.toLowerCase()}`;
  const ceiling = badge.at_ceiling
    ? ", at ceiling"
    : badge.ceiling && badge.ceiling !== badge.grade
      ? `, ceiling ${badge.ceiling}, not reached`
      : "";
  const body = `${head}${ceiling}. ${badge.entity_name}.`;
  return prefix ? `${prefix} ${body}` : body;
}
