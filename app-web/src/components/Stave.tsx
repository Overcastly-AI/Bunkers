/**
 * THE STAVE — DESIGN.md §6, the atom of the design.
 *
 * One glyph carrying a complete evidence profile for ONE PROPOSITION. Three
 * sizes; every size is the same data at a different resolution. Every geometry
 * number below is transcribed from §6.1 / §6.2 / §6.3 and none of them is a
 * value someone liked better.
 *
 * The invariants a reviewer should check first:
 *
 *  FULL INK AT EVERY BAND. The F square is exactly as black as the A square.
 *  Nothing on this site fades, dims, greys or de-emphasises with descending
 *  grade. There is no `opacity` and no `--ink-3` anywhere on a grade mark.
 *
 *  NO HUE ON ANY GRADE. `--ink` and nothing else. `--undercut` appears only on
 *  UNDERCUTS ticks, where it is redundant reinforcement beside a mark that is
 *  already on the other side of the baseline. Remove all colour and every
 *  distinction survives.
 *
 *  R AND X ARE OFF THE RAIL. When the grade is unranked the A–F region renders
 *  as the bare rail with no stops and no marks. "Putting them on the same rail
 *  as A–F would be a lie in geometry."
 *
 *  ONE TICK, ONE ROW. Every mark in the evidence bar is one row of
 *  `core.observation`. No aggregation, no scaling, no averaging.
 */

import type { EvidenceRow, PropositionBadge } from "../lib/types/api";
import type { Grade } from "../lib/types/enums";
import { BAND_WORD } from "../lib/types/grade";
import { staveLabel, tickLabel } from "../lib/stave/label";
import { ladderIndex, staveModel, type StaveModel, type Tick } from "../lib/stave/model";

const INK = "var(--ink)";
const INK3 = "var(--ink-3)";
const INK4 = "var(--ink-4)";
const RULE = "var(--rule)";
const RULE_STRONG = "var(--rule-strong)";
const UNDERCUT = "var(--undercut)";
const HATCH = "url(#hatch45)";
const MONO = "var(--font-mono)";

export interface StaveProps {
  badge: PropositionBadge;
  /** The observation rows, when the caller has them. One tick per row. */
  evidence?: readonly EvidenceRow[];
  /**
   * The band reachable if outstanding verification debt resolves. Supplied
   * only where a value exists; the outline square is simply absent otherwise,
   * because a mark with no row behind it is a bug (§0).
   */
  debtCeiling?: Grade | null;
  /** Specimen containment mechanism 5 — prefixed to EVERY aria-label. */
  ariaPrefix?: string;
}

/* ================================================================== *
 * §6.1 STAVE-FULL — viewBox "0 0 324 26", rendered at 324x26 CSS px
 * ================================================================== */

/** ② the six ranked stops, at 10px pitch. */
const FULL_STOP_X = [46, 56, 66, 76, 86, 96];
/** ③ diagnosticity by tick height — a five-stop discrete ordinal. */
const FULL_TICK_H = [2, 3, 4, 5, 7];

export function StaveFull(props: StaveProps) {
  const m = staveModel(props.badge, {
    evidence: props.evidence,
    debtCeiling: props.debtCeiling ?? null,
  });
  const label = staveLabel(m, props.ariaPrefix);

  return (
    <svg
      className="stave stave-full"
      viewBox="0 0 324 26"
      width="324"
      height="26"
      role="img"
      aria-label={label}
      shapeRendering="crispEdges"
    >
      <title>{label}</title>

      {/* ① CLASS — fixed 4-character code, so class is a scannable left edge. */}
      <text
        x="0"
        y="16"
        fontFamily={MONO}
        fontSize="11"
        fill={INK3}
        style={{ letterSpacing: ".05em" }}
      >
        {m.tag}
      </text>

      <FullLadder m={m} />
      <FullEvidence m={m} />
      <FullPips m={m} />
      <FullSci m={m} />
      <FullFlags m={m} />
    </svg>
  );
}

