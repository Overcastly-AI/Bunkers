# DEPLOY REPORT — Bunkers schema to live Supabase

**Project:** `fsszjobpykbpmctlzxiv` ("Bunkers", org `mhmwcthjznrazrfvyjmv`, us-east-1)
**URL:** https://fsszjobpykbpmctlzxiv.supabase.co
**Target:** PostgreSQL 17.6 / PostGIS 3.3.7
**Authored & previously verified against:** PostgreSQL 16.13 / PostGIS 3.4
**Date:** 2026-08-17 → 2026-08-18
**Outcome:** Applied. Acceptance suite **65/65**. One real PG17 incompatibility found and fixed.
Two configuration problems and one schema defect remain open and need your decision.

---

## 1. Verdict first

The schema is on the database and it works. But do not read "65/65" as "ready".
Three things are wrong that the acceptance suite does not test for, and one of them —
§6.1 — silently empties the public register. I did not fix that one, because fixing it
means deciding what publication *means*, and that is your call, not mine.

---

## 2. What applied

Applied as 11 sequential migrations, split at statement boundaries from
`supabase/schema.sql` (215 KB was too large for a single `apply_migration` call).
The split was verified programmatically: the concatenation of the parts is
whitespace-identical to the source file, and no split point falls inside a
dollar-quoted body or string literal. Dependency order was preserved exactly as
authored — no statement was reordered.

| # | Migration | Contents |
|---|-----------|----------|
| 01 | `bunkers_01_extensions_vocab_helpers` | extensions, 4 schemas, roles, §1 vocabularies, §2 helpers |
| 02 | `bunkers_02_registry_entities` | `registry.*`, `core.entity` and kin |
| 03 | `bunkers_03_geometry_propositions_documents` | geometry assertions, propositions, documents, receipts |
| 04 | `bunkers_04_spans_search_observation` | spans, leads, search receipts, `core.observation` |
| 05 | `bunkers_05_citation_graph_lineage_origin_trace` | citation graph, lineage, `trace_origin`, citogenesis |
| 06 | `bunkers_06_refutation_nullstate_evaluate` | refutation, null state, `evaluate_proposition` |
| 07 | `bunkers_07_grade_events_rollup_apply_grade` | grade events, rollup, clamp, ratchet |
| 08 | `bunkers_08_queue_publication_render_geometry` | regrade queue, publication gate, `render_geometry` |
| 09 | `bunkers_09_map_views_ingest_rls_enable` | map matviews, ingest telemetry, RLS enable |
| 10 | `bunkers_10_rls_policies_api_views_grants` | 101 policies, 9 api views, grants |
| 11 | `bunkers_11_candidate_detail_and_seed` | `candidate_detail`, §19 seed |

Then:

| # | Migration | Why |
|---|-----------|-----|
| 12 | `bunkers_test_harness_result_table` | temporary assertion recorder (removed in 14) |
| 13 | `bunkers_fix_pg17_restricted_search_path_on_postgis_functions` | **the one real fix — see §3** |
| 14 | `bunkers_teardown_acceptance_harness` | removed the harness; withdrew test fixtures |

### Object counts, observed vs. the header's claim

| Object | schema.sql header claims | Actually created | |
|---|---|---|---|
| Tables | 56 | **56** | ✔ |
| api views | 9 | **9** | ✔ |
| Materialised views | 2 | **2** | ✔ |
| Indexes | 167 | **167** | ✔ |
| RLS policies | 101 | **101** | ✔ |
| Triggers | 22 | **22** | ✔ |
| Functions | 51 | **50** | drift |
| CHECK constraints | 88 | **85** | drift |

Functions: 48 in `core`/`registry`/`api`/`ingest`, plus `ops_publish_entity` and
`ops_withdraw_entity`, which land in `public` because they are declared unqualified.
CHECK constraints: 83 table-level across `core`/`registry`/`ingest` plus 2 domain
constraints (`core.sha256`, `core.iso_country`).

The two drifts are counting differences, not missing objects — every named object
in the file exists. They are worth reconciling in the header so future runs have a
trustworthy checksum, but nothing is absent.

