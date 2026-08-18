/**
 * THE MARKS — the primitives, shared by the plate and by its legend.
 *
 * DESIGN.md §9.6: legend symbols are "drawn as inline SVG AT TRUE SIZE, not as
 * scaled-up illustrations, SO THEY MATCH THE MARKS EXACTLY." The only way to
 * guarantee that is for both to call the same component, which is what this
 * file exists for. A legend that is a separate drawing of the same idea will
 * drift, and a drifted legend is a key to a map that no longer exists.
 *
 * Nothing in this file takes a colour parameter. Every stroke is `--ink`,
 * `--rule-strong` or `--ink-3`, chosen by the mark's meaning and not by its
 * grade: §7 and §16, "grade is never conveyed by colour", and §9.3, precision
 * is carried by mark FORM.
 */

import type { MarkSpec } from "@/lib/plate/precision";
import type { ScreenBox } from "@/lib/plate/geometry";
import { dotScreenFill, hatchFill } from "./PlateDefs";

/** §8.2 — "Dotted boundaries, not solid… 1px dots at 3px pitch." */
export const DOTTED = { strokeDasharray: "1 2", strokeLinecap: "butt" as const };

/* ====================================================================== *
 * The survey cross — the only mark with a centre
 * ====================================================================== */

/**
 * "Survey cross — 9px fine cross, 1.5px centre dot, no fill, NO PIN." (§8.2)
 *
 * The centre dot exists because `exact` earned one. Every other mark on this
 * plate is empty at the middle, and §20 names the alternative for what it is:
 * "A faint centre dot on an uncertainty circle 'so users have something to
 * click.' … The dot in the middle is the lie."
 */
export function SurveyCross({ cx, cy }: { cx: number; cy: number }) {
  return (
    <g>
      <path
        d={`M${cx - 4.5} ${cy}H${cx + 4.5}M${cx} ${cy - 4.5}V${cy + 4.5}`}
        stroke="var(--ink)"
        strokeWidth={1}
        fill="none"
      />
      <circle cx={cx} cy={cy} r={0.75} fill="var(--ink)" />
    </g>
  );
}

/* ====================================================================== *
 * Areas — interior and boundary, drawn from the MarkSpec
 * ====================================================================== */

interface AreaProps {
  /** An SVG path in screen space, or a circle description. */
  d: string;
  mark: MarkSpec;
  idPrefix?: string;
  /** §21.10 — above the feature ceiling, regions degrade to boundary-only. */
  interiorSuppressed?: boolean;
  emphasis?: "full" | "competing";
}

export function Area({
  d,
  mark,
  idPrefix = "",
  interiorSuppressed = false,
  emphasis = "full",
}: AreaProps) {
  const fill =
    interiorSuppressed || mark.interior === "none"
      ? "none"
      : mark.interior === "dot-screen"
        ? dotScreenFill(idPrefix)
        : hatchFill(idPrefix);

  const dotted = mark.boundary === "dotted";

  return (
    <g opacity={emphasis === "competing" ? 0.4 : 1}>
      {fill !== "none" && <path d={d} fill={fill} stroke="none" />}
      {mark.boundary !== "none" && (
        <path
          d={d}
          fill="none"
          stroke="var(--ink)"
          strokeWidth={1}
          {...(dotted ? DOTTED : { strokeLinecap: "butt" as const })}
        />
      )}
    </g>
  );
}

/* ====================================================================== *
 * The 16px substitute square
 * ====================================================================== */

/**
 * §8.2's low-zoom rule, drawn. "It renders as a fixed 16×16px dashed square
 * containing a centred `▫` glyph, which reads unmistakably as 'AN AREA TOO
 * SMALL TO DRAW AT THIS ZOOM' and never as a location."
 *
 * The `▫` is a glyph, not a mark: it is set in the label voice, it is centred
 * in the SQUARE rather than at any geometric centre of the feature, and it is
 * the same width at every zoom. Nothing here is a position.
 */
export function BelowThresholdSquare({
  box,
  glyph = "▫",
}: {
  box: ScreenBox;
  /**
   * `null` suppresses the glyph. The ONE case that passes null is an
   * `approximate` point whose ring fell below threshold: there the centre is
   * legitimately occupied by an earned survey cross, and a glyph reading "too
   * small to draw" would both collide with it and contradict it. Every other
   * caller keeps the glyph, because every other caller has an empty centre.
   */
  glyph?: string | null;
}) {
  const w = box.maxX - box.minX;
  const h = box.maxY - box.minY;
  return (
    <g>
      <rect
        x={box.minX}
        y={box.minY}
        width={w}
        height={h}
        fill="none"
        stroke="var(--ink)"
        strokeWidth={1}
        strokeDasharray="2 2"
      />
      {glyph !== null && (
      <text
        x={box.minX + w / 2}
        y={box.minY + h / 2}
        textAnchor="middle"
        dominantBaseline="central"
        fontSize={9}
        fill="var(--ink)"
        style={{ fontFamily: "var(--font-mono)" }}
      >
        {glyph}
      </text>
      )}
    </g>
  );
}

/* ====================================================================== *
 * The cluster mark
 * ====================================================================== */

/**
 * §9.3 — "a hairline square with a Mono count inside, NEVER A COLOURED BUBBLE
 * and NEVER SIZED BY MAGNITUDE." The square is the grid CELL (see
 * lib/plate/clusters.ts); the count is one returned column.
 */
export function ClusterSquare({
  box,
  count,
  border,
}: {
  box: ScreenBox;
  count: number;
  border: "solid" | "dotted";
}) {
  const w = box.maxX - box.minX;
  const h = box.maxY - box.minY;
  return (
    <g>
      <rect
        x={box.minX}
        y={box.minY}
        width={w}
        height={h}
        fill="var(--paper)"
        fillOpacity={0.72}
        stroke="var(--ink)"
        strokeWidth={1}
        {...(border === "dotted" ? DOTTED : {})}
      />
      <text
        x={box.minX + w / 2}
        y={box.minY + h / 2}
        textAnchor="middle"
        dominantBaseline="central"
        fontSize={10}
        fill="var(--ink)"
        style={{ fontFamily: "var(--font-mono)", fontVariantNumeric: "tabular-nums" }}
      >
        {count}
      </text>
    </g>
  );
}

/* ====================================================================== *
 * The chart abbreviation
 * ====================================================================== */

/**
 * §9.3 channel 5 — "A two-character text label survives zoom, print, greyscale
 * and screenshot when a stroke style might not." Mono `--t-micro`, set beside
 * every uncertain feature and beside NOTHING that is exact.
 */
export function ChartTagLabel({
  x,
  y,
  tags,
}: {
  x: number;
  y: number;
  tags: string[];
}) {
  if (tags.length === 0) return null;
  return (
    <text
      x={x}
      y={y}
      fontSize={11}
      fill="var(--ink)"
      style={{ fontFamily: "var(--font-mono)", letterSpacing: ".06em" }}
    >
      {tags.join(" ")}
    </text>
  );
}
