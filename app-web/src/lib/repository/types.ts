/**
 * THE REPOSITORY INTERFACE — the single seam the UI reads through.
 *
 * Two rules govern this file.
 *
 * ONE. THE UI MUST NOT KNOW WHICH IMPLEMENTATION IS IN USE. Every method
 * returns api.* row types and nothing else; nothing leaks a Supabase client, a
 * PostgREST filter object, a seed array, or a `specimen: boolean` the caller has
 * to remember to check. Swapping `SeedRepository` for `SupabaseRepository`
 * changes no component.
 *
 * TWO. THE REGISTER SURFACE AND THE SPECIMEN SURFACE ARE DIFFERENT METHODS.
 * This is DESIGN.md §18's containment expressed as a type. `listRegister()`
 * cannot return a specimen because specimens are not in the array it reads, and
 * `listCalibration()` cannot be mistaken for register content because its
 * return type carries the containment block with the header rule, the robots
 * directive and the aria prefix already filled in. A UI that renders whatever
 * the repository hands it renders the marker automatically.
 *
 * Method groups, and which of them is populated today:
 *
 *   REGISTER      empty. 0 candidates; collection has not begun (D-007).
 *   CLAIMS        empty, for the same reason.
 *   PLATE         empty of features; the sheet itself is complete.
 *   CURATED       POPULATED ON DAY ONE — the source registry, the ERP table,
 *                 the egress schedule, the decisions, the limitations.
 *   TELEMETRY     populated with real zeroes and its expectations beside them.
 *   CALIBRATION   POPULATED — 34 cases + 6 pipeline tests, contained.
 */

import type {
  CandidateDetail,
  ClaimsRegisterRow,
  ExpectedRecordRow,
  GradeEvent,
  LineageProfile,
  MapCluster,
  MapFeature,
  MethodologyCoverageRow,
  PropositionBadge,
  RegisterEntryRow,
  RegisterState,
  SilenceRow,
  TelemetryBandOccupancyRow,
  TelemetryConfabulationRow,
  TelemetryRefutationRow,
} from "../types/api";
import type {
  GeometryRepresentation,
  Grade,
  LocatePrecision,
  OriginTier,
  PropositionClass,
  Typology,
} from "../types/enums";
import type { GeoJsonGeometry } from "../types/api";
import type { SpecimenSheet } from "../seed";

/**
 * Filters for `/`. Every one of these is a URL parameter and a `<form>` GET
 * field: "All state in the URL." No chips, no pills, no autocomplete, no
 * search-as-you-type.
 */
export interface RegisterFilter {
  class?: PropositionClass[];
  band?: Grade[];
  cap_applied?: string[];
  silence_reading?: string[];
  locate_precision?: LocatePrecision[];
  typology?: Typology[];
  state?: string[];
  citogenesis?: boolean;
  at_ceiling?: boolean;
  marginal?: boolean;
  /** Minimum SCI. A floor, never a rank. */
  sci_floor?: number;
}

/**
 * A viewport request for the plate. Mirrors `api.map_viewport`, including its
 * `min_grade` default of D — BES §10.3, nothing below band D renders at all,
 * and the plate says so in the legend rather than omitting silently.
 */
export interface ViewportRequest {
  west: number;
  south: number;
  east: number;
  north: number;
  zoom: number;
  min_grade?: Grade;
  typologies?: Typology[];
}

export type ViewportResult =
  | { mode: "clusters"; zoom: number; clusters: MapCluster[] }
  | { mode: "features"; zoom: number; features: MapFeature[] };

/** The docked NOT LOCATABLE ON THIS PLATE panel. A map cannot show what has no
 *  coordinates; making the unmappable visible BESIDE the map is the honest
 *  answer, and it is where place_name_only and non_located become legible
 *  rather than silently absent. */
export interface NotLocatableRow {
  slug: string;
  name: string;
  locate_precision: Extract<LocatePrecision, "place_name_only" | "non_located">;
  claimed_place_name: string | null;
  destination: "claims register" | "entry";
  href: string;
}

