/**
 * §4 THE PROPOSITION DETAIL BLOCK — DESIGN.md §13.2. FIVE PARTS, EACH MANDATORY.
 *
 * ```
 * p-EXIST-1   EXIST                          [STAVE-FULL]   A  ESTABLISHED  at ceiling
 *             “A substantial artificial enclosed or subsurface structure exists at Raven Rock.”
 *             null: an ordinary Army communications station, or a granite quarry — EXCLUDED
 *             route A1 · V[D4]=2 · L(D3)=5 · L(D2)=5 · |V[claim]|=6 · U=∅ · SCI 6/6 · caps none
 *             limiting_condition: — (at ceiling) · silence INFORMATIVE · base rate UNCOMMON
 *             14 observations · 2 inert · collapse delta 3
 * ```
 *
 * Line 2 is the proposition AS A SENTENCE, Sans italic — "the reader must see a
 * sentence, not a category." Line 3 is the named null and its derived
 * `null_state`; it is always present, because CAP-7 makes an unnamed null a
 * visible cap rather than a silence. Line 4 is the arithmetic that produced the
 * band, in Mono, and EVERY TERM IS A RETURNED VALUE. Line 5 prints
 * `limiting_condition` IN FULL PROSE — §19's fourth reason the one permitted
 * interval is honest: "an error bar whose width has a NAME is a different
 * object from one whose width has a VALUE."
 *
 * A stave is never the sole rendering of a grade here: the letter and the band
 * word print adjacent, always (§7).
 */

import { GradeLetterWord, StaveFull } from "./Stave";
import type { EvidenceRow, PropositionDetail } from "../lib/types/api";
import { capCondition } from "../lib/filter-vocab";
import { SILENCE_WORD } from "../lib/stave/model";

function countD4(rows: readonly EvidenceRow[]): number {
  return rows.filter((r) => r.membership === "V" && r.magnitude === 4).length;
}

/** The route that reached the band, read off `condition_results`. Conditions
 *  that did not fire are printed too — a route is only legible beside the
 *  routes that were tried and failed. */
function routeOf(p: PropositionDetail): { passed: string[]; failed: string[]; untested: string[] } {
  const passed: string[] = [];
  const failed: string[] = [];
  const untested: string[] = [];
  for (const [k, v] of Object.entries(p.condition_results)) {
    if (v === true) passed.push(k);
    else if (v === false) failed.push(k);
    else untested.push(k);
  }
  return { passed, failed, untested };
}

export interface PropositionBlockProps {
  proposition: PropositionDetail;
  refCode: string;
  ariaPrefix?: string;
  /** The band reachable if the outstanding verification debt resolves. */
  debtCeiling?: { leads: number; max_reachable: string } | null;
  collapseDelta?: number | null;
}