RLS is enabled on **56 of 56** tables in `core`/`registry`/`ingest`. Zero exceptions.

---

## 3. The PG17 incompatibility, and the DDL I changed

**This is the version difference you told me to watch for. It is real, and it is a hard failure.**

### What broke

```
ERROR: 42704: type "geometry" does not exist
QUERY:  select 'uncertainty_circle'::core.geometry_representation,
        st_buffer(ga.point_geom::geography, rad)::geometry(Geometry,4326), ...
CONTEXT: PL/pgSQL function core.render_geometry(uuid) line 54 at RETURN QUERY
```

Triggered by `refresh materialized view api.map_feature`. Not by PostGIS 3.3.7 —
PostGIS was innocent (see §3.3). By PostgreSQL 17.

### Root cause

**PostgreSQL 17 runs maintenance operations as security-restricted operations with
`search_path` forced to `pg_catalog, pg_temp`.** `REFRESH MATERIALIZED VIEW` is one of
them (so are `CREATE MATERIALIZED VIEW`, `CREATE INDEX`, `REINDEX`, `CLUSTER`, `VACUUM`,
`ANALYZE`). This is new in 17; on PG 16.13 the session `search_path` was inherited, which
is why the file verified clean there.

`core.render_geometry()` is PL/pgSQL with no pinned `search_path`, and it references the
PostGIS `geometry` and `geography` types and `st_buffer()` **unqualified**. A PL/pgSQL
body is parsed at execution time, not at definition time, so under the stripped
`search_path` those names cannot resolve.

Confirmed by direct reproduction rather than inference:

```sql
set search_path = pg_catalog, pg_temp;
select * from core.render_geometry(<entity>);   -- same error, verbatim
```

The blast radius is the whole map: `api.map_feature` cannot be refreshed at all,
which also means `api.map_cluster` (which reads it) and `api.refresh_map()` are dead.
`api.refresh_map()` cannot dodge this by setting its own `search_path`, because the
`REFRESH` *inside* it re-enters the restricted context.

### What I changed

```sql
alter function core.render_geometry(uuid)
  set search_path = core, registry, public, extensions;

alter function api.map_viewport(double precision, double precision, double precision,
                                double precision, integer, core.grade,
                                core.typology[], text[])
  set search_path = api, core, registry, public, extensions;

alter function api.map_tile(integer, integer, integer)
  set search_path = api, core, registry, public, extensions;

alter function api.candidate_detail(text)
  set search_path = api, core, registry, public, extensions;
```

**Why this and nothing more.** `core.render_geometry` is the only one of the four that
was actually broken. The other three are the same latent defect — I audited every
function body in `core`/`registry`/`api` for unqualified PostGIS references and these
four are the complete set — and they happen to work today only because PostgREST sets a
`search_path` that contains `public`. Pinning them makes name resolution deterministic
for every caller instead of dependent on who is calling.

**This changes no logic.** It changes name resolution only. No grade semantics, no band
condition, no cap, no RLS predicate, no data model. It also clears four instances of the
Supabase `function_search_path_mutable` advisory, verified: `core.render_geometry` no
longer appears in the security advisor output.

Verified after the change, under the hostile `search_path`:

```
representation      = uncertainty_circle
suppression_reason  = "LOCATE proposition below band C: rendered as uncertainty, never as a pin"
```

### 3.3 What did *not* break: PostGIS 3.3.7

The schema uses `ST_AsGeoJSON`, `ST_AsMVT`, `ST_AsMVTGeom`, `ST_Buffer`, `ST_Centroid`,
`ST_Collect`, `ST_Envelope`, `ST_MakeEnvelope`, `ST_Point/3`, `ST_PointOnSurface`,
`ST_SnapToGrid`, `ST_TileEnvelope`, `ST_Transform`, `ST_X`, `ST_Y`. All exist in 3.3.x
(`ST_TileEnvelope` since 3.0, three-argument `ST_Point` since 3.2). **No 3.4-only
function is used and the downgrade to 3.3.7 caused no failure whatsoever.** The version
difference that mattered was Postgres, not PostGIS.

