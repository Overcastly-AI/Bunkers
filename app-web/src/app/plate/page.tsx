import type { Metadata } from "next";
import { getRepository } from "@/lib/repository";
import { Plate } from "@/components/plate/Plate";
import { PLATE_NUMBER, PLATE_TITLE } from "@/lib/plate/legend";
import "./plate.css";

/**
 * `/plate` — PLATE I, INDEX MAP TO THE CATALOGUE.
 *
 * DESIGN.md §18, on the plate at zero candidates:
 *
 * > "`/plate` at zero candidates RENDERS COMPLETE — hillshade, land status,
 * > state and county lines, graticule, scale bar, north tick, projection
 * > statement, full legend — with one Mono annotation in the corner:
 * > `PLATE I — 0 features. Basemap and land-status layers only. The index is
 * > empty; the sheet is not.` The `NOT LOCATABLE ON THIS PLATE (0)` panel is
 * > present. A BLANK GREY RECTANGLE WOULD BE THE FAILURE; A CORRECTLY
 * > FURNISHED EMPTY PLATE IS A FINISHED OBJECT."
 *
 * The server renders the panel — legend, chart abbreviations, furniture,
 * projection statement, NOT LOCATABLE panel — as real markup, so §16's rule
 * holds: "the entire site works with JavaScript disabled EXCEPT THE MAP
 * CANVAS." The canvas is the only thing on this page that waits for script.
 *
 * The initial rows come from the repository at build time. The plate then reads
 * `/api/plate/viewport` on movement, which is the same `Repository.getViewport`
 * call — one seam, two callers.
 */

export const metadata: Metadata = {
  title: `${PLATE_NUMBER} — ${PLATE_TITLE} · BUNKERS`,
  description:
    "An index map to the register. Positional uncertainty is drawn after U.S. Chart " +
    "No. 1 / IHO INT-1: no pin claims a precision the evidence cannot make.",
};

export default async function PlatePage() {
  const repo = getRepository();

  /* The default view is CONUS; the viewport call is made with the same extent
     the client will start from, so the first paint is not a second state. */
  const initial = await repo.getViewport({
    west: -126,
    south: 23,
    east: -66,
    north: 50,
    zoom: 3.6,
    min_grade: "D",
  });

  const notLocatable = await repo.listNotLocatable();

  /**
   * §9.4 — the count of candidates the publication gate holds off this plate.
   * Read from the claims register, which is where BES §10.3 sends everything
   * below band D. It is a length of a list, not an estimate: today it is 0
   * because there are no candidates at all, and when it is not 0 the note on
   * the plate will say the true number. THE MAP NEVER OMITS WITHOUT SAYING SO.
   */
  const excludedBelowD = (await repo.listClaims()).length;

  return (
    <Plate
      initialFeatures={initial.mode === "features" ? initial.features : []}
      initialClusters={initial.mode === "clusters" ? initial.clusters : []}
      notLocatable={notLocatable}
      excludedBelowD={excludedBelowD}
    />
  );
}
