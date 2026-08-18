/**
 * SPECIMEN ENTITIES — the acknowledged and documented facilities.
 *
 * CALIBRATION CASES A-01 … A-18, B-01 … B-04, B-06, C-01, E-03, R-01, X-02, P-06.
 *
 * SPECIMEN DATA. These are calibration fixtures, not register entries. Every
 * quoted span below is a PLAUSIBLE RECONSTRUCTION written for this fixture, not
 * a verbatim transcription of a retrieved document — the register has resolved
 * no citation to bytes (D-007), so it possesses no verbatim spans yet. The
 * facts, dates and grades are transcribed from `docs/CALIBRATION.md`; the
 * document identifiers are illustrative of their grammar and are NOT asserted
 * to resolve. Containment is enforced in `index.ts` and at the repository
 * boundary, not by this comment.
 */

import type { SpecEntity } from "../types";
import { ev, notFound, ok } from "../dsl";

/* ================================================================== *
 * A-01 / R-01 · Cheyenne Mountain Complex, CO
 * One entity, simultaneously A and R. Any rubric returning one number
 * for this site fails the entry by construction.
 * ================================================================== */

const cheyenneMountain: SpecEntity = {
  slug: "cheyenne-mountain-complex",
  name: "Cheyenne Mountain Complex",
  entity_level: "site",
  jurisdiction: "El Paso County, Colorado",
  typology: "military-hardened",
  reference_class: "RC1",
  reference_class_basis: "Inside an active DoD installation boundary (PAD-US).",
  aliases: ["Cheyenne Mountain Air Force Station", "CMAFS", "NORAD Combat Operations Center"],
  geometry: { precision: "surveyed", point: [-104.8458, 38.7443] },
  propositions: [
    {
      ref: "p-EXIST-1",
      class: "EXIST",
      statement:
        "A substantial hardened subsurface complex exists within Cheyenne Mountain.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      applied_caps: [],
      null_code: "A02",
      null_label: "commercial mine or cavern",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "COMMON",
      reference_class: "RC1",
      sci: [7, 7],
      l_d2: 6,
      l_d3: 6,
      condition_results: { A1: true, A2: true, A3: true, A4: true, A5: true, A6: true },
      observations: [
        ev("e1", "Army Corps of Engineers construction record for the excavation and the granite chamber system.", {
          d: 4, tier: "T1", doc: "Corps of Engineers construction completion report, NORAD Combat Operations Center",
          issuer: "U.S. Army Corps of Engineers", date: "1966-04-20", ident: "AD-0489113", identClass: "DTIC",
          authority: true, lineage: "L1",
          quote: ["excavation of the chamber complex within the granite of Cheyenne Mountain was completed", 8140, 8232],
        }),
        ev("e2", "Congressional appropriations line naming the complex and its construction authority.", {
          d: 4, tier: "T1", doc: "Military Construction Appropriations hearings, FY1962", issuer: "U.S. Congress",
          date: "1961-06-14", ident: "CHRG-87hhrg-milcon-1962", identClass: "GovInfo", authority: true, lineage: "L2",
          quote: ["combat operations center, Cheyenne Mountain, Colorado", 22110, 22164],
        }),
        ev("e3", "GAO review of the complex's operating cost and readiness posture.", {
          d: 3, tier: "T1", doc: "GAO review of NORAD command and control facilities", issuer: "Government Accountability Office",
          date: "1994-03-01", ident: "GAO/NSIAD-94-118", identClass: "GAO", lineage: "L3",
        }),
        ev("e4", "DTIC technical report describing the shock-isolated building system.", {
          d: 3, tier: "T1", doc: "Shock isolation of structures within the Cheyenne Mountain complex",
          issuer: "Defense Technical Information Center", date: "1970-11-01", ident: "AD-0716244", identClass: "DTIC", lineage: "L4",
        }),
        ev("e5", "Published DoD photography of the blast doors and interior buildings.", {
          d: 3, tier: "T1", doc: "Defense Visual Information Distribution Service imagery set", issuer: "U.S. Department of Defense",
          date: "2015-05-11", lineage: "L5",
        }),
        ev("e6", "Named personnel records placing thousands of service members at the facility.", {
          d: 3, tier: "T1", doc: "AFHRA unit history, 21st Space Wing", issuer: "Air Force Historical Research Agency",
          date: "1998-01-01", ident: "IRIS 01084415", identClass: "AFHRA", lineage: "L6",
        }),
        ev("e7", "Portal and spoil terrain visible on USGS orthoimagery.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "USGS high-resolution orthoimagery, El Paso County",
          issuer: "U.S. Geological Survey", date: "2021-08-01", lineage: "L1",
        }),
      ],
      alternatives: [
        { null_code: "A02", label: "commercial mine or cavern", description: "Commercial or industrial mine, quarry, or cavern warehouse", disposition: "EXCLUDED", reasoning: "A quarry has no CATCODE, no shock-isolation report and no appropriations line naming a combat operations center.", excluding: ["e1", "e2"] },
      ],
      searches: [
        { query: "\"Cheyenne Mountain\" combat operations center construction", corpus_as_of: "2026-07-01", outcome: "POSITIVE", result_count: 41, erp_profile: "MILCON/DD-1391" },
        { query: "NORAD Cheyenne Mountain GAO report", corpus_as_of: "2026-07-01", outcome: "POSITIVE", result_count: 12 },
      ],
      movement: [{ occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "A", cause: "INITIAL", note: "Initial canonical search set." }],
    },
    {
      ref: "p-LOCATE-1",
      class: "LOCATE",
      statement: "The complex portal is located at the surveyed coordinate given, to within 30 m.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A01",
      null_label: "no constructed object",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      sci: [4, 4],
      l_d2: 3,
      l_d3: 3,
      observations: [
        ev("e1", "USGS control-point match against the published portal structure.", {
          d: 4, tier: "T1", doc: "USGS 7.5-minute quadrangle, Cheyenne Mountain, CO", issuer: "U.S. Geological Survey",
          date: "1994-01-01", authority: true, lineage: "L1",
          quote: ["portal, Cheyenne Mountain Complex", 512, 543],
        }),
        ev("e2", "Federal real property inventory record carrying the parcel geometry.", {
          d: 3, tier: "T1", doc: "Federal Real Property Profile record", issuer: "General Services Administration",
          date: "2019-09-30", lineage: "L2",
        }),
      ],
    },
    {
      ref: "p-TYPOLOGY-1",
      class: "TYPOLOGY",
      statement: "The facility is a hardened military command installation.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A12",
      null_label: "other known typology",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      sci: [3, 3],
      l_d2: 3,
      l_d3: 2,
      observations: [
        ev("e1", "DoD facility CATCODE assignment for a hardened command centre.", {
          d: 4, tier: "T1", doc: "DoD Real Property Category Code assignment", issuer: "U.S. Department of Defense",
          date: "1990-01-01", authority: true, lineage: "L1",
          quote: ["CATCODE 141 — command and control facility, hardened", 1210, 1262],
        }),
      ],
    },
    {
      ref: "p-STATUS-1",
      class: "STATUS",
      statement:
        "The complex is the current headquarters of NORAD and USNORTHCOM.",
      grade: "R",
      refutation_state: "R3",
      ceiling_reason:
        "R3 — verified, instance-scope, subject-bound, unsolicited DoD records from a party with authority over the fact directly state the negation. NORAD/USNORTHCOM operations consolidated at Peterson AFB in 2006 and the complex moved to alternate/warm-standby status. The claim is stale rather than invented.",
      null_code: "A12",
      null_label: "other known typology",
      null_state: "DOMINANT",
      silence_reading: "INFORMATIVE",
      sci: [5, 5],
      l_d2: 3,
      l_d3: 2,
      predicate_args: {
        claim_text: "Cheyenne Mountain is the current NORAD headquarters.",
        first_appearance_date: "1966-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "DoD announcement of the 2006 consolidation of NORAD operations at Peterson AFB.", {
          d: 4, sign: "UNDERCUTS", tier: "T1", doc: "NORAD/USNORTHCOM realignment announcement",
          issuer: "U.S. Department of Defense", date: "2006-07-28", authority: true, refutes: "R3", lineage: "U1",
          quote: ["day-to-day operations have moved to Peterson Air Force Base; Cheyenne Mountain is maintained on warm standby", 3020, 3128],
        }),
        ev("e2", "Air Force fact sheet describing the complex's alternate-command-center role.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Cheyenne Mountain Air Force Station fact sheet",
          issuer: "U.S. Air Force", date: "2018-03-01", refutes: "R3", lineage: "U2",
        }),
      ],
      alternatives: [
        { null_code: "A12", label: "other known typology", description: "Decommissioned facility of a different, already-known typology", disposition: "DOMINANT", reasoning: "The complex remains a hardened alternate command centre; the headquarters function moved. The alternative accounts for every row.", excluding: [] },
      ],
      movement: [
        { occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "C", cause: "INITIAL" },
        { occurred_at: "2026-05-19T00:00:00Z", from: "C", to: "R", cause: "REFUTATION", note: "R3 established on the 2006 realignment record." },
      ],
    },
  ],
  notes: [
    "A-01 and R-01 on one page: EXIST A and STATUS R, and the R does not clamp the EXIST.",
  ],
};

/* ================================================================== *
 * A-02 · Raven Rock Mountain Complex (Site R) — the flagship
 * Seven propositions at A. The proposition detail block printed in
 * DESIGN.md §13.2 is this entity's p-EXIST-1, so the counts below are
 * the ones that block prints: 14 observations, 2 inert, |V[claim]| = 6.
 * ================================================================== */

