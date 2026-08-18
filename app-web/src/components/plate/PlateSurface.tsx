"use client";

/**
 * THE SURFACE — MapLibre GL over self-hosted PMTiles, and nothing else.
 *
 * DESIGN.md §9.1, §9.5, §17. Four constraints are enforced in the map options
 * below and each of them is a sentence in the specification, not a preference:
 *
 *   · `addProtocol("pmtiles", …)` and NO other protocol. Tiles come from this
 *     deployment's own origin by HTTP range request. No token, no vendor, no
 *     log of which coordinates a reader panned to (§9.1, §20).
 *   · `attributionControl: false` — the OSM ODbL credit is printed in the plate
 *     credit block as plate furniture, where a chart puts it, not in a floating
 *     widget with a rounded corner (§5, §9.6, §13.8).
 *   · Rotation and pitch DISABLED. A rotated plate has no north tick and a
 *     pitched one has no scale. This is a plate, not a camera.
 *   · `fadeDuration: 0` and `jumpTo` everywhere — "No fly-to. No camera easing.
 *     Transitions ≤120ms, opacity only. AN INSTRUMENT DOES NOT PERFORM." (§9.5)
 */

import { useEffect, useRef, useState } from "react";
import maplibregl, { type Map as MapLibreMap } from "maplibre-gl";
import { Protocol } from "pmtiles";
import "maplibre-gl/dist/maplibre-gl.css";

import { buildStyle, readTokens } from "@/lib/plate/style";
import { probeArchives, type ArchiveAvailability } from "@/lib/plate/basemap";
import type { ScreenPoint } from "@/lib/plate/geometry";

export interface PlateView {
  centre: [number, number];
  zoom: number;
  bounds: { west: number; south: number; east: number; north: number };
  width: number;
  height: number;
}

export interface PlateSurfaceProps {
  initial: { centre: [number, number]; zoom: number };
  onView: (v: PlateView) => void;
  onArchives: (a: ArchiveAvailability) => void;
  /** Rendered above the canvas, in screen space. The overlay lives here. */
  children: (project: (lngLat: [number, number]) => ScreenPoint) => React.ReactNode;
}

let protocolRegistered = false;

function registerPmtiles() {
  if (protocolRegistered) return;
  const protocol = new Protocol();
  maplibregl.addProtocol("pmtiles", protocol.tile);
  protocolRegistered = true;
}

export function PlateSurface({ initial, onView, onArchives, children }: PlateSurfaceProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<MapLibreMap | null>(null);
  const [ready, setReady] = useState(false);
  /** Bumped on every map move so the overlay reprojects. */
  const [, setFrame] = useState(0);

  useEffect(() => {
    const container = containerRef.current;
    if (!container || mapRef.current) return;

    registerPmtiles();

    let cancelled = false;
    let map: MapLibreMap | null = null;
    let cleanup: (() => void) | null = null;

    void (async () => {
      const available = await probeArchives();
      if (cancelled) return;
      onArchives(available);

      const dark = prefersDark();
      map = new maplibregl.Map({
        container,
        style: buildStyle({ tokens: readTokens(dark), available, dark }),
        center: initial.centre,
        zoom: initial.zoom,
        minZoom: 2,
        maxZoom: 15,
        attributionControl: false,
        /* A plate has one orientation. */
        dragRotate: false,
        pitchWithRotate: false,
        touchPitch: false,
        /* An instrument does not perform. */
        fadeDuration: 0,
      });
      map.touchZoomRotate.disableRotation();
      map.keyboard.disableRotation();
      mapRef.current = map;

      const report = () => {
        if (!map) return;
        const b = map.getBounds();
        const c = map.getCenter();
        onView({
          centre: [c.lng, c.lat],
          zoom: map.getZoom(),
          bounds: { west: b.getWest(), south: b.getSouth(), east: b.getEast(), north: b.getNorth() },
          width: container.clientWidth,
          height: container.clientHeight,
        });
        setFrame((n) => n + 1);
      };

      map.on("load", () => {
        if (cancelled) return;
        setReady(true);
        report();
      });
      map.on("move", report);
      map.on("resize", report);

      /* The style is built from the page's own tokens, so a theme change
         rebuilds it rather than maintaining a second palette by hand. */
      const mq = window.matchMedia("(prefers-color-scheme: dark)");
      const onTheme = () => {
        if (!map) return;
        const d = prefersDark();
        map.setStyle(buildStyle({ tokens: readTokens(d), available, dark: d }));
      };
      mq.addEventListener("change", onTheme);
      const observer = new MutationObserver(onTheme);
      observer.observe(document.documentElement, {
        attributes: true,
        attributeFilter: ["data-theme"],
      });
      cleanup = () => {
        mq.removeEventListener("change", onTheme);
        observer.disconnect();
      };
    })();

    return () => {
      cancelled = true;
      cleanup?.();
      map?.remove();
      mapRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const project = (lngLat: [number, number]): ScreenPoint => {
    const map = mapRef.current;
    if (!map) return { x: NaN, y: NaN };
    const p = map.project(lngLat);
    return { x: p.x, y: p.y };
  };

  return (
    <div className="plate-surface">
      <div className="plate-canvas" ref={containerRef} />
      {ready && children(project)}
      {!ready && (
        /* §17 — "Loading renders a 1px rule and the word `retrieving…` in Mono
           --ink-3." No skeleton, no shimmer, no spinner. */
        <div className="plate-retrieving voice-mono">retrieving…</div>
      )}
    </div>
  );
}

function prefersDark(): boolean {
  if (typeof document === "undefined") return false;
  const explicit = document.documentElement.getAttribute("data-theme");
  if (explicit === "dark") return true;
  if (explicit === "light") return false;
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}
