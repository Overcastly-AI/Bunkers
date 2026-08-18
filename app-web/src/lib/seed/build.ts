/**
 * BUILD — spec -> api.* rows.
 *
 * Every derivation in this file has a named counterpart in `supabase/schema.sql`
 * and is annotated with it. Where the DDL branches, this branches the same way;
 * where the DDL refuses to emit something, this refuses too. The most important
 * of those is `renderGeometry()`, which is a line-for-line transcription of
 * `core.render_geometry()` — including the hard gate that a point requires BOTH
 * a precise assertion AND a LOCATE proposition at band C or better.
 *
 * Nothing here computes a grade. Grades are declared by the specimen because
 * they are the calibration suite's EXPECTED VALUES; a fixture that graded
 * itself would assert nothing.
 */

import type {
  AlternativeRow,
  CandidateDetail,
  CandidateEntity,
  ClaimsRegisterRow,
  EvidenceRow,
  GeoJsonGeometry,
  GradeEvent,
  LineageProfile,
  MapFeature,
  PropositionBadge,
  PropositionDetail,
  RegisterEntryRow,
  SearchReceipt,
  SilenceRow,
} from "../types/api";
import type { GeometryRepresentation, Grade, PropositionClass } from "../types/enums";
import { PROPOSITION_CLASS_ORDER } from "../types/enums";
import { gradeRank } from "../types/grade";
import {
  deriveExclusionReason,
  deriveMembership,
  effectiveScope,
  gateConditions,
  gatePass,
  signedWeight,
} from "./membership";
import type {
  SpecEntity,
  SpecGeometry,
  SpecObservation,
  SpecProposition,
} from "./types";

/* ------------------------------------------------------------------ *
 * Deterministic synthetic identifiers.
 *
 * Specimen ids are generated, stable across builds, and carry the literal
 * string `5pec` in the version position so that an id copied out of a specimen
 * sheet cannot be mistaken for — or collide with — a register uuid. They are
 * not v4 uuids and are not meant to look like one on close reading.
 * ------------------------------------------------------------------ */

function fnv1a(s: string): number {
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h >>> 0;
}

export function hex(s: string, len: number): string {
  let out = "";
  let salt = 0;
  while (out.length < len) {
    out += fnv1a(`${s}#${salt++}`).toString(16).padStart(8, "0");
  }
  return out.slice(0, len);
}

export function specimenId(kind: string, ...parts: string[]): string {
  const s = `${kind}:${parts.join("/")}`;
  return `${hex(s, 8)}-${hex(`${s}-a`, 4)}-5pec-${hex(`${s}-c`, 4)}-${hex(`${s}-d`, 12)}`;
}

/* ------------------------------------------------------------------ *
 * Geometry — `core.render_geometry(p_entity_id)`
 * ------------------------------------------------------------------ */

export interface RenderedGeometry {
  representation: GeometryRepresentation;
  geom: GeoJsonGeometry | null;
  uncertainty_radius_m: number | null;
  claimed_place_name: string | null;
  suppression_reason: string | null;
}

/** A circle on the ground, as `st_buffer(point::geography, rad)` returns one. */
function groundCircle(
  [lon, lat]: [number, number],
  radiusM: number,
  segments = 64,
): GeoJsonGeometry {
  const ring: [number, number][] = [];
  const dLat = (radiusM / 111_320) * (180 / 180);
  const dLon = radiusM / (111_320 * Math.cos((lat * Math.PI) / 180));
  for (let i = 0; i <= segments; i++) {
    const t = (i / segments) * 2 * Math.PI;
    ring.push([
      Number((lon + dLon * Math.cos(t)).toFixed(6)),
      Number((lat + dLat * Math.sin(t)).toFixed(6)),
    ]);
  }
  return { type: "Polygon", coordinates: [ring] };
}

