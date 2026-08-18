/**
 * THE CATALOGUE TABLE — DESIGN.md §13.1(d).
 *
 * ```
 * REF · NAME (aliases) · JURISDICTION · TYPOLOGY · LOCATE · [ 12-column grade
 * matrix ] · SCI · LAST MOVED
 * ```
 *
 * THERE IS NO "GRADE" COLUMN ANYWHERE IN THIS PRODUCT. The matrix is twelve
 * FIXED columns, one per proposition class in `api.proposition_badge` order,
 * each cell holding a STAVE-TICK. Column headers carry the 4-character class
 * tags. Absent classes render an empty rail.
 *
 * "Because the columns are fixed and position-stable, THE CORPUS-WIDE FACT
 * THAT HOLES ARE CERTAIN AND FUNCTIONS ARE NOT BECOMES VISIBLE ON THE INDEX
 * PAGE AS A DIAGONAL TEXTURE, not just on the entry page."
 *
 * The disclosed compression (§21.4): multiple propositions of one class stack
 * up to three ticks in the cell, then `+n` linking to the entry. NO WORST-CASE
 * COLLAPSE, NO "HIGHEST GRADE" SUMMARY — stacking with an explicit overflow
 * count is lossy about *which*, never about *whether*. The loss is disclosed in
 * the column header, where a reader would otherwise infer completeness.
 *
 * §18.1 governs the empty state: THE LAYOUT DOES NOT CHANGE WHEN DATA ARRIVES.
 * The full header — all twelve class columns — renders at zero rows, and the
 * ruled block sits where rows would be. Nothing here is a stand-in.
 */

import { StaveTick, StaveTickAbsent } from "./Stave";
import type { PropositionBadge, RegisterEntryRow } from "../lib/types/api";
import { CLASS_TAG, PROPOSITION_CLASS_ORDER } from "../lib/types/enums";
import { propositionRef } from "../lib/refs";
import { BAND_SORT_LIMITATION, SORT_KEYS, type SortKey } from "../lib/register";
import { withParams, type SearchParams } from "../lib/query";

export interface RegisterTableProps {
  rows: readonly RegisterEntryRow[];
  /** Where a row's sheet lives. `/e/…` for the register, `/calibration/…` for
   *  a specimen — the caller decides, and the table never guesses. */
  hrefFor: (row: RegisterEntryRow) => string;
  /** `?marks=letters` — the accessibility and low-vision path, and it is URL
   *  state so it can be linked. */
  marks: "ticks" | "letters";
  basePath: string;
  searchParams: SearchParams;
  sort: SortKey;
  dir: "asc" | "desc";
  /** Required before band order means anything. */
  bandClass: string | null;
  /** Specimen containment mechanism 5 — carried into every stave label. */
  ariaPrefix?: string;
  /** The ruled block that renders where rows would be. */
  emptyBlock?: React.ReactNode;
}

function SortHead({
  label,
  k,
  props,
  title,
}: {
  label: string;
  k: SortKey;
  props: RegisterTableProps;
  title?: string;
}) {
  const active = props.sort === k;
  const next = active && props.dir === "asc" ? "desc" : "asc";
  const href = withParams(props.basePath, props.searchParams, { sort: k, dir: next });
  return (
    <th
      scope="col"
      rowSpan={2}
      aria-sort={active ? (props.dir === "asc" ? "ascending" : "descending") : "none"}
    >
      <a href={href} title={title}>
        {label}
        {active ? <span aria-hidden="true">{props.dir === "asc" ? " ▴" : " ▾"}</span> : null}
      </a>
    </th>
  );
}

function MatrixCell({
  badges,
  row,
  props,
}: {
  badges: readonly PropositionBadge[];
  row: RegisterEntryRow;
  props: RegisterTableProps;
}) {
  const href = props.hrefFor(row);
  if (badges.length === 0) {
    return (
      <td className="matrix-cell">
        <StaveTickAbsent label={`Not graded on ${row.canonical_name}.`} />
      </td>
    );
  }

  const shown = badges.slice(0, 3);
  const overflow = badges.length - shown.length;

  return (
    <td className="matrix-cell">
      {shown.map((b) => {
        const ref = propositionRef(b, badges);
        return (
          <a key={b.proposition_id} href={`${href}#${ref}`} className="matrix-link">
            {props.marks === "letters" ? (
              <span className="voice-mono matrix-letter" aria-hidden="true">
                {b.grade}
              </span>
            ) : (
              <StaveTick badge={b} ariaPrefix={props.ariaPrefix} />
            )}
            {props.marks === "letters" ? (
              <span className="sr-only">
                {b.class}: grade {b.grade} on {row.canonical_name}.
              </span>
            ) : null}
          </a>
        );
      })}
      {overflow > 0 ? (
        <a href={href} className="matrix-overflow voice-mono">
          +{overflow}
          <span className="sr-only">
            {" "}
            more {shown[0]!.class} propositions on {row.canonical_name}; open the sheet to
            read them.
          </span>
        </a>
      ) : null}
    </td>
  );
}

