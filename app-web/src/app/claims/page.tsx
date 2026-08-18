import { ClaimsTable } from "@/components/ClaimsTable";
import { getRepository } from "@/lib/repository";
import type { SearchParams } from "@/lib/query";

/**
 * `/claims` — THE CLAIMS REGISTER. DESIGN.md §13.3.
 *
 * Organised by ORIGIN, not by facility, and sorted by ORIGIN DATE ASCENDING.
 * "Sorted that way, band F becomes a CHRONOLOGY OF AMERICAN UNDERGROUND
 * FOLKLORE … That is a genuine scholarly contribution and it is the strongest
 * available answer to 'the dignity of a negative result.'"
 *
 * Styled identically to `/`: same rules, same weight, same ink, same stave
 * marks, same type sizes. IT IS NOT A GRAVEYARD, and nothing in this file
 * dims, mutes, greys or apologises for a row.
 *
 * At zero candidates the page renders complete — headnote, full column header,
 * the ruled block where rows would be — because §18.1 forbids the layout from
 * changing when data arrives.
 */
export const metadata = {
  title: "The claims register — BUNKERS",
  description:
    "Claims in bands E, F, R and X with their origin work, ordered by the date the claim first appears in the record.",
};

export default async function ClaimsPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>;
}) {
  await searchParams;
  const repo = getRepository();
  const rows = await repo.listClaims();

  return (
    <div className="doc">
      <div className="doc-ref">§1</div>
      <div className="doc-text">
        <h1>The claims register</h1>

        {/* The headnote, verbatim. */}
        <div className="rule-block t-lede">
          <em>
            These entries are not omissions. Each records a claim that circulated, where it
            came from, and what the record does and does not support. An F entry with a
            documented origin is a finding.
          </em>
        </div>

        <p>
          A claim heads each row and a facility follows it. That inversion is the whole
          idea: this is a catalogue of claims and where they came from, and it is a
          contribution independent of whether any facility turns out to be real. The
          register grades the <em>origin</em> of a claim on the same ladder it grades a
          hole in the ground, which is why the recurring pair on this page is an{" "}
          <span className="voice-mono">ORIGIN</span> proposition at A beside a{" "}
          <span className="voice-mono">FUNCTION</span> proposition at F — an A-grade fact
          about a fabrication.
        </p>
      </div>
      <div className="doc-margin">
        <span className="t-micro">[doc]</span> Bands E, F, R and X, from{" "}
        <span className="voice-mono">api.claims_register</span>. R is not a low grade and X
        is not a low grade; both are unranked and both are printed here with their origin
        work rather than filed away.
      </div>

      <div className="doc-ref">§2</div>
      <div className="doc-wide">
        <ClaimsTable
          rows={rows}
          hrefFor={(r) => `/e/${r.slug}`}
          refFor={(r) => r.slug}
          emptyBlock={
            <div className="empty-block">
              <p style={{ fontWeight: 600 }}>
                0 claims. Collection has not begun.
              </p>
              <p>
                The chronology this page exists to print — Oliver 1894, Pollock 1976,
                Bennewitz 1979&ndash;80, Lazar 1989, Nichols &amp; Moon 1992, 2016 — is
                already worked through in the calibration set, where each of those origins
                is graded against BES v0.2 as a known standard. Until egress lands, no
                citation resolves to bytes and no claim can be published here with a
                verified origin. &mdash; D-007
              </p>
              <p className="t-small">
                The worked chronology is at <a href="/calibration/claims">/calibration/claims</a>.
                Those rows are specimens, not entries.
              </p>
            </div>
          }
        />
      </div>
    </div>
  );
}
