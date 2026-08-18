import type { Metadata } from "next";

import { Block, SectionHead, Tag } from "@/components/Doc";
import { BASE_CAPS, CAP_CONDITION } from "@/lib/filter-vocab";
import { BAND_STATEMENT, BAND_WORD } from "@/lib/types/grade";
import { GRADES } from "@/lib/types/enums";
import { getRepository, CORPUS_CATALOGUED, CORPUS_TRANSCRIBED } from "@/lib/repository";

export const metadata: Metadata = {
  title: "Method — BES v0.2 · BUNKERS",
  description:
    "How a claim is graded: propositions rather than places, signed evidence, diagnosticity against a named alternative, provenance tiers, and resolve-or-die.",
};

/**
 * `/method` — HOW A CLAIM IS GRADED.
 *
 * For this project this page is PRIMARY CONTENT, not boilerplate. At zero
 * candidates it is most of the product: DESIGN.md §18.4 lists `/method` among
 * the pages that are "complete and populated on day one", and D-008 records the
 * owner's reasoning — "shipping the methodology before the data is the correct
 * order for this project: IT LETS THE COMMUNITY SEE HOW A CLAIM WILL BE JUDGED
 * BEFORE ANY CLAIM IS MADE."
 *
 * Two constraints shaped what is written here.
 *
 * ONE — THIS PAGE IS FOR A READER WHO HAS NOT READ 160 KB OF SPECIFICATION.
 * `GRADING.md` is 2,544 lines and is the authority; this is not a summary of it
 * and not a replacement for it. It explains the five ideas that actually decide
 * a grade, each with the worked case from the calibration set that shows the
 * idea biting, and links to the specimen sheet so the reader can see the
 * arithmetic rather than take the explanation on trust.
 *
 * TWO — D-006 IS DISCHARGED HERE, AT §2, ABOVE THE MECHANICS.
 * "The register must state ON ITS METHODOLOGY PAGE that its second line of
 * defence is SELF-VERIFICATION, NOT INDEPENDENT VERIFICATION. That claim is
 * ABSENT, not merely weaker." DESIGN.md §20 rejects "burying D-006 in a footer
 * or behind a dismissible banner" by name. It is placed BEFORE the description
 * of the mechanisms because it qualifies all of them: a reader who learns how
 * entailment checking works before learning that its adversarial half is absent
 * has been told the mechanism and not the limitation.
 *
 * Rule Zero applies to a prose page as much as to a stave. Every count on this
 * page is read from the repository at build time; the band words and statements
 * come from `BAND_STATEMENT`, and the cap conditions from `CAP_CONDITION`,
 * because both are already the single source those values have. Retyping them
 * into prose here would be a second copy free to drift from the components.
 */
