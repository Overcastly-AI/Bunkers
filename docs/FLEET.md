# FLEET — THE CORRECTED AGENT ARCHITECTURE

Supersedes WORKFLOW.md §2. Companion to `docs/GRADING.md` (the model) and `docs/SCHEMA.md` (the
enforcement).

**The single largest change from v0.1: most of this fleet is code, and no agent in it assigns a
grade.** The §9.4 algorithm runs as PL/pgSQL (`core.evaluate_proposition`). An agent's entire
contribution to a grade is a scope, a locus, a sign, a fact key, and either a catalog ID or two E/A
ordinals.

**The second largest change: a verification tier now sits between discovery and adjudication, and
nothing reaches the evidence table without passing through it.**

---

## PART 0 — THE GOVERNING CONSTRAINT

The v0.1 integrity rule was *"Every claim in the database carries a citation. No orphan facts."* It
fails because it tests a **string**. A confabulating LLM satisfies it 100% of the time.

The replacement is a **privilege separation enforced in the schema, not in agent briefs**:

> **No LLM has INSERT on `core.observation`, `core.retrieval_receipt`, or `core.lineage`. Discovery
> agents can write to exactly two tables: `ingest.lead` and `ingest.null_return`. The only writer of
> observations is deterministic verification code.**

An agent's citation is therefore **not a citation**. It is a *hypothesis about the existence of a
document*, and it is stored as such. That is the whole design in one sentence: BES §2.2 already says
an unresolved row is tier V0 and arithmetically inert; this tier makes V0 the **default state of
everything an agent says**, rather than a punishment applied later.

**`ingest.lead` rejects unquotable claims at INSERT.** A lead requires `identifier` +
`identifier_class` + `claimed_issuer_metadata` (title, date, issuing body) + a **verbatim
`claimed_span`** + a `proposition_id`. *An agent that cannot produce a quotable span has not found a
document.*

**There are no `origin_tier`, `diagnosticity`, `scope`, `property_locus` or `grade` columns on
`ingest.lead`.** An agent cannot assert them because the fields do not exist.

---

## PART 1 — THE VERIFICATION TIER: V-0 THROUGH V-6

Each stage is code unless marked. A lead traverses them in order; failure at any stage terminates with
a **recorded state, never a silent drop.**

### V-0 — EGRESS PRECONDITION (per host, not per lead) · **W1 blocker**

This is stage zero because it is what stops a network failure from being misread as agent fabrication.

```
registry.egress_probe(host, robots_txt_sha, robots_posture, reachable, http_status,
                      rate_limit_observed, mirror_designated_for, last_probed_at,
                      status ∈ {OPEN, THROTTLED, BLOCKED, MIRROR-ONLY})
```

Probed on a schedule and **published**. Consequences, per BES §2.6:

- unreachable issuer → resolution may fall to a designated faithful mirror with `MIRROR-ONLY` and
  CAP-6 (max B);
- unreachable canonical corpus → the corresponding search returns `UNSEARCHED`, **never** `NEGATIVE`,
  and SCI falls.

**Three of the five W0 registries were written with .gov/.mil egress blocked, so every endpoint grammar
in the 158-source registry is currently unverified.** V-0 re-verifies each against the live target and
fetches every robots.txt before discovery is permitted to start.

### V-1 — GRAMMAR + INTERNAL CONSISTENCY (deterministic, zero network)

Fifteen identifier grammar validators: CREST CIA-RDP · DTIC AD (with ADB-prefix detection) · NARA
NAID · GAO report number · Federal Register citation · GovInfo package ID · FCC ASR/ULS · FPDS PIID ·
FRUS volume+document · USGS quad name+year · county parcel ID · MSHA MINE_ID · AFHRA IRIS · DOI · IA
identifier.

> **Grammar failure is informative; grammar success is worthless.**

That asymmetry is the skeptic's entire finding and V-1 is written to respect it: it is a **cheap reject
filter and a telemetry source, never a pass criterion.** Its output feeds the published
*format-valid-but-unresolvable* rate.

What V-1 *can* do beyond regex is **cross-field arithmetic impossibility**, which catches a meaningful
slice of confabulation before any network call:

- Federal Register volume ↔ year (vol = year − 1935) and page ≤ that volume's final page.
- DTIC AD accession number vs asserted report date, against a table of AD-number/year anchors —
  accessions are near-monotone in time, so a 1962 report with a 1990s-range AD number is impossible.
- CREST CIA-RDP record-group prefix vs asserted document date.
- GovInfo package ID must encode a real Congress/session; NAID must be in issued ranges.
- **USGS quad citations resolve fully offline** against the local 186,061-row `historicaltopo` index —
  name, scale and imprint year must all match a real sheet. Zero network, zero cost, 100% coverage.

### V-2 — RESOLUTION (network or local mirror, deterministic)

Fetch at the **issuing authority's own interface** first. Store `resolved_url`, `http_status`,
`sha256_of_bytes`, `retrieved_at`, `content_type`, and the bytes into the content-addressed store.

Resolution preference order, recorded as `channel`:

1. issuing authority → `ORIGIN-HOST`
2. designated faithful mirror from `registry.corpus` → `FAITHFUL-MIRROR`, flagged `MIRROR-ONLY`, CAP-6
   applies
3. nothing → V0

**The three-way failure split, and why collapsing it would be a serious error:**

| State | Meaning | Counts as |
|---|---|---|
| `UNRESOLVED-NOTFOUND` | The issuer answered authoritatively that no such record exists (CREST/DTIC/NARA search returns zero for that exact accession) | **measured fabrication** — the only state that counts toward an agent's confabulation rate |
| `UNRESOLVED-UNREACHABLE` | Timeout, 403, egress block, rate-limit exhaustion | Counts against SCI and against the host's egress status. **Not** fabrication |
| `DEAD` | Previously resolved, now 404 | Drift signal; fires a revalidation alert |

*A blocked proxy would otherwise inflate the published fabrication metric and let the register
attribute its own network failure to its agents.*

### V-3 — ISSUER METADATA MATCH (deterministic)

The retrieved record's *own* metadata versus what the agent asserted in the lead. Title compared by
token Jaccard over a domain stoplist against a threshold; date exact or within the artifact's stated
granularity; issuing body against a controlled vocabulary.

Mismatch → `MISATTRIBUTED`, routed to review, **not silently accepted**.

**This catches the very common failure that no existence check ever detects: a model recalls a *real*
accession number and attaches the wrong title to it.**

### V-4 — SPAN LOCATION (deterministic, non-LLM)

The claimed verbatim span must be located in the retrieved bytes by **exact match** after a
**versioned normalization pipeline**: NFKC, whitespace collapse, line-break de-hyphenation, ligature
expansion, quote/dash folding, case preserved.

Record `span_start_offset`, `span_end_offset`, and the hash of the normalizer version, so offsets
remain interpretable across normalizer changes.

