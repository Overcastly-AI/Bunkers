/**
 * THE 34 CALIBRATION CASES + 6 PIPELINE TESTS.
 *
 * Transcribed from `docs/CALIBRATION.md`. Each row names the case, its expected
 * outcome under BES v0.2 verbatim from the summary table, its marker, the
 * entity and propositions it asserts against, and what it guards.
 *
 * "Scoring the suite. A case passes when the grade matches AND the named
 * `limiting_condition`, `applied_caps` and `null_state` match. MATCHING THE
 * LETTER ALONE IS NOT A PASS: two of the historically most dangerous failures
 * (SubTropolis reaching the right band by the wrong route, DIA reaching E
 * without CAP-2b) produce a correct letter from a broken mechanism."
 *
 * The `demonstrates` field is what a specimen sheet leads with, because it is
 * the reason the case exists — and because a reader arriving at a register with
 * zero candidates needs to see the instrument measuring a known standard.
 */

import type { SpecCase } from "./types";

export const CASES: SpecCase[] = [
  /* ---------------------------- BAND A ---------------------------- */
  {
    case_id: "A-01",
    title: "Cheyenne Mountain Complex, CO — EXIST",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "historian #1, IC #3 (identical)",
    entity_slug: "cheyenne-mountain-complex",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "That the model does not penalise a facility for being famous, and that an easy case requires nothing clever. v0.1 already got this right and any revision moving it below A is broken.",
    paired_with: ["R-01"],
  },
  {
    case_id: "A-02",
    title: "Raven Rock Mountain Complex (Site R), Adams County PA — all propositions",
    band: "A",
    marker: "REPRODUCED",
    expected: "A on EXIST, HARDEN, CONTROL, FUNCTION, STATUS, LOCATE, TYPOLOGY",
    sources: "IC #1",
    entity_slug: "raven-rock-site-r",
    proposition_refs: [
      "p-EXIST-1", "p-LOCATE-1", "p-EXTENT-1", "p-TYPOLOGY-1",
      "p-HARDEN-1", "p-CONTROL-1", "p-FUNCTION-1", "p-STATUS-1",
    ],
    demonstrates:
      "What a full ladder looks like: |V[D4]| = 2 · L(D3) = 5 · L(D2) = 5 · |V[claim]| = 6 · U = ∅ · SCI = 6/6.",
    notes: [
      "ADDITIONAL ASSERTION BEYOND THE LETTER: the PLACE-DERIVED bar must be ZERO for the FUNCTION claim. Portals, terrain and spoil contribute nothing; the CLAIM-DERIVED bar carries all of it. A pass that shows place-derived weight on FUNCTION is a failing pass.",
      "IC #1: 'If a revised rubric moves this below A, the revision is broken.'",
    ],
  },
  {
    case_id: "A-03",
    title: "33 Thomas Street, Manhattan — the urban / in-building test",
    band: "A",
    marker: "REPRODUCED",
    expected:
      "EXIST A · HARDEN A · FUNCTION(gateway switch) A · FUNCTION(TITANPOINTE SIGINT) A · IDENTITY B",
    sources: "historian #3",
    entity_slug: "33-thomas-street",
    proposition_refs: ["p-EXIST-1", "p-HARDEN-1", "p-FUNCTION-1", "p-FUNCTION-2", "p-IDENTITY-1"],
    demonstrates:
      "The case that proved v0.1's GEO axis encoded a buried-rural-mountain prior: adits, spoil and terrain are inapplicable to a Manhattan tower, so 33 Thomas could not clear B and would have needed a GEO score v0.1's own criteria cannot generate for a tower.",
    notes: [
      "THE DECOMPOSITION IS THE POINT. An A-grade fact about a codename, an A-grade fact about a building, and a B-grade link between them, on one page, without contradiction.",
      "Boundary demonstration: if the DOB filing does not itself state hardening intent, §3.4(d) fails on e1, A1 fails, and the entry falls to B on L(D3) = 3, with limiting_condition naming the document that decided it.",
    ],
    paired_with: ["B-06"],
  },
  {
    case_id: "A-04",
    title: "Mount Weather Emergency Operations Center, VA — EXIST",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "historian #13, IC #4",
    entity_slug: "mount-weather-eoc",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "Federally acknowledged and on the public record since at least the TWA Flight 514 crash of 1 December 1974 — the NTSB report is T1 and places a federal facility on the mountain.",
    paired_with: ["E-03"],
  },
  {
    case_id: "A-05",
    title: "The Greenbrier / Project Greek Island — post-1992",
    band: "A",
    marker: "REPRODUCED",
    expected: "A on EXIST, HARDEN, CONTROL, FUNCTION · transition_cause NEW-DISCLOSURE",
    sources: "historian #5, IC #5",
    entity_slug: "greenbrier-project-greek-island",
    proposition_refs: ["p-EXIST-1", "p-HARDEN-1", "p-CONTROL-1", "p-FUNCTION-1"],
    demonstrates:
      "That the system records the 1992 transition as caused by DISCLOSURE, not by the arrival of new evidence about the physical world, and renders NEW-DISCLOSURE with the annotation 'the publication record changed; the world did not.'",
    notes: [
      "S-5 · grade_as_of('1991-06-01') must still return the 1991 vector after the 1992 re-grade lands, and grade_history must name the Gup article as the observation that moved it.",
    ],
    paired_with: ["B-05", "C-02", "D-01", "E-02"],
  },
  {
    case_id: "A-06",
    title: "Iron Mountain / Boyers, PA — OPM Retirement Operations Center",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "historian #7, IC #7",
    entity_slug: "iron-mountain-boyers",
    proposition_refs: ["p-EXIST-1", "p-TYPOLOGY-1", "p-FUNCTION-1"],
    demonstrates:
      "That two limestone mines with federal-adjacent tenants separate on DOCUMENTATION, not on place-signals — where they are identical.",
    paired_with: ["R-02"],
  },
  {
    case_id: "A-07",
    title: "Titan II Missile Site 571-7, Green Valley AZ",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "IC #6",
    entity_slug: "titan-ii-571-7",
    proposition_refs: ["p-EXIST-1", "p-STATUS-1", "p-TYPOLOGY-1"],
    demonstrates:
      "That the large silo population does not clog the middle bands: EXIST/CONTROL/LOCATE are near-trivially D4 under the silo catalog, and the live propositions are STATUS and current CONTROL.",
  },
  {
    case_id: "A-08",
    title: "Camp Hero Air Force Station, Montauk NY — EXIST and FUNCTION(radar)",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "historian #9, IC #14",
    entity_slug: "camp-hero-afs",
    proposition_refs: ["p-EXIST-1", "p-FUNCTION-1"],
    demonstrates:
      "Two entities at the same coordinates, published without contradiction. v0.1 returned 84.42 → B from axis-weighting drag and had no way to hold the two propositions apart.",
    paired_with: ["F-01", "A-13"],
  },
  {
    case_id: "A-09",
    title: "Mount Pony, Culpeper VA — the non-appropriated blind-spot control",
    band: "A",
    marker: "REPRODUCED",
    expected:
      "A on EXIST, HARDEN, CONTROL, FUNCTION(COG), STATUS(converted) · four ERP profiles at X0 · coverage note published",
    sources: "skeptic",
    entity_slug: "mount-pony-culpeper",
    proposition_refs: ["p-EXIST-1", "p-HARDEN-1", "p-CONTROL-1", "p-FUNCTION-1", "p-STATUS-1"],
    demonstrates:
      "SCI = 1.000 on an EMPTY DENOMINATOR. Under v0.1 this lost roughly 40 points across DOC and OWN because the Federal Reserve is self-funded: no appropriations line, no MILCON J-book, no FRPP entry, no FPDS record.",
    notes: [
      "The four profiles return X0 and therefore produce NO ROWS — not zeros. Those searches were still executed and their negative receipts logged.",
      "A BLIND SPOT IN A GRADING SYSTEM IS A SAFE HARBOUR FOR FABRICATION.",
    ],
  },
  {
    case_id: "A-10",
    title:
      "Louisville Mega Cavern — FUNCTION(designated civil-defense fallout shelter, 1960s–70s)",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "skeptic (paired test, half one)",
    entity_slug: "louisville-mega-cavern",
    proposition_refs: ["p-FUNCTION-1"],
    demonstrates:
      "A real, primary, on-topic credential granted in full and without grudging. The mundane truth here scores legitimately high — WHICH IS WHAT MAKES R-03 DANGEROUS.",
    paired_with: ["R-03"],
  },
  {
    case_id: "A-11",
    title: "DUCC — PROGRAM and STATUS(never-built)",
    band: "A",
    marker: "REPRODUCED",
    expected: "PROGRAM A · STATUS(never-built) A · LOCATE non-located",
    sources: "historian #12, IC #11",
    entity_slug: "ducc",
    proposition_refs: ["p-PROGRAM-1", "p-STATUS-1", "p-LOCATE-1"],
    demonstrates:
      "The clamp exemption. PROGRAM is clamp_exempt BY TRIGGER, never by agent choice — without it the monotone clamp drags PROGRAM down to EXIST's R and the entry is unrepresentable. This is the single schema decision that makes DUCC expressible.",
    notes: ["STATUS = never-built is a valid enum value. v0.1's nearest option was 'alleged-only', the epistemic opposite."],
    paired_with: ["R-04"],
  },
  {
    case_id: "A-12",
    title: "Dulce Base — ORIGIN(the claim first appears with Bennewitz, Albuquerque, 1979–80)",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "derived from historian #11's 'with the origin documented'",
    entity_slug: "dulce-base",
    proposition_refs: ["p-ORIGIN-1"],
    demonstrates:
      "THE PART v0.1 COULD NOT DO AT ALL. D4 for the ORIGIN class, because the dated earliest artifact retrieved with a receipt IS the evidence for an origin claim — plus the negative receipt the ORIGIN definition requires. This is the register publishing an A-grade fact about a fabrication.",
    paired_with: ["R-05"],
  },
  {
    case_id: "A-13",
    title: "The Montauk Project — ORIGIN(Nichols & Moon, 1992)",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "derived from historian #10 / IC #14",
    entity_slug: "montauk-project",
    proposition_refs: ["p-ORIGIN-1"],
    demonstrates:
      "The ORIG A / FUNC F pair, published beside Camp Hero EXIST A at the same coordinates.",
    paired_with: ["F-01", "A-08"],
  },
  {
    case_id: "A-14",
    title: "SubTropolis — EXIST, TYPOLOGY(commercial-underground), CONTROL(Hunt Midwest)",
    band: "A",
    marker: "REPRODUCED",
    expected: "A on all three",
    sources: "derived from IC #10",
    entity_slug: "subtropolis",
    proposition_refs: ["p-EXIST-1", "p-TYPOLOGY-1", "p-CONTROL-1"],
    demonstrates:
      "A true, useful, boring entry — and it must be, because R-02 is on the same page. An entry that refutes a facility's COG claim while grading its real existence A is the product.",
    paired_with: ["R-02"],
  },
  {
    case_id: "A-15",
    title: "SF-88L, Marin County CA — restored Nike site",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "IC #17 (contrast case)",
    entity_slug: "sf-88l-marin",
    proposition_refs: ["p-EXIST-1", "p-STATUS-1"],
    demonstrates:
      "That A-15 and B-04 are separated by roughly ONE band, not four. Under v0.1 they separate by four, because the unrestored site has no photography, no tours and no named accounts to feed the axes.",
    paired_with: ["B-04"],
  },
  {
    case_id: "A-16",
    title: "Manzano Base, Kirtland AFB NM — EXIST and FUNCTION",
    band: "A",
    marker: "REPRODUCED",
    expected: "A · STATUS decommissioned",
    sources: "skeptic (entity-resolution trap)",
    entity_slug: "manzano-base",
    proposition_refs: ["p-EXIST-1", "p-FUNCTION-1", "p-STATUS-1"],
    demonstrates: "One half of the entity-resolution trap. See P-06 for the assertion that matters.",
    paired_with: ["B-02", "P-06"],
  },
  {
    case_id: "A-17",
    title: "Groom Lake / Area 51 — EXIST",
    band: "A",
    marker: "REPRODUCED",
    expected: "A",
    sources: "skeptic",
    entity_slug: "groom-lake",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "The parent site of F-04. Its function in the suite is to be the credibility donor that F-04 must not inherit from.",
    paired_with: ["F-04"],
  },
  {
    case_id: "A-18",
    title:
      "Fairview, Kansas — EXIST, CONTROL(AT&T historic), FUNCTION(hardened long-haul relay), LOCATE",
    band: "A",
    marker: "REPRODUCED",
    expected: "A on all four",
    sources: "derived from IC #9",
    entity_slug: "fairview-kansas",
    proposition_refs: ["p-EXIST-1", "p-CONTROL-1", "p-FUNCTION-1", "p-LOCATE-1"],
    demonstrates:
      "THE §3.4(e) DISCRIMINATION: the same FCC record is D4 for FUNCTION(relay) and at most D2 for HARDEN, because the FCC has authority over the LICENCE and not over the HARDENING. If a scorer awards D4 to HARDEN from the FCC record, the suite fails even though the letter for FUNCTION is right.",
    notes: [
      "EXIST via A1-alt: two independent verified direct observations by resolvable named persons with lawful physical access, each with georeferenced imagery matched to a public control point, plus a T1 record placing a structure on the parcel. You can stand in it, two resolvable people have, and the deed recites it.",
      "FACT-KEY MERGE ASSERTION: e1 (deed), e2 (ASR) and e3 (Long Lines records) all assert fact_key 'AT&T owned and operated this site' and merge to the strongest for L-counting. One fact must not enter as three lineages.",
    ],
    paired_with: ["B-01"],
  },

  /* ---------------------------- BAND B ---------------------------- */
  {
    case_id: "B-01",
    title: "Fairview, Kansas — HARDEN(blast)",
    band: "B",
    marker: "REPRODUCED",
    expected: "B · ceiling A · at_ceiling FALSE",
    sources: "IC #9",
    entity_slug: "fairview-kansas",
    proposition_refs: ["p-HARDEN-1"],
    demonstrates:
      "THE CRITICAL NEGATIVE-CONTROL PAIR, with R-02. v0.1 scored the commercial warehouse (60.23 = C) ABOVE the real bunker (56.25 = C): two cases, opposite ground truths, indistinguishable output.",
    notes: [
      "The limiting condition is the register's real product: it tells a researcher exactly what to go find. The suite asserts the limiting condition TEXT, not just the letter.",
      "The compiler-transparency branch must also be computed and published: if the underlying Bell System Practice resolves, the PRIMARY is the lineage and the compiler scores nothing; if not, long-lines.net is one T4 terminus at catalog D2 → e3 falls to D2 → L(D3) = 1 → CAP-1 → C. THE MODEL MUST PUBLISH WHICH READING IT TOOK AND WHY.",
    ],
    paired_with: ["R-02"],
  },
  {
    case_id: "B-02",
    title: "KUMMSC, Kirtland AFB NM",
    band: "B",
    marker: "PAIR-NOT-LETTER",
    expected: "EXIST A · HARDEN A · EXTENT D (reviewer expected composite B)",
    sources: "IC #8",
    entity_slug: "kummsc",
    proposition_refs: ["p-EXIST-1", "p-HARDEN-1", "p-EXTENT-1"],
    demonstrates:
      "BES has no composite, so there is nothing that can be 'B'. The reviewer's stated requirement — 'existence solid, extent partly inferred' — is EXACTLY A PAIR, and the decomposition satisfies it. But it is not a letter-for-letter match and the suite must not report it as one.",
    notes: [
      "A run that produces a single letter for this entity has failed regardless of which letter.",
    ],
    paired_with: ["A-16", "P-06"],
  },
  {
    case_id: "B-03",
    title: "Presidential Emergency Facility \"Cartwheel\", Fort Reno Park, Washington DC",
    band: "B",
    marker: "MARGINAL",
    expected: "EXIST A · EXTENT D — OR — EXIST C via C1c (reviewer expected B)",
    sources: "historian #6",
    entity_slug: "pef-cartwheel-fort-reno",
    proposition_refs: ["p-EXIST-1", "p-EXTENT-1"],
    demonstrates:
      "Transparent-compiler pass-through (§5.1.3) dragging an entry out of D. v0.1 returned 53.11 → D, 'weak inference', because the GEO axis finds nothing to reward in a city park and CONTAM penalised the fact that one careful compiler did the collation.",
    notes: [
      "EITHER OUTCOME PASSES, but marginal_flag MUST be TRUE and the branch taken must be named in limiting_condition. A run that returns A or C without the marginal flag has failed.",
    ],
  },
  {
    case_id: "B-04",
    title: "An unrestored Nike Hercules launch magazine on private agricultural land",
    band: "B",
    marker: "PAIR-NOT-LETTER",
    expected: "EXIST A · TYPOLOGY A · STATUS unknown/X (reviewer expected composite B)",
    sources: "IC #17",
    entity_slug: "nike-hercules-magazine-unrestored",
    proposition_refs: ["p-EXIST-1", "p-TYPOLOGY-1", "p-STATUS-1"],
    demonstrates:
      "That the model does not punish a facility for being ORDINARY AND WELL-ATTESTED AT THE CLASS LEVEL rather than dramatically documented at the instance level.",
    paired_with: ["A-15", "X-02"],
  },
  {
    case_id: "B-05",
    title: "The Greenbrier / Project Greek Island, 1 Jan 1991 — EXIST",
    band: "B",
    marker: "REVIEWER-CONFLICT",
    expected: "B · at_ceiling TRUE · silence UNINFORMATIVE · base rate VERY-RARE",
    sources: "historian: C on evidence · IC: B",
    entity_slug: "greenbrier-project-greek-island",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "THE FLAGSHIP CASE. In 1991, a fully staffed 1,100-bed congressional relocation facility with essentially no documentary trace, behind a cover contractor. v0.1 returned 22.91 → E, 'folklore with a trace' — printed over an operating COG facility.",
    notes: [
      "THE DELIBERATE HINGE: A1's second clause reads 'two rows at D3 in two independent lineages, both CLAIM-PROPERTY', which e4 and e5 satisfy on their face. But they describe the SAME OBJECT, and §5.5 fact-key merging collapses them. A1 fails; marginal_flag = TRUE.",
      "NEGATIVE RECEIPTS ASSERTION: searches against CREST, DTIC, NARA, GovInfo, FRPP and GSA disposal were EXECUTED AND LOGGED, and every profile returns X0 → NO ROWS. A run that scores those absences against the facility has failed, and that is precisely what v0.1 did.",
      "THE CONFLICT, RECORDED: the historian expected C on evidence with P(exists) HIGH published beside it; the IC analyst expected B. BES takes the IC reading. BES ALSO DECLINES the historian's requested form — a published probability — and substitutes at_ceiling + silence_reading + base_rate_reading.",
      "Boundary demonstrations: if only ONE worker resolves → still B. If the utility filing also fails → CAP-1 → C, limiting_condition 'B1 — fewer than three independent D2 lineages.'",
    ],
    paired_with: ["A-05", "C-02", "D-01", "E-02"],
  },
  {
    case_id: "B-06",
    title: "33 Thomas Street — IDENTITY(TITANPOINTE ≡ 33 Thomas Street)",
    band: "B",
    marker: "REPRODUCED",
    expected: "B",
    sources: "derived from historian #3",
    entity_slug: "33-thomas-street",
    proposition_refs: ["p-IDENTITY-1"],
    demonstrates:
      "Because IDENTITY is at B (≥ C), §11.1 permits the alias to be used for subject binding on the SIGINT proposition. THE MERGE IS EVIDENCED RATHER THAN ASSUMED. If IDENTITY were below C, the alias must not be usable for binding — and the suite should test that direction too.",
    paired_with: ["A-03"],
  },

  /* ---------------------------- BAND C ---------------------------- */
  {
    case_id: "C-01",
    title: "An unnamed \"Federal Relocation Arc\" site from declassified 1960s OEP records",
    band: "C",
    marker: "REPRODUCED",
    expected: "C via C1c · ceiling C · LOCATE non-located",
    sources: "IC #16",
    entity_slug: "federal-relocation-arc-site-07",
    proposition_refs: ["p-EXIST-1", "p-LOCATE-1", "p-PROGRAM-1"],
    demonstrates:
      "THE REAL-BUT-UNLOCATED TEST. Declassified T1 records establish that a set of relocation facilities existed and describe their programme function, WITHOUT individually identifying or locating each one. For an individual candidate the OEP record is scope = CLASS and is excluded from V for the instance.",
    notes: [
      "THE DILUTION ASSERTION, which is the anti-gaming half: adding a thirteenth candidate recomputes M for ALL TWELVE as a versioned CANDIDATE-SET-CHANGE; if M exceeds 3N the whole set drops to D. ADDING CANDIDATES DILUTES.",
      "LOCATE assertion: non_located, or a regional polygon. NEVER A PIN. A precise pin manufactured from imprecise evidence is the register performing its own citogenesis at the interface layer.",
    ],
  },
  {
    case_id: "C-02",
    title: "The Greenbrier, 1991 — HARDEN(blast)",
    band: "C",
    marker: "REPRODUCED",
    expected: "C · CAP-1 applied · at_ceiling TRUE",
    sources: "historian #5, IC #5",
    entity_slug: "greenbrier-project-greek-island",
    proposition_refs: ["p-HARDEN-1"],
    demonstrates:
      "Only e4/e5 describe the steel door; the fact-key merge takes L(D3) to 1, B1 fails, and C1a holds — a resolvable witness's description of a blast door is CLAIM-PROPERTY at D3.",
    paired_with: ["B-05"],
  },

  /* ---------------------------- BAND D ---------------------------- */
  {
    case_id: "D-01",
    title: "The Greenbrier, 1991 — CONTROL(federal)",
    band: "D",
    marker: "REPRODUCED",
    expected: "D (capped from E by clamp) · CAP-2b in applied_caps · at_ceiling TRUE",
    sources: "historian #5, IC #5",
    entity_slug: "greenbrier-project-greek-island",
    proposition_refs: ["p-CONTROL-1"],
    demonstrates:
      "CAP-2b MUST APPEAR IN applied_caps EVEN THOUGH IT DID NOT BIND. A run that reaches D without recording the cap is recording a different mechanism than the one that ran.",
    paired_with: ["B-05"],
  },

  /* ---------------------------- BAND E ---------------------------- */
  {
    case_id: "E-01",
    title:
      "Denver International Airport — FUNCTION(hardened non-airport federal facility beneath the terminal)",
    band: "E",
    marker: "REVIEWER-CONFLICT",
    expected: "E",
    sources: "historian: F · IC: E",
    entity_slug: "denver-international-airport",
    proposition_refs: ["p-EXIST-1", "p-FUNCTION-1"],
    demonstrates:
      "THE DEEPEST ASSERTION IN THE SUITE. Six of seven agents independently returned REAL T1 SIGNALS, and not one discriminated {hardened federal facility} from {very large airport, built badly}. The suite asserts that the six returns produce SIX D0 ROWS satisfying zero conditions above D, and that CAP-2b — NOT LUCK — holds the ceiling at E.",
    notes: [
      "IC #12 called this 'the single most important thing to test before ratification': 'A published C-grade DIA bunker entry would on its own destroy the register's credibility.' v0.1 returns 55.59 = GRADE C at the more defensible CONTAM 30.",
      "REFUTATION MUST NOT FIRE. R2 requires ≥2 verified UNDERCUTS rows improbable under the proposition, and there are none. A COMPLETE MUNDANE EXPLANATION REMOVES PROBATIVE VALUE; IT DOES NOT DISCONFIRM. → R0.",
      "THE CONFLICT, RECORDED: the historian expected F. BES follows the IC — V is not empty, so F would misdescribe the evidentiary state.",
    ],
    paired_with: ["F-01"],
  },
  {
    case_id: "E-02",
    title: "The Greenbrier, 1991 — FUNCTION(congressional relocation)",
    band: "E",
    marker: "REVIEWER-CONFLICT",
    expected: "E · CAP-2b binding · at_ceiling TRUE · base rate VERY-RARE",
    sources: "IC: F",
    entity_slug: "greenbrier-project-greek-island",
    proposition_refs: ["p-FUNCTION-1"],
    demonstrates:
      "THE CASE CAP-2b WAS WRITTEN FOR, and the single hardest constraint in the anti-gaming ledger: no FUNCTION claim exceeds E without a verified, instance-scope, subject-bound, CLAIM-PROPERTY observation. The stave renders it without a word — THE UPPER STOREY IS EMPTY.",
    notes: [
      "The IC's F is declined because V is not empty. E — 'verified support exists but fails to discriminate' — is the accurate description.",
    ],
    paired_with: ["B-05", "E-01"],
  },
  {
    case_id: "E-03",
    title: "Mount Weather — the \"underground city\" FEATURE claim",
    band: "E",
    marker: "KNOWN-DIVERGENCE",
    expected: "E + citogenesis flag, inside an A-grade site (reviewer expected D)",
    sources: "historian #14",
    entity_slug: "mount-weather-eoc",
    proposition_refs: ["p-FEATURE-1"],
    demonstrates:
      "A T3 publication built on T5 testimony — the exact laundering pattern citogenesis detection exists to name. STRUCTURAL ASSERTION, INDEPENDENT OF THE LETTER: the citogenesis flag attaches to the PROPOSITION, not the site. Under v0.1 this content rode inside an A-grade entry with the flag having nowhere to attach.",
    notes: [
      "KNOWN DIVERGENCE — one band, conservative. THE SUITE ASSERTS E. If a future change makes this return D, that change must be justified against this note, not treated as a bug fix.",
      "The journalist is reporting others' attestation, NOT the claimant — so §2.5 does not exclude him. His report enters V at D0.",
    ],
    paired_with: ["A-04"],
  },

  /* ---------------------------- BAND F ---------------------------- */
  {
    case_id: "F-01",
    title: "The Montauk Project — FUNCTION(underground levels, time and mind-control experiments)",
    band: "F",
    marker: "REPRODUCED",
    expected: "F · ORIGIN A",
    sources: "historian #10, IC #14",
    entity_slug: "montauk-project",
    proposition_refs: ["p-FUNCTION-1", "p-ORIGIN-1"],
    demonstrates:
      "THE E/F LINE, STATED. DIA's V contains verified third-party records of real facts that fail to discriminate → E. Montauk's V is EMPTY because the only artifact IS the claim → F. That line falls out of one written rule and it is checkable.",
    notes: [
      "The base's real documentation is bound to EXIST(camp-hero) and CONTROL(USAF), NOT to this proposition — proposition binding plus subject binding make the citogenesis mechanism unavailable to the register itself.",
      "REFUTATION MUST NOT FIRE: the NY State Parks and EPA surveys returning no such levels are EXPECTED-RECORD NEGATIVES, and §8.4 forbids R on those alone. → R0.",
      "v0.1 returned 43.29 → D, 'suggestive but thin', because the claim inherited the real base's DOC/GEO/INF/OWN.",
    ],
    paired_with: ["A-08", "A-13", "E-01"],
  },
  {
    case_id: "F-02",
    title: "Telos, the Lemurian city beneath Mount Shasta CA",
    band: "F",
    marker: "REPRODUCED",
    expected: "F · ORIGIN A",
    sources: "IC #15",
    entity_slug: "telos-mount-shasta",
    proposition_refs: ["p-EXIST-1", "p-ORIGIN-1"],
    demonstrates:
      "THE CLEANEST CASE OF THE BACKWARD-SOURCING METHOD: a claim whose origin document is openly a work of fiction.",
    notes: [
      "SECOND ASSERTION: the claim is attached to real, dramatic, geologically anomalous terrain — a stratovolcano with genuine lava tubes and caves. IT MUST NOT INHERIT A PLACE-DERIVED FLOOR. Under v0.1 it would.",
    ],
  },
  {
    case_id: "F-03",
    title: "The Sauder / Schneider \"129 Deep Underground Military Bases\" corpus",
    band: "F",
    marker: "REPRODUCED",
    expected: "F · ORIGIN A/B",
    sources: "IC #2",
    entity_slug: "sauder-129-dumb-corpus",
    proposition_refs: ["p-PROGRAM-1", "p-ORIGIN-1"],
    demonstrates:
      "THE §8.4 ASSERTION. The expected-record negatives here are deep and real — X3 profiles on MILCON, on procurement traces >$50M, on spoil-volume signatures. A model that licenses R from negatives alone returns R, which is WRONG, and is the characteristic failure mode of any evidence model with signed negatives. The suite must assert refutation_state = R0 and grade = F (SILENCE-DOMINATED).",
    notes: [
      "THE SAUDER-AS-BIBLIOGRAPHY MOVE: identifiers regexed out of the books are LEADS and become citations only after independent resolution at DTIC / NTRL / Federal Register. His documents get promoted; his conclusions stay T4.",
      "IC #2: 'If a revised rubric moves this above F, the revision is broken.'",
    ],
  },
  {
    case_id: "F-04",
    title: "Bob Lazar / \"S-4, Papoose Lake\", Nevada",
    band: "F",
    marker: "REPRODUCED",
    expected: "F on the S-4 underground-facility claim; A on Groom Lake (A-17)",
    sources: "skeptic",
    entity_slug: "s4-papoose-lake",
    proposition_refs: ["p-EXIST-1", "p-ORIGIN-1"],
    demonstrates:
      "THE HARDEST TESTIMONY CASE IN THE SUITE, and the one that forced a rewrite of §5.4 into a POSITION-TO-KNOW gate rather than an identity gate: the individual must be independently locatable in a record that PREDATES THE CLAIM, was CREATED FOR AN UNRELATED PURPOSE, and PLACES THEM IN THE ROLE ASSERTED.",
    notes: [
      "Continuous restricted airspace over Groom Lake is a genuine D2/D3 signal — but for propositions about GROOM LAKE, not about a claimed separate facility at Papoose Lake, where it is scope = ADJACENT and excluded from V entirely.",
    ],
    paired_with: ["A-17"],
  },
  {
    case_id: "F-05",
    title: "Site CARDINAL, Pendleton County WV — the confabulation canary",
    band: "F",
    marker: "REPRODUCED",
    expected: "F, deterministically, with five identifiers logged as measured confabulation",
    sources: "skeptic, BES Part 14",
    entity_slug: "site-cardinal",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "THE CASE THAT DECIDED THE MODEL ADJUDICATION. Under v0.1 this dossier scored 76.10 → GRADE B, 'strongly evidenced, existence solid.' NOTHING IN IT EXISTS.",
    notes: [
      "Assertions beyond the letter, all of which are the actual product: all five identifiers are RETAINED (v0_count = 5), not deleted — they are confabulation telemetry; the entity is NEVER PUBLISHABLE (three independent blocks); the identifiers are attributed per agent and published in the confabulation rate; not rendered as a map pin.",
      "THE INCENTIVE INVERSION THIS REPAIRS: under v0.1, citing a forum post required possessing a URL that exists, while citing a CREST document required only emitting a well-formed string.",
    ],
    paired_with: ["P-01", "P-02"],
  },
  {
    case_id: "F-06",
    title: "Comet Ping Pong tunnel/basement claim, Washington DC (2016)",
    band: "F",
    marker: "KNOWN-DIVERGENCE",
    expected: "F — or R if the DOB record resolves",
    sources: "skeptic",
    entity_slug: "comet-ping-pong-tunnel-claim",
    proposition_refs: ["p-EXIST-1", "p-ORIGIN-1"],
    demonstrates:
      "The skeptic includes it BECAUSE v0.1 passes, and labels why it passes: 'not because any gate detected the fabrication, but because a retail storefront on Connecticut Avenue has no adit, no spoil, no substation and no terrain to donate. It is the control that isolates the variable.'",
    notes: [
      "THE SUITE ASSERTS EITHER, AND ASSERTS THAT limiting_condition OR refutation_state NAMES WHICH. It fails if the entry returns F with the origin-lack as the only recorded reason WHILE a resolvable building record exists — because that is the register declining to do the work it exists to do.",
      "This fixture takes the R branch and names it.",
    ],
    paired_with: ["R-05"],
  },

  /* ---------------------------- BAND R ---------------------------- */
  {
    case_id: "R-01",
    title: "Cheyenne Mountain — STATUS(\"it is the current NORAD headquarters\")",
    band: "R",
    marker: "REPRODUCED",
    expected: "R (R3)",
    sources: "historian #2",
    entity_slug: "cheyenne-mountain-complex",
    proposition_refs: ["p-STATUS-1"],
    demonstrates:
      "THE STRUCTURAL ASSERTION. This site is simultaneously A (A-01, EXIST) and R (this case). ANY RUBRIC RETURNING ONE NUMBER FOR CHEYENNE MOUNTAIN FAILS THIS ENTRY BY CONSTRUCTION. Both render on the same page without contradiction, and the R does not clamp the EXIST.",
    notes: ["The claim is STALE rather than invented, and is contradicted by primary DoD sources."],
    paired_with: ["A-01"],
  },
  {
    case_id: "R-02",
    title: "SubTropolis, Kansas City MO — HARDEN(blast/EMP) and FUNCTION(COG)",
    band: "R",
    marker: "REVIEWER-CONFLICT",
    expected: "R (R2)",
    sources: "historian: R · IC: F · decision: R, following the historian",
    entity_slug: "subtropolis",
    proposition_refs: ["p-HARDEN-1", "p-FUNCTION-1"],
    demonstrates:
      "THE CRITICAL NEGATIVE CONTROL, paired with B-01. It scores near-maximum on every place-signal — portals, ventilation shafts, spoil history, road grade, a dedicated substation, a rail spur, deep wells, fuel permits — plus clean documented title. AND IT IS NOT A BUNKER IN ANY SENSE. v0.1 gives it 60.23 = C, outranking the real AT&T bunker at 56.25.",
    notes: [
      "TWO INDEPENDENT ROUTES, AND THE SUITE MUST CHECK BOTH. R2 fires on U1 and U2 with null_state DOMINANT. Had refutation not fired, CAP-2b caps at E anyway — a run that reaches R via CAP-2b rather than R2 has the right letter from the wrong mechanism.",
      "THE CONFLICT, RECORDED: R is taken. The mundane explanation here is not merely complete but AFFIRMATIVELY DOCUMENTED AND PUBLICLY ADVERTISED, and the published lease chain and ticketed tours are affirmatively improbable under a hardened-COG claim.",
      "THE ENTRY IS NOT DELETED. A reader who arrives believing SubTropolis is a bunker leaves with the refutation and its sources — published beside A-14.",
    ],
    paired_with: ["A-14", "B-01", "A-06"],
  },
  {
    case_id: "R-03",
    title: "Louisville Mega Cavern — FUNCTION(COG/COOP)",
    band: "R",
    marker: "REPRODUCED",
    expected: "R (R2)",
    sources: "skeptic (paired test, half two)",
    entity_slug: "louisville-mega-cavern",
    proposition_refs: ["p-FUNCTION-2"],
    demonstrates:
      "THE SHARPEST FALSE-POSITIVE CASE IN THE SUITE, and strictly harder than SubTropolis: 'SubTropolis can be argued down on DOC because its federal documentation is thin; Mega Cavern's DOC is genuine, primary, on-topic and about civil defence, so a diagnosticity fix alone does not dispose of it.' THE GENUINE, PRIMARY, ON-TOPIC DOCUMENT CONTRIBUTES EXACTLY NOTHING TO THE COG CLAIM, because the named alternative explains it completely.",
    notes: [
      "THE TYPOLOGY GATE, WHICH IS WHAT THIS CASE ACTUALLY TESTS: 'Any rubric in which the typology field is not itself an evidenced, graded proposition fails this entry by construction.' THE ATTACK IS DEAD: there is no typology label and no composite.",
      "The .gov laundering channels each contribute exactly 0: regulations.gov (SOLICITED-BY-CLAIMANT), a FOIA no-records letter (uninformative either way under ERP), a Zenodo DOI (SELF-PUBLISHED → T4), an OSM tag (CROWD-EDITED → one lineage regardless of renderer count).",
    ],
    paired_with: ["A-10", "R-02"],
  },
  {
    case_id: "R-04",
    title: "DUCC — EXIST(a physical DUCC structure beneath Washington)",
    band: "R",
    marker: "REVIEWER-CONFLICT",
    expected: "R (R3)",
    sources: "historian: R · IC: F · decision: R",
    entity_slug: "ducc",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "THE ONE CASE IN THE ENTIRE SUITE WHERE THE ARGUMENT FROM SILENCE IS VALID, and the ERP table is precisely what licenses it — the same table that FORBIDS the inference for B-05. DUCC publishes INFORMATIVE and Greenbrier-1991 publishes UNINFORMATIVE, from the same table.",
    notes: [
      "THE AFFIRMATIVE HALF, WITHOUT WHICH R MUST NOT FIRE. §8.4 forbids R on expected-record negatives alone. R3 supplies the content: the appropriations record documents non-funding and the programme record documents cancellation.",
      "Remove the appropriations record from the fixture and the expected result becomes F (SILENCE-DOMINATED), not R.",
      "v0.1 returned 37.24 → E, six points above Dulce Base. A PROVEN NON-FACILITY WITH SUPERB DOCUMENTATION MUST NOT SHARE A BIN WITH AN INVENTION.",
    ],
    paired_with: ["A-11", "B-05"],
  },
  {
    case_id: "R-05",
    title: "Dulce Base, Archuleta Mesa NM — EXIST, HARDEN, FUNCTION, LOCATE",
    band: "R",
    marker: "KNOWN-DIVERGENCE",
    expected: "R (R1) · ORIGIN A (both reviewers expected F)",
    sources: "historian #11, IC, skeptic",
    entity_slug: "dulce-base",
    proposition_refs: ["p-EXIST-1", "p-HARDEN-1", "p-FUNCTION-1", "p-LOCATE-1", "p-ORIGIN-1"],
    demonstrates:
      "ORIG A ESTABLISHED below the unclamped rule, EXST R REFUTED above it. An A-grade fact about a fabrication and a refuted facility on one page, without either lying about the other. UNDER v0.1, THE AFOSI DISINFORMATION DOCUMENTATION ADDED TO THE DOC AXIS — a documented disinformation operation counted as documentation FOR the claim. That single fact is the clearest statement of what signed evidence fixes.",
    notes: [
      "THE DIVERGENCE, DECLARED. Both lenses expected F. BES returns R deliberately: the historian's own text demands that the AFOSI/Doty documentation 'must be representable as evidence AGAINST' — that IS R by definition, and their F was constrained by v0.1's vocabulary, in which R was unreachable.",
      "Under v0.1 grade F was UNREACHABLE: the CONTAM multiplier floors at ×0.5, so even a flawless lineage analysis returned 20.65 → E; and following v0.1's own calibration text, the three named claimants yield CONTAM ≈ 55 and the entry RISES to 23.49.",
      "Project Gasbuggy — a genuine 1967 AEC underground detonation ~20 miles away with a full paper trail — is VERIFIED, T1, and scope = ADJACENT. EXCLUDED, DISPLAYED AS EXCLUDED WITH THE REASON. PROXIMITY IS NOT SUPPORT.",
      "THE CONTRAST PUBLISHED ALONGSIDE: EXIST(some constructed works on Archuleta Mesa) grades honestly at C. 'There are real works on this mesa' and 'the base claim is refuted' sit side by side.",
    ],
    paired_with: ["A-12", "F-06"],
  },

  /* ---------------------------- BAND X ---------------------------- */
  {
    case_id: "X-01",
    title: "Any newly ingested candidate, before the canonical search set has run",
    band: "X",
    marker: "REPRODUCED",
    expected: "X",
    sources: "derived from BES §7.2, §12.6, §15",
    entity_slug: "candidate-2026-0141",
    proposition_refs: ["p-EXIST-1", "p-LOCATE-1"],
    demonstrates:
      "X IS THE CORRECT DEFAULT for every newly ingested candidate, and it must render VISUALLY DISTINCT FROM F. X is not a low grade; it is the absence of one.",
    notes: [
      "A candidate with SCI < 0.5 whose provisional grade would be D/E/F/R publishes 'X — INSUFFICIENT SEARCH (SCI 0.33)' with the fraction shown.",
      "Grades A, B and C publish at ANY SCI: positive evidence does not require exhaustion, but a negative verdict does.",
      "R SHORT-CIRCUITS THE FLOOR (ratification item R-1). An affirmatively established refutation is not withheld for incomplete search. This is a declared, contested behaviour and the suite pins it so a change is visible.",
      "SCI with an empty denominator is 1.000, not 0. See A-09.",
      "Band-occupancy discipline (§12.6): the modal register entry should be X or D. If C-band occupancy exceeds ~15% of graded propositions, the diagnosticity catalog is leaking and is re-audited.",
    ],
  },
  {
    case_id: "X-02",
    title: "Unrestored Nike Hercules magazine — STATUS",
    band: "X",
    marker: "REPRODUCED",
    expected: "X (unknown / unsearched)",
    sources: "IC #17",
    entity_slug: "nike-hercules-magazine-unrestored",
    proposition_refs: ["p-STATUS-1"],
    demonstrates:
      "THE CASE THAT DISTINGUISHES 'we looked and found nothing' (F) from 'we have not looked, and the record class may not exist' (X). Current condition and status are GENUINELY UNKNOWN, not unsupported.",
    paired_with: ["B-04"],
  },

  /* -------------------------- PIPELINE ---------------------------- */
  {
    case_id: "P-01",
    title: "A format-valid but nonexistent CREST identifier",
    band: "PIPELINE",
    marker: "PIPELINE",
    expected:
      "rejected at write time as a citation; stored as a lead; V0 if it reaches an observation; logged as a fleet confabulation event",
    sources: "skeptic",
    entity_slug: "site-cardinal",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "CREST identifiers are a regular grammar an LLM reproduces perfectly and populates emptily. Under v0.1 such a string is P1 BY ASSERTION, lands on DOC at weight .28, and passes the firewall because the firewall gates on tier and THE TIER CAME FROM THE AGENT THAT INVENTED THE DOCUMENT.",
    notes: [
      "THE TEST HAS THREE PARTS AND ALL THREE MUST PASS: grammar validation passes and proves nothing; resolution against the authoritative interface with a stored SHA-256 receipt fails; and METADATA MATCH — 'the one that catches the genuinely dangerous case that parts 1 and 2 miss: a REAL document about facility X misattributed to facility Y, which survives every existence check ever devised.'",
      "receipt_state = UNRESOLVED-NOTFOUND, not UNRESOLVED-UNREACHABLE. The distinction is the whole point: a blocked proxy must not inflate the published fabrication metric.",
      "membership = V0 BY GENERATED COLUMN, not by any agent's assertion. An attempted UPDATE to membership must raise.",
      "A real, resolvable CREST document about a different facility must land as MISATTRIBUTED and be routed to review, with scope demoted INSTANCE → CLASS, removing it from V without deleting it.",
    ],
    paired_with: ["F-05"],
  },
  {
    case_id: "P-02",
    title: "The rotating canary candidate",
    band: "PIPELINE",
    marker: "PIPELINE",
    expected: "F with zero sources; any citation returned is a measured hallucination",
    sources: "skeptic",
    entity_slug: "site-cardinal",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "'Neither prior lens proposes any mechanism for measuring the fleet's error rate; both assume a competent scorer and debate what a competent scorer should compute. But the register's stated premise is continuous unbounded ingest by agents nobody is watching, and the confabulation rate is therefore the single most important operating parameter and is currently unknown and unknowable.'",
    notes: [
      "THE CANARY CAN NEVER BE PUBLISHED. Three independent blocks: the is_canary CHECK constraint, a publication-gate refusal, and exclusion from the map view. If a canary can be published, the measurement is destroyed.",
      "The canary roster is unreachable to anonymous readers — knowing the canaries defeats them. Canaries rotate so they cannot be memorised. The measured rate is published on the methodology page beside the grade definitions.",
    ],
    paired_with: ["F-05"],
  },
  {
    case_id: "P-03",
    title: "A Grokipedia article or an unbylined post-2022 AI content-farm page",
    band: "PIPELINE",
    marker: "PIPELINE",
    expected: "contributes zero to every condition, counts as ZERO lineages, retained and displayed",
    sources: "skeptic",
    entity_slug: "candidate-2026-0141",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "The base rates make this THE NORMAL CASE RATHER THAN THE EDGE CASE. Under v0.1 it is a 'wiki' — P4 — and P4 is gated ONLY on DOC, so it feeds GEO, INF, OWN, TEST and COR without limit and counts as a fully independent lineage, BECAUSE IT SHARES NO STRINGS WITH WIKIPEDIA AND CITES NOTHING LINEAGE TRACING CAN TRAVERSE.",
    notes: [
      "Four such sources yield ZERO lineages — where v0.1 yields COR ~60 and CONTAM ~15, the exact inverse of the truth.",
      "Test the same page under BOTH the explicit versioned blocklist AND the general mechanical heuristic, BECAUSE THE BLOCKLIST WILL ALWAYS LAG.",
      "corpus_era is COMPUTED from Wayback CDX, domain registration and byline history — NEVER JUDGED.",
      "THE NEGATIVE ASSERTION: no AI-text-detection classifier is used anywhere in the pipeline. They do not survive paraphrase and their false-positive profile is worst on formal institutional prose — exactly this corpus.",
    ],
  },
  {
    case_id: "P-04",
    title: "An OSM or Wikimapia node tagged military=bunker at a real coordinate",
    band: "PIPELINE",
    marker: "PIPELINE",
    expected: "a discovery LEAD contributing zero; one lineage regardless of renderer count",
    sources: "skeptic",
    entity_slug: "candidate-2026-0141",
    proposition_refs: ["p-EXIST-1", "p-LOCATE-1"],
    demonstrates:
      "THE MULTIPLIER THAT MAKES IT WORSE THAN AN ORDINARY LOOSE SECONDARY: an OSM feature replicates automatically into dozens of downstream renderers and derived datasets, so one changeset presents to a naive crawler as broad independent geospatial corroboration, PROPAGATED BY DATABASE REPLICATION RATHER THAN BY CITATION — a mechanism a citation graph cannot observe at all.",
    notes: [
      "channel = ADVERSARY-WRITABLE and causal_provenance = CROWD-EDITED → excluded from V outright. Collapse rule 5: replication into N renderers is ONE lineage. Retained as a visible discovery pointer with its changeset author, timestamp and comment recorded.",
      "THE PROMPT-INJECTION VARIANT: an identifier planted in a free-text description is routed to ingest.lead and must resolve independently at the issuing authority before any row may cite it. All fetched text enters as structurally bounded data, never as free prose in a scoring prompt.",
    ],
  },
  {
    case_id: "P-05",
    title: "The self-citation ratchet, across cycles",
    band: "PIPELINE",
    marker: "PIPELINE",
    expected:
      "quarantined — retained and displayed, zero lineages, zero conditions; the grade must not rise",
    sources: "skeptic",
    entity_slug: "candidate-2026-0141",
    proposition_refs: ["p-EXIST-1"],
    demonstrates:
      "THE ONE ENTRY IN THIS SUITE THAT FAILS ONLY OVER TIME, which is why it must be in CI rather than left to observation. Cycle N publishes at C; content farms regenerate it; the coordinate propagates into crowd map layers because the register is now the best available source for it; cycle N+1 finds sources that did not exist during cycle N; lineage reports independence; C → B. THAT IS CITOGENESIS, EXECUTED BY THE INSTRUMENT BUILT TO DETECT IT, ON A CRON SCHEDULE, PUBLISHED AS EVIDENCE OF RIGOUR.",
    notes: [
      "THE PASSING CONDITION IS THE ASYMMETRY: a grade may RISE only on evidence whose own document date precedes the register's own publication of that candidate. Downward movement carries no such restriction, because the failure mode is inflation.",
      "THE RATCHET TESTS THE TRIGGERING ROWS, NOT ALL OF V. Testing all of V means one unrelated recent blog post freezes the proposition against a genuine new archival find forever. That polarity error was present in one of the two schema proposals and is the kind of bug that looks like caution.",
      "A blocked rise is not silent: limiting_condition records that upward movement was withheld.",
    ],
  },
  {
    case_id: "P-06",
    title: "Manzano Base vs KUMMSC — the entity-resolution trap",
    band: "PIPELINE",
    marker: "PIPELINE",
    expected: "merge schema-prohibited; DISTINCT-FROM seeded from this calibration entry",
    sources: "skeptic",
    entity_slug: "kummsc",
    proposition_refs: ["p-IDENTITY-1"],
    demonstrates:
      "A LIVE TRAP. The IC analyst placed KUMMSC in their own calibration set at B WITHOUT NOTICING THE ADJACENT FACILITY IT IS CONSTANTLY CONFLATED WITH. A brief reading 'merge name variants, alias chains, coordinate near-duplicates' describes the CORRECT merge and the CATASTROPHIC merge in identical language.",
    notes: [
      "What a merged record does: scores HIGHER than either true record; spans 1947 to present (true of neither); holds a status simultaneously active and decommissioned; and pins a coordinate wrong for both.",
      "A merge requires an IDENTITY proposition at band C+ backed by a named, verified, instance-level source. PROXIMITY AND NAME SIMILARITY FLAG, NEVER MERGE.",
      "IF A MERGE RAISES A GRADE, THE MERGE IS REJECTED — expressed as a CHECK constraint on grade_before/grade_after/raised_a_grade, not as a guideline.",
      "The CORRECT merge must still work: KUMMSC ≡ KUMSC on a name-variant IDENTITY proposition.",
    ],
    paired_with: ["A-16", "B-02"],
  },
];

