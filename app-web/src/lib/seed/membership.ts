/**
 * THE GENERATED COLUMNS, RECOMPUTED.
 *
 * `core.observation.membership` is `GENERATED ALWAYS ... STORED` in the DDL and
 * `core.observation.exclusion_reason` is generated alongside it. SCHEMA.md §0
 * is explicit about why: "an agent would write `V`". The seed is written by an
 * agent. So the seed does not get to write it either — these functions compile
 * the same seven BES §2.4 exclusions the generated column compiles, from the
 * same fields, and the builder calls them.
 *
 * The consequence is that a specimen author cannot make a row count toward a
 * grade by declaring that it counts. To move a row into V they have to give it
 * a verified receipt, instance scope, a passing subject binding, a non-hostile
 * channel, unsolicited provenance and a pre-waterline era — which is the whole
 * argument of the register, enforced in the fixture.
 */

import type { EvidenceMembership, EvidenceScope } from "../types/enums";
import type { SpecObservation } from "./types";

/**
 * SCHEMA.md §5 / §6. A receipt discharges the resolve-or-die rule when it is
 * VERIFIED (the CHECK constraint already guarantees grammar + resolution +
 * HTTP 200 + hash + issuer metadata behind that one word), or when it is a
 * NEGATIVE receipt — the receipt FOR AN ABSENCE, which is what licenses an
 * argument from silence at all. UNRESOLVED and DEAD are not receipts; they are
 * the record of a failure to obtain one, and they land in V0.
 */
export function receiptDischarged(o: SpecObservation): boolean {
  const s = o.receipt?.state;
  if (s === "VERIFIED") return true;
  if (s === "NEGATIVE" && o.negative_search) return true;
  return false;
}

/**
 * `core.sync_observation_provenance()` — subject binding is enforced, not
 * requested. A failed binding demotes INSTANCE to CLASS, which removes the row
 * from V WITHOUT DELETING IT. This is the countermeasure to the commonest
 * real-world failure: a genuine record attributed to the wrong site.
 */
export function effectiveScope(o: SpecObservation): EvidenceScope {
  if (o.subject_binding_pass === false && o.scope === "INSTANCE") return "CLASS";
  return o.scope;
}

/** The reasons, in the order the generated column tests them. */
type Exclusion =
  | { kind: "V0"; reason: string }
  | { kind: "INERT"; reason: string }
  | null;