function FullLadder({ m }: { m: StaveModel }) {
  const l = m.ladder;
  const bare = l.offRail !== null;
  const gradeX = l.gradeStop === null ? null : FULL_STOP_X[l.gradeStop]!;
  const ceilX = l.ceilingStop === null ? null : FULL_STOP_X[l.ceilingStop]!;
  const debtX = l.debtStop === null ? null : FULL_STOP_X[l.debtStop]!;

  return (
    <g>
      {/* The rail is always drawn. Under R and X it is drawn BARE — the ranked
          scale is visibly not in play. */}
      <line x1="46" y1="12" x2="96" y2="12" stroke={RULE_STRONG} strokeWidth="1" />

      {!bare &&
        FULL_STOP_X.map((x) => (
          <line
            key={x}
            x1={x}
            y1="10.5"
            x2={x}
            y2="13.5"
            stroke={RULE_STRONG}
            strokeWidth="1"
          />
        ))}

      {/* Unreached span: reachable, not reached. A hatch, never a fill. */}
      {!bare && gradeX !== null && ceilX !== null && ceilX < gradeX && (
        <rect x={ceilX} y="9" width={gradeX - ceilX} height="6" fill={HATCH} />
      )}

      {/* Debt-ceiling: filled = now · outline = if the debt clears · bar = the
          structural limit. */}
      {!bare && debtX !== null && debtX !== gradeX && (
        <rect
          x={debtX - 3.5}
          y="8.5"
          width="7"
          height="7"
          fill="none"
          stroke={INK}
          strokeWidth="1"
        />
      )}

      {/* GRADE. 7x7, --ink, FULL INK AT EVERY BAND. */}
      {!bare && gradeX !== null && (
        <rect x={gradeX - 3.5} y="8.5" width="7" height="7" fill={INK} />
      )}

      {/* Ceiling terminal bar. at_ceiling draws it at stop+5 so the square
          abuts it and renders as the learnable shape `■┤`. */}
      {!bare && (l.atCeiling ? gradeX !== null : ceilX !== null) && (
        <line
          x1={l.atCeiling ? gradeX! + 5 : ceilX!}
          y1="5"
          x2={l.atCeiling ? gradeX! + 5 : ceilX!}
          y2="19"
          stroke={INK}
          strokeWidth="1.5"
        />
      )}

      {/* Discrimination rule — under A, B and C only. Above it the evidence
          discriminates; below it, it does not. A typographic rule, not a fill. */}
      <line x1="42" y1="20" x2="71" y2="20" stroke={RULE} strokeWidth="1" />

      {/* The off-rail compartment. The detachment is load-bearing. */}
      <line x1="106" y1="4" x2="106" y2="20" stroke={RULE_STRONG} strokeWidth="1" />
      {l.offRail === "R" && (
        <rect x="110.5" y="8.5" width="9" height="9" fill={INK} />
      )}
      {l.offRail === "X" && (
        <rect
          x="122.5"
          y="8.5"
          width="9"
          height="9"
          fill="none"
          stroke={INK}
          strokeWidth="1"
          strokeDasharray="2 2"
        />
      )}
    </g>
  );
}

/** Ticks: 2px wide, 3px pitch, max 10 per quadrant. Highest diagnosticity
 *  nearest the baseline, descending outward — D4 sits against the axis because
 *  D4 is the gate. */
function fullTicks(
  ticks: readonly Tick[],
  side: "right" | "left",
  storey: "upper" | "lower",
  fill: string,
) {
  const shown = ticks.slice(0, 10);
  return shown.map((t, i) => {
    const h = FULL_TICK_H[t.d]!;
    const x = side === "right" ? 173 + i * 3 : 169 - i * 3;
    const y = storey === "upper" ? 12 - h : 14;
    return <rect key={t.key} x={x} y={y} width="2" height={h} fill={fill} />;
  });
}

