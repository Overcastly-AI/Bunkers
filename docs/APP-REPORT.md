# APP-REPORT — the web application, as built

*W2 integration pass · 2026-08-18 · written to decide whether to ship, not to reassure.*

This reports on `app-web/`, the Next.js application implementing `docs/DESIGN.md` v1.0. It was
built by three agents working in sequence — foundation, plate, register surface — and this pass
added the methodology surface and reconciled the three.

**Verdict up front: it builds, it runs, and every page renders. It is shippable as the
zero-candidate artifact D-008 describes. It is not shippable as a data product, and nothing in it
pretends to be.** The gap between those two statements is the whole of §4 below.

---

## 1. BUILD AND VERIFICATION STATE

| check | result |
|---|---|
| `npm run build` | **passes** — 67 routes, no warnings that matter |
| `npx tsc --noEmit` | **clean** |
| `npm run seed:check` | **PASS** — 49 cases, 30 specimen entities, 161 propositions, 431 observations |
| `npm run plate:check` | **PASS** — symbolisation, the 16px rule, six refusals |
| every route returns 200 | **yes**, 17 page routes + 2 API routes; `/nonexistent` correctly 404s |
| renders with JavaScript disabled | **yes** — full text, tables, forms and staves server-rendered |
| external network requests at read time | **zero**, verified in-browser across all pages |
| horizontal body scroll | **none** at 390 / 768 / 1024 / 1440px |

Verified by driving the production build in headless Chromium, not by reading source. Screenshots
are in `app-web/screenshots/` (22 files: 14 desktop, 4 dark, 3 mobile, plus the plate in both
themes).

---

## 2. WHAT EXISTS AND WHAT RENDERS

### 2.1 Routes

All seventeen render. Seven of them did not exist before this pass — the contents line linked to
them and every link 404'd.

| route | state |
|---|---|
| `/` | complete. Four §13.1 blocks: masthead, stave legend, filter strip, catalogue table with the fixed 12-column matrix. Renders its real zero. |
| `/claims` | complete, register-empty. Worked chronology at `/calibration/claims`. |
| `/plate` | complete as a sheet. **No basemap** — see §4.2. |
| `/method` | **new.** BES v0.2 for a reader who has not read the specification. D-006 at §2, above the mechanics. |
| `/method/expected-records` | **new.** 9 ERP profiles, live-queried. |
| `/limits` | **new.** Part 18 verbatim, L-1 … L-19, individually addressable. |
| `/telemetry` | **new.** Expectations printed beside observations that are all "no data". |
| `/sources` | **new.** Corpus registry, 18 of 158, with the shortfall stated. |
| `/decisions` | **new.** D-001 … D-008. |
| `/corrections` | **new.** Six corrections, one open. |
| `/api` | **new.** Machine surface + colophon. |
| `/methodology` | **new.** Permanent redirect to `/method` — one canonical address per document. |
| `/calibration`, `/calibration/[case]` | complete. 49 sheets through the same components, contained. |
| `/calibration/claims` | complete. |
| `/e/[slug]`, `/lineage/[doc]` | honest empty sheets. No fallback to fixtures. |

### 2.2 The methodology pages

These are primary content for this project, and they are written as such rather than as
boilerplate. `/method` explains five ideas — propositions not places, signed evidence,
diagnosticity against a named alternative, three-column provenance, resolve-or-die — each with the
defect it exists to answer and a link to the calibration case where it bites.

**D-006 is discharged in five places**, at the weight §20 demands and never as a footer:

- the standing foot of **every** page (verified: 11/11 sampled)
- `/method` §2, verbatim, in a flagged block *above* the mechanics, because it qualifies all of them
- `/limits` §1, in full, plus `L-3` as its standing-limitation form
- `/decisions#D-006`, with the reasoning and the consequence
- `/` — verbatim, behind the 2px `--undercut` rule

The wording is the register's own: the second line of defence is **self-verification, not
independent verification; that claim is absent, not merely weaker.** No page softens it.

`/corrections` publishes the v0.1 supersession with all sixteen fatal defects named individually
(H1–H6, I1–I4, S1–S6), not as a count. It also carries the project's own instrument defects,
including one left **open** (C-006, the 34-vs-43 calibration discrepancy) rather than held back
until it closes.

---

## 3. DEFECTS FOUND AND FIXED IN THIS PASS

Seven. Five were real and user-visible; the concurrent agents could not have caught the last two
because each owned only half of the seam.

1. **Seven contents-line links 404'd.** The entire methodology surface — the product, at zero
   candidates — did not exist. Built.

2. **Site-wide horizontal scroll at phone widths.** The contents line emitted no whitespace
   between items, so it had no line-break opportunity and became one unbreakable 631px word. Every
   page inherited it from the root layout, and §15's "the page body never scrolls horizontally" is
   a hard requirement, not a preference. Fixed with real whitespace text nodes.

