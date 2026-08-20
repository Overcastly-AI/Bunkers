-- ============================================================================
-- BUNKERS register — W1 sweep-01 post-load verification
-- Run AFTER all 20 chunks of sweep-01.sql. Every assertion RAISES on failure; a clean run
-- ends with the summary SELECTs. Scoping: sweep rows only (entity slug ~ '^res-0dd-',
-- proposition.created_by = 'sweep-01-ingest'), so the pre-existing acceptance-fixture residue
-- documented in docs/DEPLOY-REPORT.md §7 is never counted. Safe to re-run; writes nothing.
-- ============================================================================

do $verify$
declare
  n bigint; n2 bigint; msg text;

  -- deterministic document ids (uuidv5 under the sweep-01 namespace)
  schneider_pool uuid[] := array['a4fad54b-b6ba-50b8-a79a-cf6f343acba4', 'f6a59ba8-c4d7-5a6c-b5c3-8a42d42a1dc8', '606c2e9b-a70a-53b0-b110-e0df99392d4f', '8dbd2775-cbb8-59a4-8126-eff80c42bf31', '8daaad09-970f-589e-b100-b80312c7bf82', '351daaba-ff00-5669-8b52-fb9765f93e8e', '6cefca91-206d-5d6f-9bf2-6891b2025449', 'be8bb770-a4c1-54a0-9653-b798f3e93f56', 'bc561ef9-2cbd-5b49-83ff-2704cc0b871a', 'cbfff9f9-dec5-507c-a7cd-03f90d126039']::uuid[];
  subterrene_docs uuid[] := array['8ac93519-5951-5777-b862-9a128398fa25', '28c097cd-acc7-5eae-8f5c-a26cf151b8c4', 'bb8e6682-d78a-571c-aa01-95aeb58c760a', '594d358b-eb96-5e52-aed9-e24608cb43c4', '79e80fe5-c3da-51d9-8dca-5efe54cb9473']::uuid[];
  subterrene_plus_lecture uuid[] := array['8ac93519-5951-5777-b862-9a128398fa25', '28c097cd-acc7-5eae-8f5c-a26cf151b8c4', 'bb8e6682-d78a-571c-aa01-95aeb58c760a', '594d358b-eb96-5e52-aed9-e24608cb43c4', '79e80fe5-c3da-51d9-8dca-5efe54cb9473', 'a4fad54b-b6ba-50b8-a79a-cf6f343acba4']::uuid[];
