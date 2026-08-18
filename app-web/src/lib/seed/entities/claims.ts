/**
 * SPECIMEN ENTITIES — the claims register.
 *
 * CALIBRATION CASES A-12, A-13, F-01 … F-06, R-05, X-01, and the pipeline
 * tests P-01 … P-05.
 *
 * `/claims` is styled identically to `/`. IT IS NOT A GRAVEYARD. Each entry
 * records a claim that circulated, where it came from, and what the record does
 * and does not support — and an F entry with a documented origin is a finding.
 * Sorted by origin date ascending, band F becomes a chronology of American
 * underground folklore: Oliver 1894 (Telos) -> Pollock 1976 (Mount Weather) ->
 * Bennewitz 1979–80 (Dulce) -> Lazar 1989 (S-4) -> Nichols & Moon 1992
 * (Montauk) -> 2016 (Comet Ping Pong).
 *
 * SPECIMEN DATA. Quoted spans are plausible reconstructions written for this
 * fixture, not verbatim transcriptions of retrieved documents.
 */

import type { SpecEntity } from "../types";
import { ev, notFound, unreachable } from "../dsl";

/* ================================================================== *
 * F-01 / A-13 · The Montauk Project — the ORIG A / FUNC F pair,
 * the design's most distinctive repeated artefact.
 * ================================================================== */

const montaukProject: SpecEntity = {
  slug: "montauk-project",
  name: "The Montauk Project",
  entity_level: "site",
  jurisdiction: "Suffolk County, New York",
  typology: "unknown-anomaly",
  reference_class: "RC2",
  reference_class_basis: "Former military reservation, now a state park.",
  aliases: ["Montauk Project", "Project Phoenix (claimed)"],
  /**
   * A coordinate was ASSERTED by the claimants. Never a pin: representation
   * degrades to an uncertainty circle with NO CENTRE MARK, and the chart tags
   * ED (existence doubtful) and Rep (reported) print beside it.
   */
  geometry: {
    precision: "claimed_only",
    point: [-71.8631, 41.0642],
    radius_m: 2000,
    chart_tags: ["ED", "Rep"],
  },
  propositions: [
    {
      /**
       * F-01 · V IS EMPTY. §2.5: Nichols is the claimant and the book's
       * probative content IS the claim -> SELF-ATTESTING -> excluded from V,
       * routed to ORIGIN. The base's real documentation is bound to
       * EXIST(camp-hero) and CONTROL(USAF), NOT to this proposition:
       * PROPOSITION BINDING PLUS SUBJECT BINDING MAKE THE CITOGENESIS MECHANISM
       * UNAVAILABLE TO THE REGISTER ITSELF.
       *
       * REFUTATION MUST NOT FIRE. R1? Recovered memories are not an admission
       * of fabrication, not a documented disinformation operation, and there is
       * no post-dating impossibility. R2? Requires >= 2 affirmative UNDERCUTS at
       * D2+; the NY State Parks and EPA surveys returning no such levels are
       * EXPECTED-RECORD NEGATIVES, and §8.4 forbids R on those alone. -> R0.
       */
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement:
        "Underground levels beneath Camp Hero housed time-displacement and mind-control experiments.",
      grade: "F",
      refutation_state: "R0",
      applied_caps: ["CAP-5"],
      ceiling: "F",
      at_ceiling: true,
      ceiling_reason: "CAP-5 — V is empty. E1 requires V ≠ ∅ and fails.",
      limiting_condition:
        "CAP-5 — V = ∅. Every circulating version traces to one 1992 book whose author is the claimant; §2.5 routes it to ORIGIN. The real documentation of Camp Hero is bound to that entity's own propositions and cannot be borrowed by this one.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "UNINFORMATIVE",
      base_rate_reading: "VERY-RARE",
      sci: [5, 5], l_d2: 0, l_d3: 0,
      condition_results: { E1: false, R1: false, R2: false, "CAP-5": true },
      predicate_args: {
        claim_text:
          "Underground levels beneath Camp Hero housed time-displacement and mind-control experiments.",
        first_appearance_date: "1992-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "The 1992 book's account of recovered memories of the facility.", {
          d: 0, tier: "T5", doc: "The Montauk Project: Experiments in Time",
          author: "Preston B. Nichols with Peter Moon", date: "1992-01-01",
          selfAttesting: "the author is the claimant and the book's probative content is the claim itself",
          lineage: "L1", siglum: "M1" }),
        ev("e2", "Later book-series volumes restating the account.", {
          d: 0, tier: "T5", doc: "Montauk series, subsequent volumes", author: "Peter Moon",
          date: "1994-01-01", selfAttesting: "the claimant restating the claim; semantic clustering collapses it into the 1992 origin",
          lineage: "L1", siglum: "M2" }),
        ev("e3", "Fringe compilation sites reproducing the account.", {
          d: 0, tier: "T5", doc: "Fringe compilation site", channel: "AGGREGATOR", provenance: "SELF-PUBLISHED",
          date: "2004-01-01", lineage: "L1", siglum: "M7" }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", is_selected: true, disposition: "DOMINANT", reasoning: "A recovered-memory narrative attached to a real, documented radar station. The station's records account for the station; nothing accounts for the claim except the claim.", excluding: [] },
      ],
      silence: [
        { record_class: "NY State Parks site survey", expected_record_level: "X2", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 b108…7d2" },
        { record_class: "EPA site survey", expected_record_level: "X2", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 4e19…c60" },
      ],
      lineage: {
        document_count: 60,
        lineage_count: 1,
        verdict:
          "60 citing documents · 1 independent lineage · collapse delta 59. Semantic clustering collapses every later appearance into the 1992 origin: this proposition rests on one source and 59 copies.",
        blocks: [
          {
            origin: { siglum: "M1", label: "Nichols, P. & Moon, P. The Montauk Project: Experiments in Time.", document_date: "1992-01-01", origin_tier: "T5", note: "The claimant's own account. §2.5 excludes it from V and routes it here." },
            descendants: [
              { siglum: "M2", label: "Montauk series, subsequent volumes", document_date: "1994-01-01", origin_tier: "T5", collapses: true },
              { siglum: "M7", label: "Fringe compilation site", document_date: "2004-01-01", origin_tier: "T5", collapses: true },
            ],
            downstream_count: 59,
          },
        ],
      },
    },
    {
      /**
       * A-13 · ORIGIN A. The dated 1992 artifact, retrieved with a receipt,
       * PLUS the negative receipt across the canonical ORIGIN set. Published
       * BESIDE Camp Hero EXIST A and this entity's FUNCTION F, at the same
       * coordinates. ORIGIN is clamp-exempt, so DESIGN.md §8.1 prints it below
       * the rule reading UNCLAMPED — THESE DO NOT DESCRIBE THE STRUCTURE.
       */
      ref: "p-ORIGIN-1", class: "ORIGIN",
      statement:
        "The Montauk Project claim first appears with Nichols and Moon in 1992.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "UNCOMMON",
      sci: [6, 6], l_d2: 3, l_d3: 3,
      condition_results: { A1: true, A3: true },
      predicate_args: {
        claim_text: "The Montauk Project claim originates with Nichols & Moon, 1992.",
        first_appearance_date: "1992-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "The dated 1992 artifact itself, retrieved with a receipt. For an ORIGIN claim the earliest dated artifact IS the evidence.", {
          d: 4, tier: "T2", doc: "The Montauk Project: Experiments in Time",
          author: "Preston B. Nichols with Peter Moon", date: "1992-01-01",
          corpus: "Internet Archive", channel: "CURATED-ARCHIVE", authority: true, lineage: "L1",
          quote: ["what follows is reconstructed from memories recovered beginning in 1985", 210, 282] }),
        ev("e2", "Negative receipt across the canonical ORIGIN set: no earlier appearance.", {
          d: 3, tier: "T1", doc: "Canonical ORIGIN search set", issuer: "Wayback CDX, IA full-text, periodical runs",
          date: "2026-07-01", lineage: "L2",
          negative: { query: "\"Montauk Project\" OR \"Camp Hero\" underground experiments before:1992", result_count: 0, erp: "ORIGIN-canonical" } }),
        ev("e3", "Bibliographic record dating first publication.", {
          d: 3, tier: "T1", doc: "Library of Congress catalog record", issuer: "Library of Congress",
          date: "1992-06-01", lineage: "L3" }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "The claim predates 1992 and Nichols merely repeated it", disposition: "EXCLUDED", reasoning: "EXCLUDED by the negative receipt across the canonical ORIGIN set, with query strings, corpora, versions and result counts recorded.", excluding: ["e2"] },
      ],
      searches: [
        { query: "\"Montauk\" underground base experiments", corpus_as_of: "2026-07-01", outcome: "NEGATIVE", result_count: 0, erp_profile: "ORIGIN-canonical", egress_state: "REACHABLE" },
      ],
    },
  ],
  notes: [
    "THE E/F LINE, STATED. DIA's V contains verified third-party records of real facts that fail to discriminate -> E. Montauk's V is empty because the only artifact IS the claim -> F. That line falls out of one written rule and it is checkable.",
    "v0.1 returned 43.29 → D, 'suggestive but thin', because the claim inherited the real base's DOC/GEO/INF/OWN.",
  ],
};

