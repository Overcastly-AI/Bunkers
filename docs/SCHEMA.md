# SCHEMA — WHAT THE DATABASE GUARANTEES

Companion to `supabase/schema.sql` (the executable DDL) and `docs/GRADING.md` (the model it
implements). This file explains *why* the schema is shaped the way it is, table by table, and gives
worked query examples.

**Verified:** applies clean from an empty database on PostgreSQL 16.13 + PostGIS 3.4; the 65-assertion
acceptance suite (`supabase/test_acceptance.sql`) passes 65/65 with zero failures. 56 tables, 9 API
views, 2 materialised views, 51 functions, 167 indexes, 101 RLS policies, 88 CHECK constraints, 22
triggers.

---

## 0. THE DESIGN CONSTRAINT THAT DETERMINES EVERYTHING

> **The register is populated entirely by LLM agents. They confabulate, hallucinate plausible document
> identifiers, and misattribute real documents to the wrong facility. Any design that assumes
> trustworthy agent output is broken before it ships.**

That sentence is the reason for most of what follows. The practical test applied to every field was:
*can an agent satisfy this by asserting it?* Where the answer was yes and the field was load-bearing,
the field was removed, generated, re-derived, or gated by a CHECK constraint.

Four things that look like they could be columns are not:

| Not a column | Why | Where it lives instead |
|---|---|---|
| Set membership (V / U / INERT / V0) | An agent would write `V` | `core.observation.membership`, a **STORED GENERATED** column compiling the seven §2.4 exclusions |
| A lineage identifier on an observation | Four copies of one document with four lineage IDs would count as four independent lineages | Computed from citation edges by `core.lineage_components()`. **There is no `lineage_id` column on `core.observation` at all**, and a test asserts its absence by querying `information_schema` |
| Refutation state | An LLM writing `'R3'` would produce an R grade | `core.refutation.proposed_state` stores what the agent said; `core.derive_refutation()` re-tests R1/R2/R3 against the rows |
| A site-level score | It is the v0.1 defect | Nowhere. The composite does not exist |

And one thing that looks like it could be a policy but is a constraint:

| Not a policy | Where it lives |
|---|---|
| "Verified means the whole chain resolved" | `receipt_verified_requires_everything` — a CHECK constraint making `receipt_state='VERIFIED'` unreachable without grammar + resolution + HTTP 200 + hash + issuer metadata |

---

## 1. THE FOUR SCHEMAS

```
registry   the curated, versioned, reviewed-write tables. Judgement lives here, once, auditably.
core       the canonical evidence graph and the grades. Never exposed to PostgREST.
ingest     acquisition and adjudication plumbing. Default-deny; no anon policy on any table.
api        the published projection. The ONLY schema PostgREST serves.
```

Schema separation is doing real work, not tidiness. The alternative design — all tables in `public`
behind row-level security alone — makes every future table one forgotten policy away from public. Here
a new `core` table is unreachable from the API by construction, and becomes reachable only by someone
writing an `api` view for it on purpose.

`core`, `registry` and `ingest` are `revoke all ... from public`. `anon` and `authenticated` get
`usage` on `core` and `registry` solely so `security_invoker` views resolve; they hold no table
grants there.

---

## 2. `registry` — WHERE THE JUDGEMENT LIVES

BES §12.1 promises that every quantity in a grade is a receipt, a lookup, a count, a boolean, or one
of two adjudicated judgements. The lookups all resolve here.

| Table | What it holds | Why it is curated rather than asserted |
|---|---|---|
| `corpus` | The 158 catalogued sources. **`host_tier` and `content_tier` are separate columns** | The Black Vault is a T3 host delivering T1 content; the Internet Archive is a channel, not a tier. Three incompatible tier ladders existed in W0 output before a single candidate was graded |
| `diagnosticity_catalog` | D0–D4 per (typology profile, observation kind, null) | The universal-D0 list is permanent and explicit. Two hundred adits satisfy zero conditions above D |
| `erp_profile` | Expected-record profiles keyed on record class × era × controlling authority × classification posture | This is the table that licenses the argument from silence for DUCC and forbids it for Greenbrier-1991. It is also the highest-value artifact the W0 registries produced |
| `candidate_set` / `candidate_set_member` | N, M, membership, dilution limit M ≤ 3N | Adding a candidate **dilutes** every member; a trigger re-queues them all |
| `identifier_grammar` | The fifteen validators | Grammar failure is informative; **grammar success is worthless** |
| `null_hypothesis` | The twelve enumerated nulls (A01–A12) | Null selection is a lookup keyed to typology + reference class, not a free choice, because REFUTER shares the discoverer's priors |
| `base_rate` | The RC × class ordinal table | Published beside the grade, **never entering the arithmetic** — which is precisely what stops the canary reaching B |
| `egress_probe` | Per-host reachability, robots posture, mirror designation | An unreachable canonical corpus yields `UNSEARCHED`, never `NEGATIVE`. Without this a network failure reads as a finding |
| `table_version` | One `is_current` per table, versioned independently | Every grade event pins all of them, so no grade is comparable across versions without re-scoring the baseline, and a bad version is identifiable and rollback-able |
| `scorer_model` | Model IDs and **families** | The family, not the ID, is what collapses to one lineage |
| `country` / `admin_area` | Geography as **rows** | US-first, country-agnostic. Non-US expansion is additive, not a migration |

`registry.corpus` also carries the `adversary_writable` flag that surfaces on the entry page, and the
egress state that drives BES §2.6 degraded-verification mode.

---

## 3. `core.entity` — A CONTAINER THAT CARRIES NOTHING GRADED

```
core.entity(entity_id, slug, canonical_name, entity_level, country_code,
            typology_cached, is_canary, publication_state, first_published_at, ...)
```

