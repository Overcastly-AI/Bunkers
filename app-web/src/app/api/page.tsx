import type { Metadata } from "next";

import { Block, SectionHead, Tag } from "@/components/Doc";
import { getRepository } from "@/lib/repository";

export const metadata: Metadata = {
  title: "Machine surface and colophon · BUNKERS",
  description:
    "The machine-readable endpoints, the provenance beacon, the house citation style, and the colophon.",
};

/**
 * `/api` — MACHINE-READABLE ENDPOINTS AND THE PROVENANCE BEACON, plus the
 * colophon (§13.8).
 *
 * The two are on one page deliberately. §13.8 says the colophon is "NOT A
 * FOOTER" and gives it no URL of its own in the §13 IA; what it lists —
 * typefaces and licences, tile source and attribution, data licence, build hash,
 * PROVENANCE BEACON URL — is the same subject as this page: how this object is
 * made and how a machine may consume it. Putting the beacon URL in one place and
 * its documentation in another would be the split worth avoiding.
 *
 * A NOTE ON WHAT THIS PAGE MAY PROMISE. The endpoints below are the read surface
 * the schema publishes. This deployment is reading its local seed, so they are
 * documented rather than demonstrated, and the page says which is which instead
 * of printing a base URL that would 404. An API page that documents endpoints
 * nobody can call, without saying so, is the same defect as a padded source
 * table.
 */
