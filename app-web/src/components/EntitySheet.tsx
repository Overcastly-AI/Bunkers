/**
 * THE ENTRY SHEET — DESIGN.md §13.2.
 *
 * "Section order is fixed by `GRADING.md` §10.1 AND IS NOT REORDERED."
 *
 *   §0 HEAD · §1 IDENTITY · §2 DISPOSITION · §3 PROPOSITIONS · §4 DETAIL ·
 *   §5 ALTERNATIVES · §6 LINEAGE · §7 APPARATUS · §8 SILENCE · §9 SEARCH LOG ·
 *   §10 MOVEMENT · §11 NOTES · §12 CITE THIS · §13 MACHINE
 *
 * THE ENTITY HAS NO GRADE RENDERING OF ANY KIND, anywhere on this sheet: not a
 * number, not a badge, not a ring, not a sort key, not a colour, not a
 * headline letter. `core.entity` carries nothing graded, so there is no visual
 * slot into which a composite could later be inserted. §3 is the lead and §3 is
 * N marks, never one — "THE DECOMPOSITION IS THE PRODUCT."
 *
 * §2 is the safety net for the stave's learning cost: a deterministically
 * composed sentence, in prose, because PROSE CANNOT BE COLLAPSED INTO A NUMBER.
 *
 * An F-grade or refuted entity renders at FULL INK throughout. There is no
 * muted ground, no error iconography and no warning glyph anywhere below —
 * "an F entry with documented origin work is a contribution."
 */

import { LineageSpine, StemmaticsGloss } from "./LineageSpine";
import { PropositionBlock } from "./PropositionBlock";
import { ReceiptList } from "./Receipts";
import { GradeLetterWord, StaveFull } from "./Stave";
import { StepChart } from "./StepChart";
import type {
  CandidateDetail,
  GradeEvent,
  LineageProfile,
  PropositionDetail,
  SilenceRow,
} from "../lib/types/api";
import { isClampExempt } from "../lib/types/enums";
import { scopeAndContent } from "../lib/types/grade";
import { propositionRefs } from "../lib/refs";

export interface EntitySheetProps {
  detail: CandidateDetail;
  lineage: Record<string, LineageProfile>;
  silence: Record<string, SilenceRow[]>;
  movement: Record<string, GradeEvent[]>;
  /** Verification debt, keyed by proposition_id, where the source carries it. */
  debt?: Record<string, { leads: number; max_reachable: string }>;
  /** Specimen containment mechanism 5 — into every stave label on the page. */
  ariaPrefix?: string;
  /** The canonical URL of this sheet, for §12. */
  selfHref: string;
  /** Specimens are cited AS SPECIMENS and emit no provenance beacon. */
  specimen?: boolean;
  notes?: readonly string[];
  /**
   * The heading level for §0 HEAD. Defaults to 1, because on `/e/[slug]` this
   * sheet IS the page and §3 allows the page title "once per page".
   *
   * A specimen sheet nests this component beneath the calibration case's own
   * title, so the case page passes 2. Two `<h1>`s on one page give a screen
   * reader two competing page titles and break the document outline the ref
   * codes and section numbers otherwise establish — on the one page where the
   * containment marker most needs to be the thing announced first.
   */
  headingLevel?: 1 | 2;
}

function SectionHead({ n, title, id }: { n: string; title: string; id: string }) {
  return (
    <>
      <div className="doc-ref">{n}</div>
      <div className="doc-text">
        <h2 className="section-head" id={id}>
          {title}
        </h2>
      </div>
    </>
  );
}

