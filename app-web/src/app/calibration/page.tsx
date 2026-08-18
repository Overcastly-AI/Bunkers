import type { Metadata } from "next";
import { FilterStrip } from "@/components/FilterStrip";
import { RegisterTable } from "@/components/RegisterTable";
import { StaveList } from "@/components/StaveList";
import { SpecimenFrame, SpecimenResidual } from "@/components/SpecimenFrame";
import { getRepository } from "@/lib/repository";
import { one, withParams, type SearchParams } from "@/lib/query";
import {
  activeFacetCount,
  applyFilter,
  parseSort,
  parseFilter,
  propositionCount,
  sortRows,
  statesIn,
  BAND_SORT_REQUIRES_CLASS,
} from "@/lib/register";
import { CASES, KNOWN_WRONG, RATIFICATION_ITEM_R3, SUITE_ASSERTIONS } from "@/lib/seed";
import type { EvidenceRow } from "@/lib/types/api";

/**
 * `/calibration` — THE REGRESSION SUITE, PUBLISHED. DESIGN.md §13, §18.3.
 *
 * "THE CALIBRATION CASES SHIP AS SPECIMEN SHEETS, RENDERED THROUGH THE EXACT
 * SAME COMPONENTS. This is what makes the launch feel alive rather than broken,
 * and it is precisely what a survey instrument does before fieldwork: IT
 * MEASURES A KNOWN STANDARD AND PUBLISHES THE READING."
 *
 * So this page is the catalogue table — the same component, the same twelve
 * fixed grade columns, the same stave ticks, the same sort discipline as `/`.
 * The difference is entirely containment: a different namespace, a different
 * repository method reading a different array, a hatched margin, a header rule
 * on every sheet, `noindex`, and exclusion from every count on the register.
 *
 * THE COUNT DISCREPANCY IS PUBLISHED RATHER THAN RESOLVED SILENTLY.
 * `docs/CALIBRATION.md` says "34 cases" in its prose and enumerates 43 case
 * ids, because several ids are one facility read from different angles
 * (Greenbrier carries five). Both counts are printed below, with the entity
 * count beside them. Quietly picking one would be the register correcting a
 * source without saying so, which is the thing it exists not to do.
 */
export const metadata: Metadata = {
  title: "Calibration specimens — BUNKERS",
  description:
    "The regression suite, published as specimen sheets. Expected values under BES v0.2, not register entries.",
  /* Containment mechanism 2. */
  robots: { index: false, follow: false },
};

const HEADER_RULE =
  "SPECIMEN INDEX — CALIBRATION SUITE. Expected values under BES v0.2, not register entries. No candidate has been graded.";

