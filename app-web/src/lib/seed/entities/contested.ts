/**
 * SPECIMEN ENTITIES — the contested cases.
 *
 * CALIBRATION CASES A-05, A-10, A-11, A-14, B-05, C-02, D-01, E-01, E-02,
 * R-02, R-03, R-04.
 *
 * These are the entries where the register's mechanisms bite, and each one is
 * a case where a plausible model returns the right letter by the wrong route.
 * The suite scores the route, not the letter: "two of the historically most
 * dangerous failures (SubTropolis reaching the right band by the wrong route,
 * DIA reaching E without CAP-2b) produce a correct letter from a broken
 * mechanism."
 *
 * SPECIMEN DATA. Quoted spans are plausible reconstructions written for this
 * fixture, not verbatim transcriptions — no citation in this register has been
 * resolved to bytes (D-007).
 */

import type { SpecEntity } from "../types";
import { ev, negativeReceipt } from "../dsl";

/* ================================================================== *
 * B-05 / C-02 / D-01 / E-02 / A-05 · The Greenbrier — THE FLAGSHIP
 *
 * One entity decomposing across B / C / D / E on one page, at
 * as_of 1991-01-01, with the 1992 disclosure recorded as MOVEMENT.
 * v0.1 returned 22.91 -> E, "folklore with a trace" — printed over an
 * operating congressional relocation facility.
 * ================================================================== */