function Overflow({ n, side, y }: { n: number; side: "right" | "left"; y: number }) {
  if (n <= 0) return null;
  return (
    <text
      x={side === "right" ? 204 : 140}
      y={y}
      fontFamily={MONO}
      fontSize="9"
      fill={INK3}
      textAnchor={side === "right" ? "start" : "end"}
    >
      ▸
    </text>
  );
}

function FullEvidence({ m }: { m: StaveModel }) {
  const e = m.evidence;
  const inert = Array.from({ length: Math.min(e.inert, 20) }, (_, i) => i);
  return (
    <g>
      {/* Zero baseline. */}
      <line x1="172" y1="3" x2="172" y2="23" stroke={RULE_STRONG} strokeWidth="1" />

      {/* Upper storey = CLAIM-PROPERTY. An EMPTY upper storey IS CAP-2b, and it
          is visible as a void rather than stated in a footnote. */}
      {fullTicks(e.vClaim, "right", "upper", INK)}
      {fullTicks(e.vPlace, "right", "lower", INK)}
      {fullTicks(e.uClaim, "left", "upper", UNDERCUT)}
      {fullTicks(e.uPlace, "left", "lower", UNDERCUT)}

      <Overflow n={e.vClaim.length - 10} side="right" y={8} />
      <Overflow n={e.vPlace.length - 10} side="right" y={22} />
      <Overflow n={e.uClaim.length - 10} side="left" y={8} />
      <Overflow n={e.uPlace.length - 10} side="left" y={22} />

      {/* THE INERT TRAY. Retained, displayed, arithmetically inert — and the
          geometry says exactly that: on the chart, not on the axis. */}
      {e.inert > 0 && (
        <>
          <line
            x1="142"
            y1="25"
            x2="202"
            y2="25"
            stroke={RULE}
            strokeWidth="1"
            strokeDasharray="1 2"
          />
          {inert.map((i) => (
            <rect
              key={i}
              x={142 + i * 3}
              y="22"
              width="2"
              height="2"
              fill="none"
              stroke={INK3}
              strokeWidth="1"
            />
          ))}
        </>
      )}
    </g>
  );
}

function FullPips({ m }: { m: StaveModel }) {
  const p = m.pips;
  const shown = Math.min(p.total, 5);
  const pips = Array.from({ length: shown }, (_, i) => i);
  return (
    <g>
      {pips.map((i) => {
        const filled = i < p.filled;
        return (
          <circle
            key={i}
            cx={213 + i * 5}
            cy="13"
            r="1.75"
            fill={filled ? INK : "none"}
            stroke={filled ? "none" : INK}
            strokeWidth="1"
          />
        );
      })}
      {p.total > 5 && (
        <text x="238" y="16" fontFamily={MONO} fontSize="9" fill={INK}>
          +{p.total - 5}
        </text>
      )}
    </g>
  );
}

function FullSci({ m }: { m: StaveModel }) {
  const s = m.sci;
  if (!s) return null;

  /* An EMPTY DENOMINATOR is COMPLETE, and it must not look like zero. */
  if (s.emptyDenominator) {
    return (
      <g>
        <rect
          x="252"
          y="8.5"
          width="9"
          height="9"
          fill="none"
          stroke={INK3}
          strokeWidth="1"
        />
        <text
          x="256.5"
          y="16"
          fontFamily={MONO}
          fontSize="8"
          fill={INK}
          textAnchor="middle"
        >
          ∅
        </text>
      </g>
    );
  }

  if (s.collapse) {
    return (
      <text x="252" y="16" fontFamily={MONO} fontSize="9" fill={INK}>
        {s.k}/{s.n}
      </text>
    );
  }

  const cells = Array.from({ length: s.n }, (_, i) => i);
  return (
    <g>
      {cells.map((i) => (
        <rect
          key={i}
          x={252 + i * 4}
          y="8.5"
          width="3"
          height="9"
          fill={i < s.k ? INK : "none"}
          stroke={i < s.k ? "none" : INK3}
          strokeWidth="1"
        />
      ))}
      {/* The X-floor is a VISIBLE POSITION, not a colour. */}
      <line
        x1={252 + s.thresholdAt * 4}
        y1="6"
        x2={252 + s.thresholdAt * 4}
        y2="20"
        stroke={RULE_STRONG}
        strokeWidth="1"
      />
    </g>
  );
}