export function RegisterTable(props: RegisterTableProps) {
  const { rows } = props;
  const marksHref = withParams(props.basePath, props.searchParams, {
    marks: props.marks === "letters" ? null : "letters",
  });

  return (
    <>
      <p className="t-small marks-toggle">
        Grade matrix rendered as{" "}
        {props.marks === "letters" ? (
          <>
            <strong>letters</strong> · <a href={marksHref}>switch to stave marks</a>
          </>
        ) : (
          <>
            <strong>stave marks</strong> · <a href={marksHref}>switch to letters</a>
          </>
        )}
        . The preference is a URL parameter, so this view can be linked and cited.
      </p>

      <div
        className="scroll-region register-table-region"
        role="region"
        aria-label="The catalogue"
        tabIndex={0}
      >
        <table className="register-table">
          <caption className="t-small">
            One row per candidate; one mark per proposition. The twelve grade columns are
            fixed and position-stable, so a class is always in the same place and the
            register can be read down a column as well as across a row.{" "}
            <em>{BAND_SORT_LIMITATION}</em>
          </caption>
          <thead>
            <tr>
              <SortHead label="Ref" k="ref" props={props} />
              <SortHead label="Name" k="name" props={props} />
              <SortHead label="Jurisdiction" k="jurisdiction" props={props} />
              <SortHead label="Typology" k="typology" props={props} />
              <SortHead label="Locate" k="locate" props={props} />
              <th scope="colgroup" colSpan={12} className="matrix-group-head">
                Grade matrix — twelve proposition classes
                <span className="matrix-disclosure">
                  Up to three marks per cell; a cell with more prints{" "}
                  <span className="voice-mono">+n</span> and defers to the sheet. Lossy about{" "}
                  <em>which</em>, never about <em>whether</em>. No cell summarises another and
                  no row has a grade of its own.
                </span>
              </th>
              <SortHead label="SCI" k="sci" props={props} />
              <SortHead label="Last moved" k="moved" props={props} />
            </tr>
            <tr className="matrix-head-row">
              {PROPOSITION_CLASS_ORDER.map((c) => {
                const href = withParams(props.basePath, props.searchParams, {
                  sort: "band",
                  dir: props.sort === "band" && props.bandClass === c && props.dir === "asc" ? "desc" : "asc",
                  sortclass: c,
                });
                return (
                  <th key={c} scope="col" className="matrix-col-head">
                    <a href={href} title={`Order by ${c} band. ${BAND_SORT_LIMITATION}`}>
                      <span className="voice-mono">{CLASS_TAG[c]}</span>
                      <span className="sr-only"> — {c}, order by band</span>
                    </a>
                  </th>
                );
              })}
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.entity_id}>
                <th scope="row" className="voice-mono col-ref">
                  <a href={props.hrefFor(row)}>{row.ref}</a>
                </th>
                <td className="col-name">
                  <a href={props.hrefFor(row)}>{row.canonical_name}</a>
                  {row.aliases.length > 0 ? (
                    <span className="aliases t-micro">
                      {" "}
                      {row.aliases.slice(0, 2).join(" · ")}
                      {row.aliases.length > 2 ? ` · +${row.aliases.length - 2}` : ""}
                    </span>
                  ) : null}
                </td>
                <td>{row.jurisdiction}</td>
                <td className="voice-mono">{row.typology ?? "—"}</td>
                <td className="voice-mono">{row.locate_precision}</td>
                {PROPOSITION_CLASS_ORDER.map((c) => (
                  <MatrixCell key={c} badges={row.matrix[c] ?? []} row={row} props={props} />
                ))}
                <td className="voice-mono">
                  {row.sci === null ? "—" : row.sci.toFixed(3)}
                </td>
                <td className="voice-mono">{row.last_moved ?? "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {rows.length === 0 ? props.emptyBlock ?? null : null}
    </>
  );
}

/** The sort keys, re-exported so a page can validate a URL parameter without
 *  importing two modules. */
export { SORT_KEYS };