`entity_level ∈ {program, site, structure}` with parent-child relations. Identity, aliases, typed
identifiers and typed relations live here. **No grade, no score, no confidence.**

**`typology_cached` cannot change without evidence.** `core.guard_typology_change()` raises unless the
entity's TYPOLOGY proposition is at band C+, and writes a `core.entity_typology_history` row. This is a
trigger, not a comment saying the column "may not be written directly" — the difference matters,
because a comment is a suggestion to an agent and a trigger is not.

**`core.entity_relation` carries typed relations including `DISTINCT-FROM`**, seeded from the
calibration set, so Manzano Base and KUMMSC can never silently re-merge. A brief reading "merge name
variants, alias chains, coordinate near-duplicates" describes the correct Kirtland merge (KUMMSC ≡
KUMSC) and the catastrophic one (Manzano ≡ KUMMSC) in identical language; the schema holds them apart
where the brief cannot.

**`core.entity_alias` is not bookkeeping — it is a verification input.** It is the table subject
binding matches against. Entity resolution therefore sits *upstream* of the evidence gate, which is
also why it is an unaudited attack surface (see `docs/GRADING.md` §18.7).

### Canary containment

`is_canary` plus `entity_canary_never_published` (a CHECK constraint), plus a refusal in
`core.assert_publishable()`, plus exclusion from `api.map_feature`. **Three independent blocks.** If a
fabricated canary facility can be published, the hallucination measurement is destroyed — and the
measurement is the point. A direct `UPDATE ... SET publication_state='PUBLISHED'` on a canary raises.

---

## 4. `core.proposition` — THE ATOMIC GRADED UNIT

```
core.proposition(proposition_id, entity_id, class, subject, predicate_args, as_of_date,
                 null_code, typology_profile, reference_class, clamp_exempt, ...)
```

Every grade in the register lives on one of these rows, over the closed twelve-class enum
(`core.proposition_class`). An agent may not invent a class — the enum forbids it — and may not emit
an under-specified one: `core.validate_predicate_args()` checks the required `predicate_args` keys per
class and validates closed vocabularies **inside** the jsonb. A `STATUS` of `'mothballed'` is
rejected at write time, not stored and quietly mis-scored.

**Three structural guarantees:**

1. **`proposition_one_exist`** — a unique index enforcing exactly one EXIST per entity per as-of date,
   so the monotone clamp's parent is unambiguous.
2. **`clamp_exempt` is set by trigger** (`core.set_clamp_exemption`), never by agent choice. PROGRAM
   and ORIGIN are exempt. That exemption is what makes DUCC (PROGRAM A / EXIST R) and Dulce (ORIGIN A
   / FUNCTION R) representable — **the register can publish an A-grade fact about a fabrication**,
   which is the stated philosophy.
3. **`core.proposition_erp`** makes ERP applicability **per proposition**, not per class. Two EXIST
   propositions under different controlling authorities have different applicable profile sets, and
   that is exactly the Mount Pony case.

### "The hole is certain, the function is not"

This is the single most common real state of affairs in the domain, and v0.1 could not express it. It
is now expressed natively and is asserted by the acceptance suite: **one entity, EXIST graded A from a
D4 claim-property row, FUNCTION graded E on the same entity at the same instant, with `CAP-2b` in
`applied_caps`** — proving the FUNCTION claim could not borrow the EXIST documentation.

The structural reason it cannot: **observations attach to `proposition_id` and to nothing else.** This
is the fix for the v0.1 unit error, where a well-documented real installation laundered its
documentation onto every claim attached to it.

### The monotone clamp

Applied inside `core.recompute_proposition`, recorded as a `core.clamp_event`, and stored on the
rollup. Children are re-queued whenever a parent's grade moves, and the drain runs to convergence,
parents before children.

*Two failure modes this design specifically avoids.* A clamp that lives only in a read-time helper
which the map view does not call publishes the **unclamped** grade. And a clamp that reads the
parent's rollup with no ordering guarantee uses a stale parent when FUNCTION regrades before EXIST,
with nothing to re-fire it. Here EXIST enqueues at priority 10, children are automatically re-queued
when a parent moves, and the drain is multi-pass — a single-pass `FOR` loop cannot see rows the loop
itself enqueues.

---

## 5. `core.observation` — THE ATOM

This is where the model actually bites.

```
core.observation(observation_id, proposition_id, document_id, quoted_span_id,
                 scope, property_locus, sign, magnitude,
                 signed_weight    GENERATED,
                 membership       GENERATED STORED,
                 exclusion_reason GENERATED,
                 fact_key, subject_binding_pass, self_attesting,
                 register_echo_quarantined, superseded_at, rebutted,
                 rebutted_by_observation_id, ...)
```

### Signed evidence

`sign ∈ {SUPPORTS, UNDERCUTS, NEUTRAL}` and `signed_weight` is generated as magnitude × sign.
**`UNDERCUTS` is a first-class state, distinct from `NEUTRAL` and distinct from no row at all.** The
acceptance suite drives EXIST from A down to F by inserting a single UNDERCUTS row.

`core.ea_matrix()` implements the BES §4.4 fallback and **returns negative cells**, so a published
tenant lease list counts *against* a hardened-facility claim rather than merely failing to count for
it. Its ceiling is hard-coded at D3: D4 is unreachable by inference and requires the §3.4 gate. **The
firewall is arithmetic, not a bolted-on cap.**

### `membership` — a generated column, not an assertion

Compiles all seven BES §2.4 exclusions plus the receipt state:

- unverified receipt → **V0**
- **INERT** for: non-INSTANCE scope · ADVERSARY-WRITABLE channel · causal provenance outside
  {UNSOLICITED, SOLICITED-3P} · POST-2022-UNATTRIBUTED era · `self_attesting` · register-echo
  quarantine · NEUTRAL sign · supersession
