# GRADING — THE BUNKERS EVIDENTIARY STANDARD v0.2

**Status: RATIFIED. This document supersedes WORKFLOW.md §1 in its entirety.**

This file is the authoritative, self-contained specification of the scoring model. An adjudicating
agent must be able to apply it from this file alone, without reading the rubric JSON, the critiques,
or any other document in the repository. Everything needed — every criterion, band, formula,
parameter, default and written anchor — is here.

Two things about how to read it:

1. **Every band label is a statement about the record, never about the world.** "ESTABLISHED" is
   *defined* as "conditions A1–A6 hold." The label and the mathematics are one instrument. There is
   no second instrument that could disagree with the first. This is not stylistic; it is the fix for
   the v0.1 defect in which the grade-band prose described evidence *kinds* while the formula
   measured evidence *breadth*, and the two disagreed by up to three bands on the same candidate.

2. **There is no composite and no score.** There is no number anywhere in this model. There are
   conditions, which hold or do not; counts of rows; lookups into versioned tables; and exactly two
   adjudicated judgement calls, both of which are logged. Nothing can be noise-tuned because there
   is nothing continuous to tune.

The model is implemented in SQL, not by an agent. **No LLM in the fleet assigns a grade.** See
`docs/SCHEMA.md` and `supabase/schema.sql` (`core.evaluate_proposition`). This document is what the
SQL implements, and any divergence between the two is a bug in the SQL.

---

## TABLE OF CONTENTS

- Part 0 — Adjudication: how BES was chosen
- Part 1 — The unit: propositions
- Part 2 — The evidence row
- Part 3 — Provenance: three orthogonal dimensions
- Part 4 — Diagnosticity
- Part 5 — Independence and contamination
- Part 6 — Silence, expected records, signed negatives
- Part 7 — Canonical search sets and completeness
- Part 8 — Refutation
- Part 9 — The bands, the caps, the algorithm
- Part 10 — What the register publishes
- Part 11 — Versioning, merges, movement
- Part 12 — Reliability engineering
- Part 13 — The anti-gaming ledger
- Part 14 — Worked examples with their arithmetic
- Part 15 — Defaults, complete
- Part 16 — What v0.1 got wrong and how v0.2 answers it (all sixteen fatal defects)
- Part 17 — Reviewer disagreements, recorded rather than papered over
- Part 18 — Standing limitations: what v0.2 does NOT resolve
- Part 19 — Ratification items for BES v0.2.1

---

## PART 0 — ADJUDICATION, AND WHAT THIS DOCUMENT IS

Two v0.2 candidate models were tested by arithmetic against the combined 32-entry calibration set
drawn from the three critiques on disk. **TIERED SUFFICIENCY wins; DECIBAN loses.** The deciding
computations are not the models' self-reports:

- **The hallucination canary.** DECIBAN's posterior with zero verified evidence equals its prior.
  For a candidate placed at reference class RC1/RC3/RC4 that prior is +13 dB = **grade B**. The
  result swings across four bands (B / D / F / R) purely on the reference-class assignment, which
  DECIBAN's own tradeoffs concede is its softest judgement. TIERED returns **F** deterministically
  via CAP-5. A model whose answer to the single most important pipeline test depends on an admitted
  soft judgement cannot be ratified.
