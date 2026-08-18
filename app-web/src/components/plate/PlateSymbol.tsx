/**
 * LEGEND SYMBOLS — drawn at true size, by the same components as the plate.
 *
 * DESIGN.md §9.6. What "true size" means here, exactly: every stroke weight,
 * dash pattern, dot-screen pitch, cross arm and glyph is the SAME NUMBER as on
 * the surface. The one quantity that cannot be true is a circle's radius, which
 * on the plate is ground distance and therefore a function of zoom; the legend
 * draws it at 8px — just above the 16px degradation threshold — and the
 * MEANING column says the radius is ground distance rather than symbol size.
 */

import { markFor, type MarkSpec } from "@/lib/plate/precision";
import type { GeometryRepresentation, LocatePrecision } from "@/lib/types/enums";
import { PlateDefs } from "./PlateDefs";
import { Area, SurveyCross, BelowThresholdSquare, ClusterSquare } from "./marks";

const W = 44;
const H = 24;
const CX = 16;
const CY = 12;

function circlePath(cx: number, cy: number, r: number): string {
  return `M${cx - r} ${cy}a${r} ${r} 0 1 0 ${r * 2} 0a${r} ${r} 0 1 0 ${-r * 2} 0Z`;
}

/** A deliberately irregular quadrilateral: a region is not a shape we chose. */
function regionPath(): string {
  return "M5 5L27 3L29 20L8 21Z";
}

export function PlateSymbol({
  representation,
  precision,
  idPrefix,
}: {
  representation: GeometryRepresentation;
  precision: LocatePrecision;
  idPrefix: string;
}) {
  const mark: MarkSpec = markFor(representation, precision);
  return (
    <svg
      width={W}
      height={H}
      viewBox={`0 0 ${W} ${H}`}
      role="img"
      aria-label={`${mark.precisionWord}: ${mark.reading}`}
      shapeRendering="crispEdges"
      style={{ display: "block", overflow: "visible" }}
    >
      <PlateDefs idPrefix={idPrefix} />
      <SymbolBody mark={mark} idPrefix={idPrefix} />
    </svg>
  );
}

function SymbolBody({ mark, idPrefix }: { mark: MarkSpec; idPrefix: string }) {
  switch (mark.form) {
    case "survey-cross":
      return <SurveyCross cx={CX} cy={CY} />;

    case "cross-in-dotted-circle":
      return (
        <g>
          <Area d={circlePath(CX, CY, 8)} mark={mark} idPrefix={idPrefix} />
          <SurveyCross cx={CX} cy={CY} />
        </g>
      );

    case "dotted-circle":
      /* No centre. The middle of this symbol is empty and that emptiness is
         the whole content of the mark. */
      return <Area d={circlePath(CX, CY, 8)} mark={mark} idPrefix={idPrefix} />;

    case "dotted-polygon":
    case "surveyed-footprint":
      return <Area d={regionPath()} mark={mark} idPrefix={idPrefix} />;

    case "none":
      /* Nothing is drawn, and the legend shows that nothing rather than
         substituting a placeholder mark. An em rule is punctuation, not a
         symbol: it occupies the cell without asserting a position. */
      return (
        <text
          x={CX}
          y={CY}
          textAnchor="middle"
          dominantBaseline="central"
          fontSize={11}
          fill="var(--ink-3)"
          style={{ fontFamily: "var(--font-mono)" }}
        >
          —
        </text>
      );
  }
}

/* ====================================================================== *
 * The two symbols that are not a precision — drawn in the legend beneath
 * the precision table because a reader meets them on the plate.
 * ====================================================================== */

export function BelowThresholdSymbol({ idPrefix }: { idPrefix: string }) {
  return (
    <svg
      width={W}
      height={H}
      viewBox={`0 0 ${W} ${H}`}
      role="img"
      aria-label="An area too small to draw at this zoom. Not a location."
      shapeRendering="crispEdges"
      style={{ display: "block", overflow: "visible" }}
    >
      <PlateDefs idPrefix={idPrefix} />
      <BelowThresholdSquare box={{ minX: 8, minY: 4, maxX: 24, maxY: 20 }} />
    </svg>
  );
}

export function ClusterSymbol({ idPrefix }: { idPrefix: string }) {
  return (
    <svg
      width={W}
      height={H}
      viewBox={`0 0 ${W} ${H}`}
      role="img"
      aria-label="A cluster: a count of features in one grid cell. Not a position."
      shapeRendering="crispEdges"
      style={{ display: "block", overflow: "visible" }}
    >
      <PlateDefs idPrefix={idPrefix} />
      <ClusterSquare box={{ minX: 5, minY: 1, maxX: 27, maxY: 23 }} count={14} border="dotted" />
    </svg>
  );
}

/**
 * §8.2 — competing geometry, drawn all at once. The legend has to teach this
 * because the shape only appears on selection: "'Four sources put this in four
 * different places' becomes a SHAPE. Coordinates are never averaged."
 */
export function CompetingSymbol({ idPrefix }: { idPrefix: string }) {
  const mark = markFor("uncertainty_circle", "claimed_only");
  return (
    <svg
      width={W}
      height={H}
      viewBox={`0 0 ${W} ${H}`}
      role="img"
      aria-label="Competing geometry assertions, drawn simultaneously and joined by a hairline. No coordinate is averaged."
      shapeRendering="crispEdges"
      style={{ display: "block", overflow: "visible" }}
    >
      <PlateDefs idPrefix={idPrefix} />
      <line x1={10} y1={12} x2={32} y2={12} stroke="var(--rule-strong)" strokeWidth={1} />
      <Area d={circlePath(10, 12, 6)} mark={mark} idPrefix={idPrefix} />
      <g opacity={0.4}>
        <Area d={circlePath(32, 12, 5)} mark={mark} idPrefix={idPrefix} />
      </g>
    </svg>
  );
}
