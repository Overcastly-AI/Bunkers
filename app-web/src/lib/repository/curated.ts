/**
 * CURATED TABLES — the content that is populated on day one.
 *
 * DESIGN.md §18.4: "The site is not actually empty, because the instrument is
 * already reporting on itself. /method, /method/expected-records, /limits,
 * /decisions, /sources and /telemetry are complete and populated on day one."
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * SCOPE OF THIS FILE, STATED PLAINLY, BECAUSE THE ALTERNATIVE IS FABRICATION.
 *
 * `docs/SOURCE-REGISTRY.md` catalogues 158 sources across five beats and
 * `registry.corpus` is their home. THIS FILE IS A PARTIAL TRANSCRIPTION — the
 * eighteen sources named in `docs/CALIBRATION.md`, `docs/SCHEMA.md` and
 * `docs/DECISIONS.md`, which is what the calibration set actually exercises.
 * The remaining rows must be imported from the registry rather than written
 * here: inventing 140 corpus rows to make a table look full would be precisely
 * the confabulation this register measures.
 *
 * `/sources` therefore prints what it has, states the count it has, and states
 * the count it does not. A partial table that says so is a finding aid; a
 * padded one is a lie.
 *
 * SOURCE-REGISTRY.md rule 3, which governs every row below: "EVERY ENDPOINT
 * BELOW IS CURRENTLY UNVERIFIED. Three of the five registries were written with
 * .gov and .mil egress blocked… By the register's own standard, this document
 * is V0-UNRESOLVED." Hence `egress_state: "UNPROBED"` on every row and
 * `egress_probed_at: null`. Zero of 122 hosts are reachable (D-007).
 * ─────────────────────────────────────────────────────────────────────────────
 */

import type { ExpectedRecordRow, MethodologyCoverageRow } from "../types/api";

/** How many of the 158 catalogued sources this file carries. Printed on `/sources`. */
export const CORPUS_TRANSCRIBED = 18;
export const CORPUS_CATALOGUED = 158;
export const HOSTS_IN_ACCESS_SCHEDULE = 122;

function corpus(
  slug: string,
  name: string,
  beat: string,
  host: string,
  host_tier: MethodologyCoverageRow["host_tier"],
  content_tier: MethodologyCoverageRow["content_tier"],
  value: string,
  extra: Partial<MethodologyCoverageRow> = {},
): MethodologyCoverageRow {
  return {
    slug,
    name,
    beat,
    host,
    host_tier,
    content_tier,
    value,
    robots_posture: "unverified — strictest reading binding until P0 proves otherwise",
    rate_limits: null,
    egress_state: "UNPROBED",
    egress_probed_at: null,
    adversary_writable: false,
    tier_trap: false,
    machine_generated_blocklist: false,
    ...extra,
  };
}

export const CORPUS_SAMPLE: MethodologyCoverageRow[] = [
  corpus("crest", "CIA Records Search Tool (CREST)", "federal declassification", "cia.gov", "T1", "T1", "CRITICAL"),
  corpus("dtic", "Defense Technical Information Center", "federal declassification", "apps.dtic.mil", "T1", "T1", "CRITICAL"),
  corpus("nara", "National Archives and Records Administration", "federal declassification", "catalog.archives.gov", "T1", "T1", "CRITICAL"),
  corpus("govinfo", "GovInfo — congressional and Federal Register packages", "appropriations and oversight", "govinfo.gov", "T1", "T1", "CRITICAL"),
  corpus("frus", "Foreign Relations of the United States", "federal declassification", "history.state.gov", "T1", "T1", "HIGH", {
    rate_limits: "git-clonable TEI XML; resolution, subject binding and quote-grounding are deterministic and offline-verifiable",
  }),
  corpus("fpds", "FPDS / USAspending", "procurement", "usaspending.gov", "T1", "T1", "HIGH"),
  corpus("frpp", "Federal Real Property Profile", "real property", "gsa.gov", "T1", "T1", "HIGH"),
  corpus("gao", "Government Accountability Office reports", "appropriations and oversight", "gao.gov", "T1", "T1", "HIGH"),
  corpus("afhra", "Air Force Historical Research Agency (IRIS)", "unit histories", "afhra.af.mil", "T1", "T1", "HIGH"),
  corpus("usgs-htmc", "USGS Historical Topographic Map Collection", "terrain and cartography", "ngmdb.usgs.gov", "T1", "T1", "CRITICAL"),
  corpus("padus", "PAD-US protected areas and land status", "terrain and cartography", "usgs.gov", "T1", "T1", "HIGH", {
    value: "HIGH — reference class RC1–RC6 is assigned from land status, so the base-rate reading follows from it",
  }),
  corpus("fcc-uls", "FCC Universal Licensing System / Antenna Structure Registration", "licensing", "fcc.gov", "T1", "T1", "HIGH"),
  corpus("msha", "Mine Safety and Health Administration mine records", "licensing", "msha.gov", "T1", "T1", "MODERATE"),
  corpus("chronicling-america", "Chronicling America / Open ONI", "periodicals", "chroniclingamerica.loc.gov", "T1", "T2", "HIGH"),
  corpus("internet-archive", "Internet Archive (Wayback CDX, full-text)", "archive channel", "archive.org", "T2", "T5", "CRITICAL", {
    value: "CRITICAL — a CHANNEL, not a tier. A faithfully scanned T5 newsletter in a T2 archive is a T5 document with high retrieval integrity, which is exactly what makes the AFU collection usable for ORIGIN grading",
  }),
  corpus("black-vault", "The Black Vault", "federal declassification", "theblackvault.com", "T3", "T1", "MODERATE", {
    tier_trap: true,
    value: "MODERATE — a T3 HOST DELIVERING T1 CONTENT. host_tier and content_tier are separate columns for exactly this reason",
  }),
  corpus("openstreetmap", "OpenStreetMap", "crowd geodata", "openstreetmap.org", "T5", "T5", "LOW", {
    adversary_writable: true,
    value: "LOW — ADVERSARY-WRITABLE and CROWD-EDITED. A lead only; replication into N renderers is ONE lineage",
  }),
  corpus("grokipedia", "Machine-written encyclopedia corpora", "post-2022 web", "grokipedia.com", "T4", "T4", "LOW", {
    machine_generated_blocklist: true,
    adversary_writable: true,
    value: "LOW — on the versioned machine-generated blocklist AND caught by the mechanical heuristic, because the blocklist will always lag",
  }),
];

