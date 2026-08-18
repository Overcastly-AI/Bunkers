import type { Metadata } from "next";

import { Block, SectionHead, Tag } from "@/components/Doc";
import {
  getRepository,
  CORPUS_CATALOGUED,
  CORPUS_TRANSCRIBED,
} from "@/lib/repository";

export const metadata: Metadata = {
  title: "The sigla — witness key to the corpus · BUNKERS",
  description:
    "The source registry as a witness key: host tier, content tier, robots posture and egress state for every corpus the register searches.",
};

/**
 * `/sources` — THE SIGLA.
 *
 * DESIGN.md §13.6: "The witness key: every document node with siglum,
 * origin_tier, access method, causal provenance, egress_state, robots posture,
 * last probe, and the propositions it touches. WITHOUT THIS THE LINEAGE SPINE IS
 * UNREADABLE; with it, the spine is a reference table."
 *
 * TWO TABLES ARE SPECIFIED HERE AND ONLY ONE OF THEM CAN BE POPULATED TODAY.
 *
 *   The CORPUS registry — which archives the register searches — is curated
 *   content and is populated (partially; see below).
 *
 *   The DOCUMENT-NODE sigla — one row per document actually cited by an
 *   observation — is derived from the citation graph, and the citation graph
 *   holds zero documents because no candidate has been graded. It renders as a
 *   real empty table with its real zero, not as a placeholder.
 *
 * THE PARTIAL-TRANSCRIPTION DISCLOSURE IS THE POINT OF THIS PAGE, NOT A CAVEAT
 * ON IT. `curated.ts` carries 18 of the 158 catalogued sources — the ones the
 * calibration set exercises — and the remaining 140 must be imported from the
 * registry rather than written by hand: "inventing 140 corpus rows to make a
 * table look full would be precisely the confabulation this register measures."
 *
 * So the page prints the count it has AND the count it does not. A partial table
 * that says so is a finding aid; a padded one is a lie.
 */
