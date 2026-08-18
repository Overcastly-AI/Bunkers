/**
 * FIG. n — THE LOCATOR FIGURE, for the margin column of an entry sheet.
 *
 * DESIGN.md §9: "From an entry page it appears as a 13rem MARGIN FIGURE
 * captioned `FIG. 1 — Locator, Adams County PA. Uncertainty: surveyed ±30 m.`"
 *
 * It is a FIGURE, not a small map: no tiles, no GL context, no pan, no zoom, no
 * network request. It draws the same mark the plate draws, at a scale fitted to
 * the feature, with a scale bar and a north tick, and it prints — §17, "the
 * plate renders as a static figure with its legend", and §21.7, which accepts
 * that tablets lose this figure rather than pretending they keep it.
 *
 * It is a server component: nothing here needs the browser. That matters,
 * because §16 requires the entry sheet to be fully readable with JavaScript
 * disabled, and a locator that needed script would put the one exempted element
 * — the map canvas — into the middle of a text page.
 *
 * THE PROJECTION IS LOCAL AND STATED. At the size of a margin figure the
 * difference between Web Mercator and a local equirectangular fit is far below
 * a pixel, so the figure fits a plate-carrée window around the feature's own
 * extent and prints its scale bar at the feature's own latitude. Nothing about
 * this figure is a claim the plate does not also make.
 */

import type { MapFeature } from "@/lib/types/api";
import { markForFeature, centreOf } from "@/lib/plate/precision";
import { chartTags } from "@/lib/plate/chart-tags";
import { metresPerPixel, scaleBar } from "@/lib/plate/geometry";
import type { ScreenPoint } from "@/lib/plate/geometry";
import { PlateDefs } from "./PlateDefs";
import { Area, ChartTagLabel, SurveyCross } from "./marks";
import "./locator.css";

const W = 208; /* 13rem at 16px */
const H = 150;
const PAD = 16;

export interface LocatorFigureProps {
  feature: MapFeature;
  /** Figure number within the sheet. Sequential and citable, like a plate number. */
  figure?: number;
  /** e.g. "Adams County PA" — from `core.entity`'s jurisdiction, not derived here. */
  jurisdiction?: string;
}

export function LocatorFigure({ feature, figure = 1, jurisdiction }: LocatorFigureProps) {
  const mark = markForFeature(feature);

  /* An unlocatable entity gets a figure that says so, not a blank box and not
     an omission. §9.6's NOT LOCATABLE panel, at the scale of one sheet. */
  if (!mark.locatable || !feature.geom) {
    return (
      <figure className="locator-figure">
        <figcaption className="t-micro voice-mono">
          FIG. {figure} — Not locatable.{" "}
          {mark.precisionWord}. {mark.reading}
        </figcaption>
      </figure>
    );
  }

  const window_ = fitWindow(feature);
  const project = (lngLat: [number, number]): ScreenPoint => ({
    x: PAD + ((lngLat[0] - window_.west) / (window_.east - window_.west)) * (W - PAD * 2),
    y: PAD + ((window_.north - lngLat[1]) / (window_.north - window_.south)) * (H - PAD * 2),
  });

  /* The figure's own zoom, derived from the fitted window, so the scale bar is
     read from the same arithmetic the plate uses. */
  const lat = (window_.north + window_.south) / 2;
  const zoom = zoomForSpan(window_.east - window_.west, lat, W - PAD * 2);
  const bar = scaleBar(lat, zoom, 72);

  const centre = centreOf(feature);
  const tags = chartTags(feature);
  const id = `fig${figure}-`;

  return (
    <figure className="locator-figure">
      <svg
        width={W}
        height={H}
        viewBox={`0 0 ${W} ${H}`}
        role="img"
        aria-label={`Locator figure. ${feature.canonical_name}. ${mark.reading}`}
        shapeRendering="crispEdges"
      >
        <PlateDefs idPrefix={id} />
        <rect x={0.5} y={0.5} width={W - 1} height={H - 1} fill="var(--field)" stroke="var(--rule-strong)" />

        {feature.geom.type !== "Point" && (
          <Area d={pathFor(feature, project)} mark={mark} idPrefix={id} />
        )}
        {centre && <SurveyCross cx={project(centre).x} cy={project(centre).y} />}
        <ChartTagLabel x={PAD} y={H - PAD - 14} tags={tags} />

        {/* Scale bar and north tick — the same furniture as the plate, at
            figure scale, because a figure without a scale is an illustration. */}
        <g>
          <path
            d={`M${PAD} ${H - 10}v-4M${PAD} ${H - 12}h${Math.round(bar.pixels)}M${PAD + Math.round(bar.pixels)} ${H - 10}v-4`}
            stroke="var(--ink)"
            strokeWidth={1}
            fill="none"
          />
          <text
            x={PAD + Math.round(bar.pixels) + 4}
            y={H - 9}
            fontSize={9}
            fill="var(--ink-3)"
            style={{ fontFamily: "var(--font-mono)" }}
          >
            {bar.label}
          </text>
          <path d={`M${W - PAD} ${H - 8}V${H - 22}`} stroke="var(--ink)" strokeWidth={1} />
          <path d={`M${W - PAD - 3} ${H - 19}L${W - PAD} ${H - 25}L${W - PAD + 3} ${H - 19}Z`} fill="var(--ink)" />
        </g>
      </svg>

      {/*
        The caption is the specification's, filled from returned columns. The
        uncertainty clause reads the precision word and the radius — a surveyed
        point's ±metres are PUBLISHED HERE AS A NUMBER rather than drawn as a
        ring, because at any figure scale that ring is below the 16px threshold
        and a substitute square would overstate what the survey established.
      */}
      <figcaption className="t-micro voice-mono locator-caption">
        FIG. {figure} — Locator{jurisdiction ? `, ${jurisdiction}` : ""}. Uncertainty:{" "}
        {mark.precisionWord}
        {feature.uncertainty_radius_m ? ` ±${formatMetres(feature.uncertainty_radius_m)}` : ""}.
      </figcaption>
    </figure>
  );
}

