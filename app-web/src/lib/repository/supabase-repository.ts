/**
 * SUPABASE REPOSITORY — the seam, stubbed.
 *
 * NOTHING IN THIS FILE CONNECTS TO ANYTHING. There is no client, no key, no
 * import of `@supabase/supabase-js`, and no network call. It exists so that the
 * shape of the eventual implementation is fixed now, while the interface is
 * being designed against real data, rather than being retrofitted against a
 * UI that has already grown assumptions.
 *
 * Every method carries the query it will make. They are written as PostgREST
 * paths because `api` is the only schema PostgREST serves (SCHEMA.md §1), and
 * writing them out is how the interface gets checked against the read surface
 * before anyone wires a client.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * WHAT A LATER AGENT MUST KNOW BEFORE FILLING THIS IN
 *
 * 1. `api` IS THE ONLY SCHEMA POSTGREST MAY SERVE. D-008 records that at the
 *    time of the deploy decision PostgREST was pointed at `public` instead —
 *    "the published projection was unreachable while ~965 PostGIS functions
 *    were exposed. Deploying in that state would have shipped the inverted
 *    surface." Verify `db-schemas = api` before the first call.
 *
 * 2. THE ANON KEY SHIPS IN CLIENT-SIDE CODE and that is correct by design: the
 *    register is public with no login. It is also why the RLS posture must be
 *    right BEFORE a public URL exists.
 *
 * 3. `api.map_feature` AND `api.map_cluster` ARE MATERIALISED VIEWS. They do
 *    not enforce RLS; their WHERE clause IS the security boundary. Do not
 *    replace `api.map_viewport` with a client-side filter over `map_feature`.
 *
 * 4. NEVER SELECT `label_point_3857`. It is a rendering-internal clustering
 *    anchor and it is never painted (DESIGN.md §0.2, §8.2, §19 refusal 4). It
 *    is absent from the `MapFeature` type on purpose; keep it absent.
 *
 * 5. `getEntry` SHOULD CALL `api.candidate_detail(p_slug)`, not assemble the
 *    entry from four separate selects. The RPC returns the proposition table,
 *    the evidence rows with receipts, the alternatives and the search receipts
 *    in ONE ROUND TRIP, already ordered by the fixed class order.
 *
 * 6. THE CALIBRATION METHODS MUST KEEP READING THE LOCAL SEED. The specimens
 *    are fixtures, not rows; they have no home in `core` and they must never
 *    acquire one. `SupabaseRepository` therefore delegates them to the seed,
 *    which is also what guarantees containment survives the swap.
 * ─────────────────────────────────────────────────────────────────────────────
 */

import type {
  CandidateDetail,
  ClaimsRegisterRow,
  ExpectedRecordRow,
  GradeEvent,
  LineageProfile,
  MethodologyCoverageRow,
  PropositionBadge,
  RegisterEntryRow,
  RegisterState,
  SilenceRow,
  TelemetryBandOccupancyRow,
  TelemetryConfabulationRow,
  TelemetryRefutationRow,
} from "../types/api";
import { SPECIMENS, SPECIMEN_CLAIMS, SPECIMEN_REGISTER_ROWS, specimenSheet, type SpecimenSheet } from "../seed";
import { compareByOriginDate } from "./seed-repository";
import type {
  CompetingGeometry,
  NotLocatableRow,
  RegisterFilter,
  Repository,
  ViewportRequest,
  ViewportResult,
} from "./types";

/** The query each method will issue, kept beside the method it belongs to. */
const QUERY = {
  registerState: "rpc/register_state — not yet defined; assemble from api.telemetry_* + registry.table_version",
  listRegister: "GET /api/proposition_badge?select=*&order=entity_slug",
  getEntry: "POST /api/rpc/candidate_detail  { p_slug }",
  badges: "GET /api/proposition_badge?entity_slug=eq.{slug}",
  lineage: "POST /api/rpc/trace_origin  { p_proposition_id, p_depth }",
  silence: "GET /api/expected_record_table + core.search_receipt via candidate_detail",
  movement: "POST /api/rpc/grade_history  { p_proposition_id, p_include_drift }",
  claims: "GET /api/claims_register?order=first_appearance_date.asc.nullslast",
  viewport: "POST /api/rpc/map_viewport  { west, south, east, north, zoom, min_grade }",
  notLocatable:
    "GET /api/proposition_badge — LOCATE rows whose entity render_geometry is 'none'",
  geometryAssertions:
    "POST /api/rpc/entity_geometry_assertions  { p_slug } — every non-superseded row, never one",
  corpora: "GET /api/methodology_coverage?order=host",
  erp: "GET /api/expected_record_table?order=profile_key",
  confabulation: "GET /api/telemetry_confabulation",
  bandOccupancy: "GET /api/telemetry_band_occupancy",
  refutation: "GET /api/telemetry_refutation",
} as const;

