# DESIGN — THE BUNKERS REGISTER INTERFACE v1.0

*Status: ratified design specification. Implementation follows this document; deviations are
recorded as corrections, not applied silently.*

This document is the interface counterpart to `GRADING.md`. Where BES v0.2 defines what a grade
*means*, this defines what a grade *looks like* — and, more importantly, what it may never look like.
Every rule here exists because breaking it would let the register assert something the database does
not contain.

Read alongside: `docs/GRADING.md` (Parts 1, 9, 10, 18), `docs/SCHEMA.md` (§4, §5, §11, §14),
`docs/CALIBRATION.md`, `docs/DECISIONS.md` (D-006, D-007, Standing rule).

---

## 0. RULE ZERO — NO MARK WITHOUT A ROW

> **Every mark on this site corresponds to exactly one value the SQL computes. Nothing is drawn from
> a quantity the interface derives by averaging, aggregating, interpolating, or summarising across
> rows.**

This is the governing constraint and it is checkable in review. Its three enforcements:

1. **No composite.** `core.entity` carries nothing graded (`SCHEMA.md` §3). Therefore no entity
   receives a grade mark, a score, a badge, a ring, a meter, a colour, or a sort key derived from its
   propositions. There is no visual slot into which a composite could later be inserted. The
   decomposition is the product (`GRADING.md` §10.1).
2. **No manufactured coordinate.** `core.render_geometry()` emits no point below LOCATE band C.
   Therefore no component in the codebase draws a point for such a feature — including cluster
   anchors, label anchors, and hover targets. `label_point_3857` is a rendering-internal quantity and
   is never painted.
3. **No interpolation.** Grades are ordinal. No line chart of grade over time, no gradient between
   bands, no half-step, no "trending toward B", no partial credit at a band boundary.

A reviewer who finds a mark that cannot be traced to a single returned row has found a bug, not a
style disagreement.

---

## 1. WHICH DIRECTION WON, AND WHAT WAS GRAFTED

**CHART NO. 1 wins.** Its stave glyph is the only proposal that makes non-collapse *structural rather
than editorial* — the container has no mark to collapse into — and it delivers "compact and data
driven" at index scale. Its uncertainty rendering is materially more rigorous: it adopts a citable
200-year-old public vocabulary (IHO INT-1 / U.S. Chart No. 1 `PA`/`PD`/`ED`/`Rep`) instead of
inventing one, it separates existence-doubt from position-doubt as the register itself does, and its
observation that **alpha-compositing makes overlapping uncertainty regions look like corroboration**
is the single sharpest point in either document. Dot screens instead of translucent washes is
non-negotiable because of it.

**Grafted from APPARATUS**, because CHART NO. 1's weakness is that a rail + panel + status-bar chassis
is a dashboard, and dashboards are precisely what the owner said no to:

- The **reference gutter and addressable ref codes** on every block. The cheapest device that makes a
  page feel like research is that any piece of it can be cited.
- The **running head and contents line** instead of an app rail. The **colophon** instead of a footer.
- The **generated scope-and-content sentence** at the head of every stave column. This is the
  human-readable safety net for the stave's learning cost and it is the best copy device in either
  direction.
- The **Claims Register sorted by origin date**, which turns band F into a chronology of American
  underground folklore.
- The **`UNCLAMPED — these do not describe the structure`** labelled rule separating PROGRAM/ORIGIN.
- The **low-zoom degradation rule**: an uncertainty region that falls below 16px on screen becomes a
  fixed dashed square, never a point. CHART NO. 1 did not solve this and it is where the map would
  most easily start lying.
- Plate furniture: **plate number, scale bar, north tick, projection statement, legend-as-table**,
  and the **NOT LOCATABLE ON THIS PLATE (n)** docked panel.
- **Print as a first-class deliverable**, `/corrections`, `/sources` as a sigla table, and the house
  citation style carrying `evidence_state_hash`.

**Rejected from both** (see §20 for the full list): the traffic-light grade ramp, the confident pin,
the teal-for-R hue, APPARATUS's rule-weight grade encoding, and CHART NO. 1's three-zone app frame.

---

## 2. THREE VOICES — the rule that does the work colour usually does

| Voice | Face | Means |
|---|---|---|
| **Mono** | IBM Plex Mono | *This value was computed by the database.* Identifiers, coordinates, hashes, counts, class tags, grades, receipts, versions, offsets, SQL. |
| **Sans** | IBM Plex Sans | *This sentence was written by the register.* Definitions, band labels, silence readings, editorial notes, limitations, headings, all interface furniture. |
| **Serif** | IBM Plex Serif | *These are the source's own words, verbatim.* Quoted spans from documents, and nothing else, anywhere on the site. |

The register's premise is keeping *documented*, *inferred* and *claimed* visibly separate. The type
system encodes the adjacent and equally important separation: **machine-derived / editorial / source
verbatim**. A reader can always tell whose words they are reading, on every line, without being told.

Serif has exactly one job. If serif appears anywhere that is not a quotation from a source document,
that is a bug. It is not available for headings, pull quotes, or emphasis.

Self-hosted via `@fontsource-variable/ibm-plex-sans`, `@fontsource/ibm-plex-mono`,
`@fontsource/ibm-plex-serif`. **No Google Fonts request.** A register whose readers' viewports should
not be logged by a vendor should not ship their font requests to one either; this is the same
decision as the self-hosted basemap and it belongs on `/method`.

Fallbacks:
```css
--font-sans:  "IBM Plex Sans", ui-sans-serif, -apple-system, "Segoe UI", Roboto, sans-serif;
--font-mono:  "IBM Plex Mono", ui-monospace, "SF Mono", "Cascadia Mono", Menlo, monospace;
--font-serif: "IBM Plex Serif", Charter, Georgia, "Times New Roman", serif;
```

---

## 3. TYPOGRAPHY

Base 15px on a 16px root. Ratio 1.2 (minor third). **Seven steps and no more.** Nothing on the site
is larger than 26px — the absence of any figure big enough to be a headline is itself a design
statement.

| token | size | line-height | weight | use |
|---|---|---|---|---|
| `--t-micro` | 11px / 0.6875rem | 1.36 | 600 | class tags, flags, units, column heads, ref codes, status line. `text-transform: uppercase; letter-spacing: .06em` |
| `--t-small` | 12.5px / 0.78125rem | 1.45 | 400 | table body, receipt lines, citations, marginal apparatus, legend |
| `--t-base` | 15px / 0.9375rem | 1.55 | 400 | running prose, table cells in wide tables |
| `--t-lede` | 17px / 1.0625rem | 1.50 | 400 | scope-and-content sentence, band definitions, silence readings, lineage verdict sentence |
| `--t-h3` | 17px / 1.0625rem | 1.35 | 600 | subsection head |
| `--t-h2` | 21px / 1.3125rem | 1.30 | 600 | section head |
| `--t-h1` | 26px / 1.625rem | 1.20 | 600 | page title, once per page |

**Weights: 400 and 600 only.** No 700. Emphasis is italic, uppercase-micro, or a rule.

**Numerals:** `font-variant-numeric: tabular-nums lining-nums` globally, including in Sans, so counts
column-align everywhere. `font-feature-settings: "ss02" 1` on Mono for the slashed zero.

**Measure:** prose `max-width: 46rem` (~68ch at 15px). Marginal apparatus `13rem` (~40ch). Tables and
plates span text + margin.

**Italic is reserved** for: proposition statement sentences, null hypotheses, editorial interpolation
inside a quotation, Latin terms in the stemmatics gloss, and hydrography labels on the plate. Nothing
else.

**Quoted spans** (Serif): `--t-base`, `1.6` line-height, indented `16px`, with a `1px solid var(--rule-strong)`
left rule at `8px` offset. Located character offsets print at the right in Mono `--t-micro`,
`--ink-3`. The offsets are shown because they are the proof a deterministic non-LLM locator found the
string.

---

## 4. COLOUR TOKENS

**Two hues, each with exactly one meaning. Grade has no hue at all.**

Grade is encoded by position, letter, band word and fill state (§7). A green-to-red ramp asserts a
confidence axis, and A→F is not one: `R` and `X` are unranked epistemic objects (`GRADING.md` §1.4),
and an F entry with documented origin work is a contribution. Hue is reserved for the single genuinely
categorical thing that needs it — the **sign of an observation** — plus links and hydrography.

**Why ochre, not red, for UNDERCUTS.** Red on a page about federal facilities reads as alarm and
imports emotional freight the model does not assert. Undercutting evidence is a *correction*, and
ochre is the colour of a correction stamp and a margin annotation.

### Light — bare `:root`

```css
:root {
  --paper:        #FAFAF8;  /* warm near-white — paper, not screen           */
  --paper-sunk:   #F1F0EB;  /* table header, sunken block, panel ground      */
  --ink:          #1A1A17;  /* body, SUPPORTS ticks, grade marks    16.9:1   */
  --ink-2:        #45433C;  /* secondary prose, editorial notes      9.7:1   */
  --ink-3:        #6E6B62;  /* labels, meta, offsets, inert marks     5.2:1  */
  --ink-4:        #8E8B81;  /* NON-TEXT marks only (empty flag dots)  3.4:1  */
  --rule:         #D5D2C9;  /* DECORATIVE hairlines — may never carry info   */
  --rule-strong:  #6E6B62;  /* INFORMATIONAL rules (rails, baselines) 5.2:1  */
  --undercut:     #8A4B0F;  /* ochre — UNDERCUTS, corrections         6.5:1  */
  --link:         #1A4E7A;  /* iron blue — links and hydrography ONLY 8.4:1  */
  --screen:       rgb(26 26 23 / .10);  /* dot-screen fill, uncertainty areas */
  --hatch:        rgb(26 26 23 / .14);  /* 45° hatch: inert, unreached span   */
  --focus:        #1A1A17;
}
```

### Dark

Redefines **only** these tokens. Every token above is defined on bare `:root` first; nothing gets its
sole definition inside a media query.

```css
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { /* values below */ }
}
:root[data-theme="dark"] {
  --paper:        #121210;
  --paper-sunk:   #1B1B18;
  --ink:          #F0EFE7;  /* 16.3:1 */
  --ink-2:        #B8B5AA;  /* 10.0:1 */
  --ink-3:        #85827A;  /*  5.3:1 */
  --ink-4:        #6C6961;  /*  3.4:1 */
  --rule:         #2E2D28;  /* solid, not alpha — dark grounds swallow 1px alpha rules */
  --rule-strong:  #85827A;
  --undercut:     #D9A054;  /*  8.1:1 */
  --link:         #8CBBE0;  /*  9.1:1 */
  --screen:       rgb(240 239 231 / .12);
  --hatch:        rgb(240 239 231 / .16);
  --focus:        #F0EFE7;
}
```

