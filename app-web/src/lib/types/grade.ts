/**
 * GRADE VOCABULARY — the four redundant channels of DESIGN.md §7, minus hue.
 *
 * 1. Position — the ladder stop, or the detached off-rail cell.
 * 2. Letter   — A B C D E F R X, Mono, fixed advance.
 * 3. Band word — the table below.
 * 4. Fill state — filled = attained, open = debt-reachable, dashed = X.
 *
 * There is no hue channel and no function in this file returns one. Remove all
 * colour and every distinction survives.
 *
 * Everything here is a LOOKUP or a TRANSCRIPTION of a SQL function. Nothing
 * computes a grade, averages one, or interpolates between two — grades are
 * ordinal (DESIGN.md §0.3, §19 refusal 3).
 */

import { type Grade, isRanked, RANKED_GRADES } from "./enums";

/**
 * `core.grade_rank(core.grade)`. A=6 … F=1; R and X are NULL because they are
 * unranked epistemic objects, not low grades (GRADING.md §1.4). A caller that
 * wants to sort must handle the null itself rather than coercing it to 0 —
 * coercing is how R ends up reading as "worse than F".
 */
export function gradeRank(g: Grade): number | null {
  switch (g) {
    case "A":
      return 6;
    case "B":
      return 5;
    case "C":
      return 4;
    case "D":
      return 3;
    case "E":
      return 2;
    case "F":
      return 1;
    default:
      return null; // R, X
  }
}

/** `core.rank_grade(smallint)`, the inverse. */
export function rankGrade(rank: number | null): Grade | null {
  if (rank === null) return null;
  return (RANKED_GRADES.find((g) => gradeRank(g) === rank) ?? null) as Grade | null;
}

/**
 * DESIGN.md §7.3 — the band words.
 *
 * "Band words are statements about the record, never about the world"
 * (GRADING.md §9.1). No copy anywhere may paraphrase a band as a claim about
 * existence, which is why the statement column below exists and why it is the
 * thing rendered beside the letter, not a gloss of our own.
 */
export const BAND_WORD: Record<Grade, string> = {
  A: "ESTABLISHED",
  B: "CORROBORATED",
  C: "SUPPORTED",
  D: "INDICATED",
  E: "DOUBTFUL",
  F: "UNSUPPORTED",
  R: "REFUTED",
  X: "NOT ASSESSED",
};

/** The statement-about-the-record for each band. Printed in the `/` legend. */
export const BAND_STATEMENT: Record<Grade, string> = {
  A: "The record contains a dispositive primary document, resolved to bytes at its issuing authority.",
  B: "Three or more independent lineages corroborate the proposition on the record; no single record is dispositive.",
  C: "The record supports the proposition through one verified claim-property witness, or through membership in a documented candidate set.",
  D: "Signals consistent with the proposition, and equally consistent with the named alternative.",
  E: "Verified support exists in the record but fails to discriminate the proposition from its named alternative.",
  F: "Nothing verified in the record favours the proposition.",
  R: "The record affirmatively contradicts the proposition.",
  X: "The proposition has not been assessed. This is the absence of a grade, not a low one.",
};

/**
 * DESIGN.md §8.1 — the generated scope-and-content sentence.
 * Grammar fixed by band; this is the entire mapping and it is deterministic.
 */
export const SCOPE_VERB: Record<Grade, string> = {
  A: "Established",
  B: "Established",
  C: "Supported",
  D: "Indicated",
  E: "Doubtful",
  F: "Unsupported",
  R: "Refuted",
  X: "Not assessed",
};

/**
 * Compose the scope-and-content sentence from N propositions.
 *
 * This is PROSE, deterministically composed, and prose cannot be collapsed into
 * a number — which is precisely why it is permitted to span propositions where
 * a composite grade is not. It asserts nothing the rows do not each say.
 */
export function scopeAndContent(
  parts: { grade: Grade; statement_text: string }[],
): string {
  if (parts.length === 0) return "No proposition has been opened on this entity.";
  const seen = new Map<Grade, string[]>();
  for (const p of parts) {
    const list = seen.get(p.grade) ?? [];
    list.push(p.statement_text);
    seen.set(p.grade, list);
  }
  const order: Grade[] = ["A", "B", "C", "D", "E", "F", "R", "X"];
  const sentences: string[] = [];
  for (const g of order) {
    const list = seen.get(g);
    if (!list || list.length === 0) continue;
    sentences.push(`${SCOPE_VERB[g]}: ${joinClauses(list)}.`);
  }
  return sentences.join(" ");
}

function joinClauses(list: string[]): string {
  const trimmed = list.map((s) => s.replace(/\.$/, ""));
  if (trimmed.length === 1) return trimmed[0]!;
  return `${trimmed.slice(0, -1).join("; ")}; and ${trimmed[trimmed.length - 1]!}`;
}

/**
 * The ladder's one permitted interval (DESIGN.md §19): grade -> debt-ceiling ->
 * ceiling. Both endpoints are computed by SQL; this only reports the stops the
 * span covers so a renderer can hatch them. It never invents an intermediate
 * position and it returns nothing at all when either endpoint is unranked.
 */
export function unreachedStops(grade: Grade, ceiling: Grade | null): Grade[] {
  if (!isRanked(grade) || ceiling === null || !isRanked(ceiling)) return [];
  const g = gradeRank(grade)!;
  const c = gradeRank(ceiling)!;
  if (c <= g) return [];
  return RANKED_GRADES.filter((b) => {
    const r = gradeRank(b)!;
    return r > g && r <= c;
  });
}

/** Grades that publish to the plate. BES §10.3: nothing below band D. */
export function isMappable(g: Grade): boolean {
  const r = gradeRank(g);
  return r !== null && r >= gradeRank("D")!;
}

/** Grades that live in the claims register (`api.claims_register` WHERE clause). */
export function isClaimsRegister(g: Grade): boolean {
  return g === "E" || g === "F" || g === "R" || g === "X";
}
