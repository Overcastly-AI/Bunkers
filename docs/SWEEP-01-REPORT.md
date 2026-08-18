# SWEEP 01 — WHAT THE FIRST DISCOVERY CYCLE PRODUCED

**Status: complete. Nothing in it is publishable as a graded candidate.**

Produced 2026-08-18 · rubric BES v0.2 (`docs/GRADING.md`, ratified) · input
`research/candidates/resolved.json` (48 entities from four blind beats) · output
`research/candidates/graded.json`.

---

## THE ANSWER, FIRST

Four discovery agents produced 48 candidate entities carrying 200 propositions. Under BES v0.2:

| Band | Count | Share |
|---|---|---|
| A ESTABLISHED | 0 | — |
| B CORROBORATED | 0 | — |
| C SUPPORTED | 0 | — |
| D INDICATED | 0 | — |
| E DOUBTFUL | 0 | — |
| **F UNSUPPORTED** | **4** | 2% |
| R REFUTED | 0 | — |
| **X NOT ASSESSED** | **196** | 98% |

**X is not a low grade. It is the absence of a grade.** The register has not graded these sites low; it
has not graded them at all, and it is required to say so rather than to publish a letter it cannot
support.

The cause is a single fact stated in one sentence: **not one citation in this sweep was resolved to
bytes.** Outbound egress blocked `.gov`, `.mil` and most archive hosts. Every source in every beat file
is `SEARCH-SNIPPET-ONLY`, `FETCH-BLOCKED` or `CITED-BY-OTHERS-NOT-SEEN`. Under §2.2 resolve-or-die each
one is `receipt_state = UNRESOLVED-UNREACHABLE`, `membership = V0`, arithmetically inert on every
condition in the model.

So for every proposition on every entity:

```
V = ∅ · U = ∅ · |V[claim]| = 0 · |V[D2+]| = 0 · |V[D4]| = 0 · L(D2) = 0 · L(D3) = 0 · SCI = 0.000
```

Everything below follows from those eight zeros.

**This sweep produced a research queue, not a register.** That is a real product — the queue is priced,
ordered and specific, and §12.4 is right that a register stating its own limits is worth more than one
implying none — but it is not the product the map page needs, and nothing here should reach the map.

---

## HOW 196 PROPOSITIONS REACHED X

Applied as written, §9.4 runs in order and the row never gets past step 2.

**Step 1 — refutation, checked first.** `R0` everywhere. R3 requires a verified, subject-bound,
unsolicited row from a party with authority over the fact directly stating the negation. R2 requires two
independent-lineage **verified** UNDERCUTS rows at D2+ plus `null_state = DOMINANT`. R1 requires the sole
origin lineage **shown** fabricated. All three branches are V-dependent, and §8.5 re-derives the state
rather than trusting an agent's proposal. Nothing resolved, so nothing refutes.

**Step 2 — the SCI floor, which is what actually decides this sweep.** `SCI = 0.000`. The numerator is
the count of expected-record profiles at X≥1 that received a *receipted* search, and it is zero
everywhere: county recorders, USGS HTMC, GovInfo, CREST, DTIC, NARA, FRPP, GSA disposal and FCC ASR/ULS
were all egress-blocked, which under §2.6 makes them `UNSEARCHED`, not `NEGATIVE`. The denominator is
at least one on essentially every located subject, because "County deed / assessor parcel record, **any
CONUS parcel, any era** — X3" is the universal floor. `SCI < 0.5` and the provisional grade would be
D/E/F/R, therefore the grade is withheld: **`X — INSUFFICIENT SEARCH (SCI 0.00)`**.

**§10.5 reaches the same place independently.** A proposition holding an unverified lead whose claimed
diagnosticity could raise its band publishes `X — VERIFICATION PENDING`. Nearly every row here holds
several. Two separate rules, one answer.

**Steps 3–7, computed and recorded but not binding.** Bands A–E all fail on their first condition (A1
needs a D4 row in V; B1 needs L(D3) ≥ 2 or L(D2) ≥ 3; C1a/C1b need rows in V; D1 needs a row in V[D1+];
E1 needs V ≠ ∅). CAP-5 would cap at F, CAP-1 at C, CAP-2a at D for EXIST/EXTENT/LOCATE/FEATURE/TYPOLOGY
and CAP-2b at E for HARDEN/CONTROL/FUNCTION/PROGRAM/IDENTITY/ORIGIN. Those caps are recorded on every
row in `caps_computed` — per calibration D-01, `applied_caps` must show the mechanism that ran, not only
the one that bound — but none binds, because X is returned before step 6.

