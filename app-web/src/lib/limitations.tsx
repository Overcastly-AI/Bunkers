/**
 * THE STANDING LIMITATIONS — `GRADING.md` Part 18, transcribed, numbered
 * L-1 … L-19 so each is individually citable.
 *
 * DESIGN.md §13.4 puts this at TOP LEVEL and says why: "GRADING.md §18.11 warns
 * that the pressure to soften this will come from THE MAINTAINER, continuously;
 * A PAGE THAT CAN BE DEMOTED INTO A SUBSECTION IS A PAGE THAT WILL BE."
 *
 * Held in a module rather than inline in the page for one reason: DESIGN.md
 * §13.2 requires that "a proposition whose grade is affected by a standing
 * limitation carries a margin reference `see L-3`", so limitations "stop being a
 * page and become apparatus that reaches into the data." A component rendering
 * that margin reference needs the title without importing a route.
 *
 * Part 18's own framing, which is the reason this is published at all:
 *
 *   "What follows is not a list of things to fix later. It is a list of things
 *    this design DOES NOT SOLVE, published because a register that hides its
 *    blind spots is a safe harbour for the fabrications those blind spots
 *    admit."
 *
 * The text is Part 18's, not the interface's. Where a sentence is emphasised
 * below, it is emphasised in the source.
 */

import type { ReactNode } from "react";

export interface Limitation {
  /** The citable address. Stable: L-3 is 18.3 forever. */
  id: string;
  /** The Part 18 clause this transcribes. */
  clause: string;
  title: string;
  body: ReactNode;
}