**`schema.sql` is not yet patched.** I applied the fix to the live database only, per
your instruction not to commit. Fold migration 13 into `supabase/schema.sql` before the
next clean apply, or the next deployment reproduces the bug.

---

## 4. Acceptance results — 65 / 65, zero failures

Run against the live database. `t_ok()` was rewritten to record each assertion to a
table *and* still raise on failure, so the count is measured, not inferred from the
absence of an error. Nothing else in the suite was altered except removing the psql
meta-command `\set ON_ERROR_STOP on`, which `execute_sql` cannot parse.

| Requirement | Assertions | Failed |
|---|---|---|
| REQ1 propositions graded independently, clamp | 5 | 0 |
| REQ2 undercuts move grades down | 1 | 0 |
| REQ3 resolve-or-die, canaries, publication gate | 8 | 0 |
| REQ4 lineage collapse, echo chambers | 5 | 0 |
| REQ5 cyclic graph termination | 5 | 0 |
| REQ6 grades as append-only events | 5 | 0 |
| REQ7 geometric uncertainty | 4 | 0 |
| REQ8 RLS / anon boundary | 16 | 0 |
| REQ9 map projection & tile path | 10 | 0 |
| REQ10 queue, no-delete, rollup-is-a-cache | 6 | 0 |
| **Total** | **65** | **0** |

(The file contains 70 `t_ok` call sites; five are `t_ok(false, …)` arms inside exception
handlers that are unreachable when the schema behaves. 65 executed — matching the header.)

The suite had to be run in four transactions rather than one, because `execute_sql` wraps
each call in a transaction and a mid-file failure would roll back everything before it.
This is closer to `psql -f` semantics than a single transaction would have been, since
psql autocommits per statement.

---

## 5. The three things you asked me to verify by inspection

### 5.1 Recursive origin trace on a cyclic citation graph — **CONFIRMED, fix is present and works**

The deployed `core.trace_origin` body was read out of `pg_proc` and checked directly:
plain `UNION` (not `UNION ALL`), no `CYCLE … SET … USING` clause, **no path array** in
the recursive term, and `distinct on (node)` for the shallowest reach. The fix described
in the header is genuinely in the deployed function.

Behaviour on a deliberately dense cyclic fixture — 40 documents, 420 edges, containing
mutual 2-cycles — measured on this database:

| Depth | Deployed `trace_origin` |
|---|---|
| 25 | 20 nodes, **4.2 ms** |
| 40 | 20 nodes, **2.8 ms** |
| 60 | 20 nodes, **4.0 ms** |

Flat. It does not care how deep you ask.

I also ran the counterfactual — the `UNION ALL` + path-array formulation the header says
fails — against the **same** fixture:

| Depth | Rows | Time |
|---|---|---|
| 4 | 7,391 | 12.6 ms |
| 5 | 59,231 | 107.8 ms |
| 6 | 422,111 | 1,004 ms |

~8× per level. Depth 8 would be ~27 M rows; depth 25 is not reachable. This closely
reproduces the header's own measurements and confirms the defect was real and the fix is
the thing preventing it. `core.lineage_components` resolved the 40-node cyclic cluster
well inside budget, and `core.origin_path` terminates.

**One correction to the documentation.** The header claims termination rests on *three*
independent grounds, the third being "a node budget". It does not. `core.traversal_node_budget()`
exists, returns 20000, and is **referenced by nothing** — I checked every function body in
`core`, `api`, `registry`, `ingest` and `public`. Termination rests on two grounds: UNION
node-deduplication and the depth cap. Both are sound and both are sufficient. But the
claim is overstated, and dead code that looks like a safety mechanism is worse than no
code at all, because the next reader will trust it.

### 5.2 Anonymous/public roles cannot read unpublished or unverified rows — **CONFIRMED, but not by the suite**

**The acceptance suite's own leak assertions cannot detect a leak.** Several REQ8 tests
have the shape:

```sql
select count(*) into n from core.entity;                        -- run as anon
perform t_ok(n = (select count(*) from core.entity
                   where publication_state='PUBLISHED'), …);    -- also run as anon
```

Both sides are RLS-filtered. If the policy leaked every row, both counts would still be
equal and the assertion would still pass. It is close to a tautology.

