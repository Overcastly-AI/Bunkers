import type { Metadata } from "next";

import { Block, SectionHead, Tag } from "@/components/Doc";

export const metadata: Metadata = {
  title: "Ratified decisions · BUNKERS",
  description:
    "The decisions the project has made, with the reasoning and the consequence — including D-006, the single-model-family verification limitation.",
};

/**
 * `/decisions` — RATIFIED DECISIONS.
 *
 * From `docs/DECISIONS.md`, whose own headnote is the reason this page exists:
 * "Recorded here because several of them change what a grade MEANS, and A
 * REGISTER THAT CANNOT SHOW WHAT IT DECIDED AND WHEN HAS NO STANDING TO GRADE
 * ANYONE ELSE'S SOURCES."
 *
 * Each decision keeps its own address (`/decisions#D-006`) because they are
 * cited from `/method`, `/limits`, `/corrections`, the empty-state block on `/`
 * and the standing foot. A decision that could not be linked to would be an
 * assertion rather than a record.
 */

interface Decision {
  id: string;
  title: string;
  date?: string;
  body: React.ReactNode;
}

const DECISIONS: Decision[] = [
  {
    id: "D-001",
    title: "Geographic scope: US-first",
    body: (
      <>
        <p>
          The continental United States first. Archive access is strongest there — the
          declassification, technical-report, archival, procurement and topographic corpora
          are all US-centric — and it is where the rubric can be validated against ground
          truth that can actually be checked.
        </p>
        <p>
          <strong>Consequence:</strong> the schema is country-agnostic from day one, so
          expansion is additive rather than a migration. The foreign discovery beat is
          designed but dormant. What is <em>not</em> portable is every table governing
          silence and search — see <a href="/limits#L-16">L-16</a>.
        </p>
      </>
    ),
  },
  {
    id: "D-002",
    title: "Stack: a dedicated database project, not a schema inside an existing one",
    body: (
      <p>
        <strong>Consequence:</strong> this application is public with no login, so the
        anonymous read key ships in client-side code. A dedicated project means one
        misconfigured row-level-security policy cannot reach unrelated data. That
        separation is the reason the choice is recorded as a decision rather than left as
        an implementation detail.
      </p>
    ),
  },
  {
    id: "D-003",
    title: "Collection is continuous and broad, not a themed one-shot",
    body: (
      <p>
        The register is an accumulating database, never a finished report. Coverage deepens
        over successive cycles.{" "}
        <strong>
          Consequence: every candidate is provisional and versioned from the start.
        </strong>{" "}
        Grades move as evidence lands, and the database records the movement rather than
        the current value alone — which is why every entry carries a step chart and a grade
        history rather than a single letter.
      </p>
    ),
  },
  {
    id: "D-004",
    title: "The v0.1 grading rubric is superseded by BES v0.2",
    body: (
      <>
        <p>
          Three adversarial reviews — an archival historian, an intelligence analyst, and a
          disinformation skeptic — returned <em>restructure, not patch</em>.{" "}
          <strong>Sixteen defects were rated fatal.</strong>
        </p>
        <p>
          The decisive one was arithmetic: under v0.1 a conclusive declassified primary
          document, scoring alone, landed at 28 — grade{" "}
          <span className="voice-mono">E</span>,{" "}
          <em>&ldquo;folklore with a trace.&rdquo;</em> The grade bands described evidence{" "}
          <strong>kinds</strong> while the formula measured evidence{" "}
          <strong>breadth</strong>.
        </p>
        <p>
          <strong>Consequence:</strong> grading moved from places to propositions, evidence
          acquired a sign, and diagnosticity replaced presence-scoring. The v0.1 text is
          retained under a supersession notice rather than deleted. The full defect list is
          at <a href="/corrections#C-001">C-001</a>.
        </p>
      </>
    ),
  },
  {
    id: "D-005",
    title: "Corroboration is a graph property, not a count of agents",
    body: (
      <>
        <p>
          The original design claimed that search agents being blind to each other created
          the independence the corroboration axis measured. That is a category error, and
          it was load-bearing: <strong>agent independence is not source independence.</strong>{" "}
          N agents searching the same indexed web surface the same single source and score
          it as N-fold corroboration. The design was manufacturing the exact false
          corroboration the register exists to expose.
        </p>
        <p>
          It survived into the first schema proposals, one of which implemented
          &ldquo;a graph property, not a count&rdquo; as, literally, a distinct-count over
          an agent-writable column — four copies of one document, written with four lineage
          identifiers, would have counted as four independent lineages and opened grade band{" "}
          <span className="voice-mono">B</span>. It was rejected for this.
        </p>
        <p>
          <strong>Consequence:</strong> blind fan-out is retained for recall only and
          contributes nothing to corroboration. Independence is computed as connected
          components over citation edges, downstream of discovery. Recorded as a correction
          at <a href="/corrections#C-002">C-002</a>.
        </p>
      </>
    ),
  },
  {
    id: "D-006",
    title: "Single model family, with the limitation published",
    date: "2026-08-17",
    body: (
      <>
        <p>
          The register runs its pipeline with one model family. Two families would make
          entailment checking genuinely adversarial, make the two-family agreement
          requirement real, and make double-scoring a measurement rather than a self-check.
          One family collapses all of that.
        </p>
        <p>
          <strong>This decision cannot be retrofitted.</strong> A grade produced under
          single-family verification and one produced under two-family verification are not
          the same object, and there is no honest way to distinguish them after the register
          is populated. It is therefore made before the first grade is written.
        </p>
        <div className="flag-block">
          <div className="flag-head">Consequence — a publication obligation, not a footnote</div>
          <p style={{ marginBottom: 0 }}>
            The register must state on its methodology page that its second line of defence
            is <strong>self-verification, not independent verification</strong>. That claim
            is <em>absent</em>, not merely weaker. The mechanisms that do not depend on model
            family — resolve-or-die, subject binding, the diagnosticity catalog, the caps —
            remain fully in force.
          </p>
        </div>
        <p className="t-small">
          Discharged at <a href="/method#verification">/method §2</a>, at{" "}
          <a href="/limits#D-006">/limits §1</a>, on <a href="/">the register</a>, and in
          the standing foot of every page. Its standing-limitation form is{" "}
          <a href="/limits#L-3">L-3</a>.
        </p>
      </>
    ),
  },
  {
    id: "D-007",
    title: "Network egress must be widened before the register can publish",
    date: "2026-08-17",
    body: (
      <>
        <p>
          Outbound egress is currently denied in full. The verification tier therefore
          cannot resolve a single citation to bytes. The project&rsquo;s own integrity rule
          was found to be a test for the <em>presence of a citation string</em>, which a
          confabulating language model satisfies 100% of the time; resolve-or-die is the
          fix, and resolve-or-die requires egress.
        </p>
        <p>
          <strong>Consequence:</strong> the 158-source registry was built entirely from
          search snippets and has never been tested against a live endpoint. By the
          register&rsquo;s own standard that groundwork is{" "}
          <span className="voice-mono">V0-UNRESOLVED</span>. Until egress lands, the
          pipeline can be built and exercised but cannot publish a graded candidate.
        </p>
        <p className="t-small">
          This is the reason <a href="/">the register</a> shows zero candidates, and the
          reason that zero is stated in the register&rsquo;s own vocabulary rather than as
          an apology.
        </p>
      </>
    ),
  },
  {
    id: "D-008",
    title: "Deploy once the application exists",
    date: "2026-08-18",
    body: (
      <>
        <p>
          <strong>Sequencing, and why it is not merely tidiness.</strong> The register is
          public with no login, so the anonymous read key ships in client-side code. That is
          correct by design — and it means the row-level-security posture and the published
          read surface must be right <em>before</em> a public URL exists, not after. At the
          time of this decision the API was pointed at the wrong schema, so the published
          projection was unreachable while several hundred internal geometry functions were
          exposed. Deploying in that state would have shipped the inverted surface.
        </p>
        <p>
          <strong>Consequence:</strong> the first deployment publishes a register with{" "}
          <strong>zero candidates</strong> — the grading model, the calibration suite, the
          sixteen documented fatal defects, and the D-006 verification limitation.{" "}
          <em>That is the intended first artifact, not a placeholder.</em> Shipping the
          methodology before the data is the correct order for this project: it lets the
          community see how a claim will be judged before any claim is made.
        </p>
      </>
    ),
  },
];