const ravenRock: SpecEntity = {
  slug: "raven-rock-site-r",
  name: "Raven Rock Mountain Complex (Site R)",
  entity_level: "site",
  jurisdiction: "Adams County, Pennsylvania",
  typology: "cog-coop",
  reference_class: "RC1",
  reference_class_basis: "Inside an active DoD installation boundary (PAD-US).",
  aliases: ["Site R", "Raven Rock", "Alternate Joint Communications Center", "AJCC"],
  former_designations: ["Alternate National Military Command Center (relocation site)"],
  geometry: { precision: "surveyed", point: [-77.4267, 39.7342], radius_m: 30 },
  propositions: [
    {
      ref: "p-EXIST-1",
      class: "EXIST",
      statement:
        "A substantial artificial enclosed or subsurface structure exists at Raven Rock.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      ceiling_reason: "At ceiling: the highest band the evidence route can reach.",
      applied_caps: [],
      null_code: "A02",
      null_label: "commercial mine or cavern",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "COMMON",
      reference_class: "RC1",
      sci: [6, 6],
      l_d2: 5,
      l_d3: 5,
      condition_results: { A1: true, A2: true, A3: true, A4: true, A5: true, A6: true },
      observations: [
        ev("e1", "MILCON J-book line carrying the project number and the facility CATCODE.", {
          d: 4, tier: "T1", doc: "Military Construction Program (J-book), project listing", issuer: "U.S. Department of Defense",
          date: "1988-02-01", ident: "DD-1391 PN 41221", identClass: "MILCON", authority: true, lineage: "L1",
          quote: ["Alternate Joint Communications Center, Raven Rock, Pennsylvania — CATCODE 141", 14020, 14094],
          fact: "a federal hardened facility exists at Raven Rock",
        }),
        ev("e2", "DoD acknowledgment with a corresponding Base Structure Report entry.", {
          d: 4, tier: "T1", doc: "Base Structure Report, DoD real property inventory", issuer: "U.S. Department of Defense",
          date: "2010-09-30", identClass: "BSR", authority: true, lineage: "L1",
          quote: ["Raven Rock Mountain Complex, Adams County, PA", 8801, 8846],
          fact: "a federal hardened facility exists at Raven Rock",
        }),
        ev("e3", "NEPA environmental impact statement describing the hardened structure and its blast scope.", {
          d: 3, tier: "T1", doc: "Environmental Impact Statement, facility modernization", issuer: "U.S. Department of Defense",
          date: "2004-06-01", lineage: "L2",
        }),
        ev("e4", "GAO report on continuity-of-operations facility readiness naming the site.", {
          d: 3, tier: "T1", doc: "GAO report on continuity of operations facilities", issuer: "Government Accountability Office",
          date: "2004-04-01", ident: "GAO-04-160", identClass: "GAO", lineage: "L3",
        }),
        ev("e5", "DoD Inspector General audit referencing the installation by name.", {
          d: 3, tier: "T1", doc: "DoD Inspector General audit report", issuer: "DoD Office of Inspector General",
          date: "2011-02-14", lineage: "L3",
        }),
        ev("e6", "AFHRA unit history retrieved by IRIS number placing a unit at the complex.", {
          d: 3, tier: "T1", doc: "Unit history, communications squadron", issuer: "Air Force Historical Research Agency",
          date: "1972-06-30", ident: "IRIS 00489121", identClass: "AFHRA", lineage: "L4",
        }),
        ev("e7", "Adams County recorded deed for the federal parcel acquisition.", {
          d: 2, locus: "PLACE-PROPERTY", tier: "T1", doc: "Adams County recorder, deed of conveyance",
          issuer: "Adams County, Pennsylvania", date: "1951-11-02", lineage: "L5",
        }),
        ev("e8", "USACE construction records for the excavation contract.", {
          d: 3, locus: "PLACE-PROPERTY", tier: "T1", doc: "Corps of Engineers construction record",
          issuer: "U.S. Army Corps of Engineers", date: "1953-01-01", lineage: "L5",
        }),
        ev("e9", "Portal structures visible on public orthoimagery.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "USGS orthoimagery, Adams County",
          issuer: "U.S. Geological Survey", date: "2020-05-01", lineage: "L5",
        }),
        ev("e10", "Spoil terrace consistent with a large excavation, on the 1953 quadrangle.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "Historical topographic map, 7.5-minute series",
          issuer: "U.S. Geological Survey", date: "1953-01-01", lineage: "L5",
        }),
        ev("e11", "Dedicated substation and transmission spur in the utility record.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "State utility commission filing",
          issuer: "Pennsylvania Public Utility Commission", date: "1962-01-01", lineage: "L5",
        }),
        ev("e12", "Restricted airspace designation over the ridge.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "FAA special use airspace designation",
          issuer: "Federal Aviation Administration", date: "1960-01-01", lineage: "L4",
        }),
        ev("e13", "Encyclopedia article summarising the site's history.", {
          d: 2, tier: "T4", doc: "Encyclopedia article, \"Raven Rock Mountain Complex\"", channel: "ADVERSARY-WRITABLE",
          provenance: "CROWD-EDITED", adversary: true, date: "2019-04-02", lineage: "L6",
        }),
        ev("e14", "Aggregator facility page compiled from the sources above.", {
          d: 2, tier: "T4", doc: "globalsecurity.org facility page", channel: "AGGREGATOR",
          provenance: "SELF-PUBLISHED", date: "2003-08-01", lineage: "L6",
        }),
      ],
      alternatives: [
        { null_code: "A02", label: "commercial mine or cavern", description: "Commercial or industrial mine, quarry, or cavern warehouse", disposition: "EXCLUDED", reasoning: "An ordinary Army communications station, or a granite quarry — EXCLUDED. A quarry has no CATCODE and no EIS blast scope.", excluding: ["e1", "e3"] },
        { null_code: "A08", label: "ordinary government building", description: "Ordinary above-ground government building", disposition: "EXCLUDED", reasoning: "The EIS describes a subsurface structure with a blast scope.", excluding: ["e3"] },
      ],
      silence: [
        { record_class: "MILCON/DD-1391", expected_record_level: "X3", searched: true, outcome: "POSITIVE", result_count: 3, receipt: "sha256 4f2a…9c1" },
        { record_class: "NEPA documentation", expected_record_level: "X2", searched: true, outcome: "POSITIVE", result_count: 1, receipt: "sha256 91bd…07e" },
        { record_class: "GAO/DoD-IG oversight", expected_record_level: "X2", searched: true, outcome: "POSITIVE", result_count: 2, receipt: "sha256 3c10…aa4" },
      ],
      searches: [
        { query: "\"Raven Rock\" OR \"Site R\" military construction CATCODE", corpus_as_of: "2026-07-01", outcome: "POSITIVE", result_count: 9, erp_profile: "MILCON/DD-1391" },
        { query: "\"Alternate Joint Communications Center\" environmental impact", corpus_as_of: "2026-07-01", outcome: "POSITIVE", result_count: 4, erp_profile: "NEPA" },
        { query: "Raven Rock GAO continuity of operations", corpus_as_of: "2026-07-01", outcome: "POSITIVE", result_count: 2 },
      ],
      lineage: {
        document_count: 8,
        lineage_count: 5,
        verdict:
          "8 citing documents · 5 independent lineages · collapse delta 3. The proposition rests on five separate witnesses, two of them at the issuing authority.",
        blocks: [
          {
            origin: { siglum: "L1", label: "MILCON J-book line, PN 41221", document_date: "1988-02-01", origin_tier: "T1" },
            descendants: [{ siglum: "L1b", label: "Base Structure Report entry — same issuer, §5.1.1", document_date: "2010-09-30", origin_tier: "T1", collapses: true }],
            downstream_count: 1,
          },
          { origin: { siglum: "L2", label: "Environmental Impact Statement", document_date: "2004-06-01", origin_tier: "T1" }, downstream_count: 0 },
          { origin: { siglum: "L3", label: "GAO and DoD-IG reports", document_date: "2004-04-01", origin_tier: "T1" }, downstream_count: 1 },
          { origin: { siglum: "L4", label: "AFHRA unit history, IRIS 00489121", document_date: "1972-06-30", origin_tier: "T1" }, downstream_count: 0 },
          { origin: { siglum: "L5", label: "County deed and USACE construction records", document_date: "1951-11-02", origin_tier: "T1" }, downstream_count: 0 },
        ],
      },
      movement: [{ occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "A", cause: "INITIAL" }],
    },
    {
      ref: "p-LOCATE-1",
      class: "LOCATE",
      statement: "The installation is located at the surveyed coordinate given, to within 30 m.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A01",
      null_label: "no constructed object",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      sci: [3, 3],
      l_d2: 3,
      l_d3: 2,
      observations: [
        ev("e1", "Federal parcel geometry from the recorded deed, matched to a public control point.", {
          d: 4, tier: "T1", doc: "Adams County parcel geometry", issuer: "Adams County, Pennsylvania",
          date: "1951-11-02", authority: true, lineage: "L1",
          quote: ["beginning at the survey monument on the ridge line", 220, 268],
        }),
      ],
    },
    {
      ref: "p-EXTENT-1",
      class: "EXTENT",
      statement: "The complex comprises multiple free-standing buildings within an excavated chamber system.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A02",
      null_label: "commercial mine or cavern",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      sci: [3, 3],
      l_d2: 3,
      l_d3: 2,
      observations: [
        ev("e1", "EIS describing the chamber system and the buildings it contains.", {
          d: 4, tier: "T1", doc: "Environmental Impact Statement, facility modernization", issuer: "U.S. Department of Defense",
          date: "2004-06-01", authority: true, lineage: "L1",
          quote: ["free-standing structures on shock isolators within the excavated chambers", 22400, 22473],
        }),
      ],
    },
    {
      ref: "p-TYPOLOGY-1",
      class: "TYPOLOGY",
      statement: "The facility is a continuity-of-government / continuity-of-operations installation.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A12",
      null_label: "other known typology",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      sci: [3, 3],
      l_d2: 3,
      l_d3: 2,
      observations: [
        ev("e1", "GAO report classifying the site among continuity-of-operations facilities.", {
          d: 4, tier: "T1", doc: "GAO report on continuity of operations facilities", issuer: "Government Accountability Office",
          date: "2004-04-01", ident: "GAO-04-160", identClass: "GAO", authority: true, lineage: "L1",
          quote: ["among the department's alternate command and continuity facilities", 4110, 4172],
        }),
      ],
    },
    {
      ref: "p-HARDEN-1",
      class: "HARDEN",
      statement: "The structure is engineered to resist blast and shock loading.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A07",
      null_label: "unhardened data centre",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "UNCOMMON",
      sci: [4, 4],
      l_d2: 4,
      l_d3: 3,
      observations: [
        ev("e1", "EIS blast scope and shock-isolation description.", {
          d: 4, tier: "T1", doc: "Environmental Impact Statement, facility modernization", issuer: "U.S. Department of Defense",
          date: "2004-06-01", authority: true, lineage: "L1",
          quote: ["structures are mounted on shock isolation systems designed against overpressure loading", 22510, 22599],
        }),
        ev("e2", "Design-standard citation in the construction record.", {
          d: 3, tier: "T1", doc: "Corps of Engineers design memorandum", issuer: "U.S. Army Corps of Engineers",
          date: "1953-06-01", lineage: "L2",
        }),
      ],
    },
    {
      ref: "p-CONTROL-1",
      class: "CONTROL",
      statement: "The installation is owned and operated by the U.S. Department of Defense.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A08",
      null_label: "ordinary government building",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "COMMON",
      sci: [4, 4],
      l_d2: 4,
      l_d3: 3,
      observations: [
        ev("e1", "Base Structure Report entry listing the installation under DoD ownership.", {
          d: 4, tier: "T1", doc: "Base Structure Report", issuer: "U.S. Department of Defense", date: "2010-09-30",
          authority: true, lineage: "L1", quote: ["owned, active, Department of Defense", 8850, 8886],
        }),
        ev("e2", "Recorded deed conveying the parcel to the United States.", {
          d: 3, tier: "T1", doc: "Adams County recorder, deed of conveyance", issuer: "Adams County, Pennsylvania",
          date: "1951-11-02", lineage: "L2",
        }),
      ],
    },
    {
      ref: "p-FUNCTION-1",
      class: "FUNCTION",
      statement:
        "The installation serves an alternate joint military command and continuity function.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A08",
      null_label: "ordinary government building",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "RARE",
      reference_class: "RC1",
      sci: [5, 5],
      l_d2: 4,
      l_d3: 4,
      /**
       * SUITE ASSERTION S-4 and CALIBRATION A-02: the PLACE-DERIVED bar must be
       * ZERO for this claim. Portals, terrain and spoil contribute nothing; the
       * CLAIM-DERIVED bar carries all of it. Every row below is CLAIM-PROPERTY,
       * so `place_derived_weight` counts to 0 — a pass that shows place-derived
       * weight on FUNCTION is a failing pass, and here it cannot show any.
       */
      observations: [
        ev("e1", "DoD designation of the site as the Alternate Joint Communications Center.", {
          d: 4, tier: "T1", doc: "Joint Staff designation memorandum", issuer: "Joint Chiefs of Staff",
          date: "1962-01-01", authority: true, lineage: "L1",
          quote: ["designated the Alternate Joint Communications Center", 1180, 1231],
        }),
        ev("e2", "GAO continuity-of-operations report describing the function.", {
          d: 3, tier: "T1", doc: "GAO report on continuity of operations facilities", issuer: "Government Accountability Office",
          date: "2004-04-01", ident: "GAO-04-160", identClass: "GAO", lineage: "L2",
        }),
        ev("e3", "AFHRA unit history describing the mission of the resident squadron.", {
          d: 3, tier: "T1", doc: "Unit history, communications squadron", issuer: "Air Force Historical Research Agency",
          date: "1972-06-30", ident: "IRIS 00489121", identClass: "AFHRA", lineage: "L3",
        }),
        ev("e4", "DoD-IG audit describing the continuity mission it audited.", {
          d: 3, tier: "T1", doc: "DoD Inspector General audit report", issuer: "DoD Office of Inspector General",
          date: "2011-02-14", lineage: "L4",
        }),
      ],
    },
    {
      ref: "p-STATUS-1",
      class: "STATUS",
      statement: "The installation is active.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A12",
      null_label: "other known typology",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      sci: [3, 3],
      l_d2: 3,
      l_d3: 2,
      predicate_args: { status: "active" },
      observations: [
        ev("e1", "Current-year Base Structure Report entry listing the installation as active.", {
          d: 4, tier: "T1", doc: "Base Structure Report", issuer: "U.S. Department of Defense", date: "2023-09-30",
          authority: true, lineage: "L1", quote: ["status: active", 9100, 9114],
        }),
      ],
    },
  ],
};

