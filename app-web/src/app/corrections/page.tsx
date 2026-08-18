import type { Metadata } from "next";

import { Block, SectionHead, Tag } from "@/components/Doc";

export const metadata: Metadata = {
  title: "Corrections · BUNKERS",
  description:
    "A published errata series: what this project got wrong, when it was found, and what changed — including the sixteen fatal defects that superseded the v0.1 rubric.",
};

/**
 * `/corrections` — A PUBLISHED ERRATA SERIES.
 *
 * DESIGN.md §13.7: "'Corrections are published, not quietly applied' NEEDS A
 * URL, OR IT IS NOT TRUE. Each correction is numbered, dated, and links to the
 * grade event it explains."
 *
 * The standing rule from `DECISIONS.md` is the authority: "Nothing is deleted…
 * corrections are published rather than quietly applied — INCLUDING CORRECTIONS
 * TO THIS PROJECT'S OWN REASONING."
 *
 * At zero candidates there are no grade movements to explain, so every
 * correction here is of the second kind: a correction to the project's own
 * reasoning, its rubric, its schema or its documentation. That is not a
 * placeholder use of the page — it is the more demanding one. A register that
 * publishes only corrections to other people's claims and none to its own has
 * the standing problem this page exists to solve.
 *
 * Each entry states what was wrong, how it was found, and what changed. Where a
 * correction is still open it says so rather than being held back until it
 * closes; C-006 below is open.
 */

interface Correction {
  id: string;
  date: string;
  title: string;
  /** What kind of thing was corrected. Not a severity — a locus. */
  locus: string;
  state: "closed" | "open";
  body: React.ReactNode;
}