export function EntitySheet(props: EntitySheetProps) {
  const { detail } = props;
  const e = detail.entity;
  const props_ = detail.propositions;
  const refs = propositionRefs(props_);

  const clamped = props_.filter((p) => !isClampExempt(p.class));
  const unclamped = props_.filter((p) => isClampExempt(p.class));

  const scope = scopeAndContent(
    props_.map((p) => ({ grade: p.grade, statement_text: p.statement_text })),
  );

  const allEvents = Object.values(props.movement).flat();
  const lastMoved =
    allEvents.length > 0
      ? allEvents.map((x) => x.occurred_at).sort().slice(-1)[0]!.slice(0, 10)
      : null;
  const hash =
    props_.map((p) => p.evidence_state_hash).find((h) => h !== null) ?? null;

  return (
    <div className="doc entity-sheet">
      {/* ---------------- §0 HEAD ---------------- */}
      <div className="doc-ref">§0</div>
      <div className="doc-wide entity-head">
        {props.headingLevel === 2 ? (
          <h2 className="entity-title">{e.name}</h2>
        ) : (
          <h1 className="entity-title">{e.name}</h1>
        )}
        {e.aliases && e.aliases.length > 0 ? (
          <p className="voice-mono t-small entity-aliases">
            aliases: {e.aliases.join(" · ")}
          </p>
        ) : null}
      </div>

      {/* ---------------- §1 IDENTITY ---------------- */}
      <SectionHead n="§1" title="Identity" id="identity" />
      <div className="doc-text">
        <dl className="dl">
          <dt>entity_id</dt>
          <dd>{e.entity_id}</dd>
          <dt>slug</dt>
          <dd>{e.slug}</dd>
          <dt>jurisdiction / country</dt>
          <dd>{e.country}</dd>
          <dt>entity_level</dt>
          <dd>{e.entity_level}</dd>
          <dt>typology</dt>
          <dd>{e.typology ?? "—"}</dd>
          <dt>locate_precision</dt>
          <dd>{e.locate_precision}</dd>
          <dt>representation</dt>
          <dd>{e.representation}</dd>
          <dt>reference class</dt>
          <dd>{e.reference_class ?? "—"}</dd>
          <dt>propositions</dt>
          <dd>{props_.length}</dd>
          <dt>grade events</dt>
          <dd>{allEvents.length}</dd>
          <dt>last moved</dt>
          <dd>{lastMoved ?? "—"}</dd>
          <dt>provenance beacon</dt>
          <dd>
            {props.specimen
              ? "none — specimen"
              : (detail.provenance_beacon?.rubric ?? "not emitted")}
          </dd>
        </dl>

        {/* A map cannot show what has no coordinates, and the honest answer is
            to say so in the sheet rather than to render a centre nobody
            asserted. NO PIN EXISTS IN THIS CODEBASE. */}
        {e.suppression_reason ? (
          <p className="t-small entity-suppression">
            <span className="voice-mono t-micro">geometry</span> {e.suppression_reason}
            {e.claimed_place_name ? (
              <>
                {" "}
                The claim names a place and not a position:{" "}
                <span className="voice-serif">&ldquo;{e.claimed_place_name}&rdquo;</span>
              </>
            ) : null}
          </p>
        ) : null}

        {e.distinct_from && e.distinct_from.length > 0 ? (
          <div className="flag-block t-small">
            <span className="t-micro">distinct from</span>
            <ul>
              {e.distinct_from.map((d) => (
                <li key={d.entity_id}>
                  {d.name}
                  {d.note ? ` — ${d.note}` : ""}
                </li>
              ))}
            </ul>
          </div>
        ) : null}
      </div>
      <div className="doc-margin">
        <span className="t-micro">[doc]</span> Identity fields are columns of{" "}
        <span className="voice-mono">core.entity</span>. None of them is graded, and none of them
        is derived from the propositions below.
      </div>

      {/* ---------------- §2 DISPOSITION ---------------- */}
      <SectionHead n="§2" title="Scope and content" id="disposition" />
      <div className="doc-text">
        <p className="t-lede scope-sentence">
          <em>{scope}</em>
        </p>
      </div>
      <div className="doc-margin">
        <span className="t-micro">[inf]</span> Composed deterministically from the band of each
        proposition below. It is prose, and prose cannot be collapsed into a number — which is
        exactly why it is permitted to span propositions where a composite grade is not. It
        asserts nothing the rows do not each say.
      </div>

      {/* ---------------- §3 PROPOSITIONS ---------------- */}
      <SectionHead n="§3" title="Propositions" id="propositions" />
      <div className="doc-wide stave-column">
        {clamped.map((p) => (
          <StaveRow key={p.proposition_id} p={p} refCode={refs.get(p.proposition_id)!} ariaPrefix={props.ariaPrefix} />
        ))}

        {unclamped.length > 0 ? (
          <>
            {/* The labelled rule. An A-grade fact about a fabrication and a
                refuted facility sit on one page without either lying about the
                other. */}
            <div className="unclamped-rule t-micro">
              Unclamped — these do not describe the structure
            </div>
            {unclamped.map((p) => (
              <StaveRow
                key={p.proposition_id}
                p={p}
                refCode={refs.get(p.proposition_id)!}
                ariaPrefix={props.ariaPrefix}
              />
            ))}
          </>
        ) : null}

        <p className="t-small stave-column-note">
          {props_.length} propositions, {props_.length} marks. This entity has no grade of its own
          and no slot for one: <span className="voice-mono">core.entity</span> carries nothing
          graded. Reading down this column is the product.
        </p>
      </div>

      {/* ---------------- §4 DETAIL ---------------- */}
      <SectionHead n="§4" title="Detail" id="detail" />
      <div className="doc-wide">
        {props_.map((p) => (
          <PropositionBlock
            key={p.proposition_id}
            proposition={p}
            refCode={refs.get(p.proposition_id)!}
            ariaPrefix={props.ariaPrefix}
            debtCeiling={props.debt?.[p.proposition_id] ?? null}
            collapseDelta={props.lineage[p.proposition_id]?.collapse_delta ?? null}
          />
        ))}
      </div>

      {/* ---------------- §5 ALTERNATIVES ---------------- */}
      <SectionHead n="§5" title="Alternatives" id="alternatives" />
      <div className="doc-wide">
        <AlternativesTable propositions={props_} refs={refs} />
      </div>
      <div className="doc-margin">
        <span className="t-micro">[doc]</span> An observation contributes in proportion to its
        power to discriminate the proposition from the <em>named</em> alternative, so there is
        always a named alternative. An unnamed null is a visible cap (CAP-7), never a silence.
      </div>

      {/* ---------------- §6 LINEAGE ---------------- */}
      <SectionHead n="§6" title="Lineage" id="lineage" />
      <div className="doc-wide">
        {props_.some((p) => props.lineage[p.proposition_id]) ? (
          props_.map((p) => {
            const l = props.lineage[p.proposition_id];
            if (!l) return null;
            return (
              <div key={p.proposition_id} className="lineage-for-prop">
                <h3 className="t-h3">
                  <span className="voice-mono">{refs.get(p.proposition_id)}</span> {p.class}
                </h3>
                <LineageSpine profile={l} />
              </div>
            );
          })
        ) : (
          <p className="t-small">
            No descent has been traced on this entity. That is the absence of a trace, not a
            finding of independence.
          </p>
        )}
      </div>
      <div className="doc-margin">
        <StemmaticsGloss />
      </div>

      {/* ---------------- §7 APPARATUS ---------------- */}
      <SectionHead n="§7" title="Apparatus" id="apparatus" />
      <div className="doc-wide">
        {props_.map((p) => (
          <section key={p.proposition_id} className="apparatus-for-prop">
            <h3 className="t-h3">
              <span className="voice-mono">{refs.get(p.proposition_id)}</span> {p.class}{" "}
              <GradeLetterWord grade={p.grade} atCeiling={p.at_ceiling} ceiling={p.ceiling} />
            </h3>
            <ReceiptList rows={p.evidence} />
          </section>
        ))}
      </div>

      {/* ---------------- §8 SILENCE ---------------- */}
      <SectionHead n="§8" title="Silence" id="silence" />
      <div className="doc-wide">
        {props_.map((p) => {
          const rows = props.silence[p.proposition_id] ?? [];
          if (rows.length === 0) return null;
          return (
            <SilenceTable
              key={p.proposition_id}
              rows={rows}
              caption={`${refs.get(p.proposition_id)} ${p.class} — expected record profiles`}
            />
          );
        })}
        {props_.every((p) => (props.silence[p.proposition_id] ?? []).length === 0) ? (
          <p className="t-small">
            No expected-record profile has been resolved against this entity. An unresolved profile
            prints no zero, because a zero is a claim.
          </p>
        ) : null}
      </div>

      {/* ---------------- §9 SEARCH LOG ---------------- */}
      <SectionHead n="§9" title="Search log" id="search-log" />
      <div className="doc-wide">
        <SearchLog propositions={props_} refs={refs} />
      </div>
      <div className="doc-margin">
        <span className="t-micro">[doc]</span> Long and boring, and it should be: it is the
        evidence for the argument from silence and the SCI denominator made auditable.
      </div>

      {/* ---------------- §10 MOVEMENT ---------------- */}
      <SectionHead n="§10" title="Movement" id="movement" />
      <div className="doc-wide">
        {props_.map((p) => {
          const ev = props.movement[p.proposition_id] ?? [];
          if (ev.length === 0) return null;
          return (
            <div key={p.proposition_id} className="movement-for-prop">
              <h3 className="t-h3">
                <span className="voice-mono">{refs.get(p.proposition_id)}</span> {p.class}
              </h3>
              <StepChart events={ev} />
            </div>
          );
        })}
        {props_.every((p) => (props.movement[p.proposition_id] ?? []).length === 0) ? (
          <p className="t-small">No grade event is recorded on this entity.</p>
        ) : null}
      </div>

      {/* ---------------- §11 NOTES ---------------- */}
      <SectionHead n="§11" title="Notes" id="notes" />
      <div className="doc-text">
        {props.notes && props.notes.length > 0 ? (
          <ul className="t-small">
            {props.notes.map((nte, i) => (
              <li key={i}>{nte}</li>
            ))}
          </ul>
        ) : (
          <p className="t-small">No editorial note is attached to this sheet.</p>
        )}
      </div>

      {/* ---------------- §12 CITE THIS ---------------- */}
      <SectionHead n="§12" title="Cite this" id="cite" />
      <div className="doc-text">
        <p className="voice-mono t-small citation">
          BUNKERS Register. &ldquo;{e.name}.&rdquo;{" "}
          {props.specimen ? "Calibration specimen" : "Entry"} {e.slug}, BES v0.2
          {hash ? `; evidence state ${hash}` : "; evidence state not yet stamped"}.{" "}
          {props.selfHref}
        </p>
        <p className="t-small">
          {props.specimen ? (
            <>
              This sheet is a <strong>specimen</strong>. It is an expected value under BES v0.2, not
              a register entry, and it emits no provenance beacon. Citing it as a finding about a
              facility would be a category error the register cannot correct on your behalf.
            </>
          ) : (
            <>
              A versioned grade is only citable at a point in time, which is why the evidence state
              hash is part of the citation and not a footnote to it.
            </>
          )}
        </p>
      </div>

      {/* ---------------- §13 MACHINE ---------------- */}
      <SectionHead n="§13" title="Machine-readable" id="machine" />
      <div className="doc-text">
        <p className="t-small">
          Every value on this sheet is a column of the <span className="voice-mono">api.*</span>{" "}
          views described at <a href="/api">/api</a>. Nothing rendered above was derived by
          averaging, aggregating, interpolating or summarising across rows.
        </p>
        <dl className="dl">
          <dt>propositions</dt>
          <dd>{props_.length}</dd>
          <dt>observations</dt>
          <dd>{props_.reduce((a, p) => a + p.evidence.length, 0)}</dd>
          <dt>evidence state hash</dt>
          <dd>{hash ?? "—"}</dd>
        </dl>
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ *
 * §3 — one row of the stave column
 * ------------------------------------------------------------------ */

function StaveRow({
  p,
  refCode,
  ariaPrefix,
}: {
  p: PropositionDetail;
  refCode: string;
  ariaPrefix?: string;
}) {
  return (
    <div className="stave-row">
      <a className="voice-mono stave-row-ref" href={`#${refCode}`}>
        {refCode}
      </a>
      <div className="stave-row-mark">
        <StaveFull badge={p} evidence={p.evidence} ariaPrefix={ariaPrefix} />
      </div>
      {/* A stave is never the sole rendering of a grade on a detail page. */}
      <GradeLetterWord grade={p.grade} atCeiling={p.at_ceiling} ceiling={p.ceiling} />
      <span className="stave-row-statement t-small">
        <em>{p.statement_text}</em>
      </span>
    </div>
  );
}

/* ------------------------------------------------------------------ *
 * §5 — the alternative-hypothesis disposition table
 * ------------------------------------------------------------------ */

function AlternativesTable({
  propositions,
  refs,
}: {
  propositions: readonly PropositionDetail[];
  refs: Map<string, string>;
}) {
  const rows = propositions.flatMap((p) =>
    p.alternatives.map((a) => ({ p, a })),
  );
  if (rows.length === 0) {
    return (
      <p className="t-small">
        No alternative has been dispositioned on this entity beyond the named null carried on each
        proposition.
      </p>
    );
  }
  return (
    <div className="scroll-region" role="region" aria-label="Alternative hypotheses" tabIndex={0}>
      <table>
        <caption className="t-small">
          Alternative hypotheses and their disposition. A proposition is only as strong as its
          power to discriminate against these.
        </caption>
        <thead>
          <tr>
            <th scope="col">Proposition</th>
            <th scope="col">Code</th>
            <th scope="col">Alternative</th>
            <th scope="col">Disposition</th>
            <th scope="col">Reasoning</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(({ p, a }, i) => (
            <tr key={`${p.proposition_id}-${a.null_code}-${i}`}>
              <th scope="row" className="voice-mono">
                <a href={`#${refs.get(p.proposition_id)}`}>{refs.get(p.proposition_id)}</a>
              </th>
              <td className="voice-mono">{a.null_code}</td>
              <td>
                <em>{a.label}</em>
                {a.description ? <div className="t-small">{a.description}</div> : null}
              </td>
              <td className="voice-mono">{a.disposition}</td>
              <td className="t-small">{a.reasoning ?? "—"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

/* ------------------------------------------------------------------ *
 * §8 — the silence table
 * ------------------------------------------------------------------ */

export function SilenceTable({
  rows,
  caption,
}: {
  rows: readonly SilenceRow[];
  caption: string;
}) {
  return (
    <div className="scroll-region" role="region" aria-label={caption} tabIndex={0}>
      <table className="silence-table">
        <caption className="t-small">{caption}</caption>
        <thead>
          <tr>
            <th scope="col">Record class</th>
            <th scope="col">Expected (X)</th>
            <th scope="col">Searched</th>
            <th scope="col">Result</th>
            <th scope="col">Receipt</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={`${r.record_class}-${i}`}>
              <th scope="row">{r.record_class}</th>
              <td className="voice-mono">{r.expected_record_level}</td>
              <td className="voice-mono">{r.searched ? "yes" : "— not searched"}</td>
              {/* An unsearched class prints NO ZERO, because a zero is a claim. */}
              <td className="voice-mono">
                {r.searched ? `${r.outcome ?? "—"} ${r.result_count ?? 0}` : "—"}
              </td>
              <td className="voice-mono t-micro">
                {r.receipt ?? "—"}
                {r.egress_state ? ` · egress ${r.egress_state}` : ""}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {rows.some((r) => r.prose) ? (
        <ul className="silence-prose t-small">
          {rows
            .filter((r) => r.prose)
            .map((r, i) => (
              <li key={i}>
                <span className="voice-mono t-micro">{r.record_class}</span> {r.prose}
              </li>
            ))}
        </ul>
      ) : null}
    </div>
  );
}

/* ------------------------------------------------------------------ *
 * §9 — the search log
 * ------------------------------------------------------------------ */

function SearchLog({
  propositions,
  refs,
}: {
  propositions: readonly PropositionDetail[];
  refs: Map<string, string>;
}) {
  const rows = propositions.flatMap((p) =>
    p.search_receipts.map((s) => ({ p, s })),
  );
  if (rows.length === 0) {
    return (
      <p className="t-small">
        No corpus has been queried against this entity. NEGATIVE and UNSEARCHED are never
        conflated: this is UNSEARCHED.
      </p>
    );
  }
  return (
    <div className="scroll-region" role="region" aria-label="Search log" tabIndex={0}>
      <table className="search-log">
        <thead>
          <tr>
            <th scope="col">Proposition</th>
            <th scope="col">Query</th>
            <th scope="col">Corpus as of</th>
            <th scope="col">Outcome</th>
            <th scope="col">Results</th>
            <th scope="col">Egress</th>
          </tr>
        </thead>
        <tbody>
          {rows.map(({ p, s }, i) => (
            <tr key={i}>
              <th scope="row" className="voice-mono">
                {refs.get(p.proposition_id)}
              </th>
              <td className="voice-mono">{s.query}</td>
              <td className="voice-mono">{s.corpus_as_of ?? "—"}</td>
              <td className="voice-mono">{s.outcome}</td>
              <td className="voice-mono">
                {s.outcome === "UNSEARCHED" ? "—" : (s.result_count ?? 0)}
              </td>
              <td className="voice-mono t-micro">{s.egress_state ?? "UNPROBED"}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
