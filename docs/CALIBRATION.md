# CALIBRATION — THE REGRESSION SUITE

**Purpose: detect rubric drift.** Every case below has an expected outcome under BES v0.2
(`docs/GRADING.md`). If the live pipeline stops reproducing them, either the rubric moved, a curated
table moved, or the scorer drifted — and the suite says which.

**Provenance.** Merged and deduplicated from the three adversarial critiques on disk: 43 raw cases
(archival historian 15, intelligence analyst 17, adversarial skeptic 11) collapsing to **34 distinct
cases**, plus one sub-case (SF-88L) carried as a paired contrast. Where two reviewers submitted the
same facility with different expected letters, the disagreement is recorded in the case rather than
resolved silently — see the `REVIEWER CONFLICT` marker.

**Reading the markers.**

| Marker | Meaning |
|---|---|
| ✅ | BES v0.2 reproduces the reviewers' expectation |
| ⚠️ **REVIEWER CONFLICT** | The two lenses disagreed; the adjudicated decision is recorded |
| ❌ **KNOWN DIVERGENCE** | BES deliberately returns something else. **The suite asserts the BES answer, not the reviewer's.** These are the cases most likely to be "fixed" by mistake |
| 🔶 **MARGINAL** | The correct answer depends on a fact the calibration text does not settle; `marginal_flag` must be TRUE |
| 🔷 **PAIR, NOT LETTER** | The reviewer gave one composite letter; BES answers with a pair of propositions. Satisfied by the decomposition, **not** by a letter-for-letter match |
| 🔧 **PIPELINE** | Not about a facility at all. Tests the ingestion path, not the rubric |

**How to run it.** Every case is executed through the **live pipeline** — discovery, verification,
silence, lineage, refutation, grading — not by hand-loading evidence rows. A case that passes only
when its evidence is hand-loaded proves nothing about the register.

**Scoring the suite.** A case passes when the grade matches AND the named `limiting_condition`,
`applied_caps` and `null_state` match. **Matching the letter alone is not a pass**: two of the
historically most dangerous failures (SubTropolis reaching the right band by the wrong route, DIA
reaching E without CAP-2b) produce a correct letter from a broken mechanism.

---

## SUMMARY TABLE

| # | Case | Expected (BES v0.2) | Marker |
|---|---|---|---|
| **A** | | | |
| A-01 | Cheyenne Mountain — EXIST | A | ✅ |
| A-02 | Raven Rock (Site R) — all seven propositions | A | ✅ |
| A-03 | 33 Thomas Street — EXIST · HARDEN · FUNCTION(gateway) · FUNCTION(TITANPOINTE) | A / A / A / A, **IDENTITY B** | ✅ |
| A-04 | Mount Weather — EXIST | A | ✅ |
| A-05 | Greenbrier post-1992 | A on all, cause NEW-DISCLOSURE | ✅ |
| A-06 | Iron Mountain / Boyers | A | ✅ |
| A-07 | Titan II 571-7 | A | ✅ |
| A-08 | Camp Hero AFS — EXIST · FUNCTION(radar) | A | ✅ |
| A-09 | Mount Pony, Culpeper — the non-appropriated control | A on all, 4 profiles X0 | ✅ |
| A-10 | Louisville Mega Cavern — FUNCTION(designated fallout shelter) | A | ✅ |
| A-11 | DUCC — PROGRAM · STATUS(never-built) | A / A | ✅ |
| A-12 | Dulce — ORIGIN(Bennewitz 1979–80) | A | ✅ |
| A-13 | Montauk Project — ORIGIN(Nichols & Moon 1992) | A | ✅ |
| A-14 | SubTropolis — EXIST · TYPOLOGY · CONTROL | A / A / A | ✅ |
| A-15 | SF-88L, Marin County (restored Nike site) | A | ✅ |
| A-16 | Manzano Base — EXIST · FUNCTION | A | ✅ |
| A-17 | Groom Lake / Area 51 — EXIST | A | ✅ |
| A-18 | Fairview KS — EXIST · CONTROL · FUNCTION(relay) · LOCATE | A | ✅ |
| **B** | | | |
| B-01 | Fairview KS — HARDEN | B | ✅ |
| B-02 | KUMMSC | EXIST A · HARDEN A · EXTENT D | 🔷 |
| B-03 | PEF Cartwheel, Fort Reno | EXIST A · EXTENT D, **or** C via C1c | 🔶 🔷 |
| B-04 | Unrestored Nike Hercules magazine | EXIST A · TYPOLOGY A · STATUS X | 🔷 |
| B-05 | Greenbrier 1991 — EXIST | B | ⚠️ |
| B-06 | 33 Thomas — IDENTITY(TITANPOINTE ≡ 33 Thomas) | B | ✅ |
| **C** | | | |
| C-01 | Federal Relocation Arc — instance EXIST | C via C1c, ceiling C | ✅ |
| C-02 | Greenbrier 1991 — HARDEN | C | ✅ |
| **D** | | | |
| D-01 | Greenbrier 1991 — CONTROL(federal) | D (capped from E by clamp) | ✅ |
| **E** | | | |
| E-01 | DIA — FUNCTION(hardened federal facility) | E | ⚠️ |
| E-02 | Greenbrier 1991 — FUNCTION(COG) | E | ⚠️ |
| E-03 | Mount Weather — "underground city" FEATURE | E + citogenesis flag | ❌ |
| **F** | | | |
| F-01 | The Montauk Project — FUNCTION | F | ✅ |
| F-02 | Telos, Mount Shasta | F | ✅ |
| F-03 | Sauder / Schneider "129 DUMBs" | F | ✅ |
| F-04 | Bob Lazar / S-4 Papoose Lake | F | ✅ |
| F-05 | Site CARDINAL (canary) | F | ✅ |
| F-06 | Comet Ping Pong tunnel claim | F, **or R if the DOB record resolves** | ❌ |
| **R** | | | |
| R-01 | Cheyenne Mountain — STATUS(current NORAD HQ) | R (R3) | ✅ |
| R-02 | SubTropolis — HARDEN · FUNCTION(COG) | R (R2) | ⚠️ |
| R-03 | Louisville Mega Cavern — FUNCTION(COG/COOP) | R (R2) | ✅ |
| R-04 | DUCC — EXIST | R (R3) | ⚠️ |
| R-05 | Dulce Base — EXIST · HARDEN · FUNCTION · LOCATE | R (R1) | ❌ |
| **X** | | | |
| X-01 | Any newly ingested candidate before search | X | ✅ |
| X-02 | Unrestored Nike magazine — STATUS | X (unknown / unsearched) | ✅ |
| **PIPELINE** | | | |
| P-01 | Fabricated but format-valid CREST identifier | V0, contributes nothing | 🔧 |
| P-02 | Rotating canary candidate | F, never publishable | 🔧 |
| P-03 | Grokipedia / post-2022 unbylined page | zero lineages, retained, displayed | 🔧 |
| P-04 | OSM / Wikimapia `military=bunker` node | lead only, one lineage | 🔧 |
| P-05 | Self-citation ratchet across cycles | no upward movement | 🔧 |
| P-06 | Manzano Base vs KUMMSC | merge schema-prohibited | 🔧 |

---

## BAND A — ESTABLISHED

### A-01 · Cheyenne Mountain Complex, CO — EXIST
**Expected: A** · sources: historian #1, IC #3 (identical) · ✅

Publicly acknowledged since construction; Army Corps engineering records, DTIC reports, congressional
appropriations, GAO reviews; exact surveyed location; published photography; named personnel by the
thousand; many fully independent lineages.

**Route:** A1 on multiple D4 CLAIM-PROPERTY rows. A2–A6 all hold; A6 satisfied at issuing authorities.

**What it guards.** That the model does not penalise a facility for being famous, and that an easy
case requires nothing clever. v0.1 already got this right (94.26 → A) and any revision moving it below
A is broken.

### A-02 · Raven Rock Mountain Complex (Site R), Adams County PA — all propositions
**Expected: A on EXIST, HARDEN, CONTROL, FUNCTION, STATUS, LOCATE, TYPOLOGY** · source: IC #1 · ✅

`|V[D4]| = 2 · L(D3) = 5 · L(D2) = 5 · |V[claim]| = 6 · U = ∅ · SCI = 6/6`

MILCON J-book line with project number and CATCODE (D4, L1); NEPA/EIS describing the hardened
structure (D3, L2); GAO and DoD-IG reports (D3, L3); AFHRA unit histories by IRIS number (D3, L4);
DoD acknowledgment + BSR entry (D4, collapses into L1 — same issuer, §5.1.1); county deed / USACE
construction records (D3, L5).

null = "an ordinary Army communications station, or a granite quarry" → **EXCLUDED** (a quarry has no
CATCODE and no EIS blast scope).

**Additional assertion beyond the letter.** The **PLACE-DERIVED bar must be zero** for the FUNCTION
claim. Portals, terrain and spoil contribute nothing; the CLAIM-DERIVED bar carries all of it. A pass
that shows place-derived weight on FUNCTION is a failing pass.

IC #1 states the stake plainly: *"If a revised rubric moves this below A, the revision is broken."*

### A-03 · 33 Thomas Street, Manhattan — the urban / in-building test
**Expected: EXIST A · HARDEN A · FUNCTION(gateway switch) A · FUNCTION(TITANPOINTE SIGINT) A ·
IDENTITY B** · source: historian #3 · ✅

This is the case that proved v0.1's GEO axis encoded a buried-rural-mountain prior: adits, spoil and
terrain are inapplicable to a Manhattan tower, so 33 Thomas could not clear B (72.11) and would have
needed a GEO score v0.1's own criteria cannot generate for a tower.

