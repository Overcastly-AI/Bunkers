/**
 * `/api/plate/viewport` — a thin pass-through to `Repository.getViewport()`.
 *
 * This endpoint exists so that CLUSTERING STAYS ON THE SERVER. DESIGN.md §9.3
 * clusters in SQL, on the grid cell, in `api.map_cluster`; a browser that
 * grouped features into bins of its own would be inventing positions, which is
 * the failure Rule Zero and refusal 4 exist to prevent. The client asks for a
 * viewport and draws what it is handed.
 *
 * It adds nothing to the repository's answer: no reprojection, no simplification,
 * no sorting, no merging of the two modes. `mode` is the repository's own, so a
 * reader of the JSON sees the same clusters-or-features decision the plate saw.
 */

import { NextResponse } from "next/server";
import { getRepository } from "@/lib/repository";
import type { Grade } from "@/lib/types/enums";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const p = new URL(request.url).searchParams;

  const west = Number(p.get("west"));
  const south = Number(p.get("south"));
  const east = Number(p.get("east"));
  const north = Number(p.get("north"));
  const zoom = Number(p.get("zoom"));

  if (![west, south, east, north, zoom].every((n) => Number.isFinite(n))) {
    return NextResponse.json(
      { error: "west, south, east, north and zoom are required and must be finite" },
      { status: 400 },
    );
  }

  /**
   * BES §10.3 and DESIGN.md §9.4: nothing below band D appears on the plate at
   * all, and the plate says so in the legend rather than omitting silently.
   * `min_grade` is not a caller-supplied parameter here — a query string must
   * not be able to publish an E-band candidate onto the index map.
   */
  const result = await getRepository().getViewport({
    west,
    south,
    east,
    north,
    zoom,
    min_grade: "D" as Grade,
  });

  return NextResponse.json(result, {
    headers: { "cache-control": "no-store" },
  });
}