/**
 * Transcription of `core.render_geometry()`. Read the DDL alongside it.
 *
 * THE HARD GATE, verbatim from the function body: a `point` requires BOTH
 * `precision in ('surveyed','approximate_1km')` AND a LOCATE proposition graded
 * C or better. Everything else degrades to an area. There is no branch in this
 * function that emits a coordinate for anything else, which is what makes
 * DESIGN.md §0.2 ("no manufactured coordinate") a property of the code rather
 * than a rule someone has to remember.
 */
export function renderGeometry(
  g: SpecGeometry,
  locateGrade: Grade | null,
): RenderedGeometry {
  if (g.precision === "non_located") {
    return {
      representation: "none",
      geom: null,
      uncertainty_radius_m: null,
      claimed_place_name: null,
      suppression_reason: "non-located: documented, coordinates genuinely unknown",
    };
  }
  if (g.precision === "place_name_only") {
    return {
      representation: "none",
      geom: null,
      uncertainty_radius_m: null,
      claimed_place_name: g.claimed_place_name ?? null,
      suppression_reason: "place name claimed, no coordinate asserted by any source",
    };
  }

  const locateRank = locateGrade ? (gradeRank(locateGrade) ?? 0) : 0;

  if (
    g.point &&
    (g.precision === "surveyed" || g.precision === "approximate_1km") &&
    locateRank >= gradeRank("C")!
  ) {
    return {
      representation: "point",
      geom: { type: "Point", coordinates: g.point },
      uncertainty_radius_m: g.radius_m ?? null,
      claimed_place_name: null,
      suppression_reason: null,
    };
  }

  if (g.point) {
    const rad =
      g.radius_m ??
      (g.precision === "approximate_1km"
        ? 1000
        : g.precision === "approximate_10km"
          ? 10000
          : 25000);
    return {
      representation: "uncertainty_circle",
      geom: groundCircle(g.point, rad),
      uncertainty_radius_m: rad,
      claimed_place_name: null,
      suppression_reason:
        locateRank < gradeRank("C")!
          ? "LOCATE proposition below band C: rendered as uncertainty, never as a pin"
          : "coordinate precision below approximate_1km",
    };
  }

  if (g.polygon) {
    const closed: [number, number][] = [...g.polygon];
    const first = closed[0]!;
    const last = closed[closed.length - 1]!;
    if (first[0] !== last[0] || first[1] !== last[1]) closed.push(first);
    return {
      representation: g.precision === "admin_area" ? "admin_polygon" : "region_polygon",
      geom: { type: "Polygon", coordinates: [closed] },
      uncertainty_radius_m: null,
      claimed_place_name: null,
      suppression_reason:
        g.precision === "admin_area" ? "located only to administrative area" : null,
    };
  }

  return {
    representation: "none",
    geom: null,
    uncertainty_radius_m: null,
    claimed_place_name: null,
    suppression_reason: "no renderable shape",
  };
}

/**
 * DESIGN.md §8.2, the closing constraint on interface-layer citogenesis:
 * "nothing that is not `exact` ever receives a visible centre mark — not
 * faintly, not as a cluster anchor, not as a label anchor, not as a hover
 * target."
 *
 * A `point` representation carries a real asserted coordinate. When it also
 * carries a radius the mark is a survey cross inside a dotted circle at true
 * ground scale; when it does not, the cross stands alone. Every other
 * representation is an area, and an area has no centre.
 */
export function paintsCentre(rep: GeometryRepresentation): boolean {
  return rep === "point";
}

/* ------------------------------------------------------------------ *
 * Observations -> api.evidence_row
 * ------------------------------------------------------------------ */

