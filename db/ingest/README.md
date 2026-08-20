# db/ingest — W1 sweep-01 load

Transforms the first discovery sweep (`research/candidates/graded.json` +
`research/candidates/resolved.json`) into ingest SQL for the live register database
(`supabase/schema.sql`, schema 0.2.0, deployed per `docs/DEPLOY-REPORT.md`).

| File | What it is |
|---|---|
| `sweep-01.sql` | The load, in 20 sequential chunks marked `-- CHUNK n/20 --`. |
| `sweep-01-verify.sql` | Post-load assertions. Raises on any failure; ends with a summary. |
| `README.md` | This file: how to apply, what loads, what doesn't, and the findings. |

Both SQL files were **validated end-to-end before delivery** on a scratch PostgreSQL 16 +
PostGIS 3.4 instance (the stack the schema was authored against): `supabase/schema.sql`
applied from empty, all 20 chunks applied in order, `sweep-01-verify.sql` passed, all 20
chunks re-applied (idempotency), verify passed again. The expected counts asserted by the
verify script are the counts actually observed in that run.

---

## 1. How to apply

1. Split `sweep-01.sql` at the `-- CHUNK n/20 --` markers. Every chunk is a self-contained
   script ≤ ~70 KB, sized for one SQL-over-HTTP call each (the deploy report found 215 KB
   too large for a single call).
2. Run the chunks **strictly in order 1 → 20, one call per chunk**. Order matters: entities
   before propositions before documents before receipts/edges/observations, and grading
   (chunk 20) last. Do not interleave, do not skip.
3. Run `sweep-01-verify.sql` as one call. A clean run emits
   `NOTICE: sweep-01-verify: all assertions passed` and
   `NOTICE: sweep-01-verify: anon sees zero sweep rows`, then a summary table.

Operational notes:

- **Idempotent**: every row has a deterministic UUIDv5 identity and every insert is
  `ON CONFLICT DO NOTHING` / `WHERE NOT EXISTS`. Any chunk may be re-run; a failed call can
  simply be retried. Nothing needs (or tolerates) DELETE — `core.forbid_delete()` is
  load-bearing.
- **Chunk 20 re-run semantics**: the first run writes 167 grade events and *parks* 28
  regrade-queue rows (see §5.2). A re-run converges cleanly — apply_grade recomputes the
  same grades, appends no new events, and clears the 28 parked rows. The verify script
  accepts both states (28 parked or 0 after re-run).
- **Scoping**: the live database carries acceptance-fixture residue (6 entities, 94
  documents, 420 edges — deploy report §7). The load never touches it and the verify script
  never counts it: sweep rows are identified by entity slug `^res-0dd-` and
  `proposition.created_by = 'sweep-01-ingest'`.
- **Do not** run a global `core.drain_regrade_queue()` after loading — it is unnecessary
  (chunk 20 grades every sweep proposition itself), and it would also retry whatever
  non-sweep queue rows exist.
- The verify script's anon check uses `begin; set local role anon; … commit; reset role;`.
  If the executor already wraps calls in a transaction the `BEGIN` produces a harmless
  "already a transaction in progress" warning.

## 2. What the load contains