/* ================================================================== *
 * A-03 / B-06 · 33 Thomas Street, Manhattan — the urban test
 * ================================================================== */

const thirtyThreeThomas: SpecEntity = {
  slug: "33-thomas-street",
  name: "33 Thomas Street",
  entity_level: "structure",
  jurisdiction: "New York County, New York",
  typology: "urban-in-building",
  reference_class: "RC4",
  reference_class_basis: "Private urban parcel, no federal land status (PAD-US).",
  aliases: ["AT&T Long Lines Building", "TITANPOINTE"],
  geometry: { precision: "surveyed", point: [-74.0059, 40.7166] },
  propositions: [
    {
      ref: "p-EXIST-1",
      class: "EXIST",
      statement: "A windowless hardened telecommunications structure exists at 33 Thomas Street.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A07",
      null_label: "unhardened data centre",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "COMMON",
      sci: [5, 5],
      l_d2: 5,
      l_d3: 3,
      observations: [
        ev("e1", "NYC Department of Buildings filing carrying the survivability design documentation.", {
          d: 4, tier: "T1", doc: "NYC Department of Buildings filing, 33 Thomas Street", issuer: "New York City Department of Buildings",
          date: "1969-03-11", ident: "NB 214-1969", identClass: "DOB", authority: true, lineage: "L1",
          quote: ["structure designed to remain self-sufficient for two weeks following an attack", 4180, 4258],
        }),
        ev("e2", "AT&T engineering and route literature describing the building.", {
          d: 3, tier: "T2", doc: "AT&T Long Lines engineering record", issuer: "AT&T", date: "1974-01-01", lineage: "L2" }),
        ev("e3", "Warnecke's architectural record for the commission.", {
          d: 3, tier: "T2", doc: "John Carl Warnecke & Associates project record", issuer: "Warnecke & Associates",
          date: "1969-01-01", lineage: "L3" }),
        ev("e4", "Municipal energy-benchmarking disclosure for the building.", {
          d: 2, tier: "T1", doc: "NYC energy benchmarking disclosure", issuer: "City of New York", date: "2019-01-01", lineage: "L4" }),
        ev("e5", "Roof vent-stack array visible on public orthoimagery.", {
          d: 2, locus: "PLACE-PROPERTY", tier: "T1", doc: "NYC orthoimagery", issuer: "City of New York", date: "2020-01-01", lineage: "L5" }),
        ev("e6", "No leasable floor plate in the commercial listing record.", {
          d: 1, tier: "T2", doc: "Commercial real estate listing record", issuer: "CoStar", date: "2018-01-01", lineage: "L4" }),
      ],
      alternatives: [
        { null_code: "A07", label: "unhardened data centre", description: "Commercial data centre or telecom exchange, unhardened", disposition: "EXCLUDED", reasoning: "The DOB filing states an attack-survivability design objective on its face.", excluding: ["e1"] },
      ],
    },
    {
      ref: "p-HARDEN-1",
      class: "HARDEN",
      statement: "The structure is engineered against blast and fallout, with independent utilities.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A07",
      null_label: "unhardened data centre",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "RARE",
      sci: [4, 4],
      l_d2: 4,
      l_d3: 3,
      observations: [
        ev("e1", "DOB filing stating the hardening intent on its face.", {
          d: 4, tier: "T1", doc: "NYC Department of Buildings filing, 33 Thomas Street", issuer: "New York City Department of Buildings",
          date: "1969-03-11", ident: "NB 214-1969", identClass: "DOB", authority: true, lineage: "L1",
          quote: ["self-sufficient for two weeks, with fuel, water and food stores", 4260, 4322],
        }),
      ],
    },
    {
      ref: "p-FUNCTION-1",
      class: "FUNCTION",
      statement: "The building houses a long-distance gateway switching function.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A07",
      null_label: "unhardened data centre",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      sci: [4, 4],
      l_d2: 4,
      l_d3: 3,
      observations: [
        ev("e1", "AT&T route literature naming the gateway switch at this address.", {
          d: 4, tier: "T2", doc: "AT&T Long Lines route and switching record", issuer: "AT&T", date: "1976-01-01",
          authority: true, lineage: "L1", quote: ["4ESS gateway switch, 33 Thomas Street", 810, 848],
        }),
      ],
    },
    {
      ref: "p-FUNCTION-2",
      class: "FUNCTION",
      statement: "The site designated TITANPOINTE hosts an NSA signals-intelligence collection function.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A07",
      null_label: "unhardened data centre",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "VERY-RARE",
      sci: [4, 4],
      l_d2: 3,
      l_d3: 3,
      observations: [
        ev("e1", "Agency-originated document describing the TITANPOINTE collection site.", {
          d: 4, tier: "T1", doc: "Agency site description, TITANPOINTE", issuer: "National Security Agency",
          date: "2013-01-01", authority: true, lineage: "L1",
          quote: ["TITANPOINTE, a partner-operated facility hosting collection equipment", 2210, 2278],
        }),
      ],
      see_limits: ["L-7"],
    },
    {
      ref: "p-IDENTITY-1",
      class: "IDENTITY",
      statement: "The site designated TITANPOINTE is 33 Thomas Street.",
      grade: "B",
      ceiling: "A",
      at_ceiling: false,
      limiting_condition:
        "A1 — no record from either party asserts the equivalence. The documents that would move this: an agency record naming the street address, or a carrier record naming the codename.",
      null_code: "A09",
      null_label: "duplicate entity",
      null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE",
      sci: [4, 4],
      l_d2: 4,
      l_d3: 2,
      condition_results: { A1: false, B1: true, B2: true, B3: true, B4: true },
      observations: [
        ev("e1", "Journalistic correlation of the agency site description against the building's features.", {
          d: 3, tier: "T2", doc: "Investigative correlation of TITANPOINTE and 33 Thomas Street",
          issuer: "The Intercept", author: "Ryan Gallagher and Henrik Moltke", date: "2016-11-16", lineage: "L1",
        }),
        ev("e2", "Roof antenna configuration matching the agency description.", {
          d: 3, locus: "PLACE-PROPERTY", tier: "T1", doc: "FCC antenna structure registration", issuer: "Federal Communications Commission",
          date: "1980-01-01", lineage: "L2" }),
      ],
    },
  ],
  notes: [
    "B-06 consequence: because IDENTITY is at B (>= C), §11.1 permits the alias to be used for subject binding on the SIGINT proposition. The merge is evidenced rather than assumed.",
    "A-03 boundary demonstration: if the DOB filing did not itself state hardening intent, §3.4(d) fails on e1, A1 fails, and EXIST falls to B on L(D3) = 3.",
  ],
};

/* ================================================================== *
 * A-04 / E-03 · Mount Weather Emergency Operations Center
 * ================================================================== */