- otherwise **V** (SUPPORTS) or **U** (UNDERCUTS)

An agent cannot write it. The acceptance suite attempts an UPDATE and asserts that it raises.

`exclusion_reason` is generated alongside, so the entry page can render **why** each row is inert
rather than silently omitting it. Nothing is deleted; `core.forbid_delete()` is installed on ten core
tables.

### Subject binding is enforced, not requested

`core.sync_observation_provenance()` demotes `scope` from INSTANCE to CLASS whenever
`subject_binding_pass` is false, and `observation_binding_gates_instance` makes the pair
(INSTANCE, binding failed) unrepresentable.

This is the countermeasure to the commonest real-world failure — **a genuine record attributed to the
wrong site** — and it removes such a row from V *without deleting it*.

### D4 is the gate and nothing else

`observation_d4_is_the_gate` is a CHECK constraint requiring all six §3.4 conditions.
`observation_matrix_ceiling` holds E/A-derived rows at D3. PENDING-tier sources are clamped to
magnitude 2 at write time, so an uncatalogued source can support C and D but never A or B — which
removes the incentive to route around the review queue.

### `rebutted`

Both an explicit adjudicated flag (`rebutted`, `rebutted_by_observation_id`) **and** an automatic test
(a same-`fact_key` V row of equal or greater magnitude). The automatic test alone leaves no way to
record an adjudicated rebuttal; the flag alone leaves the common case to an agent.

---

## 6. RECEIPTS — RESOLVE-OR-DIE AS A CHECK CONSTRAINT

```
core.retrieval_receipt(receipt_id, document_id, receipt_state, receipt_class,
                       resolved_url, http_status, sha256_of_bytes, retrieved_at,
                       grammar_pass, resolved_at_issuer, mirror_only,
                       issuer_metadata_match, text_layer_provenance,
                       verifier_model_id, ...)
```

**`receipt_verified_requires_everything`** makes `receipt_state = 'VERIFIED'` unreachable unless:

```
grammar_pass
AND (resolved_at_issuer OR mirror_only)
AND http_status = 200
AND sha256_of_bytes IS NOT NULL
AND issuer_metadata_match
```

A second constraint **forbids a model verifying a model of its own family** — an LLM verifying an LLM
shares the priors that produced the error. Anything short of the full chain is UNRESOLVED = tier V0,
and `membership` picks that up automatically.

`receipt_class` implements the custody ladder (§2.8 of GRADING.md): R-FULL reaches D4; R-MIRROR
reaches D4 but triggers CAP-6; R-SURROGATE caps at D2 and **can never satisfy §3.4**, because (d)
requires a receipted span and a folder title is not one; R-ATTESTED-TRANSCRIPTION caps at D3;
R-PENDING-ACQUISITION and R-NONE are V0.

`core.quoted_span` carries both the probative span and the subject-binding span, with character
offsets and the normalizer version, so offsets stay interpretable across normalizer changes.

**`ingest.lead` is the firewall.** Untrusted identifiers — anything regexed out of fetched prose,
Wikimapia descriptions, OSM changesets, forum bodies, PDF text layers, fringe books — land here and
must independently resolve at the issuing authority before any row may cite them. A lead is rejected
at INSERT without identifier + identifier class + claimed issuer metadata + a verbatim claimed span +
a proposition. **There are no `origin_tier`, `diagnosticity`, `scope`, `property_locus` or `grade`
columns on `ingest.lead`** — an agent cannot assert them because the fields do not exist.

`core.search_log` and `core.search_receipt` carry the negative side: query string, corpus, corpus
version, executed_at, result count. **Absence is not citable without a receipt for the absence**, and
`NEGATIVE` versus `UNSEARCHED` is distinguished by the per-host egress status, never conflated.

---

## 7. THE CITATION GRAPH — INDEPENDENCE AS A GRAPH PROPERTY

This is the requirement most easily faked and it is worth being precise about what "faked" means here.

A schema can carry a comment reading *"a graph property, not a COUNT(\*)"* directly above a line that
reads `count(distinct v.lineage_id)` over a denormalised, agent-writable column. That is a
`COUNT(DISTINCT)`. An agent that writes four distinct lineage IDs for four copies of one document gets
four lineages, and `L(D2) >= 3` opens band B. **The register's founding premise is "one source and 399
copies"**; a count over an agent-written column does not implement it.

### The nodes and edges

```
core.source_document      the nodes
core.document_citation(citing_document_id, cited_document_id, edge_kind,
                       counterfactual_verdict, quorum_models[], quorum_disagreed,
                       collapses_lineage GENERATED, retracted_at, ...)
```

Directed, **cyclic** (a citogenesis loop *is* a cycle and must be traversed, not prevented), and
typed: `explicit-citation`, `mirror-of`, `replication`, `paraphrase`, `semantic-derivation`,
`compiler-exposes`, `quotes-testimony`.

**`collapses_lineage` is a GENERATED column**: an edge collapses unless it is `compiler-exposes` or the
counterfactual verdict is `independent`. That single expression encodes BES §5.1.3 — **a transparent
compiler is a CONDUIT**, so a critical edition citing forty Signal Agency documents is forty lineages
and the compiler is neither counted nor penalised.

### `core.lineage_components()`

Connected components over the *collapsing subgraph*, computed **undirected** (if B copied A they are
one lineage whichever end you start from), with `UNION` deduplication as the termination guarantee:
the working set empties in at most |V| iterations no matter how many cycles exist. Component root is
`min(node)` — stable and order-independent, so the same graph always yields the same component keys.