/* ====================================================================== *
 * Fitting — the window is the feature's own extent, padded. Nothing else
 * decides where this figure looks.
 * ====================================================================== */

function fitWindow(f: MapFeature) {
  const coords = allCoords(f);
  let west = Infinity;
  let south = Infinity;
  let east = -Infinity;
  let north = -Infinity;
  for (const [lng, lat] of coords) {
    west = Math.min(west, lng);
    east = Math.max(east, lng);
    south = Math.min(south, lat);
    north = Math.max(north, lat);
  }
  /* A point has no extent; give the figure a fixed 4 km window around it so
     the scale bar has something to measure. The window is arbitrary and the
     scale bar is what makes it readable — which is why the scale bar is not
     optional on this figure. */
  const spanLng = Math.max(east - west, 0.04);
  const spanLat = Math.max(north - south, 0.03);
  const cx = (east + west) / 2;
  const cy = (north + south) / 2;
  const pad = 1.25;
  return {
    west: cx - (spanLng / 2) * pad,
    east: cx + (spanLng / 2) * pad,
    south: cy - (spanLat / 2) * pad,
    north: cy + (spanLat / 2) * pad,
  };
}

function allCoords(f: MapFeature): [number, number][] {
  const g = f.geom;
  if (!g) return [];
  if (g.type === "Point") return [g.coordinates];
  if (g.type === "Polygon") return g.coordinates.flat();
  return g.coordinates.flat(2) as [number, number][];
}

function pathFor(f: MapFeature, project: (c: [number, number]) => ScreenPoint): string {
  const g = f.geom;
  if (!g || g.type === "Point") return "";
  const rings = g.type === "Polygon" ? g.coordinates : g.coordinates.flat();
  return rings
    .map((ring) => `M${ring.map((c) => { const p = project(c); return `${p.x.toFixed(1)} ${p.y.toFixed(1)}`; }).join("L")}Z`)
    .join("");
}

/** The zoom at which `spanDeg` fills `widthPx`, so the scale bar is honest. */
function zoomForSpan(spanDeg: number, latitude: number, widthPx: number): number {
  const metres = spanDeg * 111320 * Math.cos((latitude * Math.PI) / 180);
  const target = metres / widthPx;
  let z = 4;
  while (z < 20 && metresPerPixel(latitude, z) > target) z += 0.25;
  return z;
}

function formatMetres(m: number): string {
  return m >= 1000 ? `${(m / 1000).toFixed(m % 1000 === 0 ? 0 : 1)} km` : `${Math.round(m)} m`;
}