const mountWeather: SpecEntity = {
  slug: "mount-weather-eoc",
  name: "Mount Weather Emergency Operations Center",
  entity_level: "site",
  jurisdiction: "Loudoun County, Virginia",
  typology: "cog-coop",
  reference_class: "RC1",
  reference_class_basis: "Federal installation boundary (PAD-US).",
  aliases: ["Mount Weather", "High Point Special Facility", "Special Facility"],
  geometry: { precision: "surveyed", point: [-77.8917, 39.0617] },
  propositions: [
    {
      ref: "p-EXIST-1",
      class: "EXIST",
      statement: "A federal emergency operations facility exists at Mount Weather.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A08",
      null_label: "ordinary government building",
      null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "COMMON",
      sci: [5, 5],
      l_d2: 5,
      l_d3: 4,
      observations: [
        ev("e1", "NTSB accident report placing a federal facility on the mountain.", {
          d: 4, tier: "T1", doc: "Aircraft Accident Report, TWA Flight 514", issuer: "National Transportation Safety Board",
          date: "1975-11-26", ident: "NTSB-AAR-75-16", identClass: "NTSB", authority: true, lineage: "L1",
          quote: ["the aircraft struck the west slope of Mount Weather, Virginia, near a federal installation", 1620, 1706],
        }),
        ev("e2", "FEMA budget line naming the Mount Weather Emergency Operations Center.", {
          d: 4, tier: "T1", doc: "FEMA congressional budget justification", issuer: "Federal Emergency Management Agency",
          date: "2008-02-04", authority: true, lineage: "L2",
          quote: ["Mount Weather Emergency Operations Center", 9902, 9942],
        }),
        ev("e3", "GSA federal real property record for the site.", {
          d: 3, tier: "T1", doc: "Federal Real Property Profile record", issuer: "General Services Administration", date: "2019-09-30", lineage: "L3" }),
        ev("e4", "GAO oversight report referencing the facility.", {
          d: 3, tier: "T1", doc: "GAO report on continuity of operations facilities", issuer: "Government Accountability Office",
          date: "2004-04-01", ident: "GAO-04-160", identClass: "GAO", lineage: "L4" }),
      ],
    },
    {
      ref: "p-FEATURE-1",
      class: "FEATURE",
      statement:
        "The facility contains an underground city with streets, sidewalks, a lake and its own mass transit system.",
      grade: "E",
      grade_pre_clamp: "E",
      ceiling: "E",
      at_ceiling: true,
      ceiling_reason:
        "CAP-2b — no FUNCTION or FEATURE claim exceeds E without a verified, instance-scope, subject-bound CLAIM-PROPERTY observation. CAP-3 caps at E independently on the confirmed citogenesis loop.",
      applied_caps: ["CAP-2b", "CAP-3"],
      limiting_condition:
        "CAP-2b — |V[claim]| = 0. Every circulating version descends from one 1976 magazine article resting on unnamed off-the-record testimony. The document that would move this: any instance-level record from a party with authority over the facility's internal configuration.",
      citogenesis: true,
      null_code: "A08",
      null_label: "ordinary government building",
      null_state: "SURVIVING",
      silence_reading: "UNINFORMATIVE",
      base_rate_reading: "VERY-RARE",
      sci: [4, 4],
      l_d2: 1,
      l_d3: 0,
      condition_results: { A1: false, B1: false, C1a: false, D1: false, E1: true, E2: true },
      predicate_args: {
        claim_text: "Mount Weather contains an underground city with streets, sidewalks and a lake.",
        first_appearance_date: "1976-03-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "Magazine report of unnamed former officials describing the interior.", {
          d: 0, tier: "T3", doc: "\"The Mysterious Mountain\"", issuer: "The Progressive", author: "Richard Pollock",
          date: "1976-03-01", lineage: "L1", siglum: "A1",
          quote: ["streets and sidewalks, a small lake fed by underground springs, and its own mass transit system", 2110, 2205],
        }),
        ev("e2", "Syndicated column repeating the 1976 account.", {
          d: 0, tier: "T4", doc: "Syndicated column", author: "Jack Anderson", date: "1987-05-02", lineage: "L1", siglum: "D3" }),
        ev("e3", "Aggregator facility page repeating the account.", {
          d: 0, tier: "T4", doc: "globalsecurity.org/facility/mount-weather", channel: "AGGREGATOR", provenance: "SELF-PUBLISHED",
          date: "2003-01-01", lineage: "L1", siglum: "D7" }),
        ev("e4", "Encyclopedia article citing the aggregator page, subsequently cited as primary.", {
          d: 0, tier: "T4", doc: "Encyclopedia article, \"Mount Weather\" §Facilities", channel: "ADVERSARY-WRITABLE",
          provenance: "CROWD-EDITED", adversary: true, date: "2011-06-14", lineage: "L1", siglum: "D14" }),
      ],
      alternatives: [
        { null_code: "A08", label: "ordinary government building", description: "Ordinary above-ground government building", disposition: "SURVIVING", reasoning: "A federal emergency operations centre with conventional interior configuration accounts for every verified row. Nothing in V discriminates.", excluding: [] },
      ],
      lineage: {
        document_count: 41,
        lineage_count: 1,
        verdict:
          "41 citing documents · 1 independent lineage · collapse delta 40. This proposition rests on one source and 40 copies.",
        citogenesis_note:
          "This encyclopedia article cites the 2003 page, which cites the 1976 article, which is the only source. The loop was counted as three sources until 2026-04.",
        blocks: [
          {
            origin: {
              siglum: "A1", label: "Pollock, R. \"The Mysterious Mountain.\" The Progressive.",
              document_date: "1976-03-01", origin_tier: "T3", resolved: true,
              note: "A T3 publication resting on unattributable T5 testimony, subsequently cited as primary.",
            },
            descendants: [
              { siglum: "A1a", label: "rests on: unnamed off-the-record former officials", origin_tier: "T5", edge_kind: "rests-on", resolved: false, note: "unresolvable · custody none" },
              { siglum: "A1b", label: "rests on: Senate subcommittee material", origin_tier: "T1", edge_kind: "rests-on", resolved: true },
              { siglum: "D3", label: "Anderson, J., syndicated column", document_date: "1987-05-02", origin_tier: "T4", collapses: true },
              { siglum: "D7", label: "globalsecurity.org/facility/mount-weather", document_date: "2003-01-01", origin_tier: "T4", collapses: true },
              { siglum: "D14", label: "Encyclopedia \"Mount Weather\" §Facilities", document_date: "2011-06-14", origin_tier: "T4", collapses: true, citogenesis: true, edge_kind: "contamination", closes_cycle: "D14 → A1 (undated; entry point unresolved)" },
            ],
            downstream_count: 41,
          },
        ],
      },
      movement: [
        { occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "E", cause: "INITIAL" },
      ],
    },
  ],
  notes: [
    "E-03 is a KNOWN DIVERGENCE. The historian expected D; BES returns E, one band conservative. The suite asserts E; a change returning D must be argued against this note.",
    "Structural assertion: the citogenesis flag attaches to the PROPOSITION, not the site. Under v0.1 this content rode inside an A-grade entry with the flag having nowhere to attach.",
  ],
};

/* ================================================================== *
 * A-06 · Iron Mountain / Boyers, PA
 * ================================================================== */

const ironMountainBoyers: SpecEntity = {
  slug: "iron-mountain-boyers",
  name: "Iron Mountain, Boyers — OPM Retirement Operations Center",
  entity_level: "site",
  jurisdiction: "Butler County, Pennsylvania",
  typology: "archive-storage",
  reference_class: "RC4",
  reference_class_basis: "Private parcel with a documented federal tenancy.",
  aliases: ["Boyers", "Iron Mountain National Data Center"],
  geometry: { precision: "surveyed", point: [-79.9186, 41.0339] },
  propositions: [
    {
      ref: "p-EXIST-1",
      class: "EXIST",
      statement: "A converted limestone mine housing federal records operations exists at Boyers.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A02", null_label: "commercial mine or cavern", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON",
      sci: [5, 5], l_d2: 5, l_d3: 4,
      observations: [
        ev("e1", "GSA prospectus stating the rentable square footage of the federal occupancy.", {
          d: 4, tier: "T1", doc: "GSA lease prospectus, Boyers PA", issuer: "General Services Administration",
          date: "2015-03-01", authority: true, lineage: "L1",
          quote: ["approximately 580,000 rentable square feet in the underground facility at Boyers, Pennsylvania", 1810, 1904],
        }),
        ev("e2", "OPM published material describing the Retirement Operations Center.", {
          d: 4, tier: "T1", doc: "OPM Retirement Operations Center description", issuer: "Office of Personnel Management",
          date: "2014-01-01", authority: true, lineage: "L2",
          quote: ["the Retirement Operations Center in Boyers, Pennsylvania", 420, 474],
        }),
        ev("e3", "Mine safety records for the former US Steel limestone workings.", {
          d: 3, locus: "PLACE-PROPERTY", tier: "T1", doc: "MSHA mine record", issuer: "Mine Safety and Health Administration",
          date: "1975-01-01", lineage: "L3" }),
        ev("e4", "Extensive named-source journalism describing the operation.", {
          d: 2, tier: "T2", doc: "Feature report on the Boyers facility", issuer: "The Washington Post", date: "2014-03-22", lineage: "L4" }),
      ],
      alternatives: [
        { null_code: "A02", label: "commercial mine or cavern", description: "Commercial or industrial mine, quarry, or cavern warehouse", disposition: "EXCLUDED", reasoning: "The mine conversion is real and the federal operation inside it is separately documented at the issuing authority.", excluding: ["e1", "e2"] },
      ],
    },
    {
      ref: "p-TYPOLOGY-1",
      class: "TYPOLOGY",
      statement: "The facility is a records storage and archive facility, not a continuity-of-government site.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "OPM description of the retirement records operation.", {
          d: 4, tier: "T1", doc: "OPM Retirement Operations Center description", issuer: "Office of Personnel Management",
          date: "2014-01-01", authority: true, lineage: "L1", quote: ["paper retirement records are processed and stored", 610, 655] }),
      ],
    },
    {
      ref: "p-FUNCTION-1",
      class: "FUNCTION",
      statement: "The facility processes federal civilian retirement casework.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A06", null_label: "general storage", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "UNCOMMON", sci: [4, 4], l_d2: 4, l_d3: 3,
      observations: [
        ev("e1", "OPM operational description of the casework process.", {
          d: 4, tier: "T1", doc: "OPM Retirement Operations Center description", issuer: "Office of Personnel Management",
          date: "2014-01-01", authority: true, lineage: "L1", quote: ["retirement applications are adjudicated at this location", 700, 756] }),
        ev("e2", "GAO report on retirement processing backlogs naming the site.", {
          d: 3, tier: "T1", doc: "GAO report on federal retirement processing", issuer: "Government Accountability Office",
          date: "2019-01-01", lineage: "L2" }),
      ],
    },
  ],
  notes: [
    "A-06 is paired against R-02 (SubTropolis). Both are limestone mines with federal-adjacent tenants; Boyers has direct T1 documentation of the federal operation and SubTropolis does not. A model that separates them on place-signals rather than on documentation is measuring the wrong thing — on place-signals they are identical.",
  ],
};

/* ================================================================== *
 * A-07 · Titan II Missile Site 571-7
 * ================================================================== */

const titanII: SpecEntity = {
  slug: "titan-ii-571-7",
  name: "Titan II Missile Site 571-7",
  entity_level: "site",
  jurisdiction: "Pima County, Arizona",
  typology: "missile-silo",
  reference_class: "RC2",
  reference_class_basis: "Former DoD withdrawal, now in private museum ownership.",
  aliases: ["Titan Missile Museum", "571-7"],
  geometry: { precision: "surveyed", point: [-110.9994, 31.9028] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A Titan II launch complex exists at this location.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [5, 5], l_d2: 5, l_d3: 4,
      observations: [
        ev("e1", "Air Force real property record for launch complex 571-7.", {
          d: 4, tier: "T1", doc: "Air Force real property record, 390th Strategic Missile Wing",
          issuer: "U.S. Air Force", date: "1963-01-01", authority: true, lineage: "L1",
          quote: ["Launch Complex 571-7, Green Valley, Arizona", 300, 342] }),
        ev("e2", "Construction and deactivation record for the complex.", {
          d: 4, tier: "T1", doc: "Titan II deactivation record", issuer: "U.S. Air Force", date: "1984-11-01",
          authority: true, lineage: "L2", quote: ["complex 571-7 retained for museum use", 1420, 1458] }),
        ev("e3", "National Register of Historic Places nomination.", {
          d: 3, tier: "T1", doc: "National Register nomination form", issuer: "National Park Service", date: "1994-01-01", lineage: "L3" }),
      ],
    },
    {
      ref: "p-STATUS-1", class: "STATUS",
      statement: "The complex is decommissioned and converted to museum use.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      predicate_args: { status: "converted" },
      observations: [
        ev("e1", "Deactivation record and museum transfer instrument.", {
          d: 4, tier: "T1", doc: "Titan II deactivation record", issuer: "U.S. Air Force", date: "1984-11-01",
          authority: true, lineage: "L1", quote: ["deactivated; transferred for public interpretation", 1460, 1512] }),
      ],
    },
    {
      ref: "p-TYPOLOGY-1", class: "TYPOLOGY",
      statement: "The facility is an ICBM launch facility.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [2, 2], l_d2: 2, l_d3: 2,
      observations: [
        ev("e1", "Air Force real property record classifying the complex.", {
          d: 4, tier: "T1", doc: "Air Force real property record", issuer: "U.S. Air Force", date: "1963-01-01",
          authority: true, lineage: "L1", quote: ["launch facility, Titan II weapon system", 350, 390] }),
      ],
    },
  ],
  notes: [
    "A-07 guards against silo clog: a large fraction of the register will be Atlas/Titan/Minuteman sites and they must not fill the middle bands. Under the silo catalog, EXIST/CONTROL/LOCATE are near-trivially D4 and the live propositions are STATUS and current CONTROL.",
  ],
};

/* ================================================================== *
 * A-08 · Camp Hero Air Force Station — published beside F-01/A-13
 * ================================================================== */