**Fallback for scanned material:** a bounded edit-distance second pass (≤2% of span length) sets
`quote_check = FUZZY-OCR`. **A FUZZY-OCR row is capped at D3 and can never satisfy the §3.4 gate**,
because condition (d) requires the span to state the proposition *on its face* and a fuzzy match is
not that.

**`text_layer_provenance ∈ {native, publisher-ocr, ia-djvu, own-ocr, own-ocr-vision}`** on the
receipt. A span "located" in text this pipeline generated with a vision model is a weaker receipt than
one in a native text layer; **`own-ocr-vision` cannot support D4.** This matters because CREST is
essentially all OCR and raster reading is the single most hallucination-prone operation in the fleet.

**Failure to locate the span at all → V0, logged as a fabricated-quote event** — the most damning and
cheapest telemetry in the system.

### V-5 — SUBJECT BINDING (deterministic, BES §2.3)

The bytes must contain, in the quoted span or a second receipted span from the same document, a token
resolving to the subject's **RESOLVER-maintained alias set**: facility name, installation + building
number, RPUID, parcel ID, MINE_ID, FCC ASR number, coordinate, or a codename carrying an `IDENTITY`
proposition at C+.

Coordinate binding needs its own parser and its own restraint: DMS, decimal, UTM, MGRS, and **PLSS
section/township/range** — essential, because pre-1970 federal records locate by PLSS, not lat/long.
**Coordinate-only binding is capped and cannot alone establish INSTANCE scope**, because "a coordinate
near the subject" is exactly the ADJACENT trap §2.4 exists to close.

Failure downgrades `scope` INSTANCE → CLASS, which removes the row from V(P) — **without deleting
it.**

### V-6 — CLAIM-SUPPORT ADJUDICATION (the subtle failure; the one unavoidable model role)

Stages V-1 to V-5 prove a real document exists, is the document claimed, and is about this subject.
**They do not prove it says what the discoverer said it says.** That is the one place a model cannot be
avoided. It is therefore made as narrow, as blind, and as one-directional as possible.

**Input — structurally bounded data, never free prose:**
- the proposition rendered as a canonical sentence from the 12-class template (§1.2), **not** the
  discovering agent's wording;
- the verified span plus bounded context;
- the subject-binding span;
- the named `null_hypothesis` from §4.5.

**Withheld:** the agent's narrative, the site dossier, other evidence rows, the proposed
diagnosticity, the current grade. *The adjudicator is starved of everything that would let it
rationalize toward a conclusion.*

**Output — one forced-choice label from a closed set, plus a sub-span justifying it:**

`STATES-ON-FACE` · `ENTAILS` · `CONSISTENT-WITH-BOTH` · `UNDERCUTS` · `IRRELEVANT`

**Mapping to BES, and the critical property — V-6 can only demote:**

| Label | Effect |
|---|---|
| `STATES-ON-FACE` | *permits* a D4 assessment if the §3.4 gate also passes |
| `ENTAILS` | ceiling D3 |
| `CONSISTENT-WITH-BOTH` | forces **D0** — this is the ACH discipline made mechanical |
| `UNDERCUTS` | **flips `sign`** to UNDERCUTS at the stated magnitude |
| `IRRELEVANT` | V0 |

**Final diagnosticity = `min(catalog-or-matrix assignment, V-6 ceiling)`.**

> **A model that can only lower a grade cannot inflate the register. That asymmetry is what makes an
> LLM safe in this seat.**

**Escalations:**

- A `STATES-ON-FACE` label — a claimed D4, the highest-stakes decision in the whole model — requires
  **two model families to agree**. Disagreement caps the row at D3 and is logged, **never resolved by a
  third same-family vote.**
- §3.4 condition (e) — *the issuing body has authority over the fact* — is **removed from model
  judgement entirely** and becomes a **fifth reviewed-write curated table**:
  `authority_over_fact(issuing_body, proposition_class, has_authority, basis, version)`.
  BES §12.1 promises every quantity is "a receipt, a lookup, a count, a boolean, or one of two
  adjudicated judgements," and (e) as written is a **sixth judgement smuggled into the most
  load-bearing gate in the model.** The FCC has authority over a licence and not over hardening; a
  recorder of deeds has authority over the *fact of recording*; The Intercept has authority over
  nothing. **That belongs in a table.**
- **The adjudicating family must differ from the discovering family.** If only one family is available,
  V-6 is self-verification and the register must publish that it has no independent verification and
  cap accordingly.

---

## PART 2 — THE GRADED FALLBACK FOR DOCUMENTS THAT CANNOT BE AUTO-RESOLVED

Discarding these classes guts the register. The registries' own `gaps` sections establish that ~96% of
NARA textual holdings are undigitised; that RG 77/374/397 is where the construction record actually
lives; that pre-1994 congressional material — the hearings where these facilities were funded — is
scanned-only or behind ProQuest; that county records digitise back only to the 1990s; and that AFHRA is
an index rather than a corpus.

> **The best evidence in this domain is disproportionately unfetchable.**

The answer is a **custody ladder** (`receipt_class`) where the cap is tied to *what was actually
checked*, never to how valuable the source is. The full table is in `docs/GRADING.md` §2.8. Two
properties make it defensible rather than a loophole:

1. **The cap follows the check, not the prestige.** A NARA folder title is capped at D2 not because it
   is offline but because **a folder title cannot state a proposition on its face**. A paywalled
   ProQuest hearing transcript quoted by a cited monograph is D3 for exactly the same reason a free one
   would be.
2. **R-PENDING-ACQUISITION converts blindness into a work queue.** It emits
   `acquisition_task(class ∈ {FOIA-request, NARA-pull, digitisation-on-demand, ILL, purchase,
   on-site-visit, microfilm-scan, county-records-request}, cost_estimate, latency_estimate)`.
   Successful later acquisition **promotes** the row, which §11.3's asymmetry permits because the
   document's own date precedes publication. Transition cause `NEW-VERIFICATION`, rendered distinctly
   from `NEW-DISCLOSURE`.

`SILENCE-KNOWN-WITHHELD` is the silence reading this produces: *"we know the record exists, we know
where, we cannot have it yet."* Materially different from UNINFORMATIVE and from UNSEARCHED.

---

## PART 3 — COST, RATE LIMITS AND THROUGHPUT

### Layer 1 — most verification is a local lookup, not a network call

The registries' own bootstrap sequences make the majority of citation classes resolvable **offline**
after a one-time pull: `historicaltopo.csv` (186,061 sheets, 185 MB, into PostGIS with a GiST index) ·
`MapIndices_National_GPKG` · `WESM.gpkg` · USMIN · MSHA `Mines.txt` · MRDS · FRUS (a `git clone` of
structured TEI) · Federal Register bulk · FRPP annual CSV · the USAspending monthly Postgres dump ·
FCC ULS/ASR bulk `.dat`.

After that, a quad citation, a MINE_ID, an ASR number, a PIID or a FRUS document verifies in
**sub-millisecond time with no network at all.**

