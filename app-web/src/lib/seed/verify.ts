/**
 * SEED VERIFICATION — the fixture's own acceptance suite.
 *
 * Run with `npm run seed:check`.
 *
 * This exists because a calibration fixture that has drifted from
 * `docs/CALIBRATION.md` is worse than no fixture: it publishes a wrong expected
 * value under a marker that says it is the right one. The checks below are the
 * ones that would catch that, plus the containment checks, plus the Rule Zero
 * checks — every mark traces to a row.
 *
 * It is not a test framework. It prints and exits non-zero.
 */

import {
  CASES,
  REGISTER_CLAIMS,
  REGISTER_ENTRIES,
  REGISTER_MAP_FEATURES,
  SPECIMENS,
  SPECIMEN_ENTITIES,
} from "./index";
import { GRADES, LOCATE_PRECISIONS } from "../types/enums";
import type { Grade, LocatePrecision } from "../types/enums";
import { gradeRank } from "../types/grade";
import { SeedRepository } from "../repository/seed-repository";

const failures: string[] = [];
const notes: string[] = [];

function check(ok: boolean, label: string) {
  if (!ok) failures.push(label);
}

/* ---------------------------------------------------------------- *
 * 1. Case coverage
 * ---------------------------------------------------------------- */

const facilityCases = CASES.filter((c) => c.marker !== "PIPELINE");
const pipelineCases = CASES.filter((c) => c.marker === "PIPELINE");

/**
 * A DISCREPANCY IN THE SOURCE DOCUMENT, RECORDED RATHER THAN RESOLVED SILENTLY.
 *
 * `docs/CALIBRATION.md` headlines "34 distinct cases" and its footer reads
 * "34 cases + 6 pipeline tests". Its SUMMARY TABLE, and its body, enumerate
 * FORTY-THREE case ids: A-01…A-18, B-01…B-06, C-01…C-02, D-01, E-01…E-03,
 * F-01…F-06, R-01…R-05, X-01…X-02.
 *
 * The two numbers are reconcilable: 43 is the count of case IDS, and 34 is the
 * count after collapsing the ids that are the same facility read from different
 * angles — Greenbrier alone carries five (A-05, B-05, C-02, D-01, E-02), and
 * Dulce, Montauk, SubTropolis, DUCC, Cheyenne Mountain, Mega Cavern, Fairview,
 * 33 Thomas and the Nike pair each carry two.
 *
 * THE SEED TRANSCRIBES ALL 43, because each has its own section with its own
 * expected value, its own marker and its own assertions, and dropping nine of
 * them would drop nine expected values. `/calibration` publishes both counts.
 */
check(facilityCases.length === 43, `43 case ids, found ${facilityCases.length}`);
check(pipelineCases.length === 6, `6 pipeline tests, found ${pipelineCases.length}`);

const distinctEntities = new Set(
  facilityCases.map((c) => c.entity_slug).filter(Boolean),
).size;
notes.push(
  `cases: ${facilityCases.length} case ids + ${pipelineCases.length} pipeline tests, over ${distinctEntities} distinct entities`,
);

const slugs = new Set(SPECIMEN_ENTITIES.map((e) => e.slug));
for (const c of CASES) {
  if (!c.entity_slug) continue;
  check(slugs.has(c.entity_slug), `${c.case_id}: unknown entity ${c.entity_slug}`);
  const e = SPECIMEN_ENTITIES.find((x) => x.slug === c.entity_slug);
  for (const ref of c.proposition_refs ?? []) {
    check(
      Boolean(e?.propositions.some((p) => p.ref === ref)),
      `${c.case_id}: ${c.entity_slug} has no proposition ${ref}`,
    );
  }
}

/* ---------------------------------------------------------------- *
 * 2. Band and precision coverage — every visual state must be exercised
 * ---------------------------------------------------------------- */