const greenbrier: SpecEntity = {
  slug: "greenbrier-project-greek-island",
  name: "The Greenbrier / Project Greek Island",
  entity_level: "site",
  jurisdiction: "Greenbrier County, West Virginia",
  typology: "cog-coop",
  reference_class: "RC5",
  reference_class_basis:
    "A resort on private land. RC5 is taken because §6.5 requires the LOWEST reading when the reference class is ambiguous.",
  aliases: ["Project Greek Island", "The Bunker at the Greenbrier", "West Virginia Wing"],
  geometry: { precision: "surveyed", point: [-80.3006, 37.7856] },
  propositions: [
    {
      /**
       * B-05 · REVIEWER CONFLICT (historian: C on evidence; IC: B).
       * BES takes the IC reading: three verified claim-property lineages
       * satisfy B1's second clause on the record alone. BES ALSO DECLINES the
       * historian's requested form — a published probability — and substitutes
       * at_ceiling + silence_reading + base_rate_reading.
       */
      ref: "p-EXIST-1", class: "EXIST",
      statement:
        "A large hardened subsurface structure was built beneath the West Virginia Wing.",
      as_of_date: "1991-01-01",
      grade: "B",
      ceiling: "B",
      at_ceiling: true,
      ceiling_reason:
        "At ceiling: the expected-record profile for an active facility under commercial cover predicts no dispositive documentary class, so no route above B is reachable from the record as it stands.",
      marginal_flag: true,
      limiting_condition:
        "A1 — no dispositive primary record; the expected-record profile predicts none. A1's second clause reads 'two rows at D3 in two independent lineages, both CLAIM-PROPERTY', which e4 and e5 satisfy on their face — but they describe the SAME OBJECT, and §5.5 fact-key merging collapses them to one row for A1 purposes.",
      null_code: "A10", null_label: "civil-defence designation only", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE",
      base_rate_reading: "VERY-RARE",
      reference_class: "RC5",
      sci: [6, 6],
      l_d2: 5, l_d3: 2,
      condition_results: { A1: false, B1: true, B2: true, B3: true, B4: true },
      observations: [
        ev("e1", "Greenbrier County recorder: construction and parcel records for the 1958–61 West Virginia Wing.", {
          d: 2, tier: "T1", doc: "Greenbrier County recorder, construction and parcel records",
          issuer: "Greenbrier County, West Virginia", date: "1959-06-01", lineage: "L1",
          quote: ["addition to the West Virginia Wing, excavation and concrete", 610, 668] }),
        ev("e2", "Local press 1959–62: anomalous concrete volumes, out-of-state contractors, sustained heavy trucking.", {
          d: 2, tier: "T2", doc: "Local press coverage, 1959–1962", issuer: "Regional newspaper",
          date: "1960-04-12", corpus: "Chronicling America / Open ONI", lineage: "L2",
          quote: ["concrete deliveries have continued through the winter at a rate the addition does not explain", 220, 322] }),
        ev("e3", "Utility filing: electrical service far exceeding the above-ground floor area.", {
          d: 2, tier: "T1", doc: "Utility service filing", issuer: "West Virginia Public Service Commission",
          date: "1962-01-01", lineage: "L3" }),
        ev("e4", "Named construction worker, resolvable in a union roll and in an obituary created for an unrelated purpose, describing a concrete structure with a heavy steel door. Custody satisfied by a bylined quotation in named local press.", {
          d: 3, tier: "T2", doc: "Bylined local press interview", issuer: "Regional newspaper",
          author: "named construction worker (resolvable, §5.4 satisfied)", date: "1983-05-01", lineage: "L4",
          fact: "a large hardened subsurface structure was built under the West Virginia Wing",
          quote: ["there was a door on it you could not have moved with a truck", 1420, 1478] }),
        ev("e5", "Second named worker, likewise resolvable and bylined, describing the same excavation and the same door.", {
          d: 3, tier: "T2", doc: "Second bylined local press interview", issuer: "Regional newspaper",
          author: "second named construction worker (resolvable)", date: "1986-09-01", lineage: "L5",
          fact: "a large hardened subsurface structure was built under the West Virginia Wing",
          rebutted: "§5.5 fact-key merge: e4 and e5 describe the SAME OBJECT — one door, one excavation. They collapse to one row for A1 purposes. This is the deliberate hinge on which the band turns, and it is why marginal_flag is TRUE." }),
      ],
      alternatives: [
        { null_code: "A10", label: "civil-defence designation only", description: "Civil-defence shelter designation only", disposition: "EXCLUDED", reasoning: "A shelter designation produces no unexplained concrete volume, no out-of-state contractor pattern and no electrical service exceeding the above-ground floor area.", excluding: ["e1", "e3", "e4"] },
        { null_code: "A06", label: "general storage", description: "Agricultural, cold or general storage", disposition: "EXCLUDED", reasoning: "Storage does not require a blast door or a dedicated service of this magnitude.", excluding: ["e4"] },
      ],
      /**
       * THE NEGATIVE RECEIPTS ASSERTION. Searches against CREST, DTIC, NARA,
       * GovInfo, FRPP and GSA disposal were EXECUTED AND LOGGED, and every
       * profile returns X0 under "active facility under commercial cover" ->
       * NO ROWS. A run that scores those absences against the facility has
       * failed, and that is precisely what v0.1 did.
       */
      silence: [
        { record_class: "CREST", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 1c9a…4b2", egress_state: "REACHABLE" },
        { record_class: "DTIC", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 88fe…d31", egress_state: "REACHABLE" },
        { record_class: "NARA", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 40b7…9ac", egress_state: "REACHABLE" },
        { record_class: "GovInfo appropriations", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 e21d…770", egress_state: "REACHABLE" },
        { record_class: "Federal Real Property Profile", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 6b44…08c", egress_state: "REACHABLE" },
        { record_class: "County deed", expected_record_level: "X3", searched: true, outcome: "POSITIVE", result_count: 2, receipt: "sha256 fa02…31d", egress_state: "REACHABLE" },
        { record_class: "Historical topographic map", expected_record_level: "X3", searched: true, outcome: "POSITIVE", result_count: 1, receipt: "sha256 2e58…bb9", egress_state: "REACHABLE" },
      ],
      searches: [
        { query: "\"Greek Island\" OR \"Greenbrier\" relocation facility", corpus_as_of: "1991-01-01", outcome: "NEGATIVE", result_count: 0, erp_profile: "COG-under-commercial-cover", egress_state: "REACHABLE" },
        { query: "Greenbrier County recorder West Virginia Wing 1958..1961", corpus_as_of: "1991-01-01", outcome: "POSITIVE", result_count: 2 },
      ],
      lineage: {
        document_count: 7,
        lineage_count: 5,
        verdict:
          "7 citing documents · 5 independent lineages · collapse delta 2. Two workers describing one door are one witness to that fact; the three documentary lineages are independent of them and of each other.",
        blocks: [
          { origin: { siglum: "L1", label: "Greenbrier County recorder, construction records", document_date: "1959-06-01", origin_tier: "T1" }, downstream_count: 0 },
          { origin: { siglum: "L2", label: "Local press, 1959–1962", document_date: "1960-04-12", origin_tier: "T2" }, downstream_count: 1 },
          { origin: { siglum: "L3", label: "Utility service filing", document_date: "1962-01-01", origin_tier: "T1" }, downstream_count: 0 },
          {
            origin: { siglum: "L4", label: "Bylined worker interview, 1983", document_date: "1983-05-01", origin_tier: "T2" },
            descendants: [{ siglum: "L5", label: "Second bylined worker interview, 1986 — same object, §5.5 merge", document_date: "1986-09-01", origin_tier: "T2", collapses: true }],
            downstream_count: 1,
          },
        ],
      },
      movement: [
        { occurred_at: "1991-01-01T00:00:00Z", from: "X", to: "B", cause: "INITIAL", note: "The 1991 vector. grade_as_of('1991-06-01') must still return this after the 1992 re-grade lands." },
        { occurred_at: "1992-05-31T00:00:00Z", from: "B", to: "A", cause: "NEW-DISCLOSURE", note: "Gup, T., The Washington Post, 31 May 1992; then official acknowledgment, decommissioning, declassification and public tours. THE PUBLICATION RECORD CHANGED; THE WORLD DID NOT." },
      ],
      see_limits: ["L-3"],
    },
    {
      /**
       * C-02 · CAP-1 applied, at_ceiling TRUE. Only e4/e5 describe the steel
       * door; the fact-key merge takes L(D3) to 1, so B1 fails. C1a holds — a
       * resolvable witness's description of a blast door is CLAIM-PROPERTY at
       * D3 — and the grade is C with CAP-1 confirmed.
       */
      ref: "p-HARDEN-1", class: "HARDEN",
      statement: "The structure is engineered against blast effects.",
      as_of_date: "1991-01-01",
      grade: "C",
      ceiling: "C",
      at_ceiling: true,
      applied_caps: ["CAP-1"],
      limiting_condition:
        "B1 — fewer than three independent D2 lineages bear on hardening. §5.5 fact-key merging collapses e4 and e5 to one witness to one door, so L(D3) = 1. CAP-1 applies. The document that would move this: a design-standard citation or an as-built naming protective engineering at this structure.",
      null_code: "A10", null_label: "civil-defence designation only", null_state: "EXCLUDED",
      silence_reading: "UNINFORMATIVE",
      base_rate_reading: "VERY-RARE",
      sci: [5, 6], l_d2: 2, l_d3: 1,
      condition_results: { A1: false, B1: false, C1a: true },
      observations: [
        ev("e4", "Named worker's description of a heavy steel door.", {
          d: 3, tier: "T2", doc: "Bylined local press interview", issuer: "Regional newspaper",
          author: "named construction worker (resolvable)", date: "1983-05-01", lineage: "L1",
          fact: "the structure has a blast door",
          quote: ["there was a door on it you could not have moved with a truck", 1420, 1478] }),
        ev("e5", "Second named worker describing the same door.", {
          d: 3, tier: "T2", doc: "Second bylined local press interview", issuer: "Regional newspaper",
          author: "second named construction worker", date: "1986-09-01", lineage: "L1",
          fact: "the structure has a blast door",
          rebutted: "§5.5 fact-key merge with e4: one door, one witness." }),
      ],
      alternatives: [
        { null_code: "A10", label: "civil-defence designation only", description: "Civil-defence shelter designation only", disposition: "EXCLUDED", reasoning: "A designation does not install a blast door.", excluding: ["e4"] },
      ],
    },
    {
      /**
       * D-01 · CAP-2b must appear in applied_caps EVEN THOUGH IT DID NOT BIND.
       * "A run that reaches D without recording the cap is recording a
       * different mechanism than the one that ran."
       * grade = min(D, E) = D.
       */
      ref: "p-CONTROL-1", class: "CONTROL",
      statement: "The facility is federally controlled.",
      as_of_date: "1991-01-01",
      grade: "D",
      grade_pre_clamp: "D",
      ceiling: "E",
      at_ceiling: true,
      applied_caps: ["CAP-2b"],
      ceiling_reason:
        "CAP-2b — V[claim] is empty: the power anomaly is PLACE-PROPERTY and would be recorded identically under the null. The cap holds the maximum at E; the D conditions hold on their own, so grade = min(D, E) = D and the cap did not bind. It is recorded because it ran.",
      limiting_condition:
        "A1/B1 — the cover entity of record is Forsythe Associates, a television-service contractor. Negative receipts against the FPDS predecessor, GSA inventory, FRPP and the deed chain all return X0 under the expected-record profile and therefore produce no rows.",
      null_code: "A10", null_label: "civil-defence designation only", null_state: "SURVIVING",
      silence_reading: "UNINFORMATIVE",
      base_rate_reading: "VERY-RARE",
      sci: [5, 6], l_d2: 1, l_d3: 0,
      condition_results: { A1: false, B1: false, C1a: false, D1: true, D2: true },
      observations: [
        ev("e1", "Utility service anomaly: electrical load exceeding the above-ground floor area.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "Utility service filing",
          issuer: "West Virginia Public Service Commission", date: "1962-01-01", lineage: "L1" }),
        ev("e2", "Deed chain naming the resort corporation and no federal party.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "Greenbrier County recorder, deed chain",
          issuer: "Greenbrier County, West Virginia", date: "1959-01-01", lineage: "L2" }),
      ],
      alternatives: [
        { null_code: "A10", label: "civil-defence designation only", description: "Civil-defence shelter designation only", disposition: "SURVIVING", reasoning: "A privately owned hardened annexe under a service contract accounts for every verified row. Nothing in V is a claim property of federal control.", excluding: [] },
      ],
      silence: [
        { record_class: "FPDS predecessor procurement", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 9a13…c05" },
        { record_class: "GSA inventory", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 71b8…2df" },
        { record_class: "Federal Real Property Profile", expected_record_level: "X0", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 44c1…6ea" },
      ],
    },
    {
      /**
       * E-02 · REVIEWER CONFLICT (IC: F). THE CASE CAP-2b WAS WRITTEN FOR, and
       * the single hardest constraint in the anti-gaming ledger: no FUNCTION
       * claim exceeds E without a verified, instance-scope, subject-bound,
       * CLAIM-PROPERTY observation. The IC's F is declined because V IS NOT
       * EMPTY. E — "verified support exists but fails to discriminate" — is the
       * accurate description.
       *
       * The stave renders this without a word: the UPPER STOREY IS EMPTY.
       */
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement: "The facility served as a congressional relocation site.",
      as_of_date: "1991-01-01",
      grade: "E",
      grade_pre_clamp: "D",
      ceiling: "E",
      at_ceiling: true,
      applied_caps: ["CAP-2b"],
      ceiling_reason:
        "CAP-2b binding — |V[claim]| = 0. What remains in V is the communications plant sized far beyond resort needs, and that is PLACE-PROPERTY.",
      limiting_condition:
        "CAP-2b — no verified, instance-scope, subject-bound CLAIM-PROPERTY observation. In 1991 the local attribution is diffuse, unattributed town talk: self-attesting and unresolvable, excluded from V under §2.5. The document that would move this: any instance-level record from a party with authority over the facility's function.",
      null_code: "A10", null_label: "civil-defence designation only", null_state: "SURVIVING",
      silence_reading: "UNINFORMATIVE",
      base_rate_reading: "VERY-RARE",
      reference_class: "RC5",
      sci: [5, 6], l_d2: 1, l_d3: 0,
      condition_results: { A1: false, B1: false, C1a: false, D1: true, E1: true, E2: false },
      observations: [
        ev("e1", "Communications plant sized far beyond resort requirements.", {
          d: 2, locus: "PLACE-PROPERTY", tier: "T1", doc: "Utility and communications service filing",
          issuer: "West Virginia Public Service Commission", date: "1962-01-01", lineage: "L1",
          quote: ["circuit provisioning at this location exceeds the establishment's stated requirement", 1810, 1898] }),
        ev("e2", "Diffuse, unattributed local attribution of the facility's purpose.", {
          d: 0, tier: "T5", doc: "Unattributed local account", date: "1988-01-01",
          selfAttesting: "the account is the claim and no claimant is resolvable; §2.5 excludes it from V and routes it to ORIGIN",
          lineage: "L2" }),
      ],
      alternatives: [
        { null_code: "A10", label: "civil-defence designation only", description: "A private hardened shelter for hotel guests", disposition: "SURVIVING", reasoning: "A privately provisioned shelter for guests explains the plant sizing as completely as the relocation claim does. Nothing verified discriminates between them.", excluding: [] },
      ],
      movement: [
        { occurred_at: "1991-01-01T00:00:00Z", from: "X", to: "E", cause: "INITIAL" },
        { occurred_at: "1992-05-31T00:00:00Z", from: "E", to: "A", cause: "NEW-DISCLOSURE", note: "The publication record changed; the world did not." },
      ],
    },
  ],
  notes: [
    "A-05 · The regression test is the PAIR with B-05/C-02/D-01/E-02. The system must record that the 1992 transition was caused by DISCLOSURE, not by the arrival of new evidence about the physical world.",
    "S-5 · grade_as_of('1991-06-01') must still return the 1991 vector after the 1992 re-grade lands, and grade_history must name the Gup article as the observation that moved it.",
    "B-05 boundary demonstrations: if only ONE worker resolves, L(D3) = 1 and L(D2) = 4 — B1's second clause still holds on the three documentary lineages, so still B. If the utility filing also fails, L(D2) = 2 < 3 and L(D3) = 1 → CAP-1 → C, limiting_condition 'B1 — fewer than three independent D2 lineages.'",
  ],
};

/* ================================================================== *
 * A-14 / R-02 · SubTropolis — THE CRITICAL NEGATIVE CONTROL
 * v0.1 gives it 60.23 = C, OUTRANKING the real AT&T bunker at 56.25.
 * ================================================================== */

const subtropolis: SpecEntity = {
  slug: "subtropolis",
  name: "SubTropolis, Kansas City",
  entity_level: "site",
  jurisdiction: "Jackson County, Missouri",
  typology: "mine-conversion",
  reference_class: "RC3",
  reference_class_basis: "Private industrial parcel, no federal land status.",
  aliases: ["Hunt Midwest SubTropolis"],
  geometry: { precision: "surveyed", point: [-94.5044, 39.1483] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A large room-and-pillar limestone mine converted to commercial warehousing exists here.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [5, 5], l_d2: 5, l_d3: 4,
      observations: [
        ev("e1", "MSHA regulated-mine permit and inspection record.", {
          d: 4, tier: "T1", doc: "MSHA mine record and inspection history", issuer: "Mine Safety and Health Administration",
          date: "1980-01-01", authority: true, lineage: "L1",
          quote: ["underground limestone, room and pillar, Kansas City, Missouri", 210, 268] }),
        ev("e2", "Recorded leases and title chain at the Jackson County recorder.", {
          d: 4, tier: "T1", doc: "Jackson County recorder, lease and title records",
          issuer: "Jackson County, Missouri", date: "1990-01-01", authority: true, lineage: "L2",
          quote: ["lease of underground warehouse space", 1120, 1156] }),
        ev("e3", "Surveyed geometry of the workings in the state geological record.", {
          d: 3, locus: "PLACE-PROPERTY", tier: "T1", doc: "Missouri DNR geological survey record",
          issuer: "Missouri Department of Natural Resources", date: "2005-01-01", lineage: "L3" }),
        ev("e4", "The operator's own published material describing the facility.", {
          d: 2, tier: "T2", doc: "Operator facility description", issuer: "Hunt Midwest", date: "2018-01-01",
          provenance: "SELF-PUBLISHED", lineage: "L4" }),
      ],
    },
    {
      ref: "p-TYPOLOGY-1", class: "TYPOLOGY",
      statement: "The facility is a commercial underground warehousing operation.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [4, 4], l_d2: 4, l_d3: 3,
      observations: [
        ev("e1", "MSHA classification of the workings.", {
          d: 4, tier: "T1", doc: "MSHA mine record", issuer: "Mine Safety and Health Administration",
          date: "1980-01-01", authority: true, lineage: "L1", quote: ["underground limestone mine, active", 210, 244] }),
        ev("e2", "Published tenant lease list at the county recorder.", {
          d: 3, tier: "T1", doc: "Jackson County recorder, tenant lease list", issuer: "Jackson County, Missouri",
          date: "2015-01-01", lineage: "L2" }),
      ],
    },
    {
      ref: "p-CONTROL-1", class: "CONTROL",
      statement: "The facility is owned and operated by Hunt Midwest.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A08", null_label: "ordinary government building", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "Recorded title chain naming the operator.", {
          d: 4, tier: "T1", doc: "Jackson County recorder, title chain", issuer: "Jackson County, Missouri",
          date: "1990-01-01", authority: true, lineage: "L1", quote: ["title vested in Hunt Midwest", 300, 328] }),
      ],
    },
    {
      /**
       * R-02 · TWO INDEPENDENT ROUTES, AND THE SUITE MUST CHECK BOTH.
       * R2 fires on U1 and U2 with null_state DOMINANT. Had refutation not
       * fired, CAP-2b caps at E anyway — so a run that reaches R via CAP-2b
       * rather than R2 has the right letter from the wrong mechanism.
       */
      ref: "p-HARDEN-1", class: "HARDEN",
      statement: "The facility is engineered against blast and electromagnetic-pulse effects.",
      grade: "R",
      refutation_state: "R2",
      ceiling: "E",
      applied_caps: ["CAP-2b"],
      ceiling_reason:
        "R2 — two independent-lineage verified UNDERCUTS rows at D2+ improbable under the proposition (the published tenant lease list and the operator's advertised public tours), plus null_state DOMINANT. §8.4's gate is satisfied because U1 and U2 are AFFIRMATIVE content, not expected-record negatives. The independent route: CAP-2b caps at E on |V[claim]| = 0.",
      limiting_condition:
        "R2 established. Every place-signal the site offers — portals into hillside, ventilation shafts, spoil history, road grade, a dedicated substation, a rail spur, deep wells, fuel permits — is on the universal-D0 list and satisfies zero conditions above D.",
      null_code: "A02", null_label: "commercial mine or cavern", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "VERY-RARE",
      sci: [5, 5], l_d2: 0, l_d3: 0,
      condition_results: { A1: false, B1: false, C1a: false, D1: false, E1: true, R2: true },
      predicate_args: {
        claim_text: "SubTropolis is a blast- and EMP-hardened facility.",
        first_appearance_date: "1998-01-01",
        first_appearance_confidence: "first observation",
      },
      observations: [
        ev("e1", "Portals into the hillside, ventilation shafts and spoil history.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "Missouri DNR geological survey record",
          issuer: "Missouri Department of Natural Resources", date: "2005-01-01", lineage: "L1" }),
        ev("e2", "Dedicated substation and rail spur in the utility and rail records.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "Utility and rail service records",
          issuer: "Missouri Public Service Commission", date: "1996-01-01", lineage: "L2" }),
        ev("u1", "Published tenant lease list: ordinary commercial tenants on recorded leases.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Jackson County recorder, tenant lease list",
          issuer: "Jackson County, Missouri", date: "2015-01-01", ea: ["E0", "A3"], refutes: "R2", lineage: "U1",
          quote: ["schedule of tenants and demised premises", 90, 128] }),
        ev("u2", "Operator marketing with named tenants, published square footage and public site tours.", {
          d: 3, sign: "UNDERCUTS", tier: "T2", doc: "Operator marketing material and tour schedule",
          issuer: "Hunt Midwest", date: "2019-01-01", ea: ["E0", "A3"], refutes: "R2", lineage: "U2",
          quote: ["tours of the underground business complex are offered by appointment", 410, 478] }),
        ev("u3", "MSHA regulated-mine permit: the workings are a regulated active mine.", {
          d: 1, sign: "UNDERCUTS", tier: "T1", doc: "MSHA mine record", issuer: "Mine Safety and Health Administration",
          date: "1980-01-01", ea: ["E1", "A3"], lineage: "U1" }),
      ],
      alternatives: [
        { null_code: "A02", label: "commercial mine or cavern", description: "A room-and-pillar limestone mine converted to commercial warehousing", is_selected: true, disposition: "DOMINANT", reasoning: "This null is DOCUMENTED AND PUBLICLY ADVERTISED BY THE OPERATOR, which is why it is the strongest surviving alternative. It is affirmatively documented by MSHA records, recorded leases and Missouri DNR filings, and it accounts for every row in V.", excluding: [] },
      ],
      movement: [
        { occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "E", cause: "INITIAL" },
        { occurred_at: "2026-05-02T00:00:00Z", from: "E", to: "R", cause: "REFUTATION", note: "R2 established on U1 and U2." },
      ],
    },
    {
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement: "The facility serves a continuity-of-government function.",
      grade: "R",
      refutation_state: "R2",
      ceiling: "E",
      applied_caps: ["CAP-2b"],
      ceiling_reason:
        "R2 on the same two independent UNDERCUTS lineages, with null_state DOMINANT. CAP-2b independently caps at E on |V[claim]| = 0.",
      limiting_condition:
        "R2 established. A reader who arrives believing SubTropolis is a bunker leaves with the refutation and its sources — published beside the EXIST, TYPOLOGY and CONTROL propositions, where the same facility grades A on what it actually is.",
      null_code: "A02", null_label: "commercial mine or cavern", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE", base_rate_reading: "VERY-RARE",
      sci: [5, 5], l_d2: 0, l_d3: 0,
      predicate_args: {
        claim_text: "SubTropolis serves a continuity-of-government function.",
        first_appearance_date: "1998-01-01",
        first_appearance_confidence: "first observation",
      },
      observations: [
        ev("e1", "Deep wells and fuel permits on the parcel.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "State well and fuel storage permits",
          issuer: "Missouri Department of Natural Resources", date: "2001-01-01", lineage: "L1" }),
        ev("u1", "Published tenant lease list.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Jackson County recorder, tenant lease list",
          issuer: "Jackson County, Missouri", date: "2015-01-01", ea: ["E0", "A3"], refutes: "R2", lineage: "U1" }),
        ev("u2", "Operator marketing, named tenants and public tours.", {
          d: 3, sign: "UNDERCUTS", tier: "T2", doc: "Operator marketing material", issuer: "Hunt Midwest",
          date: "2019-01-01", ea: ["E0", "A3"], refutes: "R2", lineage: "U2" }),
      ],
      alternatives: [
        { null_code: "A02", label: "commercial mine or cavern", description: "A room-and-pillar limestone mine converted to commercial warehousing", is_selected: true, disposition: "DOMINANT", reasoning: "Affirmatively documented and publicly advertised by the operator.", excluding: [] },
      ],
    },
  ],
  notes: [
    "R-02 REVIEWER CONFLICT (historian: R; IC: F). R is taken: the mundane explanation is not merely complete but affirmatively documented and publicly advertised, and the published lease chain and ticketed tours are affirmatively improbable under a hardened-COG claim. F would say 'nothing verified favours the claim', which understates what the record shows.",
    "THE ENTRY IS NOT DELETED. It is published beside A-14, where the same facility grades A on what it actually is.",
  ],
};