export default async function SourcesPage() {
  const repo = getRepository();
  const corpora = await repo.listCorpora();
  const state = await repo.getRegisterState();

  const missing = CORPUS_CATALOGUED - CORPUS_TRANSCRIBED;
  const traps = corpora.filter((c) => c.tier_trap);
  const writable = corpora.filter((c) => c.adversary_writable);
  const blocklisted = corpora.filter((c) => c.machine_generated_blocklist);
  const probed = corpora.filter((c) => c.egress_state !== "UNPROBED");

  return (
    <div className="doc">
      <Block
        code="§0"
        margin={
          <>
            <Tag k="doc" /> A siglum is a short fixed label for a witness. The convention is
            borrowed from critical editions, where the apparatus is unreadable without one.
          </>
        }
      >
        <h1>The sigla</h1>

        <div className="rule-block t-lede">
          The witness key. Every corpus the register searches, what tier it is, who is
          serving the bytes, and whether the register has ever successfully reached it.
        </div>

        <p>
          Two things are catalogued here, and they are different objects. The{" "}
          <strong>corpus registry</strong> (§2) is the list of archives the register
          searches — the denominator of every completeness figure it publishes. The{" "}
          <strong>document sigla</strong> (§3) is one row per document actually cited by an
          observation, and it is what makes a lineage spine readable. The second is derived
          from the first and is currently empty.
        </p>
      </Block>

      {/* ==================================================================
          §1 — WHAT THIS TABLE IS AND IS NOT. Stated before the table, because
          a reader who scrolls into 18 rows without this has been told the
          register searches 18 archives.
          ================================================================== */}

      <SectionHead
        code="§1"
        id="scope"
        title="What is here and what is not"
        margin={
          <>
            <Tag k="doc" /> <a href="/limits#L-9">L-9</a> — the registry may be
            substantially wrong and nobody knows yet.
          </>
        }
      />

      <Block code="§1.1">
        <div className="flag-block">
          <div className="flag-head">Partial transcription — disclosed</div>
          <p>
            <strong>{CORPUS_CATALOGUED} sources are catalogued. {CORPUS_TRANSCRIBED} are
            transcribed into this table. {missing} are not.</strong>
          </p>
          <p style={{ marginBottom: 0 }}>
            The {CORPUS_TRANSCRIBED} below are the corpora the calibration suite actually
            exercises. The remaining {missing} must be imported from the source registry
            rather than written by hand — inventing {missing} rows to make this table look
            complete would be precisely the confabulation this register measures and
            publishes.
          </p>
        </div>

        <p>
          <strong>Every endpoint below is currently unverified.</strong> Three of the five
          registries the catalogue was built from were written with federal and military
          egress blocked; every endpoint grammar, parameter name and identifier scheme in
          them was reconstructed from search snippets and prior knowledge rather than from a
          live response. {probed.length} of {corpora.length} hosts here have been
          successfully probed. Across the whole access schedule the figure is{" "}
          {state.hosts_reachable} of {state.hosts_in_access_schedule}.
        </p>
        <p>
          By the register&rsquo;s own standard that makes this catalogue{" "}
          <span className="voice-mono">V0-UNRESOLVED</span>: format-valid, internally
          consistent, and unverified. It is published in that state, marked as such, rather
          than held back — and the register applies the same rule to it that it applies to
          anyone else&rsquo;s citation.
        </p>
        <p className="t-small">
          Robots posture is recorded as <em>unverified, strictest reading binding</em> until
          a probe proves otherwise. The register does not assume access it has not
          demonstrated.
        </p>
      </Block>

      {/* ==================================================================
          §2 — THE CORPUS REGISTRY.
          ================================================================== */}

      <SectionHead
        code="§2"
        id="corpora"
        title="The corpus registry"
        margin={
          <>
            <Tag k="doc" /> Host tier and content tier are separate columns. See{" "}
            <a href="/method#provenance">/method §6</a> for why.
          </>
        }
      />

      <Block code="§2.1" wide>
        <div
          className="scroll-region"
          role="region"
          aria-label="The corpus registry"
          tabIndex={0}
        >
          <table>
            <thead>
              <tr>
                <th scope="col">Siglum</th>
                <th scope="col">Corpus</th>
                <th scope="col">Beat</th>
                <th scope="col">Host</th>
                <th scope="col">Host</th>
                <th scope="col">Content</th>
                <th scope="col">Egress</th>
                <th scope="col">Flags</th>
                <th scope="col">Value to the register</th>
              </tr>
            </thead>
            <tbody>
              {corpora.map((c) => (
                <tr key={c.slug} id={`s-${c.slug}`}>
                  <th scope="row" className="siglum">
                    {c.slug}
                  </th>
                  <td>{c.name}</td>
                  <td className="t-micro">{c.beat}</td>
                  <td className="siglum">{c.host}</td>
                  <td className="voice-mono">{c.host_tier}</td>
                  <td className="voice-mono">{c.content_tier}</td>
                  <td className="voice-mono">
                    {c.egress_state}
                    <div className="t-micro" style={{ color: "var(--ink-3)" }}>
                      {c.egress_probed_at ?? "never probed"}
                    </div>
                  </td>
                  <td className="voice-mono">
                    {[
                      c.tier_trap ? "TIER-TRAP" : null,
                      c.adversary_writable ? "WRITABLE" : null,
                      c.machine_generated_blocklist ? "MACHINE-GEN" : null,
                    ]
                      .filter(Boolean)
                      .join(" · ") || "—"}
                  </td>
                  <td>
                    {c.value}
                    {c.rate_limits ? (
                      <div className="t-micro" style={{ marginTop: "var(--s-1)" }}>
                        {c.rate_limits}
                      </div>
                    ) : null}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Block>

      <Block code="§2.2" id="flags">
        <h3>The flags, and why each one changes what a source can be used for</h3>
        <dl className="dl-prose">
          <div className="defn">
            <dt>TIER-TRAP</dt>
            <dd>
              A host whose tier differs from its content&rsquo;s tier — most often a lower-
              tier host faithfully serving primary documents. {traps.length} here. Host tier
              and content tier are separate columns for exactly this reason: a scanned
              agency release does not become less primary for sitting in an enthusiast
              archive, and a clean domain does not upgrade the text it serves.
            </dd>
          </div>
          <div className="defn">
            <dt>WRITABLE</dt>
            <dd>
              Adversary-writable — anyone can edit it. {writable.length} here. Usable as a
              lead only, never as a witness, and replication of one edit into many renderers
              remains <strong>one lineage</strong> however many sites carry it.
            </dd>
          </div>
          <div className="defn">
            <dt>MACHINE-GEN</dt>
            <dd>
              On the versioned machine-generated blocklist. {blocklisted.length} here. Also
              caught by a mechanical heuristic, <em>because the blocklist will always lag</em>{" "}
              — and the failure of contamination detection against regenerated rather than
              copied text is one of the sixteen original defects (
              <a href="/corrections#C-001">C-001</a>, S5).
            </dd>
          </div>
        </dl>
      </Block>

      {/* ==================================================================
          §3 — THE DOCUMENT SIGLA. Empty, because the citation graph is empty.
          ================================================================== */}

      <SectionHead
        code="§3"
        id="documents"
        title="Document sigla"
        margin={
          <>
            <Tag k="doc" /> One row per document node in the citation graph. Populated by
            grading, not by cataloguing.
          </>
        }
      />

      <Block code="§3.1" wide>
        <div className="empty-block">
          <p style={{ fontWeight: 600 }}>
            {state.documents_in_citation_graph} documents in the citation graph.
          </p>
          <p>
            A document acquires a siglum when an observation cites it and that citation
            resolves to bytes. No candidate has been graded, so no observation exists, so
            there is nothing here. This table is the key to the lineage spine on every entry
            sheet; when entries exist, each row will carry the document&rsquo;s siglum, its
            origin tier, how it was accessed, whether it was produced in the course of the
            activity or written about it afterwards, and the propositions it touches.
          </p>
          <p className="t-small" style={{ marginBottom: 0 }}>
            The corpus registry above is the list of places the register will look. This is
            the list of things it has found. The first is curated; the second is earned.
          </p>
        </div>
      </Block>

      <SectionHead code="§4" id="tiers" title="The tier vocabulary" />

      <Block
        code="§4.1"
        margin={
          <>
            <Tag k="doc" /> A tier is never a quality judgement about an author. It is a
            statement about custody and about what a document is.
          </>
        }
      >
        <dl className="dl-prose">
          <div className="defn">
            <dt>T1</dt>
            <dd>
              Primary record under institutional custody: an agency&rsquo;s own document,
              served by that agency or a national archive.
            </dd>
          </div>
          <div className="defn">
            <dt>T2</dt>
            <dd>
              Archived or mirrored primary material with documented retrieval integrity — an
              archive is a <em>channel</em>, not a tier, and a faithfully scanned document
              keeps its own tier through it.
            </dd>
          </div>
          <div className="defn">
            <dt>T3</dt>
            <dd>
              Edited secondary publication with named authorship and an editorial process.
            </dd>
          </div>
          <div className="defn">
            <dt>T4</dt>
            <dd>
              Aggregators, reference sites and unedited secondary compilation — the tier
              where citogenesis lives.
            </dd>
          </div>
          <div className="defn">
            <dt>T5</dt>
            <dd>
              Unattributable testimony, anonymous posts, and material with no custody chain.
              Not worthless: it is frequently the <em>origin</em> artifact, and origin is a
              proposition this register grades on its own merits.
            </dd>
          </div>
        </dl>
        <p className="t-small">
          Alongside the tier, every source carries its <strong>causal provenance</strong>:
          whether the document was produced in the course of doing the thing (a contract
          award, a permit, a construction line) or written about it afterwards. The first
          kind is a by-product and is much harder to fabricate at scale.
        </p>
      </Block>
    </div>
  );
}