| Object | Rows | Notes |
|---|---|---|
| `core.entity` | 48 | All `INTERNAL`, all `typology_cached='unknown-anomaly'`, no canaries. |
| `core.entity_alias` | 193 | All `facility-name` kind (see §4.6). |
| `core.entity_relation` | 19 | Refused merges as `DISTINCT-FROM` (Safeguard triple, the two Denvers, Netcong≠Project-Office, DIA↔Schneider-numerology, the four converted Atlas sites, Bothell↔BA-79), `PART-OF` (Oscar-Zero/November-33 ⊂ Grand Forks population), `PARENT-OF` (Project Office chain → its five stations). |
| `core.geometry_assertion` | 48 | 44 `place_name_only`, 4 `non_located`. **No coordinates exist anywhere** — the beats held none and fabricated none. Nothing can ever have become a map pin. |
| `core.claim` | 14 | One per ORIGIN proposition; `first_appearance_date` only where the payload states an exact date, always confidence `inferred`. Schneider claims carry `cluster_key='N-SCHNEIDER'`. |
| `core.proposition` | 195 | Of graded.json's 200; the 5 unrepresentable ones are in §4.1. |
| `core.source_document` | 308 | 257 sweep sources + 48 W1 dossiers (T5, agent-authored, transparent compilers) + 3 carrier documents for Schneider claim families 4–5. |
| `core.retrieval_receipt` | 259 | **All `UNRESOLVED`.** `failure_reason` = `[P-tier | SEARCH-SNIPPET-ONLY / FETCH-BLOCKED / CITED-BY-OTHERS-NOT-SEEN]` + the beat's verbatim SAW/INFER accounting. The RES-011 self-reference to `docs/CALIBRATION.md` deliberately has none (nothing was retrieved) and is `register_echo_quarantined`. |
| `core.document_citation` | 289 | 257 `compiler-exposes` (dossier → its sources; never collapses) + 32 lineage-finding edges (§3). |
| `core.observation` | 441 | One per supporting/undercutting entry in resolved.json. **All membership `V0`** (generated column; unresolved receipts), magnitude 0 (`DEFAULT` = D0), scope CLASS. V and U are empty on every proposition, exactly as graded.json states. |
| `core.proposition_erp` | 1,062 | Canonical class mapping from `registry.erp_profile.applies_to_classes`, all `searched=false` (egress blocked → UNSEARCHED, never NEGATIVE). The four graded-F propositions carry graded.json's explicit adjudication instead (§5.1). |
| `core.alternative_disposition` | 195 | The selected null per proposition (A02/A05–A08/A10–A12), reasoning from graded.json. Makes `derive_null_state()` return SURVIVING (vacuously) instead of UNTESTED — as graded. |
| `core.citogenesis_loop` | 18 | State **`suspected`** — proposed by the beats, never confirmed (the settling searches were not run). CAP-3 fires only on `confirmed`, so no grade moves. |
| `core.grade_event` | 167 | Written by `core.apply_grade()` in chunk 20, cause `INITIAL`, scorer `claude-opus-5`. 28 propositions have a rollup but no event (§5.2). |
| `core.proposition_rollup` | 195 | Written by the schema's own recompute; `evidence_state_hash` verified consistent with live evidence. |
| `ingest.lead` | 5 | `AD1078617` (DTIC — flagged by the beat itself as possible confabulation), `310505952` (Iowa DNR), `CMPT-2016-0001` (Loudoun permit), `HGTWMDQ0010`, `LSBGVA05` (CLLI codes). Identifiers stay leads, never citations. |
| `ingest.curation_proposal` | 12 | The shared-lineage nodes (Wikipedia family, CLUI, LaFrance, Schneider, FAS+GS, …) proposed as `registry.corpus` rows, carrying the CONTRA-04/05 tier disputes for review. |
| `ingest.adjudication_task` | 13 | The 11 cross-beat contradictions (stage REVIEW) + RES-042 split-required and RES-047 identity-unresolved (stage RESOLVER). |
| `ingest.agent_run` | 6 | The four discovery beats, the resolution pass, the grading pass. |
| `registry.scorer_model` | 1 | `claude-opus-5` (family `claude`, role ASSESSOR). |

## 3. The Schneider collapse, as graph structure

The five separately-presented claim families that RESOLUTION-NOTES traces to one 1995
lecture land as **citation edges, not prose**:

1. DIA underground base — *Pandora's Box II* `explicit-citation` → Schneider lecture;
   KSEO interview `paraphrase` → *Pandora's Box II*.
2. "129/131 DUMBs, 1,477 worldwide" — the secondary-source documents
   `explicit-citation` / `semantic-derivation` → the lecture (Internet Archive `philexpo`).
3. Subterrene tunnel-network inference — Sauder 1995 `quotes-testimony` → the lecture
   (co-terminus: Sauder supplies the bibliography, Schneider the numbers).