const seenGrades = new Set<Grade>();
const seenPrecisions = new Set<LocatePrecision>();
for (const e of SPECIMEN_ENTITIES) {
  seenPrecisions.add(e.geometry.precision);
  for (const p of e.propositions) seenGrades.add(p.grade);
}
for (const g of GRADES) check(seenGrades.has(g), `no proposition at grade ${g}`);
for (const lp of LOCATE_PRECISIONS) {
  check(seenPrecisions.has(lp), `no entity with locate_precision ${lp}`);
}
notes.push(`grades exercised: ${[...seenGrades].sort().join(" ")}`);
notes.push(`precisions exercised: ${seenPrecisions.size}/${LOCATE_PRECISIONS.length}`);

/* ---------------------------------------------------------------- *
 * 3. RULE ZERO — no mark without a row.
 * Every count on a badge must equal the rows it is counted from.
 * ---------------------------------------------------------------- */

let propositions = 0;
let observations = 0;
const membershipTally = { V: 0, U: 0, INERT: 0, V0: 0 };

for (const sheet of SPECIMENS) {
  if (!sheet.detail) continue;
  for (const p of sheet.detail.propositions) {
    const v = p.evidence.filter((r) => r.membership === "V");
    const u = p.evidence.filter((r) => r.membership === "U");
    check(p.v_count === v.length, `${p.entity_slug}/${p.class}: v_count drift`);
    check(p.u_count === u.length, `${p.entity_slug}/${p.class}: u_count drift`);
    check(
      p.v_claim_count === v.filter((r) => r.property_locus === "CLAIM-PROPERTY").length,
      `${p.entity_slug}/${p.class}: v_claim_count drift`,
    );
    check(
      p.claim_derived_weight ===
        v
          .filter((r) => r.property_locus === "CLAIM-PROPERTY")
          .reduce((a, r) => a + r.magnitude, 0),
      `${p.entity_slug}/${p.class}: claim_derived_weight drift`,
    );
    /* SCI §7.2: an empty denominator is 1.000, never 0. */
    if (p.sci_denominator === 0) {
      check(p.sci === 1, `${p.entity_slug}/${p.class}: empty denominator must be 1.000`);
    }
    /* A published grade must carry a rank iff it is ranked. */
    check(
      p.grade_rank === gradeRank(p.grade),
      `${p.entity_slug}/${p.class}: grade_rank disagrees with the grade`,
    );
  }
}

for (const sheet of SPECIMENS) {
  if (!sheet.detail) continue;
  propositions += sheet.detail.propositions.length;
  for (const p of sheet.detail.propositions) {
    observations += p.evidence.length;
    for (const r of p.evidence) membershipTally[r.membership] += 1;
  }
}
notes.push(
  `built (with duplicates across cases sharing an entity): ${propositions} propositions, ${observations} observations`,
);
notes.push(
  `membership: V ${membershipTally.V} · U ${membershipTally.U} · INERT ${membershipTally.INERT} · V0 ${membershipTally.V0}`,
);
for (const m of ["V", "U", "INERT", "V0"] as const) {
  check(membershipTally[m] > 0, `no observation lands in membership ${m}`);
}

/* ---------------------------------------------------------------- *
 * 4. Named calibration assertions
 * ---------------------------------------------------------------- */

const ravenRock = SPECIMENS.find((s) => s.case.case_id === "A-02")!.detail!;
const rrFunction = ravenRock.propositions.find((p) => p.class === "FUNCTION")!;
/* S-4 / A-02: the PLACE-DERIVED bar must be ZERO for the FUNCTION claim. */
check(
  rrFunction.place_derived_weight === 0,
  "A-02 S-4: FUNCTION must show zero place-derived weight",
);

const mountPony = SPECIMENS.find((s) => s.case.case_id === "A-09")!.detail!;
check(
  mountPony.propositions.every((p) => p.sci === 1 && p.sci_denominator === 0),
  "A-09: SCI must be 1.000 on an empty denominator",
);

const greenbrier = SPECIMENS.find((s) => s.case.case_id === "B-05")!.detail!;
const bands = new Set(greenbrier.propositions.map((p) => p.grade));
check(
  ["B", "C", "D", "E"].every((g) => bands.has(g as Grade)),
  "B-05/C-02/D-01/E-02: one entity must decompose across B, C, D and E",
);
const gbControl = greenbrier.propositions.find((p) => p.class === "CONTROL")!;
check(
  gbControl.applied_caps.includes("CAP-2b"),
  "D-01: CAP-2b must appear in applied_caps even though it did not bind",
);
const gbFunction = greenbrier.propositions.find((p) => p.class === "FUNCTION")!;
check(
  gbFunction.v_claim_count === 0,
  "E-02: CAP-2b binding requires |V[claim]| = 0 — the upper storey must be empty",
);