/**
 * SUITE-LEVEL ASSERTIONS — S-1 … S-8. These hold ACROSS the suite rather than
 * within any one case, and `/calibration` publishes them beside the case table.
 */
export const SUITE_ASSERTIONS = [
  {
    id: "S-1",
    title: "The discriminating pair separation",
    text: "Fairview (B-01) and SubTropolis (R-02) must be separated by four bands in the correct direction. Boyers (A-06) and SubTropolis must be separated on DOCUMENTARY grounds, not on place-signals, where they are identical.",
  },
  {
    id: "S-2",
    title: "The E/F line",
    text: "E-01 (DIA) and F-01 (Montauk) must be separated by exactly the §2.5 rule, and the reason recorded must be \"V non-empty and non-discriminating\" versus \"V empty.\"",
  },
  {
    id: "S-3",
    title: "Split entities at shared coordinates",
    text: "A-08/F-01 (Camp Hero / Montauk Project) and A-01/R-01 (Cheyenne Mountain EXIST / current-NORAD-HQ) must both publish without contradiction on one page.",
  },
  {
    id: "S-4",
    title: "The two bars",
    text: "Every graded proposition carries place_derived_weight and claim_derived_weight separately. A-02's FUNCTION claim must show ZERO place-derived weight.",
  },
  {
    id: "S-5",
    title: "Reconstruction",
    text: "For B-05 → A-05, grade_as_of must return the 1991 vector for a 1991 timestamp after the 1992 grade lands, and grade_history must name the observation that moved it and label the cause NEW-DISCLOSURE.",
  },
  {
    id: "S-6",
    title: "Nothing is deleted",
    text: "Every excluded, inert, V0, quarantined and refuted row in every case above is still present and still rendered, with exclusion_reason. A suite run that ends with fewer rows than it started has failed.",
  },
  {
    id: "S-7",
    title: "Band occupancy",
    text: "Reported, not pass/fail: the modal band across the graded suite should be X or D once the register is populated; C-band above ~15% triggers a diagnosticity-catalog audit.",
  },
  {
    id: "S-8",
    title: "Condition-level agreement",
    text: "Reliability is measured at the CONDITION level (\"did A2 pass?\"), not at the letter level. The double-scoring sample reports per-condition agreement, with reference-class assignment and the lineage counterfactual measured first as the two softest inputs.",
  },
] as const;