const FULL_FLAG_X = [297, 303, 309, 315, 321];

function FullFlags({ m }: { m: StaveModel }) {
  return (
    <g>
      {m.flags.map((f, i) =>
        f.glyph ? (
          <text
            key={i}
            x={FULL_FLAG_X[i]}
            y="16"
            fontFamily={MONO}
            fontSize="9"
            fill={INK}
            textAnchor="middle"
          >
            {f.glyph}
          </text>
        ) : (
          /* AN EMPTY SLOT RENDERS AS A DOT so that absence is visible. */
          <circle key={i} cx={FULL_FLAG_X[i]} cy="13" r="0.75" fill={INK4} />
        ),
      )}
    </g>
  );
}

/* ================================================================== *
 * §6.2 STAVE-MICRO — viewBox "0 0 212 16". Fluid; the mobile stave list.
 * Drops ① (class comes from column position) and ⑤.
 * ================================================================== */

const MICRO_STOP_X = [2, 10, 18, 26, 34, 42];
/** At micro, D0 and D1 ARE NOT DISTINGUISHABLE — stated, accepted, and
 *  recovered in the aria-label and on expansion. */
const MICRO_TICK_H = [2, 2, 3, 4, 5];

export function StaveMicro(props: StaveProps) {
  const m = staveModel(props.badge, {
    evidence: props.evidence,
    debtCeiling: props.debtCeiling ?? null,
  });
  const label = staveLabel(m, props.ariaPrefix);
  const l = m.ladder;
  const bare = l.offRail !== null;
  const gradeX = l.gradeStop === null ? null : MICRO_STOP_X[l.gradeStop]!;
  const ceilX = l.ceilingStop === null ? null : MICRO_STOP_X[l.ceilingStop]!;
  const debtX = l.debtStop === null ? null : MICRO_STOP_X[l.debtStop]!;
  const e = m.evidence;

  const ticks = (
    list: readonly Tick[],
    side: "right" | "left",
    storey: "upper" | "lower",
    fill: string,
  ) =>
    list.slice(0, 12).map((t, i) => {
      const h = MICRO_TICK_H[t.d]!;
      const x = side === "right" ? 115 + i * 2 : 112 - i * 2;
      const y = storey === "upper" ? 7 - h : 9;
      return <rect key={t.key} x={x} y={y} width="1" height={h} fill={fill} />;
    });

  return (
    <svg
      className="stave stave-micro"
      viewBox="0 0 212 16"
      preserveAspectRatio="xMinYMid meet"
      role="img"
      aria-label={label}
      shapeRendering="crispEdges"
    >
      <title>{label}</title>

      {/* ② ladder */}
      <line x1="2" y1="7" x2="42" y2="7" stroke={RULE_STRONG} strokeWidth="1" />
      {!bare &&
        MICRO_STOP_X.map((x) => (
          <line key={x} x1={x} y1="6" x2={x} y2="8" stroke={RULE_STRONG} strokeWidth="1" />
        ))}
      {!bare && gradeX !== null && ceilX !== null && ceilX < gradeX && (
        <rect x={ceilX} y="5" width={gradeX - ceilX} height="4" fill={HATCH} />
      )}
      {!bare && debtX !== null && debtX !== gradeX && (
        <rect
          x={debtX - 2.5}
          y="4.5"
          width="5"
          height="5"
          fill="none"
          stroke={INK}
          strokeWidth="1"
        />
      )}
      {!bare && gradeX !== null && (
        <rect x={gradeX - 2.5} y="4.5" width="5" height="5" fill={INK} />
      )}
      {!bare && (l.atCeiling ? gradeX !== null : ceilX !== null) && (
        <line
          x1={l.atCeiling ? gradeX! + 4 : ceilX!}
          y1="3"
          x2={l.atCeiling ? gradeX! + 4 : ceilX!}
          y2="11"
          stroke={INK}
          strokeWidth="1.5"
        />
      )}
      <line x1="0" y1="12" x2="22" y2="12" stroke={RULE} strokeWidth="1" />
      <line x1="50" y1="2" x2="50" y2="14" stroke={RULE_STRONG} strokeWidth="1" />
      {l.offRail === "R" && <rect x="53.5" y="4.5" width="7" height="7" fill={INK} />}
      {l.offRail === "X" && (
        <rect
          x="62.5"
          y="4.5"
          width="7"
          height="7"
          fill="none"
          stroke={INK}
          strokeWidth="1"
          strokeDasharray="2 2"
        />
      )}

      {/* ③ evidence */}
      <line x1="114" y1="1" x2="114" y2="14" stroke={RULE_STRONG} strokeWidth="1" />
      {ticks(e.vClaim, "right", "upper", INK)}
      {ticks(e.vPlace, "right", "lower", INK)}
      {ticks(e.uClaim, "left", "upper", UNDERCUT)}
      {ticks(e.uPlace, "left", "lower", UNDERCUT)}
      {e.inert > 0 && (
        <>
          <line
            x1="90"
            y1="15"
            x2="138"
            y2="15"
            stroke={RULE}
            strokeWidth="1"
            strokeDasharray="1 2"
          />
          {Array.from({ length: Math.min(e.inert, 20) }, (_, i) => (
            <rect
              key={i}
              x={90 + i * 2}
              y="13"
              width="1"
              height="1"
              fill="none"
              stroke={INK3}
              strokeWidth="1"
            />
          ))}
        </>
      )}

      {/* ④ pips */}
      {Array.from({ length: Math.min(m.pips.total, 5) }, (_, i) => {
        const filled = i < m.pips.filled;
        return (
          <circle
            key={i}
            cx={159 + i * 4}
            cy="8"
            r="1.25"
            fill={filled ? INK : "none"}
            stroke={filled ? "none" : INK}
            strokeWidth="1"
          />
        );
      })}
      {m.pips.total > 5 && (
        <text x="180" y="11" fontFamily={MONO} fontSize="7" fill={INK}>
          +{m.pips.total - 5}
        </text>
      )}

      {/* ⑥ flags */}
      {m.flags.map((f, i) =>
        f.glyph ? (
          <text
            key={i}
            x={192 + i * 4}
            y="11"
            fontFamily={MONO}
            fontSize="7"
            fill={INK}
            textAnchor="middle"
          >
            {f.glyph}
          </text>
        ) : (
          <circle key={i} cx={192 + i * 4} cy="8" r="0.6" fill={INK4} />
        ),
      )}
    </svg>
  );
}

