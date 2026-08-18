import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { EntitySheet } from "@/components/EntitySheet";
import { SpecimenFrame, SpecimenResidual } from "@/components/SpecimenFrame";
import { getRepository } from "@/lib/repository";
import { CASES } from "@/lib/seed";

/**
 * `/calibration/[case]` — THE SPECIMEN SHEET. DESIGN.md §13, §18.3.
 *
 * The sheet is `<EntitySheet>` — THE SAME COMPONENT `/e/[slug]` renders, with
 * the same section order, the same stave column, the same apparatus, the same
 * lineage spine and the same silence table. A specimen rendered through a
 * simplified renderer would be demonstrating a different instrument from the
 * one the register will use, and would therefore demonstrate nothing.
 *
 * Everything that differs is containment, and all of it is data the repository
 * already attached: the namespace, the `noindex` directive, the header rule,
 * the hatched margin, and the aria prefix threaded into EVERY stave label on
 * the page. A UI that renders what it is handed renders the marker
 * automatically.
 */
export async function generateStaticParams() {
  return CASES.map((c) => ({ case: c.case_id }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ case: string }>;
}): Promise<Metadata> {
  const { case: caseId } = await params;
  const sheet = await getRepository().getCalibrationCase(caseId);
  return {
    title: sheet ? `Specimen ${caseId} — ${sheet.case.title}` : `Specimen ${caseId}`,
    /* Containment mechanism 2. */
    robots: { index: false, follow: false },
  };
}

export default async function SpecimenSheetPage({
  params,
}: {
  params: Promise<{ case: string }>;
}) {
  const { case: caseId } = await params;
  const sheet = await getRepository().getCalibrationCase(caseId);
  if (!sheet) notFound();

  const c = sheet.case;
  const crossListed = CASES.filter(
    (x) => c.entity_slug && x.entity_slug === c.entity_slug && x.case_id !== c.case_id,
  );

  return (
    <SpecimenFrame headerRule={sheet.containment.header_rule}>
      <div className="doc">
        <div className="doc-ref">{c.case_id}</div>
        <div className="doc-text">
          <h1>{c.title}</h1>

          {/* What the case guards is the reason it exists, so it leads. */}
          <div className="rule-block t-lede">
            <em>{c.demonstrates}</em>
          </div>

          <dl className="dl">
            <dt>expected under BES v0.2</dt>
            <dd>{c.expected}</dd>
            <dt>band filed under</dt>
            <dd>{c.band}</dd>
            <dt>marker</dt>
            <dd>{c.marker}</dd>
            <dt>sources</dt>
            <dd>{c.sources}</dd>
          </dl>

          {c.notes && c.notes.length > 0 ? (
            <div className="flag-block t-small">
              <span className="t-micro">recorded on this case</span>
              <ul>
                {c.notes.map((n, i) => (
                  <li key={i}>{n}</li>
                ))}
              </ul>
            </div>
          ) : null}

          {c.paired_with && c.paired_with.length > 0 ? (
            <p className="t-small">
              Read beside:{" "}
              {c.paired_with.map((p, i) => (
                <span key={p}>
                  {i > 0 ? " · " : ""}
                  <a href={`/calibration/${p}`}>{p}</a>
                </span>
              ))}
              . A pair is not a letter: the demonstration is the relationship between the two
              sheets, not either sheet&rsquo;s grade.
            </p>
          ) : null}

          {crossListed.length > 0 ? (
            <p className="t-small">
              The same entity is also read as:{" "}
              {crossListed.map((x, i) => (
                <span key={x.case_id}>
                  {i > 0 ? " · " : ""}
                  <a href={`/calibration/${x.case_id}`}>{x.case_id}</a>
                </span>
              ))}
              . One facility, several cases — which is why the enumerated case count exceeds the
              facility count.
            </p>
          ) : null}

          <SpecimenResidual />
        </div>
        <div className="doc-margin">
          <span className="t-micro">[doc]</span> This sheet emits no provenance beacon, enters no
          count on <a href="/">the register</a>, contributes no feature to{" "}
          <a href="/plate">the plate</a> and appears in no telemetry aggregate.
        </div>
      </div>

      {sheet.detail ? (
        <EntitySheet
          detail={sheet.detail}
          lineage={sheet.lineage}
          silence={sheet.silence}
          movement={sheet.movement}
          debt={sheet.debt}
          ariaPrefix={sheet.containment.aria_prefix}
          selfHref={sheet.containment.href}
          specimen
          notes={sheet.entity_notes}
          /* The case title is this page's <h1>; the sheet nests beneath it.
             Two competing page titles would be worst here of all places, since
             the containment marker is what must be announced first. */
          headingLevel={2}
        />
      ) : (
        <div className="doc">
          <div className="doc-ref">§0</div>
          <div className="doc-text">
            <div className="empty-block">
              <p style={{ fontWeight: 600 }}>Pipeline test — no entity sheet.</p>
              <p>
                This case tests the pipeline rather than a facility: there is no entity behind it
                and therefore no stave column to render. The expected value above is the whole of
                the case, and it is asserted by the seed verifier rather than by a sheet.
              </p>
            </div>
          </div>
        </div>
      )}
    </SpecimenFrame>
  );
}