### `core.independent_lineages()` — four collapses, and the order matters

1. **Membership filter** (§2.4) — only V rows count.
2. **Fact-key merge** (§5.5) — one underlying fact is one lineage even through four record types. This
   kills the double-count where "this was an AT&T Long Lines station" enters four times via deed, ASR
   registration, corporate route record and press.
3. **Model-family collapse** (§5.1.2) — all findings from agents sharing a base model become ONE
   lineage, capped at 1 by a unique index on `core.lineage(agent_model_family)`. *N prompts over one
   set of weights is one witness speaking N times in different words.*
4. **Graph component collapse** — copies, paraphrase, regeneration, replication.

Tested end to end: **one T5 origin plus 40 downstream copies chained by paraphrase edges collapse to
ONE lineage, CAP-1 fires, and the proposition is held at C. Volume does not corroborate.**

`core.lineage_count()` and `core.lineage_count_claim()` are the two numbers the bands consume. A1's
second clause requires *two D3 rows in two independent lineages, **both CLAIM-PROPERTY***; checking
">=2 D3 lineages AND >=2 claim-property rows anywhere" is a relaxation that lets one lineage supply
both claim rows while a place-property lineage makes up the count, so `lineage_count_claim()` exists
separately.

### Origin tracing terminates — verified, not assumed

Both input schema proposals wrote origin tracing as:

```sql
WITH RECURSIVE ... UNION ALL ... CYCLE node SET is_cycle USING path
```

at depth 25 and depth 24 respectively, each commenting that the CYCLE clause made it safe. **It does
not.** The CYCLE clause prunes a branch when a node repeats *on that branch*. It says nothing about
the **number of distinct simple paths**, which grows exponentially with depth in a dense graph — and
`UNION ALL` plus a path array makes every path a distinct row, so deduplication cannot help.

Measured on a 40-document / 380-edge citogenesis cluster, a small one for this domain:

| depth | rows | time |
|---|---|---|
| 4 | 9,111 | 18 ms |
| 5 | 73,911 | 163 ms |
| 6 | 592,311 | 1,595 ms |
| 8 | — | **did not complete within a 25-second statement timeout** |

Both proposals ran this **inside the ingest path** at depth 24–25. Citation cycles are the norm here,
not the exception. The first real echo chamber ingested takes the worker down.

**`core.trace_origin()` deduplicates on the NODE rather than enumerating PATHS:**

- `UNION` (not `UNION ALL`) keyed on `(node, depth)`, which bounds the working set at |V| × max_depth
- **no path array in the recursive term** — path arrays are precisely what defeat deduplication
- a node budget (`core.traversal_node_budget`) as a third independent stop
- keeps the shallowest reach of each node
- `closes_cycle` **marks** the edge that closed a loop rather than hiding it, because a closed citation
  loop with no dated entry point is itself a finding about the claim

Same fixture, same depth 25: **20 nodes in 9.6 ms.** `core.lineage_components()` resolves the 40-node
cyclic cluster in **2.6 ms**.

`core.origin_path()` reconstructs a path **outside** the recursion, as a bounded iterative loop of
single-row lookups with a visited set.

`core.claim_origin()` prefers a receipted document date, falls back to first-observation dating, and
**LABELS which it used** — the register does not invent a terminus it does not have.

`core.detect_citogenesis()` walks backward from every T1–T3 document cited on a proposition and reports
those whose closure terminates in T5 material. A confirmed `core.citogenesis_loop` triggers CAP-3
(max E) and **the flag attaches to the PROPOSITION, not the site** — which is exactly where the Mount
Weather "underground city" claim had nowhere to live under v0.1.

### Attestation custody

`core.witness` and `core.attestation` close the cheapest lineage-seeding attack there is:
**`asserting_document_id` is the lineage terminus**, so attributing invented testimony to two real,
dead, findable people yields ONE lineage with the claimant, not two with the deceased.

The resolvability gate — locatable in a record that predates the claim and was created for an
unrelated purpose — is a stored, adjudicated boolean, and `observation_testimony_custody` makes D3
testimony impossible without **both** resolvability and a real custody path.

---

## 8. VERSIONING — HOW A PAST GRADE IS RECONSTRUCTED

**There is no grade column on `core.proposition`.** A grade is an append-only event.

```
core.grade_event(grade_event_id, proposition_id, seq, occurred_at,
                 grade, awarded_band, grade_pre_clamp, applied_caps[],
                 clamped_by_proposition_id, condition_results jsonb,
                 ceiling, at_ceiling, limiting_condition, marginal_flag,
                 refutation_state, null_state, silence_reading, base_rate_reading,
                 l_d2, l_d3, v_count, u_count, v_claim_count, v0_count,
                 sci_numerator, sci_denominator,
                 place_derived_weight, claim_derived_weight,
                 transition_cause, is_instrument_drift GENERATED,
                 triggering_observation_ids[], scorer_model_id, scorer_model_family,
                 rubric_version, tier_table_version, diagnosticity_table_version,
                 erp_table_version, typology_profile_version,
                 evidence_state_hash, snapshot jsonb,
                 is_published, published_at)
```

### `condition_results` is the full vector, not a summary

Every A1–A6 / B1–B4 / C1a–C3 / D1 / D2cond / E1 / E2 pass-fail is stored. **Reliability is measured at
the CONDITION level** because "did A2 pass?" is far more reproducible than "is DOC 78 or 84?" — this
is what makes double-scoring a meaningful instrument rather than a letter-comparison.

### Append-only is ENFORCED, not documented

`core.grade_event_immutable()` diffs the **whole row as jsonb** and permits only `is_published` /
`published_at` to move. An `UPDATE` raises. (`is_instrument_drift` is excluded from the diff because
generated columns are computed after BEFORE-row triggers — not a loophole, since it is a pure function
of `transition_cause`, which the diff does cover.)