class NotWired extends Error {
  constructor(method: keyof typeof QUERY) {
    super(
      `SupabaseRepository.${method} is not wired. The register has 0 candidates and ` +
        `egress to the 122 catalogued hosts has not landed (D-007), so there is nothing ` +
        `to read yet. When wiring it, issue: ${QUERY[method]}`,
    );
    this.name = "NotWired";
  }
}

export interface SupabaseRepositoryConfig {
  url: string;
  /** The anon key. Public by design; the RLS posture is what protects the data. */
  anonKey: string;
  /** Must be `api`. Anything else is the inverted surface D-008 describes. */
  schema?: "api";
}

export class SupabaseRepository implements Repository {
  readonly kind = "supabase" as const;

  constructor(private readonly config: SupabaseRepositoryConfig) {
    if ((config.schema ?? "api") !== "api") {
      throw new Error(
        "SupabaseRepository must read the `api` schema. `public` exposes the PostGIS " +
          "function surface and hides the published projection — see D-008.",
      );
    }
  }

  /** Diagnostics for `/api`, without leaking the key. */
  describe(): { url: string; schema: string; wired: false } {
    return { url: this.config.url, schema: "api", wired: false };
  }

  async getRegisterState(): Promise<RegisterState> {
    throw new NotWired("registerState");
  }
  async listRegister(_filter?: RegisterFilter): Promise<RegisterEntryRow[]> {
    throw new NotWired("listRegister");
  }
  async getEntry(_slug: string): Promise<CandidateDetail | null> {
    throw new NotWired("getEntry");
  }
  async getPropositionBadges(_slug: string): Promise<PropositionBadge[]> {
    throw new NotWired("badges");
  }
  async getLineage(_propositionId: string): Promise<LineageProfile | null> {
    throw new NotWired("lineage");
  }
  async getSilence(_propositionId: string): Promise<SilenceRow[]> {
    throw new NotWired("silence");
  }
  async getMovement(_propositionId: string): Promise<GradeEvent[]> {
    throw new NotWired("movement");
  }
  async listClaims(): Promise<ClaimsRegisterRow[]> {
    throw new NotWired("claims");
  }
  async getViewport(_req: ViewportRequest): Promise<ViewportResult> {
    throw new NotWired("viewport");
  }
  async listNotLocatable(): Promise<NotLocatableRow[]> {
    throw new NotWired("notLocatable");
  }
  /**
   * GET /rest/v1/rpc/entity_geometry_assertions  { p_slug }
   *
   * There is no `api.*` view for this yet. It needs one, and it must be an RPC
   * or a view over `core.geometry_assertion` filtered to
   * `superseded_at is null`, projecting `geometry_assertion_id, entity_id,
   * precision, origin_tier, is_preferred, claimed_place_name,
   * uncertainty_radius_m, asserted_at`, the source siglum by join, and
   * `st_asgeojson(coalesce(point_geom, region_geom))` — one row per
   * ASSERTION, never a reconciliation of them.
   *
   * DO NOT add a `preferred_only` parameter. The point of this call is that
   * every non-superseded assertion is returned and drawn at once; a filter that
   * returns one of them silently restores the averaged-coordinate failure this
   * endpoint exists to prevent.
   */
  async getGeometryAssertions(_slug: string): Promise<CompetingGeometry[]> {
    throw new NotWired("geometryAssertions");
  }
  async listCorpora(): Promise<MethodologyCoverageRow[]> {
    throw new NotWired("corpora");
  }
  async listExpectedRecords(): Promise<ExpectedRecordRow[]> {
    throw new NotWired("erp");
  }
  async getConfabulation(): Promise<TelemetryConfabulationRow[]> {
    throw new NotWired("confabulation");
  }
  async getBandOccupancy(): Promise<TelemetryBandOccupancyRow[]> {
    throw new NotWired("bandOccupancy");
  }
  async getRefutationTelemetry(): Promise<TelemetryRefutationRow> {
    throw new NotWired("refutation");
  }

  /**
   * Point 6 above: the specimens stay local under every implementation. They
   * are fixtures and they must never acquire a row in `core`.
   */
  async listCalibration(): Promise<SpecimenSheet[]> {
    return SPECIMENS;
  }
  async getCalibrationCase(caseId: string): Promise<SpecimenSheet | null> {
    return specimenSheet(caseId);
  }
  async listCalibrationRegister(): Promise<RegisterEntryRow[]> {
    return SPECIMEN_REGISTER_ROWS;
  }
  async listCalibrationClaims(): Promise<ClaimsRegisterRow[]> {
    return [...SPECIMEN_CLAIMS].sort(compareByOriginDate);
  }
}