function buildEvidenceRow(
  entitySlug: string,
  propRef: string,
  propositionId: string,
  o: SpecObservation,
): EvidenceRow {
  const d = o.document;
  const r = o.receipt;
  const scope = effectiveScope(o);
  return {
    observation_id: specimenId("obs", entitySlug, propRef, o.key),
    proposition_id: propositionId,
    statement: o.statement,
    observation_key: o.key,

    sign: o.sign,
    magnitude: o.magnitude,
    signed_weight: signedWeight(o),
    membership: deriveMembership(o),
    exclusion_reason: deriveExclusionReason(o),

    diagnosticity_source: o.diagnosticity_source ?? "CATALOG",
    ea_expectedness: o.ea_expectedness ?? null,
    ea_alternative: o.ea_alternative ?? null,

    scope,
    property_locus: o.property_locus,
    subject_binding_pass: o.subject_binding_pass ?? true,
    fact_key: o.fact_key ?? null,

    null_excluding: o.null_excluding ?? false,
    documents_null: o.documents_null ?? false,
    gate_pass: gatePass(o),
    gate_conditions: gateConditions(o),

    refutation_class: o.refutation_class ?? null,
    rebutted: o.rebutted ?? false,
    rebuttal_note: o.rebuttal_note ?? null,

    document_id: d ? specimenId("doc", d.title, d.identifier ?? "") : null,
    title: d?.title ?? null,
    issuing_body: d?.issuing_body ?? null,
    author_name: d?.author_name ?? null,
    document_date: d?.document_date ?? null,
    url: d?.url ?? null,
    identifier: d?.identifier ?? null,
    identifier_class: d?.identifier_class ?? null,
    origin_tier: d?.origin_tier ?? null,
    channel: d?.channel ?? null,
    causal_provenance: d?.causal_provenance ?? null,
    corpus_era: d?.corpus_era ?? null,
    self_attesting: d?.self_attesting ?? null,
    self_attesting_rationale: d?.self_attesting_rationale ?? null,
    register_echo_quarantined: d?.register_echo_quarantined ?? null,
    lineage_id: o.lineage_id ?? null,

    corpus_name: d?.corpus_name ?? null,
    corpus_host: d?.corpus_host ?? null,
    adversary_writable: d?.adversary_writable ?? null,
    egress_state: d?.egress_state ?? null,

    receipt_state: r?.state ?? null,
    resolved_url: r?.resolved_url ?? null,
    http_status: r?.http_status ?? null,
    sha256: r?.sha256 ?? null,
    retrieved_at: r?.retrieved_at ?? null,
    mirror_only: r?.mirror_only ?? null,
    issuer_metadata_match: r?.issuer_metadata_match ?? null,
    content_drifted: r?.content_drifted ?? null,

    quoted_text: o.quote?.text ?? null,
    span_start_offset: o.quote?.start ?? null,
    span_end_offset: o.quote?.end ?? null,
    quote_check: o.quote?.check ?? "EXACT-MATCH",
    binding_quote: o.binding_quote ?? null,

    negative_search_query: o.negative_search?.query ?? null,
    negative_search_corpus_date: o.negative_search?.corpus_as_of ?? null,
    negative_search_result_count: o.negative_search?.result_count ?? null,

    expected_record_profile: o.negative_search?.erp_profile ?? null,
    expected_record_level: o.negative_search?.expected_record_level ?? null,
  };
}

/* ------------------------------------------------------------------ *
 * Rollup counts — COUNTED FROM THE ROWS, never declared.
 *
 * This is Rule Zero in the data layer. Each of these is a mark on the stave;
 * each is a `filter().length` or a `reduce()` over the observation array that
 * the same page renders underneath. If a tick appears in the evidence bar there
 * is a receipt row beneath it, because they are the same array.
 * ------------------------------------------------------------------ */

function rollupCounts(rows: EvidenceRow[]) {
  const v = rows.filter((r) => r.membership === "V");
  const u = rows.filter((r) => r.membership === "U");
  return {
    v_count: v.length,
    u_count: u.length,
    v0_count: rows.filter((r) => r.membership === "V0").length,
    inert_count: rows.filter((r) => r.membership === "INERT").length,
    /** |V[claim]| — the upper storey. An empty one IS CAP-2b, visibly. */
    v_claim_count: v.filter((r) => r.property_locus === "CLAIM-PROPERTY").length,
    /** BES §10.2 two bars: how much of this grade is the mountain. */
    place_derived_weight: v
      .filter((r) => r.property_locus === "PLACE-PROPERTY")
      .reduce((a, r) => a + r.magnitude, 0),
    claim_derived_weight: v
      .filter((r) => r.property_locus === "CLAIM-PROPERTY")
      .reduce((a, r) => a + r.magnitude, 0),
  };
}