/* ================================================================== *
 * A-10 / R-03 · Louisville Mega Cavern — THE SHARPEST FALSE POSITIVE
 * The genuine, primary, on-topic document that grades A-10 at band A
 * contributes EXACTLY NOTHING to the COG claim, because the named
 * alternative explains it completely.
 * ================================================================== */

const megaCavern: SpecEntity = {
  slug: "louisville-mega-cavern",
  name: "Louisville Mega Cavern",
  entity_level: "site",
  jurisdiction: "Jefferson County, Kentucky",
  typology: "mine-conversion",
  reference_class: "RC3",
  reference_class_basis: "Private commercial parcel, no federal land status.",
  aliases: ["Louisville Crushed Stone mine", "Mega Cavern"],
  geometry: { precision: "surveyed", point: [-85.6919, 38.2003] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A large converted limestone mine exists beneath the site.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [4, 4], l_d2: 4, l_d3: 3,
      observations: [
        ev("e1", "MSHA mine record for the limestone workings.", {
          d: 4, tier: "T1", doc: "MSHA mine record", issuer: "Mine Safety and Health Administration",
          date: "1975-01-01", authority: true, lineage: "L1", quote: ["underground limestone mine, Jefferson County", 180, 224] }),
        ev("e2", "County record of the commercial conversion.", {
          d: 3, tier: "T1", doc: "Jefferson County property record", issuer: "Jefferson County, Kentucky",
          date: "1989-01-01", lineage: "L2" }),
      ],
    },
    {
      ref: "p-TYPOLOGY-1", class: "TYPOLOGY",
      statement: "The facility is a commercial underground storage and attraction operation.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      observations: [
        ev("e1", "County business and occupancy records for the commercial operation.", {
          d: 4, tier: "T1", doc: "Jefferson County occupancy record", issuer: "Jefferson County, Kentucky",
          date: "1994-01-01", authority: true, lineage: "L1", quote: ["commercial storage and public attraction use", 220, 264] }),
      ],
    },
    {
      /**
       * A-10 · A REAL, PRIMARY, ON-TOPIC CREDENTIAL, GRANTED IN FULL AND
       * WITHOUT GRUDGING. The Office of Civil Defense Community Fallout Shelter
       * Program survey record names this space as a licensed shelter with a
       * stated capacity. §3.4: (a)(b)(c)(d)(e)(f) all hold -> D4 -> A1 -> A.
       *
       * The suite asserts this reaches A CLEANLY, because its function is to
       * establish that the mundane truth here scores legitimately high — WHICH
       * IS WHAT MAKES R-03 DANGEROUS.
       */
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement:
        "The space was a designated civil-defence fallout shelter in the 1960s–70s.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A06", null_label: "general storage", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "UNCOMMON", sci: [4, 4], l_d2: 3, l_d3: 3,
      condition_results: { A1: true, A2: true, A3: true, A4: true, A5: true, A6: true },
      observations: [
        ev("e1", "Office of Civil Defense Community Fallout Shelter Program survey record naming the space as a licensed shelter with a stated capacity.", {
          d: 4, tier: "T1", doc: "OCD Community Fallout Shelter Program survey record",
          issuer: "Office of Civil Defense", date: "1964-01-01", authority: true, lineage: "L1",
          quote: ["licensed shelter space, capacity 50,000 persons, with designated occupant list", 4120, 4198] }),
        ev("e2", "Designated-occupant list for the shelter.", {
          d: 3, tier: "T1", doc: "OCD designated occupant list", issuer: "Office of Civil Defense",
          date: "1965-01-01", lineage: "L2" }),
      ],
    },
    {
      /**
       * R-03 · THE DECISIVE MOVE, MADE BY TABLE LOOKUP RATHER THAN BY
       * SPECIAL-CASING. The OCD shelter record — the same genuine, primary,
       * on-topic document that grades the proposition above at band A — asks:
       * does a public community fallout shelter evidence a CONTINUITY-OF-
       * GOVERNMENT function? E2 under H; A3 under A02, WHICH INCLUDES THE
       * SHELTER DESIGNATION -> §4.4 matrix -> D0.
       *
       * The genuine, primary, on-topic document contributes EXACTLY NOTHING to
       * the COG claim, because the named alternative explains it completely.
       * This is the move v0.1 could not make.
       */
      ref: "p-FUNCTION-2", class: "FUNCTION",
      statement: "The facility serves a continuity-of-government or continuity-of-operations function.",
      grade: "R",
      refutation_state: "R2",
      ceiling: "E",
      applied_caps: ["CAP-2b"],
      ceiling_reason:
        "R2 — two independent-lineage verified UNDERCUTS rows at D2+ (continuous public commercial occupancy in the county record and the operator's own filings; ticketed zip lines, mountain-bike park and Christmas light drive-through), plus null_state DOMINANT. CAP-2b independently caps at E on |V[claim]| = 0.",
      limiting_condition:
        "R2 established. The OCD shelter record — genuine, primary and on-topic — returns D0 against this proposition through the §4.4 matrix, because the named alternative INCLUDES the shelter designation and explains the document completely.",
      null_code: "A02", null_label: "commercial mine or cavern", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE", base_rate_reading: "VERY-RARE",
      sci: [5, 5], l_d2: 0, l_d3: 0,
      predicate_args: {
        claim_text: "Louisville Mega Cavern serves a continuity-of-government function.",
        first_appearance_date: "2011-01-01",
        first_appearance_confidence: "first observation",
      },
      observations: [
        ev("e1", "The OCD shelter record, scored against THIS proposition through the §4.4 matrix.", {
          d: 0, tier: "T1", doc: "OCD Community Fallout Shelter Program survey record",
          issuer: "Office of Civil Defense", date: "1964-01-01", ea: ["E2", "A3"], lineage: "L1",
          quote: ["licensed shelter space, capacity 50,000 persons", 4120, 4166] }),
        ev("e2", "regulations.gov comment naming the facility.", {
          d: 0, tier: "T4", doc: "Public comment naming the facility", issuer: "regulations.gov",
          provenance: "SOLICITED-BY-CLAIMANT", date: "2019-01-01", lineage: "L2" }),
        ev("e3", "Zenodo \"technical assessment\" with a minted DOI.", {
          d: 0, tier: "T4", doc: "Self-published technical assessment", provenance: "SELF-PUBLISHED",
          date: "2021-01-01", ident: "10.5281/zenodo.0000000", identClass: "DOI", lineage: "L3" }),
        ev("e4", "OSM `military=bunker` tag replicating into dozens of renderers.", {
          d: 0, tier: "T5", doc: "OpenStreetMap node, military=bunker", channel: "ADVERSARY-WRITABLE",
          provenance: "CROWD-EDITED", adversary: true, date: "2020-01-01", lineage: "L4" }),
        ev("u1", "Ticketed zip lines, mountain-bike park and Christmas light drive-through.", {
          d: 3, sign: "UNDERCUTS", tier: "T2", doc: "Operator attraction schedule and ticketing record",
          issuer: "Louisville Mega Cavern", date: "2019-01-01", ea: ["E0", "A3"], refutes: "R2", lineage: "U1",
          quote: ["underground zip line course and seasonal lighting drive-through", 220, 284] }),
        ev("u2", "Continuous public commercial occupancy since 1989 in the county record and the operator's own filings.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Jefferson County occupancy record",
          issuer: "Jefferson County, Kentucky", date: "2020-01-01", ea: ["E0", "A3"], refutes: "R2", lineage: "U2",
          quote: ["continuous commercial occupancy since 1989", 300, 342] }),
      ],
      alternatives: [
        { null_code: "A02", label: "commercial mine or cavern", description: "A commercial limestone mine, now a storage facility and tourist attraction with underground zip lines and a Christmas light drive-through, CARRYING A GENUINE HISTORICAL CIVIL-DEFENCE SHELTER DESIGNATION", is_selected: true, disposition: "DOMINANT", reasoning: "The alternative includes the shelter designation, so the shelter record does not discriminate. It is affirmatively documented in the county record and by the operator.", excluding: [] },
      ],
    },
    {
      ref: "p-STATUS-1", class: "STATUS",
      statement: "The facility is an operating commercial attraction.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A12", null_label: "other known typology", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 3], l_d2: 3, l_d3: 2,
      predicate_args: { status: "active" },
      observations: [
        ev("e1", "Current county occupancy and business licence record.", {
          d: 4, tier: "T1", doc: "Jefferson County occupancy record", issuer: "Jefferson County, Kentucky",
          date: "2024-01-01", authority: true, lineage: "L1", quote: ["active commercial occupancy", 120, 148] }),
      ],
    },
  ],
  notes: [
    "R-03 published line, asserted verbatim in structure: 'Louisville Mega Cavern — EXIST A · TYPOLOGY commercial-underground A · FUNCTION(designated fallout shelter, 1960s) A · FUNCTION(COG/COOP) R · STATUS operating commercial attraction A.' Five propositions, five ledgers, no contradiction, all visible at once.",
    "THE TYPOLOGY GATE: 'Any rubric in which the typology field is not itself an evidenced, graded proposition fails this entry by construction.' Under v0.1 an entry could earn a defensible B and then be relabelled COG/COOP at zero cost with the composite unchanged. There is no typology label and no composite — only a proposition, and opening a new one starts it with an empty ledger, a mandatory named alternative that already explains every observation on the page, and CAP-2b holding the ceiling at E before refutation even runs.",
    "The .gov laundering channels each contribute exactly 0: a regulations.gov comment is SOLICITED-BY-CLAIMANT; a Zenodo DOI is SELF-PUBLISHED (T4, and A1 requires T1/T2); an OSM tag is CROWD-EDITED and is one lineage regardless of renderer count.",
  ],
};

