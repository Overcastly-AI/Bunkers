import { FilterStrip } from "@/components/FilterStrip";
import { RegisterTable } from "@/components/RegisterTable";
import { StaveList } from "@/components/StaveList";
import { StaveLegend } from "@/components/StaveLegend";
import { getRepository, CORPUS_CATALOGUED, HOSTS_IN_ACCESS_SCHEDULE } from "@/lib/repository";
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

/**
 * `/` — THE REGISTER. THERE IS NO HOMEPAGE.
 *
 * "No hero, no explainer panel, no 'learn more', no 'get started', no call to
 * action, no newsletter, no social links. THE SITE IS A VOLUME, NOT AN APP."
 *
 * DESIGN.md §13.1 specifies four blocks in this order and no others:
 *
 *   (a) MASTHEAD — definition line, STATE OF THE REGISTER, the D-006 sentence
 *   (b) HOW TO READ A STAVE — the permanent true-size legend, NOT COLLAPSIBLE
 *   (c) FILTER STRIP — a plain <form> GET, all state in the URL, + status line
 *   (d) THE CATALOGUE TABLE — REF · NAME · JURISDICTION · TYPOLOGY · LOCATE ·
 *       [12-column grade matrix] · SCI · LAST MOVED
 *
 * §18.1 GOVERNS WHAT THIS LOOKS LIKE AT ZERO. "THE LAYOUT DOES NOT CHANGE WHEN
 * DATA ARRIVES. No placeholder component, no skeleton loader, no 'coming soon',
 * no illustration, no email capture, no timeline. `/` renders the same table
 * with the same twelve grade-matrix columns and the same header. The status
 * line is present and computing. Every count reads its real value, WHICH IS 0.
 * NOTHING IS A STAND-IN, SO NOTHING HAS TO BE TORN OUT LATER."
 *
 * Every block below is therefore live rather than staged: the filter strip
 * filters, the sort links sort, the status line counts, and all four of them
 * are reading a real empty array.
 */
