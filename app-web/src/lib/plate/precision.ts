/**
 * THE SYMBOL TABLE — U.S. Chart No. 1 / IHO INT-1, adopted whole.
 *
 * DESIGN.md §8.2. "The register does not invent a vocabulary for 'reported but
 * unconfirmed.' Cartography solved this and has published the solution for two
 * centuries."
 *
 * This module is the single place where a `locate_precision` becomes a mark.
 * Every renderer on the plate — the overlay, the legend, the entry-page locator
 * figure — reads its mark from `markFor()` and from nowhere else, so the six
 * independent channels of §9.3 cannot drift apart between the legend and the
 * sheet. A legend that does not match the plate is a lie with a key attached.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * THE VOCABULARY IS TWO ENUMS, NOT ONE.
 *
 * DESIGN.md §8.2's table is written in the language of the *rendering*
 * (`exact`, `approximate`, `uncertainty_circle`, `region_polygon`,
 * `place_name_only`, `non_located`). The database carries the *assertion*
 * (`core.locate_precision`: surveyed · approximate_1km · approximate_10km ·
 * regional · admin_area · claimed_only · place_name_only · non_located) and the
 * *result of the gate* separately (`core.geometry_representation`: point ·
 * uncertainty_circle · region_polygon · admin_polygon · none).
 *
 * The mark is a function of BOTH, because that is the only way the gate stays
 * visible. `core.render_geometry()` will degrade an `approximate_1km` assertion
 * to an `uncertainty_circle` when the LOCATE proposition is below band C, and
 * when it does, the reader must see a circle with no centre — not a cross —
 * even though the precision column still reads `approximate_1km`. Keying the
 * mark on precision alone would repaint a suppressed point.
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * REFUSAL 5, ENFORCED HERE. "No centre mark on uncertain geometry. A region has
 * no centre. A circle has one only if a source asserted it." `centre: true`
 * appears on exactly two rows of this table, both of which are
 * `representation === "point"`, and `centreOf()` below is the only function in
 * the codebase that returns a paintable coordinate. It returns `null` for
 * everything else and there is no parameter that changes that.
 */

import type { MapFeature } from "../types/api";
import type { GeometryRepresentation, LocatePrecision } from "../types/enums";

/* ====================================================================== *
 * The mark
 * ====================================================================== */

/**
 * The mark *form*. Six forms, and no seventh — in particular there is no
 * `"pin"`, no `"marker"`, and no `"teardrop"`. DESIGN.md §8.2: "Pins are
 * abolished sitewide. No teardrop marker exists in the codebase."
 */
export type MarkForm =
  /** A 9px fine cross with a 1.5px centre dot. A fixed point, and nothing else. */
  | "survey-cross"
  /** The same cross inside a dotted circle drawn at true ground radius. */
  | "cross-in-dotted-circle"
  /** A dotted circle at true ground radius, dot-screened, and EMPTY at the centre. */
  | "dotted-circle"
  /** A dotted polygon, dot-screened, and EMPTY at the centre. */
  | "dotted-polygon"
  /** A solid hairline polygon — a KNOWN footprint, not an uncertainty region. */
  | "surveyed-footprint"
  /** Nothing is drawn. The feature belongs in the NOT LOCATABLE panel. */
  | "none";

export interface MarkSpec {
  form: MarkForm;
  /**
   * §9.3 channel 2 — THE CENTRE. Drawn only where a source asserted a point AND
   * the LOCATE proposition earned band C. "The code path that emits a
   * coordinate below LOCATE band C does not exist."
   */
  centre: boolean;
  /** §9.3 channel 3 — solid hairline for a surveyed extent, DOTTED for uncertainty. */
  boundary: "none" | "dotted" | "solid-hairline";
  /**
   * §9.3 channel 4 — surveyed footprints unfilled or hairline-hatched;
   * uncertainty regions dot-screened. NEVER a translucent wash: "alpha-
   * compositing makes overlapping uncertainty regions look like corroboration."
   */
  interior: "none" | "dot-screen" | "hairline-hatch";
  /** False for `place_name_only` and `non_located`. Drives the docked panel. */
  locatable: boolean;
  /** The legend's PRECISION column. */
  precisionWord: string;
  /** The legend's MEANING column — the reading, in the register's own voice. */
  reading: string;
}

