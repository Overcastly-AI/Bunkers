/**
 * THE STAVE LIST — DESIGN.md §15, the narrow-column presentation.
 *
 * "Dense tables fail on phones by horizontal scroll (loses comparison) or by
 * card stacks (loses density and destroys table semantics). NEITHER IS USED AS
 * THE WHOLE ANSWER."
 *
 * "The register table TRANSPOSES INTO A STAVE LIST. Each entry becomes: name
 * (1 line); `state · typology · locate_precision` (1 line, Mono micro); then
 * the FULL STAVE COLUMN AS A STACKED MICRO-BLOCK — up to 12 STAVE-MICRO at 100%
 * width, 16px each, ~200px total, carrying the entire evidence profile. THIS IS
 * THE ONE ELEMENT THAT *GAINS* FROM A NARROW COLUMN, because staves stack
 * rather than tile."
 *
 * It is reached at `?view=list` and the catalogue table stays at `?view=table`,
 * as §15 requires. It is a URL choice rather than a breakpoint because the page
 * is server-rendered and the alternative — shipping both markup trees and
 * hiding one with a media query — would double the DOM of every index page and
 * put a second copy of every stave in the accessibility tree. The cost of the
 * choice is that a phone does not get the transposition automatically; it is
 * one link away, the link is in the URL, and the table itself never forces the
 * page body to scroll horizontally (§15's actual hard requirement).
 *
 * Class comes from ROW POSITION here rather than from a tag, exactly as §6.2
 * says: the twelve rows are in the fixed class order on every entry, so the
 * seventh line is FUNCTION on every entry in the list.
 */

import { GradeLetterWord, StaveMicro } from "./Stave";
import type { EvidenceRow, RegisterEntryRow } from "../lib/types/api";
import { CLASS_TAG, PROPOSITION_CLASS_ORDER } from "../lib/types/enums";
import { propositionRef } from "../lib/refs";

export function StaveList({
  rows,
  hrefFor,
  ariaPrefix,
  evidence,
}: {
  rows: readonly RegisterEntryRow[];
  hrefFor: (row: RegisterEntryRow) => string;
  ariaPrefix?: string;
  /**
   * The observation rows, keyed by `proposition_id`, WHERE THE CALLER HOLDS
   * THEM. An index row carries counts, not observations, so without this the
   * micro stave draws its ticks at a uniform height and the aria-label says
   * "per-observation diagnosticity is not carried on this row" — the honest
   * rendering of a value the row does not have. When the caller does hold the
   * rows, the ticks carry their real diagnosticity and D4 sits against the
   * baseline where the design puts it.
   */
  evidence?: Record<string, readonly EvidenceRow[]>;
}) {
  return (
    <ol className="stave-list">
      {rows.map((row) => (
        <li key={row.entity_id} className="stave-list-entry">
          <div className="stave-list-name">
            <a href={hrefFor(row)}>{row.canonical_name}</a>{" "}
            <span className="voice-mono t-micro">{row.ref}</span>
          </div>
          <div className="voice-mono t-micro stave-list-meta">
            {row.jurisdiction} · {row.typology ?? "no typology"} · {row.locate_precision}
          </div>

          <div className="stave-list-block">
            {PROPOSITION_CLASS_ORDER.map((c) => {
              const badges = row.matrix[c] ?? [];
              return (
                <div key={c} className="stave-list-line">
                  <span className="voice-mono stave-list-tag">{CLASS_TAG[c]}</span>
                  {badges.length === 0 ? (
                    /* An absent class keeps its line. The empty slot is part of
                       the reading: the register is saying it has not opened a
                       proposition of this class on this entity. */
                    <span className="t-micro stave-list-absent">not graded</span>
                  ) : (
                    badges.map((b) => (
                      <a
                        key={b.proposition_id}
                        className="stave-list-mark"
                        href={`${hrefFor(row)}#${propositionRef(b, badges)}`}
                      >
                        <StaveMicro
                          badge={b}
                          evidence={evidence?.[b.proposition_id]}
                          ariaPrefix={ariaPrefix}
                        />
                        <GradeLetterWord
                          grade={b.grade}
                          atCeiling={b.at_ceiling}
                          ceiling={b.ceiling}
                        />
                      </a>
                    ))
                  )}
                </div>
              );
            })}
          </div>
        </li>
      ))}
    </ol>
  );
}