### `core.grade_event_observation` — the evidence snapshot

Snapshots the exact evidence set in scope at scoring time, **with `membership` and `signed_weight` as
they were**. This is what makes *"show what evidence moved it and when"* answerable rather than
asserted: `core.grade_history()` diffs consecutive events to report `observations_added` and
`observations_removed`.

### `evidence_state_hash` — the reconstruction key

md5 over the ordered (observation, membership, signed_weight) tuple set. Two gradings with the same
hash saw the same evidence, so **a grade change with an unchanged hash IS instrument drift** and
`transition_cause` had better say so.

It lives on **both** the event and the rollup. The rollup copy is the one publication tests against,
because an event is only written when the grade *moves* — so evidence that lands without changing the
letter would otherwise leave the event's hash stale and let the publication gate pass on a grade that
predates the current evidence. One shared `core.evidence_state_hash()` computes both.

### Reconstruction

```sql
select core.grade_as_of(:proposition_id, '2026-01-01'::timestamptz);
select * from core.entity_as_of(:entity_id, '2026-01-01'::timestamptz);
```

Rebuilt from events alone. Tested: a FUNCTION proposition graded E, then lifted to C by a NEPA filing,
**still returns E for the earlier instant**, and `grade_history` names the NEPA observation as what
moved it.

### Transition-cause discipline

The fifteen-value vocabulary is mandatory on every re-grade. `is_instrument_drift` is a generated
column over SCORER-CHANGE / TABLE-VERSION-CHANGE / RESCORE-NOISE, and `core.grade_history()`
**suppresses those from the public chart by default while keeping them retrievable** — hiding them
entirely would be the same sin one level up. `NEW-DISCLOSURE` renders with the annotation *"the
publication record changed; the world did not"*, distinct from `STATUS-CHANGE`'s *"the world
changed."*

### The one-way ratchet

`core.apply_grade()` permits a rise only when at least one of the observations that arrived **since the
last event** is a V-member whose own document date **precedes the register's first publication** of
that entity, and which is not register-echo-quarantined. Downward movement is unrestricted.
`NEW-DISCLOSURE`, `MERGE` and `SPLIT` are exempt, as are the three drift causes.

**Polarity matters and is easy to get backwards.** Counting *any* V observation whose document
postdates first publication, and blocking the rise if any exists, means one unrelated recent blog post
freezes the proposition against a genuine new archival find **forever**. The test is on the
**triggering** rows: a rise requires at least one newly verified supporting document whose own date
precedes publication.

A blocked rise is not silent: the rollup's `limiting_condition` records that upward movement was
withheld.

### Merges

`core.entity_merge_event` is versioned and reversible, with `grade_before` / `grade_after` and a
`raised_a_grade` flag carrying a CHECK that **a merge which raised a grade must be marked rejected**.
BES §11.1's rule — that a merge doing unjustified evidentiary work is refused — expressed as a
constraint rather than a guideline.

---

## 9. THE ROLLUP AND THE REGRADE QUEUE

`core.proposition_rollup` is a **cache**, and a stale cache is a wrong grade. It is treated
accordingly.

- The acceptance suite **deletes the entire rollup and rebuilds it bit-identically** from the
  observation rows. If it cannot, the rollup is holding state that exists nowhere else.
- `evidence_state_hash` is carried on the rollup and refreshed on every recompute.
- **Publication is refused when the rollup's hash disagrees with the live hash.** Landing new evidence
  without draining the queue makes publication raise; it succeeds after the drain.

`ingest.regrade_queue` plus enqueue triggers plus `core.drain_regrade_queue()` give cheap incremental
re-grading under unbounded ingest. One new observation dirties exactly one proposition; nothing
recomputes the whole table.

**The drain is multi-pass, bounded by `p_max_passes`.** A single-pass `FOR` loop cannot see rows the
loop itself enqueues, so children re-queued by a parent regrade keep a stale clamp until some unrelated
later write. Priority ordering puts EXIST at priority 10 so parents drain before children.

**One subtlety worth naming**: publishing an entity flips `publication_state` on all its observations,
which naïvely re-fires the regrade trigger and leaves the queue permanently non-empty after every
publish — making *"is anything stale?"* unanswerable. The enqueue is skipped when `publication_state`
is the only changed field, detected by whole-row jsonb diff.

---

## 10. PUBLICATION — THE ONLY PATH TO PUBLIC VISIBILITY

`ops_publish_entity()` is the sole path, and `core.assert_publishable()` refuses on four independent
grounds:

| Ground | Why |
|---|---|
| (a) The entity is a **canary** | A fabricated name with zero corpus presence measures hallucination **only if it never publishes** |
| (b) Any proposition has **never been graded** | An ungraded proposition on a published entity is an unbounded claim |
| (c) The rollup's `evidence_state_hash` **disagrees with the live hash** | The published grade must have been computed from the evidence **currently** on file |
| (d) Any counted (V or U) observation **lacks a VERIFIED receipt** | Resolve-or-die, applied at the boundary as well as at the row |

The function is revoked from `anon`/`authenticated` and granted only to `service_role`.

### The transitive citation closure

Publishing an entity publishes the **full backward citation closure** of its documents, so an origin
trace is never truncated at the first unpublished hop. Without it the register shows the laundered
claim and hides the T5 forum post beneath it — which is the opposite of the product.

The consequence, stated plainly: **a document can become public because something else cited it.**
That is the intended semantics of a lineage graph, and it is why `core.source_document` has no
per-entity ownership.

The closure walk is written with node deduplication so a cyclic closure terminates.