/* ================================================================== *
 * F-02 · Telos, beneath Mount Shasta — the cleanest backward-sourced
 * case: a claim whose origin document is openly a work of fiction.
 * ================================================================== */

const telos: SpecEntity = {
  slug: "telos-mount-shasta",
  name: "Telos, beneath Mount Shasta",
  entity_level: "site",
  jurisdiction: "Siskiyou County, California",
  typology: "unknown-anomaly",
  reference_class: "RC6",
  reference_class_basis: "No parcel or land status is asserted by any source.",
  aliases: ["Telos", "the Lemurian city"],
  /** A place NAME was claimed. No coordinate exists at all. */
  geometry: {
    precision: "place_name_only",
    claimed_place_name: "beneath Mount Shasta, California",
  },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A city named Telos exists beneath Mount Shasta.",
      grade: "F",
      refutation_state: "R0",
      applied_caps: ["CAP-5"],
      ceiling: "F",
      at_ceiling: true,
      ceiling_reason: "CAP-5 — V is empty.",
      limiting_condition:
        "CAP-5 — V = ∅. The author is the claimant and the content is the claim. THE CLAIM MUST NOT INHERIT A PLACE-DERIVED FLOOR from the genuinely anomalous terrain it is attached to: Mount Shasta is a stratovolcano with real lava tubes and caves, and under v0.1 those signals fed the grade.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "VERY-RARE",
      sci: [4, 4], l_d2: 0, l_d3: 0,
      predicate_args: {
        claim_text: "A Lemurian city named Telos exists beneath Mount Shasta.",
        first_appearance_date: "1894-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "The 1894 novel in which the claim first appears.", {
          d: 0, tier: "T5", doc: "A Dweller on Two Planets", author: "Frederick Spencer Oliver",
          date: "1894-01-01", selfAttesting: "openly a work of fiction; the author is the claimant and the content is the claim",
          lineage: "L1", siglum: "T1" }),
        ev("e2", "Subsequent Lemurian Fellowship literature restating it.", {
          d: 0, tier: "T5", doc: "Lemurian Fellowship literature", date: "1936-01-01",
          selfAttesting: "the claimant tradition restating the claim", lineage: "L1", siglum: "T4" }),
        ev("e3", "Lava tubes and caves in the state geological record — real, and PLACE-PROPERTY.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "California Geological Survey record",
          issuer: "California Geological Survey", date: "2004-01-01", lineage: "L2" }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", is_selected: true, disposition: "DOMINANT", reasoning: "The origin document is a novel and says so.", excluding: [] },
      ],
      lineage: {
        document_count: 120,
        lineage_count: 1,
        verdict:
          "120 citing documents · 1 independent lineage · collapse delta 119. Every witness descends from one 1894 novel.",
        blocks: [
          {
            origin: { siglum: "T1", label: "Oliver, F. S. A Dweller on Two Planets.", document_date: "1894-01-01", origin_tier: "T5", note: "A work of fiction, openly so." },
            descendants: [{ siglum: "T4", label: "Lemurian Fellowship literature", document_date: "1936-01-01", origin_tier: "T5", collapses: true }],
            downstream_count: 119,
          },
        ],
      },
    },
    {
      ref: "p-ORIGIN-1", class: "ORIGIN",
      statement: "The Telos claim originates with Oliver's 1894 novel.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [4, 4], l_d2: 3, l_d3: 2,
      predicate_args: {
        claim_text: "The Telos claim originates with Oliver, 1894.",
        first_appearance_date: "1894-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "The dated 1894 first edition, retrieved with a receipt.", {
          d: 4, tier: "T2", doc: "A Dweller on Two Planets, first edition", author: "Frederick Spencer Oliver",
          date: "1894-01-01", corpus: "Internet Archive", channel: "CURATED-ARCHIVE", authority: true, lineage: "L1",
          quote: ["the city that lies beneath the mountain", 4020, 4058] }),
        ev("e2", "Negative receipt across the canonical ORIGIN set: no earlier appearance.", {
          d: 3, tier: "T1", doc: "Canonical ORIGIN search set", issuer: "Chronicling America, IA full-text",
          date: "2026-07-01", lineage: "L2",
          negative: { query: "Telos Lemuria \"Mount Shasta\" before:1894", result_count: 0, erp: "ORIGIN-canonical" } }),
      ],
    },
  ],
};

/* ================================================================== *
 * F-03 · The Sauder / Schneider "129 Deep Underground Military Bases"
 * THE §8.4 ASSERTION: a model that licenses R from negatives alone
 * returns R — which is WRONG, and is the characteristic failure mode
 * of any evidence model with signed negatives.
 * ================================================================== */

