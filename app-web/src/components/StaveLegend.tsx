/**
 * HOW TO READ A STAVE — DESIGN.md §13.1(b).
 *
 * A permanent legend printing STAVE-FULL at true size with each of the six
 * compartments labelled, and the eight bands listed with letter, band word and
 * statement-about-the-record. NOT COLLAPSIBLE, NOT DISMISSIBLE. "The apparatus
 * is handed to the reader BEFORE any data, exactly as a chart prints its legend
 * on the plate."
 *
 * WHY THIS IS DRAWN RATHER THAN RENDERED FROM A BADGE. A legend is the symbol
 * vocabulary, not a reading. If this block rendered `<StaveFull>` over a
 * fabricated `api.proposition_badge` row, the register's front page would carry
 * a graded proposition that no observation supports — Rule Zero violated at the
 * top of the document, in the one place a reader is most likely to screenshot.
 * §9.6 settles the form: legend symbols are "drawn as inline SVG AT TRUE SIZE,
 * not as scaled-up illustrations, so they match the marks exactly." Every
 * coordinate below is the same coordinate `Stave.tsx` draws.
 */

import { GRADES, RANKED_GRADES, type Grade } from "../lib/types/enums";
import { BAND_STATEMENT, BAND_WORD } from "../lib/types/grade";

const INK = "var(--ink)";
const INK3 = "var(--ink-3)";
const INK4 = "var(--ink-4)";
const RULE = "var(--rule)";
const RULE_STRONG = "var(--rule-strong)";
const UNDERCUT = "var(--undercut)";
const MONO = "var(--font-mono)";

const COMPARTMENTS: { n: string; label: string; x: number; body: string }[] = [
  { n: "①", label: "CLASS", x: 0, body: "which proposition" },
  { n: "②", label: "LADDER", x: 42, body: "grade · ceiling · unreached span" },
  { n: "③", label: "EVIDENCE", x: 140, body: "one tick = one observation" },
  { n: "④", label: "LINEAGE", x: 212, body: "independent witnesses" },
  { n: "⑤", label: "SCI", x: 252, body: "search completeness k of n" },
  { n: "⑥", label: "FLAGS", x: 294, body: "five fixed slots" },
];

/**
 * The annotated figure. It is the STAVE-FULL skeleton at true size — the same
 * 324x26 viewBox, the same stop pitch, the same tick heights — carrying one
 * example of every mark type, with the compartment rules drawn above it.
 */