4. FEMA-regional-centres-as-DUMB-nodes (cog) — the DUMB-list pages
   (coreinsightsintl.com, deepundergroundmilitarybases.com, the subterraneanbases.com
   Georgia page already among RES-005's sources) `semantic-derivation` → Sauder.
5. Silos-as-DUMB-entrances (silo) — the silo.tips "Secret Underground Bases" carrier
   `semantic-derivation` → Sauder.

All edges carry counterfactual verdict `same-lineage`, so `collapses_lineage` is true and
**`core.lineage_components()` over the ten pool documents returns exactly ONE component**
— asserted by the verify script. Equally load-bearing, the **negative** structure: the four
institutional subterrene roots (LA-5354-MS + its UNT mirror, LA-4547, US Patent 3,693,731,
the DRI/DOE U12t evaluation) resolve to four separate components and share **no** component
with the lecture. The verify script asserts both, so the register cannot let the document
programme launder the network claim (RESOLUTION-NOTES: "A register that lets the first
launder the second has performed citogenesis on itself").

Also encoded as edges: Grokipedia `mirror-of` Wikipedia on the seven candidates carrying
both (CITOGENESIS-09), FAS+GlobalSecurity `replication` (one node, not two), the WVOCCO
coinage descending from Pollock 1976 (CITOGENESIS-01), the LaFrance hedge-stripping chain
(CITOGENESIS-02), the qsl.net 20-megaton chain (CITOGENESIS-03), the 20th Century Castles
brokerage copy (CITOGENESIS-04), the Nekoma announcement chain (CITOGENESIS-08), and
coldwar-ct/coldwar-ma as one project.

## 4. What could NOT be expressed, and where it went instead

Nothing was dropped silently. The complete list:

### 4.1 Five propositions (200 → 195)

| Proposition | Why the schema cannot hold it |
|---|---|
| `RES-022-EXIST-2` | The unique index `proposition_one_exist` admits one EXIST per entity per as-of date; the merged Notch record arrived with the second beat's duplicate EXIST. Its statement differs only in wording; nothing evidentiary is lost (both beats' sources and its FUNCTION/STATUS siblings load). |
| `RES-003-IDENTITY` | IDENTITY requires `object_entity_id`; the Everett WA regional office is not an entity in this sweep. |
| `RES-011-IDENTITY` | Same; Raven Rock "Site C" is not a registered entity. The Fort-Ritchie/Site-C/Site-R conflation hazard is preserved in the RES-011 lead (`AD1078617`) and the payload. |
| `RES-012-IDENTITY` | IDENTITY takes ONE object entity; the chain-membership claim over five stations is expressed instead as five `PARENT-OF` entity relations plus `parent_entity_id`. |
| `RES-047-IDENTITY` | The object is one of twelve 579th SMS sites and the beat states plainly it does not know which; there is no entity to point at and inventing one would be worse. Carried as an `ingest.adjudication_task` (RESOLVER). |

`RES-031/039/042-IDENTITY` **do** load, with `object_entity_id` = the entity itself: they
are designation-correspondence claims within one entity, not A≡B claims between two.

### 4.2 Fields with no schema home

- **Legacy P1–P4 tiers**: `core.source_document.origin_tier` is a reviewed assignment.
  P5 material is carried as T5 (can only lower); everything else stays `PENDING`
  (scores as T4 — supports C/D, never A/B). The P-tier itself is preserved verbatim in each
  receipt's `failure_reason` and in the `ingest.curation_proposal` payloads; actual tier
  assignment is the registry review's job, not the ingest's.
- **`independent_origins` counts** from resolved.json: deliberately not stored anywhere —
  the schema computes lineage counts from the citation graph precisely so agents cannot
  write them. The structure that *produces* those counts is loaded (§3); the prose counts
  remain in the payload files.
- **Analyst ceiling projections** ("ceiling if the NRHP nomination resolves: A"),
  per-proposition `route`, `verification_debt`, `caps_computed` prose: graded.json itself
  marks these "ANALYST PROJECTION … must never be rendered beside the grade". The schema
  recomputes its own condition vectors, caps and ceilings; the prose stays in the payload.
- **`refuted_or_hollow_carried_forward`** (32 records) and `coverage_gaps_carried_forward`:
  not entities, not graded — not loaded, except the two Schneider-family carrier documents
  (§3) which exist purely as lineage structure.
- **Entity scope nuance** (`population`, `system`, `two complexes in one record — SPLIT
  REQUIRED`, `non-located claim`): `core.entity_level` is a closed enum
  (program/site/structure). Mapping: population/system → `program`, everything else →
  `site`; the verbatim scope string is preserved in `discovered_by`, the never-pin warnings
  in the geometry-assertion notes, and the split/identity problems as adjudication tasks.
- **Identifier classes** for the 5 leads: `registry.identifier_grammar` is unseeded, so
  `ingest.lead.identifier_class` stays null.
- **`function_set`** (sensitive/mundane) was not carried per proposition in graded.json;
  it stays `'n/a'`, so `base_rate_reading` is null on FUNCTION rollups where graded.json
  showed a reading (publication-only field; no arithmetic effect).
- **Beat search queries**: no `core.search_receipt` rows are created — the payload carries
  no receiptable query strings, and inventing them would manufacture the very receipts the
  sweep says do not exist. SCI numerators are honestly zero.

### 4.3 Ingest judgement calls (marked inside the rows)

- `STATUS.predicate_args.status` must come from the closed `core.status_value` enum; the 22
  statements were hand-mapped (e.g. "non-operational or mothballed" → `standby`, the
  destroyed 374-7 complex → `sealed`, museum/library conversions → `converted`). Each row
  carries the original wording in a `status_basis` key.
- EXTENT/CONTROL/PROGRAM/FEATURE/FUNCTION `predicate_args` were structured from the
  statement text (dimension/value/unit, controlling entity, program name/state); ORIGIN
  carries `claim_text`; HARDEN carries a generic unverified-threats entry.
- Observation `property_locus` is `'CLAIM-PROPERTY'` uniformly — a placeholder: the locus
  of an unread source cannot be adjudicated, and at magnitude 0 / V0 the field enters no
  arithmetic.
- Alias kinds are uniformly `facility-name`; no codename adjudication was performed
  (binding admissibility for codenames needs an IDENTITY proposition at band C).

## 5. Findings — where the schema's own computation diverges from graded.json

graded.json proposed **196 X + 4 F**. The schema's own path (chunk 20:
`core.apply_grade` → `recompute_proposition` → `evaluate_proposition`) produces
**179 X + 16 F**, with all four graded-F propositions showing `grade_pre_clamp = 'F'`.
Per the working rule, these divergences are surfaced, not forced.