**Three consequences worth naming separately.**

- **The monotone clamp is inert.** §1.4: R and X are unranked, are neither capped nor clamped, and do
  not clamp their children. Every EXIST is X, so no child grade in this file was produced by clamping.
- **C1c, the candidate-set rule, is unreachable everywhere.** It requires a PROGRAM graded A or B *and*
  a verified instance-scope CLAIM-PROPERTY row at D1+. Both are V-dependent. The mechanism the register
  designed to rescue real-but-thinly-documented sites — the five AT&T Project Offices, the Federal
  Relocation Arc pattern — is the *last* path to open, not the first.
- **Every entity scores under `unknown-anomaly`.** §1.2 makes TYPOLOGY a graded proposition that cannot
  move without clearing band C. One entity in 48 carries a TYPOLOGY proposition at all, and it is X. The
  typology strings carried through discovery and resolution (`COG-COOP`, `missile-silo`,
  `private-shelter`) are ungraded claims and must not be rendered.

---

## THE FOUR EXCEPTIONS, AND WHY THEY ARE THE ONLY ONES

Four propositions receive a band. All four are **F**, all four are **R0**, and all four get there by the
same route: the §7.2 denominator-zero correction. When no expected-record profile at X≥1 applies to a
proposition, the denominator is empty, `SCI = 1.000` ("nothing to search is complete"), the step-2 floor
does not withhold, and CAP-5 binds on `V = ∅`.

| Proposition | Why the denominator is empty |
|---|---|
| RES-029 · FUNCTION — Mel's Hole has unmeasurable depth and revives dead animals | No record class of any era or authority bears on it |
| RES-032 · FUNCTION — the claimed 129 facilities house black-budget human/non-human programmes | Every applicable profile is X0: NIP/MIP construction, active facility under commercial cover, CREST/DTIC while classified |
| RES-035 · EXIST — an inhabited cavern system exists beneath the earth's surface | Non-located; asserts no construction event by any recorded party |
| RES-035 · FUNCTION — the caverns house a hostile population operating machinery | Same |

RES-032's FUNCTION row is the interesting one, because its **sibling** proposition — EXIST, "129 to 131
secret hardened underground facilities were operating in the United States in 1995" — grades **X**, not
F. The expected-record profile for the EXIST claim is dense and at X3 (MILCON line existence, procurement
traces above $50M, spoil-volume signature above 1e5 m³). Those searches were never run, so §9.4 step 2
withholds the grade. The FUNCTION claim has no such profile, so F stands.

**Two propositions on one 1995 lecture, one X and one F, separated entirely by which record classes
would have been expected.** That is the model working precisely as designed, and it is a sharper result
than a flat F.

The four F's establish that four fringe claims have no verified support, which nobody doubted. That is
the honest measure of what a blind sweep can produce.

---

## CALIBRATION: 17 OVERLAPS, 17 DIVERGENCES, 0 REPRODUCTIONS

`docs/CALIBRATION.md` holds 34 cases. Seventeen propositions here overlap them. **Every one diverges.**
None is tuned; all are reported.

The suite is specified to run through the **live pipeline** — discovery, verification, silence, lineage,
refutation, grading — and explicitly states that "a case that passes only when its evidence is
hand-loaded proves nothing about the register." This sweep never reached the verification stage on a
single row. **Not one calibration case is reproducible under egress blockade.** No divergence below is
evidence that the rubric moved.

### The divergences that are research findings

**A-02 · Raven Rock — expected A on seven propositions, returned X on four.** The case is specified with
`|V[D4]| = 2, L(D3) = 5, SCI = 6/6`. This sweep has `SCI = 0.000` and `V = ∅`. IC #1 wrote *"if a
revised rubric moves this below A, the revision is broken."* The rubric has not moved. The pipeline read
nothing. Raven Rock's sole reachable lineage in this sweep is a Wikipedia family; DTIC, NARA, GovInfo,
AFHRA and the Adams County recorder — the five roots that carry the A — are the five that were blocked.
**Do not adjust the rubric.** Re-run when egress is restored; if it does not return A then, the revision
*is* broken.