export function PropositionBlock({
  proposition: p,
  refCode,
  ariaPrefix,
  debtCeiling,
  collapseDelta,
}: PropositionBlockProps) {
  const route = routeOf(p);
  const v4 = countD4(p.evidence);

  return (
    <article className="prop-block" id={refCode}>
      <header className="prop-head">
        <span className="voice-mono prop-ref">{refCode}</span>
        <span className="voice-mono prop-class">{p.class}</span>
        <span className="prop-stave">
          <StaveFull
            badge={p}
            evidence={p.evidence}
            debtCeiling={(debtCeiling?.max_reachable as never) ?? null}
            ariaPrefix={ariaPrefix}
          />
        </span>
        <GradeLetterWord grade={p.grade} atCeiling={p.at_ceiling} ceiling={p.ceiling} />
      </header>

      {/* Line 2 — the statement, as a sentence. */}
      <p className="prop-statement t-lede">
        <em>{p.statement_text}</em>
      </p>

      {/* Line 3 — the named null and its derived disposition. */}
      <p className="prop-null t-small">
        <span className="voice-mono t-micro">null</span>{" "}
        <em>{p.null_label}</em>{" "}
        <span className="voice-mono">
          ({p.null_code}) — {p.null_state}
        </span>
      </p>

      {/* Line 4 — the arithmetic. Every term is a returned value. */}
      <p className="prop-arithmetic voice-mono t-small">
        {route.passed.length > 0 ? `route ${route.passed.join("+")} · ` : "route none · "}
        V[D4]={v4} · L(D3)={p.l_d3} · L(D2)={p.l_d2} · |V[claim]|={p.v_claim_count} ·{" "}
        {p.u_count === 0 ? "U=∅" : `U=${p.u_count}`} · place-derived weight={p.place_derived_weight}{" "}
        · claim-derived weight={p.claim_derived_weight} · SCI{" "}
        {p.sci_denominator === 0
          ? "∅ (nothing to search — complete)"
          : `${p.sci_numerator}/${p.sci_denominator}`}{" "}
        · caps {p.applied_caps.length === 0 ? "none" : p.applied_caps.join(", ")}
        {route.failed.length > 0 ? ` · failed ${route.failed.join(", ")}` : ""}
      </p>

      {/* Line 5 — limiting_condition IN FULL PROSE. */}
      <p className="prop-limiting t-small">
        <span className="voice-mono t-micro">limiting_condition</span>{" "}
        {p.limiting_condition ?? (p.at_ceiling ? "— at ceiling; nothing is holding this band down." : "—")}
        {" · "}
        <span className="voice-mono t-micro">silence</span> {SILENCE_WORD[p.silence_reading]}
        {p.base_rate_reading ? (
          <>
            {" · "}
            <span className="voice-mono t-micro">base rate</span>{" "}
            <span className="voice-mono">{p.base_rate_reading}</span> — an ordinal reading of
            reference class {p.reference_class ?? "unassigned"}. <strong>Not a probability. It
            did not enter the grade.</strong>
          </>
        ) : null}
      </p>

      {/* Line 6 — the row counts, which are the same rows printed in §7. */}
      <p className="prop-counts voice-mono t-small">
        {p.evidence.length} observations · {p.inert_count + p.v0_count} inert
        {collapseDelta !== null && collapseDelta !== undefined
          ? ` · collapse delta ${collapseDelta}`
          : ""}
        {p.grade_pre_clamp !== p.grade
          ? ` · clamped from ${p.grade_pre_clamp}`
          : ""}
        {p.refutation_state !== "R0" ? ` · refutation_state ${p.refutation_state}` : ""}
      </p>

      {/* Applied caps are LISTED WITH THEIR DEFINITIONS INLINE, not as codes. */}
      {p.applied_caps.length > 0 ? (
        <dl className="prop-caps t-small">
          {p.applied_caps.map((c) => (
            <div key={c}>
              <dt className="voice-mono">{c}</dt>
              <dd>{capCondition(c)}</dd>
            </div>
          ))}
        </dl>
      ) : null}

      {/* §8.7 VERIFICATION DEBT — what the register does not yet know,
          quantified in rows, and the outline square on the ladder above. */}
      {debtCeiling ? (
        <p className="prop-debt voice-mono t-small">
          {p.grade} — VERIFICATION PENDING · {debtCeiling.leads} unverified leads · maximum
          reachable band if all resolve: {debtCeiling.max_reachable}
        </p>
      ) : null}

      {/* `marginal_flag` fires a flagged note, because §18.13 admits BES is
          brittle at band boundaries BY DESIGN and the design amplifies rather
          than softens that. There is no visual gradient at a band boundary. */}
      {p.marginal_flag ? (
        <div className="flag-block t-small">
          One contested fact decided this band. The decision is recorded in the judgement log and
          the band is not smoothed toward its neighbour: BES is brittle at band boundaries by
          design, and the register flags the brittleness rather than blurring it.
        </div>
      ) : null}

      {p.citogenesis ? (
        <div className="flag-block t-small">
          <span className="voice-mono t-micro">⟳ citogenesis confirmed</span> — a document in this
          proposition&rsquo;s citation graph cites a later document that rests on it. The loop is
          closed and counts once, not three times.
        </div>
      ) : null}

      {p.ceiling_reason ? (
        <p className="t-small prop-ceiling-reason">
          <span className="voice-mono t-micro">ceiling</span> {p.ceiling_reason}
        </p>
      ) : null}
    </article>
  );
}