/**
 * COMPETING GEOMETRY — `core.geometry_assertion`, versioned and competing by
 * design (SCHEMA.md §11).
 *
 * DESIGN.md §8.2: "On selection, EVERY NON-SUPERSEDED ASSERTION RENDERS
 * SIMULTANEOUSLY: preferred at full weight, competitors at 40% opacity with
 * their `origin_tier` tag beside them, joined by 1px `--rule-strong` hairlines
 * showing they refer to one entity. 'Four sources put this in four different
 * places' becomes a SHAPE. COORDINATES ARE NEVER AVERAGED. An averaged
 * coordinate is a point no source asserts, and once painted it will be cited."
 *
 * This is a per-entity read, made on selection only — `api.map_feature` returns
 * one already-resolved shape per entity, which is the right default for a
 * viewport query and the wrong thing to show when a reader asks about ONE
 * candidate. It is also what makes the `PD` chart tag provable: PD is "competing
 * geometry assertions in conflicting positions", and without these rows nothing
 * on the plate may assert it.
 */
export interface CompetingGeometry {
  geometry_assertion_id: string;
  entity_id: string;
  precision: LocatePrecision;
  /** What `core.render_geometry()` would emit for THIS assertion, alone. */
  representation: GeometryRepresentation;
  origin_tier: OriginTier;
  is_preferred: boolean;
  /** Null for `place_name_only` and `non_located`. Nothing is drawn for those. */
  geom: GeoJsonGeometry | null;
  claimed_place_name: string | null;
  uncertainty_radius_m: number | null;
  /** The siglum of the document asserting this position — `/sources` links here. */
  asserted_by_siglum: string | null;
  asserted_at: string | null;
}

export interface Repository {
  /** Which implementation answered. Diagnostics only — never a branch in a component. */
  readonly kind: "seed" | "supabase";

  /* --------------------------- REGISTER --------------------------- */
  getRegisterState(): Promise<RegisterState>;
  listRegister(filter?: RegisterFilter): Promise<RegisterEntryRow[]>;
  getEntry(slug: string): Promise<CandidateDetail | null>;
  getPropositionBadges(slug: string): Promise<PropositionBadge[]>;
  getLineage(propositionId: string): Promise<LineageProfile | null>;
  getSilence(propositionId: string): Promise<SilenceRow[]>;
  getMovement(propositionId: string): Promise<GradeEvent[]>;

  /* ---------------------------- CLAIMS ---------------------------- */
  /** Organised by origin, sorted by origin date ASCENDING. Not a graveyard. */
  listClaims(): Promise<ClaimsRegisterRow[]>;

  /* ----------------------------- PLATE ---------------------------- */
  getViewport(req: ViewportRequest): Promise<ViewportResult>;
  listNotLocatable(): Promise<NotLocatableRow[]>;
  /** Selection only. Drawn all at once, never reconciled into one position. */
  getGeometryAssertions(slug: string): Promise<CompetingGeometry[]>;

  /* ---------------------------- CURATED --------------------------- */
  listCorpora(): Promise<MethodologyCoverageRow[]>;
  listExpectedRecords(): Promise<ExpectedRecordRow[]>;

  /* --------------------------- TELEMETRY -------------------------- */
  getConfabulation(): Promise<TelemetryConfabulationRow[]>;
  getBandOccupancy(): Promise<TelemetryBandOccupancyRow[]>;
  getRefutationTelemetry(): Promise<TelemetryRefutationRow>;

  /* -------------------------- CALIBRATION ------------------------- */
  /**
   * The specimen surface. Separate method, separate return type, containment
   * block attached. These rows enter no count on `/`, no telemetry aggregate
   * and no plate feature, and the repository is where that is guaranteed.
   */
  listCalibration(): Promise<SpecimenSheet[]>;
  getCalibrationCase(caseId: string): Promise<SpecimenSheet | null>;
  /**
   * The specimen catalogue and the specimen claims register, one row per
   * entity / per proposition rather than one per case.
   *
   * They exist because DESIGN.md §18.3 requires the calibration set to be
   * "rendered through THE EXACT SAME COMPONENTS", and the components that
   * render `/` and `/claims` take `RegisterEntryRow[]` and
   * `ClaimsRegisterRow[]`. Keeping them on their own methods is what keeps the
   * containment structural rather than conventional: `listRegister()` cannot
   * return a specimen because it does not read this array, and no caller can
   * accidentally concatenate the two without writing the concatenation down.
   */
  listCalibrationRegister(): Promise<RegisterEntryRow[]>;
  listCalibrationClaims(): Promise<ClaimsRegisterRow[]>;
}