**A-04 / E-03 · Mount Weather — expected EXIST A and FEATURE E with a citogenesis flag; returned X on
both.** But E-03's structural assertion **passes**: the citogenesis flag attaches to the *proposition*,
not the site. CITOGENESIS-01 sits on `RES-033-ORIGIN` and `RES-033-FEATURE` and does not touch
`RES-033-EXIST`. That is the half of E-03 invisible in the letter, and it is the half that works. CAP-3
is nonetheless **not** applied: §5.3 requires a resolved T3+ publication resting on a resolved T5
substrate, and the March 1976 *Progressive* was never opened. A suite that scored letters alone would
have logged a total failure and missed that the mechanism ran correctly.

**E-01 · Denver International Airport — expected EXIST A, FUNCTION E via CAP-2b; returned X on both.**
E-01 is called *"the single most important thing to test before ratification"* and its deepest assertion
is that six real T1 returns produce six D0 rows. This sweep cannot run that test: it holds no T1
returns, only descriptions of them.

**B-02 · Survival Condo EXTENT, read against KUMMSC — expected the EXIST A / EXTENT D pair; returned X
on both.** The *decomposition* survives — EXIST and EXTENT are separate graded rows, and the beat's note
that seller-stated geometry is D0–D1 while a recorded condominium declaration would be D3–D4 is carried.
What is missing is the grades, not the structure.

### The divergences that are rubric findings

**F-03 · the Sauder/Schneider "129 DUMBs" corpus — expected F (SILENCE-DOMINATED); returned X on EXIST.**
IC #2: *"if a revised rubric moves this above F, the revision is broken."* It has not moved *above* F —
it has moved *beside* it, to X. The reason is the register's own rule: F-03's F is licensed by deep X3
expected-record negatives that were never searched, and §9.4 step 2 forbids a negative verdict on
unsearched records. **The register may not say "unsupported" about records it has not looked for.** Three
searches convert this row from X to F in one pass.

**R-05 · Dulce Base — expected R (R1) on EXIST/HARDEN/FUNCTION/LOCATE and A on ORIGIN; returned X on
all.** This is the case that exposes the cost asymmetry the register assumed and does not have. R1
requires the origin lineage *shown* fabricated — the LeVesque admission documented by Gorightly, the
AFOSI/Doty record, the post-dating impossibility in images dated 1987 that contain a still from a 2000
film. Every one is affirmative, machine-checkable and resolvable. Not one resolved. And ORIGIN cannot be
graded either, because **an ORIGIN proposition is a negative receipt** and no negative receipt was run.

**C-01 · the candidate-set path, read against the AT&T Project Office chain — expected C via C1c;
returned X.** Structural, not evidentiary: C1c depends on a graded PROGRAM, which depends on resolved
bytes. Worth stating plainly, because C1c is exactly the mechanism a reader would expect to rescue the
five Project Offices, and it cannot.

### Two entity-resolution hazards the suite does not currently warn about

- **"Iron Mountain."** Calibration A-06 grades *Iron Mountain / Boyers, PA* — the OPM Retirement
  Operations Center — at A. RES-030 is the *Iron Mountain facility near Hudson, New York* and the 1967
  *Report from Iron Mountain* literary hoax. Two different places sharing a brand. §11.1 forbids the
  merge, but nothing in the suite warns about it. Add a DISTINCT-FROM edge and a P-class case on the
  P-06 (Manzano vs KUMMSC) pattern.
- **Titan II designations.** A-07 grades *571-7, Green Valley AZ*. RES-043 is *374-7, Southside /
  Damascus AR* — the 1980 accident site. Three characters apart, both toured, both well documented. Add
  a DISTINCT-FROM edge.

### One suite gap

**RES-046 · the Grand Forks 321st MW launch facilities** carries the strongest independence structure
anywhere in this sweep — five roots, one of them an **adversary government** verifying by national
technical means under a regime that required the excavation to stay open for ninety days. It is also the
register's *inverse* case: the programme is certain, the function is certain, the destruction is
certain, and **the hole is gone**. "The hole is certain, the function is not" is the register's stated
modal case; this is its mirror, and the calibration set has no entry for it. Add one: EXIST R / STATUS A
/ PROGRAM A on a treaty-eliminated launcher population, asserting that the R does not clamp PROGRAM.

### The one thing that did reproduce

**P-01.** A fabricated but format-valid identifier must resolve to V0 and contribute nothing. This sweep
reproduces it 200 times. And the distinction P-01 turns on is load-bearing here: these rows are
`UNRESOLVED-UNREACHABLE`, which counts against SCI and against host egress status — **not**
`UNRESOLVED-NOTFOUND`, which would count as measured fabrication. This sweep therefore publishes a
confabulation rate of **zero measured**, which is not a low rate but an unmeasured one. Conflating the
two would have let a blocked proxy inflate the register's own fabrication metric, which is exactly why
§2.2 splits them.

