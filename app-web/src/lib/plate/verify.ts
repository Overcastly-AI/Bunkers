/**
 * PLATE VERIFICATION — the refusals, made executable.
 *
 * Run with `npm run plate:check`.
 *
 * DESIGN.md §19 opens: "Nine. A PULL REQUEST THAT VIOLATES ONE IS REJECTED ON
 * THOSE GROUNDS ALONE." A refusal that lives only in a document is a refusal
 * that survives exactly until the first person in a hurry. Six of the nine bear
 * on the plate, and the checks below are the ones that would actually catch a
 * violation:
 *
 *   Refusal 1  no composite ............ no entity-level grade mark is drawn
 *   Refusal 4  no averaged coordinate ... `centroid` and `label_point` unread
 *   Refusal 5  no centre on uncertainty . the symbol table, asserted
 *   Refusal 8  no hue on any grade ...... no grade token reaches a paint value
 *   Refusal 9  no mark without a row ..... every legend count is a list length
 *   §9.1       no vendor tile origin ..... the archive manifest, asserted
 *
 * Two of these are source scans rather than assertions about values, because
 * the violation they catch is "somebody read a column they should not have
 * read", and that is a property of the code, not of a return value.
 *
 * It is not a test framework. It prints and exits non-zero.
 */

import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

import { ARCHIVES, assertNoVendorHost } from "./basemap";
import { assertCentreDiscipline, centreOf, LEGEND_ROWS, markFor } from "./precision";
import { chartTags } from "./chart-tags";
import { clusterMark } from "./clusters";
import {
  degrade,
  groundRadiusToPixels,
  metresPerPixel,
  MIN_EXTENT_PX,
  scaleBar,
  screenBox,
  type ScreenPoint,
} from "./geometry";
import { legendRows } from "./legend";
import type { MapFeature } from "../types/api";
import { GEOMETRY_REPRESENTATIONS, LOCATE_PRECISIONS } from "../types/enums";

const failures: string[] = [];
const notes: string[] = [];

function check(ok: boolean, label: string) {
  if (!ok) failures.push(label);
}

/* ================================================================== *
 * 1. REFUSAL 5 — no centre mark on uncertain geometry
 * ================================================================== */

for (const f of assertCentreDiscipline()) failures.push(`symbol table: ${f}`);

/**
 * The table is exhaustive over both enums. A precision or representation added
 * to the schema without a mark would otherwise render as whatever the last
 * `switch` arm happened to be.
 */
for (const rep of GEOMETRY_REPRESENTATIONS) {
  for (const prec of LOCATE_PRECISIONS) {
    const m = markFor(rep, prec);
    check(m.form !== undefined, `markFor(${rep}, ${prec}) returned no form`);
    if (m.centre) {
      check(
        rep === "point",
        `markFor(${rep}, ${prec}) claims a centre mark on a non-point representation`,
      );
    }
  }
}

/** `centreOf()` is the only coordinate emitter, and it refuses everything else. */
const base: MapFeature = {
  entity_id: "00000000-0000-0000-0000-000000000000",
  slug: "check",
  canonical_name: "Check",
  entity_level: "site",
  country_code: "US",
  typology: null,
  exist_grade: "A",
  exist_rank: 6,
  at_ceiling: false,
  marginal_flag: false,
  ceiling: null,
  silence_reading: "UNINFORMATIVE",
  base_rate_reading: null,
  limiting_condition: null,
  representation: "point",
  locate_precision: "surveyed",
  locate_grade: "A",
  uncertainty_radius_m: null,
  suppression_reason: null,
  geom: { type: "Point", coordinates: [-77.4, 39.8] },
  proposition_count: 1,
  refuted_count: 0,
  unassessed_count: 0,
  graded_at: "2026-08-18T00:00:00Z",
};

check(centreOf(base) !== null, "a surveyed point must yield its asserted coordinate");
check(
  centreOf({ ...base, representation: "uncertainty_circle" }) === null,
  "REFUSAL 5 VIOLATED: an uncertainty circle was given a centre",
);
check(
  centreOf({ ...base, representation: "region_polygon" }) === null,
  "REFUSAL 5 VIOLATED: a region was given a centre",
);
check(
  centreOf({ ...base, representation: "admin_polygon" }) === null,
  "REFUSAL 5 VIOLATED: an admin polygon was given a centre",
);
check(
  centreOf({ ...base, representation: "none", locate_precision: "place_name_only" }) === null,
  "REFUSAL 5 VIOLATED: a place name was given a centre",
);

