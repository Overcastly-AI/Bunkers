/**
 * §10 MOVEMENT — A STEP CHART, NEVER A LINE. DESIGN.md §13.2.
 *
 * "Grades are ordinal, so there is NO INTERPOLATION, NO SMOOTHING, NO
 * HALF-STEP. Y-axis is the six ranked stops with R and X in a DETACHED BAND
 * BELOW THE AXIS, matching the ladder."
 *
 * The chart draws only horizontal treads and vertical risers. There is no
 * diagonal anywhere in it, because a diagonal between two bands would assert
 * the existence of intermediate states that BES does not define — §19 refusal
 * 3. The x-axis is EVENT ORDER, not elapsed time: spacing events by date would
 * make the gap between them a visual quantity, and the gap between two grading
 * runs measures the register's staffing, not the evidence.
 *
 * `NEW-DISCLOSURE` carries its annotation because the distinction it marks is
 * the register's whole subject: the publication record changed; the world did
 * not.
 *
 * Instrument-drift causes are hidden by default behind A VISIBLE TOGGLE STATING
 * THE COUNT — "because hiding them silently would be the same sin one level up."
 */

import type { GradeEvent } from "../lib/types/api";
import type { Grade } from "../lib/types/enums";
import { INSTRUMENT_DRIFT_CAUSES, RANKED_GRADES } from "../lib/types/enums";
import { BAND_WORD } from "../lib/types/grade";

const ROW_H = 14;
const COL_W = 78;
const LEFT = 28;
const TOP = 10;
/** The gap that detaches R and X from the ranked axis. */
const DETACH_GAP = 12;

function yFor(g: Grade): number {
  const i = RANKED_GRADES.indexOf(g as never);
  if (i >= 0) return TOP + i * ROW_H;
  const j = g === "R" ? 0 : 1;
  return TOP + 6 * ROW_H + DETACH_GAP + j * ROW_H;
}

function isDrift(e: GradeEvent): boolean {
  return (INSTRUMENT_DRIFT_CAUSES as readonly string[]).includes(e.transition_cause);
}

export function StepChart({ events }: { events: readonly GradeEvent[] }) {
  const drift = events.filter(isDrift);
  const shown = events.filter((e) => !isDrift(e));

  if (events.length === 0) {
    return (
      <p className="t-small">
        No grade event is recorded for this proposition. It has not moved, which is different from
        having been confirmed.
      </p>
    );
  }

  const w = LEFT + Math.max(1, shown.length) * COL_W + 20;
  const h = TOP + 6 * ROW_H + DETACH_GAP + 2 * ROW_H + 34;

  const label = shown
    .map(
      (e) =>
        `${e.occurred_at.slice(0, 10)}: ${e.grade_from ?? "no grade"} to ${e.grade_to}, ${e.transition_cause}`,
    )
    .join("; ");

  return (
    <div className="step-chart">
      <div className="scroll-region" role="region" aria-label="Grade movement" tabIndex={0}>
        <svg
          viewBox={`0 0 ${w} ${h}`}
          width={w}
          height={h}
          role="img"
          aria-label={`Grade movement, ${shown.length} steps. ${label}`}
          shapeRendering="crispEdges"
        >
          <title>Grade movement — a step chart. No value between two bands is drawn.</title>

          {/* The ranked axis. */}
          {RANKED_GRADES.map((g) => (
            <g key={g}>
              <text
                x="0"
                y={yFor(g) + 4}
                fontFamily="var(--font-mono)"
                fontSize="9"
                fill="var(--ink-3)"
              >
                {g}
              </text>
              <line
                x1={LEFT}
                y1={yFor(g)}
                x2={w - 10}
                y2={yFor(g)}
                stroke="var(--rule)"
                strokeWidth="1"
              />
            </g>
          ))}

          {/* The detached band. R and X are not low grades; they are not on the
              scale that contains F, and the gap says so. */}
          {(["R", "X"] as Grade[]).map((g) => (
            <g key={g}>
              <text
                x="0"
                y={yFor(g) + 4}
                fontFamily="var(--font-mono)"
                fontSize="9"
                fill="var(--ink-3)"
              >
                {g}
              </text>
              <line
                x1={LEFT}
                y1={yFor(g)}
                x2={w - 10}
                y2={yFor(g)}
                stroke="var(--rule)"
                strokeWidth="1"
                strokeDasharray="2 2"
              />
            </g>
          ))}

          {/* Treads and risers only. */}
          {shown.map((e, i) => {
            const x0 = LEFT + i * COL_W;
            const x1 = x0 + COL_W;
            const y = yFor(e.grade_to);
            const prev = i === 0 ? (e.grade_from ?? null) : shown[i - 1]!.grade_to;
            return (
              <g key={e.grade_event_id}>
                {prev !== null && (
                  <line
                    x1={x0}
                    y1={yFor(prev)}
                    x2={x0}
                    y2={y}
                    stroke="var(--ink)"
                    strokeWidth="1.5"
                  />
                )}
                <line x1={x0} y1={y} x2={x1} y2={y} stroke="var(--ink)" strokeWidth="1.5" />
                <rect x={x0 - 2.5} y={y - 2.5} width="5" height="5" fill="var(--ink)" />
                <text
                  x={x0 + 2}
                  y={h - 20}
                  fontFamily="var(--font-mono)"
                  fontSize="8"
                  fill="var(--ink-3)"
                >
                  {e.occurred_at.slice(0, 10)}
                </text>
                <text
                  x={x0 + 2}
                  y={h - 10}
                  fontFamily="var(--font-mono)"
                  fontSize="8"
                  fill="var(--ink-3)"
                >
                  {e.transition_cause}
                </text>
              </g>
            );
          })}
        </svg>
      </div>

      {drift.length > 0 ? (
        <details className="drift-toggle">
          <summary className="t-micro">
            {drift.length} instrument-drift {drift.length === 1 ? "event" : "events"} hidden — show
          </summary>
          <ul className="t-small">
            {drift.map((e) => (
              <li key={e.grade_event_id} className="voice-mono">
                {e.occurred_at.slice(0, 10)} {e.grade_from ?? "—"} → {e.grade_to}{" "}
                {e.transition_cause} · rubric {e.rubric_version}
              </li>
            ))}
          </ul>
          <p className="t-small">
            These are movements of the instrument, not of the record. They are hidden by default and
            counted in the open, because hiding them silently would be the same failure one level up.
          </p>
        </details>
      ) : null}

      {/* The text log. Long, plain, and the thing that is actually citable. */}
      <ol className="movement-log voice-mono t-small">
        {events.map((e) => (
          <li key={e.grade_event_id}>
            {e.occurred_at.slice(0, 10)} {e.grade_from ?? "—"} → {e.grade_to}{" "}
            {e.transition_cause} rubric {e.rubric_version} hash {e.evidence_state_hash.slice(0, 6)}…
            {e.transition_cause === "NEW-DISCLOSURE" ? (
              <span className="voice-sans"> — the publication record changed; the world did not.</span>
            ) : null}
            {e.note ? <span className="voice-sans"> — {e.note}</span> : null}
          </li>
        ))}
      </ol>

      <p className="t-small">
        The y-axis is the six ranked bands with{" "}
        <span className="voice-mono">R</span> and <span className="voice-mono">X</span> detached
        below it. Nothing is drawn between two bands: {BAND_WORD.C} and {BAND_WORD.D} have no
        midpoint, and a line implying one would be a value no rubric defines.
      </p>
    </div>
  );
}