const campHero: SpecEntity = {
  slug: "camp-hero-afs",
  name: "Camp Hero Air Force Station",
  entity_level: "site",
  jurisdiction: "Suffolk County, New York",
  typology: "military-hardened",
  reference_class: "RC2",
  reference_class_basis: "Former military reservation, now a state park.",
  aliases: ["Montauk Air Force Station", "Camp Hero State Park"],
  geometry: { precision: "surveyed", point: [-71.8631, 41.0642] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A former Air Force radar station exists at Camp Hero, Montauk.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [6, 6], l_d2: 5, l_d3: 4,
      observations: [
        ev("e1", "NARA unit records for the Air Force station.", {
          d: 4, tier: "T1", doc: "NARA unit records, 773d Radar Squadron", issuer: "National Archives and Records Administration",
          date: "1958-01-01", authority: true, lineage: "L1", quote: ["Montauk Air Force Station, Montauk, New York", 90, 134] }),
        ev("e2", "Closure and disposal records for the installation.", {
          d: 4, tier: "T1", doc: "Installation disposal record", issuer: "General Services Administration",
          date: "1984-01-01", authority: true, lineage: "L2", quote: ["excess property, Montauk Air Force Station", 210, 252] }),
        ev("e3", "EPA site files for the former station.", {
          d: 3, tier: "T1", doc: "EPA site file", issuer: "Environmental Protection Agency", date: "1998-01-01", lineage: "L3" }),
        ev("e4", "New York State Parks acquisition record.", {
          d: 3, tier: "T1", doc: "State parks acquisition record", issuer: "New York State Office of Parks", date: "1984-01-01", lineage: "L4" }),
        ev("e5", "The AN/FPS-35 tower, still standing, on public orthoimagery.", {
          d: 2, locus: "PLACE-PROPERTY", tier: "T1", doc: "NY State orthoimagery", issuer: "New York State", date: "2021-01-01", lineage: "L5" }),
      ],
    },
    {
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement: "The station operated an AN/FPS-35 search radar within the SAGE air defence network.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A08", null_label: "ordinary government building", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "UNCOMMON", sci: [4, 4], l_d2: 4, l_d3: 3,
      observations: [
        ev("e1", "Air Force unit history naming the radar set and its SAGE role.", {
          d: 4, tier: "T1", doc: "Unit history, 773d Radar Squadron", issuer: "Air Force Historical Research Agency",
          date: "1966-06-30", ident: "IRIS 00447281", identClass: "AFHRA", authority: true, lineage: "L1",
          quote: ["AN/FPS-35 search radar reporting to the SAGE direction center", 3120, 3182] }),
      ],
    },
  ],
  notes: [
    "A-08 is paired with F-01 at the same coordinates. The register must publish both without contradiction: the station is A, the Montauk Project claim is F, and they are different entities with different propositions.",
  ],
};

/* ================================================================== *
 * A-09 · Mount Pony, Culpeper VA — the non-appropriated control
 * SCI = 1.000 on an EMPTY DENOMINATOR. Four ERP profiles at X0
 * produce NO ROWS, not zeros — and the searches were still executed.
 * ================================================================== */

const mountPony: SpecEntity = {
  slug: "mount-pony-culpeper",
  name: "Mount Pony, Culpeper",
  entity_level: "site",
  jurisdiction: "Culpeper County, Virginia",
  typology: "cog-coop",
  reference_class: "RC4",
  reference_class_basis:
    "Private parcel under a self-funded federal instrumentality; no appropriated federal land status.",
  aliases: ["Federal Reserve Culpeper Switch", "Packard Campus for Audio-Visual Conservation"],
  geometry: { precision: "surveyed", point: [-77.9536, 38.4636] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A hardened semi-recessed federal facility exists at Mount Pony.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A08", null_label: "ordinary government building", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "UNCOMMON", reference_class: "RC4",
      /**
       * SCI with an EMPTY DENOMINATOR is 1.000, not 0 (GRADING.md §7.2). The
       * four appropriated-record profiles return X0 — no record of that class
       * would be expected for a self-funded instrumentality — so they produce
       * NO ROWS and enter no denominator. The naive reading pins this entity at
       * X forever, which is why the correction exists and why this case is here.
       */
      sci: [0, 0],
      l_d2: 4, l_d3: 3,
      observations: [
        ev("e1", "Federal Reserve Board publication describing the facility's dedication and construction.", {
          d: 4, tier: "T1", doc: "Board publication, Culpeper communications and records center",
          issuer: "Board of Governors of the Federal Reserve System", date: "1969-12-10", authority: true, lineage: "L1",
          quote: ["dedicated 10 December 1969; 140,000 square feet, semi-recessed beneath two to four feet of earth", 880, 976] }),
        ev("e2", "Construction record describing foot-thick steel-reinforced concrete and lead-lined shutters.", {
          d: 3, tier: "T1", doc: "Construction specification record", issuer: "Board of Governors of the Federal Reserve System",
          date: "1968-01-01", lineage: "L2" }),
        ev("e3", "Library of Congress acquisition record for the 1997 transfer.", {
          d: 3, tier: "T1", doc: "Library of Congress acquisition record", issuer: "Library of Congress",
          date: "1997-01-01", lineage: "L3" }),
        ev("e4", "Named-source journalism on the currency reserve and the electronic funds transfer node.", {
          d: 2, tier: "T2", doc: "Feature report on the Culpeper facility", issuer: "The Washington Post", date: "1992-08-01", lineage: "L4" }),
      ],
      silence: [
        { record_class: "MILCON / DD-1391", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 c04a…d19", egress_state: "REACHABLE" },
        { record_class: "FPDS / USAspending", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 7b31…8f2", egress_state: "REACHABLE" },
        { record_class: "Federal Real Property Profile", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 e5c8…41a", egress_state: "REACHABLE" },
        { record_class: "GSA disposal record", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 2ad9…6b7", egress_state: "REACHABLE" },
      ],
      searches: [
        { query: "\"Culpeper\" Federal Reserve facility construction", corpus_as_of: "2026-07-01", outcome: "POSITIVE", result_count: 6 },
        { query: "MILCON DD-1391 Culpeper Virginia", corpus_as_of: "2026-07-01", outcome: "NEGATIVE", result_count: 0, erp_profile: "MILCON/DD-1391", egress_state: "REACHABLE" },
        { query: "FPDS award Culpeper communications center", corpus_as_of: "2026-07-01", outcome: "NEGATIVE", result_count: 0, erp_profile: "FPDS", egress_state: "REACHABLE" },
      ],
    },
    {
      ref: "p-HARDEN-1", class: "HARDEN",
      statement: "The structure is hardened against blast and radiological effects.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A07", null_label: "unhardened data centre", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "UNCOMMON", sci: [0, 0], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "Construction specification naming the protective engineering.", {
          d: 4, tier: "T1", doc: "Construction specification record", issuer: "Board of Governors of the Federal Reserve System",
          date: "1968-01-01", authority: true, lineage: "L1",
          quote: ["one-foot steel-reinforced concrete walls with lead-lined shutters", 2210, 2274] }),
      ],
    },
    {
      ref: "p-CONTROL-1", class: "CONTROL",
      statement: "The facility was owned and operated by the Federal Reserve System.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A08", null_label: "ordinary government building", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE", sci: [0, 0], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "Board publication asserting ownership and operation.", {
          d: 4, tier: "T1", doc: "Board publication, Culpeper communications and records center",
          issuer: "Board of Governors of the Federal Reserve System", date: "1969-12-10", authority: true, lineage: "L1",
          quote: ["owned and operated by the Board of Governors", 1010, 1054] }),
      ],
    },
    {
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement:
        "The facility served a continuity-of-government function for post-attack monetary reconstitution.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A06", null_label: "general storage", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "VERY-RARE", sci: [0, 0], l_d2: 3, l_d3: 3,
      observations: [
        ev("e1", "Board record describing the currency holding and the reconstitution role.", {
          d: 4, tier: "T1", doc: "Board record, continuity program", issuer: "Board of Governors of the Federal Reserve System",
          date: "1988-01-01", authority: true, lineage: "L1",
          quote: ["shrink-wrapped currency held against post-attack monetary reconstitution", 640, 712] }),
        ev("e2", "Record of the peacetime staffing and 30-day support posture.", {
          d: 3, tier: "T1", doc: "Continuity staffing record", issuer: "Board of Governors of the Federal Reserve System",
          date: "1985-01-01", lineage: "L2" }),
      ],
    },
    {
      ref: "p-STATUS-1", class: "STATUS",
      statement: "The facility is converted to audio-visual conservation use.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE", sci: [0, 0], l_d2: 2, l_d3: 2,
      predicate_args: { status: "converted" },
      observations: [
        ev("e1", "Library of Congress record of the 1997 purchase and conversion.", {
          d: 4, tier: "T1", doc: "Library of Congress acquisition record", issuer: "Library of Congress",
          date: "1997-01-01", authority: true, lineage: "L1", quote: ["purchased for $5.5 million on behalf of the Library", 300, 352] }),
      ],
    },
  ],
  notes: [
    "A-09 is the non-appropriated blind-spot control. Under v0.1 it lost roughly 40 points across DOC and OWN because the Federal Reserve is self-funded: no appropriations line, no MILCON J-book, no FRPP entry, no FPDS record, and the 1997 transfer was not a GSA disposal.",
    "The coverage note the suite asserts: MILCON/DD-1391, FPDS/USAspending, FRPP and GSA-disposal profiles all return X0 and therefore produce NO ROWS — not zeros. Those searches were still executed and their negative receipts logged.",
    "A blind spot in a grading system is a safe harbour for fabrication.",
  ],
};

/* ================================================================== *
 * A-16 / B-02 / P-06 · Manzano Base and KUMMSC — the merge trap
 * ================================================================== */

const manzanoBase: SpecEntity = {
  slug: "manzano-base",
  name: "Manzano Base",
  entity_level: "site",
  jurisdiction: "Bernalillo County, New Mexico",
  typology: "military-hardened",
  reference_class: "RC1",
  reference_class_basis: "Inside the Kirtland AFB installation boundary (PAD-US).",
  aliases: ["Manzano Mountain Storage Facility", "Site Able"],
  distinct_from: [
    {
      slug: "kummsc",
      name: "Kirtland Underground Munitions Maintenance and Storage Complex",
      note:
        "P-06 · Manzano Base is tunnelled into the Manzano Mountains, begun 1947 and phased out around 1992. KUMMSC is a 56-acre replacement completed 1994, OUTSIDE the mountain, on the same base with the same mission. A merged record would score higher than either true record, span 1947 to present (true of neither), hold a status simultaneously active and decommissioned, and pin a coordinate wrong for both. Seeded DISTINCT-FROM so they can never silently re-merge.",
    },
  ],
  geometry: { precision: "surveyed", point: [-106.5147, 34.9906] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "An underground nuclear weapons storage facility exists in the Manzano Mountains.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A02", null_label: "commercial mine or cavern", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [5, 5], l_d2: 4, l_d3: 4,
      observations: [
        ev("e1", "Air Force installation history recording the construction and completion dates.", {
          d: 4, tier: "T1", doc: "Installation history, Manzano Base", issuer: "Air Force Historical Research Agency",
          date: "1962-01-01", ident: "IRIS 00512204", identClass: "AFHRA", authority: true, lineage: "L1",
          quote: ["construction begun 1947, functional 1950, complete 1961", 2110, 2164] }),
        ev("e2", "DOE environmental filing describing the tunnelled storage structures.", {
          d: 3, tier: "T1", doc: "DOE environmental record", issuer: "Department of Energy", date: "1996-01-01", lineage: "L2" }),
      ],
    },
    {
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement: "The facility stored and maintained nuclear weapons.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A06", null_label: "general storage", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "RARE", sci: [4, 4], l_d2: 3, l_d3: 3,
      observations: [
        ev("e1", "Installation history describing the storage mission.", {
          d: 4, tier: "T1", doc: "Installation history, Manzano Base", issuer: "Air Force Historical Research Agency",
          date: "1962-01-01", ident: "IRIS 00512204", identClass: "AFHRA", authority: true, lineage: "L1",
          quote: ["national stockpile storage site under Armed Forces Special Weapons Project", 2200, 2274] }),
      ],
    },
    {
      ref: "p-STATUS-1", class: "STATUS",
      statement: "The facility is decommissioned.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      predicate_args: { status: "decommissioned" },
      observations: [
        ev("e1", "Record of the phase-out and mission transfer.", {
          d: 4, tier: "T1", doc: "Mission transfer record", issuer: "U.S. Air Force", date: "1994-01-01",
          authority: true, lineage: "L1", quote: ["storage mission transferred from Manzano to the new complex", 410, 470] }),
      ],
    },
  ],
};