**Route:** `typology_profile = urban/in-building` selects a different catalog. `|V[D4]| = 1 ·
L(D3) = 3 · L(D2) = 5`. NYC DOB filings with the survivability design documentation (D4, L1); AT&T's
own engineering and route literature (D3, L2); Warnecke's architectural record (D3, L3); municipal
energy-benchmarking disclosure (D2, L4); roof vent-stack array (D2, L5); no leasable floor plate
(D1).

**Boundary demonstration the suite must also check:** if the DOB filing does not itself state
hardening intent, §3.4(d) fails on e1, A1 fails, and the entry falls to **B** on L(D3) = 3, with
`limiting_condition` naming the document that decided it.

**The decomposition is the point.** The Snowden material is often summarised as "proof 33 Thomas is
an NSA site." It is two propositions: FUNCTION(TITANPOINTE) at **A** on agency-originated T1 documents
(The Intercept is the retrieval CHANNEL, not the origin tier), and IDENTITY(TITANPOINTE ≡ 33 Thomas)
at **B** — the journalists' correlation, with `limiting_condition = "A1 — no record from either party
asserts the equivalence."` An A-grade fact about a codename, an A-grade fact about a building, and a
B-grade link between them, on one page, without contradiction.

### A-04 · Mount Weather Emergency Operations Center, VA — EXIST
**Expected: A** · sources: historian #13, IC #4 · ✅

Federally acknowledged; on the public record since at least the TWA Flight 514 crash of 1 December
1974 (the NTSB report is T1 and places a federal facility on the mountain); FEMA budget lines; exact
location.

**Paired with E-03**, which is the operationally important half.

### A-05 · The Greenbrier / Project Greek Island — post-1992
**Expected: A on EXIST, HARDEN, CONTROL, FUNCTION · transition_cause NEW-DISCLOSURE** ·
sources: historian #5, IC #5 · ✅

Ted Gup, *Washington Post*, 31 May 1992; then official acknowledgment, decommissioning,
declassification, public tours.

**The regression test is the PAIR with B-05/C-02/D-01/E-02.** The system must record that the
transition was caused by **disclosure, not by the arrival of new evidence about the physical world**,
and render `NEW-DISCLOSURE` visually distinct with the annotation *"the publication record changed;
the world did not."*

**Additional assertion:** `grade_as_of('1991-06-01')` must still return the 1991 vector after the 1992
re-grade lands, and `grade_history` must name the Gup article as the observation that moved it.

### A-06 · Iron Mountain / Boyers, PA — OPM Retirement Operations Center
**Expected: A** · sources: historian #7, IC #7 · ✅

Former US Steel limestone mine (excavated 1902–1952); federal records storage from 1960; OPM occupancy
from 1970; ~580,000 rentable sq ft per GSA's 2015 prospectus; OPM's own published material; extensive
named-source journalism. Typology **storage & archive**, not COG.

**Paired against R-02 (SubTropolis).** Both are limestone mines with federal-adjacent tenants. Boyers
has direct T1 documentation of the federal operation; SubTropolis does not. **A model that separates
them on place-signals rather than on documentation is measuring the wrong thing** — and on
place-signals they are identical.

### A-07 · Titan II Missile Site 571-7, Green Valley AZ
**Expected: A** · source: IC #6 · ✅

Fully documented Air Force real property; complete construction and deactivation record; publicly
toured; exact coordinates. STATUS decommissioned/converted; typology missile silo.

**What it guards.** A large fraction of the register will be Atlas/Titan/Minuteman sites. They must
not clog the middle bands. Under the silo/launch-facility catalog, EXIST/CONTROL/LOCATE are
near-trivially D4 and the live propositions are STATUS and current CONTROL.

### A-08 · Camp Hero Air Force Station, Montauk NY — EXIST and FUNCTION(radar)
**Expected: A** · sources: historian #9, IC #14 · ✅

Army coastal artillery 1942; USAF radar 1952–81; AN/FPS-35 within SAGE; NARA unit records; closure and
disposal records; EPA files; NY State Parks acquisition; the tower still standing.

**Paired with F-01 at the same coordinates.** The register must publish both without contradiction.
v0.1 returned 84.42 → B from axis-weighting drag, and had no way to hold the two propositions apart.

### A-09 · Mount Pony, Culpeper VA — the non-appropriated blind-spot control
**Expected: A on EXIST, HARDEN, CONTROL, FUNCTION(COG), STATUS(converted) · four ERP profiles at X0 ·
coverage note published** · source: skeptic · ✅

Dedicated 10 December 1969; 140,000 sq ft; foot-thick steel-reinforced concrete; lead-lined shutters;
semi-recessed under 2–4 ft of earth; held shrink-wrapped currency for post-attack monetary
reconstitution 1969–1988; central node for US electronic funds transfer; COG until July 1992 with a
peacetime staff of 100 supporting 540 for 30 days; purchased 1997 by the Packard Foundation for $5.5M
on behalf of the Library of Congress.

**Under v0.1 it lost roughly 40 points across DOC and OWN** because the Federal Reserve is self-funded:
no appropriations line, no MILCON J-book, no FRPP entry, no FPDS record, and the 1997 transfer was not
a GSA disposal.

**What the suite must assert, beyond the letter:**
1. MILCON/DD-1391, FPDS/USAspending, FRPP and GSA-disposal profiles all return **X0** and therefore
   produce **no rows** — not zeros.
2. Those searches were **still executed** and their negative receipts logged and annotated.
3. **SCI = 1.0**, not 0. (The denominator-zero correction in §7.2 exists for exactly this case; the
   naive reading pins Mount Pony at X forever.)
4. The coverage note renders on the entry page in the prescribed words.

*A blind spot in a grading system is a safe harbour for fabrication.* This case matters beyond
itself: a fabricator labelling an invention "Federal Reserve continuity facility" still has to produce
a Board publication that resolves at the issuing authority, matches metadata and binds to the subject.

### A-10 · Louisville Mega Cavern — FUNCTION(designated civil-defense fallout shelter, 1960s–70s)
**Expected: A** · source: skeptic (paired test, half one) · ✅

Genuinely true and genuinely documented: the working limestone mine was a designated nuclear fallout
shelter planned to hold up to 50,000 people, with a designated-occupant list and real Office of Civil
Defense shelter-survey records behind it.

**Route:** the OCD Community Fallout Shelter Program survey record names this space as a licensed
shelter with a stated capacity. §3.4: (a)✓ (b)✓ (c)✓ (d)✓ names the function on its face (e)✓ OCD has
authority over shelter designation (f)✓ → **D4** → A1 ✓ → **A.**

**A real, primary, on-topic credential, granted in full and without grudging.** The suite must assert
that this reaches A cleanly, because its function is to establish that the mundane truth here scores
legitimately high — **which is what makes R-03 dangerous.**

### A-11 · DUCC — PROGRAM and STATUS(never-built)
**Expected: PROGRAM A · STATUS(never-built) A · LOCATE non-located** ·
sources: historian #12, IC #11 · ✅

`|V[D4]| = 2 · L(D3) = 4 · |V[claim]| = 5`

JCS/OSD memoranda in FRUS 1964–68 vol. X (D4, L1 — FRUS ships as git-clonable TEI XML, so resolution,
subject binding and quote-grounding are deterministic and offline-verifiable, and A6 is satisfied at
the issuing authority); the FY1965 appropriations record showing the rejection (D4, L2); declassified
feasibility studies (D3, L3); the Hitch memorandum (D3, collapses into L1); LBJ Library holdings
(D3, L4).

null = "a paper study never seriously considered" → **EXCLUDED** (a memorandum reaching the President
and drawing a recorded appropriations refusal is not an unconsidered study).

**Structural assertion:** PROGRAM is `clamp_exempt` **by trigger, never by agent choice**. Without
that exemption the monotone clamp would drag PROGRAM down to EXIST's R and the entry would be
unrepresentable. This is the single schema decision that makes DUCC expressible.

**Also assert:** `STATUS = never-built` is a valid enum value. v0.1's nearest option was
"alleged-only," the epistemic opposite.

Sibling cases on the same pattern: SAC's Deep Underground Support Center; NORAD's Survivable Command
Centers.

### A-12 · Dulce Base — ORIGIN(the claim first appears with Bennewitz, Albuquerque, 1979–80)
**Expected: A** · derived from historian #11's "with the origin documented" · ✅

**The part v0.1 could not do at all.** Dated APRO Bulletin and regional newsletter appearances in the
AFU collection on Internet Archive — **T5 content quality, T2 archive quality**, recorded as **both**
(§3.1) — and **D4 for the ORIGIN class**, because the dated earliest artifact retrieved with a receipt
*is* the evidence for an origin claim. Plus Bishop's reconstruction (T3, transparent compiler).

**Plus the NEGATIVE RECEIPT the ORIGIN definition requires**: logged, dated searches over Wayback CDX,
IA full-text `hits_inside`, the AFU newsletter runs, UTZOO mirrors and the mirrored aggregator corpus,
returning no earlier appearance, with query strings, corpora, versions and result counts recorded.

A3 holds because the null "the claim predates Bennewitz and he merely repeated it" is EXCLUDED by that
negative receipt.

**This is the register publishing an A-grade fact about a fabrication**, which is the stated
philosophy, and it is why ORIGIN is clamp-exempt.

### A-13 · The Montauk Project — ORIGIN(Nichols & Moon, 1992)
**Expected: A** · derived from historian #10 / IC #14 · ✅

Same route as A-12: the dated 1992 artifact, retrieved with a receipt, plus a negative receipt across
the canonical ORIGIN set. Published **beside** A-08 (Camp Hero EXIST A) and F-01 (the claim, F) at the
same coordinates.

### A-14 · SubTropolis — EXIST, TYPOLOGY(commercial-underground), CONTROL(Hunt Midwest)
**Expected: A on all three** · derived from IC #10's *"an A-documented commercial underground
facility"* · ✅

MSHA records, recorded leases, surveyed geometry, the operator's own material.