> **The leading cost fact: verification cost is dominated by fixed corpus acquisition, not by
> per-citation traffic. The belief that a verification tier is prohibitively expensive is what caused
> it to be omitted, and it is wrong.**

### Layer 2 — per-host token buckets, using the registries' documented limits

loc.gov 10 bulk requests / 10 min / IP · Open ONI 1 rps with identifying UA · Wikimapia 100 / 5 min ·
SAM.gov ~1 rps regardless of documented quota · FPDS ATOM 10 records/page (window by date, never
paginate deep) · FERC EQR max 3 concurrent · **NARA Catalog 10,000 queries/month hard cap.**

The queue is priority-ordered **per host**, so one slow or throttled host cannot stall verification
globally. The NARA cap is an explicitly allocated budget, and **verification always outranks discovery
inside it** — an unverified citation is worth less than no citation.

### Layer 3 — priority by marginal grade impact. This is the replacement for sampling

For every unverified lead, compute whether resolving it could change the published band: claimed
diagnosticity × distance to the next band × whether it is the current `limiting_condition`. Verify in
that order.

The consequence is the defensible position:

> **Nothing that is load-bearing is sampled. Every published grade is fully verified up to its own
> band, and unverified leads sit below the waterline where they cannot change it.**

Sampling a citation that determines a published band means the band is a claim about evidence nobody
looked at — precisely the failure being fixed. Reordering achieves bounded cost without that
concession. The residue is published per proposition as **`verification_debt`**: the count of
unverified leads and the maximum band the proposition could reach if all of them resolved.

### Layer 4 — sampling used only where it is a legitimate statistical instrument

A rolling **10% blind re-verification of already-VERIFIED rows** by a different model family with a
fresh fetch (catches V-6 error and content drift), plus the §12.4 canary programme. This estimates an
*error rate over a population*; **it does not license an individual claim.** Those are different
statistical objects and only the second is indefensible.

### Layer 5 — batching

Multi-identifier resolution where the API supports it: HathiTrust bib API 20/batch, NARA multi-NAID,
GovInfo `offsetMark` cursor for permanent incremental sync. **Negative-search receipts batch by corpus
sweep**: one pass over a canonical corpus yields N negative receipts for N propositions at the cost of
one pass — which is what makes BES §6 and §7 affordable at all.

### Layer 6 — cache-and-revalidate, never cache-once

Revalidation interval keyed to `adversary_writable` and tier: T1 origin-host annually, T4 monthly,
ADVERSARY-WRITABLE re-fetched on every citation use. Drift fires an alert; **a source that changes
after being cited is a signal.**

### OCR is the real cost centre

Policy: **never OCR to find, only OCR to verify a specific span.** Prefer Internet Archive `_djvu.txt`
sidecars over own OCR — free, precomputed, and generally better than CIA's own text layer.
Page-target the OCR when the lead names a page.

### Rough sizing

With the local mirrors in place, the network-bound fraction is the archival beat (CREST, DTIC, NARA,
GovInfo, FR, GAO) plus the vernacular/fringe beat — **on the order of 10 network resolutions per
candidate proposition.** At polite pacing across ~8 concurrent hosts this is a few thousand
resolutions/day, comfortably exceeding what 2-way agent concurrency can generate.

> **Verification is not the bottleneck; discovery and OCR are.**

---

## PART 4 — THE AGENTS

### Tier 0 — Preconditions and infrastructure (non-LLM except CURATOR)

| Agent | Phase | Inputs | Outputs |
|---|---|---|---|
| **EGRESS** (code) | P0 | 158-source registry hostnames | `registry.egress_probe`, robots.txt corpus, mirror designations, published per-host status. **Can halt W1** |
| **HARVESTER** (code, rewritten) | P1, continuous | `registry.corpus` | Local bulk mirrors; content-addressed store; documents and receipts. Cache-and-revalidate with drift alerts; `adversary_writable` flag per host; **all fetched text enters as structurally bounded DATA, never free prose in a scoring prompt**; identifiers extracted from untrusted text go to `ingest.lead`, never to a citation |
| **CURATOR** (proposes via agent, assigns by reviewed write) | continuous | Curation proposals | The now-**five** reviewed-write tables: tier ladder (158 rows, one ladder), diagnosticity catalog per typology, ERP profiles, candidate sets (N, M, membership), and **`authority_over_fact` (new)**. Owns the PENDING-tier queue, the candidate-set denominators, and the re-derivation cadence |

### Tier 1 — Discovery (RECALL ONLY)

**ARCHIVIST · CARTOGRAPHER · LEDGER · CIRCUIT · VERNACULAR · PALIMPSEST · FOREIGN** — beats unchanged,
briefs rewritten.

**Verbatim in every brief:**

> *"Your parallelism buys recall. It contributes exactly nothing to corroboration. N agents over one
> indexed web surface one source N times."*

*(That sentence belongs in the briefs because the opposite sentence is currently in WORKFLOW.md §2 and
will be quoted at the project.)*

**Enumerate indexes first, free-text search second.** Walk the NARA `ancestorNaId` series tree; iterate
`historicaltopo` by polygon; page FPDS by date window; sweep MSHA by controller; enumerate FCC ASR by
geography. **Index enumeration is model-prior-independent by construction** and is the primary
discovery mode; free-text search is secondary and is where shared priors bite.

**Write access: `ingest.lead` and `ingest.null_return` only.** No tier, no diagnosticity, no scope, no
grade. **A lead without a verbatim span is rejected at INSERT.**

**Null returns are mandatory and rewarded.** Sites examined and rejected, with reasons. *"I looked and
there is nothing here"* is a first-class output; per-agent telemetry counts it as production. It is
also the base-rate denominator.

**X is expected to be the modal grade for a long time.** Stated in every brief.

### Tier 1.5 — Structuring

| Agent | Phase | Inputs | Outputs |
|---|---|---|---|
| **PROPOSER** (new) | P3 | entity + leads | `core.proposition` rows in the closed 12-class vocabulary with subject, `predicate_args`, `as_of_date`, and **mandatory** `null_hypothesis` (lookup from §4.5). Always ≥ EXIST and TYPOLOGY. Default grade X, default typology `unknown-anomaly`. **Without this agent, site-level dossiers return and the unit error comes back through the back door** |
| **RESOLVER** (rebuilt) | P7 | entities, aliases | Maintains the **alias sets that V-5 subject binding matches against** — entity resolution is now a *verification input*, not bookkeeping. Proposes `IDENTITY` propositions (merge requires C+), `DISTINCT-FROM` relations seeded from the calibration set, and **splits**. Evidence never pools. **If a merge raises a grade, the merge is rejected** |

### Tier 2 — VERIFICATION (the new tier; mostly code)