const kummsc: SpecEntity = {
  slug: "kummsc",
  name: "Kirtland Underground Munitions Maintenance and Storage Complex",
  entity_level: "site",
  jurisdiction: "Bernalillo County, New Mexico",
  typology: "military-hardened",
  reference_class: "RC1",
  reference_class_basis: "Inside the Kirtland AFB installation boundary (PAD-US).",
  aliases: ["KUMMSC", "KUMSC", "Kirtland Underground Munitions Storage Complex"],
  distinct_from: [
    {
      slug: "manzano-base",
      name: "Manzano Base",
      note:
        "P-06 · The adjacent facility this one is constantly conflated with. A merge requires an IDENTITY proposition at band C+ backed by a named, verified, instance-level source. Proximity and name similarity FLAG, never merge. The CORRECT merge — KUMMSC ≡ KUMSC, a name variant — is a separate IDENTITY proposition and it still works.",
    },
  ],
  geometry: { precision: "surveyed", point: [-106.5372, 34.9994] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "An underground munitions maintenance and storage complex exists at Kirtland AFB.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A02", null_label: "commercial mine or cavern", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [5, 5], l_d2: 4, l_d3: 4,
      observations: [
        ev("e1", "DoD construction record for the replacement complex.", {
          d: 4, tier: "T1", doc: "Military construction record, Kirtland AFB", issuer: "U.S. Department of Defense",
          date: "1994-01-01", authority: true, lineage: "L1",
          quote: ["56-acre underground munitions maintenance and storage complex, completed 1994", 1240, 1318] }),
        ev("e2", "DOE environmental filing describing the complex.", {
          d: 3, tier: "T1", doc: "DOE environmental record", issuer: "Department of Energy", date: "2011-01-01", lineage: "L2" }),
      ],
    },
    {
      ref: "p-HARDEN-1", class: "HARDEN",
      statement: "The complex is engineered against blast and forced entry.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A06", null_label: "general storage", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "UNCOMMON", sci: [4, 4], l_d2: 3, l_d3: 3,
      observations: [
        ev("e1", "Construction record naming the protective design standard.", {
          d: 4, tier: "T1", doc: "Military construction record, Kirtland AFB", issuer: "U.S. Department of Defense",
          date: "1994-01-01", authority: true, lineage: "L1",
          quote: ["designed to the applicable nuclear weapons storage protective construction standard", 1360, 1444] }),
      ],
    },
    {
      /**
       * B-02 · PAIR, NOT LETTER. The reviewer expected a composite B:
       * "existence solid, extent partly inferred". BES has no composite, so
       * there is nothing that can be B. EXIST A and EXTENT D on the same entity
       * at the same instant IS the reviewer's stated requirement — but it is
       * not a letter-for-letter match and the suite must not report it as one.
       */
      ref: "p-EXTENT-1", class: "EXTENT",
      statement: "The complex's internal extent, capacity and current inventory are as described.",
      grade: "D",
      ceiling: "B",
      at_ceiling: false,
      limiting_condition:
        "A1/B1 — internal extent, capacity and current inventory are inferred from footprint and environmental filings rather than documented. The documents that would move this: an as-built drawing set, or a capacity figure in a DoD or DOE record naming this complex.",
      null_code: "A06", null_label: "general storage", null_state: "SURVIVING",
      silence_reading: "UNINFORMATIVE", sci: [3, 5], l_d2: 2, l_d3: 0,
      condition_results: { A1: false, B1: false, C1a: false, D1: true },
      observations: [
        ev("e1", "Surface footprint and berm geometry from public orthoimagery.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "USGS orthoimagery, Bernalillo County",
          issuer: "U.S. Geological Survey", date: "2021-01-01", lineage: "L1" }),
        ev("e2", "Acreage figure in the environmental filing.", {
          d: 2, tier: "T1", doc: "DOE environmental record", issuer: "Department of Energy", date: "2011-01-01", lineage: "L2" }),
        ev("e3", "Capacity figure asserted in an aggregator compilation.", {
          d: 0, tier: "T4", doc: "Aggregator facility compilation", channel: "AGGREGATOR", provenance: "SELF-PUBLISHED",
          date: "2015-01-01", lineage: "L3" }),
      ],
      alternatives: [
        { null_code: "A06", label: "general storage", description: "Agricultural, cold or general storage", disposition: "SURVIVING", reasoning: "Footprint and berm geometry are consistent with a range of storage configurations. Nothing in V discriminates internal extent.", excluding: [] },
      ],
    },
    {
      ref: "p-IDENTITY-1", class: "IDENTITY",
      statement: "The designations KUMMSC and KUMSC refer to the same complex.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A09", null_label: "duplicate entity", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "DoD record using both designations for the same facility number.", {
          d: 4, tier: "T1", doc: "DoD facility designation record", issuer: "U.S. Department of Defense",
          date: "2001-01-01", authority: true, lineage: "L1",
          quote: ["KUMMSC (also KUMSC), facility 20000", 220, 254] }),
      ],
    },
  ],
  notes: [
    "P-06 · The correct merge (KUMMSC ≡ KUMSC) and the catastrophic merge (Manzano ≡ KUMMSC) are described in identical language by a brief reading 'merge name variants, alias chains, coordinate near-duplicates'. The schema holds them apart where the brief cannot.",
  ],
};

/* ================================================================== *
 * A-17 · Groom Lake — the credibility donor F-04 must not inherit from
 * ================================================================== */

const groomLake: SpecEntity = {
  slug: "groom-lake",
  name: "Groom Lake",
  entity_level: "site",
  jurisdiction: "Lincoln County, Nevada",
  typology: "military-hardened",
  reference_class: "RC1",
  reference_class_basis: "Inside a DoD withdrawal and restricted airspace (PAD-US).",
  aliases: ["Area 51", "Homey Airport", "Detachment 3, AFFTC"],
  geometry: { precision: "surveyed", point: [-115.8111, 37.2350] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A U.S. Air Force flight test installation exists at Groom Lake.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [5, 5], l_d2: 5, l_d3: 4,
      observations: [
        ev("e1", "Federal Register notice of land withdrawal naming the installation.", {
          d: 4, tier: "T1", doc: "Federal Register land withdrawal notice", issuer: "Bureau of Land Management",
          date: "1984-01-01", identClass: "FR", authority: true, lineage: "L1",
          quote: ["withdrawal of public lands adjacent to the Nellis Range for the operating location near Groom Lake", 1120, 1224] }),
        ev("e2", "Declassified CIA history of the OXCART programme naming the site.", {
          d: 4, tier: "T1", doc: "Declassified programme history", issuer: "Central Intelligence Agency",
          date: "1992-01-01", ident: "CIA-RDP89B01354R000400460003-3", identClass: "CREST", authority: true, lineage: "L2",
          quote: ["the site at Groom Lake, Nevada", 4310, 4340] }),
        ev("e3", "EPA litigation record concerning the operating location.", {
          d: 3, tier: "T1", doc: "Federal court record", issuer: "U.S. District Court", date: "1995-01-01", lineage: "L3" }),
      ],
    },
  ],
  notes: [
    "A-17's function in the suite is to be the credibility donor that F-04 must not inherit from.",
  ],
};

/* ================================================================== *
 * A-15 / B-04 / X-02 · the Nike pair — one band apart, not four
 * ================================================================== */

const sf88l: SpecEntity = {
  slug: "sf-88l-marin",
  name: "Nike Site SF-88L, Marin County",
  entity_level: "site",
  jurisdiction: "Marin County, California",
  typology: "military-hardened",
  reference_class: "RC2",
  reference_class_basis: "Former military reservation inside a National Recreation Area.",
  aliases: ["SF-88L", "Nike Missile Site SF-88"],
  geometry: { precision: "surveyed", point: [-122.5311, 37.8264] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A restored Nike Hercules launch magazine exists at SF-88L.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [5, 5], l_d2: 5, l_d3: 4,
      observations: [
        ev("e1", "National Park Service site record for the restored installation.", {
          d: 4, tier: "T1", doc: "NPS cultural resource record, Nike Site SF-88", issuer: "National Park Service",
          date: "1996-01-01", authority: true, lineage: "L1",
          quote: ["launcher area SF-88L, restored to its 1974 configuration", 640, 698] }),
        ev("e2", "Army real property record for the site.", {
          d: 4, tier: "T1", doc: "Army real property record", issuer: "U.S. Army", date: "1958-01-01",
          authority: true, lineage: "L2", quote: ["SF-88L launcher area, Fort Barry", 200, 232] }),
        ev("e3", "Disposal record on the 1974 deactivation.", {
          d: 3, tier: "T1", doc: "Installation disposal record", issuer: "General Services Administration", date: "1974-01-01", lineage: "L3" }),
      ],
    },
    {
      ref: "p-STATUS-1", class: "STATUS",
      statement: "The site is preserved and open to the public.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      predicate_args: { status: "converted" },
      observations: [
        ev("e1", "NPS interpretation record for the restored site.", {
          d: 4, tier: "T1", doc: "NPS cultural resource record, Nike Site SF-88", issuer: "National Park Service",
          date: "1996-01-01", authority: true, lineage: "L1", quote: ["open for public interpretation", 720, 750] }),
      ],
    },
  ],
  notes: [
    "A-15 and B-04 are the same facility type with different evidence depth. The suite asserts they are separated by roughly ONE band, not four. Under v0.1 they separate by four, because the unrestored site has no photography, no tours and no named accounts to feed the axes.",
  ],
};

