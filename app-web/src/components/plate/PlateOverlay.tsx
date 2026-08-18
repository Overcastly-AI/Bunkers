"use client";

/**
 * THE OVERLAY — every evidentiary mark on the plate.
 *
 * The basemap is MapLibre's; the register's own marks are drawn HERE, in one
 * SVG in screen space, for four reasons that are all consequences of DESIGN.md
 * rather than preferences:
 *
 *  1. §8.2's 16px rule is a decision about ON-SCREEN EXTENT and has to be made
 *     per frame, per feature. No declarative paint expression can express it,
 *     and an approximation of it is exactly the "letting a small region shrink
 *     to a dot" failure §20 names.
 *  2. §8.2 requires a 4px-pitch SVG `<pattern>` "never `fill-opacity`". SVG
 *     patterns are what SVG has; a GL fill pattern is a raster tile that
 *     resamples, and a resampled dot screen at fractional device pixels is a
 *     wash again.
 *  3. §16 requires every feature to be focusable, in catalogue order, with a
 *     full-sentence accessible name and a visible 2px focus ring. SVG elements
 *     are real DOM nodes; GL features are not in the DOM at all.
 *  4. §17 requires print to be a first-class deliverable. Vector marks print;
 *     a WebGL canvas prints as a bitmap or as nothing.
 *
 * WHAT THIS COMPONENT MAY NOT DO, and does not: it never computes a position
 * from more than one row, never falls back to a centroid, never reads
 * `label_point`, never reads a cluster's `centroid`, and never draws a centre
 * mark for anything `centreOf()` declines to place.
 */

import { useEffect, useMemo } from "react";
import type { MapCluster, MapFeature } from "@/lib/types/api";
import type { CompetingGeometry } from "@/lib/repository/types";
import { centreOf, markFor, markForFeature } from "@/lib/plate/precision";
import { chartTags, type TagEvidence } from "@/lib/plate/chart-tags";
import {
  degrade,
  exceedsViewport,
  graticuleLines,
  groundRadiusToPixels,
  interiorSuppressed as suppressInterior,
  projectRings,
  ringsToPath,
  screenBox,
  type Project,
  type ScreenBox,
} from "@/lib/plate/geometry";
import { clusterId, clusterLabel, clusterMark, CLUSTER_MIN_PX } from "@/lib/plate/clusters";
import { PlateDefs } from "./PlateDefs";
import {
  Area,
  BelowThresholdSquare,
  ChartTagLabel,
  ClusterSquare,
  SurveyCross,
} from "./marks";

export interface PlateOverlayProps {
  width: number;
  height: number;
  zoom: number;
  bounds: { west: number; south: number; east: number; north: number };
  project: Project;
  features: MapFeature[];
  clusters: MapCluster[];
  /** Competing assertions for the SELECTED entity only. Drawn all at once. */
  competing: CompetingGeometry[];
  selectedSlug: string | null;
  onSelect: (slug: string | null) => void;
  /** Per-feature tag evidence, keyed by slug. Absent means "not queried". */
  tagEvidence?: Record<string, TagEvidence>;
  /** Whether the basemap archives loaded; the graticule draws either way. */
  graticule?: boolean;
  /**
   * §8.2 — "When a circle exceeds the viewport, a marginal note appears." The
   * overlay is the only place that knows, because knowing requires projecting;
   * it reports upward so the note prints in the panel as a marginal note rather
   * than as an overlay of its own on the surface.
   */
  onExceedsViewport?: (exceeds: boolean) => void;
}

