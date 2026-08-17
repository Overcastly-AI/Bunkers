# FOUNDATION REPORT

**To:** project manager
**Re:** W0 close-out — the scoring model, the schema, the fleet correction, and what W1 costs
**Date:** 2026-08-17

This is a decision document, not a status update. Where something is weak I have said so plainly,
including where the weakness is mine.

---

## 1 · THE HEADLINE

**Four things are now established, and one thing is not.**

Established:

1. **A ratified scoring model** — BES v0.2, complete and self-contained in `docs/GRADING.md`. It
   answers all sixteen fatal defects the three critiques raised, and it says explicitly where it does
   not.
2. **A schema that executes** — `supabase/schema.sql`, 215 KB, applies clean from an empty database on
   PostgreSQL 16.13 + PostGIS 3.4, with a 65-assertion acceptance suite passing 65/65.
3. **A regression suite** — `docs/CALIBRATION.md`, 34 cases plus 6 pipeline tests, merged from 43 raw
   cases across the three critiques, with the five known-divergent cases marked so they cannot be
   "fixed" by accident.
4. **A corrected fleet with a verification tier** — `docs/FLEET.md`. The single most important change:
   **no LLM assigns a grade, and no LLM can write an evidence row.**

Not established, and this is the thing to decide about:

5. **Nothing has been verified against a live target.** Not one CREST identifier has been resolved. Not
   one HTMC sheet fetched. The 158-source registry's endpoint grammars were reconstructed from search
   snippets with .gov/.mil egress blocked. **By the register's own standard, the entire W0 output is
   V0-UNRESOLVED: format-valid, internally consistent, and unverified.**

---

## 2 · WHAT THE RESTRUCTURE CHANGED, AND WHY

Three adversarial reviews converged on the same verdict — *restructure, do not reweight* — from three
different directions, and the third one is the reason the project is not shipping a reweighted v0.1.

**The archival historian** found that evidence had no sign, that grades attached to places while
evidence attaches to propositions, that a documentary void was scored identically whether the record
class never existed or was searched and found empty, and that a single conclusive primary document
could not exceed grade E. That last one inverts the foundational premise of documentary history.

**The intelligence analyst** found that 54% of the weight sat on axes measuring "there is underground
infrastructure here" — a proposition true of limestone mines, highway tunnels, sewer works, data
centres and large airports — and demonstrated it: **the AT&T Long Lines hardened station at Fairview,
Kansas scored 56.25 and SubTropolis, a commercial warehouse in a limestone mine, scored 60.23. The
warehouse outranked the bunker.**

**The adversarial skeptic** found the thing that actually matters, and it is worth quoting the shape of
it:

> Every gate in v0.1 tests the FORM of evidence, and form is the one thing a language model produces
> flawlessly. "Every claim carries a citation" tests for the presence of a citation string. A
> confabulating LLM satisfies it 100% of the time.

And then the finding that should decide budget allocation: across 353 KB of ratification material —
WORKFLOW.md, both prior critiques, all five source registries — the strings *"hallucinat"*,
*"confabulat"*, *"prompt inject"*, *"checksum"*, *"AI-generated"* and *"synthetic"* occur **zero
times**. The threat model this system will actually face had not been written down anywhere.

### The three structural changes

**(a) The unit changed from a place to a proposition.** Grades live on `core.proposition` rows over a
closed twelve-class vocabulary. `core.entity` carries identity, aliases, relations and geometry and
**nothing graded**. There is no site-level score column anywhere in the schema and no code path that
computes one.

This is not a refinement. It is the fix for the register performing citogenesis on itself: a
well-documented real installation laundering its documentation onto every claim attached to it. It is
also what makes the domain's most common real state of affairs expressible — *"the hole is certain, the
function is not"* — and that case is now an acceptance-suite assertion: one entity, EXIST at A and
FUNCTION at E, at the same instant, with CAP-2b proving the FUNCTION claim could not borrow the EXIST
documentation.

**(b) Evidence acquired a sign, and refutation became a band.** `sign ∈ {SUPPORTS, UNDERCUTS,
NEUTRAL}`, `signed_weight` generated as magnitude × sign, and band R checked first and overriding
everything.