- **Documentary sufficiency (historian fatal #6).** A conclusive primary record naming facility,
  location and function must reach A. DECIBAN: worst prior −25 dB + band +5 (+40 dB) = +15 dB =
  **B**. It reintroduces a weakened version of the exact defect it was built to kill. TIERED: **A**
  by A1.
- **Fairview, Kansas (IC #9, expected B).** DECIBAN +23 dB = **A**. TIERED = **B**.
- **The premise test.** The project's first sentence grades facilities "by the QUALITY OF EVIDENCE
  behind it rather than asserted as fact." DECIBAN's headline letter denotes a model posterior
  probability of existence. That is the historian's fatal #5 with the polarity reversed: evidence
  quality demoted to a subscript while a probability the register cannot calibrate becomes the badge.

DECIBAN's genuinely superior mechanisms are grafted in and named at the point of use: the
explicit-statement gate (§3.4), signed expected-record negatives (§6), the refutation gate discipline
(§8), the E/A likelihood matrix as catalog fallback (§4.4), the monotone clamp (§1.4), search
completeness as a fraction (§7.2), and REFUTER at band A (§8.5).

**Eleven requirements both models failed** are marked ▲NEW throughout: self-attestation exclusion
(§2.5), R narrowed to affirmative disconfirmation (§8), class-conditional CAP-2 (§9.3), the
candidate-set rule (§9.2 C1c), attestation custody (§5.4), subject binding (§2.3), pending-tier
(§3.2), degraded-verification mode (§2.6), the base-rate reading (§6.5), derivable null_state (§4.6),
and forgery pricing on band A (§9.2 A6).

---

## PART 1 — THE UNIT: PROPOSITIONS

### 1.1 A site is a container

An `entity` row carries identity, aliases, typed relations and geometry (subject to §10.3) and
**nothing graded**. All grades live on `proposition` rows. An entry page renders N badges, never one.

This is the structural fix for the v0.1 unit error: the unit of grading was a PLACE while the unit of
evidence is a PROPOSITION, so a well-documented real installation laundered its documentation onto
every claim ever attached to it — the register performing citogenesis on itself.

### 1.2 Closed proposition vocabulary

An agent may not invent a class. The enum is closed in the schema.

| Class | Form |
|---|---|
| `EXIST` | A substantial artificial enclosed or subsurface structure exists at subject S |
| `EXTENT` | S's depth / area / volume / capacity is within a factor of 2 of claimed value d |
| `HARDEN` | S is engineered against {blast, EMP/HEMP, CBR, radiation, forced entry} beyond ordinary construction for its class |
| `CONTROL` | S is/was owned, operated or occupied by named entity E in [t0,t1] |
| `FUNCTION` | S served function F in [t0,t1]. One row per claimed typology |
| `STATUS` | As of D, S is {active, standby, decommissioned, converted, sealed, demolished, proposed, studied, cancelled, never-built, unknown} |
| `LOCATE` | S is at coordinate C within radius R |
| `FEATURE` | S contains or exhibits specific feature X |
| `PROGRAM` | Program P was {proposed, approved, funded, constructed, cancelled} with characteristics X. **Carries no physical claim** |
| `IDENTITY` | Named entity A is the same object as named entity B |
| `ORIGIN` | Claim K first appears in artifact Z at date D, and no earlier appearance exists in the searched corpora |
| `TYPOLOGY` | S is of type T |

`FEATURE`, `IDENTITY` and `ORIGIN` are load-bearing. `ORIGIN` is why the register can publish an
A-grade fact about a fabrication, which is the stated philosophy. `EXTENT` separates "the hole is
certain" from "the hole is a mile deep."

**TYPOLOGY is a graded proposition, not a filter.** Default for every new candidate is
`unknown-anomaly`; it cannot change without a TYPOLOGY proposition clearing band C; and asserting a
new typology **instantiates the corresponding `FUNCTION` row, which is then scored**.

**The typology circularity, closed.** `typology_profile` selects the diagnosticity catalog, so the
table used to score a proposition depends on a typology that is itself graded. Therefore: scoring
runs under the profile of the **graded** typology, never a claimed-but-ungraded one
(`unknown-anomaly` until TYPOLOGY clears C); `typology_profile_version` is pinned on every grade row;
and a `TYPOLOGY-CHANGE` transition cause forces re-scoring of every proposition on the entity, with
both scorings retained.

### 1.3 Mandatory proposition fields

```
proposition_id, entity_id, class, subject, predicate_args, as_of_date,
null_hypothesis      REQUIRED, from the enumerated set (§4.5). Not nullable.
null_state           UNTESTED | SURVIVING | DOMINANT | INSUFFICIENT | EXCLUDED   (DERIVED, §4.6)
typology_profile     selects the diagnosticity catalog
reference_class      RC1..RC6 (§6.5) — publication only, never arithmetic
erp_profile_id       FK, expected-record table (applicability is PER PROPOSITION, not per class)
search_log_id        FK; SCI computed from it (§7.2)
grade                A|B|C|D|E|F|R|X                    (an EVENT, not a column — see §11)
ceiling, at_ceiling, limiting_condition, marginal_flag
silence_reading      INFORMATIVE | UNINFORMATIVE | RECORD-DESTROYED | UNSEARCHED | KNOWN-WITHHELD
base_rate_reading    COMMON | UNCOMMON | RARE | VERY-RARE   (▲NEW, §6.5)
refutation_state     R0 | R1 | R2 | R3                      (DERIVED, §8 — never trusted from an agent)
scorer_model_id, rubric_version, tier_table_version,
diagnosticity_table_version, erp_table_version, typology_profile_version, transition_cause
```

`predicate_args` is validated per class against closed vocabularies. A `STATUS` of `mothballed` is
rejected at write time, not stored and silently mis-scored.

### 1.4 The monotone clamp

A published child grade may not exceed its parent's:

```
grade_pub(child) = min(grade(child), grade(EXIST))
```

Recorded as a CLAMP event. **`PROGRAM` and `ORIGIN` are exempt** — that exemption is what makes DUCC
(PROGRAM A, EXIST R) and Dulce (ORIGIN A, FUNCTION R) representable, and it is what allows the
register to publish an A-grade fact about a fabrication.

Exactly one EXIST proposition exists per entity per as-of date, so the clamp parent is unambiguous.
When a parent's grade moves, every child is re-queued for re-grading; the drain runs to convergence,
parents before children, so a child clamp is never computed against a stale parent.

`R` and `X` are UNRANKED: they are not low grades, they are different epistemic objects. They are
neither capped nor clamped, and they do not clamp their children.

---

## PART 2 — THE EVIDENCE ROW

### 2.1 Schema of an observation

```
observation_id, proposition_id,
receipt_state     VERIFIED | UNRESOLVED-NOTFOUND | UNRESOLVED-UNREACHABLE | DEAD | NEGATIVE
receipt_class     R-FULL | R-MIRROR | R-SURROGATE | R-ATTESTED-TRANSCRIPTION
                  | R-PENDING-ACQUISITION | R-NONE
resolved_url, http_status, sha256_of_bytes, retrieved_at,
quoted_span, span_start_offset, span_end_offset, quote_check   (deterministic, non-LLM)
text_layer_provenance  native | publisher-ocr | ia-djvu | own-ocr | own-ocr-vision
subject_binding_span, subject_binding_pass                     (▲NEW, §2.3)
identifier, identifier_class, grammar_pass, issuer_metadata_match
origin_tier       T1..T5 | PENDING     FK into the single tier table
channel           ORIGIN-HOST | FAITHFUL-MIRROR | CURATED-ARCHIVE | AGGREGATOR | ADVERSARY-WRITABLE
causal_provenance UNSOLICITED | SOLICITED-3P | SOLICITED-BY-CLAIMANT | SELF-PUBLISHED | CROWD-EDITED
scope             INSTANCE | CLASS | ADJACENT
property_locus    CLAIM-PROPERTY | PLACE-PROPERTY
sign              SUPPORTS | UNDERCUTS | NEUTRAL
magnitude         0..4      (the diagnosticity ordinal; catalog lookup, or E/A matrix fallback §4.4)
signed_weight     GENERATED: magnitude x sign        (+n for SUPPORTS, −n for UNDERCUTS, 0 NEUTRAL)
fact_key          normalized string naming the underlying real-world fact
corpus_era, first_observed_date, register_echo_quarantined
self_attesting    boolean   (▲NEW, §2.5)
membership        GENERATED: V | U | INERT | V0       (§2.4 — NOT writable)
exclusion_reason  GENERATED: why this row is inert, rendered on the entry page
```

**There is no `lineage_id` column on an observation.** Independence is a graph property computed
from citation edges (§5), never a denormalised count over an agent-writable column. The absence of
that column is asserted by a test that reads `information_schema`.

`membership` is a **STORED GENERATED column**. An agent cannot write it. It compiles all seven §2.4
exclusions plus the receipt state. This is the difference between a rule and a wish.

### 2.2 RESOLVE-OR-DIE

`receipt_state = VERIFIED` requires **all** of: identifier grammar passes; the identifier resolves at
the issuing authority or a designated faithful mirror; HTTP 200; bytes hashed; a verbatim span
located at character offsets by deterministic non-LLM code; issuer metadata (title, date, issuing
body) matches what the agent claimed; and subject binding passes.

Anything else is **UNRESOLVED = tier V0: arithmetically inert on every condition, retained and
displayed.** The format-valid-but-unresolvable rate is published per agent as confabulation
telemetry.

**▲v0.2 REFINEMENT — the three-way failure split.** `UNRESOLVED` is split, because collapsing these
would let a blocked proxy inflate the register's own published fabrication metric and attribute a
network failure to its agents:

| State | Meaning | Counts as |
|---|---|---|
| `UNRESOLVED-NOTFOUND` | the issuer answered authoritatively that no such record exists | **measured fabrication** |
| `UNRESOLVED-UNREACHABLE` | timeout, 403, egress block, rate-limit exhaustion | against SCI and against the host's egress status; **not** fabrication |
| `DEAD` | previously resolved, now 404 | drift signal; fires a revalidation alert |

The verifier is deterministic code. Where a model is unavoidable it must be a **different family**
from the discoverer: an LLM verifying an LLM shares the priors that produced the error. This is a
CHECK constraint, not a policy.

### 2.3 ▲NEW — SUBJECT BINDING

A receipt proves the bytes exist and contain the span. It does **not** prove the document is about
this facility — the commonest real-world failure being a genuine record attributed to the wrong site.

Therefore: the retrieved bytes must contain, in the quoted span or in a second receipted span from
the same document, a token that resolves to the subject's registered alias set (facility name,
installation + building number, RPUID, parcel ID, MINE_ID, FCC ASR number, coordinate — including
PLSS section/township/range, which is essential because pre-1970 federal records locate by PLSS and
not by lat/long — or a codename carrying a graded `IDENTITY` proposition at C+).

This is a string match against a table: code, not judgement.

**Failure downgrades `scope` from INSTANCE to CLASS**, which removes the row from `V` (§2.4). The
downgrade happens at write time in a trigger, and the pair (INSTANCE scope, binding failed) is
unrepresentable in the schema.

Coordinate-only binding is capped and cannot alone establish INSTANCE scope, because "a coordinate
near the subject" is exactly the ADJACENT trap §2.4 exists to close.

### 2.4 The membership sets

```
V(P) = { e : receipt_state = VERIFIED
             AND sign = SUPPORTS
             AND scope = INSTANCE
             AND causal_provenance IN {UNSOLICITED, SOLICITED-3P}
             AND corpus_era != POST-2022-UNATTRIBUTED
             AND channel != ADVERSARY-WRITABLE
             AND self_attesting = FALSE
             AND register_echo_quarantined = FALSE
             AND superseded = FALSE }
U(P) = identical filters, sign = UNDERCUTS
V[Dk+]   = { e in V : magnitude >= k }
V[claim] = { e in V : property_locus = CLAIM-PROPERTY }
L(Dk)    = count of INDEPENDENT LINEAGES containing >=1 row of V[Dk+], after fact-key merge (§5.5)
```

Seven exclusions, each a one-line schema constraint, do enormous work:

- `ADJACENT` excludes Project Gasbuggy from Dulce. **Proximity is not support.**
- `CLASS` excludes the PEF program record from certifying any individual hilltop (routed instead to
  PROGRAM and to the candidate-set rule, §9.2 C1c).
- `SOLICITED-BY-CLAIMANT` excludes the regulations.gov comment and the requester's half of a FOIA
  letter. **Evidence created after, and because of, a claim is not evidence for the claim.**
- `CROWD-EDITED` makes OSM and Wikimapia leads, never evidence.
- `SELF-PUBLISHED` maps Zenodo-class DOI deposits to T4: a resolving DOI is not an editorial
  assertion.
- `ADVERSARY-WRITABLE` excludes any host where an anonymous party can write the cited field.
- `self_attesting` — §2.5.

Rows outside V and U are **INERT** if excluded by one of the seven, or **V0** if the receipt did not
verify. Both are retained, displayed, and rendered with `exclusion_reason`. Nothing is deleted.

### 2.5 ▲NEW — THE SELF-ATTESTATION EXCLUSION

> **An artifact authored by the claimant, or by a party whose only relationship to the subject is
> advancing the claim, and whose probative content is the claim itself, is not a member of V(P).
> It is evidence for ORIGIN(P) and is graded there.**

Corollary — **UNRESOLVABLE-ATTESTATION FLOOR.** A third-party report of attestation by persons who
fail the resolvability gate (§5.4) is not self-attesting — it enters V — but at **D0**.

This single rule is the E/F discriminator both submitted models got wrong. It sorts:

- Nichols 1992 (Montauk Project), Sauder (129 DUMBs), Oliver's 1894 novel (Telos) → author *is* the
  claimant, content *is* the claim → excluded → V = ∅ → CAP-5 → **F**.
- Denver International Airport → the tunnels, fuel farm and electrical load are third-party T1
  records of real facts → they enter V at D0 → **E**.
- Pollock, *The Progressive* 1976 → a journalist reporting others' attestation, not the claimant →
  enters V at D0 → Mount Weather FEATURE = E with a citogenesis flag.

### 2.6 ▲NEW — DEGRADED-VERIFICATION MODE

This model is built entirely on resolve-or-die, so egress is an operational precondition, not a
footnote.

- Per-host egress status is probed on a schedule and **published**.
- If the issuing authority is unreachable, a receipt may resolve against a **designated faithful
  mirror** and the row is flagged `MIRROR-ONLY`.
- **A proposition whose band-A item is MIRROR-ONLY is capped at B** until the issuing authority
  resolves, unless a second independent lineage at D2+ corroborates (§9.2 A6 / CAP-6).
- If no host in a canonical corpus is reachable, the corresponding search returns `UNSEARCHED`, not
  `NEGATIVE`, and the SCI falls accordingly.

### 2.7 Cache-and-revalidate

Never cache-once. Store the content hash, re-fetch on schedule, alert on drift. A source that changes
after being cited is a signal. Revalidation interval is keyed to `adversary_writable` and tier: T1
origin-host annually, T4 monthly, ADVERSARY-WRITABLE re-fetched on every citation use.

Fetched text enters the pipeline as structurally bounded **data**, never as free prose in a scoring
prompt. Identifiers extracted from untrusted text go to `ingest.lead` and must be independently
resolved at the issuing authority before any row may cite them.

### 2.8 ▲v0.2 — the receipt custody ladder

Discarding documents that cannot be auto-resolved guts the register: ~96% of NARA textual holdings
are undigitised, RG 77/374/397 is where the construction record actually lives, pre-1994
congressional material is scanned-only or paywalled, county records digitise back only to the 1990s.
**The best evidence in this domain is disproportionately unfetchable.**

The answer is a custody ladder where the cap is tied to *what was actually checked*, never to how
valuable the source is:

| `receipt_class` | What is receipted | Cap | Notes |
|---|---|---|---|
| **R-FULL** | Bytes in hand; all gates pass at the issuing authority | **D4 reachable** | The only path to band A via A1 |
| **R-MIRROR** | Resolves only at a designated faithful mirror | D4 reachable but **CAP-6 → max B** | Lifted by A6 corroboration at D2+ |
| **R-SURROGATE** | Existence and metadata verified against a machine-resolvable authoritative finding aid / catalog / index; content unavailable | **D2** | NARA NAID with series/box/folder for an undigitised record · DTIC record for an ADB accession · HathiTrust bib API on a search-only volume · a county recorder's index resolving book/page while the image is paywalled · an AFHRA IRIS reel. Subject binding runs against catalog metadata: a folder title naming the facility binds at INSTANCE, a series title at CLASS. **Can never satisfy §3.4**, because (d) requires a receipted span |
| **R-ATTESTED-TRANSCRIPTION** | Content quoted by a resolvable T1/T2/T3 secondary that itself passes all gates | **D3** | NSArchive EBB reproducing the document; a peer-reviewed article quoting the NARA folder; Black Vault hosting a release. The *transcription* takes the quoter's tier; the *content* keeps the original's. Never D4 — §3.4 and A6 both require the issuer's own artifact. Where the quoter exposes its primaries this is §5.1.3 transparent-compiler pass-through |
| **R-PENDING-ACQUISITION** | Artifact identified via a resolvable finding aid; no receipt possible today; acquisition path known and costed | **V0 — inert** | Emits an `acquisition_task` (FOIA-request / NARA-pull / digitisation-on-demand / ILL / purchase / on-site-visit / microfilm-scan / county-records-request) with cost and latency estimates |
| **R-NONE** | Nothing resolved | **V0** | Retained, displayed, telemetered |

Two properties make this a ladder rather than a loophole:

1. **The cap follows the check, not the prestige.** A NARA folder title is capped at D2 not because
   it is offline but because a folder title cannot state a proposition on its face. A paywalled
   ProQuest hearing transcript quoted by a cited monograph is D3 for exactly the same reason a free
   one would be.
2. **R-PENDING-ACQUISITION converts blindness into a work queue.** Successful later acquisition
   **promotes** the row, which §11.3's asymmetry permits because the document's own date precedes
   publication. Transition cause `NEW-VERIFICATION`, rendered distinctly from `NEW-DISCLOSURE`.

**Span-location quality gates D4.** A span located only by bounded edit-distance on scanned material
is marked `FUZZY-OCR`, capped at D3, and can never satisfy the §3.4 gate, because condition (d)
requires the span to state the proposition *on its face* and a fuzzy match is not that. Likewise a
span "located" in a text layer this project generated with a vision model (`own-ocr-vision`) cannot
support D4.

---

## PART 3 — PROVENANCE: THREE ORTHOGONAL DIMENSIONS

### 3.1 Institutional origin (`origin_tier`) — ONE versioned table

Three incompatible P-tier ladders exist in the W0 output. `origin_tier` is a **foreign key** into a
single curated table with per-source assignments for all 158 catalogued sources. An agent may
PROPOSE; assignment is a reviewed write. **The tier of a document is the tier of its AUTHOR, not its
HOST.**

| Tier | Definition | Anchors |
|---|---|---|
| **T1** | Originating record office or its official machine interface; a record created by a party with direct authority or direct physical access, for its own purposes | CREST, DTIC, NARA Catalog, GovInfo, Federal Register, FRUS, GAO, agency FOIA rooms, FRPP, DoD BSR, MILCON J-books, USAspending/FPDS, county recorder/assessor, MSHA, USGS HTMC/3DEP/EarthExplorer, FCC ULS/ASR, FAA SUA, EPA NEPA repositories, AFHRA index, Chronicling America |
| **T2** | Faithful mirror of a T1 record, or professional curation over primaries that exposes them | IA CREST/DTIC mirrors, National Security Archive EBBs, HathiTrust scans, AFU newsletter scans, AT&T Long Lines route/plant literature, Gup/WaPo 1992, Wayback CDX |
| **T3** | Independent rigorous secondary: FOIA-requester archives, peer-reviewed work, investigative journalism with named sourcing, disciplined enthusiast survey with cited sources | The Black Vault, governmentattic, Subterranea Britannica, Ed Thelen, Bishop *Project Beta*, FAS NIP, Pollock/*The Progressive* 1976 |
| **T4** | Loose secondary: aggregator synthesis, unsourced enthusiast site, unsourced press, wiki, self-published DOI, crowd-map annotation | GlobalSecurity, long-lines.net, Sauder's *conclusions*, missilebases.com, urbex sites, Wikimapia/OSM, Zenodo deposits |
| **T5** | Uncorroborated claim: forum post, video, anonymous testimony, machine-generated text, **an LLM's own interpretation of a primary artifact** | AboveTopSecret, GLP, bibliotecapleyades, Coast to Coast archive, Grokipedia, uapedia.ai, listicle farms |

**Collision rulings, ratified.** Black Vault and governmentattic are **T3 hosts delivering T1
content** — record both. GlobalSecurity is **T4**, registered as a tier trap and a hop, never a
terminus. Internet Archive is a **channel**, not a tier: an IA-mirrored CREST document is T1 content
via FAITHFUL-MIRROR; a user-uploaded PDF is T5 via ADVERSARY-WRITABLE. A faithfully scanned T5
mimeographed newsletter in a T2 archive is a **T5 document with high retrieval integrity** — record
both, which is what makes the AFU collection usable for ORIGIN grading.

**INTERPRETATION INHERITS THE TIER OF WHOEVER ASSERTED IT.** A 1953 USGS quadrangle is T1. "This
quad shows an adit at 38.744, −104.848" is an assertion; made by a fleet agent it is **T5**, a
hypothesis and not evidence, until confirmed by (a) a second read from a **different model family,
blind to the first's conclusion**, and (b) a citation to the era-correct USGS symbol standard for
that sheet's imprint year. Disagreement is logged, never broken by a third same-family vote.

This is the single highest-hallucination-rate operation in the fleet, and it is the reason it is
tiered rather than trusted.

### 3.2 ▲NEW — PENDING-TIER, for unbounded ingest

Ingest is continuous; new sources will arrive faster than review. A source not in the table enters as
`PENDING` and **is treated as T4 for all conditions** until reviewed — magnitude clamped to 2 at
write time. It can support C and D, never A or B. This removes the incentive to route around the
review queue and stops tier assignment from silently becoming an inline agent judgement.

### 3.3 Causal provenance and corpus era

`causal_provenance` is orthogonal to tier and gates membership in V (§2.4).

**It is derived from four mechanical signals, never asserted.** An agent asked to set it will simply
write UNSOLICITED.

1. **The register's own solicitation log.** Every FOIA request, records request, docket comment or
   inquiry made by this project or its agents is logged **before it is sent** — facility named, text,
   date, recipient. Any artifact matching a logged solicitation is `SOLICITED-BY-CLAIMANT`
   permanently. This matters more than it first appears: the R-PENDING-ACQUISITION queue will
   *generate* exactly this class of document, and **the register must not launder its own FOIA
   requests into support for its own candidates.**
2. **Span-level segmentation.** Causal provenance is a property of a **span, not a document**. A FOIA
   response restates the request; the restatement is machine-locatable (case number, "your request
   dated", quoted request text) and the PDF is split into a `SOLICITED-BY-CLAIMANT` segment and an
   `UNSOLICITED` agency-response segment with separate offsets. Identical treatment for
   regulations.gov and for court records (a party's pleading versus the court's order).
3. **The date rule, which resolves the whole class.** For a solicited document, **only content whose
   own creation date predates the solicitation is UNSOLICITED**. The requester chooses the *subject*;
   the agency chooses the *content*. A no-records letter naming "Site CARDINAL" contributes nothing —
   its only claim-bearing content is the requester's own name for the place — while a 1962
   engineering drawing released under that same request contributes fully at D4, because its content
   is causally independent of the request that surfaced it. **Soliciting evidence therefore remains a
   legitimate research act**: the rule is not "don't file FOIAs," it is "the artifact is evidence at
   the date of its content, and the solicitation is logged and published."
4. **Third-party solicitation.** Default `SOLICITED-3P`, admitted to V — *unless* the claim's known
   lineage terminus is a known FOIA requester in this subject area (Sauder FOIAs it, then writes the
   book), in which case it collapses to `SOLICITED-BY-CLAIMANT` and the row is capped at D2 pending
   requester identification.

`SELF-PUBLISHED` and `CROWD-EDITED` are derived from the host's write model and adversary-writable
flag, never asserted.

`corpus_era` is computed from Wayback CDX first-capture, domain registration and pre-2022 capture
history, **never judged**. **POST-2022-UNATTRIBUTED** (first observed after 2022-11-30; no named
author; no byline history; no pre-2022 domain capture) contributes zero to every condition and counts
as **zero lineages**, retained and displayed. A versioned public blocklist of machine-generated
corpora — Grokipedia, uapedia.ai, the identified listicle farms — is T5 + POST-2022-UNATTRIBUTED by
construction.

**AI-text detection classifiers are explicitly rejected.** They do not survive paraphrase and their
false-positive profile is worst on formal institutional prose, which is exactly this corpus. A
register that mislabels a genuine 1990s enthusiast page or an agency memo as machine-written commits
the opposite error to the one it is trying to avoid, silently and at scale. The reason is published
on the methodology page.

### 3.4 The explicit-statement gate — the definition of a D4 item

> (a) `origin_tier` T1 or T2;
> (b) receipt VERIFIED with subject binding;
> (c) scope INSTANCE;
> (d) the receipted verbatim span **states the proposition on its face** — for FUNCTION it names the
>     function, for HARDEN it specifies protective engineering, for CONTROL it names the custodial
>     entity;
> (e) **the issuing body has AUTHORITY OVER THE FACT** — an agency describing its own facility, a
>     court, a recorder of deeds for title, a licensing authority for a licence;
> (f) `causal_provenance` UNSOLICITED or SOLICITED-3P, with no unresolved authenticity challenge.

Condition (e) does the discriminating work. The Intercept publishing NSA documents is T3 reporting a
T1 artifact — the artifact is D4, the reporting is not. The FCC has authority over a licence and not
over hardening, so an FCC record is D4 for FUNCTION(relay) and at most D2 for HARDEN.

**A source failing exactly one of (a) or (e), while still explicitly asserting the instance-level
proposition, is D3, not D4.**

**▲v0.2 REFINEMENT — condition (e) is a table, not a judgement.** §12.1 promises that every quantity
is "a receipt, a lookup, a count, a boolean, or one of two adjudicated judgements," and (e) as
originally written is a *sixth* judgement smuggled into the most load-bearing gate in the model. It
becomes a **fifth reviewed-write curated table**:

```
authority_over_fact(issuing_body, proposition_class, has_authority, basis, version)
```

A recorder of deeds has authority over the *fact of recording*. The FCC has authority over a licence.
The Intercept has authority over nothing. That belongs in a table.

**A `STATES-ON-FACE` adjudication requires two model families to agree.** Disagreement caps the row
at D3 and is logged, never resolved by a third same-family vote.

---

## PART 4 — DIAGNOSTICITY

### 4.1 The rule

An observation contributes in proportion to its power to discriminate the proposition from the
**named** alternative. `null_hypothesis` is not nullable; `null_state = UNTESTED` caps at D (CAP-7).

### 4.2 The ordinal scale

| Level | Meaning |
|---|---|
| **D0** | The named null predicts this just as strongly. Contributes to no condition at any volume |
| **D1** | Mildly favours. Satisfies band-D conditions only |
| **D2** | Clearly favours. The null must strain to produce it |
| **D3** | Strongly favours. Typically requires an institutional record or a resolvable direct witness |
| **D4** | Satisfies the §3.4 gate. Near-dispositive on its own |

There is no summation. Two hundred D0 observations satisfy zero conditions above band D. This is the
dissolution — not the reweighting — of v0.1's "54% of the weight on the three least diagnostic axes."

### 4.3 The catalog — ratified defaults

Assignment is a **lookup into a versioned curated table**, not an agent judgement.

**UNIVERSAL D0 — permanently, for every typology:** adit or portal existence · spoil or muck pile ·
ventilation shaft · anomalous road grade into terrain · deep well · rail spur · fenced perimeter ·
large excavation volume · generator · fuel tank · guard shack · cameras · controlled access · "the
locals say there's something under there" · a hill · a windowless wall · a basement.

*These are the signals shared by limestone mines, highway tunnels, sewer works, cold-storage caverns,
data centres and large airports. Two hundred of them satisfy zero conditions above band D.*

**BURIED-RURAL / MOUNTAIN**

- **D1** — dedicated substation whose capacity exceeds visible built footprint by >3× · continuous
  thermal/lighting signature at an unoccupied-looking site · multiple redundant utility feeds ·
  helipad with no medical or airfield justification
- **D2** — restricted/prohibited airspace <3 NM radius, surface to <5000 ft AGL, **continuous** (not
  scheduled), with a **non-flying using agency** · HTMC editorial blanking (feature on edition N,
  absent on N+1, no demolition record) · heat-rejection capacity grossly disproportionate to
  occupancy · FRPP asset count materially below installation acreage (the withheld-asset gap, itself
  a citable absence) · MSHA controller identity = federal entity or records-storage/data-centre
  operator · fuel storage far exceeding generator run-time norms for the building class · NTIA GMF
  assignment at the coordinate
- **D3** — AT&T Long Lines hardened-site lineage in **corporate route/plant engineering records** ·
  AFHRA unit history (IRIS number) describing the facility · earth-covered-magazine or command-post
  CATCODE in a real-property record for the parcel · NEPA document specifying blast doors, blast
  valves, shielding or CBR filtration · PSC C1xx architect-engineer design award for a hardened
  facility type at the coordinate with no subsequent public construction award · project unit cost
  >3× the UFC 3-701-01 pricing factor for its CATCODE · a **resolvable named witness** (§5.4)
  describing the facility
- **D4** — anything meeting the §3.4 gate. Canonical instances: MIL-STD-188-125-1/-2 (HEMP) cited in
  a design or procurement document naming the site · UFC 3-340-01/-02 blast design for the named
  project · DD Form 1391 for the named installation with hardening scope · a declassified record
  naming facility + location + function · an as-built or engineering drawing · a GSA disposal record
  describing a hardened special facility · a deed or court record reciting the structure · a MILCON
  line item naming it

**URBAN / IN-BUILDING** *(the axis-inapplicability defect dissolves: no axes, a different catalog)*

- **D0** — windowless envelope · setback · bollards · rooftop generators
- **D1** — no leasable floor plate, no tenant directory, no retail frontage on a commercially zoned
  parcel · municipal benchmarking consumption above class norm
- **D2** — structural floor loading >200 psf on multiple floors in building-department filings · roof
  vent-stack array disproportionate to stated occupancy · carrier-hotel meet-me room with emergency
  power disproportionate to tenants
- **D3** — the architect's own record describing a hardening programme · corporate engineering
  literature naming the building as hardened or survivable · dedicated-feeder utility interconnection
  agreement · permit valuation unit cost far above class norm
- **D4** — the §3.4 gate

**SILO / LAUNCH-FACILITY** — EXIST/CONTROL/LOCATE are near-trivially D4 (Air Force site lists, real
property disposal records, recorded deeds). The live propositions are `STATUS` and current `CONTROL`;
the catalog weights recent deed activity, county permit filings and dated direct observation.

**RELAY/COMMS · ARCHIVE-STORAGE · CIVIL-DEFENSE-SHELTER · MINE-CONVERSION** each carry their own
catalog on the same pattern.

### 4.4 The E/A fallback for uncatalogued observations

Catalog first; matrix if and only if there is no catalog row. This repairs the blindness to novel
typologies that a hard D0 default produces — "slowest exactly where it would be most valuable."

The agent answers two anchored four-level questions and reads off the table.

**Q1 — Expectedness under H** (the proposition is true): E3 REQUIRED (would almost always exist and
be findable) · E2 LIKELY · E1 POSSIBLE · E0 SURPRISING.
**Q2 — Expectedness under H_alt** (the named null is true): A3 / A2 / A1 / A0, same anchors.

```
        A3    A2    A1    A0
  E3    D0    D0    D1    D3
  E2    D0    D0    D1    D3
  E1   -D1   -D1    D0    D2
  E0   -D3   -D3   -D2    D0
```

Anchor probabilities: **0.9 / 0.6 / 0.2 / 0.03**.

Negative cells produce an **UNDERCUTS** row at the stated magnitude. This is what makes a published
tenant lease list *count against* a hardened-facility claim rather than merely fail to count for it.

**The matrix ceiling is D3.** D4 is unreachable by inference and requires the §3.4 gate — the
firewall is arithmetic, not a bolted-on cap.

Every matrix assignment is logged as a **catalog-extension proposal**; PRIOR-KEEPER adjudicates them
into the catalog on review, so the fallback is self-retiring.

**Published worked anchors, verbatim, for scorers:**

| Observation | H | E/A | Result |
|---|---|---|---|
| Ventilation shaft | vs A02 mine | E3/A3 | D0 |
| Spoil pile | — | — | D0 |
| Anomalous road grade | — | — | D0 |
| Deep well | — | — | D0 |
| Rail spur | — | E2/A3 | D0 |
| Dedicated substation | — | E3/A2 | D0 |
| Continuous restricted airspace, non-flying using agency | — | E3/A0 | **D3** |
| Blast-valve line item in a filed permit | — | E3/A0 | **D3** |
| Published tenant lease list | H = hardened federal | E0/A3 | **−D3** |
| Operator-run public ticketed tours | H = hardened federal | E0/A3 | **−D3** |
| MSHA regulated-mine permit | H = hardened | E1/A3 | **−D1** |

### 4.5 The enumerated null set

REFUTER selects; extensible by reviewed write only.

| Code | Null hypothesis |
|---|---|
| A01 | no constructed object here |
| A02 | commercial or industrial mine, quarry, or cavern warehouse |
| A03 | highway, rail or transit tunnel |
| A04 | water, sewer or flood-control works |
| A05 | utility vault, substation enclosure or pipeline works |
| A06 | agricultural, cold or general storage |
| A07 | commercial data centre or telecom exchange (unhardened) |
| A08 | ordinary above-ground government building |
| A09 | duplicate of an already-registered entity |
| A10 | civil-defence shelter designation only |
| A11 | claim fabricated, misattributed or transposed |
| A12 | decommissioned facility of a different, already-known typology |

REFUTER must select the **strongest surviving** alternative and state why the others are weaker.
**A11 is mandatory as a co-null** on any proposition whose positive support includes a T5 lineage;
both scorings run and the one producing the **lower** grade is published.

**Null selection is a lookup**, keyed to `typology_profile` + reference class, not a free choice —
because REFUTER shares the discoverer's priors and will otherwise name the null the discoverer
expects.

### 4.6 ▲NEW — `null_state` is DERIVED, not asserted

It is a function of the evidence rows, computed in SQL:

| State | Derivation |
|---|---|
| `UNTESTED` | no null named |
| `DOMINANT` | the null is itself affirmatively documented by ≥1 verified T1/T2 row, **and** accounts for every row in V |
| `SURVIVING` | the null accounts for every row in V, but is not itself documented |
| `INSUFFICIENT` | ≥1 row in V at **D2+** that the null cannot produce |
| `EXCLUDED` | ≥1 row in V at **D3+** that the null cannot produce |

"Cannot produce" has a written test: the catalog row is marked null-excluding for that null, or the
E/A assignment placed A at level A0 or A1.

**Implementation note.** A dispositive primary document at D4 satisfying gates (d) and (e) is marked
`null_excluding` at write time, so a conclusive record cannot stall at C on condition A3 merely
because the catalog row was not flagged. This is stored on the evidence row and is auditable.

---

## PART 5 — INDEPENDENCE AND CONTAMINATION

There is no CONTAM score and no multiplier. **Independence is deduplication before counting.**

### 5.0 The category error, stated so it cannot return

**Agent independence is not source independence.** N prompts over one set of weights is one witness
speaking N times in different words. Blind fan-out is retained for **RECALL only** and contributes
exactly nothing to corroboration. That sentence goes verbatim into every discovery agent brief.

It is enforced structurally, not by policy: `ingest.lead.discovering_agent` and `ops.agent_run` are
not reachable from any grading query. The count of agents that reported a claim is a *telemetry*
quantity and is physically unable to enter the arithmetic.

### 5.1 Collapse rules — schema-enforced, not agent judgement

1. Same author, same organisation, same publication → **one** lineage.
2. **All findings from agents sharing a base model → ONE lineage, capped at 1 by construction**
   (a unique index on the model family). High inter-agent agreement on **unverified** assertions is a
   shared-prior signature and is logged as such, never as corroboration.
3. **Transparent-compiler pass-through.** A secondary that exposes its primaries such that they can
   be independently pulled is a *conduit*: the primaries are the lineages and the compiler is neither
   counted nor penalised. A critical edition citing forty Signal Agency documents is forty lineages.
4. **Opaque compiler = one terminus** at its own tier.
5. **Replication is not independence.** Crowd-map geometry propagated into downstream renderers by
   database replication is one lineage regardless of renderer count.
6. **Semantic clustering on the assertion, not the wording.** Paraphrase and machine regeneration
   collapse into the parent. MinHash/shingle overlap survives only as a fast pre-filter.
7. **The counterfactual test** — *would this source have produced this claim if the prior source had
   never existed?* No → same lineage. **Default under uncertainty: SAME lineage.** Quorum-adjudicated
   by two agents of different model families; disagreement logged. This is one of only two genuine
   judgement calls left in the model.
8. **Self-exclusion.** Any source whose first observation postdates the register's own publication of
   that candidate is quarantined — retained, displayed, zero lineages, zero conditions — unless it is
   a verified T1/T2 whose own document date precedes publication.

### 5.1.7 The counterfactual test, operationalised

Rather than free judgement, a checklist that mostly resolves mechanically; the model is consulted
only where the checklist is indeterminate.

- **Date test** — B's own artifact date precedes A's → cannot descend from A.
- **Citation test** — B cites A directly or transitively → SAME.
- **Access test (the one that does the real work)** — could B's author have reached the underlying
  *fact* without the *claim*? Parties with direct authority or direct physical access observe the
  fact, not the claim: a county recorder, a contracting officer, an agency filing its own EIS, a
  utility filing an interconnection agreement. **This is why institutional records are effectively
  the only reliable source of independence in this domain** — a recorded deed and a MILCON line item
  are independent because two separate bureaucracies each recorded the same underlying event for
  their own unrelated purposes. Secondary sources are almost never independent of one another, and
  the default reflects that.
- **Fact-key test** — §5.5.
- **Distinctive-error test** — shared idiosyncratic error (a transposed coordinate digit, a wrong
  elevation, a misspelled contractor name) → SAME, at high confidence. Regenerated text loses wording
  but **keeps facts, including wrong ones**. This is classical stemmatics, it survives paraphrase and
  machine regeneration where MinHash does not, and it is the strongest available positive evidence of
  derivation. It fires only when the parent contained an error, but when it fires it is close to
  dispositive.
- **Default: SAME.**

### 5.2 CAP-1 (single lineage)

`L(D2) ≤ 1` and band A not attained → max **C**. One source is not corroboration at any volume; one
*sufficient document* is still sufficient, which is why A is an independent path.

### 5.3 CAP-3 (citogenesis)

A T3+ publication resting on unattributable T5 testimony, subsequently cited as though primary →
`citogenesis = confirmed`, the whole loop is **one** lineage, the laundered proposition is capped at
**E**, and the flag attaches **to the proposition**, not to the site — which is exactly where the
Mount Weather "underground city" claim had nowhere to live under v0.1.

### 5.4 Testimony: the resolvability gate, and attestation custody

A named account reaches D3 only if the individual is independently locatable in a record that
(i) **predates the claim** and (ii) was **created for an unrelated purpose** — payroll, unit history,
union roll, obituary, court filing, property record. A name resolving to nothing outside the claim is
D0. Statements by resolvable named persons **denying** the proposition are scored normally as
UNDERCUTS.

**Position to know is part of the gate, not just identity.** A real, publicly identifiable, on-the-
record individual whose *credentials* are the disputed element does not satisfy it. The record must
place the person *in the role asserted*, predating the claim, created for an unrelated purpose.

▲**ATTESTATION CUSTODY.** Testimony constitutes an independent lineage only if the **attestation
itself** is receipted to a custody path the witness controlled or a third party recorded
contemporaneously — a signed or recorded interview, a byline-bearing quotation in a T1/T2/T3 outlet,
a deposition, a numbered oral-history accession. **An anonymous claim *about* what a named person
said is one lineage with the claimant, not with the person.** The lineage terminus is whoever is
asserting, never whoever is quoted.

This closes the cheapest lineage-seeding attack there is: attributing invented testimony to two real,
dead, findable people.

### 5.5 Fact-key merging

Rows sharing `fact_key` within a proposition collapse to one for L-counting; keep the strongest. This
stops one fact ("this was an AT&T Long Lines station") entering as four lineages through four record
types.

### 5.6 The collapse order, which matters

`independent_lineages()` applies four collapses **in this order**:

1. **membership filter** (§2.4) — only V rows count;
2. **fact-key merge** (§5.5) — one underlying fact is one lineage even through four record types;
3. **model-family collapse** (§5.1.2) — all findings from agents sharing a base model become ONE
   lineage;
4. **graph component collapse** — connected components over the collapsing citation subgraph,
   undirected (if B copied A they are one lineage whichever end you start from).

`L(Dk)` is the count of resulting components containing at least one V[Dk+] row. It is **never**
`COUNT(*)` and never `COUNT(DISTINCT lineage_id)` over a column an agent can write.

### 5.7 Corroboration is non-monotone

Lineage membership is a global property. Discovering that document B cites document A merges two
previously separate lineages and can **lower** a grade.

> **A grade can fall because a link was found, not because evidence was lost.**

Transition cause `RE-ANALYSIS`. It is an evidence event and renders on the public confidence chart.

### 5.8 Residual shared-prior channels, and the honest ceiling

Verification closes the corroboration channel — a document found twice is one lineage, and a document
that does not resolve is not a lineage at all. Three residual channels remain and are different
problems:

- **(a) Query-selection correlation → recall bias, not corroboration inflation.** Same weights
  produce the same queries and surface the same subset of a corpus. **Mitigation, the strongest
  available: enumerate indexes rather than searching them.** Walking `ancestorNaId` series trees,
  iterating `historicaltopo` by polygon, paging FPDS by date window, sweeping MSHA by controller —
  index enumeration is model-prior-independent by construction, and is the primary discovery mode.
- **(b) Interpretation correlation.** Two agents of the same family reading the same 1953 quad
  hallucinate the same adit. Closed by §3.1's T5 rule plus a *blind* second read from a different
  family.
- **(c) Null-hypothesis correlation.** Mitigated by making null selection a lookup, by A11 as
  mandatory co-null wherever a T5 lineage supports the claim, and by requiring REFUTER to be a
  different family from the discoverer.

**If only one model family is available, (b) and (c) are unmitigated, entailment adjudication becomes
self-verification, and double-scoring measures nothing. In that case the register publishes that it
has no independent verification and caps accordingly.** This is asserted at pipeline start, before
any grade is written.

---

## PART 6 — SILENCE, EXPECTED RECORDS, AND SIGNED NEGATIVES

### 6.1 The rule

**Absence of a record is evidence only where the presence of that record would have been expected.**
For a classified facility, absent records are the expected condition and carry near-zero negative
information.

### 6.2 Negatives are signed

A completed, **receipted** negative search produces an UNDERCUTS row at:

| X | Meaning | Row |
|---|---|---|
| **X3** | near-certain to exist AND be public if the proposition is true | UNDERCUTS at −D3 |
| **X2** | likely | −D2 |
| **X1** | possible | −D1 |
| **X0** | unlikely, or the record class is structurally absent / destroyed / never existed / withheld | **no row** |

**An unsearched record class produces NO ROW — not a zero, an absence.**

### 6.3 Expected-record table v0.2.0

Seeded from the five W0 `gaps` sections. Keyed on record class × era × controlling authority ×
classification posture.

| Profile | X |
|---|---|
| MILCON J-book line, appropriated agency, 1950–1990, unclassified | X3 |
| MILCON line marked "Classified Project"/"Classified Location" (existence of a line) | X3 |
| …same, for scope and location | X0 |
| MILCON / appropriations, **non-appropriated entity** (Federal Reserve, USPS, TVA, FDIC, Farm Credit) | **X0** |
| NIP/MIP-funded construction, any era | X0 |
| FRPP entry, executive-agency facility, post-1998 | X2 |
| FRPP entry, national-security-withheld asset class | **X0** |
| DoD Base Structure Report entry, acknowledged installation | X2 |
| FPDS/USAspending award naming the site, post-2008 | X1 *(descriptions sanitised and miscoded; place of performance is frequently the contracting office)* |
| NEPA EIS filed with EPA, major federal action | X2 |
| NEPA EA for facility-scale construction | X1 *(no central index; most defence actions categorically excluded)* |
| NEPA, classified action or categorical exclusion | X0 |
| Local building permit, federal construction on federal land | X0 |
| County deed / assessor parcel record, **any CONUS parcel, any era** | **X3 — the universal floor** |
| County deed, federal-to-federal transfer or land withdrawal | X0 |
| County deed, pre-1975 in a county digitised only to the 1990s | X0 |
| GSA disposal record, executive-agency real property | X2 |
| FCC ASR/ULS registration, commercial emitter | X3 |
| FCC ASR/ULS registration, federal or covert emitter | **X0** *(federal spectrum is NTIA/IRAC; GMF withheld — availability anti-correlates with the property being detected)* |
| NPRC personnel file, Army 1912–1960 or USAF 1947–1964 | **X0 — RECORD-DESTROYED**, NPRC fire 12 July 1973, ~16–18M files, no duplicates, no index |
| USGS HTMC quadrangle coverage, any CONUS coordinate | X3 *(186,061 sheets — so a temporal-stack absence IS informative)* |
| USGS quad depiction where cartographic suppression is plausible | X1 |
| NRHP listing, restricted or sensitive feature | X0 |
| 3DEP lidar coverage, remote federal land | X1 *(acquisitions cost-shared with states; remote federal land systematically under-flown)* |
| Chronicling America coverage, local press after 1963 | X0 *(free corpus copyright-bounded)* |
| Pre-1994 congressional material in GovInfo | X1 — flag `ARCHIVE-GAP` *(born-digital text starts ~103rd Congress)* |
| NARA textual holdings, RG 77 / 374 / 397 | X1 — flag `ARCHIVE-GAP` *(~96% undigitised)* |
| State well-driller report, well on federal land | X0 |
| EPCRA Tier II, federal facility | X0 |
| MSHA record, underground mine post-1970 / pre-1970 | X3 / X0 |
| CREST/DTIC record, facility still classified or <25 years | **X0** |
| CREST/DTIC record, facility declassified >25 years | X2 |
| DTIC **ADB-prefix** accession | **KNOWN-TO-EXIST-NOT-RELEASED** — a positive state, not an absence; auto-generates a FOIA worklist item |
| Any documentary record, active facility under commercial cover | **X0** |
| Spoil-volume signature in imagery, excavation >1e5 m³ | X3 |
| Procurement trace for construction >$50M, appropriated agency | X3 |

**ERP applicability is per proposition, not per class.** Two EXIST propositions on different
controlling authorities have different applicable profile sets.

### 6.4 The published silence reading

- **SILENCE-INFORMATIVE** (X≥1, searched, negative receipts logged)
- **SILENCE-UNINFORMATIVE** (X0), rendered verbatim: *"No public record of this class would be
  expected for a facility of this type in this period under this authority. The absence is not
  evidence against."*
- **SILENCE-RECORD-DESTROYED** (with the destroying event cited)
- **SILENCE-UNSEARCHED** → grade **X**
- ▲v0.2 **SILENCE-KNOWN-WITHHELD** — "we know the record exists, we know where, we cannot have it
  yet." Materially different from UNINFORMATIVE and from UNSEARCHED. Generated by DTIC ADB accessions
  and by any R-PENDING-ACQUISITION row.

### 6.5 ▲NEW — the base-rate reading (and why it is not a probability)

The historian's fatal #5 demanded two published numbers: quality-of-record and
probability-of-existence. BES answers with an **ordinal base-rate reading** derived from the
reference class, published beside the grade and **never entering the arithmetic** — which is
precisely what stops the canary reaching B.

**Reference classes:** RC1 interior of an acknowledged federal/military installation · RC2 federal
land outside an installation boundary · RC3 extractive or heavy-industrial site · RC4 purpose-built
critical-infrastructure structure · RC5 ordinary private land or building · RC6 non-located.

Assigned from the parcel/land-status record and the object's undisputed commercial identity,
**never** from the claim under test; **if ambiguous, take the class giving the lowest reading.**

| Proposition | RC1 | RC2 | RC3 | RC4 | RC5 | RC6 |
|---|---|---|---|---|---|---|
| EXIST | COMMON | UNCOMMON | COMMON | COMMON | UNCOMMON | RARE |
| HARDEN | UNCOMMON | RARE | VERY-RARE | UNCOMMON | VERY-RARE | VERY-RARE |
| CONTROL(federal) | COMMON | UNCOMMON | VERY-RARE | RARE | VERY-RARE | RARE |
| FUNCTION, sensitive set | RARE | VERY-RARE | VERY-RARE | VERY-RARE | VERY-RARE | VERY-RARE |
| FUNCTION, mundane set | UNCOMMON | UNCOMMON | UNCOMMON | UNCOMMON | RARE | RARE |

**Sensitive set:** COG/COOP, nuclear C2, nuclear weapons storage, SIGINT/collection, special-access
research, detention.
**Mundane set:** storage & archive, civil-defence shelter, communications relay, missile silo,
general research, data centre, private commercial shelter, military support.

VERY-RARE is published with its arithmetic: *on the order of a few hundred genuinely hardened federal
facilities in CONUS against tens of thousands of anthropogenic underground structures.*

Greenbrier-1991 therefore publishes `EXIST B · at ceiling · silence uninformative · base rate for
this class: facilities of this type routinely leave no public record` — the historian's two-quantity
requirement in a form the register can stand behind.

---

## PART 7 — CANONICAL SEARCH SETS AND COMPLETENESS

### 7.1 What "searched" means

Each query carries a **search receipt**: query string, corpus, corpus version/date, executed_at,
result count, and NEGATIVE receipts for empty returns. **Absence is not citable without a receipt for
the absence.**

`NEGATIVE` and `UNSEARCHED` are distinguished by the per-host egress status, never conflated.

| Class | Canonical corpora (all free, all machine-accessible) |
|---|---|
| `EXIST`, `LOCATE`, `EXTENT` | USGS HTMC temporal stack (point-in-polygon over `historicaltopo.csv`, `geom_wkt` in PostGIS) · 3DEP lidar where WESM shows coverage (SVF / SLRM / negative-openness) · EarthExplorer declassified imagery via M2M · county recorder + assessor · MSHA / USMIN / e-AMLIS / MRDS / state mine-map repositories · FAA SUA · GNIS |
| `CONTROL` | FRPP · DoD BSR · GSA disposal + realestatesales.gov · USAspending/FPDS + SAM · county deed chain · state business-entity registry · BLM MLRS/GLO |
| `HARDEN`, `FUNCTION`, `FEATURE` | CREST · DTIC incl. ADB detection · NTRL · NARA Catalog · GovInfo · Federal Register · FRUS · GAO + agency IG · agency FOIA reading rooms · MILCON J-books + DD 1391 · NEPA repositories (EPA EIS, service NEPA, DOE) · AFHRA index · ERDC/USACE · PSC/CATCODE/UFC string sweeps |
| `ORIGIN` | Wayback CDX (`collapse=digest`) · IA full-text `hits_inside` · AFU newsletter runs · UTZOO mirrors · Arctic Shift (Reddit) · ATS/GLP thread metadata · the mirrored aggregator corpus · Chronicling America + Open ONI |
| `PROGRAM` | FRUS (git-clonable TEI) · GovInfo/Serial Set · Congress.gov · DoD Comptroller archives · NSArchive EBBs |

### 7.2 Search Completeness Index

```
SCI = (# X>=1 profiles with a receipted search) / (# X>=1 profiles applicable to this proposition)
```

Published on every row.

**If SCI < 0.5 and the grade would be D, E, F or R, the grade is withheld and the row publishes
`X — INSUFFICIENT SEARCH (SCI 0.33)`.** Grades A, B and C publish at any SCI: positive evidence does
not require exhaustion, but a negative verdict does.

**X is not a low grade; it is the absence of one, and must render visually distinct from F.**

**▲v0.2 CORRECTION — the denominator-zero case.** If no X≥1 profile applies to the proposition, the
denominator is empty. **SCI = 1.000**, not 0 and not NULL. An empty denominator means there was
nothing to search, which is complete. Every applicable ERP profile at X0 is the *normal* condition
for a classified facility and is exactly the Mount Pony (non-appropriated entity) and Greenbrier-1991
cases; the opposite reading pins those propositions at X forever and prevents the register from ever
publishing the silence reading the model exists to state.

---

## PART 8 — REFUTATION

Checked **first**; overrides all bands.

**R is narrowed to affirmative disconfirmation.** A test that fires whenever a documented mundane
explanation accounts for everything returns R for Denver International Airport where E is correct,
returns R for the Montauk Project where F is correct, and would have refuted the Greenbrier in 1991
had the Forsythe Associates cover been slightly better documented. The corrected test:

> **A mundane explanation that merely ACCOUNTS FOR the signals removes their probative value; it does
> not disconfirm the claim. Refutation requires observations that are affirmatively IMPROBABLE under
> the proposition.**

| State | Condition |
|---|---|
| **R3 — CONTRADICTED** | ≥1 verified, instance-scope, subject-bound, unsolicited row from a party with authority over the fact (§3.4e) **directly stating the negation**, or documenting non-construction, non-funding or cancellation |
| **R2 — AFFIRMATIVELY INCONSISTENT** | ≥2 **independent-lineage** verified UNDERCUTS rows at **D2+** whose content is improbable under the proposition (E0 under H in §4.4), **plus** null_state = DOMINANT. Published leases, ticketed public tours, a public tenant directory, continuous documented commercial occupancy |
| **R1 — ORIGIN FABRICATED** | The claim's sole origin lineage is shown fabricated: an admission by a participant; a documented disinformation or forgery operation; or a **post-dating impossibility** (the claim's evidence postdates the claim's asserted date) — deterministic and machine-checkable |
| **R0** | none of the above |

### 8.4 The negative-evidence gate on R

**Expected-record UNDERCUTS rows (§6.2) can never alone license R.** R requires at least one row under
R1, R2 or R3 whose content is affirmative. Without it, however deep the negative stack, the row
publishes as **F (SILENCE-DOMINATED)**.

Without that gate the model quietly refutes real facilities whose cover story is good — its
characteristic failure mode — and returns R on the Sauder 129-DUMB corpus from two X3 negatives where
F is correct.

Expressed in the schema, this is `derived_from_search_receipt_id IS NULL` in every branch of the
refutation test.

### 8.5 Refutation is RE-DERIVED, never trusted

An agent proposing `state = 'R3'` produces nothing. The proposal is stored as `proposed_state` and
the register independently re-tests R3, R2 and R1 against the rows. This is the difference between a
schema that assumes trustworthy agent output and one that does not.

### 8.6 REFUTER's brief

REFUTER (a) names the null from §4.5 and justifies it as the strongest surviving alternative,
(b) assigns the A-level for every E/A fallback observation — half of every likelihood assignment in
the model is REFUTER's output, (c) proposes the UNDERCUTS rows, and (d) **runs on grades A and C
through R** — the inverted threshold, because scrutiny belongs where error lives and where the
register's exposure is largest, not on the obvious cases.

The blanket "defaults to refuted under uncertainty" prior is **deleted** and replaced with a
typology-conditional prior: default-refute for high-base-rate mundane categories; default-open for
categories where the base rate of concealment is known to be high (COG, SIGINT, weapons storage).
Blanket refute-by-default systematically erases the contemporary classified facilities the register
exists to hold.

**R is not F.** F means nothing verified favours the claim. R means something affirmatively resolves
against it. Any R resting entirely on R2 is re-reviewed on a schedule, and the register publishes its
R-rate and its R-reversal rate as standing telemetry.

---

## PART 9 — THE BANDS

Checked top-down; the first band whose conditions **all** hold wins; then caps; then
`limiting_condition` records the first failed condition of the band immediately above.

### 9.1 Labels — statements about the record, never about the world

| | |
|---|---|
| **A ESTABLISHED** | A dispositive record, independently resolvable, settles this proposition |
| **B CORROBORATED** | Multiple independent lines converge; no single dispositive record |
| **C SUPPORTED** | Positive discriminating evidence, thin or single-threaded, or carried by membership in a documented candidate set |
| **D INDICATED** | Signals consistent with the proposition and equally consistent with the named alternative. This is where quarries live |
| **E DOUBTFUL** | Verified support exists but fails to discriminate, or attestation is unresolvable. The claim survives only as a claim |
| **F UNSUPPORTED** | Nothing verified favours the claim. Retained, with its origin documented where traceable |
| **R REFUTED** | Affirmative disconfirmation, refuting sources cited. Retained |
| **X NOT ASSESSED** | Canonical coverage incomplete (§7.2). The correct default for every newly ingested candidate |

Every label describes an evidentiary state. **No band asserts existence.**

### 9.2 Conditions

**A — ESTABLISHED**

- **A1** — ≥1 row in `V` at **D4** (satisfying the §3.4 gate) with `property_locus = CLAIM-PROPERTY`;
  **OR** two rows at **D3** in two independent lineages, **both CLAIM-PROPERTY**.
- **A1-alt** (DIRECT OBSERVATION — `EXIST`, `EXTENT`, `LOCATE`, `FEATURE` only) — ≥2 independent
  verified direct observations by **resolvable named persons with lawful physical access** (§5.4
  custody applies), each with georeferenced imagery matched to a public control point, **plus** a T1
  record placing a structure on the parcel.
- **A2** — every identifier used to satisfy A1 passed grammar, resolved, matched issuer metadata, and
  passed subject binding.
- **A3** — `null_state = EXCLUDED`.
- **A4** — no unrebutted verified UNDERCUTS at D3+.
- **A5** — every A1 row is UNSOLICITED or SOLICITED-3P.
- **A6** ▲NEW **(forgery pricing)** — the A1 row resolved at the **issuing authority's own
  interface**; **or** it resolved at a designated faithful mirror (`MIRROR-ONLY`) **and** ≥1
  independent lineage at D2+ corroborates.

*Forging a document into a public mirror is cheap; forging one into cia.gov, govinfo.gov or a county
recorder's index with matching issuer metadata is not.*

*A single conclusive primary source reaches A regardless of base rate. This is the documentary
sufficiency principle and it is the point of the rebuild.*

**Note on A1's second clause.** BES requires *two rows at D3 in two independent lineages, BOTH
CLAIM-PROPERTY*. Checking ">=2 D3 lineages AND >=2 claim-property rows anywhere" is a relaxation:
it lets one lineage supply both claim rows while a place-property lineage makes up the count. The
implementation counts claim-property lineages specifically.

**B — CORROBORATED**

- **B1** — `L(D3) ≥ 2`; **OR** `L(D2) ≥ 3` with ≥1 lineage rooted at T1/T2.
- **B2** — `null_state ∈ {EXCLUDED, INSUFFICIENT}`.
- **B3** — no unrebutted verified UNDERCUTS at D3+.
- **B4** — `|V[claim]| ≥ 1`.

**C — SUPPORTED**

- **C1a** — ≥1 row in `V[claim]` at **D2+**; **OR**
- **C1b** — `L(D2) ≥ 2` from PLACE-PROPERTY rows the named null cannot jointly account for; **OR**
- **C1c** ▲NEW **(candidate-set rule)** — the subject is a member of an **enumerated, closed,
  published candidate set** for a `PROGRAM` graded A or B; the set's denominator M and the program's
  documented instance count N are published; **M ≤ 3N**; and ≥1 verified instance-scope
  CLAIM-PROPERTY row at D1+ ties this candidate to the set. **C is the ceiling of this path.**
  Adding a candidate recomputes M for every member as a versioned transition with cause
  `CANDIDATE-SET-CHANGE` — **adding candidates dilutes**, which is the standing countermeasure to a
  find-rewarded fleet's regional-gap-filling incentive.
- **C2** — `null_state ≠ UNTESTED`.
- **C3** — no unrebutted verified UNDERCUTS at D3+.

**D — INDICATED**

- **D1** — ≥1 row in `V[D1+]`, or ≥2 D0 rows forming a stated pattern.
- **D2cond** — `null_state ∈ {SURVIVING, DOMINANT, UNTESTED}`.

**E — DOUBTFUL**

- **E1** — `V ≠ ∅`.
- **E2** — `V[D2+] = ∅`.

(`ORIGIN` for the claim, where graded, is displayed alongside; it is not a precondition.)

**F — UNSUPPORTED** — `V = ∅`, or all higher bands and E fail. Retained with whatever origin work was
done.

**R — REFUTED** — Part 8. **X — NOT ASSESSED** — §7.2.

### 9.3 The caps

| Cap | Condition | Effect |
|---|---|---|
| **CAP-1** | `L(D2) ≤ 1` and A not attained via A1/A1-alt | max **C** |
| **CAP-2a** | `V[claim] = ∅` for `EXIST, EXTENT, LOCATE, FEATURE, TYPOLOGY` | max **D** |
| **CAP-2b** ▲NEW | `V[claim] = ∅` for `HARDEN, CONTROL, FUNCTION, PROGRAM, IDENTITY, ORIGIN` | max **E** |
| **CAP-3** | `citogenesis = confirmed` | max **E** |
| **CAP-4** | all support postdates 2022-11-30 with no verified pre-2022 document | max **D** |
| **CAP-5** | `V = ∅` | max **F** |
| **CAP-6** ▲ | A1 row is `MIRROR-ONLY` without corroboration (A6) | max **B** |
| **CAP-7** ▲ | `null_hypothesis` unnamed (`null_state = UNTESTED`) | max **D** |

**CAP-2's split by proposition class is the single hardest constraint in the anti-gaming ledger.** A
function, control or hardening claim carried entirely by attributes of the *place* has **no support
for the claim at all** and belongs at E, not D:

> **No FUNCTION claim can exceed E without a verified, instance-scope, subject-bound, CLAIM-PROPERTY
> observation.**

CAP-4 is a blunt instrument justified only by the absence of a better one; it will be revisited as
attribution infrastructure improves, and the register says so on the methodology page.

`R` and `X` are unranked and are neither capped nor clamped.

### 9.4 The algorithm — complete

```
GRADE(P):
  1. Evaluate R3, R2, R1 in order (with the §8.4 gate). If any holds -> return R.
  2. If SCI < 0.5 and the provisional grade would be D/E/F/R -> return X.
  3. Build V, U. Apply fact-key merge. Compute L(D2), L(D3), |V[claim]|, |V[Dk+]|.
  4. Derive null_state (§4.6).
  5. For band in [A, B, C, D, E, F]: if all conditions hold -> awarded = band; break
  6. grade = min(awarded, CAP-1..CAP-7)
  7. grade = min(grade, grade(parent))                      # monotone clamp, §1.4
  8. limiting_condition = first failed condition of the band above `grade`
  9. marginal_flag = TRUE if a single condition turning on one contested fact
                     (a lineage counterfactual, or one witness's resolvability) decides the band
 10. ceiling = f(ERP, caps); at_ceiling = (grade == ceiling)
 11. silence_reading = f(ERP, search_log); base_rate_reading = f(reference_class, class)
 12. Stamp scorer_model_id, rubric_version, and all four table versions.
```

Every step is deterministic given the evidence table. Exactly **two** judgement calls survive: the
lineage counterfactual (§5.1.7) and, on the fallback path only, the two E/A ordinals. Both are
quorum-adjudicated across model families and logged, with `marginal_flag` surfacing when one of them
decided the band.

**Ordering note (a declared, ratified divergence).** Step 1 returns R *before* the SCI floor in step 2
is applied, so an R grade is not withheld for incomplete search even though §9.4 step 2 nominally
withholds D/E/F/R below SCI 0.5. **This is deliberate**: a refutation that has been affirmatively
established does not become unestablished for want of further searching, and publishing X over a
documented contradiction is worse than publishing R with a low SCI. Recorded as ratification item
R-1 (Part 19).

---

## PART 10 — WHAT THE REGISTER PUBLISHES

**10.1** The entry page leads with the **proposition table** — grade, ceiling, at-ceiling, limiting
condition, marginal flag, silence reading, base-rate reading, named null and its derived state. Then
the alternative-hypothesis disposition table. Then the lineage graph. Then evidence rows with
receipts, tiers, causal provenance and diagnosticity, **including V0 and quarantined rows shown as
inert with their exclusion reason**. **The composite does not exist; the decomposition is the
product.**

**10.2 Two bars, always** — PLACE-DERIVED and CLAIM-DERIVED contributions rendered separately, so a
reader sees at a glance how much of a grade is the mountain.

**10.3 Publication gates** — Nothing below band D renders as a map pin; E, F and R live in the claims
register with their origin work, which is the product. `LOCATE` below band C renders as a region
polygon or county centroid with visible uncertainty, **never a point** — a precise pin manufactured
from imprecise evidence is the register performing its own citogenesis at the interface layer. A
machine-readable provenance beacon is emitted on every entry and API response.

**10.4 Location precision enums** — `exact` · `approximate` · `region_polygon` ·
`uncertainty_circle` · **`place_name_only`** (a claimed place name with no coordinates at all —
distinct from below) · **`non_located`** (documented, coordinates genuinely unknown). Both were
unrepresentable in earlier drafts and both occur in the calibration set.

**10.5 Verification debt** is published per proposition: the count of unverified leads and the
maximum band the proposition could reach if all of them resolved. A proposition holding an unverified
lead whose claimed diagnosticity could raise its band publishes `X — VERIFICATION PENDING` rather
than being scored.

---

## PART 11 — VERSIONING, MERGES, MOVEMENT

**11.1 Non-pooling merges.** A merge requires an `IDENTITY` proposition at band C+ backed by a named,
verified, instance-level source. Coordinate proximity and name similarity **FLAG**, never merge.
Evidence never pools: every row stays bound to the entity its source names. **If a merge raises a
grade, the merge is doing evidentiary work it has not justified and is rejected** — expressed as a
CHECK constraint, not a guideline. Merges and splits are versioned and reversible; a rising merge
rate is an entity-resolution failure signature.

**11.2 Transition-cause vocabulary** (mandatory on every re-grade):

`NEW-DISCLOSURE` · `NEW-SEARCH` · `NEW-VERIFICATION` · `RE-ANALYSIS` · `REFUTATION` ·
`STATUS-CHANGE` · `CANDIDATE-SET-CHANGE` · `TYPOLOGY-CHANGE` · `SCORER-CHANGE` ·
`TABLE-VERSION-CHANGE` · `RESCORE-NOISE` · `REGISTER-ECHO` · `MERGE` · `SPLIT` · `CLAMP`

`SCORER-CHANGE`, `TABLE-VERSION-CHANGE` and `RESCORE-NOISE` are **instrument drift** and are
suppressed from the public confidence chart by default while remaining retrievable — the chart shows
evidence events, not instrument drift, and hiding them entirely would be the same sin one level up.

`NEW-DISCLOSURE` renders visually distinct from `NEW-VERIFICATION` and from `STATUS-CHANGE`,
annotated *"the publication record changed; the world did not."*

**11.3 The asymmetry (the one-way ratchet).** A grade may **rise** only when at least one of the
observations that arrived since the last grade event is a V-member whose **own document date precedes
the register's first publication of that entity** and which is not register-echo-quarantined.
Downward movement carries no such restriction. `NEW-DISCLOSURE`, `MERGE` and `SPLIT` are exempt, as
are the three drift causes.

The failure mode is inflation, so the ratchet runs one way against it. **A blocked rise is not
silent**: `limiting_condition` records that upward movement was withheld.

**Polarity matters here.** The test is on the *triggering* rows — is there a newly verified
supporting document whose own date predates publication? — and not on all of V. Testing all of V
means one unrelated recent blog post freezes the proposition against a genuine new archival find
forever.

**11.4 Table re-derivation.** `table_version` versions the tier, diagnosticity, ERP, candidate-set,
typology-profile and rubric tables independently. Every grade event pins all of them, so no grade is
comparable across versions without re-scoring the baseline, and a bad version is identifiable and
rollback-able. Cadence: after the first 25 adjudications, then every 50 resolved A/R propositions.

---

## PART 12 — RELIABILITY ENGINEERING

**12.1** Every quantity is exactly one of: a receipt from deterministic non-LLM code; a lookup into
one of **five** versioned curated tables (tier, diagnosticity, ERP, candidate-set,
authority-over-fact); a count of rows; a boolean with a written test; or one of two adjudicated
judgement calls. There are no continuous parameters and no weights, so there is nothing to
noise-tune, and reliability is measured at the **condition** level — "did A2 pass?" is far more
reproducible than "is DOC 78 or 84?"

**12.2** Rolling **10%** blind double-scoring by a **different model family**; per-condition agreement
published. Reference-class assignment and the lineage counterfactual are measured first, being the
two softest inputs.

**12.3** Every grade row pins scorer model ID, rubric version and all table versions.

**12.4 The canary programme.** Rotating fabricated facility names with zero corpus presence are
injected into the discovery queue every cycle. Any citation returned for a canary is a directly
measured hallucination against known ground truth. Published alongside the format-valid-but-
unresolvable rate and per-agent grade distributions.

A canary entity carries `is_canary` and **can never be published** — enforced by a CHECK constraint,
by a publication-gate refusal, and by exclusion from the map view. If a canary can be published the
measurement is destroyed. The canary roster itself is unreachable to anonymous readers: knowing the
canaries would defeat them.

*A register that states its own measured fabrication rate is more credible than one that implies
none.*

**12.5 Table re-derivation** — see §11.4. Affected rows are re-scored against both the pinned old
table and the new one; only the delta attributable to the table is published, labelled
`TABLE-VERSION-CHANGE`, and excluded from the evidence narrative.

**12.6 Band-occupancy discipline.** The ladder is calibrated so the **modal register entry is X or
D**. Most candidates are undifferentiated holes; a healthy register says so. If C-band occupancy
exceeds ~15% of graded propositions, the diagnosticity catalog is leaking and is re-audited.

**12.7 CI regression suite** — the combined three-lens calibration set (`docs/CALIBRATION.md`) plus
four pipeline tests that are not about facilities at all:

1. the fabricated CREST identifier must resolve to V0 and contribute nothing;
2. the rotating canary must return F;
3. the self-citation ratchet, simulated against a staging corpus, must produce no upward movement;
4. an injection red-team suite against the live ingestion path.

**Load-bearing pairs must reproduce exactly:** Mega Cavern (shelter A / COG R) · Kirtland (Manzano
and KUMMSC never merged) · Camp Hero (station A / Montauk Project F) · Cheyenne Mountain (EXIST A /
current-NORAD-HQ STATUS R) · Greenbrier (1991 EXIST B + FUNCTION E, 1992 both A, cause
NEW-DISCLOSURE) · SubTropolis vs Fairview (HARDEN R vs HARDEN B) · DUCC (PROGRAM A / EXIST R) ·
Dulce (FUNCTION R / ORIGIN A) · DIA (EXIST A / FUNCTION E).

---

## PART 13 — THE ANTI-GAMING LEDGER

The rubric is published with an explicit warning that it is a public optimisation target, and a
red-team adversarial calibration set runs in CI beside the true-positive set.

| Attack | Cost | Blocking criterion |
|---|---|---|
| Emit a format-valid CREST/DTIC/GAO/ASR/PIID identifier | zero | A2 (resolve + issuer metadata + subject binding); CAP-5 |
| Cite a real document about a different facility | zero | **Subject binding** (§2.3) downgrades scope to CLASS, removing it from V |
| File a regulations.gov comment naming the facility | minutes | SOLICITED-BY-CLAIMANT excluded from V; author-tier T4, not host-tier T1 |
| FOIA a no-records letter restating your own facility name | weeks | The requester's half is SOLICITED-BY-CLAIMANT; the agency's half is a NEGATIVE receipt usable only where X≥1 |
| Mint a Zenodo DOI for a "technical assessment" | zero | SELF-PUBLISHED → T4; A1 requires T1/T2 |
| Tag `military=bunker` in OSM/Wikimapia | free account | CROWD-EDITED → lead only; replication is one lineage |
| Pick a real place with portals, substation, rail spur, title chain | zero | Universal-D0 list; **CAP-2b** — a FUNCTION claim cannot exceed E without a claim-property row |
| Relabel typology to COG/COOP | zero | TYPOLOGY is graded; the relabel instantiates FUNCTION(COG), which is scored and, for Mega Cavern, refuted |
| Seed two "independent" lineages by attributing testimony to two real dead findable people | hours | **Attestation custody** (§5.4): the lineage terminus is the asserter, not the quoted. Both collapse to one lineage |
| Let AI content farms regenerate the claim | zero | POST-2022-UNATTRIBUTED → zero lineages; semantic clustering collapses paraphrase; CAP-4 |
| Prompt-inject identifiers into a Wikimapia description | one POST | Fetched text is data; untrusted identifiers are leads; ADVERSARY-WRITABLE excluded; cache-and-revalidate with drift alerts |
| Name the invention to collide with a real site so RESOLVER merges it | zero | Merge requires IDENTITY at C+; evidence never pools; DISTINCT-FROM |
| Wait for the register to cite its own echo | months | Self-exclusion quarantine; upward movement requires pre-existing document dates |
| Forge a plausible PDF onto a public mirror | days | **A6**: mirror-only A1 caps at B absent independent corroboration |

**Producing an A-band fraudulently requires forging a record inside a federal repository, with
matching issuer metadata, that binds to the subject.** That asymmetry is the design.

---

## PART 14 — WORKED EXAMPLES, WITH THEIR ARITHMETIC

These seven are normative. An adjudicating agent that cannot reproduce them from this document has
misread the document.

### 14.1 Site CARDINAL, Pendleton County WV — the confabulation canary

*Not a facility. The pipeline test.* Under v0.1 this dossier scored DOC 90, GEO 80, INF 70, OWN 65,
TEST 45, COR 80, CONTAM 0 → 76.10 → **GRADE B**, "strongly evidenced, existence solid." Nothing in it
exists.

What the fleet returns: three CREST identifiers and one DTIC AD number for "Relocation Site Survey,
Blue Ridge, 1962"; "an adit symbol at 38.6xx, −79.4xx on the 1953 quadrangle"; a real FCC ASR
registration 3 km away; "a plausible appropriations line"; an account citing an alleged local
newspaper.

Verification runs before anything is scored:

- `CIA-RDP…-1/-2/-3` → grammar **PASSES** (the format is a regular grammar). Resolution attempted at
  cia.gov/readingroom AND the IA CREST mirror → 404 on all three → UNRESOLVED-NOTFOUND → **V0**,
  inert, retained.
- `AD-xxxxxx` → grammar PASSES. apps.dtic.mil and the IA DTIC mirror → 404 → **V0**.
- The quad reading → the HTMC point-in-polygon DOES return the sheet and the GeoTIFF IS fetched (that
  part is real). But "this raster shows an adit here" is an INTERPRETATION and inherits the tier of
  whoever asserted it (§3.1) → **T5**, a hypothesis, until confirmed by a second different-family
  read AND a citation to the era-correct symbol standard. Neither exists → excluded.
- FCC ASR 3 km away → resolves, real, T1 — but `scope = ADJACENT` → excluded from V. **Proximity is
  not support.** And even at INSTANCE scope, a tower is catalog-D1.
- The appropriations line → no GovInfo package ID, no resolution → **V0**.
- The alleged newspaper → no Chronicling America / Open ONI hit, no receipt → **V0**.

**COUNTS:** V = ∅ · |V[claim]| = 0 · L(D2) = 0.

- **R?** No — nothing affirmatively disconfirms, because there is nothing there. §8.4 forbids R on
  negatives alone.
- **X?** The canonical EXIST search set WAS executed with logged negative receipts, so SCI ≈ 1.0 →
  not X.
- **E?** E1 requires V ≠ ∅ → fails.
- **CAP-5 fires:** V = ∅ → max F.

→ **GRADE F.** Not rendered as a map pin. Annotated: *"All five cited identifiers are format-valid
and unresolvable. No evidence survives receipt-checking."* Five identifiers logged against the
cycle's confabulation rate, attributed per agent, published.

*The incentive inversion this repairs:* under v0.1, citing a forum post required possessing a URL
that exists, while citing a CREST document required only emitting a well-formed string — the higher
the tier and the more format-regular the identifier, the easier to hallucinate and the more weight it
carried. Under resolve-or-die the gradient runs the other way.

### 14.2 The Greenbrier / Project Greek Island — 1 Jan 1991, then 1 June 1992

*The flagship case.* In 1991, a fully staffed 1,100-bed congressional relocation facility with
essentially no documentary trace, behind a Forsythe Associates cover. v0.1 returned 22.91 → E,
"folklore with a trace."

Typology profile buried-rural. Reference class **RC5** (a resort on private land — taken because
§6.5 requires the lowest reading when ambiguous). ERP profile "active COG facility under commercial
cover" → all documentary classes X0; county deed X3; HTMC X3.

**EXIST(greenbrier-wv-wing) @1991.** null = A06 "a large resort expansion with a conventional
basement and a bomb-shelter-styled cold store."

V rows (all VERIFIED, INSTANCE, subject-bound, SUPPORTS, UNSOLICITED, CLAIM-PROPERTY):

| | Row | Tier | D | Lineage |
|---|---|---|---|---|
| e1 | Greenbrier County recorder, construction and parcel records for the 1958–61 West Virginia Wing | T1 | D2 | L1 |
| e2 | Local press 1959–62 (Chronicling America / Open ONI): anomalous concrete volumes, out-of-state contractors, sustained heavy trucking | T2 | D2 | L2 |
| e3 | Utility filing showing electrical service far exceeding the wing's above-ground floor area | T1 | D2 | L3 |
| e4 | A named construction worker, resolvable in a union roll and a local obituary created for an unrelated purpose, describing a concrete structure with a heavy steel door. **Custody:** a bylined quotation in named local press → satisfied | T2 | D3 | L4 |
| e5 | A second named worker, likewise resolvable and likewise quoted under a byline | T2 | D3 | L5 |

NEGATIVE receipts logged against CREST, DTIC, NARA, GovInfo, FRPP, GSA disposal — **every profile
returns X0** under "active facility under commercial cover" → **NO ROWS**. The silence is not
surprising and produces nothing.

**COUNTS:** L(D3) = 2 · L(D2) = 5 · |V[claim]| = 5 · |V[D4]| = 0 · U = ∅
**null_state:** e4 is D3 and A06 cannot produce a heavy steel blast door → **EXCLUDED**.

**BAND A adjudication — the deliberate hinge.** A1's second clause reads "two rows at D3 in two
independent lineages, both CLAIM-PROPERTY," which e4 and e5 satisfy on their face. But the workers
describe the SAME OBJECT (one door, one excavation); §5.5 fact-key merging collapses them on
`fact_key = 'a large hardened subsurface structure was built under the West Virginia Wing'` → one row
survives for A1 purposes. **A1 fails.** `marginal_flag = TRUE`.

**BAND B:** B1 ✓ (L(D2) = 5 ≥ 3, with L1 and L3 rooted at T1) · B2 ✓ EXCLUDED · B3 ✓ · B4 ✓ →
**EXIST = B.**

`ceiling = B` (the ERP predicts no documentary path while the facility is operational under cover) ·
`at_ceiling = TRUE` · `limiting_condition = "A1 — no dispositive primary record; the expected-record
profile predicts none"` · silence UNINFORMATIVE · base rate VERY-RARE.

**Boundary demonstration.** If only ONE worker resolves, L(D3) = 1 and L(D2) = 4 — B1's second clause
still holds on the three documentary lineages → **still B**. If the utility filing also fails,
L(D2) = 2 < 3 and L(D3) = 1 → CAP-1 → **C**, limiting_condition "B1 — fewer than three independent D2
lineages." *The band turns on named, checkable facts an auditor can re-run.*

**HARDEN(blast) @1991.** null = A06. Only e4/e5 describe the steel door; fact-key merge → L(D3) = 1.
B1 ✗. C1a ✓ (a resolvable witness's description of a blast door is CLAIM-PROPERTY at D3) → **C**,
CAP-1 confirmed, at_ceiling TRUE.

**CONTROL(federal) @1991.** Cover entity is Forsythe Associates, a TV-service contractor. Negative
receipts against FPDS-predecessor, GSA inventory, FRPP, deed chain — all X0 → no rows. V[claim] = ∅
(the power anomaly is PLACE-PROPERTY: it would be recorded identically under the null). **CAP-2b
fires → max E.** Band D conditions hold (D1 via the utility anomaly; null SURVIVING) → grade
min(D, E) = **D**. at_ceiling TRUE.

**FUNCTION(congressional relocation) @1991.** null = A10 "a private hardened shelter for hotel
guests." In 1991 the local attribution is diffuse, unattributed town talk — SELF-ATTESTING and
unresolvable → excluded from V (§2.5). What remains: the communications plant sized far beyond resort
needs (D2, but PLACE-PROPERTY). V ≠ ∅, V[claim] = ∅ → **CAP-2b → max E**; V[D2+] ≠ ∅ so E2 fails and
D applies, capped → **E**. at_ceiling TRUE, base rate VERY-RARE.

**PUBLISHED 1991 LINE:** *"EXIST B (at ceiling) · HARDEN C (at ceiling) · CONTROL D (at ceiling) ·
FUNCTION E (at ceiling) — silence uninformative: no public record of these classes would be expected
for a facility of this type under commercial cover; the absence is not evidence against. Base rate
for this class: VERY-RARE."*

**RE-GRADE 1 JUNE 1992.** Ted Gup, *Washington Post*, 31 May 1992 (T2, investigative, named sourcing)
→ then official acknowledgment, decommissioning, declassification, public tours.

FUNCTION: A1 ✓ — acknowledged agency records naming facility, location and function, satisfying all
six §3.4 conditions; A2–A6 ✓ → **A**. EXIST → **A** (now also A1-alt: publicly toured and
photographed by resolvable named people with the deed on file). HARDEN, CONTROL → **A**.

`transition_cause` on every row = **NEW-DISCLOSURE**, rendered visually distinct, annotated *"the
publication record changed; no new fact about the physical world was discovered."*

### 14.3 Fairview, Kansas vs SubTropolis, Kansas City — the discriminating pair

*v0.1 scored the commercial warehouse (60.23 = C) ABOVE the real bunker (56.25 = C). Two cases,
opposite ground truths, indistinguishable output.*

**FAIRVIEW, KS** — typology profile relay/comms (buried). Reference class RC4.

`EXIST(fairview-ks-station)`. null = A08 "a farm outbuilding with a microwave tower."

- e1 Brown County recorder — the AT&T-to-private deed reciting the underground improvements — T1.
  §3.4: (a)✓ T1 · (b)✓ · (c)✓ instance · (d)✓ recites the structure · (e)✓ the recorder has authority
  over title · (f)✓ → **D4**, CLAIM-PROPERTY, lineage L1
- e2 FCC ASR registration at the coordinate — T1, catalog **D1** (towers are everywhere), L2
- e3 AT&T Long Lines corporate route and plant engineering records identifying the site as a hardened
  L-carrier main station — T2, catalog **D3**, CLAIM-PROPERTY, L3. *Compiler transparency (§5.1.3):
  long-lines.net is T4 and exposes its primaries; if the underlying Bell System Practice resolves,
  the PRIMARY is the lineage and the compiler scores nothing; if it does not resolve, long-lines.net
  is one T4 terminus at catalog D2. Both readings are computed.*
- e4 Dated interior photography by the named current owner (resolvable in e1's deed), lawful access,
  matched to a public exterior control point — direct observation, L4
- e5 Independent dated interior photography by a second named visitor, likewise matched, likewise
  custody-receipted — L5

**Fact-key merge:** e1, e2 and e3 all assert `fact_key = 'AT&T owned and operated this site'` —
merged to the strongest for L-counting, so that one fact cannot enter three times.

**BAND A via A1-alt:** two independent verified direct observations by resolvable named persons with
lawful access, each with matched georeferenced imagery ✓ (e4, e5), plus a T1 record placing a
structure on the parcel ✓ (e1). A2–A6 ✓ → **EXIST = A.** *You can stand in it, two resolvable people
have, and the deed recites it.*

`HARDEN(blast)`. null = A07 "an ordinary telephone repeater building."

L(D3) = 2: {e3, the corporate engineering record — CLAIM-PROPERTY, D3} and {the direct observation of
blast doors and shock-isolated equipment in e4/e5 — **one** observational lineage, since §5.1.7
collapses two visitors describing the same door}.

B1 ✓ · B2 ✓ null EXCLUDED (a repeater hut has no blast door and is not buried) · B3 ✓ · B4 ✓
|V[claim]| = 3. A1 ✗ — no design-standard citation or as-built naming the site has been retrieved;
e1's deed recites the structure but does not specify protective engineering, so §3.4(d) fails for
HARDEN.

→ **HARDEN = B.** `ceiling = A`, `at_ceiling = FALSE`,
`limiting_condition = "A1 — no D4 design-standard citation or as-built. The documents that would move
this: the AT&T L-carrier hardened-station engineering specification, or a corporate filing citing
it."`

*That limiting condition is the register's real product: it tells a researcher exactly what to go
find.*

Under the opaque-compiler reading, e3 falls to D2 → L(D3) = 1 → CAP-1 → **C**, limiting_condition
"B1." The model publishes which reading it took and why.

`CONTROL(AT&T, historic)` A1 ✓ via the recorded deed chain → **A**. `FUNCTION(hardened long-haul
relay)`: FCC ULS/ASR names the licensee and the microwave path from a licensing authority with
authority over the licence → §3.4 satisfied for the RELAY function → D4 → **A** (*D4 withheld for
HARDEN: the FCC has authority over the licence, not over the hardening*). `LOCATE(±20 m)` A1 ✓ parcel
geometry → **A**. `FUNCTION(COG)`, if a claimant asserts it: V[claim] = ∅ → **CAP-2b → E**.

**SUBTROPOLIS** — typology profile archive-storage / commercial-underground. RC3.

EXIST: trivially **A** (MSHA records, recorded leases, surveyed geometry, the operator's own
material). TYPOLOGY(commercial-underground): A1 ✓ → **A**. *The register holds this as a true,
useful, boring entry.*

`HARDEN(blast/EMP)`. null = A02 "a room-and-pillar limestone mine converted to commercial
warehousing" — **and this null is DOCUMENTED AND PUBLICLY ADVERTISED BY THE OPERATOR**, which is why
it is the strongest surviving alternative.

Catalog lookups on everything the fleet offers: truck portals D0 · ventilation shafts D0 · spoil
history D0 · anomalous road grade D0 · dedicated substation D0/D1 · an actual rail spur D0 · deep
wells D0 · generator and fuel permits D0 · controlled access D0 · clean title and lease chain,
PLACE-PROPERTY, D0 for HARDEN. **Every one is on the universal-D0 list.** *These are where 54% of
v0.1's weight lived; here they satisfy zero conditions.*

|V[D2+]| = 0 · |V[claim]| = 0 · L(D3) = 0 → CAP-2b would cap at E.

UNDERCUTS rows via the §4.4 matrix: published tenant lease list — E0 under "hardened federal
facility" / A3 under A02 → **−D3**, lineage U1 (Jackson County recorder, T1). Operator marketing with
named tenants, published square footage and public site tours — E0/A3 → **−D3**, lineage U2 (T2,
independent). MSHA regulated-mine permit — E1/A3 → **−D1**.

**REFUTATION, checked first: R2** requires ≥2 independent-lineage verified UNDERCUTS at D2+ improbable
under the proposition (U1, U2 ✓) plus null_state = DOMINANT (A02 is affirmatively documented by MSHA
records, recorded leases and Missouri DNR filings, and accounts for every row in V ✓). §8.4's gate is
satisfied because U1 and U2 are **affirmative**, not expected-record negatives.

→ **HARDEN = R.** Same computation → **FUNCTION(COG) = R.** Had refutation not fired, CAP-2b caps at
E anyway; the model reaches the right answer by two independent routes.

**Result: the pair is now separated by four bands in the correct direction.**

### 14.4 Denver International Airport vs the Montauk Project — where R stops and E and F begin

**DIA — FUNCTION(hardened non-airport federal facility beneath the terminal).** null = "the
largest-footprint airport in North America, built badly, with an automated baggage system deactivated
in 2005 leaving empty tunnels."

`EXIST(large underground works at DIA)` = **A** — baggage tunnels, utility tunnels, the
inter-concourse train, all in T1 records. True, boring, published, displayed alongside.

Every observation the blind fleet returns, through the catalog:

| Observation | Result |
|---|---|
| GAO audits on cost overruns and the failed baggage system (T1) | supports the NULL |
| large-footprint underground structures and tunnels (T1/T2) | **D0**, PLACE-PROPERTY |
| enormous dedicated electrical load (T1) | **D0** for an airport of this size |
| dedicated fuel farm and pipeline (T1) | **D0** |
| deep wells (T1) | **D0** (universal list) |
| construction contracts sequenced, terminated and reissued (T1 FPDS) | supports the NULL |
| 1990s Denver press describing buried structures (T2) | **D0** |

The origin artifacts (Alex Christopher, Phil Schneider, mid-1990s) are SELF-ATTESTING under §2.5 →
excluded from V, routed to ORIGIN.

**COUNTS:** V ≠ ∅ (seven verified third-party T1/T2 rows of real facts) · V[D2+] = ∅ · |V[claim]| = 0.

**REFUTATION:** R3? No agency record states "there is no facility beneath the terminal." R2?
null_state = DOMINANT ✓ — but R2 also requires ≥2 verified UNDERCUTS rows **improbable under the
proposition**, and there are none. *The airport's documented ordinariness explains the signals; it
does not contradict a concealed facility.* → **R0.**

CAP-2b: |V[claim]| = 0, FUNCTION class → max E. Band E: E1 ✓ (V ≠ ∅) · E2 ✓ (V[D2+] = ∅) → **E**.

`ORIGIN(the DIA bunker claim, mid-1990s)` → **A** or **B** depending on how far back the earliest
artifact resolves, established by dated first appearances plus the negative receipt the ORIGIN
definition requires.

*The deeper v0.1 bug this exposes:* six of seven agents independently returned real T1 signals, and
not one discriminated {hardened federal facility} from {very large airport, built badly}. Under v0.1
that read as COR 65 and CONTAM 30 — "converging open signals." Under BES the same six returns are six
D0 rows satisfying zero conditions above D.

**THE MONTAUK PROJECT — FUNCTION(underground levels, time and mind-control experiments at Camp
Hero).**

Camp Hero itself: EXIST **A** (Army coastal artillery 1942, USAF radar 1952–81, AN/FPS-35 within
SAGE, NARA unit records, disposal records, EPA files, NY State Parks acquisition, standing
structure).

The claim: every circulating version traces to Preston B. Nichols' recovered memories in the 1992
book with Peter Moon. Semantic clustering (§5.1.6) collapses every later appearance into that origin
→ L = 1. §2.5: **Nichols is the claimant and the book's probative content is the claim itself** →
SELF-ATTESTING → excluded from V and routed to ORIGIN.

What remains in V: **nothing**. The base's real documentation is bound to EXIST(camp-hero) and
CONTROL(USAF), not to this proposition — §2.4's proposition binding plus subject binding make the
citogenesis mechanism unavailable to the register itself.

**COUNTS: V = ∅.**

REFUTATION: R1? Recovered memories are not an admission of fabrication, not a documented
disinformation operation, and there is no post-dating impossibility. R2? Requires ≥2 affirmative
UNDERCUTS at D2+; the NY State Parks and EPA site surveys returning no such levels are
**expected-record negatives**, and §8.4 forbids R on those alone. → **R0.**

Band E: E1 requires V ≠ ∅ → **fails**. CAP-5: V = ∅ → max **F**.

→ **FUNCTION(Montauk Project) = F**, with `ORIGIN(Nichols & Moon, 1992)` graded **A**.

**THE DISCRIMINATION, STATED:** DIA's V contains verified third-party records of real facts that fail
to discriminate → **E**. Montauk's V is empty because the only artifact is the claim itself → **F**.
That is the E/F line, it falls out of one written rule, and it is checkable.

Applying the same rule: Telos (Oliver's 1894 novel, self-attesting fiction) → **F** with ORIGIN A;
the Sauder/Schneider "129 DUMBs" corpus (Sauder is the claimant) → **F** with ORIGIN A/B.

### 14.5 Dulce Base, Archuleta Mesa NM — refutation with the origin retained

*Under v0.1 grade F was UNREACHABLE: the CONTAM multiplier floors at ×0.5, so even a flawless lineage
analysis returned 20.65 → E. BES has no multiplier and no floor.*

Reference class RC5. null = **A11** "claim fabricated, misattributed or transposed" — MANDATORY as
co-null because the support includes a T5 lineage; the alternative scoring against A01 is also run
and the lower grade published.

`FUNCTION(joint alien-human underground base, multi-level)`:

- Bennewitz 1979 → popular press 1983 → Lear's 1987 "independent confirmation" → LeVesque as "Jason
  Bishop III" → the 1987 "Thomas Castello" documents → "Branton" → Schneider → bibliotecapleyades →
  ~400 downstream sites. **Semantic clustering (§5.1.6):** each read the prior one; none contains a
  particular absent from its predecessor → **ONE lineage**, not four. Then §2.5: each of these is the
  claimant asserting the claim → SELF-ATTESTING → excluded from V entirely.
- "Thomas Castello" → fails the resolvability gate (§5.4): no independent record predating the claim,
  created for an unrelated purpose. **D0**, and excluded as self-attesting.
- Project Gasbuggy — the 1967 AEC underground detonation ~20 miles away with a full AEC/DOE paper
  trail. VERIFIED, T1 — but `scope = ADJACENT`. **EXCLUDED, displayed as excluded with the reason.
  PROXIMITY IS NOT SUPPORT.** *Under v0.1 this genuine P1 material pushed DOC to 45.*
- NM State Police cattle-mutilation files (Valdez) — VERIFIED, T1, but bound to a different
  proposition → excluded.
- Jicarilla/BLM land records, real terrain, road cuts, regional mining scarring — INSTANCE, VERIFIED,
  but PLACE-PROPERTY at **D0**.

**COUNTS:** V ≠ ∅ (land records at D0) · V[D2+] = ∅ · |V[claim]| = 0.

**U rows (UNDERCUTS) — and this is where the historian's fatal #1 gets its hook:**

- **u1** The AFOSI counterintelligence operation against Paul Bennewitz c.1979–82, in which Richard C.
  Doty supplied forged documents and staged material to steer him from classified Kirtland programs —
  established by Doty's on-record admissions and by Greg Bishop's *Project Beta* (T3, transparent
  compiler → §5.1.3 pulls the underlying primaries, which are the lineages). **UNDER v0.1 THIS
  EVIDENCE ADDED TO THE DOC AXIS.**
- **u2** LeVesque's later admission of fabricating Dulce material, documented by Adam Gorightly — a
  distinct admitting party, distinct fact_key, independent lineage.
- **u3** A retired USAF colonel and NM State Police officer Gabe Valdez — both resolvable named
  persons, both custody-receipted in named press — stating on the record that no such person was
  employed there.
- **u4 POST-DATING IMPOSSIBILITY**: images attributed to "Castello" and dated 1987 include a still
  from the 2000 film *The 6th Day*. An artifact cannot evidence a claim that predates it.
  Deterministic and machine-checkable.

**REFUTATION, checked first: R1 — ORIGIN FABRICATED**, on four independent grounds. §8.4's gate is
satisfied several times over: every one of these is affirmative content, not an expected-record
negative.

→ **FUNCTION = R**, on EXIST(the claimed facility), HARDEN, FUNCTION and LOCATE. Refuting sources
cited; entry retained.

**And the part v0.1 could not do.** `ORIGIN(the claim "a joint human-alien underground base exists
beneath Archuleta Mesa" first appears with Paul Bennewitz, Albuquerque, 1979–80)`:

- V rows: dated APRO Bulletin and regional newsletter appearances in the AFU collection on Internet
  Archive — **T5 content quality, T2 archive quality**, faithfully scanned and dated, recorded as both
  (§3.1), and **D4 for the ORIGIN class** (the dated earliest artifact itself, retrieved with a
  receipt). Plus Bishop's reconstruction (T3, transparent).
- Plus the **NEGATIVE RECEIPT** the ORIGIN definition requires: logged, dated searches over the
  canonical ORIGIN set — Wayback CDX, IA full-text `hits_inside`, the AFU newsletter runs, UTZOO
  mirrors, the mirrored aggregator corpus — returning no earlier appearance, with query strings,
  corpora, versions and result counts recorded.
- A1 ✓ · A2 ✓ · A3 ✓ the null "the claim predates Bennewitz and he merely repeated it" is EXCLUDED by
  the negative receipt · A4–A6 ✓ → **ORIGIN = A (ESTABLISHED).**

CITOGENESIS flag fires on the downstream lineage; the entry RETAINS the full origin chain with dates.

Contrast published alongside: `EXIST(some constructed works on Archuleta Mesa — roads, gas-field
wells)` grades honestly at C or better. *"There are real works on this mesa" and "the base claim is
refuted" sit side by side*, which is what a reader arriving from the fringe corpus needs to see.

### 14.6 DUCC, the Federal Relocation Arc, and Louisville Mega Cavern

**DUCC, Washington DC — PROGRAM A / EXIST R.**

Proposed 31 Jan 1962; Austere (~50-person) and Moderate (~300-person) variants at 3,000–4,000 ft
beneath the Washington area, specified against multiple 200–300 MT direct hits; endorsed by McNamara
and Rusk; reached the President; killed when Congress declined FY1965 funds. *v0.1 returned 37.24 →
E, six points above Dulce Base.*

The entity-level split does the work: this is a PROGRAM with no SITE, and §1.4 exempts PROGRAM from
the monotone clamp — the single schema decision that makes the entry representable.

`PROGRAM(DUCC, proposed and cancelled 1962–64)`. null = "a paper study never seriously considered."

- e1 JCS and OSD memoranda in FRUS 1964–68 vol. X — T1, **D4 for PROGRAM** (the decision record), L1.
  *Resolution is unusually strong: FRUS ships as structured TEI XML in the HistoryAtState/frus
  repository, git-clonable, so identifier resolution, subject binding and quote-grounding are fully
  deterministic and offline-verifiable — and A6 is satisfied at the issuing authority.*
- e2 The FY1965 appropriations record showing the rejection — T1, D4, L2 (GovInfo/Serial Set)
- e3 Declassified feasibility studies — T1, D3, L3 (DTIC/NARA)
- e4 The Hitch memorandum — T1, D3, collapses into L1 (same issuing body, §5.1.1)
- e5 LBJ Library holdings — T1, D3, L4

|V[D4]| = 2 · L(D3) = 4 · |V[claim]| = 5. A1 ✓ A2 ✓ A3 ✓ (a memorandum reaching the President and
drawing a recorded appropriations refusal is not an unconsidered study) A4–A6 ✓ → **PROGRAM = A.**

`EXIST(a physical DUCC structure beneath Washington)`. ERP: for an excavation of this scale under an
appropriated DoD programme, MILCON lines (X3), procurement traces >$50M (X3), spoil-volume signature
>1e5 m³ (X3) and NEPA-era documentation would ALL be expected. Canonical set executed; all negative
with receipts → three UNDERCUTS rows at −D3. **silence_reading = INFORMATIVE.** *This is the one case
where the argument from silence is valid, and the ERP table is precisely what licenses it — the same
table that forbids the inference for Greenbrier-1991 permits it here.*

But §8.4 forbids R on expected-record negatives alone. **R3 supplies the affirmative content**: the
appropriations record documents non-funding and the programme record documents cancellation, from
parties with authority over the fact, unsolicited, verified, subject-bound. → **EXIST = R.**

`STATUS(never-built)` = **A** on the same documentary record. `LOCATE` = **non-located** (siting
proposed, never surveyed).

*The same treatment covers SAC's Deep Underground Support Center and NORAD's Survivable Command
Centers.*

**FEDERAL RELOCATION ARC — the candidate-set rule.**

Declassified 1960s Office of Emergency Planning records establish that a set of relocation facilities
existed and describe their programme function, without individually identifying or locating each one.

`PROGRAM(Federal Relocation Arc)` = **A** on the declassified record.

For an individual candidate hilltop: the OEP record is `scope = CLASS` and is excluded from V for the
instance (§2.4) — this closes the defect in which class evidence was credited at full strength to
every instance.

**C1c fires** if and only if: the candidate set is enumerated, closed and published; N (documented
instances) and M (live candidates) are published; **M ≤ 3N**; and ≥1 verified instance-scope
CLAIM-PROPERTY row at D1+ ties this candidate to the set — for example a WHCA/Army Signal Agency
microwave path record terminating at this coordinate, or an AT&T cable route into the parcel.

→ **EXIST = C**, ceiling C (the path's ceiling by rule),
`limiting_condition = "A1/B1 — no instance-level dispositive record; grade rests on membership in a
documented candidate set of M=12 against N=8."` LOCATE = **non-located** or regional, rendered as a
polygon, never a pin.

Adding a thirteenth candidate recomputes M for all twelve as a versioned `CANDIDATE-SET-CHANGE`; if M
exceeds 3N the whole set drops to D. **Adding candidates dilutes.**

**LOUISVILLE MEGA CAVERN — the free-relabel attack, with every input true.**

*Under v0.1 this scored 63.64 = C on honest inputs, 73.81 = B with free .gov laundering, and then the
unscored Typology field could be changed from "civil defense shelter" to "COG/COOP" at zero cost.*

EXIST **A** (MSHA and Kentucky mine permits, recorded deeds, published surveys, public access).
TYPOLOGY(commercial-underground) **A**.

`FUNCTION(designated civil-defense fallout shelter, 1960s–70s)`: Office of Civil Defense Community
Fallout Shelter Program survey record naming this space as a licensed shelter with a stated capacity
— T1, INSTANCE, subject-bound; §3.4: (a)✓ (b)✓ (c)✓ (d)✓ names the function on its face (e)✓ OCD has
authority over shelter designation (f)✓ → **D4** → A1 ✓ A2–A6 ✓ → **A (ESTABLISHED).** *A real,
primary, on-topic credential, granted in full and without grudging.*

`FUNCTION(COG/COOP)` — the relabel target. null = A02 "a commercial limestone mine, now a storage
facility and tourist attraction with underground zip lines and a Christmas light drive-through,
carrying a genuine historical civil-defence shelter designation."

Available observations: portals D0 · spoil D0 · road grade D0 · largest man-made cave system in North
America D0 and PLACE-PROPERTY · dedicated power D0/D1 · ventilation shafts D0 · generators D0 · clean
title chain PLACE-PROPERTY D0.

**The OCD shelter record**: does a public community fallout shelter evidence a continuity-of-
government function? E2 under H; A3 under A02, which INCLUDES the shelter designation → §4.4 matrix →
**D0**. *The genuine, primary, on-topic civil-defence document contributes EXACTLY NOTHING to the COG
claim, because the named alternative explains it completely. This is the move v0.1 could not make and
it is made by table lookup, not by special-casing.*

|V[claim]| = 0 → CAP-2b → max E.

UNDERCUTS: u1 the operator publicly markets and ticket-sells underground zip lines, a mountain-bike
park and a Christmas light drive-through — E0/A3 → **−D3**, T2, U1. u2 continuous public commercial
occupancy since 1989 documented in the county record and the operator's own filings — E0/A3 →
**−D3**, T1, U2. Both affirmative, both independent.

R2: ≥2 independent D2+ UNDERCUTS improbable under the proposition ✓; null_state = DOMINANT ✓; §8.4
gate ✓ → **FUNCTION(COG/COOP) = R.**

*The .gov laundering channels, priced:* a regulations.gov comment → SOLICITED-BY-CLAIMANT, author-tier
T4, contribution 0. A FOIA no-records letter naming the facility → the requester's half
SOLICITED-BY-CLAIMANT; the agency's half a NEGATIVE receipt, and ERP makes it uninformative either
way, contribution 0. A Zenodo "technical assessment" with a minted DOI → SELF-PUBLISHED → T4;
A1 requires T1/T2, contribution 0. An OSM `military=bunker` tag replicating into dozens of renderers
→ CROWD-EDITED → lead only, one lineage regardless of renderer count, contribution 0.

**PUBLISHED:** *"Louisville Mega Cavern — EXIST A · TYPOLOGY commercial-underground A ·
FUNCTION(designated fallout shelter, 1960s) **A** · FUNCTION(COG/COOP) **R** · STATUS operating
commercial attraction A."* Three propositions, three ledgers, no contradiction, all visible at once.

**THE ATTACK IS DEAD**: changing the typology label does not move a number, because there is no
typology label and no composite. There is only a proposition, and opening a new one starts it with an
empty ledger, a mandatory named alternative that already explains every observation on the page, and
CAP-2b holding the ceiling at E before refutation even runs.

### 14.7 Raven Rock, Mount Pony and 33 Thomas Street — the positive controls that must not break

*A restructuring that breaks the easy positive controls has failed.*

**RAVEN ROCK MOUNTAIN COMPLEX (Site R), Adams County PA.** Typology buried-rural. RC1. Base-rate
reading for FUNCTION-sensitive at RC1 = RARE — published, contributing nothing to the arithmetic,
which is the entire point of §6.5.

Canonical EXIST set executed and logged: HTMC temporal stack (portal visible from the 1950s sheets
forward), 3DEP lidar (portal notch and apron, negative-openness), EarthExplorer declass imagery
(construction-phase spoil growth), Adams County recorder, FAA SUA, GNIS. **SCI = 6/6.**

- e1 MILCON J-book line item naming the complex with project number and CATCODE — T1, **D4**,
  CLAIM-PROPERTY, L1. §3.4: (a)✓ (b)✓ subject binding on the installation name (c)✓ (d)✓ names the
  facility (e)✓ the Comptroller has authority over the appropriation (f)✓.
- e2 NEPA/EIS filings describing the hardened structure — T1, D3, L2
- e3 GAO and DoD-IG reports on the facility — T1, D3, L3
- e4 AFHRA unit histories retrieved by IRIS number — T1, D3, L4
- e5 DoD public acknowledgment and Base Structure Report entry — T1, D4, collapses into L1 (§5.1.1)
- e6 County deed / USACE construction records — T1, D3, L5

|V[D4]| = 2 · L(D3) = 5 · L(D2) = 5 · |V[claim]| = 6 · U = ∅. R0. A1 ✓ A2 ✓ A3 ✓ (a quarry has no
CATCODE and no EIS blast scope) A4–A6 ✓ → **EXIST = A**, at_ceiling TRUE, no limiting condition.

HARDEN A · CONTROL(DoD) A · FUNCTION(alternate joint communications centre / COG) A · STATUS(active
@2026) A · LOCATE(±50 m) A · TYPOLOGY A.

**Note where the grade comes from:** the CLAIM-DERIVED bar carries all of it; the PLACE-DERIVED bar
(portals, terrain, spoil) contributes exactly zero to the function claim, and the entry page renders
that split.

**MOUNT PONY, CULPEPER VA — the non-appropriated blind spot.**

A 140,000 sq ft radiation-hardened facility dedicated 10 December 1969 — foot-thick steel-reinforced
concrete, lead-lined shutters, semi-recessed under two to four feet of earth — holding billions in
shrink-wrapped currency for post-attack monetary reconstitution, hosting the central node for
American electronic funds transfer, serving as a COG facility until July 1992. *Under v0.1 it lost
roughly 40 points across DOC and OWN because the Federal Reserve System is self-funded and outside
the executive real-property and procurement systems.*

**A blind spot in a grading system is a safe harbour for fabrication**, so this case matters beyond
itself.

ERP lookup on `controlling_authority = Federal Reserve Bank of Richmond` → non-appropriated:
MILCON / DD 1391 → **X0** · FPDS/USAspending → **X0** · FRPP → **X0** · GSA disposal → **X0** (the
1997 disposition was a private sale to the Packard Foundation on behalf of the Library of Congress).

Those searches are **STILL EXECUTED** and their NEGATIVE receipts logged and annotated *"record class
does not exist for this controlling authority."* **They produce no rows and do not touch the grade.**
*Under v0.1 those four absences were scored as weak evidence about the facility.*

The classes that DO exist, and are EXPECTED: Federal Reserve Board annual reports and minutes, FRB
Richmond publications, Fed OIG, GAO audits of the Fed, Culpeper County deeds and assessor records,
the Library of Congress acquisition record, the Packard Foundation grant record.

FUNCTION(COG/COOP): Board and FRB Richmond publications describing the facility's continuity and
currency-reconstitution role — T1, INSTANCE, subject-bound; §3.4(e) the Board has direct authority
over its own facility's function → **D4** → **A.** HARDEN **A** · CONTROL(FRB Richmond, 1969–92)
**A** · STATUS(converted @2026) **A**. SCI = 6/6, four profiles returning X0.

**COVERAGE NOTE published on the entry, not implied:** *"This facility is invisible to appropriations,
FPDS and FRPP because its operator is self-funded and outside the executive real-property and
procurement systems. Those searches were executed and returned nothing; the absence is a property of
the funding authority, not of the facility."*

*A documented blind spot is a caveat; a silent one is a false negative and a safe harbour a fabricator
will find.*

**33 THOMAS STREET, MANHATTAN — the urban / in-building test.**

*This is the case that proved v0.1's GEO axis encoded a buried-rural-mountain prior: 33 Thomas could
not clear B because adits, spoil and terrain are inapplicable to a Manhattan tower.* **In BES there
are no axes to be inapplicable.** `typology_profile = urban/in-building` selects a different catalog;
an inapplicable signal class simply generates no observation; and the ERP profile for "USGS quad adit
symbol at RC4" is X0, so the negative search produces **no row** rather than a zero score.

RC4. EXIST: trivially **A**.

`HARDEN(blast, self-sufficiency)`. null = A07 "an ordinary windowless telephone exchange building,
robust but not hardened."

- e1 NYC Department of Buildings filings: structural floor loading far above office norm on multiple
  floors, plus the design documentation for the survivability programme — T1, **D4**, CLAIM-PROPERTY,
  L1
- e2 AT&T's own published engineering and route literature describing the building as designed for
  self-sufficiency and survivability — T2 corporate primary, urban-catalog **D3**, L2
- e3 John Carl Warnecke's architectural record describing the hardening programme — T2, **D3**, L3
- e4 Municipal energy-benchmarking disclosure showing consumption far above class — T1, **D2**, L4
- e5 Roof vent-stack array disproportionate to stated occupancy — **D2**, L5
- e6 No leasable floor plate, no tenant directory — **D1**

|V[D4]| = 1 · L(D3) = 3 · L(D2) = 5. A1 ✓ A2 ✓ A3–A6 ✓ → **HARDEN = A.**

*If the DOB filing does not itself state hardening intent, §3.4(d) fails on e1, A1 fails, and the
entry falls to **B** on L(D3) = 3, with limiting_condition naming the document that decided it. The
model publishes which document decided it.*

`FUNCTION(international gateway switch)`: AT&T and FCC records → **A.**

**Now the decomposition that matters.** The Snowden material published by The Intercept in November
2016 is often summarised as "proof 33 Thomas is an NSA site." It is two propositions:

- `FUNCTION(TITANPOINTE, SIGINT access point)`: the published documents are **agency-originated, T1**,
  retrieved with receipts; The Intercept is the retrieval CHANNEL, not the origin tier (§3.1). A T1
  document naming the site by cover name and stating its function → D4 → **A.**
- `IDENTITY(TITANPOINTE ≡ 33 Thomas Street)`: this is the journalists' correlation, resting on address
  details internal to the documents, travel and visit records, and the building's known role.
  L(D3) = 2. B1–B4 ✓; A1 ✗ — no record from either party asserts the equivalence → **IDENTITY = B**,
  `limiting_condition = "A1 — no record from either party asserts the equivalence."`

And because IDENTITY is at B, not below C, §11.1 permits the alias to be used for subject binding on
the SIGINT proposition — **the merge is evidenced rather than assumed.**

*This is the honest joint v0.1 could not articulate: an A-grade fact about a codename, an A-grade fact
about a building, and a B-grade link between them, on one page, without contradiction.*

---

## PART 15 — DEFAULTS, COMPLETE

```
default typology                  unknown-anomaly (no FUNCTION row)
default grade, new candidate      X
default null                      A01 for EXIST/LOCATE/EXTENT; A11 for all other classes
default lineage decision          SAME lineage
default reference class           the one giving the lowest base-rate reading
default diagnosticity             catalog lookup; E/A matrix fallback; D0 if neither resolves
default tier, uncatalogued source PENDING (scored as T4, magnitude clamped to 2)
default receipt_class             R-NONE
default causal_provenance         derived, never asserted (§3.3); SOLICITED-3P for third-party FOIA
E/A anchor probabilities          0.9 / 0.6 / 0.2 / 0.03
E/A matrix ceiling                D3 (D4 requires the §3.4 gate)
X-level -> row                    X3:-D3  X2:-D2  X1:-D1  X0: no row
SCI grade-withholding floor       0.5
SCI with an empty denominator     1.000  (nothing to search is complete)
waterline date                    2022-11-30
candidate-set dilution limit      M <= 3N
fact-key merge                    keep strongest within proposition
double-scoring sample             10%, different model family
REFUTER multi-vote                grades A and C through R (inverted threshold)
D4 STATES-ON-FACE adjudication    two model families must agree; disagreement caps at D3
table re-derivation cadence       after 25 adjudications, then every 50 resolved A/R
C-band audit trigger              >15% of graded propositions
target modal bands                X and D
lease duration, work items        30 minutes
```

---

## PART 16 — WHAT v0.1 GOT WRONG AND HOW v0.2 ANSWERS IT

Sixteen defects were rated **fatal** across the three critiques: six from the archival historian, four
from the intelligence analyst, six from the adversarial skeptic. Each is stated here as the reviewer
stated it, followed by the v0.2 resolution and an explicit note where the resolution is partial.

### HISTORIAN H1 — Evidence has no sign

**The defect.** Every axis counts evidence *presence*; nothing in the formula can encode evidence that
a claim is FALSE. Disconfirmation can only be expressed by declining to award points, which is
indistinguishable from having looked and found nothing. REFUTER exists in the fleet but has no numeric
hook, so "refuted" becomes a flag sitting beside a passing grade. The Dulce AFOSI documentation — a
documented disinformation operation — *added to the DOC axis*.

**RESOLVED, with three distinct hooks.** Every row carries `sign ∈ {SUPPORTS, UNDERCUTS, NEUTRAL}`
against a named proposition, and `signed_weight` is a generated column so the sign is arithmetic, not
commentary.

1. An unrebutted verified UNDERCUTS row at D3+ fails A4/B3/C3 and blocks the top three bands.
2. The §4.4 matrix produces negative cells (−D1/−D2/−D3) directly, so a published tenant lease list
   counts *against* a hardened-facility claim.
3. Band **R** exists, is checked first, and overrides everything.

`sign = UNDERCUTS` is a first-class state distinct from NEUTRAL and from no row at all — the schema
test drives EXIST from A to F on the insertion of a single UNDERCUTS row.

### HISTORIAN H2 — The unit of grading is a PLACE; the unit of evidence is a PROPOSITION

**The defect.** Because the axes accrue to the site, a well-documented real installation launders its
documentation onto every claim ever attached to it. *This is precisely the citogenesis mechanism the
register exists to fight, executed by the register itself.*

**RESOLVED.** Grading attaches only to `proposition` rows from a closed twelve-class vocabulary; an
entity carries identity and geometry and nothing graded. Four mechanisms close the laundering routes:
rows are keyed to `proposition_id` and to nothing else; `scope = ADJACENT` excludes Project Gasbuggy
from Dulce; `scope = CLASS` excludes the PEF programme record from certifying any hilltop; and subject
binding (§2.3) blocks the commonest real failure.

The monotone clamp (§1.4) stops a child grade exceeding EXIST, with PROGRAM and ORIGIN exempted.

Tested natively: one entity with `EXIST = A` and `FUNCTION = E` simultaneously — *"the hole is
certain, the function is not"* — with `CAP-2b` in `applied_caps` proving the FUNCTION claim could not
borrow the EXIST documentation.

### HISTORIAN H3 — Confidence in EVIDENCE published under labels that assert EXISTENCE; no expected-record prior

**The defect.** The argument from silence is valid only where the silence is surprising. For a
classified facility, absent records are the expected condition. v0.1 treated a documentary void
identically whether the record class never existed, was destroyed, or was searched and found empty —
and then printed "folklore with a trace" over a fully operational COG facility.

**RESOLVED.** Four separately published fields: `grade` (the evidentiary standard attained), `ceiling`
+ `at_ceiling` (whether that standard is the epistemic limit for this class of object),
`silence_reading`, and `base_rate_reading` (§6.5). The ERP table (§6.3) is a versioned lookup keyed on
record class × era × controlling authority × classification posture, seeded from the five W0 `gaps`
sections.

Greenbrier-1991 publishes *"EXIST B — AT CEILING — silence uninformative: no public record of this
class would be expected under commercial cover; the absence is not evidence against — base rate
VERY-RARE."* DUCC publishes silence **INFORMATIVE**, because for an appropriated programme of that
scale the records would be expected. **The same table that forbids the inference in one case licenses
it in the other.**

**PARTIAL — a declared divergence from the reviewer's stated form.** The historian asked for
P(EXISTS) as a published *number*. BES declines and substitutes an ordinal base-rate reading. Reason:
a published posterior makes the headline letter a model probability, which contradicts the project's
premise sentence and implies a calibration the register cannot demonstrate. This is a divergence from
the *form* requested, not from the *requirement*. See Part 17.

### HISTORIAN H4 — GEO's .22 weight encodes a buried-rural-mountain prior

**The defect.** Every GEO criterion is null for urban, in-building or above-ground hardened
facilities. Those sites cannot reach A by construction, regardless of documentation. 33 Thomas Street
returns B and would need a GEO score v0.1's own criteria cannot generate for a tower.

**RESOLVED STRUCTURALLY.** There are no axes to be inapplicable. `typology_profile` selects a
diagnosticity catalog; urban/in-building has its own D1–D4 anchors. An inapplicable signal class
generates no observation; a searched-and-absent class at X0 produces **no row**, not a zero. 33 Thomas
reaches HARDEN A on documentation alone. **Nothing is renormalised out, because nothing was ever
weighted in.**

### HISTORIAN H5 — No diagnosticity term

**The defect.** The axes reward the PRESENCE of signals, not their power to discriminate the hardened-
facility hypothesis from the mundane one. A commercial limestone warehouse scores C as a hardened-
facility candidate purely for having an adit, a substation and a rail spur.

**RESOLVED, and it is the spine rather than a coefficient.** D0–D4 is a required per-observation
field, assigned by lookup into a versioned catalog against a **mandatory named null**. The universal-
D0 list is explicit and permanent. Band conditions are **typed**: B1 requires L(D3) ≥ 2, and no
quantity of D0 observations produces a single D3 lineage. **There is no summation**, so 200
non-diagnostic observations accumulate into nothing.

The E/A matrix (§4.4) is the fallback for uncatalogued observations, repairing the blindness to novel
typologies that a hard D0 default produces, while keeping the catalog primary and auto-generating
catalog-extension proposals so the fallback retires itself.

### HISTORIAN H6 — A single conclusive primary source cannot exceed grade E

**The defect.** DOC is capped at weight .28, so DOC=100 with all other axes at zero yields exactly
28.00 → E. The grade-band PROSE describes evidence KINDS while the FORMULA measures evidence BREADTH.
*These are different instruments and they disagree by up to three bands on the same candidate.*

**RESOLVED WITHOUT AN OVERRIDE.** Band A is attained by A1: one verified T1/T2 D4 CLAIM-PROPERTY row
meeting the §3.4 gate. A single declassified record naming facility, location and function is band A
on its own, from any starting point.

**The band LABELS and the band CONDITIONS are the same text.** "ESTABLISHED" is defined as "A1–A6
hold," not as a number range, so the two-instruments problem cannot recur. A1-alt adds a second
sufficient path so a facility you can stand in also reaches A.

*Implementation note, and a genuine sharp edge:* an early implementation made this fail in one
specific case, where a dispositive D4 document could not reach `null_state = EXCLUDED` because the
catalog row happened not to be marked null-excluding, stalling the proposition at C on condition A3 —
H6 reappearing through the side door. The fix is at write time: magnitude 4 with gates (d) and (e)
sets `null_excluding` on the evidence row, stored and auditable.

### IC I1 — No P(evidence | not-H) term anywhere in the system

**The defect.** GEO, INF and OWN describe features shared by every large underground works project and
together carry 54% of the weight. Evidence consistent with every hypothesis has zero analytic value
under ACH regardless of how solid the evidence itself is.

**RESOLVED** — this is the same fix as H5, seen from the ACH side. Every observation is scored against
a *named* alternative, and the E/A matrix asks Q2 (`expectedness under H_alt`) explicitly. Where the
null predicts the observation just as strongly, the row is D0 and satisfies no condition at any
volume. The alternative-hypothesis disposition table is a published product surface (§10.1), not an
internal quantity.

### IC I2 — CONFIDENCE has no required documentary floor; the weighting inverts the relationship

**The defect.** A candidate can reach grade B — "strongly evidenced" — with DOC exactly 0. A candidate
with DOC 100 and nothing else lands at 28 = E.

**RESOLVED.** B4 requires `|V[claim]| ≥ 1` and B1 requires lineages at D2/D3, which in this domain are
institutional records or resolvable direct witnesses. CAP-2a and CAP-2b make place-only support
structurally unable to exceed D and E respectively. And H6's fix supplies the other direction: one
conclusive document is band A.

### IC I3 — The CONTAM multiplier floors at ×0.5, so F is unreachable

**The defect.** A claim traced with perfect rigor to one admitted fabrication retains half its score.
Combined with GEO/INF/OWN scoring the location, any fabrication anchored to a real place inherits a
floor it cannot fall through. **F becomes unreachable for the entire class of claims the register most
needs to grade F.**

**RESOLVED.** No multiplier, no CONTAM score, no floor. Total collapse to a fabricated origin is
**R1**. Total collapse to a single origin is **CAP-1** → max C. Citogenesis is **CAP-3** → max E.
Nothing surviving receipt-checking is **CAP-5** → max F.

The self-attestation exclusion (§2.5) is what actually lets F be reached *honestly*: Nichols, Sauder
and Oliver's 1894 novel are the claimants and their content is the claim, so V = ∅ → CAP-5 → F.

### IC I4 — COR counts sources and calls it independence; the fleet manufactures false corroboration

**The defect.** "Tier 1 agents are blind to the others' findings during discovery — that independence
is what makes the COR axis mean anything." That is a category error. Seven blind crawlers over a
corpus seeded by one origin each independently return the same claim, and COR rises for a reason that
has nothing to do with the evidence.

**RESOLVED, and enforced in the schema rather than in briefs.** No COR axis. `L(Dk)` counts LINEAGES —
connected components over the citation graph — under eight collapse rules. Rule 2 is decisive: **all
findings from agents sharing a base model constitute ONE lineage, capped at 1 by a unique index.**
Rule 3 fixes the inverse error so a careful collation of forty Signal Agency documents is forty
lineages. Rule 6 replaces textual-overlap detection with claim-level semantic clustering. Rule 8
quarantines the register's own echo. §5.5 fact-key merging stops one fact entering four times.

**And structurally:** `discovering_agent` and `agent_run` are not reachable from any grading query.
The observation table has **no lineage column at all** — the count is computed from edges, never
asserted. The v0.1 sentence claiming agent blindness produces source independence is deleted; blind
fan-out is retained for **RECALL only**.

### SKEPTIC S1 — There is no verification tier

**The defect.** No agent in the fleet resolves a citation to bytes. "Every claim carries a citation" is
a test for the PRESENCE OF A CITATION STRING, which a confabulating LLM satisfies 100% of the time.
The rule has exactly zero discriminating power while creating the strongest possible appearance of
rigour. **And the incentive gradient runs the wrong way:** the higher the tier and the more
format-regular the identifier, the easier to hallucinate and the more weight it carries.

**RESOLVED AS A SCHEMA CONSTRAINT, and this is the load-bearing addition.** Resolve-or-die (§2.2):
resolved URL, HTTP status, SHA-256, timestamp, and a verbatim span at character offsets confirmed by
deterministic non-LLM code. Then grammar → resolution → **issuer metadata match** → **subject
binding**. The third check catches a real document misattributed to the wrong facility; the fourth
catches a real document about the right issuer but the wrong subject.

V0-UNRESOLVED contributes zero to every condition while remaining visible; CAP-5 caps a receipt-less
candidate at F; the format-valid-but-unresolvable rate is published per agent.

Enforced structurally: `receipt_state = VERIFIED` is unreachable by CHECK constraint without the full
chain, and `membership` is a generated column, so an unresolved receipt lands in V0 automatically.
**No LLM holds INSERT on the evidence, receipt or lineage tables.** Discovery agents write to
`ingest.lead` and `ingest.null_return` and nothing else.

The Sauder-as-bibliography move is correctly handled: identifiers regexed out of a fringe book are
LEADS and become citations only after independent resolution at the issuing authority — his documents
get promoted, his conclusions stay T4.

**PARTIAL, and stated as such.** Grammar failure is informative; **grammar success is worthless**.
V-1 grammar validation is a cheap reject filter and a telemetry source, never a pass criterion. And a
well-executed forgery that resolves at the issuing authority, quotes at the claimed offsets, matches
issuer metadata and binds to the subject passes every gate. A6 raises the cost by orders of magnitude;
it does not eliminate the attack. See Part 18.

### SKEPTIC S2 — Typology is excluded from scoring, and typology is the entire product

**The defect.** The grade certifies evidence ABOUT A PLACE while the typology asserts WHAT THE PLACE
IS, and no evidence is ever required for the typology. The reader sees "COG/COOP · Grade B". *The
arithmetic behind that badge never touched the words "COG/COOP".* Earn a defensible B on a real hole
and relabel it for free.

**RESOLVED.** TYPOLOGY is a graded proposition class, default `unknown-anomaly`, immovable without
clearing band C — enforced by a trigger that raises, not by convention. Relabelling to COG/COOP
instantiates FUNCTION(COG/COOP), which is scored, capped at E by CAP-2b before refutation even runs,
and for Mega Cavern is immediately R. **There is no composite to leave unmoved.**

The circularity the reviewer did not name — that `typology_profile` selects the diagnosticity catalog,
so a free relabel silently swaps the entire scoring table — is closed by §1.2: scoring runs under the
*graded* typology, the profile version is pinned on every grade row, and a `TYPOLOGY-CHANGE` forces
re-scoring of every proposition on the entity with both scorings retained.

### SKEPTIC S3 — The cheapest path to grade B costs zero dollars and fabricates nothing

**The defect.** Because GEO, INF and OWN score the LOCATION rather than the CLAIM and carry 54% of the
weight, the fabricator's optimal strategy is not to manufacture evidence but to **choose a target**.
Pick a real place that already scores high on mundane facts, attach an extraordinary claim, and the
register does the scoring work at no cost with no falsifiable step to attack.

**RESOLVED, and hardened beyond both submitted models.** CAP-2a caps place-only physical claims at D;
**CAP-2b caps place-only HARDEN, CONTROL, FUNCTION, PROGRAM, IDENTITY and ORIGIN claims at E**, because
a function claim carried entirely by attributes of the place has no support for the claim at all.
Place-derived and claim-derived contributions render as two separate bars on every entry.

v0.1's firewall ceiling of 83.20 on nothing but blogs and forum posts has no analogue: **there is no
accumulation path.**

Attestation custody (§5.4) closes the one attack neither submitted model blocked — seeding two
apparently-independent D3 lineages by attributing invented testimony to two real, dead, findable
people. The lineage terminus is the asserter, never the quoted, so both collapse to one.

### SKEPTIC S4 — Shared model priors invert CONTAM and inflate COR at the same time

**The defect.** When seven agents are one base model under seven prompts, they are not merely failing
to produce independence, they are **actively manufacturing false independence**. They share parametric
priors perfectly so they agree; they generate divergent surface text so they look unrelated; and each
invents a different citation for the shared belief so lineage tracing resolves them to different
origins. **The contamination detector reports its cleanest possible reading exactly when the evidence
base is entirely synthetic.**

**RESOLVED** by collapse rule 2 (schema-enforced same-family cap at 1), rule 6 (semantic clustering,
so divergent surface text does not create divergent lineages), and resolve-or-die (an unverified agent
assertion is not a lineage at all — it is a hypothesis awaiting retrieval).

Fleet independence is MEASURED, not asserted: a rolling sample runs through different model families
and inter-family agreement is published. **High agreement on VERIFIED sources is corroboration; high
agreement on UNVERIFIED assertions is a shared-prior signature.** Because there is no CONTAM term,
there is nothing left to invert.

**PARTIAL.** The design leans hard on "a different model family," and cross-family independence is
*asserted, not measured*. Different families share training corpora and plausibly share the specific
errors this domain is full of. The inter-family agreement telemetry measures agreement, which is not
the same as measuring independence. See Part 18.

### SKEPTIC S5 — CONTAM detects copying; LLM contamination is regeneration

**The defect.** Citation graphs, near-duplicate detection and first-URL dating all assume that a copy
resembles its source and points at it. Machine-regenerated text does neither. It shares no strings,
cites nothing, and is published fresh. **The axis designed as the conspiracy handler is structurally
blind to the dominant mechanism by which claims now propagate, and it fails silently, reporting LOW
contamination for the most contaminated cases.**

**RESOLVED IN THE ONLY WAY AVAILABLE — by denying regeneration a channel rather than by detecting
it.** `corpus_era` is computed mechanically. POST-2022-UNATTRIBUTED contributes zero and counts as
zero lineages, retained and displayed. A versioned public blocklist of machine-generated corpora makes
those hosts T5 by construction. Lineage clustering is semantic, not textual. CAP-4 sets the pre-2022
evidentiary waterline and is stated publicly as the blunt instrument it is.

**One genuine positive detector is added: shared distinctive error.** Regenerated text loses wording
but **keeps facts, including wrong ones**. Normalized fact-tuple fingerprints (coordinates to 4dp,
dates, proper nouns, numeric quantities, unit conversions) clustered on **error co-occurrence**. If
four apparently independent pages all give the same wrong elevation or the same transposed coordinate
digit, they are one lineage. Classical stemmatics; cheap; survives paraphrase. Incomplete — it fires
only when the parent contained an error — but close to dispositive when it fires.

**The blunt finding, stated in the record rather than hidden:**

> **There is no reliable general method for detecting machine regeneration, and this design does not
> claim one.** What it does instead is refuse the open post-2022 web any weight it cannot back with a
> receipt to an institutionally issued, dated artifact.

The structural reason this is survivable: **web text is almost never evidence in BES to begin with.**
Every D3 and D4 catalog row is an institutional artifact with an issuer, an identifier and a date. A
web page is at best T3/T4, cannot reach A or B, and CAP-2b prevents any FUNCTION claim exceeding E
without a claim-property row. The exposure is confined to lineage counting (closed by requiring a
lineage terminus to be a resolvable dated artifact rather than a URL) and to ORIGIN propositions
(where the contaminated corpus is the *object of study*). See Part 18 for the residual case.

**AI-text classifiers are rejected** — see §3.3.

### SKEPTIC S6 — The DOC firewall is breached for free through legitimate .gov channels

**The defect.** Provenance tiers are keyed to institutional origin rather than **causal** origin. The
rubric has no concept of SOLICITED EVIDENCE: an artifact that exists only because the claimant caused
it to exist. A government document created in direct response to a request naming the fabricated
facility is not independent of the claim — **it is the claim, echoed on letterhead** — and v0.1 tiers
it P1 and credits it at full weight.

**RESOLVED** by `causal_provenance` orthogonal to tier, plus **the tier of a document is the tier of
its author, not its host**. SOLICITED-BY-CLAIMANT contributes zero: regulations.gov comments and the
requester's half of a FOIA letter. The agency's half of the same PDF is a NEGATIVE receipt usable only
where X ≥ 1 — the schema splits one document into two rows with separate offsets. SELF-PUBLISHED maps
Zenodo-class deposits to T4. CROWD-EDITED makes OSM and Wikimapia leads-only, and replication into
downstream renderers is one lineage.

The general rule closes all four: **evidence created after, and because of, a claim is not evidence
for the claim.**

**And §3.3 adds the mechanism v0.2 needed and BES-as-drafted lacked**: causal provenance is *derived*
from four mechanical signals — the register's own solicitation log written before sending, span-level
segmentation of FOIA and docket PDFs, the date rule (only content predating the solicitation is
UNSOLICITED), and third-party requester identification. An agent asked to set this field will simply
write UNSOLICITED, so it is not asked.

Corollary that matters operationally: **the register's own FOIA requests cannot support its own
candidates.** Every acquisition task the pipeline files is written to the solicitation log first, so
any artifact it produces is SOLICITED-BY-CLAIMANT by construction and permanently.

---

## PART 17 — WHERE THE REVIEWERS DISAGREED, AND WHAT WAS DECIDED

These are recorded rather than smoothed, because a suite that hides its contested cases stops
detecting drift in exactly the places drift matters.

### 17.1 Greenbrier 1991 — the historian says C, the IC analyst says B

- **Historian:** *"C on evidence, but P(exists) HIGH — and it must be published as two numbers."*
- **IC analyst:** *"the correct pre-disclosure answer is that the structure was strongly evidenced and
  the function was unsupported"* — EXISTS B / FUNCTION F.

**DECIDED: EXIST B, FUNCTION E.** The IC reading is taken on EXIST: three verified claim-property
lineages (county construction record, contemporaneous local press, utility filing) satisfy B1's second
clause on the record alone, and the historian's C rests on an assessment of the *witnesses* that the
lineage rules already handle. On FUNCTION, neither reviewer's letter is taken exactly: the IC's F is
too low because V is not empty (the communications plant is verified, real and place-property), and
BES returns **E** via CAP-2b. **This diverges from the historian's letter and is a genuine
disagreement, not a rounding.**

### 17.2 Dulce Base — both lenses say F; BES returns R

- **Historian:** F with the origin documented and a citogenesis flag.
- **IC analyst:** F.

**DECIDED: R, deliberately.** The historian's own text demands that the AFOSI/Doty documentation *"be
representable as evidence AGAINST"*; that is R by definition. Their F was constrained by v0.1's
vocabulary, in which R did not exist as a reachable band. **Logged as ratification item R-2, not
smoothed.**

### 17.3 Mount Weather "underground city" — historian says D; BES returns E

**DECIDED: E, one band conservative.** The entry's operative requirements — A on the site, the flagged
claim on the same page, the flag attached to the *proposition* — are all met. E ("the claim survives
only as a claim") is judged a truer description than D. **This is a genuine divergence and is marked
as a known-divergent case in `docs/CALIBRATION.md`.**

### 17.4 SubTropolis — historian says R, IC analyst says F

**DECIDED: R**, following the historian. The mundane explanation is not merely complete but
**affirmatively documented and publicly advertised by the operator**, and the published lease chain
and ticketed public tours are affirmatively improbable under a hardened-COG claim. That is R2, not F.
F would say "nothing verified favours the claim," which understates what the record actually shows.

### 17.5 DIA — historian says F, IC analyst says E

**DECIDED: E**, following the IC analyst, who called this *"the single most important thing to test
before ratification."* V is not empty: seven verified third-party T1/T2 records of real facts exist
and enter V at D0. F would misdescribe the evidentiary state. The historian's F and the IC's E differ
on exactly the E/F line that §2.5 now defines, and the rule sorts them: **DIA's V is non-empty and
non-discriminating (E); Montauk's V is empty (F).**

### 17.6 The composite "B" cases — KUMMSC, Cartwheel, the Nike magazine

Both reviewers assigned a single composite letter (B) to entries that BES represents as **pairs**:
KUMMSC = EXIST A / EXTENT D; Cartwheel = EXIST A / EXTENT D (or C via C1c); the Nike magazine =
EXIST A / TYPOLOGY A / STATUS unknown-or-X.

**DECIDED: the decomposition is the answer, and it satisfies the reviewers' stated requirement** —
"existence solid, extent partly inferred" is *exactly* a pair. But it is **not a letter-for-letter
match and must not be reported as one.** The calibration suite scores these on the pair, not on a
composite.

### 17.7 Cartwheel is base-rate-sensitive and cannot be resolved from the calibration text

If the WHCA records name Fort Reno at instance level it is **A**; if they document the PEF network at
class level it is **C** via C1c. Which obtains cannot be determined from the reviewers' text.
**Flagged MARGINAL in the suite and scored as "either A or C, and the marginal_flag must be set."**

### 17.8 Bob Lazar / S-4 — the skeptic's hardest testimony case

The skeptic's entry is a direct challenge to any identity-only gate: Lazar is an unambiguously real,
publicly identifiable, named individual on the record since 1989 — so he satisfies "independently
confirmed to exist" — while his *credentials* are the disputed element.

**DECIDED: §5.4 is written as a position-to-know gate, not an identity gate.** The record must place
the person *in the role asserted*, predate the claim, and have been created for an unrelated purpose.
Lazar fails on that, and the S-4 underground-facility claim returns **F**, with Groom Lake EXIST at
**A**. This is a change to the *wording* of §5.4 forced by the skeptic's case, and it is recorded as
such.

---

## PART 18 — STANDING LIMITATIONS

What follows is not a list of things to fix later. It is a list of things this design **does not
solve**, published because a register that hides its blind spots is a safe harbour for the
fabrications those blind spots admit.

**18.1 Forgery at an authoritative issuer — and worse, the authoritative issuer that does not
authenticate.** There is no defence against a well-executed forgery that resolves at the issuing
authority, quotes at the claimed offsets, matches issuer metadata and binds to the subject. A6 raises
the cost by orders of magnitude; it does not eliminate the attack. **The sharper unaddressed version:
the tier table conflates *authoritative* issuers with *authenticating* ones.** A county recorder has
authority over the fact of recording and none over the facts a deed recites — recorders do not
adjudicate truth, and recording fees are tens of dollars. §4.3 lists "a deed or court record reciting
the structure" as a D4 anchor and §6.3 makes county deed records "X3 — the universal floor." That is a
genuinely cheap path to a D4 row, and `authority_over_fact` narrows but does not close it, because the
authority is real; it is the *scope* of the authority that is being exceeded. Same structural problem
at regulations.gov. The canary programme measures confabulation, not forgery, so this is unmonitored
as well as unblocked.

**18.2 ORIGIN corruption by regeneration.** A machine-generated page becomes the *first observed
appearance* of a claim, and the register dates the origin to a regeneration rather than to its true
earlier source. IA full-text `hits_inside`, AFU newsletter runs, Arctic Shift and the pre-2022 corpora
are partial coverage only. Since ORIGIN is the class that lets the register publish an A-grade fact
about a fabrication, a systematically wrong origin date corrupts the register's most distinctive
output — and corrupts it in the direction of **understating** how old and how contaminated a claim is.

**18.3 Cross-family independence is asserted, not measured.** The design leans on "a different model
family" for entailment adjudication, for the second read that promotes an interpretation out of T5,
for REFUTER, for the 10% double-scoring, and for the lineage counterfactual quorum. Different families
share training corpora and plausibly share the specific errors this domain is full of. Two families
agreeing that a span "states the proposition on its face" is weaker evidence than the design treats
it as, and **nobody knows how much weaker.** If only one family is available, the second line of
defence collapses to a banner.

**18.4 Semantic clustering false merges: direction safe, magnitude unknown.** Collapsing genuinely
independent witnesses into one lineage systematically **under**-counts corroboration. That is the safe
direction and it is chosen deliberately, but the error rate is unmeasurable without ground truth on
lineage, which does not exist for this corpus. **The register will under-grade an unknown fraction of
real facilities and will never be able to say which ones or how many.**

**18.5 The physical archive queue is a promise, not a capability.** R-PENDING-ACQUISITION converts
blindness into a work queue, but nobody visits College Park, nobody pulls RG 373, nobody scans county
minute books from 1962. ~96% of NARA textual holdings stay undigitised; RG 77/374/397 is where the
construction record actually lives; pre-1994 congressional material is scanned-only or paywalled;
county records digitise back only to the 1990s while every facility of interest was permitted between
1950 and 1975. **The grade distribution this register publishes is therefore a map of digitisation,
not a map of evidence.** That bias is not correctable by design. It is only disclosable, and it must
be disclosed on the methodology page in those words.

**18.6 Verification debt at the bottom of the register never clears.** Priority-by-marginal-grade-
impact guarantees that nothing published rests on unverified evidence, but its corollary is that
low-band propositions may never be verified at all. Harmless for grading — they cannot rise unverified
— but harmful for **refutation**, because R requires affirmative disconfirming evidence and the
register will systematically not go looking for it on entries nobody is defending. A long tail of
permanently-D/E entries that are in fact refutable will accumulate.

**18.7 Alias sets are an unaudited attack surface on subject binding.** Subject binding is only as good
as the alias table, which an LLM proposes into. An alias that is too generic — "Site R", "the Bunker",
a common installation name — silently widens binding across unrelated documents, and a wrongly-added
alias converts CLASS-scope rows into INSTANCE-scope ones, which is exactly the promotion path CAP-2b
exists to block. Reviewed writes slow this but do not make it observable: **nothing in the telemetry
measures binding precision**, and there is no obvious way to measure it without labelled data.

**18.8 OCR quality gates the oldest and best documents.** FUZZY-OCR caps at D3, which means the CREST
holdings, pre-1975 DTIC, the agency reading rooms and most WES scans — the highest-value D4 material
in the register's entire universe — are structurally biased toward *not* reaching D4 for reasons that
have nothing to do with what they say.

**18.9 The 158-source registry may be substantially wrong and nobody knows yet.** Three of the five
registries were written with .gov/.mil egress blocked; every endpoint grammar, parameter name and
identifier scheme in them was reconstructed from search snippets, GitHub client code and prior
knowledge. **The register's own W0 output has not been through the register's own verification tier.**
It should be, and it has not been costed.

**18.10 `authority_over_fact` is new and empty.** Until it is populated, §3.4(e) remains a model
judgement — and it is the condition that does the discriminating work in the highest-stakes gate in
the entire model. **Every D4 assignment made before that table is filled is provisional in a way the
grade row does not currently record.**

**18.11 Honest-mostly-X is an epistemic success and a product risk.** §12.6 sets the modal entry at X
or D, and a register that is honestly mostly-X is more credible than one dishonestly mostly-C. That is
right. It also means the first public version will look, to a casual reader, like an empty database
with elaborate excuses — and the pressure to relieve that will be continuous, will come from the
maintainer rather than from an attacker, and is not something any schema constraint can resist.
**The most likely way this model gets quietly abandoned is by weakening the SCI floor under pressure
to look substantial, and that abandonment will not announce itself.**

**18.12 It cannot rank within a band, and it cannot express degree.** Two C-grade propositions are not
comparable and there is no defensible sort order. HARDEN is a proposition, not a quantity: "designed
against multiple 200–300 MT direct hits" and "has a heavy door" both reach A if the documents support
them.

**18.13 It is brittle at band boundaries, deliberately.** A proposition one condition short of B sits
at C indefinitely. There is no partial credit and no "nearly B." The mitigation is transparency, not
smoothing — `limiting_condition` names the exact criterion and `marginal_flag` announces that one
contested fact decided it. **Users accustomed to scores will experience this as arbitrariness.**

**18.14 The R narrowing cuts both ways.** Requiring affirmative disconfirmation fixes DIA and the
Montauk Project, but a candidate whose mundane explanation is complete and documented — yet which
produces nothing *improbable* under the claim — sits at E forever rather than being cleanly refuted.
Conversely, R2 can still misfire on **a dual-use facility whose cover story is also completely true
and completely documented**, which is exactly what a good cover story is.

**18.15 The five curated tables are asserted, not derived, and they are the new attack surface.**
Moving judgement from per-candidate scoring into versioned lookups makes it auditable and
back-fittable, which is a large improvement — but it is a **relocation, not an elimination**. The
diagnosticity anchors are estimates and have not been back-fitted against outcomes because there are
no outcomes yet. The ERP table encodes a policy about how American secrecy works that could simply be
wrong for some agency or era, and **being wrong there is invisible**: it silently licenses or forbids
the argument from silence.

**18.16 It does not solve foreign or non-English material.** Receipts, identifier grammars, ERP
profiles and canonical search sets are all US-specific. The schema is country-agnostic but every table
in Parts 6 and 7 would need rebuilding per country.

**18.17 It is more expensive per candidate.** Propositions multiply rows; receipted negative searches
multiply queries; REFUTER scores every observation and runs at band A; verification adds a fetch, a
hash, a metadata comparison and an alias match per source. **A candidate that cost one adjudication
pass under v0.1 costs perhaps five to eight here.**

**18.18 The model says nothing about whether a candidate is worth scoring.** A find-rewarded fleet
pointed at Montana will still return Montana adits; they will now grade D or X instead of C, which is
better, but the register will fill with them. The candidate-set dilution rule (C1c) is the only
structural pushback and it applies only where a documented programme denominator exists.

**18.19 And the one it cannot argue its way out of: this specification is itself unverified.** It was
written by reading five registries, three of which state that their endpoint grammars and identifier
schemes were reconstructed from memory and search snippets because .gov egress was blocked. Not one
CREST identifier has been resolved, not one HTMC sheet fetched. **By its own standard this document is
V0-UNRESOLVED: format-valid, internally consistent, and unverified.** It should be treated as a
specification to be checked, not a finding, and the first task after ratification is to run its own
tables through its own verification tier.

---

## PART 19 — RATIFICATION ITEMS FOR BES v0.2.1

These are known defects **in the rubric**, discovered during implementation, deliberately implemented
literally rather than silently smoothed. **The schema should not quietly invent rubric.**

**R-1 — R short-circuits the SCI floor.** §9.4 step 2 withholds D/E/F/R below SCI 0.5, but step 1
returns R first. Implemented with R short-circuiting, on the grounds that an affirmatively established
refutation does not become unestablished for want of further searching, and publishing X over a
documented contradiction is worse. **Requires ratification either way.**

**R-2 — Dulce returns R where both lenses expected F.** Declared divergence; see §17.2.

**R-3 — Band F absorbs a spec gap.** §9.2's band F is "V = ∅, OR all higher bands and E fail." A
proposition with a single unrebutted D3 UNDERCUTS *and* strong D4 support falls through A/B/C (blocked
by A4/B3/C3), fails D (`null_state = EXCLUDED` is not in D2cond) and fails E (E2 requires V[D2+]
empty) — landing at **F**, beneath a middle band, on strong evidence. The acceptance suite reproduces
this. It is implemented literally because **the fix belongs in the rubric, not in the schema.**
Candidate fix for v0.2.1: add an explicit "contested" band, or relax D2cond to admit EXCLUDED when U
is non-empty.

**R-4 — `authority_over_fact` is specified but unpopulated.** §3.4(e) is a model judgement until
CURATOR fills the table. Grade rows made before that should carry a provisional marker they currently
do not.

**R-5 — `SILENCE-KNOWN-WITHHELD` and the three-way `UNRESOLVED` split** are v0.2 additions made during
implementation and are not in the ratified §6.4 / §2.2 text. They are strictly more expressive and
break nothing, but they should be folded into the rubric text rather than living only in the schema.

**R-6 — `receipt_class`, `text_layer_provenance` and the FUZZY-OCR D3 cap** are likewise
implementation-era additions (§2.8) that need ratifying into the rubric proper.

---

*BES v0.2 · rubric_version pinned on every grade row · this file is the specification the SQL
implements.*