export default async function RegisterPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  const sp = await searchParams;
  const repo = getRepository();
  const state = await repo.getRegisterState();
  const all = await repo.listRegister();

  const filter = parseFilter(sp);
  const filtered = applyFilter(all, filter);

  const { sort, dir, bandClass } = parseSort(sp);
  const rows = sortRows(filtered, sort, dir, bandClass);
  const marks = one(sp, "marks") === "letters" ? "letters" : "ticks";
  const view = one(sp, "view") === "list" ? "list" : "table";

  return (
    <div className="doc">
      {/* ================= (a) MASTHEAD ================= */}

      <div className="doc-ref">§1</div>
      <div className="doc-text">
        <h1>The Register</h1>

        <div className="rule-block t-lede">
          Not a map of secrets. A map of what can be established, from what, and how
          well.
        </div>

        <h2 className="t-micro" style={{ marginTop: "var(--s-5)" }}>
          State of the register
        </h2>

        <dl className="dl">
          <dt>candidates published</dt>
          <dd>{state.candidates_published}</dd>
          <dt>propositions graded</dt>
          <dd>{state.propositions_graded}</dd>
          <dt>documents in the citation graph</dt>
          <dd>{state.documents_in_citation_graph}</dd>
          <dt>sources catalogued</dt>
          <dd>{state.sources_catalogued}</dd>
          <dt>hosts reachable</dt>
          <dd>
            {state.hosts_reachable} / {state.hosts_in_access_schedule}
          </dd>
          <dt>measured confabulation rate</dt>
          {/* An unmeasured rate prints an em dash. A zero would be a claim. */}
          <dd>{state.measured_confabulation_rate ?? "—"}</dd>
          <dt>rubric version</dt>
          <dd>{state.rubric_version}</dd>
          <dt>last grading run</dt>
          <dd>{state.last_grading_run ?? "—"}</dd>
        </dl>

        {/*
          D-006, VERBATIM, behind a 2px --undercut left rule. Stated here, in
          the standing foot, and at /limits. Redundancy on a publication
          obligation is correct.
        */}
        <div className="flag-block t-lede">
          <em>{state.verification_posture}</em>
          <div className="t-micro voice-mono" style={{ marginTop: "var(--s-2)" }}>
            D-006 → <a href="/limits">/limits</a>
          </div>
        </div>
      </div>
      <div className="doc-margin">
        <span className="t-micro">[doc]</span> Counts are read from the register&rsquo;s
        own tables at build time. Every one of them is its real value.
      </div>

      {/* ================= (b) HOW TO READ A STAVE ================= */}

      <div className="doc-ref">§2</div>
      <div className="doc-wide">
        <StaveLegend />
      </div>

      {/* ================= (c) FILTER STRIP + STATUS LINE ================= */}

      <div className="doc-ref">§3</div>
      <div className="doc-wide">
        <FilterStrip
          action="/"
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
              {rows.length} entries · {propositionCount(rows)} propositions ·{" "}
              {CORPUS_CATALOGUED} sources catalogued · {HOSTS_IN_ACCESS_SCHEDULE} hosts in
              the access schedule, {state.hosts_reachable} reachable
              {activeFacetCount(filter) > 0 ? ` · filtered from ${all.length}` : ""}
            </>
          }
        />
      </div>

      {/* ================= (d) THE CATALOGUE ================= */}

      <div className="doc-ref">§4</div>
      <div className="doc-wide">
        {sort === "band" && bandClass === null ? (
          <p className="flag-block t-small">{BAND_SORT_REQUIRES_CLASS}</p>
        ) : null}

        {/*
          §15 — the register table transposes into a stave list for a narrow
          column. Both are one link apart and both are URLs.
        */}
        <p className="t-small view-toggle">
          View as{" "}
          {view === "list" ? (
            <>
              <strong>stave list</strong> ·{" "}
              <a href={withParams("/", sp, { view: null })}>catalogue table</a>
            </>
          ) : (
            <>
              <strong>catalogue table</strong> ·{" "}
              <a href={withParams("/", sp, { view: "list" })}>stave list</a>
            </>
          )}
          . The list is the table transposed: one block per entry, twelve stave lines in
          the fixed class order, the whole evidence profile in about 200px of column.
        </p>

        {view === "list" ? (
          <StaveList rows={rows} hrefFor={(r) => `/e/${r.slug}`} />
        ) : (
        <RegisterTable
          rows={rows}
          hrefFor={(r) => `/e/${r.slug}`}
          marks={marks}
          basePath="/"
          searchParams={sp}
          sort={sort}
          dir={dir}
          bandClass={bandClass}
          emptyBlock={
            /*
              §18.2 — THE REASON IS STATED IN THE REGISTER'S OWN VOCABULARY, NOT
              IN APOLOGY. A single ruled block where rows would be.

              "This is an application of the project's own rule to the project's
              own situation, which is the most credible thing it could say."
            */
            <div className="empty-block">
              <p style={{ fontWeight: 600 }}>
                {activeFacetCount(filter) > 0
                  ? "0 entries match these facets."
                  : "0 candidates. Collection has not begun."}
              </p>
              <p>
                The grading model is ratified (BES v0.2). The schema is executable. Egress
                to {HOSTS_IN_ACCESS_SCHEDULE} catalogued hosts is being provisioned; until
                it lands, no citation can be resolved to bytes, and by this
                register&rsquo;s own standard an unresolved citation is not evidence.
                Publishing graded candidates before then would mean publishing grades that
                were never verified. &mdash; D-007
              </p>
            </div>
          }
        />
        )}

        {view === "list" && rows.length === 0 ? (
          <div className="empty-block">
            <p style={{ fontWeight: 600 }}>0 candidates. Collection has not begun.</p>
            <p>
              The list and the table report the same zero, because they read the same
              array. &mdash; D-007
            </p>
          </div>
        ) : null}

        {/*
          §18.3 — THE CALIBRATION CASES SHIP AS SPECIMEN SHEETS, rendered
          through the exact same components. "It measures a known standard and
          publishes the reading."

          The link is to the specimen namespace. It is never to /e/.
        */}
        <p className="t-small">
          The instrument is calibrated against known cases spanning bands A to F, R and X,
          plus six pipeline tests. They are published as specimen sheets at{" "}
          <a href="/calibration">/calibration</a> — through this same table, this same
          stave and this same apparatus — and they are excluded from every count on this
          page.
        </p>
      </div>
      <div className="doc-margin">
        <span className="t-micro">[doc]</span> D-007, <em>Network egress must be
        widened before W1 can publish</em>, ratified 2026-08-17.
      </div>
    </div>
  );
}