function firstExclusion(o: SpecObservation): Exclusion {
  if (!receiptDischarged(o)) {
    const s = o.receipt?.state;
    if (s === "UNRESOLVED" || s === undefined) {
      const k = o.receipt?.unresolved_kind ?? "NOTFOUND";
      return {
        kind: "V0",
        reason:
          `UNRESOLVED-${k} — the citation was not resolved to bytes at an issuing ` +
          `authority. Retained and counted as measured fabrication telemetry; ` +
          `contributes nothing to any condition.`,
      };
    }
    if (s === "DEAD") {
      return {
        kind: "V0",
        reason:
          "DEAD — the resolved location no longer serves the document and no " +
          "faithful mirror carries it. Retained; contributes nothing.",
      };
    }
    return {
      kind: "V0",
      reason: "receipt unverified — the retrieval chain did not complete.",
    };
  }

  const d = o.document;
  const scope = effectiveScope(o);

  if (o.sign === "NEUTRAL") {
    return {
      kind: "INERT",
      reason:
        "NEUTRAL sign — the row bears on the proposition in neither direction. " +
        "Displayed; arithmetically inert.",
    };
  }
  if (o.superseded) {
    return {
      kind: "INERT",
      reason: "superseded by a later assertion. Retained; nothing is deleted.",
    };
  }
  if (scope !== "INSTANCE") {
    if (o.subject_binding_pass === false) {
      return {
        kind: "INERT",
        reason:
          "subject binding failed — the document does not bind to this entity, " +
          "so scope was demoted INSTANCE -> CLASS by trigger. A genuine record " +
          "attributed to the wrong site is removed from V without being deleted.",
      };
    }
    return {
      kind: "INERT",
      reason:
        scope === "ADJACENT"
          ? "scope ADJACENT — the record is about a neighbouring subject. " +
            "PROXIMITY IS NOT SUPPORT."
          : "scope CLASS — the record is about the class, not this instance. " +
            "Class evidence is not credited at full strength to every instance.",
    };
  }
  if (d?.self_attesting) {
    return {
      kind: "INERT",
      reason:
        `SELF-ATTESTING — ${d.self_attesting_rationale ?? "the claimant is the source and the artifact is the claim"}. ` +
        "Excluded from V and routed to the ORIGIN proposition, where it is " +
        "evidence of the claim's origin rather than of the claim.",
    };
  }
  if (d?.channel === "ADVERSARY-WRITABLE" || d?.adversary_writable) {
    return {
      kind: "INERT",
      reason:
        "ADVERSARY-WRITABLE channel — any anonymous party can write this field. " +
        "Retained as a discovery pointer with its author, timestamp and comment.",
    };
  }
  if (
    d?.causal_provenance !== undefined &&
    d.causal_provenance !== "UNSOLICITED" &&
    d.causal_provenance !== "SOLICITED-3P"
  ) {
    return {
      kind: "INERT",
      reason:
        `causal provenance ${d.causal_provenance} — the record exists because the ` +
        "claimant caused it to exist. Host tier is not author tier.",
    };
  }
  if (d?.corpus_era === "POST-2022-UNATTRIBUTED") {
    return {
      kind: "INERT",
      reason:
        "POST-2022-UNATTRIBUTED — first observed after the machine-generated-text " +
        "waterline with no named author, no byline history and no pre-2022 domain " +
        "capture. Computed from Wayback CDX and domain registration, never judged, " +
        "and never by an AI-text classifier.",
    };
  }
  if (d?.register_echo_quarantined) {
    return {
      kind: "INERT",
      reason:
        "REGISTER ECHO — first observed after this register published the " +
        "candidate. Quarantined: zero lineages, zero conditions. A grade may rise " +
        "only on evidence whose own document date precedes our publication.",
    };
  }
  return null;
}

export function deriveMembership(o: SpecObservation): EvidenceMembership {
  const ex = firstExclusion(o);
  if (ex) return ex.kind;
  return o.sign === "UNDERCUTS" ? "U" : "V";
}

export function deriveExclusionReason(o: SpecObservation): string | null {
  return firstExclusion(o)?.reason ?? null;
}

/** `signed_weight` GENERATED: magnitude x sign. Always carries an explicit sign. */
export function signedWeight(o: SpecObservation): number {
  if (o.sign === "NEUTRAL") return 0;
  return o.sign === "UNDERCUTS" ? -o.magnitude : o.magnitude;
}

/**
 * `observation_d4_is_the_gate` — a CHECK constraint, not a policy. All six §3.4
 * conditions or the row cannot be D4. Reported here so the entry page can show
 * WHICH condition failed rather than only that the row is D3.
 */
export function gateConditions(o: SpecObservation) {
  const scope = effectiveScope(o);
  const d = o.document;
  const g = o.gate ?? {};
  return {
    a_tier: g.a_tier ?? (d?.origin_tier === "T1" || d?.origin_tier === "T2"),
    b_receipt: g.b_receipt ?? receiptDischarged(o),
    c_instance: g.c_instance ?? scope === "INSTANCE",
    d_on_its_face: g.d_on_its_face ?? Boolean(o.quote),
    e_authority: g.e_authority ?? false,
    f_unsolicited:
      g.f_unsolicited ?? (d?.causal_provenance ?? "UNSOLICITED") === "UNSOLICITED",
  };
}

export function gatePass(o: SpecObservation): boolean {
  return Object.values(gateConditions(o)).every(Boolean);
}