export default function DecisionsPage() {
  return (
    <div className="doc">
      <Block
        code="§0"
        margin={
          <>
            <Tag k="doc" /> <span className="voice-mono">docs/DECISIONS.md</span>,
            transcribed. Each decision is addressable:{" "}
            <span className="voice-mono">/decisions#D-006</span>.
          </>
        }
      >
        <h1>Ratified decisions</h1>

        <div className="rule-block t-lede">
          Several of these change what a grade means. A register that cannot show what it
          decided, and when, has no standing to grade anyone else&rsquo;s sources.
        </div>

        <p>
          Eight decisions, with the reasoning and the consequence. Two of them —{" "}
          <a href="#D-006">D-006</a> and <a href="#D-007">D-007</a> — are the reason this
          register currently publishes no candidates, and both were taken deliberately and
          before any grade was written rather than discovered afterwards.
        </p>
      </Block>

      <SectionHead code="§1" id="decisions" title="The decisions" />

      {DECISIONS.map((d) => (
        <Block key={d.id} code={d.id} id={d.id}>
          <div className="clause">
            <span className="clause-id">
              {d.id}
              {d.date ? ` · decided ${d.date}` : ""}
            </span>
            <h3 className="clause-title">{d.title}</h3>
            {d.body}
          </div>
        </Block>
      ))}

      <SectionHead code="§2" id="standing-rule" title="The standing rule" />

      <Block
        code="§2.1"
        margin={
          <>
            <Tag k="doc" /> Enforced in the interface: retained rows print at full size and
            full ink, never greyed and never collapsed by default.
          </>
        }
      >
        <div className="rule-block t-lede">
          Nothing is deleted. Refuted and F-grade entries are retained with their refutations
          attached, and corrections are published rather than quietly applied — including
          corrections to this project&rsquo;s own reasoning.
        </div>
        <p>
          The second clause is why <a href="/corrections">/corrections</a> exists as a URL.
          &ldquo;Corrections are published, not quietly applied&rdquo; is not true unless
          there is somewhere to read them.
        </p>
      </Block>
    </div>
  );
}