/**
 * SCI = k/n. GRADING.md §7.2's ratified correction: an EMPTY DENOMINATOR is
 * 1.000, not 0 — "nothing to search is COMPLETE, and it must not look like
 * zero." Without this, Mount Pony (A-09) is pinned at X forever.
 */
export function sciValue([k, n]: [number, number]): number {
  return n === 0 ? 1 : k / n;
}

/* ------------------------------------------------------------------ *
 * Propositions -> api.proposition_badge
 * ------------------------------------------------------------------ */

const SILENCE_PROSE: Record<string, string> = {
  UNINFORMATIVE:
    "No public record of this class would be expected for a facility of this type in this period under this authority. The absence is not evidence against.",
  "RECORD-DESTROYED":
    "The record class that would have carried this evidence no longer exists.",
  UNSEARCHED: "Not yet searched.",
  INFORMATIVE: "Searched; negative receipts logged.",
};

export function buildProposition(
  e: SpecEntity,
  p: SpecProposition,
): PropositionDetail {
  const entityId = specimenId("entity", e.slug);
  const propositionId = specimenId("prop", e.slug, p.ref);
  const evidence = (p.observations ?? []).map((o) =>
    buildEvidenceRow(e.slug, p.ref, propositionId, o),
  );
  const counts = rollupCounts(evidence);
  const [k, n] = p.sci;

  const alternatives: AlternativeRow[] = (p.alternatives ?? []).map((a) => ({
    proposition_id: propositionId,
    null_code: a.null_code,
    label: a.label,
    description: a.description,
    is_selected: a.is_selected ?? a.null_code === p.null_code,
    disposition: a.disposition,
    reasoning: a.reasoning ?? null,
    excluding_observation_ids: (a.excluding ?? []).map((key) =>
      specimenId("obs", e.slug, p.ref, key),
    ),
  }));

  const search_receipts: SearchReceipt[] = (p.searches ?? []).map((s) => ({
    query: s.query,
    corpus_as_of: s.corpus_as_of ?? null,
    outcome: s.outcome,
    result_count: s.result_count ?? null,
    erp_profile: s.erp_profile ?? null,
    egress_state: s.egress_state ?? null,
  }));

  const movement = p.movement ?? [];
  const last = movement.length > 0 ? movement[movement.length - 1]! : null;

  const badge: PropositionBadge = {
    proposition_id: propositionId,
    entity_id: entityId,
    entity_slug: e.slug,
    entity_name: e.name,

    class: p.class,
    statement_text: p.statement,
    predicate_args: p.predicate_args ?? {},
    as_of_date: p.as_of_date ?? "2026-08-18",

    grade: p.grade,
    grade_rank: gradeRank(p.grade),
    awarded_band: p.awarded_band ?? p.grade,
    grade_pre_clamp: p.grade_pre_clamp ?? p.grade,
    applied_caps: p.applied_caps ?? [],
    clamped_by_proposition_id: p.clamped_by
      ? specimenId("prop", e.slug, p.clamped_by)
      : null,

    ceiling: p.ceiling ?? null,
    ceiling_reason: p.ceiling_reason ?? null,
    at_ceiling: p.at_ceiling ?? false,

    limiting_condition: p.limiting_condition ?? null,
    marginal_flag: p.marginal_flag ?? false,

    refutation_state: p.refutation_state ?? "R0",
    null_state: p.null_state,
    null_code: p.null_code,
    null_label: p.null_label,

    silence_reading: p.silence_reading ?? "UNSEARCHED",
    silence_prose: SILENCE_PROSE[p.silence_reading ?? "UNSEARCHED"]!,

    base_rate_reading: p.base_rate_reading ?? null,
    reference_class: p.reference_class ?? e.reference_class ?? null,
    citogenesis: p.citogenesis ?? false,

    sci: sciValue(p.sci),
    sci_numerator: k,
    sci_denominator: n,

    l_d2: p.l_d2 ?? 0,
    l_d3: p.l_d3 ?? 0,

    ...counts,

    condition_results: p.condition_results ?? {},
    graded_at: last?.occurred_at ?? "2026-08-18T00:00:00Z",

    transition_cause: last?.cause ?? null,
    rubric_version: last ? "BES-0.2.0" : null,
    scorer_model_id: last ? "specimen-fixture" : null,
    evidence_state_hash: last
      ? hex(`${e.slug}/${p.ref}/${evidence.length}`, 12)
      : null,
  };

  return { ...badge, evidence, alternatives, search_receipts };
}

