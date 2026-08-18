import type { Metadata } from "next";

import { Block, SectionHead, Tag } from "@/components/Doc";
import { getRepository } from "@/lib/repository";

export const metadata: Metadata = {
  title: "Expected records — the table that licenses the argument from silence · BUNKERS",
  description:
    "The versioned expected-record profiles: what documentary silence is allowed to mean, per record class, era and controlling authority.",
};

/**
 * `/method/expected-records` — THE ERP TABLE, PUBLISHED.
 *
 * DESIGN.md §13 gives this its own URL rather than a section on `/method`,
 * because it is a reference table a reader returns to and cites, not an
 * explanation they read once.
 *
 * `GRADING.md`: "This is the table that licenses the argument from silence for
 * DUCC and forbids it for Greenbrier-1991. It is also the highest-value artifact
 * the W0 registries produced."
 *
 * The X-level column is the whole instrument. X0 means NO RECORD OF THIS CLASS
 * WOULD BE EXPECTED, and an X0 profile produces NO ROWS — not zeros. Printing a
 * zero there would convert "we would not expect to find this" into "we looked
 * and found none", which is the exact inference this table exists to block.
 */
export default async function ExpectedRecordsPage() {
  const rows = await getRepository().listExpectedRecords();

  const x0 = rows.filter((r) => r.x_level === "X0");
  const overrides = rows.filter((r) => r.silence_override !== null);

  return (
    <div className="doc">
      <Block
        code="§0"
        margin={
          <>
            <Tag k="doc" /> <span className="voice-mono">registry.erp_profile</span>,
            keyed on record class × era × controlling authority × classification posture.
            Method at <a href="/method#silence">/method §8</a>.
          </>
        }
      >
        <h1>Expected records</h1>

        <div className="rule-block t-lede">
          The argument from silence is valid only where the silence is surprising. This
          table is where the register decides, in advance and in public, which silences
          those are.
        </div>

        <p>
          Before an absence is allowed to count for or against anything, the register
          consults a profile: <em>would a record of this class be expected to exist, and
          to be public, for a facility of this type, in this period, under this
          authority?</em> The answer is a level from{" "}
          <span className="voice-mono">X0</span> to <span className="voice-mono">X3</span>{" "}
          and, where the profile is decisive, an explicit override of the silence reading.
        </p>
        <p>
          <strong>
            The same table forbids the inference in one case and licenses it in another.
          </strong>{" "}
          That is the point of writing it down rather than judging case by case: a
          facility under commercial cover produces no federal construction record{" "}
          <em>by design</em>, so its absence is not evidence against it — while an
          excavation of the asserted scale under an appropriated defence programme would
          produce a construction line, and its absence is a finding.
        </p>
      </Block>

      <SectionHead
        code="§1"
        id="levels"
        title="The levels"
        margin={
          <>
            <Tag k="doc" /> An <span className="voice-mono">X0</span> profile produces no
            rows, not zeros. {x0.length} of the {rows.length} profiles below are{" "}
            <span className="voice-mono">X0</span>.
          </>
        }
      />

      <Block code="§1.1">
        <dl className="dl-prose">
          <div className="defn">
            <dt>X0</dt>
            <dd>
              <strong>No record of this class would be expected.</strong> The searches are
              still executed and their negative receipts still logged — but a grading run
              that scores those absences against the facility has failed. The entry sheet
              prints the sentence in full:{" "}
              <em>
                no public record of this class would be expected for a facility of this
                type in this period under this authority; the absence is not evidence
                against.
              </em>
            </dd>
          </div>
          <div className="defn">
            <dt>X1</dt>
            <dd>
              The class existed and was disposed of under an approved retention schedule.
              Distinct from searched-and-empty and distinct from unsearched — the record is
              gone, which is a fact about the archive rather than about the facility.
            </dd>
          </div>
          <div className="defn">
            <dt>X2</dt>
            <dd>
              Expected to exist, partially public. Coverage is real but incomplete, so
              absence is weak evidence at best.
            </dd>
          </div>
          <div className="defn">
            <dt>X3</dt>
            <dd>
              Expected to exist and expected to be public.{" "}
              <strong>Here an absence is informative</strong> — though never on its own
              sufficient to refute: refutation requires affirmative disconfirming evidence,
              not merely a hole where a document should be.
            </dd>
          </div>
        </dl>
      </Block>

      <SectionHead
        code="§2"
        id="profiles"
        title="The profiles"
        margin={
          <>
            <Tag k="doc" /> {rows.length} profiles published. {overrides.length} carry an
            explicit silence override; the rest inform the reading without dictating it.
          </>
        }
      />

      <Block code="§2.1" wide>
        <div
          className="scroll-region"
          role="region"
          aria-label="Expected-record profiles"
          tabIndex={0}
        >
          <table>
            <thead>
              <tr>
                <th scope="col">Profile</th>
                <th scope="col">X</th>
                <th scope="col">Record class</th>
                <th scope="col">Era</th>
                <th scope="col">Authority note</th>
                <th scope="col">Override</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((r) => (
                <tr key={r.profile_key} id={r.profile_key}>
                  <th scope="row" className="siglum">
                    {r.profile_key}
                  </th>
                  <td className="voice-mono">{r.x_level}</td>
                  <td>{r.description}</td>
                  <td className="voice-mono">
                    {r.era_from ?? "—"}–{r.era_to ?? "  "}
                  </td>
                  <td>
                    {r.authority_note}
                    {r.destroying_event ? (
                      <div className="t-micro" style={{ marginTop: "var(--s-1)" }}>
                        destroying event: {r.destroying_event}
                      </div>
                    ) : null}
                  </td>
                  <td className="voice-mono">{r.silence_override ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <p className="t-small legend-note" style={{ marginTop: "var(--s-3)" }}>
          An era with no closing year is open: the profile still applies. An em dash in the
          override column means the profile informs the silence reading without dictating
          it.
        </p>
      </Block>

      <SectionHead code="§3" id="incomplete" title="What this table does not cover" />

      <Block
        code="§3.1"
        margin={
          <>
            <Tag k="doc" /> <a href="/limits#L-15">L-15</a> — the curated tables are
            asserted, not derived, and they are the new attack surface.
          </>
        }
      >
        <div className="flag-block">
          <div className="flag-head">Standing limitation</div>
          <p>
            This table encodes a policy about how American secrecy works, and{" "}
            <strong>being wrong here is invisible</strong>. A wrong profile does not
            produce an error; it silently licenses or forbids the argument from silence for
            every candidate it touches. Moving that judgement out of per-candidate scoring
            and into a versioned lookup makes it auditable and back-fittable, which is a
            real improvement — but it is a <em>relocation</em> of judgement, not an
            elimination of it.
          </p>
        </div>
        <p>
          The {rows.length} profiles above are the ones the calibration suite exercises.
          They are US-specific in every dimension — record classes, identifier grammars,
          retention schedules and controlling authorities — and the table would need
          rebuilding per country before this register could grade anything outside the
          United States.
        </p>
        <p className="t-small">
          The deeper problem is coverage of the archive itself: roughly 96% of textual
          holdings at the National Archives are undigitised, the construction record for
          the period of interest lives in record groups that are not online, and county
          records digitise back only to the 1990s while every facility of interest was
          permitted between 1950 and 1975. The grade distribution this register publishes
          is therefore <strong>a map of digitisation, not a map of evidence</strong>. That
          bias is not correctable by design — only disclosable. It is disclosed at{" "}
          <a href="/limits#L-5">L-5</a>.
        </p>
      </Block>
    </div>
  );
}