/* ================================================================== *
 * §6.3 STAVE-TICK — viewBox "0 0 18 20", rendered at 18x20 CSS px.
 *
 * THE INDEX MARK. Ladder only, rotated vertical, so twelve of them fit in a
 * 32px table row and THE WHOLE REGISTER READS AS A FIELD OF SMALL MULTIPLES.
 * ================================================================== */

const TICK_STOP_Y = [2, 5, 8, 11, 14, 17];

export interface StaveTickProps {
  badge: PropositionBadge;
  debtCeiling?: Grade | null;
  ariaPrefix?: string;
}

export function StaveTick({ badge, debtCeiling, ariaPrefix }: StaveTickProps) {
  const label = tickLabel(badge, ariaPrefix);
  const gradeY = ladderIndex(badge.grade) === null ? null : TICK_STOP_Y[ladderIndex(badge.grade)!]!;
  const ceilIdx = ladderIndex(badge.ceiling);
  const ceilY = ceilIdx === null ? null : TICK_STOP_Y[ceilIdx]!;
  const debtIdx = ladderIndex(debtCeiling ?? null);
  const debtY = debtIdx === null ? null : TICK_STOP_Y[debtIdx]!;
  const bare = badge.grade === "R" || badge.grade === "X";

  return (
    <svg
      className="stave stave-tick"
      viewBox="0 0 18 20"
      width="18"
      height="20"
      role="img"
      aria-label={label}
      shapeRendering="crispEdges"
    >
      <title>{label}</title>
      <line x1="1" y1="1" x2="1" y2="18" stroke={RULE_STRONG} strokeWidth="1" />

      {!bare && gradeY !== null && ceilY !== null && ceilY < gradeY && (
        <rect x="2" y={ceilY} width="6" height={gradeY - ceilY} fill={HATCH} />
      )}

      {!bare && debtY !== null && debtY !== gradeY && (
        <rect
          x="2"
          y={debtY - 1}
          width="6"
          height="2"
          fill="none"
          stroke={INK}
          strokeWidth="1"
        />
      )}

      {/* Ceiling as a dimension tick with 3px serifs at each end: the span is
          an interval with COUNTABLE ENDPOINTS, and it is the only interval on
          the site. */}
      {!bare && gradeY !== null && ceilY !== null && ceilY !== gradeY && (
        <g stroke={INK} strokeWidth="1">
          <line x1="10" y1={ceilY} x2="10" y2={gradeY} />
          <line x1="9" y1={ceilY} x2="12" y2={ceilY} />
          <line x1="9" y1={gradeY} x2="12" y2={gradeY} />
        </g>
      )}

      {/* GRADE — 6x2 filled bar. Full ink at every band. */}
      {!bare && gradeY !== null && (
        <rect x="2" y={gradeY - 1} width="6" height="2" fill={INK} />
      )}

      {badge.grade === "R" && <rect x="11" y="7" width="6" height="6" fill={INK} />}
      {badge.grade === "X" && (
        <rect
          x="11"
          y="7"
          width="6"
          height="6"
          fill="none"
          stroke={INK}
          strokeWidth="1"
          strokeDasharray="1.5 1.5"
        />
      )}
    </svg>
  );
}