The clearest statement of why this mattered: under v0.1, the documented AFOSI counterintelligence
operation against Paul Bennewitz — in which forged documents were supplied to *seed* the Dulce claim —
**added to the DOC axis**. A documented disinformation operation counted as documentation *for* the
thing it fabricated. That is now R1, and Dulce grades R with `ORIGIN` graded A alongside it.

**(c) A verification tier now sits between discovery and adjudication.** This is the addition that
makes the other two worth having.

> Apply a perfectly restructured, diagnosticity-weighted, proposition-level rubric to synthetic
> evidence and you get perfectly calibrated fiction — an entry that is wrong in a more sophisticated
> way, with a better-looking uncertainty decomposition attached.

The tier is seven stages (V-0 egress precondition through V-6 entailment adjudication), and six of the
seven are deterministic code. The seventh — does this span actually *say* what the discoverer claimed —
is the one place a model is unavoidable, and it is constrained so it **can only demote**. Final
diagnosticity is `min(assignment, V-6 ceiling)`. A model that can only lower a grade cannot inflate the
register.

---

## 3 · THE SCHEMA ADJUDICATION, AND THE FINDING THAT MATTERS MOST

Two schema proposals were built. **Proposal B (evidence-centric) wins** and is the base of the final
schema; the parts of A that B lacked were grafted in. B was judged on its DDL alone — the agent that
wrote it was killed by a usage limit before it could summarise, and the absence of a summary was
correctly disregarded.

B wins on the two requirements where A fails outright:

- **Independence as a graph property.** A's `independent_lineages()` is literally
  `count(distinct v.lineage_id)` over a denormalised, agent-writable column — sitting under a comment
  claiming *"a graph property, not a COUNT(\*)."* It is a COUNT(DISTINCT). An agent that writes four
  distinct lineage IDs for four copies of one document gets four lineages, and `L(D2) >= 3` opens band
  B. **This is the register's founding premise — one source and 399 copies — and A does not implement
  it.** B computes connected components over the citation edges. The final schema goes further and
  removes any writable lineage column from `core.observation` entirely, asserted by a test that reads
  `information_schema`.
- **Verification state.** B's `membership` (V/U/INERT/V0) is a STORED GENERATED column compiling the
  seven §2.4 exclusions, so set membership is a schema fact no agent can assert. A expresses it as a
  view predicate plus a partial index — correct today, silently bypassable by any future query that
  forgets a clause.

### The headline finding — both proposals would have taken the register down

I was asked to verify termination explicitly rather than assume it. **Both proposals write origin
tracing as `WITH RECURSIVE ... UNION ALL ... CYCLE node SET is_cycle USING path`** — at depth 25 in A
and depth 24 in B — and both comment that the CYCLE clause makes it safe.

It does not. The CYCLE clause prunes a branch when a node repeats *on that branch*. It says nothing
about the **number of distinct simple paths**, which grows exponentially with depth in a dense graph,
and `UNION ALL` plus a path array makes every path a distinct row, so deduplication cannot help.

Measured on a 40-document / 380-edge citogenesis cluster — a *small* one for this domain:

| depth | rows | time |
|---|---|---|
| 4 | 9,111 | 18 ms |
| 5 | 73,911 | 163 ms |
| 6 | 592,311 | 1,595 ms |
| 8 | — | **did not complete within a 25-second statement timeout** |

**Both proposals run this inside the ingest path at depth 24–25.** Citation cycles are the norm here,
not the exception — a citogenesis loop literally *is* a cycle, and detecting them is the register's
entire purpose. **The first real echo chamber ingested takes the worker down**, and it would have
looked like an infrastructure problem rather than a design one.

Fixed by deduplicating on the NODE rather than enumerating PATHS: `UNION` (not `UNION ALL`) keyed on
`(node, depth)`, no path array in the recursive term, and a node budget as a third independent stop.
Path reconstruction moved out of the recursion into a bounded iterative loop with a visited set. Same
fixture, same depth 25: **20 nodes in 9.6 ms.**

### Other defects found and fixed

Briefly, because the full list with file and line references is in the schema commentary:

- **A (fatal):** the lineage COUNT(DISTINCT) above.
- **B (fatal):** refutation state read straight off an agent-written row. An LLM writing `'R3'`
  produced an R grade. Now re-derived by `core.derive_refutation()`, which re-tests R1/R2/R3 against
  the rows; the agent's value is demoted to `proposed_state`.
- **B:** SCI with a zero denominator returned NULL, coalesced to 0, forcing X. **Every applicable ERP
  profile at X0 is the normal condition for a classified facility** — it is exactly the Mount Pony and
  Greenbrier-1991 cases. Those entries could never have published the silence reading the model exists
  to state. An empty denominator means there was nothing to search, which is complete: SCI = 1.000.
- **B:** the monotone clamp was **dead code** — declared, never inserted into by any path, and living
  only in a read-time helper the map view did not call. **The published grade was the unclamped
  grade.**
- **A:** the clamp read a stale parent with no ordering guarantee, and nothing ever re-fired.
- **B (three RLS leaks):** anonymous read on `core.witness` (real people's names, the resolvability
  adjudication, the adjudicator and free-text notes, **for candidates never published**); anonymous
  read on `core.document_citation` (**the entire citation graph regardless of publication** — an
  anonymous reader could enumerate the shape and size of the evidence base behind every unpublished
  candidate); anonymous read on `core.lineage`. All three fixed and verified by `SET ROLE anon`.
- **A:** the vector-tile query transformed geometry inside the predicate, which is not sargable.
  Measured on 50,000 points: **547.9 ms sequential scan versus 0.29 ms bitmap index scan** — ~1,890×,
  degrading linearly. The acceptance suite now inspects the actual query plan.
- **A (no canary containment):** nothing prevented an entity created from a fabricated canary name
  being published, which destroys the hallucination measurement.
- **Both:** a claimed place name with **no coordinates at all** was unrepresentable. Both schemas' CHECK
  constraints forced claimed-only geometry to carry a shape. That case is in the calibration set.

**Four defects were mine, found by my own tests**, and I note them because they are the shape of thing
that survives a code review and dies in a test:

- A single-pass drain cannot see rows the loop itself enqueues, so children re-queued by a parent
  regrade kept a stale clamp until some unrelated later write.
- `caps := caps || 'CAP-1'` resolves to `anyarray||anyarray`, not `anyarray||anyelement`, because the
  literal is untyped. **Every capped proposition failed with "malformed array literal" and was silently
  swallowed by the queue's exception handler, leaving it ungraded.** Proposal A had the `::text` cast; I
  had dropped it.
- The evidence-state hash went stale whenever evidence landed that did not change the letter, because a
  grade event is only written on movement — so the publication gate would pass on a grade that predated
  the current evidence.
- Publishing an entity flipped `publication_state` on all its observations, re-firing the regrade
  trigger and leaving the queue permanently non-empty after every publish, making *"is anything
  stale?"* unanswerable.

---

## 4 · WHAT THE FLEET CORRECTION MEANS FOR W1

### The load moved from models to code

W1 as originally conceived opened with blind web fan-out by seven discovery agents. That is now
**phase P4 of eleven**, it is not the first phase, and it writes to two tables neither of which is an
evidence table.

The new shape, and the operational consequence:

| Phase | Nature | Consumes an LLM slot? |
|---|---|---|
| P0 egress precondition | code | no |
| P1 corpus acquisition | code, long, most kill-prone | no |
| P2 seeding by index enumeration | code | no |
| P3 decomposition (PROPOSER) | agent | yes |
| P4 discovery | agent | yes |
| P5 verification V-1…V-5 | code | no |
| P5 entailment V-6 (ENTAILER) | agent, different family | yes |
| P6 silence / negative receipts | code + agent | mostly no |
| P7 lineage + resolver | code (graph) | partly |
| P8 refutation → assessment → **grade** | agents, then **SQL** | yes for the first two, **no for the grade** |
| P9 publication + telemetry | code | no |
| P10 completeness critic | agent | yes |

**A substantial fraction of W1 needs no model at all.** With zero LLM slots available, P0/P1/P2/P5-code
/P6/P7 continue to make progress unattended. That is the single most important property for a project
that has been killed by usage limits twice.

### Three W1 blockers that did not exist before

