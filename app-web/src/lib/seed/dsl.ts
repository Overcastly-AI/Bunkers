/**
 * A SMALL AUTHORING DSL for the specimen observations.
 *
 * Its only purpose is to keep the calibration fixtures readable, so that a
 * reviewer holding `docs/CALIBRATION.md` open beside `entities/*.ts` can check
 * a case line by line. It deliberately has NO parameter for `membership`,
 * `signed_weight`, or `exclusion_reason` — those are generated (see
 * `membership.ts`), and there is no way to reach them from here.
 */

import type {
  CausalProvenance,
  Channel,
  CorpusEra,
  Diagnosticity,
  EaAlternative,
  EaExpectedness,
  EvidenceScope,
  EvidenceSign,
  OriginTier,
  PropertyLocus,
  RefutationState,
  XLevel,
} from "../types/enums";
import { hex } from "./build";
import type { SpecObservation, SpecReceipt } from "./types";

/** A deterministic synthetic digest. Stands where a real sha256 will stand. */
export function digest(seed: string): string {
  return hex(`sha:${seed}`, 64);
}

/**
 * `receipt_verified_requires_everything` — a CHECK constraint, so VERIFIED is
 * unreachable without grammar + resolution at issuer (or a designated mirror)
 * + HTTP 200 + a stored hash + an issuer-metadata match. Constructing one here
 * means asserting all five, which is why there is no shorthand for a
 * half-verified receipt.
 */
export function ok(seed: string, url?: string, mirror = false): SpecReceipt {
  return {
    state: "VERIFIED",
    resolved_url: url,
    http_status: 200,
    sha256: digest(seed),
    retrieved_at: "2026-07-14T09:12:00Z",
    mirror_only: mirror,
    issuer_metadata_match: true,
    content_drifted: false,
  };
}

/** UNRESOLVED-NOTFOUND. The grammar passed and the document does not exist. */
export function notFound(url?: string): SpecReceipt {
  return {
    state: "UNRESOLVED",
    resolved_url: url,
    http_status: 404,
    unresolved_kind: "NOTFOUND",
  };
}

/**
 * UNRESOLVED-UNREACHABLE. Never conflated with NOTFOUND: collapsing them would
 * let a blocked proxy inflate the register's own published fabrication metric.
 */
export function unreachable(url?: string): SpecReceipt {
  return {
    state: "UNRESOLVED",
    resolved_url: url,
    http_status: null as unknown as number,
    unresolved_kind: "UNREACHABLE",
  };
}

/** A receipt FOR AN ABSENCE. Absence is not citable without one. */
export function negativeReceipt(seed: string): SpecReceipt {
  return {
    state: "NEGATIVE",
    http_status: 200,
    sha256: digest(seed),
    retrieved_at: "2026-07-14T09:12:00Z",
    issuer_metadata_match: true,
  };
}

export interface EvOpts {
  /** Diagnosticity D0..D4, a five-stop discrete ordinal. Never interpolated. */
  d: Diagnosticity;
  sign?: EvidenceSign;
  locus?: PropertyLocus;
  scope?: EvidenceScope;
  tier?: OriginTier;

  doc?: string;
  issuer?: string;
  author?: string;
  date?: string;
  ident?: string;
  identClass?: string;
  url?: string;
  corpus?: string;
  host?: string;
  siglum?: string;

  channel?: Channel;
  provenance?: CausalProvenance;
  era?: CorpusEra;
  adversary?: boolean;
  selfAttesting?: string;
  registerEcho?: boolean;

  receipt?: SpecReceipt;
  /** Passing a quote satisfies §3.4(d): the record names the fact on its face. */
  quote?: [text: string, start: number, end: number];
  bindingQuote?: string;
  /** §3.4(e): the issuer has authority over the fact, not merely over a licence. */
  authority?: boolean;
  binding?: boolean;
  fact?: string;
  lineage?: string;
  superseded?: boolean;
  ea?: [EaExpectedness, EaAlternative];
  refutes?: RefutationState;
  rebutted?: string;
  excludesNull?: boolean;
  documentsNull?: boolean;
  negative?: {
    query: string;
    result_count?: number;
    corpus_as_of?: string;
    erp?: string;
    x?: XLevel;
  };
  egress?: string;
}

/** One row of `core.observation`. One tick on the evidence bar. */
export function ev(key: string, statement: string, o: EvOpts): SpecObservation {
  const hasDoc =
    o.doc !== undefined || o.tier !== undefined || o.selfAttesting !== undefined;
  return {
    key,
    statement,
    sign: o.sign ?? "SUPPORTS",
    magnitude: o.d,
    scope: o.scope ?? "INSTANCE",
    property_locus: o.locus ?? "CLAIM-PROPERTY",
    subject_binding_pass: o.binding ?? true,
    fact_key: o.fact,
    diagnosticity_source: o.ea ? "MATRIX" : "CATALOG",
    ea_expectedness: o.ea?.[0],
    ea_alternative: o.ea?.[1],
    null_excluding: o.excludesNull,
    documents_null: o.documentsNull,
    gate: {
      e_authority: o.authority ?? false,
    },
    refutation_class: o.refutes,
    rebutted: o.rebutted !== undefined,
    rebuttal_note: o.rebutted,
    superseded: o.superseded,
    lineage_id: o.lineage,
    document: hasDoc
      ? {
          title: o.doc ?? "(untitled record)",
          issuing_body: o.issuer,
          author_name: o.author,
          document_date: o.date,
          identifier: o.ident,
          identifier_class: o.identClass,
          url: o.url,
          origin_tier: o.tier ?? "T1",
          channel: o.channel ?? "ORIGIN-HOST",
          causal_provenance: o.provenance ?? "UNSOLICITED",
          corpus_era: o.era ?? "PRE-2022",
          corpus_name: o.corpus,
          corpus_host: o.host,
          adversary_writable: o.adversary,
          egress_state: o.egress ?? "REACHABLE",
          self_attesting: o.selfAttesting !== undefined,
          self_attesting_rationale: o.selfAttesting,
          register_echo_quarantined: o.registerEcho,
          siglum: o.siglum,
        }
      : undefined,
    receipt: o.receipt ?? (o.negative ? negativeReceipt(key) : ok(key, o.url)),
    quote: o.quote
      ? { text: o.quote[0], start: o.quote[1], end: o.quote[2] }
      : undefined,
    binding_quote: o.bindingQuote,
    negative_search: o.negative
      ? {
          query: o.negative.query,
          corpus_as_of: o.negative.corpus_as_of ?? "2026-07-01",
          result_count: o.negative.result_count ?? 0,
          erp_profile: o.negative.erp,
          expected_record_level: o.negative.x,
        }
      : undefined,
  };
}