export default async function ApiPage() {
  const repo = getRepository();
  const state = await repo.getRegisterState();
  const live = repo.kind === "supabase";

  return (
    <div className="doc">
      <Block
        code="§0"
        margin={
          <>
            <Tag k="doc" /> Data source currently answering:{" "}
            <span className="voice-mono">{repo.kind}</span>.
          </>
        }
      >
        <h1>Machine surface</h1>

        <div className="rule-block t-lede">
          Everything the register publishes to a reader, it publishes to a program — with
          the evidence state hash that makes a grade citable at a point in time.
        </div>

        <p>
          A grade is versioned, so a citation to one is only meaningful with the state it
          was read at. Every response carries an{" "}
          <span className="voice-mono">evidence_state_hash</span>, and so does every
          citation the interface prints. Two readers quoting the same entry at different
          times can tell that they are quoting different objects.
        </p>

        <div className="flag-block">
          <div className="flag-head">Current state</div>
          <p style={{ marginBottom: 0 }}>
            {live ? (
              <>
                The published read surface is live and serving{" "}
                {state.candidates_published} candidates.
              </>
            ) : (
              <>
                <strong>These endpoints are documented, not live.</strong> This deployment
                reads a local calibration seed, and the register holds{" "}
                {state.candidates_published} candidates, so there is nothing behind them to
                serve. The shapes below are the schema&rsquo;s published projection and will
                not change when data arrives — the layout of this page does not change when
                the register fills, which is the same rule the catalogue table follows.
              </>
            )}
          </p>
        </div>
      </Block>

      {/* ==================================================================
          §1 — THE READ SURFACE.
          ================================================================== */}

      <SectionHead
        code="§1"
        id="endpoints"
        title="The read surface"
        margin={
          <>
            <Tag k="doc" /> One projection per object. The internal schema is not exposed;
            only the published views are.
          </>
        }
      />

      <Block code="§1.1">
        <p>
          The register exposes a small set of read-only projections. There is no write
          surface, no authentication, and no login — the register is public, and its
          anonymous read role can reach published, verified rows and nothing else.
        </p>

        <dl className="dl-prose">
          <div className="defn">
            <dt>register_entry</dt>
            <dd>
              The catalogue: one row per entity with its twelve-class grade matrix. Carries{" "}
              <strong>no composite grade</strong>, because the entity has none — there is no
              field for one, in the response shape or anywhere else.
            </dd>
          </div>
          <div className="defn">
            <dt>proposition_badge</dt>
            <dd>
              One row per graded proposition: band, ceiling, at-ceiling, applied caps,
              limiting condition, lineage counts, search completeness, silence reading,
              marginal flag. This is what a stave renders.
            </dd>
          </div>
          <div className="defn">
            <dt>candidate_detail</dt>
            <dd>
              One entity in full: identity, propositions, observations with their membership
              sets and exclusion reasons, silence table, search log, grade history.
            </dd>
          </div>
          <div className="defn">
            <dt>claims_register</dt>
            <dd>
              Propositions at <span className="voice-mono">E</span>,{" "}
              <span className="voice-mono">F</span>, <span className="voice-mono">R</span>{" "}
              and <span className="voice-mono">X</span> with their origin work, ordered by
              origin date ascending.
            </dd>
          </div>
          <div className="defn">
            <dt>map_feature · map_cluster</dt>
            <dd>
              Plate geometry, already gated: nothing below band{" "}
              <span className="voice-mono">D</span>, and{" "}
              <strong>no coordinate for anything the positional gate suppressed</strong>. The
              label anchor used internally for clustering is not in the projection, so no
              client can paint it.
            </dd>
          </div>
          <div className="defn">
            <dt>methodology_coverage · expected_records</dt>
            <dd>
              The curated tables: the corpus registry with tiers and egress state, and the
              expected-record profiles that govern the argument from silence.
            </dd>
          </div>
          <div className="defn">
            <dt>telemetry_*</dt>
            <dd>
              The register&rsquo;s measurements of itself: confabulation by agent, band
              occupancy, refutation and reversal counts.
            </dd>
          </div>
        </dl>
      </Block>

      <Block code="§1.2" id="plate-endpoints">
        <h3>Live endpoints in this deployment</h3>
        <p>
          Two endpoints are served by this application rather than by the database, because
          the work they do must not move to the browser:
        </p>
        <div className="machine">{`GET /api/plate/viewport
      ?west&south&east&north&zoom[&min_grade][&typology]
  -> { mode: "clusters", zoom, clusters[] }
   | { mode: "features", zoom, features[] }

GET /api/plate/geometry-assertions?slug=<entity-slug>
  -> CompetingGeometry[]   // every non-superseded assertion, unreconciled`}</div>
        <p className="t-small">
          Clustering stays on the server because a browser that grouped features into bins
          of its own would be inventing positions. The second endpoint returns{" "}
          <strong>every competing assertion at once</strong> and has no parameter to request
          only the preferred one — four sources putting a facility in four different places
          is a finding, and averaging them would produce a point no source asserts.
        </p>
      </Block>

      {/* ==================================================================
          §2 — THE PROVENANCE BEACON.
          ================================================================== */}

      <SectionHead
        code="§2"
        id="beacon"
        title="The provenance beacon"
        margin={
          <>
            <Tag k="doc" /> No beacon is emitted for a calibration specimen. A fixture must
            not be machine-readable as a register entry.
          </>
        }
      />

      <Block code="§2.1">
        <p>
          Every entry sheet carries a machine-readable provenance link in its head and a
          copy control beside its title. The beacon resolves to the entry&rsquo;s state at a
          specific evidence hash, so a program that cites the register can record{" "}
          <em>what it read</em> rather than <em>where it read it</em>.
        </p>
        <div className="machine">{`<link rel="provenance" href="/api/provenance/<slug>#<evidence_state_hash>">`}</div>
        <p>
          <strong>Specimen sheets emit no beacon.</strong> That is one of six containment
          mechanisms keeping calibration fixtures from being mistaken for register entries:
          a separate URL namespace, a no-index directive, a persistent header rule, a hatched
          margin rule running the length of the page, the marker embedded in every stave&rsquo;s
          accessible name, exclusion from every count — and no beacon. None of them closes
          the risk fully, and the register says so.
        </p>
      </Block>

      <Block code="§2.2" id="citation">
        <h3>House citation style</h3>
        <p>
          The form the register uses for itself, and asks others to use. The hash is not
          decoration — it is the reproducibility claim:
        </p>
        <div className="machine">{`BUNKERS Register. "<preferred name>." Entry <ref>,
proposition <proposition_id>, grade <band> as of <date>.
BES v0.2; evidence state <evidence_state_hash>.
<url>#<proposition_id>`}</div>
        <p className="t-small">
          A citation to an entity without a proposition is malformed. There is no site-wide
          grade to cite — the unit of grading is the proposition, and a citation that omits
          it is asserting something the register does not publish.
        </p>
      </Block>

      {/* ==================================================================
          §3 — THE COLOPHON.
          ================================================================== */}

      <SectionHead
        code="§3"
        id="colophon"
        title="Colophon"
        margin={
          <>
            <Tag k="doc" /> Not a footer. Credits, licences and the standing rule.
          </>
        }
      />

      <Block code="§3.1" wide>
        <dl className="dl">
          <dt>typefaces</dt>
          <dd>
            IBM Plex Sans, Mono and Serif — SIL Open Font License 1.1, self-hosted, no
            vendor request
          </dd>
          <dt>voices</dt>
          <dd>mono = computed · sans = written by the register · serif = quoted verbatim</dd>
          <dt>basemap</dt>
          <dd>self-hosted vector tiles; no commercial tile vendor, no API key</dd>
          <dt>map data</dt>
          <dd>© OpenStreetMap contributors, ODbL</dd>
          <dt>land status</dt>
          <dd>PAD-US, U.S. Geological Survey</dd>
          <dt>terrain</dt>
          <dd>3DEP / SRTM, U.S. Geological Survey</dd>
          <dt>positional conventions</dt>
          <dd>IHO INT-1 / U.S. Chart No. 1 — PA · PD · ED · Rep</dd>
          <dt>grading model</dt>
          <dd>{state.rubric_version}</dd>
          <dt>rubric · tier · diagnosticity · ERP · typology</dt>
          <dd>
            v{state.rubric_version.replace(/^BES-/, "")} · v{state.tier_version} · v
            {state.diagnosticity_version} · v{state.erp_version} · v{state.typology_version}
          </dd>
          <dt>third-party requests at read time</dt>
          <dd>none — no analytics, no tag manager, no font CDN, no embedded media</dd>
        </dl>
      </Block>

      <Block code="§3.2">
        <div className="rule-block t-lede">
          Nothing is deleted. Refuted and F-grade entries are retained with their refutations
          attached.
        </div>
        <p className="t-small">
          The register publishes what it can establish, from what, and how well. Its second
          line of defence is self-verification, not independent verification — that claim is
          absent, not merely weaker (<a href="/decisions#D-006">D-006</a>,{" "}
          <a href="/limits#L-3">L-3</a>). What the model does not solve is at{" "}
          <a href="/limits">/limits</a>; what it got wrong is at{" "}
          <a href="/corrections">/corrections</a>.
        </p>
      </Block>
    </div>
  );
}