const CORRECTIONS: Correction[] = [
  {
    id: "C-001",
    date: "2026-08-16",
    locus: "grading model",
    state: "closed",
    title: "The v0.1 rubric was superseded after sixteen defects were rated fatal",
    body: (
      <>
        <p>
          Three adversarial reviews of the original grading rubric — by an archival
          historian, an intelligence analyst and a disinformation skeptic — returned{" "}
          <em>restructure, not patch</em>. Sixteen defects were rated fatal. The rubric was
          not amended; it was replaced.
        </p>
        <p>
          <strong>The decisive defect was arithmetic.</strong> Under v0.1, a conclusive
          declassified primary document — the strongest evidence this domain can produce —
          scoring on its own, landed at 28 points: grade{" "}
          <span className="voice-mono">E</span>,{" "}
          <em>&ldquo;folklore with a trace.&rdquo;</em> The bands described evidence{" "}
          <strong>kinds</strong> while the formula measured evidence{" "}
          <strong>breadth</strong>, and nothing in the model noticed the contradiction.
        </p>
        <p>The sixteen, as the reviewers stated them:</p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>H1</dt>
            <dd>
              Evidence has no sign. Nothing in the formula could encode evidence that a
              claim is <em>false</em>; a documented disinformation operation{" "}
              <em>added</em> to the score.
            </dd>
          </div>
          <div className="defn">
            <dt>H2</dt>
            <dd>
              The unit of grading was a place; the unit of evidence is a proposition. A
              well-documented real installation laundered its documentation onto every claim
              attached to it — <strong>citogenesis performed by the register itself.</strong>
            </dd>
          </div>
          <div className="defn">
            <dt>H3</dt>
            <dd>
              Confidence in <em>evidence</em> was published under labels asserting{" "}
              <em>existence</em>, with no expected-record prior. A documentary void was
              treated identically whether the record class never existed, was destroyed, or
              was searched and found empty.
            </dd>
          </div>
          <div className="defn">
            <dt>H4</dt>
            <dd>
              The geographic axis encoded a buried-rural-mountain prior, so urban,
              in-building and above-ground hardened facilities could not reach the top band
              by construction, regardless of documentation.
            </dd>
          </div>
          <div className="defn">
            <dt>H5</dt>
            <dd>
              No diagnosticity term. The axes rewarded the presence of signals, not their
              power to discriminate the hardened-facility hypothesis from the mundane one.
            </dd>
          </div>
          <div className="defn">
            <dt>H6</dt>
            <dd>
              A single conclusive primary source could not exceed grade{" "}
              <span className="voice-mono">E</span>. This is the arithmetic defect above.
            </dd>
          </div>
          <div className="defn">
            <dt>I1</dt>
            <dd>
              No term anywhere in the system for the probability of the evidence under the{" "}
              <em>negation</em> of the hypothesis.
            </dd>
          </div>
          <div className="defn">
            <dt>I2</dt>
            <dd>
              The confidence axis had no required documentary floor, and the weighting
              inverted the relationship it was meant to express.
            </dd>
          </div>
          <div className="defn">
            <dt>I3</dt>
            <dd>
              The contamination multiplier floored at ×0.5, making grade{" "}
              <span className="voice-mono">F</span> unreachable. A claim that was pure
              folklore could not be graded as such.
            </dd>
          </div>
          <div className="defn">
            <dt>I4</dt>
            <dd>
              The corroboration axis counted sources and called it independence — and the
              search design manufactured false corroboration. See{" "}
              <a href="#C-002">C-002</a>.
            </dd>
          </div>
          <div className="defn">
            <dt>S1</dt>
            <dd>
              <strong>There was no verification tier at all.</strong> The integrity rule
              tested for the presence of a citation string, which a confabulating model
              satisfies every time.
            </dd>
          </div>
          <div className="defn">
            <dt>S2</dt>
            <dd>
              Typology was excluded from scoring, and typology is the entire product: what
              kind of facility this is, is the question.
            </dd>
          </div>
          <div className="defn">
            <dt>S3</dt>
            <dd>
              The cheapest path to grade <span className="voice-mono">B</span> cost zero
              dollars and fabricated nothing — it merely exploited how breadth was counted.
            </dd>
          </div>
          <div className="defn">
            <dt>S4</dt>
            <dd>
              Shared model priors inverted contamination detection and inflated corroboration
              at the same time.
            </dd>
          </div>
          <div className="defn">
            <dt>S5</dt>
            <dd>
              Contamination detection assumed copying; machine contamination is{" "}
              <em>regeneration</em>, which leaves none of the traces copying leaves.
            </dd>
          </div>
          <div className="defn">
            <dt>S6</dt>
            <dd>
              The documentary firewall was breachable for free through legitimate government
              channels — a cheap route to an authoritative-looking record.
            </dd>
          </div>
        </dl>
        <p>
          <strong>What changed.</strong> Grading moved from places to propositions; evidence
          acquired a sign; diagnosticity replaced presence-scoring; a verification tier was
          added with resolve-or-die; expected-record profiles were introduced so silence is
          read rather than scored; and the caps were written as an explicit anti-gaming
          ledger. The v0.1 text is <strong>retained under a supersession notice rather than
          deleted</strong>, per the standing rule.
        </p>
        <p className="t-small">
          Eight points where the three reviewers disagreed with <em>each other</em> are
          recorded with the decision taken, rather than smoothed — because a calibration
          suite that hides its contested cases stops detecting drift in exactly the places
          drift matters. Two of those disagreements are logged as open ratification items
          against the next rubric version.
        </p>
      </>
    ),
  },
  {
    id: "C-002",
    date: "2026-08-16",
    locus: "search design, then schema",
    state: "closed",
    title: "Agent independence was mistaken for source independence",
    body: (
      <>
        <p>
          The original design claimed that search agents being blind to one another created
          the independence the corroboration axis measured.{" "}
          <strong>That is a category error, and it was load-bearing.</strong> N agents
          searching the same indexed web surface the same single source and score it as
          N-fold corroboration. The design was manufacturing the exact false corroboration
          the register exists to expose.
        </p>
        <p>
          <strong>It then survived the correction once.</strong> One of the first schema
          proposals implemented &ldquo;a graph property, not a count&rdquo; as, literally, a
          distinct-count over a column the writing agents controlled. Four copies of one
          document, written with four different lineage identifiers, would have counted as
          four independent lineages — and four independent lineages opens grade band{" "}
          <span className="voice-mono">B</span>. It was caught in review and rejected.
        </p>
        <p>
          <strong>What changed.</strong> Blind fan-out is retained for recall only and
          contributes nothing to corroboration. Independence is computed as connected
          components over citation edges, downstream of discovery, from data the discovery
          agents cannot write. Ratified as <a href="/decisions#D-005">D-005</a>.
        </p>
        <p className="t-small">
          Recorded here in full because the second occurrence is the instructive one: the
          defect was understood, named, and then reintroduced in a different vocabulary by
          someone implementing the fix. The residual channels this does{" "}
          <em>not</em> close are at <a href="/limits#shared-priors">/limits §3.1</a>.
        </p>
      </>
    ),
  },
  {
    id: "C-003",
    date: "2026-08-18",
    locus: "database",
    state: "closed",
    title: "A geometry function resolved names against the wrong schema path",
    body: (
      <>
        <p>
          The function that decides how a candidate&rsquo;s position may be drawn —
          including the gate that refuses to emit a point for anything below the required
          positional band — contained unqualified spatial references. It worked only because
          callers happened to supply a schema search path that included the right one.
          Under a hostile path it failed.
        </p>
        <p>
          <strong>Why this one mattered more than its size suggests.</strong> That function
          is the single place in the system where{" "}
          <em>&ldquo;this may not be drawn as a point&rdquo;</em> is enforced. A failure
          there is not a rendering bug; it is the mechanism that prevents the map from
          asserting a precision the evidence does not have.
        </p>
        <p>
          <strong>What changed.</strong> The search path is now pinned explicitly on that
          function and on the three others carrying the same latent defect — the complete
          set, found by auditing every function body rather than by fixing the one that
          failed. Name resolution is deterministic for every caller instead of dependent on
          who is calling. No grade semantics, no band condition, no cap and no access
          predicate changed. Verified afterwards under the hostile path: the suppression
          fires and publishes its reason.
        </p>
      </>
    ),
  },
  {
    id: "C-004",
    date: "2026-08-18",
    locus: "documentation",
    state: "closed",
    title: "A safety mechanism that was documented but referenced by nothing",
    body: (
      <>
        <p>
          The citation-graph traversal documented its termination as resting on{" "}
          <em>three</em> independent grounds, the third being a node budget. A function
          implementing that budget exists and returns a value.{" "}
          <strong>Nothing calls it.</strong>
        </p>
        <p>
          Termination in fact rests on two grounds — node de-duplication and a depth cap —
          and both were measured and found sound and sufficient. The claim was nonetheless
          overstated, and the correction was recorded in those terms:{" "}
          <strong>
            dead code that looks like a safety mechanism is worse than no code at all,
            because the next reader will trust it.
          </strong>
        </p>
        <p className="t-small">
          Published as a correction rather than fixed silently, because the documentation
          error is the finding. The unreferenced function remains, now described accurately.
        </p>
      </>
    ),
  },
  {
    id: "C-005",
    date: "2026-08-18",
    locus: "interface",
    state: "closed",
    title: "The map would have drawn a confident point for an approximate position",
    body: (
      <>
        <p>
          A candidate declaring kilometre-scale positional precision, whose positional
          proposition had not been assessed, would have rendered as a survey cross — a mark
          with a centre, which is a claim that a point is known.
        </p>
        <p>
          <strong>What changed.</strong> The symbol is now a function of{" "}
          <em>both</em> the declared precision and what the geometry function actually
          emitted, never of precision alone. The degradation is drawn as an uncertainty
          circle and{" "}
          <strong>the suppression reason is published beside it</strong> rather than the
          mark quietly changing. The rule that only an exact position may carry a centre
          mark is now enforced in one function, which is the only function in the codebase
          that can return a paintable coordinate.
        </p>
        <p className="t-small">
          A build check scans the map source and fails if an averaged centroid or a label
          anchor appears in any renderer. An averaged coordinate is a point no source
          asserts, and once painted it will be cited.
        </p>
      </>
    ),
  },
  {
    id: "C-006",
    date: "2026-08-18",
    locus: "documentation",
    state: "open",
    title: "The calibration suite is described as 34 cases and enumerates 43",
    body: (
      <>
        <p>
          The calibration document states a suite of <strong>34 cases</strong> and then sets
          out <strong>43 case identifiers</strong>, plus six pipeline tests. The two counts
          are reconcilable — several identifiers are one facility read from a different
          angle, and one facility carries five of them — but the document does not say which
          reconciliation it intends, and the difference is not editorial: it is the
          denominator of the suite that certifies the instrument.
        </p>
        <p>
          <strong>Current disposition.</strong> The register publishes both counts wherever
          the suite is described, and the implementation carries all 43 identifiers plus the
          six pipeline tests, because each has its own section, its own containment marker
          and its own expected value. Nothing is dropped to make a number match.
        </p>
        <p>
          <strong>Open until</strong> the calibration document states the intended
          reconciliation. Until then, a reader who counts the specimen sheets and a reader
          who reads the headline will get different numbers, and neither is being misled
          about which cases exist.
        </p>
      </>
    ),
  },
];

