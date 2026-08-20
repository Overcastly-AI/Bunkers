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
const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  eslint: { ignoreDuringBuilds: true },
  typescript: { ignoreBuildErrors: false },

  /* /basemap/* is served by src/app/basemap/[...path]/route.ts — a faithful
   * range proxy. It replaced a rewrite here after the edge cache, which does
   * not key on the Range header, cached the 16-byte presence probe and
   * replayed it for every range request on the archive. The route handler
   * carries the full account. */
};

export default nextConfig;