/* ================================================================== *
 * A-11 / R-04 · DUCC — PROGRAM A, EXIST R. The clamp exemption is
 * the single schema decision that makes this entity expressible.
 * ================================================================== */

const ducc: SpecEntity = {
  slug: "ducc",
  name: "Deep Underground Command Center (DUCC)",
  entity_level: "program",
  jurisdiction: "District of Columbia (proposed)",
  typology: "cog-coop",
  reference_class: "RC6",
  reference_class_basis: "No land status: no facility was ever constructed.",
  aliases: ["DUCC"],
  /**
   * A-11 · LOCATE non_located. Documented programme, no facility, no
   * coordinates. `core.render_geometry` emits representation 'none' and the
   * plate's NOT LOCATABLE panel carries it. A map cannot show what has no
   * coordinates; making the unmappable visible BESIDE the map is the honest
   * answer.
   */
  geometry: { precision: "non_located" },
  propositions: [
    {
      /**
       * A-11 STRUCTURAL ASSERTION: PROGRAM is clamp_exempt BY TRIGGER, never by
       * agent choice. Without that exemption the monotone clamp would drag
       * PROGRAM down to EXIST's R and the entry would be unrepresentable.
       */
      ref: "p-PROGRAM-1", class: "PROGRAM",
      statement:
        "A Deep Underground Command Center programme was proposed, studied and rejected in the 1960s.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "UNCOMMON", reference_class: "RC6",
      sci: [5, 5], l_d2: 4, l_d3: 4,
      condition_results: { A1: true, A2: true, A3: true, A4: true, A5: true, A6: true },
      observations: [
        ev("e1", "JCS/OSD memoranda in FRUS 1964–68 volume X.", {
          d: 4, tier: "T1", doc: "Foreign Relations of the United States, 1964–1968, Volume X",
          issuer: "U.S. Department of State, Office of the Historian", date: "1964-11-01",
          corpus: "FRUS (git-clonable TEI XML)", authority: true, lineage: "L1",
          quote: ["a deep underground command center beneath the Washington area", 12800, 12862] }),
        ev("e2", "FY1965 appropriations record showing the rejection.", {
          d: 4, tier: "T1", doc: "Appropriations record, FY1965", issuer: "U.S. Congress",
          date: "1965-01-01", identClass: "GovInfo", authority: true, lineage: "L2",
          quote: ["the committee declines to fund the deep underground command center", 9100, 9168] }),
        ev("e3", "Declassified feasibility studies for the programme.", {
          d: 3, tier: "T1", doc: "Declassified feasibility study", issuer: "Office of the Secretary of Defense",
          date: "1963-01-01", lineage: "L3" }),
        ev("e4", "The Hitch memorandum on programme cost.", {
          d: 3, tier: "T1", doc: "Hitch memorandum", issuer: "Office of the Secretary of Defense",
          author: "Charles J. Hitch", date: "1964-01-01", lineage: "L1" }),
        ev("e5", "LBJ Library holdings on the programme.", {
          d: 3, tier: "T1", doc: "LBJ Presidential Library holdings", issuer: "LBJ Presidential Library",
          date: "1965-01-01", lineage: "L4" }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", disposition: "EXCLUDED", reasoning: "A paper study never seriously considered — EXCLUDED. A memorandum reaching the President and drawing a recorded appropriations refusal is not an unconsidered study.", excluding: ["e1", "e2"] },
      ],
    },
    {
      /**
       * R-04 · R3, and §8.4 forbids R on expected-record negatives alone. The
       * silence half supplies three UNDERCUTS rows at −D3; the AFFIRMATIVE half
       * — the appropriations record documenting non-funding and the programme
       * record documenting cancellation — is what licenses R.
       *
       * "Remove the appropriations record from the fixture and the expected
       * result becomes F (SILENCE-DOMINATED), not R."
       *
       * THIS IS THE ONE CASE IN THE SUITE WHERE THE ARGUMENT FROM SILENCE IS
       * VALID, and the ERP table is precisely what licenses it — the same table
       * that FORBIDS the inference for Greenbrier-1991. DUCC publishes
       * INFORMATIVE; Greenbrier-1991 publishes UNINFORMATIVE; same table.
       */
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A physical DUCC structure exists beneath Washington.",
      grade: "R",
      refutation_state: "R3",
      ceiling_reason:
        "R3 — the appropriations record documents non-funding and the programme record documents cancellation, from parties with authority over the fact, unsolicited, verified and subject-bound.",
      limiting_condition:
        "R3 established on affirmative content. The three expected-record negatives (MILCON X3, procurement traces >$50M X3, spoil-volume signature >1e5 m³ X3) corroborate but do not license the refutation: §8.4 forbids R on expected-record negatives alone.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "RARE",
      sci: [6, 6], l_d2: 3, l_d3: 3,
      condition_results: { R3: true, "§8.4-gate": true },
      predicate_args: {
        claim_text: "A DUCC facility was built beneath Washington.",
        first_appearance_date: "1970-01-01",
        first_appearance_confidence: "first observation",
      },
      observations: [
        ev("u1", "Appropriations record documenting non-funding.", {
          d: 4, sign: "UNDERCUTS", tier: "T1", doc: "Appropriations record, FY1965", issuer: "U.S. Congress",
          date: "1965-01-01", authority: true, refutes: "R3", lineage: "U1",
          quote: ["the committee declines to fund the deep underground command center", 9100, 9168] }),
        ev("u2", "Programme record documenting cancellation.", {
          d: 4, sign: "UNDERCUTS", tier: "T1", doc: "Programme termination record",
          issuer: "Office of the Secretary of Defense", date: "1966-01-01", authority: true, refutes: "R3", lineage: "U2",
          quote: ["the deep underground command center programme is terminated", 410, 468] }),
        ev("u3", "MILCON search: expected at X3 for an excavation of this scale under an appropriated DoD programme; executed, negative, receipted.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "MILCON canonical search", issuer: "U.S. Department of Defense",
          date: "2026-07-01", receipt: negativeReceipt("ducc-milcon"), lineage: "U3",
          negative: { query: "MILCON deep underground command center Washington", result_count: 0, erp: "MILCON/DD-1391", x: "X3" } }),
        ev("u4", "Procurement traces above $50M: executed, negative, receipted.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Procurement canonical search", issuer: "General Services Administration",
          date: "2026-07-01", receipt: negativeReceipt("ducc-procure"), lineage: "U3",
          negative: { query: "procurement > $50M underground command center 1963..1968", result_count: 0, erp: "FPDS", x: "X3" } }),
        ev("u5", "Spoil-volume signature above 1e5 m³: executed, negative, receipted.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Spoil-volume canonical search", issuer: "U.S. Geological Survey",
          date: "2026-07-01", receipt: negativeReceipt("ducc-spoil"), lineage: "U3",
          negative: { query: "spoil volume signature District of Columbia 1963..1968", result_count: 0, erp: "spoil-signature", x: "X3" } }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", is_selected: true, disposition: "DOMINANT", reasoning: "The programme is real and documented; the facility is not. The claim transposes a studied proposal into a built structure.", excluding: [] },
      ],
      silence: [
        { record_class: "MILCON lines", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 3f10…c72", egress_state: "REACHABLE" },
        { record_class: "Procurement traces > $50M", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 a207…19b", egress_state: "REACHABLE" },
        { record_class: "Spoil-volume signature > 1e5 m³", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 c8b3…04f", egress_state: "REACHABLE" },
        { record_class: "NEPA-era documentation", expected_record_level: "X2", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 55da…8e1", egress_state: "REACHABLE" },
      ],
      movement: [
        { occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "F", cause: "INITIAL", note: "Silence-dominated on the canonical set." },
        { occurred_at: "2026-04-22T00:00:00Z", from: "F", to: "R", cause: "REFUTATION", note: "R3 established when the appropriations and termination records resolved. §8.4's gate is satisfied by affirmative content." },
      ],
    },
    {
      ref: "p-STATUS-1", class: "STATUS",
      statement: "The programme was never built.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [4, 4], l_d2: 3, l_d3: 3,
      /**
       * A-11: `STATUS = never-built` is a VALID ENUM VALUE. v0.1's nearest
       * option was "alleged-only," the epistemic opposite.
       */
      predicate_args: { status: "never-built" },
      observations: [
        ev("e1", "Programme termination record.", {
          d: 4, tier: "T1", doc: "Programme termination record", issuer: "Office of the Secretary of Defense",
          date: "1966-01-01", authority: true, lineage: "L1",
          quote: ["no construction was undertaken", 500, 530] }),
      ],
    },
    {
      ref: "p-LOCATE-1", class: "LOCATE",
      statement: "The programme's proposed site can be located.",
      grade: "X",
      limiting_condition:
        "X — no facility exists to locate. The programme records describe a proposed area, not a constructed site. locate_precision is non_located and no geometry is emitted.",
      null_code: "A01", null_label: "no constructed object", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE", sci: [2, 2], l_d2: 0, l_d3: 0,
      observations: [],
    },
  ],
  notes: [
    "R-04 REVIEWER CONFLICT (historian: R; IC: F). BES returns R because the cancellation is affirmatively documented, which is R3 by definition. v0.1 returned 37.24 → E, six points above Dulce Base: a proven non-facility with superb documentation must not share a bin with an invention.",
    "PROGRAM A beside EXIST R on one page is the register publishing an A-grade fact about a facility that does not exist. DESIGN.md §8.1 puts PROGRAM below the rule reading UNCLAMPED — THESE DO NOT DESCRIBE THE STRUCTURE.",
  ],
};

/* ================================================================== *
 * E-01 · Denver International Airport — THE DEEPEST ASSERTION
 * Six of seven agents independently returned REAL T1 SIGNALS, and not
 * one discriminated {hardened federal facility} from {very large
 * airport, built badly}. The suite asserts six D0 rows satisfying zero
 * conditions above D, and that CAP-2b — NOT LUCK — holds it at E.
 * ================================================================== */

const dia: SpecEntity = {
  slug: "denver-international-airport",
  name: "Denver International Airport",
  entity_level: "site",
  jurisdiction: "Denver County, Colorado",
  typology: "unknown-anomaly",
  reference_class: "RC3",
  reference_class_basis: "Municipal airport parcel; no federal land status.",
  aliases: ["DIA", "DEN"],
  geometry: { precision: "surveyed", point: [-104.6737, 39.8617] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "Large underground works exist beneath and around the terminal complex.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A03", null_label: "transport tunnel", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON", sci: [5, 5], l_d2: 5, l_d3: 4,
      observations: [
        ev("e1", "Airport construction records for the baggage, utility and inter-concourse train tunnels.", {
          d: 4, tier: "T1", doc: "Airport construction record, tunnel systems", issuer: "City and County of Denver",
          date: "1993-01-01", authority: true, lineage: "L1",
          quote: ["automated baggage tunnels, utility tunnels and the inter-concourse transit tunnel", 3100, 3184] }),
        ev("e2", "GAO audit of the baggage system describing the tunnel works.", {
          d: 3, tier: "T1", doc: "GAO report on the Denver airport baggage system",
          issuer: "Government Accountability Office", date: "1995-01-01", lineage: "L2" }),
      ],
    },
    {
      /**
       * E-01 · REVIEWER CONFLICT (historian: F; IC: E). BES follows the IC:
       * V IS NOT EMPTY, so F would misdescribe the evidentiary state.
       * E-01 and F-01 together define the E/F line.
       *
       * REFUTATION MUST NOT FIRE. R3? No agency record states "there is no
       * facility beneath the terminal." R2? null_state = DOMINANT holds — but
       * R2 ALSO requires >= 2 verified UNDERCUTS rows improbable under the
       * proposition, and there are none. The airport's documented ordinariness
       * EXPLAINS the signals; it does not CONTRADICT a concealed facility.
       * A complete mundane explanation removes probative value; it does not
       * disconfirm. -> R0.
       */
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement:
        "A hardened non-airport federal facility operates beneath the terminal.",
      grade: "E",
      grade_pre_clamp: "D",
      refutation_state: "R0",
      ceiling: "E",
      at_ceiling: true,
      applied_caps: ["CAP-2b"],
      ceiling_reason:
        "CAP-2b — |V[claim]| = 0. Every returned signal is PLACE-PROPERTY or supports the null.",
      limiting_condition:
        "CAP-2b — no verified, instance-scope, subject-bound CLAIM-PROPERTY observation. Six independent returns produced six D0 rows satisfying zero conditions above D. The document that would move this: any instance-level record from a party with authority over the facility's occupancy.",
      null_code: "A08", null_label: "ordinary government building", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE",
      base_rate_reading: "VERY-RARE",
      reference_class: "RC3",
      sci: [6, 6], l_d2: 0, l_d3: 0,
      condition_results: { A1: false, B1: false, C1a: false, D1: false, E1: true, E2: true, R2: false, R3: false },
      predicate_args: {
        claim_text: "A hardened federal facility operates beneath Denver International Airport.",
        first_appearance_date: "1995-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "GAO audits on cost overruns and the failed baggage system. A property of how the airport was BUILT AND OPERATED, not a claim property of a concealed facility — and it supports the null.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "GAO report on the Denver airport baggage system",
          issuer: "Government Accountability Office", date: "1995-01-01", documentsNull: true, lineage: "L1",
          quote: ["the automated baggage handling system did not perform as designed and was abandoned", 1210, 1294] }),
        ev("e2", "Large-footprint underground structures and tunnels.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "Airport construction record, tunnel systems",
          issuer: "City and County of Denver", date: "1993-01-01", lineage: "L2" }),
        ev("e3", "Enormous dedicated electrical load.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "Utility service record", issuer: "Public Service Company of Colorado",
          date: "1995-01-01", lineage: "L3" }),
        ev("e4", "Dedicated fuel farm and pipeline.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "Pipeline and fuel storage permit", issuer: "Colorado Department of Public Health",
          date: "1994-01-01", lineage: "L4" }),
        ev("e5", "Deep wells on the parcel.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "State well permit record", issuer: "Colorado Division of Water Resources",
          date: "1992-01-01", lineage: "L5" }),
        ev("e6", "Construction contracts sequenced, terminated and reissued — and this too supports the null.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "FPDS contract action history",
          issuer: "General Services Administration", date: "1994-01-01", documentsNull: true, lineage: "L6" }),
        ev("e7", "1990s Denver press describing buried structures.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T2", doc: "Regional press coverage of the tunnel works",
          issuer: "The Denver Post", date: "1994-06-01", lineage: "L7" }),
        ev("e8", "Origin artifacts: mid-1990s claimant publications.", {
          d: 0, tier: "T5", doc: "Claimant publication, mid-1990s", author: "Alex Christopher / Phil Schneider",
          date: "1995-01-01", selfAttesting: "the author is the claimant and the publication's probative content is the claim itself",
          lineage: "L8" }),
      ],
      alternatives: [
        { null_code: "A08", label: "ordinary government building", description: "A very large airport, built badly", is_selected: true, disposition: "DOMINANT", reasoning: "The airport's documented ordinariness — its scale, its abandoned baggage system, its contract history — accounts for every row in V. A COMPLETE MUNDANE EXPLANATION REMOVES PROBATIVE VALUE; IT DOES NOT DISCONFIRM. Hence DOMINANT, and hence R0 rather than R2.", excluding: [] },
      ],
      silence: [
        { record_class: "Federal Real Property Profile", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 91c4…5b8" },
        { record_class: "MILCON / DD-1391", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 07ab…d43" },
      ],
      movement: [{ occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "E", cause: "INITIAL" }],
    },
  ],
  notes: [
    "E-01 · IC #12 called this 'the single most important thing to test before ratification': 'A published C-grade DIA bunker entry would on its own destroy the register's credibility.' v0.1 returns 45.78 at CONTAM 60 and 55.59 = GRADE C at the more defensible CONTAM 30.",
    "EXIST(large underground works at DIA) = A — baggage tunnels, utility tunnels, the inter-concourse train, all in T1 records. True, boring, published, and displayed alongside.",
  ],
};

export const CONTESTED_ENTITIES: SpecEntity[] = [
  greenbrier,
  subtropolis,
  megaCavern,
  ducc,
  dia,
];
