"use client";

/**
 * PLATE FURNITURE — plate number, scale bar, north tick, projection statement.
 *
 * DESIGN.md §9: "the map is PLATE I — INDEX MAP TO THE CATALOGUE. It carries a
 * plate number, a scale bar, a north tick, a projection statement, and a legend
 * that is a table. It is an index to the catalogue and it is styled to look
 * like one."
 *
 * Furniture is what separates a plate from a map widget. None of it is
 * decoration: the scale bar is the only way to read a drawn uncertainty radius
 * as a distance, the north tick is the only way to know the sheet is not
 * rotated, and the projection statement is the disclaimer that makes both
 * honest at continental scale.
 */

import { PROJECTION_STATEMENT, scaleBar } from "@/lib/plate/geometry";
import { PLATE_NUMBER, PLATE_TITLE } from "@/lib/plate/legend";

export function PlateHead({ zoom, centre }: { zoom: number; centre: [number, number] }) {
  return (
    <div className="plate-head">
      <div className="t-micro voice-mono plate-number">{PLATE_NUMBER}</div>
      <div className="t-micro plate-title">{PLATE_TITLE}</div>
      <div className="t-micro voice-mono plate-position">
        {formatLatLng(centre)} · z{zoom.toFixed(1)}
      </div>
    </div>
  );
}

/**
 * THE SCALE BAR. Computed at the CENTRE LATITUDE of the current view and
 * annotated with it, because Web Mercator's scale is a function of latitude and
 * a bar that does not say where it was measured is a bar that is wrong
 * everywhere else on the sheet.
 */
export function ScaleBar({ latitude, zoom }: { latitude: number; zoom: number }) {
  const bar = scaleBar(latitude, zoom);
  const w = Math.round(bar.pixels);
  return (
    <div className="plate-scale">
      <svg width={w + 2} height={14} viewBox={`0 0 ${w + 2} 14`} aria-hidden="true" shapeRendering="crispEdges">
        <path
          d={`M1 3V11M1 11H${w + 1}M${w + 1} 3V11M${1 + w / 2} 7V11`}
          stroke="var(--ink)"
          strokeWidth={1}
          fill="none"
        />
      </svg>
      <span className="t-micro voice-mono">
        {bar.label} at {Math.abs(bar.latitude).toFixed(1)}°{bar.latitude < 0 ? "S" : "N"}
      </span>
    </div>
  );
}

/**
 * THE NORTH TICK. A tick, not a compass rose: rotation is disabled on this
 * plate, so north is up, always, and the mark says so rather than implying a
 * control that does not exist.
 */
export function NorthTick() {
  return (
    <div className="plate-north">
      <svg width={14} height={22} viewBox="0 0 14 22" aria-hidden="true" shapeRendering="crispEdges">
        <path d="M7 21V5" stroke="var(--ink)" strokeWidth={1} fill="none" />
        <path d="M7 1L11 8H3Z" fill="var(--ink)" />
      </svg>
      <span className="t-micro voice-mono">N</span>
      <span className="t-micro plate-north-note">rotation disabled</span>
    </div>
  );
}

export function ProjectionStatement() {
  return (
    <p className="t-small plate-projection">
      <em>{PROJECTION_STATEMENT}</em>
    </p>
  );
}

function formatLatLng([lng, lat]: [number, number]): string {
  const ns = lat < 0 ? "S" : "N";
  const ew = lng < 0 ? "W" : "E";
  return `${Math.abs(lat).toFixed(3)}°${ns} ${Math.abs(lng).toFixed(3)}°${ew}`;
}