`body { background: var(--paper); color: var(--ink); }` explicitly, always.

Two further tokens, used only by the plate, are defined on bare `:root` alongside these — see §11.

**Rule discipline, enforced in review:** `--rule` may never carry information. Anything a reader must
*read off* a rule — a ladder rail, an evidence baseline, an SCI threshold, a lineage boundary — uses
`--rule-strong` at ≥3:1. Under `-webkit-min-device-pixel-ratio: 1`, `--rule` darkens one step
(`#C8C5BA` light / `#3A3934` dark) because 1px hairlines vanish on low-DPI panels.

Both hues are **only ever redundant reinforcement** on marks that already differ in position and
shape. Remove all colour and every distinction on the site survives.

---

## 5. SPACING, MATERIALS, GRID

### Spacing scale
`4 · 8 · 12 · 16 · 24 · 32 · 48 · 64`. Baseline 4px. Nothing larger than 64. Generous whitespace is a
marketing device; an instrument separates with rules and gutters.

### Materials — the anti-SaaS clause
```css
* { border-radius: 0; box-shadow: none; }
```
Global, no exceptions. No cards, no elevation, no rounded corners, no gradients, no glass, no
illustrations, no icon set beyond the nine apparatus glyphs (`✓ ✕ ⌛ † − ⌀ ⟳ ≈ ∥`) and the five flag
glyphs. All separation is 1px hairlines. This single constraint kills the dashboard read more
effectively than any other decision in this document.

### The document grid

```css
.doc {
  display: grid;
  grid-template-columns: [ref] 6rem [text] minmax(0, 46rem) [margin] 13rem;
  column-gap: 1.5rem;
  max-width: 72rem;
  margin-inline: auto;
  padding-inline: 1.5rem;
}
```

- **Reference gutter (6rem, left).** Every heading, proposition block, table, receipt row and note
  carries a ref code, right-aligned, Mono `--t-micro`, `--ink-3`. Hover/focus reveals a `¶` anchor
  linking to that block. Ref codes are stable and derived from data, never from DOM order:
  `§2` for sections, `p-EXIST-1` for propositions, `e14` for observations, `L-3` for limitations,
  `D-006` for decisions.
- **Text column (46rem).** Prose, proposition blocks, receipt lists.
- **Margin column (13rem).** Marginal apparatus: the citation for the adjacent paragraph, editorial
  glosses, `see L-3` cross-references, the locator figure on an entry page.
- **Wide objects** (register table, plate, stave columns, telemetry tables) span `text / margin`
  (≈60rem) via `grid-column: text / -1`.

### Breakpoints

| width | behaviour |
|---|---|
| ≥1240px | three columns as above |
| 1024–1239px | margin column narrows to 11rem |
| 768–1023px | margin column collapses; marginal apparatus renders inline beneath its paragraph behind a 1px `--rule` left rule; ref gutter drops to 4rem |
| <768px | single column; ref codes render inline as a leading Mono span; wide tables become scroll regions (§15) |

The plate (`/plate`) is the one page that does not use this grid; it uses the coupled split in §9.

### Running head — not a nav bar

36px, one line, Mono `--t-micro`, `2px solid var(--ink)` beneath.

```
BUNKERS · A REGISTER OF HARDENED AND BURIED FACILITIES IN THE UNITED STATES     BES v0.2 · 0 CANDIDATES
```

Beneath it, a plain contents line, items separated by middots, no buttons, no chips:

```
Register · Claims · Plate · Method · Limits · Telemetry · Sources · Decisions · Corrections · Calibration · API
```

On scroll it reduces to a 26px sticky bar carrying the current entry's ref code and section number.
A book's running head, doing a book's job.

### Standing foot — where D-006 lives permanently

A 24px fixed foot, Mono `--t-micro`, `--ink-3`, `1px solid var(--rule)` above it, no background panel,
no chrome, no dismiss control. Present on every page. It is a colophon line, not a status bar.

```
rubric v0.2 · tier v3 · diag v2 · erp v0.2.0 · typology v1 · egress 0/122 · confabulation — · candidates 0 · verification: SELF — single model family, not independent ▸
```

The last field links to `/limits#L-1`. **This is where the D-006 publication obligation is
structurally discharged**, at the same weight and in the same voice as the table versions — because
that is exactly what it is: a property of the instrument's current configuration. It is also stated
verbatim on `/` and at the foot of every proposition table. Redundancy on a publication obligation is
correct.

---

## 6. THE STAVE — the atom of the design

One glyph carrying a complete evidence profile for **one proposition**. Rendered as inline SVG,
`shape-rendering: crispEdges`, `role="img"`, with a `<title>` and a generated `aria-label` (§16).
Three sizes; every size is the same data at a different resolution.

Data source: one row of `api.proposition_badge` plus the observation membership counts.

### 6.1 STAVE-FULL — `viewBox="0 0 324 26"`, rendered at 324×26 CSS px

| # | compartment | x-range | contents |
|---|---|---|---|
| ① | CLASS | 0–36 | 4-char Mono 11px, `--ink-3`, `letter-spacing:.05em`, baseline y=16 |
| ② | LADDER | 42–132 | ranked stops + off-rail cells |
| ③ | EVIDENCE | 140–204 | two-storey signed diverging count bar |
| ④ | LINEAGE | 212–246 | countable pips |
| ⑤ | SCI | 252–288 | k-of-n discrete cells |
| ⑥ | FLAGS | 294–324 | five fixed slots |

**① Class tag.** Fixed 4-character codes so staves align into a column and class becomes a scannable
left edge:
`EXST · EXTN · HRDN · CTRL · FUNC · STAT · LOCT · FEAT · PROG · IDNT · ORIG · TYPO`

**② The ladder.**
- Rail: `x1=46 y1=12 x2=96 y2=12`, 1px `--rule-strong`.
- Six stops at 10px pitch: `A=46 · B=56 · C=66 · D=76 · E=86 · F=96`.
- **Grade** = 7×7 filled square, `--ink`, centred on the stop. **Full ink at every band. An F square
  is exactly as black as an A square.** Density never encodes quality — this is the dignity-of-a-
  negative-result requirement made literal in the ink, and it is checkable.
- **Ceiling** = 1.5px vertical terminal bar, `--ink`, `y=5..19`, at the ceiling stop.
- **`at_ceiling = TRUE`** → the terminal bar is drawn at `stop+5` so the square abuts it, rendering as
  `■┤`. A distinct, learnable shape.
- **Unreached span** (grade → ceiling) = `rect y=9..15` filled `url(#hatch45)` at `--hatch`.
  Reachable, not reached.
- **Debt-ceiling** (`GRADING.md` §10.5, max band if all unverified leads resolve) = 7×7 square,
  `fill:none`, 1px `--ink` stroke, inside the hatch. **Filled = now · outline = if the debt clears ·
  bar = the structural limit.**
- **Discrimination rule**: 1px `--rule`, `y=20`, `x=42..71` — under stops A, B and C only. Above it
  the evidence discriminates; below it, it does not. A typographic rule, not a fill.
- Nothing exists below F. F is the floor, not a basement.
- **Off-rail compartment.** 1px `--rule-strong` vertical separator at `x=106, y=4..20`, then two
  cells: `R` centred at `x=115`, `X` centred at `x=127`.
  - `R` = 9×9 filled square, `--ink`. When grade is R, **the A–F region renders as the bare rail with
    no stops and no marks** — the ranked scale is visibly not in play.
  - `X` = 9×9 square, `fill:none`, 1px `--ink` stroke, `stroke-dasharray: 2 2`. Same bare-rail
    treatment.
  - The detachment is load-bearing. §1.4 states R and X are UNRANKED — "not low grades, different
    epistemic objects." Putting them on the same rail as A–F would be a lie in geometry. They are
    neither capped nor clamped and they cannot read as "worse than F" because they are not on the
    scale that contains F.

**③ The evidence bar.** Every mark is exactly one row of `core.observation`. No aggregation, no
scaling, no averaging.
- Zero baseline: 1px `--rule-strong` vertical at `x=172, y=3..23`.
- **Right of baseline: `V` (SUPPORTS), fill `--ink`. Left of baseline: `U` (UNDERCUTS), fill
  `--undercut`.**
- **Upper storey = CLAIM-PROPERTY** (ticks sit on `y=12`, grow upward).
  **Lower storey = PLACE-PROPERTY** (ticks sit on `y=14`, grow downward).
  This satisfies `GRADING.md` §10.2's mandatory two bars *inside the glyph* rather than as a separate
  chart, and it makes **CAP-2b visible as an empty upper storey**. "No FUNCTION claim can exceed E
  without a CLAIM-PROPERTY observation" — the single hardest constraint in the anti-gaming ledger —
  becomes a visible void. A reader sees at a glance how much of a grade is the mountain.
- Ticks: 2px wide, 3px pitch, max 10 per quadrant (right edge `x=202`, left edge `x=142`).
- **Diagnosticity by tick height**, a five-stop discrete ordinal: `D0=2 · D1=3 · D2=4 · D3=5 · D4=7`.
- **Sort: highest diagnosticity nearest the baseline**, descending outward. A D4 row therefore sits
  against the axis and is visible instantly, which is the point — D4 is the gate.
- Overflow: `▸` in Mono 9px at the outer edge; the exact count lives in the aria-label and in the
  adjacent table cell.
- **The inert tray.** `INERT` and `V0` rows render as 2×2 **open** squares (1px `--ink-3`, no fill) at
  `y=22..24`, 3px pitch, on a dashed sub-rule (`y=25, x=142..202, --rule, dasharray 1 2`).
  **They do not touch the baseline.** Retained, displayed, arithmetically inert — and the geometry
  says exactly that: on the chart, not on the axis.

**④ Lineage pips.** Literal countable pips, never a bar. `L` is an integer, almost always 0–6, so pips
are lossless. Circles `r=1.75`, `cy=13`, 5px pitch from `x=213`.
- **Filled** = an independent lineage containing a D3+ row (`core.lineage_count_claim(p, 3)`).
- **Open** (1px `--ink` stroke) = a lineage reaching only D2 (`core.lineage_count(p, 2)`).
- Above 5: five pips then `+n` in Mono 9px at `x=238`.