export const LIMITATIONS: Limitation[] = [
  {
    id: "L-1",
    clause: "18.1",
    title:
      "Forgery at an authoritative issuer — and worse, the authoritative issuer that does not authenticate",
    body: (
      <>
        <p>
          There is no defence against a well-executed forgery that resolves at the issuing
          authority, quotes at the claimed offsets, matches issuer metadata and binds to
          the subject. The corroboration requirement raises the cost by orders of
          magnitude; it does not eliminate the attack.
        </p>
        <p>
          <strong>
            The sharper unaddressed version: the tier table conflates{" "}
            <em>authoritative</em> issuers with <em>authenticating</em> ones.
          </strong>{" "}
          A county recorder has authority over the fact of recording and none over the
          facts a deed recites — recorders do not adjudicate truth, and recording fees are
          tens of dollars. The rubric lists &ldquo;a deed or court record reciting the
          structure&rdquo; as a top-diagnosticity anchor and makes county deed records the
          universal floor for expected records. That is a genuinely cheap path to a
          dispositive row, and <span className="voice-mono">authority_over_fact</span>{" "}
          narrows but does not close it, because the authority is real; it is the{" "}
          <em>scope</em> of the authority that is being exceeded. The same structural
          problem exists at public comment dockets. The canary programme measures
          confabulation, not forgery, so this is unmonitored as well as unblocked.
        </p>
      </>
    ),
  },
  {
    id: "L-2",
    clause: "18.2",
    title: "ORIGIN corruption by regeneration",
    body: (
      <p>
        A machine-generated page becomes the <em>first observed appearance</em> of a claim,
        and the register dates the origin to a regeneration rather than to its true earlier
        source. Full-text archive search, newsletter runs and the pre-2022 corpora are
        partial coverage only. Since ORIGIN is the class that lets the register publish an
        A-grade fact about a fabrication, a systematically wrong origin date corrupts the
        register&rsquo;s most distinctive output — and corrupts it in the direction of{" "}
        <strong>understating</strong> how old and how contaminated a claim is.
      </p>
    ),
  },
  {
    id: "L-3",
    clause: "18.3",
    title: "Cross-family independence is asserted, not measured",
    body: (
      <>
        <p>
          The design leans on &ldquo;a different model family&rdquo; for entailment
          adjudication, for the second read that promotes an interpretation out of the
          lowest tier, for refutation, for the ten-percent double-scoring, and for the
          lineage counterfactual quorum. Different families share training corpora and
          plausibly share the specific errors this domain is full of. Two families agreeing
          that a span &ldquo;states the proposition on its face&rdquo; is weaker evidence
          than the design treats it as, and <strong>nobody knows how much weaker.</strong>
        </p>
        <p>
          <strong>
            If only one family is available, the second line of defence collapses to a
            banner.
          </strong>{" "}
          That is this register&rsquo;s current configuration — see{" "}
          <a href="/decisions#D-006">D-006</a>, which was ratified in full knowledge of this
          clause and before the first grade was written.
        </p>
      </>
    ),
  },
  {
    id: "L-4",
    clause: "18.4",
    title: "Semantic clustering false merges: direction safe, magnitude unknown",
    body: (
      <p>
        Collapsing genuinely independent witnesses into one lineage systematically{" "}
        <strong>under</strong>-counts corroboration. That is the safe direction and it is
        chosen deliberately, but the error rate is unmeasurable without ground truth on
        lineage, which does not exist for this corpus.{" "}
        <strong>
          The register will under-grade an unknown fraction of real facilities and will
          never be able to say which ones or how many.
        </strong>
      </p>
    ),
  },
  {
    id: "L-5",
    clause: "18.5",
    title: "The physical archive queue is a promise, not a capability",
    body: (
      <>
        <p>
          Pending-acquisition status converts blindness into a work queue, but nobody visits
          College Park, nobody pulls the aerial photography record group, nobody scans
          county minute books from 1962. Roughly 96% of textual holdings at the National
          Archives stay undigitised; the record groups where the construction record
          actually lives are among them; pre-1994 congressional material is scanned-only or
          paywalled; and county records digitise back only to the 1990s while every facility
          of interest was permitted between 1950 and 1975.
        </p>
        <p>
          <strong>
            The grade distribution this register publishes is therefore a map of
            digitisation, not a map of evidence.
          </strong>{" "}
          That bias is not correctable by design. It is only disclosable, and it must be
          disclosed on the methodology page in those words.
        </p>
      </>
    ),
  },
  {
    id: "L-6",
    clause: "18.6",
    title: "Verification debt at the bottom of the register never clears",
    body: (
      <p>
        Prioritising verification by marginal grade impact guarantees that nothing published
        rests on unverified evidence, but its corollary is that low-band propositions may
        never be verified at all. That is harmless for grading — they cannot rise unverified
        — but harmful for <strong>refutation</strong>, because refutation requires
        affirmative disconfirming evidence and the register will systematically not go
        looking for it on entries nobody is defending. A long tail of permanently D-or-E
        entries that are in fact refutable will accumulate.
      </p>
    ),
  },
  {
    id: "L-7",
    clause: "18.7",
    title: "Alias sets are an unaudited attack surface on subject binding",
    body: (
      <p>
        Subject binding is only as good as the alias table, which a language model proposes
        into. An alias that is too generic — &ldquo;Site R&rdquo;, &ldquo;the Bunker&rdquo;,
        a common installation name — silently widens binding across unrelated documents, and
        a wrongly-added alias converts class-scope rows into instance-scope ones, which is
        exactly the promotion path <span className="voice-mono">CAP-2b</span> exists to
        block. Reviewed writes slow this but do not make it observable:{" "}
        <strong>nothing in the telemetry measures binding precision</strong>, and there is no
        obvious way to measure it without labelled data.
      </p>
    ),
  },
  {
    id: "L-8",
    clause: "18.8",
    title: "OCR quality gates the oldest and best documents",
    body: (
      <p>
        Fuzzy OCR caps a row below the dispositive level, which means the declassification
        holdings, pre-1975 technical reports, the agency reading rooms and most engineering
        scans — <strong>the highest-value material in the register&rsquo;s entire
        universe</strong> — are structurally biased toward not reaching that level for
        reasons that have nothing to do with what they say.
      </p>
    ),
  },
  {
    id: "L-9",
    clause: "18.9",
    title: "The 158-source registry may be substantially wrong and nobody knows yet",
    body: (
      <p>
        Three of the five registries were written with federal and military egress blocked;
        every endpoint grammar, parameter name and identifier scheme in them was
        reconstructed from search snippets, client code and prior knowledge.{" "}
        <strong>
          The register&rsquo;s own groundwork has not been through the register&rsquo;s own
          verification tier.
        </strong>{" "}
        It should be, and it has not been costed. See <a href="/sources">/sources</a>, where
        every row currently carries an unprobed egress state.
      </p>
    ),
  },
  {
    id: "L-10",
    clause: "18.10",
    title: "authority_over_fact is new and empty",
    body: (
      <p>
        Until that table is populated, the condition that distinguishes an issuer with
        authority over a fact from an issuer merely recording it remains a model judgement —
        and it is the condition doing the discriminating work in the highest-stakes gate in
        the entire model.{" "}
        <strong>
          Every dispositive-level assignment made before that table is filled is provisional
          in a way the grade row does not currently record.
        </strong>
      </p>
    ),
  },
  {
    id: "L-11",
    clause: "18.11",
    title: "Honest-mostly-X is an epistemic success and a product risk",
    body: (
      <>
        <p>
          The model sets the modal entry at <span className="voice-mono">X</span> or{" "}
          <span className="voice-mono">D</span>, and a register that is honestly mostly-X is
          more credible than one dishonestly mostly-C. That is right. It also means the
          first public version will look, to a casual reader, like an empty database with
          elaborate excuses — and the pressure to relieve that will be continuous,{" "}
          <strong>will come from the maintainer rather than from an attacker</strong>, and is
          not something any schema constraint can resist.
        </p>
        <p>
          <strong>
            The most likely way this model gets quietly abandoned is by weakening the
            search-completeness floor under pressure to look substantial, and that
            abandonment will not announce itself.
          </strong>
        </p>
      </>
    ),
  },
  {
    id: "L-12",
    clause: "18.12",
    title: "It cannot rank within a band, and it cannot express degree",
    body: (
      <p>
        Two <span className="voice-mono">C</span>-grade propositions are not comparable and
        there is no defensible sort order. HARDEN is a proposition, not a quantity:
        &ldquo;designed against multiple 200–300 MT direct hits&rdquo; and &ldquo;has a
        heavy door&rdquo; both reach <span className="voice-mono">A</span> if the documents
        support them. Every table on this site that offers to sort by band publishes this
        limitation in the column header.
      </p>
    ),
  },
  {
    id: "L-13",
    clause: "18.13",
    title: "It is brittle at band boundaries, deliberately",
    body: (
      <p>
        A proposition one condition short of <span className="voice-mono">B</span> sits at{" "}
        <span className="voice-mono">C</span> indefinitely. There is no partial credit and no
        &ldquo;nearly B&rdquo;. The mitigation is transparency, not smoothing: the limiting
        condition names the exact criterion, and a marginal flag announces that one
        contested fact decided it.{" "}
        <strong>Users accustomed to scores will experience this as arbitrariness.</strong>{" "}
        The interface amplifies rather than softens it — there is no visual gradient at a
        band boundary anywhere on this site, because smoothing the boundary would be the
        softest and most plausible-looking route back to a composite.
      </p>
    ),
  },
  {
    id: "L-14",
    clause: "18.14",
    title: "The refutation narrowing cuts both ways",
    body: (
      <p>
        Requiring affirmative disconfirmation fixes the cases where a facility was being
        refuted merely for being undocumented, but a candidate whose mundane explanation is
        complete and documented — yet which produces nothing <em>improbable</em> under the
        claim — sits at <span className="voice-mono">E</span> forever rather than being
        cleanly refuted. Conversely, refutation can still misfire on{" "}
        <strong>
          a dual-use facility whose cover story is also completely true and completely
          documented
        </strong>
        , which is exactly what a good cover story is.
      </p>
    ),
  },
  {
    id: "L-15",
    clause: "18.15",
    title: "The five curated tables are asserted, not derived, and they are the new attack surface",
    body: (
      <p>
        Moving judgement from per-candidate scoring into versioned lookups makes it auditable
        and back-fittable, which is a large improvement — but it is a{" "}
        <strong>relocation, not an elimination</strong>. The diagnosticity anchors are
        estimates and have not been back-fitted against outcomes because there are no
        outcomes yet. The expected-record table encodes a policy about how American secrecy
        works that could simply be wrong for some agency or era, and{" "}
        <strong>being wrong there is invisible</strong>: it silently licenses or forbids the
        argument from silence.
      </p>
    ),
  },
  {
    id: "L-16",
    clause: "18.16",
    title: "It does not solve foreign or non-English material",
    body: (
      <p>
        Receipts, identifier grammars, expected-record profiles and canonical search sets are
        all US-specific. The schema is country-agnostic but every table governing silence and
        search would need rebuilding per country.
      </p>
    ),
  },
  {
    id: "L-17",
    clause: "18.17",
    title: "It is more expensive per candidate",
    body: (
      <p>
        Propositions multiply rows; receipted negative searches multiply queries; refutation
        scores every observation and runs even at band <span className="voice-mono">A</span>;
        verification adds a fetch, a hash, a metadata comparison and an alias match per
        source.{" "}
        <strong>
          A candidate that cost one adjudication pass under the previous rubric costs perhaps
          five to eight here.
        </strong>
      </p>
    ),
  },
  {
    id: "L-18",
    clause: "18.18",
    title: "The model says nothing about whether a candidate is worth scoring",
    body: (
      <p>
        A find-rewarded search pointed at Montana will still return Montana adits; they will
        now grade <span className="voice-mono">D</span> or <span className="voice-mono">X</span>{" "}
        instead of <span className="voice-mono">C</span>, which is better, but the register
        will fill with them. The candidate-set dilution rule is the only structural pushback
        and it applies only where a documented programme denominator exists.
      </p>
    ),
  },
  {
    id: "L-19",
    clause: "18.19",
    title: "And the one it cannot argue its way out of: this specification is itself unverified",
    body: (
      <p>
        It was written by reading five registries, three of which state that their endpoint
        grammars and identifier schemes were reconstructed from memory and search snippets
        because federal egress was blocked. Not one declassification identifier has been
        resolved, not one historical quadrangle sheet fetched.{" "}
        <strong>
          By its own standard this document is V0-UNRESOLVED: format-valid, internally
          consistent, and unverified.
        </strong>{" "}
        It should be treated as a specification to be checked, not a finding, and the first
        task after ratification is to run its own tables through its own verification tier.
      </p>
    ),
  },
];

export function limitation(id: string): Limitation | null {
  return LIMITATIONS.find((l) => l.id === id) ?? null;
}
