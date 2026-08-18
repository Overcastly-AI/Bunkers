/**
 * THE RECEIPT LIST — DESIGN.md §10.2, the evidence row.
 *
 * Every observation is one row. The rules, and every one of them is checkable:
 *
 *  MEMBERSHIP SET IS THE FIRST TOKEN, in a fixed 3-character cell, so a column
 *  of sixty rows can be counted by eye.
 *
 *  `INERT` AND `V0` ROWS RENDER AT THE SAME SIZE AND THE SAME INK AS `V` ROWS,
 *  distinguished by a hatched left margin rule, with the generated
 *  `exclusion_reason` occupying the position the quoted span would occupy.
 *  THEY ARE NEVER GREYED OUT AND NEVER COLLAPSED BY DEFAULT. "Greying is
 *  deletion by other means, and the standing rule is that nothing is deleted."
 *
 *  THE QUOTED SPAN IS THE PAYLOAD and carries the most visual weight on the
 *  page: Serif, indented, with located character offsets in Mono at the right.
 *  Serif has exactly one job on this site and this is it.
 *
 *  `signed_weight` always carries an explicit sign, and UNDERCUTS rows carry
 *  THREE redundant encodings: the `−` glyph, the word UNDERCUTS, and the ochre.
 *
 *  Receipt state is GLYPH + WORD, NEVER COLOUR ALONE, and the three-way
 *  UNRESOLVED split is preserved in the words, "because collapsing them would
 *  let a blocked proxy inflate the register's own published fabrication metric."
 */

import { CopyHash } from "./CopyHash";
import type { EvidenceRow } from "../lib/types/api";
import type { ReceiptState } from "../lib/types/enums";

const RECEIPT_MARK: Record<ReceiptState, { glyph: string; word: string }> = {
  VERIFIED: { glyph: "✓", word: "VERIFIED" },
  UNRESOLVED: { glyph: "✕", word: "UNRESOLVED" },
  DEAD: { glyph: "†", word: "DEAD" },
  NEGATIVE: { glyph: "−", word: "NEGATIVE" },
};

/** Default order: V by descending magnitude → U → INERT → V0. NOTHING HIDDEN. */
const MEMBERSHIP_ORDER = { V: 0, U: 1, INERT: 2, V0: 3 } as const;

export function sortReceipts(rows: readonly EvidenceRow[]): EvidenceRow[] {
  return [...rows].sort((a, b) => {
    const m = MEMBERSHIP_ORDER[a.membership] - MEMBERSHIP_ORDER[b.membership];
    if (m !== 0) return m;
    if (a.magnitude !== b.magnitude) return b.magnitude - a.magnitude;
    return a.observation_key.localeCompare(b.observation_key, undefined, { numeric: true });
  });
}

function QuotedSpan({ row }: { row: EvidenceRow }) {
  if (row.quoted_text === null) return null;
  return (
    <div className="quoted">
      <blockquote className="voice-serif">{row.quoted_text}</blockquote>
      {row.span_start_offset !== null && row.span_end_offset !== null ? (
        /* The offsets print because they are THE PROOF a deterministic,
           non-LLM locator found the string in the retrieved bytes. */
        <span className="voice-mono t-micro quoted-offsets">
          @ {row.span_start_offset.toLocaleString("en-US")}–
          {row.span_end_offset.toLocaleString("en-US")}
        </span>
      ) : null}
    </div>
  );
}