**⑤ SCI strip.** `SCI = k/n` literally, so n cells with k filled is lossless. Cells 3px wide × 9px
tall (`y=8.5..17.5`), 1px gap, from `x=252`.
- Filled `--ink` = a receipted profile. Open 1px `--ink-3` = applicable but unsearched.
- **Threshold rule**: 1px `--rule-strong` vertical at `y=6..20` at the 0.5-of-n position. The X-floor
  is a *visible position*, not a colour.
- `n > 9` → collapse the strip to Mono 9px `k/n`.
- **Empty denominator** (`GRADING.md` §7.2's ratified correction, SCI = 1.000): a single 9×9 open cell
  containing `∅` in Mono 8px. Nothing to search is *complete*, and it must not look like zero.

**⑥ Flag gutter.** Five fixed slots, always present, 6px pitch, centres `x = 297, 303, 309, 315, 321`,
`cy=13`, Mono 9px. **An empty slot renders as a 1px `--ink-4` dot (r=0.75) so absence is visible.**

| slot | glyph | meaning |
|---|---|---|
| 1 | `∥` | clamped (`grade_pub < grade`, `GRADING.md` §1.4) |
| 2 | `≈` | `marginal_flag` — one contested fact decided this band |
| 3 | `⟳` | citogenesis confirmed (CAP-3) |
| 4 | `⌀ ! † ⊘ ?` | silence reading: uninformative · informative · record-destroyed · known-withheld · unsearched |
| 5 | `⚑` | any cap applied; the list prints in the detail block |

### 6.2 STAVE-MICRO — `viewBox="0 0 212 16"`

Drops ① (class comes from column position) and ⑤. Fluid: `width:100%; max-width:212px; height:16px;
preserveAspectRatio="xMinYMid meet"`.
- Ladder `x=0..70`: rail `y=7, x=2..42`; stops at 8px pitch (`2,10,18,26,34,42`); grade square 5×5;
  terminal bar `y=3..11`; hatch band `y=5..9`; discrimination rule `y=12, x=0..22`; separator `x=50`;
  R cell `cx=57`, X cell `cx=66`, both 7×7.
- Evidence `x=78..150`: baseline `x=114, y=1..14`; upper tick line `y=7` growing up, lower `y=9`
  growing down; heights `D0=2 · D1=2 · D2=3 · D3=4 · D4=5`; ticks 1px wide, 2px pitch, max 12 per
  quadrant. **At micro, D0 and D1 are not distinguishable — stated, accepted, and recovered in the
  aria-label and on expansion.** Inert tray: dashed rule `y=15`, 1×1 open marks at `y=13..15`.
- Pips `x=158..184`: `r=1.25`, 4px pitch, `cy=8`, up to 5 then `+n`.
- Flags `x=190..212`: five slots, 4px pitch, Mono 7px.

### 6.3 STAVE-TICK — `viewBox="0 0 18 20"`, rendered at 18×20 CSS px

The index mark. **Ladder only, rotated vertical**, so twelve of them fit in a 32px table row and the
whole register reads as a field of small multiples.

- Rail: 1px `--rule-strong` vertical at `x=1, y=1..18`.
- Stops A→F top to bottom at 3px pitch: `y = 2, 5, 8, 11, 14, 17`.
- **Grade** = 6×2 filled bar, `--ink`, at `x=2..8`, centred on the stop.
- **Ceiling** = 1px vertical dimension tick at `x=10`, spanning from the grade stop to the ceiling
  stop, with 3px horizontal serifs at each end.
- **Unreached span** = `rect x=2..8` between the two stops, `url(#hatch45)`.
- **Debt-ceiling** = 6×2 open bar (1px `--ink` stroke) at the debt stop.
- **R / X** = the A–F region renders as the bare rail with no marks, and a 6×6 mark sits at
  `x=11..17, y=7..13`: filled `--ink` for R, 1px dashed open for X.
- **Absent class** = the rail drawn in `--rule` with no mark at all. An empty slot in the container
  list, and visibly so.

### 6.4 The killer property, restated

"The hole is certain, the function is not" — the single most common real state of affairs, and the one
v0.1 could not express — renders without a word:

```
EXST  ■┤ at A          ░│▓▓▓▓▓▓▓ upper storey full   ●●●●●   ▮▮▮▮▮▮   ∥·····
HRDN     ■────┤ at C    ░│▓▓                          ●●      ▮▮▮▮▯▯   ·≈···
CTRL        ■─┤ at D      │▓                          ●       ▮▮▮▮▮▮   ··⚑··
FUNC          ■ at E      │      upper storey EMPTY   ·       ▮▮▮▮▮▮   ··⟳⌀⚑
                         ┈┈┈┈┈┈  7 inert
```

`FUNC`'s empty upper storey **is** CAP-2b. `EXST`'s terminal bar at A against `FUNC`'s at E is the two
propositions' ceilings differing by four bands on the same site, on the same screen, at the same
instant. This is `SCHEMA.md` §4's acceptance assertion rendered as a picture.

---

## 7. GRADE RENDERING OUTSIDE THE STAVE

**Four redundant channels, zero hue:**

1. **Position** — the ladder stop, or the detached off-rail cell.
2. **Letter** — `A B C D E F R X`, Mono, fixed advance so a column aligns.
3. **Band word** — `ESTABLISHED · CORROBORATED · SUPPORTED · INDICATED · DOUBTFUL · UNSUPPORTED ·
   REFUTED · NOT ASSESSED`, Sans `--t-micro` uppercase.
4. **Fill state** — filled = attained · open = debt-reachable · dashed-open = X.

**Hard rules:**
- A stave never appears without an accessible name containing the letter and the band word.
- A stave is never the *sole* rendering of a grade on a detail page; letter and word always print
  adjacent.
- No grade anywhere is rendered as a coloured pill, chip, badge, dot, ring, meter, or gauge.
- No grade is rendered in any hue. Remove all colour and the encoding is intact.
- **Band words are statements about the record, never about the world** (`GRADING.md` §9.1). No copy
  anywhere may paraphrase a band as a claim about existence.

---

## 8. UNCERTAINTY RENDERING — the four problems

### 8.1 Per-proposition grades are never collapsed

The entity has **no grade rendering of any kind**, anywhere: not on the entry page, not in the index,
not on the plate, not in a sort key, not in the API response shape. There is no visual slot for a
composite.

The entry page leads with the **stave column** — N staves, one per proposition, in the fixed class
order used by `api.proposition_badge`:

```
EXIST · LOCATE · EXTENT · TYPOLOGY · HARDEN · CONTROL · FUNCTION · STATUS · FEATURE · PROGRAM · IDENTITY · ORIGIN
```

Position stability is what makes the grid comparable: `FUNC` is always the seventh row, so an eye
trained on one entry reads every entry.

**Above the stave column sits the generated scope-and-content sentence**, Sans `--t-lede`, italic, one
paragraph, deterministically composed from the band of each proposition:

> *Established: the structure exists and is hardened. Doubtful: that it served continuity of
> government. Refuted: that it is federally controlled.*

Grammar fixed by band: A/B → "Established" · C → "Supported" · D → "Indicated" · E → "Doubtful" ·
F → "Unsupported" · R → "Refuted" · X → "Not assessed". This is prose, and **prose cannot be collapsed
into a number.** It is the single-glance answer and the safety net for the stave's learning cost.

**Ordering.** `EXIST` first always — it is the clamp parent — then its clamped children. Then, *below
a labelled 1px `--rule-strong` rule reading* `UNCLAMPED — THESE DO NOT DESCRIBE THE STRUCTURE`, the
`PROGRAM` and `ORIGIN` propositions. This is how Dulce (`docs/CALIBRATION.md` A-12 / R-05) reads:
`ORIG A ESTABLISHED` below the rule, `EXST R · FUNC R · LOCT R` above it. An A-grade fact about a
fabrication and a refuted facility sit on one page without either lying about the other.

### 8.2 Positional uncertainty — hydrographic convention, adopted whole

The register does not invent a vocabulary for "reported but unconfirmed." Cartography solved this and
has published the solution for two centuries. **BUNKERS adopts U.S. Chart No. 1 / IHO INT-1 and cites
it in the legend.**

| `locate_precision` | gate | mark | reading |
|---|---|---|---|
| `exact` | LOCATE ≥ C | **survey cross** — 9px fine cross, 1.5px centre dot, no fill, **no pin** | a fixed point |
| `approximate` | LOCATE ≥ C | survey cross inside a **dotted circle at true `radius_m` ground scale** | a point known to within r |
| `uncertainty_circle` | LOCATE ≥ D | **dotted circle only, no centre mark**, dot-screened interior | somewhere in here |
| `region_polygon` | LOCATE ≥ D | **dotted polygon, no centre mark**, dot-screened interior | somewhere in this region |
| `place_name_only` | — | **no geometry at all** — NOT LOCATABLE panel, name in quotes | a name, not a place |
| `non_located` | — | **no geometry at all** — NOT LOCATABLE panel, separate heading | documented, position unknown |

**Pins are abolished sitewide. No teardrop marker exists in the codebase.** A pin has a tip that
points at one square metre; that tip is a precision claim, and it is the claim this data most often
cannot make. The survey cross has a centre only because `exact` earned one.

**The hard constraint that closes interface-layer citogenesis:** nothing that is not `exact` ever
receives a visible centre mark — not faintly, not as a cluster anchor, not as a label anchor, not as a
hover target. `label_point_3857` is never painted.

**Dotted boundaries, not solid.** The edge of an uncertainty region is *itself* uncertain. A solid
boundary asserts the facility is definitely inside and definitely not outside. 1px dots at 3px pitch.

**Dot screen, not translucent wash.** Interiors are a 4px-pitch SVG `<pattern>` at `--screen`, never
`fill-opacity`. Three reasons, the third decisive:
1. A flat wash reads as a *choropleth value* — "this area is hot" — a different and false claim.
2. A dot screen reads as *sampling / unresolved*, which is the true claim.
3. **Alpha-compositing makes overlap look like corroboration.** Two overlapping translucent regions
   darken into a blob that appears more confident than either. A phase-locked dot screen moirés
   instead of compounding. Translucent fills lie by stacking, and this register cannot afford that
   particular lie.

**The low-zoom rule — where the map would most easily start lying.** When a circle or polygon's
on-screen extent falls below **16px**, it does **not** shrink toward a point. It renders as a fixed
16×16px dashed square containing a centred `▫` glyph, which reads unmistakably as "an area too small
to draw at this zoom" and never as a location. Above 16px it draws at true ground extent.

**Zoom refuses false precision.** Uncertainty circles are drawn at true ground distance, so zooming in
makes them grow — correctly. When a circle exceeds the viewport, a marginal note appears: *"Uncertainty
exceeds the current view. Zoom out to see the extent of the claim."*

**Chart abbreviations**, Mono `--t-micro`, set beside every uncertain feature and beside nothing
`exact`:

| tag | expansion | condition |
|---|---|---|
| `ED` | existence doubtful | EXIST at D or below — doubt about the *thing* |
| `PD` | position doubtful | competing geometry assertions in conflicting positions — doubt about the *place* |
| `PA` | position approximate | `approximate` or `uncertainty_circle` |
| `Rep` | reported | `V ≠ ∅` but nothing at D2+ — reported, not confirmed |

The ED/PD split is precious here because it is *precisely* the register's central distinction, already
lexicalised: existence-doubt and position-doubt are different objects, and hydrography has kept them
separate for longer than the United States has had a Geological Survey.

**Competing geometry is drawn all at once.** `core.geometry_assertion` is versioned and competing by
design. On selection, every non-superseded assertion renders simultaneously: preferred at full weight,
competitors at 40% opacity with their `origin_tier` tag beside them, joined by 1px `--rule-strong`
hairlines showing they refer to one entity. "Four sources put this in four different places" becomes a
*shape*. **Coordinates are never averaged.** An averaged coordinate is a point no source asserts, and
once painted it will be cited.

### 8.3 Refutation and F, drawn as results

- **Every grade mark is full ink at every band.** F is exactly as black as A. Nothing on this site
  fades, dims, greys, or de-emphasises with descending grade. The only reduced-ink content anywhere is
  an *inert observation's* open tick and its `exclusion_reason` — and even those print at full size in
  `--ink-3`, never greyed to illegibility. Greying is deletion by other means, and the standing rule
  is that nothing is deleted.
- **F and R rows in every table carry identical visual weight to A rows** — same type size, same rule
  weight, no muted ground, no error iconography, no warning glyph.
- **R is off-rail and has no hue.** Filled square in the detached cell, bare rail beside it, letter,
  the word `REFUTED`. It cannot be misread as "worse than F" because it is not on that scale.
- **X renders visually distinct from F**, as `GRADING.md` §7.2 demands: the second detached cell, a
  **dashed hollow** mark, plus the SCI strip showing the shortfall against the threshold rule. X is
  the absence of an assessment, so it is drawn as an absence beside a measurement of what is missing.
- **`/claims` is organised by origin, not by facility, and sorted by origin date ascending.** Sorted
  that way, band F becomes a *chronology of American underground folklore*: Oliver 1894 (Telos) →
  Pollock 1976 (Mount Weather) → Bennewitz 1979–80 (Dulce) → Nichols & Moon 1992 (Montauk) → Lazar
  1989 (S-4) → 2016 (Comet Ping Pong). That is a genuine scholarly contribution and it is the
  strongest available answer to "the dignity of a negative result."
- The recurring **`ORIG A` beside `FUNC F`** stave pair — the register publishing an A-grade fact about
  a fabrication — is the design's most distinctive repeated artefact. `/claims` is styled identically
  to `/`. It is not a graveyard.

### 8.4 Contamination and lineage — see §12

### 8.5 Silence

`§SILENCE` on every entry is a table of the ERP profiles applicable to *this proposition*:

```
RECORD CLASS · EXPECTED (X) · SEARCHED · RESULT · RECEIPT
```

- `X0` rows print the verbatim sentence in Sans: *"No public record of this class would be expected
  for a facility of this type in this period under this authority. The absence is not evidence
  against."* An absence becomes a positive statement about the archive.
- An unsearched class prints `— not searched` and **no zero**, because a zero is a claim.
- `NEGATIVE` and `UNSEARCHED` are never conflated; the per-host `egress_state` from
  `api.methodology_coverage` prints in the receipt cell.
- `SILENCE-KNOWN-WITHHELD` prints its own sentence and its acquisition queue reference.

### 8.6 Base rate — published, disclaimed, never drawn

The base-rate reading renders as **words with its disclaimer attached**, never as a bar, a percentage,
or a position on any scale:

> `RARE` — an ordinal reading of reference class RC2. **Not a probability. It did not enter the
> grade.**

`VERY-RARE` additionally prints its arithmetic verbatim (`GRADING.md` §6.5).

### 8.7 Verification debt

Renders inline beneath the proposition's stave, Mono `--t-small`:

```
X — VERIFICATION PENDING · 3 unverified leads · maximum reachable band if all resolve: B
```

and as the outline square on the ladder. The reader sees what the register does not yet know,
quantified in rows.

---

## 9. THE PLATE — `/plate`

**Framing: the map is PLATE I — INDEX MAP TO THE CATALOGUE.** It carries a plate number, a scale bar,
a north tick, a projection statement, and a legend that is a table. It is an index to the catalogue
and it is styled to look like one. From an entry page it appears as a 13rem margin figure captioned
`FIG. 1 — Locator, Adams County PA. Uncertainty: surveyed ±30 m.`

### 9.1 Basemap

**Self-hosted Protomaps `.pmtiles`.** One static archive on object storage, read directly by MapLibre
GL over HTTP range requests via the `pmtiles://` protocol. No tile server, no API key, no rate limit,
and — decisively for this project — **no commercial vendor receiving a log of which coordinates a
reader of a register of federal facilities panned to.** That is a privacy decision before it is a
design one and it belongs on `/method` beside the font decision. CONUS extract at max-zoom 14,
rebuilt monthly against the daily planet build. OpenFreeMap is the documented fallback; OSM ODbL
attribution prints in the plate credit line.

```ts
import { Protocol } from "pmtiles";
maplibregl.addProtocol("pmtiles", new Protocol().tile);
```

### 9.2 Style — three quiet layers

1. **Terrain hillshade at 5–9% contrast**, from a self-hosted 3DEP/SRTM terrain-RGB tileset. The only
   basemap element carrying analytic meaning: this register is about holes in the ground, so relief is
   subject matter, not decoration. Light theme: warm grey multiply on `--field`. Dark theme: cool
   luminance screen at 10%.
2. **Land-status boundaries from PAD-US** — federal installations, DoD withdrawals, BLM/USFS — 0.5px
   hairlines at 20% ink. **Load-bearing, not scenery.** Reference class RC1–RC6 is assigned from land
   status, and the base-rate reading follows from the reference class. The basemap must let a reader
   *see* the reference class, or the base-rate reading published on the entry page is an unverifiable
   assertion. A candidate sitting just outside an installation boundary is RC2, not RC1.
3. **Minimal structure** — coastline; state and county lines (county because the register's
   jurisdiction column is county-level); a restrained road/place layer that fades above z10; **PLSS
   township/range grid at z≥13**, because pre-1970 federal records locate by section-township-range
   and no consumer map draws it.

- Ground: `--field` (`#E9E6DC` light / `#16150F` dark).
- **All roads one hairline** in `--rule` — 1.2px motorway, 0.6px everything else. No casings, no
  fills. Roads exist to make terrain legible.
- **Hydrography** in `--link` hairline, 4% fill, labels in Sans italic `--ink-3`.
- No POIs, no landuse fills, no green parks, no blue water polygons.
- Labels: Sans, `--ink-3`, ≤1px halo, `letter-spacing: .02em`.
- Graticule hairlines with edge ticks at low zoom — plate furniture.

**The plate is a ground, and the uncertainty overlays are always the loudest marks on it.** If a
basemap feature ever competes with an overlay for attention, the style is wrong.

### 9.3 Symbolisation

Per §8.2. **Six independent channels hold "region ≠ point" apart**, so no single rendering failure
collapses the distinction:

1. **Geometry class** — a cross is a mark with a centre; a region is an area with none. Different mark
   types, not two sizes of one.
2. **The centre** — drawn only for `exact`. The code path that emits a coordinate below LOCATE band C
   does not exist.
3. **Boundary stroke** — solid hairline for a surveyed extent (a known footprint); **dotted** for any
   uncertainty boundary.
4. **Interior** — surveyed footprints unfilled or hairline-hatched; uncertainty regions dot-screened.
5. **Chart tag** — `PA`/`PD`/`ED`/`Rep` beside every uncertain feature and nothing beside an `exact`
   one. A two-character text label survives zoom, print, greyscale and screenshot when a stroke style
   might not.
6. **Cluster inheritance** — below z9, a cluster containing any non-`exact` feature carries a
   **dotted** square border. Twelve surveyed points and twelve 50 km regions must never resolve into
   the same cluster mark.

**Clustering** uses `api.map_cluster` on `label_point_3857` (so region features participate at all),
with the **grid cell `(cell_x, cell_y)` as the cluster id** — stable across
`REFRESH MATERIALIZED VIEW CONCURRENTLY`, therefore linkable and cacheable. The mark is a **hairline
square with a Mono count inside**, never a coloured bubble and **never sized by magnitude**. Focus or
hover breaks it down: `14 features — 3 surveyed · 4 approximate · 7 regions`.

### 9.4 Publication gates are visible, not silent

Nothing below band D appears on the plate at all (`GRADING.md` §10.3). The plate carries a permanent
note in the legend block:

```
n candidates are excluded from this plate below band D and appear in the claims register →
```

**The map never omits without saying so.**

### 9.5 Interaction — coupling, not popups

Selecting a feature does **not** open a popup floating over the map. A popup implies the map is
primary and the data is a detail. Selection **fills the coupled panel** with that entity's identity
block, its scope-and-content sentence and its full stave column, ending `→ open sheet`.

Reciprocally, **hovering or focusing a stave row highlights the geometry supporting that specific
proposition.** LOCATE is a graded proposition with its own evidence; the map is literally rendering
one proposition's output. A reader who focuses `LOCT D` and watches a dotted 50 km polygon light up
has learned the central idea of this register without reading a sentence.

Features are in the tab order in catalogue order. A `list view` toggle renders `/` filtered to the
current viewport, so the plate is fully usable without a pointer. **Every map state — bbox, zoom, band
filter, class filter, selection — lives in the URL**, because a plate you cannot cite is not a plate.

No fly-to. No camera easing. Transitions ≤120ms, opacity only. An instrument does not perform.

### 9.6 Legend and furniture

Open by default on desktop, in the panel, above the fold — on a chart the legend is *printed on the
plate*, not hidden behind a `?`. It is a table:

```
SYMBOL · PRECISION · MEANING · n
```

Symbols drawn as inline SVG **at true size**, not as scaled-up illustrations, so they match the marks
exactly. Followed by: the four chart abbreviations with definitions and the INT-1 citation; the scale
bar; the north tick; the projection statement —

> *Web Mercator (EPSG:3857). Areas at high latitude are exaggerated; uncertainty radii are drawn as
> true ground distance.*

— the tile credit line; and the docked panel:

```
NOT LOCATABLE ON THIS PLATE (n)
"Archuleta Mesa, Dulce NM"      place_name_only   → claims register
Unnamed Federal Relocation Arc site   non_located → entry
```

A map cannot show what has no coordinates. Making the unmappable visible *beside* the map is the
honest answer, and it is where `place_name_only` and `non_located` — both of which occur in the
calibration set — become legible rather than silently absent.

### 9.7 Layout

The plate is the one page not on the document grid. Desktop: `grid-template-columns: 26rem 1fr` —
panel left, surface right, both full-height below the running head. Mobile: 50/50 vertical split, map
top, panel bottom, panel draggable to full height. **Never a full-bleed map with a floating sheet** —
the coupling is the point.

---

## 10. TABLES AND CITATION STYLING

### 10.1 Tables

- Row height 32px. 1px `--rule` horizontal hairlines.
- **No zebra striping.** It is decoration and it fights the stave. Vertical column rules at
  `--rule` instead — the survey-report convention.
- Header: `--paper-sunk`, Mono `--t-micro` uppercase, `position: sticky; top: 0`, `2px solid var(--ink)`
  bottom border. First column sticky.
- Native `<table>` semantics are never overridden with `display: block`. Wide tables are wrapped in a
  focusable `role="region"` with an `aria-label` and `overflow-x: auto`; a 1px dotted rule marks the
  clipped edge (no shadow). **The page body never scrolls horizontally.**

**Sort discipline.** `GRADING.md` §18.12 states BES cannot rank within a band. Therefore sorting by
band ties on `entity_id`, and **the column header carries the limitation in the header itself**:

> *Within a band, order is arbitrary. BES cannot rank two C-grade propositions.*

Publishing the constraint where a user would otherwise infer a ranking is the apparatus doing its job.
Likewise, a "sort by grade" control must first ask *which proposition class* — there is no site-wide
grade to sort by.

### 10.2 Receipt lines — the evidence row

Every observation is one row, expandable, in the entry sheet's `§APPARATUS`:

```
e14  V   D4  T1  ▸ CIA-RDP79B00873A001600010025-3   CREST · 1963-11-08 · sha256 4f2a…9c1   ✓ VERIFIED
             UNSOLICITED · INSTANCE · CLAIM-PROPERTY · issuer metadata matched · binding ✓
             “…the relocation facility at Mount Weather, Virginia, is maintained in a…”      @ 4,182–4,297

e19  V0  —   —  ▸ CIA-RDP79B00752A000300010003-1                                            ✕ NOT FOUND
             UNRESOLVED-NOTFOUND · grammar passed · 404 at cia.gov/readingroom and at the CREST mirror
             exclusion_reason: receipt unverified — counted as measured fabrication, agent DISCOVERY-4 → /telemetry
```

- **Membership set is the first token**, fixed 3-character cell (`V`, `U`, `V0`, `INERT`). A column of
  sixty rows can be counted by eye.
- **`INERT` and `V0` rows render at the same size and the same ink as `V` rows**, distinguished by a
  hatched left margin rule, with the generated `exclusion_reason` occupying the position the quoted
  span would occupy. **They are never greyed out and never collapsed by default.**
- **The quoted span is the payload** and carries the most visual weight on the page: Serif, indented,
  with located character offsets in Mono `--t-micro` at the right.
- `signed_weight` always carries an explicit sign. `UNDERCUTS` rows carry **three** redundant
  encodings: the `−` glyph, the word `UNDERCUTS`, and `--undercut`.
- Receipt state is **glyph + word, never colour alone**: `✓ VERIFIED` · `✕ NOT FOUND` ·
  `⌛ UNREACHABLE` · `† DEAD` · `− NEGATIVE`. The three-way UNRESOLVED split (`GRADING.md` §2.2) is
  preserved in the words, because collapsing them would let a blocked proxy inflate the register's own
  published fabrication metric.
- The truncated `sha256` is click-to-copy. Showing a hash is not decoration; it is the reproducibility
  claim, and it is the most instrument-like gesture available.
- Default order: `V` by descending magnitude → `U` → `INERT` → `V0`. Nothing hidden.

### 10.3 Marginal apparatus — no footnotes anywhere

**There is no superscript-number footnote system and no page-bottom notes section on this site.**
Instead: the margin column carries the citation for the adjacent paragraph, always. Every claim is
adjacent to its citation. A notes section is where citations go to be ignored.

Below 1024px the marginal note collapses **inline beneath its paragraph** behind a 1px `--rule` left
rule. Never a tooltip, never a modal — hover-only disclosure is an accessibility failure, not a space
saver. Hover reveals no content that is not otherwise reachable in the DOM.

**Every editorial sentence the register itself writes carries a 5-character margin tag**, the same
scheme the register applies to its sources:

`[doc]` documented · `[inf]` inferred from open signals · `[clm]` claimed

### 10.4 House citation style

Every proposition block ends with a citation carrying the `evidence_state_hash`, because a versioned
grade is only citable at a point in time:

```
BUNKERS Register. “Raven Rock Mountain Complex (Site R).” Entry US-PA-ADA-0007,
proposition p-EXIST-1, grade A as of 2026-08-18. BES v0.2; evidence state 7a1c9f….
https://…/e/raven-rock-site-r#p-EXIST-1
```

Plus a machine-readable provenance beacon: `<link rel="provenance">` in the head and a `⌗` control in
the entry head that copies the beacon URL.

---

## 11. PLATE TOKENS (extension of §4)

Two tokens used only by the plate, defined on bare `:root` alongside the rest of §4:

```css
:root { --field: #E9E6DC; --field-ink: #1A1A17; }
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) { --field: #16150F; --field-ink: #F0EFE7; }
}
:root[data-theme="dark"]          { --field: #16150F; --field-ink: #F0EFE7; }
```

`--field` is the map ground and is deliberately one step warmer/darker than `--paper`, so the plate
reads as a plotted sheet laid on the page rather than as a hole in it.

---

## 12. THE LINEAGE SPINE — contamination made readable

The failure mode is a force-directed hairball. Nobody reads a hairball, and a hairball says *"many
nodes"* when the finding is *"one source."*

The lineage graph is presented in **three registers, text first, drawing last and optional.**

### 12.1 The verdict sentence — always first, Sans `--t-lede`

> **41 citing documents · 1 independent lineage · collapse delta 40.
> This proposition rests on one source and 40 copies.**

`collapse delta` is `documents − lineages`, published per proposition and computed by
`core.lineage_count()` (`SCHEMA.md` §14 Q3). It is the register's own honest replacement for a
contamination score: not a judgement, just the distance between how many sources there appear to be
and how many witnesses there are.

For a citogenesis loop:

> *A T3 publication resting on unattributable T5 testimony, subsequently cited as primary. The loop is
> closed and counts once.*

### 12.2 The descent spine — an indented outline, not a node-link diagram

A form every reader already knows from file trees and comment threads. **Origin at the top:** a tree
read downward from one root says "one source" before a word is read.

```
◇ ORIGIN  1976-03   Pollock, R. “The Mysterious Mountain.” The Progressive.    T3  ✓   INDEPENDENT
          ├ rests on: unnamed off-the-record former officials   ✕ unresolvable  T5  · custody none
          └ rests on: Senate subcommittee material              ✓ resolved      T1
          │
          └ 41 downstream appearances · 1 lineage ───────────────────────────────────────────────
            ├─ 1987  Anderson, J., syndicated column                            T4      collapses
            ├─ 2003  globalsecurity.org/facility/mount-weather                   T4      collapses
            ├╌ 2011  Wikipedia “Mount Weather” §Facilities   ⟳ CITOGENESIS       T4      collapses
            │        └ replication of the 2003 page                             T5      collapses
            ├─ 37 more ▸                                                     T4/T5      collapses
            └ ⟲ closes cycle: D14 → A1 (undated; entry point unresolved)
```

- **The count is in the collapsed row.** *41 downstream appearances · 1 lineage* is the entire finding
  in six words; everything below is elaboration.
- **The right-hand verdict column** is the device that makes this readable by someone who has never
  heard of citogenesis. A reader scanning the right edge sees a column of `collapses` with a single
  `INDEPENDENT`. **That column *is* the "one source and 399 copies" finding, and it requires no graph
  literacy at all.**
- **A horizontal rule is the lineage boundary.** Three independent lineages = three blocks, each with
  its own origin at top. A reader counting blocks is counting `L`. Independent lineages are separate
  **blocks**, never separate colours.
- **Solid connector `├─` = descent. Dashed connector `├╌` = contamination** — the Lachmannian
  stemmatics convention, which is exactly what a cross-lineage citation is, cited by name.
- **Cycles are marked, never hidden.** `closes_cycle` from `core.trace_origin()` renders as `⟲` with
  the edge named. A closed citation loop with no dated entry point is itself a finding about the claim.
- **Merged lineages** (`GRADING.md` §5.7 — a grade can *fall* because a link was found) render as two
  blocks joined by a dashed brace carrying the discovery date and `transition_cause = RE-ANALYSIS`,
  plus a permanent margin gloss: *"Corroboration is non-monotone. Nothing was lost; a link was found."*
- **Origin trace labels its own dating basis** — `document date` vs `first observation` vs `undated`
  (`core.claim_origin()`) — so the register never invents a terminus it does not have.

### 12.3 Citogenesis, in plain language

Wherever `⟳` appears, one plain sentence appears with it, in Sans, no jargon:

> *This encyclopedia article cites the 2003 page, which cites the 1976 article, which is the only
> source. The loop was counted as three sources until 2026-04.*

Once per page, in the margin, an unnumbered gloss teaches the apparatus:

> *Removing derivative witnesses before counting them is what textual scholarship calls* eliminatio
> codicum descriptorum*; a claim crossing between branches is* contamination*. The register performs
> both. The count at the right is the result.*

### 12.4 The distinctive-error test gets a UI

When SAME lineage is asserted on a shared idiosyncratic error (`GRADING.md` §5.1.7), **show the
error.** Two quoted spans side by side in Serif, with the shared error marked by a 2px `--undercut`
underline, and one Sans sentence beneath:

> *Both give the elevation as 4,215 ft. The USGS 7.5-minute quadrangle gives 3,940 ft. An error this
> specific is not independently reproducible.*

A diff view. Everyone can read a diff, and this is the most persuasive single artefact the project can
produce.

### 12.5 The graph view is the escape hatch, not the default

A node-link view exists behind `graph ▸` for the rare many-lineage case: monochrome, hairline, sigla
only, no force layout, no zoom, no path highlighting, no analytics. Captioned in the plate idiom:
`FIG. 2 — Stemma of the FUNCTION claim. Vertical: depth from origin. Horizontal: no meaning.`
The spine is always the default and always carries the load.

---

## 13. PAGE-BY-PAGE IA

**There is no homepage.** `/` is the register. No hero, no explainer panel, no "learn more", no
"get started", no call to action, no newsletter, no social links. The site is a volume, not an app.

```
/                       THE REGISTER — the catalogue table (the index)
/e/[slug]               ENTRY SHEET
/e/[slug]#p-EXIST-1     PROPOSITION — deep-linked and citable
/claims                 THE CLAIMS REGISTER — E, F, R and X with their origin work
/plate                  PLATE I — INDEX MAP TO THE CATALOGUE
/lineage/[doc]          DOCUMENT SHEET — one source and its descent
/sources                THE SIGLA — witness key to every document node (158 sources)
/method                 BES v0.2, readable, with the five curated tables LIVE-QUERIED
/method/expected-records   the ERP table, published
/limits                 STANDING LIMITATIONS — Part 18, verbatim, L-1 … L-19. TOP LEVEL.
/telemetry              THE REGISTER ABOUT ITSELF
/decisions              RATIFIED DECISIONS D-001 … D-007
/corrections            CORRECTIONS AND GRADE MOVEMENT — a published errata series
/calibration            THE REGRESSION SUITE — 34 cases
/calibration/[case]     SPECIMEN SHEET — A-01 … P-06
/api                    machine-readable endpoints and the provenance beacon
```

### 13.1 `/` — THE REGISTER

Four blocks, in order, no others.

**(a) Masthead block.** Definition line between two rules:
*"Not a map of secrets. A map of what can be established, from what, and how well."*
Then **STATE OF THE REGISTER**, a `<dl>` of counts and dates — candidates published · propositions
graded · documents in the citation graph · sources catalogued · hosts reachable / 122 · measured
confabulation rate · rubric version · last grading run. Then the D-006 sentence verbatim, behind a 2px
`--undercut` left rule:

> *This register's second line of defence is self-verification, not independent verification. That
> claim is absent, not merely weaker.* — D-006 → /limits

**(b) HOW TO READ A STAVE.** A permanent legend, ~110px tall, printing STAVE-FULL at true size with
each of the six compartments labelled and the eight bands listed with letter, band word and
statement-about-the-record. **Not collapsible, not dismissible.** The apparatus is handed to the
reader *before* any data, exactly as a chart prints its legend on the plate.

**(c) Filter strip.** Rule-bounded, Sans, plain `<form>` GET with checkboxes and inputs. No chips, no
pills, no autocomplete, no search-as-you-type. Facets: proposition class · band · cap applied · silence
reading · locate precision · typology · state · citogenesis flag · at-ceiling · marginal · SCI floor.
**All state in the URL.** Beneath it, a Mono status line:

```
0 entries · 0 propositions · 158 sources catalogued · 122 hosts in the access schedule, 0 reachable
```

**(d) The catalogue table.** Columns:

```
REF · NAME (aliases) · JURISDICTION · TYPOLOGY · LOCATE · [ 12-column grade matrix ] · SCI · LAST MOVED
```

**There is no "grade" column anywhere in this product.** The grade matrix is twelve fixed columns, one
per proposition class in `api.proposition_badge` order, each cell holding a STAVE-TICK (§6.3). Column
headers carry the 4-character class tags. Absent classes render an empty rail.

Because the columns are fixed and position-stable, **the corpus-wide fact that holes are certain and
functions are not becomes visible on the index page as a diagonal texture**, not just on the entry
page. That is Tufte's small-multiples argument applied to the exact problem the brief names first.

Multiple propositions of one class (several `FUNCTION` rows) stack up to 3 STAVE-TICKs in the cell,
then `+n` linking to the entry. **No worst-case collapse, no "highest grade" summary** — stacking with
an explicit overflow count is lossy about *which*, never about *whether*.

Aliases follow the name in Sans italic `--ink-3` `--t-micro`, truncated with an inline expander.
**F and R rows have identical visual weight to A rows.**

A URL preference `?marks=letters` swaps the tick matrix for a Mono letter matrix (`A B C D E F R X`),
persisted per reader. This is the accessibility and low-vision path, and it is URL state so it can be
linked.

### 13.2 `/e/[slug]` — THE ENTRY SHEET

Section order is fixed by `GRADING.md` §10.1 and is not reordered.

```
§0  HEAD          2px rule · ref code · preferred name · aliases (Mono, published in full) · former designations
§1  IDENTITY      <dl>: entity_id · slug · jurisdiction · entity_level · typology (with its own grade) ·
                  locate_precision · reference class RC1–RC6 with its basis · first published ·
                  last graded · grade events (n) · provenance beacon ⌗
§2  DISPOSITION   the generated scope-and-content sentence (§8.1)
§3  PROPOSITIONS  THE STAVE COLUMN — N staves, full size. This is the lead and it is the product.
§4  DETAIL        one block per proposition (below)
§5  ALTERNATIVES  alternative-hypothesis disposition table
§6  LINEAGE       the spine (§12)
§7  APPARATUS     receipt list — V, U, INERT, V0 in one list, sortable, nothing hidden
§8  SILENCE       ERP profiles, searches, receipts (§8.5)
§9  SEARCH LOG    every corpus queried, query string, corpus version, executed_at, result count,
                  NEGATIVE receipts. Long and boring, and it should be: it is the evidence for the
                  argument from silence and the SCI denominator made auditable.
§10 MOVEMENT      grade history as a STEP CHART, never a line
§11 NOTES         editorial notes, corrections, marginalia
§12 CITE THIS     house citation with evidence_state_hash (§10.4)
§13 MACHINE       JSON / GeoJSON endpoints, permalink to this exact grade version
```

**§4 detail block, per proposition** — five parts, each mandatory:

```
p-EXIST-1   EXIST                                            [STAVE-FULL]   A  ESTABLISHED   at ceiling
            “A substantial artificial enclosed or subsurface structure exists at Raven Rock.”
            null: an ordinary Army communications station, or a granite quarry — EXCLUDED
            route A1 · V[D4]=2 · L(D3)=5 · L(D2)=5 · |V[claim]|=6 · U=∅ · SCI 6/6 · caps none
            limiting_condition: — (at ceiling) · silence INFORMATIVE · base rate UNCOMMON (RC1, not a probability)
            14 observations · 2 inert · collapse delta 3
```

- Line 2 is the **proposition statement as a sentence**, Sans italic — the reader must see a sentence,
  not a category.
- Line 3 is the named null and its **derived** `null_state`. Always present; CAP-7 makes an unnamed
  null a visible cap.
- Line 4 is the arithmetic that produced the band, in Mono. Every term is a returned value.
- Line 5 prints `limiting_condition` **in full prose**, deep-linked to its exact clause on `/method`.
- `marginal_flag` fires a margin note behind a 2px `--undercut` left rule: *"One contested fact decided
  this band: the lineage counterfactual on e21. Recorded in the judgement log."*
- Applied caps are **listed with their definitions inline**, not as codes alone.
- A proposition whose grade is affected by a standing limitation carries a margin reference `see L-3`.
  Limitations stop being a page and become apparatus that reaches into the data.

**§10 MOVEMENT — a step chart, never a line.** Grades are ordinal, so there is no interpolation, no
smoothing, no half-step. Y-axis is the six ranked stops with R and X in a **detached band below the
axis**, matching the ladder. Each step labelled with `transition_cause`. `NEW-DISCLOSURE` carries the
annotation *"the publication record changed; the world did not."* Instrument-drift causes are hidden
by default behind **a visible toggle stating the count** — `3 instrument-drift events hidden ▸` —
because hiding them silently would be the same sin one level up. Text log beneath:

```
2026-03-04  X → D  INITIAL-SEARCH   rubric v0.2.0  hash 7a1c…
2026-05-19  D → B  NEW-EVIDENCE     + e21 (NEPA EIS, D3, L2)
2026-06-02  B → C  RE-ANALYSIS      − lineage: e21 found to cite e07
```

### 13.3 `/claims`

Headnote, verbatim:

> *These entries are not omissions. Each records a claim that circulated, where it came from, and what
> the record does and does not support. An F entry with a documented origin is a finding.*

**Organised by origin, not by facility.** The `ORIGIN` proposition heads each entry; facilities are
downstream. That inversion is the whole idea: this is a catalogue of claims and where they came from,
a genuine scholarly contribution independent of whether any facility is real.

Columns: `REF · CLAIM · ORIGIN (person / artifact / date) · ORIGIN GRADE · FACILITY · CLASS · GRADE ·
LINEAGES · COLLAPSE DELTA · CITOGENESIS · LIMITING CONDITION`.

**Default sort: origin date ascending.** Styled identically to `/` — same rules, same weight, same
ink, same stave marks. It is not a graveyard.

### 13.4 `/limits`

**Top level, not a subsection of `/method`.** `GRADING.md` §18.11 warns that the pressure to soften
this will come from the maintainer, continuously; a page that can be demoted into a subsection is a
page that will be. Permanent link in the contents line and permanent field in the standing foot.

Part 18 verbatim, numbered `L-1 … L-19` so each is individually citable, plus: D-006 in full; the
residual shared-prior channels; CAP-4's self-description as *"a blunt instrument justified only by the
absence of a better one"*; the two surviving judgement calls; the R-reversal rate; the live egress
state; and §18.19's admission that this specification is itself `V0-UNRESOLVED`.

### 13.5 `/telemetry`

Tables, not dashboards. Linked from the contents line **at the same level as the register**.
`api.telemetry_confabulation` per agent, with a hairline bar in the final cell. Band occupancy printed
**beside its own expectation**:

```
modal band should be X or D — observed X                                    ✓
C-band 22% — expected ≤15%                                                  ✗  diagnosticity catalog may be leaking
```

A register that prints its own failing test is the entire thesis in one row. Also: R-rate and
R-reversal rate; per-host egress and robots posture across 122 rows, **state by word + glyph, never by
colour**; SCI distribution; verification debt totals.

### 13.6 `/sources` — THE SIGLA

The witness key: every document node with siglum, `origin_tier`, access method, causal provenance,
`egress_state`, robots posture, last probe, and the propositions it touches. Without this the lineage
spine is unreadable; with it, the spine is a reference table.

### 13.7 `/corrections`

A published errata series. *"Corrections are published, not quietly applied"* needs a URL, or it is not
true. Each correction is numbered, dated, and links to the grade event it explains.

### 13.8 Colophon

Not a footer. Typefaces and licences; tile source and OSM ODbL attribution; PAD-US and 3DEP credits;
data licence; build hash; provenance beacon URL; and the standing rule verbatim:

> *Nothing is deleted. Refuted and F-grade entries are retained with their refutations attached.*

No CTA, no newsletter, no social.

---

## 14. COMPONENT INVENTORY — 24, deliberately small

1. Running head (+ reduced sticky form)
2. Contents line
3. Standing foot (instrument state line, carries D-006)
4. Reference gutter + `¶` anchor
5. Section head (`§n` + 2px rule)
6. Masthead block (definition line + STATE OF THE REGISTER `<dl>`)
7. Descriptive list (`<dl>`)
8. Data table (sticky head, sticky first column, focusable scroll region)
9. **STAVE-FULL**
10. **STAVE-MICRO**
11. **STAVE-TICK** (index grade matrix)
12. Stave legend block (HOW TO READ A STAVE)
13. Scope-and-content sentence
14. Proposition detail block (5 mandatory lines)
15. Receipt row, 4 states (V / U / INERT / V0)
16. Quoted span (Serif + offsets)
17. Lineage spine (indented outline + verdict column)
18. Distinctive-error diff
19. Stemma figure (optional margin SVG)
20. Silence table
21. Step chart (grade movement)
22. Marginal note / apparatus tag (`[doc] [inf] [clm]`)
23. Flag block (limitation / citogenesis / correction, 2px `--undercut` left rule)
24. Plate + legend table + NOT LOCATABLE panel

**Not present, by decision:** cards · shadows · rounded corners · tabs · modals · toasts · pills ·
chips · badges · avatars · gradients · illustrations · skeleton loaders · progress rings · KPI tiles ·
delta arrows · donuts · gauges · accordions (except the lineage descendant expander and the
instrument-drift toggle, both of which state their hidden count) · hero sections · CTAs · onboarding ·
search-as-you-type · saved views · any icon outside the nine apparatus glyphs and five flag glyphs.

---

## 15. MOBILE

Dense tables fail on phones by horizontal scroll (loses comparison) or by card stacks (loses density
and destroys table semantics). Neither is used as the whole answer.

- **The register table transposes into a stave list.** Each entry becomes: name (1 line); `state ·
  typology · locate_precision` (1 line, Mono `--t-micro`); then the **full stave column as a stacked
  micro-block** — up to 12 STAVE-MICRO at 100% width, 16px each, ~200px total, carrying the entire
  evidence profile. This is the one element that *gains* from a narrow column, because staves stack
  rather than tile. Tap to expand to STAVE-FULL, one per line, horizontally scrollable in its own
  region.
- The catalogue table remains available at `?view=table` as a single `<table>` in a focusable scroll
  region with sticky ref + name columns. One markup tree, semantics intact.
- **The plate** is a 50/50 vertical split, map top, panel bottom, panel draggable to full height.
- Genuinely wide reference tables (sources, ERP, telemetry) get `overflow-x: auto` in their own
  container with a 1px dotted rule at the clipped edge as the "more columns" indicator. **No shadow.**
- Marginal apparatus collapses inline beneath its paragraph behind a 1px `--rule` left rule.
- Ref codes move inline as a leading Mono span.
- **The page body never scrolls horizontally.**

---

## 16. ACCESSIBILITY

- **Grade is never conveyed by colour.** Position + letter + band word + fill state. Zero hue on any
  grade mark. The stave survives greyscale, print, 1-bit, and every CVD simulation.
- Both hues are used **only as redundant reinforcement** on marks that already differ in position and
  shape. `--undercut` always accompanies the `−` sign and the word `UNDERCUTS`.
- **Every stave is `role="img"` with a `<title>` and a generated full-sentence `aria-label`:**

  > *"EXIST: grade A, established, at ceiling. Six verified supporting observations, two at
  > diagnosticity 4, all claim-derived. No undercutting observations. Two inert rows retained. Five
  > independent lineages. Search completeness six of six. No caps applied."*

  A screen-reader user receives **more** than a sighted user gets from the thumbnail.
- STAVE-TICK cells in the index are wrapped in links whose accessible name is the same full sentence,
  and `?marks=letters` renders the grade matrix as text for anyone who prefers it.
- Body ink ≥ 7:1 against ground; `--t-micro` ≥ 4.5:1; non-text marks ≥ 3:1. `--ink-4` is for non-text
  marks only and never carries a word.
- Dot screens and 45° hatches are SVG `<pattern>` fills — they scale, print, and remain distinguishable
  under any CVD. Patterns are baked at fixed device-pixel pitch.
- Focus: `outline: 2px solid var(--focus); outline-offset: 2px`, never removed, on every interactive
  element **including map features**.
- Full keyboard traversal of the stave column, the receipt list, and the plate's features (in catalogue
  order).
