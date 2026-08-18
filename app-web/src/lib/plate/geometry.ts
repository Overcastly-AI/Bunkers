/**
 * PLATE GEOMETRY — projection arithmetic, and the one rule that keeps the map
 * from lying at low zoom.
 *
 * Everything in this file is a pure function of a projected screen position and
 * a returned row. Nothing here averages coordinates, invents a position, or
 * reads `label_point`. The only screen-space quantity this module derives is
 * the bounding box of a shape that is ALREADY BEING DRAWN, and §"THE 16px RULE"
 * below states exactly what that is allowed to become and why.
 */

import type { GeoJsonGeometry } from "../types/api";

/** A screen-space point, in CSS pixels relative to the plate surface. */
export interface ScreenPoint {
  x: number;
  y: number;
}

/** The projection the overlay is handed. In practice `map.project`. */
export type Project = (lngLat: [number, number]) => ScreenPoint;

export interface ScreenBox {
  minX: number;
  minY: number;
  maxX: number;
  maxY: number;
}

export const boxWidth = (b: ScreenBox) => b.maxX - b.minX;
export const boxHeight = (b: ScreenBox) => b.maxY - b.minY;

/* ====================================================================== *
 * Web Mercator arithmetic
 * ====================================================================== */

/** Circumference of the WGS 84 sphere at the equator, in metres. */
export const EARTH_CIRCUMFERENCE_M = 40075016.686;

/**
 * Ground metres per CSS pixel at a latitude and zoom. Web Mercator exaggerates
 * with latitude, which is exactly why the scale bar below is annotated with the
 * latitude it was computed at and why the projection statement is printed on
 * the plate rather than assumed.
 */
export function metresPerPixel(latitude: number, zoom: number, tileSize = 512): number {
  return (
    (EARTH_CIRCUMFERENCE_M * Math.cos((latitude * Math.PI) / 180)) /
    (tileSize * Math.pow(2, zoom))
  );
}

/**
 * "Uncertainty circles are drawn at TRUE GROUND DISTANCE, so zooming in makes
 * them grow — correctly." (§8.2)
 */
export function groundRadiusToPixels(
  radiusM: number,
  latitude: number,
  zoom: number,
  tileSize = 512,
): number {
  return radiusM / metresPerPixel(latitude, zoom, tileSize);
}

/* ====================================================================== *
 * Projecting a returned geometry
 * ====================================================================== */

/** Every ring of a returned geometry, projected. Points return a single ring of one. */
export function projectRings(geom: GeoJsonGeometry, project: Project): ScreenPoint[][] {
  switch (geom.type) {
    case "Point":
      return [[project(geom.coordinates)]];
    case "Polygon":
      return geom.coordinates.map((ring) => ring.map(project));
    case "MultiPolygon":
      return geom.coordinates.flatMap((poly) => poly.map((ring) => ring.map(project)));
  }
}

export function screenBox(rings: ScreenPoint[][]): ScreenBox | null {
  let minX = Infinity;
  let minY = Infinity;
  let maxX = -Infinity;
  let maxY = -Infinity;
  for (const ring of rings) {
    for (const p of ring) {
      if (!Number.isFinite(p.x) || !Number.isFinite(p.y)) continue;
      if (p.x < minX) minX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.x > maxX) maxX = p.x;
      if (p.y > maxY) maxY = p.y;
    }
  }
  if (!Number.isFinite(minX)) return null;
  return { minX, minY, maxX, maxY };
}

export function ringsToPath(rings: ScreenPoint[][]): string {
  return rings
    .map((ring) =>
      ring.length === 0
        ? ""
        : `M${ring.map((p) => `${round(p.x)} ${round(p.y)}`).join("L")}Z`,
    )
    .join("");
}

const round = (n: number) => Math.round(n * 10) / 10;

/* ====================================================================== *
 * THE 16px RULE — where the map would most easily start lying
 * ====================================================================== */

/**
 * DESIGN.md §1 (grafted from APPARATUS) and §8.2:
 *
 * > "When a circle or polygon's on-screen extent falls below 16px, it does NOT
 * > shrink toward a point. It renders as a fixed 16×16px dashed square
 * > containing a centred `▫` glyph, which reads unmistakably as 'an area too
 * > small to draw at this zoom' and never as a location."
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * WHAT THE SQUARE IS, PRECISELY, SO THAT IT IS NOT A MANUFACTURED COORDINATE.
 *
 * The square is the feature's OWN PROJECTED BOUNDING BOX, floored to 16px in
 * each dimension by growing it equally on both sides. It is not a point, and it
 * is not `label_point`, and it is not a centroid: it is a box that CONTAINS the
 * whole true extent, at a zoom where the true extent is unresolvable.
 *
 * Three properties make it honest, and the implementation asserts the first:
 *
 *   1. CONTAINMENT. The drawn square is always a superset of the true extent.
 *      It therefore claims LESS precision than the geometry, never more. A
 *      point-like mark would claim more, which is the failure this rule exists
 *      to prevent.
 *   2. NO CENTRE. The square carries a dashed boundary and the `▫` glyph and
 *      nothing at its middle. §20: "the dot in the middle is the lie."
 *   3. IT IS NEVER EXPORTED. The anchor exists for the duration of one frame at
 *      one zoom. It is not written to the URL, not offered as a coordinate
 *      readout, not used as a cluster anchor, and not persisted. There is no
 *      function in this module that converts it back to a lng/lat.
 * ─────────────────────────────────────────────────────────────────────────────
 */