1. **EGRESS (P0).** Nothing in the fleet fetches anything today. BES is built entirely on
   resolve-or-die. Without working egress to cia.gov, apps.dtic.mil, catalog.archives.gov, govinfo.gov,
   comptroller.war.gov, county recorders and the rest, **every receipt fails, every candidate is V0, and
   the entire register grades F** — which looks exactly like a register full of findings. P0 halts W1 if
   the canonical EXIST/LOCATE corpora are predominantly blocked. **This is the correct behaviour and you
   should expect it to fire.**
2. **VERIFY.** No agent in the current fleet resolves a citation to bytes. ARCHIVIST finds, LINEAGE
   traces, REFUTER argues, ASSESSOR scores — **nobody fetches.** VERIFY is code: a fetcher, a hasher, a
   substring locator, an alias-set matcher and fifteen identifier grammar validators.
3. **SILENCE.** No agent records a search that found nothing. Without receipted absence there is no
   SCI, no expected-record machinery, no licensable F or R, and no X band. *Absence is not citable
   without a receipt for the absence.*

And one architectural requirement that is not negotiable:

4. **A SECOND MODEL FAMILY.** Needed in three places that cannot be served by the same weights: V-6
   entailment adjudication; the blind second read that promotes an agent's interpretation of a primary
   artifact out of T5; and the 10% double-scoring sample. **If only one family is available, W1 proceeds
   but publishes that it has no independent verification and caps accordingly.** That decision is made
   in P0, before any grade is written — not discovered afterwards.

### The degradation rule, which you should ratify explicitly

> **Under contention, verification and adjudication always outrank discovery.**

The register's failure mode is unverified volume, so starving discovery is the *correct* degradation.
With one LLM slot, the pipeline drains P5/P8 to empty before P4 gets the slot back. This will feel
wrong — it looks like the project has stopped finding things — and it is right.

### Checkpointing, given that this workflow has been killed twice

**The database is the checkpoint.** No in-memory state survives a turn.

- One agent invocation = one work item, in one transaction. Lease → do → write → mark DONE. **A kill
  mid-item loses that item only.**
- Work-item granularity is chosen so an item completes inside a single agent turn: one lead to verify,
  one proposition to score, one (corpus × tile) sweep. **This — not a checkpoint file — is the actual
  defence against usage limits: the cost of a kill is bounded at minutes by construction.**
- Leases expire at 30 minutes and are reclaimed by a single UPDATE with no manual intervention.
- **Phase gates are queries, not flags.** "P5 is complete" is `NOT EXISTS (... status IN ('PENDING',
  'LEASED'))`. Re-running the driver from scratch is always safe.

This document exists because the same failure has now happened twice at the same point — the
consolidation step at the end of a long research phase. The work products in this repository were
written **incrementally, one complete file at a time**, for the same reason.

---

## 5 · WHAT IT COSTS TO RUN W1

Given ~2-way agent concurrency and the expectation of repeated usage-limit kills.

### Wall-clock, by phase

| Phase | Dominant cost | Rough duration | Kill sensitivity |
|---|---|---|---|
| **P0** egress | ~160 HTTP probes + robots fetches, politely paced | hours | **very low** — pure code, fully resumable |
| **P1** corpus acquisition | Bandwidth and disk. `historicaltopo.csv` ~185 MB; USAspending monthly dump is the large one; FRUS is a git clone | **days**, dominated by the USAspending dump and 3DEP/WESM | **low** but this is *the* long pole. Range-resumable, one work item per file |
| **P2** seeding | Local queries over the acquired indexes | hours | very low |
| **P3** decomposition | 1 agent turn per entity | proportional to entity count | low — one entity per item |
| **P4** discovery | 1 agent turn per (agent × beat × subject) | **unbounded by design** | low |
| **P5** verification | ~10 network resolutions per candidate proposition; the rest local | throughput-bound, not model-bound | low |
| **P6** silence | Batched corpus sweeps: one pass serves many propositions | hours per sweep | low |
| **P7** lineage | Graph computation, O(seeds × reachable) per grade | seconds per proposition | low |
| **P8** grading | **SQL**. Not an agent | milliseconds | none |
| **P9/P10** | code + one agent | hours | low |