3. **`.dl` forced overflow on six pages at 390px.** The 22rem-term/value grid leaves the value
   column ~6px, and a value cannot render narrower than its longest word. Stacks below 768px now.

4. **The plate never loaded.** The style set `glyphs: undefined` as a present key; MapLibre
   validates key presence, rejected it, aborted the style load, and the map never fired `load` —
   so the surface sat in its `retrieving…` state forever. The key is now omitted rather than
   undefined.

5. **The map container collapsed to zero height.** `maplibre-gl.css` ships
   `.maplibregl-map { position: relative }`, MapLibre adds that class to the container, and the
   vendor sheet is bundled *after* `plate.css` — so at equal specificity the vendor rule won. The
   canvas fell back to the HTML default 300px and **the overlay SVG, which is sized from
   `container.clientHeight`, was drawn into a zero-height viewBox** — graticule, edge ticks and
   every uncertainty mark invisible. This is exactly the "blank grey rectangle" §18 names as the
   failure. Fixed by raising the selector's specificity.

6. **The plate panel printed bare grade letters**, violating §7's "letter and word always print
   adjacent". The stave agent had already built `GradeLetterWord`; the plate agent, working
   concurrently, could not know. Now wired to the shared component.

7. **Two `<h1>` on every specimen sheet**, and a missing favicon 404'ing on every page load. Fixed
   via a `headingLevel` prop and an `icon.svg` drawn from the register's own stave motif.

---

## 4. WHAT IS STUBBED, ABSENT, OR APPROXIMATED

### 4.1 The database is not connected

`SupabaseRepository` is a **stub**: no client, no key, no import, no network call. Every method
carries its PostgREST query written out beside it, unexecuted. The application runs entirely on
`SeedRepository`, and the register-facing methods return empty **because the arrays are empty**,
not because a flag is set.

This means **the `api.*` views have never been read by this application.** The TypeScript
interfaces were transcribed from `supabase/schema.sql` column by column and are unverified against
a live response. That is the single largest untested surface in the codebase.

### 4.2 The plate has no basemap

No `.pmtiles` archives exist and none could be fetched in this environment. The plate probes for
five archives by range request, they 404, and **the absence is published in the panel** rather
than silently degraded. Ground, graticule, edge ticks, scale bar, north tick, projection
statement, legend at true size, and the NOT LOCATABLE panel all draw. No vendor basemap is
substituted, deliberately.

`public/basemap/README.md` carries the exact paths and acquisition commands. Until those archives
exist there is no hillshade, no land status, no coastline, no county lines and no place labels —
and **PAD-US land status is load-bearing, not scenery**: reference class RC1–RC6 is assigned from
it, so a reader currently cannot see the basis of any base-rate reading the entry pages will
publish.

### 4.3 Curated content is partial, and says so

- **18 of 158 sources** transcribed. The other 140 must be imported from `registry.corpus`; writing
  them by hand would be the confabulation this register measures. `/sources` prints both counts.
- **9 ERP profiles** — the ones the calibration suite exercises.
- **Document sigla table is empty** (0 documents in the citation graph). Correct: a document earns
  a siglum when an observation cites it and that citation resolves.
- **Telemetry is empty** across the board, with expectations printed beside dashes. "No data" is
  rendered as a distinct state from a passing test, never as one.

### 4.4 Specified but not implemented

| spec | state |
|---|---|
| §9.5 selection fills the panel with the **full stave column** | **not done.** Panel shows identity, disposition and chart tags, and states explicitly that the mark renders LOCATE only and that the entity's propositions are not summarised. Wiring the column needs a per-entity badge fetch that has no endpoint; with zero features the panel is unreachable in this deployment. |
| §9.3 cluster precision breakdown, dotted-border inheritance | **not computable.** `api.map_cluster` returns no precision columns. Border defaults to dotted (never asserts "all surveyed"); the missing breakdown is printed in the legend. The three-column DDL fix is written out in `CLUSTER_PRECISION_DDL`. |
| §8.7 debt-ceiling outline square in the **index** matrix | **absent.** `api.proposition_badge` has no verification-debt column. Drawn on STAVE-FULL/MICRO where the specimen supplies one; a mark with no returned value would break Rule Zero. |
| §12.4 distinctive-error diff | **not implemented.** No shared-error pairing exists in the data model. |
| §12.5 stemma graph escape hatch | **not implemented.** The spine carries the load in all seed cases. |
| §5 sticky reduced running head on scroll | **not implemented.** Requires JS; the site must read without it. |
| §10.4 `<link rel="provenance">` and `⌗` copy control | **not emitted.** Specimens must emit no beacon and the register has no entries. The citation line with `evidence_state_hash` does print; `CopyHash` exists. |
| §15 mobile transposition | **approximated as URL state** (`?view=list`), not a breakpoint. Server-rendered pages cannot know viewport width, and shipping both trees would put a second copy of every stave in the accessibility tree. |
| `PD` / `Rep` chart tags | **fire only on selection.** Not provable from a plate row; guessing them would be a mark without a row. |

