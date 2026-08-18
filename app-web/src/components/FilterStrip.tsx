/**
 * THE FILTER STRIP — DESIGN.md §13.1(c).
 *
 * "Rule-bounded, Sans, PLAIN `<form>` GET with checkboxes and inputs. NO CHIPS,
 * NO PILLS, NO AUTOCOMPLETE, NO SEARCH-AS-YOU-TYPE. Facets: proposition class ·
 * band · cap applied · silence reading · locate precision · typology · state ·
 * citogenesis flag · at-ceiling · marginal · SCI floor. ALL STATE IN THE URL."
 *
 * It is a `<form method="get">` and nothing else, so it works with JavaScript
 * disabled, the back button works, and a filtered register is a URL somebody
 * can paste into a footnote. The `<details>` grouping is one of the two
 * permitted disclosures and it states its count in the summary (§16).
 *
 * At zero candidates this strip is LIVE, not disabled: §18.1 requires the
 * layout not to change when data arrives, and a filter that computes a real
 * zero is a working instrument, where a greyed-out one would be a stand-in.
 */

import {
  BASE_CAPS,
  type IndexFilter,
} from "../lib/filter-vocab";
import {
  GRADES,
  LOCATE_PRECISIONS,
  PROPOSITION_CLASSES,
  SILENCE_READINGS,
  TYPOLOGIES,
} from "../lib/types/enums";
import { BAND_WORD } from "../lib/types/grade";

export interface FilterStripProps {
  action: string;
  filter: IndexFilter;
  /** The states actually present in the data. Never a hardcoded list of 50. */
  states: readonly string[];
  /** Carried through the round-trip so a filter does not silently reset them. */
  hidden: Record<string, string | undefined>;
  /** How many rows and propositions the current filter is reporting on. */
  status: React.ReactNode;
  activeCount: number;
}

function CheckGroup({
  legend,
  name,
  options,
  selected,
  labels,
}: {
  legend: string;
  name: string;
  options: readonly string[];
  selected: readonly string[];
  labels?: Record<string, string>;
}) {
  return (
    <fieldset className="facet">
      <legend className="t-micro">{legend}</legend>
      <div className="facet-options">
        {options.map((o) => (
          <label key={o} className="facet-option t-small">
            <input type="checkbox" name={name} value={o} defaultChecked={selected.includes(o)} />
            <span className="voice-mono">{o}</span>
            {labels?.[o] ? <span className="facet-gloss"> {labels[o]}</span> : null}
          </label>
        ))}
      </div>
    </fieldset>
  );
}

export function FilterStrip(props: FilterStripProps) {
  const f = props.filter;
  const bandLabels = Object.fromEntries(
    GRADES.map((g) => [g, BAND_WORD[g].toLowerCase()]),
  ) as Record<string, string>;

  return (
    <form className="filter-strip" method="get" action={props.action}>
      {Object.entries(props.hidden).map(([k, v]) =>
        v === undefined ? null : <input key={k} type="hidden" name={k} value={v} />,
      )}

      <details className="filter-details" open={props.activeCount > 0}>
        <summary className="t-micro">
          Filter — {props.activeCount === 0 ? "no facet applied" : `${props.activeCount} facets applied`}
        </summary>

        <div className="facet-grid">
          <CheckGroup
            legend="Proposition class"
            name="class"
            options={PROPOSITION_CLASSES}
            selected={f.class}
          />
          <CheckGroup
            legend="Band"
            name="band"
            options={GRADES}
            selected={f.band}
            labels={bandLabels}
          />
          <CheckGroup legend="Cap applied" name="cap" options={BASE_CAPS} selected={f.cap} />
          <CheckGroup
            legend="Silence reading"
            name="silence"
            options={SILENCE_READINGS}
            selected={f.silence}
          />
          <CheckGroup
            legend="Locate precision"
            name="locate"
            options={LOCATE_PRECISIONS}
            selected={f.locate}
          />
          <CheckGroup legend="Typology" name="typology" options={TYPOLOGIES} selected={f.typology} />
          {props.states.length > 0 ? (
            <CheckGroup legend="State" name="state" options={props.states} selected={f.state} />
          ) : null}

          <fieldset className="facet">
            <legend className="t-micro">Flags</legend>
            <div className="facet-options">
              <label className="facet-option t-small">
                <input type="checkbox" name="citogenesis" value="1" defaultChecked={f.citogenesis} />
                <span>citogenesis confirmed</span>
              </label>
              <label className="facet-option t-small">
                <input type="checkbox" name="at_ceiling" value="1" defaultChecked={f.at_ceiling} />
                <span>at ceiling</span>
              </label>
              <label className="facet-option t-small">
                <input type="checkbox" name="marginal" value="1" defaultChecked={f.marginal} />
                <span>marginal — one contested fact decided the band</span>
              </label>
            </div>
          </fieldset>

          <fieldset className="facet">
            <legend className="t-micro">SCI floor</legend>
            <div className="facet-options">
              <label className="facet-option t-small">
                <span>
                  Minimum search completeness. A floor, never a rank — SCI does not order two
                  propositions.
                </span>
                <input
                  type="number"
                  name="sci_floor"
                  min="0"
                  max="1"
                  step="0.05"
                  defaultValue={f.sci_floor ?? ""}
                  className="voice-mono"
                />
              </label>
            </div>
          </fieldset>
        </div>

        <div className="filter-actions">
          <button type="submit" className="t-micro">
            Apply
          </button>
          <a href={props.action} className="t-micro">
            Clear all facets
          </a>
        </div>
      </details>

      <div className="voice-mono t-micro status-line">{props.status}</div>
    </form>
  );
}