/** The five cases where the adjudicated model is known to diverge from a reviewer. */
export const KNOWN_WRONG = [
  { case_id: "R-05", reviewers: "both: F", bes: "R", why: "The historian's own text demands the AFOSI documentation be representable as evidence AGAINST — that is R. Their F was bounded by a vocabulary in which R did not exist." },
  { case_id: "E-03", reviewers: "historian: D", bes: "E", why: "One band, conservative. \"The claim survives only as a claim\" is judged truer than \"signals equally consistent with the alternative\", because there are no signals, only a report of testimony." },
  { case_id: "B-05", reviewers: "historian: C · IC: B", bes: "B", why: "The two lenses contradict each other. The IC reading is taken: three verified claim-property lineages satisfy B1's second clause on the record alone." },
  { case_id: "F-06", reviewers: "skeptic: F, for a stated reason", bes: "F or R", why: "The two halves of the requirement conflict under BES. If a DOB/DCRA record affirmatively establishes no basement, that is R3 → R, which is the stronger answer." },
  { case_id: "B-02/B-03/B-04", reviewers: "both: B", bes: "pairs", why: "The composite has no BES analogue. Satisfied by the decomposition; must not be reported as a letter match." },
] as const;

/** The structural known-wrong, not tied to a facility. */
export const RATIFICATION_ITEM_R3 = {
  id: "R-3",
  description:
    "A proposition with strong D4 support AND one unrebutted D3 UNDERCUTS falls through A/B/C (blocked by A4/B3/C3), fails D (null_state = EXCLUDED is not in D2cond) and fails E (E2 requires V[D2+] empty) — landing at F, beneath a middle band, on strong evidence. Implemented literally. THE FIX BELONGS IN THE RUBRIC, NOT THE SCHEMA. A synthetic fixture reproduces it in the acceptance suite.",
} as const;