- No hover-only content anywhere. Everything is in the DOM, linkable, and reachable by keyboard.
- `prefers-reduced-motion` honoured; the map has no camera animation by default regardless.
- **The entire site works with JavaScript disabled except the map canvas.** Server-rendered `<table>`,
  real `<a href>`, filters as `<form>` GET params. A register that requires JS to read a citation is
  not an archive.
- Native `<table>` semantics are never overridden with `display: block`.
- Native `<details>` for the two permitted disclosures; both state their hidden count in the summary.

---

## 17. MOTION, FOCUS, PRINT

- All transitions ≤120ms, **opacity only**. No hover animation, no scroll effects, no parallax, no
  skeleton shimmer. Loading renders a 1px rule and the word `retrieving…` in Mono `--ink-3`.
- No camera flights, no easing on map moves, no fly-to.
- **Print is a first-class deliverable.** `@media print`: marginal apparatus becomes true footnotes at
  the foot of the page; the margin column folds into the text block; the plate renders as a static
  figure with its legend; ref codes stay in the gutter; URLs print after links; the standing foot
  prints once at the end as a colophon; staves print as vector SVG at true size. A finding aid that
  cannot print is not a finding aid.

---

## 18. THE EMPTY STATE — the instrument before first light

An observatory the night before first light is not a broken observatory. It is a complete, calibrated
instrument reporting zero. Four consequences.