**The register holds this as a true, useful, boring entry**, and it must, because R-02 is on the same
page. An entry that refutes a facility's COG claim while grading its real existence A is the product.

### A-15 · SF-88L, Marin County CA — restored Nike site
**Expected: A** · source: IC #17 (contrast case) · ✅

Same facility type as B-04, different evidence depth. **The suite asserts that A-15 and B-04 are
separated by roughly one band, not four.** Under v0.1 they separate by four, because the unrestored
site has no photography, no tours and no named accounts to feed the axes.

### A-16 · Manzano Base, Kirtland AFB NM — EXIST and FUNCTION
**Expected: A · STATUS decommissioned** · source: skeptic (entity-resolution trap) · ✅

Underground nuclear weapons storage tunnelled into the Manzano Mountains; begun 1947, functional 1950,
complete 1961, phased out around 1992.

**Paired with B-02 and P-06.** See P-06 for the assertion that actually matters.

### A-17 · Groom Lake / Area 51 — EXIST
**Expected: A** · source: skeptic · ✅

The parent site of F-04. Real, acknowledged, documented. **Its function in the suite is to be the
credibility donor that F-04 must not inherit from.**

### A-18 · Fairview, Kansas — EXIST, CONTROL(AT&T historic), FUNCTION(hardened long-haul relay), LOCATE
**Expected: A on all four** · derived from IC #9 · ✅

- **EXIST via A1-alt**: two independent verified direct observations by resolvable named persons with
  lawful physical access, each with georeferenced imagery matched to a public control point (e4, e5),
  plus a T1 record placing a structure on the parcel (e1, the Brown County deed). *You can stand in
  it, two resolvable people have, and the deed recites it.*
- **CONTROL** A1 ✓ via the recorded deed chain.
- **FUNCTION(relay)**: FCC ULS/ASR names the licensee and the microwave path from a licensing
  authority **with authority over the licence** → §3.4 satisfied → D4 → A.
- **LOCATE(±20 m)** A1 ✓ on parcel geometry.

**The §3.4(e) discrimination the suite must assert:** the same FCC record is **D4 for FUNCTION(relay)
and at most D2 for HARDEN**, because the FCC has authority over the licence and not over the
hardening. If a scorer awards D4 to HARDEN from the FCC record, the suite fails even though the letter
for FUNCTION is right.

**Fact-key merge assertion:** e1 (deed), e2 (ASR) and e3 (Long Lines records) all assert
`fact_key = 'AT&T owned and operated this site'` and merge to the strongest for L-counting. One fact
must not enter as three lineages.

---

## BAND B — CORROBORATED

### B-01 · Fairview, Kansas — HARDEN(blast)
**Expected: B · ceiling A · at_ceiling FALSE** · source: IC #9 · ✅

**THE CRITICAL NEGATIVE-CONTROL PAIR, with R-02.** v0.1 scored the commercial warehouse (60.23 = C)
**above** the real bunker (56.25 = C). Two cases, opposite ground truths, indistinguishable output.

`L(D3) = 2`: {the AT&T corporate engineering record identifying the site as a hardened L-carrier main
station — CLAIM-PROPERTY, D3} and {the direct observation of blast doors and shock-isolated equipment
— **one** observational lineage, since §5.1.7 collapses two visitors describing the same door}.

B1 ✓ · B2 ✓ null = A07 "an ordinary telephone repeater building" **EXCLUDED** (a repeater hut has no
blast door and is not buried) · B3 ✓ · B4 ✓ `|V[claim]| = 3`.

A1 ✗ — no design-standard citation or as-built naming the site has been retrieved; the deed recites
the structure but does not specify protective engineering, so §3.4(d) fails for HARDEN.

`limiting_condition = "A1 — no D4 design-standard citation or as-built. The documents that would move
this: the AT&T L-carrier hardened-station engineering specification, or a corporate filing citing
it."`

***That limiting condition is the register's real product: it tells a researcher exactly what to go
find.*** The suite asserts the limiting condition text, not just the letter.

**The compiler-transparency branch, which must also be computed and published:** long-lines.net is T4
and exposes its primaries. If the underlying Bell System Practice resolves, the PRIMARY is the lineage
and the compiler scores nothing. If it does not resolve, long-lines.net is one T4 terminus at catalog
D2 → e3 falls to D2 → L(D3) = 1 → CAP-1 → **C**, `limiting_condition = "B1"`. **The model must publish
which reading it took and why.**

**Separation assertion:** Fairview and SubTropolis must be separated by **four bands in the correct
direction**.

### B-02 · KUMMSC, Kirtland AFB NM
**Expected under BES: EXIST A · HARDEN A · EXTENT D** · reviewer expected composite **B** ·
source: IC #8 · 🔷 **PAIR, NOT LETTER**

IC #8: *"Acknowledged, appears in DoD/DOE documentation and environmental filings, existence and
general function certain, but internal extent, capacity and current inventory are inferred rather than
documented. This is the intended meaning of grade B."*

BES has no composite, so there is nothing that can be "B." **The reviewer's stated requirement —
"existence solid, extent partly inferred" — is exactly a pair, and the decomposition satisfies it.**
But it is not a letter-for-letter match and the suite must not report it as one.

**Assertion:** EXIST at A, EXTENT at D, on the same entity, at the same instant, with EXTENT's
`limiting_condition` naming what is missing. A run that produces a single letter for this entity has
failed regardless of which letter.

### B-03 · Presidential Emergency Facility "Cartwheel", Fort Reno Park, Washington DC
**Expected: EXIST A · EXTENT D — OR — EXIST C via C1c** · reviewer expected **B** ·
source: historian #6 · 🔶 **MARGINAL** 🔷 **PAIR, NOT LETTER**

Existence and function documented in White House Army Signal Agency / WHCA records and in PEF
microwave-network documentation, with a direct AT&T cable route to the White House. Internal extent
and current condition partly inferred.

v0.1 returned 53.11 → D, *"weak inference"* — because the GEO axis finds nothing to reward in a city
park and CONTAM penalised the fact that **one careful compiler did the collation**. That second half
is the scholarship-vs-rumour defect: transparent-compiler pass-through (§5.1.3) is what drags
Cartwheel out of D.

**The branch the calibration text cannot settle:** if the WHCA records name Fort Reno at **instance**
level, the entry is **A**. If they document the PEF network at **class** level, the instance record is
`scope = CLASS`, excluded from V, and the entry reaches **C** via C1c — provided the candidate set is
enumerated, closed and published with M ≤ 3N.

**Assertion:** either outcome passes, **but `marginal_flag` MUST be TRUE and the branch taken must be
named in `limiting_condition`.** A run that returns A or C without the marginal flag has failed.

### B-04 · An unrestored Nike Hercules launch magazine on private agricultural land
**Expected: EXIST A · TYPOLOGY A · STATUS unknown/X** · reviewer expected composite **B** ·
source: IC #17 · 🔷 **PAIR, NOT LETTER**

Categorical existence is certain — the Army built hundreds and the site lists, real property disposal
records and county deeds are public — but site-specific documentation for any individual unrestored
magazine is thin, and current condition and status are genuinely unknown.

**What it guards.** That the model does not punish a facility for being **ordinary and well-attested
at the class level rather than dramatically documented at the instance level**. See A-15 for the
one-band separation assertion.

**Note the interaction with X-02:** STATUS here is genuinely X (not searched / not knowable from the
record), not F. X must render visually distinct from F.

### B-05 · The Greenbrier / Project Greek Island, 1 Jan 1991 — EXIST
**Expected: B · at_ceiling TRUE · silence UNINFORMATIVE · base rate VERY-RARE** ·
⚠️ **REVIEWER CONFLICT** (historian: C on evidence; IC: B)

**THE FLAGSHIP CASE.** In 1991, a fully staffed 1,100-bed congressional relocation facility with
essentially no documentary trace, behind a Forsythe Associates cover. v0.1 returned 22.91 → **E,
"folklore with a trace"** — printed over an operating COG facility.

Typology buried-rural. Reference class **RC5** (a resort on private land — taken because §6.5 requires
the lowest reading when ambiguous). ERP profile "active COG facility under commercial cover" → all
documentary classes X0; county deed X3; HTMC X3.

`L(D3) = 2 · L(D2) = 5 · |V[claim]| = 5 · |V[D4]| = 0 · U = ∅ · null_state = EXCLUDED`

| | Row | Tier | D |
|---|---|---|---|
| e1 | Greenbrier County recorder, construction and parcel records, 1958–61 West Virginia Wing | T1 | D2 |
| e2 | Local press 1959–62 (Chronicling America / Open ONI): anomalous concrete volumes, out-of-state contractors, sustained heavy trucking | T2 | D2 |
| e3 | Utility filing, electrical service far exceeding above-ground floor area | T1 | D2 |
| e4 | Named construction worker, resolvable in a union roll and a local obituary created for an unrelated purpose, describing a concrete structure with a heavy steel door; **custody satisfied** (bylined quotation in named local press) | T2 | D3 |
| e5 | Second named worker, likewise resolvable and bylined | T2 | D3 |

**The deliberate hinge — why A1 fails.** A1's second clause reads "two rows at D3 in two independent
lineages, both CLAIM-PROPERTY," which e4 and e5 satisfy on their face. But they describe the SAME
OBJECT (one door, one excavation); §5.5 fact-key merging collapses them on
`fact_key = 'a large hardened subsurface structure was built under the West Virginia Wing'` → one row
survives for A1 purposes. **A1 fails; `marginal_flag = TRUE`.**

B1 ✓ (L(D2) = 5 ≥ 3, with L1 and L3 rooted at T1) · B2 ✓ · B3 ✓ · B4 ✓ → **B**.

`limiting_condition = "A1 — no dispositive primary record; the expected-record profile predicts none"`

