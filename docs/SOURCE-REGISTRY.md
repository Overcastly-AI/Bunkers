# SOURCE REGISTRY — 158 SOURCES ACROSS FIVE BEATS

**This is a working reference, not a summary. Harvester and discovery agents read the relevant beat in
full before every sweep.** Nothing here is abbreviated: each source carries its holdings, access
method, return format, provenance tier, rate limits, robots/ToS posture and search technique as
recorded.

---

## HOW TO USE THIS DOCUMENT

**Read the beat, then the gaps section for that beat, then start.** The gaps sections are not
apologies — they are the raw material for the expected-record table (`registry.erp_profile`), and they
are the highest-value artifact the source-registry work produced. A source that does not exist for a
given controlling authority produces **no row**, not a zero, and the gaps sections are where that is
established.

### Four rules that apply to every source below

**1 · ENUMERATE INDEXES; DO NOT SEARCH THEM.** Walking a series tree, iterating a polygon index,
paging by date window or sweeping by controller is **model-prior-independent by construction**.
Free-text search is where shared priors bite, and it is demoted to secondary everywhere. The
registries state the rule themselves: *"Do not construct identifiers; enumerate them."*

**2 · THE TIER OF A DOCUMENT IS THE TIER OF ITS AUTHOR, NOT ITS HOST.** `provenance_tier` below is
recorded as the source captured it, in P-notation. It maps onto BES T1–T5 as follows, and where a host
and its content differ, **both are recorded**: The Black Vault and governmentattic are T3 hosts
delivering T1 content; the Internet Archive is a **channel**, not a tier; a faithfully scanned T5
mimeographed newsletter in a T2 archive is a **T5 document with high retrieval integrity**, which is
exactly what makes the AFU collection usable for ORIGIN grading.

**3 · EVERY ENDPOINT BELOW IS CURRENTLY UNVERIFIED.** Three of the five registries were written with
.gov and .mil egress blocked. Endpoint grammars, parameter names and identifier schemes were
reconstructed from search snippets, GitHub client code and prior knowledge. **W1/P0 exists to
re-verify all of it against live targets**, and P0 may discover that a large fraction of this document
is fiction of exactly the kind the verification tier was built to catch. By the register's own
standard, **this document is V0-UNRESOLVED**.

**4 · ROBOTS AND RATE LIMITS ARE OPERATIONAL CONSTRAINTS, NOT SUGGESTIONS.** Fetch every robots.txt in
P0 and honour it. Where a posture below reads "could not verify," treat the strictest reading as
binding until P0 proves otherwise. A source that blocks the register is recorded as BLOCKED in
`registry.egress_probe` and its searches return `UNSEARCHED`, **never `NEGATIVE`** — because an
unreachable corpus that reads as a negative turns the register's own network failure into a finding.

### The value grades used below

| Grade | Meaning |
|---|---|
| **CRITICAL** | Load-bearing. Its absence changes what the register can grade |
| **HIGH** | Routinely decisive on some proposition class |
| **MODERATE** | Useful, situational, or a good cross-check |
| **LOW** | Retained for completeness or for ORIGIN work only |

Within each beat, sources are ordered **critical first**.

---

## CONTENTS

1. **BEAT 1 — FEDERAL DECLASSIFICATION AND TECHNICAL ARCHIVES** — 24 sources (8 critical · 12 high · 4 moderate) · primary agent: **ARCHIVIST**
2. **BEAT 2 — GEOSPATIAL, CARTOGRAPHIC AND GEOLOGICAL** — 26 sources (9 critical · 7 high · 9 moderate · 1 low) · primary agent: **CARTOGRAPHER**
3. **BEAT 3 — MONEY, PROPERTY, PROCUREMENT AND ENVIRONMENTAL FILINGS** — 37 sources (12 critical · 18 high · 7 moderate) · primary agent: **LEDGER**
4. **BEAT 4 — INFRASTRUCTURE: COMMUNICATIONS, POWER, WATER AND FUEL** — 31 sources (7 critical · 15 high · 8 moderate · 1 low) · primary agent: **CIRCUIT**
5. **BEAT 5 — LOCAL RECORD, ORAL HISTORY AND THE FRINGE CORPUS** — 40 sources (15 critical · 17 high · 8 moderate) · primary agent: **VERNACULAR / PALIMPSEST**

---

# BEAT 1 — FEDERAL DECLASSIFICATION AND TECHNICAL ARCHIVES

**Beat as scoped:** Federal declassification and technical archives

**Primary agent:** ARCHIVIST · **24 sources**

## Access notes for this beat

SEVERE ENVIRONMENT CAVEAT, STATED UP FRONT: this session's egress proxy blocked every .gov and .mil host, plus archive.org, wikipedia, cran, muckrock and glama. Only github.com/raw.githubusercontent.com were directly fetchable, alongside WebSearch. So the URL patterns, parameter names and identifier schemes below were reconstructed from (a) live GitHub source code of working clients, (b) live result URLs returned by search, and (c) search-engine extraction of the target pages. Everything marked "confirmed" was seen in a real URL or in real code. Nothing here was verified by me issuing a request to the target host. Before building a harvester, re-verify each endpoint and FETCH EVERY robots.txt — I could not.

PROVENANCE TIERS as used above: P1 = the originating federal record office or its official machine interface. P2 = faithful mirror of a P1 record, or professional curation over primary records (Internet Archive mirrors, National Security Archive, FRUS). P3 = independent FOIA-requester archives (Black Vault, governmentattic). P4 = enthusiast/analyst synthesis (coldwar-c4i, FAS, GlobalSecurity, Cryptome). P5 reserved for unsourced folklore. Critically, a document's tier is set by its ORIGIN, not its retrieval channel: an official DoD release hosted on Black Vault is P1 content acquired via P3, and the register should record both.

SUGGESTED INGEST ORDER, cheapest-and-best-first. (1) git clone HistoryAtState/frus — one command, structured TEI, zero rate limits, contains the DUCC decision record. (2) GovInfo API — born-digital HTML post-1994, clean package IDs, offsetMark cursor gives you a permanent incremental-sync primitive for an unbounded register. (3) Federal Register API — keyless, no rate limit. (4) NARA Catalog API — but budget the 10,000 queries/month hard cap deliberately; spend it on ancestorNaId series walks, not keyword fishing. (5) DTIC via its published sitemap.xml, which is an explicit crawler invitation and the friendliest robots posture on the beat. (6) ERDC Knowledge Core via OAI-PMH. (7) CREST and DTIC bulk via the Internet Archive scrape API rather than the origin sites. (8) The small hand-curated FOIA reading rooms (DoD IG, ESD/WHS, DTRA) mirrored completely once, then re-synced monthly. (9) P3/P4 sites last, and only as candidate generators.

OCR IS THE DOMINANT COST. Roughly: govinfo post-1994, FRUS, modern GAO/CRS and many DTIC post-1990 reports are already text. Essentially all of CREST, most pre-1975 DTIC/NTRL, all of ESD/WHS and the agency reading rooms, and most WES scans require OCR. Where an Internet Archive mirror exists, take IA's _djvu.txt sidecar instead of running your own OCR — it is free, already computed, and generally better than CIA's own text layer. Budget OCR only for material with no IA mirror.

TWO IDENTIFIER JOINS DO MOST OF THE DEDUPLICATION WORK, and should be first-class schema fields from day one: the AD accession number (joins DTIC ↔ Internet Archive ↔ NTRL ↔ WES/ERDC, since Corps reports carry both a WES number and an AD number), and the DoD FOIA case number {YY}-F-{NNNN} (joins ESD/WHS ↔ DoD IG ↔ Black Vault ↔ any downstream blog copy). The CIA ESDN plays the same role for CREST. Build these before ingesting, or you will store the same document four times at four different grades.

THE FREE NEGATIVE-EVIDENCE SIGNAL: DTIC's ADB prefix means "citation public, document distribution-limited." These are machine-detectable at scale and constitute a ready-made, prioritized FOIA worklist plus a legitimate register state — "known to exist, not released." Same for OpenNet records that carry an accession number but no digital object. Capture these rather than discarding them; they are exactly the honest uncertainty the project is built to render.

RATE-LIMIT AND COURTESY POSTURE: cia.gov is fragile and should be hit at ≤1 req/s single-threaded if at all (prefer the IA mirror). Federal Register is explicitly keyless and unlimited but caps pagination at 2,000 results, forcing date-sliced enumeration. NARA is 10,000 queries/month. governmentattic and Black Vault are individually funded volunteer archives — fetch selectively, never mirror wholesale, and always try to resolve to the official copy. DTIC and GovInfo are the only two sources that affirmatively invite bulk machine access.

## High-yield query strings for this beat

- `site:apps.dtic.mil "protective construction" — then harvest AD numbers and refetch from apps.dtic.mil/sti/pdfs/{AD}.pdf`
- `AFWL-TR — Air Force Weapons Laboratory technical report series, the hardened-structures shop at Kirtland AFB`
- `TM 5-858 "Designing Facilities to Resist Nuclear Weapon Effects" — the multi-volume joint-service design canon for buried facilities`
- `TM 5-855-1 "Fundamentals of Protective Design for Conventional Weapons"; superseded by UFC 3-340-01 / UFC 3-340-02`
- `DASA-{nnnn} / DNA-{nnnn} / DNA-TR-{yy}-{nnn} / DSWA-TR / DTRA-TR — the AFSWP→DASA→DNA→DSWA→DTRA report lineage`
- `WES Technical Report N-{yy}-{n} and GL-{yy}-{n} — Waterways Experiment Station nuclear-effects and geotechnical series`
- `NCEL-TR — Naval Civil Engineering Laboratory, Navy hardened and undersea/underground construction`
- "deep basing" / "superhard" / "deep underground" / "shock isolation" / "blast valve" / "blast door" / "ground shock" — DTIC free-text phrases that actually retrieve
- `"hard and deeply buried targets" (HDBT) — modern targeting literature that describes hardened-facility characteristics`
- `Deep Underground Command Center (DUCC); "National Deep Underground Command Post" — FRUS 1964-68 vol X documents d3, d77, d110`
- Project Greek Island (Greenbrier); Operation High Point / High Point Special Facility / CRYSTAL (Mount Weather); Site R / Raven Rock / Alternate Joint Communications Center (AJCC)
- `IVY LEAGUE 82; NINE LIVES; REX 82 ALPHA — documented COG/COP exercise names, strong National Security Archive keys`
- `govinfo field query: collection:chrg AND isappropriation:true — military construction authorization and appropriations hearings`
- `govinfo package IDs CHRG-{congress}{s|h}hrg{number}; content at /content/pkg/{PKGID}/html/{PKGID}.htm`
- `GAO/NSIAD-{yy}-{nnn} — legacy GAO national-security division series; modern GAO-{FY}-{6 digits}`
- NARA record groups: RG 77 (Chief of Engineers), RG 374 (Defense Nuclear Agency), RG 304 / RG 396 / RG 397 / RG 311 (civil defense lineage), RG 269 (GSA — holds Federal Preparedness Agency), RG 330 (OSD), RG 218 (JCS), RG 341 / RG 342 (USAF), RG 373 (DIA aerial photography)
- `NARA Catalog API: ancestorNaId walk to levelOfDescription=series, then mine scope-and-content notes for facility names`
- `CIA CREST ESDN pattern CIA-RDP{nn}{nnnnn}{L}{block}{item}-{check}; direct PDF at /readingroom/docs/{ESDN}.pdf; node walk at /readingroom/node/{id}`
- `CIA CREST Solr facets: f[0]=im_field_collection:{term_id}, f[1]=dm_field_release_date:[{ISO} TO {ISO}], ds_field_pub_date[min]/[max]`
- `archive.org scrape: q=identifier:cia-readingroom-document-* and q=identifier:DTIC_AD* with fields=identifier,title,date, count=10000, cursor-paginated`
- `USGS M2M: POST login-token then scene-search against the Declass 1/2/3 datasets; call dataset-filters first to learn the real mission/camera field IDs`
- Federal Register API: conditions[term]="notice of realty action" / "withdrawal of public lands" / "record of decision" with conditions[agencies][]=army|air-force
- `DoD FOIA case numbers {YY}-F-{NNNN} — the join key linking ESD/WHS, DoD IG, and Black Vault copies of the same release`
- `ERDC DSpace: handle 11681, WES community 11681/22942, OAI ListRecords for bulk metadata`

## Sources

### 1.1 · CIA CREST / FOIA Electronic Reading Room

`CRITICAL` · tier **P1** · <https://www.cia.gov/readingroom/>

*Serves:* documented evidence · facility identification · construction chronology · folklore backsourcing · program codewords

**Holdings.** ~930,000 declassified documents / ~12M pages released under the 25-Year Program, plus discrete FOIA release collections. Relevant content clusters: Office of Communications and Office of Logistics facility files (relocation sites, hardened comms), ground photo caption cards (RG-style imagery indexes under CIA-RDP78-05867A), National Intelligence Estimates on Soviet hardened/deep-underground facilities (useful as a methodology mirror for how the US assessed hardening), agency continuity-of-operations and relocation-site administration, and the STAR GATE/SUN STREAK files (CIA-RDP96-00787/00788/00789) which are the documented origin of a large amount of bunker folklore and are therefore the single most valuable corpus for BACKSOURCING fringe claims.

**Access method.** HTML scrape of a Drupal 7 + Apache Solr site; direct PDF fetch by document number. No API, no bulk endpoint.

**Format returned.** Scanned PDF requiring OCR for most pre-1990 material; CIA supplies a partial OCR text layer of poor quality on many items. Metadata is clean HTML.

**Search technique.** The document identifier is the ESDN (Electronic Search Document Number), rendered as CIA-RDP{2-digit originating-office series}{5-digit record series}{letter}{block}{item}-{check}, e.g. CIA-RDP79B00752A000300010001-1. It is NOT a date. Three stable URL patterns, all confirmed live: landing page https://www.cia.gov/readingroom/document/{esdn-lowercased-hyphenated}; direct PDF https://www.cia.gov/readingroom/docs/{ESDN-UPPERCASE}.pdf; printer view https://www.cia.gov/readingroom/print/{drupal_node_id} and https://www.cia.gov/readingroom/node/{drupal_node_id}. Node IDs are dense integers roughly 1..1,900,000 and can be walked directly, which is the cheapest full-corpus enumeration path and bypasses search entirely. Paginated browse: https://www.cia.gov/readingroom/document-type/crest?page=N — N observed to at least 89121 at 10 docs/page. The advanced search at /readingroom/advanced-search-view exposes raw Solr dynamic fields as URL params, confirmed from a live query string: f[0]=im_field_collection:{numeric_term_id}, f[1]=dm_field_release_date:[2010-01-01T00:00:00Z TO 2011-01-01T00:00:00Z] (literal Solr range syntax, URL-encoded), ds_field_pub_date[min], ds_field_pub_date[max], ds_field_pub_date_op, order=label, sort=desc. The im_/dm_/ds_ prefixes are Drupal SearchAPI-Solr conventions (integer-multivalue / date-multivalue / date-single), so additional facet fields almost certainly follow the same naming and can be discovered by reading the facet block hrefs on any result page. Full-text search supports AND/OR/NOT. Beyond the three content types in CIA's own guide there are ~90 further content-type values in the metadata, reachable as facets.

**Rate limits.** None published. Site is slow and returns 403/503 under concurrency; observed community practice is 1 request/sec single-threaded. Treat as fragile.

**Robots / ToS posture.** Could not verify robots.txt from this environment (cia.gov is blocked by the egress proxy here). MUST be fetched and honored before any harvesting run. Assume /readingroom/search/ and faceted URLs are disallowed until proven otherwise, and prefer the Internet Archive mirror for bulk work.

**Notes.** Do not treat CREST as a corpus about US bunkers — it is overwhelmingly a foreign-intelligence corpus. Its value to this register is (a) logistics/communications administrivia that incidentally names US relocation facilities, and (b) it is the provenance root for a very large share of internet bunker folklore. Grade accordingly.

---

### 1.2 · CIA Reading Room mirror, Internet Archive

`CRITICAL` · tier **P2** · <https://archive.org/details/cia-readingroom-document-cia-rdp67-00896r000100090004-0>

*Serves:* documented evidence · bulk acquisition · OCR full text · folklore backsourcing

**Holdings.** Item-level mirror of the CIA Reading Room. Confirmed identifier convention: cia-readingroom-document-{esdn-lowercased}. An older, separately-uploaded tranche uses the bare uppercase ESDN as identifier, e.g. CIA-RDP61-00549R000100220001-0. Both conventions coexist; a harvester must try both.

**Access method.** Internet Archive Scrape API + item metadata API + direct file download

**Format returned.** PDF, plus IA-generated DjVu/ABBYY full-text OCR sidecars — meaningfully better OCR than CIA's own layer in many cases

**Search technique.** Enumerate with the cursor-based scrape endpoint: https://archive.org/services/search/v1/scrape?q=identifier:cia-readingroom-document-*&fields=identifier,title,date&count=10000, paging on the returned cursor. Per-item metadata at https://archive.org/metadata/{identifier} returns the file manifest including the _djvu.txt OCR sidecar; fetch that instead of OCRing the PDF yourself. Advanced search (https://archive.org/advancedsearch.php) is capped at 10,000 paged results, so use scrape for enumeration and advancedsearch only for narrow queries. Full-text search across OCR is a separate service and is the way to find hardened-facility mentions inside documents whose titles are '(UNTITLED)' — a very common CREST title.

**Rate limits.** Scrape API requires count>=100 per call, cursor-paginated; IA tolerates polite parallelism far better than cia.gov

**Robots / ToS posture.** archive.org permits automated metadata access via its documented public APIs; the scrape and metadata endpoints are the sanctioned path

**Notes.** This is the correct bulk path for CREST. It removes the cia.gov rate/robots problem entirely, gives better OCR, and is resumable. Provenance note for the register: an IA item is a MIRROR of a P1 record, not an independent source — cite the CIA ESDN as the authority and IA as the retrieval channel.

---

### 1.3 · DTIC public technical reports (apps.dtic.mil)

`CRITICAL` · tier **P1** · <https://apps.dtic.mil/sti/>

*Serves:* documented evidence · engineering parameters · program codewords · contractor identification · construction chronology

**Holdings.** Unclassified/unlimited-distribution DoD technical reports. This is the richest single corpus for the ENGINEERING of hardened and buried facilities: blast-resistant and protective construction design, rock mechanics and tunnelling for military use, shock isolation, EMP hardening, silo and command-post survivability, deep-basing studies, and nuclear weapons effects. Public site covers all unclassified/unlimited citations since 1975 plus a large body of digitized older material back to the 1940s.

**Access method.** Sitemap-driven crawl (explicitly offered to crawlers), plus deterministic per-document URL construction. No public JSON API.

**Format returned.** PDF. Pre-~1990 scans need OCR; DTIC also exposes an HTML rendition for some items which is already text.

**Search technique.** Identifier is the AD (ASTIA Document) accession number, issued continuously since 1943. Prefixes carry distribution meaning and are the most efficient filter on the whole beat: AD0/ADA = approved for public release (fetchable); ADB = distribution limited (citation only, FOIA required for the body); ADC = classified; ADP = individual paper within a compilation. Deterministic URLs, all confirmed: citation https://apps.dtic.mil/sti/citations/{AD}; PDF https://apps.dtic.mil/sti/pdfs/{AD}.pdf and the older https://apps.dtic.mil/sti/tr/pdf/{AD}.pdf (both live — try both); HTML full text https://apps.dtic.mil/sti/html/tr/{AD}/index.html; legacy resolver https://discover.dtic.mil/tr_redirect/{AD}. The high-yield move is searching by ORIGINATING LAB REPORT SERIES rather than by topic, because these labs did essentially nothing else: AFWL-TR-{yy}-{nnn} (Air Force Weapons Laboratory, Kirtland AFB — the hardened-structures and silo-survivability shop; its 'Air Force Design Manual: Principles and Practices for Design of Hardened Structures' is the canonical text); AFSWC-TR (Air Force Special Weapons Center, predecessor); DASA-{nnnn} (Defense Atomic Support Agency, 1959-71); DNA-{nnnn}{letter} and DNA-TR-{yy}-{nnn} (Defense Nuclear Agency, 1971-96); DSWA-TR (Defense Special Weapons Agency, 1996-98); DTRA-TR (1998-); WES TR / Technical Report {series}-{yy}-{n} where series SL=Soils, GL=Geotechnical, N=Nuclear weapons effects (Army Engineer Waterways Experiment Station, Vicksburg — did the physical cratering and buried-structure testing); CERL-TR (Construction Engineering Research Lab); NCEL-TR (Naval Civil Engineering Laboratory, Port Hueneme — Navy hardened/underground construction). Free-text phrases that actually retrieve: 'protective construction', 'hardened structures', 'deep basing', 'deep underground', 'superhard', 'shock isolation', 'blast door', 'blast valve', 'ground shock', 'cratering', 'rock mechanics tunnel', 'hard and deeply buried targets' (HDBT — the modern targeting-side literature, which describes US facility characteristics in the course of describing how to attack analogous ones).

**Rate limits.** Not published. Cloud-hosted and more robust than CREST, but throttle conservatively (~1-2 req/s).

**Robots / ToS posture.** DTIC publishes https://apps.dtic.mil/sitemap.xml and its guidance explicitly directs crawlers wishing to index the unclassified/unlimited technical report collection to that sitemap. That is an affirmative invitation to crawl the TR collection — the cleanest robots posture of any source on this beat. Fetch apps.dtic.mil/robots.txt and honor it alongside.

**Notes.** ADB-prefixed citations are a systematic, machine-detectable FOIA worklist: the metadata is public, the document is not. Harvest ADB citations into the register as 'known to exist, not released' — that is itself an evidence grade and is exactly the kind of honest negative the project wants.

---

### 1.4 · ERDC Knowledge Core (Army Corps of Engineers research repository)

`CRITICAL` · tier **P1** · <https://erdc-library.erdc.dren.mil/>

*Serves:* engineering parameters · documented evidence · construction chronology · contractor identification

**Holdings.** The full published research output of the Corps' laboratories, including the Waterways Experiment Station (WES) community covering 1 Mar 1937 - 30 Sep 1999. WES did the physical experimental work on buried structures, cratering, ground shock and rock mechanics for the hardened-facility program. Also holds Corps historical publications and district histories.

**Access method.** DSpace repository — REST API, OAI-PMH, and direct bitstream URLs

**Format returned.** PDF, scanned for older reports (OCR often needed); Dublin Core metadata via OAI

**Search technique.** This is a DSpace instance using Handle prefix 11681. Community/collection browse at https://erdc-library.erdc.dren.mil/jspui/handle/11681/{id} — the WES community is 11681/22942. Files are served from the DSpace 7 REST layer as https://erdc-library.erdc.dren.mil/server/api/core/bitstreams/{uuid}/content, which means item metadata must be fetched first to resolve bitstream UUIDs (they are not derivable). Try the standard OAI endpoint (typically /server/oai/request?verb=ListRecords&metadataPrefix=oai_dc&set=hdl_11681_22942) for bulk metadata — this is the correct enumeration primitive and avoids scraping entirely. Report series to filter on: Technical Report S- and SL- (soils), GL- (geotechnical), N- (nuclear weapons effects), Miscellaneous Paper, and Research Report, each numbered {series}-{yy}-{n}. Note that many WES reports carry BOTH a WES number and an AD number, so this repository and DTIC deduplicate against each other — store both identifiers.

**Rate limits.** Not published; DSpace instances generally tolerate polite harvesting and OAI-PMH is designed for it

**Robots / ToS posture.** DSpace repositories are built for OAI-PMH harvesting; that is the intended machine path and should be preferred over HTML scraping

**Notes.** Underused and high-value. The .dren.mil hostname makes people assume it is access-controlled; the public repository is not. Cross-referencing WES report numbers against DTIC AD numbers recovers items where one system's copy is missing or unreadable.

---

### 1.5 · GovInfo API and Bulk Data Repository (GPO)

`CRITICAL` · tier **P1** · <https://api.govinfo.gov/docs/>

*Serves:* documented evidence · cost/appropriations · construction chronology · political provenance · folklore backsourcing

**Holdings.** Congressional Hearings (CHRG), Congressional Reports (CRPT), Congressional Record (CREC/CRECB), Serial Set, US Code, CFR, Federal Register, and GAO Reports (GAOREPORTS, all publicly released reports FY95 - Sept 2008). For this beat the load-bearing collection is CHRG: military construction authorization and appropriations hearings are where line items for hardened facilities are named, justified, questioned, and sometimes killed on the record — the DUCC funding fight in the FY1965 MilCon bill is the model case.

**Access method.** JSON REST API with api.data.gov key; plus XML bulk data repository; plus deterministic content URLs

**Format returned.** PDF, HTML (already text — no OCR needed for post-1994 material), XML, MODS metadata

**Search technique.** Package IDs are deterministic and parseable: CHRG-{congress}{chamber}hrg{number}, e.g. CHRG-107shrg70864 (Senate), CHRG-119hhrg62456 (House). Content URLs, all confirmed: https://www.govinfo.gov/content/pkg/{PKGID}/html/{PKGID}.htm and .../pdf/{PKGID}.pdf and details page https://www.govinfo.gov/app/details/{PKGID}. API services: /collections/{collectionCode}/{lastModifiedDate} for incremental sync (cursor via offsetMark — this is how you keep an unbounded ingest current), /packages/{PKGID}/summary and /granules for hearing-level subdivision, /published/{dateRange} and /search. The field-query language is the real power tool and is shared between the web UI and the search service: collection:chrg, publishdate:range(1994-01-01,), governmentauthor:, sudocclass:, congress:, branch:, citation:, plus MODS traversal via mods:{path}:{value}. Two specific high-yield queries: collection:chrg AND isappropriation:true restricted to military construction subcommittees; and full-text phrase searches for 'hardened', 'relocation facility', 'alternate command post', 'classified location', 'special facility'. Bulk XML at https://www.govinfo.gov/bulkdata/{COLLECTION} with schema, XSLT and user guide under each collection's Resources directory.

**Rate limits.** api.data.gov standard tiering; DEMO_KEY works for trial but is aggressively limited. Register a real key.

**Robots / ToS posture.** Public API is the sanctioned path; govinfo also publishes sitemaps at https://govinfo.gov/sitemaps

**Notes.** Post-1994 govinfo text is born-digital HTML, so it is the cheapest full-text corpus on this entire beat — no OCR, no scraping, clean IDs. Start ingest here before touching anything scanned. The pre-1994 congressional record is the gap (see the Serial Set / HathiTrust note in gaps).

---

### 1.6 · NARA National Archives Catalog API v2

`CRITICAL` · tier **P1** · <https://catalog.archives.gov/api/v2/>

*Serves:* facility identification · construction chronology · finding-aid discovery · FOIA/visit targeting

**Holdings.** Archival descriptions, authority records, digital object metadata, public contributions (tags/transcriptions), and extracted OCR text across all NARA holdings. Only ~3.9% of NARA's estimated textual pages are digitized (475M scans as of mid-2026), so the catalog is primarily a FINDING AID that tells you which box to request, not a document delivery system.

**Access method.** JSON REST API with API key

**Format returned.** JSON metadata; digital objects as JPEG/PDF/TIFF where digitized

**Search technique.** Key: obtain free by emailing Catalog_API@nara.gov (read-only or read-write). Auth via header x-api-key. Search endpoint https://catalog.archives.gov/api/v2/records/search?q={query}; OpenAPI spec at https://catalog.archives.gov/api/v2/api-docs. q supports AND/OR/NOT, * wildcards, and "exact phrases". Confirmed useful field params: ancestorNaId (restrict to everything beneath a given description — the way to walk a record group or series), levelOfDescription (recordGroup / collection / series / fileUnit / item), geographicReference (matches record.subjects.heading where authorityType=geographicPlaceName — the geospatial hook for a place-based register). Field selection and sorting are supported, so request only the fields you store. The record groups that actually matter for this beat: RG 77 Office of the Chief of Engineers (the builder of record — Site R, Mount Weather tunnels, missile silos); RG 374 Defense Nuclear Agency (successor to AFSWP/DASA; weapons-effects and hardness testing); RG 304 Office of Civil and Defense Mobilization; RG 396 Office of Emergency Preparedness; RG 397 Defense Civil Preparedness Agency (1947-79, bulk 1961-79); RG 311 FEMA; RG 269 GSA (holds Federal Preparedness Agency records — a non-obvious placement that defeats naive searching); RG 330 Office of the Secretary of Defense; RG 218 Joint Chiefs of Staff (JCS emergency relocation, AJCC); RG 341 HQ USAF Air Staff; RG 342 USAF commands and activities; RG 373 Defense Intelligence Agency (aerial photography). Bulk-download helper scripts live at https://github.com/usnationalarchives/Catalog-API/tree/master/bulk-download-scripts — notably combinedDigitalObjectScript.py (menu-driven; single NAID, parent NAID, arbitrary search, or CSV input) and GenerateObjectURLs_NoDownload_AllChildRecords.py, which emits object URLs to CSV without downloading and is the right primitive for building a register index.

**Rate limits.** 10,000 queries per month per key by default, auto-reset monthly; key is temporarily blocked on overage. Higher limits granted on justified request.

**Robots / ToS posture.** API governed by published Terms of Use; acceptance is implied by use. The API is the sanctioned machine path — do not scrape catalog.archives.gov HTML instead.

**Notes.** The single highest-leverage NARA technique for this project is walking ancestorNaId down from a record group to series level and harvesting SERIES-LEVEL scope-and-content notes. Those notes describe undigitized boxes in plain English and routinely name facilities, projects and dates that appear nowhere online. That converts directly into both register entries graded 'documented — described in finding aid, not yet examined' and a prioritized research-visit list.

---

### 1.7 · National Security Archive, George Washington University

`CRITICAL` · tier **P2** · <https://nsarchive.gwu.edu/>

*Serves:* documented evidence · program codewords · expert curation · folklore backsourcing

**Holdings.** Curated Electronic Briefing Books (5 to 100+ documents each) with introductory essays and per-document descriptions. The Nuclear Vault collection and Bill Burr's 233 EBBs are the core for this beat: nuclear command and control, presidential succession, and continuity of government. Documented exercise names that serve as search keys: IVY LEAGUE 82, NINE LIVES (continuity of the presidency), REX 82 ALPHA (continuity of government).

**Access method.** HTML scrape; two site generations coexist (nsarchive.gwu.edu current, nsarchive2.gwu.edu legacy at /NSAEBB/)

**Format returned.** HTML essays plus linked PDFs of the underlying documents

**Search technique.** Crawl both generations: current briefing books under /briefing-book/{collection}/{date}/{slug} (e.g. /briefing-book/nuclear-vault/2024-04-17/...), the index at /postings/briefing-books?page=N, /index-previous-postings, and the legacy tree at nsarchive2.gwu.edu/NSAEBB/. The high-value extraction is not the essay but the per-document DESCRIPTIONS, which name the originating agency, date, classification and declassification route for each attached PDF — that is pre-assembled provenance metadata, exactly the schema this register needs, produced by professional historians.

**Rate limits.** Not published; a university-hosted site — be conservative

**Robots / ToS posture.** Check nsarchive.gwu.edu/robots.txt. Note the Archive sells subscription document sets through a commercial publisher; the free web EBBs are the open portion and the paywalled sets are not fair game.

**Notes.** This is the best single quality benchmark available for the register's own citation practice. Where NSArchive has already traced a document, adopt their provenance chain and cite them as the intermediary rather than re-deriving it. It is P2 because it is curation over primary records, not the record office itself — but it is the most reliable P2 on the beat.

---

### 1.8 · USGS EarthExplorer Machine-to-Machine (M2M) API — declassified imagery

`CRITICAL` · tier **P1** · <https://m2m.cr.usgs.gov/>

*Serves:* geolocation · construction chronology · imagery corroboration · open-signal inference

**Holdings.** Declass 1 (released 1996): CORONA, ARGON, LANYARD, 1960-1972, >860,000 frames. Declass 2 (2002): KH-7 GAMBIT 1963-67 and KH-9 HEXAGON mapping camera 1973-80. Declass 3 (2013, with a further ~14,000 rolls / 670,000+ scenes transferred to EROS in 2019): KH-9 HEXAGON panoramic, 1971-1984. KH-9 panoramic resolution ~0.6-1.2 m; KH-9 mapping camera ~6-9 m; this is enough to see spoil piles, portal construction, access roads and antenna farms.

**Access method.** JSON-RPC-style REST API over HTTPS; free registration required

**Format returned.** Scanned film delivered as GeoTIFF/JPEG; browse images separately downloadable; georeferencing is approximate for the declassified sets and often needs manual control points

**Search technique.** Register at https://ers.cr.usgs.gov/register then request M2M access at https://ers.cr.usgs.gov/profile/access. Auth is username + M2M TOKEN (not your password). Base path https://m2m.cr.usgs.gov/api/api/json/stable/ ; POST to login-token, then pass the returned key as an X-Auth-Token header on every subsequent call. Endpoints confirmed in working client code: dataset-search, dataset-filters, scene-search, scene-metadata, scene-metadata-list, scene-list-add/get/remove, download-options, download-request, download-search, download-remove, download-order-remove, logout. Request bodies are JSON with datasetName, sceneFilter (spatial + temporal + metadata filters), entityId/entityIds, maxResults, startingNumber, metadataType. Critically: call dataset-filters for each declass dataset FIRST and read the real filter field IDs — the declassified datasets expose mission/camera/frame fields that differ from Landsat's and are not documented narratively anywhere. Entity IDs are structured and parseable, e.g. D3C1217-401747A005 encodes the Declass phase, mission, and frame. Reference client with working request construction: https://github.com/adehecq/usgs_explorer (see usgsxplore/api.py).

**Rate limits.** Enforced server-side; the API returns a RATE_LIMIT error code that clients are expected to back off and retry on. Download requests are queued/ordered rather than instantaneous for large scene sets.

**Robots / ToS posture.** Sanctioned programmatic API — this is the intended access path, no scraping needed

**Notes.** The declassified sets are the backbone of the 'inferred from open signals' evidence bucket: a 1960s frame showing excavation at a site that appears in no document is real evidence of activity, and a frame showing nothing at a site that folklore says was built in 1962 is real evidence against. Both belong in the register. Note that the coverage is US-domestic-sparse for CORONA (it was aimed at the USSR/PRC); domestic coverage is better served by RG 373 and USGS aerial photography.

---

### 1.9 · Congressional Research Service reports

`HIGH` · tier **P2** · <https://crsreports.congress.gov/>

*Serves:* documented evidence · expert synthesis · folklore backsourcing · legislative history

**Holdings.** Non-confidential CRS reports, including recurring products on continuity of government, presidential succession, COOP/COG policy, and defense facility programs. CRS reports are unusually valuable for backsourcing because they footnote precisely and summarize the documentary state of play at a point in time.

**Access method.** HTML/PDF from the official site; EveryCRSReport provides a mirror with better bulk access; UNT Digital Library and FAS hold deep historical archives

**Format returned.** HTML and PDF, born-digital text

**Search technique.** Identifier is the CRS product code: R{5-digit}, RL{5-digit}, RS{5-digit}, IF{5-digit}, IN{5-digit}. crsreports.congress.gov serves current versions only — for superseded versions and pre-2018 reports use EveryCRSReport (https://www.everycrsreport.com/, 22,000+ reports, offers bulk access and preserves version history), the UNT Digital Library CRSR collection (https://digital.library.unt.edu/explore/collections/CRSR/), and the FAS archive (https://sgp.fas.org/crs/). Version history is the point: comparing successive editions of the same RL number shows when a fact entered or left the official summary.

**Rate limits.** Not published

**Robots / ToS posture.** Official site publishes reports as required by P.L. 115-141; EveryCRSReport publishes explicitly for reuse

**Notes.** The official site's current-version-only policy is a real limitation — a claim can be silently dropped from a report between editions. EveryCRSReport and UNT preserve the earlier text, which is exactly the kind of movement this register is designed to record.

---

### 1.10 · DoD / Washington Headquarters Services Executive Services Directorate FOIA Reading Room

`HIGH` · tier **P1** · <https://www.esd.whs.mil/Records-Declass/FOIA/Reading-Room/Reading-Room-List_2/>

*Serves:* documented evidence · program codewords · construction chronology

**Holdings.** OSD and Joint Staff FOIA releases and declassified records, organized by component (including a DARPA subsection). ESD is the OSD-level declassification and records office, so this is where OSD-originated continuity, relocation and command-post material surfaces when released.

**Access method.** HTML scrape of a component-partitioned directory listing

**Format returned.** PDF, scanned, OCR usually required

**Search technique.** Two live path prefixes exist and are not identical — crawl both: /FOIA/Reading-Room/Reading-Room-List_2/ and /Records-Declass/FOIA/Reading-Room/Reading-Room-List_2/, plus the older /FOID/Reading-Room/. Enumerate the component subdirectories rather than relying on site search, which is poor. Case files are named by FOIA request number in the form {YY}-F-{NNNN} (e.g. 20-F-0163) — that token is also how the same release is cited on The Black Vault and elsewhere, making it a reliable join key for deduplication across mirrors.

**Rate limits.** Not published

**Robots / ToS posture.** Verify esd.whs.mil/robots.txt

**Notes.** The {YY}-F-{NNNN} request number is the most useful cross-archive identifier on the FOIA side of this beat. Store it as a first-class field.

---

### 1.11 · DOE OpenNet and OSTI.GOV API

`HIGH` · tier **P1** · <https://www.osti.gov/opennet/>

*Serves:* documented evidence · engineering parameters · site infrastructure

**Holdings.** OpenNet: 485,000+ bibliographic references and 140,000 declassified DOE documents (declassified after Oct 1994, including FOIA releases). OSTI.GOV: 70+ years of DOE/AEC scientific and technical reports. Relevant threads: AEC-era protective construction and shelter research, weapons-complex site infrastructure, underground test containment engineering (directly transferable to buried-facility survivability), and NNSA site records.

**Access method.** REST API (OSTI) plus HTML search (OpenNet)

**Format returned.** PDF, mixed scanned and born-digital; bibliographic metadata as JSON/XML; MARC records available in bulk

**Search technique.** OSTI API: https://www.osti.gov/api/v1/records with ?rows={n}&page={n}, parameters url-escaped; docs at https://www.osti.gov/api/v1/docs. Sibling APIs exist at /pages/api/v1/docs (DOE PAGES), /doepatents/api/v1/docs, /dataexplorer/api/v1/docs, /etdeweb/api/v1/docs — each with its own corpus. OpenNet item URLs are deterministic: https://www.osti.gov/opennet/detail?osti-id={id}, so the id space can be walked directly. OpenNet records carry an Accession Number field which is the token needed to request a physical copy when no digital object exists. Report series worth targeting: TID-, UCRL- (Livermore), SC- (Sandia), LA- (Los Alamos), and the Nevada test-containment literature. Related: the Nevada National Security Site Nuclear Testing Archive (https://nnss.gov/nuclear-testing-archive/) holds the physical test records.

**Rate limits.** Not published for the v1 API; paginated at 20 records/page by default

**Robots / ToS posture.** Documented public API is the sanctioned path

**Notes.** OpenNet's coverage starts at Oct 1994 declassifications — earlier AEC declassifications are in NTRL and NARA RG 326/RG 434 instead. Do not mistake OpenNet for a complete DOE declassification record.

---

### 1.12 · DTIC technical reports mirrored on Internet Archive

`HIGH` · tier **P2** · <https://archive.org/details/DTIC_ADA369152>

*Serves:* documented evidence · OCR full text · recovery of withdrawn documents

**Holdings.** A large but INCOMPLETE community mirror of DTIC technical reports. Identifier convention DTIC_{AD}. Valuable chiefly for items DTIC has since withdrawn from public access, and for IA's OCR text layer.

**Access method.** Internet Archive scrape/metadata API

**Format returned.** PDF plus _djvu.txt OCR sidecar

**Search technique.** Scrape with q=identifier:DTIC_AD* to enumerate; cross-join the resulting AD list against your apps.dtic.mil crawl to find items present on IA but absent (withdrawn) from DTIC. Those deltas are disproportionately interesting.

**Rate limits.** Standard IA API behavior

**Robots / ToS posture.** Sanctioned public API

**Notes.** DoD has periodically pulled previously-public reports offline. IA copies of pulled reports are a documented, citable P1 record retrieved via a P2 channel — record both the AD number and the mirror.

---

### 1.13 · Federal Register API v1

`HIGH` · tier **P1** · <https://www.federalregister.gov/developers/documentation/api/v1>

*Serves:* open-signal inference · facility identification · property disposal · construction chronology

**Holdings.** Every Federal Register document 1994-present (and scanned back to 1936 via the FR/CFR archive on govinfo). For this beat: NEPA notices of intent and records of decision for federal construction, land withdrawals, real-property disposal notices, airspace and restricted-area designations that ring hardened sites, and agency relocation/COOP rulemakings.

**Access method.** Public REST API, keyless

**Format returned.** JSON, CSV, XML full text, PDF

**Search technique.** GET https://www.federalregister.gov/api/v1/documents.json with conditions[term], conditions[agencies][], conditions[type][] (RULE/PRORULE/NOTICE/PRESDOCU), conditions[publication_date][gte]/[lte]. Use fields[] to trim the payload — available values include agencies, agency_names, docket_ids, full_text_xml_url, raw_text_url, pdf_url, html_url, mods_url, start_page, end_page, topics, citation, document_number, significant. The raw_text_url and full_text_xml_url fields let you pull clean text without a second scrape. Work around the 2,000-result cap by iterating month-by-month. Productive terms: 'environmental impact statement' combined with agency=Department of the Army/Air Force; 'notice of realty action'; 'withdrawal of public lands'; 'restricted area' + 'special use airspace'; 'record of decision' + 'construction'.

**Rate limits.** No API key and no published rate limit for reasonable use; usage is logged and abuse is mitigated infrastructurally. Pagination is hard-capped at the first 2,000 results per query — you MUST slice queries by date or agency to enumerate exhaustively.

**Robots / ToS posture.** Explicitly keyless and public by design; the agency's stated position is that API keys would be an unnecessary barrier

**Notes.** The Federal Register is where a buried facility surfaces administratively even when nobody discusses it substantively — land withdrawals and airspace rules have to be published. Strong source for the 'inferred from open signals' bucket.

---

### 1.14 · Foreign Relations of the United States (FRUS), TEI XML on GitHub

`HIGH` · tier **P1** · <https://github.com/HistoryAtState/frus>

*Serves:* documented evidence · program codewords · construction chronology · decision provenance

**Holdings.** The official documentary record of US foreign policy, as complete TEI P5 XML volumes — one file per volume. Directly relevant volumes exist: FRUS 1964-68 vol X (National Security Policy) contains the JCS/McNamara exchanges on the Deep Underground Command Center, including the 19 Dec 1963 SecDef Decision/Guidance and the 7 Nov 1963 JCS draft memorandum on a National Deep Underground Command Post.

**Access method.** git clone — the entire corpus, no API, no rate limit, no scraping

**Format returned.** TEI P5 XML with schema (frus.odd), Schematron and RelaxNG in /schema

**Search technique.** git clone the repo and grep/XPath the volumes locally — this is by far the cheapest high-quality corpus on the beat. Volume files are at /volumes/frus{years}{vol}.xml, e.g. frus1964-68v10.xml. Web equivalents resolve as https://history.state.gov/historicaldocuments/{VOLUME_ID}/{ELEMENT_ID} (e.g. .../frus1964-68v10/d77), so you can construct citable public URLs from the XML IDs without ever fetching history.state.gov. TEI gives you structured persons, dates, classification markings and editorial footnotes for free. Developer resources at https://history.state.gov/developer; the org has further repositories at https://github.com/HistoryAtState.

**Rate limits.** None — clone once, pull for updates

**Robots / ToS posture.** Deliberately published as open government data under the Digital Government Strategy; explicitly intended for reuse

**Notes.** Best effort-to-value ratio of any source here: one git clone, no OCR, no rate limits, structured markup, and it contains the authoritative decision record for at least one major deep-underground program. Do this first.

---

### 1.15 · GAO reports and testimonies

`HIGH` · tier **P1** · <https://www.gao.gov/advanced-search>

*Serves:* documented evidence · cost/appropriations · facility identification · program status

**Holdings.** Audits and evaluations of federal programs. High-value threads for this beat: COOP/continuity readiness audits, DoD facility recapitalization and MilCon oversight, NNSA and DOE site infrastructure, and the recurring critique that agencies cannot account for their own real property. GAO reports routinely name facilities, costs and dates that agencies do not otherwise publish.

**Access method.** HTML search on gao.gov with per-product PDF; plus GovInfo GAOREPORTS collection for FY95-Sept 2008

**Format returned.** PDF and HTML; born-digital text for modern reports

**Search technique.** Two identifier eras and you need both. Modern: GAO-{2-digit FY}-{6-digit number}, URL https://www.gao.gov/products/gao-25-106000. Legacy (pre-2004): GAO/{DIVISION}-{yy}-{nnn}, where the division code is the filter that matters — NSIAD (National Security and International Affairs Division) is the Cold War defense-facility series, plus RCED, AIMD, and the Comptroller General B-{number} decisions. Search 'GAO/NSIAD' plus 'continuity', 'relocation', 'hardened', 'command center'. Via GovInfo: collection:gaoreports with the field-query language above, which is the machine-friendly route for FY95-2008.

**Rate limits.** Not published

**Robots / ToS posture.** Verify gao.gov/robots.txt; for bulk work prefer the GovInfo GAOREPORTS collection, which is API-served and sanctioned

**Notes.** Note the coverage seam: GovInfo's GAOREPORTS stops at September 2008 and gao.gov carries the modern set. A complete harvester needs both, joined on report number.

---

### 1.16 · governmentattic.org

`HIGH` · tier **P3** · <https://www.governmentattic.org/>

*Serves:* documented evidence · facility identification · property inventory

**Holdings.** FOIA releases of internal agency administrative material — organizational histories, facility inventories, internal manuals, telephone directories, property lists. Precisely the boring documentation that names facilities without discussing them. Example on-beat holding: CIA releasable RDP wrap-up summaries 1996-2016.

**Access method.** HTML index with direct PDF links

**Format returned.** PDF, scanned, OCR required

**Search technique.** Files sit at https://www.governmentattic.org/{N}docs/{descriptive-name}.pdf where {N} is a directory generation counter (observed up to 40+). The site has no real search — the productive approach is to harvest the topical index pages once and full-text index locally. Target: agency facility lists, real-property inventories, internal histories of engineering and logistics offices, and organizational directories, all of which enumerate installations by name.

**Rate limits.** Not published; small volunteer site

**Robots / ToS posture.** Check robots.txt; fetch politely and selectively

**Notes.** Punches well above its size for this specific register because it specializes in exactly the unglamorous administrative records that enumerate facilities. Worth a careful full mirror given its modest size.

---

### 1.17 · NARA cartographic branch — RG 373 aerial photography and original CORONA film

`HIGH` · tier **P1** · <https://www.archives.gov/research/cartographic/aerial-photography/satellite-photography>

*Serves:* construction chronology · geolocation · imagery corroboration

**Holdings.** Original CORONA/ARGON/LANYARD film and mission-related technical documentation; RG 373 Aerial Photographs 1935-1970 including domestic-flown coverage indexed in Special List 25, plus captured German (GX) and Japanese (JX) foreign coverage. Domestic USAF/DIA aerial coverage is the highest-resolution pre-1970 imagery of US facility construction that exists and is materially better than the satellite product for construction-phase detection.

**Access method.** Manual — in-person research at College Park; Special List 25 and can indexes consulted on site. Not machine-accessible.

**Format returned.** Film (original negatives and duplicate positives); paper indexes; some finding aids as PDF

**Search technique.** Domestic coverage is indexed by Special List 25 (SL25) — search the Catalog for SL25 and for the series 'Aerial Photographs, 1935-1970' under RG 373. Cans carrying an 'ON' identifier are original negatives held offsite at the Lenexa Federal Records Center and must be ordered through the Cartographic Research Room with about three business days' lead. Workflow that works: identify a construction window from a documentary source (appropriation, EIS, Corps history), then pull SL25 for that county and year rather than browsing imagery first.

**Rate limits.** N/A — physical

**Robots / ToS posture.** N/A

**Notes.** Honest limitation: this is a physical-visit source with no remote access path. Its correct role in an automated register is as a TARGETED follow-up generated by the pipeline — the database should be able to emit 'RG 373 SL25, county X, 1958-1962' as a research task, not attempt to ingest it.

---

### 1.18 · NARA Record Group Explorer and Guide to Federal Records

`HIGH` · tier **P1** · <https://www.archives.gov/findingaid/record-group-explorer>

*Serves:* finding-aid discovery · agency lineage · construction chronology

**Holdings.** Narrative agency histories, record-group scope notes, and per-RG statistics on what is digitized. The Guide to Federal Records (archives.gov/research/guide-fed-records/groups/{NNN}.html) gives agency lineage — which is the only reliable way to know which RG a given Cold War office's records actually landed in after successive reorganizations.

**Access method.** HTML scrape; stable, predictable URL structure

**Format returned.** HTML

**Search technique.** Deterministic URLs: https://www.archives.gov/research/guide-fed-records/groups/{RG}.html and https://www.archives.gov/findingaid/stat/discovery/{RG}. Harvest all RG pages once (there are ~500) and index the narrative text — this is a small, cheap, high-value corpus. Use it to resolve the reorganization chain that defeats keyword search: FCDA + ODM -> OCDM (1958, RG 304) -> Office of Emergency Planning (1961) -> Office of Emergency Preparedness (1968, RG 396) -> Federal Preparedness Agency (records in RG 269, GSA) and Defense Civil Preparedness Agency (RG 397) -> FEMA (RG 311, EO 12148, 1979). A researcher who searches only 'FEMA' or only 'civil defense' misses four of those.

**Rate limits.** None published

**Robots / ToS posture.** Check www.archives.gov/robots.txt; the guide pages are static reference content and low-risk at polite rates

**Notes.** Cheap to harvest, permanently useful, and it is the map that makes the Catalog API productive rather than a keyword lottery.

---

### 1.19 · National Technical Reports Library (NTRL / NTIS)

`HIGH` · tier **P1** · <https://ntrl.ntis.gov/NTRL/>

*Serves:* documented evidence · pre-1975 coverage gap · engineering parameters

**Holdings.** ~3M bibliographic records and 800,000+ digitized full-text federal technical reports, 1900-present, including ~195,000 brief records for pre-1964 material. Overlaps DTIC but is NOT a subset: NTRL holds many pre-1975 AD-numbered reports that never made it onto DTIC's public site, plus AEC/ERDA and civil-defense engineering reports.

**Access method.** HTML search interface; free and open-access since 1 Oct 2016 (previously subscription)

**Format returned.** PDF, mostly scanned, OCR required

**Search technique.** Search by the same AD numbers as DTIC, plus PB numbers (the NTIS civilian-agency accession series) and AEC/TID- and UCRL- series for Atomic Energy Commission protective-construction and shelter work. This is the correct place to resolve an AD number that DTIC returns as a dead link or that appears only as a citation in a bibliography.

**Rate limits.** Not published; JS-heavy interface, likely needs a headless browser

**Robots / ToS posture.** Verify ntrl.ntis.gov/robots.txt before harvesting; no crawler invitation equivalent to DTIC's sitemap is published

**Notes.** The main practical reason to use NTRL is the pre-1975 window, which is exactly the Cold War hardened-construction boom. Treat it as the fallback resolver in an AD-number pipeline: DTIC first, IA second, NTRL third.

---

### 1.20 · USACE Publications portal (Engineer Manuals, Regulations, Technical Manuals)

`HIGH` · tier **P1** · <https://www.publications.usace.army.mil/>

*Serves:* engineering parameters · design standards · construction chronology

**Holdings.** Current and superseded Engineer Manuals (EM), Engineer Regulations (ER), Engineer Technical Letters (ETL), and Technical Manuals. The EM 1110 series is the Corps' design canon; the protective-construction and blast-design guidance for hardened facilities lives here and in the joint-service TM 5-855 / UFC 3-340 lineage.

**Access method.** Static PDF hosting with predictable paths

**Format returned.** PDF, mostly born-digital for current editions; superseded editions often scanned

**Search technique.** Direct construction: https://www.publications.usace.army.mil/Portals/76/Publications/EngineerManuals/EM_{number}.pdf (path capitalization is inconsistent — both /Portals/76/Publications/EngineerManuals/ and /portals/76/publications/engineermanuals/ resolve). A parallel mirror with older editions sits at https://planning.erdc.dren.mil/toolbox/library/EMs/em{dotted.number}.pdf and .../ERs/. The documents that matter for this beat are the protective-design lineage rather than the civil-works EMs: TM 5-855-1 'Fundamentals of Protective Design for Conventional Weapons', TM 5-858 'Designing Facilities to Resist Nuclear Weapon Effects' (a multi-volume series specifically on hardened and buried facilities), and their modern replacement UFC 3-340-01/-02. Search DTIC and the Whole Building Design Guide for these rather than the USACE portal, which carries mainly current civil-works EMs.

**Rate limits.** Not published

**Robots / ToS posture.** Verify publications.usace.army.mil/robots.txt

**Notes.** Important correction to the obvious approach: searching the USACE publications portal for 'protective' mostly returns coatings and corrosion manuals. The hardened-design canon is TM 5-858 and TM 5-855, and those are found through DTIC AD numbers, not through this portal. Registered here so the harvester does not waste a crawl.

---

### 1.21 · Cold War C4I / FAS Nuclear Information Project / GlobalSecurity.org / Cryptome

`MODERATE` · tier **P4** · <https://coldwar-c4i.net/>

*Serves:* candidate generation · folklore backsourcing · citation chains

**Holdings.** Long-running enthusiast and analyst compilations on hardened command-and-control sites: coldwar-c4i.net has a dedicated DUCC section; FAS (nuke.fas.org/guide/usa/c3i/) carries the Mount Weather / High Point Special Facility profile; GlobalSecurity.org maintains facility pages; Cryptome hosts imagery 'eyeball' series and the DUNMCC document set.

**Access method.** HTML scrape of static legacy sites

**Format returned.** HTML with linked scanned PDFs and images

**Search technique.** Harvest these NOT as evidence but as CANDIDATE GENERATORS and as the citation graph. Their real value is that they frequently cite the underlying document, letting you jump straight to a DTIC AD number, a CIA ESDN, or a FRUS document ID. Extract outbound links and document identifiers, resolve each to its P1 original, and record the enthusiast page only as the discovery path. Where a claim has no resolvable citation, that absence is itself the finding.

**Rate limits.** Not published; several are unmaintained static sites

**Robots / ToS posture.** Check each individually; some are long-abandoned and fragile

**Notes.** This is the tier where the '400 websites, one source' problem lives. These four sites are among the actual ORIGINS of much repeated bunker material, so mapping which claims trace back to them — and whether they in turn cite anything — is core to the backsourcing mission. Grade the sites themselves P4; grade any document they host by its true origin.

---

### 1.22 · DoD Office of Inspector General FOIA Reading Room

`MODERATE` · tier **P1** · <https://www.dodig.mil/FOIA/FOIA-Reading-Room/>

*Serves:* documented evidence · program status · cost/appropriations

**Holdings.** DoD IG audits, evaluations and reports of investigation, including previously-released FOIA responses. Relevant threads: physical security and facility construction audits, classified-program oversight, MilCon execution.

**Access method.** HTML scrape with query-string search and pagination

**Format returned.** PDF, often born-digital text with redaction boxes

**Search technique.** The reading room takes GET params directly: https://www.dodig.mil/FOIA/FOIA-Reading-Room/?Search={terms} and ?Page={n}, so it is trivially enumerable — walk Page= to exhaustion with an empty search to get the full inventory, then filter locally rather than issuing many searches.

**Rate limits.** Not published

**Robots / ToS posture.** Verify dodig.mil/robots.txt

**Notes.** Small corpus relative to DTIC but cheap to mirror completely. Do the full walk once and re-sync monthly.

---

### 1.23 · NSA, DIA and DTRA FOIA electronic reading rooms

`MODERATE` · tier **P1** · <https://www.nsa.gov/Helpful-Links/NSA-FOIA/Reading-Room/>

*Serves:* documented evidence · program codewords

**Holdings.** Agency-specific FOIA releases. DTRA's is the most on-point for this register — DTRA is the successor to AFSWP/DASA/DNA/DSWA and therefore the custodian of the hardened-target and weapons-effects institutional record (https://www.dtra.mil/About/Mission/Freedom-of-Information-Act-and-Privacy-Act/FOIA-Reading-Room/). DIA's reading room (https://www.dia.mil/FOIA/FOIA-Electronic-Reading-Room/) matters mainly for imagery-derived assessments.

**Access method.** HTML scrape; each site is a separately-templated DoD CMS instance with its own pagination scheme

**Format returned.** PDF, scanned, OCR required

**Search technique.** These are small, hand-curated listings, not searchable corpora. Mirror each completely (hundreds to low thousands of items) and index locally; do not attempt query-driven access. DTRA first, by a wide margin, given the DASA/DNA lineage that connects to the DTIC report series above.

**Rate limits.** Not published

**Robots / ToS posture.** Each host needs its own robots.txt check — they are administered separately

**Notes.** Low yield per unit effort individually, but DTRA closes the loop on the DASA/DNA/DSWA report series and is worth the crawl.

---

### 1.24 · The Black Vault

`MODERATE` · tier **P3** · <https://www.theblackvault.com/documentarchive/>

*Serves:* documented evidence · FOIA case recovery · folklore backsourcing

**Holdings.** ~4 million pages of FOIA-obtained documents, privately maintained since 1996. Includes CIA CREST program documentation (the CREST manuals and procedures set is genuinely useful for understanding the ESDN scheme), OSD and CIA FOIA case files. Hosts documents at documents.theblackvault.com and documents2.theblackvault.com.

**Access method.** HTML category browse with direct PDF links

**Format returned.** PDF, scanned, OCR required

**Search technique.** Documents are addressable at https://documents.theblackvault.com/documents/{agency}/{case}.pdf and https://documents2.theblackvault.com/documents/{agency}/{file}.pdf. The FOIA case number embedded in the filename ({YY}-F-{NNNN} for DoD/OSD) is the join key back to the originating agency's own reading room — always attempt to resolve a Black Vault item to its official ESD/agency copy and cite that as the authority. Browse by category rather than searching.

**Rate limits.** Not published; privately funded — be conservative and do not mirror wholesale

**Robots / ToS posture.** Check theblackvault.com/robots.txt. This is one person's privately funded archive; heavy automated traffic imposes real cost. Fetch selectively.

**Notes.** Provenance discipline matters here. The site is heavily oriented toward UFO/fringe topics, which means it is simultaneously (a) a legitimate source of real FOIA releases and (b) a major amplification node for claims that get attached to bunker folklore. Both roles are useful to this register, but they must be graded differently: a hosted PDF of an official release is P1 content retrieved via P3; the site's own commentary is P3.

---

## Gaps for this beat — the expected-record raw material

*Every statement here becomes, or should become, a row in `registry.erp_profile`. A record
class that does not exist for a given authority, era or classification posture is **X0** and
produces **no row** — not a zero. This is what licenses the argument from silence in one case
and forbids it in another.*

WHAT THIS BEAT STRUCTURALLY CANNOT TELL US:

1. Current facility status. Everything on this beat is retrospective by construction — the 25-year declassification rule, the FOIA lag, the fact that DTIC only publishes distribution-unlimited material. Active hardened facilities are represented only by their absence, by ADB-tier citations, and by budget line items with redacted descriptions. No amount of archive work closes this; the register should say "no post-{year} documentary evidence" explicitly rather than implying continuity.

2. Precise geolocation. Almost nothing on this beat carries coordinates. Documents name facilities, describe engineering, and cite costs, but the geospatial join must come from other beats — USGS historical topographic quadrangles, FCC antenna registration, county parcel and deed records, NEPA EIS map figures, federal real-property disposal listings, and the declassified imagery in EarthExplorer. Declass imagery is the one geospatial asset ON this beat, and its georeferencing is approximate and frequently needs manual control points.

3. Anything never written down, and anything written down in records that were destroyed or remain classified. Records-retention schedules mean much routine facility documentation was legally destroyed. Silence in the archive is not evidence of absence and the register must not let a "no documents found" state harden into a negative claim.

SPECIFIC COVERAGE HOLES I COULD NOT CLOSE:

4. Pre-1994 congressional material. GovInfo's born-digital text starts around the 103rd Congress. The Cold War hardened-construction debates — the exact hearings where these facilities were funded — sit in the pre-1994 Serial Set, bound Congressional Record, and committee prints, which are scanned-only and unevenly digitized. HathiTrust, the Law Library of Congress, and ProQuest Congressional (PAYWALLED, institutional subscription only) hold the fuller record. This is the single biggest gap on the beat and it is a paywall/OCR problem, not a secrecy problem. Needs: a HathiTrust full-text search strategy and an assessment of what the free GovInfo Serial Set digitization actually covers.

5. NARA's 96% undigitized bulk. Only ~3.9% of NARA's textual holdings are scanned. RG 77, RG 374 and RG 397 are where the construction record actually lives and they are overwhelmingly paper at College Park. The Catalog API can identify the boxes; it cannot deliver them. Needs: a physical research trip, or a targeted digitization-on-demand request program, and the register should be able to emit "series-level description exists, contents unexamined" as a grade.

6. RG 373 domestic aerial photography. Entirely manual — Special List 25, paper indexes, three-day retrieval from Lenexa for original negatives. No remote access path exists. This is the best pre-1970 construction-phase imagery available and it is unreachable by any harvester.

7. CIA CREST robots.txt and true search-parameter surface. I could not fetch cia.gov at all. The facet parameters I recovered (im_field_collection, dm_field_release_date, ds_field_pub_date) came from a single live advanced-search URL surfaced in search results; the full facet vocabulary, the numeric collection term IDs, and the ~90 content-type values remain unmapped. Needs: fetch robots.txt, then read the facet block hrefs on any result page to enumerate the real field list before writing a scraper.

8. DTIC's actual search API. DTIC runs on MarkLogic and the public interface is JS-driven; I found no documented public JSON API, only the sitemap invitation and deterministic per-document URLs. Whether a queryable endpoint exists behind the UI is unresolved. Needs: inspect network traffic on discover.dtic.mil to determine whether search can be driven directly, otherwise fall back to sitemap-crawl-plus-local-index.

9. NARA Catalog API v2 full field vocabulary. I confirmed ancestorNaId, levelOfDescription and geographicReference but the complete searchable field list lives only in the OpenAPI spec at /api/v2/api-docs, which I could not reach. Whether record group can be filtered directly (vs. only via ancestorNaId) is unresolved and materially affects harvester design. Needs: pull the OpenAPI spec on a machine with .gov egress.

10. Whether the Internet Archive CREST mirror is COMPLETE. I confirmed the identifier conventions and that two distinct upload generations exist, but not the item count against CIA's ~930,000. If the mirror is partial, the origin site is still required for the delta. Needs: a total_only scrape call against each identifier pattern, compared to the CREST document-type page count.

11. Rate limits and robots posture for nearly every source. Unverifiable from this environment. Treat every "not published" above as "unknown, must check," not as "unlimited."

12. Not covered on this beat by design, and needed for a complete register: FCC antenna structure registration, USGS historical topographic quadrangles, EPA/agency NEPA EIS databases, GSA and federal real-property disposal records, state and county deed/parcel records, and USASpending/FPDS contract data. Several of these are the ONLY route to the geolocation gap in (2) above, so the beats must be joined on facility identity, not treated as independent."


# BEAT 2 — GEOSPATIAL, CARTOGRAPHIC AND GEOLOGICAL

**Beat as scoped:** Geospatial, cartographic, and geological sources — corpora that reveal or corroborate subsurface and hardened construction in the United States

**Primary agent:** CARTOGRAPHER · **26 sources**

## Access notes for this beat

SANDBOX CAVEAT, STATED HONESTLY UP FRONT. This session's egress proxy returned 403 CONNECT for almost every relevant host: ngmdb.usgs.gov, www.usgs.gov, mrdata.usgs.gov, sciencebase.gov, tnmaccess.nationalmap.gov, apps.nationalmap.gov, earthexplorer.usgs.gov, m2m.cr.usgs.gov, rockyweb.usgs.gov, msha.gov, data.msha.gov, faa.gov, nfdc.faa.gov, nps.gov, npgallery.nps.gov, catalog.data.gov, and all *.arcgis.com. Two hosts WERE reachable and I used them hard: prd-tnm.s3.amazonaws.com and usgs-lidar-public.s3.amazonaws.com. Every fact I labelled VERIFIED was obtained by actually downloading and parsing the file in this session on 2026-08-16. Everything else is from web search plus prior knowledge and carries the normal risk of drift. Treat the S3-derived material as ground truth and re-verify the rest on first harvester run.

THE STRATEGIC POINT ABOUT prd-tnm. Most tutorials and most existing tooling point at nationalmap.gov, ngmdb.usgs.gov, or rockyweb.usgs.gov. All of those are front doors. The actual bytes live in a plain, unauthenticated, unthrottled S3 bucket at prd-tnm.s3.amazonaws.com, which serves standard list-objects-v2 XML and supports HTTP Range requests. This is the single most useful operational fact on the beat. It means the entire 186,061-sheet historical topographic archive, the entire 3DEP staging tree, the lidar coverage index, and the per-quad vector geopackages are harvestable with curl and no credentials. WESM's lpc_link and sourcedem_link columns point at rockyweb.usgs.gov/vdelivery/Datasets/Staged/... — rewrite that prefix to prd-tnm.s3.amazonaws.com/StagedProducts/ and the same objects come back, faster.

THE BOOTSTRAP SEQUENCE, in order, for a harvester written tomorrow.
1. Pull StagedProducts/MapIndices/National/GPKG/MapIndices_National_GPKG.zip. This is the quadrangle grid and the join key for everything else.
2. Pull StagedProducts/Maps/Metadata/historicaltopo.zip nightly, COPY the CSV into PostGIS with geom_wkt as geometry(Polygon,4326), GIST-index it. You now have the full temporal map stack for any point in the country as a single ST_Contains query. 186,061 rows, 185 MB, four minutes of work.
3. Pull StagedProducts/Elevation/metadata/WESM.gpkg. Now every candidate can be immediately answered for "does high-resolution lidar exist here, at what quality level, from what year".
4. Pull USMIN from mrdata (state shapefiles or the ArcGIS FeatureServer mirror). Now every mapped adit and shaft in 35 states is a queryable point.
5. Pull MSHA Mines.txt weekly and MRDS rdbms-tab-all.zip monthly.
6. Register for an ERS account and submit the M2M access request immediately — approval takes 24 to 48 business hours and it gates all declassified satellite and historical aerial imagery. Do this on day one so it is not a blocker on day thirty.
Steps 1 through 3 require no credentials at all and take under an hour.

THE CORE ANALYTICAL PATTERN, which is what actually makes this beat productive. For any candidate coordinate, run five queries and record all five results including the nulls, because the nulls are evidence too:
(a) HTMC temporal stack — every sheet covering the point, ordered by date, with photo_revision_year. VERIFIED example: Cheyenne Mountain NORAD returns 34 sheets from 1893 to 1989, including 1948 and 1949 sheets that predate excavation and nine 1961-base sheets photorevised in 1969, 1975 and 1988. You get the before, the during and the after, free, in seconds.
(b) WESM lidar availability and quality level, then either the 1 m DEM or a PDAL readers.ept pull from usgs-lidar-public for a 0.5 m bare-earth surface.
(c) USMIN, MRDS, MSHA and e-AMLIS spatial joins for any recorded subsurface working.
(d) FAA special-use airspace intersection, filtered to small, surface-based, continuous restrictions.
(e) NRHP intersection, and if a listing exists, the nomination PDF, which is often the richest single document about a decommissioned hardened site that exists outside FOIA.

THE STRONGEST EVIDENCE CONSTRUCTIONS THIS BEAT SUPPORTS.
1. Cartographic omission against contemporaneous photography. Every HTMC row carries aerial_photo_year and photo_revision_year — the year of the imagery the cartographer worked from. If the photography exists in the EROS Aerial Photo Single Frames archive, and the photograph shows construction the quad does not draw, that is documented suppression rather than mere absence. This is a defensible, citable, reproducible finding, and it is the kind of thing that should raise a candidate's grade.
2. Spoil volume. A muck pile is the excavated volume turned inside out. Difference a lidar bare-earth surface against a reconstructed pre-construction surface (or against terrain digitised from the pre-construction quad's contours) and you get a lower bound on excavated volume that no press release can argue with. This is arguably the single most valuable quantitative product available on the whole beat.
3. Adit without a mine record. A USMIN adit or air-shaft symbol with no corresponding MRDS deposit, no MSHA mine ID and no e-AMLIS problem area means USGS cartographers drew a portal that no mining regulator ever recorded. That is a genuine anomaly and a legitimate candidate origin.
4. Reverse-sourcing folklore through GNIS. A claim that names a place can be tested: does the toponym exist in the federal gazetteer, on which quadrangle, in what feature class? A name that appears on 400 websites and in zero gazetteers almost always traces to one text.

DISCIPLINE ON RATE LIMITS AND TERMS. prd-tnm and usgs-lidar-public are AWS Open Data and impose no limits — keep parallelism to 4 to 8 anyway and cache by ETag. TNM Access, ArcGIS FeatureServers and OGC WFS should be paged at 1,000 features with concurrency of 2 to 4. OpenTopography is the one genuinely hard cap: 50 calls per 24 hours for non-academic users, so it can never be a backbone. HistoricAerials is commercial with terms prohibiting automated access — do not scrape it; its topo layer is the HTMC corpus we already have in full. Academic archives (UCSB, Penn State, Cornell) should be approached at one request per second with an identifying User-Agent, and via OAI-PMH or IIIF where offered rather than HTML scraping.

CRS AND FORMAT GOTCHAS THAT WILL BITE.
HTMC GeoTIFFs are NAD27 Polyconic (VERIFIED from GeoKeys: GeographicTypeGeoKey 4267, ProjCoordTransGeoKey 22). NAD27-to-WGS84 shifts run 50 to 100 metres in the western US, which is larger than most features of interest. Reproject before overlaying anything modern, and never compare an HTMC coordinate to a modern one without doing so.
HTMC GeoTIFFs are JPEG-compressed inside a tiled TIFF (Compression=7, YCbCr, 512x512 tiles, with internal overviews) — effectively COGs, so GDAL /vsicurl/ subwindow reads work and you do not need to pull 8.5 MB to look at one hillside. But JPEG is lossy, so do not do fine radiometric analysis on them; use the GeoPDF for anything where line fidelity matters.
Scan resolution is exactly 300 dpi (VERIFIED: 2.032 m ModelPixelScale at 1:24,000). At 300 dpi a 1:24,000 sheet resolves roughly 2 m per pixel on the ground, which is fine for symbols and useless for fine texture.
EPT bounds in usgs-lidar-public are EPSG:3857, not WGS84 — reproject candidate coordinates before setting PDAL bounds.
The metadata_url pattern substitutes underscores for spaces while product_url percent-encodes them; construct neither, read both from the CSV.
S3 list-objects-v2 truncates at 1,000 keys — usgs-lidar-public has more than 1,000 project prefixes, so you must follow NextContinuationToken or you will silently enumerate only part of the archive.

## High-yield query strings for this beat

- `curl -s 'https://prd-tnm.s3.amazonaws.com/?list-type=2&delimiter=/&prefix=StagedProducts/' — enumerate the whole USGS bulk tree with no credentials`
- curl -O https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/Metadata/historicaltopo.zip — 17.5 MB, nightly, 186,061 rows, every HTMC sheet with WKT geometry and direct GeoTIFF/GeoPDF URLs
- SELECT * FROM htmc WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint(:lon,:lat),4326)) ORDER BY date_on_map — returns the full temporal map stack for any US coordinate; verified 34 sheets, 1893-1989, over the Cheyenne Mountain portal
- `SELECT * FROM htmc WHERE publishers LIKE '%MIL%' OR publishers LIKE '%WarDept%' OR publishers LIKE '%AMS%' — 9,579 military-lineage sheets out of 186,061`
- SELECT * FROM htmc WHERE photo_revision_year IS NOT NULL AND photo_revision_year::int - date_on_map::int > 5 — sheets whose purple photorevision overprint colour-codes exactly what appeared between two dates
- `SELECT * FROM htmc WHERE variations LIKE '%Planimetric%' — 2,925 contourless sheets, disproportionately engineering and military products`
- curl -O https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/metadata/WESM.csv — 3,269 lidar work units with quality level, collection dates and staging links; WESM.gpkg for footprints
- SELECT workunit, ql, collect_start, lpc_link FROM wesm WHERE ST_Intersects(geom, :aoi) AND ql IN ('QL 0','QL 1','QL 2') — is there sub-metre lidar over this candidate, and from what year
- PDAL pipeline: readers.ept on https://usgs-lidar-public.s3.amazonaws.com/{PROJECT}/ept.json with bounds in EPSG:3857, then filters.range Classification[2:2], then writers.gdal output_type=idw resolution=0.5 — bare-earth DTM for one site without downloading a tile
- PDAL: same reader, filters.range Classification[7:7] and Classification[18:18] — the discarded 'noise' class, where lidar returns fired down an open portal door survive
- gdalinfo /vsicurl/https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/HistoricalTopo/GeoTIFF/CO/CO_Cheyenne%20Mountain_450177_1961_24000_geo.tif — tiled JPEG-in-TIFF with overviews, NAD27 Polyconic, 2.032 m/px; range-readable
- `gdal_translate -projwin with /vsicurl/ on an HTMC GeoTIFF — crop one hillside out of an 8.5 MB sheet over HTTP`
- USMIN: SELECT * WHERE Ftr_Type IN ('Adit','Air Shaft','Mine Shaft') AND Ftr_Name ~* '(Tunnel|Portal|Cave)' — mapped subsurface openings whose printed label is not a mine name
- `USMIN LEFT JOIN MSHA LEFT JOIN MRDS ON ST_DWithin(...) WHERE mine_id IS NULL AND mrds_id IS NULL — portals USGS drew that no mining regulator ever recorded`
- MSHA Mines.txt: WHERE MINE_TYPE='Underground' AND CURRENT_MINE_STATUS IN ('Abandoned','Abandoned and Sealed','NonProducing') — sealed underground workings with coordinates
- MSHA Mines.txt: WHERE CONTROLLER_NAME ~* '(records|storage|data cent|vault|archive|defense|federal)' — the small set of genuinely repurposed mines, under their real operator names
- e-AMLIS / state ArcGIS: WHERE PROBLEM_TYPE IN ('Portal','Vertical Opening','Dangerous Highwall','Subsidence','Underground Mine Fire') — federally funded closures prove a physical opening existed
- https://{state-arcgis-host}/arcgis/rest/services?f=pjson — enumerate every service a state geological survey publishes; fastest way to discover a state's real geospatial holdings
- FAA SUA FeatureServer: WHERE lower altitude limit = 'SFC' AND ST_Area(geom) < :small AND time_of_use = 'continuous' — tight, low, always-on restrictions over unremarkable terrain, filtered clear of the large well-known training ranges
- M2M POST /login-token then /dataset-search then /scene-search with spatialFilter type=mbr — the only supported programmatic path to Declass I/II/III (CORONA, GAMBIT, HEXAGON) and the 6.5M-frame Aerial Photo Single Frames archive
- npgallery.nps.gov/nrhp full-text: "blast door" | "emergency operating center" | "shock isolation" | "hardened" | "underground operations" — NRHP nominations carry construction detail otherwise only reachable by FOIA
- GNIS Domestic Names: WHERE FEATURE_CLASS IN ('Mine','Tunnel','Cave') — and the inverse test, checking whether a folklore toponym exists in the federal gazetteer at all
- NARA Special List 25, by state then degree square, resolving to spot number then RG 373 can locator via carto@nara.gov — the only route into 30M frames of 1935-1970 domestic-flown DIA photography
- Relief Visualization Toolbox: Sky-View Factor, Simple Local Relief Model, Negative Openness, Local Dominance over a 0.5 m bare-earth DTM — portal notches, muck piles, cut-and-fill benches and igloo fields that plain hillshade misses

## Sources

### 2.1 · USGS 3DEP DEM rasters (1 m, 1/3 arc-second, 1 arc-second, DSM, OPR)

`CRITICAL` · tier **P1** · <https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/>

*Serves:* terrain analysis without point-cloud processing · change detection between DEM editions · first-pass triage where lidar is absent

**Holdings.** VERIFIED LIVE prefixes: /1m/Projects/ (per-project 1 m bare-earth GeoTIFF, e.g. AL_25Co_B1_2017, CO_CentralWestern_2019_D19), /13/TIFF/current/{nXXwYYY}/ and /13/TIFF/historical/ (1/3 arc-second ~10 m seamless, one directory per 1-degree cell, with a historical/ tree that preserves superseded editions), /1/ (1 arc-second ~30 m), /19/ (1/9 arc-second ~3 m), /2/ (2 m, Alaska), /OPR/ (Original Product Resolution source DEMs), /DSM/ (first-return digital surface models), /ORI/ (Alaska IFSAR orthorectified radar intensity), /S1M/, /AK_ifsar_breaklines/, /Non_Standard_Contributed/, /tiling_scheme/, /Contours/.

**Access method.** Anonymous HTTPS; GeoTIFFs are Cloud-Optimized, so /vsicurl/ subwindow reads work.

**Format returned.** Cloud-Optimized GeoTIFF, float32 elevation, plus FGDC XML.

**Search technique.** The /13/TIFF/historical/ tree is the underexploited one: it preserves superseded editions of the seamless 10 m DEM, which means you can difference the same 1-degree cell across production epochs and see where the underlying source data changed — often because a new lidar acquisition replaced legacy contour-derived elevations, which is itself a signal that fine-resolution data now exists there. The /DSM/ tree matters because DSM minus DTM isolates above-ground structure, and a hardened site's above-ground signature is frequently just a few small blockhouses and vent stacks that get lost in a plain hillshade.

**Rate limits.** None observed.

**Robots / ToS posture.** Public domain bulk channel.

**Notes.** 1/3 arc-second is roughly 10 m and will NOT resolve a portal. Use it only to build a slope/aspect context layer and to identify candidate ridgelines. Anything below about 2 m of feature size requires the 1 m tree or the point cloud.

---

### 2.2 · USGS 3DEP lidar on AWS as Entwine Point Tiles (usgs-lidar-public)

`CRITICAL` · tier **P1** · <https://usgs-lidar-public.s3.amazonaws.com/>

*Serves:* arbitrary-AOI point extraction without bulk download · fast candidate triage at continental scale

**Holdings.** VERIFIED LIVE. Over 1,000 3DEP projects republished as EPT (Entwine Point Tile) octrees, one prefix per project, e.g. CO_DRCOG_1_2020/, CO_CentralEasternPlains_1_2020/, AK_EMRI_1_D24/. VERIFIED contents of a project: ept.json, ept-build.json, ept-data/, ept-hierarchy/, ept-sources/, info/. VERIFIED ept.json for CO_DRCOG_1_2020: 19,912,349,351 points, dataType laszip, bounds in EPSG:3857, full LAS attribute schema (X/Y/Z with 0.001 scale, Intensity, ReturnNumber, NumberOfReturns, ScanDirectionFlag, EdgeOfFlightLine, Classification, ScanAngleRank, UserData, PointSourceId, GpsTime).

**Access method.** Anonymous HTTPS, AWS Open Data Registry. Read directly with PDAL readers.ept, which performs HTTP range reads over the octree and returns only the points inside your requested bounds.

**Format returned.** EPT octree of laszip chunks; JSON hierarchy.

**Search technique.** This is the correct way to pull lidar for a single candidate site. A PDAL pipeline of {type: readers.ept, filename: https://usgs-lidar-public.s3.amazonaws.com/{PROJECT}/ept.json, bounds: ([xmin,xmax],[ymin,ymax]) in EPSG:3857} followed by filters.range (Classification[2:2]) and writers.gdal (output_type=idw, resolution=0.5) produces a bare-earth DTM tile for one site in seconds. Then run a second pass WITHOUT the class filter, and a third selecting Classification 7 and 18 only, to look for the below-surface portal returns described above. Bounds are Web Mercator — reproject your WGS84 candidate coordinates first. Project names largely mirror, but do not exactly equal, the WESM workunit names (WESM has CO_DRCOG_1_2020 style too, but numbering suffixes differ), so fuzzy-match rather than assuming a key.

**Rate limits.** None. Requester does not pay.

**Robots / ToS posture.** AWS Open Data Registry, explicitly free and unrestricted for any use.

**Notes.** Enumerate projects with GET /?list-type=2&delimiter=/ and page the continuation token; the bucket has more than 1,000 project prefixes so the first page truncates. There is no boundaries/resources.geojson at the bucket root (VERIFIED 404) despite what older tutorials claim — use WESM.gpkg for footprints and match by name.

---

### 2.3 · USGS 3DEP Lidar Point Cloud (LPC) — bulk LAZ staging

`CRITICAL` · tier **P1** · <https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/LPC/Projects/>

*Serves:* bare-earth microtopography · excavation and spoil volumetrics · portal and vent detection under canopy · construction-era earthwork surviving under vegetation

**Holdings.** VERIFIED LIVE. Per-project directories of tiled LAZ, named USGS_LPC_{ST}_{ProjectName}_{Year}_{TileID}_LAS_{PubYear}.zip, organised under Projects/{PROJECT}/las/tiled/ with a metadata/ sibling. Project naming carries state, area and a collection code, e.g. CO_CentralWestern_2019_D19, AZ_Coconino_2019_B19, AK_Prince_of_Wales_Island_QL1_Lidar_2017_B17. A flat manifest of every published zip lives at StagedProducts/Elevation/LPC/prd_lpc_zips.txt (VERIFIED — a newline-delimited list of ./Projects/... relative paths). Tile IDs are UTM-derived MGRS-style strings (e.g. 15SWA574002).

**Access method.** Anonymous HTTPS. Range requests supported. No auth, no key.

**Format returned.** LAZ (LASzip) inside per-tile ZIP; ASPRS LAS 1.4 classification. Metadata as FGDC XML plus project-level report PDFs.

**Search technique.** Do not walk the bucket. Fetch prd_lpc_zips.txt once, parse it into a table of project + tile, and join against WESM (below) for the project footprint and collection date. For an arbitrary AOI, the cheaper route is the AWS Entwine endpoint (separate entry) which supports bbox extraction without downloading tiles.

**Rate limits.** None observed.

**Robots / ToS posture.** USGS bulk-delivery bucket, intended for scripted access. Public domain.

**Notes.** WHAT A HARDENED FACILITY LOOKS LIKE IN A POINT CLOUD. Work from the ground-classified (class 2) returns rasterised to a 0.5–1 m bare-earth DTM, then run the archaeological visualisation stack rather than plain hillshade: Sky-View Factor, Simple Local Relief Model, Positive and Negative Openness, Local Dominance, and multi-azimuth hillshade blends (the Relief Visualization Toolbox implements all of these). Specific signatures: (1) PORTAL NOTCH — a sharp rectangular or arched re-entrant cut into a slope, 4–12 m wide, with a flat apron in front; negative openness lights these up far better than hillshade. (2) MUCK / SPOIL PILE — a lobate or fan-shaped mound of unnatural convexity immediately downslope or downvalley of the notch, with a distinctly steeper repose angle than the surrounding hillside; its volume, differenced against a reconstructed pre-construction surface, gives a defensible lower bound on excavated volume, which is the single strongest quantitative inference this beat can produce. (3) CUT-AND-FILL BENCHES — perfectly horizontal terraces on a graded slope, with straight edges and constant-gradient access ramps; nature does not produce straight lines at constant grade. (4) IGLOO FIELDS — rows of parallel earth-covered arch magazines, each roughly 5–10 m wide and 1–4 m tall, at rigidly uniform spacing along access roads; unmistakable in SLRM. (5) BLAST BERMS AND REVETMENTS — U-, L- or horseshoe-shaped earth walls of uniform height enclosing a flat pad. (6) VENT AND ESCAPE SHAFTS — small isolated rectangular or circular pads or collars, often 3–8 m across, on ridgelines with no road connection, sometimes with a faint foot trail. (7) SUBSIDENCE — circular or elongate closed depressions over a known working, indicating collapse. (8) SENSOR ARTIFACT AS SIGNAL — if a portal door was open at flight time, the scanner will have shot returns down the tunnel, producing a cluster of points several metres BELOW the local ground surface. Vendors usually reclassify these as class 7 (low noise) or class 18 (high noise) and processors usually discard them; DO NOT discard them. Query the raw LAZ for class 7/18 and for ground-class holes with anomalous minimum Z, and treat a coherent below-surface point train with a consistent bearing as a positive indication of an open subsurface void. Similarly, a hole in the ground class where the DSM shows a solid face is often a portal shadow. (9) Compare DSM minus DTM to find structures under canopy that no aerial image will ever show.

---

### 2.4 · USGS 3DEP WESM — Work unit Extent Spatial Metadata (lidar availability index)

`CRITICAL` · tier **P1** · <https://prd-tnm.s3.amazonaws.com/StagedProducts/Elevation/metadata/WESM.csv>

*Serves:* does high-resolution lidar exist over this candidate, at what density, and in what year

**Holdings.** VERIFIED LIVE, downloaded and parsed. 3,269 lidar work units with quality level, collection start and end dates, projection, GSD, geoid, publication dates and direct links to LPC and source-DEM staging. Verified quality-level distribution: QL 0 = 9, QL 1 = 770, QL 2 = 1,161, QL 3 = 240, QL 5 = 432, Other = 657. Verified collection-year distribution runs from legacy (2000) through 2025, peaking 2016–2019 (215/277/395/313 work units). Companion WESM.gpkg at the same prefix carries the polygon footprints.

**Access method.** Anonymous HTTPS GET, ~2.2 MB CSV / GeoPackage. Rewritten almost daily.

**Format returned.** CSV and OGC GeoPackage (SQLite). VERIFIED column list: workunit, workunit_id, project, project_id, collect_start, collect_end, ql, spec, p_method, dem_gsd_meters, horiz_crs, vert_crs, geoid, lpc_pub_date, lpc_update, lpc_category, lpc_reason, sourcedem_pub_date, sourcedem_update, sourcedem_category, sourcedem_reason, onemeter_category, onemeter_reason, seamless_category, seamless_reason, lpc_link, sourcedem_link, metadata_link.

**Search technique.** Load WESM.gpkg into PostGIS and make it the first join in every candidate workflow: given a candidate point, ST_Intersects against WESM gives you QL, collection dates and the exact staging URL in one query. Filter to ql IN ('QL 0','QL 1','QL 2') for anything where you need sub-metre earthwork detection — QL2 is 2 pts/m², QL1 is 8, QL0 is 8+ with tighter vertical accuracy. collect_start/collect_end matter enormously for change detection: where two work units overlap in space and differ in year, you have a lidar-to-lidar difference surface, which detects new excavation and spoil placement directly.

**Rate limits.** None. It's a 2 MB file; cache it daily.

**Robots / ToS posture.** Public bulk file, no restriction.

**Notes.** Note that lpc_link and sourcedem_link point at rockyweb.usgs.gov/vdelivery/Datasets/Staged/... which is the same tree mirrored on prd-tnm — rewrite the host to prd-tnm.s3.amazonaws.com/StagedProducts/... if rockyweb is slow or blocked (it is blocked from this sandbox; prd-tnm is not). Companion indices, all VERIFIED to exist: StagedProducts/Elevation/LPC/FullExtentSpatialMetadata/LPC_TESM.gpkg (tile-level extents), StagedProducts/Elevation/1m/FullExtentSpatialMetadata/FESM_1m.gpkg and 10_km_cell_grid.gpkg, StagedProducts/Elevation/FullExtentSpatialMetadata/FESM_DSM_Proj.gpkg and FESM_DSM_Tile.gpkg (I opened FESM_DSM_Proj.gpkg: 286 features in table FEProj3189, EPSG:4269, columns project_id, s_date, e_date, refsys, horizres, horizres_m, pmethod, zunit, entry_date, format, pts_id — mostly Alaska IFSAR 5 m).

---

### 2.5 · USGS EarthExplorer + M2M machine-to-machine API — declassified satellite imagery (Declass I / II / III)

`CRITICAL` · tier **P1** · <https://m2m.cr.usgs.gov/>

*Serves:* construction-phase imagery of sites that had no aerial coverage otherwise · 1960s–1980s change detection · corroboration or refutation of claimed construction dates

**Holdings.** Declass 1: CORONA KH-1 through KH-4B, ARGON and LANYARD, 1960–1972, declassified under EO 12951 (1995); KH-4B panoramic resolution around 1.8 m. Declass 2: KH-7 GAMBIT (1963–1967, roughly 0.6–1.2 m) and KH-9 HEXAGON mapping camera (1973–1980, roughly 6–9 m), declassified 2002. Declass 3: the USGS subset of KH-9 HEXAGON, 1971–1984 — approximately 14,000 rolls and over 670,000 scenes transferred to EROS in 2019; panoramic cameras at roughly 0.3–2 m, mapping camera at 5–8 m. Also in the same archive: Aerial Photo Single Frames (over 6.5 million frames, 1937–present, federal acquisitions), NHAP (National High Altitude Photography, 1980–1989), NAPP (National Aerial Photography Program, 1987–2007), NAIP, and high-resolution orthoimagery.

**Access method.** Interactive: EarthExplorer web UI (free ERS account). Programmatic: M2M RESTful JSON API at https://m2m.cr.usgs.gov/api/api/json/stable/{endpoint}. Requires an ERS account PLUS a separately approved M2M access request submitted from the ERS profile — reviewed in 24 to 48 business hours. Not instant, and worth requesting on day one of the project.

**Format returned.** Scanned film as TIFF; declassified frames delivered as large single-band greyscale TIFFs, generally NOT georeferenced — you get frame centre coordinates and corner estimates, and you must warp them yourself against ground control.

**Search technique.** M2M call sequence: POST /login-token (or /login with app token) to get an X-Auth-Token header, then POST /dataset-search to resolve the datasetAlias, then POST /scene-search with a spatialFilter of type mbr and lowerLeft/upperRight lat-lng, an acquisitionFilter with start/end dates, and maxResults with paging via startingNumber; then /download-options, /download-request, and /download-retrieve to get signed URLs usable with curl or wget. Always resolve datasetAlias dynamically via /dataset-search rather than hard-coding it — USGS changes alias strings between releases. Use /dataset-filters to discover the per-dataset metadata fields (mission, camera, roll, frame) that you can then constrain with metadataFilter. For declassified imagery the fields that matter are mission number, camera type (panoramic vs mapping vs stellar/terrain), and frame number — CORONA frames come in forward/aft stereo pairs, and the pair is what lets you do photogrammetric height extraction of spoil piles and construction with the Ames Stereo Pipeline (the uw-cryo/declass_stereo repository on GitHub documents a working pipeline for exactly this).

**Rate limits.** M2M imposes per-account concurrency limits and download-queue throttling; not publicly numeric. Downloads of full-resolution declassified frames are hundreds of megabytes each.

**Robots / ToS posture.** Formal API with a registration and approval gate; scraping the EarthExplorer web UI instead of using M2M is against the spirit and probably the letter of the terms. Use M2M.

**Notes.** WHAT A HARDENED FACILITY LOOKS LIKE IN DECLASSIFIED OVERHEAD. Construction phases are far more legible than the finished site: cleared and graded staging areas, a spoil dump growing frame-to-frame between missions, batch plants, a spur rail line or heavy-haul road built to a hillside and later removed, and crane and derrick shadows. Finished hardened sites show: double-fenced perimeters with a graded patrol road between the fences, a single controlled entry point with a vehicle inspection apron, isolated ventilation and exhaust structures displaced hundreds of metres from the main portal (the vent house is often the only above-ground giveaway), cooling towers or heat-rejection equipment disproportionate to the visible building footprint, large isolated antenna fields, and helipads. The single most reliable indicator across all these sources is DISPROPORTION — utility, cooling, security and access infrastructure sized far beyond anything the visible buildings could require. CORONA's forward and aft panoramic cameras give convergent stereo, so a spoil pile's volume can be measured photogrammetrically from 1960s imagery.

---

### 2.6 · USGS EROS Aerial Photo Single Frames

`CRITICAL` · tier **P1** · <https://www.usgs.gov/centers/eros/science/usgs-eros-archive-aerial-photography-aerial-photo-single-frames>

*Serves:* pre-construction baseline · construction-period documentation · US coverage in decades with no satellite imagery

**Holdings.** Over 6.5 million frames of federally acquired aerial photography, 1937 to present, black-and-white, natural colour and colour infrared, covering the United States. Includes USGS, USDA, USFS, BLM, TVA and Corps of Engineers acquisitions.

**Access method.** EarthExplorer / M2M (same auth path as declassified). Some frames are already scanned and instantly downloadable; others exist only as film and must be scan-on-demand ordered (fee).

**Format returned.** TIFF. Medium resolution = 63 micron / 400 dpi scans; high resolution = 25 micron / 1,000 dpi scans from digital scanning backs. Not georeferenced — frame centre coordinates only.

**Search technique.** Search by point with a small mbr and no date constraint first, to inventory every frame that covers a candidate; then sort by acquisition date to build the temporal stack. Cross-reference against the HTMC sheet's aerial_photo_year field — USGS drew the quad from specific photography, and if you can find that photography in this archive you can see what the cartographer chose not to draw. That comparison is one of the strongest evidence constructions available on this beat: map omission plus photographic presence is documentable suppression, not speculation.

**Rate limits.** Same as M2M. Scan-on-demand orders are paid and take weeks.

**Robots / ToS posture.** Use M2M rather than scraping.

**Notes.** The 1:20,000 and 1:24,000 USDA/USGS frames from the 1930s–1950s are the pre-Cold-War baseline. Anything that appears between a 1940s frame and a 1960s frame on an otherwise empty hillside is worth a candidate record.

---

### 2.7 · USGS Historical Topographic Map Collection (HTMC) — bulk staging on prd-tnm S3

`CRITICAL` · tier **P1** · <https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/HistoricalTopo/>

*Serves:* temporal differencing of surface construction · direct depiction of adits, shafts, tunnels, and portals · pre-classification depiction of sites later scrubbed · spoil/dump and quarry footprints · military reservation boundaries · cross-check on claimed coordinates

**Holdings.** VERIFIED LIVE 2026-08-16. 186,061 georeferenced scans of USGS and cooperator topographic sheets, 1870s–2000s, 2.03 TB total. Two parallel renditions of every sheet: GeoPDF under /PDF/{ST}/{scale}/ and GeoTIFF under /GeoTIFF/{ST}/. Verified decade distribution: 1880s 517, 1890s 5,070, 1900s 5,143, 1910s 3,527, 1920s 3,185, 1930s 5,688, 1940s 16,059, 1950s 47,398, 1960s 44,889, 1970s 20,486, 1980s 19,311, 1990s 12,439, 2000s 2,344. Scale distribution: 1:24,000 = 131,189 sheets; 1:62,500 = 27,814; 1:63,360 (AK) = 7,040; 1:125,000 = 4,648; 1:250,000 = 4,497; 1:31,680 = 4,223; 1:100,000 = 2,980; plus 1:10,000 (218), 1:20,000 (317), 1:25,000 (1,553), 1:30,000, 1:48,000, 1:50,000, 1:96,000. Crucially, 45,888 distinct quad cells carry MORE THAN ONE edition (max observed: 27 editions of a single cell), which makes the collection a time series, not a snapshot. 9,579 sheets carry a military-lineage publisher tag: USACE,WarDept (2,097), USGS,USACE,AMS (1,996), USACE,AMS (1,423), USGS,USACE,WarDept (1,232), USGS,AMS (941), USGS,MIL (429), AMS (418, Army Map Service), MIL (164), WarDept (50), and combinations.

**Access method.** Bulk download / anonymous HTTPS. No login, no API key, no rate limit observed. S3 REST list-objects-v2 works directly: GET https://prd-tnm.s3.amazonaws.com/?list-type=2&delimiter=/&prefix=StagedProducts/Maps/HistoricalTopo/GeoTIFF/CO/ . Individual objects support HTTP Range requests (verified), so GDAL /vsicurl/ subwindow reads work without downloading whole files.

**Format returned.** GeoTIFF: VERIFIED header of CO_Cheyenne Mountain_450177_1961_24000_geo.tif — 6671 x 8075 px, 3-band YCbCr, Compression=7 (JPEG-in-TIFF), TILED 512x512, with a second IFD present (internal overviews) — i.e. effectively a COG. ModelPixelScale = 2.032 m, which at 1:24,000 is exactly 300 dpi. GeoKeys: GeographicTypeGeoKey 4267 = NAD27, ProjCoordTrans 22 = Polyconic, linear units metres. File size 8.5 MB for that sheet. GeoPDF is TerraGo-flavoured PDF with a geospatial extension; typical 14 MB. Both come with an FGDC CSDGM XML sidecar.

**Search technique.** Do not scrape the topoView UI. Pull the nightly-refreshed inventory instead: https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/Metadata/historicaltopo.zip (17.5 MB; VERIFIED Last-Modified 2026-08-15, refreshed nightly). It expands to historicaltopo.csv (185 MB, 186,061 rows) plus a 401-line data dictionary. Full verified column list: scan_id, product_inventory_uuid, series, edition, map_name, primary_state, westbc, eastbc, northbc, southbc, geom_wkt, date_on_map, imprint_year, survey_year, field_check_year, edit_year, aerial_photo_year, photo_inspection_year, photo_revision_year, metadata_date, print_releases, variations, hdatum_printed, projection_printed, publishers, languages, map_scale, gnis_cell_id, gnis_cell_name, gnis_primary_state, grid_size, cell_type, state_list, county_list, page_width_inches, page_height_inches, product_filename, product_filesize, product_url, thumbnail_url, geotiff_url, metadata_url, sciencebase_url. All 186,061 rows carry non-null product_url, geotiff_url, metadata_url and sciencebase_url — every sheet is downloadable in both formats. geom_wkt is a WGS84 POLYGON, so COPY the CSV straight into PostGIS and index it: a point-in-polygon query returns the full temporal stack for any coordinate. VERIFIED example: point 38.7440,-104.8480 (Cheyenne Mountain NORAD portal) is covered by 34 sheets spanning 1893–1989 — 1893 and 1909 Colorado Springs 1:125,000, 1942 Colorado Springs, 1948/1949 Cheyenne Mountain 1:24,000 (pre-excavation), 1948/1951 Mount Big Chief 1:62,500, nine separate 1961 Cheyenne Mountain 1:24,000 sheets whose aerial_photo_year / photo_revision_year values are 1960, 1969, 1969, 1969, 1975, 1975, 1975, 1988, 1988, plus 1:250,000 Pueblo sheets 1954–1989. That single query yields a 1948-vs-1969-vs-1988 differencing series over the most famous hardened facility in the country, free, in about four seconds of SQL. The `publishers` field is the single highest-yield filter in the whole corpus: WHERE publishers LIKE '%MIL%' OR publishers LIKE '%WarDept%' OR publishers LIKE '%AMS%'. The `variations` field flags 'Planimetric' (2,925 sheets — no contours, often produced for engineering/military purposes) and 'OrthophotoQuad'/'OrthophotoMap' (3,116 sheets — photo base under the linework, which sometimes shows construction the cartographer did not draw). The `photo_revision_year` field is the key temporal handle: a photorevised sheet is a base map with post-dated aerial-derived additions overprinted in purple, so a 1961 base with a 1975 photorevision literally colour-codes what appeared in the intervening fourteen years.

**Rate limits.** None documented or observed. S3-backed. Practical limit is your bandwidth: the whole GeoTIFF corpus is ~2 TB.

**Robots / ToS posture.** S3 bucket root serves an index.html; no robots.txt restriction encountered on the object paths. This is the USGS's own designated bulk-delivery channel and the FAQ explicitly endorses writing download scripts against the inventory. Public domain, no copyright. Be polite: parallelism of 4–8 and a per-object cache, since sheets are 8–20 MB each.

**Notes.** WHAT A HARDENED FACILITY LOOKS LIKE ON A QUAD SHEET. (a) Adit / tunnel / cave entrance: a small open chevron or Y-shaped black symbol opening away from the hillside, placed at a contour, frequently labelled 'Tunnel', 'Mine Tunnel', 'Portal', or a proper name. USGS convention places the adit symbol perpendicular to the slope, NOT along the true bearing of the tunnel — so the symbol tells you where the mouth is and nothing about which way the workings run. (b) Mine shaft: a small black crossed-picks or X symbol; a vertical shaft in flat ground with no associated headframe or road is anomalous. (c) Quarry / open pit: crossed-picks variant inside a hachured outline. (d) Excavation and collapse: hachured (tick-marked) closed contours indicate a depression; a rectilinear hachured depression in otherwise smooth terrain is an excavation, not karst. (e) Spoil / muck dumps: stippled or fine-hachured lobate mounds immediately downslope of a portal — the volume of the dump is a first-order estimator of excavated volume, which is the single most useful inference the map supports. (f) The negative signature: a road, power line, or fence that runs to a point and simply stops, with no structure drawn. On sheets from roughly 1950–1980 over sensitive sites, USGS suppressed structures while retaining terrain; the tell is a well-graded road terminating at a contour, or a conspicuously blank rectangle inside an otherwise densely drawn area. Compare the drawn content against the sheet's own aerial_photo_year — if the photography is contemporaneous with a known construction period and the sheet shows nothing, the omission is itself evidence and should be graded as such rather than treated as absence. (g) Military reservation boundaries drawn as a dot-dash line with 'U.S. MILITARY RESERVATION' or 'RESTRICTED AREA' lettering, sometimes with an interior blanking. (h) Isolated 'Tower' or 'Radio Tower' symbols in clusters, plus 'Underground pipeline' dashed lines running to nothing. CRS GOTCHA: HTMC GeoTIFFs are NAD27 Polyconic, not WGS84 — you must reproject (gdalwarp -s_srs from the embedded GeoKeys -t_srs EPSG:4326) before overlaying anything modern, and NAD27→WGS84 shifts are 50–100 m in the western US, which is larger than most of the features you care about.

---

### 2.8 · USGS HTMC / US Topo product inventory files (nightly CSV manifests)

`CRITICAL` · tier **P1** · <https://prd-tnm.s3.amazonaws.com/StagedProducts/Maps/Metadata/>

*Serves:* harvest planning · incremental sync · spatial index

**Holdings.** VERIFIED LIVE. Six zipped CSV manifests, all Last-Modified 2026-08-15: historicaltopo.zip (17.5 MB, 186,061 HTMC rows), topomaps_all.zip (96 MB, HTMC + US Topo combined), topomaps_all_legacy.zip, ustopo_current.zip, ustopo_historical.zip (35.6 MB), ustopo_replacements.zip. Each archive contains the CSV, a short summary .txt (row count, total bytes, last-updated date), and a long readme with a per-column data dictionary.

**Access method.** Anonymous HTTPS GET. No auth.

**Format returned.** ZIP containing UTF-8 CSV with quoted WKT geometry, plus plain-text data dictionary.

**Search technique.** This is the file that turns a 2 TB image archive into a queryable register. Diff the previous night's CSV against today's on scan_id to detect newly published or re-scanned sheets. ustopo_replacements.zip specifically records which modern US Topo sheet superseded which HTMC sheet — useful for detecting features that were on the old sheet and are not on the new one.

**Rate limits.** None.

**Robots / ToS posture.** USGS-designated bulk channel; explicitly intended for scripted download.

**Notes.** The summary .txt inside each zip is a cheap freshness probe — 6 lines, tells you row count and last-update date without unzipping 185 MB. Better still, HEAD the zip and read Last-Modified.

---

### 2.9 · USGS USMIN — Prospect- and Mine-Related Features from USGS 7.5- and 15-Minute Topographic Quadrangle Maps (ver. 10.0, May 2023)

`CRITICAL` · tier **P2** · <https://mrdata.usgs.gov/usmin/>

*Serves:* machine-readable index of every mapped adit and shaft in 35 states · instant spatial join against any candidate · proof that a topographic symbol exists at a claimed coordinate

**Holdings.** The USGS systematically DIGITISED the mine and prospect symbols off the historical topographic quadrangle archive. Version 10.0 contains over 637,000 point and polygon features from roughly 88,000 map sheets across 35 states. Feature classes include adits, mine shafts, air shafts, prospect pits, quarries, open pits, tailings piles and ponds, gravel and borrow pits, and undifferentiated disturbed ground. DOI 10.5066/F78W3CHG. ScienceBase item 5a1492c3e4b09fc93dcfd574.

**Access method.** Bulk download of shapefiles and file geodatabases from mrdata.usgs.gov/usmin/ and ScienceBase; also served as OGC WMS/WFS from mrdata, and mirrored as an ArcGIS MapServer at gisweb.unr.edu/nbmg/rest/services/MineralsAndEnergy/USMIN/MapServer and energy.usgs.gov ArcGIS FeatureServer.

**Format returned.** Shapefile, File Geodatabase, CSV; WMS 1.3.0 and WFS 1.1.0.

**Search technique.** THIS IS THE SINGLE HIGHEST-LEVERAGE DERIVED DATASET ON THIS BEAT. It converts 'somebody would have to read 88,000 map sheets' into a PostGIS table. Key attributes: Ftr_Type (the feature class, e.g. 'Adit', 'Air Shaft', 'Mine Shaft', 'Gravel/Borrow Pit - Undifferentiated'), Ftr_Name (the label as printed on the map — proper names like 'Carlin Mine' or 'Johnson Shaft', or generic labels like 'Tunnel', 'Mine', 'Coal Mine', 'Cave'), plus the source quad name, scale and map year. Query patterns that matter for this project: (1) SELECT WHERE Ftr_Type IN ('Adit','Air Shaft','Mine Shaft') AND Ftr_Name ILIKE ANY('%Tunnel%','%Portal%','%Cave%') — 'Tunnel' and 'Cave' labels on non-mining terrain are the classic misfiled hardened-facility symbol. (2) Spatially join adits against MSHA and MRDS: an adit symbol with NO corresponding mining record in either commercial database is an anomaly worth a candidate record — it means USGS drew a portal that no mine regulator ever knew about. (3) Cluster adits by proximity to military reservations, DOE sites, and FAA restricted airspace. (4) Air Shaft is defined by USGS (after the American Geological Institute glossary) as 'a shaft used wholly or mainly for ventilating mines' — a mapped air shaft with no mapped adit within a kilometre implies an unmapped underground extent.

**Rate limits.** None on bulk files. WFS is best used with a bbox filter and a maxFeatures cap.

**Robots / ToS posture.** mrdata.usgs.gov publishes bulk downloads and OGC services precisely so people do not scrape the map viewer. Use the bulk files or WFS.

**Notes.** CAVEAT USGS STATES EXPLICITLY: the adit direction shown on a topographic map is generally drawn perpendicular to the slope, NOT along the true bearing of the tunnel. Do not infer heading from the symbol. Coverage is 35 states and skews western — eastern coal states are thinner, and for those the state mine-map repositories (below) are the substitute. HONEST LIMITATION: mrdata.usgs.gov and sciencebase.gov are both blocked from this sandbox, so field names above come from the published FAQ metadata (mrdata.usgs.gov/usmin/metadata/usmin-topo.faq.html) via search results, not from a downloaded file. Verify the exact attribute schema against the FGDC metadata before writing the loader.

---

### 2.10 · FAA Special Use Airspace and aeronautical geospatial data (AIS Open Data)

`HIGH` · tier **P1** · <https://adds-faa.opendata.arcgis.com/datasets/special-use-airspace>

*Serves:* independent corroboration of an active sensitive site · tight low-altitude restrictions over otherwise unremarkable terrain · using-agency attribution

**Holdings.** Prohibited (P-), Restricted (R-), Warning (W-), Alert (A-), Military Operations Areas, Controlled Firing Areas, and Air Traffic Control Assigned Airspace, as polygons with designator, name, lower and upper altitude limits, time of use, controlling and using agency. Published on an eight-week cycle synchronised to the aeronautical chart cycle by FAA Aeronautical Information Services. Parallel legacy portal at ais-faa.opendata.arcgis.com (dataset id dd0d1b726e504137ab3c41b21835d05b_0). The authoritative source-of-record is the 28-day NASR subscription file from the FAA's data delivery service; the graphical browser is at https://sua.faa.gov/

**Access method.** ArcGIS Hub Open Data: FeatureServer REST query, plus one-click download as CSV, KML, shapefile, GeoJSON. Also OGC WMS and WFS. No key required. NASR 28-day subscription is a separate bulk ZIP download from FAA.

**Format returned.** GeoJSON, shapefile, KML, CSV; NASR as fixed-width text plus shapefiles.

**Search technique.** Standard ArcGIS query: {service}/FeatureServer/0/query?where=1%3D1&outFields=*&f=geojson&resultOffset=0&resultRecordCount=1000, paged. The discriminating filter for this project is NOT the big ranges — R-2508, R-4806, the Nevada Test and Training Range are all well known and are training airspace, not facility indicators. What matters is the SMALL, TIGHT, LOW restriction: a prohibited or restricted area of one to three nautical miles radius, surface to a few thousand feet AGL, continuous (not scheduled), in terrain with no visible installation. Query for polygons with ST_Area below a threshold AND lower limit = 'SFC' AND a 24-hour time of use. Then check the 'using agency' field: an unusual using agency (a non-flying command, DOE, a federal agency that does not operate aircraft) on a surface-to-low restriction is a strong signal that the airspace exists to keep aircraft away from something on the ground rather than to contain flight activity. Cross-reference against lidar and against HTMC blanking.

**Rate limits.** Standard ArcGIS Hub throttling; the SUA layer is small enough (a few thousand polygons) to pull in a handful of paged requests. Refresh every 56 days to match the publication cycle.

**Robots / ToS posture.** ArcGIS Hub Open Data with published API links (GeoServices, WMS, WFS); explicitly machine-accessible. Public domain US government data.

**Notes.** Also worth harvesting from the same portal: Class Airspace, Designated Points, NAVAIDs, and the obstacle data. HONEST LIMITATION: all FAA and ArcGIS hosts are blocked from this sandbox; endpoint structure is from search results and general ArcGIS REST knowledge. Verify the exact FeatureServer ID and field names (NAME, TYPE_CODE, and the altitude/agency fields) against the service's own ?f=pjson before writing the loader. Note also that airspace absence proves nothing — several well-documented hardened facilities have no special-use airspace at all.

---

### 2.11 · MSHA Mine Data Retrieval System — open flat files

`HIGH` · tier **P1** · <https://www.msha.gov/data-and-reports/mine-data-retrieval-system>

*Serves:* authoritative regulated-mine inventory with coordinates · status transitions including sealing and abandonment · operator/controller lineage

**Holdings.** Every coal and metal/nonmetal mine under MSHA jurisdiction since 1970-01-01, in the United States, Puerto Rico and the Virgin Islands. The Mines dataset carries mine ID, current status (Active, Abandoned, Abandoned and Sealed, NonProducing, Temporarily Idled, New Mine), current controller and operator, commodity codes, physical attributes, and latitude/longitude. Around twenty flat files in total, covering mines, controllers/operators, employment and production quarterly, inspections, violations, accidents, and address-of-record.

**Access method.** Bulk delimited text files under the MSHA Open Government Initiative, refreshed weekly (uploaded Fridays). Mirrored on catalog.data.gov as the 'MSHA Mines Dataset'. Each data file has a paired *_Definition_File.txt describing the columns. Also a Socrata-style endpoint at data.msha.gov for some series.

**Format returned.** Pipe- or tab-delimited text plus definition files; CSV via data.gov.

**Search technique.** Load Mines.txt keyed on MINE_ID. High-value filters for this beat: (1) COAL_METAL_IND and MINE_TYPE = 'Underground' AND CURRENT_MINE_STATUS IN ('Abandoned','Abandoned and Sealed','NonProducing') — a sealed underground working with a known portal location is the raw material for a repurposing claim. (2) Records with a controller name that is a government entity, a defence contractor, or a records-storage or data-centre company — this is the direct route to the small number of genuinely repurposed mines (limestone-mine records storage and data-centre conversions show up here under their real operator). (3) Records whose status changed to abandoned within a few years of a federal land acquisition at the same coordinates. (4) Join MINE_ID back to e-AMLIS and to USMIN adits. The definition files are essential — MSHA column names are terse and several status codes are undocumented outside them.

**Rate limits.** None on the flat files. Weekly refresh means a weekly sync is sufficient.

**Robots / ToS posture.** msha.gov publishes these files explicitly as open government data. Use the flat files, not the interactive MDRS query form.

**Notes.** MSHA only covers mines under its jurisdiction from 1970 onward. Workings abandoned before 1970 — which is most of what matters for Cold War-era conversion — appear only in USMIN, MRDS, state repositories and topographic sheets. Treat MSHA as the modern layer of a four-layer stack, not as the inventory. HONEST LIMITATION: msha.gov and data.msha.gov are blocked from this sandbox; file names and refresh cadence come from search results and the data.gov catalog, not direct inspection.

---

### 2.12 · NARA Record Group 373 — Records of the Defense Intelligence Agency, aerial photography

`HIGH` · tier **P1** · <https://www.archives.gov/research/cartographic/aerial-photography/rg-373-dia-domestic-aerial-photography-sl25>

*Serves:* 1935–1970 domestic coverage predating or supplementing EROS · imagery of sites that were never in a civil acquisition program

**Holdings.** Over 30 million aerial photographs, 1935–1970, transferred from DIA. Split into domestic-flown (indexed in Special List 25), GX foreign-flown (captured German Luftwaffe), and JX (captured Japanese). Domestic holdings include Army Air Forces and Air Force reconnaissance training sorties flown over the continental United States, which incidentally photographed defence installations at high resolution in periods with no other coverage.

**Access method.** MANUAL. Physical research at the Cartographic Research Room, NARA II, College Park MD, or written request to carto@nara.gov. Special List 25 is downloadable as a finding aid. Access path is: geographic area → SL25 entry → 'spot number' → RG 373 can locator → film can → frame. The can locator is available digitally on request from carto@nara.gov.

**Format returned.** Film and prints. Reproduction is a paid, per-item service. A small and growing subset appears in the National Archives Catalog with digital images.

**Search technique.** Work backwards from SL25's geographic organisation (state, then degree square) rather than trying to search by installation name — the finding aid is organised by geography and mission, not by subject. Spot numbers are the pivot: an SL25 entry gives a spot number, the can locator maps spot number to a physical film can. Budget for a research trip or a paid researcher; this is not machine-accessible and no amount of engineering will make it so.

**Rate limits.** N/A — human-mediated. Expect weeks to months.

**Robots / ToS posture.** archives.gov finding aids are public documents; the images are not online in bulk.

**Notes.** HONEST ASSESSMENT: this is the highest-value non-machine-accessible source on the beat. It should be recorded in the register as a known-but-unharvested corpus, with per-candidate notes about which SL25 geographic entries would cover the site, so the research debt is explicit rather than invisible. Treat any facility whose only imagery gap is 1935–1955 as a standing RG 373 request.

---

### 2.13 · OpenTopography REST API (3DEP and global DEM cropping service)

`HIGH` · tier **P2** · <https://opentopography.org/developers>

*Serves:* convenient AOI clipping · non-3DEP lidar coverage · international expansion

**Holdings.** Server-side cropping and reprojection of USGS 3DEP 1 m, 1/3 arc-second and 1 arc-second rasters (/API/usgsdem) plus SRTM GL1/GL3, ALOS World 3D, NASADEM and Copernicus DSM (/API/globaldem). Also hosts NSF-funded high-resolution point clouds that are NOT in 3DEP, including academic and state acquisitions.

**Access method.** REST with a free API key (obtained via My Account on the portal).

**Format returned.** GeoTIFF, AAIGrid, HFA; point clouds as LAZ.

**Search technique.** GET /API/usgsdem?datasetName=USGS1m&south=&north=&west=&east=&outputFormat=GTiff&API_Key=... . Use it as a convenience layer over 3DEP, and as the PRIMARY route to the NSF/academic point clouds that never entered 3DEP — those fill real coverage gaps in the mountain west.

**Rate limits.** HARD AND LOW: free key is 200 calls per rolling 24 hours for academic users, 50 per 24 hours for non-academic. Area caps per request: 225,000 km² for 30 m, 25,000 km² for 10 m, 250 km² for 1 m. The USGS 3DEP 1 m endpoint is restricted to academic users with a separate access request. OpenTopography Plus subscription raises the limits (paid).

**Robots / ToS posture.** Published developer API with an explicit key regime; terms require attribution and prohibit bulk mirroring.

**Notes.** Because the free non-academic quota is 50 calls a day, this cannot be the backbone of a continuous harvester. Use prd-tnm S3 and the EPT bucket for volume; keep OpenTopography for the datasets that exist nowhere else, and note in the register when a candidate's only elevation evidence came from a rate-limited source.

---

### 2.14 · State geological survey and state mining agency mine-map repositories

`HIGH` · tier **P1** · <https://www.pa.gov/agencies/dep/programs-and-services/mining/>

*Serves:* actual underground plan-view geometry — the only sources that show what is BELOW the surface · depth, extent, seam elevation, pillar layout · pre-1970 workings absent from MSHA

**Holdings.** The deepest single-state example is Pennsylvania: the Mine Map Atlas (DEP with Penn State PASDA) holds over 100,000 high-resolution scans of original underground mine maps georeferenced onto a modern base, each linked to its record in PHUMMIS (Pennsylvania Historic Underground Mine Map Inventory System). EPCAMR has separately scanned 10,000 maps, georeferenced 2,500 and digitised 1,000 from the Wilkes-Barre BAMR office, the Pottsville District Mining Office and the Earth Conservancy / Blue Coal collection. Comparable programs exist in West Virginia (WVGES mine mapping), Kentucky (KGS), Ohio (ODNR, ArcGIS REST as above), Colorado (DRMS), Utah (UGS abandoned mine openings), and Nevada (NBMG, which runs an ArcGIS Open Data site at data-nbmg.opendata.arcgis.com plus REST services at web2.nbmg.unr.edu/arcgis/rest/services/ and gisweb.unr.edu/nbmg/rest/services/).

**Access method.** Highly heterogeneous. Best case: an ArcGIS Hub Open Data site with FeatureServer endpoints and bulk GeoJSON/shapefile downloads (Nevada, Ohio). Middle case: a georeferenced scan viewer with per-map download (Pennsylvania). Worst case: a paper index at a district office requiring a written request or an in-person visit.

**Format returned.** Georeferenced TIFF/JPEG scans, ArcGIS FeatureServer JSON/GeoJSON, shapefile, and PDF indices.

**Search technique.** This is the only category of source on the whole beat that gives you the shape of the void rather than the location of its mouth. Prioritise the states with (a) large limestone or sandstone room-and-pillar workings suitable for conversion — Pennsylvania, Missouri, Kansas, Ohio, Indiana, Kentucky, West Virginia — and (b) hard-rock states with deep workings near military infrastructure — Colorado, Utah, Nevada, Arizona, New Mexico. For each state, first probe for an ArcGIS Hub site (try {agency}.opendata.arcgis.com and hub.arcgis.com search by organisation) and for a bare ArcGIS Server at /arcgis/rest/services?f=pjson, which enumerates every published service on that server and is by far the fastest way to discover what a state actually publishes. Then fall back to the scan viewer. Record for each state which tier of access it offers — that itself is a useful register artefact.

**Rate limits.** ArcGIS servers: page at 1,000 features, keep concurrency at 2–4.

**Robots / ToS posture.** Per-agency. ArcGIS REST services are machine-facing by design. Scan viewers are usually not; check each site's terms and robots.txt.

**Notes.** HONEST LIMITATION: all of these hosts are blocked from this sandbox, so the specifics above are from search results. Building a per-state matrix of (repository name, access tier, endpoint, coverage years, licence) is a discrete, high-value piece of work that should be its own harvesting sub-project. Mine maps are also the source most likely to be paywalled or restricted, since several states treat detailed mine geometry as a subsidence-liability and security matter.

---

### 2.15 · TNM Access API (The National Map product search)

`HIGH` · tier **P1** · <https://tnmaccess.nationalmap.gov/api/v1/products>

*Serves:* cross-dataset discovery by AOI · elevation product availability · current-state products

**Holdings.** Unified product search across every National Geospatial Program downloadable dataset: Historical Topographic Maps, US Topo, National Elevation Dataset (1, 1/3, 1/9 arc-second), Lidar Point Cloud, Original Product Resolution DEM, NAIP, Structures, Map Indices, Hydrography, Transportation. Returns download URLs, footprints, publication dates and file sizes.

**Access method.** REST, HTTP GET or POST, JSON response. No API key. Documentation at https://tnmaccess.nationalmap.gov/api/v1/docs with a query-builder UI at https://apps.nationalmap.gov/tnmaccess/products.html

**Format returned.** JSON (default), also CSV/pretty-JSON via outputFormat.

**Search technique.** Core parameter set: datasets= (exact dataset label string, e.g. 'Historical Topographic Maps', 'Lidar Point Cloud (LPC)', 'Digital Elevation Model (DEM) 1 meter'), bbox=xmin,ymin,xmax,ymax in WGS84 decimal degrees, polygon= as a space-separated lon lat list, prodFormats= (GeoTIFF, LAS,LAZ, GeoPDF, Shapefile, FileGDB, GeoPackage), start= / end= as YYYY-MM-DD on publication date, max= (page size, practical ceiling 1000), offset= for paging, q= for free-text. Response objects carry title, sourceId, sourceName, downloadURL, downloadLazURL, metaUrl, boundingBox, publicationDate, dateCreated, sizeInBytes, format, extent. Page with offset until total is exhausted; total is returned in the envelope.

**Rate limits.** Not formally published. Community practice is to keep concurrency low (2–4) and to cache; USGS has throttled abusive callers in the past. Prefer the S3 manifests for full-corpus enumeration and use TNM Access for targeted AOI queries.

**Robots / ToS posture.** Public API with published docs; explicitly intended for programmatic access.

**Notes.** HONEST LIMITATION: host is blocked from this sandbox (403 CONNECT), so the parameter list above is from documentation and search results, not direct call verification. Verify dataset label strings against /api/v1/datasets before hard-coding them — they are exact strings and USGS renames them between releases.

---

### 2.16 · USGS Mineral Resources Data System (MRDS) and Mineral Resources Online Spatial Data

`HIGH` · tier **P2** · <https://mrdata.usgs.gov/mrds/>

*Serves:* named mine sites with coordinates · workings type (underground vs surface) · commodity and operator history · bibliographic trail back to primary reports

**Holdings.** Reports on metallic and nonmetallic mineral resource sites worldwide: deposit name, location, commodity, deposit description, geologic characteristics, production, reserves, resources, workings type, and bibliographic references. The parent mrdata.usgs.gov site also hosts state geologic maps, geophysical surveys (aeromagnetic, radiometric), and the USMIN products.

**Access method.** Bulk download plus OGC services. Verified-by-search file names: mrds-trim.zip (shapefile, ~10 MB), mrds-csv.zip (~23 MB), rdbms-tab-all.zip (tab-delimited full relational dump, ~118 MB). WFS 1.1.0 and WMS 1.3.0 at https://mrdata.usgs.gov/services/mrds?request=GetCapabilities&service=WFS&version=1.1.0

**Format returned.** Shapefile, CSV, tab-delimited relational tables, KML, WMS/WFS.

**Search technique.** Take the full relational dump (rdbms-tab-all.zip), not the trimmed shapefile — the trimmed version drops the workings, production and reference tables, which are the interesting ones. Filter on workings type = underground, then look for records where production is null or trivially small but the workings are extensive, and for records whose 'development status' changed to inactive during 1950–1975. Cross-join to USMIN adits and to MSHA. The reference table is the bibliographic bridge to primary literature — it is how you source a claim backwards.

**Rate limits.** None on bulk files.

**Robots / ToS posture.** Bulk downloads and OGC services published for machine use.

**Notes.** MRDS coordinate quality is highly variable — many legacy records are township-range centroids, accurate only to a section or worse. Never treat an MRDS coordinate as a located facility without corroboration from USMIN, a topo sheet, or imagery. This is exactly the kind of precision-versus-provenance distinction the register's grading exists for.

---

### 2.17 · GNIS Domestic Names (Geographic Names Information System)

`MODERATE` · tier **P1** · <https://prd-tnm.s3.amazonaws.com/StagedProducts/GeographicNames/>

*Serves:* named subsurface features · the quad-name join key · folklore-name resolution

**Holdings.** VERIFIED LIVE prefix on prd-tnm. The federal gazetteer of place names with feature class, coordinates, elevation, county, and the source quadrangle name. Feature classes include Mine, Tunnel, Cave, Military, Reservoir, Range, and roughly fifty others.

**Access method.** Anonymous HTTPS bulk download of pipe-delimited national and per-state files.

**Format returned.** Pipe-delimited text; also served via TNM.

**Search technique.** Filter FEATURE_CLASS IN ('Mine','Tunnel','Cave') for the obvious cases, and 'Military' for reservations and installations. The subtler use is REVERSE SOURCING of folklore: when a claim names a place ('the such-and-such tunnel'), GNIS tells you whether that name is a real registered toponym, what feature class the government assigned it, which quadrangle it appears on, and therefore which HTMC sheets to pull. A name that appears on 400 websites and in zero federal gazetteers is a strong indication that the claim originated in a single unsourced text, which is precisely the finding this register exists to record. The MAP_NAME field in GNIS is the 7.5-minute quad name, which joins directly to the HTMC inventory's gnis_cell_name/gnis_cell_id.

---

### 2.18 · HTMC per-sheet FGDC metadata web-accessible folder (thor-f5)

`MODERATE` · tier **P1** · <https://thor-f5.er.usgs.gov/ngtoc/metadata/waf/maps/historicaltopo/pdf/>

*Serves:* formal provenance for citation · source lineage of each scan

**Holdings.** One FGDC CSDGM XML record per HTMC sheet, in a web-accessible folder mirroring the PDF tree: /{ST}/{scale}/{ST}_{Quad_Name}_{scan_id}_{year}_{scale}_geo.xml . The metadata_url column of the HTMC inventory CSV points here for all 186,061 sheets (VERIFIED non-null for every row).

**Access method.** Anonymous HTTPS, one XML per sheet.

**Format returned.** FGDC CSDGM XML.

**Search technique.** Note the filename transformation: the metadata_url substitutes underscores for spaces in the quad name (AL_Abbeville_East_...xml) while the product_url percent-encodes the space (AL_Abbeville%20East_...pdf). A naive URL constructor will 404 on every multi-word quad name. Derive both from the CSV columns rather than constructing them.

**Rate limits.** Unknown; 186,061 small files — fetch lazily, only for sheets that actually enter the register, and cache permanently.

**Robots / ToS posture.** Public metadata WAF.

**Notes.** HONEST LIMITATION: thor-f5.er.usgs.gov is blocked from this sandbox and was not directly tested. The URL pattern above is read verbatim from the metadata_url column of the inventory CSV I did download, so the pattern is verified even though the host is not reachable from here. The ScienceBase item URL in the sciencebase_url column is an equivalent and probably more stable citation target.

---

### 2.19 · National Register of Historic Places spatial data (NPS Cultural Resources GIS)

`MODERATE` · tier **P1** · <https://www.nps.gov/orgs/1094/nrhp_spatialdata.htm>

*Serves:* Cold War infrastructure with detailed construction documentation · named, dated, described hardened structures

**Holdings.** Point and polygon geometry for roughly 100,000 listed properties, built to the NPS Cultural Resources Spatial Data Transfer Standards. Served as an ArcGIS MapServer at https://mapservices.nps.gov/arcgis/rest/services/cultural_resources/nrhp_locations/MapServer and downloadable as file geodatabase via the NPS IRMA portal. The associated nomination documents — which are the actually valuable part — are scanned PDFs at https://npgallery.nps.gov/nrhp/

**Access method.** ArcGIS REST query for geometry; npgallery for the nomination PDFs, which are individually addressable by reference number.

**Format returned.** File geodatabase, shapefile, ArcGIS REST JSON/GeoJSON; nominations as scanned PDF, frequently requiring OCR.

**Search technique.** The geometry is a finding aid; the nominations are the evidence. NRHP nomination forms for Cold War-era properties routinely contain construction dates, contractor names, structural descriptions (blast door thicknesses, shock isolation, EMP shielding), floor plans and historical photographs — material that is otherwise only obtainable through FOIA. High-yield nomination searches: Nike missile batteries and their launch/control site pairs, Atlas/Titan/Minuteman silos and launch control facilities, SAGE direction centres, AT&T Long Lines hardened relay stations, civil defence emergency operating centres, Distant Early Warning and Air Defense Command sites, and Federal Reserve and government records-storage bunkers. Search npgallery full-text for phrases like 'blast door', 'hardened', 'underground operations', 'emergency operating center', 'fallout shelter', 'shock isolation'. OCR is often required — the older nominations are typewritten scans.

**Rate limits.** ArcGIS paging as usual. npgallery PDFs are large; cache aggressively.

**Robots / ToS posture.** NPS mapservices are public REST endpoints. npgallery is a public document repository; rate-limit politely.

**Notes.** IMPORTANT EXCLUSION, stated by NPS: the public spatial dataset EXCLUDES all features deemed restricted or sensitive, notably archaeological sites. So NRHP absence is meaningless and should never be recorded as negative evidence. Also note the inverse selection bias — a facility gets an NRHP nomination precisely because it was decommissioned and declassified enough to be documented, so this source over-represents obsolete infrastructure and under-represents anything current.

---

### 2.20 · OSMRE e-AMLIS — Abandoned Mine Land Inventory System

`MODERATE` · tier **P1** · <https://www.osmre.gov/programs/e-amlis>

*Serves:* portals sealed with federal money · documented dangerous openings · reclamation-era site descriptions

**Holdings.** National compilation of state, tribal, Federal Reclamation Program and Rural Abandoned Mine Program inventories of abandoned mine land problems: location, problem type, extent, reclamation cost, and reclaimed/unreclaimed status. Structured as Problem Areas, Planning Units, Keyword Features and Project Sites (the geospatial data model is standardised by ASTM D7699).

**Access method.** Web query interface at osmre.gov; a copy is submitted to NETL EDX. State implementations expose ArcGIS REST services — e.g. Ohio DNR at https://gis.ohiodnr.gov/arcgis/rest/services/MRM_Services/MRMMapViewer_AMLISINFO/MapServer with AMLIS Problem Area as layer 1 and AMLIS Planning Unit as layer 2. There is no clean single national bulk geospatial download; enquiries go to the e-AMLIS team by email.

**Format returned.** Web reports, CSV exports, and state-hosted ArcGIS FeatureServer/MapServer layers.

**Search technique.** The high-yield problem types are 'Dangerous Highwall', 'Vertical Opening', 'Portal', 'Subsidence' and 'Underground Mine Fire'. A federally funded portal closure means there was a physical, located, open portal, documented with coordinates and a cost estimate — that is strong P1 evidence that a subsurface void exists, independent of any claim about what is in it. Harvest via the state ArcGIS REST services where they exist (standard /query?where=1%3D1&outFields=*&f=geojson&resultOffset=N paging) rather than the national web form.

**Rate limits.** ArcGIS services typically cap at 1,000–2,000 features per request; page with resultOffset/resultRecordCount.

**Robots / ToS posture.** State ArcGIS REST endpoints are public services designed for machine query. The national e-AMLIS web form is not.

**Notes.** Coverage and data quality vary enormously by state because states enter their own data. Grade accordingly. The national roll-up is weaker than the best individual state programs.

---

### 2.21 · topoView (NGMDB) — human-facing HTMC browser

`MODERATE` · tier **P1** · <https://ngmdb.usgs.gov/topoview/>

*Serves:* quick visual verification · citation URL for a specific sheet

**Holdings.** Web viewer over the same HTMC corpus, plus KMZ and JPEG renditions not staged on S3. Backed by ArcGIS REST services under https://ngmdb.usgs.gov/arcgis/rest/services/topoview/ (ustOverlay, ustOverlayAuto MapServer endpoints, supportedQueryFormats JSON/geoJSON/PBF).

**Access method.** HTML app plus ArcGIS REST MapServer. Also NGMDB product-description pages at /prodesc/proddesc_{id}.htm.

**Format returned.** HTML, ArcGIS REST JSON, KMZ, JPEG, GeoTIFF, GeoPDF.

**Search technique.** Use topoView only for eyeball verification and for producing a stable human-readable citation. For anything programmatic the S3 inventory is strictly superior — it has every field topoView exposes plus geometry, and it doesn't require reverse-engineering an ArcGIS app.

**Rate limits.** Unknown. ArcGIS MapServer /query endpoints typically cap at 1,000–2,000 features per request and require resultOffset paging.

**Robots / ToS posture.** Not determinable from this sandbox — ngmdb.usgs.gov is blocked by the egress proxy here. Check /robots.txt before scraping; prefer the ArcGIS REST endpoints, which are designed for machine access, over the app.

**Notes.** HONEST LIMITATION: I could not reach this host — the sandbox's egress proxy returns 403 CONNECT for ngmdb.usgs.gov, www.usgs.gov, mrdata.usgs.gov, sciencebase.gov, and all *.arcgis.com. Everything stated here about topoView comes from search results and prior knowledge, not direct inspection, and should be verified before a harvester is written against it. The S3 path, by contrast, I verified end to end.

---

### 2.22 · UCSB Library FrameFinder and comparable academic air-photo archives

`MODERATE` · tier **P3** · <https://www.library.ucsb.edu/geospatial/finding-airphotos>

*Serves:* state-level dense historical coverage · frames not in any federal archive

**Holdings.** UCSB holds the largest known academic aerial photography collection: over 2.5 million frames from the 1920s onward, overwhelmingly California, with more than 400,000 scanned and free to download. FrameFinder is a spatial browser where each dot is a frame centre point. Comparable institutional archives: Penn Pilot (Penn State, Pennsylvania 1937–1942 and later), Cornell (New York), Michigan State RSGIS, State Historical Society of Missouri digitized aerials, and numerous state-university geography departments.

**Access method.** Web browser with map interface; scanned frames download free as TIFF/JPEG. No documented public API — the map is backed by a spatial service that can be observed in browser network traffic, but there is no supported programmatic contract.

**Format returned.** Scanned TIFF/JPEG, generally not georeferenced.

**Search technique.** These archives are where state and county acquisitions live that never went to EROS. For a California candidate, FrameFinder often has denser temporal coverage than EarthExplorer. Only about 15% of the UCSB collection is scanned, so absence from the online index is not absence from the collection — the register should distinguish 'not held' from 'held but unscanned'.

**Rate limits.** Institution-specific. Assume conservative (1 request/second, identify yourself in User-Agent).

**Robots / ToS posture.** Determine per institution. Most university libraries permit reasonable automated access to public collections but publish rate expectations; several use ContentDM or similar platforms with documented OAI-PMH endpoints worth checking before scraping HTML.

**Notes.** Where an institution exposes OAI-PMH or IIIF (many library digital collections do), use it — IIIF in particular gives you tiled region access to very large scans without downloading them whole.

---

### 2.23 · USDA Aerial Photography Field Office (APFO)

`MODERATE` · tier **P1** · <https://www.fsa.usda.gov/programs-and-services/aerial-photography/>

*Serves:* county-level historical coverage where EROS is thin · stereo pairs for height extraction

**Holdings.** More than 70,000 rolls of film, 1955 to present, at multiple scales, much of it stereo. Nearly every county in the lower 48 has at least three years of coverage. Also the authoritative archive for NAIP.

**Access method.** MANUAL ORDER by phone, fax, mail or email for historical film; you must supply an accurate area description (legal description, lat/lon, or annotated local map). NAIP is separately available digitally via TNM Access and EarthExplorer.

**Format returned.** Film, prints, and scan-on-demand digital. Paid.

**Search technique.** Order by Public Land Survey System legal description where available — APFO's indexing is agricultural and PLSS-oriented, so a township-range-section request will be handled far faster than a lat/lon.

**Rate limits.** Human-mediated, fee-based.

**Robots / ToS posture.** Not a web-accessible corpus for historical film.

**Notes.** Note honestly in the register that pre-2003 APFO holdings are effectively paywalled per-item. Where a candidate's evidence hinges on APFO film, grade accordingly and record the order as a research action.

---

### 2.24 · USGS Topographic Map Symbols reference and the Kentucky Geological Survey symbol index

`MODERATE` · tier **P1** · <https://pubs.usgs.gov/gip/TopographicMapSymbols/topomapsymbols.pdf>

*Serves:* correct interpretation of raster map content · avoiding false positives

**Holdings.** The official USGS General Information Product describing every symbol on a USGS quadrangle. The KGS 'Index to USGS Topographic Map Symbols' (https://www.uky.edu/KGS/gis/USGSTopoSymbols.pdf) is a fuller historical index covering symbol sets that changed across eras. Esri publishes a rendered 'USGS Topographic Mine-related Symbols' reference on ArcGIS Hub.

**Access method.** Direct PDF download.

**Format returned.** PDF.

**Search technique.** Not a data source — an interpretation key, and an indispensable one. Symbol conventions CHANGED across eras: the 1919-era mine symbols differ from the 1950s set, which differ from the 1970s set. A register that grades evidence must be able to say which symbol standard was in force for a given sheet's imprint year, otherwise a confident reading of a 1930s sheet using a 1980s legend is simply wrong. Pin the symbol standard version to each sheet via its date_on_map / imprint_year from the HTMC inventory.

**Rate limits.** N/A.

**Robots / ToS posture.** Public domain USGS publication.

**Notes.** Pair with the USMIN FAQ metadata, which contains USGS's own operational definitions of each mine feature type (drawn from the American Geological Institute glossary) — those are the definitions USGS actually applied when digitising, and they are what your feature taxonomy should mirror.

---

### 2.25 · USGS TopoMapVector — per-quadrangle vector geopackages of US Topo content

`MODERATE` · tier **P1** · <https://prd-tnm.s3.amazonaws.com/StagedProducts/TopoMapVector/>

*Serves:* machine-readable modern map content per quad · joining named features to quad geometry

**Holdings.** VERIFIED LIVE. One directory per state/territory (AK, AL, AR, AS, AZ, CA, CO, CT, DC, DE, FL, FM, GA, GU, HI, IA, ID, IL, IN, ... verified present), each containing GPKG/ and Shape/ subtrees with one bundle per 7.5-minute quadrangle. VERIFIED naming: VECTOR_{QuadName}_{ST}_7_5_Min_GPKG.zip with a .jpg browse image and .xml FGDC metadata alongside, e.g. VECTOR_Abarr_CO_7_5_Min_GPKG.zip.

**Access method.** Anonymous HTTPS; enumerate with S3 list-objects-v2 against the state prefix.

**Format returned.** OGC GeoPackage (and shapefile) containing the layered content of the modern US Topo: structures, transportation, hydrography, boundaries, elevation contours, GNIS names, woodland.

**Search technique.** Use this as the MODERN half of a map-differencing pipeline: extract structure and transportation features from the current vector quad, then compare against features digitised or visually read from the HTMC raster for the same cell. A road present on the 1961 sheet and absent from the current vector layer is a removed access route — which is a real and repeatable signal.

**Rate limits.** None observed; there are tens of thousands of quad bundles, so enumerate from the S3 listing rather than guessing names.

**Robots / ToS posture.** Public bulk channel.

**Notes.** Companion national roll-ups verified present: StagedProducts/Struct/National/GPKG/Structures_National_GPKG.zip (national structures point layer) and StagedProducts/MapIndices/National/GPKG/MapIndices_National_GPKG.zip (the authoritative 7.5-minute, 15-minute, 30x60-minute and 1x2-degree quadrangle grids, which are the join key between every USGS product on this beat — load them first).

---

### 2.26 · NETR HistoricAerials (historicaerials.com)

`LOW` · tier **P4** · <https://www.historicaerials.com/>

*Serves:* fast visual triage

**Holdings.** Commercial aggregator of historical aerial photography and historical topographic maps, decade-by-decade from the 1930s, with a side-by-side viewer. Its topo layer is the same USGS HTMC corpus; its aerial layer aggregates federal and commercial sources.

**Access method.** Web viewer. Free to browse at reduced resolution; full-resolution georeferenced imagery is a paid product. No public API.

**Format returned.** Web tiles; paid downloads as georeferenced imagery.

**Search technique.** Useful as a five-second human sanity check on whether a candidate site has visible change across decades, before committing to a proper EROS or lidar pull. Nothing here should ever be a citation of record.

**Rate limits.** N/A — do not automate.

**Robots / ToS posture.** Commercial site with terms prohibiting automated access and redistribution. DO NOT SCRAPE. Do not mirror tiles.

**Notes.** Explicitly deprioritised. Its topo layer is HTMC, which we have in full and for free; its aerial layer is derivative. Include it in the registry only so that future contributors know it was considered and rejected on provenance and terms grounds, and so that folklore sourced to a HistoricAerials screenshot can be traced back to the underlying federal frame.

---

## Gaps for this beat — the expected-record raw material

*Every statement here becomes, or should become, a row in `registry.erp_profile`. A record
class that does not exist for a given authority, era or classification posture is **X0** and
produces **no row** — not a zero. This is what licenses the argument from silence in one case
and forbids it in another.*

WHAT THIS BEAT CANNOT DO.

1. It cannot see underground, with one exception. Every source here except state mine-map repositories observes the surface. Topographic sheets show where a portal is, not where the tunnel goes — and USGS states explicitly that the adit symbol is drawn perpendicular to the slope rather than along the tunnel's true bearing, so even the apparent directional information is not directional information. Lidar sees the ground surface and, at best, a few metres down an open portal. The ONLY sources in this registry that depict subsurface geometry are the state underground mine-map repositories (Pennsylvania's 100,000+ scans being the deepest), and those cover coal and industrial minerals, not purpose-built hardened construction. For anything excavated by the government for the government, there is no public plan-view. That gap cannot be closed by more geospatial harvesting; it needs engineering drawings from NEPA documents, GAO and DoD IG audits, construction appropriations, and Corps of Engineers records — other beats' territory.

2. Cartographic suppression is real, systematic, and mostly unmeasured. USGS omitted or generalised sensitive installations on quadrangle sheets, particularly from the 1950s through the 1980s. We can DETECT specific instances by comparing a sheet against the aerial photography it was drawn from (the inventory's aerial_photo_year makes this tractable). What does not exist publicly is the policy record: which sites were suppressed, under whose authority, by what criteria, in which years. That record — if it survives — would be an internal NGP or predecessor administrative file, reachable only by FOIA or by NARA research in USGS record groups. Until then, every suppression finding is a one-off inference and should be graded as such, never as a general pattern.

3. Lidar coverage is not uniform and its gaps are not random. WESM verifiably holds 3,269 work units, but coverage skews to populated, flood-prone and economically active areas because acquisitions are cost-shared with states and local partners. Remote federal land — exactly where hardened construction is most likely — is systematically under-flown. Worse and unquantified: some acquisitions over sensitive federal installations are believed to be withheld or degraded before public release, but I could not confirm any specific instance and will not assert one. A verifiable, tractable piece of follow-up work: intersect the WESM footprint union against DoD and DOE installation boundaries and report the coverage gaps quantitatively. If particular installations are conspicuous holes in otherwise complete state-wide acquisitions, that is a finding, and it is one nobody appears to have published.

4. Pre-1937 has essentially no aerial imagery, and pre-1960 has no satellite imagery. For facilities built during the Second World War or the earliest Cold War, the ONLY contemporaneous remote observation is NARA RG 373 domestic-flown photography and scattered USDA and state acquisitions — and RG 373 is 30 million frames indexed by spot number in a paper finding aid at College Park. It is not machine-accessible, will not become machine-accessible on any timescale relevant to this project, and no amount of engineering substitutes for a research trip or a paid researcher.

5. Several genuinely important corpora are paywalled or fee-based per item: APFO historical film (scan-on-demand, weeks, per-frame fees), NARA reproduction services, EarthExplorer scan-on-demand for unscanned frames, and OpenTopography Plus for anyone hitting the 50-call non-academic ceiling. The register should carry an explicit "research debt" field so an unpurchased frame is visible as a known gap rather than invisible as an absence.

6. Coordinate quality varies by orders of magnitude across these sources and there is no shared accuracy metadata. MRDS legacy records are frequently township-range centroids accurate to a section or worse. GNIS coordinates for tunnels and caves are often quad-derived approximations. MSHA coordinates are operator-reported and self-attested. USMIN points are digitised from raster sheets whose own NAD27 georeferencing carries 50 to 100 m of datum shift. Lidar and modern imagery are sub-metre. A naive spatial join at a 100 m tolerance will produce both false matches and false negatives. The schema needs a per-source positional-uncertainty field from day one, and the join logic needs to be uncertainty-aware, or the register will quietly manufacture correlations that are artefacts of coordinate error.

7. NRHP has a stated, structural exclusion: restricted and sensitive features are removed from the public spatial dataset. NRHP absence is therefore never evidence of anything. The same caution applies more weakly to several state datasets.

8. Nothing in this beat establishes FUNCTION. Geospatial evidence can establish that an excavation exists, roughly how large it is, when it appeared, and what it is connected to. It cannot establish what is inside or what it is for. Every finding here is an upper bound on physical fact and a zero on purpose. The register's grading must keep those separate, or a well-measured spoil pile will get read as a well-evidenced claim about continuity of government, which it is not.

9. UNTESTED SPECIFICS, flagged for the first harvester run. TNM Access exact dataset label strings; USMIN's precise attribute schema and current version; MSHA's exact flat-file names and column definitions; FAA's current FeatureServer IDs and field names; NPS mapservices layer indices. All are from search results rather than direct inspection because those hosts were unreachable from this sandbox. Each is a five-minute verification against the service's own ?f=pjson or definition file, and each will silently break a loader if assumed.


# BEAT 3 — MONEY, PROPERTY, PROCUREMENT AND ENVIRONMENTAL FILINGS

**Beat as scoped:** Money, property, procurement, and environmental filings — federal spending, real property inventory and disposal, appropriations/MILCON, NEPA and environmental compliance records, land title, and corporate-entity tracing, as applied to detecting hardened, buried, and continuity-of-government construction.

**Primary agent:** LEDGER · **37 sources**

## Access notes for this beat

SESSION LIMITATION, STATED PLAINLY. This machine's egress proxy blocked nearly every government host I tried to visit directly (api.usaspending.gov, www.fpds.gov, api.sam.gov, cedar/cdxapps.epa.gov, www.gsa.gov, comptroller.war.gov, catalog.data.gov, open.gsa.gov, huggingface.co, govtribe.com, en.wikipedia.org all returned EGRESS_BLOCKED or DNS failure). Only github.com/raw.githubusercontent.com were reachable, plus web search. Consequence: URL patterns, field names, code values and behaviours below are drawn from official documentation surfaced through search and from the USAspending api_contracts repository, which I did read directly. Anything I could not open with my own tools is flagged as unverified in the source's notes. Nothing here should be treated as live-tested. Re-verify each endpoint on a machine with open egress before writing a harvester against it, and in particular pull the OpenAPI/contract documents (open.gsa.gov specs, the FPDS ATOM wiki, the FRPP data dictionary, the PSC Manual DOCX) as the ground truth.

PROVENANCE TIERS AS USED HERE. P1 = the government's own primary record, published by the body that created it. P2 = an official secondary or summary product (GAO audits, Base Structure Report summaries) that reports on records held elsewhere. P3 = a non-governmental curated aggregation of primary records (OpenOMB, NEPATEC, NEPAccess) — searchable, but always resolve and cite the P1 original. P4 = commercial/proprietary normalisation (Regrid, GovFiles). P5 = uncorroborated. In practice the register should search P3 and cite P1.

API KEYS. api.data.gov issues one key that works across SAM.gov (opportunities, entity, contract data), GovInfo, and Congress.gov. Get it early — a SAM.gov key can take up to ten business days, and an unassociated public key is throttled to roughly ten requests a day, which is unusable. Register the key against a SAM-registered entity if you can. USAspending, the Federal Register API, and EPA Envirofacts need no key at all; those three are the ones to lean on for volume.

RATE-LIMIT REALITY. USAspending search endpoints are slow and will 504 under concurrency — for anything at scale, restore the monthly PostgreSQL dump locally instead of calling the API. FPDS ATOM is capped at ten records per page, so window queries by date rather than paginating deep. SAM.gov throws 429s at roughly 20 requests/minute regardless of the documented daily quota; pace at 1 rps. ArcGIS FeatureServers cap at 1,000–2,000 features per query — use the Hub bundled downloads. The FRPP map application caps CSV export at 2,000 rows; take the annual full CSV instead. Federal Register allows 1,000 documents per page with no key and no enforced limit, which makes it the cheapest high-volume monitor available.

ROBOTS AND TERMS. I could not fetch a single robots.txt this session, so every posture note is inference from documentation rather than observation. Fetch and honour robots.txt per host before any crawl. Three categories deserve real care: (1) county recorder and assessor portals frequently prohibit automated access in their terms even though the underlying records are public — where they do, use the county's bulk-data purchase program, a public-records request, or a licensed aggregator, not a scraper; (2) state business-entity search portals commonly CAPTCHA and prohibit automation — use the official bulk exports the ~27 states that offer them provide; (3) .mil hosts often carry restrictive robots.txt even for public-affairs PDF directories. Where a government body publishes a bulk repository or an API alongside a web UI (GovInfo, USAspending, ArcGIS Hub, Federal Register), using the machine channel rather than the UI is both the polite choice and the explicitly intended one.

PRESERVATION URGENCY — ACT ON THESE FIRST. Several corpora on this beat are actively disappearing. FPDS.gov was decommissioned as a search site on 24 February 2026 and its ATOM feed retires later in FY2026; mirror the feed and the fpds.gov/downloads bulk extracts now. The DoD Comptroller domain has moved from comptroller.defense.gov to comptroller.war.gov, so existing link sets are already breaking and old URLs may not redirect indefinitely. The OMB apportionment site was taken offline in March 2025 and only restored in August 2025 under court order — its availability is politically contingent. The Public Buildings Reform Board sunsets 31 December 2026 and its reports may go with it. The Base Structure Report stopped being published in its familiar public form after the FY2018 baseline. In a register whose premise is that this material is public but unindexed, "public" has a shelf life, and mirroring with dated snapshots is part of the evidence, not overhead.

THE CENTRAL CORRELATION METHOD. No single source on this beat proves a hardened facility. The method is a join, and it runs in this order: (1) a design or A&E contract (PSC C1*) or a sources-sought notice on SAM.gov names an intent 18–36 months early; (2) a DD Form 1391 in the MILCON justification book gives the installation, CATCODE, scope and cost; (3) the cost-per-square-foot compared against the UFC 3-701-01 pricing factor for that CATCODE, and the scope compared against the AFMAN 32-1084 allowance, quantifies the excess capability being bought; (4) an EA or EIS gives the site coordinates, disturbed acreage and excavation depth; (5) a dewatering or §404 permit confirms digging below the water table; (6) USAspending or FPDS gives the awardee, the obligation timeline and the place of performance; (7) FRPP or the Base Structure Report shows whether the resulting asset ever appears in the public inventory; (8) county deeds and parcel data establish who holds the ground. Each step is independently citable, each carries a different evidence grade, and the interesting candidates are the ones where a step is *missing* — money obligated with no NEPA document, a dewatering permit with no building permit, an inventory that gains structures no project explains.

DOCUMENT-PROCESSING BURDEN. Budget justification books before roughly 2008, Base Structure Reports, EIS appendices, GSA disposal brochures, and anything from county recorders are scanned images. Budget an OCR pipeline (and a table-extraction pass — DD 1391 cost breakdowns and committee-report project tables are tabular, and naive text extraction destroys the row alignment that makes them useful). Keep the original PDF alongside the extracted text; the register's credibility depends on being able to show the page.

## High-yield query strings for this beat

- USAspending POST /api/v2/search/spending_by_award/ with filters {tas_codes:{require:[["021","2050"]]}, psc_codes:{require:[["Y"],["Y","Y1"]]}, time_period:[{start_date:"2001-10-01",end_date:"2026-09-30"}]} — full MILCON Army construction ledger by TAS+PSC
- USAspending keyword battery over award description: "hardened" | "blast door" | "blast resistant" | "EMP" | "HEMP" | "MIL-STD-188-125" | "shielded enclosure" | "Faraday" | "TEMPEST" | "SCIF" | "ICD 705" | "ICS 705" | "earth covered magazine" | "vault door" | "rock bolt" | "shotcrete" | "tunnel" | "shaft" | "cut and cover" | "below grade" | "dewatering" | "continuity of operations" | "alternate command" | "relocation facility"
- FPDS ATOM: https://www.fpds.gov/ezsearch/FEEDS/ATOM?FEEDNAME=PUBLIC&templateName=1.5.3&q=PRODUCT_OR_SERVICE_CODE:Y1EA+SIGNED_DATE:[2015/01/01,2026/01/01]&start=0 (then start=10,20,…)
- FPDS ATOM: q=CONTRACTING_OFFICE_ID:W9128F (USACE Omaha District, home of the Protective Design Center) — surfaces protective-design work for sites physically located elsewhere
- SAM.gov Opportunities: GET https://api.sam.gov/opportunities/v2/search?api_key=KEY&postedFrom=01/01/2020&postedTo=12/31/2026&ccode=Y1EA&limit=1000 (note: dates MUST be MM/dd/yyyy)
- SAM.gov Opportunities filtered to Justification & Approval notice types — sole-source J&As must publicly explain why only one vendor can perform, and name the facility
- DoD budget justification: https://comptroller.war.gov/Portals/45/Documents/defbudget/{fy2001..FY2027}/budget_justification/pdfs/07_Military_Construction/{01..25}-{Component}.pdf — enumerate FY (try both 'fy2013' and 'FY2025' casing) and the two-digit component prefix
- `Grep extracted MILCON J-book text for: "CLASSIFIED LOCATION" | "CLASSIFIED PROJECT" | "CATEGORY CODE" | "PROJECT NUMBER" | "IMPACT IF NOT PROVIDED"`
- DoD reprogramming: https://comptroller.war.gov/Portals/45/Documents/execution/reprogramming/fy{YYYY}/prior1415s/{YY}-{NN}_PA_{Month}_{YYYY}_Request.pdf and .../ir1415s/{YY}-{NN}_IR_... — enumerate NN until 404; grep for "2803" "2804" "2805" "unspecified minor" "emergency construction"
- EPA EIS Database enumeration: https://cdxapps.epa.gov/cdx-enepa-II/public/action/eis/details?eisId={300000..540000} and attachment fetch ?downloadAttachment=&attachmentId={int}
- Federal Register API: /api/v1/documents.json?conditions[term]=%22notice+of+intent+to+prepare+an+environmental+impact+statement%22&conditions[agencies][]=defense-department&per_page=1000&fields[]=full_text_xml_url
- `Federal Register API: conditions[term]="public land order" AND "withdrawal" AND military — locates every military land withdrawal with its PLO citation`
- GovInfo package enumeration for appropriations report tables: CRPT-{108..119}{h|s}rpt{NNN}, filtered to Military Construction–VA and Defense subcommittee reports; full-text the project tables
- WBDG per-CATCODE facility standards: https://www.wbdg.org/FFC/AF/AFMAN/{catcode}_{Title}.pdf — sweep CATCODE space to recover the square-footage allowance library (observed example: 730835_Security_Forces_Operations.pdf)
- FUDS FeatureServer: {service}/1/query?where=1%3D1&outFields=*&f=geojson&resultOffset={n}&resultRecordCount=2000 (layer 1 = Property Point, layer 4 = Property Polygon); filter property names for Nike | Titan | Atlas | Minuteman | SAGE | gap filler | radar | control | annex
- EPA Envirofacts: https://data.epa.gov/efservice/sems.envirofacts_site/state_code/equals/{ST}/JSON and joined form /sems.envirofacts_site/left/sems.envirofacts_contaminants/site_id/equals/fk_site_id
- County recorder grantor/grantee name searches: "UNITED STATES OF AMERICA" | "SECRETARY OF THE ARMY" | "SECRETARY OF THE AIR FORCE" | "SECRETARY OF THE NAVY" | "ATOMIC ENERGY COMMISSION" | "ADMINISTRATOR OF GENERAL SERVICES" — search as BOTH grantor and grantee, and pull easements separately from deeds
- GSA disposal offering brochures full-text: "underground" | "bunker" | "vault" | "magazine" | "tunnel" | "subsurface structure" | "abandoned in place" | "sealed" | "restrictive covenant" + "excavation"
- NAICS sweep for underground work: 237990 (Other Heavy and Civil Engineering — tunnels/shafts), 213115 (drilling and blasting support), 238910 (site prep), 238990 (RF/EMI shielding), 332312/332439 (blast doors, pressure vessels), 541330 (engineering)
- `OMB apportionment / OpenOMB footnote full-text search for project names within TAFS 021-2050, 017-1205, 057-3300, 097-0500 and the 089-* DOE defense accounts`
- Cost-anomaly screen: for each DD 1391, compute (project unit cost) ÷ (UFC 3-701-01 pricing factor for its CATCODE); rank descending — the top of that list is the hardening candidate set

## Sources

### 3.1 · DoD Comptroller budget justification archive (MILCON 'J-books' and DD Form 1391s)

`CRITICAL` · tier **P1** · <https://comptroller.war.gov/Budget-Materials/>

*Serves:* facility_existence · construction_timeline · cost_scale · geolocation · hardening_signature

**Holdings.** The single most information-dense open corpus on this beat. Every fiscal year's Military Construction justification book contains a DD Form 1391 per project: installation, project title, five-digit CATCODE, scope in square meters/feet, unit cost, total cost, a narrative REQUIREMENT/CURRENT SITUATION/IMPACT IF NOT PROVIDED, and an itemized cost breakdown that lists individual construction elements. Archive runs back to roughly FY2000. Also includes the C-1 Construction Annex exhibit summarizing all MILCON across appropriations.

**Access method.** Static PDF download from a predictable directory tree. No API. Text-layer quality varies; older years need OCR.

**Format returned.** PDF (mostly with text layer post-2010; pre-2008 often image-only).

**Search technique.** URL pattern (confirmed across multiple fiscal years): https://comptroller.war.gov/Portals/45/Documents/defbudget/{fy}/budget_justification/pdfs/07_Military_Construction/{NN}-{Component_Name}.pdf where {fy} appears as both 'fy2013' and 'FY2025' (case varies by year — try both), and {NN} is a two-digit ordinal prefix on the component (e.g. 07-Defense_Finance_and_Accounting_Service, 12-US_Special_Operations_Command, 19-Host_Country_In-Kind_Contribution). Enumerate NN from 01 to ~25 for each FY. The '07_Military_Construction' directory is the MILCON one; sibling directories hold RDT&E, Procurement, and O&M justifications. Once downloaded, regex the extracted text for: 'CATEGORY CODE', 'PROJECT NUMBER', 'CLASSIFIED LOCATION', 'CLASSIFIED PROJECT', 'hardened', 'HEMP', 'EMP', 'blast', 'below grade', 'underground', 'SCIF', 'ICD 705', 'C4I', 'command center', 'COOP', 'alternate'.

**Rate limits.** None published. Static file host; be polite (≤1 rps).

**Robots / ToS posture.** Not verifiable from this session (egress-blocked). Check https://comptroller.war.gov/robots.txt. Note the domain migrated from comptroller.defense.gov to comptroller.war.gov — old URLs may redirect or 404, and your archived link set will need rewriting.

**Notes.** THE HIGHEST-VALUE PATTERN IN THIS BEAT: line items literally titled 'Classified Project' at 'Classified Location' or with a redacted installation. They carry a real dollar amount, a real appropriation, and a real fiscal year even when scope and place are withheld — which means the *existence* of an unnamed hardened program is documented at P1 even when its location is not. Diffing the classified-line total across fiscal years, and against the C-1 annex totals, is a legitimate inference channel. Second-order tell: a project whose unit cost per square foot is a large multiple of the UFC 3-701-01 pricing-guide factor for its CATCODE is buying something the CATCODE doesn't describe — hardening, shielding, or depth.

---

### 3.2 · EPA Environmental Impact Statement Database (CDX e-NEPA II)

`CRITICAL` · tier **P1** · <https://cdxapps.epa.gov/cdx-enepa-II/public/action/eis/search>

*Serves:* facility_existence · geolocation · construction_timeline · environmental_footprint · hardening_signature

**Holdings.** Every EIS filed with EPA since 1987 (metadata) with full PDF documents for filings since roughly October 2012: draft, final, supplemental, and adoption notices, plus EPA's own comment letters. For a hardened or buried facility, the EIS and its appendices routinely contain the site plan, the acreage disturbed, the excavation depth, the utility loads, the geotechnical summary, and the alternatives analysis explaining why *this* site.

**Access method.** Web application; no documented public API. Practical harvesting is by URL enumeration.

**Format returned.** HTML detail pages; attachments as PDF (large, often 100+ MB, frequently scanned appendices requiring OCR).

**Search technique.** Two enumerable URL patterns, confirmed: detail page https://cdxapps.epa.gov/cdx-enepa-II/public/action/eis/details?eisId={int} (observed values in the 300,000–540,000 range — a dense integer space you can sweep), and attachment fetch https://cdxapps.epa.gov/cdx-enepa-II/public/action/eis/details?downloadAttachment=&attachmentId={int}. Sweeping eisId is the reliable way to get complete coverage, because the search form's filters (state, agency, document type, comment period) are hard to exhaust. Separately, note that the *EIS Number* (the citable identifier, format YYYYNNNN) is distinct from the internal eisId — capture both.

**Rate limits.** Not published. Java/JSP application with jsessionid in paths — expect session-cookie handling and be conservative (≤0.5 rps) to avoid tripping WAF rules.

**Robots / ToS posture.** Not verifiable this session. Check https://cdxapps.epa.gov/robots.txt. Mirror at https://cdxnodengn.epa.gov/cdx-enepa-II/public/action/eis/search — useful as a fallback host, but do not double the load.

**Notes.** Filter to lead agencies DoD/Army/Navy/Air Force/DOE/GSA/DHS/NNSA, then read the alternatives chapter. NEPA documents are written by contractors who are not thinking about OPSEC, and the geotechnical and utility appendices are where depth, rock type, and power draw appear in plain text.

---

### 3.3 · Federal Register API

`CRITICAL` · tier **P1** · <https://www.federalregister.gov/api/v1/documents.json>

*Serves:* facility_existence · construction_timeline · geolocation · ownership_custody

**Holdings.** Every Federal Register document 1994–present, with full text search from 2000. Directly relevant document types: EPA's weekly 'Environmental Impact Statements; Notice of Availability' (which lists every EIS filed that week with number, title, lead agency and contact), agency Notices of Intent to prepare an EIS, Records of Decision, Public Land Orders (military land withdrawals), airspace and restricted-area actions, and Public Buildings Reform Board and NCPC meeting notices.

**Access method.** Public REST API, no key, no authentication.

**Format returned.** JSON or CSV metadata; per-document links to HTML, PDF, plain text, and full_text_xml_url.

**Search technique.** GET /api/v1/documents.json?conditions[term]={query}&conditions[agencies][]={slug}&conditions[type][]=NOTICE&conditions[publication_date][gte]=&per_page=1000&fields[]=document_number&fields[]=title&fields[]=full_text_xml_url&fields[]=agencies&fields[]=publication_date. Standing queries worth running weekly: 'notice of intent to prepare an environmental impact statement' scoped to DoD/DOE agency slugs; 'public land order' + 'withdrawal' + 'military'; 'record of decision' + installation names; 'notice of realty action'. Because full_text_xml_url gives you clean structured text, this is the cheapest full-text NEPA and land-action monitor available.

**Rate limits.** No enforced limit for reasonable use. Up to 1,000 documents per page.

**Robots / ToS posture.** Explicitly public and keyless; developer resources published at federalregister.gov/reader-aids/developer-resources/rest-api. The most permissive machine-accessible source on this beat.

**Notes.** The weekly EPA EIS availability notice is effectively a machine-readable changelog for the entire national EIS pipeline — parse it and you never need to poll the CDX application for new filings, only for documents.

---

### 3.4 · GovInfo API and Bulk Data Repository

`CRITICAL` · tier **P1** · <https://api.govinfo.gov/docs/>

*Serves:* facility_existence · cost_scale · construction_timeline · geolocation

**Holdings.** GPO's authenticated-provenance corpus: CRPT (congressional committee reports — the MILCON-VA and Defense appropriations reports contain project-by-project tables with installation names and dollar amounts), CPRT (committee prints, including the annual 'explanatory statement' compilations), BILLS and BILLSTATUS, CHRG (hearing transcripts, where members question officials about specific installations), CREC (Congressional Record, including the explanatory statements for omnibus bills that carry the real project tables), FR (Federal Register), CFR, and GAOREPORTS.

**Access method.** REST API with an api.data.gov key, plus an unauthenticated bulk-data repository.

**Format returned.** XML (bulk), plus PDF/HTML/TXT per package; MODS metadata per package.

**Search technique.** Package IDs are deterministic: CRPT-{congress}{chamber}rpt{number} (e.g. CRPT-117hrpt389), CHRG-{congress}hhrg{number}, BILLS-{congress}{type}{number}{version}. Content URL pattern: https://www.govinfo.gov/content/pkg/{packageId}/html/{packageId}.htm and /pdf/{packageId}.pdf. Harvest every MILCON-VA and Defense appropriations committee report for the last 30 years, then full-text search the tables for installation names and for the phrases 'classified project', 'classified location', 'the Committee directs', 'hardened', 'continuity of operations'. Committee report language is where Congress adds, deletes, or quietly renames projects — the report table and the bill text frequently disagree, and the disagreement is the signal.

**Rate limits.** api.data.gov tiering (default ~1,000 requests/hour for a standard key). Bulk repository is unthrottled static hosting.

**Robots / ToS posture.** Bulk data repository exists precisely to keep crawlers off the search UI — use it. Any bulkdata page accepts /xml or /json appended after 'bulkdata' in the path to get a machine-readable directory listing.

**Notes.** GPO packages carry digital signatures and an 'authenticated' flag — the strongest provenance available for a congressional document, which matters when the register grades evidence quality rather than asserting fact.

---

### 3.5 · GSA Federal Real Property Profile (FRPP) Public Data Set

`CRITICAL` · tier **P1** · <https://www.gsa.gov/policy-regulations/policy/real-property-policy-division-overview/asset-management/federal-real-property-profile/federal-real-property-public-data-set>

*Serves:* facility_existence · geolocation · ownership_custody · disposal_status

**Holdings.** The government-wide inventory of executive-branch real property: buildings, structures, and land. Per-asset records with Real Property Unique Identifier (RPUID), reporting agency and sub-agency, installation name, real property type (Building/Structure/Land), real property use code, legal interest indicator (owned/leased/otherwise managed), status (active/excess/disposed), latitude and longitude, city/county/state, size and unit of measure, utilization, condition index, mission dependency, annual operating cost, replacement value, historical status, year built, year acquired, and disposition method/date. Current public edition FY2024; archived editions FY2016–FY2023.

**Access method.** CSV download from GSA and from data.gov CKAN; interactive ArcGIS map application; data dictionary published as PDF.

**Format returned.** CSV; ArcGIS feature service behind the map app.

**Search technique.** Read the data dictionary first (https://www.gsa.gov/system/files/FY%202024%20FRPP%20DATA%20DICTIONARY%20Final.pdf) — the use-code taxonomy is what lets you isolate 'Structure' records (which is where non-building hardened assets like magazines, vaults, tunnels and antenna structures land) from 'Building'. Then: (a) filter status = Excess or Disposed and join disposition method/date to GSA disposal and county deed records; (b) filter for structures with a replacement value wildly out of proportion to size; (c) diff successive fiscal-year editions — an RPUID that disappears without a disposal record, or whose lat/long moves, is a data event worth a candidate row.

**Rate limits.** The map application's attribute-table export is capped at 2,000 rows per download — do not harvest through the map. Take the full annual CSV from GSA or data.gov instead.

**Robots / ToS posture.** Data explicitly published for public reuse; contact publicfrppdata@gsa.gov. data.gov CKAN packages carry open licences.

**Notes.** CRITICAL GAP, and itself an evidence channel: the public data set excludes assets withheld for national security, procurement-sensitivity, or FOIA exemption. The gap between an installation's published acreage/asset totals and its FRPP record count is a measurable, citable absence. DoD's contribution is also aggregated relative to what it holds internally in RPAD.

---

### 3.6 · NAICS codes and the DoD FAC/CATCODE Real Property Categorization System

`CRITICAL` · tier **P1** · <https://www.esd.whs.mil/Portals/54/Documents/DD/issuances/dodi/416503p.pdf>

*Serves:* hardening_signature · facility_existence

**Holdings.** Two orthogonal codebooks. NAICS (Census) classifies the *contractor's* industry: 236220 Commercial and Institutional Building Construction, 237990 Other Heavy and Civil Engineering Construction (the tunnel/shaft/underground code), 238910 Site Preparation, 238990 All Other Specialty Trade (RF/EMI shielding installers), 238290 Other Building Equipment, 213115 Support Activities for Nonmetallic Minerals (drilling and blasting), 541330 Engineering Services, 541620 Environmental Consulting, 332312/332439 Fabricated Structural Metal and Metal Tanks (blast doors, pressure vessels). DoD's Real Property Categorization System (RPCS, governed by DoDI 4165.03) classifies the *facility*: four-digit DoD Facility Analysis Category (FAC) codes and five-digit Service CATCODEs, republished annually by 1 April. Air Force per-CATCODE facility standards are published individually on WBDG under DAFMAN 32-1084.

**Access method.** DoDI 4165.03 as PDF; Air Force CATCODE spreadsheet and per-CATCODE standards PDFs on wbdg.org; NAICS tables from Census.

**Format returned.** PDF, XLSX.

**Search technique.** WBDG publishes AFMAN/DAFMAN 32-1084 facility standards as individual PDFs named {catcode}_{Title}.pdf (observed: 730835_Security_Forces_Operations.pdf). That filename convention is enumerable — sweep the CATCODE space and you recover a per-facility-type standards library including the square-footage allowances that a DD 1391 must justify against. Then cross-reference: a 1391 whose requested area or cost exceeds the 32-1084 allowance and the UFC 3-701-01 pricing factor for its CATCODE is buying unlisted capability. CATCODE families worth sweeping: 1xx (operations/airfield, incl. 141x command-and-control and C5ISR), 4xx (storage, incl. ammunition and earth-covered magazines), 6xx (administrative, incl. command posts), 8xx (utilities).

**Rate limits.** Static documents; WBDG is a nonprofit host — crawl gently.

**Robots / ToS posture.** WBDG hosts DoD criteria for public reference; check wbdg.org/robots.txt before enumerating.

**Notes.** UFC 3-701-01 'DoD Facilities Pricing Guide' (on WBDG, with change pages and supplementary cost-factor data files) gives the sanctioned $/unit for each CATCODE. The ratio of a project's actual unit cost to the pricing-guide factor is, in my judgement, the single best purely-quantitative hardening indicator available in open budget data.

---

### 3.7 · Product and Service Code (PSC) Manual — the hardened-construction codebook

`CRITICAL` · tier **P1** · <https://www.acquisition.gov/psc-manual>

*Serves:* hardening_signature · contractor_linkage

**Holdings.** The authoritative four-character taxonomy applied to every federal contract action. Y-series = construction of structures and facilities; Z-series = maintenance, repair and alteration of real property (mirrors the Y suffixes); C-series = architect and engineering services (also mirrors). Confirmed relevant codes include Y1EA Construction of Ammunition Facilities, Y1GA Construction of Ammunition Storage Buildings, Y1GC Construction of Fuel Storage Buildings, Y1ED Ship Construction and Repair Facilities, Y1EE Tank Automotive Facilities, Y1AZ Other Administrative Facilities and Service Buildings. Archived editions back to 2011 let you translate codes that were retired or re-scoped.

**Access method.** PDF and DOCX download from acquisition.gov; also mirrored on fpds.gov/downloads and fedmall.

**Format returned.** PDF and DOCX (the DOCX editions are far easier to parse into a table than the PDFs).

**Search technique.** Parse the DOCX edition into a code table and keep every historical edition — a contract coded Y1EA in 2009 may map to a different description than Y1EA today, and the register needs to say which manual edition it graded against. Then build three parallel sweeps over USAspending/FPDS: Y1* (new construction), Z1*/Z2* (alteration of existing real property — this is where a building gets quietly hardened without a new MILCON line), and C1* (A&E design, which precedes construction by 18–36 months and therefore *leads* the money). The A&E sweep is the underused one: a C-series award for design of an ammunition or communications facility at a site with no subsequent public construction award is a strong anomaly.

**Rate limits.** Static documents.

**Robots / ToS posture.** Published reference material intended for reuse.

**Notes.** PSC alone is weak evidence — contracting officers miscode constantly. Its value is as a recall filter feeding keyword and geography analysis, never as a classifier on its own.

---

### 3.8 · SAM.gov Contract Data API (FPDS successor)

`CRITICAL` · tier **P1** · <https://open.gsa.gov/api/contract-awards/>

*Serves:* contractor_linkage · construction_timeline · cost_scale · geolocation

**Holdings.** The RESTful replacement for the FPDS ATOM feed — same contract action report corpus, served from SAM.gov. GSA publishes a field-by-field crosswalk from FPDS ATOM tags to the new JSON schema.

**Access method.** REST/JSON with an api.data.gov key passed as api_key.

**Format returned.** JSON.

**Search technique.** Start from the migration crosswalk PDF at https://open.gsa.gov/api/contract-awards/v1/FPDSvsSAM-ContractDataAPI.pdf — it maps every legacy ATOM element to its new field name, which is exactly what you need to keep a harvester that already speaks FPDS working. Build the harvester against the crosswalk, not against your memory of FPDS field names.

**Rate limits.** Governed by api.data.gov tiering (see SAM.gov Opportunities entry). Public/unassociated keys are heavily throttled; a key tied to a registered SAM entity gets substantially more.

**Robots / ToS posture.** Documented public API; GSA actively directs FPDS consumers here.

**Notes.** As of this research pass I could not reach open.gsa.gov to read the live parameter list (egress-blocked). Treat the parameter set as unverified and pull the OpenAPI spec from open.gsa.gov before writing the client.

---

### 3.9 · SAM.gov Get Opportunities Public API

`CRITICAL` · tier **P1** · <https://api.sam.gov/opportunities/v2/search>

*Serves:* facility_existence · construction_timeline · hardening_signature · contractor_linkage · geolocation

**Holdings.** All contract opportunity notices: presolicitations, solicitations, sources-sought, special notices, award notices, and — most valuable here — Justification & Approval (J&A) documents for sole-source awards, which must publicly explain *why* only one vendor can do the work. Attachments (SOWs, drawings sets, wage determinations, site-visit instructions) are downloadable per notice.

**Access method.** REST/JSON, api.data.gov key as api_key query parameter.

**Format returned.** JSON metadata; attachments as PDF/DOCX/ZIP, frequently scanned and needing OCR.

**Search technique.** Date filters MUST be MM/dd/yyyy, not ISO-8601 — this is the single most common integration failure. Core params: postedFrom, postedTo, ncode (NAICS), ccode (PSC/classification code), ptype (notice type), state, zip, deptname, subtier, limit (max 1000), offset. Sweep ccode across the Y1*/Z1*/C1* families and ptype across sources-sought and special-notice types: a sources-sought for a hardened facility is often posted months before any obligation appears in USAspending, so this corpus *leads* the money. J&A notices are the highest-yield single document type — they name the incumbent, the facility, and the reason for exclusivity.

**Rate limits.** Documented tiers: ~10 requests/day for a bare public key, ~1,000/day for a key associated with a registered SAM entity, ~10,000/day for federal system accounts. Field reports of 429s after ~20 requests/minute regardless of daily quota — pace at ≤1 rps. Key issuance can take up to ten business days.

**Robots / ToS posture.** Official public API. Scraping the sam.gov SPA instead is discouraged and rate-limited more aggressively; use the API.

**Notes.** Attachments are the payload. A single site-visit notice can carry a floorplan, a utility tie-in drawing, or a survey with coordinates. Archive attachments, not just metadata — notices are removed from the active index after the archive date.

---

### 3.10 · USACE Formerly Used Defense Sites (FUDS) GIS

`CRITICAL` · tier **P1** · <https://geospatial-usace.opendata.arcgis.com/datasets/3f8354667d5b4b1b8ad7a6e00c3cf3b1>

*Serves:* facility_existence · geolocation · ownership_custody · disposal_status · environmental_footprint

**Holdings.** Every property formerly owned, leased or otherwise used by DoD and transferred out before 17 October 1986: property point and polygon geometries, FUDS property number, installation ID, property name, eligibility determination, project types (HTRW, MMRP, containerised HTRW, building demolition/debris removal), and links to Management Action Plans. Published annually (FY22, FY23, FY24 editions observed) plus a HIFLD-hosted public-properties layer.

**Access method.** ArcGIS Hub open data — direct downloads plus a live ArcGIS REST FeatureServer.

**Format returned.** CSV, GeoJSON, KML, Shapefile, File Geodatabase; GeoServices REST, WMS, WFS.

**Search technique.** FeatureServer query pattern: {serviceUrl}/{layerId}/query?where=1%3D1&outFields=*&f=geojson&resultOffset={n}&resultRecordCount=2000. Layer suffix _1 is FUDS Property Point, _4 is FUDS Property Polygon. FUDS property numbers encode state and sequence (pattern like B01NE0123 — component/region letter, state code, sequence), which makes them a durable join key. FILTER FOR: project types indicating buried structures, and property names containing 'Nike', 'Titan', 'Atlas', 'Minuteman', 'AAA', 'radar', 'communications', 'control', 'annex', 'reservation'. Then geocode against county parcel layers to find the current private owner of a former hardened site.

**Rate limits.** ArcGIS FeatureServer default page size is 1,000–2,000 features — page with resultOffset/resultRecordCount, or just take the full file download and skip the API.

**Robots / ToS posture.** ArcGIS Hub open-data portals are explicitly for redistribution; each dataset page carries a licence statement. Prefer the bundled download over hammering the FeatureServer.

**Notes.** The best single geospatial source for *decommissioned* hardened infrastructure. Nike missile sites, ICBM launch and launch-control facilities, SAGE and gap-filler radar sites, and AT&T/Autovon relay stations disproportionately land in FUDS.

---

### 3.11 · USAspending bulk data — full PostgreSQL snapshot, Award Data Archive, and AWS RDS snapshot

`CRITICAL` · tier **P1** · <https://files.usaspending.gov/database_download/>

*Serves:* cost_scale · contractor_linkage · construction_timeline · geolocation

**Holdings.** Monthly full PostgreSQL dump of the entire USAspending database (~1.5 TB restored), a smaller sampled dev database, and the Award Data Archive (per-agency, per-fiscal-year prime award CSV zips regenerated monthly) at https://files.usaspending.gov/award_data_archive/. Also published as an Amazon RDS snapshot for direct restore into an RDS instance.

**Access method.** Anonymous HTTPS bulk download of .zip/.dump files; AWS RDS public snapshot restore.

**Format returned.** PostgreSQL custom-format dumps, CSV inside zip archives, RDS snapshot.

**Search technique.** For an unbounded ingest register this is the correct substrate: restore locally and run SQL against transaction_search / award_search rather than hammering the API. Full-text index the award description columns once and you can re-run the whole hardening keyword battery in seconds instead of thousands of API calls. Award Data Archive filenames follow FY{YYYY}_{toptier agency code}_Contracts_Full_{YYYYMMDD}.zip — enumerate agency codes 021 (Army), 017 (Navy), 057 (Air Force), 097 (DoD Defense-Wide), 089 (DOE), 047 (GSA), 070 (DHS).

**Rate limits.** None on the file host beyond bandwidth. Restore of the full dump takes many hours and needs ~2 TB of disk.

**Robots / ToS posture.** Static file host intended for bulk retrieval; setup guide published at https://files.usaspending.gov/database_download/usaspending-db-setup.pdf.

**Notes.** Snapshots are the only way to detect *retroactive edits*: agencies silently modify or delete transactions. Keeping successive monthly dumps and diffing them gives you a provenance trail of when a record changed — directly useful to the register's versioning premise.

---

### 3.12 · USAspending.gov REST API v2

`CRITICAL` · tier **P1** · <https://api.usaspending.gov/api/v2/>

*Serves:* construction_timeline · geolocation · cost_scale · contractor_linkage · facility_existence

**Holdings.** Every prime federal contract, grant, loan and direct-payment transaction FY2001–present, plus sub-award data, federal account (TAS) obligation/outlay by program activity and object class, and DoD File B/C account-level submissions. Award records carry award description text, PSC, NAICS, place-of-performance down to county/ZIP+4 and latitude bucket, awarding/funding agency and office, contract pricing type, extent-competed, IDV parent, and period of performance. This is the single richest correlator between money and a physical location.

**Access method.** Public REST API, POST for search endpoints, no API key, no registration.

**Format returned.** JSON request/response; CSV/TSV/pipe-text for async downloads.

**Search technique.** POST /api/v2/search/spending_by_award/ with a filter object. Exact filter keys (verified against the api_contracts repo): keywords, time_period[{start_date,end_date,date_type: action_date|date_signed|last_modified_date|new_awards_only}], place_of_performance_scope, place_of_performance_locations[{country,state,county}], agencies[{type:funding|awarding, tier:toptier|subtier, name}], recipient_search_text, recipient_locations, award_type_codes (["A","B","C","D"] = definitive contracts; IDV_A..IDV_E), award_ids, award_amounts[{lower_bound,upper_bound}], naics_codes{require:[],exclude:[]}, psc_codes{require:[[..]],exclude:[[..]]} (hierarchical arrays) or legacy flat array, tas_codes{require:[[..]]}, treasury_account_components[{aid,main,sub,bpoa,epoa}], object_classes, def_codes, set_aside_type_codes, extent_competed_type_codes, contract_pricing_type_codes. KNOWN QUIRK: spending_by_award returns null for naics_code even when requested in fields[] — use /api/v2/search/spending_by_transaction/ or GET /api/v2/awards/{generated_unique_award_id}/ to recover NAICS. Filter by TAS to isolate MILCON money: aid 021 main 2050 (MILCON Army), 017/1205 (MILCON Navy & Marine Corps), 057/3300 (MILCON Air Force), 097/0500 (MILCON Defense-Wide) — Defense-Wide is where the interesting agencies hide. Combine a TAS filter with psc_codes Y1*/Z1* and place_of_performance_locations to get a per-county MILCON construction ledger.

**Rate limits.** No published hard quota. Practically: search endpoints are heavy and slow; keep concurrency ≤2 and back off on 429/504. Async /download/ jobs are queued server-side and can take tens of minutes.

**Robots / ToS posture.** Public API explicitly published for reuse; no key or ToS acceptance. robots.txt not verifiable from this session (egress blocked) — check https://api.usaspending.gov/robots.txt and https://www.usaspending.gov/robots.txt before crawling the web UI. Prefer the API and bulk files over scraping the SPA.

**Notes.** The award description field is free text typed by a contracting officer and is where hardening language leaks: run keyword filters for 'hardened', 'blast', 'EMP', 'HEMP', 'MIL-STD-188-125', 'shielded enclosure', 'SCIF', 'ICD 705', 'earth covered magazine', 'rock bolt', 'shotcrete', 'tunnel', 'shaft', 'dewatering', 'cut and cover', 'ECM', 'vault door', 'blast door', 'COOP', 'continuity of operations', 'alternate command'. Also mine parent IDV structures — a small hardened job is usually a task order under a MATOC, and the MATOC ceiling and awardee list are more informative than the task order.

---

### 3.13 · BLM Mineral & Land Records System (MLRS) and General Land Office records

`HIGH` · tier **P1** · <https://reports.blm.gov/reports/MLRS>

*Serves:* ownership_custody · geolocation · facility_existence · construction_timeline

**Holdings.** BLM land and mineral use authorisations: withdrawals (including military land withdrawals), classifications, rights-of-way, land and mineral title, and case files on federal lands and federal mineral estate. MLRS has replaced LR2000, ACRES/ALIS, LRAM and CSRC. Separately, GLO records (glorecords.blm.gov) hold historical land patents and survey plats.

**Access method.** Public report generator at reports.blm.gov/reports/MLRS; interactive research map at mlrs.blm.gov requiring login for some functions. No documented public API.

**Format returned.** HTML and CSV/Excel report exports; survey plats and patents as scanned images.

**Search technique.** Run withdrawal reports by state and county and filter for military and defence-agency holders. A military land withdrawal is the mechanism by which public land is set aside for defence use, and the withdrawal case file gives the acreage, the legal description by township/range/section, the withdrawing agency, and the purpose — sometimes stated only as 'defense purposes'. Cross-reference every withdrawal against Public Land Orders published in the Federal Register (searchable via the FR API) for the authoritative citation, and against the FRPP land records for the current status. Legacy LR2000 case-type codes still appear in MLRS data — keep an LR2000 codebook.

**Rate limits.** Report generator is interactive and slow; not built for volume.

**Robots / ToS posture.** Reports application is public-facing. Verify blm.gov/robots.txt; avoid driving the interactive map programmatically.

**Notes.** The right source for the western United States, where a large fraction of hardened and test infrastructure sits on withdrawn public land rather than on fee-owned federal property — and therefore does not appear in fee-ownership parcel data at all.

---

### 3.14 · Congress.gov API v3

`HIGH` · tier **P1** · <https://api.congress.gov/>

*Serves:* construction_timeline · cost_scale

**Holdings.** Structured bill, amendment, committee, member, and CRS-product metadata; links to text versions; committee report associations. CRS products (R-, IF-, IN- series) on military construction authorities, infrastructure funding, and real property policy are the best available orientation documents.

**Access method.** REST, api.data.gov key required.

**Format returned.** JSON or XML.

**Search technique.** Use it to walk the NDAA each year to its military construction title (the §21xx sections authorize projects by installation and amount) and to resolve each authorization to the appropriation that funded it. Cross-reference authorized-but-never-appropriated projects: a project authorized three years running and never funded, then vanishing, is a different story from one that quietly moved to a classified line.

**Rate limits.** 5,000 requests/hour. Default page size 20, max 250.

**Robots / ToS posture.** Official API; congress.gov publishes offsite-developer guidance directing bulk users to GPO bulk data rather than crawling congress.gov.

**Notes.** Bulk bill text and status belong on GovInfo; use this API for the relationship graph, not for text retrieval.

---

### 3.15 · County recorder and assessor land records, and statewide parcel GIS

`HIGH` · tier **P1** · <https://regrid.com/nationwide-parcels>

*Serves:* ownership_custody · geolocation · facility_existence · disposal_status · corporate_shell

**Holdings.** Deeds, easements, rights-of-way, reversionary interests, mortgages, and mechanic's liens (county recorder); parcel geometry, owner name, land use code, improvement value, and year built (county assessor). Regrid aggregates ~158 million parcels at ~99.2% national coverage into one normalised schema; several states (Wisconsin's Statewide Parcel Map Initiative, Florida's FGDL, and others) publish free standardised statewide parcel files.

**Access method.** Free per-county portals (thousands of them, no two alike); free statewide GIS downloads in ~20 states; commercial normalised national coverage from Regrid (~$0.10/parcel, ~$10,000/yr enterprise) and comparable vendors.

**Format returned.** Shapefile, File Geodatabase, GeoJSON, CSV; recorder documents as scanned TIFF/PDF requiring OCR.

**Search technique.** Grantor/grantee name searching is the core technique. Search as grantee AND grantor: 'UNITED STATES OF AMERICA', 'SECRETARY OF THE ARMY', 'SECRETARY OF THE AIR FORCE', 'SECRETARY OF THE NAVY', 'UNITED STATES OF AMERICA ACTING BY AND THROUGH THE ADMINISTRATOR OF GENERAL SERVICES', 'DEPARTMENT OF ENERGY', 'ATOMIC ENERGY COMMISSION'. The AEC and predecessor-agency names are what surface Cold War acquisitions. Also search for easement grantees — a communications or utility easement running to a federal grantee across private land is often the only public trace of a buried cable or an underground facility's power feed. On the parcel side, look for: federally-owned parcels absent from FRPP; parcels with high improvement value and no visible structure; and parcels whose owner is an LLC registered days before the deed date.

**Rate limits.** County portals frequently rate-limit or CAPTCHA. Many prohibit automated access in their terms.

**Robots / ToS posture.** MIXED AND OFTEN RESTRICTIVE. Many county recorder sites explicitly forbid scraping in their terms of use even though the records themselves are public. Read each site's ToS; where scraping is prohibited, the lawful routes are the county's bulk-data purchase program, a public-records request, or a commercial aggregator that has licensed the data.

**Notes.** Reversionary clauses are gold. When federal land is conveyed with a reverter or with deed restrictions on excavation, drilling, or subsurface use, the restriction text describes what is underneath.

---

### 3.16 · DENIX — Defense Environmental Programs Annual Report to Congress and DERP site inventory

`HIGH` · tier **P1** · <https://www.denix.osd.mil/arc/>

*Serves:* facility_existence · geolocation · environmental_footprint · construction_timeline

**Holdings.** Annual Reports to Congress under 10 U.S.C. §2706 with Installation Restoration Program (IRP) and Military Munitions Response Program (MMRP) status tables arranged by installation, state, and DoD component: site identifiers, contaminant types, cleanup phase, and funding. A per-site inventory of environmental liabilities across the entire DoD installation base, going back to the 1990s.

**Access method.** Web portal with per-fiscal-year report pages and downloadable appendices; some years offer customisable report generation.

**Format returned.** PDF and HTML tables; some appendices as XLS.

**Search technique.** The IRP/MMRP status tables are the useful artifact — they enumerate *sites within installations*, at finer granularity than any public real-property inventory. A remediation site whose description implies a subsurface structure (underground storage, buried debris, 'former underground facility', solvent disposal at a specific building number) is a pointer to a physical asset that may not be in FRPP. Cross-join site identifiers to EPA SEMS via Envirofacts.

**Rate limits.** Not published.

**Robots / ToS posture.** Public-facing DoD environmental information portal; verify denix.osd.mil/robots.txt.

**Notes.** Environmental liability is the honest back door into facility existence: a facility can be classified, but the contamination it caused still has to be reported and funded.

---

### 3.17 · DoD Comptroller execution and reprogramming archive (DD 1414, DD 1415-1/-3)

`HIGH` · tier **P1** · <https://comptroller.war.gov/Portals/45/Documents/execution/>

*Serves:* cost_scale · construction_timeline · facility_existence

**Holdings.** DD Form 1414 'Base for Reprogramming Actions' per fiscal year (the congressionally-blessed baseline by appropriation and sub-activity group), and every DD 1415 reprogramming action — prior-approval (1415-1) and internal (1415-3) — each with a source/recipient line item and a written justification. Archive spans FY2000–FY2026.

**Access method.** Static PDF download from an enumerable directory tree.

**Format returned.** PDF, generally with text layer.

**Search technique.** Confirmed URL patterns: /Portals/45/Documents/execution/FY_{YYYY}_DD_1414_Base_for_Reprogramming_Actions.pdf and /Portals/45/Documents/execution/reprogramming/fy{YYYY}/ir1415s/{YY}-{NN}_IR_{Month}_{YYYY}_Request.pdf and /reprogramming/fy{YYYY}/prior1415s/{YY}-{NN}_PA_{Month}_{YYYY}_Request.pdf. Enumerate NN from 01 upward until 404. Grep for 'Military Construction', 'MILCON', 'unspecified minor', 'emergency construction', '2803', '2804', '2805'.

**Rate limits.** None published; static host.

**Robots / ToS posture.** Not verified this session; check robots.txt.

**Notes.** Reprogrammings are where money moves *after* the public budget debate ends, and they are where urgent or newly-classified construction gets funded without a line item. A 10 U.S.C. §2803 (emergency) or §2804 (contingency) construction action, or a §2805 unspecified-minor-construction notification, is a documented admission that a facility was built outside the normal MILCON cycle. §2805 currently covers projects up to $9M, requires Secretary-level approval above $750K, and requires notification to the congressional defense committees within 90 days of obligation above $6M — so the notification letters exist even when the project never appeared in a budget book.

---

### 3.18 · DoD Real Property inventory reporting — Base Structure Report, RPAD, RPUID/RPSUID

`HIGH` · tier **P1** · <https://www.acq.osd.mil/eie/imr/rpid/rp/index.html>

*Serves:* facility_existence · geolocation · ownership_custody · construction_timeline

**Holdings.** The Base Structure Report (a public annual summary of DoD's real property inventory by installation: acreage, building/structure/facility counts, plant replacement value) was published for decades — FY2001 through roughly the FY2018 baseline are readily obtainable — and is the best public per-installation physical-footprint time series. Underneath it, the Real Property Assets Database (RPAD) consolidates the Services' authoritative inventories and is the source for FRPP submissions, congressional reporting and the Facilities Sustainment Model. DAIS issues Real Property Unique Identifiers (RPUID) and Real Property Site Unique Identifiers (RPSUID).

**Access method.** Historical BSR PDFs via agency sites, Internet Archive, DTIC, and third-party mirrors (globalsecurity.org, usbaseproject.com, visualbases.org). RPAD itself is not public — FOIA or contractor-report inference only.

**Format returned.** PDF, mostly with text layer; older editions need OCR.

**Search technique.** Build a per-installation acreage and structure-count time series from every BSR edition you can find, then look for step changes that no MILCON line item explains. An installation that gains several hundred thousand square feet of 'structures' in one year with no corresponding public project is a first-class candidate. RPUID and RPSUID are the join keys between BSR/RPAD, FRPP, and DD Form 1354 real property transfer records — collect them wherever they surface in contract attachments and NEPA appendices.

**Rate limits.** n/a for mirrors; Internet Archive asks for polite crawling.

**Robots / ToS posture.** Mirrors vary. Internet Archive permits programmatic access via its own APIs — use archive.org's item API rather than scraping detail pages.

**Notes.** DoD stopped publishing the BSR in its familiar public form after the FY2018 baseline; GAO-25-106132 ('DOD Real Property: Actions Needed to Improve Oversight of Underutilized and Excess Facilities') is a useful contemporary substitute that quotes current inventory figures.

---

### 3.19 · DOE NEPA document library and Office of Environmental Management EIS/EA table

`HIGH` · tier **P1** · <https://www.energy.gov/nepa/nepa-documents>

*Serves:* facility_existence · geolocation · environmental_footprint · construction_timeline

**Holdings.** DOE's own NEPA corpus, separately numbered as DOE/EIS-#### (and DOE/EA-####), organised by document type and by DOE office, with a dedicated searchable Office of Environmental Management table. Covers weapons-complex sites, national laboratories, the Nevada National Security Site, waste-isolation and underground-test-area programs.

**Access method.** HTML listings with per-document node pages (energy.gov/node/{id}) and PDF attachments. No API.

**Format returned.** HTML plus PDF.

**Search technique.** Harvest the DOE/EIS-#### numbering as a dense sequence (observed into the 0550s) rather than paginating the listing pages. DOE documents are where underground and subsurface construction is most explicitly discussed in open literature — search for 'drift', 'adit', 'shaft', 'underground test area', 'tunnel', 'emplacement', 'subsurface', 'U1a', 'P-Tunnel', 'N-Tunnel'. Cross-index DOE EIS numbers against the EPA EIS Database, which also holds them.

**Rate limits.** Not published; energy.gov is behind a CDN — crawl slowly.

**Robots / ToS posture.** Check energy.gov/robots.txt; the /nepa listings are intended for public browsing.

**Notes.** DOE's site-specific EISs frequently contain historical facility inventories going back decades, including structures that no longer appear in any current inventory — a good source of retired-facility candidates.

---

### 3.20 · DOE OpenNet / OSTI declassified document index

`HIGH` · tier **P1** · <https://www.osti.gov/opennet/>

*Serves:* facility_existence · construction_timeline · ownership_custody

**Holdings.** Roughly 495,000 bibliographic citations and ~147,000 full declassified documents released after October 1994, including FOIA releases and historical collections from across the DOE complex; produced by OSTI on contract for DOE's Office of History and Heritage Resources. Complements the Nuclear Testing Archive and DOE Legacy Management's site records.

**Access method.** Web search interface (osti.gov/opennetadmin); OSTI publishes APIs for its other collections — verify whether OpenNet is covered.

**Format returned.** HTML records; scanned PDFs requiring OCR.

**Search technique.** Search facility-type language rather than site names: 'hardened', 'underground facility', 'emergency relocation', 'continuity', 'protected facility', 'command post', 'shelter', 'tunnel'. OpenNet's value here is *backwards sourcing* — when a folklore claim about a DOE-adjacent site circulates, OpenNet is often where the single real primary document that started it can be found.

**Rate limits.** Not published.

**Robots / ToS posture.** Check osti.gov/robots.txt; OSTI generally supports programmatic access and publishes API documentation for OSTI.GOV.

**Notes.** DOE Legacy Management (energy.gov/lm) maintains site records and a 'considered sites' compilation covering properties evaluated for DOE-predecessor contamination — I could not verify its current URL this session, but it is the right place to look for properties that were once AEC/MED and are now in private hands.

---

### 3.21 · EPA Envirofacts Data Service API (SEMS, RCRAInfo, FRS, ECHO)

`HIGH` · tier **P1** · <https://data.epa.gov/efservice/>

*Serves:* facility_existence · geolocation · environmental_footprint · ownership_custody

**Holdings.** REST access to EPA's internal data holdings, including the Superfund Enterprise Management System (SEMS, successor to CERCLIS since 2014), RCRAInfo, the Facility Registry Service, TRI, ICIS-AIR and NPDES. SEMS carries site identity, location, NPL status, contaminants, and the operable-unit structure of every Superfund site — including the many DoD and DOE federal facility sites.

**Access method.** Unauthenticated REST; the URL *is* the query.

**Format returned.** XML by default; CSV, Excel and JSON on request via a format segment in the path.

**Search technique.** Path grammar: https://data.epa.gov/efservice/{schema.table}/{column}/{operator}/{value}/{format} — e.g. /sems.envirofacts_site/state_code/equals/NV/JSON. Joins are expressed inline: /sems.envirofacts_site/left/sems.envirofacts_contaminants/site_id/equals/fk_site_id. Also available as an ArcGIS layer: https://geodata.epa.gov/arcgis/rest/services/OEI/FRS_INTERESTS/MapServer/21 (SEMS).

**Rate limits.** Not published; be conservative and cache.

**Robots / ToS posture.** Explicitly built as a public data service to all Envirofacts holdings; documented at epa.gov/enviro/envirofacts-data-service-api.

**Notes.** Use SEMS to establish that *something industrial existed* at a location and when — Superfund site boundaries and operable units often trace the footprint of structures that were demolished before any public inventory recorded them.

---

### 3.22 · FPDS-NG ATOM feed (legacy, sunsetting)

`HIGH` · tier **P1** · <https://www.fpds.gov/ezsearch/FEEDS/ATOM?FEEDNAME=PUBLIC&templateName=1.5.3&q=>

*Serves:* contractor_linkage · construction_timeline · cost_scale · geolocation

**Holdings.** Raw contract action reports (CARs) as filed — the authoritative source behind USAspending contract data, with roughly 200 fields per action, including several USAspending drops or flattens: contracting office code, funding office code, solicitation procedures, IDV type and multiple-award indicator, national interest action code, DoD claimant program code, DoD acquisition program (MDAP) code, cost-or-pricing-data flags, and construction-specific flags (Davis-Bacon, Service Contract Act, walsh-healey).

**Access method.** Unauthenticated HTTP GET returning Atom 1.0 XML.

**Format returned.** Atom/XML.

**Search technique.** The q= parameter is a space-separated field:value expression, NOT a set of URL parameters. Useful keys: PIID, IDV_PIID, MOD_NUMBER, AGENCY_CODE, CONTRACTING_AGENCY_ID, CONTRACTING_OFFICE_ID, FUNDING_AGENCY_ID, PRINCIPAL_NAICS_CODE, PRODUCT_OR_SERVICE_CODE, VENDOR_UEI, VENDOR_NAME, VENDOR_DUNS_NUMBER (legacy), SIGNED_DATE, LAST_MOD_DATE, DATE_SIGNED, PLACE_OF_PERFORMANCE_STATE, PLACE_OF_PERFORMANCE_ZIP_CODE, DESCRIPTION_OF_REQUIREMENT. Date ranges use bracket syntax: LAST_MOD_DATE:[2026/06/25,2026/06/26]. Example: q=PRODUCT_OR_SERVICE_CODE:Y1EA SIGNED_DATE:[2020/01/01,2026/01/01]. The python package `fpds` (github.com/dherincx92/fpds) is a working reference implementation and converts colons to equals signs on the CLI.

**Rate limits.** Ten records per page, hard. Paginate with &start=N (0,10,20…). Undocumented server-side throttling; sequential requests with ~1s spacing are tolerated. Deep pagination past ~10,000 records degrades — window your query by SIGNED_DATE or LAST_MOD_DATE ranges instead.

**Robots / ToS posture.** Feed is published for machine consumption. FPDS.gov itself was decommissioned as a search site on 24 February 2026 and the ATOM feed is scheduled for retirement later in FY2026 — treat this as a preservation-urgency source.

**Notes.** MIRROR THIS NOW. When the feed retires, the only route to as-filed CARs will be SAM.gov's replacement API, and historical fidelity across the migration is not guaranteed. Also grab the bulk historical extracts and the PSC/NAICS reference downloads under fpds.gov/downloads/ while they exist.

---

### 3.23 · GAO reports and DoD Inspector General reports

`HIGH` · tier **P2** · <https://www.gao.gov/>

*Serves:* facility_existence · cost_scale · ownership_custody · disposal_status

**Holdings.** Audits of DoD and DOE real property management, MILCON execution, facility condition, excess and underutilised facilities, and environmental liabilities. GAO reports routinely quote inventory figures, project lists and cost data that appear nowhere else in public form, and cite the internal systems (RPAD, FRPP MS, Service APSRs) they drew from.

**Access method.** gao.gov product pages plus a static file host (files.gao.gov/reports/{product-id}/index.html observed); also mirrored in GovInfo's GAOREPORTS collection with authenticated PDFs.

**Format returned.** HTML and PDF with text layer.

**Search technique.** Search by product number series and by keyword ('real property', 'military construction', 'excess facilities', 'unspecified minor construction', 'facility condition'). The appendices matter more than the findings — GAO appendices frequently reproduce agency data tables that the agency itself never published. Also mine the 'Agency Comments' sections, where the department contradicts or qualifies GAO's numbers.

**Rate limits.** Not published; GAO also offers RSS feeds by topic.

**Robots / ToS posture.** Verify gao.gov/robots.txt. For bulk, prefer the GovInfo GAOREPORTS collection, which is designed for harvesting.

**Notes.** P2 rather than P1 because GAO is summarising records it obtained, not publishing the records. But GAO's citations tell you exactly which primary system to FOIA.

---

### 3.24 · GSA Real Property Disposal and realestatesales.gov

`HIGH` · tier **P1** · <https://realestatesales.gov/>

*Serves:* disposal_status · ownership_custody · facility_existence · geolocation

**Holdings.** Current and historical offerings of surplus federal real property: sale listings with legal descriptions, acreage, improvements, environmental disclosures, deed restrictions and covenants; plus the federal-transfer and public-benefit-conveyance pipelines that precede public sale. GSA's disposal inventory data covers property available for purchase, for federal transfer, or for public benefit conveyance.

**Access method.** Auction web application (realestatesales.gov/gsaauctions/gsaauctions); GSA's Office of Real Property Utilization and Disposal publishes inventory data and forms at propertydisposal.gsa.gov. No documented public API.

**Format returned.** HTML listings, PDF invitations for bid and offering brochures (which contain site plans and environmental condition reports).

**Search technique.** The offering brochures are the payload: they include the environmental condition of property report, known subsurface conditions, utility infrastructure, and any covenant restricting future excavation or groundwater use. Search listing and brochure text for 'underground', 'bunker', 'vault', 'magazine', 'tunnel', 'subsurface structure', 'abandoned in place', 'sealed'. Cross-reference every sold property back to FRPP (matching on RPUID or address) to confirm the federal-side record, and forward to the county deed to identify the buyer.

**Rate limits.** Not published.

**Robots / ToS posture.** Check realestatesales.gov/robots.txt. Listings are removed after sale — snapshot continuously or lose them.

**Notes.** A disposal record is often the *only* moment a hardened structure is described in plain English in a public document, because GSA has a legal duty to disclose latent conditions to a buyer. This is one of the most under-exploited corpora on the whole beat.

---

### 3.25 · NEPATEC1.0 — AI-ready NEPA document corpus

`HIGH` · tier **P3** · <https://huggingface.co/datasets/PolicyAI/NEPATEC1.0>

*Serves:* facility_existence · geolocation · environmental_footprint

**Holdings.** A large-scale, pre-extracted text corpus of NEPA PDFs derived from the EPA EIS Database, published for machine consumption.

**Access method.** HuggingFace datasets download (git-lfs or the datasets library).

**Format returned.** Structured text with per-document metadata (verify exact schema on the dataset card).

**Search technique.** Use this to run the full hardening-keyword battery across the entire NEPA corpus in one pass without hitting EPA's servers at all, then resolve every hit back to its EPA eisId and cite the EPA record as the P1 source. This is the single biggest efficiency win available on the NEPA side.

**Rate limits.** HuggingFace CDN; generous.

**Robots / ToS posture.** Published dataset with a stated licence on the dataset card — read it before redistribution.

**Notes.** I could not reach huggingface.co from this session to verify document count, licence, or whether a NEPATEC 2.0 exists — treat the schema as unverified. Also check nepaccess.org, an academic NEPA-document project drawing on the same EPA corpus with its own OCR and search layer.

---

### 3.26 · OMB public apportionment files

`HIGH` · tier **P1** · <https://apportionment-public.max.gov/>

*Serves:* cost_scale · construction_timeline

**Holdings.** Every approved apportionment — OMB's legally binding release of appropriated funds to agencies — by Treasury Account Fund Symbol (TAS), with line-level amounts and footnotes. Footnotes type 'A' carry legal effect under the Antideficiency Act; type 'B' are informational. Posted two days after OMB approval.

**Access method.** Website with downloadable data files and a basic JSON API.

**Format returned.** JSON, XLSX/CSV files, PDF.

**Search technique.** Filter to MILCON TAS (021-2050, 017-1205, 057-3300, 097-0500) and to DOE 089-* defense environmental and weapons-activities accounts. Read the footnotes, not just the amounts: apportionment footnotes routinely name specific projects, restrict funds pending a report to Congress, or hold back an amount 'pending further apportionment' — which flags a project OMB is not yet willing to release money for.

**Rate limits.** Not published.

**Robots / ToS posture.** Published under a statutory transparency requirement. Note the site was taken down 24 March 2025 and restored 15 August 2025 under court order — availability is politically contingent, so mirror aggressively.

**Notes.** Pair with OpenOMB for search; use the raw MAX files as the citable primary.

---

### 3.27 · OpenOMB

`HIGH` · tier **P3** · <https://openomb.org/>

*Serves:* cost_scale · construction_timeline

**Holdings.** Cleaned, restructured, full-text-searchable mirror of the apportionment corpus, with per-file permalinks (e.g. openomb.org/file/11404959 for Military Construction, Army Reserve) and search across contents, TAFS, bureau, fiscal year, and footnote text.

**Access method.** Web UI plus a basic JSON API; codebase and schema published on GitHub.

**Format returned.** JSON, HTML.

**Search technique.** Use OpenOMB's full-text footnote search to find the needle (project names appear in footnotes far more often than in line titles), then cite the corresponding apportionment-public.max.gov file as the P1 source. This is the correct provenance discipline for the register: search the derivative, cite the original.

**Rate limits.** Small civic-tech project — be conservative, ≤1 rps.

**Robots / ToS posture.** Check openomb.org/robots.txt. Prefer the API over scraping; source data is available upstream at MAX if you need volume.

**Notes.** Genuinely a derived source — record it as P3 and always resolve to the MAX original before grading a candidate.

---

### 3.28 · SAM.gov Entity Management API

`HIGH` · tier **P1** · <https://api.sam.gov/entity-information/v3/entities>

*Serves:* contractor_linkage · corporate_shell · geolocation

**Holdings.** Registration records for every entity that can receive a federal award: legal business name, DBA, UEI, CAGE code, physical and mailing address, registration/expiration dates, NAICS and PSC self-certifications, business types, immediate and ultimate parent entity (UEI + name), and points of contact.

**Access method.** REST/JSON, api.data.gov key.

**Format returned.** JSON.

**Search technique.** Query by ueiSAM, cageCode, legalBusinessName, or physicalAddressZipPostalCode. The physical-address search is the underused one: pull every registered entity whose physical address sits in the ZIP codes around a candidate site and you surface the small local subs and the SPE/LLC shells that don't show up as prime awardees. Then walk the immediate/ultimate parent UEI chain to collapse a cluster of shells into one owner.

**Rate limits.** Same api.data.gov tiering as Opportunities. Sensitive/FOUO fields (some POC data, banking) require a role-restricted key and are not in the public response.

**Robots / ToS posture.** Public API with a restricted-field tier; the restricted tier requires a signed data access request.

**Notes.** CAGE code is the join key into DoD systems (DLA, WAWF, facility clearance records) that UEI alone will not open.

---

### 3.29 · Service NEPA repositories — Army NEPA Online, AFCEC NEPA Center, NAVFAC

`HIGH` · tier **P1** · <https://aec.army.mil/Outreach/NEPA-Documents/>

*Serves:* facility_existence · geolocation · environmental_footprint · construction_timeline

**Holdings.** Environmental Assessments, FONSIs, EISs, RODs and supporting studies produced by the Services. Crucially this includes EAs, which are *not* filed with EPA and therefore do not appear in the EPA EIS Database at all — for facility-scale construction, an EA is far more common than an EIS, so this is where most defence construction environmental documentation actually lives. Air Force documents flow through AFCEC's Environmental Impact Analysis Process (EIAP); Navy documents are distributed across NAVFAC regional commands.

**Access method.** Web repositories with browse/metadata/full-text search (Army NEPA Online); AFCEC and NAVFAC publish PDFs on installation and command sites with no central index.

**Format returned.** PDF, variable OCR quality.

**Search technique.** Army NEPA Online supports metadata, advanced and full-text search — use it as the primary index. For Air Force and Navy there is no central index, so the practical method is a site-scoped search-engine sweep plus targeted crawls of installation public-affairs 'Environmental' directories (observed pattern: {host}/Portals/{n}/documents/Environment/*.pdf and {host}/Portals/{n}/Documents/Environmental*/*.pdf). Search strings: 'Final Environmental Assessment', 'Finding of No Significant Impact', plus the installation name.

**Rate limits.** Not published.

**Robots / ToS posture.** Varies by host; .mil sites often carry restrictive robots.txt — check each host before crawling and honour it.

**Notes.** EAs are the highest-yield-per-page documents on this beat because they describe small, specific construction actions — exactly the scale at which a hardened facility gets built — and they name the CATCODE, the square footage, and the site coordinates.

---

### 3.30 · Unified Facilities Criteria and design-standard citations as hardening tells

`HIGH` · tier **P1** · <https://www.wbdg.org/dod/ufc>

*Serves:* hardening_signature

**Holdings.** The DoD design criteria library. Specific standards whose citation in a solicitation, SOW, or DD 1391 is diagnostic: UFC 4-010-01 (Minimum Antiterrorism Standards for Buildings — ubiquitous, weak signal), UFC 4-010-02 (standoff distances), UFC 3-340-01 (design of structures to resist conventional weapons effects — restricted distribution; its citation alone is a strong tell), UFC 3-340-02 (Structures to Resist the Effects of Accidental Explosions), UFC 4-020-01 (Security Engineering Facilities Planning), UFC 4-141-03 (C5ISR facilities, with redundancy and resilience tiers), UFC 3-501-01 (electrical, including EMP/HEMP provisions), MIL-STD-188-125-1 (HEMP protection for fixed ground-based C4I facilities), and ICD 705 / IC Tech Spec for SCIF construction.

**Access method.** Public PDF download from wbdg.org; some restricted-distribution UFCs are referenced but not hosted.

**Format returned.** PDF.

**Search technique.** Use these as *query strings against other corpora*, not as a corpus to harvest. Full-text search SAM.gov attachments, NEPA documents, and budget justifications for 'MIL-STD-188-125', 'UFC 3-340-01', 'ICD 705', 'ICS 705', 'HEMP', 'TEMPEST', 'shielded enclosure', 'Faraday', 'blast door', 'earth-covered magazine', 'progressive collapse', 'Level of Protection'. MIL-STD-188-125-1 is the strongest single string: it applies to fixed ground-based facilities performing critical, time-urgent C4I missions and essentially nothing else.

**Rate limits.** Static host; crawl gently.

**Robots / ToS posture.** WBDG is the designated public repository for UFCs; verify robots.txt.

**Notes.** USACE's Protective Design Center (Omaha District, nwo.usace.army.mil/pdc) is the mandatory center of expertise for this work and publishes PDC-TR technical reports openly (e.g. PDC TR-05-01 on SBEDS blast-effects design). Contracts routing through Omaha District for a facility physically located elsewhere are a routing anomaly worth flagging.

---

### 3.31 · Federal Permitting Dashboard

`MODERATE` · tier **P1** · <https://www.permits.performance.gov/>

*Serves:* construction_timeline · facility_existence · geolocation

**Holdings.** Tracked federal environmental review and authorization timelines for large or complex infrastructure projects, plus the Federal Environmental Review and Authorization Inventory (a catalogue of every permitting/review process across agencies) and the compiled agency NEPA implementing procedures.

**Access method.** Web UI plus a token-authenticated REST API (account and API key required).

**Format returned.** JSON.

**Search technique.** GET http://permits.performance.gov/api/v1/project/{id} for individual records, plus an all-projects endpoint. Enumerate project IDs. Coverage skews heavily to energy and transportation (FAST-41 sectors), so hit rate for defence facilities is low — but when a defence project *does* appear here, the milestone schedule is unusually granular.

**Rate limits.** Not published; key-gated.

**Robots / ToS posture.** API documented at /tools/api-docs; account required. Contact permittingdashboardfeedback@dot.gov.

**Notes.** Low yield for this beat specifically. Worth a periodic sweep rather than a continuous harvester.

---

### 3.32 · National Capital Planning Commission project review records

`MODERATE` · tier **P1** · <https://www.ncpc.gov/review/>

*Serves:* facility_existence · geolocation · construction_timeline · hardening_signature

**Holdings.** Submission materials, staff recommendations and commission actions for essentially every federal construction and master-plan action in the National Capital Region: site plans, elevations, security-perimeter designs, and phasing. Agenda and submission materials are posted per meeting; historical files are split between NCPC and the National Archives.

**Access method.** Web listings with PDF submission packages; meeting notices via the Federal Register API.

**Format returned.** PDF, often with drawings.

**Search technique.** Harvest every meeting's 'Agenda and Submission Materials' package and index by agency and site. NCPC review is a statutory obligation that DoD, DOE, GSA and the intelligence agencies cannot avoid for construction in the region — which means secure and hardened facilities in the DC area leave a drawing-bearing public record here that they leave nowhere else. Search for 'below grade', 'sublevel', 'secure facility', 'perimeter', 'setback', 'blast'.

**Rate limits.** Not published.

**Robots / ToS posture.** Verify ncpc.gov/robots.txt.

**Notes.** Geographically narrow but exceptionally deep. For the continuity-of-government subject matter specifically, the National Capital Region is disproportionately where the facilities are.

---

### 3.33 · NPDES construction and dewatering permits (EPA NeT eNOI, ECHO, and state programs)

`MODERATE` · tier **P1** · <https://www.epa.gov/npdes-permits/dewatering-and-remediation-general-permit-drgp>

*Serves:* construction_timeline · geolocation · environmental_footprint

**Holdings.** Notices of Intent under the Construction General Permit (any land disturbance ≥1 acre) and under dewatering/remediation general permits (temporary lowering of the groundwater table by mechanical pumping to permit excavation). NOIs state the operator, the site location, the acreage disturbed, and the discharge. EPA's NeT tool handles electronic NOI/CNOI/NOT filing in EPA-administered jurisdictions; 40-odd states run their own delegated programs with their own databases.

**Access method.** EPA NeT and ECHO for EPA-administered jurisdictions; per-state searchable databases and bulk downloads for delegated states (quality varies enormously).

**Format returned.** HTML search, CSV/Excel exports, some state APIs.

**Search technique.** THIS IS THE DEEP-EXCAVATION TRIPWIRE. A dewatering permit is required precisely when you are digging below the water table — the defining condition for a buried structure in most of the country. Query dewatering general permits and CGP NOIs by county around candidate sites and look for: (a) a dewatering NOI with no corresponding building permit, (b) a disturbed-acreage figure far exceeding the footprint of any announced building, (c) a discharge volume implying sustained pumping over months. Federal facilities are covered — the Vermont federal-facility dewatering permit VTG910000 is an explicit example of EPA writing a general permit specifically for federal sites.

**Rate limits.** ECHO publishes documented web services with reasonable limits; state systems are unpredictable.

**Robots / ToS posture.** ECHO explicitly publishes REST services for reuse. State portals: check individually.

**Notes.** Delegated-state coverage is the weak link: fifty different systems, many without bulk export. Prioritise states with candidate sites and good data (e.g. Florida DEP, Minnesota PCA, California SWRCB GeoTracker/SMARTS).

---

### 3.34 · Public Buildings Reform Board

`MODERATE` · tier **P1** · <https://www.pbrb.gov/>

*Serves:* disposal_status · ownership_custody · facility_existence

**Holdings.** Independent board established December 2016 under FASTA to identify federal civilian real property for disposal. Publishes round reports naming specific properties recommended for disposition with square footage, location, and justification; meeting notices and minutes appear in the Federal Register.

**Access method.** Static PDFs on pbrb.gov; meeting notices via the Federal Register API.

**Format returned.** PDF.

**Search technique.** Harvest every round report now — the board sunsets 31 December 2026 under the Public Buildings Reform Legislation of 2025 and its site may not survive. Cross-reference the recommended properties against FRPP status changes to see which recommendations OMB approved and which quietly did not happen.

**Rate limits.** Static host.

**Robots / ToS posture.** Verify pbrb.gov/robots.txt.

**Notes.** Civilian-agency scope only, so no direct DoD coverage — but the DC-area properties it examines include buildings with continuity-of-government roles.

---

### 3.35 · State business entity registries and shell-entity tracing

`MODERATE` · tier **P1** · <https://govfiles.dev/>

*Serves:* corporate_shell · contractor_linkage · ownership_custody

**Holdings.** Registered entity name, formation date and state, status, registered agent name and address, officers/directors/managers where the state collects them, and annual-report history. Roughly 27 states offer some form of official bulk export; ~20 (including Delaware, the most important formation state) offer none.

**Access method.** Per-state: free bulk FTP/download (e.g. Florida, Colorado, California, several others), paid bulk subscription (e.g. Texas, Illinois), or search-only with no export (Delaware). Commercial normalisation across all 50 states from GovFiles (~75M records, monthly updates, REST API and bulk Parquet) and OpenCorporates.

**Format returned.** Fixed-width or delimited text (legacy state FTP feeds), CSV, Parquet, JSON.

**Search technique.** Three joins do most of the work: (1) registered-agent address clustering — dozens of unrelated-looking entities sharing one agent address is the signature of a formation service, and the *exceptions* (an entity using a real street address near a candidate site) are the interesting ones; (2) officer-name matching against SAM.gov Entity Management POC names and against contract award recipients; (3) formation-date-to-deed-date proximity, where an SPE formed within 90 days of a land acquisition is almost always purpose-built for that acquisition. Delaware's opacity means the practical path is to find the entity's *foreign qualification* filing in the state where the property actually sits, which will name a registered agent and sometimes an officer.

**Rate limits.** State search portals commonly CAPTCHA or block automation. Commercial APIs have contractual limits.

**Robots / ToS posture.** State portals are generally restrictive about automated querying; several explicitly prohibit it. Use official bulk products where they exist — that is the state's own sanctioned automation channel.

**Notes.** Be disciplined about what this can prove. Registry data establishes that an entity exists and who filed for it. It does not establish beneficial ownership, and in Delaware, Nevada and Wyoming it is designed not to. Treat shell-entity findings as 'inferred', never 'documented', absent a corroborating deed or contract.

---

### 3.36 · Treasury FAST Book (Federal Account Symbols and Titles)

`MODERATE` · tier **P1** · <https://fiscal.treasury.gov/accounting/fast-book>

*Serves:* cost_scale

**Holdings.** The authoritative list of every federal receipt, appropriation and fund account symbol and title. This is the codebook that turns an opaque TAS in USAspending or an apportionment file into a named appropriation.

**Access method.** PDF download, updated periodically; historical editions available.

**Format returned.** PDF (parseable to a table with effort).

**Search technique.** Extract the full account table and keep every historical edition — account symbols get retired and reused, and a MILCON account symbol in a 2004 document may mean something else today. Anchor accounts for this beat: 021-2050 Military Construction Army; 017-1205 Military Construction Navy and Marine Corps; 057-3300 Military Construction Air Force; 097-0500 Military Construction Defense-Wide; plus the 089-* DOE Atomic Energy Defense Activities family, and the Army/Navy/Air Force Family Housing and BRAC accounts.

**Rate limits.** Static document.

**Robots / ToS posture.** Published reference material.

**Notes.** Unglamorous but load-bearing. Without it, TAS-filtered queries against USAspending and the apportionment files cannot be interpreted or cited precisely.

---

### 3.37 · USACE Regulatory — Section 404/Section 10 permits (ORM2, RRS, district public notices)

`MODERATE` · tier **P1** · <https://rrs.usace.army.mil/rrs>

*Serves:* construction_timeline · geolocation · environmental_footprint

**Holdings.** Department of the Army authorisations under Clean Water Act §404 and Rivers and Harbors Act §10, plus jurisdictional determinations, tracked in the ORM2 database. Any construction that fills, dredges, or discharges into waters of the United States needs one — which catches a large share of site work involving significant earthmoving or dewatering discharge.

**Access method.** RRS is an applicant-facing portal, not a public research database. Practical public access is via district-level public notices (PDF) and via EPA's periodic reviews of ORM2 data. Bulk ORM2 is a FOIA matter.

**Format returned.** PDF public notices; ORM2 extracts as spreadsheets when obtained.

**Search technique.** Harvest district Regulatory public-notice directories (each USACE district publishes them under /Missions/Regulatory/Public-Notices/). Public notices carry applicant name, latitude/longitude, acreage of impact, and a project description. For federal applicants the applicant name is the installation or the Corps district itself. Search notice text for 'dewatering', 'excavation', 'shaft', 'tunnel', 'below grade', and for acreage-of-impact figures disproportionate to the described building.

**Rate limits.** n/a — district sites are static PDF hosts.

**Robots / ToS posture.** District .mil sites vary; honour each robots.txt.

**Notes.** Honest limitation: a project sited entirely on federal land, away from jurisdictional waters, generates no §404 record at all. Absence here is not evidence of absence.

---

## Gaps for this beat — the expected-record raw material

*Every statement here becomes, or should become, a row in `registry.erp_profile`. A record
class that does not exist for a given authority, era or classification posture is **X0** and
produces **no row** — not a zero. This is what licenses the argument from silence in one case
and forbids it in another.*

WHAT THIS BEAT STRUCTURALLY CANNOT SEE.

1. Classified and special-access construction. The MILCON justification books contain line items titled "Classified Project" at "Classified Location" — they establish that an amount of money was appropriated for construction somewhere, and nothing else. Intelligence-community construction funded through the National Intelligence Program and Military Intelligence Program does not appear in the MILCON books at all; those appropriations are published only as topline aggregates. Special access program construction is invisible by design. The honest position for the register is that these corpora document the *existence and scale* of unlocated hardened construction, and can never locate it. Closing this would require the classified annexes to the congressional defense committee reports, which are not FOIA-able.

2. FRPP withholds national-security assets outright. The public data set excludes assets withheld for national security, procurement sensitivity, or FOIA exemption. So the single best government-wide real property inventory is guaranteed to be missing exactly the class of facility this register is about. The workaround — comparing an installation's published acreage and asset totals against its FRPP record count and treating the delta as a measurable absence — produces an inference, not a record. DoD's underlying RPAD, and the RPUID/RPSUID identifiers that would let you join across systems, are not public; obtaining them means a FOIA to OSD (Energy, Installations & Environment), which for hardened facilities will be exempted under (b)(1) and likely (b)(3).

3. NEPA has a categorical-exclusion hole. Most defence construction actions are categorically excluded from documentation entirely, producing no public paper. Of the actions that do produce documents, only EISs are filed with EPA and centrally indexed; Environmental Assessments — which is what facility-scale construction almost always generates — are scattered across Army NEPA Online, AFCEC, and dozens of NAVFAC and installation sites with no central index and no API. There is no single national EA corpus. Building one would be a genuine contribution and would require per-installation crawling. National-security exemptions and classified annexes to EAs further hollow out coverage.

4. Contract descriptions are sanitised and miscoded. The award description field is free text written by a contracting officer with no obligation to be informative; "CONSTRUCTION" and "TASK ORDER 0003" are common. PSC and NAICS are miscoded routinely. Task orders under a MATOC often carry no meaningful description at all, and the place of performance is frequently recorded as the contracting office rather than the site. Keyword recall over this corpus is therefore low and unquantifiable — the register should never treat absence of a keyword hit as evidence of absence.

5. Nothing here pierces beneficial ownership. State registries in Delaware, Nevada and Wyoming are designed not to disclose it. The Corporate Transparency Act beneficial-ownership registry is not public. Registered-agent clustering and formation-date proximity generate leads, not proof, and every shell-entity finding must be graded as inferred unless a deed, contract or court filing corroborates it.

6. County land records do not capture federal-to-federal transfers, land withdrawals, or leaseholds well. Property moving between federal agencies typically generates no recorded deed. Withdrawn public land in the western states never enters the fee-ownership chain at all — it appears only in BLM case files. Leased space, including the leased facilities that host continuity functions, produces a lease that may never be recorded. And many county recorders have digitised only back to the 1970s–1990s, which is after most Cold War hardened construction; pre-digitisation deeds require an in-person or mail request to the county.

7. Deep-excavation environmental tripwires miss federal land. The dewatering and §404 permit logic — the best physical evidence of digging below the water table — only fires when there is a jurisdictional water or a delegated state program with reach. A project sited entirely on a federal installation, away from waters of the United States, generates neither. Coverage is also wildly uneven across the ~40 delegated NPDES states, several of which have no bulk export and no API. State blasting permits, which would be an excellent complementary signal for rock excavation, are administered by fifty different agencies (mining boards, fire marshals, labour departments) with essentially no machine-accessible national coverage — I could not identify a single aggregated source, and building one would mean fifty separate integrations.

8. Local building permits are absent for federal projects. Federal construction on federal land is not subject to local permitting, so the municipal permit databases that would otherwise be the richest construction record simply do not contain these projects.

9. The FPDS-to-SAM migration is an unquantified provenance risk. The as-filed contract action reports are moving to a new system and a new schema during FY2026. Whether every historical field survives with fidelity is unknown. Until the migration is complete and verified, any harvester should capture both the legacy ATOM XML and the new JSON for the overlap period so the register can document any divergence rather than silently inherit it.

10. Commercial dependencies. Complete national parcel coverage and complete 50-state entity coverage are, today, commercial products (Regrid at roughly $10,000/year for enterprise access; GovFiles and comparable vendors for entity data). Free alternatives exist but are partial — around 20 states publish standardised statewide parcel files and around 27 publish some form of entity bulk export. A register committed to open, no-login, publicly reproducible sourcing has to decide whether to accept a licensed dependency it cannot redistribute, or accept incomplete coverage and say so. My recommendation is the latter, with the coverage gaps documented per state as a first-class part of the register rather than papered over.


# BEAT 4 — INFRASTRUCTURE: COMMUNICATIONS, POWER, WATER AND FUEL

**Beat as scoped:** Infrastructure, communications, power, water, and fuel registries — the utility signature of hardened, buried, and continuity-of-government facilities

**Primary agent:** CIRCUIT · **31 sources**

## Access notes for this beat

SESSION CONSTRAINT, STATED HONESTLY: this session's egress proxy blocked HTTPS to every domain I attempted to fetch directly — fcc.gov, eia.gov, ferc.gov, epa.gov, usgs.gov, arcgis.com, wikipedia.org, catalog.data.gov, peeringdb.com, archive.org, long-lines.net and others all returned EGRESS_BLOCKED or a 403 CONNECT tunnel failure. Only WebSearch functioned. Every URL, file name, field name, record layout, and query grammar below is therefore assembled from search-result content and from prior knowledge, and NONE of it was verified by loading the endpoint. Before writing a harvester, re-verify each endpoint from an unrestricted network. Specifically re-check: (a) the data.fcc.gov/download/pub/uls/ path structure, which has moved before; (b) whether maps.nccs.nasa.gov still serves the hifld_open tree, since it did not resolve in DNS here; (c) the current ULS record-layout PDF version, since column counts differ between the v2, v4, and 2024-02-15 layouts and a stale layout silently misaligns fields.

ENGINEERING NOTES THAT WILL SAVE TIME:

FCC pipe-delimited parsing. The .dat files are pipe-separated, unquoted, and the final field on a line has NO trailing pipe. Free-text address and entity-name fields can contain embedded pipes and embedded newlines. Do not use a naive CSV reader with delimiter='|'; use a tolerant reader that splits on the expected field count and quarantines malformed lines rather than dropping them. Coordinates are stored as SEPARATE integer degree/minute/second columns plus a direction character, not decimal degrees — you must reconstruct them, and you must handle the sign from the direction char, not from the degree value.

Ordering of ingest. Pull the bulk files FIRST and use interactive web apps only for per-record verification. Both wireless2.fcc.gov and the state permit apps are session-based transactional systems (JSESSIONID cookies, sometimes injected as a path parameter before the query string — your HTTP client must not choke on ';JSESSIONID_ULSSEARCH=...' appearing between the path and the '?'). Scraping them at volume is both rude and fragile.

ArcGIS REST paging. Every Esri endpoint in this registry (NASA NCCS HIFLD mirror, PASDA, Rutgers, EIA Atlas, EPA UST Finder, NDWR, ADWR) enforces maxRecordCount, typically 1000–2000. Always GET the layer with ?f=json first to read maxRecordCount and the field list, then page with resultOffset/resultRecordCount and ORDER BY the OBJECTID to guarantee stable paging. Requesting f=geojson is usually cheaper to parse than Esri JSON.

Bulk over API wherever both exist. Overpass will rate-limit you; use a Geofabrik .osm.pbf extract with osm2pgsql. FERC EQR caps simultaneous downloaders at THREE and the compressed database exceeds 15.5 GB, with FERC explicitly advising off-peak scheduling. PeeringDB anonymous access is throttled — get a key and use the `since=` parameter for incremental sync rather than full re-pulls.

Licence obligations that attach to the register. OpenStreetMap data is ODbL: if you ingest OSM geometry into the Supabase/PostGIS database and publish it, share-alike and attribution obligations attach to the derived database. Decide this deliberately before ingesting, not after. ARIN Bulk Whois requires a signed AUP restricting redistribution. The FCC has published API Terms of Service at https://www.fcc.gov/general/api-terms-service. The CostQuest-licensed Broadband Serviceable Location Fabric underlying the FCC's BDC data is commercially licensed and not redistributable.

Documented access walls to record rather than route around. NTIA's Government Master File is classified by aggregation — any list of two or more otherwise-unclassified federal frequency assignments is classified — so the federal microwave network is structurally invisible in open spectrum data; the FOIA-released fragment is under 10% of the file. FERC Form 715 transmission planning studies and detailed one-line diagrams are CEII under 18 CFR 388.113 and require a justified application. HIFLD Secure requires a GII account and an approved Data Use Agreement. E-Plan's Tier II repository is credentialed to emergency responders only and should not be accessed by other means; the lawful route to Tier II data is a written public-records request under EPCRA §324 to the SERC or LEPC. Each of these walls is itself a data point about what the government considers sensitive, and the register should record the wall, its legal basis, and the date it was encountered.

The dead-portal problem. DHS shut down HIFLD Open in August 2025, taking hifld-geoplatform.opendata.arcgis.com with it. The consequence for this project is that the canonical citation for hundreds of infrastructure layers now 404s, and the register must cite a MIRROR while recording that the primary is gone. Hold at least two independent copies: the frozen 2025 Parquet snapshot at source.coop/seerai/hifld and a live ArcGIS mirror (NASA NCCS or PASDA). Diffing frozen against live is a first-class evidence operation — a layer or a feature present in the 2025 snapshot and absent from the live mirror is a removal, and removals are exactly the kind of movement this register is designed to record.

Cross-source join keys, in rough order of reliability. FCC Registration Number (FRN) links entities across ULS, ASR, ICFS and BDC. ASR Registration Number links a structure across FCC systems. CLLI code links a telecom building across Bell System records, long-lines.net, PeeringDB (where operators supply it) and carrier documentation — it is the best identity for the Long Lines population. EIA Plant Code links EIA-860/860M/923 and the Energy Atlas. EPA Facility Registry Service (FRS) ID links ECHO, NEI, UST Finder and TRI. County FIPS plus PLSS section/township/range links state well records. Everything else is a spatial join with a tolerance, and coordinate quality varies wildly — ASR coordinates are self-reported and often wrong by hundreds of metres, FAA DOF coordinates are surveyed, EIA plant coordinates are decent, state well coordinates are frequently PLSS-centroid-derived and can be off by a quarter mile. Record the coordinate provenance per point, not just the point.

THE ORDER OF OPERATIONS THAT ACTUALLY WORKS. This beat is not a set of independent lookups; it is a funnel. Generate candidates from the cheap national layers (ASR ∖ DOF set difference; deep-well percentile outliers; high-voltage radials to nowhere; RICE-permitted facilities with no plausible host). Then confirm with the expensive per-site work (FCC application attachment PDFs, state air permit documents, Tier II records requests, water-right documentary files). One confirmed site is worth a thousand candidates, and the confirmation step is always a document, never a dataset.

## Sources

### 4.1 · EPA ECHO — ICIS-Air bulk downloads and REST services

`CRITICAL` · tier **P1** · <https://echo.epa.gov/tools/data-downloads/icis-air-download-summary>

*Serves:* air permits · standby generator regulation · facility location · operating status · fuel combustion

**Holdings.** Every Clean Air Act stationary source in ICIS-Air: facility identity, location (lat/long), operating status (planned/under construction/operating/temporarily closed/seasonal/permanently closed), NAICS/SIC, and a repeating 'Air Program' block recording every regulatory programme the facility is subject to — SIP, NSPS, NESHAP, PSD, Title V — with pollutant-level detail. Includes NESHAP Subpart ZZZZ (RICE — Reciprocating Internal Combustion Engines), which is the regulatory hook for stationary emergency/standby generators.

**Access method.** Bulk CSV ZIP downloads at https://echo.epa.gov/tools/data-downloads plus a documented REST API (ECHO REST Services) supporting facility search by geography, programme, and NAICS. The R package 'echor' wraps it.

**Format returned.** CSV bulk; JSON/CSV/GeoJSON over REST

**Search technique.** HARDENING PATTERN — this is the sharpest single generator signal available. Filter ICIS-Air for facilities with a NESHAP Subpart ZZZZ programme block, then join to the facility location and to building footprints. A facility permitted for stationary RICE engines with substantial aggregate horsepower, at coordinates where imagery shows only a small surface structure, a fenced pad, and a large fuel tank farm, is a hardened-facility signature. Refinements: (a) the ratio of permitted generator capacity to visible building floor area — a facility permitted for many megawatts of standby power with a 3,000 sq ft above-ground footprint has its load somewhere else; (b) facilities that hold a Title V (major source) permit purely on the basis of emergency engines, which implies a very large engine fleet; (c) operating_status='operating' at a site with no NAICS that plausibly needs backup power. The facility identifier format ZZZZZNNNNNSSSSS (ZIP + 5 name consonants + 5 address chars) is useful for deduplicating across EPA systems.

**Rate limits.** REST services are rate-limited but undocumented in specifics; bulk files are unrestricted and are the correct route for full-corpus work.

**Robots / ToS posture.** Explicitly an open-data programme with a published API; programmatic use intended.

**Notes.** NESHAP ZZZZ background: https://www.epa.gov/stationary-engines/national-emission-standards-hazardous-air-pollutants-reciprocating-internal-0. Electronic reporting for RICE was expanded in 2024 (89 FR, https://www.federalregister.gov/documents/2024/08/30/2024-18766/), which improves forward coverage but not the historical record.

---

### 4.2 · FCC Antenna Structure Registration (ASR) — bulk r_tower.zip

`CRITICAL` · tier **P1** · <https://data.fcc.gov/download/pub/uls/complete/r_tower.zip>

*Serves:* structure coordinates · structure height · ownership chain · construction/dismantle dates · tower typology

**Holdings.** Every antenna structure registered with the FCC — required for any structure over 200 ft AGL or any structure that may penetrate an airport's imaginary surfaces. Inside r_tower.zip: CO.dat (coordinates — latitude/longitude by degree/minute/second, plus the structure's registration number), RA.dat (registration/application detail — structure type code, overall height above ground, overall height above mean sea level, height of support structure, date constructed, date dismantled, FAA study number, FAA circular number, status), and EN.dat (registrant entity name, FRN, address). Join CO↔RA↔EN on Registration Number (ASRN) and/or Unique System Identifier. Structure type codes are a 23-value controlled vocabulary: B, BANT, BMAST, BPIPE, BPOLE, BRIDG, BTWR, GTOWER, LTOWER, MAST, MTOWER, NNGTANN, NNLTANN, NNMTANN, PIPE, POLE, RIG, SIGN, SILO, STACK, TANK, TREE, UPOLE.

**Access method.** Bulk ZIP download, same weekly-complete + daily-delta cadence as ULS. Also an interactive search at https://wireless2.fcc.gov/UlsApp/AsrSearch/asrRegistrationSearch.jsp and a per-registration printable form at https://wireless2.fcc.gov/UlsApp/AsrSearch/printAuth_FCCASRForm.jsp?regKey=NNNNNN

**Format returned.** ZIP of pipe-delimited .dat

**Search technique.** HARDENING PATTERN, and this is the highest-yield correlation in the whole beat: filter RA.dat for structure_type in ('LTOWER','GTOWER','TOWER') AND overall_height_above_ground > 200ft AND date_constructed BETWEEN 1955 AND 1975, then spatially join against (a) building footprints (Microsoft/Overture) and (b) recent aerial imagery. A registered 300-ft self-supporting lattice tower at a rural coordinate where the only visible structure is a small windowless blockhouse — because the equipment is underground — is the Long Lines / AUTOVON signature. Second pattern: chase the OWNERSHIP CHAIN. ASR ownership-change filings (Form 854, procedure 'OC') are two-party and dated, so the EN record documents a site passing AT&T → American Tower / Crown Castle / SBA at the turn of the millennium; the underground portion is frequently severed and retained or sold separately, and the discrepancy between who owns the tower and who owns the parcel is itself evidence. Third pattern: an ASR with date_dismantled populated but the parcel still showing a graded pad, access road, and fenced perimeter.

**Rate limits.** Bulk file: none meaningful. The JSP search app is session-based (JSESSIONID_ASRSEARCH) and will rate-limit / session-expire aggressive scraping — use the bulk file and only deep-link the JSP for individual verification.

**Robots / ToS posture.** Not verifiable from this session (fcc.gov egress-blocked). Bulk endpoint is published for programmatic reuse. FCC API Terms of Service exist at https://www.fcc.gov/general/api-terms-service and should be read before any automated harvest.

**Notes.** Codes/data-element doc: https://www.fcc.gov/sites/default/files/pubacc_asr_codes_data_elem.pdf. ASR intro: https://www.fcc.gov/sites/default/files/pubacc_asr_intro.pdf. Form 854 (the registration form itself, showing every field collected): https://www.fcc.gov/sites/default/files/form854.pdf. Coordinates in ASR are self-reported by the registrant and are frequently wrong by tens to hundreds of metres — always cross-check against the FAA Digital Obstacle File, which is independently verified. Existing tooling: 'asr2geojson' (tris.fyi) and a state-level reprojected product from the Arkansas GIS Office (https://gis.arkansas.gov/category/fcc/) demonstrate the join.

---

### 4.3 · FCC ULS / ASR interactive licence app — deep-link URL grammar and the application attachment viewer

`CRITICAL` · tier **P1** · <https://wireless2.fcc.gov/UlsApp/UlsSearch/license.jsp>

*Serves:* path topology · engineering exhibits · terrain profiles · site names · application history

**Holdings.** Per-licence detail pages plus, critically, the engineering exhibits filed with microwave applications. The URL grammar is stable and directly addressable: license.jsp?licKey=NNNNNNN (licence summary); licenseLocSum.jsp?licKey=N (all locations on a licence); licensePathsSum.jsp?licKey=N[&pathType=B|C] (every microwave path, transmit→receive site pairs); licenseAdminSum.jsp?licKey=N (administrative/ownership history); applPathSum.jsp?applID=N and applPathDetail.jsp?applID=N&keyPath=N (the application-side equivalents, which survive for applications that were never granted). The attachment viewer — attachmentView.jsp?applType=search&fileKey=NNNNNNNNN&attachmentKey=NNNNNNNN&attachmentInd=applAttach and its attachmentViewRD.jsp variant — serves the actual filed PDFs, including COMSEARCH 'Microwave Path Data Sheet' exhibits containing path profiles, terrain cross-sections, antenna centrelines, structure heights, and site names.

**Access method.** HTML scrape / PDF retrieval over stable query-string deep links. licKey is an internal surrogate key recoverable by joining the bulk ULS HD.dat unique_system_identifier — do not brute-force it.

**Format returned.** JSP-rendered HTML; attachments are PDF (often scanned, OCR required for pre-2000 filings)

**Search technique.** Resolve licKey from the bulk files first, then fetch ONLY licensePathsSum.jsp for candidate licences. The path summary gives you the site-name pairs; the attachment viewer gives you the terrain profile that will show a tower centreline sitting on a hill with a note about an existing underground structure. HARDENING PATTERN: pull the attachment PDFs for every legacy AT&T/Western Union microwave application and grep the OCR for 'underground', 'hardened', 'blast', 'below grade', 'basement level', 'emergency power', 'diesel', 'fallout'. Engineering exhibits routinely describe the buried plant in passing because it is structurally relevant to the antenna support.

**Rate limits.** Undocumented. The app issues a JSESSIONID_ULSSEARCH cookie and sometimes injects it as a path parameter (';JSESSIONID_ULSSEARCH=...' before the query string) — your fetcher must tolerate that. Sessions expire; concurrent aggressive fetching triggers errors rather than bans in observed behaviour, but throttle to ~1 req/sec with a declared User-Agent.

**Robots / ToS posture.** Unverified from this session. Treat as a live transactional government app: crawl-delay it, cache aggressively, never parallelise beyond a couple of connections.

---

### 4.4 · FCC Universal Licensing System (ULS) — Public Access bulk database files

`CRITICAL` · tier **P1** · <https://www.fcc.gov/wireless/data/public-access-files-database-downloads>

*Serves:* communications infrastructure · microwave network topology · site coordinates · ownership chain · temporal change (grant/cancel dates)

**Holdings.** Complete licence and application records for every non-federal radio service, as pipe-delimited .dat tables inside per-service ZIPs. For this beat the load-bearing archives are l_micro.zip (Part 101 Common Carrier Fixed Point-to-Point Microwave + Private Operational Fixed + Microwave Public Safety Pool) and the paired a_micro.zip application archive. Inside each ZIP the tables that matter are HD.dat (licence header: call sign, radio service code, status, grant/expiration/cancellation dates), EN.dat (entity: licensee name, FRN, address — this is how you find 'AT&T Corp', 'American Telephone and Telegraph Company', 'General Services Administration' as an ASR/licence holder), LO.dat (location: location number, location type/class code, street address, city, county, state, ground elevation, lat/long in separate degree/minute/second/direction integer columns, support structure height, site status), AN.dat (antenna: azimuth, height AGL, polarisation, antenna model, EIRP), FR.dat (frequency/emission), and the PA path table (path number, path type code, transmit location number → receive location number, passive repeater locations). The PA table is the single highest-value artefact in this beat: it lets you reconstruct the actual hop-by-hop topology of a microwave network — including the surviving fragments of AT&T Long Lines — as a graph of location IDs with coordinates, rather than as a list of isolated towers. Historical/cancelled licences persist in the database, so a decommissioned 1960s relay whose licence was cancelled in 1999 is still recoverable.

**Access method.** Bulk download (ZIP of pipe-delimited .dat). Complete weekly snapshots generated early Sunday morning; daily transaction deltas generated Tuesday–Saturday mornings. No registration, no API key, no login. Files historically served from https://data.fcc.gov/download/pub/uls/complete/ and .../uls/daily/.

**Format returned.** ZIP containing pipe-delimited fixed-schema .dat text files. First two chars of every record are the record-type code; the last field on a line is NOT followed by a trailing pipe (a common parser bug). Fields are not quoted, so embedded pipes in free-text address fields are a real hazard.

**Search technique.** Do not use the web search form for harvesting. Load l_micro.zip into Postgres, then: (a) SELECT from EN where entity_name ILIKE any of '%AT&T%','%American Telephone%','%Western Union%','%General Services Admin%','%Department of%','%Federal Aviation%'; (b) join HD→LO→PA to build the path graph; (c) flag LO rows where location_class_code indicates a fixed point and the ground elevation is a local maximum but the address is a rural route / unnamed road with no city; (d) flag path endpoints whose LO record has an unusually descriptive site name (Long Lines sites carry names like 'BARNETT', 'CEDAR BLUFF', or bracketed project names). HARDENING PATTERN: a fixed microwave location with (1) a licence grant date in 1958–1968, (2) multiple distinct licences/call signs stacked at the same coordinates, (3) heavy horn-reflector or large-aperture parabolic antenna models in AN.dat, (4) a ground elevation at a ridgeline local max, and (5) a street address that resolves to nothing — is the classic buried-relay signature. A second signature: a site with an active ASR tower but NO current ULS licence at those coordinates, meaning the antenna farm outlived the licensed service.

**Rate limits.** Bulk files only — no per-request throttling concern, but the complete archives are large (hundreds of MB to multiple GB across services). Pull the weekly complete once, then apply daily deltas.

**Robots / ToS posture.** Could not verify robots.txt — fcc.gov is blocked by this session's egress proxy. The Public Access Files are explicitly published for 'research and private programming efforts without any registration requirement', so bulk retrieval of the download endpoints is clearly intended. The interactive wireless2.fcc.gov JSP search app is a different posture and should be crawled gently regardless.

**Notes.** Record layout PDFs: https://www.fcc.gov/sites/default/files/public_access_database_definitions_20240215.pdf (91-page current version) and older v2/v4 variants at .../public_access_database_definitions_v2.pdf and _v4.pdf. Intro doc: https://www.fcc.gov/sites/default/files/pubacc_intro_11122014.pdf. Keep multiple layout versions: older archived ZIPs use earlier column counts and a naive parser will silently misalign.

---

### 4.5 · HIFLD Archive on Source Cooperative (SeerAI) — Parquet bulk snapshot

`CRITICAL` · tier **P3** · <https://source.coop/seerai/hifld>

*Serves:* substations · transmission · power plants · communications · government facilities · full HIFLD snapshot

**Holdings.** A complete bulk archive of the HIFLD Open corpus taken before the August 2025 shutdown, converted to GeoParquet. Each original HIFLD dataset is archived as its own Parquet file; records are spatially sorted to geohash level 8, which makes bounding-box scans cheap. Covers the full HIFLD subject range including energy (substations, transmission, power plants), communications (towers, cellular, microwave), water, government facilities, and emergency services.

**Access method.** S3-compatible object storage via the Source Cooperative data proxy — no authentication required. List: aws s3 ls s3://seerai/hifld --endpoint-url https://data.source.coop --no-sign-request. Read directly with DuckDB (httpfs/spatial extensions), GeoPandas, or Sedona without downloading the whole corpus.

**Format returned.** GeoParquet, spatially sorted

**Search technique.** This is the right corpus for a one-time full ingest into PostGIS. Use DuckDB: INSTALL httpfs; INSTALL spatial; then SELECT * FROM read_parquet('s3://seerai/hifld/<dataset>/*.parquet') with a bbox predicate. Because it is a FROZEN 2025 snapshot and the NASA/PASDA mirrors are live, diffing the two is itself an evidence source: a facility that appears in the frozen archive but not in the live mirror has been removed since, and the register should record that movement.

**Rate limits.** Unmetered anonymous S3-style reads through the Source proxy. Practical constraint is your own egress.

**Robots / ToS posture.** Explicitly published for open programmatic access; the Source Cooperative data proxy is designed for unauthenticated AWS CLI / S3 client use.

**Notes.** Access docs: https://docs.source.coop/data-proxy and https://github.com/source-cooperative/data.source.coop. Parallel preservation efforts worth holding as independent copies: DataLumos 'HIFLD OPEN GIS Data Index and Crosswalk' (https://www.datalumos.org/datalumos/project/241367/version/V1/view — an ICPSR-hosted index/crosswalk, valuable for mapping old HIFLD layer names to new homes) and the Data Rescue Project's 400+ dataset snapshot (https://www.datarescueproject.org/hifld-data-saved/). Post-shutdown continuation: 'HIFLD Next' from Public Environmental Data Partners / Fulton Ring (https://screening-tools.com/blog/hifld-next-restoring-americas-infrastructure-datasets), 400+ layers. DHS's remaining public page: https://www.dhs.gov/gmo/hifld; the surviving public archive at Naval Postgraduate School CHDS: https://www.hsdl.org/hifld/. HIFLD Secure (commercially licensed + CUI layers) requires a GII account and an approved Data Use Agreement — that is a documented, deliberate access wall, not an oversight.

---

### 4.6 · HIFLD Open — NASA NCCS live ArcGIS mirror

`CRITICAL` · tier **P3** · <https://maps.nccs.nasa.gov/mapping/rest/services/hifld_open/>

*Serves:* substations · transmission lines · microwave towers · communications facilities · national coverage

**Holdings.** A working ArcGIS REST mirror of the DHS HIFLD Open service tree, organised into the original folders (energy, communications, commercial, geonames, and others). Confirmed live layers include communications/MapServer/8 and FeatureServer/8 = 'microwave_service_towers' — the HIFLD microwave tower layer, which is an ASR-derived but independently curated point set. The energy folder carries the electric substations and transmission line layers. This matters enormously because DHS shut down HIFLD Open in August 2025 and the canonical hifld-geoplatform.opendata.arcgis.com portal is gone.

**Access method.** ArcGIS REST API — standard /query endpoints with where=, geometry=, outFields=*, f=geojson|json, resultOffset/resultRecordCount paging. Append ?f=json to any service or layer URL for the schema.

**Format returned.** Esri FeatureServer/MapServer; GeoJSON, Esri JSON, or paged query output

**Search technique.** GET {layer}?f=json first to read the field list, then page /query?where=1%3D1&outFields=*&f=geojson. HARDENING PATTERN for the substations layer: find substations whose MAX_VOLT is high (≥115 kV) but whose LINES count is low and which sit at the terminus of a single radial feed serving no named load — a dedicated high-voltage radial to a location with no visible industrial customer is a strong signal. Second pattern: substation footprints inside or adjacent to federal land parcels where no generation, no town, and no industrial site exists. Third: cross-reference the microwave_service_towers layer against ASR — HIFLD's curation sometimes retains sites the FCC has since purged.

**Rate limits.** ArcGIS default maxRecordCount is typically 1000–2000 features per query — you must page with resultOffset. No published quota; be conservative on a research-institution server.

**Robots / ToS posture.** Unverified (domain not resolvable from this session's DNS). NASA NCCS is a research computing service, not a public data portal — treat the mirror as a courtesy and prefer the archived bulk copies (Source Cooperative, DataLumos) for full-corpus pulls, using NCCS only for targeted queries.

**Notes.** Other surviving ArcGIS mirrors of HIFLD layers, useful for redundancy and for detecting what was quietly changed: https://mapservices.pasda.psu.edu/server/rest/services/pasda/HIFLD_FEMA/MapServer (Penn State PASDA — layer 83 is Microwave_Service_Towers_HIFLD), https://oceandata.rad.rutgers.edu/arcgis/rest/services/RenewableEnergy/HIFLD_Electric_SubstationsTransmissionLines/MapServer (Rutgers), and https://services2.arcgis.com/FiaPA4ga0iQKduv3/arcgis/rest/services/Power_Plants_in_the_US/FeatureServer (FEMA GeoPlatform).

---

### 4.7 · long-lines.net — AT&T Long Lines Places and Routes

`CRITICAL` · tier **P4** · <https://www.long-lines.net/places-routes/>

*Serves:* site identity (CLLI) · hardened/underground determination · route membership · network role · Bell System provenance

**Holdings.** The most complete open compilation of the AT&T Long Lines microwave and L-carrier coaxial network, organised by CLLI (Common Language Location Identifier) code. Per-site pages document tower type and height, building construction, whether the site is hardened/underground, generator and air-filtration provisions, route membership, and the AUTOVON/defence-network role where known. Site pages carry both true CLLI codes and AT&T's internal bracketed cover names. Includes explicitly documented hardened underground sites (e.g. Lyons, NE — an underground blast-hardened building with a 329-ft self-supporting steel lattice tower and a surface entry structure; the [MD-1] site, an AUTOVON switching centre).

**Access method.** Static HTML scrape. URL grammar is highly regular: https://long-lines.net/places-routes/{IDENTIFIER}/index.html where IDENTIFIER is either an 8-character CLLI (e.g. FLKNMDFK), a short route code (e.g. MD01), or a Place_ST slug (e.g. Lyons_NE).

**Format returned.** Static HTML with embedded photographs and scanned Bell System documents

**Search technique.** Enumerate the /places-routes/ index to get the full identifier list, then fetch each site page once. Parse for the literal strings 'underground', 'hardened', 'blast', 'bunker', 'below ground', 'AUTOVON', 'Project Office', 'L-carrier', 'coaxial', 'repeater', and for tower height in feet. THIS IS A BACKWARD-SOURCING TARGET, not a primary: long-lines.net is itself a compilation, and many of its claims trace to Bell Laboratories Record articles, Bell System Practices, and AT&T route maps that should be cited directly where the site names them. Use the CLLI code as the join key back to FCC ULS location records and ASR registrations — the CLLI is the stable identity that survives the AT&T→American Tower ownership churn.

**Rate limits.** Small independent site — crawl at ≤1 req/2s, cache everything, do not re-crawl frequently.

**Robots / ToS posture.** Not verifiable from this session. Enthusiast-run; assume a courtesy crawl budget and identify your agent. Prefer a single full mirror over repeated partial crawls.

**Notes.** CLLI code background: the FCC maintains a CLLI code list at https://www.fcc.gov/clli-code-list; commercial lookup at clli.com. A parallel enthusiast corpus with per-site FCC licence citations and route maps for Missouri and elsewhere: https://personal.garrettfuller.org/blog/att-long-lines/ (Garrett Fuller). coldwar-c4i.net is the other standing reference for AUTOVON/AUTODIN/hardened C4I sites. All of these are P4 — admit them to the register, then source each specific claim backwards.

---

### 4.8 · Colorado Division of Water Resources — CDSS HydroBase REST API

`HIGH` · tier **P1** · <https://dwr.state.co.us/rest/get/help>

*Serves:* well depth · aquifer · permitted use · yield · location

**Holdings.** Full well permit and well construction record set for Colorado, queryable by field: permit number, receipt, location (PLSS section/township/range and lat/long), permitted use, aquifer, total depth, static water level, yield, pump rate, and the well's water-right association. Also groundwater levels, structures, diversion records, and water rights.

**Access method.** REST API at https://dwr.state.co.us/rest/get/api/v2 with self-documenting help at /rest/get/help. Free API key available on request to raise query limits. Also a map viewer at https://maps.dnrgis.state.co.us/dwr/Index.html?viewer=dwrwellpermit and flat downloads via CDSS and the Colorado Information Marketplace.

**Format returned.** JSON / CSV over HTTP GET

**Search technique.** HARDENING PATTERN — the anomalous-well test, done properly: for each PLSS township, compute the distribution of total_depth for wells with permitted_use in ('irrigation','domestic','stock'). Then flag wells whose total_depth exceeds the local 95th percentile by a wide margin AND whose permitted use is 'commercial', 'industrial', 'other', or is coded to a government applicant. A 1,200-ft well in a township where agricultural wells bottom out at 250 ft, drilled for a non-agricultural use, on a parcel with no visible facility, means someone needed water independent of the municipal system and independent of the shallow aquifer that a siege or contamination event would compromise. Second signal: yield/pump rate far exceeding domestic norms at a site with one small building — that is cooling water or a fire-suppression reserve for a large equipment load. Third: multiple wells permitted to the same applicant at one location (primary + backup), which is a redundancy requirement, not a farm.

**Rate limits.** Query limits enforced per-caller; a free API key raises them. Documented in the /rest/get/help pages.

**Robots / ToS posture.** Purpose-built public REST API; programmatic use explicitly supported and keyed.

**Notes.** CDSS datastore reference documentation, which enumerates every queryable field: https://opencdss.state.co.us/statedmi/latest/doc-user/datastore-ref/ColoradoHydroBaseRest/ColoradoHydroBaseRest/ — this is the single best field-level reference for the API and is easier to work from than the raw help endpoint.

---

### 4.9 · EIA Form EIA-860 / EIA-860M / EIA-923 and the EIA API v2

`HIGH` · tier **P1** · <https://www.eia.gov/electricity/data/eia860/>

*Serves:* generation capacity · plant location · in-service/retirement dates · fuel type

**Holdings.** EIA-860: generator-level detail for every plant ≥1 MW combined nameplate capacity — operator, plant location (lat/long, county, FIPS), unit type, prime mover, in-service date, retirement date, energy source, nameplate capacity, summer/winter capability, and associated environmental equipment. EIA-860M: preliminary monthly generator inventory, so new units appear before the annual form. EIA-923: monthly plant-level generation and fuel consumption. Historical EIA-860A/860B predecessor data is bundled.

**Access method.** Annual/monthly Excel and CSV ZIP downloads from eia.gov; plus the EIA API v2 (https://www.eia.gov/opendata/) with a free registered API key, exposing route-based facet queries over the electricity series.

**Format returned.** XLSX and CSV bulk; JSON over the API v2

**Search technique.** HARDENING PATTERN — and be honest about the limit here: EIA-860 covers GENERATION, not CONSUMPTION, and the 1 MW threshold means a facility's standby diesel fleet often falls outside it or is reported only as 'behind the meter'. What it does reveal: a registered generating unit with prime mover 'IC' (internal combustion) or 'GT', fuel 'DFO' (distillate fuel oil), sizeable nameplate capacity, and a plant name that is a bare place name or a numeric designator, sited at coordinates with no visible power plant. Also useful: units flagged as non-utility / behind-the-meter at a location with no identifiable industrial host. For the corporate-bunker typology, the 1-MW threshold catches large data-centre generator farms that self-report.

**Rate limits.** API v2 requires a free API key; per-key request limits apply but are generous for research volumes. Bulk files unlimited.

**Robots / ToS posture.** Explicitly open data with a published API; intended for programmatic reuse.

**Notes.** Strongly prefer the normalised version: PUDL (Public Utility Data Liberation, Catalyst Cooperative) at https://docs.catalyst.coop/pudl/ ingests EIA-860, 860M, 923, the EIA bulk API, FERC Form 1, and FERC EQR into a single cleaned relational database with stable entity IDs and cross-form crosswalks, published as SQLite/Parquet. It resolves the plant-ID churn and utility-name inconsistency that will otherwise eat weeks. PUDL is P3 (derived) but its provenance is documented per-field.

---

### 4.10 · EIA U.S. Energy Atlas

`HIGH` · tier **P1** · <https://atlas.eia.gov/>

*Serves:* power plants · substations · transmission · fuel logistics · pipeline routes

**Holdings.** 84 map layers, 60 of them derived directly from EIA survey instruments: power plants (point, with plant ID, nameplate capacity, prime mover, primary fuel), substations, transmission lines, natural gas pipelines and compressor stations, petroleum product pipelines, storage facilities, natural gas processing plants, refineries, coal mines, and terminals. Plant records key to EIA Plant Code, which is the join key to EIA-860 and EIA-923.

**Access method.** ArcGIS Hub with per-dataset download and API links. Every layer exposes CSV, KML, Shapefile, GeoJSON, GeoTIFF/PNG downloads plus GeoServices REST, WMS, and WFS endpoints.

**Format returned.** GeoJSON / CSV / Shapefile / Esri FeatureServer / WMS / WFS

**Search technique.** Power Plants layer item id bf5c5110b1b944d299bb683cdbd02d2a. HARDENING PATTERN: the fuel-logistics layers are underused for this beat. A petroleum product pipeline spur or a bulk fuel terminal that terminates at a location with no refinery, no airport, and no visible industrial customer is a fuel-supply signature for a facility with very large standby generation. Similarly, a natural gas lateral to nowhere. Pair with the UST/Tier II fuel-quantity sources below.

**Rate limits.** ArcGIS Hub paging (maxRecordCount) applies to the REST endpoints; the flat file downloads have no throttle.

**Robots / ToS posture.** Unverified from this session; EIA publishes these explicitly as open data with documented API links, so programmatic use is intended.

---

### 4.11 · EPA National Emissions Inventory (NEI) — point source file

`HIGH` · tier **P1** · <https://www.epa.gov/air-emissions-inventories/national-emissions-inventory-nei>

*Serves:* generator capacity · fuel throughput · operating hours · facility coordinates · triennial change

**Holdings.** Triennial facility-, unit-, and process-level emissions inventory. The point source file gives, per emissions unit: facility ID and coordinates, unit design capacity, Source Classification Code (SCC), throughput, operating hours per year, and annual emissions by pollutant. SCCs for stationary internal combustion — the 2-02-001-xx family for industrial distillate-oil reciprocating engines and the emergency-generator variants — let you isolate standby generation from process combustion.

**Access method.** Bulk download of the NEI data files (CSV/zipped flat files) per inventory year. The SCC vocabulary is queryable via the SCC Search Tool / web service at https://sor.epa.gov/sor_internet/registry/scc/ and https://ofmpub.epa.gov/sccwebservices/sccsearch/.

**Format returned.** Zipped CSV flat files

**Search technique.** HARDENING PATTERN: NEI carries DESIGN CAPACITY and ANNUAL OPERATING HOURS per unit, which ECHO does not. That combination is the discriminator. A genuine emergency generator runs 50–100 hours/year for testing; a unit reporting 8,000 hours is prime power, meaning the site is off-grid or grid-independent by design — which is exactly what a hardened facility looks like. Conversely, an enormous aggregate design capacity with near-zero operating hours means a very large standby fleet held in readiness. Query: SCC LIKE '2020%' or '20200102' (distillate-oil reciprocating engines) AND design_capacity high AND facility has no NAICS consistent with the capacity. Then diff across NEI cycles (2011/2014/2017/2020/2023) — a site whose generator fleet grows without any corresponding above-ground construction is the anomaly you want.

**Rate limits.** Bulk files; none. The SCC web service is a small lookup API.

**Robots / ToS posture.** Open data programme; bulk files published for reuse.

**Notes.** SCC primer: https://sor.epa.gov/sor_internet/registry/scc/SCC-IntroToSCCs_2023.pdf. NEI point-source files are large and the SCC vocabulary has changed across cycles — carry the vintage-specific SCC table with each year's data.

---

### 4.12 · EPA UST Finder — national underground storage tank composite

`HIGH` · tier **P1** · <https://www.epa.gov/land-research/underground-storage-tank-ust-finder>

*Serves:* fuel storage capacity · tank installation dates · substance stored · facility location

**Holdings.** State-sourced national composite of underground storage tanks and leaking USTs as of 2018–2021: approximately 800,000 UST facilities, 2.2 million active and historic tanks, ~500,000 historical LUST sites and ~64,000 active LUST sites. Per-tank attributes: tank status, installation date, decommission date, wall type, capacity, and substance stored.

**Access method.** ArcGIS Hub feature layer (item 5a3ae0ed53564b6fa519f08e30e79e93, 'UST Finder Feature Layer 2021'), downloadable as shapefile/GeoJSON/CSV and queryable via the ArcGIS REST /query endpoint. Also served via EPA GeoPlatform.

**Format returned.** Esri FeatureServer / shapefile / GeoJSON / CSV

**Search technique.** HARDENING PATTERN: filter for substance='diesel' or 'fuel oil' AND aggregate facility tank capacity in the tens of thousands of gallons or more, at a facility whose land use is not fuel retail, transport, agriculture, or a hospital. A 60,000-gallon underground diesel farm at a rural coordinate with a single small building is generator fuel for something with a long autonomy requirement. Second pattern: installation_date clustered in 1959–1965 — Cold War vintage — with the tank still in 'active' status. Third: compare tank capacity against the RICE/NEI permitted generator capacity at the same coordinates; the ratio gives you a rough autonomy in days, and multi-week autonomy is a continuity-of-operations design requirement, not a commercial one.

**Rate limits.** ArcGIS Hub paging applies; bulk export unrestricted.

**Robots / ToS posture.** Open EPA research product published on ArcGIS Hub for download.

**Notes.** Fact sheet with the data model: https://www.epa.gov/sites/default/files/2020-09/documents/about_ust_finder_-_fact_sheet_final_9-24-2020_508.pdf. Note the coverage boundary: this is UNDERGROUND tanks only. Very large diesel farms at data centres and hardened sites are increasingly ABOVEGROUND (ASTs), which UST Finder misses entirely — for those you need Tier II and SPCC.

---

### 4.13 · EPCRA Tier II hazardous chemical inventories (state repositories + E-Plan)

`HIGH` · tier **P2** · <https://www.epa.gov/epcra>

*Serves:* fuel storage quantity (aboveground and underground) · container inventory · site plans · annual change

**Holdings.** Annual facility-level inventories of hazardous chemicals stored above threshold, filed under EPCRA §312. For this beat the payload is DIESEL FUEL and FUEL OIL quantities — maximum amount on site, average daily amount, number and type of containers, storage pressure/temperature, and a site plan with container locations. Diesel threshold is generally 10,000 lb (~1,500 gal), with a 100,000-gallon threshold carve-out only for compliant retail motor-fuel USTs — so any non-retail facility storing meaningful generator fuel is captured. E-Plan (UT Dallas, under EPA cooperative agreement) is the largest single repository: ~200,000 facilities and 24,000+ unique chemicals.

**Access method.** NOT openly machine-accessible. Filings go to the State Emergency Response Commission, the Local Emergency Planning Committee, and the local fire department. E-Plan (https://erplan.net/) is access-controlled to credentialed first responders. Public access is via state-by-state public-records request under EPCRA §324, which grants a public right of access to Tier II forms on written request. Some states publish partial data proactively (Texas, Minnesota, Washington have had public Tier II query tools at various times); most do not.

**Format returned.** Tier2 Submit XML/T2S files at source; delivered as PDF or spreadsheet in response to records requests

**Search technique.** This is a FOIA/records-request pipeline, not a harvester. Workflow: identify a candidate coordinate from the machine-readable sources above, determine the county LEPC and the SERC, then file a §324 request naming the facility. HARDENING PATTERN when the record arrives: an aggregate diesel inventory that implies weeks of generator autonomy; a chemical list including large stocks of sodium hydroxide or lithium hydroxide (CO2 scrubbing for a sealed environment); large halon or FM-200/Novec inventories (total-flood suppression for an unoccupied equipment space); large sulphuric acid volumes (flooded-cell station battery banks sized for a UPS plant, not a building). The COMBINATION of scrubber chemistry plus multi-week fuel autonomy plus a station battery plant is close to dispositive for a sealed, occupiable, hardened space. IMPORTANT: federal facilities' Tier II filings are frequently withheld or redacted, and EPCRA reporting by federal agencies has historically been inconsistent — record the non-response as evidence of its own kind, not as a null.

**Rate limits.** N/A — request-based, 50 state processes, varying fees and turnaround.

**Robots / ToS posture.** N/A. Do not attempt to access E-Plan; it is credentialed for emergency responders and unauthorised access would be improper regardless of technical feasibility.

---

### 4.14 · FAA Digital Obstacle File (DOF) and Daily DOF (DDOF)

`HIGH` · tier **P1** · <https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dof/>

*Serves:* structure coordinates (verified) · structure height · dismantle events · non-FCC structures

**Holdings.** Every known obstacle of aviation interest in the US plus limited Pacific/Caribbean/Canada/Mexico coverage: unique obstacle number, latitude/longitude, structure type, height AGL, height AMSL, lighting, marking, horizontal and vertical accuracy codes, verification status, and an action code (A=Added, C=Changed, D=Dismantled). Critically, the DOF is INDEPENDENT of the FCC ASR — it includes structures that were never FCC-registered (government-owned towers, non-communications masts) and its coordinates are surveyed/verified rather than self-reported.

**Access method.** Direct bulk download, no login. Full DOF on the 56-day aeronautical chart cycle; DDOF published daily as a delta.

**Format returned.** .Dat fixed-width (legacy) and CSV with decimal-degree lat/long added

**Search technique.** HARDENING PATTERN: DOF-minus-ASR set difference. A tall verified obstacle in the DOF with no corresponding ASR registration is either federally owned (federal facilities are not required to register with the FCC) or deliberately unregistered. That set difference is a direct candidate generator for government-operated towers, which is precisely the CoG/AUTOVON population. Second pattern: verification_status='O' (verified by the Obstacle Data Team) plus a very precise accuracy code on a rural structure implies a field survey happened — someone cared. Third: action='D' (dismantled) records give you tower-removal dates for correlating with site disposal.

**Rate limits.** None stated for the file endpoints.

**Robots / ToS posture.** Public aeronautical product intended for redistribution; faa.gov not fetchable from this session to confirm robots.txt.

**Notes.** README with full field layout: https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/dof/media/DOF_README.pdf. DDOF README: .../DailyDOF/media/DDOF_README_09-03-2019.pdf. An existing .dat→.csv converter script: https://gist.github.com/rhewitt22/9141903. Airspace-Encounter-Models/em-core on GitHub keeps a curated historical DOF mirror (data/FAA-DOF), which matters because the FAA does not archive superseded cycles — historical DOF snapshots are how you recover structures that existed in 1998 and are gone now.

---

### 4.15 · FERC eLibrary

`HIGH` · tier **P1** · <https://elibrary.ferc.gov/>

*Serves:* transmission siting rationale · named loads · pipeline routes · utility financials

**Holdings.** Every document submitted to or issued by FERC since 1981, searchable by docket number, accession number, filing date, filer, and full text. For this beat: transmission line certificate applications and their environmental exhibits (which name the loads a line is being built to serve), interconnection agreements, natural gas pipeline certificate filings with route maps and compressor station siting, and FERC Form 1 utility annual reports.

**Access method.** Web search form (General Search subsumes the old General/Advanced/Daily forms). No official public API; an unofficial wrapper exists at https://github.com/4very/ferc-elibrary-api. Bulk FERC databases (Form 1, Form 2, EQR) are separately downloadable at https://www.ferc.gov/download-database.

**Format returned.** HTML search results; documents are PDF (frequently scanned, OCR required for pre-2000)

**Search technique.** Full-text search eLibrary for 'critical defense facility', 'national security', 'Department of Defense load', 'government facility' within transmission certificate dockets. HARDENING PATTERN: transmission and interconnection filings must justify the line, and the justification names the customer. A 115 kV or 230 kV radial justified by a single unnamed 'federal customer' or by a load forecast with no corresponding population or industry is a direct hit. IMPORTANT ACCESS WALL: the most useful transmission detail — FERC Form 715 transmission planning studies and detailed one-line diagrams — is designated CEII (Critical Energy/Electric Infrastructure Information) and is NOT public. CEII requests require a justified application under 18 CFR 388.113 and are routinely denied to researchers. Record that boundary in the register rather than pretending around it.

**Rate limits.** Undocumented; the search app is heavy. Throttle hard. A backup instance exists at elibrary-backup.ferc.gov.

**Robots / ToS posture.** Unverified. Government transactional search app — crawl conservatively, prefer the bulk database downloads for anything volume.

---

### 4.16 · Nevada Division of Water Resources — Well Driller Reports (NDWR Open Data)

`HIGH` · tier **P1** · <https://data-ndwr.hub.arcgis.com/datasets/NDWR::well-driller-reports/about>

*Serves:* well depth · specific capacity · transmissivity · location

**Holdings.** Location and site attributes of every drilled well in Nevada from the NDWR Well Log SQL Server database, including depth, completion, and two derived fields computed by NDWR: specific capacity and transmissivity. Refreshed EVERY BUSINESS DAY by a Python job against the source database.

**Access method.** ArcGIS Hub download plus a live REST endpoint at https://arcgis.water.nv.gov/arcgis/rest/services/NDWR/Well_Driller_Reports/FeatureServer (and MapServer). Interactive text search at https://tools.water.nv.gov/WellLogQuery.aspx

**Format returned.** Esri FeatureServer / shapefile / GeoJSON / CSV

**Search technique.** Nevada matters disproportionately for this beat because of the federal land fraction and the facility density. Apply the depth-percentile anomaly per hydrographic basin (Nevada's water administration is basin-based, so basin is the right normalisation unit, not county). HARDENING PATTERN: deep well, high specific capacity, inside or adjacent to a federal withdrawal, with no agricultural context. Cross-reference against the Nevada state water-rights permit records for the point of diversion holder — a federal agency or a contractor as the permit holder is the tell.

**Rate limits.** ArcGIS maxRecordCount paging; state server, so keep concurrency low.

**Robots / ToS posture.** Published as an open-data hub dataset with a documented daily refresh; programmatic access intended.

---

### 4.17 · OpenStreetMap power/telecom layer via Overpass API and Open Infrastructure Map

`HIGH` · tier **P4** · <https://openinframap.org/>

*Serves:* substations · transmission topology · towers · bunker tagging · water wells · operator names

**Holdings.** Community-mapped electricity, telecoms, water, petroleum, and microwave communications infrastructure: power=substation (with voltage, operator, name), power=line and power=minor_line (voltage, cables, circuits), power=tower/pole, power=generator, power=plant, telecom=* , man_made=communications_tower, man_made=mast, and — directly relevant — military=bunker, building=bunker, bunker_type=*, and man_made=water_well. OpenInfraMap renders these as themed overlays including a dedicated microwave communications layer.

**Access method.** Overpass API (https://overpass-api.de/api/interpreter, plus mirrors) for targeted queries; full-planet or regional .osm.pbf extracts (Geofabrik) for bulk. OpenInfraMap itself is a renderer, not a data source — go to the underlying OSM data.

**Format returned.** Overpass XML/JSON; .osm.pbf for bulk

**Search technique.** Overpass QL for the bunker set: [out:json];(nwr["military"="bunker"](bbox);nwr["building"="bunker"](bbox);nwr["bunker_type"](bbox););out center tags; — then for the power correlation: nwr["power"="substation"](bbox);out center tags;. HARDENING PATTERN: a power=substation with a voltage tag ≥115000 whose only outgoing power=line terminates at a node with no power=plant and no settlement — a high-voltage radial to nothing. Second: a power=line ending at a point tagged nothing at all, which OSM mappers frequently do when they can trace pylons on imagery but cannot identify the destination. Those dead-end traced lines are, empirically, one of the better citizen-generated leads in this beat. IMPORTANT PROVENANCE CAVEAT: OSM bunker and military tagging is heavily contaminated by hearsay and by armchair mapping from imagery. Treat every OSM bunker tag as a CLAIM to be sourced backwards — check the changeset, the mapper, and the source=* tag. Many such nodes trace to a single blog post.

**Rate limits.** Overpass public instances enforce strict per-IP timeout and slot limits and will 429 you. For anything at scale, use a Geofabrik regional extract with osm2pgsql instead of hammering Overpass — this is the correct engineering choice, not a workaround.

**Robots / ToS posture.** OSM data is ODbL-licensed; attribution and share-alike obligations attach to any derived database you publish. This has real consequences for the register's licensing — record it. Overpass public instances publish usage policies that must be honoured.

---

### 4.18 · PeeringDB API

`HIGH` · tier **P2** · <https://www.peeringdb.com/apidocs/>

*Serves:* datacenter facility location · network presence · interconnection density · operator identity

**Holdings.** Voluntary but near-comprehensive registry of interconnection facilities and networks. Objects: org, fac (colocation facility — name, address, city, country, latitude, longitude, operator, CLLI where supplied), ix (exchange), net (network/ASN), poc (contacts); derived: ixlan, ixpfx, netixlan, netfac (which networks are present in which facility), ixfac. For the corporate-bunker typology this is the authoritative map of where networks physically terminate.

**Access method.** REST at https://www.peeringdb.com/api/{object}. Field-name URL parameters for filtering; numeric fields support __lt/__lte/__gt/__gte/__in; string fields support __contains/__startswith/__in (all case-insensitive); the `since=<unix timestamp>` parameter returns everything modified since, which makes incremental sync trivial. Anonymous access is heavily rate-limited; an API key raises limits substantially.

**Format returned.** JSON

**Search technique.** GET /api/fac?country=US&depth=0 for the facility universe, then /api/netfac?fac_id=N for occupancy. HARDENING PATTERN for the corporate-bunker typology: facilities whose name or notes contain 'bunker', 'underground', 'cave', 'mine', 'vault', 'hardened', 'SCIF', 'Level 3 secure' — these are marketed features, so operators say so. Then cross-check the coordinate against USGS topo history for a former mine or quarry (the Iron Mountain / Kansas City SubTropolis / Springfield Underground pattern). Second pattern: a fac with unusually high netfac count relative to its metro — a facility punching above its market means it inherited legacy carrier plant, which frequently means it inherited a Cold War-era carrier hotel or hardened switching centre. Cross-reference fac addresses against the AT&T/Western Union long-lines building list.

**Rate limits.** Anonymous requests are throttled aggressively and some fields (contacts) are hidden without authentication. Register for an API key. Use `since=` for deltas rather than re-pulling.

**Robots / ToS posture.** Documented public API with an explicit key-based tiering model; automated use is the intended mode.

---

### 4.19 · State air-permit registries beyond ECHO (the Title V / minor-NSR layer)

`HIGH` · tier **P2** · <https://echo.epa.gov/tools/data-downloads>

*Serves:* generator equipment inventory · permitted runtime · fuel storage · applicant self-description

**Holdings.** The permits themselves. ECHO/ICIS-Air tells you a facility is subject to a programme; the ISSUED PERMIT DOCUMENT, held by the state or local air district, enumerates the equipment: each engine by make/model/serial, rated horsepower or kW, Tier certification, fuel, permitted annual hours, stack parameters, and the fuel storage authorised to serve it. Also the permit APPLICATION, which contains the applicant's own description of the facility and its purpose.

**Access method.** Highly variable by state. Some publish searchable permit databases with PDF documents (Virginia DEQ, California air districts including BAAQMD and SCAQMD, Texas TCEQ, Ohio EPA, Pennsylvania DEP eFACTS, Washington ecology). Others require a public-records request. Local air districts in California are separate authorities with their own systems.

**Format returned.** PDF permits (mixed text-layer and scanned); some states offer structured search results

**Search technique.** Pipeline: ECHO/ICIS-Air gives you the candidate facility ID and state → state permit system gives you the document → OCR and parse for engine ratings. HARDENING PATTERN: sum the rated kW across all permitted engines and divide by the visible above-ground floor area from building footprints. Data centres run roughly 0.5–2 kW per square foot of white space; a facility whose permitted generation implies far more load than its visible footprint can contain has that load below grade. Second pattern: read the applicant's own facility description in the application — applicants describe the facility honestly to the air regulator because misdescribing it invalidates the permit, and phrases like 'below-grade data hall', 'sub-level 2', 'hardened structure', 'continuity facility' appear in these documents where they appear nowhere else public.

**Rate limits.** Per-state; most are small servers. Throttle to ≤1 req/sec and cache.

**Robots / ToS posture.** Determine per state. Several state permit search apps have restrictive robots.txt because they are transactional. Where robots disallows, use the records-request route instead.

**Axes started.** []

---

### 4.20 · Texas Water Development Board — Submitted Driller's Reports (SDR) database

`HIGH` · tier **P1** · <https://www.twdb.texas.gov/groundwater/data/drillersdb.asp>

*Serves:* well depth · lithology · yield · owner · proposed use

**Holdings.** ~680,000 statewide well records submitted by licensed drillers to TDLR from February 2001 to present: well location, well type, proposed use, county, owner name, completion date, borehole depth, casing and screen intervals, lithologic log, static water level, and yield. Complements the older TWDB Groundwater Database (GWDB) for pre-2001 wells.

**Access method.** Bulk download of the complete database as pipe-delimited text files of every SDR table, refreshed NIGHTLY. A GIS shapefile of SDR well locations is also refreshed nightly. Interactive submission/retrieval system (TWRSRS) at https://www.twdb.texas.gov/groundwater/data/twrsrsguide.asp. Also mirrored on the Texas Water Data Hub (CKAN) at https://txwaterdatahub.org/dataset/submitted-drillers-report-database and a TACC CKAN instance.

**Format returned.** Pipe-delimited text (bulk); shapefile (locations)

**Search technique.** Same percentile-anomaly method as Colorado, but Texas gives you the LITHOLOGIC LOG as free text, which is a bonus: the driller's log describes the formation, and a log recording competent rock (limestone, granite, shale) at shallow depth on a site of interest is independent corroboration of a geology suitable for excavation. Query the owner field for federal agency strings. HARDENING PATTERN: proposed_use='industrial' or 'other', borehole_depth far above county norm, owner is a government entity or an anonymous LLC, and the location is not near any municipality.

**Rate limits.** Bulk nightly files; no throttle. CKAN mirrors provide a stable API for metadata.

**Robots / ToS posture.** Published for bulk download with a documented nightly refresh; reuse intended.

**Notes.** NGWA overview of the SDR schema and quirks: https://www.ngwa.org/docs/default-source/default-document-library/membership/20171011_state-of-texas-submitted-drillers-reports-database-(sdr).pdf. As of April 2026 the TWDB groundwater reports pages have been intermittently down; use the txwaterdatahub.org / CKAN mirrors as fallback.

---

### 4.21 · USGS National Water Information System (NWIS) — Site Service

`HIGH` · tier **P1** · <https://waterservices.usgs.gov/docs/site-service/site-service-details/>

*Serves:* well depth · aquifer · altitude · national normalisation

**Holdings.** Millions of hydrologic sites nationally with construction metadata, including well_depth_va (total well depth), hole_depth_va (borehole depth), aqfr_cd (aquifer code), alt_va (altitude), and site type codes. National, single-schema, and therefore the right instrument for cross-state normalisation where a state database is closed or awkward.

**Access method.** REST over HTTP GET. Site service supports stateCd, countyCd, huc, bBox, and site filters with siteOutput=expanded to get the construction fields. Output formats: RDB (tab-delimited, the legacy but most complete format), JSON, WaterML 1.2, KML.

**Format returned.** RDB (tab-delimited with a header comment block and a format-spec line), JSON, WaterML, KML

**Search technique.** GET https://waterservices.usgs.gov/nwis/site/?format=rdb&stateCd=CO&siteType=GW&siteOutput=expanded&hasDataTypeCd=gw — then parse well_depth_va. PARSING GOTCHA: the RDB format has a leading block of '#' comment lines, then a header line, then a FORMAT SPEC line (e.g. '5s 15s 12n') that is not data — naive readers ingest it as the first row. NWIS coverage of private and industrial wells is far thinner than a state driller-report database, so use NWIS for the national baseline distribution and the state databases for the individual anomalies.

**Rate limits.** Public service, generous but not unlimited; USGS asks for reasonable use and a descriptive User-Agent. Large state-wide pulls should be chunked by county.

**Robots / ToS posture.** Documented public web service designed for programmatic access.

**Notes.** Complementary: dataRetrieval (R) and the NWIS mapper at https://apps.usgs.gov/nwismapper/. Note that NWIS is mid-migration to the Water Data for the Nation platform; legacy waterdata.usgs.gov endpoints are being progressively retired, so pin your endpoints and expect breakage.

---

### 4.22 · Virginia DEQ — Issued Air Permits for Data Centers

`HIGH` · tier **P1** · <https://www.deq.virginia.gov/news-info/shortcuts/permits/air/issued-air-permits-for-data-centers>

*Serves:* generator fleet size and rating · permitted runtime · fuel type · corporate-bunker typology

**Holdings.** A state agency page that publishes the actual issued minor-NSR air permits for data centres, with the permitted generator fleet enumerated: engine count, individual engine rating, Tier certification level, fuel type, permitted annual runtime hours, and emission limits. Loudoun County alone has roughly 4,700 permitted emergency generators (~4,021 Tier II diesel, ~130 Tier IV) across data centres. Virginia updated its BACT presumption for data-centre gensets effective for applications received on or after 1 July 2026 (SCR + DOC + DPF, i.e. Tier 4-equivalent controls).

**Access method.** HTML page linking to per-permit PDFs; also the general VA DEQ air permit search. Comparable state pages exist elsewhere — this is the model to replicate state by state.

**Format returned.** PDF permits (text-layer, generally not scanned)

**Search technique.** HARDENING PATTERN for the corporate-bunker typology: parse permits for aggregate generator MW and permitted non-emergency runtime hours. A permit authorising NON-emergency operation (demand response / grid support) means the site is designed to island and run for extended periods — a hardening characteristic dressed as an economics play. Track the December 2025 Virginia proceeding on expanding permitted diesel runtime (https://townhall.virginia.gov/l/ViewNotice.cfm?gnid=2538) as it produces a documentary record of exactly how much autonomy operators want. Generalise the method: every state with data-centre concentration (VA, OH, GA, TX, AZ, IA, OR) has an equivalent minor-NSR permit series.

**Rate limits.** None published; small site, crawl politely.

**Robots / ToS posture.** Unverified from this session. State agency permit publication page; single crawl with caching is appropriate.

---

### 4.23 · Arizona Department of Water Resources — Wells55 registry and GWSI

`MODERATE` · tier **P1** · <https://new.azwater.gov/permitting-wells/wells-data>

*Serves:* well depth · owner · permitted use · field-verified water levels

**Holdings.** Wells55 is the complete registry of every well registered in Arizona (registry ID, owner, location by PLSS and coordinates, drill date, casing depth, well depth, water level, pump capacity, permitted use). GWSI (Groundwater Site Inventory) is the field-verified subset — ADWR staff have physically visited and measured these sites, so GWSI records carry higher confidence and continuing water-level time series.

**Access method.** ADWR publishes ZIP files of raw database extracts (GWSI tables last refreshed 2026-07-14 as of writing). Interactive Wells55 app at https://gisweb3.azwater.gov/WellReg and a record search at https://www.azwater.gov/permitting-wells/well-record-search. GIS layers at https://www.azwater.gov/gis-data-and-maps and mirrored on ArcGIS Hub (item a8fd16cca9494bd5bf0f10c7d92ad8dd).

**Format returned.** ZIP of raw database tables; ArcGIS feature layers

**Search technique.** Same depth-anomaly method, normalised by ADWR groundwater basin / sub-basin (Arizona's AMAs and INAs are the meaningful units). The GWSI/Wells55 split is analytically useful: a well that appears in Wells55 but was never field-verified into GWSI, at a location ADWR staff would ordinarily visit, may indicate access was denied.

**Rate limits.** Bulk ZIPs; none. gisweb3 app should be used interactively only.

**Robots / ToS posture.** ADWR publishes raw-data ZIPs explicitly for download.

**Notes.** GWSI Database Handbook (2021) documents every table and field: https://www.azwater.gov/sites/default/files/2022-12/GWSI_DatabaseHandbook2021.pdf

---

### 4.24 · BGP and IP registry infrastructure: RIPE RIS, RouteViews, ARIN RDAP/Whois

`MODERATE` · tier **P1** · <https://www.peeringdb.com/>

*Serves:* network operator identity · address-space registration · organisational address · announcement history

**Holdings.** Global BGP routing table snapshots and updates (RIPE Routing Information Service and University of Oregon RouteViews publish MRT dumps every 5–15 minutes from dozens of collectors), plus RIR registration data mapping IP prefixes and ASNs to organisations, addresses, and abuse contacts (ARIN RDAP at rdap.arin.net, bulk Whois available to ARIN under an AUP, and the daily-published delegated-extended statistics files from every RIR).

**Access method.** RouteViews MRT archives at archive.routeviews.org (plain HTTP directory listings, bulk). RIPE RIS at data.ris.ripe.net plus RIPEstat's REST API (stat.ripe.net/data/*/data.json). ARIN RDAP is a documented REST API returning JSON; ARIN Bulk Whois requires signing an Acceptable Use Policy and is granted for research.

**Format returned.** MRT binary (parse with bgpdump/bgpkit/pybgpstream); JSON for RDAP and RIPEstat

**Search technique.** HARDENING PATTERN for the corporate-bunker typology: RDAP the address blocks announced from a suspect ASN and read the registered ORGANISATION ADDRESS, which is often the physical facility. Then check which prefixes an ASN announces and from which PeeringDB facilities it peers. A small ASN announcing from a single facility, registered to a corporate address that resolves to a former mine or a rural coordinate, is the profile. Second: continuity-of-business providers (Iron Mountain, Data Bank, Cavern Technologies, Springfield Underground, Bluebird/SubTropolis tenants) all have ASNs and registered address space — enumerate their prefixes and you enumerate their tenants. Be honest about the limit: BGP tells you about ANNOUNCEMENT, not about geography; the geolocation step always requires PeeringDB or RDAP address data, both of which are self-reported.

**Rate limits.** RouteViews/RIS archives are bulk HTTP, unmetered but enormous. RIPEstat has a documented fair-use policy and asks for a sourceapp parameter identifying your tool. ARIN RDAP rate-limits per IP.

**Robots / ToS posture.** All designed for programmatic consumption; ARIN Bulk Whois has an explicit signed AUP that restricts redistribution — honour it.

---

### 4.25 · FCC Broadband Data Collection (BDC) / National Broadband Map public data

`MODERATE` · tier **P1** · <https://www.fcc.gov/BroadbandData>

*Serves:* fibre presence · provider identity · location-level service

**Holdings.** Provider-reported fixed broadband availability at the individual location level, keyed to the Broadband Serviceable Location Fabric. Per-location: provider (FRN + brand), technology code (fibre = 50, cable = 40, etc.), maximum advertised down/up speeds, business/residential. Also bulk fixed crowdsource data and provider-supplied service-area polygons.

**Access method.** Public data API requires generating an API token inside the BDC system plus a username. Bulk CSV downloads by state, technology, and as-of date, delivered as ZIP archives. Full API spec published: https://www.fcc.gov/sites/default/files/bdc-public-data-api-spec.pdf; download output spec: https://www.fcc.gov/sites/default/files/bdc-data-downloads-output.pdf

**Format returned.** CSV in ZIP; JSON over the API

**Search technique.** HARDENING PATTERN, and it is a weak-but-real signal: the Fabric is a location inventory, and a candidate site either appears in it or does not. A rural coordinate that IS a Fabric location and IS reported as fibre-served by a carrier, with no other fibre-served location for miles, means someone pulled fibre out to a single building in the middle of nowhere. That is expensive and it is done for a reason. Note the limitation honestly: BDC does not publish ROUTES, only service availability at locations — you cannot derive a fibre path from it. The important caveat is that BDC covers MASS-MARKET service; dedicated dark-fibre and private government circuits are outside its reporting scope entirely, so a hardened facility served by a private IRU will show as unserved.

**Rate limits.** Token-gated; limits documented in the API spec. State-level ZIPs are large.

**Robots / ToS posture.** Token-based public API with published specification; programmatic use intended and gated.

**Notes.** The Fabric itself (the underlying location database) is licensed from CostQuest and is NOT freely redistributable — access to Fabric location IDs beyond the public availability data requires a CostQuest licence. That is a hard commercial wall, not a technical one.

---

### 4.26 · FCC International Communications Filing System (ICFS) — submarine cable landing licences and §214 authorisations

`MODERATE` · tier **P1** · <https://www.fcc.gov/icfs>

*Serves:* cable landing points · terrestrial backhaul · carrier identity · national-security review record

**Holdings.** All applications, supporting documents, pleadings, public notices, Commission actions, and final authorisations for submarine cable landing licences (47 CFR Part 1 Subpart FF) and international §214 authorisations. Cable landing licence applications contain the landing-point coordinates, the cable landing station address, the beach manhole location, and the terrestrial backhaul description.

**Access method.** ICFS Quick Search and Advanced Search web forms. Filing is mandatory-electronic. No documented public bulk API; the search app returns HTML with per-filing document links. Public notice summaries also appear in the daily FCC releases at docs.fcc.gov/public/attachments/DA-*.

**Format returned.** HTML search; PDF filings

**Search technique.** Search by file-number prefix 'SCL-' (submarine cable landing) and 'ITC-' (international §214). HARDENING PATTERN: cable landing STATIONS are themselves hardened by design — they are the terminus of an intercontinental asset and are built to survive. The filings give you the exact station address. More subtly, the Team Telecom / Committee for the Assessment of Foreign Participation national-security review record (see the 2025 rulemaking, FCC 24-119 and FCC 25-49) documents which landing stations and backhaul routes the US government considers sensitive — that judgement is itself evidence about which routes carry government traffic. Also: §214 discontinuance filings tell you when a carrier abandoned a route, which dates the decommissioning of the plant along it.

**Rate limits.** Undocumented; interactive app, throttle hard.

**Robots / ToS posture.** Unverified (fcc.gov egress-blocked from this session).

**Notes.** Rules: https://www.ecfr.gov/current/title-47/chapter-I/subchapter-A/part-1/subpart-FF. Submarine cable applications landing page: https://www.fcc.gov/submarine-cable-applications. For cable geography as a map product, TeleGeography's Submarine Cable Map is the standard reference and publishes an open dataset on GitHub (github.com/telegeography/www.submarinecablemap.com) — P3, derived, but with landing-point coordinates and a permissive posture.

---

### 4.27 · FERC Electric Quarterly Reports (EQR) bulk database

`MODERATE` · tier **P1** · <https://www.ferc.gov/power-sales-and-markets/electric-quarterly-reports-eqr>

*Serves:* power purchase counterparties · delivery points · contract terms

**Holdings.** All physical wholesale power contracts and transactions filed by jurisdictional sellers since 2013 (with earlier data in a legacy format): buyer, seller, contract terms, delivery point, price, quantity, product type, for cost-based and market-based sales and transmission service. Over 4 billion transaction rows.

**Access method.** Bulk download of quarterly ZIPs from https://www.ferc.gov/download-database. Each outer ZIP contains one inner ZIP per respondent per quarter; each inner ZIP contains one CSV per table (4 tables). XML variant also offered.

**Format returned.** Nested ZIP → CSV (and XML)

**Search technique.** HARDENING PATTERN: query the contracts table for customer_name matching federal agencies — 'United States', 'Department of Energy', 'Department of Defense', 'General Services Administration', 'Department of the Army', 'National Nuclear Security', 'Federal Aviation Administration' — and read the delivery-point field. A federal power purchase with a named delivery point at a substation serving nowhere obvious is a strong locate. Also query for delivery points that are named substations you have already flagged as anomalous radials.

**Rate limits.** HARD LIMIT, documented: only three users may download simultaneously. Compressed database exceeds 15.5 GB. FERC explicitly advises scheduling pulls for off-peak hours (nights, Sundays).

**Robots / ToS posture.** Bulk download intended for public analysis; respect the concurrency cap, which is a stated technical limit not a guess.

**Notes.** PUDL has done the ingestion work and documents the EQR schema at https://docs.catalyst.coop/pudl/en/latest/data_sources/ferceqr.html and the parsing pain at https://catalyst.coop/2025/11/17/capturing-the-elusive-ferc-eqr/. Commercial repackaging exists (Yes Energy) — paywalled, avoid.

---

### 4.28 · Municipal and state building energy benchmarking disclosure datasets

`MODERATE` · tier **P1** · <https://catalog.data.gov/dataset/?tags=local-law-84>

*Serves:* whole-building electricity consumption · EUI · floor area · use type

**Holdings.** Whole-building annual (and in some cases monthly) energy and water consumption for large buildings in jurisdictions with disclosure mandates: NYC (Local Law 84, buildings >50,000 sq ft, ~2,000–30,000 properties depending on year), Washington DC, Seattle (plus Building Tune-Up reports on a 5-year cycle), Boston, Chicago, San Francisco, Philadelphia, Minneapolis, Denver, and a growing set of statewide programmes. Fields typically include address, BBL/parcel ID, primary use type, year built, gross floor area, site and source EUI, total annual electricity (kWh), natural gas, steam, ENERGY STAR score.

**Access method.** Open data portals with Socrata/CKAN APIs. NYC LL84 current series dataset ID 5zyy-y8am on data.cityofnewyork.us, with a full SODA API. Others via each city's portal and data.gov.

**Format returned.** JSON/CSV over Socrata SODA API; CSV bulk

**Search technique.** THIS IS THE ONLY ROUTE TO GENUINE FACILITY-LEVEL ELECTRICITY CONSUMPTION IN THE US, and it is geographically narrow. HARDENING PATTERN: compute site EUI and flag buildings whose EUI is an extreme outlier for their declared use type — an 'office' with a data-centre EUI is a data centre, and a modest-footprint building with an EUI implying megawatts of continuous load has most of its plant somewhere other than the reported floor area, which in an urban context usually means below it. Carrier hotels and hardened urban switching centres (33 Thomas St, 60 Hudson, 811 Tenth Ave in NYC; 1 Wilshire in LA) are directly visible in these datasets. Second pattern: a building reporting a large floor area with implausibly LOW EUI is often mis-reporting because the occupied sub-grade portion is excluded. Be explicit in the register that this method only works inside disclosure jurisdictions — it is a city method, not a national one.

**Rate limits.** Socrata: generous, higher with a free app token.

**Robots / ToS posture.** Open data portals with documented APIs; reuse intended.

---

### 4.29 · Utah Division of Water Rights — well logs and water right records

`MODERATE` · tier **P1** · <https://waterrights.utah.gov/wellinfo/>

*Serves:* well depth · water right ownership · documentary correspondence

**Holdings.** Well drilling records (WELLDRILL) with driller's logs, plus the complete water-right documentary file — applications, correspondence, proofs — scanned to PDF for every water right in the state, with a structured database of key fields per right. Well log search supports location search by PLSS section or by radius, and map search.

**Access method.** Web query forms: well log search at https://waterrights.utah.gov/wellinfo/wellsearch.asp, water right search at https://waterrights.utah.gov/search/, records query at https://waterrights.utah.gov/wrinfo/query.asp. No documented REST API; the forms are GET-parameterised and scriptable. Statistics pages at /wellinfo/stats2k/ give the baseline distributions you need for anomaly detection.

**Format returned.** HTML result tables; scanned PDF documentary files (OCR required)

**Search technique.** Utah's distinguishing feature is the SCANNED DOCUMENTARY FILE per water right, which includes correspondence. For a candidate site, pull the water right's full file and OCR it — applications by federal agencies and their contractors, and the agency correspondence about them, are in there and frequently describe the intended use in prose. Use the radius search around a candidate coordinate rather than trying to enumerate.

**Rate limits.** Undocumented; modest state server, throttle to ≤1 req/sec.

**Robots / ToS posture.** Unverified. Public records search app — crawl conservatively.

---

### 4.30 · Western Area Power Administration and the federal Power Marketing Administrations

`MODERATE` · tier **P1** · <https://www.wapa.gov/about-wapa/customers/>

*Serves:* federal power delivery · transmission paths · delivery points · end-use federal customers

**Holdings.** WAPA publishes a complete list of its 685+ firm and non-firm wholesale power customers, and — critically — explicitly identifies END-USE customers including federal and state agencies that consume WAPA power directly rather than reselling it. WAPA operates a 15-state high-voltage transmission network. OASIS (Open Access Same-Time Information System) publishes transmission service requests, available transfer capability, and reservations by path. Bonneville Power Administration, Southeastern Power Administration, and Southwestern Power Administration are the parallel institutions.

**Access method.** Customer list as an HTML/PDF page. OASIS at https://www.wapa.gov/transmission/oasis/ — OASIS nodes across all PMAs and RTOs share a standardised template and are machine-readable (the OASIS standard defines CSV/XML templates and query URLs).

**Format returned.** HTML/PDF (customer list); OASIS standardised CSV/XML templates

**Search technique.** HARDENING PATTERN: read the WAPA end-use customer list directly. A federal agency taking power AS AN END USE from a PMA rather than from the local utility is a deliberate arrangement — it means the facility is served on federal transmission with federal hydropower, which is a resilience decision. Cross-reference each named federal end-use customer against the delivery point in the OASIS reservations and against the substation layer. This is a small, high-signal list rather than a big dataset, and it is the closest thing to a public register of 'which federal facilities have deliberately independent power supply arrangements'.

**Rate limits.** OASIS nodes are transactional systems used by real traders; throttle and identify yourself.

**Robots / ToS posture.** Unverified. OASIS is a regulatorily mandated open-access system — machine access is the entire point of it — but the query templates are the correct interface, not scraping the web UI.

---

### 4.31 · NTIA Government Master File (GMF) of federal frequency assignments

`LOW` · tier **P2** · <https://www.ntia.gov/>

*Serves:* federal spectrum use (aspirationally)

**Holdings.** The federal counterpart to the FCC ULS: every federal government frequency assignment, including the microwave and CoG networks that are entirely absent from FCC records because federal users are licensed through NTIA/IRAC, not the FCC. Fields would include agency, frequency, emission, station class, and location.

**Access method.** NOT publicly available in any usable form. NTIA classifies any list of two or more otherwise-unclassified GMF records specifically to prevent aggregation, on national-security grounds. A FOIA-released PDF of unclassified entries exists and circulates (extensively discussed on RadioReference forums, thread 428949) but represents LESS THAN 10% of the file.

**Format returned.** FOIA-released PDF (partial); the underlying file is not released in any machine format

**Search technique.** Treat this as a documented ACCESS WALL, not a source. The register should record explicitly that federal microwave and land-mobile assignments — the exact records that would locate CoG communications sites — are deliberately withheld by aggregation classification, and that the FCC ULS therefore has a systematic blind spot precisely where this project needs data. The partial FOIA PDF is worth ingesting as a P2 fragment with an explicit note that it is <10% of the whole and non-randomly selected. The NTIA Redbook (Manual of Regulations and Procedures for Federal Radio Frequency Management, https://www.ntia.gov/files/ntia/publications/ntia_manual_september_2017_revision_0.pdf and the 2021/2023 revision annexes) is fully public and documents the assignment record STRUCTURE, station-class codes, and agency codes — useful for interpreting whatever fragments you do obtain. GAO-11-352 (https://www.gao.gov/assets/a318271.html) audits NTIA's spectrum management and describes the GMF's contents and deficiencies from the outside.

**Rate limits.** N/A

**Robots / ToS posture.** N/A — no public interface exists.

---

## Gaps for this beat — the expected-record raw material

*Every statement here becomes, or should become, a row in `registry.erp_profile`. A record
class that does not exist for a given authority, era or classification posture is **X0** and
produces **no row** — not a zero. This is what licenses the argument from silence in one case
and forbids it in another.*

WHAT THIS BEAT STRUCTURALLY CANNOT SEE

Federal spectrum. The single largest hole. Federal agencies are licensed by NTIA through the IRAC, not by the FCC, and their assignments live in the Government Master File, which NTIA classifies by aggregation. The FCC ULS — the richest source in this registry — therefore contains essentially nothing about the communications networks that actually serve continuity-of-government facilities. What survives in ULS is the COMMERCIAL carrier plant that those networks leased (AT&T Long Lines, Western Union), which is why the Long Lines material is disproportionately valuable: it is the visible commercial shadow of an invisible federal system. To close this you would need either a sustained FOIA campaign against NTIA (historically unproductive; the released fragment is under 10% and non-randomly selected) or agency-by-agency FOIA for site-specific frequency authorisations, or recourse to declassified historical records — which is a different beat's problem.

Facility-level electricity consumption, nationally. There is no US public dataset of how much power an individual facility draws. EIA-861 aggregates to the utility; EIA-923 reports GENERATION not consumption; FERC Form 714 gives hourly load by planning area, not by customer. The only genuine facility-level electricity data is in municipal building-benchmarking disclosure datasets, which cover large buildings in roughly two dozen cities and a handful of states — overwhelmingly urban, and therefore blind to exactly the rural hardened sites this project cares most about. The 'anomalous power draw for a site with no visible building' test is, honestly, NOT directly executable at national scale. What IS executable is the proxy chain: permitted standby generation capacity (ECHO/NEI/state air permits) plus fuel storage capacity (UST Finder/Tier II) plus a high-voltage radial with no visible load (HIFLD/OSM substations). That chain infers the load rather than measuring it, and the register should label it as inference, not documentation.

Transmission detail. The genuinely diagnostic transmission data — one-line diagrams, load-flow models, actual customer identities at delivery points, FERC Form 715 planning studies — is CEII-restricted. What is open is line geometry and voltage class. You can find the radial; you generally cannot find, from open transmission data alone, who is at the end of it. The FERC EQR counterparty route and the WAPA federal end-use customer list are the two partial workarounds and both have narrow coverage.

Fiber routes. There is no open, authoritative, national fibre route map. BDC gives service availability at locations, not routes. HIFLD's fibre layers were always partial and are now behind the shutdown. InfraPedia requires a login and its route geometry is crowd-sourced and often schematic rather than surveyed. TeleGeography's submarine map is good for landing points and useless for terrestrial routes. Real terrestrial route knowledge lives in state DOT utility-permit and railroad right-of-way records, in 811/one-call locate databases (which are emphatically not public and are protected as critical infrastructure information), and in carrier IRU contracts. This is a genuine, large, unaddressed gap. The most promising unexplored angle is state DOT longitudinal-encroachment permits and county right-of-way permits, which are public records in most states and which describe fibre conduit installation route by route — nobody has aggregated them, and doing so would be original work.

Tier II at national scale. Fuel and chemical inventory is one of the sharpest hardening signatures available — multi-week generator autonomy plus CO2 scrubbing chemistry plus a flooded-cell battery plant is close to dispositive — and it is available only through fifty separate state records-request processes with varying fees, formats, and turnaround, with federal facilities frequently withheld. There is no shortcut. This should be a standing, slow, per-candidate FOIA pipeline rather than a bulk ingest.

Aboveground fuel storage. UST Finder covers underground tanks only. Modern large diesel farms at data centres and newer hardened facilities are increasingly aboveground, and there is no national AST dataset. SPCC (Spill Prevention, Control and Countermeasure) plans are required above 1,320 gallons aggregate aboveground but are held at the facility and not filed with EPA — they are obtainable only on inspection or FOIA of an inspection file. Facility Response Plans (for the largest facilities) are filed with EPA but are treated as sensitive.

Well data coverage and quality. The state well databases are excellent where they exist (Colorado, Texas, Nevada, Arizona, Utah all have real machine access) and poor to nonexistent elsewhere. Many eastern states have no comprehensive driller-report database at all. Coordinates are frequently PLSS-centroid-derived rather than GPS. Wells on federal land are often exempt from state permitting entirely, which is a devastating gap for precisely this project — a well drilled inside a federal withdrawal to serve a federal facility may appear in no state database. USGS NWIS partially covers federal-land wells but its coverage of non-monitoring wells is thin. Closing this would require agency-specific FOIA (Army Corps, Bureau of Reclamation, DOE site environmental reports) — and DOE and DoD site-wide environmental reports and groundwater monitoring reports ARE often public and DO describe on-site water supply wells in detail. That is an unexploited seam and probably the single highest-value thing not yet in this registry.

Historical depth. Almost every source here is a CURRENT-STATE database. ULS retains cancelled licences and ASR retains dismantled structures, which is genuinely valuable, but EIA, HIFLD, UST Finder, and most state systems publish only the present. Detecting a facility that was decommissioned in 1975 requires historical snapshots that mostly do not exist. Mitigations: keep every snapshot you take, forever, and diff them — the register's own accumulated snapshots become the historical record nobody else has. Second: the Internet Archive holds prior versions of many of these portals and their download files, and mining archived versions of hifld-geoplatform.opendata.arcgis.com and of state permit search results is worthwhile. Third: historical USGS topographic quadrangles (a different beat) are the real historical instrument for this material.

Provenance contamination in the community sources. long-lines.net, coldwar-c4i.net, the enthusiast site compilations, and OpenStreetMap's bunker tagging are the richest sources of CANDIDATES and the weakest sources of EVIDENCE. They are compilations, and a large fraction of their claims trace back to a small number of originating documents — Bell Laboratories Record articles, Bell System Practices, a handful of 1990s Usenet posts, and one or two frequently-copied magazine features. The register's backward-sourcing discipline applies hardest here: for every claim taken from these sites, find what the site is citing, and if it cites nothing, record it as a claim with a single origin rather than as corroborated fact. An OSM bunker node with source=Bing and a changeset comment of 'looks like a bunker' is one person's guess, and 400 blog posts repeating a Long Lines site list is one list.

WHAT WOULD MOST IMPROVE COVERAGE, RANKED
1. A systematic pull of DOE and DoD site-wide environmental reports, groundwater monitoring reports, and NEPA documents for water-supply well and standby-power detail on federal land — public, voluminous, boring, and unindexed, which is exactly this project's thesis.
2. An aggregation of state DOT and county right-of-way utility permits to build the first open terrestrial fibre route dataset.
3. A standing per-candidate EPCRA §324 Tier II request pipeline, run patiently over years.
4. Systematic OCR of the FCC ULS application attachment corpus for legacy microwave filings — the COMSEARCH path data sheets and engineering exhibits are already public, already online, and as far as I can tell nobody has ever bulk-harvested them.
5. Continuous snapshotting and diffing of every live source in this registry, so the register accumulates the temporal dimension that none of the sources provide.


# BEAT 5 — LOCAL RECORD, ORAL HISTORY AND THE FRINGE CORPUS

**Beat as scoped:** Local record, oral history, and the fringe corpus

**Primary agent:** VERNACULAR / PALIMPSEST · **40 sources**

## Access notes for this beat

HARVEST-ENGINEERING NOTES, ordered by leverage.

1. The single biggest structural win in the vernacular half is that every chronam/Open ONI state newspaper site exposes an identical route table. One harvester, parameterized by hostname, covers Oregon, Pennsylvania, Nebraska, Georgia, Montana, New York, Texas A&M, North Carolina and more. Verified from open-oni/core/urls.py: search/pages/results/?format=json, newspapers.json, states.json, counties/<state>.json, batches.json, awardees.json, ocr.json, and per-page ocr.txt / ocr.xml / coordinates/. Search params inherited from chronam: andtext, phrasetext, ortext, proxtext + proxdistance, date1, date2, dateFilterType=yearRange, state, rows, page. batches.json gives ingest dates, so incremental re-harvest is a diff, not a re-crawl. Build this first; it is the cheapest large corpus in the beat.

2. Chronicling America itself changed under everyone's feet. The legacy chroniclingamerica.loc.gov API was retired in 2025 and the collection now lives behind the generic loc.gov collections API (?fo=json, fa= facets, c=, sp=, at=). LoC explicitly warns the migrated data is not yet fully synced with the catalog, so a null result from loc.gov is not evidence of non-digitization — always cross-check the state partner. Bulk OCR downloads are capped at 10 bulk requests per 10 minutes per IP; the JSON endpoints are throttled more tightly than the old chronam API. Use at= to trim response payloads or you will burn bandwidth on facet blocks you do not need.

3. OCR-tolerant querying beats clever querying. These corpora are 1940s–60s newsprint scanned from microfilm; word error rates are high and phrase search fails constantly. Search the rarest single token, not the phrase. Search contractor names rather than facility names, because the facility had no public name during construction but the contractor was in the legal notices, the hiring ads, and the accident reports.

4. Rate limits, consolidated. loc.gov: bulk OCR 10 req/10 min per IP, general endpoints throttled, back off on 429. Open ONI instances: undocumented, university-hosted, no CDN — 1 req/sec with an identifying User-Agent and contact email. Veridian/CDNC: undocumented, ~1 req/sec. Legistar: no published rate limit but a hard 1000-row response cap, page with $top/$skip. Wikimapia: ~100 requests per 5 minutes per domain on the free key. Reddit: 100 QPM free tier for non-commercial. Overpass public instances: slot-limited, self-host for volume. Internet Archive scrape API: cursor-paginated and generous; hits_inside and metadata should stay in single-digit concurrency. HathiTrust Bibliographic API: batches of up to 20 identifiers.

5. Things that are gone or moved, so you do not build against them. HathiTrust Data API — RETIRED 17 July 2024; use hathifiles for bulk metadata and HTRC Extracted Features 2.0 (rsync) for bulk derived text. Google Groups — discontinued Usenet in 2024, advanced search broken since 2015; useless. The UTZOO Usenet archive was removed from the Internet Archive around 2020 after sustained legal redaction demands, but complete mirrors survive at annex.retroarchive.org/utzoo/, shiftleft.com/mirrors/utzoo-usenet/, ftp.xtal.net/pub/archives/usenet/utzoo/ and SourceForge. Pushshift's public Reddit service was killed by Reddit's 2023 API changes; Project Arctic Shift is the maintained successor. Elephind was taken offline in 2023 over hosting costs and its current status is uncertain — verify before depending on it. ufomind.com (Glenn Campbell's Area 51 archive) is gone and survives only in the Wayback Machine and IA uploads.

6. Explicitly hostile terms — do not harvest. NewsBank / Access World News prohibits downloading for text-mining and prohibits scripts and web-scraping software outright, and prohibits machine-assisted indexing of its content. Newspapers.com (Ancestry), GenealogyBank, Find a Grave and Legacy.com all prohibit scraping and actively block it. HathiTrust page-image endpoints are defended. These are manual-lookup sources only; the pipeline should store the citation a human found, not the content. The one lawful free extraction path on Newspapers.com is the public Clippings layer, which exposes paper name and date for user-clipped articles.

7. Identifier conventions that will bite you. AFHRA microfilm reel scans on Internet Archive are NOT consistently named — observed forms for the same class of object include afhra-reel-a-1298, reela-4030, reel-a-1372 and afhra-n-0288-r. Never construct these identifiers; enumerate via the IA scrape API and match on the title string. Conversely, some identifier conventions are gifts: the Art Bell collection uses <YYYY>-<MM>-<DD>-coast-to-coast-am-with-art-bell-<guest>-<topic>, which parses directly into a dated guest×claim table without listening to a second of audio. CivicPlus AgendaCenter item and file IDs are sequential integers, so a jurisdiction's entire packet archive is enumerable by ID walk — use that gently.

8. Build the claim-dating layer before the claim-grading layer. Without it, every fringe finding is an assertion. The stack, by era: Usenet mirrors 1981–1991; textfiles.com BBS files with original dates 1985–1995; Wayback CDX 1996–present; Arctic Shift for Reddit 2005–present; forum per-post timestamps for the 2001–2015 window where Wayback forum coverage is patchy. The CDX invocation that does the most work is: web.archive.org/cdx/search/cdx?url=<host>/*&output=json&fl=timestamp,original,digest,statuscode&collapse=digest&from=&to= — collapse=digest converts a capture list into a change history, which is what you actually want.

9. Mirror the fringe aggregators once, then stop reading them. Biblioteca Pleyades, whale.to, subterraneanbases.com and the BeforeItsNews tier have negative evidential value and high diagnostic value: normalized and shingled into a MinHash index, they become the reference corpus that lets you auto-classify any new page as copy-versus-source. Biblioteca Pleyades URL grammar is regular and enumerable. This is the concrete implementation of the project's '400 sources are one source' rule.

10. Convert P4 bibliographies into P1 lead lists mechanically. Pull the _djvu.txt sidecars for Sauder, Cooper, Branton and the rest, and regex out document identifiers: AD-numbers, AFWL-TR-*, RAND R-/RM-/P-, Bureau of Mines RI/IC numbers, contract numbers, Federal Register cites. Each hit is a retrievable P1 document. A fringe library is a badly-formatted finding aid.

11. Succession risk is a live threat to the P3 enthusiast tier and should drive crawl priority. Ed Thelen died in 2024 (ed-thelen.org now stewarded by Greg Brown); Glenn Campbell has died; ufomind.com is already gone; Archiveteam has a preservation project page for UER. These one-person, decades-deep compilations vanish with their keepers. Mirror ed-thelen.org, nikemissile.org, radomes.org, dreamlandresort.com and equivalents now, record the mirror date, and treat the mirror as the citable artifact.

12. Community norms that are not negotiable. The urbex community deliberately withholds precise coordinates and treats public disclosure as a serious breach; UER's location database is contribution-gated for that reason. Do not circumvent the gate and do not import coordinate precision from urbex sources — take condition and interior evidence from them and derive coordinates independently. The Groom Lake community became markedly more security-conscious after Joerg Arnu's 2023 doxxing and home raid; approach with care and do not republish material identifying individuals.

13. Personal-data restraint. Obituaries and oral histories are legitimate evidence about facilities and are also records about named private individuals and their surviving families. Recommend the register store the citation and the facility-relevant assertion, not a person-level index, and keep living individuals out of scope entirely. The AAFM 'Taps for Missileers' column and veteran-association newsletters are the preferred route for missile and air-defense personnel because they are free, bulk-downloadable, published by the veterans' own association for the purpose, and carry no ToS conflict — use them in preference to Legacy.com and Find a Grave in every case where they cover the same person.

14. Verification caveat on this registry itself. The research environment I worked in had a narrow egress allowlist: github.com was reachable and I read open-oni's route table directly from source, but loc.gov, archive.org, guides.loc.gov, textfiles.com, airforcehistoryindex.org and most target hosts were blocked at the proxy. Everything not sourced from GitHub was assembled from search-result content rather than live inspection. The Open ONI route table, the Open ONI institution list, and the Legistar/OData constraints are directly verified. The loc.gov parameter grammar, the Veridian CGI grammar, the BoardDocs Domino endpoints, the Wikimapia Box parameters and the CDX invocation are from documentation and secondary sources and should be smoke-tested against the live services before an engineer commits to them. Where I have inferred a pattern rather than confirmed it, I have said so in the source note.

## High-yield query strings for this beat

- Open ONI universal harvest — swap hostname, same routes: https://<host>/search/pages/results/?andtext=<term>&date1=1950&date2=1975&dateFilterType=yearRange&rows=20&format=json ; then https://<host>/lccn/<lccn>/<YYYY-MM-DD>/ed-1/seq-<n>/ocr.txt
- `Open ONI inventory + incremental: https://<host>/newspapers.json , https://<host>/batches.json (ingest dates for diffing), https://<host>/counties/<state>.json`
- loc.gov Chronicling America: https://www.loc.gov/collections/chronicling-america/?q=<term>&fa=location_state:wyoming&dates=1955/1965&fo=json&c=100&at=results,pagination
- Veridian/CDNC GET grammar: https://cdnc.ucr.edu/?a=q&hs=1&r=1&results=1&txq=<terms>&txf=txIN&ssnip=txt&dafyq=1958&datyq=1968&e=-------en--20--1--txt-txIN--------  (a=cl&cl=CL1 enumerates titles)
- Legistar: https://webapi.legistar.com/v1/{client}/Matters?$filter=substringof('underground',MatterTitle)&$top=1000&$skip=0 ; also /MatterAttachments, /Events, /EventItems
- `CivicPlus packet enumeration: /AgendaCenter/Search/?term=<q>&CIDs=all ; /AgendaCenter/ViewFile/Item/<id>?fileID=<id>  (sequential integer IDs)`
- Internet Archive bulk enumeration: https://archive.org/services/search/v1/scrape?q=collection%3Aufonewsletters&fields=identifier,title,date&count=10000  (also creator:"Air Force Historical Research Agency" for the AFHRA reels)
- `Internet Archive in-book search: https://ia-fts.archive.org/api/v1/search/hits_inside?item_id=<id>&q=AFWL-TR  — use against Sauder to extract document numbers`
- Wayback change-history (the core dating call): http://web.archive.org/cdx/search/cdx?url=<host>/*&output=json&fl=timestamp,original,digest,statuscode&collapse=digest&from=1996&to=2010
- Newspaper construction-era euphemisms (search these, not facility names): "government installation" / "federal installation" / "defense project" / "classified project" / "communications site" / "relay station" / "no comment" + county name
- Contractor names as the real search key: "Morrison-Knudsen" | "Peter Kiewit" | "Utah Construction" | "Guy F. Atkinson" | "Paul Hardeman" | "Vinnell" | "Macco" | "Reynolds Electrical" | "REECo" | "Silas Mason" + county + 1955..1968
- Facility codewords and program names for cross-corpus search: "Project Greek Island" | "High Point Special Facility" | "Site R" | "Raven Rock" | "Federal Relocation Arc" | "Emergency Relocation Center" | "Presidential Emergency Facility" | "Deep Underground Command Center" | "DUCC" | "Deep Underground Support Center" | "DUSC" | "Hardened Intersite Cable System" | "HICS" | "AN/FSQ-7" | "SAGE Direction Center"
- Document-series identifiers to regex out of fringe full text (each becomes a P1 lead): AD[- ]?[0-9]{6,7} | AFWL-TR-[0-9]{2}-[0-9]+ | RAND (R|RM|P)-[0-9]+ | "Bureau of Mines" (RI|IC) [0-9]{4}
- NIOSH/DOL facility corpus: https://www.cdc.gov/niosh/ocas/pdfs/sec/<sitecode>/ and /pdfs/tbd/<sitecode>/ — search within for "tunnel" "vault" "underground" "igloo" "magazine" "classified operations"
- Fringe fingerprint strings — any page carrying these is in a known lineage: "1,477" | "129 underground bases" | "131 underground bases" | "Thomas Castello" | "Dulce Papers" | "Jason Bishop III" | "BRANTON" | "The Omega File" | "Nightmare Hall" | "Level 7"
- COG-folklore fingerprints with real documentary kernels underneath: "REX 84" | "Rex-84 Bravo" | "Garden Plot" | "Cable Splicer" | "Executive Order 11490" | "H.R. 645" | "800 detention camps" | "Western Virginia Office of Controlled Conflict Operations"
- Obituary/personnel patterns: "could not talk about" | "never discussed his work" | "top secret clearance" | "missile combat crew" | "launch control" + unit designation (e.g. "44th Strategic Missile Wing", "341st", "532nd Strategic Missile Squadron")
- AFHRA unit-history search terms (search units, not facilities): "4600th Support Group" | "1st Aerospace Control Squadron" | "9th Aerospace Defense Division" | "Alternate Joint Communications Center" + "hardening" | "blast door" | "survivability"
- Cold War cultural-resources grey literature: "Cold War historic properties inventory" | "Legacy Resource Management Program" | "Cold War material culture" + installation name (try npshistory.com and core.tdar.org before the .mil hosts)
- Wikimapia bounding-box sweep: http://api.wikimapia.org/?key=<key>&function=box&bbox=<w>,<s>,<e>,<n>&category=<military>&count=100&page=<n>&format=json ; OSM equivalent via Overpass QL: nwr["military"](bbox); out meta;  (use out meta for changeset attribution)
- Local-government records that reveal federal siting: "special use permit" + "communication" | "General Services Administration" | "excess federal property" | "quitclaim" | "easement" + "United States of America" | "Base Realignment"
- Usenet mirror grep for pre-1992 first appearances: annex.retroarchive.org/utzoo/ , shiftleft.com/mirrors/utzoo-usenet/ , ftp.xtal.net/pub/archives/usenet/utzoo/ — flat files, grep directly for the fingerprint strings above
- `Art Bell dated-claim index: enumerate IA identifiers matching ^[0-9]{4}-[0-9]{2}-[0-9]{2}-coast-to-coast-am-with-art-bell- and parse guest/topic from the slug`

## Sources

### 5.1 · Air Force History Index (airforcehistoryindex.org) + AFHRA microfilm on Internet Archive

`CRITICAL` · tier **P1** · <https://airforcehistoryindex.org/>

*Serves:* construction · function · chronology · personnel · unit lineage

**Holdings.** Index of ~550,000 documents held by the Air Force Historical Research Agency at Maxwell AFB as of 2001: unit histories, special studies, end-of-tour reports, oral histories, staff summaries. Each record carries an IRIS reference number and a microfilm reel call number. The underlying microfilm is progressively being scanned to the Internet Archive by AFHRA.

**Access method.** Free web index (search-only); documents via microfilm reel scans on archive.org, or by FOIA/research request to AFHRA

**Format returned.** Index: HTML. Documents: scanned microfilm PDFs, OCR quality poor to fair

**Search technique.** Unit histories are the most under-used documentary source for hardened facilities, because a wing or squadron history routinely describes its own facility in detail that no policy document would. Search the index by unit designation, not by facility name: '4600th Support Group' (Cheyenne Mountain area support), '1st Aerospace Control Squadron', '9th Aerospace Defense Division', 'Alternate Joint Communications Center', '2857th Test Squadron'. Also search construction-era terms: 'hardening', 'blast door', 'Deep Underground', 'survivability'. Once you have an IRIS number and reel call number (formats: K-, A-, B-, N- prefixes), search archive.org for that reel. Reel identifiers on IA are NOT normalized — observed patterns include afhra-reel-a-1298, reela-4030, reel-a-1372, and afhra-n-0288-r for the same class of object. Do not construct identifiers; enumerate them via the IA scrape API with creator or collection filters and match on the title string 'AFHRA Microfilm Reel <call>'.

**Rate limits.** IA scrape API: paginate with a cursor, keep concurrency low.

**Robots / ToS posture.** airforcehistoryindex.org is a volunteer-run index; be gentle. archive.org permits programmatic access via its documented APIs.

**Notes.** Two hard limits: the index stops at 2001 accessions, and it indexes *existence*, not content — you cannot full-text search the documents through it. The IA scanning program is incomplete and unpredictable in coverage. For anything not yet scanned, AFHRA takes research requests by mail/email with the IRIS number, which is a weeks-to-months turnaround. The Black Vault also mirrors an AFHRA document collection.

---

### 5.2 · Association of Air Force Missileers newsletter archive + 'Taps for Missileers'

`CRITICAL` · tier **P3** · <https://www.afmissileers.org/Newsletters>

*Serves:* personnel · function · chronology · condition · unit lineage

**Holdings.** Complete run of the AAFM quarterly newsletter, free to download, with a published index. Contains: first-person operational accounts of Atlas, Titan I/II, Minuteman, Peacekeeper, Mace, Matador and GLCM sites; site-by-site squadron histories; reunion notices that reveal unit-to-site mappings; and 'Taps for Missileers', a running obituary column that states each deceased member's squadrons, wings, and duty locations. Mirrored as a digitized serial in the University of Florida Digital Collections under item AA00047738.

**Access method.** Free PDF download; UFDC mirror is OAI/IIIF-accessible

**Format returned.** PDF with text layer; UFDC exposes structured metadata

**Search technique.** This directly answers the beat's 'obituaries that cite classified assignments' requirement, and it is free, bulk-downloadable, and full-text searchable — unlike Legacy.com or Find a Grave. Harvest via UFDC rather than the association site: https://ufdc.ufl.edu/AA00047738/<seq> enumerates issues, and PDFs sit at predictable ufdcimages.uflib.ufl.edu/AA/00/04/77/38/<seq>/<MM-YYYY>.pdf. Build a personnel→unit→site index by parsing 'Taps' entries for squadron designations (e.g. '532nd Strategic Missile Squadron') and cross-walking against known squadron site lists. Search the article text for 'launch control facility', 'LCC', 'LF', 'hardened intersite cable', 'REACT', 'deactivation', and for informal site nicknames that never appear in official documents.

**Rate limits.** None published; UFDC is robust.

**Robots / ToS posture.** AAFM publishes the archive for free public download. UFDC is an open academic repository.

**Notes.** Analogous association archives worth the same treatment: Nike veterans (nikemissile.org), SAC unit associations, Air Defense Command veterans, Navy Seabee associations. These veteran-association newsletters are the single richest vernacular source for what a site was actually like inside, and they are almost never cited by the fringe corpus — which is itself a useful signal when grading claims.

---

### 5.3 · Chronicling America — Library of Congress (post-2025 loc.gov API)

`CRITICAL` · tier **P1** · <https://www.loc.gov/collections/chronicling-america/>

*Serves:* chronology · location · construction · local reaction · personnel · land acquisition

**Holdings.** ~21M+ digitized US newspaper pages, 1690–1963 (rights-cleared window has crept forward), contributed by NDNP state partners in all 50 states + territories. Page-level OCR text, METS/ALTO, page JP2s, and the US Newspaper Directory (title-level bibliographic records with LCCN, place of publication, and holdings libraries — useful on its own for finding which paper covered a given county in a given year).

**Access method.** JSON API (no key, no account)

**Format returned.** JSON (fo=json), OCR text, JP2/PDF page images, METS/ALTO XML, bulk OCR tarballs

**Search technique.** The legacy chroniclingamerica.loc.gov API was retired in 2025; the collection now lives behind the generic loc.gov collections API. Base pattern: https://www.loc.gov/collections/chronicling-america/?q=<terms>&fo=json&c=100&sp=<page>. Constrain with fa=location_state:west+virginia, fa=partof:<title-slug>, and dates=1955/1965. Use at= to trim the payload (at=results,pagination) — the default response is enormous. The single highest-yield trick is that OCR error tolerance matters more than query cleverness: search the distinctive *rare* token, not the phrase. 'Greek Island' will fail; 'Greenbrier' + 'excavation' will not. Pair a construction-era window with contractor names rather than facility names, because the facility had no public name: 'Morrison-Knudsen', 'Peter Kiewit', 'Utah Construction', 'Reynolds Electrical', 'Guy F. Atkinson', 'Vinnell', 'Macco', 'Paul Hardeman Inc.' Also search the euphemisms the era actually printed: 'government installation', 'federal installation', 'communications site', 'relay station', 'radar site', 'defense project', 'classified project', 'no comment' + county name.

**Rate limits.** Endpoint-specific; the documented bulk-OCR cap is 10 bulk requests per 10 minutes per IP. The /collections and /search endpoints are throttled more tightly than the legacy chronam API was — assume single-digit requests/second at most and back off on 429. Budget for this: a full state-decade sweep is a multi-day job, not an afternoon.

**Robots / ToS posture.** Public, no key. LoC asks for reasonable crawl behavior and publishes limits at loc.gov/apis/json-and-yaml/working-within-limits/. Bulk OCR downloads are separately capped.

**Notes.** Migration is still settling — loc.gov warns that API/sitemap data is not fully synced with the catalog. Do NOT assume a null result means the paper isn't digitized; cross-check against the state partner site (see next entry), which frequently has more issues than LoC has ingested. Also note the copyright cutoff: coverage largely stops in the early 1960s, which is exactly when most hardened-facility construction peaked. The state programs, not LoC, are where post-1963 material lives.

---

### 5.4 · Claim-dating infrastructure: Wayback CDX, textfiles.com, UTZOO/Usenet, Arctic Shift

`CRITICAL` · tier **P2** · <https://web.archive.org/cdx/search/cdx>

*Serves:* claim-origin · chronology · citation-topology

**Holdings.** The tooling stack for establishing WHEN a claim first appeared, which is the load-bearing question for the entire fringe half of this beat. Layers by era: 1981–1991 — the UTZOO/Henry Spencer Usenet archive, ~2.1M posts, February 1981 to June 1991; 1985–1995 — textfiles.com's BBS file corpus with original file dates; 1996–present — the Wayback Machine; 2005–present — Reddit via Arctic Shift.

**Access method.** CDX API (no key); textfiles.com static mirror; Usenet via IA/mirrors; Arctic Shift monthly dumps + query API

**Format returned.** JSON/CDX text, plain-text mail/news batches, static text files

**Search technique.** Wayback CDX is the workhorse: http://web.archive.org/cdx/search/cdx?url=<host>/*&output=json&fl=timestamp,original,digest,statuscode&collapse=digest&from=1996&to=2005 — collapse=digest deduplicates unchanged captures, so you get a change-history rather than a capture-list, which is how you find when a page's text changed and what it said before. Use matchType=prefix or domain to sweep a whole site. To date a *string* rather than a URL, you must first find candidate hosts (via general search over the aggregator corpus) then CDX each one and diff the captures. For pre-web: the UTZOO archive was REMOVED from the Internet Archive around 2020 following sustained legal demands for redaction — but working mirrors survive at annex.retroarchive.org/utzoo/, shiftleft.com/mirrors/utzoo-usenet/, ftp.xtal.net/pub/archives/usenet/utzoo/, and on SourceForge; these are flat-file and fully greppable. Google Groups discontinued Usenet entirely in 2024 and its advanced search had already been broken since 2015, so it is not an option; narkive.com and novabbs.com are partial web front-ends over later Usenet. For Reddit: Pushshift's public service was killed by Reddit's 2023 API changes; Project Arctic Shift (Arthur Heitmann) is the maintained successor, offering large monthly dumps, a limited query API, and web search. Reddit's own API is free at ~100 QPM for non-commercial use.

**Rate limits.** CDX: undocumented but real — keep concurrency low and prefer one broad prefix query over many narrow ones. Reddit: 100 QPM free tier.

**Robots / ToS posture.** IA CDX is a documented public API. textfiles.com is an open preservation archive. Usenet mirrors are static FTP/HTTP.

**Notes.** This entry is the methodological spine of the beat. Recommend building it first, because without it every fringe claim is undatable and the whole 'one source, 399 copies' analysis is unfalsifiable assertion. Note also the honest limits: the pre-1996 record is thin and lossy, alt.* hierarchy coverage in UTZOO ends in 1991, and BBS-era material survives only where someone happened to save it.

---

### 5.5 · Documented COG scholarship — the P2 anchor for grading the fringe

`CRITICAL` · tier **P2** · <https://nsarchive.gwu.edu/>

*Serves:* function · chronology · construction · claim-origin

**Holdings.** The rigorously documented literature against which fringe claims should be graded: Garrett Graff, 'Raven Rock' (2017), extensively sourced from declassified records and interviews; Edward Zuckerman, 'The Day After World War III' (1984), the earliest serious treatment of federal relocation planning; Tom Vanderbilt, 'Survival City' (2002); L. Douglas Keeney, 'The Doomsday Scenario' (2002); William Arkin and Richard Fieldhouse, 'Nuclear Battlefields' (1985), whose appendices constitute an early open-source register of hundreds of US nuclear-related facilities and are themselves an origin point for many later list-based claims; Arkin's 'Code Names' (2005); and the National Security Archive's Electronic Briefing Books on continuity of government and nuclear command and control (William Burr's Nuclear Vault).

**Access method.** NSArchive EBBs free online with document scans; books in print/library

**Format returned.** PDF document scans with NSArchive's own citations; print

**Search technique.** NSArchive EBBs are the highest-value free primary-document collections for COG specifically — each briefing book reproduces the underlying declassified documents with archival citations (record group, box, folder), so they are simultaneously P2 analysis and P1 document delivery. Browse nsarchive.gwu.edu by the Nuclear Vault and Cyber Vault project pages. For grading work, the operationally useful move is to build a 'documented baseline' from Graff and the NSArchive — the set of COG facilities with real documentary support and their real documented functions — and then measure every fringe claim against it. Most fringe claims about COG are not fabrications of nonexistent places; they are exaggerations of real places whose real function is documented. Arkin & Fieldhouse's 1985 appendix deserves specific attention as a *list origin*: several later 'secret base list' compilations appear to be derived from it with the sourcing stripped, which is exactly the citation-topology finding this beat is meant to surface (I flag this as a hypothesis worth testing against the actual list, not a verified finding).

**Rate limits.** Unpublished; polite crawling.

**Robots / ToS posture.** NSArchive is a public research institute; documents are posted for use with attribution.

**Notes.** Also here: Trevor Paglen's 'Blank Spots on the Map' (2009) and his patch/insignia work, which are methodologically interesting (open-source tradecraft applied to classified geography) and P3; and the Washington Post/Arkin 'Top Secret America' (2010) database of contractor and intelligence facilities, which is a rare structured, published, machine-readable facility dataset from a P2 source.

---

### 5.6 · Ed Thelen's Nike Missile Site and the Nike/air-defense enthusiast register

`CRITICAL` · tier **P3** · <https://ed-thelen.org/>

*Serves:* location · function · chronology · condition · ownership/disposal

**Holdings.** The de facto authoritative public register of US Army Nike Ajax/Hercules sites: site designators, locations, activation and deactivation dates, current disposition, scanned Army technical manuals and field documents, photographs, and veteran recollections. Complemented by nikemissile.org (Nike Historical Society) and by the Army's own published site lists.

**Access method.** Free static HTML, trivially crawlable

**Format returned.** Static HTML tables, scanned PDFs/images of Army documents

**Search technique.** Directly ingestible: the site-list pages are plain HTML tables keyed by defense-area code and site designator (e.g. SF-88, C-47, HM-69), which parse cleanly into records. The scanned Army documents hosted alongside are the P1 backing for the P3 tabulation — harvest both and link them, so each site record carries its own document evidence. This is the model for what the register should look like for a whole facility class. Cross-validate against the Army's official site lists and against HAER documentation (many Nike sites were HAER-recorded, with measured drawings and photographs deposited at the Library of Congress).

**Rate limits.** None; static site, mirror it.

**Robots / ToS posture.** Open personal site, no restrictions observed; built explicitly for preservation and education.

**Notes.** Succession risk is acute and should drive priority: Ed Thelen died in 2024 and stewardship passed to Greg Brown, a Nike veteran. Sites of this kind — one dedicated person, decades of unique compilation, no institutional backing — routinely vanish when the person does. Mirror it now and record the mirror date. The same risk applies to the whole class: siloworld-type Atlas/Titan enthusiast sites, coldwar-c4i pages, radar-station registers (radomes.org for air-defense radar sites is another of this class and equally valuable).

---

### 5.7 · GlobalSecurity.org — the P3 aggregator the ecosystem treats as P1

`CRITICAL` · tier **P3** · <https://www.globalsecurity.org/wmd/facility/>

*Serves:* location · function · chronology · citation-topology

**Holdings.** Per-facility pages for a very large number of US and foreign military and WMD-related installations, including hardened and command facilities (e.g. /wmd/facility/mt_weather.htm). Founded December 2000 by John Pike, who had previously spent nearly two decades at the Federation of American Scientists directing its Military Analysis, Nuclear Resource, Space Policy and Intelligence Resource projects; a substantial portion of the facility content is carried over from Pike's 1990s FAS Military Analysis Network pages.

**Access method.** Free static HTML, no API

**Format returned.** HTML, stable URLs, frequently un-footnoted

**Search technique.** Register this explicitly as a *tier trap*. GlobalSecurity pages are typically unsourced or thinly sourced compilations of news reporting, congressional testimony, and Pike's own analysis — legitimate P3 secondary work — but they are cited across the fringe and mainstream web as though they were primary or official. When a claim's apparent 'source' is a GlobalSecurity page, that is a hop, not a terminus, and the register should say so. Practical: crawl /wmd/facility/ and /military/facility/ (stable, enumerable URL slugs), extract every facility page as a candidate record, and mark provenance as 'aggregator — requires backing'. Then diff against the archived FAS Military Analysis Network pages (fas.org/nuke/guide/usa/, retrievable from the Wayback Machine for 1996–2000) to determine which text predates GlobalSecurity and therefore originated at FAS.

**Rate limits.** Unpublished; keep it slow.

**Robots / ToS posture.** Check globalsecurity.org/robots.txt; the site is ad-supported and has historically discouraged bulk mirroring.

**Notes.** The FAS side is the more rigorous lineage and remains active: the FAS Nuclear Information Project (Hans Kristensen and successors) produces genuinely well-documented work on nuclear weapons storage locations, and the Nuclear Notebook in the Bulletin of the Atomic Scientists is peer-reviewed-adjacent P2. Distinguish FAS-today (P2) from GlobalSecurity (P3) from GlobalSecurity-as-cited-by-the-fringe (a hop).

---

### 5.8 · Internet Archive — texts, audio, and the harvest/dating infrastructure

`CRITICAL` · tier **P1** · <https://archive.org/>

*Serves:* claim-origin · chronology · construction · function · personnel

**Holdings.** For this beat specifically: AFHRA microfilm reel scans; the 'ufonewsletters' collection (Archives for the Unexplained's digitized UFO/paranormal newsletter runs); the Art Bell / Coast to Coast AM episode collections; full text of the entire fringe book corpus (Sauder, Cooper, Bishop, Nichols/Moon, Commander X); Subterranea Britannica's journal run; scanned government documents; and Usenet mirrors.

**Access method.** Public APIs: advancedsearch, scrape API, metadata API, CDX, full-text search

**Format returned.** Everything; critically, _djvu.txt full-text sidecars for scanned texts

**Search technique.** Four endpoints do most of the work. (1) Scrape API for bulk enumeration: https://archive.org/services/search/v1/scrape?q=<query>&fields=identifier,title,date,creator&count=10000 with a cursor — this is the right way to enumerate a collection like collection:ufonewsletters or the AFHRA reels, because identifier naming is inconsistent and you must match on metadata, not construct IDs. (2) Metadata API: https://archive.org/metadata/<identifier> returns the full file manifest including the _djvu.txt sidecar path. (3) Full-text-in-book search: https://ia-fts.archive.org/api/v1/search/hits_inside?item_id=<id>&q=<term> returns page-level hits inside a scanned book — this is how you find whether Sauder actually cited a given document number without reading 300 pages. (4) The CDX API (see the claim-dating entry). Practical use: pull the _djvu.txt of every fringe book in the corpus, regex out document identifiers (AD numbers, AFWL-TR-, RAND R-/RM-, contract numbers, Federal Register cites), and you have converted a P4/P5 library into a P1 lead list.

**Rate limits.** Scrape API is cursor-paginated and generous. hits_inside and metadata are lighter — keep concurrency in single digits.

**Robots / ToS posture.** IA publishes these APIs for programmatic use. Respect the documented concurrency guidance; the scrape API is designed for exactly this.

**Notes.** Copyright caveat: much of the Art Bell/Coast to Coast material and several of the fringe books are uploaded without rights clearance and can vanish. Snapshot metadata and hashes when you index them, and record that the item may become unavailable. Do not treat IA availability as permanent.

---

### 5.9 · NIOSH OCAS Special Exposure Cohort petitions, Site Profiles, and the DOL EEOICPA covered facility list

`CRITICAL` · tier **P1** · <https://www.cdc.gov/niosh/ocas/>

*Serves:* function · construction · chronology · personnel · contractor · condition

**Holdings.** For every DOE, Atomic Weapons Employer, and beryllium vendor site covered under EEOICPA: a Site Profile / Technical Basis Document describing what the facility physically was, what was in which building, what years each operation ran, and which contractor ran it — plus SEC Petition Evaluation Reports that reconstruct site operations in forensic detail specifically because the records were incomplete. Behind these sits the Site Research Database (SRDB), NIOSH's internal document store of site-specific primary records. DOL maintains the authoritative covered-facility list with operating periods and contractor names.

**Access method.** Free PDF download from cdc.gov; SRDB documents by request

**Format returned.** PDF (text-layer present, generally good OCR), HTML facility list

**Search technique.** This is the least-known high-yield corpus in the whole beat and almost nobody correlates it with facility research. Why it works: to reconstruct a worker's radiation dose, NIOSH had to reconstruct the *facility* — so PERs contain building-by-building descriptions, underground/vault descriptions, ventilation and containment details, and worker interview summaries for sites that are otherwise opaque. URL pattern is regular: https://www.cdc.gov/niosh/ocas/pdfs/sec/<sitecode>/<file>.pdf and .../pdfs/tbd/<sitecode>/... — enumerate the covered-facility list, then crawl each site code. Search within for 'tunnel', 'underground', 'vault', 'igloo', 'magazine', 'bunker', 'Building 8', 'classified operations'. The worker-interview sections are effectively an oral history corpus collected under oath-adjacent conditions.

**Rate limits.** Unpublished; federal sites tolerate modest crawling.

**Robots / ToS posture.** cdc.gov is a public federal site; crawl politely.

**Notes.** Complements: DOE Office of Legacy Management site pages (per-site histories and remediation records for closed facilities), DOE OpenNet (declassified document index), and the DOE Former Worker Medical Screening Program. The EEOICPA/AWE list is also, incidentally, a list of private industrial sites that did classified nuclear work — many of which are absent from any military facility register.

---

### 5.10 · Open ONI / chronam state instances — the universal state newspaper API

`CRITICAL` · tier **P1** · <https://github.com/open-oni/open-oni>

*Serves:* chronology · location · construction · local reaction · land acquisition

**Holdings.** State-run digitized newspaper collections running LoC's original chronam software or its community fork Open ONI. Confirmed instances include Historic Oregon Newspapers (oregonnews.uoregon.edu), Pennsylvania Newspaper Archive (panewsarchive.psu.edu), Nebraska Newspapers (nebnewspapers.unl.edu), Georgia Historic Newspapers (gahistoricnewspapers.galileo.usg.edu), Montana Newspapers (montananewspapers.org), NYS Historic Newspapers (nyshistoricnewspapers.org), Texas A&M (newspaper.library.tamu.edu), and North Carolina via DigitalNC. Many carry issues well past 1963 under local rights agreements.

**Access method.** JSON/HTTP API, identical route table across every instance

**Format returned.** JSON, plain-text OCR (.txt), OCR XML (ALTO), RDF, OpenSearch XML, ATOM feeds

**Search technique.** This is the single most exploitable fact in the whole beat: every chronam/Open ONI deployment exposes the SAME URL routes, so one harvester works against all of them by swapping the hostname. Verified from open-oni/core/urls.py — search/pages/results/?...&format=json ; search/pages/opensearch.xml ; suggest/titles/ ; newspapers.json ; states.json ; counties/<state>.json ; batches.json ; awardees.json ; ocr.json ; ocr/feed/ ; and per-page text at lccn/<lccn>/<YYYY-MM-DD>/ed-<n>/seq-<n>/ocr.txt (also ocr.xml and /coordinates/ for word-bounding boxes, which lets you highlight the hit in the page image). Search params carried from chronam: andtext=, phrasetext=, ortext=, proxtext= with proxdistance=, date1=, date2=, dateFilterType=yearRange, state=, rows= (cap it at 20–50), page=. Workflow: hit newspapers.json to enumerate titles, batches.json to detect newly ingested batches for incremental re-harvest, then paginate search/pages/results/?format=json and pull ocr.txt only for hits.

**Rate limits.** Undocumented and per-institution. These are university-funded Django/Solr stacks with no CDN in front of them — they fall over. 1 req/sec with a descriptive User-Agent and an email contact is the responsible ceiling; several admins will simply firewall an aggressive harvester.

**Robots / ToS posture.** Mostly permissive academic hosts; robots.txt varies per instance and several disallow /search paths for crawlers while leaving the JSON API usable. Check each host individually and honor it.

**Notes.** batches.json is the incremental-ingest hook: it lists batch name, awardee, and ingest date, so you can diff against last run instead of re-crawling. The open-oni wiki page 'Sites-using-Open-ONI' is the authoritative (but stale) instance list — expect to discover more by probing /newspapers.json against candidate state hostnames.

---

### 5.11 · Phil Schneider — 1995 Preparedness Expo lecture (the DUMB numerology origin)

`CRITICAL` · tier **P5** · <https://archive.org/details/philexpo>

*Serves:* claim-origin · chronology

**Holdings.** The origin of the specific, endlessly repeated numbers: ~129–131 active secret underground bases in the United States, ~1,477 worldwide, average cost $17–19 billion each, 1–2 years construction each, and the associated 'black budget' figure. Also the origin of the 1979 Dulce firefight-participant narrative in its most-copied form. Delivered as a lecture at the Preparedness Expo in 1995 (sources disagree between September and November); Schneider died in January 1996, which converted the lecture into a martyrdom text and froze it as canon.

**Access method.** Free video/audio on Internet Archive; transcripts widely mirrored

**Format returned.** Video, audio, transcript text

**Search technique.** String-match the numerals: '1,477', '1477', '129 underground bases', '131 underground bases', '$17 billion', '$19 billion'. These figures have no antecedent and no source; every occurrence anywhere is a descendant of this lecture. That makes them an ideal fingerprint — a page carrying '1,477' is definitionally in the Schneider lineage regardless of what else it claims, and its other claims should be graded accordingly. Cross-check the lecture date against the Wayback CDX and Usenet records to confirm no pre-1995 occurrence exists (I was unable to run that check directly and it should be verified).

**Rate limits.** IA standard.

**Robots / ToS posture.** archive.org APIs are open.

**Notes.** Schneider is the cleanest possible teaching example of the '400 sources, one origin' thesis: an unsourced number from a single 1995 lecture that is now cited as though it were a statistic. Note also the biographical claims (geologist, structural engineer, involvement in base construction) are unverified and disputed. Grade the content P5 while noting that the *artifact* — a dated recording — is solid evidence of when the claim entered circulation.

---

### 5.12 · Richard Pollock, 'The Mysterious Mountain,' The Progressive, March 1976 — Mount Weather origin node

`CRITICAL` · tier **P3** · <https://en.wikipedia.org/wiki/Mount_Weather_Emergency_Operations_Center>

*Serves:* claim-origin · chronology · function

**Holdings.** The single article from which essentially the entire Mount Weather folklore descends: the 'government-in-waiting' framing, the standing shadow cabinet, the claim that the facility receives raw intelligence from every federal department, and the specific personnel and capacity figures that every later retelling recycles. Based on Senate subcommittee hearings and off-the-record interviews with former Mount Weather-associated officials.

**Access method.** Print; scattered unauthorized full-text reproductions across the fringe web; The Progressive's own archive is not freely online for 1976

**Format returned.** Print / OCR'd reproductions of uncertain fidelity

**Search technique.** This is the archetype of what this project needs to demonstrate. Search the fringe web for the distinctive Pollock phrases and you will find them, verbatim and unattributed, on hundreds of pages: 'Western Virginia Office of Controlled Conflict Operations', 'the Mount Weather facility maintains its own', and the standing-cabinet passage. Any page carrying those strings without citing Pollock 1976 is a copy, not a source. Establish the canonical text once — ideally from a library copy of the March 1976 issue, not a web reproduction — then string-match against it to auto-classify the downstream ecosystem. Note the trigger context: Mount Weather became publicly discussable because TWA Flight 514 crashed into the mountain on 1 December 1974, generating an NTSB investigation and local reporting; the Senate hearings and Pollock's article followed. That crash is the reason a local vernacular record exists at all for this site — check the Loudoun/Clarke County papers for Dec 1974–1976.

**Rate limits.** N/A.

**Robots / ToS posture.** N/A (print original).

**Notes.** Grading guidance: Pollock is a real journalist working from real hearings and real sources, but with unnamed sourcing and no released documents. He is P3 — genuinely investigative, not independently verifiable. The 400 sites repeating him are not additional evidence. This is the cleanest available demonstration case for the register's core thesis.

---

### 5.13 · Richard Sauder — the document-citing fringe author

`CRITICAL` · tier **P4** · <https://archive.org/details/richard-sauder-underground-bases-and-tunnels-what-is-the-government-trying-to-hide>

*Serves:* claim-origin · construction · function · chronology

**Holdings.** 'Underground Bases and Tunnels: What Is the Government Trying to Hide?' (Adventures Unlimited, 1995), 'Underwater and Underground Bases' (2001), 'Hidden in Plain Sight' (2010). Unlike essentially every other author in this space, Sauder filed FOIA requests, worked from published federal technical literature, and reproduced actual document pages: Army Corps of Engineers and Air Force Weapons Laboratory deep-basing studies, RAND reports, Bureau of Mines and Colorado School of Mines tunneling research, Navy facility documents, and Federal Register notices.

**Access method.** Full text free on Internet Archive with _djvu.txt sidecars; in print

**Format returned.** Scanned book with OCR text layer

**Search technique.** Treat Sauder as a bibliography, not as an authority — this is the highest-leverage single move in the fringe half of the beat. Pull the _djvu.txt of both books and regex out every document identifier: AD-numbers (DTIC accession), AFWL-TR-* (Air Force Weapons Laboratory technical reports), RAND R-/RM-/P- series, Bureau of Mines RI/IC numbers, contract numbers, and Federal Register volume/page cites. Each extracted identifier is a P1 lead retrievable from DTIC, NTRL, or the Federal Register — meaning a P4 source mechanically generates P1 evidence. Specific document families he surfaces that are worth pursuing on their own: the 1960s Deep Underground Command Center (DUCC) and Deep Underground Support Center (DUSC) studies, Air Force deep-basing and superhard-silo research, and Navy underwater-facility literature. Also worth extracting: his RAND/Corps citations frequently name the *contractors* and *research programs*, which then key into other beats.

**Rate limits.** IA standard.

**Robots / ToS posture.** IA APIs open; the book is uploaded by third parties and rights status is unclear.

**Notes.** Grading nuance the register should encode explicitly: Sauder's documents are real; his inferences from them are frequently not. He moves from 'the Air Force studied deep basing' to 'therefore deep bases were built' without the intervening evidence. The correct treatment is to promote his citations to P1 and grade his conclusions P4. He is the strongest case in this beat for the proposition that a P4 source can have a real documentary track record.

---

### 5.14 · Ted Gup, 'The Ultimate Congressional Hideaway,' Washington Post Magazine, 31 May 1992 — Greenbrier

`CRITICAL` · tier **P2** · <https://www.washingtonpost.com/archive/politics/1992/05/30/hill-leaders-regret-reports-on-bomb-shelter-site/38095513-21b6-4f9f-89d6-298dc114a0c5/>

*Serves:* claim-origin · function · chronology · local reaction

**Holdings.** The disclosure of Project Greek Island, the Congressional relocation bunker under the Greenbrier resort, White Sulphur Springs WV. Directly caused the facility's deactivation (1995). Gup also published on Mount Weather in TIME in 1992.

**Access method.** Washington Post archive (paywalled but indexed); the accompanying news coverage from 30 May 1992 is free in the WaPo archive

**Format returned.** HTML archive, print

**Search technique.** The methodologically important fact for this project: the bunker's existence was an open secret in Greenbrier County for thirty years — resort staff and local residents 'all knew what it was' and treated it as a point of pride — and none of that local knowledge reached the national record until a reporter went and asked. That is a directly testable pattern. For any candidate site, the local knowledge probably already exists in the county's vernacular record; the question is whether anyone wrote it down. Search the Greenbrier-area papers (Register-Herald, Beckley; The West Virginia Daily News, Lewisburg) for 1958–1962 construction-era anomalies — unusual truck traffic, hiring notices, a 'convention facility' expansion — and treat what you find as the template for what to look for elsewhere. CONELRAD's blog (conelrad.blogspot.com) has done sustained reporting on the Greenbrier's history and is a reliable P3 secondary.

**Rate limits.** N/A.

**Robots / ToS posture.** WaPo archive is paywalled; do not scrape.

**Notes.** Contrast Gup with Pollock in the grading schema: Gup named the facility, produced documentary and testimonial corroboration, and the government effectively confirmed by shutting it down. That is P2. Pollock produced an unfalsifiable institutional description. Both are 'a journalist wrote it', and the register must distinguish them.

---

### 5.15 · The Dulce Base origin cluster: Bennewitz → LeVesque/'Jason Bishop III'/'Thomas Castello' → 'Branton'

`CRITICAL` · tier **P5** · <https://en.wikipedia.org/wiki/Dulce_Base>

*Serves:* claim-origin · chronology

**Holdings.** The canonical fabrication chain for the largest single body of US underground-base folklore. Sequence: Paul Bennewitz (Albuquerque, 1979–1980) generates the raw material while being deliberately fed disinformation; Myrna Hansen's 1980 hypnotic regression adds the underground-facility imagery; Thomas Allen LeVesque, writing as 'Jason Bishop III', authors 'The Dulce Base' in 1989; the 'Thomas Castello' persona — an alleged RAND-employed Dulce security technician with stolen 'Dulce Papers', 30 photographs and a videotape — is circulated from roughly 1987–1991; Bruce Alan Walton, writing as 'BRANTON', aggregates and vastly expands the corpus through the 1990s. LeVesque admitted before his death in 2018 that Castello never existed and that he had fabricated the Dulce material as creative writing.

**Access method.** Free web; full texts widely mirrored; primary-era material via AFU newsletter scans

**Format returned.** HTML, plain text, scanned newsletters

**Search technique.** Reverse-trace targets: the exact strings 'Thomas Castello', 'Thomas Edwin Castello', 'Dulce Papers', 'Jason Bishop III', 'BRANTON', 'The Omega File', 'Level 7', 'Nightmare Hall'. Any US underground-base claim mentioning multi-level facilities with numbered sublevels, human-alien joint operations, or 'the 1979 Dulce firefight' descends from this cluster and can be dated to it. Corroborating tracers: Greg Bishop, 'Project Beta' (2005) is the rigorous reconstruction of the Bennewitz disinformation operation and should be treated as the authoritative P2 secondary; Adam Gorightly documented LeVesque's confession; Norio Hayakawa's blog (noriohayakawa.wordpress.com) carries first-hand accounts from participants in the original Albuquerque milieu and is a genuinely useful P3-to-P4 primary-adjacent source; Christa Tilton's 'The Bennewitz Papers' records her own conclusion that Castello was fabricated. For 1979–1985 first appearances, the APRO Bulletin and other newsletters of the period are the place to look — digitized in the AFU collection on Internet Archive.

**Rate limits.** N/A.

**Robots / ToS posture.** Varies; the mirror sites are unmaintained and generally have no robots.txt.

**Notes.** Why this matters structurally: Dulce contaminates the register's inputs far beyond New Mexico. The 'multi-level underground base' template, the sublevel numbering convention, and the tunnel-network-connecting-all-bases premise all originate here and were then retrofitted onto real facilities (Mount Weather, Cheyenne Mountain, Denver, Camp Hero). When a claim about a real site carries Dulce-template features, that is strong evidence of descent rather than independent observation.

---

### 5.16 · Archives for the Unexplained (AFU) — digitized newsletter runs on Internet Archive

`HIGH` · tier **P3** · <https://archive.org/details/ufonewsletters>

*Serves:* claim-origin · chronology

**Holdings.** AFU (Norrköping, Sweden) holds ~3.5km of shelving across 15 locations: 55,000+ books, 88,000 magazine issues representing 8,000 annual titles, 650,000 newspaper clippings, 30,000 photographs, plus films and tapes. A large body of the newsletter holdings has been digitized and deposited on Internet Archive as the 'ufonewsletters' collection.

**Access method.** Free download via Internet Archive; AFU's own site has a Collections/Downloads section

**Format returned.** Scanned PDFs with variable OCR

**Search technique.** This is where the pre-internet layer of the underground-base corpus physically survives. The 1979–1985 Albuquerque/Dulce material circulated first in newsletters — APRO Bulletin, MUFON UFO Journal, regional group newsletters — and those runs are here and nowhere else in digitized form. To establish that a claim predates its usual attributed origin (or, more often, to establish that it does NOT), search this collection for the earliest occurrence. Enumerate via the IA scrape API on collection:ufonewsletters, pull _djvu.txt sidecars, and build a dated full-text index. OCR quality on mimeographed 1970s newsletters is poor — expect to need fuzzy matching, and expect names and dates to be the most reliably OCR'd tokens.

**Rate limits.** IA standard.

**Robots / ToS posture.** AFU is a nonprofit archive that has deliberately made this material public. IA APIs open.

**Notes.** A genuine and under-recognized asset: an institutional archive, run to archival standards, of a corpus that is otherwise entirely P5. The archive itself is P3 — the scans are faithful and dated — even though nearly everything in it is P4/P5 content. This distinction (archive quality vs content quality) should be a first-class concept in the register's schema.

---

### 5.17 · CivicPlus AgendaCenter / CivicClerk / PrimeGov / BoardDocs — the rest of local government

`HIGH` · tier **P1** · <https://www.civicplus.com/agenda-meeting-management/>

*Serves:* land acquisition · ownership/disposal · construction · local reaction · chronology

**Holdings.** Agendas, packets, and minutes for the small-jurisdiction majority: county commissions, township boards, planning and zoning commissions, county school boards, and utility districts. This is where a rural county's discussion of a federal land transfer, a mysterious water-line extension, or a 'no-comment' construction permit actually lives.

**Access method.** HTML scrape against per-vendor URL grammars; no public APIs

**Format returned.** PDF packets (often scanned, OCR required), HTML listing pages

**Search technique.** Each vendor has a fixed, guessable route grammar — this is the practical substitute for an API. CivicPlus AgendaCenter: /AgendaCenter/ lists categories; /AgendaCenter/Search/?term=<q>&CIDs=all&startDate=&endDate=&dateRange=&dateSelector= runs a server-side search; files download at /AgendaCenter/ViewFile/Item/<itemID>?fileID=<fileID> and /AgendaCenter/ViewFile/Agenda/<id> — item and file IDs are sequential integers, so a jurisdiction's entire packet archive is enumerable by ID walk. BoardDocs runs on Lotus Domino at go.boarddocs.com/<state>/<client>/Board.nsf/ and serves its UI from a small set of POST endpoints against that .nsf (the LlamaIndex BoardDocs reader is a working reference implementation — it retrieves a committee's meeting list with meetingID, date, and unid, then fetches agenda items by unid). PrimeGov and CivicClerk expose JSON meeting lists under /api/ or /Portal/ paths that vary by tenant; inspect one tenant and the pattern generalizes. Query terms that pay: 'special use permit' + 'communication', 'federal government lease', 'General Services Administration', 'quitclaim', 'excess federal property', 'easement' + 'United States of America', 'Air Force' + 'variance'.

**Rate limits.** Unpublished; assume fragile shared hosting. 1 req/2sec per jurisdiction.

**Robots / ToS posture.** Highly variable per jurisdiction; many CivicPlus sites disallow /AgendaCenter/ViewFile in robots.txt while permitting the listing pages. Check and honor per-host. These are small public bodies with small budgets — aggressive crawling is both rude and conspicuous.

**Notes.** Two structural gaps that matter enormously: (1) pre-2000 minutes are essentially never online, so the entire construction era of these facilities is missing from digital local government records — those minute books are in county clerks' offices on paper or microfilm and require in-person or mail requests; (2) many packets are scanned images with no text layer, so OCR is mandatory. Municode, American Legal Publishing, and Code Publishing Co. hold the codified zoning ordinances (including overlay districts and airport/military influence zones) and are separately scrapable.

---

### 5.18 · Coast to Coast AM / Art Bell episode archive — the broadcast amplification layer

`HIGH` · tier **P5** · <https://archive.org/details/the-ultimate-art-bell-collection_202201>

*Serves:* claim-origin · chronology

**Holdings.** Large collections of Art Bell-era Coast to Coast AM episodes on Internet Archive, with dated identifiers. Directly relevant broadcasts in the collection include John Lear on Area 51/UFOs (1994-09-02), Preston Nichols on the Montauk Project (1994-05-27), Al Bielek on the Philadelphia Experiment (1993-06-20), and Richard Hoagland. Bell's show from roughly 1993–2003 is the single most important amplification node in the modern American conspiracy ecosystem, and it is where Bob Lazar, Phil Schneider, Richard Sauder and the Montauk authors reached a mass audience.

**Access method.** Free streaming/download on Internet Archive (rights status unclear); official archive is behind the Coast Insider paywall

**Format returned.** MP3 audio; no official transcripts

**Search technique.** The IA identifier convention is the useful property: <YYYY>-<MM>-<DD>-coast-to-coast-am-with-art-bell-<guest>-<topic>. That means the collection is a DATED index of when each claim reached national radio, which is often the moment a claim goes from an obscure newsletter to universal circulation. Enumerate via the IA scrape API and parse identifiers into a guest×date table — that alone is a valuable artifact for this project, independent of listening to anything. To make the content searchable you must run ASR over the audio; there are no official transcripts and the fan transcripts that exist are partial and unreliable. artbellarchive.org curates the show's history, guests and topics and is a useful finding aid.

**Rate limits.** IA standard.

**Robots / ToS posture.** IA APIs are open, but much of this material is uploaded without rights clearance and is subject to takedown.

**Notes.** Sharp distinction to encode: a Coast to Coast broadcast is excellent evidence of WHEN and TO WHOM a claim was propagated, and no evidence at all of whether it is true. The register should be able to hold both facts about the same artifact.

---

### 5.19 · Glenn Campbell's Groom Lake corpus, Dreamland Resort, and Peter Merlin — the rigorous-fringe exemplar

`HIGH` · tier **P3** · <https://www.dreamlandresort.com/>

*Serves:* location · condition · chronology · claim-origin · land acquisition

**Holdings.** Glenn Campbell's 'Area 51 Viewer's Guide' (editions 1993–1998) and 'The Groom Lake Desert Rat' newsletter (1994–1996/97, ~40+ issues), plus the ufomind.com archive — field-verified perimeter documentation, BLM land-status research on the 1984 Groom Mountain Range withdrawal and the 1995 White Sides/Freedom Ridge withdrawal, security-contractor identification, and named viewpoints (Tikaboo Peak, established with Tom and Jeri Mahood). Dreamland Resort (Joerg Arnu) carries decades of photographic documentation, construction-progress tracking, and a long-running forum. Peter Merlin's aerospace-history work is archival and FOIA-based.

**Access method.** Free web; Desert Rat issues and the Viewer's Guide archived on Internet Archive; dreamlandresort.com free with an active forum

**Format returned.** HTML, plain-text newsletters, PDF compilations, photographs

**Search technique.** This is the proof-of-concept for a P3 enthusiast source with real methodology, and the register should study its technique rather than just its output. Campbell's actual method was land records, not rumor: Federal Register withdrawal notices, BLM land status plats, county recorder filings, EIS documents, and FAA charts — combined with repeat photography from legally accessible ground. That is precisely this project's method, executed in 1994 without the internet. Harvest the Desert Rat run (archive.org, including a compiled PDF) and mine it for the specific record citations. Note the divergence: the same corpus that produced Campbell's land-records work also produced Bob Lazar's 1989 S-4/Papoose Lake claims via George Knapp's KLAS-TV interviews, which are the origin of the 'S-4' element and are P5. Same geography, radically different evidentiary quality — a good calibration case.

**Rate limits.** Self-limit.

**Robots / ToS posture.** dreamlandresort.com is a private enthusiast site with a forum; respect it and do not bulk-crawl the forum. IA-archived Campbell material is fine.

**Notes.** Two cautions. Glenn Campbell has died (referenced in the dreamlandresort forum) and ufomind.com is long gone — the material survives only in the Wayback Machine and IA uploads, so snapshot it. Joerg Arnu was doxxed and had his home raided in 2023, which has made this community markedly more security-conscious; approach with care and do not republish anything that identifies individuals.

---

### 5.20 · Granicus Legistar Web API — municipal and county legislative records

`HIGH` · tier **P1** · <https://webapi.legistar.com/>

*Serves:* land acquisition · ownership/disposal · construction · chronology · local reaction

**Holdings.** Full legislative record for the thousands of US cities and counties running Legistar: matters/ordinances, agenda items, minutes, votes, sponsors, and — the payload — MatterAttachments, which are the actual staff reports, site plans, lease agreements, and correspondence. For this project the relevant records are conditional-use permits for 'communications facilities', federal lease approvals, rezonings adjacent to federal parcels, road-vacation requests, and utility-easement grants.

**Access method.** Public REST/OData API, no key

**Format returned.** JSON (OData), attached PDFs

**Search technique.** Base: https://webapi.legistar.com/v1/{Client}/... where {Client} is the jurisdiction slug (e.g. 'seattle', 'mcpl'). Core resources: /Matters, /MatterAttachments, /Events (meetings), /EventItems, /Bodies, /Persons. OData applies: $filter, $orderby, $top, $skip, $select. Responses are hard-capped at 1000 rows, so page with $top=1000&$skip=N. Text search via $filter=substringof('bunker',MatterTitle) or MatterName. Discovering the {Client} slug is the awkward part — it is not enumerable from the API; derive it from the jurisdiction's public Legistar portal hostname (<client>.legistar.com) or from the InSite URL. Build a client list by probing candidate slugs for counties adjacent to known federal installations.

**Rate limits.** Not formally published; the 1000-row cap is the main structural constraint. Keep concurrency low per client.

**Robots / ToS posture.** Granicus publishes the API as a public interface with documentation and examples at webapi.legistar.com/Home/Examples and /Help.

**Notes.** Coverage skew: Legistar is a big-city/large-county product. The rural counties that host missile fields and relocation sites mostly do not run it (see next entry). Also: minutes older than roughly the mid-2000s are almost never in these systems at all — the digital record has a hard floor.

---

### 5.21 · HathiTrust — county histories, installation histories, and trade serials

`HIGH` · tier **P2** · <https://www.hathitrust.org/>

*Serves:* chronology · location · construction · personnel · local reaction

**Holdings.** 18M+ volumes including the near-complete corpus of published US county and local histories, commemorative installation histories, engineering trade serials, and government documents. Full view for pre-1929 and for US government works of any date.

**Access method.** Full-text search web UI; bulk metadata via hathifiles; bulk derived text via HTRC Extracted Features

**Format returned.** Page images, OCR text (view-restricted), TSV hathifiles, HTRC EF JSON

**Search technique.** The HathiTrust Data API was RETIRED on 17 July 2024 — do not build against it. Remaining machine paths: (1) the Bibliographic API for metadata lookup by OCLC/LCCN/ISBN; (2) hathifiles — full tab-delimited inventory dumps, updated monthly, which give you every volume's identifier, rights code, bib data and enumeration, and are the correct way to enumerate candidate volumes; (3) HTRC Extracted Features 2.0 — page-level token counts and part-of-speech data for the full corpus, distributed by rsync, which supports large-scale term-frequency analysis without ever touching the page images; (4) the human full-text search UI, which searches inside copyrighted volumes and returns page numbers even when it cannot show you the page — meaning it works as a *locator* for material you then obtain elsewhere. Use it that way: search 'Deep Underground Support Center', 'hardened command post', a contractor name plus a county, then take the citation to a library.

**Rate limits.** Bibliographic API is documented as low-volume (batch of up to 20 identifiers per request). HTRC EF is rsync, no request-rate concern.

**Robots / ToS posture.** Scraping the page-image endpoints is prohibited and actively defended. hathifiles and HTRC EF are the sanctioned bulk paths.

**Notes.** Also here: The Military Engineer (journal of the Society of American Military Engineers, 1920–present) — the single best trade serial for hardened construction, with 1920–1930 volumes free on JSTOR and the full run in HathiTrust/JSTOR. Engineering News-Record is the other essential construction trade serial and is paywalled with no free archive; it reported on classified-adjacent projects contemporaneously and is worth manual library access. The Online Books Page (onlinebooks.library.upenn.edu/webbin/serial?id=militaryengr) indexes free volumes.

---

### 5.22 · Library of Congress Veterans History Project (AFC/2001/001)

`HIGH` · tier **P1** · <https://www.loc.gov/collections/veterans-history-project-collection/>

*Serves:* personnel · function · chronology · condition

**Holdings.** ~100,000+ veteran collections; over 70% have some material viewable online. Each record carries branch, unit of service, service locations, war/era, and rank. Interviews with missile crew, SAC command post, air defense, communications, and engineer personnel exist in quantity and are indexed by unit.

**Access method.** loc.gov collections JSON API (same stack as Chronicling America)

**Format returned.** Audio, video, digitized manuscripts, typed transcripts (inconsistently present), JSON metadata

**Search technique.** Same API grammar: https://www.loc.gov/collections/veterans-history-project-collection/?q=<term>&fo=json&c=100. Collection numbers take the form afc2001001.<5-6 digits> and item URLs are https://www.loc.gov/item/afc2001001.<id>/ — which means the ID space is enumerable if you need a complete sweep. Search by unit designation and by service location rather than by facility ('Cheyenne Mountain', 'Site R', 'Mount Weather', '341st Strategic Missile Wing', 'Ent AFB'). The searchable fields include unit of service and service locations, which is unusual and valuable.

**Rate limits.** Same as loc.gov collections API — throttled; back off on 429.

**Robots / ToS posture.** Public federal collection; same loc.gov rate-limit posture applies.

**Notes.** Serious limitation: most interviews are audio/video with NO transcript, so they are not full-text searchable. The metadata is searchable, the content is not. Any systematic mining requires running ASR over the audio, which is technically feasible but a large separate project. Privacy/consent: these are donated personal collections; treat quotation carefully.

---

### 5.23 · missilebases.com / 20th Century Castles (Ed and Dianna Peden)

`HIGH` · tier **P4** · <https://www.missilebases.com/>

*Serves:* condition · construction · ownership/disposal · location

**Holdings.** A missile-base and communications-bunker real estate brokerage active since the 1990s: has physically explored 90+ underground sites and sold 59. Listings historically carried as-built drawings, shaft and level dimensions, blast-door specifications, depth, water and power status, current condition, acreage, and the GSA disposal history of each parcel.

**Access method.** Free web listings; archived listings via Wayback

**Format returned.** HTML listings, scanned drawings, photographs

**Search technique.** An unusual P4 source holding genuinely primary data, because a broker must document a property to sell it and had lawful physical access. Harvest current listings AND the Wayback Machine's full history of the listings pages — sold properties are removed from the live site, so the historical snapshots are where most of the corpus lives. Use the CDX API against missilebases.com/*, dedupe by digest, and extract each vintage listing. Cross-reference the disposal narratives against GSA and federal property disposal records for independent confirmation. Related: Larry Hall's Survival Condo (Atlas F silo in Kansas, purchased 2008, second facility since) is publicly documented in extensive press coverage that includes engineering detail.

**Rate limits.** Self-limit.

**Robots / ToS posture.** Commercial site; check robots.txt. Wayback snapshots are the safer harvest path.

**Notes.** Grading note: condition and dimensional data from a seller is subject to obvious commercial bias (silos are marketed as more intact and more impressive than they are). Treat physical descriptions as P4 claims requiring corroboration, but treat the *existence and disposal* data as strong — a broker had to establish clear title, so the ownership chain is usually real and checkable against county recorder records.

---

### 5.24 · Nevada Test Site Oral History Project (UNLV)

`HIGH` · tier **P1** · <https://special.library.unlv.edu/ntsohp/>

*Serves:* construction · function · personnel · chronology · condition

**Holdings.** 150–200+ full interviews, ~335 hours, with complete typed transcripts, plus supporting documents and photographs. Interviewees include tunnel miners, REECo and EG&G workers, health physicists, security personnel, and test directors — i.e. the people who actually dug and instrumented underground facilities.

**Access method.** Free web access; also surfaced through CONTENTdm (nvlibrarycoop.contentdm.oclc.org)

**Format returned.** PDF transcripts (text layer), audio/video, images

**Search technique.** Unlike VHP, this project transcribed everything — so it IS full-text searchable, which makes it the reference example of what a usable oral-history corpus looks like. Search the transcripts for tunneling and containment vocabulary: 'drift', 'muck', 'stemming', 'alcove', 'button-up', 'containment vessel', 'P-Tunnel', 'N-Tunnel', 'Area 12', 'gas seal door', 'Mighty Epic', 'Diablo Hawk'. Miners describe methods and dimensions that never appear in a published report. The CONTENTdm route gives you the JSON API (/digital/api/search/collection/<alias>/...) for bulk retrieval where the bespoke UNLV interface does not.

**Rate limits.** Unpublished; low volume corpus, one-time harvest.

**Robots / ToS posture.** Open academic project, National Council on Public History award-winning; explicitly built for researchers.

**Notes.** Model source. Where you find an equivalent (Hanford History Project at WSU Tri-Cities, Atomic Heritage/'Voices of the Manhattan Project' at ahf.nuclearmuseum.org, Rocky Flats Cold War Museum oral histories, Sandia and LANL institutional oral histories), treat it the same way. The DOE Human Radiation Experiments oral histories are a further parallel corpus.

---

### 5.25 · Pure aggregator nodes: bibliotecapleyades.net, whale.to, subterraneanbases.com, beforeitsnews

`HIGH` · tier **P5** · <https://www.bibliotecapleyades.net/>

*Serves:* claim-origin · citation-topology

**Holdings.** Biblioteca Pleyades is the largest single mirror of the underground-base corpus, hosting near-complete reproductions of Branton, Sauder excerpts, the Castello material, Commander X, and hundreds of forum posts, in both English and Spanish, generally with degraded or absent attribution. whale.to hosts a comparable 'DUMB' compendium. subterraneanbases.com and the BeforeItsNews/AllConspiracy/USAHitman tier are second- and third-generation copies of the copies.

**Access method.** Free, static HTML, trivially crawlable

**Format returned.** Static HTML, mostly hand-authored, stable URLs

**Search technique.** These have negative evidential value but very high *diagnostic* value: they are the reference corpus for detecting copies. Mirror them once, normalize the text (strip markup, collapse whitespace, lowercase), and build a shingle/MinHash index. Then any newly encountered page can be scored for overlap against the aggregator corpus, and near-duplicates auto-classified as copies rather than sources. Biblioteca Pleyades URL grammar is regular and enumerable (/sociopolitica/esp_sociopol_underground<NN>.htm, /offlimits/offlimits_dulce<NN>.htm), which makes complete section mirroring straightforward. This is the concrete mechanism for the project's '400 sources, one source' rule.

**Rate limits.** None enforced; self-limit to ~1 req/sec.

**Robots / ToS posture.** Unmaintained personal sites; generally no robots.txt. Crawl slowly out of courtesy — these are hobbyist hosts.

**Notes.** Do not spend analytic time reading these. Their only function in the pipeline is as a deduplication reference set and as a source of the *earliest URL* for a claim, which you then push back further with the Wayback CDX API.

---

### 5.26 · Subterranea Britannica — the methodological model

`HIGH` · tier **P3** · <https://www.subbrit.org.uk/>

*Serves:* condition · construction · function · chronology · location

**Holdings.** Founded 1974; a per-site register of UK underground structures (nuclear bunkers, ROC posts, deep shelters, Cold War command sites) with survey notes, plans, photographs, and a documented history for each. The Sub Brit Collection (collection.subbrit.org.uk) is a purchased-and-preserved archive of nine filing cabinets of papers, plans and photographs formerly at RAF Holmpton, progressively indexed and scanned. The society's journal, Subterranea, has a digitized run on Internet Archive. Now also lists sites in Europe and the United States.

**Access method.** Free web; journal PDFs on Internet Archive

**Format returned.** HTML site records, PDFs, scanned plans and photographs

**Search technique.** The reason to register a UK-focused body in a US-first project: Sub Brit is the closest existing thing to what this project is trying to be, and its site-record schema is worth studying directly — each record separates documented history, survey observation, and current condition, with named sources. Harvest subbrit.org.uk/sites/ (stable per-site URLs under category paths like /categories/nuclear-bunkers/) as a schema reference and for its growing US section. The journal run on IA (identifiers of the form subterranea-<N>) is full-text and contains methodology articles on records research, plus obituaries and site reports. Nick Catford's site reports are the reference standard for the genre.

**Rate limits.** Self-limit.

**Robots / ToS posture.** Membership society, publicly readable. Crawl politely.

**Notes.** Also demonstrates the succession/archive-purchase problem in a positive light: when the private archive that underpins a research community came up for disposal, the society bought it. Worth noting as a precedent for what happens to US enthusiast archives (Thelen, Campbell) when their keepers die.

---

### 5.27 · The 1980s–90s conspiracy-publishing origin cluster: Lear, Cooper, Valerian, Beckley

`HIGH` · tier **P5** · <https://archive.org/details/beholdapalehorse>

*Serves:* claim-origin · chronology

**Holdings.** John Lear's 1987 'Lear Statement', posted to the ParaNet BBS network — the first widely circulated synthesis asserting joint government-alien underground facilities. Milton William Cooper, 'Behold a Pale Horse' (Light Technology, 1991) — the single most influential aggregation text in the entire American conspiracy corpus, which copies Lear, the 'Krill Papers' (1988), and 'Silent Weapons for Quiet Wars' largely without attribution. Valdamar Valerian (John Grace), 'Matrix' I–V — enormous late-80s/early-90s compendia that hoovered up and reprinted the BBS-era corpus. 'Commander X', 'Underground Alien Bases' (1990), published by Timothy Green Beckley's Abelard/Inner Light imprints — a known fabrication mill.

**Access method.** Free full text on Internet Archive and mirror sites; original BBS-era files on textfiles.com

**Format returned.** Scanned books with OCR, plain-text BBS files

**Search technique.** The essential structural insight: Cooper and Valerian are AGGREGATORS, not origins, and the ecosystem systematically miscites them as origins. Any claim traced to 'Behold a Pale Horse' has at least one further hop. Textfiles.com (textfiles.com/ufo/, /conspiracy/, /occult/) preserves the pre-web BBS file corpus with original file dates, which is the only way to date claims in the 1985–1993 window — this is the layer beneath the books. Combine: find the claim in Cooper (1991), find the same text in a textfiles.com file dated 1988, find the same text in a Usenet post dated 1987, and you have the actual origin. Beckley's imprints (Inner Light, Global Communications, Abelard) should be treated as a publisher-level red flag: material originating there is P5 by provenance regardless of content.

**Rate limits.** textfiles.com is small and static; a full mirror is trivial and appropriate.

**Robots / ToS posture.** textfiles.com is explicitly an open preservation archive. Mirror sites are unmaintained.

**Notes.** ParaNet (Jim Speiser, from 1986) and CUFON (Computer UFO Network, Seattle, Dale Goudie) were the two BBS distribution hubs. Their file archives, where preserved, carry upload dates that predate any web record and are the earliest datable layer of this corpus.

---

### 5.28 · The Black Vault (John Greenewald) and governmentattic.org — FOIA document hosts

`HIGH` · tier **P1** · <https://www.theblackvault.com/documentarchive/>

*Serves:* function · construction · chronology · claim-origin

**Holdings.** The Black Vault: a very large archive of FOIA-released documents obtained by Greenewald over three decades, organized by agency and topic, including an AFHRA document collection and extensive DoD/CIA/FBI material; also runs 'Case Files' pages that adjudicate specific fringe claims (including a determination that the Castello Dulce photograph is a hoax). governmentattic.org: an eclectic FOIA archive organized into ~11 agency categories, with two sections — FOIA Logs and Documents — including thousands of released documents plus agencies' own FOIA request logs.

**Access method.** Free public download

**Format returned.** PDF (variable OCR quality)

**Search technique.** Both are P1 *documents* wrapped in P3/P4 presentation — grade the document, not the host. governmentattic's URL grammar is regular and enumerable: governmentattic.org/<N>docs/<FILENAME>.pdf where N increments across directory generations; the index pages list them with a description block. Crawl the index pages rather than guessing filenames. The FOIA Logs section is the strategically interesting part and is badly under-exploited: a FOIA log tells you what OTHER people have already requested from an agency, with descriptions — so an agency's FOIA log is effectively a map of what documents exist and what has already been released, letting you request a known-releasable document by its prior request description rather than fishing. Search logs for 'underground', 'relocation facility', 'continuity of government', 'hardened', 'bunker', plus facility names. MuckRock (muckrock.com) is the third leg: it hosts filed requests, agency responses, and released documents with a public API, and lets you file new requests programmatically.

**Rate limits.** Unpublished; self-limit.

**Robots / ToS posture.** Both are public archives intended for reading. The Black Vault is ad-supported; crawl slowly. governmentattic is static and small.

**Notes.** Greenewald's editorial posture is 'release the documents and let people decide', which means the archive contains both solid material and documents that fringe readers over-interpret. His Case Files work is genuinely useful debunking and is one of the few instances of a P4-adjacent community member doing rigorous backward tracing — exactly the track-record signal this beat was asked to identify.

---

### 5.29 · The FEMA-camps / COG-detention corpus and its tracers

`HIGH` · tier **P5** · <https://www.splcenter.org/resources/reports/fear-fema/>

*Serves:* claim-origin · chronology · function

**Holdings.** A well-documented, unusually traceable claim lineage: a 1982 Posse Comitatus newsletter warning that 'hardcore Patriots' would be imprisoned in FEMA detention camps (predating the usual origin story); Alfonso Chardy's Miami Herald report of 5 July 1987 disclosing Readiness Exercise 1984 (Rex 84) and the associated North/NSC continuity planning, which supplied the real documentary kernel; Liberty Lobby's The Spotlight (1975–2001) and 1990s militia newsletters carrying the '800 camps' list; Alex Jones's 1990s videos ('America Destroyed by Design', 'Police State' series) providing the video-era amplification; the 2009 resurgence keyed to H.R. 645 (National Emergency Centers Establishment Act, a real introduced bill); and the 2024 hurricane-response wave.

**Access method.** Mixed: SPLC 'Fear of FEMA' report free; Miami Herald 1987 via library databases; The Spotlight via microfilm and scattered scans; militia-era newsletters via IA and university extremism collections

**Format returned.** HTML, microfilm, scanned newsletters, video

**Search technique.** Tracers to use as the P2/P3 backbone: SPLC's 'Fear of FEMA' report; the 2017 'We Are the Mutants' piece 'Look It Up, Check It Out: REX 84 and the History of an American Conspiracy', which is the best single published reconstruction of the lineage; PolitiFact's 2024 retrospective. Fingerprint strings: 'REX 84', 'Rex-84 Bravo', 'Garden Plot', 'Cable Splicer', '800 detention camps', 'Executive Order 11490', 'H.R. 645'. Note carefully which parts are real: Rex 84 was a real exercise, Garden Plot and Cable Splicer were real contingency plans, Executive Order 11490 was a real EO, and H.R. 645 was a real bill. The fabrication is the camp *list* and the operational claims layered on top. This is a case where the register must be surgical rather than dismissive — the underlying documents exist and belong in the register at P1; the derived claims do not. MuckRock hosts FOIA requests specifically for Rex 84 materials.

**Rate limits.** N/A.

**Robots / ToS posture.** SPLC and PolitiFact permit reading; the militia-era primary material is largely in institutional collections.

**Notes.** Directly relevant to this project because the '800 camps' list is a *facility list* — it names real places (armories, disused bases, federal prisons, fairgrounds) and asserts a function they do not have. That is the exact failure mode the register exists to correct: correct location, fabricated function. Ingest the list, grade every entry, and show the work.

---

### 5.30 · The Portal to Texas History / Gateway to Oklahoma History (UNT stack)

`HIGH` · tier **P1** · <https://texashistory.unt.edu/api/>

*Serves:* chronology · location · construction · land acquisition · personnel

**Holdings.** Texas newspapers (including small-county weeklies that no commercial vendor bothered with), county histories, government documents, photographs, and yearbooks. Sister deployment: The Gateway to Oklahoma History (gateway.okhistory.org) runs identical software. Directly relevant coverage: Amarillo/Pantex, Abilene/Dyess, the Texas Atlas F fields, Fort Worth District USACE projects.

**Access method.** OAI-PMH + IIIF + documented public API, no key

**Format returned.** OAI-DC and UNTL XML, IIIF Presentation JSON manifests, OCR text, page images

**Search technique.** OAI base: https://texashistory.unt.edu/oai/ with ?verb=Identify, ?verb=ListSets (sets are partner- and collection-scoped — harvest ListSets first to find the newspaper sets), ?verb=ListRecords&metadataPrefix=untl (the native untl format carries far richer fields than oai_dc, including coverage-place and coverage-date). Append /manifest to any item URL for the IIIF JSON. Per-collection and per-partner API docs exist at /explore/collections/<CODE>/api/ and /explore/partners/<CODE>/api/. Search UI params (?q=&t=fulltext&fq=untl_decade%3A1960-1969) are stable enough to scrape.

**Rate limits.** Not published. OAI resumption tokens throttle you naturally; be polite.

**Robots / ToS posture.** Explicitly invites programmatic use; 'You do not need to apply for a special key to use these APIs.'

**Notes.** The UNT model (documented OAI + IIIF + no key) is the exception, not the rule. Where a state library has this, use it and skip the HTML scraping entirely.

---

### 5.31 · USACE Digital Library, district history offices, and cultural-resources inventories

`HIGH` · tier **P1** · <https://usace.contentdm.oclc.org/digital/>

*Serves:* construction · land acquisition · chronology · function · condition

**Holdings.** Corps of Engineers district histories (e.g. 'Rivers, Rockets and Readiness: Army Engineers in the Sunbelt — Fort Worth District 1950–1975'), construction completion reports, real-estate acquisition narratives, and — critically — Cold War-era cultural resources inventories produced under Section 110/106 and the DoD Legacy Resource Management Program. Also USACE HQ Office of History: personal papers, oral histories, manuscripts. District cultural-resources pages (nwo, nan, nwp and others) post PDFs directly.

**Access method.** CONTENTdm web UI + CONTENTdm API; direct PDF links on district .mil sites

**Format returned.** PDF (often OCR'd), CONTENTdm JSON

**Search technique.** CONTENTdm exposes a JSON API at /digital/api/search/collection/<alias>/searchterm/<term>/... and /digital/api/collections/<alias>/items/<id>/false. Query the district histories for the construction years of a candidate site and read the narrative — Corps district histories habitually name projects the Air Force never acknowledged, because the Corps was proud of the engineering. Separately, the DoD Legacy Program and the service-level Cold War inventories of the early 1990s (mandated by the 1991 Defense Appropriations Act) produced facility-by-facility surveys with photographs, drawings, and significance evaluations — search 'Cold War historic properties inventory', 'Cold War material culture', 'Legacy Resource Management Program' plus a base name. npshistory.com mirrors many of these PDFs and is far more scrapable than the .mil hosts.

**Rate limits.** Unpublished. .mil hosts will rate-limit or block silently.

**Robots / ToS posture.** .mil hosts are inconsistent; several block non-browser user agents entirely and some return 403 to datacenter IPs. npshistory.com and tDAR mirrors are the practical path.

**Notes.** tDAR (core.tdar.org) has a USACE collection with archaeological/cultural-resource grey literature; much of it is metadata-only with the report behind a request wall. Note also that Corps district records not published as histories are in NARA regional facilities as RG 77 — an entirely manual research path.

---

### 5.32 · Veridian-platform state newspaper collections (CDNC and siblings)

`HIGH` · tier **P1** · <https://cdnc.ucr.edu/>

*Serves:* chronology · location · construction · local reaction

**Holdings.** California Digital Newspaper Collection: 23M+ pages, 1846–present, with article-level segmentation (not just page-level) — meaning headlines, bylines, and article boundaries are structured, which is rare and valuable. Veridian also runs a large fraction of other state/consortium collections; the vendor lists 50M+ free pages across its hosted collections.

**Access method.** HTML scrape against a stable CGI query string; no documented public JSON API

**Format returned.** HTML, page JP2/PDF, article-segmented text

**Search technique.** Veridian's URL grammar is a Greenstone descendant and is undocumented but stable and fully GET-addressable, which makes it scrapable without a headless browser. The canonical shape is ?a=q&hs=1&r=1&results=1&txq=<terms>&txf=txIN&ssnip=txt&dafdq=&dafmq=&dafyq=<startyear>&datdq=&datmq=&datyq=<endyear>&puq=<paper-code>&e=-------en--20--1--txt-txIN--------. Key params: a=q (query), a=d (document view), a=cl (collection list), txq (full-text query), puq (publication filter), dafyq/datyq (year bounds), ssnip=txt (return text snippets). Phrase search with double quotes and AND/OR/NOT are supported. a=cl&cl=CL1 enumerates the collection/title tree — start there to build your title inventory. Because CDNC runs past 1963, it is one of the few free full-text corpora covering the 1960s–70s hardened-construction and civil-defense-decommissioning era.

**Rate limits.** Undocumented. Treat as ~1 req/sec with backoff.

**Robots / ToS posture.** Check cdnc.ucr.edu/robots.txt per-host; UC Riverside has historically been tolerant of slow, identified crawling. Veridian-hosted commercial instances are less so.

**Notes.** Non-ONI state programs worth separate harvesters because each has its own stack: Utah Digital Newspapers (digitalnewspapers.org, Solr-backed, has a JSON endpoint), Hoosier State Chronicles (Indiana, chronam-derived), Colorado Historic Newspapers (coloradohistoricnewspapers.org, Veridian), Virginia Chronicle (virginiachronicle.com, Veridian), Washington Digital Newspapers, Arizona Memory Project, Illinois Digital Newspaper Collections (Veridian), Nevada, New Mexico, Wyoming Newspapers (wyomingnewspapers.org, Veridian). Wyoming, Nevada, New Mexico, Colorado and Utah matter disproportionately for this project — that is where the missile fields, the test sites, and the withdrawn land are.

---

### 5.33 · Enthusiast and crowd mapping layers: Wikimapia, OpenStreetMap, and legacy Google Earth Community KMZ

`MODERATE` · tier **P4** · <http://wikimapia.org/api/>

*Serves:* location · function · condition

**Holdings.** Wikimapia: user-annotated polygons over satellite imagery with category tagging, historically the densest crowd-sourced layer for military installations worldwide, including many annotated by local residents who simply know what a place is. OpenStreetMap: military=bunker, military=* landuse, and man_made=* tagging, with full history and changeset attribution. Google Earth Community (defunct): the 2004–2010 forum whose 'Military' folders produced thousands of KMZ placemark files, many of which survive only as orphaned KMZ downloads and Wayback captures.

**Access method.** Wikimapia: keyed REST API. OSM: Overpass API, planet dumps, full history files. GEC: dead, Wayback only

**Format returned.** JSON, KML, OSM XML/PBF, KMZ

**Search technique.** Wikimapia: create a key at wikimapia.org/api/?action=create_key, then the Box function against api.wikimapia.org returns places within a bounding box, filterable by category, max 100 places per page with pagination; JSON default, KML available; free tier is ~100 requests per 5 minutes per domain. Sweep candidate regions by bounding box with the military category filter. OSM: use Overpass QL rather than planet dumps for targeted work — e.g. a bbox query for nwr["military"="bunker"] or nwr["military"] — and critically, use the OSM full-history planet or the changeset API to see WHO added a feature and WHEN, plus their changeset comment, which occasionally cites a source. OSM's attribution trail is the best of any crowd layer. For GEC: search the Wayback Machine for bbs.keyhole.com and the Google Earth Community forum paths, and look for surviving KMZ mirrors — this is a decaying corpus worth capturing before it is entirely gone.

**Rate limits.** Wikimapia ~100 req/5min per domain, free tier. Overpass public instances: rate-limited by slot; run your own instance for heavy work.

**Robots / ToS posture.** Wikimapia requires a key and enforces rate limits. OSM data is ODbL-licensed and explicitly open for bulk use with attribution; the Overpass public instances ask for reasonable use.

**Notes.** Crowd layers are P4 by construction — an annotation is an assertion by an anonymous person — but they are unusually valuable for *discovery*: they surface candidate sites nobody has written about. Treat a Wikimapia or OSM military annotation as a lead requiring independent documentary confirmation, never as a source. OSM's licence (ODbL) has share-alike implications if you merge its geometry into a published database; check before ingesting geometry rather than just using it as a pointer.

---

### 5.34 · Forum aggregation nodes: AboveTopSecret and Godlike Productions

`MODERATE` · tier **P5** · <https://www.abovetopsecret.com/>

*Serves:* claim-origin · citation-topology · chronology

**Holdings.** ATS: founded 1997 by Simon Gray, forum-based from 2001, with a very large corpus of underground-base threads (thread IDs in the 300k–1.3M range span roughly 2004–2015) accumulating claims, photographs, map coordinates and speculation. GLP is the higher-volume, lower-signal equivalent. Both are primarily downstream — topics were routinely lifted from Infowars, GLP, and each other.

**Access method.** Free public read; stable thread URLs

**Format returned.** HTML threads with per-post timestamps

**Search technique.** Value is in the per-post timestamps, which make these forums usable as a dating layer for the 2001–2015 window where the Wayback Machine is patchy on forum content. ATS thread URLs are enumerable: abovetopsecret.com/forum/thread<ID>/pg<N>. Rather than reading, harvest thread metadata (title, first-post date, post count) and first-post text across the ID space, and index it for first-occurrence matching against the claim corpus. Genuine occasional value: local members sometimes post first-hand observation (a construction convoy, a fence line, a photograph) that is real primary observation buried in a P5 context — searchable via geographic terms plus 'I live near', 'I drove past', 'my father worked at'. Grade the observation, not the thread.

**Rate limits.** Unpublished. Be conservative.

**Robots / ToS posture.** Check robots.txt; ATS has had periods of aggressive anti-scraping. Site ownership and platform have changed over the years and older content has been lost in migrations.

**Notes.** Link rot is severe and worsening across this whole tier. Many threads cited by later material are already dead, surviving only in Wayback. Prioritize capture over analysis.

---

### 5.35 · Labor archives and building-trades periodicals

`MODERATE` · tier **P2** · <https://reuther.wayne.edu/>

*Serves:* construction · personnel · chronology · contractor · condition

**Holdings.** Walter P. Reuther Library (Wayne State) — UAW, AFL-CIO industrial union records; Kheel Center (Cornell ILR) — building trades, ILGWU, and union periodicals; George Meany AFL-CIO Archive (now at University of Maryland Special Collections) — federation-level records including wartime and defense construction. Union periodicals: The Operating Engineer (IUOE), The Ironworker, IBEW Journal, The Laborer, and district council newsletters, which routinely profiled members' work on large federal projects.

**Access method.** Finding aids online (ArchivesSpace/EAD); most content on paper, in-person or paid reproduction; some periodical runs digitized in HathiTrust/IA

**Format returned.** EAD XML finding aids; paper collections; scattered digitized serials

**Search technique.** The insight: workers who built classified facilities were unionized, and their locals published about it — often before, and in more physical detail than, any press account. Search finding aids (most of these repositories expose ArchivesSpace with an OAI-PMH or /search endpoint) for local numbers near a candidate site plus date range, and for 'jurisdictional dispute' records, which name the contractor, the project, the trades involved, and often the site. Grievance and dispatch records give crew sizes and durations — a proxy for facility scale. In digitized periodical runs, search 'defense project', 'government job', 'the Nevada job', 'tunnel work', 'shaft sinking', plus local numbers. Also: NLRB case records name employer, worksite, and unit descriptions, and are searchable at nlrb.gov by employer name.

**Rate limits.** N/A for finding aids.

**Robots / ToS posture.** Finding aids are open. Digitized content is limited and rights-encumbered.

**Notes.** Honest assessment: this is low-yield-per-hour but occasionally uniquely decisive, because it is the only source class where people who were physically inside the hole describe it without a clearance obligation. Treat as targeted follow-up on a specific candidate, not a sweep. Most material requires a visit or a paid reproduction request.

---

### 5.36 · NewsBank 'America's News' / Access World News

`MODERATE` · tier **P1** · <https://www.newsbank.com/>

*Serves:* chronology · local reaction · ownership/disposal · land acquisition

**Holdings.** 4,000+ US news sources, heavily weighted to 1980s–present local dailies — precisely the window Chronicling America does not cover and precisely where county-level reporting on federal land use, lease renewals, and base closures lives.

**Access method.** Subscription; remote access via public library card in most US states

**Format returned.** HTML full text (rarely page images)

**Search technique.** Boolean with proximity (w/n). Pair a county name with 'special use permit', 'federal lease', 'General Services Administration', 'excess property', 'environmental assessment', 'Base Realignment'. Best used as a targeted lookup tool once a candidate site is already identified, not as a discovery sweep.

**Rate limits.** N/A — automated access is contractually forbidden.

**Robots / ToS posture.** HOSTILE. Terms explicitly prohibit downloading data for text-mining applications and the use of scripts or web-scraping software, and prohibit machine-assisted indexing of the content. Do not harvest.

**Notes.** Register this as a manual-verification source only. A human with a library card may read and cite an article; the pipeline must not ingest it. Same posture applies to ProQuest and Gale historical newspaper databases.

---

### 5.37 · Newspapers.com (Ancestry) and GenealogyBank (NewsBank)

`MODERATE` · tier **P1** · <https://www.newspapers.com/>

*Serves:* chronology · personnel · local reaction

**Holdings.** Newspapers.com: 11,000+ titles, mostly US/Canada. GenealogyBank: 13,000+ titles across all 50 states, 1690–present, with obituary-only coverage for many recent decades. Both hold small-town papers that no public program digitized.

**Access method.** Paywalled subscription

**Format returned.** Page images + OCR, clipping objects

**Search technique.** Newspapers.com 'Clippings' are public-facing and indexed by search engines even when the underlying page is paywalled — site:newspapers.com/clip/ <query> in a general web search will surface user-clipped articles about a facility, including the paper name and date, which you can then verify elsewhere for free. That is the only lawful free extraction path. GenealogyBank's obituary coverage is the practical route to obituaries citing classified assignments.

**Rate limits.** N/A.

**Robots / ToS posture.** Paywalled, ToS prohibits scraping.

**Notes.** Value here is citation *leads*, not content. Use clipping metadata to identify the paper+date, then check whether a free state program has the same issue.

---

### 5.38 · State historical societies, county historical societies, and state library digitization programs

`MODERATE` · tier **P2** · <https://www.statearchivists.org/>

*Serves:* local reaction · construction · personnel · chronology · land acquisition

**Holdings.** County-level manuscript collections, local government records transferred to state archives, photograph collections, subject vertical files, and local oral history programs. Vertical files in particular — the clipping folders that a county library or historical society kept on 'Air Force Base', 'Civil Defense', 'Federal Government' — are frequently the only surviving index to local coverage of a facility.

**Access method.** Highly variable: some ArchivesSpace/CONTENTdm/PastPerfect Online; many catalog-only; many require phone or mail inquiry

**Format returned.** EAD finding aids, CONTENTdm JSON where present, PastPerfect Online HTML, paper

**Search technique.** Three machine-accessible layers worth building against: (1) state archives running ArchivesSpace expose /oai and a JSON search API — harvest EAD and grep collection scope notes for 'civil defense', 'fallout shelter', 'relocation', 'Air Force', 'Corps of Engineers'; (2) DPLA (dp.la) aggregates a large fraction of state hub metadata behind a single documented JSON API with a free key — this is by far the most efficient way to search across hundreds of small institutions at once, though it only searches metadata, not content; (3) PastPerfect Online installations (thousands of small societies) share a URL grammar under /00001.htm-style object pages with a searchdb.asp query interface, crudely scrapable. Beyond that: phone calls. Many county societies have no web presence and hold the only copy of the local weekly for the years in question.

**Rate limits.** Assume fragile.

**Robots / ToS posture.** Small institutions, small servers. Identify yourself. Several explicitly ask researchers to contact them rather than crawl.

**Notes.** This is the honest weak point of the vernacular half. The material is real and often decisive, but it is not machine-accessible at scale and never will be. Budget it as human research on specific high-value candidates. DPLA is the one genuine leverage point.

---

### 5.39 · Urban exploration communities: UER.ca, 28dayslater, Opacity, and the video tier

`MODERATE` · tier **P4** · <https://www.uer.ca/>

*Serves:* condition · location · function

**Holdings.** UER (Urban Exploration Resource, US/Canada focus): a location database opened 30 July 2003 with 10,000+ locations in dozens of countries and 3M+ forum posts, containing interior photographs, access notes, and condition reports for abandoned military and government sites. 28dayslater.co.uk is the UK-centred equivalent with substantial Cold War bunker coverage. Opacity (Tom Kirsch) is a high-quality single-author photographic archive. On video, The Proper People are the most methodical documentarians in the space; a large second tier (Exploring With Josh, Steve Ronin and similar) produces volume with little verification.

**Access method.** Free registration for forums; location database access is tiered and gated by contribution/reputation; some locations restricted or coordinates withheld

**Format returned.** HTML, photographs, video

**Search technique.** The community's governing norm is deliberate location secrecy — exact coordinates are frequently withheld or shared only privately, and posting them publicly is a serious breach. Plan accordingly: this is a source for *condition and interior evidence*, not for coordinates, and attempting to extract coordinates will get you banned and is contrary to the community's stated ethics. UER's public layer (uer.ca/locations/newlist.asp?country=United+States, /locations/search.asp, /locations/gmaps/) is browsable; the gated layer is not, and should not be circumvented. For video: photographs and footage of interiors are genuinely probative for function and condition (blast door hardware, filtration equipment, communications racks, government property tags and stencilled unit designations visible in frame are all identifiable evidence), so the right treatment is frame-level evidence extraction from publicly posted material, cited to the uploader and date. Archiveteam has a UER project page, indicating past preservation concern about the site's survival.

**Rate limits.** N/A — manual use.

**Robots / ToS posture.** UER is a private community with explicit content and access rules. Respect the gating; do not scrape the location database. Treat public forum threads as readable-but-cite-carefully.

**Notes.** Ethical and legal note the register should carry: much urbex documentation involves trespass, and republishing precise locations for intact or hazardous sites creates real-world risk. Recommend the register cite urbex material as evidence of condition while declining to import location precision from it, and prefer independently derived coordinates.

---

### 5.40 · Veterans Legacy Memorial, Nationwide Gravesite Locator, and commercial obituary archives

`MODERATE` · tier **P2** · <https://www.vlm.cem.va.gov/>

*Serves:* personnel · chronology · function

**Holdings.** VLM: a free VA-run memorial page for every veteran interred in a VA national cemetery and, increasingly, state and private cemeteries — with branch, rank, service dates, conflicts, and a family-contributed tribute area. Nationwide Gravesite Locator: interment records. Legacy.com: the syndication layer for most US newspaper obituaries since ~2000. Find a Grave: user-contributed, with transcribed obituaries.

**Access method.** VLM/NGL: free public web, no documented API. Legacy.com and Find a Grave: free to read, ToS-restricted

**Format returned.** HTML

**Search technique.** The target pattern is an obituary sentence of the form '...served with the 44th Strategic Missile Wing at Ellsworth Air Force Base' or '...worked for thirty years at a job he could never discuss'. These are findable through general web search with site: restrictions plus unit designations and the phrases 'could not talk about', 'classified assignment', 'top secret clearance', 'missile combat crew', 'launch control'. VLM is the only one of these that is unambiguously free, public, and non-hostile. Prefer AAFM 'Taps' and veteran-association newsletters over commercial obituary sites wherever the person served in a missile or air-defense unit — same information, harvestable, no ToS problem.

**Rate limits.** N/A.

**Robots / ToS posture.** Legacy.com and Find a Grave (Ancestry) both prohibit scraping and actively block it. VLM/NGL are federal public sites but publish no API.

**Notes.** Serious ethical constraint independent of ToS: these are recently deceased private individuals and their surviving families. An obituary is legitimate evidence about a facility's existence and function; it is not licence to build a personnel database. Recommend the register cite obituaries as evidence and store the citation, not a person-level index. Living-person material should be out of scope entirely.

---

## Gaps for this beat — the expected-record raw material

*Every statement here becomes, or should become, a row in `registry.erp_profile`. A record
class that does not exist for a given authority, era or classification posture is **X0** and
produces **no row** — not a zero. This is what licenses the argument from silence in one case
and forbids it in another.*

WHAT THIS BEAT CANNOT TELL US.

1. The construction era of local government is simply not online. Municipal and county agenda/minutes platforms — Legistar, CivicPlus, BoardDocs, PrimeGov, CivicClerk — have a hard digital floor somewhere around the mid-2000s, with a thin tail to the late 1990s. Every hardened facility of interest was sited, permitted, and connected to utilities between roughly 1950 and 1975. The zoning variances, road vacations, easement grants, water-line extensions and condemnation actions from that period exist as paper minute books and microfilm in county clerks' and recorders' offices and nowhere else. There is no API, no aggregator, and no realistic bulk path. Closing this requires either targeted mail/phone requests to specific county clerks for specific date ranges, or physical visits. Recommend treating it as a per-candidate escalation triggered by a promising lead, with a standard request template citing the state's public records act, rather than as a harvest.

2. County historical societies are effectively invisible to machines. Thousands of them hold the only surviving vertical files, local photograph collections, and unpublished memoirs relevant to specific sites, and the great majority have no catalog, no finding aid, and often no website. DPLA aggregates some state-hub metadata and is the one real leverage point, but it searches metadata only, never content. There is no fix short of human outreach. What would help most: a prioritized contact list, built by taking the county set that intersects known and candidate facilities and resolving each to its historical society, library local-history room, and county archivist — a bounded, mechanical task that would materially improve reachability.

3. Oral history is largely unsearchable because it was never transcribed. The Library of Congress Veterans History Project has 100,000+ collections with rich unit and service-location metadata and mostly audio/video content with no transcript. The metadata is searchable; the testimony is not. The Nevada Test Site Oral History Project shows what the transcribed case looks like and is the exception. Closing this is technically straightforward and organizationally large: run ASR over the relevant subset of VHP audio, filtered by unit and service location to the few thousand collections that plausibly touch hardened facilities, and index the output. That is a discrete, fundable sub-project and probably the highest-value single investment available in the vernacular half.

4. AFHRA is an index, not a corpus. The Air Force History Index covers ~550,000 documents but stops at 2001 accessions and indexes existence, not content — you cannot full-text search the documents through it. The Internet Archive microfilm scanning programme is incomplete, unpredictable in coverage, and inconsistently identified. Anything not yet scanned requires a research request to Maxwell AFB with an IRIS number, at weeks-to-months latency. Unit histories are probably the richest untapped documentary source for what a facility actually was, and they are gated behind this bottleneck. Worth a standing programme of requests targeting the specific units associated with priority candidates, rather than opportunistic lookups.

5. Post-1963 newspapers are largely paywalled. The free digitized corpus (Chronicling America and most NDNP partners) is bounded by copyright at roughly 1963 — which is exactly when hardened construction peaked and when deactivation, disposal, and local controversy began. A few state programmes run later (CDNC to the present, some partner sites under local rights agreements) and those are disproportionately valuable. Otherwise the 1963–2000 local record sits inside NewsBank, Newspapers.com and GenealogyBank, all of which contractually forbid harvesting. This is a permanent structural gap, not a solvable one. Mitigations: prioritize the state programmes that run past 1963; use Newspapers.com public Clippings as a free citation-discovery layer; and accept that the 1963–2000 window will be covered by human lookups rather than by the pipeline.

6. The fringe video layer is unindexed and undatable. YouTube hosts the largest current volume of underground-base and urbex content, and it is the worst-behaved evidential substrate in the whole beat: no reliable transcript archive, no edit history, uploads that silently replace or re-cut earlier versions, mass deletion on channel termination, and terms that prohibit systematic downloading. A claim that 'first appeared in a 2019 video' generally cannot be verified as first-appearing there, because the pre-2019 video record is not preserved. Auto-captions provide partial searchability through third-party interfaces but are unreliable and not archival. Recommend the register treat video as citable evidence of condition and appearance (frame-level: blast door hardware, filtration plant, equipment racks, stencilled unit designations, property tags) while declining to use it for claim-dating at all.

7. Forum link rot has already destroyed a large part of the citation trail. AboveTopSecret, Godlike Productions and the wider forum tier have gone through platform migrations, ownership changes and mass content loss; a substantial share of the threads cited by surviving fringe literature are dead, recoverable only from partial Wayback captures. The 2001–2015 window — precisely when most current underground-base claims consolidated — is the worst-preserved period. Any origin-tracing that terminates at a dead forum URL is unresolvable, and there will be many. Budget for a meaningful proportion of claims to be gradeable only as 'first observed at date X in a copy' with the true origin lost.

8. The pre-web layer is thin and lossy. UTZOO covers February 1981 to June 1991 and its alt.* coverage is limited; the BBS-era file corpus survives only where a hobbyist happened to save it and textfiles.com is not comprehensive; ParaNet and CUFON file archives are fragmentary. For claims that entered circulation between roughly 1985 and 1993 — the Dulce cluster, the Lear statement, the Krill papers — dating will often be approximate and argued from newsletter print dates rather than proven from a datestamped record. AFU's digitized newsletter runs are the best available substitute and should be prioritized for that reason.

9. Trade and engineering press is paywalled where it matters most. Engineering News-Record reported contemporaneously on large federal construction, including classified-adjacent projects, and has no free archive. The Military Engineer is partially free (1920–1930 on JSTOR) and otherwise institutional. Compressed Air Magazine, Western Construction News, Tunnels & Tunnelling and the mining trade press are scattered across HathiTrust in limited view. This material is unusually probative — trade press printed shaft depths, excavation volumes, ground conditions and contractor names that no other public source carries — and it is the most systematically inaccessible category in the beat. Institutional library access solves it for a human researcher and does nothing for the pipeline.

10. Labor records are real but expensive per unit of yield. Union local records, grievance files, dispatch records and NLRB proceedings can name the contractor, the trades, the crew size and the site for construction that was otherwise unacknowledged. Almost none of it is digitized; finding aids describe boxes, not contents; access means a visit or a paid reproduction request at a repository like the Reuther Library, the Kheel Center, or UMD's George Meany archive. Treat as a targeted last resort for high-value candidates where the documentary record is otherwise blocked.

11. Non-US coverage is essentially absent from this beat as scoped. The schema is meant to be country-agnostic from day one, and the fringe corpus is transnational — Biblioteca Pleyades operates in Spanish as much as English, and the underground-base template propagates into Spanish- and Portuguese-language ecosystems with its own origin nodes that I have not mapped. Subterranea Britannica is the one non-US body registered here, and only as a methodological model. If expansion is genuinely additive, the non-English fringe ecosystem needs its own beat; assuming it mirrors the English one will produce false origin attributions.

12. Two hypotheses in this registry are flagged and untested. First, that several later 'secret facility list' compilations derive from the appendices of Arkin & Fieldhouse, 'Nuclear Battlefields' (1985) with the sourcing stripped — this is a plausible and checkable citation-topology claim that I could not verify and that would be worth testing early, because if true it identifies a P2 origin sitting underneath a large body of P5 lists. Second, that Phil Schneider's 1,477/129 figures have no pre-1995 antecedent anywhere — asserted here on the absence of any earlier attribution, but not confirmed against Usenet or BBS records, which is exactly the check the claim-dating stack exists to perform. Both should be run as the first real exercises of the tracing pipeline, since they are bounded, falsifiable, and diagnostic of whether the pipeline works.


---

## APPENDIX A — BOOTSTRAP ORDER (W1/P1)

One work item per file, HTTP Range-resumable. This converts the majority of all future verification
into **local lookups**, which is what makes the verification tier affordable — and is why it precedes
discovery rather than following it.

1. `MapIndices_National_GPKG`
2. `historicaltopo.csv` → PostGIS with a GiST index on `geom_wkt` (186,061 sheets, ~185 MB)
3. `WESM.gpkg` (3DEP work-unit extent)
4. USMIN (mapped adits and shafts, 35 states)
5. MSHA `Mines.txt`
6. MRDS
7. `git clone HistoryAtState/frus` (structured TEI)
8. Federal Register bulk
9. FRPP annual CSV
10. USAspending monthly Postgres dump
11. FCC ULS / ASR bulk `.dat`

**Two clock-dependent items to file on day one, not on day thirty:**

- **EROS M2M access request** — 24–48 business-hour approval, and it gates *all* declassified imagery.
- **api.data.gov key registration** — SAM keys can take up to ten business days.

**Gate on P1:** resolve **100 known-good identifiers per corpus, offline**, before P2 begins. A corpus
that cannot resolve its own known-good identifiers has not been acquired; it has been downloaded.

---

## APPENDIX B — WHAT VERIFIES OFFLINE AFTER BOOTSTRAP

Sub-millisecond, zero network, 100% coverage. This is the leading cost fact of the whole design:

| Identifier class | Verified against |
|---|---|
| USGS quad name + scale + imprint year | local `historicaltopo` index (186,061 rows) |
| MSHA MINE_ID | local `Mines.txt` |
| FCC ASR number | local ULS/ASR bulk `.dat` |
| FPDS PIID | local USAspending monthly dump |
| FRUS volume + document | local `frus` TEI clone |
| Federal Register citation | local FR bulk, plus the vol = year − 1935 arithmetic check |
| FRPP asset record | local annual CSV |

> **Verification cost is dominated by fixed corpus acquisition, not by per-citation traffic. The belief
> that a verification tier is prohibitively expensive is what caused it to be omitted, and it is
> wrong.**

The network-bound residue is the archival beat (CREST, DTIC, NARA, GovInfo, FR, GAO) plus the
vernacular/fringe beat — on the order of **10 network resolutions per candidate proposition**. At
polite pacing across ~8 concurrent hosts that is a few thousand resolutions/day, comfortably exceeding
what 2-way agent concurrency can generate.

**Verification is not the bottleneck. Discovery and OCR are.**

---

## APPENDIX C — OCR POLICY

**Never OCR to find. Only OCR to verify a specific span.**

- Prefer Internet Archive `_djvu.txt` sidecars over own OCR: free, precomputed, and generally better
  than CIA's own text layer.
- Page-target the OCR when the lead names a page.
- Record `text_layer_provenance ∈ {native, publisher-ocr, ia-djvu, own-ocr, own-ocr-vision}` on every
  receipt. **`own-ocr-vision` cannot support D4.**
- A span located only by bounded edit distance (≤2% of span length) is `FUZZY-OCR`, **capped at D3**,
  and can never satisfy the §3.4 gate, because condition (d) requires the span to state the proposition
  *on its face*.

This is a known standing bias: CREST is essentially all OCR, and the highest-value D4 material in the
register's universe is structurally biased toward *not* reaching D4 for reasons that have nothing to do
with what it says. See `docs/GRADING.md` §18.8.

---

## APPENDIX D — THE STANDING WARNING

Three of the five registries above were built with the egress proxy blocking nearly every .gov host
plus archive.org. Their endpoint grammars, field names and identifier schemes were reconstructed from
memory, search snippets and GitHub client code, and were **honestly flagged as unverified by their own
authors**.

One of them proposed, as a feature, regexing document identifiers out of a fringe author's books to
*"convert a P4/P5 library into a P1 lead list."* **That is the laundering machine, already specified.**
It is now closed: identifiers extracted from untrusted text are **leads**, and become citations only
after independent resolution at the issuing authority. His documents get promoted; his conclusions stay
T4.

> **The register's own source registry has not been through the register's own verification tier. It
> should be, and that work has not been costed.**

---

*Source registry v0.2.0 · 158 sources · five beats · every endpoint unverified pending W1/P0.*
