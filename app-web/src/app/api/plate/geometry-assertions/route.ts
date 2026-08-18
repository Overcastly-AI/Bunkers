/**
 * `/api/plate/geometry-assertions` — every non-superseded assertion, never one.
 *
 * DESIGN.md §8.2: "Competing geometry is drawn all at once.
 * `core.geometry_assertion` is versioned and competing by design. On selection,
 * every non-superseded assertion renders simultaneously… COORDINATES ARE NEVER
 * AVERAGED. An averaged coordinate is a point no source asserts, and once
 * painted it will be cited."
 *
 * There is deliberately no `preferred=true` parameter and no reconciliation
 * step. This endpoint returns rows; the plate draws all of them.
 */

import { NextResponse } from "next/server";
import { getRepository } from "@/lib/repository";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const slug = new URL(request.url).searchParams.get("slug");
  if (!slug) {
    return NextResponse.json({ error: "slug is required" }, { status: 400 });
  }
  const rows = await getRepository().getGeometryAssertions(slug);
  return NextResponse.json(rows, { headers: { "cache-control": "no-store" } });
}