begin
  ---------------------------------------------------------------- row counts
  select count(*) into n from core.entity where slug ~ '^res-0[0-9][0-9]-';
  if n <> 48 then raise exception 'entities: expected 48, found %', n; end if;

  select count(*) into n from core.proposition p join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and p.created_by = 'sweep-01-ingest';
  if n <> 195 then raise exception 'propositions: expected 195 (200 in graded.json minus 5 unrepresentable, see README), found %', n; end if;

  select count(*) into n from core.observation o join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest';
  if n <> 441 then raise exception 'observations: expected 441, found %', n; end if;

  -- documents: 257 sweep sources + 48 dossiers + 3 Schneider-family carriers
  select count(*) into n from core.source_document d
   where d.document_id in (select cited_document_id from core.document_citation
                            where asserted_by = 'sweep-01-ingest')
      or d.document_id in (select citing_document_id from core.document_citation
                            where asserted_by = 'sweep-01-ingest');
  if n <> 308 then raise exception 'documents in the sweep citation graph: expected 308, found %', n; end if;

  select count(*) into n from core.retrieval_receipt rr
   where rr.document_id in (select cited_document_id from core.document_citation
                             where asserted_by = 'sweep-01-ingest')
      or rr.document_id in (select citing_document_id from core.document_citation
                             where asserted_by = 'sweep-01-ingest');
  -- 256 source receipts (the RES-011 calibration self-reference deliberately has none) + 3 carriers
  if n <> 259 then raise exception 'retrieval receipts: expected 259, found %', n; end if;

  ---------------------------------------------------------------- resolve-or-die honesty
  select count(*) into n from core.retrieval_receipt rr
   where rr.document_id in (select cited_document_id from core.document_citation
                             where asserted_by = 'sweep-01-ingest')
     and rr.receipt_state <> 'UNRESOLVED';
  if n <> 0 then raise exception '% receipt(s) not UNRESOLVED: the sweep resolved nothing to bytes', n; end if;

  select count(*) into n from core.observation o join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and o.membership <> 'V0';
  if n <> 0 then raise exception '% observation(s) escaped V0; V and U must be EMPTY on every sweep proposition', n; end if;

  select count(*) into n from core.observation o join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and (o.signed_weight <> 0 or o.magnitude <> 0);
  if n <> 0 then raise exception '% observation(s) carry nonzero magnitude/weight', n; end if;

  ---------------------------------------------------------------- nothing published, nothing canary
  select count(*) into n from core.entity
   where slug ~ '^res-0[0-9][0-9]-' and (publication_state <> 'INTERNAL' or published_at is not null);
  if n <> 0 then raise exception '% entity rows are not INTERNAL', n; end if;
  select count(*) into n from core.entity where slug ~ '^res-0[0-9][0-9]-' and is_canary;
  if n <> 0 then raise exception '% sweep entities marked canary', n; end if;
  select count(*) into n from core.proposition p join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and p.publication_state <> 'INTERNAL';
  if n <> 0 then raise exception '% proposition rows are not INTERNAL', n; end if;
  select count(*) into n from core.observation o join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and o.publication_state <> 'INTERNAL';
  if n <> 0 then raise exception '% observation rows are not INTERNAL', n; end if;
  select count(*) into n from core.grade_event ge join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and ge.is_published;
  if n <> 0 then raise exception '% grade events are published', n; end if;
  select count(*) into n from core.entity e
   where e.slug ~ '^res-0[0-9][0-9]-' and core.entity_is_public(e.entity_id);
  if n <> 0 then raise exception 'core.entity_is_public() returns true for % sweep entities', n; end if;
  select count(*) into n from core.publication_log pl join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-';
  if n <> 0 then raise exception '% publication_log rows exist for sweep entities', n; end if;

  ---------------------------------------------------------------- grades came from the schema
  select count(*) into n from core.proposition p join core.entity e using (entity_id)
    left join core.proposition_rollup pr using (proposition_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and p.created_by = 'sweep-01-ingest' and pr.proposition_id is null;
  if n <> 0 then raise exception '% propositions have no rollup (recompute did not run)', n; end if;

  -- the cached grade corresponds to the evidence currently on file (assert_publishable ground (c))
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest'
     and pr.evidence_state_hash is distinct from core.evidence_state_hash(pr.proposition_id);
  if n <> 0 then raise exception '% rollups have a stale evidence_state_hash', n; end if;

  select count(*) into n from core.grade_event ge join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and not ge.is_blind_double_score;
  if n <> 167 then
    raise exception 'grade events: expected 167 (=195 propositions minus 28 parked by the clamp/grade_x_has_low_sci defect, README §Findings), found %', n;
  end if;

  -- expected distribution from the schema's own computation (NOT graded.json's — see README):
  --   X 179 (151 SCI-floored + 28 clamped-to-X under X parents, cached rollup only)
  --   F 16  (14 ORIGIN with empty X>=1 ERP denominators + RES-035-EXIST + RES-035-FUNCTION)
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.grade = 'X';
  select count(*) into n2 from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.grade = 'F';
  if n <> 179 or n2 <> 16 then
    raise exception 'grade distribution: expected X=179 / F=16, found X=%, F=%', n, n2;
  end if;
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.grade not in ('X','F');
  if n <> 0 then raise exception '% propositions graded outside {X,F}: nothing verified can band higher', n; end if;

  -- the four graded-F propositions are present, and the schema found F on the evidence for each
  -- (grade_pre_clamp = F). RES-035-* also hold F post-clamp; RES-029/032-FUNCTION are clamped to X
  -- by their X parents — the divergence documented in README §Findings.
  select count(*) into n from core.proposition_rollup pr
   where pr.proposition_id in ('2a083331-22ae-5691-83aa-927e0f1be7d8', 'f86a1458-c9c8-5cd2-9afd-dd78bdb569c2', '43fcc47f-5905-5322-b377-a975a7c45ad5', '3c20ea83-0cdc-5708-af64-c5604ef83d81') and pr.grade_pre_clamp = 'F';
  if n <> 4 then raise exception 'the four graded-F propositions: expected 4 with grade_pre_clamp=F, found %', n; end if;
  select count(*) into n from core.proposition_rollup pr
   where pr.proposition_id in ('43fcc47f-5905-5322-b377-a975a7c45ad5', '3c20ea83-0cdc-5708-af64-c5604ef83d81') and pr.grade = 'F';
  if n <> 2 then raise exception 'RES-035 EXIST/FUNCTION: expected grade F, found % of 2', n; end if;

  -- parked queue rows: after the FIRST run of chunk 12, exactly 28 rows sit parked
  -- (attempts=3, last_error naming the clamp/grade_x_has_low_sci defect). If chunk 12 is RE-RUN,
  -- apply_grade converges on the cached clamped rollup (X = X, no event needed) and clears them,
  -- so 0 is also a valid steady state. Anything else — or an unparked row — is a failure.
  select count(*) into n from ingest.regrade_queue q join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest';
  if n not in (28, 0) then
    raise exception 'regrade queue: expected 28 parked rows (or 0 after a chunk-12 re-run), found %', n;
  end if;
  select count(*) into n from ingest.regrade_queue q join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and q.attempts < 3;
  if n <> 0 then raise exception '% queue rows for sweep propositions are not parked (attempts<3)', n; end if;

  ---------------------------------------------------------------- lineage: the Schneider collapse
  -- Five separately-presented claim families, three beats searching blind, ONE 1995 terminus.
  select count(distinct component_root) into n from core.lineage_components(schneider_pool);
  if n <> 1 then
    raise exception 'Schneider pool: expected ONE lineage component across the five claim families, found %', n;
  end if;

  -- RES-026 discipline: the four institutional subterrene roots stay separate from each other
  -- (LA-5354-MS + its UNT mirror collapse to one; LA-4547, the 1972 patent and the DRI/DOE U12t
  -- evaluation stand alone) and NONE of them shares a component with the Schneider lecture.
  select count(distinct component_root) into n from core.lineage_components(subterrene_docs);
  if n <> 4 then raise exception 'subterrene document programme: expected 4 independent roots, found %', n; end if;
  select count(distinct component_root) into n from core.lineage_components(subterrene_plus_lecture);
  if n <> 5 then raise exception 'subterrene roots must NOT share a component with the Schneider lecture (expected 5, found %)', n; end if;

  -- compiler-exposes edges never collapse: the dossier hub must not merge its sources
  select count(*) into n from core.document_citation
   where asserted_by = 'sweep-01-ingest' and edge_kind = 'compiler-exposes' and collapses_lineage;
  if n <> 0 then raise exception '% compiler-exposes edges collapse lineages', n; end if;
  select count(*) into n from core.document_citation
   where asserted_by = 'sweep-01-ingest' and edge_kind = 'compiler-exposes';
  if n <> 257 then raise exception 'dossier compiler-exposes edges: expected 257, found %', n; end if;

  ---------------------------------------------------------------- supporting structures
  select count(*) into n from core.alternative_disposition ad join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and ad.is_selected;
  if n <> 195 then raise exception 'alternative dispositions: expected 195, found %', n; end if;
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.null_state = 'UNTESTED';
  if n <> 0 then raise exception '% rollups derived null_state UNTESTED despite selected dispositions', n; end if;

  select count(*) into n from core.proposition_erp pe join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest';
  if n <> 1062 then raise exception 'proposition_erp rows: expected 1062, found %', n; end if;
  select count(*) into n from core.proposition_erp pe join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pe.searched;
  if n <> 0 then raise exception '% ERP rows claim a search happened; every canonical corpus was egress-blocked', n; end if;

  select count(*) into n from core.citogenesis_loop cl join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest';
  select count(*) into n2 from core.citogenesis_loop cl join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and cl.state = 'confirmed';
  if n <> 18 or n2 <> 0 then
    raise exception 'citogenesis: expected 18 suspected / 0 confirmed, found % / %', n, n2;
  end if;
  -- and therefore CAP-3 never fired:
  select count(*) into n from core.proposition_rollup pr join core.proposition p using (proposition_id)
   where p.created_by = 'sweep-01-ingest' and pr.citogenesis;
  if n <> 0 then raise exception '% rollups show confirmed citogenesis; the sweep only PROPOSED loops', n; end if;

  select count(*) into n from ingest.lead
   where identifier in ('AD1078617','310505952','CMPT-2016-0001','HGTWMDQ0010','LSBGVA05')
     and state = 'new' and promoted_document_id is null;
  if n <> 5 then raise exception 'identifier leads: expected 5 unpromoted, found %', n; end if;

  select count(*) into n from core.entity_alias a join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-';
  if n <> 193 then raise exception 'aliases: expected 193, found %', n; end if;
  select count(*) into n from core.entity_relation rel
   where rel.asserted_by = 'sweep-01-ingest';
  if n <> 19 then raise exception 'entity relations: expected 19, found %', n; end if;
  select count(*) into n from core.geometry_assertion ga join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and ga.superseded_at is null;
  if n <> 48 then raise exception 'geometry assertions: expected 48, found %', n; end if;
  -- no coordinate exists anywhere in the sweep — nothing may ever have become a pin
  select count(*) into n from core.geometry_assertion ga join core.entity e using (entity_id)
   where e.slug ~ '^res-0[0-9][0-9]-' and (ga.point_geom is not null or ga.region_geom is not null);
  if n <> 0 then raise exception '% geometry assertions carry a shape; the sweep holds none', n; end if;

  raise notice 'sweep-01-verify: all assertions passed';