**1. The layout does not change when data arrives.** No placeholder component, no skeleton loader, no
"coming soon", no illustration, no email capture, no timeline. `/` renders the same table with the
same twelve grade-matrix columns and the same header. The status line is present and computing. Every
count reads its real value, which is 0. Nothing is a stand-in, so nothing has to be torn out later.

**2. The reason is stated in the register's own vocabulary, not in apology.** A single ruled block
where rows would be, Sans `--t-base`, to the text measure:

> **0 candidates. Collection has not begun.**
>
> The grading model is ratified (BES v0.2). The schema is executable. Egress to 122 catalogued hosts
> is being provisioned; until it lands, no citation can be resolved to bytes, and by this register's
> own standard an unresolved citation is not evidence. Publishing graded candidates before then would
> mean publishing grades that were never verified. — D-007

This is an application of the project's own rule to the project's own situation, which is the most
credible thing it could say.

**3. The 34 calibration cases ship as specimen sheets, rendered through the exact same components.**
This is what makes the launch feel alive rather than broken, and it is precisely what a survey
instrument does before fieldwork: **it measures a known standard and publishes the reading.**

A reader arriving at zero candidates can immediately see, on facilities they have heard of:

| case | what it demonstrates |
|---|---|
| A-02 Raven Rock | seven propositions at A — what a full ladder looks like |
| B-05 / C-02 / D-01 / E-02 Greenbrier 1991 | one entity decomposing across B / C / D / E on one page |
| A-12 + R-05 Dulce | `ORIG A ESTABLISHED` below the unclamped rule, `EXST R REFUTED` above it |
| E-01 DIA | E with `CAP-2b` flagged — an empty upper storey in the stave |
| F-01 + A-13 Montauk | F with an A-grade origin — the `ORIG A / FUNC F` pair |
| F-05 Site CARDINAL | the confabulation canary with its five retained V0 identifiers |
| X-01 | a newly ingested candidate — off-rail X, SCI below the threshold rule |
| R-02 SubTropolis | R reached by the right route, with `refutation_state` shown |