**NEGATIVE RECEIPTS ASSERTION.** Searches against CREST, DTIC, NARA, GovInfo, FRPP and GSA disposal
were **executed and logged**, and every profile returns **X0** under "active facility under commercial
cover" → **NO ROWS**. A run that scores those absences against the facility has failed, and that is
precisely what v0.1 did.

**Boundary demonstrations the suite must also run:**
- If only ONE worker resolves: L(D3) = 1, L(D2) = 4 — B1's second clause still holds on the three
  documentary lineages → **still B**.
- If the utility filing also fails: L(D2) = 2 < 3 and L(D3) = 1 → CAP-1 → **C**,
  `limiting_condition = "B1 — fewer than three independent D2 lineages."`

*The band turns on named, checkable facts an auditor can re-run.*

**The conflict, recorded.** The historian expected C on evidence with P(exists) HIGH published beside
it; the IC analyst expected B. BES takes the IC reading, because three verified claim-property
lineages satisfy B1's second clause on the record alone. **BES also declines the historian's requested
form** — a published probability — and substitutes `at_ceiling` + `silence_reading` +
`base_rate_reading`. See GRADING.md §17.1.

### B-06 · 33 Thomas Street — IDENTITY(TITANPOINTE ≡ 33 Thomas Street)
**Expected: B** · derived from historian #3 · ✅

See A-03. `L(D3) = 2`; B1–B4 hold; A1 fails because no record from either party asserts the
equivalence.

**Consequence assertion:** because IDENTITY is at B (≥ C), §11.1 permits the alias to be used for
subject binding on the SIGINT proposition. **The merge is evidenced rather than assumed.** If IDENTITY
were below C, the alias must not be usable for binding — and the suite should test that direction too.

---

## BAND C — SUPPORTED

### C-01 · An unnamed "Federal Relocation Arc" site from declassified 1960s OEP records
**Expected: C via C1c · ceiling C · LOCATE non-located** · source: IC #16 · ✅

**THE REAL-BUT-UNLOCATED TEST.** Declassified T1 records establish that a set of relocation facilities
existed and describe their programme function, **without individually identifying or locating each
one**.

`PROGRAM(Federal Relocation Arc)` = **A** on the declassified record.

For an individual candidate hilltop the OEP record is `scope = CLASS` and is **excluded from V for the
instance** — this closes the defect in which class evidence was credited at full strength to every
instance.

**C1c fires if and only if all of:**
1. the candidate set is enumerated, closed and published;
2. N (documented instances) and M (live candidates) are published;
3. **M ≤ 3N**;
4. ≥1 verified instance-scope CLAIM-PROPERTY row at D1+ ties this candidate to the set — e.g. a
   WHCA/Army Signal Agency microwave path record terminating at this coordinate, or an AT&T cable
   route into the parcel.