const dia = SPECIMENS.find((s) => s.case.case_id === "E-01")!.detail!;
const diaFn = dia.propositions.find((p) => p.class === "FUNCTION")!;
check(diaFn.grade === "E", "E-01: DIA FUNCTION must be E");
check(diaFn.refutation_state === "R0", "E-01: refutation must NOT fire");
check(diaFn.v_count > 0, "E-01: V must be NON-EMPTY — that is what makes it E, not F");
check(diaFn.v_claim_count === 0, "E-01: |V[claim]| must be 0");

const montauk = SPECIMENS.find((s) => s.case.case_id === "F-01")!.detail!;
const mtkFn = montauk.propositions.find((p) => p.class === "FUNCTION")!;
check(mtkFn.grade === "F", "F-01: Montauk FUNCTION must be F");
check(mtkFn.v_count === 0, "S-2 (the E/F line): Montauk's V must be EMPTY");
const mtkOrigin = montauk.propositions.find((p) => p.class === "ORIGIN")!;
check(mtkOrigin.grade === "A", "A-13: the ORIG A / FUNC F pair");

const dulce = SPECIMENS.find((s) => s.case.case_id === "R-05")!.detail!;
check(
  dulce.propositions.find((p) => p.class === "EXIST")!.grade === "R",
  "R-05: Dulce EXIST must be R",
);
check(
  dulce.propositions.find((p) => p.class === "ORIGIN")!.grade === "A",
  "A-12: Dulce ORIGIN must be A, below the unclamped rule",
);

const cardinal = SPECIMENS.find((s) => s.case.case_id === "F-05")!;
const cardinalExist = cardinal.detail!.propositions.find((p) => p.class === "EXIST")!;
check(cardinalExist.v0_count === 5, `F-05: five retained V0 identifiers, found ${cardinalExist.v0_count}`);
check(cardinalExist.v_count === 0, "F-05: V must be empty");
/* The canary is NEVER PUBLISHABLE and never a map feature. */
check(cardinal.locator === null, "F-05/P-02: a canary must never produce a map feature");

const sauder = SPECIMENS.find((s) => s.case.case_id === "F-03")!.detail!;
const sauderProgram = sauder.propositions.find((p) => p.class === "PROGRAM")!;
check(
  sauderProgram.grade === "F" && sauderProgram.refutation_state === "R0",
  "F-03 §8.4: F (SILENCE-DOMINATED) with refutation_state R0 — R on negatives alone is forbidden",
);
check(sauderProgram.u_count >= 3, "F-03: the expected-record negatives must be present as UNDERCUTS rows");

const subtropolis = SPECIMENS.find((s) => s.case.case_id === "R-02")!.detail!;
const stHarden = subtropolis.propositions.find((p) => p.class === "HARDEN")!;
check(stHarden.grade === "R" && stHarden.refutation_state === "R2", "R-02: R via R2");
check(
  stHarden.u_count >= 2,
  "R-02: R2 requires >= 2 independent-lineage verified UNDERCUTS rows",
);
check(
  stHarden.applied_caps.includes("CAP-2b"),
  "R-02: the second route (CAP-2b at E) must be recorded",
);

const fairview = SPECIMENS.find((s) => s.case.case_id === "B-01")!.detail!;
const fvHarden = fairview.propositions.find((p) => p.class === "HARDEN")!;
check(fvHarden.grade === "B", "B-01: Fairview HARDEN must be B");
/* S-1: four bands, in the correct direction. R is unranked, so the check is
   that the real bunker is on the ranked ladder and the warehouse is off it,
   refuted — which is the separation the pair exists to assert. */
check(
  gradeRank(fvHarden.grade) !== null && gradeRank(stHarden.grade) === null,
  "S-1: the real bunker must be on the ranked ladder and the warehouse refuted off it",
);

