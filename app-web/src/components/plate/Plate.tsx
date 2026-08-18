"use client";

/**
 * PLATE I — the coupled sheet.
 *
 * DESIGN.md §9.7: "The plate is the one page not on the document grid.
 * Desktop: `grid-template-columns: 26rem 1fr` — panel left, surface right, both
 * full-height below the running head. Mobile: 50/50 vertical split, map top,
 * panel bottom, panel draggable to full height."
 *
 * §9.5: "EVERY MAP STATE — bbox, zoom, band filter, class filter, selection —
 * LIVES IN THE URL, because a plate you cannot cite is not a plate."
 *
 * The URL is maintained with `history.replaceState` on movement and
 * `pushState` on selection, with a `popstate` listener, so the back button
 * walks selections rather than the page's own pan history. Movement replaces
 * because a hundred history entries for one drag is not citation, it is noise;
 * selection pushes because a selection is a thing a reader means to return to.
 *
 * WHY THE VIEWPORT IS FETCHED RATHER THAN FILTERED IN THE BROWSER. The
 * clustering rule (§9.3) is server-side and must stay server-side: a client
 * that grouped features would be inventing bins, and a bin is a position claim.
 * `/api/plate/viewport` is a thin pass-through to `Repository.getViewport()`,
 * which is `api.map_viewport` when the register is wired.
 */

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import dynamic from "next/dynamic";
import type { MapCluster, MapFeature } from "@/lib/types/api";
import type { CompetingGeometry, NotLocatableRow } from "@/lib/repository/types";
import type { ArchiveAvailability } from "@/lib/plate/basemap";
import { URL_KEYS } from "@/lib/plate/legend";
import { CLUSTER_MAX_ZOOM } from "@/lib/plate/clusters";
import { PlateOverlay } from "./PlateOverlay";
import { PlatePanel } from "./PlatePanel";
import type { PlateView } from "./PlateSurface";

/**
 * MapLibre GL touches `window` at import time and its WebGL context has no
 * server-side meaning, so the surface is loaded with `ssr: false`. This is not
 * a performance choice: it is what keeps §16's rule true in the emitted HTML —
 * "the entire site works with JavaScript disabled EXCEPT THE MAP CANVAS." The
 * panel beside it is ordinary server-rendered markup and ships in the static
 * output with its legend, its precision table, its projection statement and its
 * NOT LOCATABLE panel intact.
 */
const PlateSurface = dynamic(
  () => import("./PlateSurface").then((m) => m.PlateSurface),
  { ssr: false },
);

/** CONUS, the extent of the register's jurisdiction. Not a camera position. */
const DEFAULT_VIEW: PlateView = {
  centre: [-98.5, 39.5],
  zoom: 3.6,
  bounds: { west: -126, south: 23, east: -66, north: 50 },
  width: 0,
  height: 0,
};

export interface PlateProps {
  initialFeatures: MapFeature[];
  initialClusters: MapCluster[];
  notLocatable: NotLocatableRow[];
  excludedBelowD: number;
}

