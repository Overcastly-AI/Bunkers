/**
 * THE PLATE STYLE — three quiet layers (DESIGN.md §9.2).
 *
 * > "The plate is a ground, and the uncertainty overlays are always the loudest
 * > marks on it. If a basemap feature ever competes with an overlay for
 * > attention, the style is wrong."
 *
 * Every colour in this file is read from the CSS custom properties in
 * `tokens.css` at build time, with the literal token values as fallbacks for
 * server rendering. MapLibre cannot read `var(--field)`, but the tokens stay
 * authoritative: a change to §4 or §11 propagates into the map without a second
 * edit, and the dark theme is handled by rebuilding the style when the media
 * query changes rather than by a second hand-written palette.
 *
 * WHAT IS DELIBERATELY NOT HERE: no POIs, no landuse fills, no green parks, no
 * blue water polygons, no road casings, no sprite sheet (a sprite is an icon
 * set, and §5 permits no icon set beyond the nine apparatus glyphs), no 3D, no
 * sky, no vendor source of any kind.
 */

import type { StyleSpecification, LayerSpecification } from "maplibre-gl";
import { ARCHIVES, GLYPHS_URL, pmtilesUrl, type ArchiveAvailability } from "./basemap";

/* ====================================================================== *
 * Tokens
 * ====================================================================== */

export interface PlateTokens {
  field: string;
  ink: string;
  ink2: string;
  ink3: string;
  ink4: string;
  rule: string;
  ruleStrong: string;
  link: string;
  paper: string;
  paperSunk: string;
  undercut: string;
}

const LIGHT: PlateTokens = {
  field: "#E9E6DC",
  ink: "#1A1A17",
  ink2: "#45433C",
  ink3: "#6E6B62",
  ink4: "#8E8B81",
  rule: "#D5D2C9",
  ruleStrong: "#6E6B62",
  link: "#1A4E7A",
  paper: "#FAFAF8",
  paperSunk: "#F1F0EB",
  undercut: "#8A4B0F",
};

const DARK: PlateTokens = {
  field: "#16150F",
  ink: "#F0EFE7",
  ink2: "#B8B5AA",
  ink3: "#85827A",
  ink4: "#6C6961",
  rule: "#2E2D28",
  ruleStrong: "#85827A",
  link: "#8CBBE0",
  paper: "#121210",
  paperSunk: "#1B1B18",
  undercut: "#D9A054",
};

/**
 * Read the live values off `:root` so the map ground and the page ground are
 * the same decision. Falls back to the literals above when there is no DOM
 * (server render, `plate:check`).
 */
export function readTokens(dark = false): PlateTokens {
  const base = dark ? DARK : LIGHT;
  if (typeof document === "undefined") return base;
  const cs = getComputedStyle(document.documentElement);
  const pick = (name: string, fallback: string) => {
    const v = cs.getPropertyValue(name).trim();
    return v.length > 0 ? v : fallback;
  };
  return {
    field: pick("--field", base.field),
    ink: pick("--ink", base.ink),
    ink2: pick("--ink-2", base.ink2),
    ink3: pick("--ink-3", base.ink3),
    ink4: pick("--ink-4", base.ink4),
    rule: pick("--rule", base.rule),
    ruleStrong: pick("--rule-strong", base.ruleStrong),
    link: pick("--link", base.link),
    paper: pick("--paper", base.paper),
    paperSunk: pick("--paper-sunk", base.paperSunk),
    undercut: pick("--undercut", base.undercut),
  };
}

/* ====================================================================== *
 * The style
 * ====================================================================== */

const SANS = ["IBM Plex Sans Regular"];
const SANS_ITALIC = ["IBM Plex Sans Italic", "IBM Plex Sans Regular"];

export interface StyleOptions {
  tokens: PlateTokens;
  available: ArchiveAvailability;
  dark: boolean;
}