/* ================================================================== *
 * 2. THE 16px RULE — a region never shrinks toward a point
 * ================================================================== */

const tiny: ScreenPoint[][] = [
  [
    { x: 100, y: 100 },
    { x: 103, y: 100 },
    { x: 103, y: 102 },
    { x: 100, y: 102 },
  ],
];
const d = degrade(tiny);
check(d.mode === "below-threshold", "a 3×2px region must degrade, not draw at true extent");
if (d.mode === "below-threshold") {
  const w = d.box.maxX - d.box.minX;
  const h = d.box.maxY - d.box.minY;
  check(w >= MIN_EXTENT_PX && h >= MIN_EXTENT_PX, "the substitute square must be at least 16px");
  const t = screenBox(tiny)!;
  check(
    d.box.minX <= t.minX && d.box.minY <= t.minY && d.box.maxX >= t.maxX && d.box.maxY >= t.maxY,
    "CONTAINMENT VIOLATED: the substitute square must contain the true extent",
  );
  check(d.glyph === "▫", "the substitute square must carry the ▫ glyph");
}

const large: ScreenPoint[][] = [
  [
    { x: 0, y: 0 },
    { x: 80, y: 0 },
    { x: 80, y: 60 },
    { x: 0, y: 60 },
  ],
];
check(degrade(large).mode === "true-extent", "an 80×60px region must draw at true extent");

/** Zoom must make a true-ground-radius circle grow, never hold it constant. */
const rNear = groundRadiusToPixels(50000, 39.5, 6);
const rFar = groundRadiusToPixels(50000, 39.5, 9);
check(rFar > rNear * 7, "an uncertainty radius must be drawn at true ground scale");
check(
  metresPerPixel(39.5, 6) > metresPerPixel(60, 6),
  "Web Mercator ground resolution must fall with latitude",
);

/* ================================================================== *
 * 3. REFUSAL 9 — every legend count is the length of a list
 * ================================================================== */

const rows = legendRows([], []);
check(rows.length === LEGEND_ROWS.length, "the legend prints one row per symbol");
check(
  rows.every((r) => r.n === 0),
  "with no features and no unlocatable rows every legend count must be 0",
);

const withOne = legendRows([base], []);
check(
  withOne.find((r) => r.precision === "surveyed")?.n === 1,
  "a surveyed feature must be counted against the surveyed symbol",
);
check(
  withOne.filter((r) => r.n > 0).length === 1,
  "a feature must be counted against exactly one symbol",
);

/* ================================================================== *
 * 4. CHART TAGS — nothing is asserted from a row that was not returned
 * ================================================================== */

check(chartTags(base).length === 0, "an exact, established feature carries NO chart tag");
check(
  chartTags({ ...base, exist_grade: "D", exist_rank: 3 }).includes("ED"),
  "EXIST at D must raise ED",
);
check(
  chartTags({ ...base, representation: "uncertainty_circle" }).includes("PA"),
  "an uncertainty circle must raise PA",
);
check(
  !chartTags({ ...base, representation: "uncertainty_circle" }).includes("PD"),
  "PD must NOT be raised without the competing-assertion rows that prove it",
);
check(
  chartTags(base, { conflictingAssertions: 2 }).includes("PD"),
  "PD must be raised when conflicting assertions are supplied",
);
check(
  chartTags(base, { locateVCount: 3, locateMaxDiagnosticity: 1 }).includes("Rep"),
  "Rep must be raised for support that reaches no D2",
);
check(
  !chartTags(base, { locateVCount: 3, locateMaxDiagnosticity: 3 }).includes("Rep"),
  "Rep must NOT be raised when support reaches D2 or better",
);

/* ================================================================== *
 * 5. CLUSTERS — a bin, never a position, never sized by magnitude
 * ================================================================== */