### 5.1 The seeded ERP catalog has no STATUS / ORIGIN / IDENTITY / TYPOLOGY coverage

`evaluate_proposition` reaches X only through the SCI floor, and the SCI denominator is
built from applicable X1–X3 `proposition_erp` rows. No seeded `registry.erp_profile` lists
STATUS, ORIGIN, IDENTITY or TYPOLOGY in `applies_to_classes`, so those classes get an empty
denominator, SCI = 1.000 by the §7.2 denominator-zero correction, and CAP-5 (V empty)
yields **F where graded.json proposed X**. This is exactly the route graded.json used for
its four F's — the payload's X for these 40 rows rests on GRADING.md §10.5
("X — VERIFICATION PENDING": unverified leads whose claimed diagnosticity could raise the
band), **a route `evaluate_proposition` does not implement**. Remedies (a schema/registry
decision, not an ingest one): add ERP profiles for those classes, or implement the 10.5
X-route.

The four graded-F propositions carry graded.json's explicit ERP adjudication so the
schema reproduces their F honestly: no `proposition_erp` rows for RES-029-FUNCTION and
RES-035-EXIST/FUNCTION ("Applicable ERP profiles: none"), and only the three X0
covert-facility profiles for RES-032-FUNCTION.

### 5.2 Schema defect: clamping an F child under an unranked X parent is unrepresentable