const sauderCorpus: SpecEntity = {
  slug: "sauder-129-dumb-corpus",
  name: "The \"129 Deep Underground Military Bases\" corpus",
  entity_level: "program",
  jurisdiction: "United States (asserted, unspecified)",
  typology: "unknown-anomaly",
  reference_class: "RC6",
  reference_class_basis: "No coordinates are asserted for any of the 129.",
  aliases: ["129 DUMBs", "Sauder corpus"],
  /** No coordinates for any of the 129. Documented claim, position unknown. */
  geometry: { precision: "non_located" },
  propositions: [
    {
      ref: "p-PROGRAM-1", class: "PROGRAM",
      statement:
        "A federal programme constructed 129 deep underground military bases.",
      grade: "F",
      /**
       * THE ASSERTION: refutation_state = R0 and grade = F (SILENCE-DOMINATED).
       * The expected-record negatives here are deep and real — X3 profiles on
       * MILCON, on procurement traces > $50M, on spoil-volume signatures — and
       * §8.4 FORBIDS R on negatives alone.
       */
      refutation_state: "R0",
      applied_caps: ["CAP-5"],
      ceiling: "F",
      at_ceiling: true,
      ceiling_reason: "CAP-5 — V is empty; §2.5 excludes the claimant's own corpus.",
      limiting_condition:
        "F (SILENCE-DOMINATED) — V = ∅ and §8.4 forbids R on expected-record negatives alone. No coordinates for any of the 129; no procurement record for a construction programme of the asserted scale; no spoil-volume accounting; originator employment credentials never independently corroborated.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE", base_rate_reading: "VERY-RARE",
      sci: [6, 6], l_d2: 0, l_d3: 0,
      predicate_args: {
        claim_text: "129 deep underground military bases were constructed in the United States.",
        first_appearance_date: "1995-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "The self-published origin set asserting the 129.", {
          d: 0, tier: "T5", doc: "Self-published origin set, 1990s", author: "Richard Sauder",
          date: "1995-01-01", provenance: "SELF-PUBLISHED",
          selfAttesting: "the author is the claimant and the corpus's probative content is the claim itself",
          lineage: "L1", siglum: "S1" }),
        ev("e2", "A document identifier regexed out of the origin corpus, treated as a LEAD and not resolved.", {
          d: 0, tier: "PENDING", doc: "Identifier extracted from the origin corpus", ident: "AD-A241 xxx",
          identClass: "DTIC", receipt: notFound("https://apps.dtic.mil/"), date: "1995-01-01", lineage: "L1" }),
        ev("u1", "MILCON canonical search: expected at X3 for a construction programme of the asserted scale; executed, negative, receipted.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "MILCON canonical search", issuer: "U.S. Department of Defense",
          date: "2026-07-01", lineage: "U1",
          negative: { query: "MILCON deep underground base construction 1980..2000", result_count: 0, erp: "MILCON/DD-1391", x: "X3" } }),
        ev("u2", "Procurement traces above $50M: executed, negative, receipted.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Procurement canonical search", issuer: "General Services Administration",
          date: "2026-07-01", lineage: "U2",
          negative: { query: "procurement > $50M underground construction programme", result_count: 0, erp: "FPDS", x: "X3" } }),
        ev("u3", "Spoil-volume signature: executed, negative, receipted.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Spoil-volume canonical search", issuer: "U.S. Geological Survey",
          date: "2026-07-01", lineage: "U3",
          negative: { query: "spoil volume signature > 1e5 m3 CONUS 1980..2000", result_count: 0, erp: "spoil-signature", x: "X3" } }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", is_selected: true, disposition: "DOMINANT", reasoning: "A self-published origin set with no coordinates, no procurement trace and no corroborated credentials.", excluding: [] },
      ],
      silence: [
        { record_class: "MILCON / DD-1391", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 6a29…11c" },
        { record_class: "Procurement traces > $50M", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 d740…3ae" },
        { record_class: "Spoil-volume signature", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 0b6c…95f" },
      ],
    },
    {
      ref: "p-ORIGIN-1", class: "ORIGIN",
      statement: "The 129-DUMB claim originates in a small self-published 1990s origin set.",
      grade: "B",
      ceiling: "A",
      at_ceiling: false,
      limiting_condition:
        "A1 — the earliest dated artifact is established, but the origin set's internal ordering is not: two 1990s items carry the same year and no month. L(D3) = 2 on the bibliographic and archival lineages.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [5, 6], l_d2: 3, l_d3: 2,
      predicate_args: {
        claim_text: "The 129-DUMB claim originates with the Sauder corpus, mid-1990s.",
        first_appearance_date: "1995-01-01",
        first_appearance_confidence: "undated within year",
      },
      observations: [
        ev("e1", "The dated origin volume, retrieved with a receipt.", {
          d: 3, tier: "T2", doc: "Self-published origin volume", author: "Richard Sauder", date: "1995-01-01",
          corpus: "Internet Archive", channel: "CURATED-ARCHIVE", lineage: "L1" }),
        ev("e2", "Negative receipt across the canonical ORIGIN set for an earlier appearance.", {
          d: 3, tier: "T1", doc: "Canonical ORIGIN search set", issuer: "IA full-text, periodical runs",
          date: "2026-07-01", lineage: "L2",
          negative: { query: "\"deep underground military base\" before:1995", result_count: 0, erp: "ORIGIN-canonical" } }),
      ],
    },
  ],
  notes: [
    "THE SAUDER-AS-BIBLIOGRAPHY MOVE: identifiers regexed out of the books are LEADS and become citations only after independent resolution at DTIC / NTRL / Federal Register. His documents get promoted; his conclusions stay T4. The suite asserts that a lead extracted from a fringe book cannot become a citation without an independent receipt.",
    "IC #2: 'If a revised rubric moves this above F, the revision is broken.'",
  ],
};

/* ================================================================== *
 * F-04 · Bob Lazar / S-4, Papoose Lake — THE HARDEST TESTIMONY CASE,
 * and the one that forced §5.4 to become a POSITION-TO-KNOW gate
 * rather than an identity gate.
 * ================================================================== */

const s4PapooseLake: SpecEntity = {
  slug: "s4-papoose-lake",
  name: "S-4, Papoose Lake",
  entity_level: "site",
  jurisdiction: "Nye County, Nevada",
  typology: "unknown-anomaly",
  reference_class: "RC6",
  reference_class_basis: "Claimed location inside restricted airspace; no parcel asserted.",
  aliases: ["S-4", "Papoose Lake facility"],
  /** A claimed area, 10 km. Dotted circle, no centre mark, tags ED and Rep. */
  geometry: {
    precision: "approximate_10km",
    point: [-115.9436, 37.0847],
    radius_m: 10000,
    chart_tags: ["ED", "Rep"],
  },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement:
        "A concealed underground facility designated S-4 exists at Papoose Lake.",
      grade: "F",
      refutation_state: "R0",
      applied_caps: ["CAP-5"],
      ceiling: "F",
      at_ceiling: true,
      ceiling_reason: "CAP-5 — V is empty.",
      limiting_condition:
        "CAP-5 — V = ∅. §5.4 is a POSITION-TO-KNOW gate, not an identity gate: the individual must be independently locatable in a record that PREDATES THE CLAIM, was CREATED FOR AN UNRELATED PURPOSE, and PLACES THEM IN THE ROLE ASSERTED. The claimant is an unambiguously real, publicly identifiable, named individual on the record from 1989 — and fails the third clause. His account is D0.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "VERY-RARE",
      sci: [5, 5], l_d2: 0, l_d3: 0,
      predicate_args: {
        claim_text: "A concealed facility designated S-4 exists at Papoose Lake.",
        first_appearance_date: "1989-05-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "Dated 1989 broadcast interviews making the claim.", {
          d: 0, tier: "T5", doc: "Dated broadcast interview, 1989", author: "Robert Lazar", date: "1989-05-01",
          selfAttesting: "the claimant asserting the claim; §5.4's third clause fails — no record predating the claim, created for an unrelated purpose, places him in the role asserted",
          lineage: "L1", siglum: "P1" }),
        ev("e2", "Continuous restricted airspace over Groom Lake — a genuine D2/D3 signal, but for propositions about GROOM LAKE, not about a claimed separate facility at Papoose Lake.", {
          d: 2, scope: "ADJACENT", locus: "PLACE-PROPERTY", tier: "T1",
          doc: "FAA special use airspace designation", issuer: "Federal Aviation Administration",
          date: "1984-01-01", lineage: "L2" }),
        ev("e3", "Institutional records for the claimed degrees: no corroboration.", {
          d: 2, sign: "UNDERCUTS", tier: "T1", doc: "Registrar record search", issuer: "Named institutions",
          date: "2026-07-01", lineage: "U1",
          negative: { query: "degree conferral records, named institutions", result_count: 0, erp: "registrar", x: "X2" } }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", is_selected: true, disposition: "DOMINANT", reasoning: "A real, named individual whose credentials and employment are the disputed element. Identity is satisfied; position-to-know is not.", excluding: [] },
      ],
    },
    {
      ref: "p-ORIGIN-1", class: "ORIGIN",
      statement: "The S-4 claim originates in dated 1989 broadcast interviews.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [4, 4], l_d2: 3, l_d3: 2,
      predicate_args: {
        claim_text: "The S-4 claim originates with Lazar, 1989.",
        first_appearance_date: "1989-05-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "The dated broadcast recording, retrieved with a receipt.", {
          d: 4, tier: "T2", doc: "Broadcast archive recording, May 1989", issuer: "Regional broadcaster",
          date: "1989-05-01", corpus: "Internet Archive", channel: "CURATED-ARCHIVE", authority: true, lineage: "L1",
          quote: ["I worked at a facility south of Groom, at Papoose", 610, 658] }),
        ev("e2", "Negative receipt across the canonical ORIGIN set for an earlier appearance.", {
          d: 3, tier: "T1", doc: "Canonical ORIGIN search set", issuer: "Wayback CDX, broadcast archives",
          date: "2026-07-01", lineage: "L2",
          negative: { query: "\"S-4\" Papoose Lake facility before:1989", result_count: 0, erp: "ORIGIN-canonical" } }),
      ],
    },
  ],
  notes: [
    "F-04 · Under v0.1 the claim inherits GEO, INF and OWN from genuine Nevada terrain and genuine restricted airspace — the highest-value GEO signal on the rubric's own list. A-17 (Groom Lake, EXIST A) is the credibility donor this entry must not inherit from, and `scope = ADJACENT` is what stops it.",
  ],
};