/**
 * An ABSENT CLASS — the rail drawn in `--rule` with no mark at all. An empty
 * slot in the container list, and visibly so. It is not a grade of any kind and
 * it carries no accessible name beyond the words.
 */
export function StaveTickAbsent({ label }: { label: string }) {
  return (
    <svg
      className="stave stave-tick"
      viewBox="0 0 18 20"
      width="18"
      height="20"
      role="img"
      aria-label={label}
      shapeRendering="crispEdges"
    >
      <title>{label}</title>
      <line x1="1" y1="1" x2="1" y2="18" stroke={RULE} strokeWidth="1" />
    </svg>
  );
}

/* ================================================================== *
 * §7 — GRADE RENDERING OUTSIDE THE STAVE
 *
 * "A stave is never the SOLE rendering of a grade on a detail page; letter and
 * word always print adjacent." Four redundant channels, zero hue.
 * ================================================================== */

export function GradeLetterWord({
  grade,
  atCeiling,
  ceiling,
}: {
  grade: Grade;
  atCeiling?: boolean;
  ceiling?: Grade | null;
}) {
  return (
    <span className="grade-lw">
      <span className="voice-mono grade-letter">{grade}</span>
      <span className="t-micro grade-band">{BAND_WORD[grade]}</span>
      {atCeiling ? (
        <span className="t-micro grade-ceiling">at ceiling</span>
      ) : ceiling ? (
        <span className="t-micro grade-ceiling">ceiling {ceiling}</span>
      ) : null}
    </span>
  );
}