const arc = SPECIMENS.find((s) => s.case.case_id === "C-01")!.detail!;
check(arc.entity.representation === "region_polygon", "C-01: a region, NEVER a pin");
check(arc.entity.geometry?.type === "Polygon", "C-01: the emitted geometry must be an area");

/* ---------------------------------------------------------------- *
 * 5. Geometry — the hard gate in core.render_geometry()
 * ---------------------------------------------------------------- */

for (const sheet of SPECIMENS) {
  const d = sheet.detail;
  if (!d) continue;
  const locate = d.propositions.find((p) => p.class === "LOCATE");
  const rank = locate ? gradeRank(locate.grade) : null;

  if (d.entity.representation === "point") {
    check(
      d.entity.locate_precision === "surveyed" ||
        d.entity.locate_precision === "approximate_1km",
      `${d.entity.slug}: a point requires a precise assertion`,
    );
    check(
      rank !== null && rank >= gradeRank("C")!,
      `${d.entity.slug}: a point requires LOCATE at band C or better`,
    );
  }
  if (
    d.entity.locate_precision === "place_name_only" ||
    d.entity.locate_precision === "non_located"
  ) {
    check(
      d.entity.representation === "none" && d.entity.geometry === null,
      `${d.entity.slug}: place_name_only / non_located must emit NO geometry`,
    );
  }
  /* Nothing below band D is on the plate (BES §10.3). */
  if (sheet.locator) {
    check(
      sheet.locator.exist_rank !== null &&
        sheet.locator.exist_rank >= gradeRank("D")!,
      `${d.entity.slug}: a locator below band D must not be drawn`,
    );
  }
}

/* ---------------------------------------------------------------- *
 * 6. CONTAINMENT — the six mechanisms
 * ---------------------------------------------------------------- */

for (const s of SPECIMENS) {
  check(s.containment.href.startsWith("/calibration/"), `${s.case.case_id}: wrong namespace`);
  check(s.containment.robots === "noindex, nofollow", `${s.case.case_id}: robots`);
  check(
    s.containment.header_rule.includes("SPECIMEN") &&
      s.containment.header_rule.includes("not a register entry"),
    `${s.case.case_id}: header rule`,
  );
  check(s.containment.hatched_margin === true, `${s.case.case_id}: hatched margin`);
  check(
    s.containment.aria_prefix.toLowerCase().includes("specimen"),
    `${s.case.case_id}: aria prefix`,
  );
  check(
    s.detail === null || s.detail.provenance_beacon === null,
    `${s.case.case_id}: NO PROVENANCE BEACON is emitted for a specimen`,
  );
}

/* The register surface is empty BY CONSTRUCTION, not by a flag. */
check(REGISTER_ENTRIES.length === 0, "register entries must be empty");
check(REGISTER_CLAIMS.length === 0, "register claims must be empty");
check(REGISTER_MAP_FEATURES.length === 0, "register map features must be empty");

async function checkRepositoryBoundary() {
  const repo = new SeedRepository();
  const leaked: string[] = [];
  await Promise.all(
    [...slugs].map(async (slug) => {
      if ((await repo.getEntry(slug)) !== null) leaked.push(slug);
    }),
  );
  check(
    leaked.length === 0,
    `SPECIMEN LEAK: /e/${leaked[0] ?? ""} served a fixture at a register URL`,
  );
  check((await repo.listRegister()).length === 0, "listRegister must return 0 rows");
  check((await repo.listClaims()).length === 0, "listClaims must return 0 rows");
  check(
    (await repo.getBandOccupancy()).length === 0,
    "specimens must not enter telemetry",
  );
  check((await repo.listCalibration()).length === CASES.length, "calibration surface");
}

/* ---------------------------------------------------------------- *
 * Report
 * ---------------------------------------------------------------- */

async function main() {
  await checkRepositoryBoundary();

  for (const n of notes) console.log(`  ${n}`);
  console.log("");
  if (failures.length === 0) {
    console.log(
      `PASS — ${CASES.length} cases, ${SPECIMEN_ENTITIES.length} specimen entities.`,
    );
  } else {
    console.error(`FAIL — ${failures.length} check(s):`);
    for (const f of failures) console.error(`  ✕ ${f}`);
    process.exit(1);
  }
}

void main();