export function PlateOverlay({
  width,
  height,
  zoom,
  bounds,
  project,
  features,
  clusters,
  competing,
  selectedSlug,
  onSelect,
  tagEvidence = {},
  graticule = true,
  onExceedsViewport,
}: PlateOverlayProps) {
  /* §21.10 — above the ceiling, regions lose their interior, never their
     boundary. "The degradation drops area emphasis, never location semantics." */
  const noInterior = suppressInterior(features.length);

  const overflowing = useMemo(
    () =>
      features.some((f) => {
        if (!f.geom || !markForFeature(f).locatable) return false;
        const box = screenBox(projectRings(f.geom, project));
        return box ? exceedsViewport(box, { width, height }) : false;
      }),
    [features, project, width, height],
  );

  useEffect(() => {
    onExceedsViewport?.(overflowing);
  }, [overflowing, onExceedsViewport]);

  const graticuleGeom = useMemo(() => {
    if (!graticule) return [];
    return graticuleLines(bounds, zoom).map((g) => {
      if (g.kind === "parallel") {
        const a = project([bounds.west, g.degrees]);
        const b = project([bounds.east, g.degrees]);
        return { ...g, x1: a.x, y1: a.y, x2: b.x, y2: b.y };
      }
      const a = project([g.degrees, bounds.south]);
      const b = project([g.degrees, bounds.north]);
      return { ...g, x1: a.x, y1: a.y, x2: b.x, y2: b.y };
    });
  }, [graticule, bounds, zoom, project]);

  return (
    <svg
      className="plate-overlay"
      width={width}
      height={height}
      viewBox={`0 0 ${width} ${height}`}
      shapeRendering="crispEdges"
      role="group"
      aria-label="Plate overlay: register features and uncertainty regions"
    >
      <PlateDefs />

      {/* ---- Plate furniture: the graticule and its edge ticks. ---------- *
          §9.2 — "Graticule hairlines with edge ticks at low zoom — plate
          furniture." Drawn from arithmetic, not from a tile, so the plate is
          furnished even when no archive is present. */}
      <g className="plate-graticule" aria-hidden="true">
        {graticuleGeom.map((g) => (
          <g key={`${g.kind}-${g.degrees}`}>
            <line
              x1={g.x1}
              y1={g.y1}
              x2={g.x2}
              y2={g.y2}
              stroke="var(--rule)"
              strokeWidth={1}
            />
            <text
              x={g.kind === "parallel" ? 4 : g.x1 + 3}
              y={g.kind === "parallel" ? g.y1 - 3 : 12}
              fontSize={9}
              fill="var(--ink-3)"
              style={{ fontFamily: "var(--font-mono)" }}
            >
              {g.label}
            </text>
          </g>
        ))}
      </g>

      {/* ---- Clusters. Server-side, on the grid cell, never on a centroid. */}
      <g className="plate-clusters">
        {clusters.map((c) => {
          const box = clusterBox(c, project);
          if (!box) return null;
          const mark = clusterMark(c);
          return (
            <g
              key={clusterId(c)}
              tabIndex={0}
              role="button"
              aria-label={clusterLabel(c)}
              className="plate-hit"
            >
              <ClusterSquare box={box} count={mark.count} border={mark.border} />
            </g>
          );
        })}
      </g>

      {/* ---- Features, in catalogue order (§9.5 — the tab order IS the
              catalogue order, so the plate is fully usable without a pointer). */}
      <g className="plate-features">
        {features.map((f) => (
          <Feature
            key={f.entity_id}
            feature={f}
            project={project}
            zoom={zoom}
            selected={f.slug === selectedSlug}
            onSelect={onSelect}
            evidence={tagEvidence[f.slug] ?? {}}
            noInterior={noInterior}
          />
        ))}
      </g>

      {/* ---- Competing geometry for the selection. §8.2: "preferred at full
              weight, competitors at 40% opacity with their origin_tier tag
              beside them, JOINED BY 1px --rule-strong HAIRLINES showing they
              refer to one entity. Coordinates are never averaged." ---------- */}
      {competing.length > 1 && (
        <CompetingSet competing={competing} project={project} zoom={zoom} />
      )}
    </svg>
  );
}

/* ====================================================================== *
 * One feature
 * ====================================================================== */