/**
 * `registry.erp_profile` — the expected-record table, published at
 * `/method/expected-records`. "This is the table that licenses the argument from
 * silence for DUCC and forbids it for Greenbrier-1991. It is also the highest-
 * value artifact the W0 registries produced."
 *
 * The subset below is the profiles the calibration set turns on. X0 means NO
 * RECORD OF THIS CLASS WOULD BE EXPECTED, and an X0 profile produces NO ROWS —
 * not zeros.
 */
export const ERP_TABLE: ExpectedRecordRow[] = [
  {
    profile_key: "milcon.appropriated-dod",
    description:
      "MILCON / DD-1391 line for a construction project under an appropriated DoD programme",
    x_level: "X3",
    authority_note:
      "An excavation of this scale under an appropriated DoD programme produces a J-book line. Its absence is informative.",
    silence_override: null,
    destroying_event: null,
    era_from: 1950,
    era_to: null,
  },
  {
    profile_key: "milcon.non-appropriated-instrumentality",
    description:
      "MILCON / DD-1391 line for a facility built by a self-funded federal instrumentality",
    x_level: "X0",
    authority_note:
      "The Federal Reserve System is self-funded: no appropriations line, no J-book, no FRPP entry, and a transfer is not a GSA disposal. THE ABSENCE IS NOT EVIDENCE AGAINST. This is the profile that rescues Mount Pony (A-09) from a permanent X.",
    silence_override: null,
    destroying_event: null,
    era_from: 1913,
    era_to: null,
  },
  {
    profile_key: "cog.active-under-commercial-cover",
    description:
      "Documentary record classes for an active continuity facility operating under a commercial cover entity",
    x_level: "X0",
    authority_note:
      "CREST, DTIC, NARA, GovInfo, FRPP and GSA disposal all return X0 under this profile. THE SEARCHES ARE STILL EXECUTED AND THEIR NEGATIVE RECEIPTS LOGGED — a run that scores those absences against the facility has failed. This is the profile that FORBIDS the argument from silence for Greenbrier-1991.",
    silence_override: "UNINFORMATIVE",
    destroying_event: null,
    era_from: 1955,
    era_to: 1992,
  },
  {
    profile_key: "procurement.large-construction",
    description: "Procurement traces above $50M for a construction programme",
    x_level: "X3",
    authority_note:
      "A construction programme of the asserted scale leaves a procurement trace. Absence is informative — but §8.4 forbids R on expected-record negatives alone.",
    silence_override: null,
    destroying_event: null,
    era_from: 1960,
    era_to: null,
  },
  {
    profile_key: "spoil.volume-signature",
    description: "Spoil-volume signature above 1e5 m³ in the terrain and cartographic record",
    x_level: "X3",
    authority_note:
      "Large excavation displaces material that appears in the topographic record. Absence is informative.",
    silence_override: null,
    destroying_event: null,
    era_from: 1940,
    era_to: null,
  },
  {
    profile_key: "county.deed",
    description: "County recorder deed and parcel records",
    x_level: "X3",
    authority_note:
      "A real property transfer is recorded at the county. Available even where every federal class returns X0, which is why it carries the Greenbrier-1991 entry.",
    silence_override: null,
    destroying_event: null,
    era_from: 1850,
    era_to: null,
  },
  {
    profile_key: "htmc.quadrangle",
    description: "USGS historical topographic quadrangle coverage for the parcel",
    x_level: "X3",
    authority_note:
      "7.5-minute coverage exists for CONUS. A SYMBOL ON A SHEET IS A READING, AND A READING IS AN INTERPRETATION that inherits the tier of whoever asserted it — see F-05.",
    silence_override: null,
    destroying_event: null,
    era_from: 1947,
    era_to: 1992,
  },
  {
    profile_key: "origin.canonical-set",
    description:
      "The canonical ORIGIN search set: Wayback CDX, IA full-text hits_inside, periodical runs, newsletter collections, mirrored aggregators",
    x_level: "X2",
    authority_note:
      "An ORIGIN grade requires a NEGATIVE RECEIPT across this set, with query strings, corpora, versions and result counts recorded. Without it, the earliest artifact found is not established as the earliest artifact.",
    silence_override: null,
    destroying_event: null,
    era_from: 1880,
    era_to: null,
  },
  {
    profile_key: "records.destroyed-by-schedule",
    description: "A record class disposed of under an approved retention schedule",
    x_level: "X1",
    authority_note:
      "The record class that would have carried this evidence no longer exists. Distinct from UNSEARCHED and distinct from NEGATIVE.",
    silence_override: "RECORD-DESTROYED",
    destroying_event: "approved records disposition schedule",
    era_from: 1945,
    era_to: null,
  },
];