export default function CorrectionsPage() {
  const open = CORRECTIONS.filter((c) => c.state === "open");

  return (
    <div className="doc">
      <Block
        code="§0"
        margin={
          <>
            <Tag k="doc" /> The standing rule:{" "}
            <a href="/decisions#standing-rule">nothing is deleted</a>. Each correction is
            addressable: <span className="voice-mono">/corrections#C-001</span>.
          </>
        }
      >
        <h1>Corrections</h1>

        <div className="rule-block t-lede">
          Corrections are published, not quietly applied — including corrections to this
          project&rsquo;s own reasoning.
        </div>

        <p>
          That sentence is a standing rule of the project, and it is not true unless there
          is somewhere to read them. This is that page.
        </p>
        <p>
          The register currently holds no graded candidates, so none of the corrections
          below explains a grade movement. Every one of them is of the harder kind: a
          correction to the instrument itself — its rubric, its schema, its interface, or
          its documentation.{" "}
          <strong>
            A register that publishes only corrections to other people&rsquo;s claims and
            none to its own has exactly the standing problem this page exists to solve.
          </strong>
        </p>
        <p className="t-small">
          {CORRECTIONS.length} corrections · {open.length} open ·{" "}
          {CORRECTIONS.length - open.length} closed. When candidates are published, grade
          movements will be recorded here and linked to the grade event that carried them.
        </p>
      </Block>

      <SectionHead
        code="§1"
        id="corrections"
        title="The series"
        margin={
          <>
            <Tag k="doc" /> Ordered by number, which is the order they were found. An open
            correction is one whose disposition has not been settled, and it is published in
            that state rather than held back.
          </>
        }
      />

      {CORRECTIONS.map((c) => (
        <Block key={c.id} code={c.id} id={c.id}>
          <div className="clause">
            <span className="clause-id">
              {c.id} · {c.date} · {c.locus} ·{" "}
              {c.state === "open" ? "OPEN" : "CLOSED"}
            </span>
            <h3 className="clause-title">{c.title}</h3>
            {c.body}
          </div>
        </Block>
      ))}

      <SectionHead code="§2" id="scope" title="What belongs here" />

      <Block
        code="§2.1"
        margin={
          <>
            <Tag k="doc" /> A standing limitation is not a correction: it is a thing the
            design does not solve. Those are at <a href="/limits">/limits</a>.
          </>
        }
      >
        <p>Three kinds of entry will appear on this page:</p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>grade movement</dt>
            <dd>
              A published grade changed. The correction links to the grade event, names the
              transition cause, and states what evidence moved it. Where a grade{" "}
              <em>fell</em> because two sources previously counted as independent were found
              to be linked, the correction says so in those words:{" "}
              <em>nothing was lost; a link was found.</em>
            </dd>
          </div>
          <div className="defn">
            <dt>instrument defect</dt>
            <dd>
              The rubric, schema or interface was wrong in a way that could have changed a
              grade. All six entries above are of this kind.
            </dd>
          </div>
          <div className="defn">
            <dt>documentation defect</dt>
            <dd>
              The register described itself inaccurately. Published because a reader who
              cannot trust the description cannot audit the instrument.
            </dd>
          </div>
        </dl>
        <p className="t-small">
          What does <em>not</em> belong here: a standing limitation (
          <a href="/limits">/limits</a>), a ratified decision (
          <a href="/decisions">/decisions</a>), or a refuted candidate. A refutation is a
          finding, not an erratum, and refuted entries are retained in{" "}
          <a href="/claims">the claims register</a> with their refutations attached.
        </p>
      </Block>
    </div>
  );
}
