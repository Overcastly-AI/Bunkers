/**
 * THE CLAIMS REGISTER — DESIGN.md §13.3, §8.3.
 *
 * "ORGANISED BY ORIGIN, NOT BY FACILITY. The `ORIGIN` proposition heads each
 * entry; facilities are downstream. THAT INVERSION IS THE WHOLE IDEA: this is a
 * catalogue of claims and where they came from, a genuine scholarly
 * contribution independent of whether any facility is real."
 *
 * DEFAULT SORT: ORIGIN DATE ASCENDING. "Sorted that way, band F becomes a
 * CHRONOLOGY OF AMERICAN UNDERGROUND FOLKLORE: Oliver 1894 (Telos) → Pollock
 * 1976 (Mount Weather) → Bennewitz 1979–80 (Dulce) → Lazar 1989 (S-4) →
 * Nichols & Moon 1992 (Montauk) → 2016 (Comet Ping Pong)."
 *
 * STYLED IDENTICALLY TO `/` — same rules, same weight, same ink, same stave
 * marks. IT IS NOT A GRAVEYARD. There is no muted ground here, no error
 * iconography, no warning glyph and no reduced type size: an F row has exactly
 * the visual weight of an A row on the register index, and the recurring
 * `ORIG A` beside `FUNC F` pair — the register publishing an A-grade fact about
 * a fabrication — is the design's most distinctive repeated artefact.
 *
 * Undated claims sort LAST rather than to the epoch, because an invented date
 * is a claim.
 */

import { GradeLetterWord, StaveTick } from "./Stave";
import type { ClaimsRegisterRow, PropositionBadge } from "../lib/types/api";

export interface ClaimsTableProps {
  rows: readonly ClaimsRegisterRow[];
  /** Where the claim's sheet lives. The caller decides the namespace. */
  hrefFor: (row: ClaimsRegisterRow) => string;
  refFor: (row: ClaimsRegisterRow) => string;
  /** `lineage_count` and `collapse_delta` per proposition, where traced. */
  lineage?: Record<string, { lineage_count: number; collapse_delta: number }>;
  /** The badge behind each row, where the caller holds it — so the claims
   *  register can print the same stave mark the index does rather than a
   *  second, different rendering of the same grade. */
  badges?: Record<string, PropositionBadge>;
  ariaPrefix?: string;
  emptyBlock?: React.ReactNode;
}

export function ClaimsTable(props: ClaimsTableProps) {
  return (
    <>
      <div className="scroll-region" role="region" aria-label="The claims register" tabIndex={0}>
        <table className="claims-table">
          <caption className="t-small">
            One row per graded proposition in bands E, F, R and X, ordered by the date the claim
            first appears in the record. A row with no date sorts last: the register does not
            invent a terminus it does not have.
          </caption>
          <thead>
            <tr>
              <th scope="col">Ref</th>
              <th scope="col">Claim</th>
              <th scope="col">Origin</th>
              <th scope="col">Origin grade</th>
              <th scope="col">Facility</th>
              <th scope="col">Class</th>
              <th scope="col">Grade</th>
              <th scope="col">Lineages</th>
              <th scope="col">Collapse delta</th>
              <th scope="col">Citogenesis</th>
              <th scope="col">Limiting condition</th>
            </tr>
          </thead>
          <tbody>
            {props.rows.map((r) => {
              const l = props.lineage?.[r.proposition_id];
              const badge = props.badges?.[r.proposition_id];
              const origins = r.origin_propositions ?? [];
              return (
                <tr key={r.proposition_id}>
                  <th scope="row" className="voice-mono col-ref">
                    <a href={props.hrefFor(r)}>{props.refFor(r)}</a>
                  </th>
                  <td className="claims-claim">
                    {r.claim_text ?? <em>{r.statement_text}</em>}
                  </td>
                  <td className="voice-mono">
                    {r.first_appearance_date ?? "undated"}
                    {r.first_appearance_confidence ? (
                      <span className="t-micro"> {r.first_appearance_confidence}</span>
                    ) : null}
                  </td>
                  <td>
                    {origins.length === 0 ? (
                      <span className="voice-mono">—</span>
                    ) : (
                      origins.map((o, i) => (
                        <span key={i} className="claims-origin-grade">
                          <GradeLetterWord grade={o.grade} />
                        </span>
                      ))
                    )}
                  </td>
                  <td>
                    <a href={props.hrefFor(r)}>{r.canonical_name}</a>
                  </td>
                  <td className="voice-mono">{r.class}</td>
                  <td className="claims-grade">
                    {badge ? (
                      <StaveTick badge={badge} ariaPrefix={props.ariaPrefix} />
                    ) : null}
                    <GradeLetterWord grade={r.grade} atCeiling={r.at_ceiling} ceiling={r.ceiling} />
                    {r.refutation_state !== "R0" ? (
                      <span className="voice-mono t-micro"> {r.refutation_state}</span>
                    ) : null}
                  </td>
                  <td className="voice-mono">{l ? l.lineage_count : "—"}</td>
                  <td className="voice-mono">{l ? l.collapse_delta : "—"}</td>
                  <td className="voice-mono">
                    {r.citogenesis ? (
                      <>
                        <span aria-hidden="true">⟳</span> confirmed
                      </>
                    ) : (
                      "—"
                    )}
                  </td>
                  <td className="t-small">{r.limiting_condition ?? "—"}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      {props.rows.length === 0 ? (props.emptyBlock ?? null) : null}
    </>
  );
}
