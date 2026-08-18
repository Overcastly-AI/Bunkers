/**
 * THE REGISTER INDEX — filtering and sorting, applied to `RegisterEntryRow`.
 *
 * SORT DISCIPLINE (DESIGN.md §10.1). `GRADING.md` §18.12 states BES cannot
 * rank within a band. Two consequences are implemented literally here and are
 * not softened:
 *
 *  1. THERE IS NO SITE-WIDE GRADE TO SORT BY. `sortByBand()` requires a
 *     proposition class, because a "sort by grade" control that did not ask
 *     which class would be sorting by a composite that does not exist. The
 *     column header publishes this.
 *  2. WITHIN A BAND, ORDER IS ARBITRARY. Ties break on `entity_id` — a stable,
 *     meaningless key — rather than on anything that could read as a ranking.
 *     R and X never fold into the ranked order: they are unranked epistemic
 *     objects, so they sort into their own group at the end, labelled.
 */

import type { PropositionBadge, RegisterEntryRow } from "./types/api";
import type { Grade, LocatePrecision, PropositionClass, Typology } from "./types/enums";
import {
  GRADES,
  LOCATE_PRECISIONS,
  PROPOSITION_CLASSES,
  SILENCE_READINGS,
  TYPOLOGIES,
} from "./types/enums";
import { gradeRank } from "./types/grade";
import { flag, many, numeric, one, type SearchParams } from "./query";

/* ------------------------------------------------------------------ *
 * Facets — DESIGN.md §13.1(c)
 * ------------------------------------------------------------------ */

export interface IndexFilter {
  class: PropositionClass[];
  band: Grade[];
  cap: string[];
  silence: string[];
  locate: LocatePrecision[];
  typology: Typology[];
  state: string[];
  citogenesis: boolean;
  at_ceiling: boolean;
  marginal: boolean;
  sci_floor?: number;
}

export const EMPTY_FILTER: IndexFilter = {
  class: [],
  band: [],
  cap: [],
  silence: [],
  locate: [],
  typology: [],
  state: [],
  citogenesis: false,
  at_ceiling: false,
  marginal: false,
};

/**
 * Read the filter off the URL. Unknown values are DROPPED, not coerced: a
 * `?band=Z` must narrow nothing rather than silently matching something, and a
 * typo in a pasted URL must not change what the register appears to contain.
 */
export function parseFilter(sp: SearchParams): IndexFilter {
  const keep = <T extends string>(vals: string[], allowed: readonly T[]): T[] =>
    vals.filter((v): v is T => (allowed as readonly string[]).includes(v));

  return {
    class: keep(many(sp, "class"), PROPOSITION_CLASSES),
    band: keep(many(sp, "band"), GRADES),
    cap: many(sp, "cap"),
    silence: keep(many(sp, "silence"), SILENCE_READINGS),
    locate: keep(many(sp, "locate"), LOCATE_PRECISIONS),
    typology: keep(many(sp, "typology"), TYPOLOGIES),
    state: many(sp, "state"),
    citogenesis: flag(sp, "citogenesis"),
    at_ceiling: flag(sp, "at_ceiling"),
    marginal: flag(sp, "marginal"),
    sci_floor: numeric(sp, "sci_floor"),
  };
}

/** How many facets are narrowing the current view. Printed in the summary so
 *  the disclosure states its own effect rather than hiding it. */
export function activeFacetCount(f: IndexFilter): number {
  return (
    f.class.length +
    f.band.length +
    f.cap.length +
    f.silence.length +
    f.locate.length +
    f.typology.length +
    f.state.length +
    (f.citogenesis ? 1 : 0) +
    (f.at_ceiling ? 1 : 0) +
    (f.marginal ? 1 : 0) +
    (f.sci_floor !== undefined ? 1 : 0)
  );
}

export function allBadges(row: RegisterEntryRow): PropositionBadge[] {
  return Object.values(row.matrix).flatMap((b) => b ?? []);
}

/**
 * The jurisdiction column is county-level (`SCHEMA.md`); the state facet reads
 * the trailing component of it rather than a separate column, because there is
 * no separate column and inventing one would be a value no row carries.
 */
export function stateOf(row: RegisterEntryRow): string {
  const parts = row.jurisdiction.split(",").map((s) => s.trim());
  return parts[parts.length - 1] ?? row.jurisdiction;
}

export function statesIn(rows: readonly RegisterEntryRow[]): string[] {
  return [...new Set(rows.map(stateOf))].sort();
}