So I ran an independent audit instead: every table in `core`/`ingest`/`registry` counted
twice — once as `postgres` (which has `BYPASSRLS = true`, giving ground truth) and once
as `anon`. Results on tables that held rows:

| Table | True rows | Visible to anon | Verdict |
|---|---|---|---|
| `core.entity` | 6 | 2 | filtered |
| `core.proposition` | 6 | 4 | filtered |
| `core.observation` | 55 | 6 | filtered |
| `core.source_document` | 94 | 5 | filtered |
| `core.retrieval_receipt` | 54 | 5 | filtered |
| `core.grade_event` | 9 | 4 | filtered |
| `core.grade_event_observation` | 60 | 5 | filtered |
| `core.document_citation` | 420 | **0** | withheld |
| `core.proposition_rollup` | 6 | **0** | withheld (see §6.1) |
| `core.geometry_assertion` | 4 | 2 | filtered |
| `core.entity_alias` | 3 | 2 | filtered |
| `core.quoted_span` | 3 | 2 | filtered |
| `core.alternative_disposition` | 6 | 4 | filtered |
| `core.clamp_event` | 1 | 1 | correct — its parent is published |
| `core.publication_log` | 2 | 2 | correct — both entities were published |
| `registry.*` (10 tables) | — | all | **by design** — `anon_read using (true)` |

`core.witness`, `core.lineage`, `core.refutation` held no rows in this fixture, so their
policies were exercised only by the suite; their predicates were read and are
publication-gated.

Privilege boundary, checked directly rather than through the suite:

| `anon` can… | |
|---|---|
| execute `ops_publish_entity` | **no** |
| execute `ops_withdraw_entity` | **no** |
| execute `api.refresh_map` | **no** |
| execute `core.apply_grade` | **no** |
| execute `core.evaluate_proposition` | **no** |
| `USAGE` on schema `ingest` | **no** |
| execute `api.map_viewport` | yes (intended) |

The `registry.*` tables being wholly public is deliberate — the methodology, the
diagnosticity catalog, the ERP profiles and the tier ladder are the product. Flagging it
here only so nobody later mistakes it for a leak.

**No unpublished or unverified adjudication state is reachable by an anonymous reader.**

### 5.3 PostGIS spatial indexes on the map query path — **CONFIRMED**

Eight GiST indexes exist; three are on the map read path exactly as the design requires:

| Relation | Index | Column | Serves |
|---|---|---|---|
| `api.map_feature` | `map_feature_gix` | `geom` (4326) | viewport bbox |
| `api.map_feature` | `map_feature_gix_3857` | `geom_3857` (stored) | vector tiles |
| `api.map_feature` | `map_feature_label_gix` | `label_point` | clustering |
| `api.map_cluster` | `map_cluster_gix` | `centroid` | zoomed-out viewport |
| `core.geometry_assertion` | `geometry_point_gix` | `point_geom` | source geometry |
| `core.geometry_assertion` | `geometry_region_gix` | `region_geom` | source geometry |
| `registry.admin_area` | `admin_area_geom_gix` | `geom` | admin fallback |
| `ingest.null_return` | `null_return_geom_gix` | `examined_geom` | negative-space telemetry |

The key property — that the tile predicate filters the **stored** `geom_3857` rather than
transforming per row — was verified on a 20,000-row fixture: the plan is an Index Scan,
and the stored-column filter beat the per-row `st_transform` form. This is REQ9 and it
passed on real timings, not on assertion of intent.

---

## 6. Problems. Ranked. Read §6.1 before anything else.

### 6.1 — SEVERE — Rebuilding the rollup cache silently unpublishes the entire register, and the schema's own blank-map guard cannot see it

`core.proposition_rollup` carries this comment:

> *"Materialised read model, fully recomputable from core.observation via
> core.recompute_proposition(). The grade is never stored knowledge, only cached knowledge."*

**That is false for two columns.** `core.recompute_proposition()` inserts with
`is_published` defaulting to `false` and `current_grade_event_id` defaulting to `null`.
Its `ON CONFLICT DO UPDATE` set-list preserves them, so an ordinary in-place recompute is
fine — but any rebuild that *deletes first* loses both.

