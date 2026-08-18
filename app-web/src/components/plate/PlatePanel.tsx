"use client";

/**
 * THE COUPLED PANEL — legend, furniture, selection, and the unmappable.
 *
 * DESIGN.md §9.5: "Selecting a feature does NOT open a popup floating over the
 * map. A popup implies the map is primary and the data is a detail. Selection
 * FILLS THE COUPLED PANEL with that entity's identity block, its
 * scope-and-content sentence and its full stave column, ending `→ open sheet`."
 *
 * §9.7: "Desktop: `grid-template-columns: 26rem 1fr` — panel left, surface
 * right… NEVER A FULL-BLEED MAP WITH A FLOATING SHEET — the coupling is the
 * point."
 *
 * §9.6: the legend is "open by default on desktop, in the panel, above the fold
 * — on a chart the legend is PRINTED ON THE PLATE, not hidden behind a `?`."
 * There is no disclosure control on it and no way to dismiss it.
 */

import type { MapFeature } from "@/lib/types/api";
import type { NotLocatableRow } from "@/lib/repository/types";
import {
  chartTags,
  CHART_TAG_CONDITION,
  CHART_TAG_EXPANSION,
  INT1_CITATION,
  type ChartTag,
} from "@/lib/plate/chart-tags";
import {
  emptyPlateAnnotation,
  legendRows,
  NOT_LOCATABLE_HEADING,
  NOT_LOCATABLE_NOTE,
  publicationGateNote,
} from "@/lib/plate/legend";
import { GradeLetterWord } from "@/components/Stave";
import { CLUSTER_BREAKDOWN_UNAVAILABLE } from "@/lib/plate/clusters";
import { markForFeature } from "@/lib/plate/precision";
import { BASEMAP_ABSENT_NOTE, creditLine, type ArchiveAvailability } from "@/lib/plate/basemap";
import { DOT_SCREEN_FEATURE_CEILING, EXCEEDS_VIEWPORT_NOTE } from "@/lib/plate/geometry";
import { NorthTick, PlateHead, ProjectionStatement, ScaleBar } from "./PlateFurniture";
import {
  BelowThresholdSymbol,
  ClusterSymbol,
  CompetingSymbol,
  PlateSymbol,
} from "./PlateSymbol";

const CHART_TAG_ORDER: ChartTag[] = ["ED", "PD", "PA", "Rep"];

export interface PlatePanelProps {
  features: MapFeature[];
  notLocatable: NotLocatableRow[];
  /** BES §10.3 — candidates held below band D, counted so the omission is stated. */
  excludedBelowD: number;
  selected: MapFeature | null;
  onSelect: (slug: string | null) => void;
  archives: ArchiveAvailability;
  view: { centre: [number, number]; zoom: number };
  listViewHref: string;
  exceedsViewport: boolean;
}