/* ================================================================== *
 * F-05 / P-01 / P-02 · Site CARDINAL — THE CONFABULATION CANARY
 *
 * Under v0.1 this dossier scored 76.10 -> GRADE B, "strongly evidenced,
 * existence solid." NOTHING IN IT EXISTS.
 *
 * `is_canary` -> never publishable. Three independent blocks: the CHECK
 * constraint, the publication gate, and exclusion from the map view.
 * ================================================================== */

const siteCardinal: SpecEntity = {
  slug: "site-cardinal",
  name: "Site CARDINAL, Pendleton County WV",
  entity_level: "site",
  jurisdiction: "Pendleton County, West Virginia",
  typology: "unknown-anomaly",
  reference_class: "RC6",
  reference_class_basis: "No parcel, no land status, no facility.",
  aliases: [],
  is_canary: true,
  /** A coordinate was ASSERTED by a source. Never a pin. */
  geometry: {
    precision: "claimed_only",
    point: [-79.4, 38.6],
    radius_m: 25000,
    chart_tags: ["ED", "Rep"],
  },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A hardened federal facility designated CARDINAL exists in Pendleton County.",
      grade: "F",
      refutation_state: "R0",
      applied_caps: ["CAP-5"],
      ceiling: "F",
      at_ceiling: true,
      ceiling_reason: "CAP-5 — V is empty.",
      limiting_condition:
        "CAP-5 — V = ∅ and |V[claim]| = 0. Five emitted identifiers passed grammar validation and none resolved. GRAMMAR FAILURE IS INFORMATIVE; GRAMMAR SUCCESS IS WORTHLESS. Not X: the canonical EXIST search set WAS executed with logged negative receipts, so SCI ≈ 1.0.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE", base_rate_reading: "VERY-RARE",
      sci: [6, 6], l_d2: 0, l_d3: 0,
      condition_results: { E1: false, R1: false, R2: false, "CAP-5": true },
      /**
       * THE FIVE RETAINED IDENTIFIERS. `v0_count` counts to 5 from these rows,
       * because they are these rows. They are RETAINED, not deleted: they are
       * confabulation telemetry, attributed per agent and published in the
       * measured confabulation rate.
       */
      observations: [
        ev("e1", "Emitted CREST identifier: grammar passes, 404 at the issuing authority and at the CREST mirror.", {
          d: 0, tier: "T1", doc: "Asserted CREST document", ident: "CIA-RDP80B01676R002900110001-4",
          identClass: "CREST", receipt: notFound("https://www.cia.gov/readingroom/"), date: "1963-01-01", lineage: "L1" }),
        ev("e2", "Second emitted CREST identifier: grammar passes, 404.", {
          d: 0, tier: "T1", doc: "Asserted CREST document", ident: "CIA-RDP80B01676R002900110002-3",
          identClass: "CREST", receipt: notFound("https://www.cia.gov/readingroom/"), date: "1964-01-01", lineage: "L1" }),
        ev("e3", "Third emitted CREST identifier: grammar passes, 404.", {
          d: 0, tier: "T1", doc: "Asserted CREST document", ident: "CIA-RDP80B01676R002900110003-2",
          identClass: "CREST", receipt: notFound("https://www.cia.gov/readingroom/"), date: "1965-01-01", lineage: "L1" }),
        ev("e4", "Emitted DTIC accession number: grammar passes, 404 at apps.dtic.mil and at the mirror.", {
          d: 0, tier: "T1", doc: "Asserted DTIC report", ident: "AD-0742119", identClass: "DTIC",
          receipt: notFound("https://apps.dtic.mil/"), date: "1970-01-01", lineage: "L2" }),
        ev("e5", "\"A plausible appropriations line\": no GovInfo package id, no resolution.", {
          d: 0, tier: "T1", doc: "Asserted appropriations line", identClass: "GovInfo",
          receipt: notFound("https://www.govinfo.gov/"), date: "1968-01-01", lineage: "L3" }),
        ev("e6", "\"An adit symbol at 38.6xx, −79.4xx on the 1953 quadrangle.\" The HTMC point-in-polygon DOES return the sheet and the GeoTIFF IS fetched — that part is real. But the READING is an interpretation and inherits the tier of whoever asserted it.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T5", doc: "Interpretation of a symbol on the 1953 quadrangle",
          issuer: "asserting agent", date: "2026-06-01",
          selfAttesting: "an interpretation, not a reading: T5 and a hypothesis until a different-family blind second read plus a citation to the era-correct symbol standard. Neither exists.",
          lineage: "L4" }),
        ev("e7", "A real FCC ASR registration 3 km away: resolves, real, T1 — and ADJACENT.", {
          d: 1, scope: "ADJACENT", tier: "T1", doc: "FCC Antenna Structure Registration",
          issuer: "Federal Communications Commission", ident: "ASR 1281004", identClass: "FCC-ASR",
          date: "1988-01-01", lineage: "L5" }),
        /**
         * The seventh returned item — "an account citing an alleged local
         * newspaper" — carries NO IDENTIFIER, so it is not one of the five
         * confabulated identifiers and does not enter v0_count. It is recorded
         * where it belongs: as the Chronicling America / Open ONI row in the
         * silence table below, whose egress state is PROXY-BLOCKED. That
         * distinction is the P-01 assertion in miniature — a blocked proxy must
         * not inflate the published fabrication metric.
         */
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", is_selected: true, disposition: "DOMINANT", reasoning: "Nothing there. Five format-valid identifiers, none of which resolves; one adjacent real tower; one interpretation of a map symbol.", excluding: [] },
      ],
      silence: [
        { record_class: "CREST", expected_record_level: "X2", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 5100…ab2", egress_state: "REACHABLE" },
        { record_class: "DTIC", expected_record_level: "X2", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 e8c3…4d9", egress_state: "REACHABLE" },
        { record_class: "GovInfo appropriations", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 1f77…62b", egress_state: "REACHABLE" },
        { record_class: "Chronicling America / Open ONI", expected_record_level: "X2", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 90aa…7c4", egress_state: "PROXY-BLOCKED" },
      ],
    },
  ],
  notes: [
    "P-01 assertions: receipt_state = UNRESOLVED-NOTFOUND, not UNRESOLVED-UNREACHABLE — the distinction is the whole point; a blocked proxy must not inflate the published fabrication metric. membership = V0 BY GENERATED COLUMN, not by any agent's assertion. The rows are RETAINED and counted.",
    "P-02 assertions: the canary can never be published (three independent blocks); the canary roster is unreachable to anonymous readers; canaries rotate so they cannot be memorised; the measured rate is published on the methodology page beside the grade definitions.",
    "THE INCENTIVE INVERSION THIS REPAIRS: under v0.1, citing a forum post required possessing a URL that exists, while citing a CREST document required only emitting a well-formed string — the higher the tier and the more format-regular the identifier, the easier to hallucinate and the more weight it carried.",
  ],
};

/* ================================================================== *
 * F-06 · Comet Ping Pong — KNOWN DIVERGENCE, conditional.
 * The two halves of the skeptic's requirement conflict under BES.
 * This fixture takes the R branch and names it, which is what the
 * suite requires: `limiting_condition` OR `refutation_state` must
 * name WHICH branch was taken.
 * ================================================================== */

const cometPingPong: SpecEntity = {
  slug: "comet-ping-pong-tunnel-claim",
  name: "Comet Ping Pong tunnel/basement claim",
  entity_level: "structure",
  jurisdiction: "District of Columbia",
  typology: "unknown-anomaly",
  reference_class: "RC4",
  reference_class_basis: "Private commercial storefront parcel.",
  aliases: [],
  geometry: { precision: "surveyed", point: [-77.0637, 38.9556] },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "The building contains a basement and a tunnel system.",
      grade: "R",
      refutation_state: "R3",
      ceiling_reason:
        "R3 — the District building record is a verified, instance-scope, subject-bound, unsolicited row from a party WITH AUTHORITY OVER THE FACT, directly stating the negation: the structure has no basement.",
      limiting_condition:
        "BRANCH TAKEN: the DCRA building record resolved, so BES returns R (R3) rather than F. This is the STRONGER answer and it satisfies the skeptic's second requirement — F for a stated reason — while failing the first, the letter F. Had the record not resolved, V = ∅ via §2.5 (the 4chan/Reddit origin is self-attesting) -> CAP-5 -> F, which satisfies the letter for exactly the reason the skeptic wanted to eliminate.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "INFORMATIVE", base_rate_reading: "VERY-RARE",
      sci: [5, 5], l_d2: 0, l_d3: 0,
      condition_results: { R3: true, "CAP-5": null },
      predicate_args: {
        claim_text: "The building contains a basement and a tunnel system.",
        first_appearance_date: "2016-10-30",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "The dated 2016 origin cluster on anonymous message boards.", {
          d: 0, tier: "T5", doc: "Anonymous message-board origin cluster", date: "2016-10-30",
          channel: "ADVERSARY-WRITABLE", provenance: "CROWD-EDITED", adversary: true,
          selfAttesting: "the posters are the claimants and the posts are the claim",
          lineage: "L1", siglum: "C1" }),
        ev("u1", "District building record: the structure has no basement.", {
          d: 4, sign: "UNDERCUTS", tier: "T1", doc: "DCRA building record and certificate of occupancy",
          issuer: "District of Columbia Department of Consumer and Regulatory Affairs",
          date: "2004-01-01", authority: true, refutes: "R3", lineage: "U1",
          quote: ["one story on slab; no cellar or basement", 220, 258] }),
        ev("u2", "Filed floor plan showing slab-on-grade construction.", {
          d: 3, sign: "UNDERCUTS", tier: "T1", doc: "Filed floor plan", issuer: "District of Columbia",
          date: "2004-01-01", refutes: "R3", lineage: "U2" }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", is_selected: true, disposition: "DOMINANT", reasoning: "A retail storefront with a documented slab-on-grade construction and no cellar.", excluding: ["u1"] },
      ],
      movement: [
        { occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "F", cause: "INITIAL", note: "Silence-dominated before the building record resolved." },
        { occurred_at: "2026-06-11T00:00:00Z", from: "F", to: "R", cause: "REFUTATION", note: "The DCRA record resolved. F for lack of infrastructure becomes R for a stated reason." },
      ],
    },
    {
      ref: "p-ORIGIN-1", class: "ORIGIN",
      statement: "The claim originates in a dated late-2016 message-board cluster.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [4, 4], l_d2: 3, l_d3: 2,
      predicate_args: {
        claim_text: "The Comet Ping Pong tunnel claim originates in late 2016.",
        first_appearance_date: "2016-10-30",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "Dated archival captures of the origin cluster, retrieved with receipts.", {
          d: 4, tier: "T2", doc: "Wayback captures of the origin cluster", corpus: "Internet Archive",
          channel: "CURATED-ARCHIVE", date: "2016-10-30", authority: true, lineage: "L1",
          quote: ["first capture of the thread, 30 October 2016", 40, 82] }),
        ev("e2", "Negative receipt across the canonical ORIGIN set for an earlier appearance.", {
          d: 3, tier: "T1", doc: "Canonical ORIGIN search set", issuer: "Wayback CDX", date: "2026-07-01",
          lineage: "L2", negative: { query: "Comet Ping Pong basement tunnel before:2016-10-30", result_count: 0, erp: "ORIGIN-canonical" } }),
      ],
    },
  ],
  notes: [
    "F-06 fails only in one way: if the entry returned F with the origin-lack as the only recorded reason WHILE a resolvable building record exists — because that is the register declining to do the work it exists to do.",
    "This is the same shape as R-05 (Dulce): a reviewer wrote F under a vocabulary in which R was unreachable, and BES's R is the better answer.",
  ],
};