**Two clock-dependent items must be filed on day one or they become day-thirty blockers:** the EROS M2M
access request (24–48 business hours, gates *all* declassified imagery) and the api.data.gov key
registration (SAM keys take up to ten business days).

### Model spend

The honest number, and it should be stated before anyone budgets a sweep:

> **A candidate that cost one adjudication pass under v0.1 costs perhaps five to eight here.**

Propositions multiply rows; receipted negative searches multiply queries; REFUTER now scores every
observation and runs at band A on the inverted threshold; verification adds a fetch, a hash, a metadata
comparison and an alias match per source.

But the composition changed favourably. Per candidate, roughly:

- **PROPOSER:** 1 turn.
- **Discovery:** N turns, and N is a recall-tuning knob, not a correctness requirement — parallelism
  buys recall and contributes exactly nothing to corroboration.
- **ENTAILER:** 1 turn per *verified* lead — and only leads that survive V-1 through V-5 reach it, which
  is a small fraction. **The grammar and resolution filters do most of the work for free.**
- **REFUTER + ASSESSOR:** 1–2 turns per proposition, with drastically reduced output shape. ASSESSOR no
  longer invents six numbers; it emits a scope, a locus, a sign, a fact key, and a catalog ID or two
  ordinals.
- **GRADER:** zero. It is SQL.

**Verification is not the model bottleneck.** Verification cost is dominated by fixed corpus
acquisition, and after P1 most identifier classes verify offline in sub-millisecond time with no
network at all. The belief that a verification tier is prohibitively expensive is what caused it to be
omitted from v0.1, and it is wrong.

### The rate-limit budget that actually binds

**NARA Catalog: 10,000 queries per month, hard cap.** That is an explicitly allocated budget and
**verification always outranks discovery inside it** — an unverified citation is worth less than no
citation. Other documented limits (loc.gov 10 bulk requests / 10 min / IP; Open ONI 1 rps; SAM.gov ~1
rps regardless of documented quota; FPDS ATOM 10 records/page; FERC EQR max 3 concurrent) are handled
by per-host token buckets, so one throttled host cannot stall verification globally.

### What you get for it

Be prepared for this: **the modal register entry will be X or D, and it should be.** §12.6 targets that
deliberately. The first public version will look, to a casual reader, like an empty database with
elaborate excuses.

> **The most likely way this model gets quietly abandoned is by weakening the SCI floor under pressure
> to look substantial, and that abandonment will not announce itself.**

That pressure will come from inside the project, not from an attacker, and no schema constraint can
resist it.

---

## 6 · WHAT REMAINS UNRESOLVED

Ordered by how much I think it should worry you.

**1 · The 158-source registry may be substantially wrong, and P0 will tell us.** Three of five
registries were written with .gov/.mil egress blocked; every endpoint grammar, parameter name and
identifier scheme was reconstructed from search snippets, GitHub client code and prior knowledge. P0
may discover that a large fraction of the project's foundational asset is fiction **of exactly the kind
the verification tier was built to catch.** The register's own W0 output has not been through the
register's own verification tier. It should be, and that work has not been costed. **This is the single
biggest unknown in the plan.**

**2 · `authority_over_fact` is specified and empty.** §3.4 condition (e) — *the issuing body has
authority over the fact* — does the discriminating work in the highest-stakes gate in the model, and it
was originally a model judgement smuggled in among five lookups. It now belongs in a fifth
reviewed-write curated table. **Until CURATOR populates it, every D4 assignment is provisional in a way
the grade row does not currently record.** That is a small schema change and a real curation task.

**3 · Cross-family independence is asserted, not measured.** The design leans hard on "a different
model family" — for V-6, for the T5-promoting second read, for REFUTER, for double-scoring, for the
lineage counterfactual quorum. Different families share training corpora, share the contaminated open
web, and plausibly share the specific errors this domain is full of. Two families agreeing that a span
"states the proposition on its face" is weaker evidence than the design treats it as, **and nobody
knows how much weaker.** The telemetry measures agreement, which is not independence.

