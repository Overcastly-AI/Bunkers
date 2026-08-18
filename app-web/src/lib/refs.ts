/**
 * REFERENCE CODES — DESIGN.md §5, the reference gutter.
 *
 * "Ref codes are stable and DERIVED FROM DATA, NEVER FROM DOM ORDER:
 *  `§2` for sections, `p-EXIST-1` for propositions, `e14` for observations,
 *  `L-3` for limitations, `D-006` for decisions."
 *
 * `core.proposition` has no `ref` column — it has `predicate_key`, a normalised
 * writer-supplied key that guarantees one row per distinct assertion, and a
 * uuid. Neither is quotable in a citation. So the ordinal in `p-EXIST-1` is
 * computed here, and it is computed FROM THE DATA rather than from render
 * order: propositions of a class are ordered by `proposition_id`, which is
 * stable across renders, across sorts, across page loads and across the two
 * repository implementations. Re-sorting the register table cannot renumber a
 * citation.
 *
 * The one thing this does not survive is a new proposition of the same class
 * being inserted with a lower-sorting uuid. That is a real limitation of
 * deriving an ordinal at all, and it is why the house citation style (§10.4)
 * carries the `evidence_state_hash` beside the ref: the hash is what makes the
 * citation resolve to a point in time.
 */

import type { PropositionBadge } from "./types/api";

export function propositionRef(
  badge: PropositionBadge,
  siblings: readonly PropositionBadge[],
): string {
  const sameClass = siblings
    .filter((b) => b.class === badge.class)
    .map((b) => b.proposition_id)
    .sort();
  const n = sameClass.indexOf(badge.proposition_id) + 1;
  return `p-${badge.class}-${n > 0 ? n : 1}`;
}

/** All refs for a proposition set, keyed by `proposition_id`. */
export function propositionRefs(
  badges: readonly PropositionBadge[],
): Map<string, string> {
  const out = new Map<string, string>();
  for (const b of badges) out.set(b.proposition_id, propositionRef(b, badges));
  return out;
}

/** `e14` — the observation ref, which the seed and the DDL both carry directly. */
export function observationRef(key: string): string {
  return key;
}