`core.publication_log` is written **before** anything goes public — self-exclusion depends on it, and
a publication log written afterwards is a publication log that cannot quarantine the register's own
echo.

---

## 11. GEOMETRY AND UNCERTAINTY

Geometry is not two columns on `entity`. It is **`core.geometry_assertion`**: versioned, sourced,
superseded, competing.

```
core.geometry_assertion(assertion_id, entity_id, locate_precision,
                        geom, label_point_3857, geom_3857,
                        claimed_place_name, radius_m,
                        derived_from_observation_id, is_preferred,
                        superseded_at, ...)
```

A cartographer's control-point match and a forum post's coordinate must be able to coexist, with their
sources attached. Overwrite-in-place destroys the prior claim in a register whose rule is that nothing
is deleted.

### `locate_precision`

```
exact · approximate · region_polygon · uncertainty_circle · place_name_only · non_located
```

Two of these were unrepresentable in both input proposals and both occur in the calibration set:

- **`place_name_only`** — a claimed place name with **no coordinates at all**, carrying
  `claimed_place_name` and no geometry.
- **`non_located`** — documented, coordinates genuinely unknown (BES §10.4). Epistemically distinct
  from the above, and from `claimed_only`.

`geometry_shape_matches_precision` uses `else false`, not an exhaustive CASE with no ELSE. A CHECK
constraint evaluating to NULL **passes**, so an exhaustive CASE means any precision level added later
silently accepts any shape. `else false` makes an ungoverned precision fail loudly.

### Rendering gates

`core.render_geometry()` will not emit a point unless LOCATE is at band C or better. Below that the
feature renders as a region polygon or an uncertainty circle. **A precise pin manufactured from
imprecise evidence is the register performing its own citogenesis at the interface layer.**

Nothing below band D renders as a map pin at all; E, F and R live in the claims register with their
origin work.

### Performance

`geom_3857` is **stored and GiST-indexed** on `api.map_feature`. Transforming inside the tile
predicate (`st_transform(render_geom,3857) && env.g`) is not sargable against any declared index and
sequentially scans the whole register on every vector-tile request. Measured on 50,000 points:
**547.9 ms sequential scan versus 0.29 ms bitmap index scan** — about 1,890× at 50k rows, degrading
linearly. The acceptance suite asserts this by inspecting the actual query plan for `Index Scan`.

### Clustering

`api.map_cluster` clusters on **`label_point_3857`** (`st_pointonsurface`, guaranteed interior even
for concave uncertainty polygons), not on `geom_3857`. Snapping a polygon to a grid yields a *snapped
polygon*, so two nearby region features land in different "cells" and never group — region features
would never cluster at all.

Cluster IDs are the **grid cell `(cell_x, cell_y)`**, not `row_number()`. Row numbers renumber every
cluster on every `REFRESH MATERIALIZED VIEW CONCURRENTLY`, so no client can cache a cluster across a
refresh.

`api.refresh_map()` **raises if it produces zero features while published band-D+ propositions
exist** — see §12 for why that assertion is load-bearing.

---

## 12. SECURITY POSTURE

**Schema separation first, RLS second.** PostgREST sees `api` only. 101 policies cover `core` and
`registry`; `ingest` is default-deny with no anon policy on any table.

Three RLS leaks present in the input proposals, all fixed and all verified by `SET ROLE anon`:

| Leak | What was exposed |
|---|---|
| `create policy anon_read on core.witness ... using (true)` | Real people's names, the resolvability adjudication, the record kind used to resolve them, the adjudicator and free-text notes — **for candidates never published**. Both an adjudication-state leak and a private-individual exposure. Now gated on a published observation via `core.attestation` |
| `create policy anon_read on core.document_citation ... using (retracted_at is null)` | **The entire citation graph, regardless of publication.** Because edges carry document UUIDs, an anonymous reader could enumerate the shape and size of the evidence base behind every unpublished candidate. Now requires both endpoints to be published documents; verified to return 0 rows as `anon` |
| `create policy anon_read on core.lineage ... using (true)` | Lineage structure, terminus document and agent model family for unpublished work. Now gated on a published document in the lineage |

**`FORCE ROW LEVEL SECURITY` was deliberately dropped.** It is defence-in-depth against a compromised
owner role, but combined with a `SECURITY DEFINER` materialised-view refresh it **fails silently to an
empty map** if the definer lacks `BYPASSRLS` — the public map goes blank with no error. A loud failure
was chosen over a silent one: `api.refresh_map()` raises if zero features are produced while published
band-D+ propositions exist. On Supabase the `postgres` role has `BYPASSRLS` so either choice works;
this one also fails safe on a bare cluster.

**`SECURITY DEFINER` helpers in RLS predicates.** `core.entity_is_public`,
`core.proposition_is_public` and `core.document_is_public` are `SECURITY DEFINER` so policy subqueries
do not recursively apply RLS. This centralises the published-closure test — a new child table cannot
accidentally get a weaker predicate than its siblings — but it means those three functions are now
security-critical surface. They are single-statement, parameterised, and have a fixed `search_path`.

**Privilege separation for agents.** No LLM holds INSERT on `core.observation`,
`core.retrieval_receipt` or `core.lineage`. Discovery agents write to `ingest.lead` and
`ingest.null_return` and nothing else. The sole writer of observations is deterministic verification
code. **An agent's citation is stored as a hypothesis about a document's existence, never as a
citation.**

**Agent identity is unreachable from the grading query.** `ingest.lead.discovering_agent` and
`ingest.agent_run` participate in no computation that produces a lineage count or a band. The number
of agents that reported a claim is physically incapable of entering the arithmetic, so the
corroboration-by-agent-count error cannot return through a later refactor.

---

## 13. TELEMETRY THE REGISTER PUBLISHES ABOUT ITSELF