**Specimen containment is strict**, because a project whose entire premise is the separation of
established from claimed cannot afford fixtures being mistaken for entries:

- separate URL namespace `/calibration/[case]`, never `/e/…`
- `noindex, nofollow`
- a persistent header rule on every specimen sheet:
  `SPECIMEN — CALIBRATION CASE A-02. Expected value under BES v0.2, not a register entry. No candidate has been graded.`
- a full-height hatched left margin rule (`url(#hatch45)`, 6px wide) running the length of the page
- the marker embedded in **every** stave `aria-label` on the page
- excluded from every count on `/`, from `/telemetry`, and from the plate
- **no provenance beacon** is emitted

**4. The site is not actually empty, because the instrument is already reporting on itself.**
`/method`, `/method/expected-records`, `/limits`, `/decisions`, `/sources` and `/telemetry` are
complete and populated on day one. `/telemetry` shows per-host egress across 122 hosts, robots
posture, the 158-source registry with tiers, and its expectations printed beside dashes:
`modal band should be X or D — observed: no data`.

**`/plate` at zero candidates** renders complete — hillshade, land status, state and county lines,
graticule, scale bar, north tick, projection statement, full legend — with one Mono annotation in the
corner: `PLATE I — 0 features. Basemap and land-status layers only. The index is empty; the sheet is
not.` The `NOT LOCATABLE ON THIS PLATE (0)` panel is present. A blank grey rectangle would be the
failure; a correctly furnished empty plate is a finished object.

