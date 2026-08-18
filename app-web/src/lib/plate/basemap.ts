/**
 * THE BASEMAP — self-hosted, and audibly so.
 *
 * DESIGN.md §9.1:
 *
 * > "Self-hosted Protomaps `.pmtiles`. One static archive on object storage,
 * > read directly by MapLibre GL over HTTP range requests via the `pmtiles://`
 * > protocol. No tile server, no API key, no rate limit, and — decisively for
 * > this project — NO COMMERCIAL VENDOR RECEIVING A LOG OF WHICH COORDINATES A
 * > READER OF A REGISTER OF FEDERAL FACILITIES PANNED TO. That is a privacy
 * > decision before it is a design one."
 *
 * §20 says the same thing from the other end: a vendor basemap token is
 * rejected, and "self-hosted PMTiles is real ops work and it is the correct
 * trade."
 *
 * There is therefore exactly ONE tile origin in this file — the deployment's
 * own origin — and no code path anywhere in the plate that reaches a third
 * party. `assertNoVendorHost()` is called on every archive URL before it is
 * handed to MapLibre, and `plate:check` runs it over the manifest.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * THE ARCHIVES ARE NOT IN THIS REPOSITORY. THIS IS A DOCUMENTED GAP.
 *
 * A CONUS Protomaps extract is ~1–3 GB and a terrain-RGB set is larger; neither
 * belongs in git, and neither can be fetched from this build environment, which
 * has no general internet egress. The plate is built to run against local files
 * at the paths below, and when they are absent it SAYS SO ON THE PLATE — see
 * `BASEMAP_ABSENT_NOTE`. It does not silently fall back to a vendor, and it
 * does not render a blank grey rectangle: ground, graticule, furniture, legend
 * and every overlay still draw, because §18 is explicit that "a blank grey
 * rectangle would be the failure; a correctly furnished empty plate is a
 * finished object."
 *
 * `public/basemap/README.md` carries the acquisition commands.
 * ─────────────────────────────────────────────────────────────────────────────
 */

export interface ArchiveSpec {
  /** MapLibre source id. */
  id: string;
  /** Path under the deployment's own origin. Never absolute, never a vendor. */
  path: string;
  kind: "vector" | "raster-dem" | "glyphs";
  required: boolean;
  /** What the plate loses when this archive is absent. Printed, not swallowed. */
  carries: string;
  /** How to obtain it. Printed in the plate's credit block and in the README. */
  acquisition: string;
  attribution: string;
}

/**
 * §9.2 — "three quiet layers": structure, terrain, land status. Plus PLSS,
 * which "no consumer map draws" and which pre-1970 federal records locate by.
 */
export const ARCHIVES: ArchiveSpec[] = [
  {
    id: "protomaps",
    path: "/basemap/us.pmtiles",
    kind: "vector",
    required: true,
    carries:
      "coastline, state and county lines, the road hairline, hydrography and place labels",
    acquisition:
      "pmtiles extract https://build.protomaps.com/<YYYYMMDD>.pmtiles us.pmtiles " +
      '--maxzoom=14 --bbox="-125.0,24.0,-66.5,49.5"',
    attribution: "© OpenStreetMap contributors (ODbL). Basemap tiles by Protomaps.",
  },
  {
    id: "terrain",
    path: "/basemap/us-terrain.pmtiles",
    kind: "raster-dem",
    required: false,
    carries:
      "the hillshade — the only basemap element carrying analytic meaning, because " +
      "this register is about holes in the ground and relief is subject matter",
    acquisition:
      "Build terrain-RGB from USGS 3DEP 1/3 arc-second (or SRTM 30 m) with " +
      "rio-rgbify, then pack with `pmtiles convert`. Max zoom 12 is sufficient at " +
      "5–9% contrast.",
    attribution: "Elevation: USGS 3DEP / NASA SRTM, public domain.",
  },
  {
    id: "padus",
    path: "/basemap/padus.pmtiles",
    kind: "vector",
    required: false,
    carries:
      "land-status boundaries — LOAD-BEARING, NOT SCENERY: reference class RC1–RC6 " +
      "is assigned from land status, so a reader who cannot see the boundary cannot " +
      "check the base-rate reading published on the entry page",
    acquisition:
      "USGS PAD-US 4.0 geodatabase → filter to federal manager types (DOD, DOE, BLM, " +
      "USFS, NPS, FWS) → tippecanoe -z10 → pmtiles convert.",
    attribution: "Land status: USGS Protected Areas Database of the United States (PAD-US).",
  },
  {
    id: "plss",
    path: "/basemap/plss.pmtiles",
    kind: "vector",
    required: false,
    carries: "the PLSS township/range grid at z≥13, which pre-1970 federal records locate by",
    acquisition:
      "BLM PLSS CadNSDI township and section polygons → tippecanoe -Z11 -z14 → pmtiles convert.",
    attribution: "PLSS: Bureau of Land Management CadNSDI.",
  },
  {
    /**
     * §2 — "No Google Fonts request." That decision does not stop at the HTML:
     * MapLibre renders map labels from signed-distance-field glyph PBFs, and the
     * default fontstack URL in every tutorial is a vendor endpoint. The plate
     * serves its own, generated from the same IBM Plex Sans the page uses, so
     * the labels on the plate are literally the same typeface as the labels
     * beside it. If the directory is absent, THE LABEL LAYERS ARE NOT ADDED AT
     * ALL rather than falling back to a hosted stack.
     */
    id: "glyphs",
    path: "/basemap/fonts/IBM%20Plex%20Sans%20Regular/0-255.pbf",
    kind: "glyphs",
    required: false,
    carries: "map label typography — place, county and hydrography labels",
    acquisition:
      "npx font-maker (or fontnik/genfontgl) over node_modules/@fontsource-variable/" +
      "ibm-plex-sans/files/*.woff2 → /basemap/fonts/IBM Plex Sans Regular/{range}.pbf " +
      "and .../IBM Plex Sans Italic/{range}.pbf",
    attribution: "Labels set in IBM Plex Sans (SIL OFL 1.1), self-hosted.",
  },
];