→ **EXIST = C**, ceiling C (the path's ceiling **by rule**),
`limiting_condition = "A1/B1 — no instance-level dispositive record; grade rests on membership in a
documented candidate set of M=12 against N=8."`

**THE DILUTION ASSERTION, which is the anti-gaming half.** Adding a thirteenth candidate recomputes M
for **all twelve** as a versioned `CANDIDATE-SET-CHANGE`; if M exceeds 3N the whole set drops to D.
**Adding candidates dilutes.** The suite must add a candidate and assert that every existing member
re-grades. This is the standing countermeasure to a find-rewarded fleet's regional-gap-filling
incentive.

**LOCATE assertion:** `non_located`, or a regional polygon. **Never a pin.** A precise pin manufactured
from imprecise evidence is the register performing its own citogenesis at the interface layer.

### C-02 · The Greenbrier, 1991 — HARDEN(blast)
**Expected: C · CAP-1 applied · at_ceiling TRUE** · ✅

Only e4/e5 describe the steel door; fact-key merge → L(D3) = 1. B1 ✗. C1a ✓ (a resolvable witness's
description of a blast door is CLAIM-PROPERTY at D3) → **C**, CAP-1 confirmed.

---

## BAND D — INDICATED

### D-01 · The Greenbrier, 1991 — CONTROL(federal)
**Expected: D · CAP-2b in applied_caps · at_ceiling TRUE** · ✅

Cover entity is Forsythe Associates, a TV-service contractor. Negative receipts against
FPDS-predecessor, GSA inventory, FRPP and the deed chain — all **X0** → no rows.

`V[claim] = ∅` (the power anomaly is PLACE-PROPERTY: it would be recorded identically under the null)
→ **CAP-2b fires → max E.** Band D conditions hold (D1 via the D1 utility anomaly; null SURVIVING) →
`grade = min(D, E)` = **D**.

**Assertion:** CAP-2b must appear in `applied_caps` even though it did not bind. A run that reaches D
without recording the cap is recording a different mechanism than the one that ran.

---

## BAND E — DOUBTFUL

### E-01 · Denver International Airport — FUNCTION(hardened non-airport federal facility beneath the terminal)
**Expected: E** · ⚠️ **REVIEWER CONFLICT** (historian: F; IC: E)

IC #12 called this *"the single most important thing to test before ratification"* and wrote: *"A
published C-grade DIA bunker entry would on its own destroy the register's credibility."* v0.1 returns
45.78 at CONTAM 60 and **55.59 = GRADE C** at the more defensible CONTAM 30.

`EXIST(large underground works at DIA)` = **A** — baggage tunnels, utility tunnels, the inter-concourse
train, all in T1 records. True, boring, published, displayed alongside.

Everything the blind fleet returns, through the catalog:

| Observation | Result |
|---|---|
| GAO audits on cost overruns and the failed baggage system (T1) | **supports the NULL** |
| large-footprint underground structures and tunnels (T1/T2) | **D0**, PLACE-PROPERTY |
| enormous dedicated electrical load (T1) | **D0** for an airport of this size |
| dedicated fuel farm and pipeline (T1) | **D0** |
| deep wells (T1) | **D0** (universal list) |
| construction contracts sequenced, terminated, reissued (T1 FPDS) | **supports the NULL** |
| 1990s Denver press describing buried structures (T2) | **D0** |

Origin artifacts (Alex Christopher, Phil Schneider, mid-1990s) are SELF-ATTESTING → excluded from V,
routed to ORIGIN.

`V ≠ ∅ · V[D2+] = ∅ · |V[claim]| = 0`

**Refutation, and why it must NOT fire:** R3? No agency record states "there is no facility beneath the
terminal." R2? `null_state = DOMINANT` ✓ — **but R2 also requires ≥2 verified UNDERCUTS rows improbable
under the proposition, and there are none.** *The airport's documented ordinariness explains the
signals; it does not contradict a concealed facility.* **A complete mundane explanation removes
probative value; it does not disconfirm.** → **R0.**

CAP-2b → max E. E1 ✓ · E2 ✓ → **E**.

**THE DEEPEST ASSERTION IN THE SUITE.** Six of seven agents independently returned **real T1 signals**,
and not one discriminated {hardened federal facility} from {very large airport, built badly}. Under
v0.1 that read as COR 65 and CONTAM 30 — *"converging open signals."* The suite must assert that the
six returns produce **six D0 rows satisfying zero conditions above D**, and that CAP-2b — not luck —
holds the ceiling at E.

**The conflict, recorded.** The historian expected F. BES follows the IC: V is not empty, so F would
misdescribe the evidentiary state. **E-01 and F-01 together define the E/F line**, and they are the
pair that most sharply tests §2.5.

### E-02 · The Greenbrier, 1991 — FUNCTION(congressional relocation)
**Expected: E · CAP-2b binding · at_ceiling TRUE · base rate VERY-RARE** ·
⚠️ **REVIEWER CONFLICT** (IC: F)

null = A10 "a private hardened shelter for hotel guests." In 1991 the local attribution is diffuse,
unattributed town talk — SELF-ATTESTING and unresolvable → excluded from V (§2.5). What remains: the
communications plant sized far beyond resort needs (D2, but **PLACE-PROPERTY**).

`V ≠ ∅ · V[claim] = ∅` → **CAP-2b → max E**; `V[D2+] ≠ ∅` so E2 fails and D applies, capped → **E**.

**This is the case CAP-2b was written for**, and it is the single hardest constraint in the anti-gaming
ledger: *no FUNCTION claim exceeds E without a verified, instance-scope, subject-bound, CLAIM-PROPERTY
observation.*

The IC's F is declined because V is not empty. E ("verified support exists but fails to discriminate")
is the accurate description.

### E-03 · Mount Weather — the "underground city" FEATURE claim
**Expected under BES: E + citogenesis flag, inside an A-grade site** · reviewer expected **D** ·
source: historian #14 · ❌ **KNOWN DIVERGENCE — one band, conservative**

The historian calls this *"the most operationally important entry in the set."*

Streets, sidewalks, a small lake fed by underground springs, its own mass transit system. Every
circulating version descends from Richard Pollock, *"The Mysterious Mountain,"* **The Progressive,
March 1976**, resting on Senate subcommittee material plus unnamed off-the-record former officials —
**a T3 publication built on T5 testimony, the exact laundering pattern citogenesis detection exists to
name.**

**Route:** Pollock is a journalist reporting others' attestation, **not the claimant** — so §2.5 does
NOT exclude him. His report enters V at **D0** (unresolvable-attestation floor). `V ≠ ∅ ·
V[D2+] = ∅ · |V[claim]| = 0` → CAP-2b → max E; E1 ✓ E2 ✓ → **E**. CAP-3 also fires on the confirmed
citogenesis loop → max E, reached by two routes.

**The divergence.** The historian expected D. BES returns E. **The entry's operative requirements are
all met** — A on the site (A-04), the flagged claim on the same page, and the flag attached to the
**proposition** rather than having nowhere to live. E ("the claim survives only as a claim") is judged
a truer description than D ("signals consistent with the proposition and equally consistent with the
named alternative"), because there are no *signals* here at all, only a report of testimony.

**THE SUITE ASSERTS E.** If a future change makes this return D, that change must be justified against
this note, not treated as a bug fix.

**Structural assertion, independent of the letter:** the citogenesis flag attaches to the
**PROPOSITION**, not the site. Under v0.1 this content rode inside an A-grade entry with the flag
having nowhere to attach — which is the defect, and it is invisible in the letter alone.

---

## BAND F — UNSUPPORTED

### F-01 · The Montauk Project — FUNCTION(underground levels, time and mind-control experiments)
**Expected: F · ORIGIN A** · sources: historian #10, IC #14 · ✅

Every circulating version traces to Preston B. Nichols' recovered memories in the 1992 book with Peter
Moon. Semantic clustering (§5.1.6) collapses every later appearance into that origin → **L = 1**.
§2.5: **Nichols is the claimant and the book's probative content is the claim itself** →
SELF-ATTESTING → excluded from V, routed to ORIGIN.

What remains in V: **nothing**. The base's real documentation is bound to EXIST(camp-hero) and
CONTROL(USAF), **not to this proposition** — proposition binding plus subject binding make the
citogenesis mechanism unavailable to the register itself.

**V = ∅.**

**Refutation must NOT fire.** R1? Recovered memories are not an admission of fabrication, not a
documented disinformation operation, and there is no post-dating impossibility. R2? Requires ≥2
affirmative UNDERCUTS at D2+; the NY State Parks and EPA site surveys returning no such levels are
**expected-record negatives**, and **§8.4 forbids R on those alone.** → **R0.**

E1 requires V ≠ ∅ → **fails**. CAP-5 → max **F**.

**THE E/F LINE, STATED.** DIA's V contains verified third-party records of real facts that fail to
discriminate → **E**. Montauk's V is empty because the only artifact **is** the claim → **F**. *That
line falls out of one written rule and it is checkable.*

v0.1 returned 43.29 → D, *"suggestive but thin,"* because the claim inherited the real base's
DOC/GEO/INF/OWN.

### F-02 · Telos, the Lemurian city beneath Mount Shasta CA
**Expected: F · ORIGIN A** · source: IC #15 · ✅

Pure literary origin, traceable to Frederick Spencer Oliver's 1894 novel *A Dweller on Two Planets*
and subsequent Lemurian Fellowship literature. **The cleanest case of the backward-sourcing method: a
claim whose origin document is openly a work of fiction.**

Same route as F-01: the author is the claimant, the content is the claim → V = ∅ → CAP-5 → F.

**Second assertion:** the claim is attached to real, dramatic, geologically anomalous terrain — a
stratovolcano with genuine lava tubes and caves. **It must not inherit a place-derived floor.** Under
v0.1 it would.

### F-03 · The Sauder / Schneider "129 Deep Underground Military Bases" corpus
**Expected: F · ORIGIN A/B** · source: IC #2 · ✅

No coordinates for any of the 129; no procurement record for a construction programme of the asserted
scale; no spoil-volume accounting; originator employment credentials never independently corroborated;
traces to a small self-published 1990s origin set.

§2.5: Sauder is the claimant → self-attesting → V = ∅ → CAP-5 → **F**.

**THE §8.4 ASSERTION, WHICH IS THE POINT OF THIS CASE.** The expected-record negatives here are deep
and real: X3 profiles on MILCON, on procurement traces >$50M, on spoil-volume signatures. A model that
licenses R from negatives alone returns **R** — which is wrong, and is the characteristic failure mode
of any evidence model with signed negatives. **§8.4 forbids it.** The suite must assert
`refutation_state = R0` and `grade = F (SILENCE-DOMINATED)`.

**The Sauder-as-bibliography move, which must also be handled correctly.** One registry proposed
regexing document identifiers out of Sauder's books to "convert a P4/P5 library into a P1 lead list."
Those identifiers are **LEADS** and become citations only after independent resolution at DTIC / NTRL /
Federal Register. **His documents get promoted; his conclusions stay T4.** The suite asserts that a
lead extracted from a fringe book cannot become a citation without an independent receipt.

IC #2: *"If a revised rubric moves this above F, the revision is broken."*

### F-04 · Bob Lazar / "S-4, Papoose Lake", Nevada
**Expected: F on the S-4 underground-facility claim; A on Groom Lake (A-17)** ·
source: skeptic · ✅

**THE HARDEST TESTIMONY CASE IN THE SUITE**, and the one that forced a rewrite of §5.4.

The skeptic's framing: both prior lenses used "Thomas Castello" (a person who appears not to exist) and
a Site R communications NCO (a person fully resolvable in unrelated records). **Lazar is the hard
middle**: an unambiguously REAL, publicly identifiable, named individual, on the record from 1989 in
dated broadcast interviews — so he satisfies any *identity* gate — **whose CREDENTIALS and employment
are the disputed element** and whose claimed degrees have never been corroborated by the institutions
named.

Under v0.1 the claim inherits GEO, INF and OWN from genuine Nevada terrain and genuine restricted
airspace — the highest-value GEO signal on the rubric's own list.

**The fix this case forced.** §5.4 is a **position-to-know** gate, not an identity gate:

> the individual must be independently locatable in a record that **predates the claim**, was
> **created for an unrelated purpose**, and **places them in the role asserted**.

Lazar fails the third clause. His account is **D0**. Continuous restricted airspace over Groom Lake is
a genuine D2/D3 signal — **but for propositions about Groom Lake, not about a claimed separate facility
at Papoose Lake**, where it is `scope = ADJACENT` and excluded from V entirely.

→ **F.**

### F-05 · Site CARDINAL, Pendleton County WV — the confabulation canary
**Expected: F, deterministically, with five identifiers logged as measured confabulation** ·
sources: skeptic, BES Part 14 · ✅

**THE CASE THAT DECIDED THE MODEL ADJUDICATION.** Under v0.1 this dossier scored DOC 90, GEO 80,
INF 70, OWN 65, TEST 45, COR 80, CONTAM 0 → **76.10 → GRADE B**, *"strongly evidenced, existence
solid."* **Nothing in it exists.**

| What the fleet returns | What happens |
|---|---|
| Three CREST identifiers `CIA-RDP…-1/-2/-3` | grammar **PASSES** (the format is a regular grammar); 404 at cia.gov/readingroom AND the IA CREST mirror → UNRESOLVED-NOTFOUND → **V0** |
| One DTIC `AD-xxxxxx` | grammar PASSES; 404 at apps.dtic.mil and the IA mirror → **V0** |
| "An adit symbol at 38.6xx, −79.4xx on the 1953 quadrangle" | the HTMC point-in-polygon DOES return the sheet and the GeoTIFF IS fetched — **that part is real**. But the reading is an INTERPRETATION and inherits the tier of whoever asserted it → **T5**, a hypothesis, until a different-family blind second read plus a citation to the era-correct symbol standard. Neither exists → excluded |
| A real FCC ASR registration 3 km away | resolves, real, T1 — but `scope = ADJACENT` → **excluded from V. Proximity is not support.** And even at INSTANCE scope, a tower is catalog-D1 |
| "A plausible appropriations line" | no GovInfo package ID, no resolution → **V0** |
| An account citing an alleged local newspaper | no Chronicling America / Open ONI hit, no receipt → **V0** |

`V = ∅ · |V[claim]| = 0 · L(D2) = 0`

R? No — nothing affirmatively disconfirms, because there is nothing there; §8.4 forbids R on negatives
alone. X? The canonical EXIST search set WAS executed with logged negative receipts, so **SCI ≈ 1.0** →
not X. E? E1 requires V ≠ ∅ → fails. **CAP-5 → F.**

**Assertions beyond the letter, all of which are the actual product:**
1. All five identifiers are **RETAINED** (`v0_count = 5`), not deleted. They are confabulation
   telemetry.
2. The entity is **never publishable** — `is_canary` blocks it at the CHECK constraint, at the
   publication gate, and at the map view.
3. The five identifiers are attributed **per agent** and published in the confabulation rate.
4. Not rendered as a map pin.

**The incentive inversion this repairs.** Under v0.1, citing a forum post required possessing a URL
that exists, while citing a CREST document required only emitting a well-formed string — *the higher
the tier and the more format-regular the identifier, the easier to hallucinate and the more weight it
carried.* Under resolve-or-die the gradient runs the other way, and A6 makes the highest band the most
expensive to fake.

### F-06 · Comet Ping Pong tunnel/basement claim, Washington DC (2016)
**Expected: F — but see the divergence** · source: skeptic · ❌ **KNOWN DIVERGENCE, conditional**

The canonical modern American underground-facility disinformation event, with a dated origin cluster on
4chan and Reddit in late 2016 amplified by a small named set of sites, and a documented real-world
consequence when an armed man entered on 4 December 2016 looking for a basement the building does not
have.

v0.1 returns DOC 3, GEO 5, INF 5, OWN 25, TEST 10, COR 15, CONTAM 100 → 8.64 × 0.5 = 4.32 → **F**.

**The skeptic includes it BECAUSE v0.1 passes, and labels why it passes:** *"not because any gate
detected the fabrication, but because a retail storefront on Connecticut Avenue has no adit, no spoil,
no substation and no terrain to donate. It is the control that isolates the variable."*

**The requirement:** under a corrected rubric it must still return F, **and it must return F for a
stated reason — affirmative refutation, the building has no basement — rather than for lack of
infrastructure.**

**THE DIVERGENCE, AND IT IS INSTRUCTIVE.** Those two requirements are in tension under BES. If the DC
Department of Consumer and Regulatory Affairs building record, a floor plan, or a court record
affirmatively establishes that the structure has no basement, that is a verified, instance-scope,
subject-bound, unsolicited row from a party **with authority over the fact**, directly stating the
negation — **which is R3, and BES returns R, not F.**

- **If the DOB/DCRA record resolves → BES returns R (R3).** This is the *stronger* answer and it
  satisfies the skeptic's second requirement (F for a stated reason) while failing the first (the
  letter F).
- **If it does not resolve → V = ∅ via §2.5 (4chan/Reddit origin is self-attesting) → CAP-5 → F**,
  which satisfies the letter but for the reason the skeptic wanted to eliminate.

**THE SUITE ASSERTS EITHER, AND ASSERTS THAT `limiting_condition` OR `refutation_state` NAMES WHICH.**
It fails if the entry returns F with the origin-lack as the only recorded reason **while a resolvable
building record exists** — because that is the register declining to do the work it exists to do.

This is the same shape as R-05 (Dulce): a reviewer wrote F under a vocabulary in which R was
unreachable, and BES's R is the better answer. Recorded as ratification item R-2's sibling.

---

## BAND R — REFUTED

### R-01 · Cheyenne Mountain — STATUS("it is the current NORAD headquarters")
**Expected: R (R3)** · source: historian #2 · ✅

NORAD/USNORTHCOM operations consolidated at Peterson AFB in 2006 and the complex went to
alternate/warm-standby status. **The claim is stale rather than invented**, and is contradicted by
primary DoD sources.

**Route:** R3 — verified, instance-scope, subject-bound, unsolicited DoD records from a party with
authority over the fact, directly stating the negation.

**THE STRUCTURAL ASSERTION.** This site is simultaneously **A** (A-01, EXIST) and **R** (this case).
*Any rubric returning one number for Cheyenne Mountain fails this entry by construction.* The suite
asserts that both render on the same page without contradiction, and that the R does not clamp the
EXIST.

### R-02 · SubTropolis, Kansas City MO — HARDEN(blast/EMP) and FUNCTION(COG)
**Expected: R (R2)** · ⚠️ **REVIEWER CONFLICT** (historian: R; IC: F) · decision: **R**, following the
historian

**THE CRITICAL NEGATIVE CONTROL**, paired with B-01.

A ~55-million-sq-ft former room-and-pillar limestone mine operating as commercial warehousing. It
scores near-maximum on every place-signal — portals into hillside, ventilation shafts, spoil history,
anomalous road grade, dedicated substation, an actual rail spur, deep wells, fuel permits — plus clean
documented title and lease chain. **And it is not a bunker in any sense.**

v0.1 gives it **60.23 = C, outranking the real AT&T bunker at 56.25.**

null = A02 "a room-and-pillar limestone mine converted to commercial warehousing" — **and this null is
DOCUMENTED AND PUBLICLY ADVERTISED BY THE OPERATOR**, which is why it is the strongest surviving
alternative.

Catalog lookups on everything the fleet offers: **every single one is on the universal-D0 list.**
`|V[D2+]| = 0 · |V[claim]| = 0 · L(D3) = 0` → CAP-2b would cap at E on its own.

**UNDERCUTS rows via the §4.4 matrix:**

| Row | E/A | Result | Lineage |
|---|---|---|---|
| Published tenant lease list (Jackson County recorder, T1) | E0/A3 | **−D3** | U1 |
| Operator marketing with named tenants, published square footage, public site tours (T2, independent) | E0/A3 | **−D3** | U2 |
| MSHA regulated-mine permit | E1/A3 | **−D1** | — |

**R2 fires:** ≥2 independent-lineage verified UNDERCUTS at D2+ improbable under the proposition (U1,
U2 ✓) **plus** `null_state = DOMINANT` (A02 is affirmatively documented by MSHA records, recorded
leases and Missouri DNR filings, and accounts for every row in V ✓). **§8.4's gate is satisfied because
U1 and U2 are affirmative, not expected-record negatives.**

→ **HARDEN = R · FUNCTION(COG) = R.**

**Two independent routes, and the suite must check both.** Had refutation not fired, CAP-2b caps at E
anyway. A run that reaches R via CAP-2b rather than R2 has the right letter from the wrong mechanism.

**The conflict, recorded.** The IC expected F; the historian expected R. **R is taken**: the mundane
explanation here is not merely complete but *affirmatively documented and publicly advertised*, and
the published lease chain and ticketed tours are affirmatively improbable under a hardened-COG claim.
F would say "nothing verified favours the claim," which understates what the record shows.

**The entry is not deleted.** A reader who arrives believing SubTropolis is a bunker leaves with the
refutation and its sources — published beside A-14, where the same facility grades A on what it
actually is.

### R-03 · Louisville Mega Cavern — FUNCTION(COG/COOP)
**Expected: R (R2)** · source: skeptic (paired test, half two) · ✅

**THE SHARPEST FALSE-POSITIVE CASE IN THE SUITE**, and the skeptic states plainly that it is **strictly
harder than SubTropolis**: *"SubTropolis can be argued down on DOC because its federal documentation is
thin; Mega Cavern's DOC is genuine, primary, on-topic and about civil defence, so a diagnosticity fix
alone does not dispose of it."*

Scored honestly with **no fabrication anywhere** — DOC 55, GEO 85, INF 75, OWN 70, TEST 55, COR 70,
CONTAM 15 — v0.1 returns 68.80 × 0.925 = **63.64 → C**; add the free .gov laundering channels and it
reaches **73.81 → B**. It is a commercial storage facility and tourist attraction with underground zip
lines and a Christmas light drive-through.

**The decisive move, and it is made by table lookup rather than by special-casing.** null = A02 "a
commercial limestone mine, now a storage facility and tourist attraction with underground zip lines
and a Christmas light drive-through, **carrying a genuine historical civil-defence shelter
designation**."

**The OCD shelter record** — the genuine, primary, on-topic civil-defence document that grades A-10 at
band A — asks: does a public community fallout shelter evidence a **continuity-of-government**
function? E2 under H; **A3 under A02, which INCLUDES the shelter designation** → §4.4 matrix → **D0**.

***The genuine, primary, on-topic document contributes EXACTLY NOTHING to the COG claim, because the
named alternative explains it completely.*** This is the move v0.1 could not make.

`|V[claim]| = 0` → CAP-2b → max E. UNDERCUTS: ticketed zip lines / mountain-bike park / Christmas light
drive-through (E0/A3 → −D3, T2, U1); continuous public commercial occupancy since 1989 in the county
record and the operator's own filings (E0/A3 → −D3, T1, U2). R2 ✓ null_state DOMINANT ✓ §8.4 ✓ →
**R.**

**THE TYPOLOGY GATE, WHICH IS WHAT THIS CASE ACTUALLY TESTS.** The skeptic: *"Any rubric in which the
typology field is not itself an evidenced, graded proposition fails this entry by construction."*
Under v0.1, an entry could earn a defensible B on "this is a large documented hole with real
civil-defence history" and then be **relabelled COG/COOP at zero cost with the composite unchanged.**

**THE ATTACK IS DEAD**: there is no typology label and no composite. There is only a proposition, and
opening a new one starts it with an empty ledger, a mandatory named alternative that already explains
every observation on the page, and CAP-2b holding the ceiling at E before refutation even runs.

**The .gov laundering channels, each asserted to contribute exactly 0:**

| Channel | Why it is worth nothing |
|---|---|
| A regulations.gov comment naming the facility | SOLICITED-BY-CLAIMANT; author-tier T4, not host-tier T1 |
| A FOIA no-records letter naming the facility | requester's half SOLICITED-BY-CLAIMANT; agency's half a NEGATIVE receipt, and ERP makes it uninformative either way |
| A Zenodo "technical assessment" with a minted DOI | SELF-PUBLISHED → T4; A1 requires T1/T2 |
| An OSM `military=bunker` tag replicating into dozens of renderers | CROWD-EDITED → lead only; **one lineage regardless of renderer count** |

**Published line the suite asserts verbatim in structure:** *"Louisville Mega Cavern — EXIST A ·
TYPOLOGY commercial-underground A · FUNCTION(designated fallout shelter, 1960s) A · FUNCTION(COG/COOP)
R · STATUS operating commercial attraction A."* **Three propositions, three ledgers, no contradiction,
all visible at once.**

### R-04 · DUCC — EXIST(a physical DUCC structure beneath Washington)
**Expected: R (R3)** · ⚠️ **REVIEWER CONFLICT** (historian: R; IC: F) · decision: **R**

*v0.1 returned 37.24 → E, six points above Dulce Base. **A proven non-facility with superb
documentation must not share a bin with an invention.***

**The silence half.** ERP for an excavation of this scale under an appropriated DoD programme: MILCON
lines (X3), procurement traces >$50M (X3), spoil-volume signature >1e5 m³ (X3), NEPA-era documentation
— **all expected**. Canonical set executed; all negative with receipts → three UNDERCUTS rows at −D3.
**`silence_reading = INFORMATIVE`.**

***This is the one case in the entire suite where the argument from silence is valid, and the ERP table
is precisely what licenses it — the same table that forbids the inference for B-05.*** The suite must
assert that DUCC publishes INFORMATIVE and Greenbrier-1991 publishes UNINFORMATIVE **from the same
table**.

**The affirmative half, without which R must not fire.** §8.4 forbids R on expected-record negatives
alone. **R3 supplies the content**: the appropriations record documents non-funding and the programme
record documents cancellation, from parties with authority over the fact, unsolicited, verified,
subject-bound. → **EXIST = R.**

**Assertion:** a run that returns R here **without** the R3 affirmative content has broken §8.4 and
will subsequently refute real facilities whose cover stories are good. Remove the appropriations record
from the fixture and the expected result becomes **F (SILENCE-DOMINATED)**, not R.

The IC expected F; BES returns R because the cancellation is affirmatively documented, which is R3 by
definition.

### R-05 · Dulce Base, Archuleta Mesa NM — EXIST(claimed facility), HARDEN, FUNCTION, LOCATE
**Expected under BES: R (R1) · ORIGIN A** · both reviewers expected **F** ·
❌ **KNOWN DIVERGENCE — declared, and the sharpest one in the suite**

*Under v0.1 grade F was **UNREACHABLE**: the CONTAM multiplier floors at ×0.5, so even a flawless
lineage analysis returned 20.65 → E. And following v0.1's own calibration text ("50 = two or three
independent origins"), the three named claimants yield CONTAM ≈ 55 and the entry **rises** to 23.49.*

null = **A11** "claim fabricated, misattributed or transposed" — **MANDATORY as co-null** because the
support includes a T5 lineage. The alternative scoring against A01 also runs and the **lower** grade
publishes.

**The lineage collapse.** Bennewitz 1979 → popular press 1983 → Lear's 1987 "independent
confirmation" → LeVesque as "Jason Bishop III" → the 1987 "Thomas Castello" documents → "Branton" →
Schneider → bibliotecapleyades → ~400 downstream sites. Semantic clustering: each read the prior one;
none contains a particular absent from its predecessor → **ONE lineage, not four.** Then §2.5: each is
the claimant asserting the claim → self-attesting → excluded from V entirely.

**What is offered and excluded, each for a named reason:**

| Offered | Disposition |
|---|---|
| "Thomas Castello" | fails the §5.4 resolvability gate — no independent record predating the claim, created for an unrelated purpose → **D0**, and excluded as self-attesting |
| Project Gasbuggy (1967 AEC underground detonation ~20 mi away, full AEC/DOE paper trail) | VERIFIED, T1 — but **`scope = ADJACENT`**. **EXCLUDED, displayed as excluded with the reason. PROXIMITY IS NOT SUPPORT.** *Under v0.1 this genuine P1 material pushed DOC to 45* |
| NM State Police cattle-mutilation files (Valdez) | VERIFIED, T1, but bound to a different proposition → excluded |
| Jicarilla/BLM land records, terrain, road cuts, regional mining scarring | INSTANCE, VERIFIED, but PLACE-PROPERTY at **D0** |

**The UNDERCUTS rows — where the historian's fatal #1 gets its hook:**

| | Row | Basis |
|---|---|---|
| u1 | The AFOSI counterintelligence operation against Paul Bennewitz c.1979–82, in which Richard C. Doty supplied forged documents and staged material to steer him from classified Kirtland programs | Doty's on-record admissions; Bishop's *Project Beta* (T3, transparent compiler → §5.1.3 pulls the primaries) |
| u2 | LeVesque's later admission of fabricating Dulce material, documented by Adam Gorightly | distinct admitting party, distinct fact_key, independent lineage |
| u3 | A retired USAF colonel and NM State Police officer Gabe Valdez — both resolvable, both custody-receipted in named press — stating on the record that no such person was employed there | §5.4 satisfied for a **denial** |
| u4 | **POST-DATING IMPOSSIBILITY**: images attributed to "Castello" and dated 1987 include a still from the 2000 film *The 6th Day* | deterministic, machine-checkable |

***UNDER v0.1, u1 ADDED TO THE DOC AXIS.*** A documented disinformation operation counted as
documentation *for* the claim. That single fact is the clearest statement of what signed evidence
fixes.

**R1 — ORIGIN FABRICATED**, on four independent grounds. §8.4's gate is satisfied several times over:
every one is affirmative content, not an expected-record negative. → **R.**

**THE DIVERGENCE, DECLARED.** Both lenses expected F. **BES returns R deliberately.** The historian's
own text demands that the AFOSI/Doty documentation *"must be representable as evidence AGAINST"* —
**that is R by definition**, and their F was constrained by v0.1's vocabulary, in which R was
unreachable. Logged as ratification item R-2 in `docs/GRADING.md` §19.

**THE SUITE ASSERTS R.** A future change returning F must be argued against this note.

**And the contrast published alongside**, which is the whole reason the entry exists:
`EXIST(some constructed works on Archuleta Mesa — roads, gas-field wells)` grades honestly at C or
better. *"There are real works on this mesa" and "the base claim is refuted" sit side by side*, which
is what a reader arriving from the fringe corpus needs to see.

---

## BAND X — NOT ASSESSED

### X-01 · Any newly ingested candidate, before the canonical search set has run
**Expected: X** · derived from BES §7.2, §12.6, §15 · ✅

**X is the correct default for every newly ingested candidate**, and it must render visually distinct
from F. X is not a low grade; it is the absence of one.

**Assertions:**
1. A candidate with SCI < 0.5 whose provisional grade would be D/E/F/R publishes
   `X — INSUFFICIENT SEARCH (SCI 0.33)` with the fraction shown.
2. Grades A, B and C publish at **any** SCI: positive evidence does not require exhaustion, but a
   negative verdict does.
3. **R short-circuits the floor** — see ratification item R-1. An affirmatively established refutation
   is not withheld for incomplete search. *This is a declared, contested behaviour and the suite pins
   it so a change is visible.*
4. A proposition holding an unverified lead whose claimed diagnosticity could raise its band publishes
   `X — VERIFICATION PENDING` with its `verification_debt`.
5. **SCI with an empty denominator is 1.000, not 0.** See A-09.

**Band-occupancy discipline (§12.6):** the modal register entry should be X or D. If C-band occupancy
exceeds ~15% of graded propositions, the diagnosticity catalog is leaking and is re-audited. The suite
reports band occupancy as a standing metric, not a pass/fail.

### X-02 · Unrestored Nike Hercules magazine — STATUS
**Expected: X** · source: IC #17 · ✅

Current condition and status are **genuinely unknown**, not unsupported. See B-04. This is the case
that distinguishes "we looked and found nothing" (F) from "we have not looked, and the record class may
not exist" (X).

---

## PIPELINE TESTS

These are not about facilities. They test the ingestion path, and they are the four the skeptic
identified as missing entirely from v0.1 — *"the highest-value missing instrument in the entire
system, and it costs almost nothing."*

### P-01 · A format-valid but nonexistent CREST identifier
**Expected: rejected at write time as a citation; stored as a lead; V0 if it reaches an observation;
logged as a fleet confabulation event** · source: skeptic · 🔧

Example shape: `CIA-RDP80B01676R002900110001-4`. CREST identifiers are a regular grammar an LLM
reproduces perfectly and populates emptily. Under v0.1 such a string is P1 **by assertion**, lands on
DOC at weight .28, and passes the firewall because the firewall gates on tier and **the tier came from
the agent that invented the document.** Three of them plus ordinary place-derived scoring reach
76.10 → B.

**The test has three parts and all three must pass:**
1. **grammar validation** — passes, and this proves nothing. *Grammar failure is informative; grammar
   success is worthless.*
2. **resolution** against the source's authoritative interface with a stored SHA-256 receipt — fails.
3. **METADATA MATCH** — *"the one that catches the genuinely dangerous case that parts 1 and 2 miss: a
   REAL document about facility X misattributed to facility Y, which survives every existence check
   ever devised."*

**Assertions:**
- `receipt_state = UNRESOLVED-NOTFOUND` (not `UNRESOLVED-UNREACHABLE` — the distinction is the whole
  point; a blocked proxy must not inflate the published fabrication metric).
- `membership = V0` **by generated column**, not by any agent's assertion. An attempted UPDATE to
  `membership` must raise.
- The row is **RETAINED and counted**, not silently dropped. *The rate is the measurement.*
- A separate assertion for part 3: a **real, resolvable** CREST document about a different facility
  must land as `MISATTRIBUTED` and be routed to review, with `scope` demoted INSTANCE → CLASS,
  removing it from V without deleting it.

### P-02 · The rotating canary candidate
**Expected: F with zero sources; any citation returned is a measured hallucination** ·
source: skeptic · 🔧

*"Neither prior lens proposes any mechanism for measuring the fleet's error rate; both assume a
competent scorer and debate what a competent scorer should compute. But the register's stated premise
is continuous unbounded ingest by agents nobody is watching, and the confabulation rate is therefore
the single most important operating parameter and is currently unknown and unknowable."*

A plausible-sounding name — a hollow-and-county construction, a Site codeword, a service acronym — with
**zero corpus presence**, run through the full fleet.

**Assertions:**
1. Grade **F**, deterministically, via CAP-5.
2. **The canary can never be published.** Three independent blocks: the `is_canary` CHECK constraint,
   a publication-gate refusal, and exclusion from the map view. *If a canary can be published, the
   measurement is destroyed.*
3. The canary roster is **unreachable to anonymous readers**. Knowing the canaries defeats them.
4. Canaries **rotate** so they cannot be memorised.
5. The measured rate is **published on the methodology page beside the grade definitions**.

*A register that states its own fabrication rate is more credible than one that claims none — and it
converts the largest unquantified risk in the project into a monitored number.*

### P-03 · A Grokipedia article or an unbylined post-2022 AI content-farm page
**Expected: contributes zero to every condition, counts as ZERO lineages, retained and displayed** ·
source: skeptic · 🔧

The base rates make this **the normal case rather than the edge case**: roughly 35% of newly published
websites were AI-generated or AI-assisted by mid-2025 (Stanford / Imperial / Internet Archive), 74.2%
of new pages carried some AI content (Ahrefs), and primarily-AI-written articles run near half of new
articles. Grokipedia launched 27 October 2025 with roughly 885,000 machine-written entries; Cornell
Tech researchers found thousands of citations to questionable sources with sourcing guardrails largely
lifted.

Under v0.1 it is a "wiki" — P4 — and **P4 is gated ONLY on DOC**, so it feeds GEO, INF, OWN, TEST and
COR without limit and counts as a fully independent lineage, **because it shares no strings with
Wikipedia and cites nothing lineage tracing can traverse.**

**Assertions:**
1. Four such sources yield **zero lineages** — where v0.1 yields COR ~60 and CONTAM ~15, *the exact
   inverse of the truth*.
2. Test the same page under **both** the explicit versioned blocklist **and** the general mechanical
   heuristic (first observed after 2022-11-30, no named author, no byline history, no pre-2022 domain
   capture), **because the blocklist will always lag.**
3. `corpus_era` is **computed from Wayback CDX, domain registration and byline history — never
   judged.**
4. CAP-4 caps at D any claim whose entire support postdates the waterline with no verified pre-2022
   document.
5. The rows are **retained and displayed as inert with `exclusion_reason`**, not deleted.

**And the negative assertion:** **no AI-text-detection classifier is used anywhere in the pipeline.**
They do not survive paraphrase and their false-positive profile is worst on formal institutional
prose — exactly this corpus. A register that mislabels a genuine 1990s enthusiast page or an agency
memo as machine-written commits the opposite error, silently and at scale.

### P-04 · An OSM or Wikimapia node tagged `military=bunker` at a real coordinate
**Expected: a discovery LEAD contributing zero; one lineage regardless of renderer count** ·
source: skeptic · 🔧

Both the infrastructure and fringe registries catalogue OSM and Wikimapia as harvest targets and
instruct discovery to sweep Wikimapia by bounding box with the military category filter — **a
documented ingestion path into a field any anonymous person can write, for the price of a free API
key.**

**The multiplier that makes it worse than an ordinary loose secondary:** an OSM feature replicates
automatically into dozens of downstream renderers and derived datasets, so **one changeset presents to
a naive crawler as broad independent geospatial corroboration, propagated by DATABASE REPLICATION
rather than by citation** — a mechanism a citation graph cannot observe at all.

**Assertions:**
1. `channel = ADVERSARY-WRITABLE` and `causal_provenance = CROWD-EDITED` → excluded from V outright.
2. **Collapse rule 5**: replication into N renderers is **one** lineage.
3. Retained as a visible discovery pointer **with its changeset author, timestamp and comment
   recorded.**
4. **The prompt-injection variant:** an identifier planted in a Wikimapia free-text description is
   routed to `ingest.lead` and must resolve independently at the issuing authority before any row may
   cite it. *All fetched text enters as structurally bounded data, never as free prose in a scoring
   prompt.* This runs as a red-team suite against the **live** ingestion path on every deploy.

*The fringe registry already states the correct handling — "treat a Wikimapia or OSM military
annotation as a lead requiring independent documentary confirmation, never as a source" — but v0.1's
GEO axis contained no such gate, so the rubric and the registry disagreed.*

### P-05 · The self-citation ratchet, across cycles
**Expected: quarantined — retained and displayed, zero lineages, zero conditions; the grade must not
rise** · source: skeptic · 🔧

***The one entry in this suite that fails only over time, which is why it must be in CI rather than
left to observation.***

Cycle N publishes candidate X at C with a coordinate and a typology. Content farms regenerate it in
novel prose; a Grokipedia-class system synthesises it; the coordinate propagates into crowd map layers
because the register is now the best available source for it. Cycle N+1 finds four to six sources that
did not exist during cycle N; none cites the register traversably, none shares text with it, all
postdate it. Lineage reports independence; corroboration rises; **C → B**; and the register versions
the movement and renders it as a confidence history **climbing on accumulating corroboration.**

***That is citogenesis, executed by the instrument built to detect it, on a cron schedule, published as
evidence of rigour.***

**Test by simulation:** publish a synthetic entry to a staging corpus, inject paraphrased derivatives,
assert the grade does not move.

**The passing condition is the asymmetry:**
> A grade may **rise** only on evidence whose own document date precedes the register's own publication
> of that candidate. Downward movement carries no such restriction, because the failure mode is
> inflation.

**Assertions:**
1. `register_publication_log` is written **before** anything goes public — self-exclusion depends on
   it.
2. Sources first observed after publication are quarantined: retained, displayed, **zero lineages,
   zero conditions** — unless verified T1/T2 whose own document date precedes publication.
3. **The ratchet tests the TRIGGERING rows, not all of V.** Testing all of V means one unrelated recent
   blog post freezes the proposition against a genuine new archival find forever. *This polarity error
   was present in one of the two schema proposals and is the kind of bug that looks like caution.*
4. **A blocked rise is not silent**: `limiting_condition` records that upward movement was withheld.
5. `NEW-DISCLOSURE`, `MERGE` and `SPLIT` are exempt from the ratchet; the three instrument-drift causes
   are too.

### P-06 · Manzano Base vs KUMMSC — the entity-resolution trap
**Expected: merge schema-prohibited; DISTINCT-FROM seeded from this calibration entry** ·
source: skeptic · 🔧

**A live trap.** The IC analyst placed KUMMSC in their own calibration set at B **without noticing the
adjacent facility it is constantly conflated with.**

- **Manzano Base:** underground nuclear weapons storage tunnelled into the Manzano Mountains; begun
  1947, functional 1950, complete 1961, phased out around 1992.
- **KUMMSC:** a 56-acre replacement completed **1994, outside the mountain**, same base, same mission.

The facility also appears under genuine name variants — KUMMSC, KUMSC, "Munitions Maintenance and
Storage" vs "Munitions Storage" — **so a brief reading "merge name variants, alias chains, coordinate
near-duplicates" describes the correct merge and the catastrophic merge in identical language.**

**What a merged record does:** scores HIGHER than either true record; spans 1947 to present (true of
neither); holds a status that is simultaneously active and decommissioned; and pins a coordinate wrong
for both.

**Assertions:**
1. An explicit **DISTINCT-FROM** relation between these two entities, **seeded from this calibration
   entry**, so they can never silently re-merge.
2. A merge requires an **IDENTITY proposition at band C+** backed by a named, verified, instance-level
   source. Proximity and name similarity **FLAG, never merge.**
3. Merges are **versioned and reversible**, and **evidence never pools** — every row stays bound to
   the entity its source names.
4. **If a merge raises a grade, the merge is rejected** — expressed as a CHECK constraint on
   `grade_before`/`grade_after`/`raised_a_grade`, not as a guideline.
5. The **correct** merge must still work: KUMMSC ≡ KUMSC on a name-variant IDENTITY proposition.
6. Merge and split rates are telemetry; **a rising merge rate is an entity-resolution failure
   signature.**

---

## SUITE-LEVEL ASSERTIONS

Beyond individual cases, the following must hold across the whole suite.

**S-1 · The discriminating pair separation.** Fairview (B-01) and SubTropolis (R-02) must be separated
by four bands in the correct direction. Boyers (A-06) and SubTropolis must be separated on
**documentary** grounds, not on place-signals, where they are identical.

**S-2 · The E/F line.** E-01 (DIA) and F-01 (Montauk) must be separated by exactly the §2.5 rule, and
the reason recorded must be "V non-empty and non-discriminating" versus "V empty."

**S-3 · Split entities at shared coordinates.** A-08/F-01 (Camp Hero / Montauk Project) and
A-01/R-01 (Cheyenne Mountain EXIST / current-NORAD-HQ) must both publish without contradiction on one
page.

**S-4 · The two bars.** Every graded proposition carries `place_derived_weight` and
`claim_derived_weight` separately. A-02's FUNCTION claim must show **zero** place-derived weight.

**S-5 · Reconstruction.** For B-05 → A-05, `grade_as_of` must return the 1991 vector for a 1991
timestamp after the 1992 grade lands, and `grade_history` must name the observation that moved it and
label the cause `NEW-DISCLOSURE`.

**S-6 · Nothing is deleted.** Every excluded, inert, V0, quarantined and refuted row in every case
above is still present and still rendered, with `exclusion_reason`. A suite run that ends with fewer
rows than it started has failed.

**S-7 · Band occupancy.** Reported, not pass/fail: the modal band across the graded suite should be X
or D once the register is populated; C-band above ~15% triggers a diagnosticity-catalog audit.

**S-8 · Condition-level agreement.** Reliability is measured at the **condition** level ("did A2
pass?"), not at the letter level. The double-scoring sample reports per-condition agreement, with
reference-class assignment and the lineage counterfactual measured first as the two softest inputs.

---

## KNOWN-WRONG CASES, COLLECTED

For quick reference, the five cases where the adjudicated model is known to diverge from at least one
reviewer, and which must not be "fixed" without argument:

| Case | Reviewer(s) | BES | Why |
|---|---|---|---|
| R-05 Dulce Base | both: F | **R** | The historian's own text demands the AFOSI documentation be representable as evidence AGAINST — that is R. Their F was bounded by a vocabulary in which R did not exist |
| E-03 Mount Weather "underground city" | historian: D | **E** | One band, conservative. "The claim survives only as a claim" is judged truer than "signals equally consistent with the alternative," because there are no signals, only a report of testimony |
| B-05 Greenbrier 1991 EXIST | historian: C · IC: B | **B** | The two lenses contradict each other. The IC reading is taken: three verified claim-property lineages satisfy B1's second clause on the record alone |
| F-06 Comet Ping Pong | skeptic: F, *for a stated reason* | **F or R** | The two halves of the requirement conflict under BES. If a DOB/DCRA record affirmatively establishes no basement, that is R3 → R, which is the stronger answer |
| B-02/B-03/B-04 composites | both: B | **pairs** | The composite has no BES analogue. Satisfied by the decomposition; must not be reported as a letter match |

Plus one **structural** known-wrong, not tied to a facility:

| Item | Description |
|---|---|
| Ratification item **R-3** | A proposition with strong D4 support **and** one unrebutted D3 UNDERCUTS falls through A/B/C (blocked by A4/B3/C3), fails D (`null_state = EXCLUDED` is not in D2cond) and fails E (E2 requires V[D2+] empty) — landing at **F**, beneath a middle band, on strong evidence. Implemented literally. **The fix belongs in the rubric, not the schema.** A synthetic fixture reproduces it in the acceptance suite |

---

*Suite version 0.2.0 · pinned against rubric_version BES-v0.2 · 34 cases + 6 pipeline tests + 8
suite-level assertions · derived from 43 raw cases across three adversarial critiques.*