const nikeUnrestored: SpecEntity = {
  slug: "nike-hercules-magazine-unrestored",
  name: "Unrestored Nike Hercules launch magazine, private agricultural land",
  entity_level: "structure",
  jurisdiction: "Rural county, United States",
  typology: "military-hardened",
  reference_class: "RC3",
  reference_class_basis: "Private agricultural parcel; no current federal land status.",
  aliases: [],
  /**
   * B-04 · Located only to the administrative area. The county polygon is the
   * whole of the register's positional knowledge, and the plate must render
   * exactly that — an admin polygon, dot-screened, with no centre mark.
   */
  geometry: {
    precision: "admin_area",
    polygon: [
      [-96.90, 39.80], [-96.40, 39.80], [-96.40, 40.15], [-96.90, 40.15],
    ],
    chart_tags: ["PA"],
  },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "An unrestored Nike Hercules launch magazine exists on this parcel.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [4, 4], l_d2: 4, l_d3: 3,
      observations: [
        ev("e1", "Army site list naming the battery and its launcher area.", {
          d: 4, tier: "T1", doc: "Army air defense site list", issuer: "U.S. Army", date: "1960-01-01",
          authority: true, lineage: "L1", quote: ["launcher area, Nike Hercules battery", 1810, 1846] }),
        ev("e2", "Real property disposal record for the launcher parcel.", {
          d: 4, tier: "T1", doc: "Real property disposal record", issuer: "General Services Administration",
          date: "1971-01-01", authority: true, lineage: "L2", quote: ["disposal of the former launcher area", 300, 336] }),
        ev("e3", "County deed conveying the parcel to a private owner.", {
          d: 3, tier: "T1", doc: "County recorder, deed of conveyance", issuer: "County recorder", date: "1972-01-01", lineage: "L3" }),
      ],
    },
    {
      ref: "p-TYPOLOGY-1", class: "TYPOLOGY",
      statement: "The structure is a Nike Hercules underground launch magazine.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "Standard drawing set for the Nike Hercules launcher area, matched to the disposal record.", {
          d: 4, tier: "T1", doc: "Standard drawing set, Nike Hercules launcher area", issuer: "U.S. Army Corps of Engineers",
          date: "1958-01-01", authority: true, lineage: "L1", quote: ["underground magazine, elevator and personnel access", 90, 142] }),
      ],
    },
    {
      /**
       * X-02 · Current condition and status are GENUINELY UNKNOWN, not
       * unsupported. This is the case that distinguishes "we looked and found
       * nothing" (F) from "we have not looked, and the record class may not
       * exist" (X). X must render visually distinct from F.
       */
      ref: "p-STATUS-1", class: "STATUS",
      statement: "The magazine's current physical condition and status are as stated.",
      grade: "X",
      limiting_condition:
        "X — INSUFFICIENT SEARCH (SCI 0.33). No record class covering the current condition of a privately held former launcher area has been searched, and it is not established that such a class exists.",
      null_code: "A12", null_label: "other known typology", null_state: "UNTESTED",
      silence_reading: "UNSEARCHED", sci: [1, 3], l_d2: 0, l_d3: 0,
      predicate_args: { status: "unknown" },
      observations: [],
      silence: [
        { record_class: "County building or demolition permit", expected_record_level: "X2", searched: false },
        { record_class: "EPA / state environmental closure file", expected_record_level: "X2", searched: false },
        { record_class: "Real property disposal record", expected_record_level: "X3", searched: true, outcome: "POSITIVE", result_count: 1, receipt: "sha256 8b02…e4c" },
      ],
    },
  ],
  notes: [
    "B-04 guards against punishing a facility for being ordinary and well-attested at the class level rather than dramatically documented at the instance level.",
  ],
};

/* ================================================================== *
 * A-18 / B-01 · Fairview, Kansas — the critical negative-control pair
 * ================================================================== */

const fairviewKansas: SpecEntity = {
  slug: "fairview-kansas",
  name: "AT&T Fairview hardened relay station, Kansas",
  entity_level: "site",
  jurisdiction: "Brown County, Kansas",
  typology: "relay-comms",
  reference_class: "RC3",
  reference_class_basis: "Private parcel, no federal land status.",
  aliases: ["Fairview L-carrier main station", "AT&T Long Lines Fairview"],
  geometry: { precision: "surveyed", point: [-95.7261, 39.8397], radius_m: 20 },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A hardened subsurface long-haul relay station exists at Fairview.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A05", null_label: "utility vault", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [5, 5], l_d2: 5, l_d3: 3,
      condition_results: { "A1-alt": true },
      observations: [
        ev("e1", "Brown County deed reciting the structure on the parcel.", {
          d: 4, tier: "T1", doc: "Brown County recorder, deed of conveyance", issuer: "Brown County, Kansas",
          date: "1962-04-11", authority: true, lineage: "L1",
          quote: ["together with the underground structure and appurtenances thereon", 1420, 1484],
          fact: "AT&T owned and operated this site" }),
        ev("e4", "First verified direct observation by a resolvable named person with lawful access, with georeferenced imagery matched to a public control point.", {
          d: 3, tier: "T2", doc: "Bylined account with georeferenced imagery", issuer: "Regional newspaper",
          author: "named visitor, resolvable in an unrelated public record", date: "2014-06-01", lineage: "L2",
          quote: ["the blast door at the head of the ramp is still in place", 880, 934] }),
        ev("e5", "Second verified direct observation by a different resolvable named person, likewise georeferenced.", {
          d: 3, tier: "T2", doc: "Second bylined account with georeferenced imagery", issuer: "Regional newspaper",
          author: "second named visitor, resolvable in an unrelated public record", date: "2016-09-01", lineage: "L3",
          quote: ["shock-isolated racks remain bolted to their springs", 610, 660] }),
        ev("e2", "FCC antenna structure registration for the microwave path.", {
          d: 2, tier: "T1", doc: "FCC Antenna Structure Registration", issuer: "Federal Communications Commission",
          date: "1968-01-01", ident: "ASR 1002341", identClass: "FCC-ASR", lineage: "L1",
          fact: "AT&T owned and operated this site" }),
        ev("e3", "AT&T Long Lines corporate engineering record for the station.", {
          d: 3, tier: "T2", doc: "AT&T Long Lines engineering record, L-carrier main station",
          issuer: "AT&T", date: "1964-01-01", lineage: "L1", fact: "AT&T owned and operated this site" }),
      ],
      alternatives: [
        { null_code: "A05", label: "utility vault", description: "Utility vault, substation enclosure or pipeline works", disposition: "EXCLUDED", reasoning: "A utility vault has no blast door and no shock-isolated equipment racks.", excluding: ["e4", "e5"] },
      ],
    },
    {
      /**
       * B-01 · THE CRITICAL NEGATIVE-CONTROL PAIR, with R-02.
       * v0.1 scored the commercial warehouse (60.23 = C) ABOVE the real bunker
       * (56.25 = C). Two cases, opposite ground truths, indistinguishable
       * output. Under BES they must separate by FOUR BANDS in the correct
       * direction: this is B, SubTropolis HARDEN is R.
       */
      ref: "p-HARDEN-1", class: "HARDEN",
      statement: "The station is engineered against blast effects.",
      grade: "B",
      ceiling: "A",
      at_ceiling: false,
      limiting_condition:
        "A1 — no D4 design-standard citation or as-built. The documents that would move this: the AT&T L-carrier hardened-station engineering specification, or a corporate filing citing it.",
      null_code: "A07", null_label: "unhardened data centre", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "VERY-RARE", reference_class: "RC3",
      sci: [4, 5], l_d2: 3, l_d3: 2,
      condition_results: { A1: false, B1: true, B2: true, B3: true, B4: true },
      observations: [
        ev("e3", "AT&T corporate engineering record identifying the site as a hardened L-carrier main station.", {
          d: 3, tier: "T2", doc: "AT&T Long Lines engineering record, L-carrier main station",
          issuer: "AT&T", date: "1964-01-01", lineage: "L1",
          quote: ["hardened main station, L-carrier route", 3210, 3248] }),
        ev("e4", "Direct observation of blast doors and shock-isolated equipment by a resolvable named visitor.", {
          d: 3, tier: "T2", doc: "Bylined account with georeferenced imagery", issuer: "Regional newspaper",
          author: "named visitor", date: "2014-06-01", lineage: "L2",
          fact: "the station has a blast door and shock-isolated equipment",
          quote: ["the blast door at the head of the ramp is still in place", 880, 934] }),
        ev("e5", "Second visitor describing the same door and the same racks.", {
          d: 3, tier: "T2", doc: "Second bylined account", issuer: "Regional newspaper", author: "second named visitor",
          date: "2016-09-01", lineage: "L2",
          fact: "the station has a blast door and shock-isolated equipment",
          rebutted: "§5.1.7 collapses two visitors describing the same door: one observational lineage, not two." }),
        ev("e6", "Compiler page exposing its primaries for the L-carrier route.", {
          d: 2, tier: "T4", doc: "long-lines.net route compilation", channel: "AGGREGATOR", provenance: "SELF-PUBLISHED",
          date: "2005-01-01", lineage: "L3" }),
      ],
      alternatives: [
        { null_code: "A07", label: "unhardened data centre", description: "Commercial data centre or telecom exchange, unhardened", disposition: "EXCLUDED", reasoning: "A repeater hut has no blast door and is not buried.", excluding: ["e4"] },
      ],
      silence: [
        { record_class: "Design-standard citation / as-built", expected_record_level: "X1", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 dd41…903", egress_state: "REACHABLE" },
      ],
      lineage: {
        document_count: 5,
        lineage_count: 2,
        verdict:
          "5 citing documents · 2 independent lineages · collapse delta 3. Two visitors describing the same door are one observational witness, not two.",
        blocks: [
          { origin: { siglum: "L1", label: "AT&T Long Lines engineering record", document_date: "1964-01-01", origin_tier: "T2" }, downstream_count: 1 },
          {
            origin: { siglum: "L2", label: "Bylined visitor account, 2014", document_date: "2014-06-01", origin_tier: "T2" },
            descendants: [{ siglum: "L2b", label: "Second bylined visitor account, 2016 — same object, §5.1.7", document_date: "2016-09-01", origin_tier: "T2", collapses: true }],
            downstream_count: 1,
          },
        ],
      },
    },
    {
      ref: "p-CONTROL-1", class: "CONTROL",
      statement: "The site was owned and operated by AT&T.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A08", null_label: "ordinary government building", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [4, 4], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "Recorded deed chain naming AT&T as grantee.", {
          d: 4, tier: "T1", doc: "Brown County recorder, deed chain", issuer: "Brown County, Kansas",
          date: "1962-04-11", authority: true, lineage: "L1",
          fact: "AT&T owned and operated this site",
          quote: ["conveyed to American Telephone and Telegraph Company", 900, 952] }),
      ],
    },
    {
      /**
       * A-18 · The §3.4(e) discrimination the suite must assert: the SAME FCC
       * record is D4 for FUNCTION(relay) and at most D2 for HARDEN, because the
       * FCC has authority over the LICENCE and not over the HARDENING. If a
       * scorer awards D4 to HARDEN from the FCC record, the suite fails even
       * though the letter for FUNCTION is right. Compare e2 here (d: 4,
       * authority: true) with e2 on p-HARDEN-1 (absent — the FCC row does not
       * appear there at all above D2).
       */
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement: "The station carried a hardened long-haul microwave and coaxial relay function.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A05", null_label: "utility vault", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "UNCOMMON", sci: [4, 4], l_d2: 3, l_d3: 3,
      observations: [
        ev("e2", "FCC ULS/ASR record naming the licensee and the microwave path.", {
          d: 4, tier: "T1", doc: "FCC Universal Licensing System record", issuer: "Federal Communications Commission",
          date: "1968-01-01", ident: "ASR 1002341", identClass: "FCC-ASR", authority: true, lineage: "L1",
          quote: ["point-to-point microwave path, Fairview KS to the adjacent main station", 410, 482] }),
        ev("e3", "AT&T route literature describing the station's place in the L-carrier network.", {
          d: 3, tier: "T2", doc: "AT&T Long Lines engineering record", issuer: "AT&T", date: "1964-01-01", lineage: "L2" }),
      ],
    },
    {
      ref: "p-LOCATE-1", class: "LOCATE",
      statement: "The station is located at the parcel coordinate given, to within 20 m.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "Parcel geometry from the county cadastre, matched to a public control point.", {
          d: 4, tier: "T1", doc: "Brown County parcel geometry", issuer: "Brown County, Kansas", date: "2019-01-01",
          authority: true, lineage: "L1", quote: ["parcel 041-22-0-00-00-003.00", 40, 68] }),
      ],
    },
  ],
  notes: [
    "S-1 · Fairview (B-01) and SubTropolis (R-02) must be separated by four bands in the correct direction.",
    "A-18 fact-key merge assertion: e1 (deed), e2 (ASR) and e3 (Long Lines records) all assert fact_key 'AT&T owned and operated this site' and merge to the strongest for L-counting. One fact must not enter as three lineages.",
    "B-01 compiler-transparency branch: long-lines.net is T4 and exposes its primaries. If the underlying Bell System Practice resolves, the PRIMARY is the lineage and the compiler scores nothing. If it does not resolve, long-lines.net is one T4 terminus at catalog D2, e3 falls to D2, L(D3) = 1, CAP-1 fires and HARDEN is C with limiting_condition 'B1'. The model must publish which reading it took and why. This fixture takes the resolving branch.",
  ],
};