The acceptance suite's own final test does exactly that:

```sql
delete from core.proposition_rollup;
perform core.recompute_proposition(proposition_id) from core.proposition …;
perform t_ok(before_state = after_state, 'REQ10 the rollup is a CACHE: … bit-identical');
```

It compares only `grade`. It passes. Meanwhile, measured on the live database immediately
afterwards:

| | |
|---|---|
| Propositions with `publication_state = 'PUBLISHED'` | 4 |
| Rollup rows with `is_published = true` | **0** |
| Rollup rows with a `current_grade_event_id` | **0** |
| Rows visible to `anon` in `core.proposition_rollup` | **0** |

Consequences, all confirmed live:

1. RLS on `core.proposition_rollup` requires `is_published`. Every grade vanishes from
   `api.proposition_badge` for anonymous readers. The public register goes blank.
2. `api.proposition_badge` LEFT JOINs `core.grade_event` on `current_grade_event_id`,
   now null — so `rubric_version`, `scorer_model_id` and `evidence_state_hash` all go
   null on every badge. The provenance beacon empties out.
3. `api.map_feature` requires `pr.is_published`. On the next refresh the map empties.

And the guard that exists precisely to catch a blank map cannot fire:

```sql
select count(*) into n_pub from core.proposition_rollup
 where is_published and grade in ('A','B','C','D');
...
if n_pub > 0 and n_feat = 0 then raise exception '…' ; end if;
```

**The guard is expressed in terms of the very column that was lost.** With `is_published`
wiped, `n_pub` is 0, the condition is false, and `api.refresh_map()` returns success while
producing an empty map. I ran it. It returned without raising, and `api.map_feature` went
from 1 row to 0 with two entities still `PUBLISHED` in `core.entity`.

**I did not fix this, deliberately.** The obvious repair — have `recompute_proposition()`
derive `is_published` from `core.proposition.publication_state = 'PUBLISHED'` — would make
public visibility a side effect of a cache rebuild. In a register whose entire security
model rests on `is_published`, and where publication is described as "one deliberate,
transactional, GATED act", that is a semantic change to the most consequential boundary in
the system. You decide, not me.

Candidate directions, in rough order of how much I would trust them:

- **Make the guard independent of the corrupted column.** Compare `api.map_feature`
  against `core.entity where publication_state='PUBLISHED'`, which no recompute touches.
  This is strictly an improvement regardless of which fix you choose for the root cause,
  and it costs nothing.
- **Make `is_published` a generated/derived read rather than a stored flag** — e.g. drop
  the column and have the RLS policy call `core.proposition_is_public(proposition_id)`,
  which already exists, is SECURITY DEFINER, and already reads `publication_state` from
  the authoritative tables. This makes the "fully recomputable" claim true.
- **Forbid `DELETE` on `core.proposition_rollup`** the way ten other core tables already
  forbid it, forcing rebuilds through the `ON CONFLICT` path that preserves both columns.
  Narrowest change; leaves the documentation claim still false.
- Whichever you pick, **the REQ10 assertion must be widened** to compare `is_published`
  and `current_grade_event_id`, not just `grade`. As written it certifies the property it
  is violating.

*Current live impact: none.* The only affected rows were test fixtures, which are now
withdrawn (§7). But this will bite the first time anyone rebuilds the rollup on real data.

### 6.2 — HIGH — PostgREST is exposing `public`, and is **not** exposing `api`

`schema.sql` states its own premise plainly:

> *"PostgREST is pointed at `api` ONLY; core/ingest/registry have no …"*

**That is not the case on this project.** There is no `pgrst.db_schemas` override on the
`authenticator` role or at database level, so the project's default API setting applies —
`public, graphql_public`. Corroborated by the advisor, which reports `public.spatial_ref_sys`
as "exposed to PostgREST" and `public.st_estimatedextent` as reachable at
`/rest/v1/rpc/st_estimatedextent`, while flagging nothing in `api` at all.

Two consequences, both bad in opposite directions:

- **Nothing in the published projection is reachable.** All 9 `api` views, both
  materialised views, `api.map_viewport`, `api.map_tile` and `api.candidate_detail` are
  invisible over REST. The public register has no public interface.
- **PostGIS is reachable instead.** Because `create extension postgis` put it in `public`
  (§6.3), roughly 965 functions in `public` are exposed as RPC endpoints to `anon`,
  including three SECURITY DEFINER overloads of `st_estimatedextent`.

**Fix (manual, you must do it — it is a project setting, not SQL):**
Dashboard → Settings → API → Exposed schemas → set to `api` (and `graphql_public` if the
GraphQL endpoint is wanted). Remove `public`. Then re-run `get_advisors`; the
`st_estimatedextent` and `spatial_ref_sys` findings should disappear, because they are
findings *about exposure*, not about the objects themselves.

Do this before any public launch. Right now the register serves PostGIS and not itself.

### 6.3 — MEDIUM — PostGIS, pg_trgm and btree_gist installed into `public`

`schema.sql` line 144–146 uses bare `create extension if not exists postgis;` etc., which
installs into the first writable schema on the path — `public`. Supabase's convention is
`extensions`. Three `extension_in_public` advisories, and it is the reason §6.2's second
bullet is as bad as it is, and the reason §3's fix has to name `public` in the search paths.

I did **not** relocate them. `ALTER EXTENSION postgis SET SCHEMA extensions` would
invalidate every `geometry` column type reference, every GiST index and both materialised
views, and PostGIS specifically documents relocation as unsupported once objects depend on
it. Doing that unilaterally on a live database is not a name-resolution fix, it is a
rebuild.

**Recommendation:** change `schema.sql` to `create extension if not exists postgis with schema extensions;`
(same for `pg_trgm`, `btree_gist`) and re-apply from empty. This database is empty of real
data, so a clean re-apply is cheap *right now* and will never be cheaper. If you do that,
change the four pinned search paths in migration 13 from `public, extensions` to
`extensions` and the §6.2 exposure problem largely solves itself.

### 6.4 — MEDIUM — 40 functions still have a mutable `search_path`

After my fix cleared four, 40 remain (38 in `core`, 2 in `registry`). All are
SECURITY INVOKER, so this is not a privilege-escalation hole today — the six
SECURITY DEFINER functions that matter (`ops_publish_entity`, `ops_withdraw_entity`,
`api.refresh_map`, `core.entity_is_public`, `core.proposition_is_public`,
`core.document_is_public`) **are** correctly pinned.

But §3 is the proof that unpinned `search_path` is not merely a lint here: it is how the
map broke. Any of these 40 invoked from a PG17 maintenance context, or from a caller with
a different path, is a latent repeat. None currently references PostGIS unqualified — I
checked — so none is broken today. Pin them anyway, in `schema.sql`, as a class.

### 6.5 — MEDIUM — Two SECURITY DEFINER publication functions live in the REST-exposed `public` schema

`ops_publish_entity` and `ops_withdraw_entity` are declared without schema qualification,
so they landed in `public` — the schema PostgREST currently exposes. They are SECURITY
DEFINER. The only thing standing between an anonymous caller and
`POST /rest/v1/rpc/ops_publish_entity` is the `REVOKE EXECUTE` in §14 of the file.

That revoke **is** in place and I verified it directly: `anon` and `authenticated` cannot
execute either function. So this is not currently exploitable. But the single most
consequential operation in the system — the one act that moves adjudication state into
public view — is protected by one `REVOKE` in a REST-exposed schema, with no schema
boundary behind it. Give them an `ops` schema, or put them in `core`, and let the schema
grant be the second line of defence.

### 6.6 — LOW — `core.traversal_node_budget()` is dead code

See §5.1. Either wire it into `core.trace_origin` as the third stop the header promises,
or delete it and correct the header. Right now it is a safety mechanism that exists only
as a comment.

### 6.7 — LOW — Header object counts drift

51 functions claimed / 50 present; 88 CHECK constraints claimed / 85 present. Nothing is
missing (§2). Reconcile the numbers so the header can be used as a checksum.

### 6.8 — INFO — Performance advisors: 157 findings, all INFO