export function PlatePanel({
  features,
  notLocatable,
  excludedBelowD,
  selected,
  onSelect,
  archives,
  view,
  listViewHref,
  exceedsViewport,
}: PlatePanelProps) {
  const rows = legendRows(features, notLocatable);
  const basemapPresent = archives["protomaps"] === true;

  return (
    <aside className="plate-panel" aria-label="Plate legend and coupled panel">
      <PlateHead zoom={view.zoom} centre={view.centre} />

      {/* §18 — the annotation that makes an empty plate a finished object
          rather than a failure. It prints the real count, which today is 0. */}
      <p className="t-small voice-mono plate-annotation">
        {emptyPlateAnnotation(features.length)}
      </p>

      {/* §9.4 — THE MAP NEVER OMITS WITHOUT SAYING SO. */}
      <p className="t-small plate-gate">
        {publicationGateNote(excludedBelowD)}{" "}
        <a href="/claims">claims register</a>
      </p>

      {!basemapPresent && (
        <div className="flag-block t-small plate-absent">{BASEMAP_ABSENT_NOTE}</div>
      )}

      {exceedsViewport && (
        <p className="t-small plate-margin-note">
          <em>{EXCEEDS_VIEWPORT_NOTE}</em>
        </p>
      )}

      {/* ---------------- SELECTION — the coupling ---------------- */}
      <Selection feature={selected} onClear={() => onSelect(null)} />

      {/* ---------------- THE LEGEND, AS A TABLE ------------------ */}
      <section className="plate-block">
        <h2 className="t-micro plate-block-head">Legend</h2>
        <table className="plate-legend">
          <caption className="t-micro">
            Symbols drawn at true size. Positional vocabulary after U.S. Chart No. 1
            / IHO INT-1.
          </caption>
          <thead>
            <tr>
              <th scope="col">Symbol</th>
              <th scope="col">Precision</th>
              <th scope="col">Meaning</th>
              <th scope="col">n</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={r.key}>
                <td className="plate-legend-symbol">
                  <PlateSymbol
                    representation={r.representation}
                    precision={r.precision}
                    idPrefix={`lg-${r.key.replace(/[^a-z0-9]/gi, "")}-`}
                  />
                </td>
                <td className="voice-mono">{r.mark.precisionWord}</td>
                <td>{r.mark.reading}</td>
                <td className="voice-mono plate-n">{r.n}</td>
              </tr>
            ))}
            <tr>
              <td className="plate-legend-symbol">
                <BelowThresholdSymbol idPrefix="lg-thresh-" />
              </td>
              <td className="voice-mono">below 16 px</td>
              <td>
                An area too small to draw at this zoom. The square contains the whole
                extent; it is not a location, and nothing is drawn at its centre.
              </td>
              <td className="voice-mono plate-n">—</td>
            </tr>
            <tr>
              <td className="plate-legend-symbol">
                <ClusterSymbol idPrefix="lg-cluster-" />
              </td>
              <td className="voice-mono">cluster</td>
              <td>
                A count of features in one grid cell, drawn on the cell. {CLUSTER_BREAKDOWN_UNAVAILABLE}
              </td>
              <td className="voice-mono plate-n">—</td>
            </tr>
            <tr>
              <td className="plate-legend-symbol">
                <CompetingSymbol idPrefix="lg-competing-" />
              </td>
              <td className="voice-mono">competing</td>
              <td>
                Two or more sources placing one entity in different positions, drawn
                simultaneously with their origin tiers. No coordinate is averaged.
              </td>
              <td className="voice-mono plate-n">—</td>
            </tr>
          </tbody>
        </table>
      </section>

      {/* ------------- THE CHART ABBREVIATIONS ------------------- */}
      <section className="plate-block">
        <h2 className="t-micro plate-block-head">Chart abbreviations</h2>
        <table className="plate-abbrev">
          <thead>
            <tr>
              <th scope="col">Tag</th>
              <th scope="col">Expansion</th>
              <th scope="col">Condition</th>
            </tr>
          </thead>
          <tbody>
            {CHART_TAG_ORDER.map((t) => (
              <tr key={t}>
                <td className="voice-mono">{t}</td>
                <td>{CHART_TAG_EXPANSION[t]}</td>
                <td>{CHART_TAG_CONDITION[t]}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <p className="t-small plate-citation">{INT1_CITATION}</p>
      </section>

      {/* ------------------- FURNITURE --------------------------- */}
      <section className="plate-block">
        <h2 className="t-micro plate-block-head">Scale and projection</h2>
        <div className="plate-furniture">
          <ScaleBar latitude={view.centre[1]} zoom={view.zoom} />
          <NorthTick />
        </div>
        <ProjectionStatement />
        <p className="t-small plate-credit">{creditLine(archives)}</p>
        {features.length > DOT_SCREEN_FEATURE_CEILING && (
          <p className="t-small">
            Above {DOT_SCREEN_FEATURE_CEILING} visible features, region interiors are
            suppressed and boundaries alone are drawn. Area emphasis is dropped;
            location semantics are not.
          </p>
        )}
      </section>

      {/* ---------- NOT LOCATABLE ON THIS PLATE (n) --------------- */}
      <section className="plate-block" id="not-locatable">
        <h2 className="t-micro plate-block-head">
          {NOT_LOCATABLE_HEADING} ({notLocatable.length})
        </h2>
        <p className="t-small">{NOT_LOCATABLE_NOTE}</p>
        {notLocatable.length === 0 ? (
          <p className="t-small voice-mono plate-empty-panel">
            0 rows. No candidate has been graded, so none has yet failed to be placed.
          </p>
        ) : (
          <table className="plate-notlocatable">
            <thead>
              <tr>
                <th scope="col">Name</th>
                <th scope="col">Precision</th>
                <th scope="col">Goes to</th>
              </tr>
            </thead>
            <tbody>
              {notLocatable.map((r) => (
                <tr key={r.slug}>
                  <td>
                    {r.locate_precision === "place_name_only" && r.claimed_place_name ? (
                      /* §8.2 — "a name, not a place." The name is quoted because
                         it is the source's word, and the plate does not adopt it. */
                      <span className="voice-serif">&ldquo;{r.claimed_place_name}&rdquo;</span>
                    ) : (
                      r.name
                    )}
                  </td>
                  <td className="voice-mono">{r.locate_precision}</td>
                  <td>
                    <a href={r.href}>{r.destination}</a>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      {/* §9.5 — "A `list view` toggle renders `/` filtered to the current
          viewport, so the plate is fully usable without a pointer." A real
          link with real GET state, not a mode switch. */}
      <p className="t-small plate-listview">
        <a href={listViewHref}>List view — the catalogue filtered to this viewport →</a>
      </p>
    </aside>
  );
}

/* ====================================================================== *
 * The selection block
 * ====================================================================== */

function Selection({
  feature,
  onClear,
}: {
  feature: MapFeature | null;
  onClear: () => void;
}) {
  if (!feature) {
    return (
      <section className="plate-block plate-selection-empty">
        <h2 className="t-micro plate-block-head">Selection</h2>
        <p className="t-small">
          No feature selected. Selecting a feature fills this panel; the plate opens
          no popup over the surface, because a popup would imply the map is primary
          and the record a detail.
        </p>
      </section>
    );
  }

  const mark = markForFeature(feature);
  const tags = chartTags(feature);

  return (
    <section className="plate-block plate-selection">
      <h2 className="t-micro plate-block-head">Selection</h2>
      <h3 className="t-lede">{feature.canonical_name}</h3>
      <dl className="dl t-small">
        <dt>entity</dt>
        <dd>{feature.slug}</dd>
        <dt>locate precision</dt>
        <dd>{feature.locate_precision}</dd>
        <dt>rendered as</dt>
        <dd>{feature.representation}</dd>
        <dt>uncertainty radius</dt>
        <dd>{feature.uncertainty_radius_m ? `${feature.uncertainty_radius_m} m` : "—"}</dd>
        {/*
          §7 — "A stave is never the SOLE rendering of a grade on a detail page;
          LETTER AND WORD ALWAYS PRINT ADJACENT." These two rows previously
          printed a bare letter, which leaves the reader with three of the four
          redundant channels and none of the one that says what the letter
          means. `GradeLetterWord` is the same component the entry sheet and the
          stave legend use, so the panel cannot drift from them.
        */}
        <dt>EXIST</dt>
        <dd>
          <GradeLetterWord grade={feature.exist_grade} atCeiling={feature.at_ceiling} />
        </dd>
        <dt>LOCATE</dt>
        <dd>
          {feature.locate_grade ? (
            <GradeLetterWord grade={feature.locate_grade} />
          ) : (
            "—"
          )}
        </dd>
        <dt>propositions published</dt>
        <dd>{feature.proposition_count}</dd>
      </dl>

      {/*
        RULE ZERO, STATED ON THE PAGE. The plate draws ONE proposition's output
        — LOCATE — and the panel says so, because §8.1 forbids the entity from
        carrying any composite and a map mark could otherwise be mistaken for
        one. "The entity has NO grade rendering of any kind, anywhere: not on
        the entry page, not in the index, NOT ON THE PLATE."
      */}
      <p className="t-small plate-rulezero">
        This mark renders the LOCATE proposition and nothing else. The{" "}
        {feature.proposition_count} propositions on this entity are graded
        independently and are not summarised here or anywhere.
      </p>

      <p className="t-small">
        <span className="voice-sans">{mark.reading}</span>
      </p>

      {feature.suppression_reason && (
        <div className="flag-block t-small">
          <span className="voice-mono">suppression_reason:</span>{" "}
          {feature.suppression_reason}
        </div>
      )}

      {tags.length > 0 && (
        <p className="t-small voice-mono">{tags.join(" · ")}</p>
      )}

      <p className="t-small">
        <a href={`/e/${feature.slug}`}>→ open sheet</a>
        {" · "}
        <button type="button" className="plate-clear" onClick={onClear}>
          clear selection
        </button>
      </p>
    </section>
  );
}