**4 · The physical archive queue is a promise, not a capability.** R-PENDING-ACQUISITION converts
blindness into a work queue, but nobody visits College Park, nobody pulls RG 373, nobody scans county
minute books from 1962. **The grade distribution this register publishes is therefore a map of
digitisation, not a map of evidence.** That bias is not correctable by design — only disclosable, and it
must be disclosed on the methodology page in those words.

**5 · Forgery, and the authoritative issuer that does not authenticate.** There is no defence against a
well-executed forgery that resolves at the issuing authority, quotes at the claimed offsets, matches
issuer metadata and binds to the subject. The sharper version, which is unmonitored as well as
unblocked: **the tier table conflates *authoritative* issuers with *authenticating* ones.** A county
recorder has authority over the fact of recording and none over the facts a deed recites — and §4.3
lists "a deed or court record reciting the structure" as a D4 anchor while §6.3 makes county deed
records "X3 — the universal floor." That is a genuinely cheap path to a D4 row. `authority_over_fact`
narrows it and does not close it, because the authority is real; it is the *scope* being exceeded.

**6 · ORIGIN corruption by regeneration.** A machine-generated page becomes the first observed
appearance of a claim, and the register dates the origin to a regeneration rather than to its true
earlier source. Since ORIGIN is the class that lets the register publish an A-grade fact about a
fabrication — the most distinctive thing it does — a systematically wrong origin date corrupts that
output **in the direction of understating how old and how contaminated a claim is.**

**7 · Alias sets are an unaudited attack surface.** Subject binding is only as good as the alias table,
which an LLM proposes into. An alias that is too generic — "Site R", "the Bunker" — silently widens
binding across unrelated documents and converts CLASS-scope rows into INSTANCE-scope ones, which is
exactly the promotion path CAP-2b exists to block. **Nothing in the telemetry measures binding
precision**, and I do not see how to measure it without labelled data.

**8 · Verification debt at the bottom never clears.** Priority-by-marginal-grade-impact guarantees
nothing published rests on unverified evidence. Its corollary is that low-band propositions may never
be verified at all — harmless for grading, harmful for **refutation**, because R requires affirmative
disconfirming evidence and we will systematically not look for it on entries nobody is defending. A
long tail of permanently-D/E entries that are in fact refutable will accumulate.

**9 · Semantic clustering false merges: direction safe, magnitude unknown.** Collapsing genuinely
independent witnesses into one lineage **under**-counts corroboration. That is the safe direction and
it is deliberate, but the error rate is unmeasurable without ground truth on lineage, which does not
exist for this corpus. **The register will under-grade an unknown fraction of real facilities and will
never be able to say which ones.**

**10 · Three ratification items are rubric bugs implemented literally.** I did not smooth them, because
the schema should not quietly invent rubric:
- **R-1:** an R grade is not withheld by the SCI floor even when search is incomplete, because step 1
  returns R before step 2 applies. I kept it — an affirmatively established refutation does not become
  unestablished for want of further searching, and publishing X over a documented contradiction is
  worse. Needs ratification either way.
- **R-3:** a proposition with strong D4 support **and** one unrebutted D3 undercut falls through A/B/C,
  fails D and fails E, and lands at **F** — beneath a middle band, on strong evidence. The acceptance
  suite reproduces it. **The fix belongs in BES v0.2.1, not in the SQL.**
- **R-2:** Dulce returns R where both lenses expected F. Declared divergence, argued in
  `docs/GRADING.md` §17.2.

---

## 7 · WHERE THE REVIEWERS DISAGREED WITH EACH OTHER

Recorded rather than smoothed, because a suite that hides its contested cases stops detecting drift
exactly where drift matters. Full arguments in `docs/GRADING.md` §17; the decisions:

| Case | Historian | IC analyst | Decided |
|---|---|---|---|
| Greenbrier 1991 EXIST | C on evidence + P(exists) as a number | B | **B**, IC reading taken; the requested probability declined and replaced by ceiling + silence reading + base-rate reading |
| SubTropolis HARDEN | R | F | **R** — the null is not merely complete but *affirmatively documented and publicly advertised* |
| DIA FUNCTION | F | E | **E** — V is not empty; F would misdescribe the evidentiary state |
| DUCC EXIST | R | F | **R** — cancellation is affirmatively documented, which is R3 by definition |
| Dulce | F | F | **R** — declared divergence; their F was bounded by a vocabulary in which R did not exist |
| Mount Weather "underground city" | D | — | **E** — one band, conservative, argued |
| KUMMSC / Cartwheel / Nike magazine | B (composite) | B (composite) | **pairs** — the composite has no BES analogue; satisfied by decomposition, **must not be reported as a letter match** |

