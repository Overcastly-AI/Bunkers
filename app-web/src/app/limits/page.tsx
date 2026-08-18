import type { Metadata } from "next";

import { Block, SectionHead, Tag } from "@/components/Doc";
import { LIMITATIONS } from "@/lib/limitations";
import { getRepository } from "@/lib/repository";

export const metadata: Metadata = {
  title: "Standing limitations — what this model does not solve · BUNKERS",
  description:
    "The nineteen standing limitations of BES v0.2, published because a register that hides its blind spots is a safe harbour for the fabrications those blind spots admit.",
};

/**
 * `/limits` — STANDING LIMITATIONS. TOP LEVEL, and it stays top level.
 *
 * DESIGN.md §13.4: "GRADING.md §18.11 warns that the pressure to soften this
 * will come from the maintainer, continuously; A PAGE THAT CAN BE DEMOTED INTO A
 * SUBSECTION IS A PAGE THAT WILL BE. Permanent link in the contents line and
 * permanent field in the standing foot."
 *
 * §20 rejects by name: "Burying D-006 in a footer or behind a dismissible
 * banner. Banners get dismissed and read as warnings; footers are where
 * obligations go to be ignored."
 *
 * Beyond Part 18 verbatim, §13.4 requires this page to carry: D-006 in full; the
 * residual shared-prior channels; CAP-4's self-description; the two surviving
 * judgement calls; the R-reversal rate; the live egress state; and §18.19's
 * admission that the specification is itself V0-UNRESOLVED. All seven are below.
 *
 * §21.11 records the deliberate cost: "Publishing /telemetry and /limits at
 * register-level prominence is a reputational cost, taken deliberately. THE
 * FIRST HOSTILE SUMMARY OF THIS SITE WILL QUOTE PART 18, AND THE DESIGN MAKES
 * THAT EASY ON PURPOSE."
 */