/* ------------------------------------------------------------------ *
 * Entities
 * ------------------------------------------------------------------ */

export function locateGradeOf(e: SpecEntity): Grade | null {
  return e.propositions.find((p) => p.class === "LOCATE")?.grade ?? null;
}

export function buildEntity(e: SpecEntity): CandidateEntity {
  const rg = renderGeometry(e.geometry, locateGradeOf(e));
  return {
    entity_id: specimenId("entity", e.slug),
    slug: e.slug,
    name: e.name,
    entity_level: e.entity_level,
    country: e.country ?? "US",
    typology: e.typology ?? null,
    reference_class: e.reference_class ?? null,
    geometry: rg.geom,
    representation: rg.representation,
    locate_precision: e.geometry.precision,
    uncertainty_radius_m: rg.uncertainty_radius_m,
    claimed_place_name: rg.claimed_place_name,
    suppression_reason: rg.suppression_reason,
    aliases: e.aliases ?? null,
    distinct_from:
      e.distinct_from?.map((x) => ({
        entity_id: specimenId("entity", x.slug),
        name: x.name,
        note: x.note,
      })) ?? null,
  };
}

/** Propositions in the fixed render order (DESIGN.md §8.1). */
export function orderPropositions(rows: PropositionDetail[]): PropositionDetail[] {
  const idx = (c: PropositionClass) => PROPOSITION_CLASS_ORDER.indexOf(c);
  return [...rows].sort((a, b) => idx(a.class) - idx(b.class));
}

export function buildCandidateDetail(e: SpecEntity): CandidateDetail {
  return {
    entity: buildEntity(e),
    propositions: orderPropositions(e.propositions.map((p) => buildProposition(e, p))),
    /**
     * DESIGN.md §18: specimen containment. "no provenance beacon is emitted."
     * A beacon is a machine-readable assertion that this is a register entry.
     * It is null here for every specimen, without exception.
     */
    provenance_beacon: null,
  };
}

/* ------------------------------------------------------------------ *
 * Derived projections
 * ------------------------------------------------------------------ */

/**
 * `api.map_feature`, WHERE clause included — and the WHERE clause is the
 * security boundary, so it is reproduced rather than paraphrased:
 *   entity published AND is_canary = false AND geom is not null
 *   AND representation <> 'none' AND EXIST grade rank >= rank('D').
 */
export function buildMapFeature(e: SpecEntity): MapFeature | null {
  if (e.is_canary) return null;
  const exist = e.propositions.find((p) => p.class === "EXIST");
  if (!exist) return null;
  const rank = gradeRank(exist.grade);
  if (rank === null || rank < gradeRank("D")!) return null;

  const locateGrade = locateGradeOf(e);
  const rg = renderGeometry(e.geometry, locateGrade);
  if (rg.geom === null || rg.representation === "none") return null;

  const published = e.propositions.length;
  return {
    entity_id: specimenId("entity", e.slug),
    slug: e.slug,
    canonical_name: e.name,
    entity_level: e.entity_level,
    country_code: e.country ?? "US",
    typology: e.typology ?? null,

    exist_grade: exist.grade,
    exist_rank: rank,
    at_ceiling: exist.at_ceiling ?? false,
    marginal_flag: exist.marginal_flag ?? false,
    ceiling: exist.ceiling ?? null,
    silence_reading: exist.silence_reading ?? "UNSEARCHED",
    base_rate_reading: exist.base_rate_reading ?? null,
    limiting_condition: exist.limiting_condition ?? null,

    representation: rg.representation,
    locate_precision: e.geometry.precision,
    locate_grade: locateGrade,
    uncertainty_radius_m: rg.uncertainty_radius_m,
    suppression_reason: rg.suppression_reason,
    geom: rg.geom,

    proposition_count: published,
    refuted_count: e.propositions.filter((p) => p.grade === "R").length,
    unassessed_count: e.propositions.filter((p) => p.grade === "X").length,
    graded_at: "2026-08-18T00:00:00Z",
  };
}