/* ====================================================================== *
 * The table
 * ====================================================================== */

const SURVEY_CROSS: MarkSpec = {
  form: "survey-cross",
  centre: true,
  boundary: "none",
  interior: "none",
  locatable: true,
  precisionWord: "surveyed",
  reading: "A fixed point. An instrument or control-point match, resolved to bytes.",
};

const CROSS_IN_CIRCLE: MarkSpec = {
  form: "cross-in-dotted-circle",
  centre: true,
  boundary: "dotted",
  interior: "none",
  locatable: true,
  precisionWord: "approximate ±1 km",
  reading: "A point known to within the drawn radius. The radius is ground distance, not a symbol size.",
};

const UNCERTAINTY_CIRCLE: MarkSpec = {
  form: "dotted-circle",
  centre: false,
  boundary: "dotted",
  interior: "dot-screen",
  locatable: true,
  precisionWord: "uncertainty circle",
  reading: "Somewhere in here. No source asserts a position inside this circle, so nothing is drawn there.",
};

const REGION_POLYGON: MarkSpec = {
  form: "dotted-polygon",
  centre: false,
  boundary: "dotted",
  interior: "dot-screen",
  locatable: true,
  precisionWord: "regional",
  reading: "Somewhere in this region. The boundary is itself uncertain, which is why it is dotted.",
};

const ADMIN_POLYGON: MarkSpec = {
  form: "dotted-polygon",
  centre: false,
  boundary: "dotted",
  interior: "dot-screen",
  locatable: true,
  precisionWord: "administrative area",
  reading: "Located only to a county or state boundary. The shape is the jurisdiction's, not the facility's.",
};

const SURVEYED_FOOTPRINT: MarkSpec = {
  form: "surveyed-footprint",
  centre: false,
  boundary: "solid-hairline",
  interior: "hairline-hatch",
  locatable: true,
  precisionWord: "surveyed extent",
  reading: "A known footprint. The boundary is solid because the boundary is what was surveyed.",
};

const PLACE_NAME_ONLY: MarkSpec = {
  form: "none",
  centre: false,
  boundary: "none",
  interior: "none",
  locatable: false,
  precisionWord: "place name only",
  reading: "A name, not a place. No coordinate was asserted by any source.",
};

const NON_LOCATED: MarkSpec = {
  form: "none",
  centre: false,
  boundary: "none",
  interior: "none",
  locatable: false,
  precisionWord: "non-located",
  reading: "Documented; position unknown. The record exists and the coordinate does not.",
};

/**
 * THE GATE, RENDERED. `core.render_geometry()` decides `representation`; this
 * decides what that decision looks like. Read the switch in this order: the
 * representation is authoritative, the precision only refines the reading.
 */
export function markFor(
  representation: GeometryRepresentation,
  precision: LocatePrecision,
): MarkSpec {
  switch (representation) {
    case "point":
      /**
       * The gate in `core.render_geometry()` emits `point` only for
       * `surveyed` and `approximate_1km`, and only at LOCATE ≥ C. Both rows
       * below therefore carry `centre: true` legitimately, and no other row in
       * this file does.
       *
       * A `surveyed` point with a non-null `uncertainty_radius_m` (±30 m, say)
       * gets the cross and NOT a circle: at every zoom a 30 m radius is far
       * below the 16px degradation threshold, so drawing it would replace an
       * earned point with a "too small to draw" square — the gate running
       * backwards. The radius is published as text on the feature's panel line
       * and in the locator figure caption, where it is a number rather than a
       * mark that has to survive a projection.
       */
      return precision === "surveyed" ? SURVEY_CROSS : CROSS_IN_CIRCLE;

    case "uncertainty_circle":
      return UNCERTAINTY_CIRCLE;

    case "region_polygon":
      /**
       * `regional` is an explicit uncertainty polygon and is dotted. A polygon
       * asserted as a surveyed footprint is a different object with a different
       * boundary (§9.3 channel 3) — solid, because the boundary is the datum.
       */
      return precision === "surveyed" ? SURVEYED_FOOTPRINT : REGION_POLYGON;

    case "admin_polygon":
      return ADMIN_POLYGON;

    case "none":
      return precision === "place_name_only" ? PLACE_NAME_ONLY : NON_LOCATED;
  }
}

