/**
 * `/basemap/[...path]` — faithful range proxy to the basemap archive store.
 *
 * WHY A ROUTE HANDLER AND NOT A REWRITE. The first deployment proxied
 * /basemap/* with a next.config rewrite and stamped the responses
 * `immutable, max-age=31536000`. Vercel's edge caches by URL and does not
 * key on the Range header, so the first range request after deploy — the
 * 16-byte presence probe — was cached and replayed verbatim for every
 * subsequent range on the archive. The PMTiles reader asked for its 16 KB
 * header, received those 16 bytes, and threw
 * `RangeError: Offset is outside the bounds of the DataView`; the plate
 * rendered ground and graticule over an archive it could never read.
 * Measured on 2026-08-20: a 16384-byte range through the rewrite returned
 * 16 bytes while the same request against the blob returned 16384, and
 * `pmtiles show` validated the stored archive completely. The upload was
 * never the problem; the cache was.
 *
 * This handler forwards Range upstream unmodified, streams the upstream
 * status and body back, and marks every response `no-store`, because a
 * cache that cannot key on Range must not hold range responses at all.
 * The privacy posture is unchanged: the browser still addresses only this
 * origin, and `assertNoVendorHost()` still passes — DESIGN.md §9.1 forbids
 * telling a third party which coordinates a reader panned to, and no new
 * party appears anywhere in this path.
 *
 * When BASEMAP_ORIGIN is unset the handler 404s, `public/basemap/` static
 * files (which Next serves ahead of route handlers) still win when present,
 * and the plate's absent-archive notice behaves exactly as before.
 */

export const dynamic = "force-dynamic";

const FORWARDED = [
  "content-type",
  "content-range",
  "accept-ranges",
  "content-length",
  "etag",
] as const;

export async function GET(
  request: Request,
  { params }: { params: Promise<{ path: string[] }> },
) {
  const origin = process.env.BASEMAP_ORIGIN?.replace(/\/+$/, "");
  if (!origin) {
    return new Response("basemap origin not configured", { status: 404 });
  }

  const { path } = await params;
  const upstream = `${origin}/${path.map(encodeURIComponent).join("/")}`;

  const range = request.headers.get("range");
  const res = await fetch(upstream, {
    headers: range ? { range } : undefined,
    cache: "no-store",
  });

  const headers = new Headers();
  for (const h of FORWARDED) {
    const v = res.headers.get(h);
    if (v) headers.set(h, v);
  }
  headers.set("cache-control", "no-store");

  return new Response(res.body, { status: res.status, headers });
}