/**
 * THE INDEX ROW — one entity as `/` renders it (DESIGN.md §13.1 d).
 *
 * `matrix` is twelve slots, each holding the badges of that class and nothing
 * else. THERE IS NO GRADE FIELD ON THIS ROW and no field into which one could
 * be inserted: the row is the container, and `core.entity` carries nothing
 * graded.
 *
 * Two fields need their derivation stated, because both could easily have been
 * a Rule Zero violation:
 *
 *  `sci` IS THE EXIST PROPOSITION'S SCI, NOT AN ENTITY AVERAGE. Averaging
 *  search completeness across propositions would produce a number no row
 *  holds — precisely the operation §0 forbids — and the column header says
 *  which proposition it reports. Entities with no EXIST proposition report
 *  null, and the cell prints an em dash.
 *
 *  `last_moved` IS THE DATE OF THE MOST RECENT GRADE EVENT — one row's value,
 *  selected, not a quantity computed across rows.
 */
export function buildRegisterRow(e: SpecEntity, ref: string): RegisterEntryRow {
  const details = orderPropositions(e.propositions.map((p) => buildProposition(e, p)));

  const matrix: Partial<Record<PropositionClass, PropositionBadge[]>> = {};
  for (const d of details) {
    (matrix[d.class] ??= []).push(d);
  }

  const exist = details.find((d) => d.class === "EXIST");
  const dates = e.propositions
    .flatMap((p) => p.movement ?? [])
    .map((m) => m.occurred_at)
    .sort();

  return {
    entity_id: specimenId("entity", e.slug),
    slug: e.slug,
    ref,
    canonical_name: e.name,
    aliases: e.aliases ?? [],
    jurisdiction: e.jurisdiction,
    typology: e.typology ?? null,
    locate_precision: e.geometry.precision,
    matrix,
    sci: exist ? exist.sci : null,
    last_moved: dates.length > 0 ? dates[dates.length - 1]!.slice(0, 10) : null,
  };
}

/** `api.claims_register` — WHERE grade in ('E','F','R','X'). */
export function buildClaimsRows(e: SpecEntity): ClaimsRegisterRow[] {
  const originProps = e.propositions
    .filter((p) => p.class === "ORIGIN")
    .map((p) => ({ class: p.class, grade: p.grade }));

  return e.propositions
    .filter((p) => ["E", "F", "R", "X"].includes(p.grade))
    .map((p) => ({
      proposition_id: specimenId("prop", e.slug, p.ref),
      entity_id: specimenId("entity", e.slug),
      slug: e.slug,
      canonical_name: e.name,
      class: p.class,
      statement_text: p.statement,
      grade: p.grade as "E" | "F" | "R" | "X",
      limiting_condition: p.limiting_condition ?? null,
      silence_reading: p.silence_reading ?? "UNSEARCHED",
      refutation_state: p.refutation_state ?? "R0",
      citogenesis: p.citogenesis ?? false,
      base_rate_reading: p.base_rate_reading ?? null,
      ceiling: p.ceiling ?? null,
      at_ceiling: p.at_ceiling ?? false,
      claim_text: (p.predicate_args?.["claim_text"] as string | undefined) ?? null,
      first_appearance_date:
        (p.predicate_args?.["first_appearance_date"] as string | undefined) ?? null,
      first_appearance_confidence:
        (p.predicate_args?.["first_appearance_confidence"] as string | undefined) ??
        null,
      refutations:
        p.refutation_state && p.refutation_state !== "R0"
          ? [
              {
                state: p.refutation_state,
                narrative:
                  p.ceiling_reason ??
                  p.limiting_condition ??
                  "Refutation recorded; see the proposition detail block.",
                next_review_due: null,
              },
            ]
          : null,
      origin_propositions: originProps.length > 0 ? originProps : null,
    }));
}