function LegendFigure() {
  return (
    <svg
      className="stave-legend-figure"
      viewBox="0 0 324 58"
      width="324"
      height="58"
      role="img"
      aria-label="Legend: the six compartments of a stave, left to right — class tag, ladder, evidence bar, lineage pips, search-completeness strip, flag gutter. The marks below are symbol examples, not a graded proposition."
      shapeRendering="crispEdges"
    >
      <title>The six compartments of a stave, drawn at true size.</title>

      {/* Compartment numerals and boundary ticks. */}
      {COMPARTMENTS.map((c) => (
        <g key={c.label}>
          <text x={c.x} y="8" fontFamily={MONO} fontSize="8" fill={INK3}>
            {c.n} {c.label}
          </text>
          <line x1={c.x} y1="11" x2={c.x} y2="14" stroke={RULE} strokeWidth="1" />
        </g>
      ))}

      <g transform="translate(0 16)">
        {/* ① */}
        <text
          x="0"
          y="16"
          fontFamily={MONO}
          fontSize="11"
          fill={INK3}
          style={{ letterSpacing: ".05em" }}
        >
          FUNC
        </text>

        {/* ② the ladder — grade at C, ceiling at A, hatched unreached span. */}
        <line x1="46" y1="12" x2="96" y2="12" stroke={RULE_STRONG} strokeWidth="1" />
        {[46, 56, 66, 76, 86, 96].map((x) => (
          <line key={x} x1={x} y1="10.5" x2={x} y2="13.5" stroke={RULE_STRONG} strokeWidth="1" />
        ))}
        <rect x="46" y="9" width="20" height="6" fill="url(#hatch45)" />
        <rect x="52.5" y="8.5" width="7" height="7" fill="none" stroke={INK} strokeWidth="1" />
        <rect x="62.5" y="8.5" width="7" height="7" fill={INK} />
        <line x1="46" y1="5" x2="46" y2="19" stroke={INK} strokeWidth="1.5" />
        <line x1="42" y1="20" x2="71" y2="20" stroke={RULE} strokeWidth="1" />
        <line x1="106" y1="4" x2="106" y2="20" stroke={RULE_STRONG} strokeWidth="1" />
        <rect x="110.5" y="8.5" width="9" height="9" fill="none" stroke={RULE} strokeWidth="1" />
        <rect
          x="122.5"
          y="8.5"
          width="9"
          height="9"
          fill="none"
          stroke={RULE}
          strokeWidth="1"
          strokeDasharray="2 2"
        />

        {/* ③ the evidence bar — upper storey CLAIM, lower storey PLACE. */}
        <line x1="172" y1="3" x2="172" y2="23" stroke={RULE_STRONG} strokeWidth="1" />
        <rect x="173" y="5" width="2" height="7" fill={INK} />
        <rect x="176" y="7" width="2" height="5" fill={INK} />
        <rect x="179" y="8" width="2" height="4" fill={INK} />
        <rect x="173" y="14" width="2" height="5" fill={INK} />
        <rect x="176" y="14" width="2" height="3" fill={INK} />
        <rect x="169" y="14" width="2" height="4" fill={UNDERCUT} />
        <line
          x1="142"
          y1="25"
          x2="202"
          y2="25"
          stroke={RULE}
          strokeWidth="1"
          strokeDasharray="1 2"
        />
        {[0, 1, 2].map((i) => (
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

        {/* ④ pips — filled = D3+, open = D2 only. */}
        <circle cx="213" cy="13" r="1.75" fill={INK} />
        <circle cx="218" cy="13" r="1.75" fill={INK} />
        <circle cx="223" cy="13" r="1.75" fill="none" stroke={INK} strokeWidth="1" />

        {/* ⑤ SCI — filled = receipted, open = applicable but unsearched. */}
        {[0, 1, 2, 3, 4, 5].map((i) => (
          <rect
            key={i}
            x={252 + i * 4}
            y="8.5"
            width="3"
            height="9"
            fill={i < 4 ? INK : "none"}
            stroke={i < 4 ? "none" : INK3}
            strokeWidth="1"
          />
        ))}
        <line x1="264" y1="6" x2="264" y2="20" stroke={RULE_STRONG} strokeWidth="1" />

        {/* ⑥ flags — an empty slot is a dot, so absence is visible. */}
        <text x="297" y="16" fontFamily={MONO} fontSize="9" fill={INK} textAnchor="middle">
          ∥
        </text>
        <circle cx="303" cy="13" r="0.75" fill={INK4} />
        <text x="309" y="16" fontFamily={MONO} fontSize="9" fill={INK} textAnchor="middle">
          ⟳
        </text>
        <text x="315" y="16" fontFamily={MONO} fontSize="9" fill={INK} textAnchor="middle">
          ⌀
        </text>
        <text x="321" y="16" fontFamily={MONO} fontSize="9" fill={INK} textAnchor="middle">
          ⚑
        </text>
      </g>
    </svg>
  );
}

/**
 * The ladder position of one band, drawn at STAVE-TICK size and with the same
 * coordinates. R is a filled detached cell beside a BARE rail; X is a dashed
 * hollow one — "X renders visually distinct from F … drawn as an absence."
 */
function BandTick({ grade }: { grade: Grade }) {
  const stops = [2, 5, 8, 11, 14, 17];
  const idx = RANKED_GRADES.indexOf(grade as never);
  return (
    <svg
      viewBox="0 0 18 20"
      width="18"
      height="20"
      aria-hidden="true"
      focusable="false"
      shapeRendering="crispEdges"
    >
      <line x1="1" y1="1" x2="1" y2="18" stroke={RULE_STRONG} strokeWidth="1" />
      {idx >= 0 && <rect x="2" y={stops[idx]! - 1} width="6" height="2" fill={INK} />}
      {grade === "R" && <rect x="11" y="7" width="6" height="6" fill={INK} />}
      {grade === "X" && (
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

export function StaveLegend() {
  return (
    <section className="stave-legend" aria-labelledby="legend-h">
      <h2 id="legend-h" className="t-micro">
        How to read a stave
      </h2>

      <div className="stave-legend-scroll" role="region" aria-label="Stave legend figure">
        <LegendFigure />
      </div>

      <dl className="legend-compartments t-small">
        {COMPARTMENTS.map((c) => (
          <div key={c.label}>
            <dt className="voice-mono">
              {c.n} {c.label}
            </dt>
            <dd>{c.body}</dd>
          </div>
        ))}
      </dl>

      <p className="t-small legend-note">
        One stave is one <em>proposition</em>, never one site. A site is a container of
        independently graded propositions, and the container carries no grade of its own —
        there is no composite anywhere in this register and no slot into which one could be
        inserted. Grade is carried by four redundant channels — position on the ladder, the
        letter, the band word, and fill state — and by no hue at all. <strong>R</strong> and{" "}
        <strong>X</strong> sit in detached cells beside the rail because they are unranked
        epistemic objects, not low grades.
      </p>

      <div className="scroll-region" role="region" aria-label="The eight bands">
        <table className="band-table">
          <caption className="t-micro">
            The eight bands. Each is a statement about the record, never about the world.
          </caption>
          <thead>
            <tr>
              <th scope="col">Mark</th>
              <th scope="col">Letter</th>
              <th scope="col">Band</th>
              <th scope="col">What the register is saying</th>
            </tr>
          </thead>
          <tbody>
            {GRADES.map((g) => (
              <tr key={g}>
                <td>
                  <BandTick grade={g} />
                </td>
                <td className="voice-mono grade-letter">{g}</td>
                <td className="t-micro">{BAND_WORD[g]}</td>
                <td>{BAND_STATEMENT[g]}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}