---

## RUBRIC FINDINGS

Six defects in BES v0.2 that this sweep exposed. Full text in `graded.json.rubric_findings`.

**RF-1 (material) — the SCI denominator is undefined for ORIGIN, and the denominator-zero correction
then hands out F where nothing was searched.** §7.2 computes SCI over expected-record profiles, and the
ERP table is keyed on *record class × era × controlling authority × classification posture* — a
facility-records table. It carries no row bearing on an ORIGIN proposition, whose canonical corpora
(§7.1: Wayback CDX, IA full-text `hits_inside`, AFU newsletter runs, UTZOO, Chronicling America) are a
different list entirely. Read strictly, every ORIGIN proposition has an empty denominator, `SCI = 1.000`,
and grades **F** despite the ORIGIN corpus never having been touched. That is the exact defect X exists
to prevent, reappearing through §7.2. **Disposition:** all 14 ORIGIN propositions here are graded X, on
the ground that the denominator-zero correction is licensed by "every applicable profile returns X0" —
its stated Mount Pony / Greenbrier rationale — and not by "the table has no row for this class." The
strict reading would have returned F on 14 rows. Both are recorded; the register should ratify one.

**RF-2 (presentational) — `null_state` returns SURVIVING vacuously on an empty V.** §4.6 derives
SURVIVING as "the null accounts for every row in V, but is not itself documented." With V empty the
condition is vacuously true, so all 200 propositions publish SURVIVING — which on an entry page reads as
*"the mundane explanation is holding"* when the actual state is *"nothing has been tested."* Every row
here carries an explicit note marking it vacuous. Add a distinct derived state.

**RF-3 (material) — §12.6 band-occupancy discipline cannot distinguish healthy caution from total
retrieval failure.** The discipline sets the target modal band at X or D and audits only C-band
over-occupancy. This sweep is 98% X and 0% C: it passes perfectly while having established nothing. A
health metric a completely blind pipeline satisfies is not measuring pipeline health. Pair it with a
floor that publishes the fraction of X attributable to `SCI < 0.5` and alerts above a threshold.

**RF-4 (minor) — §6.5 publishes base-rate readings for four proposition classes only** (EXIST, HARDEN,
CONTROL(federal), FUNCTION). STATUS, ORIGIN, PROGRAM, IDENTITY, FEATURE, EXTENT, TYPOLOGY and LOCATE
have no row, so 64 of 200 propositions (32%) publish no base-rate reading. Those rows carry `null` with
a not-applicable note rather than an invented value.

**RF-5 (material) — refutation is exactly as expensive as establishment, and the register did not price
that in.** The project philosophy holds that refutation is a finding and that showing a famous claim
hollow is as valuable as finding a facility. But every branch of the §8 test — R3, R2 and R1 alike —
requires **verified** rows, and §8.5 re-derives rather than trusts. Under blockade the register can
neither confirm nor refute. The implicit assumption that debunking is cheaper than confirming is false
under resolve-or-die, and this sweep is the demonstration: **zero R on 200 propositions**, including on
claims whose refuting documents are named, dated and known to exist.

**RF-6 (minor) — the typology field carried through discovery is ungraded and looks like a fact.** See
above. Rename to `claimed_typology` in the discovery schema and refuse to render it without a TYPOLOGY
proposition at C+.

---

## THE MOST SIGNIFICANT REFUTATION — AND WHY IT IS NOT ONE

The sweep produced **no refutations at all**, and that absence is the single most consequential thing in
this report. Two candidates for the title, both of them currently ungradeable:

**The strongest refutation available: CITOGENESIS-01.** "Western Virginia Office of Controlled Conflict
Operations" appears to be a coinage of the Mount Weather folklore layer, originating with Richard
Pollock, *The Mysterious Mountain*, **The Progressive, March 1976**, with no documentary attestation
found. It now sits as an *alternate official name in the page titles* of the Federation of American
Scientists' Nuclear Information Project and of GlobalSecurity.org — a T3 source and a T4 source **in
this project's own registry**. The laundering loop runs through our own bibliography, so the flag must
attach at the **source** level, not only the proposition level. It is also independent support for the
finding that FAS and GlobalSecurity share text: the same unattested coinage in both titles is what
shared authorship looks like. The test is binary and cheap — does the phrase appear in any federal
record? — and the folklore beat was explicit that it did not run it. **Until that search runs, this
finding is a hypothesis about a hypothesis.**