/** The fontstack URL template. Origin-relative, always. */
export const GLYPHS_URL = "/basemap/fonts/{fontstack}/{range}.pbf";

export const BASEMAP_ABSENT_NOTE =
  "BASEMAP ARCHIVE ABSENT. This deployment carries no local .pmtiles archive, so " +
  "hillshade, land status, coastline, county lines and place labels do not draw. " +
  "Ground, graticule, plate furniture and every uncertainty overlay draw as " +
  "specified. No vendor basemap is substituted: a register that will not send a " +
  "reader's coordinates to a third party does not do so as a fallback either.";

/**
 * The refusal, executable. §9.1 and §20 ban a vendor tile origin outright; this
 * runs on every URL before MapLibre sees it, so the ban survives a well-meaning
 * edit that "just adds a fallback for local development."
 */
const VENDOR_HOSTS = [
  "mapbox.com",
  "mapbox.cn",
  "googleapis.com",
  "google.com",
  "arcgis.com",
  "esri.com",
  "maptiler.com",
  "stadiamaps.com",
  "carto.com",
  "cartocdn.com",
  "thunderforest.com",
  "openfreemap.org",
  "protomaps.com",
  "tile.openstreetmap.org",
];

export function assertNoVendorHost(url: string): void {
  if (url.startsWith("/") || url.startsWith("pmtiles:///")) return;
  let host: string;
  try {
    host = new URL(url, "http://localhost").hostname.toLowerCase();
  } catch {
    throw new Error(`plate/basemap: unparseable tile URL ${url}`);
  }
  if (host === "localhost" || host === "127.0.0.1") return;
  for (const v of VENDOR_HOSTS) {
    if (host === v || host.endsWith(`.${v}`)) {
      throw new Error(
        `plate/basemap: ${host} is a vendor tile origin. DESIGN.md §9.1 and §20 ` +
          `forbid it — a vendor receives a log of which coordinates a reader of a ` +
          `register of federal facilities panned to.`,
      );
    }
  }
}

/** `pmtiles://` + an origin-relative path. The only URL form the plate builds. */
export function pmtilesUrl(a: ArchiveSpec): string {
  assertNoVendorHost(a.path);
  return `pmtiles://${a.path}`;
}

export type ArchiveAvailability = Record<string, boolean>;

/**
 * Probe by range request — the same 16 bytes the PMTiles reader would ask for.
 * A miss is a fact about this deployment and it gets published on the plate,
 * not logged to a console nobody reads.
 */
export async function probeArchives(
  specs: ArchiveSpec[] = ARCHIVES,
  fetchImpl: typeof fetch = fetch,
): Promise<ArchiveAvailability> {
  const entries = await Promise.all(
    specs.map(async (a) => {
      try {
        const res = await fetchImpl(a.path, {
          headers: { Range: "bytes=0-15" },
          cache: "force-cache",
        });
        return [a.id, res.ok || res.status === 206] as const;
      } catch {
        return [a.id, false] as const;
      }
    }),
  );
  return Object.fromEntries(entries);
}

/** The plate credit line. OSM ODbL attribution prints here (§9.1, §13.8). */
export function creditLine(available: ArchiveAvailability): string {
  const present = ARCHIVES.filter((a) => available[a.id]);
  if (present.length === 0) return "No basemap archive loaded. Overlays and graticule only.";
  return present.map((a) => a.attribution).join(" ");
}