/* ================================================================== *
 * A-12 / R-05 · Dulce Base — THE SHARPEST DECLARED DIVERGENCE.
 * ORIG A ESTABLISHED below the unclamped rule; EXST R REFUTED above
 * it. An A-grade fact about a fabrication and a refuted facility on
 * one page, without either lying about the other.
 * ================================================================== */

const dulceBase: SpecEntity = {
  slug: "dulce-base",
  name: "Dulce Base, Archuleta Mesa",
  entity_level: "site",
  jurisdiction: "Rio Arriba County, New Mexico",
  typology: "unknown-anomaly",
  reference_class: "RC6",
  reference_class_basis: "Tribal and BLM land; no facility parcel is asserted by any record.",
  aliases: ["Dulce Base", "the Archuleta Mesa facility"],
  /** DESIGN.md §9.6's own NOT LOCATABLE example. A name, not a place. */
  geometry: {
    precision: "place_name_only",
    claimed_place_name: "Archuleta Mesa, Dulce NM",
  },
  propositions: [
    {
      /**
       * R-05 · R1, ORIGIN FABRICATED, on FOUR independent grounds. §8.4's gate
       * is satisfied several times over: every one is affirmative content, not
       * an expected-record negative.
       *
       * BOTH REVIEWERS EXPECTED F. BES RETURNS R DELIBERATELY. The historian's
       * own text demands that the AFOSI/Doty documentation "must be
       * representable as evidence AGAINST" — that IS R by definition, and their
       * F was constrained by v0.1's vocabulary, in which R was unreachable.
       *
       * UNDER v0.1, u1 ADDED TO THE DOC AXIS. A documented disinformation
       * operation counted as documentation FOR the claim. That single fact is
       * the clearest statement of what signed evidence fixes.
       */
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A multi-level underground facility exists beneath Archuleta Mesa.",
      grade: "R",
      refutation_state: "R1",
      ceiling_reason:
        "R1 — ORIGIN FABRICATED, on four independent grounds: a documented counterintelligence operation supplying forged material to the originator; a later admission of fabrication by a distinct admitting party; two resolvable officials stating on the record that no such person was employed there; and a deterministic post-dating impossibility.",
      limiting_condition:
        "R1 established on affirmative content. The alternative scoring against A01 also runs and the LOWER grade publishes. A11 is MANDATORY as co-null because the support includes a T5 lineage.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "VERY-RARE",
      sci: [6, 6], l_d2: 0, l_d3: 0,
      condition_results: { R1: true, "§8.4-gate": true },
      predicate_args: {
        claim_text: "A multi-level underground facility exists beneath Archuleta Mesa.",
        first_appearance_date: "1979-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "The originator's 1979–80 assertions.", {
          d: 0, tier: "T5", doc: "Originator's assertions, Albuquerque, 1979–80", author: "Paul Bennewitz",
          date: "1979-06-01", selfAttesting: "the claimant asserting the claim", lineage: "L1", siglum: "B1" }),
        ev("e2", "\"Thomas Castello\" documents.", {
          d: 0, tier: "T5", doc: "\"Thomas Castello\" documents", date: "1987-01-01",
          selfAttesting: "fails the §5.4 resolvability gate — no independent record predating the claim, created for an unrelated purpose, places this person anywhere; and the content is the claim",
          lineage: "L1", siglum: "B4" }),
        ev("e3", "Project Gasbuggy: a 1967 AEC underground detonation about 20 miles away, with a full AEC/DOE paper trail. VERIFIED, T1 — AND ADJACENT.", {
          d: 3, scope: "ADJACENT", tier: "T1", doc: "Project Gasbuggy AEC record", issuer: "Atomic Energy Commission",
          date: "1967-12-10", lineage: "L2" }),
        ev("e4", "New Mexico State Police cattle-mutilation files: VERIFIED, T1, and bound to a different proposition.", {
          d: 2, tier: "T1", doc: "NM State Police investigation files", issuer: "New Mexico State Police",
          author: "Gabe Valdez", date: "1976-01-01", binding: false, lineage: "L3" }),
        ev("e5", "Jicarilla/BLM land records, terrain, road cuts and regional mining scarring: INSTANCE, VERIFIED, and PLACE-PROPERTY at D0.", {
          d: 0, locus: "PLACE-PROPERTY", tier: "T1", doc: "BLM land and mining records",
          issuer: "Bureau of Land Management", date: "1985-01-01", lineage: "L4" }),
        ev("u1", "The AFOSI counterintelligence operation against the originator, c.1979–82, in which forged documents and staged material were supplied to steer him away from classified programmes.", {
          d: 3, sign: "UNDERCUTS", tier: "T3", doc: "Project Beta (transparent compiler; §5.1.3 pulls the primaries)",
          author: "Greg Bishop", issuer: "on-record admissions by the operation's officer", date: "2005-01-01",
          refutes: "R1", lineage: "U1",
          quote: ["material was prepared and given to him that was not true", 8210, 8262] }),
        ev("u2", "A later admission of fabricating Dulce material by a distinct admitting party, documented by an independent researcher.", {
          d: 3, sign: "UNDERCUTS", tier: "T3", doc: "Documented admission of fabrication", author: "Adam Gorightly",
          date: "2013-01-01", refutes: "R1", lineage: "U2" }),
        ev("u3", "A retired USAF colonel and a New Mexico State Police officer, both resolvable and both custody-receipted in named press, stating on the record that no such person was employed there.", {
          d: 3, sign: "UNDERCUTS", tier: "T2", doc: "Bylined press interviews with two resolvable officials",
          issuer: "Named regional press", date: "1990-01-01", refutes: "R1", lineage: "U3",
          quote: ["there was no such person on that installation", 1020, 1066] }),
        ev("u4", "POST-DATING IMPOSSIBILITY: images attributed to \"Castello\" and dated 1987 include a still from a film released in 2000. Deterministic and machine-checkable.", {
          d: 4, sign: "UNDERCUTS", tier: "T1", doc: "Image provenance analysis, deterministic",
          issuer: "frame-level comparison against the 2000 release", date: "2026-05-01",
          authority: true, refutes: "R1", lineage: "U4",
          quote: ["frame identical to the 2000 release; the 1987 attribution is impossible", 90, 158] }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "Claim fabricated, misattributed or transposed", is_selected: true, disposition: "DOMINANT", reasoning: "MANDATORY as co-null because the support includes a T5 lineage. Affirmatively documented on four independent grounds.", excluding: ["u1", "u2", "u3", "u4"] },
        { null_code: "A01", label: "no constructed object", description: "No constructed object exists here at all", disposition: "SURVIVING", reasoning: "The alternative scoring against A01 also runs; the LOWER grade publishes.", excluding: [] },
      ],
      lineage: {
        document_count: 400,
        lineage_count: 1,
        verdict:
          "≈400 citing documents · 1 independent lineage · collapse delta ≈399. Each read the prior one; none contains a particular absent from its predecessor. ONE lineage, not four.",
        citogenesis_note:
          "Bennewitz 1979 → popular press 1983 → the 1987 'independent confirmation' → a pseudonymous intermediary → the 1987 'Castello' documents → a compiler → a later author → a fringe portal → roughly 400 downstream sites. Semantic clustering collapses the chain; §2.5 then excludes each claimant from V entirely.",
        blocks: [
          {
            origin: { siglum: "B1", label: "Bennewitz, Albuquerque, 1979–80", document_date: "1979-06-01", origin_tier: "T5" },
            descendants: [
              { siglum: "B2", label: "Popular press, 1983", document_date: "1983-01-01", origin_tier: "T4", collapses: true },
              { siglum: "B3", label: "\"Independent confirmation\", 1987", document_date: "1987-01-01", origin_tier: "T5", collapses: true, edge_kind: "contamination" },
              { siglum: "B4", label: "\"Thomas Castello\" documents", document_date: "1987-01-01", origin_tier: "T5", collapses: true },
              { siglum: "B9", label: "Fringe portal, ~400 downstream sites", document_date: "2001-01-01", origin_tier: "T5", collapses: true },
            ],
            downstream_count: 399,
          },
        ],
      },
      movement: [
        { occurred_at: "2026-03-04T00:00:00Z", from: "X", to: "F", cause: "INITIAL" },
        { occurred_at: "2026-05-30T00:00:00Z", from: "F", to: "R", cause: "REFUTATION", note: "R1 established on four independent affirmative grounds." },
      ],
    },
    {
      ref: "p-HARDEN-1", class: "HARDEN",
      statement: "The claimed facility is hardened.",
      grade: "R", refutation_state: "R1",
      clamped_by: "p-EXIST-1",
      grade_pre_clamp: "F",
      ceiling_reason: "Clamped by the parent EXIST proposition, which is R.",
      limiting_condition: "R1 on the parent. A hardening claim about a facility whose existence is refuted has no independent ledger to stand on.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "UNINFORMATIVE", sci: [4, 4], l_d2: 0, l_d3: 0,
      observations: [],
    },
    {
      ref: "p-FUNCTION-1", class: "FUNCTION",
      statement: "The claimed facility houses a joint biological research programme.",
      grade: "R", refutation_state: "R1",
      clamped_by: "p-EXIST-1",
      grade_pre_clamp: "F",
      applied_caps: ["CAP-2b"],
      ceiling_reason: "Clamped by the parent EXIST proposition, which is R. CAP-2b applies independently: |V[claim]| = 0.",
      limiting_condition: "R1 on the parent.",
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "DOMINANT",
      silence_reading: "UNINFORMATIVE", base_rate_reading: "VERY-RARE", sci: [4, 4], l_d2: 0, l_d3: 0,
      predicate_args: {
        claim_text: "The Dulce facility houses a joint biological research programme.",
        first_appearance_date: "1979-01-01",
        first_appearance_confidence: "document date",
      },
      observations: [],
    },
    {
      ref: "p-LOCATE-1", class: "LOCATE",
      statement: "The claimed facility is located beneath Archuleta Mesa.",
      grade: "R", refutation_state: "R1",
      clamped_by: "p-EXIST-1",
      grade_pre_clamp: "F",
      ceiling_reason: "Clamped by the parent EXIST proposition, which is R.",
      limiting_condition:
        "R1 on the parent. locate_precision is place_name_only: a place NAME was claimed and no coordinate exists at all. The entity appears in the NOT LOCATABLE ON THIS PLATE panel and nowhere on the sheet.",
      null_code: "A01", null_label: "no constructed object", null_state: "DOMINANT",
      silence_reading: "UNINFORMATIVE", sci: [3, 3], l_d2: 0, l_d3: 0,
      observations: [],
    },
    {
      /**
       * A-12 · THE PART v0.1 COULD NOT DO AT ALL. D4 for the ORIGIN class,
       * because the dated earliest artifact retrieved with a receipt IS the
       * evidence for an origin claim. T5 content quality, T2 archive quality,
       * recorded as BOTH (§3.1). Plus the NEGATIVE RECEIPT the ORIGIN
       * definition requires.
       *
       * THIS IS THE REGISTER PUBLISHING AN A-GRADE FACT ABOUT A FABRICATION,
       * and it is why ORIGIN is clamp-exempt.
       */
      ref: "p-ORIGIN-1", class: "ORIGIN",
      statement:
        "The Dulce Base claim first appears with Bennewitz in Albuquerque, 1979–80.",
      grade: "A", ceiling: "A", at_ceiling: true,
      null_code: "A11", null_label: "fabricated or misattributed", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "UNCOMMON",
      sci: [6, 6], l_d2: 4, l_d3: 3,
      condition_results: { A1: true, A3: true },
      predicate_args: {
        claim_text: "The Dulce Base claim originates with Bennewitz, 1979–80.",
        first_appearance_date: "1979-06-01",
        first_appearance_confidence: "document date",
      },
      observations: [
        ev("e1", "Dated APRO Bulletin appearance in the AFU collection: T5 content quality, T2 archive quality, recorded as BOTH.", {
          d: 4, tier: "T2", doc: "APRO Bulletin, dated issue", corpus: "AFU collection, Internet Archive",
          channel: "CURATED-ARCHIVE", date: "1980-03-01", authority: true, lineage: "L1",
          quote: ["reports of an installation beneath the mesa near Dulce", 1420, 1472] }),
        ev("e2", "Dated regional newsletter appearance in the same collection.", {
          d: 3, tier: "T2", doc: "Regional newsletter, dated issue", corpus: "AFU collection, Internet Archive",
          channel: "CURATED-ARCHIVE", date: "1980-09-01", lineage: "L2" }),
        ev("e3", "Transparent-compiler reconstruction of the origin, exposing its primaries.", {
          d: 3, tier: "T3", doc: "Project Beta", author: "Greg Bishop", date: "2005-01-01", lineage: "L3" }),
        ev("e4", "Logged, dated negative searches across Wayback CDX, IA full-text hits_inside, the AFU newsletter runs, UTZOO mirrors and the mirrored aggregator corpus, returning NO EARLIER APPEARANCE, with query strings, corpora, versions and result counts recorded.", {
          d: 3, tier: "T1", doc: "Canonical ORIGIN search set", issuer: "Wayback CDX, IA full-text, AFU runs, UTZOO mirrors",
          date: "2026-07-01", lineage: "L4",
          negative: { query: "Dulce base underground installation before:1979-06", result_count: 0, erp: "ORIGIN-canonical" } }),
      ],
      alternatives: [
        { null_code: "A11", label: "fabricated or misattributed", description: "The claim predates Bennewitz and he merely repeated it", disposition: "EXCLUDED", reasoning: "A3 holds because this null is EXCLUDED by the negative receipt across the canonical ORIGIN set.", excluding: ["e4"] },
      ],
      searches: [
        { query: "Dulce underground base before:1979", corpus_as_of: "2026-07-01", outcome: "NEGATIVE", result_count: 0, erp_profile: "ORIGIN-canonical", egress_state: "REACHABLE" },
        { query: "APRO Bulletin Dulce 1979..1981", corpus_as_of: "2026-07-01", outcome: "POSITIVE", result_count: 2, erp_profile: "ORIGIN-canonical", egress_state: "REACHABLE" },
      ],
    },
  ],
  notes: [
    "R-05 · Under v0.1 grade F was UNREACHABLE: the CONTAM multiplier floors at ×0.5, so even a flawless lineage analysis returned 20.65 → E. And following v0.1's own calibration text, the three named claimants yield CONTAM ≈ 55 and the entry RISES to 23.49.",
    "The contrast published alongside is the whole reason the entry exists: EXIST(some constructed works on Archuleta Mesa — roads, gas-field wells) grades honestly at C or better, as a separate entity. 'There are real works on this mesa' and 'the base claim is refuted' sit side by side, which is what a reader arriving from the fringe corpus needs to see.",
  ],
};