export function buildLineage(
  e: SpecEntity,
  p: SpecProposition,
): LineageProfile | null {
  if (!p.lineage) return null;
  const l = p.lineage;
  return {
    proposition_id: specimenId("prop", e.slug, p.ref),
    document_count: l.document_count,
    lineage_count: l.lineage_count,
    collapse_delta: l.document_count - l.lineage_count,
    verdict_sentence: l.verdict,
    citogenesis_note: l.citogenesis_note ?? null,
    blocks: (l.blocks ?? []).map((b, i) => ({
      lineage_index: i + 1,
      dating_basis: b.dating_basis ?? "document date",
      downstream_count: b.downstream_count ?? (b.descendants?.length ?? 0),
      origin: {
        document_id: specimenId("doc", b.origin.siglum),
        siglum: b.origin.siglum,
        label: b.origin.label,
        document_date: b.origin.document_date ?? null,
        origin_tier: b.origin.origin_tier,
        collapses_lineage: false,
        edge_kind: "descent",
        depth: 0,
        resolved: b.origin.resolved ?? true,
        citogenesis: b.origin.citogenesis ?? false,
        closes_cycle: b.origin.closes_cycle ?? null,
        note: b.origin.note ?? null,
      },
      descendants: (b.descendants ?? []).map((d) => ({
        document_id: specimenId("doc", d.siglum),
        siglum: d.siglum,
        label: d.label,
        document_date: d.document_date ?? null,
        origin_tier: d.origin_tier,
        collapses_lineage: d.collapses ?? true,
        edge_kind: d.edge_kind ?? "descent",
        depth: d.depth ?? 1,
        resolved: d.resolved ?? true,
        citogenesis: d.citogenesis ?? false,
        closes_cycle: d.closes_cycle ?? null,
        note: d.note ?? null,
      })),
    })),
  };
}

export function buildSilence(e: SpecEntity, p: SpecProposition): SilenceRow[] {
  return (p.silence ?? []).map((s) => ({
    proposition_id: specimenId("prop", e.slug, p.ref),
    record_class: s.record_class,
    expected_record_level: s.expected_record_level,
    searched: s.searched,
    outcome: s.outcome ?? (s.searched ? "NEGATIVE" : "UNSEARCHED"),
    /** An unsearched class prints "— not searched" and NO ZERO: a zero is a claim. */
    result_count: s.searched ? (s.result_count ?? 0) : null,
    receipt: s.receipt ?? null,
    egress_state: s.egress_state ?? null,
    prose:
      s.expected_record_level === "X0"
        ? SILENCE_PROSE["UNINFORMATIVE"]!
        : s.searched
          ? null
          : "Not yet searched. This is the absence of a search, not a finding.",
  }));
}

export function buildMovement(e: SpecEntity, p: SpecProposition): GradeEvent[] {
  return (p.movement ?? []).map((m, i) => ({
    grade_event_id: specimenId("event", e.slug, p.ref, String(i)),
    proposition_id: specimenId("prop", e.slug, p.ref),
    occurred_at: m.occurred_at,
    grade_from: m.from ?? null,
    grade_to: m.to,
    transition_cause: m.cause,
    rubric_version: "BES-0.2.0",
    evidence_state_hash: hex(`${e.slug}/${p.ref}/${i}`, 12),
    note: m.note ?? null,
  }));
}
