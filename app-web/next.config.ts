import type { NextConfig } from "next";

/**
 * BUNKERS — build configuration.
 *
 * Static by default. Every route in this application is a projection of data
 * that is known at build time (the seed repository) or of curated tables that
 * change only when the register republishes. Nothing is rendered per-request,
 * so nothing needs a server at read time.
 *
 * `output: "export"` is deliberately NOT set. The register will later serve
 * `/api/*` machine-readable endpoints (DESIGN.md §13 `/api`) and the provenance
 * beacon, and an export target forbids route handlers. Next's default output
 * still prerenders every one of these pages at build time — the build log
 * marks them `○ (Static)` — so the pages ship as static HTML either way.
 *
 * No remote images, no external hosts: DESIGN.md §2 (fonts self-hosted, no
 * Google Fonts request) and §9.1 (basemap self-hosted, no vendor request at
 * runtime). There is nothing to allowlist here, and that is the point.
 */
/**
 * BASEMAP ORIGIN REWRITE
 *
 * The Protomaps CONUS extract is 1–3 GB: too large for git, too large for a
 * deployment bundle, and pointless in either because PMTiles is read by HTTP
 * range request. A reader panning the plate pulls a few hundred KB of byte
 * ranges, never the archive.
 *
 * So the archive lives in object storage and is proxied here under
 * `/basemap/*`. What §9.1 forbids is a *vendor request at runtime* — the
 * browser telling a third party which coordinates a reader of a register of
 * federal facilities panned to. A rewrite satisfies that completely: the
 * browser only ever addresses this origin, and `assertNoVendorHost()`, which
 * inspects the URL the browser sees, passes unchanged. `public/basemap/` was
 * only ever the simplest way to meet that constraint, not the constraint.
 *
 * With BASEMAP_ORIGIN unset, requests fall through to `public/basemap/`, so a
 * local archive still works and the absent-archive notice still fires.
 *
 * The archive is immutable — rebuilt monthly under a dated name — so it is
 * safe to cache for a year at the edge.
 */
const basemapOrigin = process.env.BASEMAP_ORIGIN?.replace(/\/+$/, "");

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  eslint: { ignoreDuringBuilds: true },
  typescript: { ignoreBuildErrors: false },

  async rewrites() {
    if (!basemapOrigin) return [];
    return [
      {
        source: "/basemap/:path*",
        destination: `${basemapOrigin}/:path*`,
      },
    ];
  },

  async headers() {
    if (!basemapOrigin) return [];
    return [
      {
        source: "/basemap/:path*",
        headers: [
          { key: "Cache-Control", value: "public, max-age=31536000, immutable" },
          // PMTiles requires range support; make it explicit to intermediaries.
          { key: "Accept-Ranges", value: "bytes" },
        ],
      },
    ];
  },
};

export default nextConfig;