const archuletaWorks: SpecEntity = {
  slug: "archuleta-mesa-works",
  name: "Constructed works on Archuleta Mesa",
  entity_level: "site",
  jurisdiction: "Rio Arriba County, New Mexico",
  typology: "mine-conversion",
  reference_class: "RC5",
  reference_class_basis: "Tribal and BLM land with documented resource development.",
  aliases: [],
  distinct_from: [
    { slug: "dulce-base", name: "Dulce Base, Archuleta Mesa", note: "The refuted claim attached to the same mesa. These are different entities with different ledgers and they must never merge." },
  ],
  geometry: {
    precision: "regional",
    polygon: [[-107.05, 36.90], [-106.85, 36.90], [-106.85, 37.02], [-107.05, 37.02]],
    chart_tags: ["PA"],
  },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement:
        "Constructed works — roads, road cuts and gas-field wells — exist on Archuleta Mesa.",
      grade: "C",
      ceiling: "B",
      at_ceiling: false,
      limiting_condition:
        "A1/B1 — the works are documented at class level in land and resource records; no single record enumerates them at instance level. The documents that would move this: a BLM right-of-way grant or a well-file set naming these specific works.",
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", base_rate_reading: "COMMON",
      sci: [4, 5], l_d2: 2, l_d3: 1,
      observations: [
        ev("e1", "BLM land and mining records for the mesa.", {
          d: 3, tier: "T1", doc: "BLM land and mining records", issuer: "Bureau of Land Management",
          date: "1985-01-01", lineage: "L1",
          quote: ["access roads and well pads within the described township", 620, 676] }),
        ev("e2", "State oil and gas well files for the field.", {
          d: 2, tier: "T1", doc: "State oil and gas well files", issuer: "New Mexico Oil Conservation Division",
          date: "1990-01-01", lineage: "L2" }),
        ev("e3", "Road cuts and pads visible on public orthoimagery.", {
          d: 1, locus: "PLACE-PROPERTY", tier: "T1", doc: "USGS orthoimagery", issuer: "U.S. Geological Survey",
          date: "2020-01-01", lineage: "L1" }),
      ],
    },
    {
      ref: "p-LOCATE-1", class: "LOCATE",
      statement: "The works lie within the region shown.",
      grade: "C",
      ceiling: "B",
      at_ceiling: false,
      limiting_condition: "Positional knowledge is at township scale. The mark is the region.",
      null_code: "A01", null_label: "no constructed object", null_state: "EXCLUDED",
      silence_reading: "INFORMATIVE", sci: [3, 4], l_d2: 2, l_d3: 1,
      observations: [
        ev("e1", "Township and range description in the BLM record.", {
          d: 3, tier: "T1", doc: "BLM land record", issuer: "Bureau of Land Management", date: "1985-01-01", lineage: "L1" }),
      ],
    },
  ],
};