function Feature({
  feature: f,
  project,
  zoom,
  selected,
  onSelect,
  evidence,
  noInterior,
}: {
  feature: MapFeature;
  project: Project;
  zoom: number;
  selected: boolean;
  onSelect: (slug: string | null) => void;
  evidence: TagEvidence;
  noInterior: boolean;
}) {
  const mark = markForFeature(f);

  /* Unlocatable features draw NOTHING and live in the docked panel. This is
     not an omission — §9.6 — it is the honest rendering of a name that is not
     a place. */
  if (!mark.locatable || !f.geom) return null;

  const tags = chartTags(f, evidence);
  const label = featureLabel(f, tags);

  /* --- The two point forms. `centreOf()` is the ONLY coordinate emitter. --- */
  if (f.representation === "point") {
    const centre = centreOf(f);
    if (!centre) return null;
    const p = project(centre);

    /* The uncertainty ring, at TRUE GROUND RADIUS (§8.2). Drawn only for the
       approximate form; a `surveyed` point carries no ring and publishes its
       ±metres as text — see the note in lib/plate/precision.ts. */
    let ring: React.ReactNode = null;
    let ringBox: ScreenBox | null = null;
    if (mark.form === "cross-in-dotted-circle" && f.uncertainty_radius_m) {
      const r = groundRadiusToPixels(f.uncertainty_radius_m, centre[1], zoom);
      ringBox = { minX: p.x - r, minY: p.y - r, maxX: p.x + r, maxY: p.y + r };
      ring =
        r * 2 >= 16 ? (
          <Area d={circlePath(p.x, p.y, r)} mark={mark} interiorSuppressed={noInterior} />
        ) : (
          /* §8.2's low-zoom rule, applied to the RING rather than to the
             feature: the ring becomes the containing 16px dashed square and
             the earned cross stays where the source put it. The `▫` glyph is
             suppressed here alone, because the centre is legitimately occupied
             — it would collide with the cross, and a glyph reading "too small
             to draw" is redundant beside a mark that IS drawn. The square
             still contains the true ring, so it overstates uncertainty and
             never understates it. */
          <BelowThresholdSquare
            box={{ minX: p.x - 8, minY: p.y - 8, maxX: p.x + 8, maxY: p.y + 8 }}
            glyph={null}
          />
        );
    }

    const tagAnchor = ringBox
      ? { x: Math.max(ringBox.maxX, p.x + 8) + 4, y: ringBox.minY + 9 }
      : { x: p.x + 8, y: p.y - 6 };

    return (
      <g
        tabIndex={0}
        role="button"
        aria-label={label}
        aria-pressed={selected}
        className={selected ? "plate-hit plate-selected" : "plate-hit"}
        onClick={() => onSelect(f.slug)}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            e.preventDefault();
            onSelect(f.slug);
          }
        }}
      >
        {ring}
        <SurveyCross cx={p.x} cy={p.y} />
        <ChartTagLabel x={tagAnchor.x} y={tagAnchor.y} tags={tags} />
        {selected && ringBox && <SelectionBracket box={ringBox} />}
      </g>
    );
  }

  /* --- Areas: circles that were degraded, regions, admin polygons. -------- */
  const rings = projectRings(f.geom, project);
  const d = degrade(rings);
  if (d.mode === "off-plate") return null;

  const body =
    d.mode === "below-threshold" ? (
      <BelowThresholdSquare box={d.box} />
    ) : (
      <Area d={ringsToPath(rings)} mark={mark} interiorSuppressed={noInterior} />
    );

  return (
    <g
      tabIndex={0}
      role="button"
      aria-label={label}
      aria-pressed={selected}
      className={selected ? "plate-hit plate-selected" : "plate-hit"}
      onClick={() => onSelect(f.slug)}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          onSelect(f.slug);
        }
      }}
    >
      {/* The hit target is the boundary AND the interior screen — never a
          centre. §20: "Uncertain features are clicked by their boundary and
          their interior screen; the centre stays empty." */}
      <path d={ringsToPath(rings)} fill="none" pointerEvents="all" />
      {body}
      <ChartTagLabel x={d.box.maxX + 4} y={d.box.minY + 9} tags={tags} />
      {selected && <SelectionBracket box={d.box} />}
    </g>
  );
}

/**
 * Selection is shown by CORNER BRACKETS, not by a fill, a glow or a colour.
 * A fill would composite with the dot screen and make a selected region read as
 * denser evidence than an unselected one — the alpha-stacking failure of §8.2
 * arriving through the interaction layer instead of the paint layer.
 */
function SelectionBracket({ box }: { box: ScreenBox }) {
  const a = 7;
  const { minX: x0, minY: y0, maxX: x1, maxY: y1 } = box;
  const m = 3;
  return (
    <path
      d={
        `M${x0 - m} ${y0 - m + a}V${y0 - m}H${x0 - m + a}` +
        `M${x1 + m - a} ${y0 - m}H${x1 + m}V${y0 - m + a}` +
        `M${x1 + m} ${y1 + m - a}V${y1 + m}H${x1 + m - a}` +
        `M${x0 - m + a} ${y1 + m}H${x0 - m}V${y1 + m - a}`
      }
      fill="none"
      stroke="var(--ink)"
      strokeWidth={1.5}
    />
  );
}

/* ====================================================================== *
 * Competing geometry
 * ====================================================================== */