| Component | Phase | Inputs | Outputs |
|---|---|---|---|
| **VERIFY** (code: V-1…V-5) | P5 | `ingest.lead` | receipts, quoted spans, observations or V0; `receipt_class`; `acquisition_task`; confabulation telemetry |
| **ENTAILER** (V-6; **different model family**; demote-only) | P5 | canonical proposition sentence, span, binding span, named null — nothing else | Forced-choice label + diagnosticity ceiling. Two-family agreement required for STATES-ON-FACE |
| **SILENCE** (new; **W1 blocker**) | P6 | proposition × applicable ERP profiles | `core.search_receipt` with query, corpus, corpus version, `executed_at`, result count; NEGATIVE vs UNSEARCHED distinguished by egress status. Makes SCI computable, makes F and R licensable, makes X-level UNDERCUTS rows possible. **Absence is not citable without a receipt for the absence** |
| **CANARY** (code) | P2/P4 | rotating fabricated facility names with zero corpus presence | `ingest.canary` hits — any citation returned is directly measured hallucination against known ground truth |

### Tier 3 — Adjudication

| Agent | Phase | Inputs | Outputs |
|---|---|---|---|
| **LINEAGE** (rebuilt) | P7 | **verified documents only** | Document citation graph; §5.1 collapse rules as connected components; semantic clustering; **shared-distinctive-error fingerprints**; `corpus_era`; attestation custody; self-exclusion against `core.publication_log`; transparent-compiler pass-through emitting primaries back to P5. Computes `L(Dk)` |
| **REFUTER** (promoted to co-scorer; **different family from discoverer**) | P8 | proposition, V and U rows | (a) names the strongest surviving null from §4.5 and says why the others are weaker; (b) supplies the **A-level for every E/A fallback** — half of every likelihood assignment in the model; (c) proposes UNDERCUTS rows; (d) runs on grades **A and C through R** (inverted threshold). Blanket refute-by-default **deleted**, replaced by a typology-conditional prior: default-refute for high-base-rate mundane categories, default-open for COG/SIGINT/weapons-storage where concealment base rates are high. `A11` mandatory as co-null wherever a T5 lineage supports the claim |
| **ASSESSOR** (output shape drastically reduced) | P8 | evidence rows | Per observation only: `proposition_id`, `scope`, `property_locus`, `sign`, `fact_key`, catalog diagnosticity ID **or** (only where no catalog row exists) the two E/A ordinals, and which §3.4 conditions are satisfied where a gate is claimed. **It no longer invents six numbers.** Every matrix use is logged as a catalog-extension proposal |
| **GRADER** (SQL, not an agent) | P8 | evidence table | §9.4 verbatim: refutation → SCI floor → V/U with fact-key merge → derived `null_state` → bands A–F → seven caps → monotone clamp. Writes a `grade_event` only when the published grade moves |

ASSESSOR's reduction is **the single largest cut in required judgement in the redesign**, and the
reason the model is applicable at scale: the agent is asked *"is this row claim-property or
place-property, and does the mine explanation predict it"*, never *"what is GEO out of 100."*

### Tier 4 — Oversight

| Agent | Phase | Job |
|---|---|---|
| **DOUBLE-SCORER** | continuous | 10% blind re-scoring by a different model family; per-**condition** agreement published. Reference-class assignment and the lineage counterfactual measured first, being the two softest inputs |
| **PRIOR-KEEPER** | continuous | Adjudicates E/A catalog-extension proposals into the diagnosticity catalog, so the fallback path is self-retiring. Owns the §12.5 re-derivation cadence (after 25 adjudications, then every 50 resolved A/R) |
| **COMPLETENESS CRITIC** (rebriefed) | P10 | **May request searches only, never candidates.** Its v0.1 brief — "what region is underrepresented" — manufactures candidates in sparse regions inside a find-rewarded fleet. Its output is now measured in **receipts, not finds** |
| **TELEMETRY** (code) | P9 | Publishes: canary hit rate · format-valid-but-`UNRESOLVED-NOTFOUND` rate per agent · fabricated-quote rate · verification debt · per-host egress status · band occupancy against the X/D modal target · C-band audit trigger (>15%) · R-rate and R-reversal rate · merge/split rate · inter-family agreement |

### Tier 5 — Construction (unchanged, outside W1)

**SCHEMA · ATLAS · INTERFACE · DEPLOY**

---

## PART 5 — SOURCE INDEPENDENCE, COMPUTED FROM THE CITATION GRAPH

### The category error, stated so it cannot return

**Agent independence is not source independence.** N prompts over one set of weights is **one witness
speaking N times in different words.** Blind fan-out is retained for **RECALL only** and contributes
exactly nothing to corroboration.

### Enforced structurally, not by policy

> **`ingest.lead.discovering_agent` and `ingest.agent_run` are not reachable from any grading query.
> `core.observation` carries no lineage column and no agent column that participates in any
> computation. The count of agents that reported a claim is a *telemetry* quantity and is physically
> unable to enter the arithmetic.**

That is what prevents the error from coming back through a later refactor.

### The construction

**1 · Verification is the precondition.** Nothing enters the lineage graph without a VERIFIED receipt.
An unverified agent assertion is not a node in any graph — it is a hypothesis awaiting retrieval.
**This single rule dissolves the skeptic's worked example:** five agents, five fabricated identifiers,
zero resolutions → zero nodes → zero lineages → V = ∅ → CAP-5 → **F**. *The graph fix and the
verification fix are the same fix*, which is why they are one deliverable.

**2 · Nodes are documents; edges are derivation.** Directed and **cyclic**, because a citogenesis loop
*is* a cycle and must be traversed, not prevented. Non-citation derivation edges carry the same weight:
same-author, same-organisation, same-publication, database-replication, semantic-cluster-parent,
shared-distinctive-error.

**3 · A lineage is a connected component under the §5.1 collapse relation**, computed over the
collapsing subgraph and materialised. Every collapse edge stores its reason, and for the counterfactual
rule the full quorum record.

**4 · `L(Dk)` = the count of distinct lineages over `V[Dk+]` after fact-key merge.** Corroboration is a
distinct count of **lineages** — never of documents, URLs, sources, or agents. B1 (`L(D3) ≥ 2`, or
`L(D2) ≥ 3` with a T1/T2 root) and CAP-1 (`L(D2) ≤ 1` → max C) both read this one number.

### Where the computation sits

**Between verification and scoring: phase P7, after P5/P6 and before P8. Per proposition, not per
candidate.** It is a mandatory pipeline stage, not a commentary agent.

It **re-runs whenever a new verified row lands on the proposition**, because lineage membership is a
*global* property: discovering that document B cites document A can merge two previously separate
lineages and **lower the grade**. So:

> **Corroboration is non-monotone. A grade can fall because a link was found, not because evidence was
> lost.**

Transition cause `RE-ANALYSIS`; it is an evidence event and renders on the public confidence chart.

### The counterfactual test, operationalised

§5.1.7 asks whether B would have produced this claim had A never existed. Rather than free judgement,
it is a checklist that mostly resolves mechanically; the model is consulted only where the checklist is
indeterminate.

