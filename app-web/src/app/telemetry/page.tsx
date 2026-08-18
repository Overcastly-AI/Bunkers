import type { Metadata } from "next";

import { Block, SectionHead, Tag } from "@/components/Doc";
import { getRepository } from "@/lib/repository";

export const metadata: Metadata = {
  title: "Telemetry — the register about itself · BUNKERS",
  description:
    "The register's own measurements: confabulation rate, band occupancy against its own expectations, refutation rate, and per-host egress.",
};

/**
 * `/telemetry` — THE REGISTER ABOUT ITSELF.
 *
 * DESIGN.md §13.5: "TABLES, NOT DASHBOARDS. Linked from the contents line AT THE
 * SAME LEVEL AS THE REGISTER. Band occupancy printed BESIDE ITS OWN
 * EXPECTATION… A REGISTER THAT PRINTS ITS OWN FAILING TEST IS THE ENTIRE THESIS
 * IN ONE ROW."
 *
 * The expectation-beside-observation device is the whole page. An observed value
 * on its own is a number a reader cannot evaluate; the same number beside the
 * value the register said in advance it should have is a test result. At zero
 * candidates every observation is "no data" — and the expectations are printed
 * anyway, because an expectation published before the data is the only kind that
 * can be failed honestly.
 *
 * §16 is binding on the verdict column: state is carried by WORD + GLYPH, never
 * by colour. `✓` and `✗` each print beside their word.
 */

/** A published expectation. `observed === null` means no data yet — which is a
 *  state, not a pass and not a failure. */
interface Expectation {
  expectation: string;
  observed: string | null;
  /** Null while there is nothing to test. */
  verdict: "pass" | "fail" | null;
  note?: string;
}

