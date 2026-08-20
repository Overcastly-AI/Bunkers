# PLATE I — THE BASEMAP ARCHIVES

**Status, 2026-08-20: `us.pmtiles` is live.** Built by `.github/workflows/basemap.yml`
(CONUS, maxzoom 12, 1.9 GB, Protomaps daily build), published to Vercel Blob, and served
under `/basemap/*` by the rewrite in `next.config.ts` when `BASEMAP_ORIGIN` is set. The
files are still not in this repository — that part remains by design.

**None of the files described here are in this repository, and that is the documented
state, not an oversight.** They are between 200 MB and several GB, they are rebuilt on a
cadence rather than versioned with the source, and the environment this application was
built in has no general internet egress. `/plate` is built to run against them at the
paths below; when they are absent it **says so on the plate** (see `BASEMAP_ABSENT_NOTE`
in `src/lib/plate/basemap.ts`) and draws ground, graticule, furniture, legend and every
uncertainty overlay regardless.

**No vendor fallback is provided, and adding one would be a specification violation.**
DESIGN.md §9.1 and §20:

> A vendor basemap token (Mapbox, Google, Esri). Beyond the licensing and repricing risk:
> it sends a log of which coordinates a reader of a register of federal facilities panned
> to, to a third party. Self-hosted PMTiles is real ops work and it is the correct trade.

`assertNoVendorHost()` runs over every tile URL before MapLibre sees it and throws on a
known vendor host. `npm run plate:check` runs it over the whole manifest.

---

## The files

| path | required | what the plate loses without it |
|---|---|---|
| `public/basemap/us.pmtiles` | **yes** | coastline, state and county lines, the road hairline, hydrography, place labels |
| `public/basemap/us-terrain.pmtiles` | no | the hillshade — the only basemap element carrying analytic meaning |
| `public/basemap/padus.pmtiles` | no | land-status boundaries, which are how a reader checks the reference class |
| `public/basemap/plss.pmtiles` | no | the PLSS township/range grid at z≥13 |
| `public/basemap/fonts/{fontstack}/{range}.pbf` | no | all map label typography |

Presence is probed at runtime with a 16-byte range request — the same bytes the PMTiles
reader asks for — and a miss is published in the panel rather than logged to a console.

---

## 1. `us.pmtiles` — the Protomaps basemap

Protomaps publishes a daily planet build. Extract CONUS from it; do not serve the planet.

```sh
# Once, to get the tool:
#   https://github.com/protomaps/go-pmtiles/releases
pmtiles extract https://build.protomaps.com/20260801.pmtiles us.pmtiles \
  --maxzoom=14 \
  --bbox="-125.0,24.0,-66.5,49.5"
mv us.pmtiles public/basemap/us.pmtiles
```

DESIGN.md §9.1 specifies **CONUS extract at max-zoom 14, rebuilt monthly against the daily
planet build.** Expect roughly 1–3 GB.

The style reads the source layers `earth`, `water`, `roads`, `boundaries` and `places`. It
adds **no** landuse fill, **no** POI layer and **no** building layer: §9.2 bans all three,
and the ban is enforced by their absence from `src/lib/plate/style.ts` rather than by an
opacity of zero.

### County lines

§9.2 requires county lines "because the register's jurisdiction column is county-level."
The `boundaries` layer in a stock Protomaps extract carries country and region admin
levels; if your extract lacks `kind: "county"` features, build a fifth archive from the
Census TIGER county file and add it as a source — do not substitute a coarser boundary and
call it a county line.

## 2. `us-terrain.pmtiles` — hillshade

§9.2: *"Terrain hillshade at 5–9% contrast, from a self-hosted 3DEP/SRTM terrain-RGB
tileset. The only basemap element carrying analytic meaning: this register is about holes
in the ground, so relief is subject matter, not decoration."*

```sh
# USGS 3DEP 1/3 arc-second, or SRTM 30 m outside its coverage.
rio rgbify -b -10000 -i 0.1 dem.tif terrain-rgb.tif
rio mbtiles terrain-rgb.tif terrain.mbtiles --zoom-levels 0..12 --format PNG
pmtiles convert terrain.mbtiles public/basemap/us-terrain.pmtiles
```

The style uses `encoding: "mapbox"` (the `-10000 / 0.1` parameters above). Exaggeration is
0.08 light / 0.10 dark, which is the 5–9% contrast the specification asks for; **do not
raise it.** A louder hillshade competes with the overlays, and §9.2 is explicit that if a
basemap feature ever competes with an overlay for attention, the style is wrong.