- **Date test** — B's own artifact date precedes A's → cannot descend from A.
- **Citation test** — B cites A directly or transitively → SAME.
- **Access test (the one that does the real work)** — could B's author have reached the underlying
  *fact* without the *claim*? Parties with direct authority or direct physical access observe the fact,
  not the claim: a county recorder, a contracting officer, an agency filing its own EIS, a utility
  filing an interconnection agreement. **This is why institutional records are effectively the only
  reliable source of independence in this domain** — a recorded deed and a MILCON line item are
  independent because two separate bureaucracies each recorded the same underlying event for their own
  unrelated purposes. Secondary sources are almost never independent of one another, and the default
  reflects that.
- **Fact-key test** — §5.5: rows naming the same underlying real-world fact via the same record event
  merge regardless of independence, which is what stops "this was an AT&T Long Lines station" entering
  as four lineages through four record types.
- **Distinctive-error test** — shared idiosyncratic error (a transposed coordinate digit, a wrong
  elevation, a misspelled contractor name) → SAME, at high confidence. Cheap, classical, and **the only
  derivation signal that survives machine regeneration.**
- **Default: SAME.** Quorum-adjudicated across two model families; disagreement logged, never silently
  resolved.

### Does shared model prior still inflate independence after the graph fix?

**Not through the corroboration channel — verification closes it.** Lineages are documents; finding the
same document twice is one lineage; a document that does not resolve is not a lineage at all. Three
residual channels remain, and they are **different problems** than the one that was fixed:

**(a) Query-selection correlation → recall bias, not corroboration inflation.** Same weights produce
the same queries and surface the same subset of a corpus. This does not inflate any count, but it means
the corpus subset the fleet ever sees is the subset the model's priors point at — **systematically
under-discovering exactly the obscure material the register exists to surface.**
*Mitigation, and it is the strongest one available: enumerate indexes rather than searching them.*
Costs nothing, and the registries already recommend it: *"Do not construct identifiers; enumerate
them."*

**(b) Interpretation correlation.** Two agents of the same family reading the same 1953 quad raster
hallucinate the same adit. §3.1 already makes an agent's interpretation **T5** — a hypothesis, not
evidence — until confirmed by a second read from a different model family *and* a citation to the
era-correct USGS symbol standard for that sheet's imprint year. **Extended here: the second read must
be *blind to the first's conclusion*** (given the raster and the question, never the answer), and
disagreement is logged rather than broken by a third same-family vote.

**(c) Null-hypothesis correlation.** REFUTER shares the discoverer's priors and will name the null the
discoverer expects. Mitigated by making null selection a lookup keyed to `typology_profile` + reference
class from the curated §4.5 set; by `A11` mandatory as a co-null wherever a T5 lineage supports the
claim (both scorings run; the lower grade publishes); and by requiring REFUTER to be a different family
from the discoverer.

**And the honest ceiling:** if only one model family is available, (b) and (c) are unmitigated, V-6
becomes self-verification, and the 10% double-scoring measures nothing. **In that case the register
publishes that it has no independent verification and caps accordingly.** `fleet_capability` is
asserted in P0 so this is decided **before** any grade is written, not after.

### Telemetry that keeps the claim honest

- **Inter-family agreement rate**, published: high agreement on *verified* rows is corroboration; high
  agreement on *unverified* assertions is a shared-prior signature and is logged as such, never as
  corroboration.
- **Document-count minus lineage-count** — the collapse delta, published per proposition. The honest
  replacement for a contamination score: not a judgement, just **the distance between how many sources
  there appear to be and how many witnesses there are.**
- **Citogenesis loop set** — T1/T2/T3 documents citing T5 documents inside the traced set, attached to
  the **proposition**, firing CAP-3.
- **Merge/split rate** — a rising merge rate is an entity-resolution failure signature.

---

## PART 6 — SOLICITED EVIDENCE: HOW CAUSAL ORIGIN IS ACTUALLY TRACKED

BES has `causal_provenance` as a field but no mechanism, and **an agent asked to set it will simply
assert UNSOLICITED.** It is therefore derived from four mechanical signals, never asserted.

**1 · The register's own solicitation log (fully reliable, and self-applying).** Every FOIA request,
records request, docket comment or inquiry made *by this project or its agents* is logged **before it
is sent** — facility named, text, date, recipient. Any artifact matching a logged solicitation is
`SOLICITED-BY-CLAIMANT` permanently. This matters more than it first appears: the
R-PENDING-ACQUISITION queue will *generate* exactly this class of document, and **the register must not
launder its own FOIA requests into support for its own candidates.**

**2 · Span-level segmentation, which is the real answer.** Causal provenance is a property of a **span,
not a document**. A FOIA response restates the request; the restatement is machine-locatable (case
number, "your request dated", quoted request text) and the PDF is split into a
`SOLICITED-BY-CLAIMANT` segment and an `UNSOLICITED` agency-response segment with separate offsets. V-4
records **which segment the verified span falls in**; a span in the requester's half is excluded from
V. Identical treatment for regulations.gov (comment and agency response are different document types
with different identifiers) and for court records (a party's pleading versus the court's order).

**3 · The date rule, which resolves the whole class.** For a solicited document, **only content whose
own creation date predates the solicitation is UNSOLICITED.** *The requester chooses the subject; the
agency chooses the content.* So a no-records letter naming "Site CARDINAL" contributes nothing — its
only claim-bearing content is the requester's own name for the place — while a 1962 engineering drawing
released under that same request contributes fully at D4, because its content is causally independent
of the request that surfaced it.

This is checkable from dates alone, and it means **soliciting evidence remains a legitimate and
valuable research act**: the rule is not "don't file FOIAs," it is *"the artifact is evidence at the
date of its content, and the solicitation is logged and published."*

**4 · Third-party solicitation.** Default `SOLICITED-3P`, admitted to V — *unless* the claim's known
lineage terminus is a known FOIA requester in this subject area (Sauder FOIAs it, then writes the
book), in which case it collapses to `SOLICITED-BY-CLAIMANT` and the row is capped at D2 pending
requester identification. Requester identity is harvestable: agencies publish FOIA request logs, many
release cover sheets print the requester, and Black Vault / governmentattic attribute their own
requests.

`SELF-PUBLISHED` and `CROWD-EDITED` are derived from the host's write model and `adversary_writable`
flag, never asserted.

---

## PART 7 — TYPOLOGY: WHAT THE FLEET MUST SUPPLY

**Confirmed — BES fixes the v0.1 defect.** §1.2 makes `TYPOLOGY` one of the twelve graded proposition
classes, not a filter. Default is `unknown-anomaly`; it cannot change without a TYPOLOGY proposition
clearing **band C**; and asserting a new typology **instantiates the corresponding `FUNCTION` row,
which is then scored**. CAP-2a caps TYPOLOGY at D without a verified claim-property row.

The anti-gaming ledger prices the Mega Cavern attack directly: relabelling instantiates FUNCTION(COG),
which is scored and refuted, and the entry publishes `TYPOLOGY(civil-defence-shelter) A` beside
`TYPOLOGY(COG) R` on the same page without contradiction.