/* ================================================================== *
 * B-03 · PEF "Cartwheel", Fort Reno Park — MARGINAL, branch named
 * ================================================================== */

const pefCartwheel: SpecEntity = {
  slug: "pef-cartwheel-fort-reno",
  name: "Presidential Emergency Facility \"Cartwheel\", Fort Reno Park",
  entity_level: "site",
  jurisdiction: "District of Columbia",
  typology: "cog-coop",
  reference_class: "RC2",
  reference_class_basis: "Municipal parkland with a documented federal use.",
  aliases: ["Cartwheel", "Fort Reno PEF"],
  geometry: { precision: "surveyed", point: [-77.0776, 38.9520], radius_m: 60 },
  propositions: [
    {
      /**
       * B-03 · MARGINAL. The branch the calibration text cannot settle: if the
       * WHCA records name Fort Reno at INSTANCE level the entry is A; if they
       * document the PEF network at CLASS level the instance record is
       * scope = CLASS, excluded from V, and the entry reaches C via C1c.
       * EITHER OUTCOME PASSES, but `marginal_flag` MUST be TRUE and the branch
       * taken must be named in `limiting_condition`. This fixture takes the
       * instance branch and says so.
       */
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A Presidential Emergency Facility exists beneath Fort Reno Park.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      marginal_flag: true,
      limiting_condition:
        "MARGINAL — branch taken: the White House Army Signal Agency records name Fort Reno at INSTANCE level, so e1 enters V and A1 holds. On the alternative reading the same record documents the PEF network at CLASS level, e1 is excluded from V, and the entry reaches C via C1c on candidate-set membership. One contested fact decided this band.",
      null_code: "A08", null_label: "ordinary government building", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "RARE", sci: [4, 5], l_d2: 3, l_d3: 3,
      condition_results: { A1: true, A2: true, A3: true, A4: true, A5: true, A6: true, C1c: null },
      observations: [
        ev("e1", "White House Army Signal Agency record naming the Fort Reno facility.", {
          d: 4, tier: "T1", doc: "White House Army Signal Agency / WHCA record", issuer: "White House Communications Agency",
          date: "1963-01-01", authority: true, lineage: "L1",
          quote: ["emergency facility, Fort Reno, District of Columbia", 2010, 2062] }),
        ev("e2", "PEF microwave-network documentation showing a path terminating at the site.", {
          d: 3, tier: "T1", doc: "PEF microwave network documentation", issuer: "White House Communications Agency",
          date: "1965-01-01", lineage: "L2" }),
        ev("e3", "AT&T cable route record showing a direct route to the White House.", {
          d: 3, tier: "T2", doc: "AT&T cable route record", issuer: "AT&T", date: "1964-01-01", lineage: "L3" }),
        ev("e4", "Transparent compiler collation of the PEF network, exposing its primaries.", {
          d: 2, tier: "T4", doc: "PEF network collation", channel: "AGGREGATOR", provenance: "SELF-PUBLISHED",
          date: "2012-01-01", lineage: "L3" }),
      ],
    },
    {
      ref: "p-EXTENT-1", class: "EXTENT",
      statement: "The facility's internal extent and current condition are as described.",
      grade: "D",
      ceiling: "C",
      at_ceiling: false,
      limiting_condition:
        "A1/B1 — internal extent and current condition are partly inferred. The documents that would move this: an as-built drawing set, or a GSA condition survey naming the structure.",
      null_code: "A05", null_label: "utility vault", null_state: "SURVIVING",
      silence_reading: "UNINFORMATIVE", sci: [2, 5], l_d2: 2, l_d3: 0,
      observations: [
        ev("e1", "Surface features consistent with a subsurface structure in the park.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "DC orthoimagery", issuer: "District of Columbia",
          date: "2021-01-01", lineage: "L1" }),
        ev("e2", "Network documentation implying an equipment volume without stating one.", {
          d: 2, tier: "T1", doc: "PEF microwave network documentation", issuer: "White House Communications Agency",
          date: "1965-01-01", lineage: "L2" }),
      ],
    },
  ],
  notes: [
    "B-03 · v0.1 returned 53.11 → D, 'weak inference' — because the GEO axis finds nothing to reward in a city park and CONTAM penalised the fact that one careful compiler did the collation. Transparent-compiler pass-through (§5.1.3) is what drags Cartwheel out of D.",
    "A run that returns A or C without the marginal flag has failed.",
  ],
};

/* ================================================================== *
 * C-01 · Federal Relocation Arc site — C via C1c, ceiling C
 * The real-but-unlocated test. A REGIONAL POLYGON, never a pin.
 * ================================================================== */

const relocationArcSite: SpecEntity = {
  slug: "federal-relocation-arc-site-07",
  name: "Unnamed Federal Relocation Arc site (candidate 7 of 12)",
  entity_level: "site",
  jurisdiction: "Frederick County, Maryland",
  typology: "cog-coop",
  reference_class: "RC2",
  reference_class_basis: "Adjacent to, but outside, a federal installation boundary (PAD-US).",
  aliases: [],
  /**
   * C-01 LOCATE assertion, verbatim: "non_located, or a regional polygon.
   * NEVER a pin. A precise pin manufactured from imprecise evidence is the
   * register performing its own citogenesis at the interface layer."
   * This fixture takes the regional polygon so the region rendering is
   * exercised: dotted boundary, dot-screened interior, NO CENTRE MARK.
   */
  geometry: {
    precision: "regional",
    polygon: [
      [-77.60, 39.35], [-77.20, 39.35], [-77.20, 39.62], [-77.60, 39.62],
    ],
    chart_tags: ["PA", "Rep"],
  },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A federal relocation facility of the documented programme exists at this candidate site.",
      grade: "C",
      ceiling: "C",
      at_ceiling: true,
      ceiling_reason: "Ceiling C by rule: the C1c candidate-set route cannot exceed band C.",
      limiting_condition:
        "A1/B1 — no instance-level dispositive record; grade rests on membership in a documented candidate set of M=12 against N=8.",
      null_code: "A08", null_label: "ordinary government building", null_state: "SURVIVING",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "UNCOMMON", reference_class: "RC2",
      sci: [5, 6], l_d2: 2, l_d3: 0,
      condition_results: { A1: false, B1: false, C1a: false, C1c: true },
      observations: [
        ev("e1", "Declassified Office of Emergency Planning record describing the programme and its facilities — CLASS scope.", {
          d: 3, scope: "CLASS", tier: "T1", doc: "Declassified OEP relocation programme record",
          issuer: "Office of Emergency Planning", date: "1964-01-01", lineage: "L1",
          quote: ["a series of relocation facilities was established along the arc", 3120, 3178] }),
        ev("e2", "WHCA microwave path record terminating at this coordinate — INSTANCE scope, ties the candidate to the set.", {
          d: 1, tier: "T1", doc: "White House Army Signal Agency microwave path record",
          issuer: "White House Communications Agency", date: "1965-01-01", lineage: "L2",
          quote: ["path terminus, Frederick County", 810, 842] }),
        ev("e3", "AT&T cable route entering the parcel.", {
          d: 1, tier: "T2", doc: "AT&T cable route record", issuer: "AT&T", date: "1964-01-01", lineage: "L3" }),
      ],
      alternatives: [
        { null_code: "A08", label: "ordinary government building", description: "Ordinary above-ground government building", disposition: "SURVIVING", reasoning: "A conventional federal building served by the same microwave path would produce the instance-level rows equally well. The class record does not discriminate between the twelve candidates.", excluding: [] },
      ],
      searches: [
        { query: "OEP relocation facility Frederick County", corpus_as_of: "2026-07-01", outcome: "NEGATIVE", result_count: 0, erp_profile: "OEP-programme", egress_state: "REACHABLE" },
      ],
      movement: [
        { occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "C", cause: "INITIAL" },
        { occurred_at: "2026-06-18T00:00:00Z", from: "C", to: "C", cause: "CANDIDATE-SET-CHANGE", note: "A thirteenth candidate was added; M recomputed for all twelve members. M = 12 against N = 8 still satisfies M ≤ 3N, so the band holds. Adding candidates dilutes." },
      ],
    },
    {
      ref: "p-LOCATE-1", class: "LOCATE",
      statement: "The site lies within the region shown.",
      grade: "D",
      ceiling: "C",
      at_ceiling: false,
      limiting_condition:
        "No instance-level positional record. The register knows the region and does not know the point. The mark is the region.",
      null_code: "A01", null_label: "no constructed object", null_state: "SURVIVING",
      silence_reading: "UNINFORMATIVE", sci: [3, 6], l_d2: 1, l_d3: 0,
      observations: [
        ev("e1", "Microwave path terminus bounding the candidate area.", {
          d: 1, tier: "T1", doc: "White House Army Signal Agency microwave path record",
          issuer: "White House Communications Agency", date: "1965-01-01", lineage: "L1" }),
      ],
    },
    {
      ref: "p-PROGRAM-1", class: "PROGRAM",
      statement: "A federal relocation programme establishing a set of such facilities existed.",
      grade: "A",
      ceiling: "A",
      at_ceiling: true,
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [4, 4], l_d2: 4, l_d3: 3,
      observations: [
        ev("e1", "Declassified OEP record establishing the programme.", {
          d: 4, tier: "T1", doc: "Declassified OEP relocation programme record", issuer: "Office of Emergency Planning",
          date: "1964-01-01", authority: true, lineage: "L1",
          quote: ["the relocation programme comprised eight documented installations", 3200, 3266] }),
      ],
    },
  ],
  notes: [
    "C-01 · C1c fires if and only if: the candidate set is enumerated, closed and published; N and M are published; M ≤ 3N; and at least one verified instance-scope CLAIM-PROPERTY row at D1+ ties this candidate to the set.",
    "THE DILUTION ASSERTION: adding a thirteenth candidate recomputes M for all twelve as a versioned CANDIDATE-SET-CHANGE; if M exceeds 3N the whole set drops to D. Adding candidates dilutes. This is the standing countermeasure to a find-rewarded fleet's regional-gap-filling incentive.",
  ],
};

export const ACKNOWLEDGED_ENTITIES: SpecEntity[] = [
  cheyenneMountain,
  ravenRock,
  thirtyThreeThomas,
  mountWeather,
  ironMountainBoyers,
  titanII,
  campHero,
  mountPony,
  manzanoBase,
  kummsc,
  groomLake,
  sf88l,
  nikeUnrestored,
  fairviewKansas,
  pefCartwheel,
  relocationArcSite,
];