export default async function MethodPage() {
  const repo = getRepository();
  const state = await repo.getRegisterState();
  const erp = await repo.listExpectedRecords();
  const corpora = await repo.listCorpora();

  return (
    <div className="doc">
      <Block
        code="§0"
        margin={
          <>
            <Tag k="doc" /> BES v0.2 is specified in full in{" "}
            <span className="voice-mono">docs/GRADING.md</span> (Parts 1–19). Where this
            page and that document differ, that document governs and the difference is a
            defect on <a href="/corrections">/corrections</a>.
          </>
        }
      >
        <h1>Method</h1>

        <div className="rule-block t-lede">
          A grade in this register is a statement about the record, never a statement
          about the world. It says what has been established, from what, and how well —
          not what is true.
        </div>

        <p>
          Every entry here is graded by the <strong>Bunkers Evidence Standard</strong>,
          rubric version <span className="voice-mono">{state.rubric_version}</span>. This
          page explains what the grade means for a reader who has not read the
          specification. Five ideas do nearly all of the work, and each of them exists
          because the previous rubric failed on it.
        </p>

        <ol className="t-base">
          <li>The thing graded is a proposition, not a place.</li>
          <li>Evidence carries a sign; it can count against.</li>
          <li>Evidence is weighed by how well it discriminates a named alternative.</li>
          <li>Where a document came from is three separate questions, not one.</li>
          <li>A citation that cannot be resolved to bytes is not evidence.</li>
        </ol>
      </Block>

      {/* ==================================================================
          §1 — WHAT A GRADE IS NOT. Stated before the mechanics, because the
          most common misreading of a graded register is that the letter is a
          probability that the facility exists.
          ================================================================== */}

      <SectionHead code="§1" id="not" title="What the letter is not" />

      <Block
        code="§1.1"
        margin={
          <>
            <Tag k="doc" /> <span className="voice-mono">GRADING.md</span> §9.1 — band
            words are statements about the record. No copy on this site paraphrases a
            band as a claim about existence.
          </>
        }
      >
        <p>
          <strong>The letter is not a probability.</strong> Nothing in this register
          expresses P(the facility exists). A published posterior would make the headline
          letter a model probability and imply a calibration the register cannot
          demonstrate. An archival historian reviewing the rubric asked for exactly that
          number and the register declined; the disagreement is recorded rather than
          papered over.
        </p>
        <p>
          <strong>The letter is not a score for a site.</strong> There is no site grade
          anywhere in this product — no badge, no composite, no sort key. A site is a
          container of independently graded propositions, and the decomposition is the
          product.
        </p>
        <p>
          <strong>A and F are not good and bad.</strong> An F entry with documented origin
          work is a contribution, and the{" "}
          <a href="/claims">claims register</a> is where those entries live. F is drawn at
          exactly the same ink as A everywhere on this site.{" "}
          <span className="voice-mono">R</span> and <span className="voice-mono">X</span>{" "}
          are not low grades at all — they are different epistemic objects, and they are
          drawn off the A–F rail because putting them on it would be a lie in geometry.
        </p>
      </Block>

      {/* ==================================================================
          §2 — D-006. THE PUBLICATION OBLIGATION, DISCHARGED IN FULL, ABOVE
          THE MECHANICS RATHER THAN BENEATH THEM.
          ================================================================== */}

      <SectionHead
        code="§2"
        id="verification"
        title="The limitation this instrument publishes about itself"
        margin={
          <>
            <Tag k="doc" /> D-006, ratified 2026-08-17. Also carried verbatim in the
            standing foot of every page, on <a href="/">the register</a>, and at{" "}
            <a href="/limits#L-3">L-3</a>.
          </>
        }
      />

      <Block code="D-006" id="d-006">
        <div className="flag-block t-lede">
          <div className="flag-head">Verification posture</div>
          <p>
            <em>{state.verification_posture}</em>
          </p>
          <p className="t-small" style={{ marginTop: "var(--s-3)", marginBottom: 0 }}>
            D-006 · <a href="/decisions#D-006">the decision</a> ·{" "}
            <a href="/limits#L-3">the standing limitation</a>
          </p>
        </div>

        <p>
          This is the plainest way to say it: <strong>the register checks its own
          work.</strong> Several of the mechanisms described below — entailment
          adjudication, the second read that promotes an interpretation out of the lowest
          tier, the refutation pass, the ten-percent double-scoring, the lineage
          counterfactual quorum — were designed to run across{" "}
          <em>two different model families</em>, so that agreement between them would be a
          measurement rather than a self-check. The register runs one family. That second
          line of defence does not exist here.
        </p>
        <p>
          The register does not describe this as a weaker version of independent
          verification, because it is not a version of it. <strong>The claim is absent.</strong>{" "}
          Two systems from one family share training corpora and plausibly share the
          specific errors this domain is full of; two of them agreeing that a span
          &ldquo;states the proposition on its face&rdquo; is weaker evidence than the
          design treats it as, and nobody knows how much weaker.
        </p>
        <p>
          <strong>What this does not excuse.</strong> The mechanisms that do not depend on
          model family remain fully in force and are not softened by this admission:
          resolve-or-die (§7), subject binding (§3), the diagnosticity catalog (§5), the
          caps (§9), and the requirement that every published grade rest on evidence whose
          receipts verified. The decision was made <em>before the first grade was
          written</em>, because a grade produced under single-family verification and one
          produced under two-family verification are not the same object and there is no
          honest way to distinguish them afterwards.
        </p>
      </Block>

      {/* ==================================================================
          §3 — PROPOSITIONS, NOT PLACES
          ================================================================== */}

      <SectionHead
        code="§3"
        id="propositions"
        title="The unit is a proposition, not a place"
        margin={
          <>
            <Tag k="doc" /> Defect H2 of sixteen, raised by the archival historian and
            rated fatal. See <a href="/corrections#C-001">C-001</a>.
          </>
        }
      />

      <Block code="§3.1">
        <p>
          The previous rubric graded <em>places</em>. Evidence accrued to the site, so a
          well-documented real installation laundered its documentation onto every claim
          ever attached to it. A reader could see a strong grade beside a sentence about
          mind control and have no way to tell that the strength belonged to a different
          sentence entirely.
        </p>
        <p>
          <strong>That is citogenesis, performed by the register itself</strong> — which
          is the one thing a register built to expose citogenesis cannot do. It was the
          defect that killed v0.1.
        </p>
        <p>
          A site is now a container. It carries identity and geometry and{" "}
          <strong>nothing graded</strong>. What gets graded is a proposition from a closed
          twelve-class vocabulary, each independently, each with its own evidence, its own
          ceiling and its own limiting condition:
        </p>

        <dl className="dl-prose">
          <div className="defn">
            <dt>EXIST</dt>
            <dd>A substantial artificial enclosed or subsurface structure exists here.</dd>
          </div>
          <div className="defn">
            <dt>LOCATE</dt>
            <dd>Its position is known, and to what precision.</dd>
          </div>
          <div className="defn">
            <dt>EXTENT</dt>
            <dd>Its size or depth is as asserted.</dd>
          </div>
          <div className="defn">
            <dt>TYPOLOGY</dt>
            <dd>It is a facility of the asserted kind.</dd>
          </div>
          <div className="defn">
            <dt>HARDEN</dt>
            <dd>It is hardened against the asserted threat.</dd>
          </div>
          <div className="defn">
            <dt>CONTROL</dt>
            <dd>It is under the asserted control — federal, military, private.</dd>
          </div>
          <div className="defn">
            <dt>FUNCTION</dt>
            <dd>It serves the asserted purpose.</dd>
          </div>
          <div className="defn">
            <dt>STATUS</dt>
            <dd>It is currently active, closed, or disposed of.</dd>
          </div>
          <div className="defn">
            <dt>FEATURE</dt>
            <dd>A specific physical feature is present.</dd>
          </div>
          <div className="defn">
            <dt>PROGRAM</dt>
            <dd>A named programme existed. Not a claim about this structure.</dd>
          </div>
          <div className="defn">
            <dt>IDENTITY</dt>
            <dd>This structure is that named facility.</dd>
          </div>
          <div className="defn">
            <dt>ORIGIN</dt>
            <dd>
              A claim first appeared at a given time, in a given artifact, from a given
              person. Not a claim about the structure.
            </dd>
          </div>
        </dl>

        <p>
          <strong>The most common real state of affairs is that the hole is certain and
          the function is not.</strong> The old rubric could not express it. This one
          renders it without a word: a single entity carrying{" "}
          <span className="voice-mono">EXIST&nbsp;A</span> beside{" "}
          <span className="voice-mono">FUNCTION&nbsp;E</span>, on the same screen, at the
          same instant.
        </p>
        <p>
          <span className="voice-mono">PROGRAM</span> and{" "}
          <span className="voice-mono">ORIGIN</span> are set below a labelled rule reading{" "}
          <span className="voice-mono">UNCLAMPED — THESE DO NOT DESCRIBE THE STRUCTURE</span>,
          because they are facts about a programme or about a claim&rsquo;s history rather
          than about the ground. That is how the register can publish{" "}
          <span className="voice-mono">ORIGIN&nbsp;A</span> — a well-established fact about
          where a story came from — on the same page as{" "}
          <span className="voice-mono">EXIST&nbsp;R</span>, without either lying about the
          other.
        </p>
      </Block>

      <Block
        code="§3.2"
        margin={
          <>
            <Tag k="doc" /> Worked: <a href="/calibration/A-12">A-12</a> and{" "}
            <a href="/calibration/R-05">R-05</a> are one facility read from two angles.
          </>
        }
      >
        <h3>Three routes a claim cannot take</h3>
        <dl className="dl-prose">
          <div className="defn">
            <dt>scope = ADJACENT</dt>
            <dd>
              A document about something nearby does not certify the thing itself. A
              1960s underground nuclear test excludes rather than supports a claim about a
              cavern beneath the next mesa.
            </dd>
          </div>
          <div className="defn">
            <dt>scope = CLASS</dt>
            <dd>
              A document about a programme in general does not certify any particular
              hilltop as a member of it.
            </dd>
          </div>
          <div className="defn">
            <dt>subject binding</dt>
            <dd>
              The document must be shown to be about <em>this</em> subject, by identifier
              or by verified alias. Where binding fails, an instance-level row is demoted
              to class level automatically — which is the commonest real failure and the
              one an enthusiastic reader makes most often.
            </dd>
          </div>
        </dl>
      </Block>

      {/* ==================================================================
          §4 — SIGNED EVIDENCE
          ================================================================== */}

      <SectionHead
        code="§4"
        id="sign"
        title="Evidence has a sign"
        margin={
          <>
            <Tag k="doc" /> Defect H1. Under v0.1 the documented AFOSI disinformation
            operation at Dulce <em>added</em> to the score.
          </>
        }
      />

      <Block code="§4.1">
        <p>
          Every observation is one row, and every row carries{" "}
          <span className="voice-mono">sign ∈ &#123;SUPPORTS, UNDERCUTS, NEUTRAL&#125;</span>{" "}
          against a named proposition. The sign is arithmetic, not commentary: the signed
          weight is a generated column in the database, so a row that cuts against a claim
          subtracts rather than merely failing to add.
        </p>
        <p>
          The old rubric could only express disconfirmation by declining to award points,
          which is indistinguishable from having looked and found nothing.{" "}
          <strong>Those are completely different states of the record</strong> and this
          register never conflates them.
        </p>
        <p>
          A single verified undercutting row at high diagnosticity, unrebutted, blocks the
          top three bands outright. A published tenant lease list counts{" "}
          <em>against</em> a hardened-facility claim rather than being silently omitted.
          And band <span className="voice-mono">R</span> — refuted — is evaluated{" "}
          <em>first</em>, before any other band, and overrides everything.
        </p>
        <p>
          On screen the sign is carried three redundant ways at once: the{" "}
          <span className="voice-mono">−</span> glyph, the word{" "}
          <span className="voice-mono">UNDERCUTS</span>, and the one ochre in the palette.
          Colour is never the only channel.
        </p>
      </Block>

      <Block
        code="§4.2"
        margin={
          <>
            <Tag k="doc" /> Retained, displayed, arithmetically inert — and drawn as such:
            on the chart, not on the axis.
          </>
        }
      >
        <h3>Nothing is deleted</h3>
        <p>
          Rows that fail to qualify are not removed. They are retained in one of two
          inert states, printed at full size and full ink beside the rows that counted,
          with the generated reason for their exclusion in the position the quotation
          would occupy:
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>INERT</dt>
            <dd>
              Excluded from the arithmetic by one of seven published exclusions — wrong
              scope, failed binding, superseded, and so on.
            </dd>
          </div>
          <div className="defn">
            <dt>V0</dt>
            <dd>
              The citation did not resolve. Format-valid, internally consistent, and
              unverified — <strong>counted as measured fabrication</strong> and reported
              on <a href="/telemetry">/telemetry</a> rather than quietly dropped.
            </dd>
          </div>
        </dl>
        <p className="t-small">
          Greying them out would be deletion by other means. The standing rule is that
          nothing is deleted.
        </p>
      </Block>

      {/* ==================================================================
          §5 — DIAGNOSTICITY
          ================================================================== */}

      <SectionHead
        code="§5"
        id="diagnosticity"
        title="Diagnosticity — evidence is weighed against a named alternative"
        margin={
          <>
            <Tag k="doc" /> Defect H5. The rubric rewarded the presence of signals, not
            their power to discriminate.
          </>
        }
      />

      <Block code="§5.1">
        <p>
          This is the idea that does the most work, and it is the one most often missing
          from amateur research into this subject.
        </p>
        <p>
          A signal counts for a proposition only in proportion to how much better it is
          explained by that proposition than by <strong>a specific, named, mundane
          alternative</strong>. An adit, a substation and a rail spur are perfectly
          consistent with a hardened federal facility. They are equally consistent with a
          commercial limestone warehouse. Under a presence-scoring rubric that warehouse
          scores <span className="voice-mono">C</span> as a bunker candidate. It should
          not, and here it does not — <em>not because the evidence is weak, but because it
          does not discriminate</em>.
        </p>
        <p>
          Every proposition therefore carries a <strong>null hypothesis, named in a
          sentence</strong>, printed on the entry page directly beneath the proposition it
          opposes. Leaving it unnamed is not an option a grader has: an unnamed null is
          itself a cap (<span className="voice-mono">CAP-7</span>) that holds the
          proposition at <span className="voice-mono">D</span> until someone writes one.
        </p>
        <p>
          Diagnosticity is a five-stop discrete ordinal from{" "}
          <span className="voice-mono">D0</span> to <span className="voice-mono">D4</span>,
          assigned from a versioned catalog keyed to the facility type rather than
          estimated per candidate. <span className="voice-mono">D4</span> is the gate: it
          is the level at which a document is dispositive on its face, and the bands that
          matter are defined in terms of it. On a stave the diagnosticity of each row is
          its tick height, sorted with the highest against the axis, so a{" "}
          <span className="voice-mono">D4</span> row is visible instantly.
        </p>
      </Block>

      {/* ==================================================================
          §6 — PROVENANCE
          ================================================================== */}

      <SectionHead
        code="§6"
        id="provenance"
        title="Provenance is three orthogonal questions"
        margin={
          <>
            <Tag k="doc" /> The witness key for every source is at{" "}
            <a href="/sources">/sources</a>.
          </>
        }
      />

      <Block code="§6.1">
        <p>
          &ldquo;How reliable is this source&rdquo; is not one question. Collapsing it into
          a single tier is how a scanned primary document gets discounted for sitting on a
          hobbyist website, and how a machine-generated article gets credited for sitting
          on a clean domain. The register keeps three columns:
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>host_tier</dt>
            <dd>
              Who is serving the bytes. <span className="voice-mono">T1</span> a federal
              archive, <span className="voice-mono">T5</span> an anonymous post.
            </dd>
          </div>
          <div className="defn">
            <dt>content_tier</dt>
            <dd>
              What the document itself is. A declassified memorandum is{" "}
              <span className="voice-mono">T1</span> content wherever it is hosted.
            </dd>
          </div>
          <div className="defn">
            <dt>causal provenance</dt>
            <dd>
              Whether the document was produced <em>in the course of the activity</em> or
              written <em>about</em> it afterwards. A contract award is a by-product of
              doing the thing; an article is a report of it.
            </dd>
          </div>
        </dl>
        <p>
          The register calls the interesting case a <strong>tier trap</strong>: a{" "}
          <span className="voice-mono">T3</span> host delivering{" "}
          <span className="voice-mono">T1</span> content. A faithfully scanned agency
          release in an enthusiast archive is a{" "}
          <span className="voice-mono">T1</span> document with a retrieval-integrity
          question, and it is graded that way. The inverse trap matters more:{" "}
          <strong>a clean domain does not upgrade machine-generated text.</strong>
        </p>
        <p className="t-small">
          Two further properties are tracked because they change what a source can be used
          for at all: <span className="voice-mono">adversary_writable</span> (anyone can
          edit it — replication into many renderers is still one lineage) and{" "}
          <span className="voice-mono">machine_generated</span> (on a versioned blocklist,
          plus a mechanical heuristic, because the blocklist will always lag).
        </p>
      </Block>

      <Block
        code="§6.2"
        margin={
          <>
            <Tag k="doc" /> The full spine, with the verdict column, renders on every
            entry sheet under <span className="voice-mono">§6 LINEAGE</span>.
          </>
        }
      >
        <h3>Corroboration is a graph property, not a count</h3>
        <p>
          Forty-one documents saying the same thing is not forty-one witnesses if forty of
          them copied the first. Independence is computed as connected components over
          citation edges — never as a count of documents, and never as a count of agents
          that found them. The register publishes the distance between the two as a{" "}
          <strong>collapse delta</strong>, and states the finding in a sentence before it
          draws anything:
        </p>
        <p className="t-lede" style={{ borderInlineStart: "1px solid var(--rule-strong)", paddingInlineStart: "var(--s-3)" }}>
          <em>
            41 citing documents · 1 independent lineage · collapse delta 40. This
            proposition rests on one source and 40 copies.
          </em>
        </p>
        <p>
          Where a loop is closed — an encyclopedia article cites a 2003 page which cites
          the 1976 article which is the only source — it is marked{" "}
          <span className="voice-mono">⟳ CITOGENESIS</span>, counted once, and explained in
          a plain sentence. Confirmed citogenesis is itself a cap at band{" "}
          <span className="voice-mono">E</span>.
        </p>
      </Block>

      {/* ==================================================================
          §7 — RESOLVE OR DIE
          ================================================================== */}

      <SectionHead
        code="§7"
        id="resolve"
        title="Resolve-or-die"
        margin={
          <>
            <Tag k="doc" /> D-007. The reason this register currently publishes zero
            candidates.
          </>
        }
      />

      <Block code="§7.1">
        <p>
          <strong>A citation that cannot be resolved to bytes is not evidence.</strong>
        </p>
        <p>
          The project&rsquo;s own integrity rule was found to be a test for the{" "}
          <em>presence of a citation string</em> — a test a confabulating language model
          passes one hundred percent of the time. The fix is that every observation must
          be fetched, hashed, quoted at located character offsets, matched against issuer
          metadata, and bound to its subject. A row whose citation does not resolve does
          not become a weak row. It becomes a{" "}
          <span className="voice-mono">V0</span> row: retained, displayed, and counted as{" "}
          <strong>measured fabrication</strong> in the register&rsquo;s own published
          telemetry.
        </p>
        <p>
          This is why the register is empty. Outbound network egress is currently denied
          in full, so the verification tier cannot resolve a single citation to bytes.{" "}
          {state.hosts_reachable} of {state.hosts_in_access_schedule} catalogued hosts are
          reachable. Publishing graded candidates in that state would mean publishing
          grades that were never verified.
        </p>
        <p className="t-small">
          By its own standard the register applies this to itself: the 158-source registry
          was built entirely from search snippets and has never been tested against a live
          endpoint, so the whole of that groundwork is{" "}
          <span className="voice-mono">V0-UNRESOLVED</span> — format-valid, internally
          consistent, and unverified. That is stated at{" "}
          <a href="/limits#L-9">L-9</a> and again at <a href="/limits#L-19">L-19</a>.
        </p>
      </Block>

      {/* ==================================================================
          §8 — SILENCE
          ================================================================== */}

      <SectionHead
        code="§8"
        id="silence"
        title="Silence, and when it is allowed to count"
        margin={
          <>
            <Tag k="doc" /> The full table is published at{" "}
            <a href="/method/expected-records">/method/expected-records</a> —{" "}
            {erp.length} profiles.
          </>
        }
      />

      <Block code="§8.1">
        <p>
          The argument from silence is valid only where the silence is{" "}
          <em>surprising</em>. For a classified facility, absent records are the expected
          condition, and treating a documentary void as evidence against is how a fully
          operational continuity-of-government site gets published as folklore.
        </p>
        <p>
          The register therefore consults an <strong>expected-record profile</strong>{" "}
          before reading anything into an absence — a versioned table keyed on record class
          by era by controlling authority by classification posture. It answers one
          question: <em>would a record of this class be expected to exist and be public,
          for a facility of this type, in this period, under this authority?</em>
        </p>
        <p>
          The same table forbids the inference in one case and licenses it in another,
          which is the whole reason it is a table and not a judgement:
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>uninformative</dt>
            <dd>
              A facility operating under commercial cover produces no federal construction
              record by design. <strong>The absence is not evidence against.</strong>
            </dd>
          </div>
          <div className="defn">
            <dt>informative</dt>
            <dd>
              An excavation of the asserted scale under an appropriated defence programme
              would produce a construction line. Its absence is a finding.
            </dd>
          </div>
          <div className="defn">
            <dt>record-destroyed</dt>
            <dd>
              The class was disposed of under an approved retention schedule. Distinct from
              searched-and-empty, and distinct from unsearched.
            </dd>
          </div>
          <div className="defn">
            <dt>unsearched</dt>
            <dd>
              Nobody has looked. Prints as <span className="voice-mono">— not searched</span>{" "}
              and never as a zero, <strong>because a zero is a claim</strong>.
            </dd>
          </div>
        </dl>
        <p>
          A profile at <span className="voice-mono">X0</span> — no record of this class
          would be expected — produces <strong>no rows at all</strong>, not zeros. The
          searches are still executed and their negative receipts still logged; a grading
          run that scored those absences against the facility has failed.
        </p>
      </Block>

      <Block code="§8.2">
        <h3>Search completeness, and the grade that is not a grade</h3>
        <p>
          Every proposition publishes a <strong>search completeness index</strong>: of the
          record classes applicable to this proposition, how many have actually been
          searched with a receipt. It is printed as k-of-n rather than as a percentage,
          because k and n are both countable and a percentage is not.
        </p>
        <p>
          Below the threshold, the register does not publish a low grade. It publishes{" "}
          <span className="voice-mono">X — NOT ASSESSED</span>, which is the{" "}
          <em>absence</em> of an assessment rather than a weak one, drawn as a dashed
          hollow mark off the ranked rail beside a measurement of exactly what is missing.
          Refutation is the one exception: an established{" "}
          <span className="voice-mono">R</span> is not withheld for want of further
          searching, because a refutation does not become unestablished by not looking
          harder.
        </p>
        <p className="t-small">
          Where nothing is applicable, completeness is <span className="voice-mono">1.000</span>{" "}
          on an empty denominator and draws as <span className="voice-mono">∅</span>.
          Nothing to search is <em>complete</em>, and it must not look like zero.
        </p>
      </Block>

      {/* ==================================================================
          §9 — THE BANDS AND THE CAPS
          ================================================================== */}

      <SectionHead
        code="§9"
        id="bands"
        title="The bands"
        margin={
          <>
            <Tag k="doc" /> Rendered from the same table the staves read. Band words and
            statements have one definition in this codebase.
          </>
        }
      />

      <Block code="§9.1" wide>
        <div className="scroll-region" role="region" aria-label="The eight bands" tabIndex={0}>
          <table className="band-table">
            <caption className="t-small">
              Eight bands. <span className="voice-mono">A</span>–
              <span className="voice-mono">F</span> are ranked;{" "}
              <span className="voice-mono">R</span> and{" "}
              <span className="voice-mono">X</span> are unranked and are neither capped nor
              clamped. Every statement below is a statement about the record.
            </caption>
            <thead>
              <tr>
                <th scope="col">Band</th>
                <th scope="col">Word</th>
                <th scope="col">What it says about the record</th>
              </tr>
            </thead>
            <tbody>
              {GRADES.map((g) => (
                <tr key={g}>
                  <th scope="row" className="voice-mono">
                    {g}
                  </th>
                  <td className="t-micro">{BAND_WORD[g]}</td>
                  <td>{BAND_STATEMENT[g]}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="t-small legend-note" style={{ marginTop: "var(--s-3)" }}>
          The register cannot rank <em>within</em> a band. Two{" "}
          <span className="voice-mono">C</span>-grade propositions are not comparable and
          there is no defensible sort order between them, so every table that offers to
          sort by band publishes that limitation in the column header rather than letting
          a reader infer a ranking. It is also brittle <em>at</em> band boundaries by
          design: a proposition one condition short of{" "}
          <span className="voice-mono">B</span> sits at <span className="voice-mono">C</span>{" "}
          indefinitely, with no partial credit and no &ldquo;nearly B&rdquo;. The register
          names the exact criterion that stopped it and flags when a single contested fact
          decided the band.
        </p>
      </Block>

      <SectionHead
        code="§9.2"
        id="caps"
        title="The caps"
        margin={
          <>
            <Tag k="doc" /> A cap is the named reason a proposition could not go higher.
            Caps are listed with their conditions inline, never as codes alone.
          </>
        }
      />

      <Block code="§9.3">
        <p>
          A band is attained by meeting its conditions and then <em>reduced</em> by any cap
          that applies. Caps are the anti-gaming ledger, and they are published so a reader
          can see precisely which one is holding a proposition down:
        </p>
        <dl className="dl-prose">
          {BASE_CAPS.map((c) => (
            <div className="defn" key={c}>
              <dt>{c}</dt>
              <dd>{CAP_CONDITION[c]}</dd>
            </div>
          ))}
        </dl>
        <p>
          <strong>
            <span className="voice-mono">CAP-2b</span> is the hardest constraint in the
            ledger and the one worth understanding.
          </strong>{" "}
          A claim about function, control or hardening that is carried entirely by
          attributes of the <em>place</em> — a big hole, a fence, a substation — has no
          support for the claim at all, and belongs at{" "}
          <span className="voice-mono">E</span>. In one sentence:{" "}
          <em>
            no FUNCTION claim can exceed E without a verified, instance-scope,
            subject-bound observation about the claim itself.
          </em>{" "}
          On a stave this renders as a visible void — an empty upper storey — so a reader
          can see at a glance how much of a grade is just the mountain.
        </p>
        <p className="t-small">
          <span className="voice-mono">CAP-4</span> is published with the register&rsquo;s
          own assessment of it attached: <em>a blunt instrument justified only by the
          absence of a better one</em>. It will be revisited as attribution infrastructure
          improves.
        </p>
      </Block>

      {/* ==================================================================
          §10 — WHAT IS PUBLISHED
          ================================================================== */}

      <SectionHead code="§10" id="publishes" title="What the register publishes" />

      <Block
        code="§10.1"
        margin={
          <>
            <Tag k="doc" /> Nothing below band <span className="voice-mono">D</span>{" "}
            appears on <a href="/plate">the plate</a>, and the plate says so in its legend
            rather than omitting silently.
          </>
        }
      >
        <p>
          Alongside the band, every proposition publishes four things that a single letter
          would hide:
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>ceiling</dt>
            <dd>
              The best band this <em>class of object</em> could reach even with perfect
              work — and whether it is already there. A facility under commercial cover has
              a low ceiling for reasons that are not about the evidence.
            </dd>
          </div>
          <div className="defn">
            <dt>limiting_condition</dt>
            <dd>
              The exact named criterion that stopped it going higher, in prose. An error
              bar whose width has a <em>name</em> is a different object from one whose
              width has a value.
            </dd>
          </div>
          <div className="defn">
            <dt>silence_reading</dt>
            <dd>Whether the absences were allowed to count, and why.</dd>
          </div>
          <div className="defn">
            <dt>base_rate_reading</dt>
            <dd>
              An ordinal reading of the reference class — and it is published with its
              disclaimer attached: <strong>not a probability, and it did not enter the
              grade.</strong>
            </dd>
          </div>
        </dl>
        <p>
          Grades move as evidence lands, and the database records the movement rather than
          the current value alone. Corroboration is non-monotone: a grade can{" "}
          <em>fall</em> because a link was found between two sources previously counted as
          independent. Nothing was lost when that happens; a link was found. Movement is
          drawn as a step chart, never a line, because grades are ordinal and there is
          nothing in between two of them.
        </p>
      </Block>

      {/* ==================================================================
          §11 — THE CURATED TABLES
          ================================================================== */}

      <SectionHead
        code="§11"
        id="tables"
        title="The five curated tables"
        margin={
          <>
            <Tag k="doc" /> Counts on this page are read from the register&rsquo;s own
            tables at build time.
          </>
        }
      />

      <Block code="§11.1">
        <p>
          Judgement that would otherwise be made per-candidate is moved into versioned
          lookup tables, so it is auditable, citable and back-fittable. This is a genuine
          improvement and it is also a <strong>relocation of judgement, not an elimination
          of it</strong> — the register says so at <a href="/limits#L-15">L-15</a>, and it
          is why all five are published rather than described.
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>tier table</dt>
            <dd>
              Host tier, content tier and causal provenance per source —{" "}
              <a href="/sources">/sources</a>, {CORPUS_TRANSCRIBED} of{" "}
              {CORPUS_CATALOGUED} catalogued rows currently transcribed.
            </dd>
          </div>
          <div className="defn">
            <dt>diagnosticity catalog</dt>
            <dd>
              <span className="voice-mono">D0</span>–<span className="voice-mono">D4</span>{" "}
              anchors per facility type. Version{" "}
              <span className="voice-mono">{state.diagnosticity_version}</span>.
            </dd>
          </div>
          <div className="defn">
            <dt>expected-record profiles</dt>
            <dd>
              What silence is allowed to mean —{" "}
              <a href="/method/expected-records">/method/expected-records</a>, {erp.length}{" "}
              profiles published.
            </dd>
          </div>
          <div className="defn">
            <dt>typology profiles</dt>
            <dd>
              Which diagnosticity catalog applies to which kind of facility. Version{" "}
              <span className="voice-mono">{state.typology_version}</span>.
            </dd>
          </div>
          <div className="defn">
            <dt>access schedule</dt>
            <dd>
              The {state.hosts_in_access_schedule} hosts, their robots posture and their
              egress state — <a href="/telemetry">/telemetry</a>, {corpora.length} rows
              carried here.
            </dd>
          </div>
        </dl>
        <p className="t-small">
          Being wrong in these tables is <em>invisible</em>: a wrong expected-record
          profile silently licenses or forbids the argument from silence, and the
          diagnosticity anchors are estimates that have not been back-fitted against
          outcomes because there are no outcomes yet. That is the standing limitation, not
          a to-do.
        </p>
      </Block>

      {/* ==================================================================
          §12 — SELF-HOSTING. Belongs on this page per §2 and §9.1.
          ================================================================== */}

      <SectionHead
        code="§12"
        id="vendors"
        title="No vendor sees who is reading this"
        margin={
          <>
            <Tag k="doc" /> A privacy decision before it is a design one. Credits are in
            the <a href="/api#colophon">colophon</a>.
          </>
        }
      />

      <Block code="§12.1">
        <p>
          This site makes <strong>no request to any third party</strong>, at build time or
          at read time. Both instances of that decision are the same decision:
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>typefaces</dt>
            <dd>
              Self-hosted and inlined at build. A register whose readers&rsquo; viewports
              should not be logged by a vendor should not ship their font requests to one
              either.
            </dd>
          </div>
          <div className="defn">
            <dt>basemap</dt>
            <dd>
              Self-hosted vector tiles read over range requests. A commercial basemap token
              sends a log of which coordinates a reader of a register of federal facilities
              panned to, to a third party. No vendor tile host is reachable from this
              codebase, and the build fails if one is introduced.
            </dd>
          </div>
        </dl>
        <p className="t-small">
          There is no analytics script, no tag manager, no embedded media, no font CDN and
          no telemetry beacon on any page of this site. The one thing the register measures
          about itself is its own fabrication rate, and it publishes that at{" "}
          <a href="/telemetry">/telemetry</a>.
        </p>
      </Block>

      {/* ==================================================================
          §13 — WHERE TO GO NEXT
          ================================================================== */}

      <SectionHead code="§13" id="next" title="Reading the instrument" />

      <Block
        code="§13.1"
        margin={
          <>
            <Tag k="doc" /> The specimen sheets are calibration fixtures, contained under
            their own namespace, and are excluded from every count on{" "}
            <a href="/">the register</a>.
          </>
        }
      >
        <p>
          The register currently holds {state.candidates_published} candidates, so the
          method above is best read against the calibration suite — known facilities whose
          expected grades were fixed in advance and against which the instrument is
          checked:
        </p>
        <dl className="dl-prose">
          <div className="defn">
            <dt>A-02</dt>
            <dd>
              <a href="/calibration/A-02">Raven Rock</a> — seven propositions at{" "}
              <span className="voice-mono">A</span>. What a full ladder looks like.
            </dd>
          </div>
          <div className="defn">
            <dt>B-05</dt>
            <dd>
              <a href="/calibration/B-05">Greenbrier 1991</a> — one entity decomposing
              across four bands on one page, with silence ruled uninformative.
            </dd>
          </div>
          <div className="defn">
            <dt>E-01</dt>
            <dd>
              <a href="/calibration/E-01">DIA</a> —{" "}
              <span className="voice-mono">CAP-2b</span> holding a claim at{" "}
              <span className="voice-mono">E</span>: the empty upper storey.
            </dd>
          </div>
          <div className="defn">
            <dt>A-12 · R-05</dt>
            <dd>
              <a href="/calibration/A-12">Dulce</a> — an{" "}
              <span className="voice-mono">A</span>-grade fact about a fabrication beside a
              refuted facility.
            </dd>
          </div>
          <div className="defn">
            <dt>F-05</dt>
            <dd>
              <a href="/calibration/F-05">Site CARDINAL</a> — the confabulation canary and
              its five retained <span className="voice-mono">V0</span> identifiers.
            </dd>
          </div>
        </dl>
        <p>
          The full suite is at <a href="/calibration">/calibration</a>. What the model does
          not solve is at <a href="/limits">/limits</a>, and it is a longer page than this
          one.
        </p>
      </Block>
    </div>
  );
}
