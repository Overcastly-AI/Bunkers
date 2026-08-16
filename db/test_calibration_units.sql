-- CALIBRATION SMOKE TEST — CI fixture, not part of the schema.
begin;

create or replace function t_prop(p_slug text, p_class core.proposition_class, p_null char(3))
returns uuid language plpgsql as $$
declare eid uuid; pid uuid;
begin
  select entity_id into eid from core.entity where slug = p_slug;
  insert into core.proposition (entity_id, class, statement_text, null_code, created_by,
                                predicate_args)
  values (eid, p_class, p_slug||' :: '||p_class, p_null, 'PROPOSER',
          case p_class when 'PROGRAM' then '{"program":"DUCC","program_state":"cancelled"}'::jsonb
                       when 'FUNCTION' then '{"function":"COG-COOP"}'::jsonb
                       else '{}'::jsonb end)
  returning proposition_id into pid;
  insert into core.alternative_disposition (proposition_id, null_code, is_selected, disposition,
                                            reasoning, assessed_by)
  values (pid, p_null, true, 'selected-strongest', 'REFUTER selection', 'REFUTER');
  return pid;
end $$;

-- fill the SCI denominator with receipted searches so negative verdicts are licensed
create or replace function t_search(p_pid uuid) returns void language plpgsql as $$
declare sl uuid; ep record;
begin
  insert into core.search_log (proposition_id, opened_by) values (p_pid,'SILENCE') returning search_log_id into sl;
  for ep in select css.erp_profile_id from registry.canonical_search_set css
             join core.proposition p on p.proposition_id = p_pid
            where css.proposition_class = p.class
  loop
    insert into core.search_receipt (search_log_id, proposition_id, erp_profile_id, query_string,
                                     executed_by, result_count, outcome)
    values (sl, p_pid, ep.erp_profile_id, 'canonical sweep', 'SILENCE', 0, 'NEGATIVE');
  end loop;
end $$;

insert into core.entity (slug, entity_level, canonical_name, country_code, is_canary) values
 ('site-cardinal','site','Site CARDINAL','US',true),
 ('ducc','program','Deep Underground Command Center','US',false),
 ('subtropolis','site','SubTropolis','US',false),
 ('camp-hero','site','Camp Hero / Montauk AFS','US',false);

-- =====================================================================
-- 1. THE HALLUCINATION CANARY — fabricated name, zero corpus presence.
-- =====================================================================
select t_prop('site-cardinal','EXIST','A01') as canary_exist \gset
select t_search(:'canary_exist');

insert into core.source_document (document_id, causal_provenance, channel, origin_tier,
                                  identifier, identifier_class)
values ('dddddddd-0000-0000-0000-000000000001','UNSOLICITED','ORIGIN-HOST','T1',
        'CIA-RDP79B00752A000300010001-2','CREST_ESDN');
insert into core.retrieval_receipt (receipt_id, document_id, requested_url, http_status,
                                    receipt_state, grammar_pass, failure_reason)
values ('cccccccc-0000-0000-0000-000000000001','dddddddd-0000-0000-0000-000000000001',
        'https://www.cia.gov/readingroom/document/x', 404,'UNRESOLVED',true,
        'format-valid, unresolvable: confabulation');
-- The agent asserts all six gate conditions; the RECEIPT refutes it.
insert into core.observation (proposition_id, document_id, receipt_id, statement, sign, magnitude,
    diagnosticity_source, scope, property_locus, subject_binding_pass,
    gate_a_tier,gate_b_receipt,gate_c_instance,gate_d_on_its_face,gate_e_authority,gate_f_unsolicited,
    asserted_by)
values (:'canary_exist','dddddddd-0000-0000-0000-000000000001','cccccccc-0000-0000-0000-000000000001',
        'Alleged CREST record naming Site CARDINAL','SUPPORTS',4,'GATE','INSTANCE','CLAIM-PROPERTY',
        true,true,true,true,true,true,true,'ARCHIVIST');