**The honest observation:** this empty state is arguably better than the populated one will be. That
is fine. The methodology *is* the product until the data exists, and pretending otherwise is the
failure mode `GRADING.md` §18.11 warns will come from the maintainer rather than from an attacker.

---

## 19. THE REFUSALS — the honesty guard, checkable in code review

Nine. A pull request that violates one is rejected on those grounds alone.

1. **No composite.** No number, badge, meter, ring or letter summarising an entity. The stave column is
   the summary and it is N marks, never one.
2. **No probability.** Nothing expresses P(the facility exists). Base-rate readings render as words
   with their disclaimer attached — never a bar, a percentage, or a position on a continuous scale.
3. **No interpolation.** Every grade rendering uses discrete stops. No line chart of grade over time,
   no gradient between bands, no half-step, no "nearly B".
4. **No averaged coordinate.** Competing geometry assertions are drawn simultaneously. The register
   never emits a point no source asserts. `label_point_3857` is never painted.
5. **No centre mark on uncertain geometry.** A region has no centre. A circle has one only if a source
   asserted it. No pin exists in the codebase.
6. **No greying-out of retained evidence.** INERT and V0 render at full size with their
   `exclusion_reason`. Greying is deletion by other means.
7. **No error bar without countable endpoints.** Every drawn interval has endpoints the SQL computes
   and the page names in words. The ladder's `grade → debt-ceiling → ceiling` span is the only
   interval on the site, and `limiting_condition` prints the reason for its width in prose beside it.