export function ReceiptRow({ row }: { row: EvidenceRow }) {
  const inert = row.membership === "INERT" || row.membership === "V0";
  const undercuts = row.sign === "UNDERCUTS";
  const receipt = row.receipt_state ? RECEIPT_MARK[row.receipt_state] : null;
  const sign = row.signed_weight > 0 ? "+" : row.signed_weight < 0 ? "−" : "±";

  return (
    <li
      className={`receipt${inert ? " receipt-inert" : ""}${undercuts ? " receipt-undercut" : ""}`}
      id={`e-${row.observation_key}`}
    >
      {/* The hatched left margin rule that marks a retained-but-inert row. It
          marks the row; it does not dim it. Same size, same ink, same weight as
          a counted row — the difference is a margin rule and a printed reason,
          because greying is deletion by other means. */}
      {inert ? (
        <svg
          className="receipt-hatch"
          width="6"
          preserveAspectRatio="none"
          aria-hidden="true"
          focusable="false"
        >
          <rect x="0" y="0" width="6" height="100%" fill="url(#hatch45)" />
        </svg>
      ) : null}

      <div className="receipt-head">
        <span className="voice-mono receipt-key">{row.observation_key}</span>
        <span className="voice-mono receipt-membership">{row.membership}</span>
        <span className="voice-mono receipt-weight">
          {sign}
          {Math.abs(row.signed_weight)}
        </span>
        <span className="voice-mono receipt-d">D{row.magnitude}</span>
        <span className="voice-mono receipt-tier">{row.origin_tier ?? "—"}</span>
        <span className="receipt-title">
          {row.url ? (
            <a href={row.url} rel="nofollow noreferrer">
              {row.identifier ?? row.title ?? "untitled document"}
            </a>
          ) : (
            (row.identifier ?? row.title ?? "no document")
          )}
        </span>
        {receipt ? (
          <span className="voice-mono receipt-state">
            <span aria-hidden="true">{receipt.glyph}</span> {receipt.word}
          </span>
        ) : (
          <span className="voice-mono receipt-state">— no receipt</span>
        )}
      </div>

      <div className="receipt-meta voice-mono t-micro">
        {[
          row.causal_provenance,
          row.scope,
          row.property_locus,
          undercuts ? "UNDERCUTS" : row.sign,
          row.corpus_name,
          row.document_date,
          row.issuer_metadata_match === true
            ? "issuer metadata matched"
            : row.issuer_metadata_match === false
              ? "issuer metadata NOT matched"
              : null,
          row.mirror_only ? "MIRROR-ONLY" : null,
          row.content_drifted ? "CONTENT DRIFTED" : null,
          row.subject_binding_pass ? "binding ✓" : "binding ✕ — demoted to CLASS",
          row.gate_pass ? "D4 gate ✓" : null,
        ]
          .filter(Boolean)
          .join(" · ")}
        {row.sha256 ? (
          <>
            {" · "}
            <CopyHash sha256={row.sha256} />
          </>
        ) : null}
      </div>

      {/* The exclusion reason occupies the position the quoted span would
          occupy. An inert row is a row that was retained and shown, with the
          reason it does not count printed where its evidence would be. */}
      {row.exclusion_reason ? (
        <div className="receipt-exclusion t-small">
          <span className="voice-mono t-micro">exclusion_reason</span> {row.exclusion_reason}
        </div>
      ) : null}

      <QuotedSpan row={row} />

      {row.binding_quote ? (
        <div className="receipt-binding t-small">
          <span className="voice-mono t-micro">subject binding</span>{" "}
          <span className="voice-serif">{row.binding_quote}</span>
        </div>
      ) : null}

      {row.negative_search_query ? (
        <div className="receipt-negative t-small">
          <span className="voice-mono t-micro">negative search</span>{" "}
          <span className="voice-mono">{row.negative_search_query}</span> ·{" "}
          {row.negative_search_result_count === null
            ? "not searched"
            : `${row.negative_search_result_count} results`}
          {row.negative_search_corpus_date
            ? ` · corpus as of ${row.negative_search_corpus_date}`
            : null}
          {row.expected_record_profile
            ? ` · discharges ${row.expected_record_profile} (${row.expected_record_level})`
            : null}
        </div>
      ) : null}

      {row.rebutted ? (
        <div className="flag-block t-small">
          <span className="t-micro">rebutted</span>{" "}
          {row.rebuttal_note ?? "A rebuttal is recorded against this observation."}
        </div>
      ) : null}
    </li>
  );
}

export function ReceiptList({ rows }: { rows: readonly EvidenceRow[] }) {
  const sorted = sortReceipts(rows);
  const counts = {
    V: rows.filter((r) => r.membership === "V").length,
    U: rows.filter((r) => r.membership === "U").length,
    INERT: rows.filter((r) => r.membership === "INERT").length,
    V0: rows.filter((r) => r.membership === "V0").length,
  };

  if (sorted.length === 0) {
    return (
      <p className="t-small">
        No observation has been opened against this proposition. That is an empty set, not a zero:
        nothing has been searched and nothing has been excluded.
      </p>
    );
  }

  return (
    <div className="receipt-block">
      <p className="voice-mono t-micro receipt-counts">
        {sorted.length} rows · V {counts.V} · U {counts.U} · INERT {counts.INERT} · V0 {counts.V0}{" "}
        · nothing hidden, nothing collapsed
      </p>
      <ol className="receipt-list">
        {sorted.map((r) => (
          <ReceiptRow key={r.observation_id} row={r} />
        ))}
      </ol>
    </div>
  );
}
