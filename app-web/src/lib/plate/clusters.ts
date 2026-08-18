/**
 * CLUSTERING — a bin is not a position.
 *
 * DESIGN.md §9.3:
 *
 * > "Clustering uses `api.map_cluster` on `label_point_3857` (so region
 * > features participate at all), with THE GRID CELL `(cell_x, cell_y)` AS THE
 * > CLUSTER ID — stable across `REFRESH MATERIALIZED VIEW CONCURRENTLY`,
 * > therefore linkable and cacheable. The mark is a HAIRLINE SQUARE WITH A MONO
 * > COUNT INSIDE, never a coloured bubble and NEVER SIZED BY MAGNITUDE."
 *
 * Clustering is done SERVER-SIDE, in SQL, in the materialised view. The client
 * never groups features: "clustering must never average or invent a position",
 * and the surest way to keep that true is for the client to have no clustering
 * code at all. This module contains no grouping function — only the rules for
 * drawing a cluster row the server already computed.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * WHERE A CLUSTER MARK IS DRAWN, AND WHY IT IS NOT `centroid`.
 *
 * `api.map_cluster` returns a `centroid` column. THE PLATE NEVER PAINTS IT.
 *
 * That column is `st_centroid(st_collect(cell))` — an average of snapped grid
 * cells, and therefore a point no source asserts. Refusal 4 is unambiguous:
 * "the register never emits a point no source asserts." Painting a count on a
 * centroid would place a mark at a coordinate that exists only because of an
 * aggregation, and once painted it will be screenshotted.
 *
 * The mark is drawn on the CELL instead — the `bbox` column, which is the
 * envelope of the grid cells the row aggregates. A grid cell is a bin: it is a
 * deterministic quantisation of space that asserts only "at least one feature
 * fell in this box." That is precisely the claim a cluster is entitled to make.
 * The square is floored to a legible minimum so the count fits, exactly as a
 * region is floored to 16px, and for the same reason — a bin too small to draw
 * must not collapse toward a point.
 *
 * `centroid` is present on the `MapCluster` type because that type transcribes
 * the view column for column. `plate:check` scans the plate source and fails if
 * any renderer reads it. It receives the same treatment as
 * `label_point_3857`, which is not on the read surface at all.
 * ─────────────────────────────────────────────────────────────────────────────
 */

import type { MapCluster } from "../types/api";

/** Below this zoom the viewport RPC returns clusters; above it, features. */
export const CLUSTER_MAX_ZOOM = 9;

/** A cluster square is never smaller than this, and never larger for being fuller. */
export const CLUSTER_MIN_PX = 22;

export interface ClusterMark {
  /** §9.3 — hairline square. Not a bubble, not a disc, not a pill. */
  form: "hairline-square";
  /**
   * §9.3 channel 6 — "below z9, a cluster containing any non-`exact` feature
   * carries a DOTTED square border. Twelve surveyed points and twelve 50 km
   * regions must never resolve into the same cluster mark."
   */
  border: "solid" | "dotted";
  /** The Mono count printed inside. One returned column, `feature_count`. */
  count: number;
  /** The reason the border is what it is, printed on focus. Never a hidden rule. */
  borderReason: string;
}

/**
 * ─────────────────────────────────────────────────────────────────────────────
 * A SCHEMA GAP, RECORDED RATHER THAN PAPERED OVER.
 *
 * §9.3 channel 6 requires the cluster border to inherit from the precision of
 * its members, and §9.3 requires focus to break the cluster down as
 * `14 features — 3 surveyed · 4 approximate · 7 regions`.
 *
 * `api.map_cluster` (supabase/schema.sql §15) aggregates
 * `count(*) · max(exist_rank) · mode(typology) · min(country_code) · centroid ·
 * bbox · sample_entity_ids` — AND NOTHING ABOUT PRECISION. The breakdown is not
 * a column, so the breakdown is not drawn: rendering it would require the
 * client to fetch and group the member features, which is client-side
 * clustering by another name, and inventing it from `sample_entity_ids` would
 * report a sample of 25 as if it were the whole.
 *
 * The border therefore defaults to DOTTED, and this is the conservative
 * direction rather than a shrug. A solid border asserts "every feature in this
 * bin is a surveyed point" — a positive claim about precision that the returned
 * row does not contain. A dotted border asserts "this bin may contain
 * uncertainty", which is true of any bin whose composition is unknown. The
 * failure mode of the default is understating precision, never overstating it.
 *
 * THE FIX IS THREE COLUMNS IN THE VIEW, and it is written out in
 * `CLUSTER_PRECISION_DDL` below so the next person does not have to derive it.
 * ─────────────────────────────────────────────────────────────────────────────
 */
export function clusterMark(c: MapCluster): ClusterMark {
  return {
    form: "hairline-square",
    border: "dotted",
    count: c.feature_count,
    borderReason:
      "api.map_cluster carries no precision breakdown, so this bin's composition " +
      "is unknown. A dotted border understates precision; a solid one would assert it.",
  };
}

/** Published on the plate's legend so the gap is readable, not merely commented. */
export const CLUSTER_BREAKDOWN_UNAVAILABLE =
  "Cluster composition (surveyed · approximate · regions) is not a column of " +
  "api.map_cluster. It is not shown rather than sampled.";

export const CLUSTER_PRECISION_DDL = `-- Add to api.map_cluster to satisfy DESIGN.md §9.3 channel 6 and the
-- focus breakdown. Three counts, each a filter() over the same rows the
-- cluster already aggregates — no new join, no new scan.
count(*) filter (where representation = 'point'
                   and locate_precision = 'surveyed')::integer as surveyed_count,
count(*) filter (where locate_precision in ('approximate_1km','approximate_10km')
                   or representation = 'uncertainty_circle')::integer as approximate_count,
count(*) filter (where representation in ('region_polygon','admin_polygon'))::integer as region_count`;

/**
 * The accessible name for a cluster mark. §16: a screen-reader user receives
 * MORE than a sighted user gets from the thumbnail, so the unavailable
 * breakdown is stated here too rather than silently omitted.
 */
export function clusterLabel(c: MapCluster): string {
  const grade = c.best_exist_grade
    ? `Best EXIST grade in this bin: ${c.best_exist_grade}.`
    : "No EXIST grade returned for this bin.";
  return (
    `Cluster of ${c.feature_count} feature${c.feature_count === 1 ? "" : "s"}, ` +
    `grid cell ${c.cell_x}, ${c.cell_y} at zoom ${c.zoom}. ${grade} ` +
    `${CLUSTER_BREAKDOWN_UNAVAILABLE} ` +
    `The mark is drawn on the grid cell, not on a computed centre.`
  );
}

/** A stable, linkable cluster identity — the grid cell, exactly as §9.3 specifies. */
export function clusterId(c: MapCluster): string {
  return `z${c.zoom}-${c.cell_x}-${c.cell_y}`;
}