export function Plate({
  initialFeatures,
  initialClusters,
  notLocatable,
  excludedBelowD,
}: PlateProps) {
  const [view, setView] = useState<PlateView>(DEFAULT_VIEW);
  const [initialView, setInitialView] = useState<PlateView | null>(null);
  const [archives, setArchives] = useState<ArchiveAvailability>({});
  const [features, setFeatures] = useState<MapFeature[]>(initialFeatures);
  const [clusters, setClusters] = useState<MapCluster[]>(initialClusters);
  const [selectedSlug, setSelectedSlug] = useState<string | null>(null);
  const [competing, setCompeting] = useState<CompetingGeometry[]>([]);
  const [exceeds, setExceeds] = useState(false);
  const fetchTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  /* ---- URL → state, once, and on every popstate. ---------------------- */
  useEffect(() => {
    const apply = () => {
      const p = new URLSearchParams(window.location.search);
      const v = parseView(p) ?? DEFAULT_VIEW;
      setInitialView(v);
      setView(v);
      setSelectedSlug(p.get(URL_KEYS.selection));
    };
    apply();
    window.addEventListener("popstate", apply);
    return () => window.removeEventListener("popstate", apply);
  }, []);

  /* ---- state → URL. ---------------------------------------------------- */
  useEffect(() => {
    if (!initialView) return;
    const p = new URLSearchParams(window.location.search);
    p.set(URL_KEYS.centre, `${view.centre[0].toFixed(5)},${view.centre[1].toFixed(5)}`);
    p.set(URL_KEYS.zoom, view.zoom.toFixed(2));
    p.set(
      URL_KEYS.bbox,
      [view.bounds.west, view.bounds.south, view.bounds.east, view.bounds.north]
        .map((n) => n.toFixed(4))
        .join(","),
    );
    if (selectedSlug) p.set(URL_KEYS.selection, selectedSlug);
    else p.delete(URL_KEYS.selection);
    window.history.replaceState(null, "", `${window.location.pathname}?${p.toString()}`);
  }, [view, selectedSlug, initialView]);

  /* ---- viewport → rows. Server-side clustering, always. ---------------- */
  useEffect(() => {
    if (!initialView || view.width === 0) return;
    if (fetchTimer.current) clearTimeout(fetchTimer.current);
    fetchTimer.current = setTimeout(() => {
      const q = new URLSearchParams({
        west: String(view.bounds.west),
        south: String(view.bounds.south),
        east: String(view.bounds.east),
        north: String(view.bounds.north),
        zoom: String(view.zoom),
      });
      void fetch(`/api/plate/viewport?${q.toString()}`)
        .then((r) => (r.ok ? r.json() : null))
        .then((json: { mode: string; features?: MapFeature[]; clusters?: MapCluster[] } | null) => {
          if (!json) return;
          setFeatures(json.features ?? []);
          setClusters(json.clusters ?? []);
        })
        .catch(() => {
          /* A failed viewport read leaves the last drawn state in place rather
             than clearing the plate: an empty plate is a statement ("0
             features") and it must not be produced by a network error. */
        });
    }, 180);
    return () => {
      if (fetchTimer.current) clearTimeout(fetchTimer.current);
    };
  }, [view, initialView]);

  /* ---- selection → competing geometry, drawn all at once. -------------- */
  useEffect(() => {
    if (!selectedSlug) {
      setCompeting([]);
      return;
    }
    void fetch(`/api/plate/geometry-assertions?slug=${encodeURIComponent(selectedSlug)}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((json: CompetingGeometry[] | null) => setCompeting(json ?? []))
      .catch(() => setCompeting([]));
  }, [selectedSlug]);

  const onSelect = useCallback((slug: string | null) => {
    setSelectedSlug(slug);
    const p = new URLSearchParams(window.location.search);
    if (slug) p.set(URL_KEYS.selection, slug);
    else p.delete(URL_KEYS.selection);
    window.history.pushState(null, "", `${window.location.pathname}?${p.toString()}`);
  }, []);

  const selected = useMemo(
    () => features.find((f) => f.slug === selectedSlug) ?? null,
    [features, selectedSlug],
  );

  const listViewHref = useMemo(() => {
    const p = new URLSearchParams();
    p.set(
      URL_KEYS.bbox,
      [view.bounds.west, view.bounds.south, view.bounds.east, view.bounds.north]
        .map((n) => n.toFixed(4))
        .join(","),
    );
    p.set(URL_KEYS.view, "list");
    return `/?${p.toString()}`;
  }, [view.bounds]);

  return (
    <div className="plate">
      <PlatePanel
        features={features}
        notLocatable={notLocatable}
        excludedBelowD={excludedBelowD}
        selected={selected}
        onSelect={onSelect}
        archives={archives}
        view={{ centre: view.centre, zoom: view.zoom }}
        listViewHref={listViewHref}
        exceedsViewport={exceeds}
      />

      {initialView ? (
        <PlateSurface
          initial={{ centre: initialView.centre, zoom: initialView.zoom }}
          onView={setView}
          onArchives={setArchives}
        >
          {(project) => (
            <PlateOverlay
              width={view.width}
              height={view.height}
              zoom={view.zoom}
              bounds={view.bounds}
              project={project}
              features={features}
              clusters={view.zoom <= CLUSTER_MAX_ZOOM ? clusters : []}
              competing={competing}
              selectedSlug={selectedSlug}
              onSelect={onSelect}
              onExceedsViewport={setExceeds}
            />
          )}
        </PlateSurface>
      ) : (
        /* Server render and first paint. The panel above is complete markup and
           is readable here; the surface is the one part that waits.

           The <noscript> lives in THIS branch, not inside PlateSurface, because
           PlateSurface is loaded with `ssr: false` and therefore contributes
           nothing to the static HTML — a no-script notice that only exists once
           script has run is not a notice. §16's exemption is stated where a
           reader without JavaScript will actually encounter it. */
        <div className="plate-surface">
          <div className="plate-canvas plate-canvas-idle" />
          <noscript>
            <div className="plate-noscript">
              The plate surface is the one part of this register that requires
              JavaScript. Everything it would tell you about these features — the
              legend at true size, the precision table, the chart abbreviations,
              the scale and projection statement, the NOT LOCATABLE panel and the
              catalogue itself — is in this page&rsquo;s markup beside it, and in
              the register at <a href="/">/</a>.
            </div>
          </noscript>
        </div>
      )}
    </div>
  );
}

function parseView(p: URLSearchParams): PlateView | null {
  const c = p.get(URL_KEYS.centre);
  const z = p.get(URL_KEYS.zoom);
  const bbox = p.get(URL_KEYS.bbox);
  if (!c || !z) return null;
  const [lng, lat] = c.split(",").map(Number);
  const zoom = Number(z);
  if (!isFinite(lng!) || !isFinite(lat!) || !isFinite(zoom)) return null;
  const b = bbox?.split(",").map(Number);
  return {
    centre: [lng!, lat!],
    zoom,
    bounds:
      b && b.length === 4 && b.every((n) => isFinite(n))
        ? { west: b[0]!, south: b[1]!, east: b[2]!, north: b[3]! }
        : DEFAULT_VIEW.bounds,
    width: 0,
    height: 0,
  };
}
