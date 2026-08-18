import { permanentRedirect } from "next/navigation";

/**
 * `/methodology` → `/method`.
 *
 * DESIGN.md §13 fixes the canonical path as `/method`, and the contents line,
 * the standing foot and every cross-reference in the codebase point there.
 * `/methodology` is the name a reader is more likely to type or to have been
 * handed, so it resolves rather than 404s — but it resolves by REDIRECT rather
 * than by rendering a second copy.
 *
 * Two pages with the same content at two URLs is a citation defect: the house
 * citation style carries a URL, and a register that answers to two addresses for
 * one document has made its own citations ambiguous. One canonical address, one
 * permanent redirect.
 */
export default function MethodologyAlias(): never {
  permanentRedirect("/method");
}
