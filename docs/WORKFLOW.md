# BUNKERS — Research Workflow Specification

**Status:** DRAFT v0.1 — awaiting ratification
**Role of maintainer:** project manager / trigger operator. All research, adjudication, and construction is performed by agent fleets.

---

## 0. Premise and honest framing

This project builds a **candidate register** of hardened, buried, and continuity-of-government facilities, and grades each candidate by the quality of the evidence behind it.

A note on "this isn't public information": more of it is public than most people assume — it is just **scattered, unindexed, and boring**. Declassified CREST documents, DTIC technical reports, GAO audits, NEPA environmental impact statements, FCC antenna registrations, USGS historical topographic quadrangles, federal property disposal records, and congressional appropriations line items are all open. They are simply nobody's full-time job to correlate.

What is *not* public gets handled the same way it gets handled in intelligence analysis and in history: as **inference from open signals**, explicitly labeled as inference, with a confidence score attached.

And a third category — folklore, forum lore, claimed insider testimony — is **not excluded**. It is admitted to the register, then *sourced backwards to its origin*. A claim that 400 websites repeat is not 400 sources; it is usually one source and 399 copies. The system is built to say so out loud.

**The grading system is the product.** The map is the interface. The scrapers are plumbing.

---

## 1. The Grading System

### 1.1 Six evidence dimensions

Each candidate is scored 0–100 on six independent axes. Axes are scored separately and never silently averaged into a single number that hides its own composition.

| Code | Dimension | What earns points |
|---|---|---|
| **DOC** | Documentary | Declassified records, FOIA releases, DTIC/CREST/NARA holdings, GAO & IG reports, congressional appropriations, NEPA/EIS filings, patents, engineering journals |
| **GEO** | Geospatial signature | Historical USGS quads showing tunnel/adit symbols, spoil and cut-and-cover scarring, ventilation and blast-portal morphology, anomalous road grade into terrain, restricted airspace overlay, terrain suitability (rock competence, water table) |
| **INF** | Infrastructure correlates | Dedicated substation or anomalous load, AT&T Long Lines / microwave relay lineage, fiber trunk termination, deep well or water rights, rail spur, EMP-hardened comms, generator and fuel storage permits |
| **OWN** | Ownership & institutional trail | Title chain, shell-entity registration, GSA acquisition/disposal, federal real property inventory, contractor award records (FPDS/USAspending), lease anomalies |
| **TEST** | Testimonial | Named worker accounts, local press interviews, oral histories, obituaries citing assignments, unit histories, memoirs |
| **COR** | Independent corroboration | Count of source *lineages* — not documents — that arrived at the claim independently |

### 1.2 Source provenance tiers

Every individual source is tagged. Tiers gate how much a source can contribute to its axis.

- **P1 — Primary official.** Declassified or released government document, court record, filed permit.
- **P2 — Primary derived.** Raw imagery, historical maps, registry data, procurement databases.
- **P3 — Secondary rigorous.** Peer-reviewed, book with citations, investigative journalism with named sourcing.
- **P4 — Secondary loose.** Enthusiast site, urbex documentation, unsourced press, wiki.
- **P5 — Uncorroborated claim.** Forum post, video, anonymous testimony, oral rumor.

A candidate cannot exceed **DOC 40** on P4/P5 sources alone. This is the firewall.

### 1.3 Contamination score (the conspiracy handler)

`CONTAM` — 0 to 100, where **high is bad**. Measures how much of the evidence base collapses to a single origin.

The **LINEAGE** agent traces each claim to its earliest traceable appearance and builds a citation graph. Then:

- 100 = every source traces to one origin (single book, one video, one 2004 forum post)
- 50 = two or three independent origins with heavy downstream copying
- 0 = genuinely independent lineages that never touched each other

**Citogenesis flag** fires when a P4/P5 claim is later cited by a P3 source that itself cites only the P5 — the loop where rumor gets laundered into respectability. Flagged loudly, on the record.

### 1.4 Composite grade

```
CONFIDENCE = weighted(DOC .28, GEO .22, INF .18, OWN .14, TEST .08, COR .10)
             × (1 − CONTAM/200)
```

| Grade | Score | Meaning |
|---|---|---|
| **A** | 85–100 | Documented. Primary sources establish existence and function. |
| **B** | 70–84 | Strongly evidenced. Existence solid, function or extent partly inferred. |
| **C** | 55–69 | Reasonable inference. Converging open signals, no primary confirmation. |
| **D** | 40–54 | Weak inference. Suggestive but thin, or heavily contaminated. |
| **E** | 20–39 | Folklore with a trace. Claim has an identifiable origin and nothing more. |
| **F** | 0–19 | Unsupported. Retained with origin documented, so it stops recirculating. |

**F-grade entries are kept, not deleted.** A register that can show *why* a famous claim is empty is more useful than one that quietly omits it.

### 1.5 Independent classification axes

Not folded into the score — these are filters.

- **Typology:** COG/COOP · military hardened · missile silo (active/decommissioned/converted) · civil defense shelter · communications/relay · storage & archive · corporate/data · private commercial shelter · research · unknown anomaly
- **Status:** active · decommissioned · converted · sealed · demolished · unknown · alleged-only
- **Location precision:** exact (surveyed) · approximate (±1 km) · regional · claimed-only
- **Era:** pre-WWII · WWII · early Cold War (45–62) · late Cold War (62–91) · post-Cold War · post-9/11 · contemporary

---

## 2. Agent Fleet