**One circularity BES does not close, and this design closes it.** `typology_profile` *selects the
diagnosticity catalog*, so the table used to score a proposition depends on a typology that is itself
graded. As written, a free relabel would silently change every diagnosticity lookup on the entity — the
Mega Cavern attack in its second form. Fix:

- Scoring runs under the profile of the **graded** typology, never a claimed-but-ungraded one
  (`unknown-anomaly` until TYPOLOGY clears C).
- `typology_profile_version` is **pinned on every grade row** alongside the other table versions.
- A new transition cause, **`TYPOLOGY-CHANGE`**, is required; when a TYPOLOGY proposition changes band,
  every proposition on that entity is re-scored under the new profile and **both scorings are
  retained.**

**What the fleet must supply:**

1. **PROPOSER** emits a TYPOLOGY proposition for **every type any source claims**, including ones the
   register expects to refute — *not emitting is not neutral.*
2. **REFUTER** supplies the competing typologies from §4.5 (A02 mine, A06 storage, A07 data centre, A10
   shelter-designation-only …) as named nulls, and the alternative-hypothesis disposition table renders
   them.
3. At least one **verified, instance-scope, subject-bound, CLAIM-PROPERTY** row naming the function or
   type — CAP-2a, otherwise max D.
4. Every claimed typology above the mundane baseline instantiates its FUNCTION row and inherits CAP-2b:
   **no FUNCTION claim exceeds E without a claim-property row.**

---

## PART 8 — W1: THE FIRST DISCOVERY SWEEP

Designed for **~2-way agent concurrency**, mostly-code execution, and **survival of mid-flight kills**
— which has already happened twice on this project.

### Checkpointing model — the database *is* the checkpoint

No in-memory state survives a turn. Every phase reads its work queue from a table and commits per item.

```
ops.workflow_run(run_id, workflow='W1', phase, status, started_at, last_heartbeat)
ops.work_item(run_id, phase, subject_key, payload,
              status ∈ {PENDING, LEASED, DONE, FAILED, SKIPPED},
              lease_expires_at, attempts, last_error)
```

**Four properties do the work:**

1. **One agent invocation = one work item, in one transaction.** Lease → do → write → mark DONE. A kill
   mid-item loses **that item only**.
2. **Work-item granularity is chosen so an item completes inside a single agent turn.** One lead to
   verify, one proposition to score, one (corpus × tile) sweep. **This — not a checkpoint file — is the
   actual defence against usage limits: the cost of a kill is bounded at minutes by construction.**
3. **Leases expire (30 min).** A killed lease is reclaimable with no manual intervention:
   `UPDATE ops.work_item SET status='PENDING' WHERE status='LEASED' AND lease_expires_at < now()`.
4. **Phase gates are queries, not flags.** "P5 is complete" ≡
   `NOT EXISTS (SELECT 1 FROM ops.work_item WHERE phase='P5' AND status IN ('PENDING','LEASED'))`.
   **Resumption is stateless — re-running the driver from scratch is always safe.**

**Idempotency keys** so a re-run never duplicates:

| Object | Key |
|---|---|
| leads | `(agent_run, identifier, proposition_id, span_hash)` |
| receipts | `(resolved_url, sha256)` |
| search receipts | `(query, corpus, corpus_version, date_bucket)` |
| propositions | `(entity_id, class, subject, predicate_args, as_of_date)` |

### The phases

#### P0 — PRECONDITION (code; **blocking gate**)

Probe egress for every host in the 158-source registry; fetch every robots.txt; **re-verify each
endpoint grammar in the registries against the live target** (three of the five were reconstructed from
search snippets with .gov/.mil blocked); designate faithful mirrors; record `fleet_capability` (how
many model families are available).

**Halt conditions:**
- If the canonical corpora for EXIST/LOCATE are predominantly BLOCKED, **W1 stops.** Running discovery
  without egress produces a register that grades F everywhere and *looks like findings* — the worst
  possible failure mode.
- If only one model family is available, W1 proceeds but sets the global "no independent verification"
  cap and publishes the banner.

Writes: `registry.egress_probe`, published host-status page.

#### P1 — CORPUS ACQUISITION (code; long; the most kill-prone phase, therefore the most resumable)

Registry bootstrap order, **one work item per file**, HTTP Range-resumable:

`MapIndices_National_GPKG` → `historicaltopo.csv` into PostGIS with a GiST index → `WESM.gpkg` → USMIN
→ MSHA `Mines.txt` → MRDS → `git clone HistoryAtState/frus` → Federal Register bulk → FRPP annual CSV →
USAspending monthly dump → FCC ULS/ASR bulk.

**File the EROS M2M access request on day one** (24–48 business-hour approval; gates all declassified
imagery — must not become a day-30 blocker). **Register the api.data.gov key immediately** (SAM keys
take up to ten business days).

**Gate:** resolve 100 known-good identifiers per corpus offline.

*Justification for its position: this converts the majority of all future verification into local
lookups. It is what makes the verification tier affordable, so it precedes discovery rather than
following it.*

#### P2 — SEEDING (code; a deliberate inversion of the original W1)

The original W1 opened with blind web fan-out. **That frontier is model-prior-shaped.** P2 seeds from
**index enumeration**, which is not:

- USMIN mapped adits and shafts (35 states)
- MSHA underground mines whose controller is a federal entity or a records-storage / data-centre
  operator
- FRPP/BSR asset-count-versus-acreage anomalies
- FAA SUA continuous restricted airspace <3 NM, surface to <5000 ft AGL, **non-flying using agency**
- `historicaltopo` temporal-stack diffs (feature on edition N, absent on N+1, no demolition record)
- FCC ASR clusters
- The **32 calibration entities**, run through the identical live pipeline as ground truth
- **CANARY** injections

Writes: entity rows at `unknown-anomaly`; P3 work items.

#### P3 — DECOMPOSITION (PROPOSER; 1 item = 1 entity)

Emit propositions in the closed 12-class vocabulary with subject, predicate args, as-of date, and
mandatory `null_hypothesis` by lookup. Minimum EXIST + TYPOLOGY. Default grade **X**.

**Gate:** no entity without ≥1 proposition; no proposition without a null (CAP-7 otherwise).

#### P4 — DISCOVERY (Tier 1 agents; 2 concurrent; blind; **pipelined, not barriered**)

Work item = (agent × beat × subject) or (agent × index tile). Enumerate-first briefs.

Writes: `ingest.lead`, `ingest.null_return`. **Nothing else.** P4 and P5 run concurrently — a lead
becomes verifiable the moment it lands, preserving the original design's pipelining.

#### P5 — VERIFICATION (code + ENTAILER; 1 item = 1 lead)

V-1 → V-2 → V-3 → V-4 → V-5 → V-6. Queue ordered by marginal grade impact, per host.