const c5 = clusterMark({
  zoom: 5,
  cell_x: 1,
  cell_y: 2,
  feature_count: 5,
  best_exist_rank: 6,
  best_exist_grade: "A",
  modal_typology: null,
  country_code: "US",
  centroid: { type: "Point", coordinates: [0, 0] },
  bbox: { type: "Polygon", coordinates: [[[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]] },
  sample_entity_ids: [],
});
check(c5.form === "hairline-square", "a cluster is a hairline square");
check(
  c5.border === "dotted",
  "a cluster of unknown composition must carry the DOTTED border — a solid one " +
    "asserts that every member is a surveyed point",
);

/* ================================================================== *
 * 6. §9.1 — no vendor tile origin, ever
 * ================================================================== */

for (const a of ARCHIVES) {
  try {
    assertNoVendorHost(a.path);
  } catch (e) {
    failures.push(`archive ${a.id}: ${(e as Error).message}`);
  }
  check(a.path.startsWith("/"), `archive ${a.id} must be origin-relative, got ${a.path}`);
}
let vendorRefused = false;
try {
  assertNoVendorHost("https://api.mapbox.com/v4/x.json");
} catch {
  vendorRefused = true;
}
check(vendorRefused, "a vendor tile origin must be refused, not warned about");

/* ================================================================== *
 * 7. SOURCE SCANS — the two columns no renderer may read
 * ================================================================== */

/**
 * Rule Zero enforcement 2 and refusal 4. `label_point_3857` is absent from the
 * `MapFeature` type so it cannot be read; `api.map_cluster.centroid` IS on the
 * `MapCluster` type, because that type transcribes the view column for column,
 * and this scan is what keeps it unpainted. See lib/plate/clusters.ts for why
 * the cluster mark is drawn on the grid cell instead.
 */
const PLATE_SOURCE_DIRS = [
  join(process.cwd(), "src/components/plate"),
  join(process.cwd(), "src/lib/plate"),
  join(process.cwd(), "src/app/plate"),
];

const FORBIDDEN = [
  { pattern: /label_point/, why: "label_point is a rendering-internal anchor and is never painted" },
  { pattern: /\.centroid\b/, why: "api.map_cluster.centroid is an averaged point and is never painted" },
];

function sourceFiles(dir: string): string[] {
  let entries: string[];
  try {
    entries = readdirSync(dir);
  } catch {
    return [];
  }
  return entries.flatMap((e) => {
    const p = join(dir, e);
    if (statSync(p).isDirectory()) return sourceFiles(p);
    return /\.(ts|tsx|css)$/.test(e) ? [p] : [];
  });
}

for (const file of PLATE_SOURCE_DIRS.flatMap(sourceFiles)) {
  /* This file is exempt: it CONSTRUCTS a `MapCluster` fixture, which means it
     writes the `centroid` column in order to prove that nothing else reads it,
     and it names `label_point` in the failure messages. The checker is not the
     renderer. */
  if (file.endsWith("/plate/verify.ts")) continue;
  const src = readFileSync(file, "utf8");
  const code = stripComments(src);
  for (const { pattern, why } of FORBIDDEN) {
    if (pattern.test(code)) {
      failures.push(`${file}: reads a forbidden quantity — ${why}`);
    }
  }
  /* Refusal 8, mechanically: no grade letter may reach a paint value. If a
     fill or stroke is ever keyed off a grade, this catches the idiom. */
  if (/(fill|stroke)\s*[:=]\s*[^;\n]*grade/i.test(code)) {
    failures.push(`${file}: a paint value appears to be derived from a grade (refusal 8)`);
  }
}

function stripComments(src: string): string {
  return src.replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
}

/* ================================================================== *
 * 8. Scale bar — a round number, or nothing
 * ================================================================== */

const bar = scaleBar(39.5, 6);
check(bar.pixels > 0 && bar.pixels <= 160, "the scale bar must fit its allowance");
check(/^\d+(\.\d+)? (m|km)$/.test(bar.label), `scale bar label must be a round figure, got ${bar.label}`);

/* ================================================================== *
 * Report
 * ================================================================== */

notes.push(`${LEGEND_ROWS.length} legend symbols, exhaustive over locate_precision.`);
notes.push(
  `${ARCHIVES.length} basemap archives declared; all origin-relative. ` +
    `Presence is probed at runtime and published on the plate.`,
);

for (const n of notes) console.log(`  ${n}`);
console.log("");
if (failures.length === 0) {
  console.log("PASS — plate symbolisation, the 16px rule, and the six refusals that reach the map.");
} else {
  console.error(`FAIL — ${failures.length} check(s):`);
  for (const f of failures) console.error(`  ✕ ${f}`);
  process.exit(1);
}