export function buildStyle({ tokens, available, dark }: StyleOptions): StyleSpecification {
  const sources: StyleSpecification["sources"] = {};
  const layers: LayerSpecification[] = [];

  const have = (id: string) => available[id] === true;

  for (const a of ARCHIVES) {
    if (a.kind === "glyphs" || !have(a.id)) continue;
    sources[a.id] =
      a.kind === "raster-dem"
        ? { type: "raster-dem", url: pmtilesUrl(a), tileSize: 512, encoding: "mapbox" }
        : { type: "vector", url: pmtilesUrl(a) };
  }

  /* ---- Ground. Always drawn, archives or none. ------------------------ *
   * §11: "--field is the map ground and is deliberately one step
   * warmer/darker than --paper, so the plate reads as a plotted sheet laid on
   * the page rather than as a hole in it." */
  layers.push({
    id: "ground",
    type: "background",
    paint: { "background-color": tokens.field },
  });

  if (have("protomaps")) {
    layers.push({
      id: "earth",
      type: "fill",
      source: "protomaps",
      "source-layer": "earth",
      paint: { "fill-color": tokens.field },
    });
  }

  /* ---- 1. TERRAIN HILLSHADE ------------------------------------------- *
   * §9.2: "The only basemap element carrying analytic meaning: this register
   * is about holes in the ground, so relief is subject matter, not
   * decoration." 5–9% contrast, and nothing louder. */
  if (have("terrain")) {
    layers.push({
      id: "hillshade",
      type: "hillshade",
      source: "terrain",
      paint: {
        "hillshade-exaggeration": dark ? 0.1 : 0.08,
        "hillshade-shadow-color": dark ? "#000000" : tokens.ink2,
        "hillshade-highlight-color": dark ? tokens.ink3 : tokens.paper,
        "hillshade-accent-color": tokens.field,
        "hillshade-illumination-direction": 315,
      },
    });
  }

  /* ---- 3. MINIMAL STRUCTURE — hydrography ----------------------------- *
   * §9.2: "Hydrography in --link hairline, 4% fill, labels in Sans italic
   * --ink-3." The 4% fill is the ONE translucent area fill on the plate and it
   * is basemap, not evidence: §8.2's ban on translucent fills is a rule about
   * UNCERTAINTY REGIONS, whose overlap must not composite into false
   * corroboration. Two rivers overlapping do not assert anything. */
  if (have("protomaps")) {
    layers.push({
      id: "water-area",
      type: "fill",
      source: "protomaps",
      "source-layer": "water",
      paint: { "fill-color": tokens.link, "fill-opacity": 0.04 },
    });
    layers.push({
      id: "water-line",
      type: "line",
      source: "protomaps",
      "source-layer": "water",
      filter: ["==", ["geometry-type"], "LineString"],
      paint: { "line-color": tokens.link, "line-width": 0.6 },
    });

    /* Roads. ALL ONE HAIRLINE in --rule — 1.2px motorway, 0.6px everything
     * else. No casings, no fills. "Roads exist to make terrain legible."
     * They fade above z10 so they never compete with an overlay. */
    layers.push({
      id: "roads",
      type: "line",
      source: "protomaps",
      "source-layer": "roads",
      paint: {
        "line-color": tokens.rule,
        "line-width": ["case", ["==", ["get", "kind"], "highway"], 1.2, 0.6],
        "line-opacity": ["interpolate", ["linear"], ["zoom"], 6, 0.9, 10, 0.55, 13, 0.35],
      },
    });

    /* Coastline, state and county lines. County because the register's
     * jurisdiction column is county-level. */
    layers.push({
      id: "boundaries",
      type: "line",
      source: "protomaps",
      "source-layer": "boundaries",
      paint: {
        "line-color": tokens.ruleStrong,
        "line-width": [
          "case",
          ["==", ["get", "kind"], "country"],
          1,
          ["==", ["get", "kind"], "region"],
          0.7,
          0.4,
        ],
        "line-opacity": 0.55,
      },
    });
  }

  /* ---- 2. LAND STATUS — LOAD-BEARING, NOT SCENERY --------------------- *
   * §9.2: "Reference class RC1–RC6 is assigned from land status, and the
   * base-rate reading follows from the reference class. The basemap must let a
   * reader SEE the reference class, or the base-rate reading published on the
   * entry page is an unverifiable assertion. A candidate sitting just outside
   * an installation boundary is RC2, not RC1."
   *
   * 0.5px hairlines at 20% ink. No fill: a filled installation polygon would
   * be an area wash competing with the uncertainty overlays, and it would read
   * as a choropleth value. */
  if (have("padus")) {
    layers.push({
      id: "land-status",
      type: "line",
      source: "padus",
      "source-layer": "padus",
      paint: { "line-color": tokens.ink, "line-width": 0.5, "line-opacity": 0.2 },
    });
  }

  /* PLSS township/range grid at z≥13. "No consumer map draws it." */
  if (have("plss")) {
    layers.push({
      id: "plss",
      type: "line",
      source: "plss",
      "source-layer": "plss",
      minzoom: 13,
      paint: { "line-color": tokens.ink, "line-width": 0.4, "line-opacity": 0.18 },
    });
  }

  /* ---- Labels. Only if the self-hosted glyphs are present. ------------ */
  if (have("protomaps") && have("glyphs")) {
    layers.push({
      id: "water-label",
      type: "symbol",
      source: "protomaps",
      "source-layer": "water",
      minzoom: 6,
      layout: {
        "text-field": ["get", "name"],
        "text-font": SANS_ITALIC,
        "text-size": 11,
        "text-letter-spacing": 0.02,
      },
      paint: {
        "text-color": tokens.ink3,
        "text-halo-color": tokens.field,
        "text-halo-width": 1,
      },
    });
    layers.push({
      id: "places",
      type: "symbol",
      source: "protomaps",
      "source-layer": "places",
      layout: {
        "text-field": ["get", "name"],
        "text-font": SANS,
        "text-size": ["interpolate", ["linear"], ["zoom"], 4, 10, 12, 12.5],
        "text-letter-spacing": 0.02,
      },
      paint: {
        "text-color": tokens.ink3,
        "text-halo-color": tokens.field,
        "text-halo-width": 1,
      },
    });
  }

  /*
    Self-hosted, or absent. There is no third option.

    The key is OMITTED rather than set to `undefined` when the glyph archive is
    absent, and that distinction is load-bearing rather than stylistic. A style
    object carrying `glyphs: undefined` still has the property, so MapLibre's
    validator sees the key, reports `glyphs: string expected, undefined found`,
    and aborts the style load — which means the map never fires `load` and the
    surface sits in its `retrieving…` state forever. The plate then renders as a
    blank rectangle beside a fully furnished panel, which is precisely the
    failure §18 names: "a blank grey rectangle would be the failure; a correctly
    furnished empty plate is a finished object."

    `sprite` is omitted for the same reason. Nothing on this plate is a sprite —
    §5 permits no icon set beyond the apparatus glyphs — so the key has no
    business existing at all.
  */
  const style: StyleSpecification = {
    version: 8,
    sources,
    layers,
  } as StyleSpecification;

  if (have("glyphs")) {
    (style as { glyphs?: string }).glyphs = GLYPHS_URL;
  }

  return style;
}