-- =====================================================================
-- 2. DUCC — PROGRAM A, EXIST R. The clamp exemption is what makes this
--    representable at all.
-- =====================================================================
select t_prop('ducc','PROGRAM','A11') as ducc_program \gset
select t_prop('ducc','EXIST','A01')   as ducc_exist   \gset
select t_search(:'ducc_program'); select t_search(:'ducc_exist');

insert into core.entity_alias (entity_id, alias_kind, alias_text, added_by)
select entity_id,'facility-name','Deep Underground Command Center','RESOLVER'
  from core.entity where slug='ducc';

insert into core.source_document (document_id, causal_provenance, channel, origin_tier, title,
                                  document_date, issuing_body, identifier, identifier_class)
values ('dddddddd-0000-0000-0000-000000000010','UNSOLICITED','ORIGIN-HOST','T1',
        'JCS memorandum on DUCC, FRUS 1964-68 vol X','1964-03-01','Joint Chiefs of Staff',
        'frus1964-68v10d1','FRUS_DOC'),
       ('dddddddd-0000-0000-0000-000000000011','UNSOLICITED','ORIGIN-HOST','T1',
        'FY1965 appropriations record: funds declined','1964-08-01','US Congress',
        'CDOC-1964-0001','GOVINFO_PKG');
insert into core.retrieval_receipt (receipt_id, document_id, requested_url, http_status, receipt_state,
    grammar_pass, resolved_at_issuer, sha256_of_bytes, issuer_metadata_match)
values ('cccccccc-0000-0000-0000-000000000010','dddddddd-0000-0000-0000-000000000010',
        'https://history.state.gov/historicaldocuments/frus1964-68v10d1',200,'VERIFIED',true,true,'\x01',true),
       ('cccccccc-0000-0000-0000-000000000011','dddddddd-0000-0000-0000-000000000011',
        'https://api.govinfo.gov/packages/CDOC-1964-0001/summary',200,'VERIFIED',true,true,'\x02',true);

insert into core.observation (proposition_id, document_id, receipt_id, statement, sign, magnitude,
    diagnosticity_source, scope, property_locus, subject_binding_pass, fact_key,
    gate_a_tier,gate_b_receipt,gate_c_instance,gate_d_on_its_face,gate_e_authority,gate_f_unsolicited,
    asserted_by)
values (:'ducc_program','dddddddd-0000-0000-0000-000000000010','cccccccc-0000-0000-0000-000000000010',
        'JCS memoranda establish the programme was proposed and costed','SUPPORTS',4,'GATE',
        'INSTANCE','CLAIM-PROPERTY',true,'ducc-proposed',true,true,true,true,true,true,'ASSESSOR'),
       (:'ducc_program','dddddddd-0000-0000-0000-000000000011','cccccccc-0000-0000-0000-000000000011',
        'FY1965 appropriations record documents the refusal to fund','SUPPORTS',4,'GATE',
        'INSTANCE','CLAIM-PROPERTY',true,'ducc-cancelled',true,true,true,true,true,true,'ASSESSOR'),
       -- and the SAME record is an affirmative UNDERCUT of physical existence
       (:'ducc_exist','dddddddd-0000-0000-0000-000000000011','cccccccc-0000-0000-0000-000000000011',
        'Congress declined to appropriate; nothing was ever dug','UNDERCUTS',4,'GATE',
        'INSTANCE','CLAIM-PROPERTY',true,'ducc-never-built',true,true,true,true,true,true,'REFUTER');

update core.alternative_disposition set disposition='documented-dominant',
  excluding_observation_ids = array(select observation_id from core.observation
                                     where proposition_id = :'ducc_exist')
 where proposition_id = :'ducc_exist';

insert into core.refutation (proposition_id, state, basis_observation_ids, authority_document_id,
                             narrative, asserted_by)
