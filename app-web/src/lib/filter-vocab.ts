/**
 * THE CAP LEDGER — GRADING.md §9.2, transcribed.
 *
 * DESIGN.md §13.2: "Applied caps are LISTED WITH THEIR DEFINITIONS INLINE, not
 * as codes alone." A cap is the specific named reason a proposition could not
 * go higher, and printing the code without the condition would leave the reader
 * with a label instead of an argument.
 *
 * Re-exports the index filter shape so a component imports one module.
 */

export type { IndexFilter } from "./register";

export const BASE_CAPS = [
  "CAP-1",
  "CAP-2a",
  "CAP-2b",
  "CAP-3",
  "CAP-4",
  "CAP-5",
  "CAP-6",
  "CAP-7",
] as const;

export const CAP_CONDITION: Record<string, string> = {
  "CAP-1": "L(D2) ≤ 1 and A not attained via A1 or A1-alt — maximum band C.",
  "CAP-2a":
    "V[claim] = ∅ for EXIST, EXTENT, LOCATE, FEATURE or TYPOLOGY — maximum band D.",
  "CAP-2b":
    "V[claim] = ∅ for HARDEN, CONTROL, FUNCTION, PROGRAM, IDENTITY or ORIGIN — maximum band E. A claim carried entirely by attributes of the place has no support for the claim at all.",
  "CAP-3": "Citogenesis confirmed — maximum band E.",
  "CAP-4":
    "All support postdates 2022-11-30 with no verified pre-2022 document — maximum band D. A blunt instrument justified only by the absence of a better one.",
  "CAP-5": "V = ∅ — maximum band F. Nothing verified in the record favours the proposition.",
  "CAP-6": "The A1 row is MIRROR-ONLY without A6 corroboration — maximum band B.",
  "CAP-7": "The null hypothesis is unnamed (null_state UNTESTED) — maximum band D.",
};

export function capCondition(code: string): string {
  return CAP_CONDITION[code] ?? "Condition not published for this code.";
}
