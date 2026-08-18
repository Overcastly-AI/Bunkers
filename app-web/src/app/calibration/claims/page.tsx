import type { Metadata } from "next";
import { ClaimsTable } from "@/components/ClaimsTable";
import { SpecimenFrame, SpecimenResidual } from "@/components/SpecimenFrame";
import { getRepository } from "@/lib/repository";
import type { PropositionBadge } from "@/lib/types/api";

/**
 * `/calibration/claims` — THE CHRONOLOGY, WORKED AGAINST THE KNOWN STANDARD.
 *
 * `/claims` is the register's claims register and it is empty, because no
 * candidate has been graded. This is the same table, the same columns and the
 * same ordering over the calibration set, so that the argument DESIGN.md §8.3
 * makes for the page is legible before the register has data:
 *
 * "Sorted by origin date ascending, band F becomes a CHRONOLOGY OF AMERICAN
 * UNDERGROUND FOLKLORE: Oliver 1894 (Telos) → Pollock 1976 (Mount Weather) →
 * Bennewitz 1979–80 (Dulce) → Nichols & Moon 1992 (Montauk) → Lazar 1989 (S-4)
 * → 2016 (Comet Ping Pong). That is a genuine scholarly contribution and it is
 * the strongest available answer to 'the dignity of a negative result.'"
 *
 * Read down the ORIGIN GRADE column beside the GRADE column. The repeated pair
 * — an A-grade fact about where a claim came from, beside an F or an R on the
 * claim itself — is the register's most distinctive output, and it is the
 * reason this page is styled exactly like the index rather than like an
 * appendix.
 */
export const metadata: Metadata = {
  title: "Specimen claims chronology — BUNKERS",
  description:
    "The claims register worked against the calibration set, ordered by origin date ascending.",
  robots: { index: false, follow: false },
};

const HEADER_RULE =
  "SPECIMEN — CALIBRATION CLAIMS CHRONOLOGY. Expected values under BES v0.2, not register entries. No candidate has been graded.";

export default async function SpecimenClaimsPage() {
  const repo = getRepository();
  const rows = await repo.listCalibrationClaims();
  const sheets = await repo.listCalibration();

  const badges: Record<string, PropositionBadge> = {};
  const lineage: Record<string, { lineage_count: number; collapse_delta: number }> = {};
  const refBySlug = new Map<string, string>();

  for (const s of sheets) {
    if (!s.detail) continue;
    if (!refBySlug.has(s.detail.entity.slug)) {
      refBySlug.set(s.detail.entity.slug, s.register_row.ref);
    }
    for (const p of s.detail.propositions) badges[p.proposition_id] = p;
    for (const [id, l] of Object.entries(s.lineage)) {
      lineage[id] = { lineage_count: l.lineage_count, collapse_delta: l.collapse_delta };
    }
  }

  return (
    <SpecimenFrame headerRule={HEADER_RULE}>
      <div className="doc">
        <div className="doc-ref">§1</div>
        <div className="doc-text">
          <h1>Specimen claims chronology</h1>

          <div className="rule-block t-lede">
            <em>
              These entries are not omissions. Each records a claim that circulated, where it came
              from, and what the record does and does not support. An F entry with a documented
              origin is a finding.
            </em>
          </div>

          <p className="t-small">
            {rows.length} graded propositions in bands E, F, R and X across the calibration set,
            ordered by the date the claim first appears in the record. Undated claims sort last;
            the register does not invent a terminus it does not have.
          </p>

          <SpecimenResidual />
        </div>
        <div className="doc-margin">
          <span className="t-micro">[inf]</span> Read the ORIGIN GRADE column beside the GRADE
          column. Where an A sits next to an F, the register is publishing a well-established fact
          about a fabrication — which is a contribution, and is why this page carries the same ink
          as the index.
        </div>

        <div className="doc-ref">§2</div>
        <div className="doc-wide">
          <ClaimsTable
            rows={rows}
            badges={badges}
            lineage={lineage}
            ariaPrefix="Specimen, not a register entry."
            hrefFor={(r) => `/calibration/${refBySlug.get(r.slug) ?? r.slug}`}
            refFor={(r) => refBySlug.get(r.slug) ?? r.slug}
          />
        </div>
      </div>
    </SpecimenFrame>
  );
}