select :'ducc_exist','R3', array(select observation_id from core.observation
                                  where proposition_id = :'ducc_exist' and sign='UNDERCUTS'),
       'dddddddd-0000-0000-0000-000000000011',
       'The appropriations record documents non-funding and non-construction. R3: a party with authority over the fact documents cancellation.',
       'REFUTER';

-- =====================================================================
-- 3. CITATION GRAPH WITH A DELIBERATE CYCLE — the traversal must terminate.
-- =====================================================================
insert into core.source_document (document_id, causal_provenance, channel, origin_tier, title) values
 ('eeeeeeee-0000-0000-0000-000000000001','SELF-PUBLISHED','AGGREGATOR','T5','Origin: 1990s self-published book'),
 ('eeeeeeee-0000-0000-0000-000000000002','UNSOLICITED','ORIGIN-HOST','T3','T3 magazine feature resting on unnamed sources'),
 ('eeeeeeee-0000-0000-0000-000000000003','SELF-PUBLISHED','AGGREGATOR','T5','Aggregator citing the T3 feature as primary');
insert into core.document_citation (citing_document_id, cited_document_id, edge_kind, detection_method, asserted_by) values
 ('eeeeeeee-0000-0000-0000-000000000002','eeeeeeee-0000-0000-0000-000000000001','explicit-citation','explicit-reference','LINEAGE'),
 ('eeeeeeee-0000-0000-0000-000000000003','eeeeeeee-0000-0000-0000-000000000002','explicit-citation','explicit-reference','LINEAGE'),
 -- the loop closes: the origin book's later edition cites the aggregator
 ('eeeeeeee-0000-0000-0000-000000000001','eeeeeeee-0000-0000-0000-000000000003','explicit-citation','explicit-reference','LINEAGE');

\echo '--- 1. CANARY: expect F (CAP-5), zero V rows, five gates claimed and none verified'
select core.evaluate_proposition(:'canary_exist')->>'grade' as grade,
       core.evaluate_proposition(:'canary_exist')->>'applied_caps' as caps,
       core.evaluate_proposition(:'canary_exist')->>'v_count' as v_count,
       core.evaluate_proposition(:'canary_exist')->>'v0_count' as v0_count,
       core.evaluate_proposition(:'canary_exist')->>'sci' as sci;

\echo '--- 2. DUCC PROGRAM: expect A. DUCC EXIST: expect R (R3).'
select 'PROGRAM' as p, core.evaluate_proposition(:'ducc_program')->>'grade' as grade
union all
select 'EXIST',  core.evaluate_proposition(:'ducc_exist')->>'grade';

\echo '--- 2b. clamp exemption: PROGRAM is exempt, so EXIST R does not drag it'
select class, clamp_exempt from core.proposition where entity_id=(select entity_id from core.entity where slug='ducc');

\echo '--- 3. CYCLIC CITATION GRAPH: traversal terminates and marks the cycle'
select depth, left(title,42) as title, origin_tier, is_cycle, is_terminus, array_length(path,1) as path_len
  from core.trace_origin('eeeeeeee-0000-0000-0000-000000000003', 24);

\echo '--- 4. lineage collapse: three documents, one cycle -> ONE component'
select count(distinct component_root) as components
  from core.lineage_components(array['eeeeeeee-0000-0000-0000-000000000001',
                                     'eeeeeeee-0000-0000-0000-000000000002',
                                     'eeeeeeee-0000-0000-0000-000000000003']::uuid[]);

\echo '--- 5. independent lineages on DUCC PROGRAM (two facts, two lineages)'
select lineage_key, lineage_kind, best_magnitude from core.independent_lineages(:'ducc_program', 2::smallint);

\echo '--- 6. membership generation: V / U / V0 with reasons'
select membership, left(coalesce(exclusion_reason,'-'),58) as reason, count(*)
  from core.observation group by 1,2 order by 1;

rollback;
