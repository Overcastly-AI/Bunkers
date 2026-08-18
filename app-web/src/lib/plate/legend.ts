/**
 * THE LEGEND — printed on the plate, not hidden behind a `?`.
 *
 * DESIGN.md §9.6: "Open by default on desktop, in the panel, above the fold —
 * on a chart the legend is PRINTED ON THE PLATE, not hidden behind a `?`. It is
 * a table: SYMBOL · PRECISION · MEANING · n."
 *
 * The `n` column is a `filter().length` over the exact array the plate is
 * drawing from. Rule Zero: every mark corresponds to exactly one value, and
 * every count is a count of rows that are on the plate at this moment. There is
 * no total that is not the length of a list the reader could enumerate.
 */

import type { MapFeature } from "../types/api";
import type { GeometryRepresentation, LocatePrecision } from "../types/enums";
import { LEGEND_ROWS, markFor, type MarkSpec } from "./precision";
import type { NotLocatableRow } from "../repository/types";

export interface LegendRow {
  key: string;
  representation: GeometryRepresentation;
  precision: LocatePrecision;
  mark: MarkSpec;
  /** Count of rows on the plate answering to this symbol. Never an estimate. */
  n: number;
}

export function legendRows(
  features: MapFeature[],
  notLocatable: NotLocatableRow[],
): LegendRow[] {
  return LEGEND_ROWS.map(({ representation, precision }) => {
    const mark = markFor(representation, precision);
    const n = mark.locatable
      ? features.filter(
          (f) => f.representation === representation && matchesPrecision(f, precision),
        ).length
      : notLocatable.filter((r) => r.locate_precision === precision).length;
    return { key: `${representation}:${precision}`, representation, precision, mark, n };
  });
}

/**
 * The legend prints one row per SYMBOL, and several precisions can share a
 * symbol — an `approximate_10km` assertion and a `claimed_only` one both come
 * back as an `uncertainty_circle` with no centre, because that is what the gate
 * did to them. The legend row named `approximate_10km` therefore counts every
 * feature drawn with that mark, or the counts would not sum to the plate.
 */
function matchesPrecision(f: MapFeature, precision: LocatePrecision): boolean {
  if (f.locate_precision === precision) return true;
  if (precision === "approximate_10km") {
    return (
      f.representation === "uncertainty_circle" &&
      (f.locate_precision === "claimed_only" || f.locate_precision === "approximate_1km")
    );
  }
  return false;
}

/* ====================================================================== *
 * The furniture, in words
 * ====================================================================== */

export const PLATE_NUMBER = "PLATE I";
export const PLATE_TITLE = "INDEX MAP TO THE CATALOGUE";

/**
 * §9.4 — "Nothing below band D appears on the plate at all. The plate carries a
 * permanent note in the legend block… THE MAP NEVER OMITS WITHOUT SAYING SO."
 */
export function publicationGateNote(excluded: number): string {
  return (
    `${excluded} candidate${excluded === 1 ? "" : "s"} are excluded from this plate ` +
    `below band D and appear in the claims register →`
  );
}

/** §18 — the plate at zero candidates is a finished object, not a broken one. */
export function emptyPlateAnnotation(featureCount: number): string {
  return (
    `${PLATE_NUMBER} — ${featureCount} feature${featureCount === 1 ? "" : "s"}. ` +
    `Basemap and land-status layers only. The index is empty; the sheet is not.`
  );
}

export const NOT_LOCATABLE_HEADING = "NOT LOCATABLE ON THIS PLATE";

export const NOT_LOCATABLE_NOTE =
  "A map cannot show what has no coordinates. Making the unmappable visible beside " +
  "the map is the honest answer; a candidate that cannot be placed is not a " +
  "candidate that disappears.";

/**
 * §9.5 — every map state lives in the URL, "because a plate you cannot cite is
 * not a plate." These are the parameter names, published so the plate's own
 * address bar is documentation.
 */
export const URL_KEYS = {
  bbox: "bbox",
  zoom: "z",
  centre: "c",
  band: "band",
  class: "class",
  selection: "sel",
  view: "view",
} as const;