`core.grade_min` treats unranked grades as dominating, so `recompute_proposition` clamps an
F-band child under an X-graded EXIST parent **to X** — but such a child's SCI is 1.000
(empty denominator), and `grade_event.grade_x_has_low_sci` requires `sci < 0.5` for X.
`apply_grade` therefore raises on exactly 28 propositions (22 STATUS, 3 IDENTITY,
1 TYPOLOGY, plus RES-029-FUNCTION and RES-032-FUNCTION — two of the four graded F's).
Note graded.json reads BES §1.4 the opposite way: "X is unranked and does not clamp
children."

Chunk 20 handles this without hiding it: the failing propositions fall back to
`core.recompute_proposition()` (rollup cached: `grade = X` by clamp, `grade_pre_clamp = F`,
`clamped_by` set — but **no immutable grade_event can exist for this state**), and their
regrade-queue rows are parked (`attempts = 3`, `last_error` naming this defect) so the
condition stays visible. The verify script asserts the exact split: 195 rollups, 167
events, 28 event-less rollups, queue parked-or-cleared.

**This needs a schema decision** before W2: either exempt unranked parents from the clamp
(matching graded.json's reading of §1.4), or relax/condition `grade_x_has_low_sci` for
clamped events. Until then, RES-029-FUNCTION and RES-032-FUNCTION publish X-by-clamp in the
rollup while their pre-clamp F is preserved on the same row.

### 5.3 Minor divergences

- `transition_cause` is `INITIAL` (these are first gradings); graded.json wrote
  `NEW-SEARCH`.
- `silence_reading` on CONTROL/FUNCTION rollups reads `RECORD-DESTROYED` because the
  NPRC-fire profile (silence_override) applies to those classes under the mechanical
  mapping; its 1912–1964 era restriction is not modeled per proposition. X0 profile — no
  grade effect, but the published silence prose will over-claim the fire's relevance for
  modern facilities until per-proposition ERP applicability is adjudicated.
- `base_rate_reading` is null where graded.json showed a reading (see §4.2 function_set,
  and the seed's base-rate table only covers EXIST/HARDEN/CONTROL/FUNCTION).
- Grade events for X rows carry `awarded_band = 'F'` (the band before the SCI floor) —
  consistent with graded.json's "the provisional band the SCI floor withheld is F".

### 5.4 Publication gate observation (for the operator)

`core.assert_publishable()` **passes** for these entities as loaded: X/F propositions with
all-V0 evidence are publishable claims-register content by the schema's design (ground (d)
only checks *counted* V/U observations, and there are none). Nothing in this load publishes
anything — but be aware the gate would not stop an accidental `ops_publish_entity` call.
Publication remains a deliberate operator decision, and per deploy report §6.1 it currently
also breaks the public read model. Do not publish from this load.

## 6. What this load deliberately does not do

- **No publication**: zero rows leave `INTERNAL`; zero `publication_log` entries; anon
  sees nothing (verified by `SET ROLE anon` in the verify script).
- **No map presence**: no coordinates, no pins, nothing for `api.refresh_map()` to pick up.
- **No verified receipts, no VERIFIED anything**: resolve-or-die is respected by loading
  the failure honestly, not by faking success.
- **No confirmed citogenesis, no refutations, no R grades**: the beats proposed and
  declined to confirm; §8.4 forbids refutation on expected-record negatives.
- **No canaries touched, no fixture rows touched, no corpus tier assignments, no
  identifier promotions, no search receipts, no drain of non-sweep queue rows.**

## 7. Row provenance / regeneration

All UUIDs are UUIDv5 under a fixed namespace (`uuid5(NAMESPACE_URL, 'bunkers-sweep-01')`)
keyed by payload identity (`ent:RES-001`, `prop:RES-001-EXIST`, `doc:RES-001:0`,
`dossier:RES-001`, `obs:<pid>:supporting:<i>`, …), so the files can be regenerated
byte-stably from the payload and re-applied without duplication.