One reviewer case forced a change to the rubric text itself: **Bob Lazar / S-4**. He is a real,
publicly identifiable, on-the-record named individual whose *credentials* are the disputed element — so
he passes any identity gate. §5.4 was rewritten as a **position-to-know** gate: the record must place
the person *in the role asserted*, predate the claim, and have been created for an unrelated purpose.

---

## 8 · WHAT I RECOMMEND

**Ratify BES v0.2 and the schema.** Both are executable and both are tested. The three ratification
items (§6.10) are known, argued, and do not block W1.

**Then, in this order:**

1. **Run P0 before anything else, and be prepared to halt.** It is cheap, it is pure code, and it
   determines whether the rest of the plan is real. Its output — per-host egress status and re-verified
   endpoint grammars — is also the first genuine evidence this project has produced about its own
   foundational asset.
2. **Decide the model-family question in P0, not later.** If only one family is available, the register
   publishes that it has no independent verification and caps accordingly. That is a public statement
   and it should be a deliberate one.
3. **File the EROS M2M request and register the api.data.gov key on day one.**
4. **Populate `authority_over_fact` before any D4 is assigned.** It is a small table and a real curation
   task, and every D4 made before it exists is provisional.
5. **Run the 32 calibration entities through the live pipeline as the W1 exit gate**, not as a
   post-hoc check.

---

## 9 · THE ONE DECISION I NEED FROM YOU

**Is the register permitted to run W1 with a single model family?**

Everything else in this document is a plan I can execute. This one is a policy question about what the
register is willing to publish about itself, and it must be answered in P0 because it changes what
every subsequent grade means.

- **With two families:** V-6 entailment is genuinely adversarial; D4 requires two families to agree;
  the T5-to-evidence promotion for raster interpretation is a real second read; the 10% double-scoring
  measures something. The design works as specified.
- **With one family:** V-6 is self-verification, the second read shares the priors that produced the
  first, double-scoring measures agreement with itself, and **the entire second line of defence
  collapses to a banner on the methodology page.** The register still functions — resolve-or-die,
  subject binding, the diagnosticity catalog and the caps are all family-independent — but its claim to
  independent verification is not merely weaker, it is absent, and it must say so.

I have built for both. The design does not fail with one family; it publishes a narrower claim. But
**the choice must be made before the first grade is written, not discovered after the register is
populated** — because a grade produced under single-family verification and a grade produced under
two-family verification are not the same object, and there is no honest way to retrofit the
distinction.

---

## APPENDIX — WHAT IS ON DISK

| Path | What it is |
|---|---|
| `docs/GRADING.md` | BES v0.2, complete and self-contained. An adjudicating agent applies it from this file alone |
| `docs/CALIBRATION.md` | 34 merged regression cases + 6 pipeline tests + 8 suite-level assertions; known divergences marked |
| `supabase/schema.sql` | The adjudicated DDL, 215 KB, executable as-is |
| `supabase/test_acceptance.sql` | 65 assertions, 0 failures on PostgreSQL 16.13 + PostGIS 3.4 |
| `docs/SCHEMA.md` | Prose: what each table guarantees, and why it is shaped that way. Worked queries |
| `docs/FLEET.md` | The corrected agent architecture, the verification tier, the W1 design and its checkpointing |
| `docs/SOURCE-REGISTRY.md` | All 158 sources, by beat then by value, complete and untruncated |
| `docs/FOUNDATION-REPORT.md` | This document |
| `db/final/`, `db/evidence-centric/`, `db/0*.sql` | The input proposals and the pre-consolidation final, retained |
| `research/raw/` | The rubric adjudications, three critiques and five registries, unmodified |

Apply with:

```
psql -v ON_ERROR_STOP=1 -f supabase/schema.sql
psql -v ON_ERROR_STOP=1 -f supabase/test_acceptance.sql
```