end
$verify$;

-- ---------------------------------------------------------------------------
-- Anonymous-visibility check: as anon, ZERO sweep rows are readable anywhere.
-- The BEGIN makes 'set local' valid when the executor runs statements in
-- autocommit; under an executor that already wraps the call in a transaction
-- it is a harmless no-op warning. Role is restored by RESET ROLE either way.
-- ---------------------------------------------------------------------------
begin;
set local role anon;
do $anon$
declare n bigint;
begin
  select count(*) into n from core.entity where slug ~ '^res-0[0-9][0-9]-';
  if n <> 0 then raise exception 'anon can see % sweep entities', n; end if;
  select count(*) into n from core.proposition where created_by = 'sweep-01-ingest';
  if n <> 0 then raise exception 'anon can see % sweep propositions', n; end if;
  select count(*) into n from core.observation where asserted_by like 'resolved.json W1%';
  if n <> 0 then raise exception 'anon can see % sweep observations', n; end if;
  select count(*) into n from core.document_citation where asserted_by = 'sweep-01-ingest';
  if n <> 0 then raise exception 'anon can see % sweep citation edges', n; end if;
  raise notice 'sweep-01-verify: anon sees zero sweep rows';
end
$anon$;
commit;
reset role;

-- ---------------------------------------------------------------------------
-- Summary (informational)
-- ---------------------------------------------------------------------------
select 'entities' as what, count(*)::text as n from core.entity where slug ~ '^res-0[0-9][0-9]-'
union all
select 'propositions', count(*)::text from core.proposition where created_by = 'sweep-01-ingest'
union all
select 'observations (all V0)', count(*)::text
  from core.observation o join core.proposition p using (proposition_id)
 where p.created_by = 'sweep-01-ingest'