export default async function CalibrationIndex({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const sp = await searchParams;
  const repo = getRepository();
  const all = await repo.listCalibrationRegister();
  const sheets = await repo.listCalibration();

  const filter = parseFilter(sp);
  const filtered = applyFilter(all, filter);
  const { sort, dir, bandClass } = parseSort(sp);
  const rows = sortRows(filtered, sort, dir, bandClass);
  const marks = one(sp, "marks") === "letters" ? "letters" : "ticks";
  const view = one(sp, "view") === "list" ? "list" : "table";

  /**
   * The observation rows behind the specimen badges, so the stave list draws
   * real diagnosticity heights rather than the uniform fallback. The register's
   * own index has no equivalent, because `api.proposition_badge` carries counts
   * and not rows — which is exactly what the fallback's aria-label says.
   */
  const evidence: Record<string, readonly EvidenceRow[]> = {};
  for (const s of sheets) {
    for (const p of s.detail?.propositions ?? []) evidence[p.proposition_id] = p.evidence;
  }

  const pipeline = CASES.filter((c) => c.band === "PIPELINE");
  const graded = CASES.filter((c) => c.band !== "PIPELINE");

  return (
    <SpecimenFrame headerRule={HEADER_RULE}>
      <div className="doc">
        <div className="doc-ref">§1</div>
        <div className="doc-text">
          <h1>Calibration specimens</h1>

          <div className="rule-block t-lede">
            An observatory the night before first light is not a broken observatory. It is a
            complete, calibrated instrument reporting zero. These sheets are the instrument
            measuring a known standard and publishing the reading.
          </div>

          <dl className="dl">
            <dt>graded cases enumerated</dt>
            <dd>{graded.length}</dd>
            <dt>pipeline tests</dt>
            <dd>{pipeline.length}</dd>
            <dt>distinct entities</dt>
            <dd>{all.length}</dd>
            <dt>propositions</dt>
            <dd>{propositionCount(all)}</dd>
            <dt>specimen sheets published</dt>
            <dd>{sheets.length}</dd>
          </dl>

          <div className="flag-block t-small">
            <p>
              <span className="t-micro">discrepancy, published</span>{" "}
              <span className="voice-mono">docs/CALIBRATION.md</span> describes the suite as
              &ldquo;34 cases&rdquo; in its prose and enumerates{" "}
              <span className="voice-mono">{graded.length}</span> case identifiers. The two
              numbers are reconcilable — several identifiers are one facility read from a
              different angle, and Greenbrier alone carries five — but they are not the same
              number, and the register prints both rather than choosing one on the source&rsquo;s
              behalf. Every enumerated identifier has its own section, its own marker and its own
              expected value, so every one of them is published here.
            </p>
          </div>

          <SpecimenResidual />
        </div>
        <div className="doc-margin">
          <span className="t-micro">[doc]</span> These rows are read through{" "}
          <span className="voice-mono">listCalibrationRegister()</span>, a different repository
          method reading a different array from the one <a href="/">the register</a> reads. There
          is no code path between them.
        </div>

        {/* The same filter strip, over the specimen array. */}
        <div className="doc-ref">§2</div>
        <div className="doc-wide">
          <FilterStrip
            action="/calibration"
            filter={filter}
            states={statesIn(all)}
            activeCount={activeFacetCount(filter)}
            hidden={{
              sort,
              dir,
              sortclass: bandClass ?? undefined,
              marks: marks === "letters" ? "letters" : undefined,
              view: view === "list" ? "list" : undefined,
            }}
            status={
              <>
                {rows.length} specimens · {propositionCount(rows)} propositions ·{" "}
                {graded.length} enumerated cases · {pipeline.length} pipeline tests · excluded
                from every count on the register
              </>
            }
          />
        </div>

        {/* THE SAME CATALOGUE TABLE. This is the point of the page. */}
        <div className="doc-ref">§3</div>
        <div className="doc-wide">
          {sort === "band" && bandClass === null ? (
            <p className="flag-block t-small">{BAND_SORT_REQUIRES_CLASS}</p>
          ) : null}

          {/* §15 — the same transposition, over the specimen array. */}
          <p className="t-small view-toggle">
            View as{" "}
            {view === "list" ? (
              <>
                <strong>stave list</strong> ·{" "}
                <a href={withParams("/calibration", sp, { view: null })}>catalogue table</a>
              </>
            ) : (
              <>
                <strong>catalogue table</strong> ·{" "}
                <a href={withParams("/calibration", sp, { view: "list" })}>stave list</a>
              </>
            )}
            .
          </p>

          {view === "list" ? (
            <StaveList
              rows={rows}
              hrefFor={(r) => `/calibration/${r.ref}`}
              ariaPrefix="Specimen, not a register entry."
              evidence={evidence}
            />
          ) : (
          <RegisterTable
            rows={rows}
            hrefFor={(r) => `/calibration/${r.ref}`}
            marks={marks}
            basePath="/calibration"
            searchParams={sp}
            sort={sort}
            dir={dir}
            bandClass={bandClass}
            ariaPrefix="Specimen, not a register entry."
            emptyBlock={
              <div className="empty-block">
                <p>0 specimens match these facets.</p>
              </div>
            }
          />
          )}

          <p className="t-small">
            Read down the <span className="voice-mono">EXST</span> column and then down the{" "}
            <span className="voice-mono">FUNC</span> column. The texture is the finding: the hole
            is certain and the function is not, across the whole suite, without a word of
            commentary. That is the single state of affairs the register exists to express and the
            one its previous version could not.
          </p>
        </div>

        {/* The case list — every enumerated identifier, with its expected value. */}
        <div className="doc-ref">§4</div>
        <div className="doc-text">
          <h2 className="section-head">The cases</h2>
        </div>
        <div className="doc-wide">
          <div className="scroll-region" role="region" aria-label="Calibration cases" tabIndex={0}>
            <table>
              <caption className="t-small">
                Every enumerated case identifier. A case passes when the grade matches{" "}
                <em>and</em> the named limiting condition, applied caps and null state match.
                Matching the letter alone is not a pass.
              </caption>
              <thead>
                <tr>
                  <th scope="col">Case</th>
                  <th scope="col">Band</th>
                  <th scope="col">Title</th>
                  <th scope="col">Expected</th>
                  <th scope="col">Marker</th>
                </tr>
              </thead>
              <tbody>
                {CASES.map((c) => (
                  <tr key={c.case_id}>
                    <th scope="row" className="voice-mono">
                      <a href={`/calibration/${c.case_id}`}>{c.case_id}</a>
                    </th>
                    <td className="voice-mono">{c.band}</td>
                    <td>{c.title}</td>
                    <td className="voice-mono">{c.expected}</td>
                    <td className="voice-mono t-micro">{c.marker}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Suite-level assertions and the declared divergences. */}
        <div className="doc-ref">§5</div>
        <div className="doc-text">
          <h2 className="section-head">Suite assertions</h2>
          <dl className="dl-prose">
            {SUITE_ASSERTIONS.map((s) => (
              <div key={s.id}>
                <dt className="voice-mono t-micro">
                  {s.id} · {s.title}
                </dt>
                <dd className="t-small">{s.text}</dd>
              </div>
            ))}
          </dl>

          <h2 className="section-head">Where the model is known to diverge</h2>
          <p className="t-small">
            Five cases where the adjudicated model disagrees with a reviewer, published as
            disagreements rather than resolved into agreement.
          </p>
          <dl className="dl-prose">
            {KNOWN_WRONG.map((k) => (
              <div key={k.case_id}>
                <dt className="voice-mono t-micro">
                  {k.case_id} · reviewers {k.reviewers} · BES {k.bes}
                </dt>
                <dd className="t-small">{k.why}</dd>
              </div>
            ))}
            <div>
              <dt className="voice-mono t-micro">{RATIFICATION_ITEM_R3.id} · structural</dt>
              <dd className="t-small">{RATIFICATION_ITEM_R3.description}</dd>
            </div>
          </dl>
        </div>
      </div>
    </SpecimenFrame>
  );
}