/* ================================================================== *
 * X-01 / P-03 / P-04 / P-05 · A newly ingested candidate before search
 * X is the correct default for every newly ingested candidate, and it
 * must render visually distinct from F. X is not a low grade; it is
 * the ABSENCE of one.
 *
 * This entity also carries the three ingestion-path states, because
 * they are what a newly ingested candidate actually arrives with.
 * ================================================================== */

const newlyIngested: SpecEntity = {
  slug: "candidate-2026-0141",
  name: "Unnamed candidate 2026-0141",
  entity_level: "site",
  jurisdiction: "Pocahontas County, West Virginia",
  typology: "unknown-anomaly",
  reference_class: "RC5",
  reference_class_basis: "Private parcel adjacent to a national forest boundary (PAD-US).",
  aliases: [],
  /**
   * Declared `approximate_1km`, but the LOCATE proposition is X — below band C
   * — so `core.render_geometry`'s hard gate REFUSES THE POINT and degrades the
   * feature to an uncertainty circle with no centre mark. The suppression
   * reason is published beside it. This is the gate doing its job on the one
   * kind of record most likely to be wrong.
   */
  geometry: {
    precision: "approximate_1km",
    point: [-80.2181, 38.4331],
    radius_m: 1000,
    chart_tags: ["ED", "PA"],
  },
  propositions: [
    {
      ref: "p-EXIST-1", class: "EXIST",
      statement: "A hardened subsurface structure exists on this parcel.",
      grade: "X",
      limiting_condition:
        "X — INSUFFICIENT SEARCH (SCI 0.33). A candidate whose provisional grade would be D/E/F/R publishes X with the fraction shown until the canonical search set has run. Grades A, B and C publish at ANY SCI: positive evidence does not require exhaustion, but a negative verdict does.",
      verification_debt: { leads: 3, max_reachable: "C" },
      null_code: "A01", null_label: "no constructed object", null_state: "UNTESTED",
      silence_reading: "UNSEARCHED", base_rate_reading: "UNCOMMON",
      sci: [2, 6], l_d2: 0, l_d3: 0,
      condition_results: { A1: null, B1: null, C1a: null, D1: null },
      observations: [
        ev("e1", "P-03 · An unbylined post-2022 page describing the parcel. First observed after the machine-generated-text waterline; no named author, no byline history, no pre-2022 domain capture. Computed from Wayback CDX and domain registration, NEVER JUDGED — and no AI-text classifier is used anywhere in the pipeline.", {
          d: 0, tier: "T4", doc: "Unbylined article, post-2022 domain", era: "POST-2022-UNATTRIBUTED",
          date: "2024-04-01", host: "example-content-farm.invalid", lineage: "L1" }),
        ev("e2", "P-03 · A second machine-written encyclopedia-style entry on the same subject. Four such sources yield ZERO lineages.", {
          d: 0, tier: "T4", doc: "Machine-written encyclopedia entry", era: "POST-2022-UNATTRIBUTED",
          date: "2025-11-02", lineage: "L1" }),
        ev("e3", "P-04 · An OpenStreetMap node tagged military=bunker at a real coordinate, with its changeset author, timestamp and comment recorded. Replication into N renderers is ONE lineage: propagated by DATABASE REPLICATION rather than by citation, a mechanism a citation graph cannot observe at all.", {
          d: 0, tier: "T5", doc: "OpenStreetMap node, military=bunker", channel: "ADVERSARY-WRITABLE",
          provenance: "CROWD-EDITED", adversary: true, date: "2023-08-14", lineage: "L2" }),
        ev("e4", "P-05 · A source first observed AFTER this register published the candidate. Quarantined: retained, displayed, zero lineages, zero conditions. A grade may RISE only on evidence whose own document date precedes our publication; downward movement carries no such restriction, because the failure mode is inflation.", {
          d: 0, tier: "T4", doc: "Derivative article postdating our publication", date: "2026-06-01",
          era: "POST-2022-ATTRIBUTED", lineage: "L3" }),
        ev("e5", "An emitted identifier awaiting resolution.", {
          d: 0, tier: "T1", doc: "Asserted federal record", ident: "AD-0812345", identClass: "DTIC",
          receipt: unreachable("https://apps.dtic.mil/"), date: "1974-01-01", lineage: "L4" }),
      ],
      silence: [
        { record_class: "MILCON / DD-1391", expected_record_level: "X2", searched: false },
        { record_class: "CREST", expected_record_level: "X2", searched: false },
        { record_class: "County deed", expected_record_level: "X3", searched: true, outcome: "POSITIVE", result_count: 1, receipt: "sha256 aa10…3f2" },
        { record_class: "Historical topographic map", expected_record_level: "X3", searched: true, outcome: "NEGATIVE", result_count: 0, receipt: "sha256 77e5…ba1" },
        { record_class: "FPDS / USAspending", expected_record_level: "X2", searched: false },
        { record_class: "NEPA documentation", expected_record_level: "X1", searched: false },
      ],
      searches: [
        { query: "Pocahontas County WV parcel deed 1965..1975", corpus_as_of: "2026-07-01", outcome: "POSITIVE", result_count: 1 },
        { query: "HTMC 7.5-minute sheet, adit symbols", corpus_as_of: "2026-07-01", outcome: "NEGATIVE", result_count: 0 },
        { query: "MILCON DD-1391 Pocahontas County", outcome: "UNSEARCHED", egress_state: "PENDING-ALLOWLIST" },
      ],
      movement: [{ occurred_at: "2026-08-01T00:00:00Z", from: undefined, to: "X", cause: "INITIAL", note: "Ingested; canonical search set not yet run." }],
    },
    {
      ref: "p-LOCATE-1", class: "LOCATE",
      statement: "The structure lies within one kilometre of the asserted coordinate.",
      grade: "X",
      limiting_condition:
        "X — the coordinate was asserted by an adversary-writable source and has not been independently established. Because LOCATE is below band C, core.render_geometry refuses the point and emits an uncertainty circle: RENDERED AS UNCERTAINTY, NEVER AS A PIN.",
      null_code: "A01", null_label: "no constructed object", null_state: "UNTESTED",
      silence_reading: "UNSEARCHED", sci: [1, 4], l_d2: 0, l_d3: 0,
      observations: [
        ev("e1", "The coordinate asserted by the OSM node.", {
          d: 0, tier: "T5", doc: "OpenStreetMap node, military=bunker", channel: "ADVERSARY-WRITABLE",
          provenance: "CROWD-EDITED", adversary: true, date: "2023-08-14", lineage: "L1" }),
      ],
    },
  ],
  notes: [
    "X-01 assertions: a candidate with SCI < 0.5 whose provisional grade would be D/E/F/R publishes X — INSUFFICIENT SEARCH with the fraction shown; grades A, B and C publish at any SCI; R SHORT-CIRCUITS THE FLOOR (ratification item R-1, a declared and contested behaviour the suite pins so a change is visible); a proposition holding an unverified lead whose claimed diagnosticity could raise its band publishes X — VERIFICATION PENDING with its verification debt; SCI with an empty denominator is 1.000, not 0.",
    "P-05 · THE RATCHET TESTS THE TRIGGERING ROWS, NOT ALL OF V. Testing all of V means one unrelated recent blog post freezes the proposition against a genuine new archival find forever. That polarity error was present in one of the two schema proposals and is the kind of bug that looks like caution.",
    "P-05 · A blocked rise is not silent: limiting_condition records that upward movement was withheld. NEW-DISCLOSURE, MERGE and SPLIT are exempt from the ratchet; the three instrument-drift causes are too.",
  ],
};

export const CLAIMS_ENTITIES: SpecEntity[] = [
  montaukProject,
  telos,
  sauderCorpus,
  s4PapooseLake,
  siteCardinal,
  cometPingPong,
  dulceBase,
  archuletaWorks,
  newlyIngested,
];