union all
select 'grade ' || pr.grade, count(*)::text
  from core.proposition_rollup pr join core.proposition p using (proposition_id)
 where p.created_by = 'sweep-01-ingest' group by pr.grade
union all
select 'grade events', count(*)::text
  from core.grade_event ge join core.proposition p using (proposition_id)
 where p.created_by = 'sweep-01-ingest'
union all
select 'parked (clamp/X-SCI defect)', count(*)::text
  from ingest.regrade_queue q join core.proposition p using (proposition_id)
 where p.created_by = 'sweep-01-ingest'
union all
select 'Schneider pool components (must be 1)', count(distinct component_root)::text
  from core.lineage_components(array['a4fad54b-b6ba-50b8-a79a-cf6f343acba4', 'f6a59ba8-c4d7-5a6c-b5c3-8a42d42a1dc8', '606c2e9b-a70a-53b0-b110-e0df99392d4f', '8dbd2775-cbb8-59a4-8126-eff80c42bf31', '8daaad09-970f-589e-b100-b80312c7bf82', '351daaba-ff00-5669-8b52-fb9765f93e8e', '6cefca91-206d-5d6f-9bf2-6891b2025449', 'be8bb770-a4c1-54a0-9653-b798f3e93f56', 'bc561ef9-2cbd-5b49-83ff-2704cc0b871a', 'cbfff9f9-dec5-507c-a7cd-03f90d126039']::uuid[])
order by 1;