Every agent is research-heavy, given a distinct search modality, and **blind to the others' findings during discovery** — that independence is what makes the COR axis mean anything.

### Tier 1 — Discovery (parallel, blind to each other)

| Agent | Beat |
|---|---|
| **ARCHIVIST** | CIA CREST, DTIC, NARA, FOIA reading rooms, GovInfo, Federal Register, GAO/IG reports, declassified imagery programs |
| **CARTOGRAPHER** | USGS historical topographic quads, terrain and geology, restricted airspace, mine and quarry registries, coordinate resolution |
| **LEDGER** | Appropriations, FPDS/USAspending contractor awards, GSA property records, NEPA/EIS filings, land title and county records |
| **CIRCUIT** | AT&T Long Lines lineage, FCC antenna registry, substations and grid anomalies, fiber routes, water rights, fuel permits |
| **VERNACULAR** | Local newspaper archives, county historical societies, oral histories, obituaries, union and unit records |
| **PALIMPSEST** | Forums, video transcripts, urbex, fringe literature — **tasked to find the ORIGIN of a claim, not to collect repetitions** |
| **FOREIGN** | Non-English corpora — Russian, German, Swiss, Nordic, Chinese, Czech, Serbian civil defense and hardened-facility literature |

### Tier 2 — Adjudication (per candidate, adversarial)

| Agent | Job |
|---|---|
| **LINEAGE** | Build the citation graph, date the earliest appearance, compute CONTAM, fire citogenesis flags |
| **REFUTER** | Adversarial. Actively tries to kill the candidate — mundane explanation, duplicate of a known entry, misread map symbol, confused with a neighboring site. Defaults to *refuted* under uncertainty. |
| **RESOLVER** | Entity resolution — merge name variants, alias chains, coordinate near-duplicates |
| **ASSESSOR** | Applies the §1 rubric, writes per-axis justification with citations, assigns the grade |
| **COMPLETENESS CRITIC** | End of every cycle: what modality wasn't run, what claim wasn't traced, what region is underrepresented — output becomes the next cycle's work list |

### Tier 3 — Construction (separate workflows)

**SCHEMA** · **HARVESTER** (scraper + PDF/OCR pipeline) · **ATLAS** (map + geospatial) · **INTERFACE** (frontend) · **DEPLOY** (Vercel/Supabase)

---

## 3. Workflows

### W0 — Foundation *(one-time, ~8 agents)*
Ratify rubric against how historians and IC analysts actually weight evidence · build the **source registry** (every archive, database, and corpus with access method, rate limits, robots.txt posture) · fix the taxonomy · design the Postgres/PostGIS schema · define the candidate JSON contract every downstream agent emits.

### W1 — Discovery Sweep *(recurring, ~7–10 agents)*
Tier 1 fans out blind over a scoped region or theme → each returns structured candidates → RESOLVER merges → new/changed candidates enter W2. **Pipelined, not barriered:** a candidate begins adjudication the moment its finder returns, while other finders are still working.

### W2 — Adjudication *(per candidate, ~3–5 agents each)*
LINEAGE → REFUTER (multi-vote for anything above grade C) → ASSESSOR. Survivors are written with full citation payload. Refuted candidates are written too, marked refuted, with the refutation attached — the register keeps its negatives.

### W3 — Construction *(phased)*
Schema → ingest pipeline → map → interface → deploy. Sequenced, with review gates between phases.

### W4 — Continuous Ingest *(cron)*
Delta sweeps on the watchlist · new-declassification monitors · re-grading when new evidence lands on an existing candidate · COMPLETENESS CRITIC sets the next cycle's targets. Every re-grade is versioned, so a candidate's confidence history is itself visible.

---

## 4. Proposed Stack

- **Next.js on Vercel** — static-heavy, no auth, public read
- **Supabase Postgres + PostGIS** — geospatial queries, versioned grade history, full citation graph
- **MapLibre GL** + open basemap (no proprietary token), terrain layer, historical map overlay
- **Ingest** as scheduled jobs writing to Supabase; the public site reads only

**Design language:** archival. Monospace and serif, dense tables, visible citations, footnotes, uncertainty rendered honestly — confidence shown as a distribution, not a pin that implies certainty. No hero section. No calls to action. It should read like a finding aid.

---

## 5. Ratified decisions

1. **Geographic scope** — **US-first.** CONUS is where archive access is strongest (CREST, DTIC, NARA, FPDS, USGS quads) and where the rubric can be validated against checkable ground truth. Non-US expands later; the schema is built country-agnostic from day one so expansion is additive, not a migration.
2. **Stack** — **Next.js on Vercel + Supabase (Postgres/PostGIS) + MapLibre GL.**
3. **W1 target** — **Broad and ongoing, not themed.** The first sweep runs every discovery agent wide across all typologies. The register is an accumulating database, not a report: W1 is a recurring engine that keeps adding, and coverage deepens over successive cycles rather than being scoped up front. The COMPLETENESS CRITIC sets each next cycle's targets.

**Consequence for design:** because ingest is continuous and unbounded, the schema must treat every candidate as *provisional and versioned* from the start. Grades move as evidence lands. The database records the movement, not just the current value.

---

## 6. Operating rules

- Scraping respects robots.txt and rate limits. Archives get cached locally so we hit them once.
- Every claim in the database carries a citation. No orphan facts.
- Nothing is deleted. Refuted and F-grade entries stay, with reasons.
- Confidence is versioned. The register shows how a candidate's grade moved and why.
- Agents do the work. The maintainer triggers, reviews, and ratifies.