Writes: receipts, quoted spans, observations (or V0), `receipt_class`, `acquisition_task`,
confabulation telemetry.

**Gate on P8 — this is where verification sits, and why it is a gate rather than a pass:**

> **A proposition may not be scored while it holds an unverified lead whose claimed diagnosticity could
> raise its band.** Until then it publishes at `X — VERIFICATION PENDING` with its
> `verification_debt`.

#### P6 — SILENCE (SILENCE + code; 1 item = (proposition × ERP profile); concurrent with P5)

Execute canonical-corpus searches per §7.1; write receipts including NEGATIVE and UNSEARCHED
(distinguished by P0 egress status, **never conflated**); compute SCI.

Batched — one corpus sweep serves many propositions. **Different host set from P5, so the two do not
contend.**

#### P7 — LINEAGE + RESOLVER (1 item = 1 proposition; graph-global)

Refresh lineage components over **verified documents only**; apply §5.1 collapse rules; semantic +
distinctive-error clustering; `corpus_era`; attestation custody; self-exclusion against
`core.publication_log`; transparent-compiler pass-through **emits new leads back into P5** (an explicit
feedback edge, bounded by a hop limit and a per-run budget). RESOLVER proposes IDENTITY and
DISTINCT-FROM.

**Gate:** no merge without IDENTITY at C+; **a merge that raises a grade is rejected.**

#### P8 — REFUTATION → ASSESSMENT → GRADE (1 item = 1 proposition)

REFUTER (different family) names the null, supplies A-levels, proposes UNDERCUTS. ASSESSOR emits the
reduced shape. **GRADER is `core.evaluate_proposition()` in SQL.**

**Gate:** SCI ≥ 0.5 unless the band is A/B/C; typology profile and all table versions pinned;
`scorer_model_id` stamped.

#### P9 — PUBLICATION + TELEMETRY

§10.3 gates: nothing below D renders as a map pin; `LOCATE` below C renders as a polygon or county
centroid, **never a point**. Write `core.publication_log` **before** anything is public — self-exclusion
depends on it. Emit the provenance beacon. Publish the full telemetry set.

**Operational constraint:** publication requires a **drained regrade queue**, because
`core.assert_publishable()` compares the rollup's `evidence_state_hash` against the live evidence and
refuses on mismatch.

#### P10 — COMPLETENESS CRITIC

Sets the next cycle's **search** targets — never candidate targets — and writes W1+1 work items.

### Concurrency and graceful degradation

At any moment the two LLM slots hold **one discovery agent (P4)** and **one adjudication agent
(P5-ENTAILER / P8-REFUTER / P8-ASSESSOR)**. P0, P1, P2, the P5 code stages, P6's execution, P7's graph
computation and all of P8's grading run as non-LLM jobs and **do not consume a slot.**

**Degradation rule, explicit:** under contention, **verification and adjudication always outrank
discovery.** The register's failure mode is unverified volume, so starving discovery is the correct
degradation.

- With one slot: the pipeline drains P5/P8 to empty before P4 gets the slot back.
- With zero LLM slots: P0/P1/P2/P5-code/P6/P7 continue to make progress unattended. **A substantial
  fraction of W1 needs no model at all.**

### W1 exit criteria

W1 does not publish until, **through the live pipeline**:

1. All 32 calibration entities reproduce their expected grades, including the load-bearing pairs —
   Mega Cavern (shelter A / COG R) · Kirtland (Manzano and KUMMSC never merged) · Camp Hero (station A
   / Montauk Project F) · Cheyenne Mountain (EXIST A / current-NORAD-HQ STATUS R) · Greenbrier (1991
   B+E → 1992 A+A, cause NEW-DISCLOSURE) · SubTropolis vs Fairview (HARDEN R vs B) · DUCC (PROGRAM A /
   EXIST R) · Dulce (FUNCTION R / ORIGIN A) · DIA (EXIST A / FUNCTION E).
2. Every canary returns **F** with its identifiers logged as confabulation.
3. The fabricated-CREST-identifier test resolves to V0 and contributes nothing.
4. The self-citation ratchet, simulated against a staging corpus, produces no upward movement.
5. The injection red-team suite passes against the live ingestion path.
6. Confabulation telemetry and per-host egress status are published.

---

## PART 9 — LLM-GENERATED WEB TEXT: WHAT WORKS, AND THE BLUNT PART

The honest answer requires separating four sub-problems.

**(a) What genuinely works, and it is mechanical, not semantic.** `corpus_era` computed from Wayback
CDX first-capture, domain registration date and byline history — **never judged**.
`POST-2022-UNATTRIBUTED` contributes zero to every condition and counts as **zero lineages**. CAP-4
caps at D any claim whose entire support postdates the waterline with no verified pre-2022 document. A
versioned public blocklist of known machine corpora (Grokipedia, uapedia.ai, identified listicle farms)
is T5 + POST-2022-UNATTRIBUTED by construction. **None of this detects regeneration; all of it denies
regeneration a channel**, which is the more robust move.

**(b) The one detector worth standing behind: shared distinctive error.** Regenerated text loses
wording but **keeps facts, including wrong ones.** Extract a normalized fact-tuple fingerprint from
every document carrying a claim — coordinates to 4dp, dates, proper nouns, numeric quantities, unit
conversions — and cluster on **error co-occurrence**. If four apparently independent pages all give the
same wrong elevation, the same transposed coordinate digit, or the same misspelling of a contractor's
name, **they are one lineage.** This is classical stemmatics; it survives paraphrase and machine
regeneration where MinHash does not; and it is cheap. It is **not complete** — it fires only when the
parent contained an error — but when it fires it is close to dispositive, and it is the strongest
available positive evidence of derivation.

**(c) Semantic clustering on the assertion.** Collapses regeneration of the same claim regardless of
wording. Its failure mode is the mirror image: two genuinely independent witnesses reporting the same
fact get merged and corroboration is **under**-counted. Default-SAME-under-uncertainty makes this a
deliberately conservative error; the design accepts it, states it publicly, and publishes the merge
rate.

**(d) Explicitly rejected: AI-text detection classifiers.** They do not survive paraphrase, and their
false-positive profile is worst on **formal institutional prose — which is exactly this corpus.** A
register that mislabels a real 1990s enthusiast page or a genuine agency memo as machine-written
commits the opposite error to the one it is trying to avoid, silently and at scale. Not used, and the
reason is on the methodology page.

**The blunt finding, which belongs in the record:**

> **There is no reliable general method for detecting machine regeneration, and this design does not
> claim one.** What it does instead is refuse the open post-2022 web any weight it cannot back with a
> receipt to an institutionally issued, dated artifact.

**Why that is survivable rather than fatal:** web text is almost never evidence in BES to begin with.
Every D3 and D4 catalog row is an institutional artifact with an issuer, an identifier and a date. A
web page is at best T3/T4, cannot reach A or B, and CAP-2b prevents any FUNCTION claim exceeding E
without a verified claim-property row. The exposure is confined to two places:

- **Lineage counting** — closed by requiring a lineage terminus to be a **resolvable dated artifact
  rather than a URL**.
- **ORIGIN propositions** — where the contaminated corpus is the *object of study* rather than the
  evidence base, so the register is measuring the contamination rather than being fooled by it.

**The genuinely uncatchable case is narrow and real:** a machine-generated page that becomes the *first
observed appearance* of a claim, corrupting an ORIGIN grade by dating the claim to a regeneration
rather than its true earlier source. Partial mitigation only (IA full-text `hits_inside`, AFU newsletter
runs, Arctic Shift, pre-2022 corpora). Listed as a standing limitation in `docs/GRADING.md` §18.2.

---

## PART 10 — THE GUARDRAIL LEDGER

Every item here is enforced somewhere concrete — a constraint, a trigger, a generated column, or a
missing column — not in an agent brief.

| # | Guardrail |
|---|---|
| 1 | **SCHEMA PRIVILEGE SEPARATION.** No LLM holds INSERT on observations, receipts or lineages. Discovery agents write only to `ingest.lead` and `ingest.null_return`. The sole writer of observations is deterministic verification code |
| 2 | **LEAD SCHEMA REJECTS UNQUOTABLE CLAIMS AT INSERT.** Identifier + class + claimed issuer metadata + verbatim span + proposition. **No `origin_tier`, `diagnosticity`, `scope`, `property_locus` or `grade` columns exist** — an agent cannot assert them |
| 3 | **RESOLVE-OR-DIE WITH A THREE-WAY FAILURE SPLIT.** `UNRESOLVED-NOTFOUND` (measured fabrication) · `UNRESOLVED-UNREACHABLE` (against SCI and host status, **not** the agent) · `DEAD` (drift). Conflating them lets a blocked proxy inflate the published fabrication rate |
| 4 | **DETERMINISTIC SPAN LOCATION, NON-LLM.** Character offsets under a versioned normalization pipeline. Failure is a **fabricated-quote event** — the cheapest and most damning telemetry available. FUZZY-OCR capped at D3, unable to satisfy §3.4 |
| 5 | **SUBJECT BINDING AGAINST A CURATED ALIAS SET.** Failure downgrades scope INSTANCE→CLASS and removes the row from V. The guardrail against the commonest real failure: a genuine document attributed to the wrong facility |
| 6 | **V-6 ENTAILMENT ADJUDICATION IS DEMOTE-ONLY.** Different family, bounded input, five forced-choice labels, narrative/dossier/other-evidence/proposed-diagnosticity all withheld. Final = min(assignment, V-6 ceiling) |
| 7 | **D4 REQUIRES TWO MODEL FAMILIES PLUS A TABLE LOOKUP.** STATES-ON-FACE needs two-family agreement; §3.4(e) moves into `authority_over_fact`. Disagreement caps at D3, never broken by a third same-family vote |
| 8 | **IDENTIFIERS FROM UNTRUSTED TEXT ARE LEADS, NEVER CITATIONS.** Blocks the "convert a fringe library into a P1 lead list" move, and the weak prompt-injection vector where the agent need only repeat rather than obey |
| 9 | **ALL FETCHED TEXT ENTERS AS STRUCTURALLY BOUNDED DATA.** Plus cache-and-revalidate, content-hash drift alerts, an `adversary_writable` flag per host surfaced on the entry page, and a **CI injection red-team suite run against the live ingestion path on every deploy** |
| 10 | **VERIFICATION IS A GATE ON SCORING, NOT A PASS OVER IT.** Nothing load-bearing is ever sampled; the queue is reordered by marginal grade impact instead |
| 11 | **NO LLM ASSIGNS A GRADE.** §9.4 runs as PL/pgSQL. ASSESSOR's entire output is a scope, a locus, a sign, a fact key, and a catalog ID or two ordinals |
| 12 | **AGENT IDENTITY IS UNREACHABLE FROM THE GRADING QUERY.** The number of agents that reported a claim is physically incapable of entering the arithmetic |
| 13 | **NOTHING ENTERS THE LINEAGE GRAPH WITHOUT A VERIFIED RECEIPT.** Five agents, five fabricated identifiers → zero nodes → zero lineages → V = ∅ → CAP-5 → F |
| 14 | **CANARY PROGRAMME.** Rotating fabricated names with zero corpus presence, injected every cycle, published beside the format-valid-but-unresolvable rate, the fabricated-quote rate and per-agent grade distributions. **A canary can never be published** |
| 15 | **CAUSAL PROVENANCE IS DERIVED AT SPAN LEVEL, NOT ASSERTED AT DOCUMENT LEVEL.** Solicitation log written before sending; FOIA/docket PDFs segmented; only content predating the solicitation is UNSOLICITED |
| 16 | **THE REGISTER'S OWN FOIA REQUESTS CANNOT SUPPORT ITS OWN CANDIDATES.** Every acquisition task is logged first, so its output is SOLICITED-BY-CLAIMANT by construction and permanently |
| 17 | **SELF-EXCLUSION.** `publication_log` written before anything goes public; post-publication sources quarantined; **a grade may rise only on evidence whose document date precedes publication**; downward movement unrestricted |
| 18 | **POST-2022 CONTAINMENT.** `corpus_era` computed mechanically, never judged. Versioned public blocklist. **AI-text classifiers explicitly rejected** as unreliable on institutional prose |
| 19 | **SHARED-DISTINCTIVE-ERROR CLUSTERING.** The one derivation signal that survives machine paraphrase where MinHash and shingle overlap do not |
| 20 | **ENUMERATE INDEXES, DON'T SEARCH THEM.** Model-prior-independent by construction; the primary discovery mode. Free-text search is secondary |
| 21 | **AN AGENT'S INTERPRETATION OF A PRIMARY ARTIFACT IS T5** until a different-family second read **blind to the first's conclusion**, plus a citation to the era-correct symbol standard. Covers the highest-hallucination-rate operation in the fleet |
| 22 | **TYPOLOGY CIRCULARITY CLOSED.** Scoring runs under the *graded* typology; `typology_profile_version` pinned; `TYPOLOGY-CHANGE` forces re-scoring with both scorings retained |
| 23 | **MERGES CANNOT LAUNDER SCORE.** IDENTITY at C+ required; evidence never pools; DISTINCT-FROM seeded from the calibration set; **any merge that raises a grade is rejected** |
| 24 | **EGRESS STATUS IS PUBLISHED AND CAN HALT THE RUN.** An unreachable canonical corpus yields UNSEARCHED, mirror-only resolution caps at B, and P0 stops the sweep if the EXIST/LOCATE corpora are predominantly blocked — **because a register grading F everywhere from its own network failure looks exactly like a register full of findings** |

---

*Fleet version 0.2.0 · supersedes WORKFLOW.md §2 · the sentence "discovery-agent blindness is what
makes the COR axis mean anything" is deleted and replaced by guardrail 12.*