| View | What it says |
|---|---|
| `api.telemetry_confabulation` | Per-agent format-valid-but-unresolvable rate |
| `api.telemetry_band_occupancy` | BES §12.6 — the modal entry should be X or D; C-band above ~15% means the diagnosticity catalog is leaking |
| `api.telemetry_refutation` | R-rate and R-reversal rate |
| `api.methodology_coverage` | Per-host egress state and robots posture |
| `api.expected_record_table` | The ERP table itself, published so a reader can check the silence reading |

`ingest.confabulation_event`, `ingest.canary` and `ingest.double_scoring` are internal. **The canary
roster in particular is unreachable to `anon` — knowing the canaries would defeat them.**

*A register that states its own measured fabrication rate is more credible than one that implies
none.*

---

## 14. WORKED QUERIES

### Q1 — The map viewport

Server-side clustering below z9, features above. A region feature carries a POLYGON and no point:
**there is no code path that emits a coordinate for a candidate whose LOCATE proposition is below band
C.**

```sql
select api.map_viewport(-84.0, 37.0, -79.0, 40.0, 12, 'D');
select api.map_viewport(-125.0, 24.0, -66.0, 49.0, 4, 'D');   -- returns clusters
```

Vector tiles for MapLibre, filtering the **stored, GiST-indexed** `geom_3857`:

```sql
select length(api.map_tile(10, 214, 392));
```

### Q2 — Candidate detail

The proposition table leads the page. **N badges, never one.** Each badge carries its evidence rows
with receipts — including V0 and quarantined rows shown as inert, with `exclusion_reason` — the
alternative-hypothesis disposition table, and the search receipts that license any negative reading.

```sql
select jsonb_pretty(api.candidate_detail('test-greenbrier'));
```

The same decomposition as a table, for the finding-aid rendering:

```sql
select class, grade, ceiling, at_ceiling, limiting_condition, marginal_flag,
       null_label, null_state, silence_reading, silence_prose,
       base_rate_reading, sci, place_derived_weight, claim_derived_weight
  from api.proposition_badge
 where entity_slug = 'test-greenbrier'
 order by array_position(array['EXIST','LOCATE','EXTENT','TYPOLOGY','HARDEN',
          'CONTROL','FUNCTION','STATUS','FEATURE','PROGRAM','IDENTITY','ORIGIN'],
          class::text);
```

### Q3 — Independence: is this 41 sources, or one source and 40 copies?

One row per genuinely independent lineage, after the membership filter, the fact-key merge, the
model-family collapse and the graph component collapse:

```sql
select lineage_key, lineage_kind, best_magnitude, observation_count,
       has_claim_property, best_tier, representative_title
  from core.independent_lineages(:proposition_id, 2::smallint);
```

The number the bands actually consume, and the delta that *is* the point:

```sql
select (select count(distinct document_id) from core.observation
         where proposition_id = :proposition_id and membership='V') as documents,
       core.lineage_count(:proposition_id, 2::smallint)             as lineages,
       core.lineage_count_claim(:proposition_id, 3::smallint)       as d3_claim_lineages;
```

`documents − lineages` is the **collapse delta**, published per proposition. It is the honest
replacement for a contamination score: not a judgement, just the distance between how many sources
there appear to be and how many witnesses there are.

### Q4 — Origin trace over the cyclic citation graph

Terminates on three independent grounds. `closes_cycle` **marks** the edge that closed a loop rather
than hiding it, because a closed loop with no dated entry point is itself a finding about the claim.

```sql
select depth, title, origin_tier, document_date, first_observed_date,
       reached_via, closes_cycle, is_terminus
  from core.trace_origin(:document_id, 24)
 order by depth;
```

The earliest traceable appearance of a claim, with the **dating basis NAMED** (document-date vs
first-observation vs undated), so an inference is never presented as a graph fact:

```sql
select * from core.claim_origin(:claim_id);
```

Citogenesis — a T1–T3 publication resting on unattributable T5 testimony:

```sql
select * from core.detect_citogenesis(:proposition_id);
```

### Q5 — Grade history

Instrument drift is suppressed from the public chart by default and remains retrievable.
`NEW-DISCLOSURE` is annotated *"the publication record changed; the world did not."*

```sql
select seq, occurred_at, grade_from, grade, direction, transition_cause,
       disclosure_annotation, limiting_condition, moved_by, counts
  from core.grade_history(:proposition_id);
```

Reconstruct any past state from stored events alone:

```sql
select core.grade_as_of(:proposition_id, '2026-01-01'::timestamptz);
select * from core.entity_as_of(:entity_id, '2026-01-01'::timestamptz);
```

### Q6 — The claims register

E, F, R and X entries live here **with their origin work, which is the product**. Nothing is deleted;
refuted entries keep their refutations attached, and X renders visually distinct from F because it is
the absence of a grade, not a low one.

```sql
select slug, canonical_name, class, statement_text, grade, refutation_state,
       citogenesis, limiting_condition, silence_reading, base_rate_reading,
       claim_text, first_appearance_date, first_appearance_confidence,
       refutations, origin_propositions
  from api.claims_register
 order by grade, slug;
```

### Q7 — The ingest loop

Agents write leads; verification code writes observations; triggers enqueue; a worker drains to
convergence (parents before children, so the monotone clamp never reads a stale parent); the map is
refreshed. **Nothing recomputes the whole table.**

```sql
select core.drain_regrade_queue(500, 'assessor-model-id');
select api.refresh_map();
```

What is dirty right now, and what failed:

```sql
select q.proposition_id, p.class, q.reason, q.priority, q.attempts, q.last_error
  from ingest.regrade_queue q join core.proposition p using (proposition_id)
 order by q.priority, q.enqueued_at;
```