90 × `unindexed_foreign_keys`, 67 × `unused_index`. Both are expected and neither is
actionable yet:

- **Unused indexes** are meaningless on a database that has never served a query. Re-run
  this advisor after real traffic; do not drop anything on this evidence.
- **Unindexed foreign keys** matter mostly for cascading deletes and for joins on the FK
  side. Deletes are structurally forbidden here, which removes the usual worst case. But
  `core.observation` → `core.proposition` and the citation-graph FKs will be joined hard
  at scale. Revisit once `core.observation` is past ~10⁵ rows, with real query shapes in
  hand rather than a linter's guess.

---

## 7. State of the database as I leave it

**Fixture residue — the acceptance suite writes to the live database, and its rows remain.**

The suite is not read-only. It creates entities, propositions, documents, receipts and a
420-edge citation graph, and it publishes two entities. `core.*` is append-only by design,
so those rows cannot simply be deleted.

What I did about it:

- **Withdrew** the two published fixtures (`test-greenbrier`, `test-mappable`) via
  `ops_withdraw_entity()` — the schema's own sanctioned exit from `PUBLISHED` — so no
  test-shaped candidate is visible to an anonymous reader.
- **Refreshed** both materialised views. `api.map_feature` is now empty.
- **Dropped** everything my harness introduced: `public.t_result` (which the security
  advisor had correctly flagged as an RLS-disabled table in an exposed schema — it is
  gone, re-verified), `public.leak_audit()`, and `core.t_ok` / `core.t_doc` / `core.t_receipt`.
- **Revoked** the temporary sequence grant to `anon`.

Confirmed after teardown: `published_entities = 0`, `map_features = 0`,
`public.t_result` does not exist.

**What remains:** 6 entities, 6 propositions, 55 observations, 94 source documents,
54 retrieval receipts, 420 citation edges — all `INTERNAL`/`WITHDRAWN`, none publicly
visible. Plus two fixture rows in `registry.corpus` (`govinfo`, `atsforum`) and two in
`registry.scorer_model` (`test-model`, `family-alpha`; `other-model`, `family-beta`),
which **are** publicly readable, since `registry.*` is public by design.

**I did not purge them.** `TRUNCATE` would bypass `core.forbid_delete()`, and that trigger
is a load-bearing guarantee of this register, not an obstacle. Working around it on a live
database is your call.

If you want a pristine register, the honest option is to **re-apply from empty** — which
you should be considering anyway for §6.3, and which is cheap exactly once, now, before
real ingest. Recommended order:

1. Fold migration 13's fix into `supabase/schema.sql` (§3).
2. Change the three `create extension` lines to `… with schema extensions` (§6.3).
3. Pin `search_path` on the remaining 40 functions (§6.4).
4. Decide §6.1 and implement it, and widen the REQ10 assertion to match.
5. Move `ops_*` out of `public` (§6.5).
6. Reset the database, re-apply, re-run acceptance.
7. Set Exposed schemas to `api` (§6.2).

Steps 1–5 are edits to the repo, which is yours to commit. **I have not committed
anything to git**, per instruction.

---

## 8. Summary for the record

- **Applied:** yes, in full, on PostgreSQL 17.6 / PostGIS 3.3.7.
- **Acceptance:** 65 / 65, zero failures, measured rather than assumed.
- **PostGIS 3.3.7 vs 3.4:** no incompatibility. The downgrade was a non-event.
- **PostgreSQL 17 vs 16:** one hard incompatibility, found, diagnosed by reproduction,
  and fixed with four `ALTER FUNCTION … SET search_path` statements that change no logic.
- **RLS:** enabled on 56/56 tables, 101 policies, independently audited. No unpublished or
  unverified adjudication state reaches an anonymous reader.
- **Advisors:** 1 security ERROR (`public.spatial_ref_sys`, a consequence of §6.3/§6.2),
  49 security WARNs, 157 performance INFOs. None indicates an RLS gap on register data.
- **Biggest open problem:** §6.1. Rebuilding the rollup cache silently unpublishes the
  register, and the guard built to detect exactly that failure is blind to it. Not fixed —
  it needs a decision about what publication means, and that decision is yours.
