# BUNKERS — database schema

PostgreSQL 15+ / PostGIS 3.x (Supabase). Implements **BES v0.2 — Tiered
Sufficiency with Signed Evidence**.

Apply in order:

```
001_types_and_reference.sql      types; the four versioned curated tables; 158-source registry
002_entities_and_propositions.sql entities, geometry-with-uncertainty, propositions
003_documents_lineage_citations.sql documents, receipts, citation graph, lineage, attestation custody
004_evidence_and_search.sql      signed evidence, search receipts, ERP applicability
005_rollups_and_grading.sql      materialised rollups, grade events, the §9.4 algorithm
006_triggers_publication_rls.sql rollup maintenance, publication, RLS policies + grants
007_ops_and_telemetry.sql        ops schema (never anon-readable) + published telemetry views
008_seed.sql                     curated-table seed: tiers, nulls, diagnosticity, ERP, base rates
009_app_queries.sql              the four queries the app runs, as SECURITY INVOKER functions
010_calibration_test.sql         §12.7 regression harness — runs in a transaction and rolls back
```

Verified against a live PostgreSQL 16.13 + PostGIS 3.4 instance. The calibration
harness reproduces every load-bearing pair from the two critiques:

| Case | Expected | Returned |
|---|---|---|
| Site CARDINAL (canary) | F | **F** (V=∅ → CAP-5) |
| One gate-passing D4 record, nothing else | A | **A** (A1, documentary sufficiency) |
| Camp Hero EXIST / "Montauk Project" FUNCTION | A / F | **A / F** |
| DUCC PROGRAM / EXIST | A / R | **A / R** (clamp exemption) |
| Greenbrier 1991 EXIST / FUNCTION(COG) | B / E | **B / E** (CAP-2b, at ceiling) |
| Greenbrier post-1992 EXIST | A | **A**, cause `NEW_DISCLOSURE` |
| SubTropolis HARDEN | R | **R** (R2) |
| Sauder 129 DUMBs EXIST | F | **F** (§8.4 gate holds) |
| Mount Weather EXIST / "underground city" | A / E+flag | **A / E**, `citogenesis=true` |
| Federal Relocation Arc instance EXIST / LOCATE | C / low | **C / F**, renders as region |

## The three rules that carry the design

1. **Nothing graded lives on a site.** `entity` is a container; every grade is a
   row in `proposition`. "The hole is certain, the function is not" is one entity
   with `EXIST=A` and `FUNCTION=E`, rendered as two badges on one page.
2. **Evidence is signed and bound.** An `evidence` row supports or undercuts
   exactly one proposition, at a magnitude, against a named alternative. The
   seven exclusions in `v_evidence_merged` are the whole anti-gaming ledger.
3. **The rollups are a cache, never the truth.** Drop `proposition_rollup` and
   `entity_rollup` and rebuild them exactly with
   `bes_recompute_proposition()` + `bes_recompute_entity()`.

## Operating notes

* Ingest writes evidence; triggers enqueue to `ops_regrade_queue`; a worker calls
  `bes_drain_regrade_queue()`. Nothing recomputes the whole table.
* `ops_publish_entity()` is the only path to public visibility. It publishes the
  transitive citation closure, so the origin trace is never truncated.
* Every recursive traversal in this codebase carries a `CYCLE` clause **and** a
  depth cap. The citation graph is cyclic by nature — that is what citogenesis is.
* `grade_event` is append-only; the only permitted mutation is `is_published`,
  and the trigger proves it by diffing the row.