### 4.5 Rules that ARE fully implemented

Verified in the served HTML, not assumed:

- **Rule Zero.** No composite anywhere. No entity carries a grade mark, score, badge or sort key.
- **No hue on grade.** Every mark in the served SVG uses `var(--ink)` / `var(--ink-3)` /
  `var(--rule*)`. Zero raw hex, zero hue on any grade mark, across every page.
- **Three voices.** `voice-serif` appears **only** on the specimen sheet, in quoted spans — zero
  occurrences on all seven prose pages. Serif outside a quotation would be a bug; there are none.
- **Self-hosted everything.** Zero external URLs in markup and zero external requests at runtime,
  measured in-browser. 46 font files served locally; no vendor tile host reachable, and
  `plate:check` fails the build-check if one is introduced.
- **No manufactured coordinate.** `centreOf()` is the only function returning a paintable
  coordinate; `plate:check` scans the renderers and fails on `.centroid` or `label_point`.
- **Materials clause.** Global `border-radius: 0; box-shadow: none`, no exceptions.
- **Accessibility basics.** Every stave `role="img"` has an accessible name (0 unnamed across
  sampled pages); no heading-level skips; no empty links; one `h1` per page; full keyboard focus
  styling; site works with JS off.

---

## 5. WHAT MUST HAPPEN BEFORE DEPLOY

Ordered by what breaks if skipped.

1. **Connect and verify the read surface.** Set `NEXT_PUBLIC_SUPABASE_URL`,
   `NEXT_PUBLIC_SUPABASE_ANON_KEY` and `BUNKERS_DATA_SOURCE=supabase`, then check every `api.*`
   view against `src/lib/types/api.ts` column by column. The types are transcribed and unverified.
   Confirm PostgREST is pointed at `api` and not `public` — D-008 records that it was inverted
   once already.
2. **Confirm RLS actually denies.** The anonymous key ships in client code by design. The schema's
   posture should be re-tested against the live project before a public URL exists, not after.
3. **Acquire the five PMTiles archives.** Until then the plate is furniture on an empty ground and
   the reference-class basis is invisible.
4. **Import the remaining 140 corpus rows** from `registry.corpus`. Do not hand-write them.
5. **Settle C-006** — the calibration suite is described as 34 cases and enumerates 43. It is the
   denominator of the suite that certifies the instrument. The register currently publishes both
   counts, which is honest but unresolved.
6. **Run a real accessibility audit.** Structural checks pass; no axe/WCAG contrast audit has been
   run against rendered output, and §16's contrast ratios are asserted from the token table rather
   than measured.
7. **Check print output in an actual print engine.** `@media print` is written to spec and has
   never been exercised. §17 calls print a first-class deliverable.
8. **Check 1px hairlines on a low-DPI panel.** §21.6 names this as fragile and says the QA pass has
   to actually check it on cheap monitors. It has not been checked on any.

**No test suite exists beyond `seed:check` and `plate:check`.** There are no component tests, no
route tests and no regression tests on the rendering rules. The refusals in §19 are enforced by
`plate:check`'s source scan and by review — not by tests. A future agent can reintroduce a
composite grade or a translucent fill and nothing will fail.

---

## 6. HONEST ASSESSMENT

The empty state is the strongest thing here, and DESIGN.md §18 predicted that: *"this empty state
is arguably better than the populated one will be."* The instrument reports zero in its own
vocabulary, publishes the reason (D-007), publishes what it cannot do (L-1 … L-19), publishes what
it got wrong (six corrections, one open), and publishes the limitation that its own verification is
not independent — five times, never softened, never in a footer.

Three things a reader should be told plainly:

- **The methodology surface is now the product, and it is complete.** Seven pages that did not
  exist this morning are the reason the site is worth publishing at zero candidates.
- **The data layer has never touched the database.** Everything renders from a local seed. The
  moment real rows arrive, expect type mismatches at the `api.*` boundary — that is the first
  thing to test, not the last.
- **The plate is a furnished sheet with nothing under it.** It is honest about that on the page.
  It is still a map with no map.

Nothing in this application asserts something the data does not contain. That was the bar, and it
holds. The risks that remain are risks of *absence* — untested seams, missing archives, partial
tables — and every one of them is stated on the site itself rather than only here.

---

*Screenshots: `app-web/screenshots/`. No MCP tool was called, no Supabase contact was made, and no
commit was created during this pass.*
