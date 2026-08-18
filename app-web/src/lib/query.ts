/**
 * URL STATE — DESIGN.md §13.1(c), §16, §20.
 *
 * "ALL STATE IN THE URL." Filters are `<form>` GET params, sorts are links,
 * the mark preference is a query parameter, and the back button works. There
 * is no client-side store, no saved view, no cookie and no `localStorage`:
 * "Each is a small persuasion or a small piece of state the URL does not
 * capture."
 *
 * Consequences that are features: every list state on this site is citable,
 * the whole register works with JavaScript disabled, and a filtered view can
 * be pasted into a footnote.
 */

export type SearchParams = Record<string, string | string[] | undefined>;

/** A repeated param (`?band=A&band=B`) always reads back as an array. */
export function many(sp: SearchParams, key: string): string[] {
  const v = sp[key];
  if (v === undefined) return [];
  return (Array.isArray(v) ? v : [v]).filter((s) => s.length > 0);
}

export function one(sp: SearchParams, key: string): string | undefined {
  const v = sp[key];
  const s = Array.isArray(v) ? v[0] : v;
  return s && s.length > 0 ? s : undefined;
}

export function flag(sp: SearchParams, key: string): boolean {
  const v = one(sp, key);
  return v === "1" || v === "true" || v === "on";
}

export function numeric(sp: SearchParams, key: string): number | undefined {
  const v = one(sp, key);
  if (v === undefined) return undefined;
  const n = Number(v);
  return Number.isFinite(n) ? n : undefined;
}

function toParams(sp: SearchParams): URLSearchParams {
  const p = new URLSearchParams();
  for (const [k, v] of Object.entries(sp)) {
    if (v === undefined) continue;
    for (const item of Array.isArray(v) ? v : [v]) {
      if (item.length > 0) p.append(k, item);
    }
  }
  return p;
}

/**
 * Build a link that CHANGES ONE THING and preserves everything else. Passing
 * `null` removes a key. This is what makes a column header a link rather than a
 * control: the reader can see, in the address bar, exactly what changed.
 */
export function withParams(
  base: string,
  sp: SearchParams,
  changes: Record<string, string | null | undefined>,
): string {
  const p = toParams(sp);
  for (const [k, v] of Object.entries(changes)) {
    p.delete(k);
    if (v !== null && v !== undefined && v.length > 0) p.append(k, v);
  }
  const q = p.toString();
  return q.length > 0 ? `${base}?${q}` : base;
}

/** The current URL, reconstructed — used for `<form>` round-trips and cites. */
export function currentUrl(base: string, sp: SearchParams): string {
  return withParams(base, sp, {});
}