export default async function LimitsPage() {
  const repo = getRepository();
  const state = await repo.getRegisterState();
  const refutation = await repo.getRefutationTelemetry();

  return (
    <div className="doc">
      <Block
        code="§0"
        margin={
          <>
            <Tag k="doc" /> <span className="voice-mono">GRADING.md</span> Part 18,
            transcribed. Each clause is addressable: <span className="voice-mono">L-7</span>{" "}
            links to <span className="voice-mono">/limits#L-7</span>.
          </>
        }
      >
        <h1>Standing limitations</h1>

        <div className="rule-block t-lede">
          This is not a list of things to fix later. It is a list of things this design does
          not solve, published because a register that hides its blind spots is a safe
          harbour for the fabrications those blind spots admit.
        </div>

        <p>
          Nineteen clauses follow, transcribed from the grading model&rsquo;s own Part 18
          and numbered so each can be cited on its own. They are linked from the entries
          they affect: a proposition whose grade is held down by one of these carries a
          margin reference to it, so a limitation is apparatus that reaches into the data
          rather than a page nobody visits.
        </p>
        <p className="t-small">
          Four of them are, in the register&rsquo;s own assessment, the load-bearing ones:{" "}
          <a href="#L-3">L-3</a> (the second line of defence is absent),{" "}
          <a href="#L-5">L-5</a> (the published grade distribution is a map of
          digitisation), <a href="#L-11">L-11</a> (the maintainer is the attacker), and{" "}
          <a href="#L-19">L-19</a> (the specification is itself unverified).
        </p>
      </Block>

      {/* ==================================================================
          §1 — D-006 IN FULL. Required by §13.4 to appear on this page, in
          full, in addition to L-3 which is its standing-limitation form.
          ================================================================== */}

      <SectionHead
        code="§1"
        id="verification"
        title="The verification posture, in full"
        margin={
          <>
            <Tag k="doc" /> D-006, ratified 2026-08-17. Also on{" "}
            <a href="/method#verification">/method §2</a>, on <a href="/">the register</a>,
            and in the standing foot of every page.
          </>
        }
      />

      <Block code="D-006" id="D-006">
        <div className="flag-block t-lede">
          <div className="flag-head">Publication obligation</div>
          <p>
            <em>{state.verification_posture}</em>
          </p>
        </div>
        <p>
          The register runs its grading pipeline with one model family. Two families would
          make entailment checking genuinely adversarial, make the two-family agreement
          requirement real, and make double-scoring a measurement rather than a self-check.
          One family collapses all of that.
        </p>
        <p>
          <strong>This decision cannot be retrofitted.</strong> A grade produced under
          single-family verification and one produced under two-family verification are not
          the same object, and there is no honest way to distinguish them after the register
          is populated. It was therefore made before the first grade was written, rather
          than discovered afterwards.
        </p>
        <p>
          The mechanisms that do not depend on model family remain fully in force:
          resolve-or-die, subject binding, the diagnosticity catalog, and the caps. The
          claim that is absent is specifically the one about <em>independent</em>{" "}
          adjudication. Its standing-limitation form is <a href="#L-3">L-3</a>.
        </p>
      </Block>

      {/* ==================================================================
          §2 — PART 18, THE NINETEEN.
          ================================================================== */}

      <SectionHead
        code="§2"
        id="part-18"
        title="What this model does not solve"
        margin={
          <>
            <Tag k="doc" /> Nineteen clauses. The register expects the first hostile summary
            of this site to quote them, and the design makes that easy on purpose.
          </>
        }
      />

      {LIMITATIONS.map((l) => (
        <Block key={l.id} code={l.id} id={l.id}>
          <div className="clause">
            <span className="clause-id">
              {l.id} · Part 18 §{l.clause}
            </span>
            <h3 className="clause-title">{l.title}</h3>
            {l.body}
          </div>
        </Block>
      ))}

      {/* ==================================================================
          §3 — THE RESIDUAL CHANNELS AND THE SURVIVING JUDGEMENT CALLS.
          ================================================================== */}

      <SectionHead
        code="§3"
        id="residual"
        title="Residual channels and surviving judgement"
        margin={
          <>
            <Tag k="doc" /> Required on this page by DESIGN.md §13.4 alongside Part 18
            itself.
          </>
        }
      />

      <Block code="§3.1" id="shared-priors">
        <h3>Residual shared-prior channels</h3>
        <p>
          Independence between witnesses is computed over citation edges, but citation is not
          the only way two sources can fail to be independent. Three channels are known to
          survive the model and are not measured by it:
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>shared training corpora</dt>
            <dd>
              Two model instances reading the same span bring the same priors to it. This is{" "}
              <a href="#L-3">L-3</a>, and with a single family it is not a residual channel
              but the main one.
            </dd>
          </div>
          <div className="defn">
            <dt>common upstream sourcing</dt>
            <dd>
              Two outlets independently reporting from one wire story, one press release or
              one briefing share an origin that no citation edge records. The register
              detects this only where one of them cites it.
            </dd>
          </div>
          <div className="defn">
            <dt>shared distinctive error</dt>
            <dd>
              The one channel the register <em>can</em> catch: an idiosyncratic error
              reproduced across documents is evidence of copying regardless of what they
              cite. Where the register asserts a shared lineage on this basis it is required
              to <strong>show the error</strong> rather than assert the finding.
            </dd>
          </div>
        </dl>
      </Block>

      <Block code="§3.2" id="judgement">
        <h3>The two surviving judgement calls</h3>
        <p>
          The grading algorithm is deterministic given the evidence table, with exactly two
          exceptions. Both are published rather than hidden inside a score:
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>the lineage counterfactual</dt>
            <dd>
              Whether a document would have said what it said had it not seen another. This
              is a judgement, it is quorum-adjudicated, and it is logged.
            </dd>
          </div>
          <div className="defn">
            <dt>the fallback ordinals</dt>
            <dd>
              On the fallback path only, two ordinal assignments that are not fixed by the
              catalog.
            </dd>
          </div>
        </dl>
        <p>
          Where one of these decided a band, the proposition carries a{" "}
          <strong>marginal flag</strong> — the <span className="voice-mono">≈</span> glyph on
          the stave — and the entry says which contested fact it turned on. The flag exists
          precisely because the model is brittle at band boundaries by design (
          <a href="#L-13">L-13</a>).
        </p>
      </Block>

      <Block
        code="§3.3"
        id="cap-4"
        margin={
          <>
            <Tag k="doc" /> The full cap ledger with conditions is at{" "}
            <a href="/method#caps">/method §9.2</a>.
          </>
        }
      >
        <h3>A cap that describes itself as blunt</h3>
        <p>
          <span className="voice-mono">CAP-4</span> holds a proposition at band{" "}
          <span className="voice-mono">D</span> where all support postdates 2022-11-30 with
          no verified pre-2022 document. The rubric&rsquo;s own words for it:{" "}
          <strong>
            &ldquo;a blunt instrument justified only by the absence of a better one&rdquo;
          </strong>
          . It will penalise genuine recent scholarship along with machine-generated text,
          because it cannot currently tell them apart. It is published in those terms, and it
          will be revisited as attribution infrastructure improves.
        </p>
      </Block>

      {/* ==================================================================
          §4 — THE LIVE STATE. Required on this page by §13.4.
          ================================================================== */}

      <SectionHead
        code="§4"
        id="live"
        title="The instrument's current state"
        margin={
          <>
            <Tag k="doc" /> Read from the register&rsquo;s own tables at build time. Full
            instrument telemetry at <a href="/telemetry">/telemetry</a>.
          </>
        }
      />

      <Block code="§4.1" wide>
        <dl className="dl">
          <dt>verification</dt>
          <dd>SELF — single model family, not independent (D-006)</dd>
          <dt>hosts reachable</dt>
          <dd>
            {state.hosts_reachable} / {state.hosts_in_access_schedule}
          </dd>
          <dt>candidates published</dt>
          <dd>{state.candidates_published}</dd>
          <dt>propositions graded</dt>
          <dd>{state.propositions_graded}</dd>
          <dt>measured confabulation rate</dt>
          <dd>{state.measured_confabulation_rate ?? "— no grading run has completed"}</dd>
          <dt>propositions at R</dt>
          <dd>{refutation.refuted}</dd>
          <dt>R reached by refutation-of-record only</dt>
          <dd>{refutation.r2_only}</dd>
          <dt>R reversals</dt>
          <dd>
            {refutation.reversed}
            {refutation.refuted === 0 ? " — no rate is computable on an empty denominator" : ""}
          </dd>
          <dt>rubric</dt>
          <dd>{state.rubric_version}</dd>
          <dt>last grading run</dt>
          <dd>{state.last_grading_run ?? "—"}</dd>
        </dl>
      </Block>

      <Block
        code="§4.2"
        margin={
          <>
            <Tag k="doc" /> D-007 → <a href="/decisions#D-007">the decision</a>. This is why{" "}
            <a href="/">the register</a> is empty.
          </>
        }
      >
        <div className="flag-block">
          <div className="flag-head">Egress</div>
          <p>
            Outbound network egress is currently denied in full. The verification tier
            therefore cannot resolve a single citation to bytes, and by this
            register&rsquo;s own standard an unresolved citation is not evidence — so no
            graded candidate can be published. The{" "}
            {state.hosts_in_access_schedule}-host access schedule exists and is catalogued;{" "}
            {state.hosts_reachable} of those hosts have been probed successfully.
          </p>
          <p className="t-small" style={{ marginBottom: 0 }}>
            The consequence the register applies to itself: the 158-source registry was built
            entirely from search snippets and has never been tested against a live endpoint,
            so it is <span className="voice-mono">V0-UNRESOLVED</span> by the same rule it
            applies to everyone else (<a href="#L-9">L-9</a>, <a href="#L-19">L-19</a>).
          </p>
        </div>
      </Block>

      <Block code="§4.3">
        <p className="t-small">
          Publishing this page and <a href="/telemetry">/telemetry</a> at the same
          prominence as the register itself is a reputational cost, taken deliberately. A
          register that states its measured fabrication rate is more credible than one that
          implies none.
        </p>
      </Block>
    </div>
  );
}
