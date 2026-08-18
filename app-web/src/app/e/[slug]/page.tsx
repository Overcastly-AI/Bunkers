import { EntitySheet } from "@/components/EntitySheet";
import { getRepository } from "@/lib/repository";
import type { GradeEvent, LineageProfile, SilenceRow } from "@/lib/types/api";

/**
 * `/e/[slug]` — THE ENTRY SHEET. DESIGN.md §13.2.
 *
 * The sheet itself is `<EntitySheet>`, and it is THE SAME COMPONENT the
 * calibration specimens render through (§18.3). That is deliberate and it is
 * the only honest way to publish specimens: if the specimen sheets used a
 * simplified renderer, they would be demonstrating a different instrument from
 * the one the register will use.
 *
 * TODAY THIS ROUTE HAS NOTHING TO SERVE. `getEntry()` returns null for every
 * slug because no candidate has been graded, and there is deliberately NO
 * FALLBACK to the specimen set: serving a fixture at a register URL is exactly
 * the failure the six containment mechanisms exist to prevent. Rather than a
 * bare 404, the page states the register's own reason in the register's own
 * vocabulary and points at the specimen namespace — which is the same thing
 * `/` does with the block where its rows would be.
 */
export async function generateStaticParams() {
  const rows = await getRepository().listRegister();
  return rows.map((r) => ({ slug: r.slug }));
}

export default async function EntryPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const repo = getRepository();
  const detail = await repo.getEntry(slug);

  if (!detail) {
    return (
      <div className="doc">
        <div className="doc-ref">§0</div>
        <div className="doc-text">
          <h1>No entry under this reference</h1>
          <div className="empty-block">
            <p style={{ fontWeight: 600 }}>
              <span className="voice-mono">{slug}</span> — 0 candidates published.
            </p>
            <p>
              No candidate has been graded, so no entry sheet exists at any slug. This is
              not a missing page: it is the register reporting that collection has not
              begun. Egress to the catalogued hosts is being provisioned; until it lands,
              no citation resolves to bytes, and by this register&rsquo;s own standard an
              unresolved citation is not evidence. &mdash; D-007
            </p>
            <p className="t-small">
              The entry sheet as a finished object — stave column, apparatus, lineage
              spine, silence table, movement — is published against known standards at{" "}
              <a href="/calibration">/calibration</a>. Those sheets are{" "}
              <strong>specimens</strong>, not entries, and the register never serves one
              from this namespace.
            </p>
          </div>
        </div>
        <div className="doc-margin">
          <span className="t-micro">[doc]</span> The repository returns null here with no
          fallback, by construction. A register URL cannot resolve to a fixture.
        </div>
      </div>
    );
  }

  /* When candidates exist, each proposition's lineage, silence and movement are
     fetched by proposition id and handed to the sheet as maps. */
  const lineage: Record<string, LineageProfile> = {};
  const silence: Record<string, SilenceRow[]> = {};
  const movement: Record<string, GradeEvent[]> = {};
  for (const p of detail.propositions) {
    const l = await repo.getLineage(p.proposition_id);
    if (l) lineage[p.proposition_id] = l;
    const s = await repo.getSilence(p.proposition_id);
    if (s.length > 0) silence[p.proposition_id] = s;
    const m = await repo.getMovement(p.proposition_id);
    if (m.length > 0) movement[p.proposition_id] = m;
  }

  return (
    <EntitySheet
      detail={detail}
      lineage={lineage}
      silence={silence}
      movement={movement}
      selfHref={`/e/${slug}`}
    />
  );
}
