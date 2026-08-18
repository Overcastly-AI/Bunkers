import { getRepository } from "@/lib/repository";

/**
 * `/lineage/[doc]` — THE DOCUMENT SHEET. DESIGN.md §13.
 *
 * One source and its descent: the witness key entry from `/sources`, the
 * propositions the document touches, and the spine drawn from that document
 * downward rather than from a proposition upward.
 *
 * THE CITATION GRAPH HOLDS ZERO DOCUMENTS. Not "the page is unfinished" — the
 * register has published no candidate, so no observation exists, so no
 * `core.source_document` row has been bound to anything, and there is nothing
 * to trace. The route resolves and says so.
 *
 * IT DOES NOT FALL BACK TO THE SPECIMEN SIGLA. The calibration sheets carry
 * real sigla and real descent, and serving one of them here would put a fixture
 * at a register URL — the exact failure the containment mechanisms exist to
 * prevent. The specimen spines are reachable inside their own namespace, at
 * `/calibration/<case>#lineage`, where the header rule and the hatched margin
 * travel with them.
 */
export async function generateStaticParams() {
  /* One param per document in the citation graph. Today: none. */
  return [] as { doc: string }[];
}

export default async function DocumentSheet({
  params,
}: {
  params: Promise<{ doc: string }>;
}) {
  const { doc } = await params;
  const state = await getRepository().getRegisterState();

  return (
    <div className="doc">
      <div className="doc-ref">§0</div>
      <div className="doc-text">
        <h1>No document under this siglum</h1>

        <div className="empty-block">
          <p style={{ fontWeight: 600 }}>
            <span className="voice-mono">{doc}</span> —{" "}
            {state.documents_in_citation_graph} documents in the citation graph.
          </p>
          <p>
            A document sheet is a witness and its descent. The register has bound no
            observation to any document, so no witness has a descent to trace. This is the
            absence of a graph, not an untraced one, and the distinction is the same one the
            register insists on everywhere else: a negative and an unsearched are not the same
            reading.
          </p>
          <p className="t-small">
            The witness key to the {state.sources_catalogued} catalogued sources is at{" "}
            <a href="/sources">/sources</a>. The descent spine as a finished object — the
            indented outline with its right-hand <span className="voice-mono">collapses</span> /{" "}
            <span className="voice-mono">INDEPENDENT</span> verdict column — is published against
            known standards inside the specimen namespace at{" "}
            <a href="/calibration">/calibration</a>, under §6 of each sheet.
          </p>
        </div>
      </div>
      <div className="doc-margin">
        <span className="t-micro">[doc]</span> Specimen sigla are never served from this
        namespace. A fixture at a register URL is the failure the six containment mechanisms
        exist to prevent.
      </div>
    </div>
  );
}