Publish, which is gated — canary, ungraded, stale-hash and unverified-evidence all raise rather than
publishing:

```sql
select ops_publish_entity(:entity_id, 'curator');
```

### Q8 — The register grading itself

```sql
select * from api.telemetry_confabulation order by unresolvable_rate desc nulls last;
select * from api.telemetry_band_occupancy order by class, grade;  -- modal band should be X or D
select * from api.telemetry_refutation;                            -- R-rate and R-reversal rate
select slug, host, egress_state, egress_probed_at, robots_posture
  from api.methodology_coverage where egress_state <> 'REACHABLE';
```

Why a silence reads the way it does, for a reader checking the argument:

```sql
select * from api.expected_record_table order by x_level desc, profile_key;
```

---

## 15. TRADEOFFS, STATED

**1 · Write amplification for read honesty.** Every observation write fires a provenance-sync trigger
and an enqueue; every grade recompute rewrites a rollup row and may fan out to children. Ingest is
slower than a bulk-load design. **Accepted, because the alternative is a grade that does not
correspond to the evidence on file — the one thing the register cannot ship.**

**2 · The rollup is denormalised state that can go stale.** Mitigated three ways: `evidence_state_hash`
on the rollup, publication refused when it disagrees with live evidence, and a test that deletes the
whole rollup and rebuilds it bit-identically. **The cost is that publication now requires a drained
queue** — an operational constraint the workflow must respect.

**3 · Lineage computation is O(seeds × reachable) per grade.** `core.independent_lineages` calls
`core.lineage_components` on every evaluation, and `evaluate_proposition` calls it four times (D2, D3,
D3-claim, place-excluding). On a proposition with a large citation neighbourhood this is the dominant
cost. **Correctness was chosen over caching, because a cached lineage count is exactly the
agent-writable number that made the alternative proposal wrong.** If it becomes a bottleneck,
materialise components per document with invalidation on citation writes — **do NOT let an agent write
the count.**

**4 · Two judgement calls survive and are not eliminable.** The lineage counterfactual (BES §5.1.7) and
the E/A ordinals on the fallback path. Both are quorum-adjudicated across model families and logged in
`core.judgement_log` with a `disagreed` flag; `marginal_flag` surfaces when one of them decided the
band. **The schema cannot make them deterministic, only visible.**

**5 · `FORCE ROW LEVEL SECURITY` was dropped** — see §12. A loud failure over a silent one.

**6 · Three `SECURITY DEFINER` helpers are security-critical surface** — see §12.

**7 · The publication closure publishes documents transitively** — see §10. Required, and it means a
document can become public because something else cited it.

**8 · Band F absorbs a spec gap.** A proposition with strong support and one unrebutted D3 undercut
lands at F rather than a middle band, because BES §9.2's conditions leave no band satisfied.
Implemented literally rather than smoothed, and flagged as ratification item R-3. **The schema should
not quietly invent rubric.**

**9 · Map clusters are pre-aggregated across eight zoom levels**, so `api.map_cluster` holds up to 8N
rows and REFRESH cost scales with the register. Free at current scale; past a few hundred thousand
features it wants incremental refresh or a tile-cache layer.

**10 · The E/A fallback is self-retiring but not yet wired to a reviewer.** Every MATRIX assignment
should log an `ingest.curation_proposal` so PRIOR-KEEPER adjudicates it into the catalog. The table and
the column exist; the trigger that auto-files the proposal is left to the ingest workflow rather than
forced in the database, because the reviewer identity is a fleet concern.

---

## 16. WHAT THE ACCEPTANCE SUITE ASSERTS

`supabase/test_acceptance.sql`, 65 assertions, 0 failures. Highlights, grouped by what would break if
they were removed:

| Assertion | What it protects |
|---|---|
| One entity at EXIST=A and FUNCTION=E simultaneously, with CAP-2b in `applied_caps` | The unit fix. FUNCTION cannot borrow EXIST's documentation |
| An UNDERCUTS row drives EXIST from A to F | Signed evidence is arithmetic, not commentary |
| `UPDATE` on `core.observation.membership` raises | Set membership is a schema fact |
| `information_schema` contains no lineage column on `core.observation` | Independence cannot silently become a count |
| 1 T5 origin + 40 paraphrase copies → 1 lineage, CAP-1, held at C | Volume does not corroborate |
| `core.trace_origin` at depth 25 on a 40-node/380-edge cyclic cluster completes | Termination, verified rather than assumed |
| Five confabulated CREST identifiers → all V0, `v0_count = 5`, grade F, publication refused | The canary test. Retained as telemetry, never published |
| `UPDATE` on a `grade_event` raises | Append-only |
| A past grade reconstructs via `grade_as_of`; history names the observation that moved it | Versioning is real, not decorative |
| Delete the whole rollup; rebuild bit-identically | The cache holds no state that exists nowhere else |
| Publication raises on a stale `evidence_state_hash`; succeeds after the drain | The published grade was computed from the evidence currently on file |
| Direct `UPDATE ... publication_state='PUBLISHED'` on a canary raises | Canary containment |
| `SET ROLE anon` returns 0 rows from `core.document_citation` and `core.witness` | The RLS leaks are closed |
| The tile query plan contains `Index Scan` | The 1,890× regression cannot return |
| Driving EXIST from A to F pulls FUNCTION down with it | The clamp is applied and fans out |
| Adding a candidate-set member re-queues every member | Adding candidates dilutes |
| A typology change below band C raises | The relabel attack is dead |

---

*Schema version 0.2.0 · implements BES v0.2 · `docs/GRADING.md` is the specification; this file is the
explanation; `supabase/schema.sql` is the truth.*