export function applyFilter(
  rows: readonly RegisterEntryRow[],
  f: IndexFilter,
): RegisterEntryRow[] {
  return rows.filter((row) => {
    if (f.typology.length > 0 && (row.typology === null || !f.typology.includes(row.typology)))
      return false;
    if (f.locate.length > 0 && !f.locate.includes(row.locate_precision)) return false;
    if (f.state.length > 0 && !f.state.includes(stateOf(row))) return false;
    if (f.sci_floor !== undefined && (row.sci === null || row.sci < f.sci_floor)) return false;

    /**
     * Class and band are ONE predicate, not two. `class=FUNCTION&band=F` must
     * mean "this entity has a FUNCTION proposition at F", not "has a FUNCTION
     * proposition, and separately has something at F" — the second reading is
     * how a filter starts implying a composite.
     */
    const scoped = f.class.length > 0
      ? f.class.flatMap((c) => row.matrix[c] ?? [])
      : allBadges(row);
    if (f.class.length > 0 && scoped.length === 0) return false;
    if (f.band.length > 0 && !scoped.some((b) => f.band.includes(b.grade))) return false;

    const pool = f.band.length > 0 ? scoped.filter((b) => f.band.includes(b.grade)) : scoped;
    if (f.cap.length > 0 && !pool.some((b) => b.applied_caps.some((c) => f.cap.includes(c))))
      return false;
    if (f.silence.length > 0 && !pool.some((b) => f.silence.includes(b.silence_reading)))
      return false;
    if (f.citogenesis && !pool.some((b) => b.citogenesis)) return false;
    if (f.at_ceiling && !pool.some((b) => b.at_ceiling)) return false;
    if (f.marginal && !pool.some((b) => b.marginal_flag)) return false;
    return true;
  });
}

/** How many propositions the filtered view is reporting on. A real count. */
export function propositionCount(rows: readonly RegisterEntryRow[]): number {
  return rows.reduce((a, r) => a + allBadges(r).length, 0);
}

/* ------------------------------------------------------------------ *
 * Sorting
 * ------------------------------------------------------------------ */

export const SORT_KEYS = [
  "ref",
  "name",
  "jurisdiction",
  "typology",
  "locate",
  "sci",
  "moved",
  "band",
] as const;
export type SortKey = (typeof SORT_KEYS)[number];

export function isSortKey(s: string | undefined): s is SortKey {
  return s !== undefined && (SORT_KEYS as readonly string[]).includes(s);
}

/** Published in the column header wherever band order is offered. */
export const BAND_SORT_LIMITATION =
  "Within a band, order is arbitrary. BES cannot rank two C-grade propositions.";

export const BAND_SORT_REQUIRES_CLASS =
  "There is no site-wide grade. Choose a proposition class first — the register has no composite to sort by.";

export interface SortState {
  sort: SortKey;
  dir: "asc" | "desc";
  /** Null unless the reader has chosen one, which band order requires. */
  bandClass: PropositionClass | null;
}

/** Read the sort off the URL, defaulting to catalogue order. */
export function parseSort(sp: SearchParams): SortState {
  const raw = one(sp, "sort");
  const cls = one(sp, "sortclass");
  return {
    sort: isSortKey(raw) ? raw : "ref",
    dir: one(sp, "dir") === "desc" ? "desc" : "asc",
    bandClass:
      cls !== undefined && (PROPOSITION_CLASSES as readonly string[]).includes(cls)
        ? (cls as PropositionClass)
        : null,
  };
}

function cmpString(a: string | null, b: string | null): number {
  if (a === null && b === null) return 0;
  if (a === null) return 1;
  if (b === null) return -1;
  return a.localeCompare(b);
}

function cmpNumber(a: number | null, b: number | null): number {
  if (a === null && b === null) return 0;
  if (a === null) return 1;
  if (b === null) return -1;
  return a - b;
}

/**
 * Band order for one class. Ranked bands first, best to worst; then R, then X,
 * each in its own group — never interleaved with the ranked ones, because they
 * are not on that scale.
 */
function bandKey(row: RegisterEntryRow, cls: PropositionClass): [number, number] {
  const badges = row.matrix[cls] ?? [];
  if (badges.length === 0) return [3, 0];
  let best: number | null = null;
  let unranked = 0;
  for (const b of badges) {
    const r = gradeRank(b.grade);
    if (r === null) unranked = b.grade === "R" ? 1 : 2;
    else best = best === null ? r : Math.max(best, r);
  }
  if (best !== null) return [0, -best];
  return [unranked, 0];
}

export function sortRows(
  rows: readonly RegisterEntryRow[],
  key: SortKey,
  dir: "asc" | "desc",
  bandClass: PropositionClass | null,
): RegisterEntryRow[] {
  const out = [...rows];
  const sign = dir === "desc" ? -1 : 1;
  out.sort((a, b) => {
    let c = 0;
    switch (key) {
      case "ref":
        c = cmpString(a.ref, b.ref);
        break;
      case "name":
        c = cmpString(a.canonical_name, b.canonical_name);
        break;
      case "jurisdiction":
        c = cmpString(a.jurisdiction, b.jurisdiction);
        break;
      case "typology":
        c = cmpString(a.typology, b.typology);
        break;
      case "locate":
        c = cmpString(a.locate_precision, b.locate_precision);
        break;
      case "sci":
        c = cmpNumber(a.sci, b.sci);
        break;
      case "moved":
        c = cmpString(a.last_moved, b.last_moved);
        break;
      case "band": {
        if (bandClass === null) {
          c = cmpString(a.ref, b.ref);
          break;
        }
        const ka = bandKey(a, bandClass);
        const kb = bandKey(b, bandClass);
        c = ka[0] - kb[0] || ka[1] - kb[1];
        break;
      }
    }
    /** Ties break on a stable, meaningless key. Never on anything readable
     *  as a ranking within a band. */
    return c !== 0 ? c * sign : a.entity_id.localeCompare(b.entity_id);
  });
  return out;
}
