/**
 * THE LINEAGE SPINE — DESIGN.md §12. Contamination made readable.
 *
 * "The failure mode is a force-directed hairball. NOBODY READS A HAIRBALL, and
 * a hairball says *many nodes* when the finding is *one source*."
 *
 * Three registers, TEXT FIRST, DRAWING LAST AND OPTIONAL:
 *
 *  §12.1 THE VERDICT SENTENCE, always first, Sans `--t-lede`.
 *  §12.2 THE DESCENT SPINE — an indented outline, not a node-link diagram,
 *        with the RIGHT-HAND VERDICT COLUMN. "A reader scanning the right edge
 *        sees a column of `collapses` with a single `INDEPENDENT`. THAT COLUMN
 *        *IS* THE 'ONE SOURCE AND 399 COPIES' FINDING, AND IT REQUIRES NO
 *        GRAPH LITERACY AT ALL."
 *  §12.3 Citogenesis in plain language, plus the stemmatics gloss in the margin.
 *
 * Conventions cited by name rather than invented: solid `├─` is descent, dashed
 * `├╌` is contamination — the Lachmannian stemmatics convention, which is
 * exactly what a cross-lineage citation is. Independent lineages are separate
 * BLOCKS separated by a rule, NEVER separate colours: colour would imply the
 * lineages differ in kind; they differ only in being separate.
 *
 * §21.5, honestly implemented rather than papered over: THE SPINE DOES NOT
 * SCALE PAST ROUGHLY EIGHT LINEAGES. Above that this component stops drawing
 * and lets the collapsed count carry the finding, and it says so in words —
 * because a long scroll that looks like a drawing is worse than a count that
 * admits it is one.
 */

import type { LineageBlock, LineageNode, LineageProfile } from "../lib/types/api";

/** Past this, no good drawing exists. The count carries the finding instead. */
const MAX_BLOCKS_DRAWN = 8;
/** Descendants drawn before the collapsed row takes over inside one block. */
const MAX_DESCENDANTS_DRAWN = 6;

function Verdict({ collapses }: { collapses: boolean }) {
  return (
    <td className="lineage-verdict voice-mono">
      {collapses ? "collapses" : "INDEPENDENT"}
    </td>
  );
}

function connectorFor(node: LineageNode, last: boolean): string {
  const stem = last ? "└" : "├";
  if (node.edge_kind === "contamination") return `${stem}╌`;
  if (node.edge_kind === "rests-on") return `${stem} rests on:`;
  return `${stem}─`;
}

function NodeRow({
  node,
  last,
  origin,
}: {
  node: LineageNode;
  last: boolean;
  origin?: boolean;
}) {
  return (
    <>
      <tr className={origin ? "lineage-origin-row" : undefined}>
        <td className="lineage-tree">
          <span className="voice-mono lineage-connector" aria-hidden="true">
            {origin ? "◇ ORIGIN" : connectorFor(node, last)}
          </span>
          <span
            className="lineage-indent"
            style={{ paddingInlineStart: `${Math.max(0, node.depth) * 12}px` }}
          >
            <span className="voice-mono lineage-date">{node.document_date ?? "undated"}</span>{" "}
            <span className="lineage-label">{node.label}</span>{" "}
            <span className="voice-mono lineage-siglum">[{node.siglum}]</span>
            {node.citogenesis ? (
              <span className="voice-mono lineage-cito"> ⟳ CITOGENESIS</span>
            ) : null}
            {node.closes_cycle ? (
              <span className="voice-mono lineage-cycle"> ⟲ closes cycle: {node.closes_cycle}</span>
            ) : null}
          </span>
        </td>
        <td className="voice-mono">{node.origin_tier}</td>
        <td className="voice-mono lineage-resolved">
          {node.resolved ? "✓ resolved" : "✕ unresolvable"}
        </td>
        <Verdict collapses={node.collapses_lineage} />
      </tr>
      {node.note ? (
        <tr className="lineage-note-row">
          <td colSpan={4} className="t-small">
            {node.note}
          </td>
        </tr>
      ) : null}
    </>
  );
}

