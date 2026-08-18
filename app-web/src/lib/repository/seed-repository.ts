/**
 * SEED REPOSITORY — the local implementation, backed by the calibration seed.
 *
 * The register-facing methods return EMPTY, and they return empty because the
 * arrays they read are empty, not because a flag is set. The calibration
 * methods return the 34 cases plus the 6 pipeline tests, each wrapped in its
 * containment block.
 *
 * The curated tables are populated on day one, exactly as DESIGN.md §18.4
 * requires: "/method, /method/expected-records, /limits, /decisions, /sources
 * and /telemetry are complete and populated on day one."
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
import {
  REGISTER_CLAIMS,
  REGISTER_ENTRIES,
  REGISTER_STATE,
  SPECIMENS,
  SPECIMEN_CLAIMS,
  SPECIMEN_REGISTER_ROWS,
  specimenSheet,
  type SpecimenSheet,
} from "../seed";
import { CORPUS_SAMPLE, ERP_TABLE } from "./curated";
import type {
  CompetingGeometry,
  NotLocatableRow,
  Repository,
  RegisterFilter,
  ViewportRequest,
  ViewportResult,
} from "./types";

export class SeedRepository implements Repository {
  readonly kind = "seed" as const;

  /* --------------------------- REGISTER --------------------------- */

  async getRegisterState(): Promise<RegisterState> {
    return REGISTER_STATE;
  }

  /**
   * `filter` is accepted and applied, not ignored, so the filter strip is live
   * at zero candidates and the status line beneath it computes a real 0 rather
   * than printing one. DESIGN.md §18.1: "The status line is present and
   * computing."
   */
  async listRegister(filter?: RegisterFilter): Promise<RegisterEntryRow[]> {
    let rows = REGISTER_ENTRIES;
    if (!filter) return rows;
    if (filter.typology?.length) {
      const want = new Set(filter.typology);
      rows = rows.filter((r) => r.typology !== null && want.has(r.typology));
    }
    if (filter.locate_precision?.length) {
      const want = new Set(filter.locate_precision);
      rows = rows.filter((r) => want.has(r.locate_precision));
    }
    if (filter.class?.length || filter.band?.length) {
      const wantClass = filter.class?.length ? new Set(filter.class) : null;
      const wantBand = filter.band?.length ? new Set(filter.band) : null;
      rows = rows.filter((r) =>
        Object.entries(r.matrix).some(([cls, badges]) => {
          if (wantClass && !wantClass.has(cls as never)) return false;
          if (!wantBand) return true;
          return (badges ?? []).some((b) => wantBand.has(b.grade));
        }),
      );
    }
    if (filter.sci_floor !== undefined) {
      const floor = filter.sci_floor;
      rows = rows.filter((r) => r.sci !== null && r.sci >= floor);
    }
    return rows;
  }

  async getEntry(_slug: string): Promise<CandidateDetail | null> {
    /**
     * There is deliberately NO fallback to the specimen set here. A reader who
     * types `/e/raven-rock-site-r` must get nothing, because no candidate has
     * been graded; serving a fixture at a register URL is exactly the failure
     * the six containment mechanisms exist to prevent.
     */
    return null;
  }

  async getPropositionBadges(_slug: string): Promise<PropositionBadge[]> {
    return [];
  }

  async getLineage(propositionId: string): Promise<LineageProfile | null> {
    void propositionId;
    return null;
  }

  async getSilence(_propositionId: string): Promise<SilenceRow[]> {
    return [];
  }

  async getMovement(_propositionId: string): Promise<GradeEvent[]> {
    return [];
  }

  /* ---------------------------- CLAIMS ---------------------------- */

  async listClaims(): Promise<ClaimsRegisterRow[]> {
    return [...REGISTER_CLAIMS].sort(compareByOriginDate);
  }

  /* ----------------------------- PLATE ---------------------------- */

  async getViewport(req: ViewportRequest): Promise<ViewportResult> {
    /**
     * PLATE I renders complete at zero features — hillshade, land status, state
     * and county lines, graticule, scale bar, north tick, projection statement,
     * full legend — with one Mono annotation in the corner. A blank grey
     * rectangle would be the failure; a correctly furnished empty plate is a
     * finished object.
     */
    return req.zoom <= 9
      ? { mode: "clusters", zoom: req.zoom, clusters: [] }
      : { mode: "features", zoom: req.zoom, features: [] };
  }

  async listNotLocatable(): Promise<NotLocatableRow[]> {
    return [];
  }

  /**
   * Empty because there are no entities, not because competing geometry is
   * unimplemented. The plate draws whatever this returns, all of it at once,
   * and reconciles nothing — see DESIGN.md §8.2.
   */
  async getGeometryAssertions(slug: string): Promise<CompetingGeometry[]> {
    void slug;
    return [];
  }

  /* ---------------------------- CURATED --------------------------- */

  async listCorpora(): Promise<MethodologyCoverageRow[]> {
    return CORPUS_SAMPLE;
  }

  async listExpectedRecords(): Promise<ExpectedRecordRow[]> {
    return ERP_TABLE;
  }

  /* --------------------------- TELEMETRY -------------------------- */

  async getConfabulation(): Promise<TelemetryConfabulationRow[]> {
    /** No agent run has completed. An empty table, not a fabricated rate. */
    return [];
  }

  async getBandOccupancy(): Promise<TelemetryBandOccupancyRow[]> {
    /**
     * Specimens are excluded from telemetry (containment mechanism 6), so this
     * is empty rather than reporting the calibration set's band distribution as
     * if it were the register's. `/telemetry` prints its expectations beside
     * dashes: "modal band should be X or D — observed: no data".
     */
    return [];
  }

  async getRefutationTelemetry(): Promise<TelemetryRefutationRow> {
    return { refuted: 0, r2_only: 0, graded: 0, reversed: 0 };
  }

  /* -------------------------- CALIBRATION ------------------------- */

  async listCalibration(): Promise<SpecimenSheet[]> {
    return SPECIMENS;
  }

  async getCalibrationCase(caseId: string): Promise<SpecimenSheet | null> {
    return specimenSheet(caseId);
  }

  /**
   * The specimen catalogue, keyed by ENTITY rather than by case, so it can be
   * handed to the same table component that renders `/`. Thirty rows against
   * the register's zero — and they are thirty rows in a different array,
   * reached by a different method, printed under a different namespace behind
   * a hatched margin rule.
   */
  async listCalibrationRegister(): Promise<RegisterEntryRow[]> {
    return SPECIMEN_REGISTER_ROWS;
  }

  async listCalibrationClaims(): Promise<ClaimsRegisterRow[]> {
    return [...SPECIMEN_CLAIMS].sort(compareByOriginDate);
  }
}

/**
 * `/claims` default sort: ORIGIN DATE ASCENDING. "Sorted that way, band F
 * becomes a chronology of American underground folklore." Undated claims sort
 * last rather than to the epoch, because an invented date is a claim.
 */
export function compareByOriginDate(
  a: ClaimsRegisterRow,
  b: ClaimsRegisterRow,
): number {
  const ad = a.first_appearance_date;
  const bd = b.first_appearance_date;
  if (ad === null && bd === null) return a.slug.localeCompare(b.slug);
  if (ad === null) return 1;
  if (bd === null) return -1;
  if (ad === bd) return a.slug.localeCompare(b.slug);
  return ad < bd ? -1 : 1;
}