export function markForFeature(f: MapFeature): MarkSpec {
  return markFor(f.representation, f.locate_precision);
}

/* ====================================================================== *
 * REFUSAL 5 — the only coordinate emitter, and its guard
 * ====================================================================== */

/**
 * THE ONLY FUNCTION IN THE PLATE CODEBASE THAT RETURNS A PAINTABLE COORDINATE.
 *
 * It returns the coordinate a source asserted, or `null`. It has no fallback,
 * no centroid branch, no `label_point` branch — `label_point_3857` is not even
 * present on `MapFeature`, so there is nothing here to fall back TO — and no
 * option that relaxes the condition.
 *
 * DESIGN.md §20: "A faint centre dot on an uncertainty circle 'so users have
 * something to click.' This is the same lie at 40% opacity. Uncertain features
 * are clicked by their boundary and their interior screen; the centre stays
 * empty. The dot in the middle is the lie."
 */
export function centreOf(f: MapFeature): [number, number] | null {
  if (f.representation !== "point") return null;
  if (!f.geom || f.geom.type !== "Point") return null;
  if (!markForFeature(f).centre) return null;
  return f.geom.coordinates;
}

/**
 * The table's own invariant, asserted rather than trusted. Called by
 * `npm run plate:check`; cheap enough to call at module load in development.
 *
 * A future edit that adds `centre: true` to a region row fails here rather than
 * in a screenshot six months later.
 */
export function assertCentreDiscipline(): string[] {
  const failures: string[] = [];
  const all: [string, MarkSpec][] = [
    ["SURVEY_CROSS", SURVEY_CROSS],
    ["CROSS_IN_CIRCLE", CROSS_IN_CIRCLE],
    ["UNCERTAINTY_CIRCLE", UNCERTAINTY_CIRCLE],
    ["REGION_POLYGON", REGION_POLYGON],
    ["ADMIN_POLYGON", ADMIN_POLYGON],
    ["SURVEYED_FOOTPRINT", SURVEYED_FOOTPRINT],
    ["PLACE_NAME_ONLY", PLACE_NAME_ONLY],
    ["NON_LOCATED", NON_LOCATED],
  ];
  for (const [name, m] of all) {
    if (m.centre && m.form !== "survey-cross" && m.form !== "cross-in-dotted-circle") {
      failures.push(`${name}: centre mark on a form that is not a cross`);
    }
    if (m.interior === "dot-screen" && m.boundary !== "dotted") {
      failures.push(`${name}: dot-screened interior with a boundary that is not dotted`);
    }
    if (!m.locatable && m.form !== "none") {
      failures.push(`${name}: an unlocatable feature must draw nothing`);
    }
  }
  return failures;
}

/* ====================================================================== *
 * The legend's row order — fixed, and identical to the plate's draw order
 * ====================================================================== */

/**
 * The legend is a table (§9.6) and its rows are drawn "as inline SVG AT TRUE
 * SIZE, not as scaled-up illustrations, so they match the marks exactly." This
 * array is the order those rows print in, and it is deliberately ordered from
 * most precise to least — the reader learns the ladder of positional claims in
 * the order the register would prefer to be able to make them.
 */
export const LEGEND_ROWS: {
  representation: GeometryRepresentation;
  precision: LocatePrecision;
}[] = [
  { representation: "point", precision: "surveyed" },
  { representation: "point", precision: "approximate_1km" },
  { representation: "uncertainty_circle", precision: "approximate_10km" },
  { representation: "region_polygon", precision: "regional" },
  { representation: "admin_polygon", precision: "admin_area" },
  { representation: "none", precision: "place_name_only" },
  { representation: "none", precision: "non_located" },
];