function Block({ block }: { block: LineageBlock }) {
  const drawn = block.descendants.slice(0, MAX_DESCENDANTS_DRAWN);
  const hidden = block.descendants.length - drawn.length;

  return (
    <div className="lineage-block">
      <div className="scroll-region" role="region" aria-label={`Lineage ${block.lineage_index}`}>
        <table className="lineage-table">
          <caption className="t-micro">
            Lineage {block.lineage_index} · dating basis: {block.dating_basis}
          </caption>
          <thead>
            <tr>
              <th scope="col">Witness</th>
              <th scope="col">Tier</th>
              <th scope="col">Receipt</th>
              <th scope="col">Verdict</th>
            </tr>
          </thead>
          <tbody>
            <NodeRow node={block.origin} last={false} origin />

            {/* THE COUNT IS IN THE COLLAPSED ROW. This line is the entire
                finding in six words; everything below it is elaboration. */}
            <tr className="lineage-collapsed-row">
              <td className="lineage-tree" colSpan={3}>
                <span className="voice-mono" aria-hidden="true">
                  └
                </span>{" "}
                <strong className="voice-mono">
                  {block.downstream_count} downstream{" "}
                  {block.downstream_count === 1 ? "appearance" : "appearances"} · 1 lineage
                </strong>
              </td>
              <Verdict collapses={false} />
            </tr>

            {drawn.map((d, i) => (
              <NodeRow key={d.document_id} node={d} last={i === drawn.length - 1 && hidden === 0} />
            ))}

            {hidden > 0 ? (
              <tr>
                <td className="lineage-tree" colSpan={3}>
                  <span className="voice-mono" aria-hidden="true">
                    ├─
                  </span>{" "}
                  <span className="voice-mono">{hidden} more</span> — not drawn. Each is a
                  downstream appearance already counted in the row above.
                </td>
                <Verdict collapses />
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export function LineageSpine({
  profile,
  refCode,
}: {
  profile: LineageProfile;
  refCode?: string;
}) {
  const tooMany = profile.blocks.length > MAX_BLOCKS_DRAWN;

  return (
    <section className="lineage" aria-label="Lineage and origin trace">
      {refCode ? <div className="lineage-ref voice-mono t-micro">{refCode}</div> : null}

      {/* §12.1 — THE VERDICT SENTENCE. Always first. */}
      <p className="t-lede lineage-sentence">
        <strong className="voice-mono">
          {profile.document_count} citing{" "}
          {profile.document_count === 1 ? "document" : "documents"} ·{" "}
          {profile.lineage_count} independent{" "}
          {profile.lineage_count === 1 ? "lineage" : "lineages"} · collapse delta{" "}
          {profile.collapse_delta}
        </strong>
        <br />
        {profile.verdict_sentence}
      </p>

      <p className="t-small lineage-delta-gloss">
        <span className="voice-mono">collapse delta</span> is documents minus lineages. It is not
        a judgement and not a score: it is the distance between how many sources there appear to be
        and how many witnesses there are.
      </p>

      {/* §12.3 — citogenesis in plain language, no jargon. */}
      {profile.citogenesis_note ? (
        <div className="flag-block t-base">
          <p>{profile.citogenesis_note}</p>
        </div>
      ) : null}

      {tooMany ? (
        <div className="lineage-toomany">
          <p className="t-base">
            <strong>
              {profile.blocks.length} independent lineages — the spine is not drawn.
            </strong>{" "}
            No readable drawing of this exists: a node-link view would be a hairball and a
            {" "}{profile.blocks.length}-block outline would be a long scroll that looks like a
            drawing without being one. The counts above carry the finding. Each lineage and its
            downstream count is listed below.
          </p>
          <div className="scroll-region" role="region" aria-label="Lineage summary" tabIndex={0}>
            <table className="lineage-table">
              <thead>
                <tr>
                  <th scope="col">Lineage</th>
                  <th scope="col">Origin</th>
                  <th scope="col">Tier</th>
                  <th scope="col">Downstream</th>
                  <th scope="col">Verdict</th>
                </tr>
              </thead>
              <tbody>
                {profile.blocks.map((b) => (
                  <tr key={b.lineage_index}>
                    <td className="voice-mono">{b.lineage_index}</td>
                    <td>
                      {b.origin.label}{" "}
                      <span className="voice-mono lineage-siglum">[{b.origin.siglum}]</span>
                    </td>
                    <td className="voice-mono">{b.origin.origin_tier}</td>
                    <td className="voice-mono">{b.downstream_count}</td>
                    <Verdict collapses={false} />
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        profile.blocks.map((b) => <Block key={b.lineage_index} block={b} />)
      )}

      {profile.blocks.length === 0 && !tooMany ? (
        <p className="t-small">
          No descent has been traced for this proposition. The counts above are the whole of what
          the register holds; an untraced lineage is not a lineage of one.
        </p>
      ) : null}
    </section>
  );
}

/**
 * §12.3 — the stemmatics gloss. Unnumbered, once per page, in the margin.
 * It teaches the apparatus rather than assuming it.
 */
export function StemmaticsGloss() {
  return (
    <>
      <span className="t-micro">[inf]</span> Removing derivative witnesses before counting them is
      what textual scholarship calls <em>eliminatio codicum descriptorum</em>; a claim crossing
      between branches is <em>contamination</em>. The register performs both. The count at the
      right is the result. Solid connectors are descent; dashed connectors are contamination.
    </>
  );
}