## 3. `padus.pmtiles` — land status

§9.2 calls this **load-bearing, not scenery**:

> Reference class RC1–RC6 is assigned from land status, and the base-rate reading follows
> from the reference class. The basemap must let a reader *see* the reference class, or the
> base-rate reading published on the entry page is an unverifiable assertion. A candidate
> sitting just outside an installation boundary is RC2, not RC1.

```sh
# USGS PAD-US 4.0, Fee + Easement + Proclamation, federal managers only.
ogr2ogr -f GeoJSONSeq padus.geojsonl PADUS4_0.gdb PADUS4_0Fee \
  -where "Mang_Type IN ('DOD','DOE','FED')"
tippecanoe -o padus.mbtiles -z10 -l padus --drop-densest-as-needed padus.geojsonl
pmtiles convert padus.mbtiles public/basemap/padus.pmtiles
```

Drawn as 0.5px hairlines at 20% ink, **with no fill**. A filled installation polygon would
be an area wash competing with the uncertainty overlays and would read as a choropleth
value — the exact misreading §8.2 rejects dot screens in order to avoid.

## 4. `plss.pmtiles` — the township/range grid

§9.2: *"PLSS township/range grid at z≥13, because pre-1970 federal records locate by
section-township-range and no consumer map draws it."*

```sh
# BLM CadNSDI PLSS, townships and first-division sections.
tippecanoe -o plss.mbtiles -Z11 -z14 -l plss plss_sections.geojsonl
pmtiles convert plss.mbtiles public/basemap/plss.pmtiles
```

## 5. `fonts/` — self-hosted glyphs

§2 bans a Google Fonts request for the page. The same decision applies to the map: MapLibre
renders labels from signed-distance-field glyph PBFs, and the default fontstack URL in every
tutorial is a vendor endpoint. Generate them from the IBM Plex Sans already in
`node_modules`, so the labels on the plate are literally the same typeface as the labels
beside it.

```sh
# CORRECTION, 2026-08-20: this file previously specified `npx font-maker …`.
# No package by that name exists on npm — the command was never runnable. The
# real tool is fontnik (0.7.7), which is what MapLibre's own glyph pipelines
# use. It takes TTF/OTF, not the woff2 that @fontsource-variable ships, so a
# conversion step is required.
#
#   1. Obtain IBM Plex Sans as TTF (the upstream IBM/plex release, or convert
#      the woff2 in node_modules with a woff2 decoder).
#   2. Generate the SDF ranges:
#
#        npm i fontnik
#        node -e "
#          const fontnik=require('fontnik'), fs=require('fs');
#          const buf=fs.readFileSync('IBMPlexSans-Regular.ttf');
#          for (let i=0;i<65536;i+=256)
#            fontnik.range({font:buf,start:i,end:i+255},(e,d)=>{
#              if(e) throw e;
#              fs.mkdirSync('public/basemap/fonts/IBM Plex Sans Regular',{recursive:true});
#              fs.writeFileSync(\`public/basemap/fonts/IBM Plex Sans Regular/\${i}-\${i+255}.pbf\`,d);
#            });
#        "
#
# Verified only that the package exists and the woff2 inputs are present; the
# pipeline above has NOT been run end to end here. Treat it as unverified until
# it has been.
```

If the directory is absent the style is built **without the label layers at all** rather
than falling back to a hosted stack. An unlabelled plate is a legible plate; a plate that
quietly phoned a vendor is not.

---

## Serving

`public/` is served by the deployment at its own origin, and PMTiles needs nothing but
HTTP range requests (`Accept-Ranges: bytes`), which every static host supports. There is no
tile server to run, no API key to rotate and no rate limit to negotiate — that is the whole
argument for this format over a hosted one.

If the archives are moved to object storage, keep the paths origin-relative by proxying
them under `/basemap/…` on the same host. `assertNoVendorHost()` permits only
origin-relative paths and localhost; a cross-origin bucket URL will throw, on purpose,
because a cross-origin request is a request a third party can log.

## Checking

```sh
npm run plate:check   # symbolisation, the 16px rule, and the six refusals that reach the map
npm run build
```

`plate:check` asserts, among other things, that every declared archive path is
origin-relative and that a Mapbox URL is *refused rather than warned about*.