**The largest structural collapse: Phil Schneider's Preparedness Expo lecture, 1995.** Five separately
presented claim families, arriving from **three beats that could not see each other**, all terminate in
one lecture by one man, with Sauder's self-published *Underground Bases and Tunnels* (1995) as
co-terminus supplying the bibliography while Schneider supplies the numbers: the DIA underground base;
"129 (or 131) DUMBs, 1,477 worldwide"; the transcontinental subterrene tunnel network; "FEMA regional
centres are nodes of a covert deep-underground network"; and "decommissioned Atlas/Titan/Nike sites are
entrances to a national DUMB network." Schneider died in January 1996, freezing the lecture as a canon
that could not be revised, defended or withdrawn. Thirty years on there is still no list, no coordinate,
no procurement record, no spoil accounting.

Any register treating any two of those five as mutually corroborating is counting one 1995 lecture
twice. Under §5.7 the merge is a **downgrade** — a grade falls because a link was found, not because
evidence was lost — and it is correctly recorded as such: `graded.json` pools RES-025 and RES-032 as one
lineage rather than two while keeping them separate entities.

The by-product is genuinely useful and survives paraphrase and machine regeneration where shingle
matching does not: **any page carrying "1,477" or "129 underground bases" is in this lineage regardless
of what else it says.**

And the discipline that must hold: **this is F, not R.** The expected-record negatives are deep and real,
and §8.4 forbids converting them into refutation — a model that refutes on negatives alone would also
have refuted the Greenbrier in 1991. Right now it is not even F on its EXIST proposition; it is X,
because the negatives were never searched.

---

## WHAT THE SWEEP DID ESTABLISH

Not about facilities — about this register's own source graph, which is the one thing a blind sweep can
observe honestly.

**Two nodes carry more than two-thirds of the candidates.** Four beats, searching blind, on four
unrelated topics: Wikipedia and its mirror/derivative family touch **20 of 48**; the Center for Land Use
Interpretation touches **15**. Neither is a primary record. Wikipedia's derivative family reliably
presents one lineage as six. CLUI is an unsigned, uncited curatorial survey that works from public
property records — a *derivative* of the land-records layer, not an independent terminus.

**The reachable sources collapse to a few nodes; the genuinely independent termini are precisely the
ones egress blocked.** NARA, DTIC, AFHRA, GovInfo, county recorders, National Register nominations, the
START implementation record, the FCC antenna registry, the Albemarle and Loudoun permit files. This is
why the remedy is acquisition, not more searching.

**Interest and documentation are inversely correlated in the reachable corpus.** The best-attested things
in this sweep are the ones nobody finds mysterious: a Battle Creek office building with no underground at
all (four origins), a Western Union microwave terminal in Tenleytown (three), a Titan I contamination
plume under state regulatory oversight (three), a treaty-destroyed missile field (five). The candidates
resting on exactly one source are the interesting ones: Raven Rock, the Lambs Knoll PEF, the Hagerstown
Project Office, Dulce, DIA, Mel's Hole, Iron Mountain, the Survival Condo, Subterra Castle. **That is not
evidence of concealment.** It is what the indexed web looks like when the archives are unreachable: the
reachable corpus is written by enthusiasts and marketers, and the record classes that would settle things
sit behind egress blocks.

**Ten citogenesis findings, of which the cleanest is CITOGENESIS-02 — hedge-stripping.** Albert LaFrance
states the Project Offices' continuity mission as inference and hedges it honestly and repeatedly:
"probably not the station's primary mission," "likely," "may have served." Wikipedia, CLUI, a Grokipedia
mirror and every downstream retelling restate the conclusion **with the hedges removed**. Nobody lied
and nobody invented. The apparent convergence of many sources is one named researcher's honestly-marked
conjecture reflected in many mirrors. The corrective is to restore the hedges and grade the conjecture
as a conjecture by a named researcher — modest, and considerably better than the unhedged version
deserves.

**And one piece of self-auditing worth more than any candidate in the file.** The comms beat caught its
*own* search tool conflating Netcong with the Project Office chain, and recorded it as a finding against
its process rather than against a source. An erroneously admitted sixth member would have inflated the
chain's membership and diluted every genuine member's grade under C1c. That is what a fleet auditing
itself looks like.

---

## WHAT THE NEXT CYCLE SHOULD TARGET

**Almost none of it is search. Almost all of it is acquisition.** Nothing new needs to be found; documents
this sweep could only see described need to be opened. Ordered by cheapness against diagnosticity:

1. **Restore egress, or stand up a fetch path that does not depend on it.** Every item below is blocked
   on this and nothing else. Until it exists, no cycle of this register can produce a grade above X on a
   located subject. This is not a research task; it is the precondition for the project.
2. **Index enumeration over query-based search** (§5.8a). Walk `ancestorNaId` series trees, iterate
   `historicaltopo` by polygon, page FPDS by date window, sweep MSHA by controller. Enumeration is
   model-prior-independent by construction and is the primary discovery mode; more searching by more
   agents adds recall and *nothing* to corroboration.
3. **The county-recorder sweep.** "County deed / assessor parcel record, any CONUS parcel, any era" is
   X3, the universal floor, and it is the profile that puts SCI at zero on nearly every entity here.
   Clearing it on 48 parcels moves the whole file off the step-2 floor in one pass, and would settle
   CONTROL and STATUS outright on the Atlas/Titan conversions, Spears Mountain, Netcong and RSL-3.
4. **Named single documents that each settle one live question.** The Albemarle County permit viewer
   (settles CITOGENESIS-05, the unsourced $61M Peters Mountain figure); Loudoun County file
   CMPT-2016-0001; the Hampshire County deed for the 1989 Notch sale; the Arkansas NRHP nomination for
   Launch Complex 374-7; FRASER RG 82, Boston, Box 2644 Folder 1 (settles the Notch currency claim); the
   NRHP nomination for Denver Federal Center Building 710 — the cheapest possible test of whether this
   register can produce a band-A proposition at all.
5. **The three F-03 searches** — MILCON line existence, procurement traces above $50M, spoil-volume
   signature above 1e5 m³. They convert RES-032-EXIST from X to F and close the sharpest calibration
   divergence in this report.
6. **The refutation queue, which RF-5 says has been underpriced.** The *Report from Iron Mountain*
   recantation — New York Times Book Review, 19 March 1972 — is one dated newspaper page and is the
   cheapest R available to this register. The Dulce post-dating check (an image dated 1987 containing a
   still from a 2000 film) is deterministic and machine-checkable. Neither was run.
7. **One binary search that either collapses a finding or indicts two reference sites.** Search federal
   records for "Western Virginia Office of Controlled Conflict Operations." If it appears, CITOGENESIS-01
   is struck. If it does not, a 1976 magazine coinage has been sitting in two reference sites' titles for
   decades — one of them in our own registry.
8. **A Wayback CDX pass over missilebases.com for "epoxy resin"** — the distinctive-error tell behind
   CITOGENESIS-04, the brokerage copy laundered into state tourism material.
9. **Fix the six rubric findings**, and add the three calibration entries this report asks for: the two
   DISTINCT-FROM hazards and the treaty-eliminated-launcher inverse case.

---

## HOW TO READ THIS REGISTER TODAY

If you are deciding whether to trust it, these are the terms.

- **Nothing in this sweep may be rendered as a map pin.** §10.3 gates map rendering at band D; the
  highest band here is F. `LOCATE` is X on all 48 entities.
- **X must render visually distinct from F.** Confusing them was a fatal defect in v0.1 and 98% of this
  file is X.
- The `ceiling_if_all_leads_resolved` field on every proposition is an **analyst projection** carried
  from the discovery beat. It has no standing in the model, and must never render beside a grade as
  though it were one.
- **A low grade here is not a claim about the world.** Raven Rock exists. Mount Weather exists. Grading
  them X is a statement that *this register has read nothing about them*, and the `limiting_condition`
  on every row says so in those words. A register that quietly exempted its famous entries from its own
  standard would have no standard.
- **Four beats agreeing is not corroboration.** N prompts over one set of weights is one witness
  speaking N times. `discovering_agent` and `agent_run` are not reachable from any grading query, and
  the one cross-beat entity merge in this sweep (the Notch) left the independent-origin count at 2 —
  exactly what the better-sourced beat said alone, and not 4.
- **The measured fabrication rate for this cycle is `zero measured` — not zero.** Every identifier here
  is format-valid and unresolved for network reasons (`UNRESOLVED-UNREACHABLE`), which is not the same
  as unresolvable at the issuing authority (`UNRESOLVED-NOTFOUND`). No confabulation telemetry can be
  read off this cycle, and none should be claimed.

The uncomfortable summary: **the register's own standard, applied honestly to its own first sweep,
returns almost nothing.** That is the correct outcome for a pipeline that read nothing, and the fact
that the instrument produced it — rather than a page of confident letters — is the strongest evidence
available that the instrument works.