export default async function TelemetryPage() {
  const repo = getRepository();
  const state = await repo.getRegisterState();
  const confab = await repo.getConfabulation();
  const occupancy = await repo.getBandOccupancy();
  const refutation = await repo.getRefutationTelemetry();
  const corpora = await repo.listCorpora();

  const graded = refutation.graded;

  /**
   * The expectations, published whether or not they can be tested. Every one of
   * these is a claim the grading model made about its own output BEFORE any
   * output existed.
   */
  const expectations: Expectation[] = [
    {
      expectation: "Modal band should be X or D",
      observed: occupancy.length === 0 ? null : null,
      verdict: null,
      note: "An honestly mostly-X register is the designed outcome, not a failure state.",
    },
    {
      expectation: "C-band occupancy ≤ 15%",
      observed: null,
      verdict: null,
      note: "Above this, the diagnosticity catalog may be leaking — signals scoring as discriminating when they are not.",
    },
    {
      expectation: "Measured confabulation rate is published, whatever it is",
      observed:
        state.measured_confabulation_rate === null
          ? null
          : String(state.measured_confabulation_rate),
      verdict: null,
      note: "Unresolvable identifiers over identifiers emitted. Not an error rate to be minimised out of sight — a measurement to be published.",
    },
    {
      expectation: "R reversals stay rare",
      observed: graded === 0 ? null : `${refutation.reversed} of ${refutation.refuted}`,
      verdict: null,
      note: "A refutation that is later reversed means the refutation gate admitted something it should not have.",
    },
    {
      expectation: "No published grade rests on unverified evidence",
      observed: state.candidates_published === 0 ? "0 published grades" : null,
      verdict: state.candidates_published === 0 ? "pass" : null,
      note: "Trivially satisfied at zero candidates, and stated anyway so the row exists before it is load-bearing.",
    },
  ];

  return (
    <div className="doc">
      <Block
        code="§0"
        margin={
          <>
            <Tag k="doc" /> Specimen sheets are excluded from every figure on this page.
            Calibration fixtures are not register output.
          </>
        }
      >
        <h1>Telemetry</h1>

        <div className="rule-block t-lede">
          The register&rsquo;s measurements of itself, printed beside the expectations it
          published in advance. A register that prints its own failing test is more
          credible than one that implies none.
        </div>

        <p>
          Every figure below is currently zero or absent, and each is shown with the
          expectation it will eventually be tested against. That ordering is deliberate:{" "}
          <strong>an expectation published before the data is the only kind that can be
          failed honestly.</strong> None of these numbers includes the calibration
          specimens, which are fixtures and are excluded by construction rather than by
          filter.
        </p>
      </Block>

      {/* ==================================================================
          §1 — EXPECTATIONS BESIDE OBSERVATIONS.
          ================================================================== */}

      <SectionHead
        code="§1"
        id="expectations"
        title="Expectations and observations"
        margin={
          <>
            <Tag k="doc" /> Verdict is carried by word and glyph, never by colour. A dash is
            neither a pass nor a failure.
          </>
        }
      />

      <Block code="§1.1" wide>
        {expectations.map((e, i) => (
          <div className="expectation" key={i}>
            <div>
              {e.expectation}
              {e.note ? (
                <div className="t-small" style={{ color: "var(--ink-2)" }}>
                  {e.note}
                </div>
              ) : null}
            </div>
            <div className="expectation-mark voice-mono">
              {e.verdict === "pass" ? "✓" : e.verdict === "fail" ? "✗" : "—"}
            </div>
            <div className="expectation-word">
              {e.verdict === "pass"
                ? "pass"
                : e.verdict === "fail"
                  ? "fail"
                  : e.observed
                    ? `observed ${e.observed}`
                    : "no data"}
            </div>
          </div>
        ))}
        <p className="t-small legend-note" style={{ marginTop: "var(--s-3)" }}>
          &ldquo;No data&rdquo; is a distinct state from a passing test and is never
          rendered as one. The register does not report an untested expectation as met.
        </p>
      </Block>

      {/* ==================================================================
          §2 — CONFABULATION.
          ================================================================== */}

      <SectionHead
        code="§2"
        id="confabulation"
        title="Measured confabulation"
        margin={
          <>
            <Tag k="doc" /> An identifier that does not resolve is counted as measured
            fabrication and retained as a <span className="voice-mono">V0</span> row on the
            entry that cited it.
          </>
        }
      />

      <Block code="§2.1" wide>
        <p>
          Each agent that writes into the register is measured on one thing: of the
          identifiers it emitted, how many resolved to bytes at the issuing authority. This
          is the register&rsquo;s own fabrication metric, and it is published per agent
          rather than as a single site-wide figure so a single bad producer cannot be
          averaged out of view.
        </p>

        {confab.length === 0 ? (
          <div className="empty-block">
            <p style={{ fontWeight: 600 }}>No grading run has completed.</p>
            <p style={{ marginBottom: 0 }}>
              The rate is <span className="voice-mono">—</span>, not{" "}
              <span className="voice-mono">0</span>. A zero here would be a claim that
              nothing was fabricated; the truth is that nothing has been measured.{" "}
              <strong>An unmeasured rate is not a clean one.</strong>
            </p>
          </div>
        ) : (
          <div
            className="scroll-region"
            role="region"
            aria-label="Confabulation by agent"
            tabIndex={0}
          >
            <table>
              <thead>
                <tr>
                  <th scope="col">Agent</th>
                  <th scope="col">Emitted</th>
                  <th scope="col">Resolved</th>
                  <th scope="col">Unresolvable rate</th>
                </tr>
              </thead>
              <tbody>
                {confab.map((r) => (
                  <tr key={r.agent}>
                    <th scope="row" className="siglum">
                      {r.agent}
                    </th>
                    <td className="voice-mono">{r.identifiers_emitted ?? "—"}</td>
                    <td className="voice-mono">{r.identifiers_resolved ?? "—"}</td>
                    <td className="voice-mono">{r.unresolvable_rate ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Block>

      {/* ==================================================================
          §3 — BAND OCCUPANCY.
          ================================================================== */}

      <SectionHead
        code="§3"
        id="occupancy"
        title="Band occupancy"
        margin={
          <>
            <Tag k="doc" /> <a href="/limits#L-11">L-11</a> — the pressure to make this
            distribution look better will come from the maintainer.
          </>
        }
      />

      <Block code="§3.1" wide>
        <p>
          How many propositions sit in each band, per proposition class, against the
          distribution the model said in advance it should produce. The modal entry is
          expected to be <span className="voice-mono">X</span> or{" "}
          <span className="voice-mono">D</span>.
        </p>

        {occupancy.length === 0 ? (
          <div className="empty-block">
            <p style={{ fontWeight: 600 }}>
              {state.propositions_graded} propositions graded.
            </p>
            <p style={{ marginBottom: 0 }}>
              Modal band should be <span className="voice-mono">X</span> or{" "}
              <span className="voice-mono">D</span> — observed: no data. The expectation is
              printed with nothing beside it on purpose. When this table fills, a
              C-band share above 15% is a signal that the diagnosticity catalog is leaking,
              and it will be printed here as a failing row rather than investigated
              privately.
            </p>
          </div>
        ) : (
          <div
            className="scroll-region"
            role="region"
            aria-label="Band occupancy by class"
            tabIndex={0}
          >
            <table>
              <thead>
                <tr>
                  <th scope="col">Class</th>
                  <th scope="col">Band</th>
                  <th scope="col">n</th>
                  <th scope="col">%</th>
                </tr>
              </thead>
              <tbody>
                {occupancy.map((r, i) => (
                  <tr key={`${r.class}-${r.grade}-${i}`}>
                    <th scope="row" className="voice-mono">
                      {r.class}
                    </th>
                    <td className="voice-mono">{r.grade}</td>
                    <td className="voice-mono">{r.n}</td>
                    <td className="voice-mono">{r.pct ?? "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Block>

      {/* ==================================================================
          §4 — REFUTATION.
          ================================================================== */}

      <SectionHead code="§4" id="refutation" title="Refutation" />

      <Block
        code="§4.1"
        wide
        margin={
          <>
            <Tag k="doc" /> <span className="voice-mono">R</span> is unranked. It is not a
            low grade; it is a different epistemic object.
          </>
        }
      >
        <dl className="dl">
          <dt>propositions graded</dt>
          <dd>{refutation.graded}</dd>
          <dt>propositions at R</dt>
          <dd>{refutation.refuted}</dd>
          <dt>R reached by refutation-of-record only</dt>
          <dd>{refutation.r2_only}</dd>
          <dt>R reversals</dt>
          <dd>{refutation.reversed}</dd>
          <dt>R rate</dt>
          <dd>{graded === 0 ? "— empty denominator" : `${refutation.refuted} / ${graded}`}</dd>
          <dt>R reversal rate</dt>
          <dd>
            {refutation.refuted === 0
              ? "— empty denominator"
              : `${refutation.reversed} / ${refutation.refuted}`}
          </dd>
        </dl>
        <p className="t-small legend-note" style={{ marginTop: "var(--s-3)" }}>
          A rate on an empty denominator prints as a dash and never as{" "}
          <span className="voice-mono">0%</span>. Reversals are watched because a refutation
          later withdrawn means the refutation gate admitted something it should not have —
          and refutation is the one band that is not withheld for incomplete search.
        </p>
      </Block>

      {/* ==================================================================
          §5 — EGRESS. The live state of the access schedule.
          ================================================================== */}

      <SectionHead
        code="§5"
        id="egress"
        title="Egress and robots posture"
        margin={
          <>
            <Tag k="doc" /> D-007. Full witness key at <a href="/sources">/sources</a>.
          </>
        }
      />

      <Block code="§5.1" wide>
        <dl className="dl">
          <dt>hosts in the access schedule</dt>
          <dd>{state.hosts_in_access_schedule}</dd>
          <dt>hosts reachable</dt>
          <dd>{state.hosts_reachable}</dd>
          <dt>hosts transcribed into the published registry</dt>
          <dd>{corpora.length}</dd>
          <dt>sources catalogued</dt>
          <dd>{state.sources_catalogued}</dd>
          <dt>documents in the citation graph</dt>
          <dd>{state.documents_in_citation_graph}</dd>
        </dl>

        <div className="flag-block" style={{ marginTop: "var(--s-4)" }}>
          <div className="flag-head">Egress state</div>
          <p style={{ marginBottom: 0 }}>
            Outbound egress is denied in full. Every host in the schedule is{" "}
            <span className="voice-mono">UNPROBED</span>, and robots posture is recorded as{" "}
            <em>unverified — strictest reading binding</em> until a probe proves otherwise.
            The register does not assume access it has not demonstrated, and it does not
            record an unprobed host as permitted.
          </p>
        </div>
      </Block>

      {/* ==================================================================
          §6 — SEARCH COMPLETENESS AND VERIFICATION DEBT.
          ================================================================== */}

      <SectionHead code="§6" id="debt" title="Completeness and verification debt" />

      <Block
        code="§6.1"
        wide
        margin={
          <>
            <Tag k="doc" /> <a href="/limits#L-6">L-6</a> — debt at the bottom of the
            register never clears, and that is harmful for refutation rather than for
            grading.
          </>
        }
      >
        <dl className="dl">
          <dt>search completeness distribution</dt>
          <dd>— no proposition has been graded</dd>
          <dt>propositions below the completeness floor (published as X)</dt>
          <dd>0</dd>
          <dt>unverified leads outstanding</dt>
          <dd>0</dd>
          <dt>propositions at ceiling</dt>
          <dd>0</dd>
        </dl>
        <p className="t-small legend-note" style={{ marginTop: "var(--s-3)" }}>
          Verification debt is the count of leads that have not been resolved, together with
          the band each proposition could reach if all of them did. It is drawn on every
          stave as an outline square inside the unreached span:{" "}
          <strong>filled is now, outline is if the debt clears, and the bar is the
          structural limit.</strong> A reader sees what the register does not yet know,
          quantified in rows.
        </p>
      </Block>
    </div>
  );
}