8. **No hue on any grade.** Grade is position + letter + word + fill. Remove all colour and every
   distinction survives.
9. **No mark without a row** (Rule Zero, §0).

### Why the one permitted interval is honest

The ladder span `grade → debt-ceiling → ceiling` is an error bar, and an error bar is a claim. Its
claim, in full: *the record currently supports exactly this band; resolving the outstanding
verification debt could reach that band; the caps and the expected-record profile make this band the
structural maximum; and the specific condition that stops it is printed beside the mark.* It is honest
for four reasons, and the fourth is the one that matters:

1. Both endpoints are **computed by the SQL**, not estimated by a model or a designer.
2. The scale is **discrete**, so the span cannot be read as a continuous confidence interval with tails.
3. **Every position on it is a defined epistemic state** with a published definition — unlike a numeric
   CI, where intermediate values are interpolations nobody asserted.
4. **The reason for the width is named in text next to it.** `limiting_condition` is not a residual or
   a variance; it is a specific failed condition, e.g. *"A1 — no instance-level dispositive record;
   grade rests on membership in a documented candidate set of M=12 against N=8."* **An error bar whose
   width has a name is a different object from one whose width has a value.**

And the countervailing refusal: `marginal_flag` exists precisely because §18.13 admits BES is brittle
at band boundaries *by design*. The stave flags it (`≈`) and the design **amplifies rather than
softens** the brittleness. There is no visual gradient at a band boundary. Smoothing the boundary
would be the softest and most plausible-looking route back to a composite, and it is refused
explicitly.

---

## 20. WHAT WE REJECTED AND WHY

Recorded because the next person will otherwise re-propose these. Every one of them is a reasonable
idea that would make the register lie.

**The traffic-light grade badge (green A → red F).** Rejected on three grounds, any one sufficient.
(a) It conveys grade by colour, failing WCAG 1.4.1 and failing every CVD reader. (b) A green-to-red
ramp asserts a *confidence axis*, and A→F is not one: R and X are unranked epistemic objects, not low
grades. (c) It makes F look like a failure state, when an F entry with documented origin work is a
contribution and the Claims Register is the register's most distinctive output. **Grade gets no hue.**

**Any single grade for a site.** This was the central defect that killed v0.1: the unit of grading was
a PLACE while the unit of evidence is a PROPOSITION, so a well-documented real installation laundered
its documentation onto every claim attached to it — the register performing citogenesis on itself.
`core.entity` carries nothing graded. If a "site grade" appears anywhere, the v0.1 defect has
returned.

**The confident pin.** A teardrop marker has a tip that points at one square metre. For a 50 km
uncertainty region, for a county-centroid guess, for a `place_name_only` claim, that tip is a
precision claim the evidence cannot make, and once painted it will be screenshotted and cited. No pin
exists in this codebase. Precision is carried by mark *form*, never by colour or size.

**A faint centre dot on an uncertainty circle "so users have something to click."** This is the same
lie at 40% opacity. Uncertain features are clicked by their boundary and their interior screen; the
centre stays empty. The dot in the middle is the lie.

**Translucent fills for uncertainty regions.** Faster and prettier than a dot screen, and it lies by
stacking: two overlapping translucent regions composite into a darker blob that reads as *more*
confident than either. A dot screen moirés instead of compounding, and it reads as sampling rather
than as a choropleth value.

**Averaging competing coordinates.** The most tempting and most dishonest operation available in this
domain. It produces a point no source asserts, and then that point circulates. Competing assertions
are drawn simultaneously with their tiers.

**Letting a small region shrink to a dot at low zoom.** The naive implementation. Below 16px on screen,
regions become a fixed dashed square with a `▫`, never a point.

**Colour-coded independent lineages.** Blocks separated by rules, not hues. Colour would imply the
lineages differ in kind; they differ only in being separate.

**Teal (or any hue) for R.** Proposed as "colourblind-safe and valence-free." It is still hue on a
grade, it still needs a legend, and it still risks reading as a status colour. R is already carried by
four achromatic channels: off-rail position, filled mark, the letter, and the word REFUTED, with the
A–F rail rendered visibly empty beside it. Hue on this site means exactly two things — sign of
evidence, and links — and nothing else may claim one.

**Encoding grade by border weight and dash style (3px solid = A, dashed = D, dotted = E …).** Elegant
on paper and genuinely achromatic, but eight border styles are harder to discriminate at a glance than
eight ladder positions, D-dashed vs E-dotted collapses at small sizes and on low-DPI panels, and it
gives the index no small-multiple texture. Position on a discrete ladder does the same job, scales
down to 18px, and reads as a *scale* rather than as decoration.

**The three-zone application frame (rail + panel + surface + status bar).** A dashboard chassis, and
the owner said this must not feel like something being marketed. Replaced with a running head, a
contents line and a standing foot — book furniture, not app chrome. The map keeps a coupled panel
because there the coupling is the content.

**A hero section, a value proposition, a "Get Started", a gradient, a testimonial, a newsletter, an
onboarding tour, an illustrated empty state with a CTA.** All persuasion. The reference points are an
archival finding aid, a survey report, and a nautical chart. Authority comes from apparatus and
citation, never from styling.

**Burying D-006 in a footer or behind a dismissible banner.** Banners get dismissed and read as
warnings; footers are where obligations go to be ignored. The limitation is reported in the standing
foot at the same weight as the table versions — because that is exactly what it is, a property of the
instrument's current configuration — plus verbatim on `/`, plus a top-level `/limits` page that cannot
be demoted to a subsection.

**Hiding, dimming, or muting F, R, X, INERT and V0.** Greying is deletion by other means, and the
standing rule is that nothing is deleted. Full ink at every band; the F square is exactly as black as
the A square.

**A force-directed node-link graph as the default lineage view.** A hairball says "many nodes" when
the finding is "one source." The indented spine with a right-hand `collapses / INDEPENDENT` column
delivers the finding without any graph literacy. The network view is an escape hatch.

**A vendor basemap token (Mapbox, Google, Esri).** Beyond the licensing and repricing risk: it sends
a log of which coordinates a reader of a register of federal facilities panned to, to a third party.
Self-hosted PMTiles is real ops work and it is the correct trade. Same reasoning bans the Google
Fonts request.

**Zebra striping, box shadows, rounded corners, skeleton loaders, tooltips as a primary detail path,
search-as-you-type, saved views.** Each is a small persuasion or a small piece of state the URL does
not capture. Filters are `<form>` GET params, URLs are the state, and the back button works.

**Sorting the register "by grade".** There is no site grade to sort by, and `GRADING.md` §18.12 says
BES cannot rank *within* a band either. A sort control must first ask which proposition class, and the
column header must publish the tie-breaking limitation.

---

## 21. WHAT THIS DESIGN DOES NOT SOLVE

Published here for the same reason Part 18 exists.

1. **The stave has a real learning cost.** No first-time reader decodes six compartments unaided.
   Mitigated by the permanent true-size legend on `/`, the scope-and-content sentence above every
   stave column, the full-sentence aria-label on every instance, and stable class ordering so one
   entry teaches all the others. It remains a genuine cost, and it is the price of the density the
   brief demands. A single-letter badge would be instantly legible and would be the composite,
   reintroduced as an affordance.

2. **Refusing hue costs skimmability.** A red/amber/green register scans faster than a monochrome
   positional one. Deliberate: skimming speed bought by implying confidence is the wrong trade, and
   the small-multiple texture of the index recovers most of it. Some readers will find this site
   harder than it needs to be and they will not be wrong.

3. **There is no whole-corpus heat read.** You cannot squint at the index and see where the register
   is weak. `/telemetry`'s band occupancy against its own expectation is the aggregate view and it is
   a better instrument, but it is a second click.

4. **The index's grade matrix is lossy about *which*.** Three STAVE-TICKs plus `+n` per class cell
   handles the common case; an entity with six FUNCTION rows defers the rest to the entry sheet. The
   loss is disclosed in the column header. It is never lossy about *whether* a class is graded.

5. **The lineage spine does not scale past roughly eight lineages** without becoming a long scroll.
   The graph view is worse. There is no good answer for a 40-lineage claim; there are also very few of
   them, and the collapsed count row plus the collapse delta carries the finding even when the drawing
   does not.

6. **1px hairlines are fragile** on low-DPI panels and at some browser zoom levels. Mitigated by
   darkening `--rule` under `-webkit-min-device-pixel-ratio: 1`, by never letting a decorative rule
   carry information, and by never using sub-pixel widths. The QA pass has to actually check this on
   cheap monitors.

7. **The margin column is dead weight between 768 and 1024px.** Tablets get inline apparatus and lose
   the locator figure and the stemma. Accepted; the spine is the primary lineage presentation, so
   nothing load-bearing is lost.

8. **Self-hosted PMTiles plus a derived hillshade is real infrastructure** with storage, egress and a
   rebuild cadence, and no SLA. Accepted as the price of the no-token, no-vendor-telemetry
   requirement.

9. **Publishing 34 specimen sheets risks fixtures being screenshotted as findings.** Six containment
   mechanisms are specified and none of them closes it fully. Judged worth it, because a site with
   nothing to read at launch has a worse credibility problem.

10. **Dot-screen SVG patterns can moiré** and degrade at high feature counts. Above ~2,000 visible
    features, regions degrade to boundary-only, still dotted. The degradation drops area emphasis,
    never location semantics.

11. **Publishing `/telemetry` and `/limits` at register-level prominence is a reputational cost**,
    taken deliberately. The first hostile summary of this site will quote Part 18, and the design
    makes that easy on purpose. A register that states its measured fabrication rate is more credible
    than one that implies none.

---

*Design v1.0 · 2026-08-18 · to be revised only through `/corrections`.*