function CompetingSet({
  competing,
  project,
  zoom,
}: {
  competing: CompetingGeometry[];
  project: Project;
  zoom: number;
}) {
  const drawn = competing
    .map((c) => {
      if (!c.geom) return null;
      const mark = markFor(c.representation, c.precision);
      if (!mark.locatable) return null;
      const rings = projectRings(c.geom, project);
      const box = screenBox(rings);
      if (!box) return null;
      const anchor = {
        x: (box.minX + box.maxX) / 2,
        y: (box.minY + box.maxY) / 2,
      };
      return { c, mark, rings, box, anchor };
    })
    .filter((x): x is NonNullable<typeof x> => x !== null);

  if (drawn.length < 2) return null;
  void zoom;

  /* The joining hairlines. They are drawn between the drawn SHAPES so a reader
     sees that these are assertions about ONE entity. They are hairlines and not
     a shape: nothing is drawn at their intersection, and no point along them is
     offered as a position. */
  const preferred = drawn.find((x) => x.c.is_preferred) ?? drawn[0]!;

  return (
    <g className="plate-competing" aria-hidden="true">
      {drawn
        .filter((x) => x !== preferred)
        .map((x) => (
          <line
            key={`join-${x.c.geometry_assertion_id}`}
            x1={preferred.anchor.x}
            y1={preferred.anchor.y}
            x2={x.anchor.x}
            y2={x.anchor.y}
            stroke="var(--rule-strong)"
            strokeWidth={1}
          />
        ))}
      {drawn.map((x) => (
        <g key={x.c.geometry_assertion_id}>
          <Area
            d={ringsToPath(x.rings)}
            mark={x.mark}
            emphasis={x.c.is_preferred ? "full" : "competing"}
          />
          <text
            x={x.box.maxX + 4}
            y={x.box.minY + 9}
            fontSize={11}
            fill="var(--ink)"
            opacity={x.c.is_preferred ? 1 : 0.4}
            style={{ fontFamily: "var(--font-mono)", letterSpacing: ".06em" }}
          >
            {x.c.origin_tier}
            {x.c.asserted_by_siglum ? ` ${x.c.asserted_by_siglum}` : ""}
          </text>
        </g>
      ))}
    </g>
  );
}

/* ====================================================================== *
 * Helpers
 * ====================================================================== */

function circlePath(cx: number, cy: number, r: number): string {
  return `M${cx - r} ${cy}a${r} ${r} 0 1 0 ${r * 2} 0a${r} ${r} 0 1 0 ${-r * 2} 0Z`;
}

/** The grid CELL, projected. Never `centroid` — see lib/plate/clusters.ts. */
function clusterBox(c: MapCluster, project: Project): ScreenBox | null {
  if (!c.bbox) return null;
  const rings = projectRings(c.bbox, project);
  const box = screenBox(rings);
  if (!box) return null;
  const w = box.maxX - box.minX;
  const h = box.maxY - box.minY;
  const dx = Math.max(0, (CLUSTER_MIN_PX - w) / 2);
  const dy = Math.max(0, (CLUSTER_MIN_PX - h) / 2);
  return {
    minX: box.minX - dx,
    minY: box.minY - dy,
    maxX: box.maxX + dx,
    maxY: box.maxY + dy,
  };
}

/**
 * §16 — "a screen-reader user receives MORE than a sighted user gets from the
 * thumbnail." Every clause below is one returned column. The entity carries no
 * composite grade and this sentence does not invent one: it names the EXIST
 * proposition by name, because that is the row `api.map_feature` returns.
 */
function featureLabel(f: MapFeature, tags: string[]): string {
  const mark = markForFeature(f);
  const parts = [
    `${f.canonical_name}.`,
    `Position: ${mark.precisionWord}. ${mark.reading}`,
    `EXIST proposition: grade ${f.exist_grade}${f.at_ceiling ? ", at ceiling" : ""}.`,
    f.locate_grade ? `LOCATE proposition: grade ${f.locate_grade}.` : "LOCATE proposition: not graded.",
    `${f.proposition_count} published proposition${f.proposition_count === 1 ? "" : "s"} on this entity; this plate shows one of them.`,
  ];
  if (f.suppression_reason) parts.push(`Rendering note: ${f.suppression_reason}.`);
  if (tags.length > 0) parts.push(`Chart abbreviations: ${tags.join(", ")}.`);
  return parts.join(" ");
}