export const MIN_EXTENT_PX = 16;

export type Degradation =
  | { mode: "true-extent"; box: ScreenBox }
  /** Too small to draw at this zoom. Drawn as a containing square, never a point. */
  | { mode: "below-threshold"; box: ScreenBox; glyph: "▫" }
  /** Nothing projected into view. */
  | { mode: "off-plate" };

export function degrade(rings: ScreenPoint[][]): Degradation {
  const box = screenBox(rings);
  if (!box) return { mode: "off-plate" };

  const w = boxWidth(box);
  const h = boxHeight(box);
  if (w >= MIN_EXTENT_PX && h >= MIN_EXTENT_PX) return { mode: "true-extent", box };

  const grown = growTo(box, MIN_EXTENT_PX);

  /* Property 1, asserted rather than assumed. */
  if (
    grown.minX > box.minX ||
    grown.minY > box.minY ||
    grown.maxX < box.maxX ||
    grown.maxY < box.maxY
  ) {
    throw new Error(
      "plate/geometry: the 16px substitute square does not contain the true extent",
    );
  }

  return { mode: "below-threshold", box: grown, glyph: "▫" };
}

function growTo(b: ScreenBox, min: number): ScreenBox {
  const dx = Math.max(0, (min - boxWidth(b)) / 2);
  const dy = Math.max(0, (min - boxHeight(b)) / 2);
  return {
    minX: b.minX - dx,
    minY: b.minY - dy,
    maxX: b.maxX + dx,
    maxY: b.maxY + dy,
  };
}

/**
 * "When a circle exceeds the viewport, a marginal note appears: 'Uncertainty
 * exceeds the current view. Zoom out to see the extent of the claim.'" (§8.2)
 */
export function exceedsViewport(box: ScreenBox, viewport: { width: number; height: number }) {
  return box.minX < 0 && box.minY < 0 && box.maxX > viewport.width && box.maxY > viewport.height;
}

export const EXCEEDS_VIEWPORT_NOTE =
  "Uncertainty exceeds the current view. Zoom out to see the extent of the claim.";

/**
 * §21.10 — "Above ~2,000 visible features, regions degrade to boundary-only,
 * still dotted. The degradation drops area emphasis, never location semantics."
 * Published as a constant so the plate can print the threshold it applied.
 */
export const DOT_SCREEN_FEATURE_CEILING = 2000;

export function interiorSuppressed(visibleFeatureCount: number): boolean {
  return visibleFeatureCount > DOT_SCREEN_FEATURE_CEILING;
}

/* ====================================================================== *
 * Plate furniture — scale bar, graticule
 * ====================================================================== */

/** 1-2-5 progression. A scale bar reads a round number or it reads nothing. */
const NICE_METRES = [
  1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000,
  200000, 500000, 1000000, 2000000,
];

export interface ScaleBar {
  metres: number;
  pixels: number;
  label: string;
  /** The latitude the bar was computed at. Web Mercator scale is latitude-dependent. */
  latitude: number;
}

export function scaleBar(latitude: number, zoom: number, maxPixels = 160): ScaleBar {
  const mpp = metresPerPixel(latitude, zoom);
  let chosen = NICE_METRES[0]!;
  for (const m of NICE_METRES) {
    if (m / mpp <= maxPixels) chosen = m;
    else break;
  }
  return {
    metres: chosen,
    pixels: chosen / mpp,
    label: chosen >= 1000 ? `${chosen / 1000} km` : `${chosen} m`,
    latitude,
  };
}

export const PROJECTION_STATEMENT =
  "Web Mercator (EPSG:3857). Areas at high latitude are exaggerated; " +
  "uncertainty radii are drawn as true ground distance.";

/** Graticule interval in degrees, by zoom. Plate furniture, not data. */
export function graticuleInterval(zoom: number): number {
  if (zoom < 3) return 20;
  if (zoom < 5) return 10;
  if (zoom < 7) return 5;
  if (zoom < 9) return 2;
  if (zoom < 11) return 1;
  if (zoom < 13) return 0.5;
  return 0.25;
}

export interface GraticuleLine {
  kind: "parallel" | "meridian";
  degrees: number;
  label: string;
}

export function graticuleLines(
  bounds: { west: number; south: number; east: number; north: number },
  zoom: number,
): GraticuleLine[] {
  const step = graticuleInterval(zoom);
  const out: GraticuleLine[] = [];
  const start = (v: number) => Math.ceil(v / step) * step;

  for (let lat = start(bounds.south); lat <= bounds.north; lat += step) {
    out.push({ kind: "parallel", degrees: lat, label: formatDegrees(lat, "NS") });
  }
  for (let lng = start(bounds.west); lng <= bounds.east; lng += step) {
    out.push({ kind: "meridian", degrees: lng, label: formatDegrees(lng, "EW") });
  }
  return out;
}

function formatDegrees(v: number, axis: "NS" | "EW"): string {
  const hemi = axis === "NS" ? (v < 0 ? "S" : "N") : v < 0 ? "W" : "E";
  const a = Math.abs(v);
  const whole = Math.floor(a);
  const minutes = Math.round((a - whole) * 60);
  return minutes === 0 ? `${whole}°${hemi}` : `${whole}°${minutes}′${hemi}`;
}
