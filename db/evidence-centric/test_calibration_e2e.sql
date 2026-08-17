-- END-TO-END: publish, query, and verify anon cannot see adjudication state.
begin;

insert into core.entity (entity_id, slug, entity_level, canonical_name, country_code,
                         publication_state, published_at)
values ('22222222-2222-2222-2222-222222222222','greenbrier','site','The Greenbrier / Project Greek Island','US',
        'PUBLISHED', now());
insert into core.entity_alias (entity_id, alias_kind, alias_text, added_by)
values ('22222222-2222-2222-2222-222222222222','facility-name','Project Greek Island','RESOLVER');
insert into core.publication_log (entity_id, event) values ('22222222-2222-2222-2222-222222222222','FIRST-PUBLISH');

insert into core.geometry_assertion (entity_id, precision, point_geom, derivation, asserted_by, is_preferred)
values ('22222222-2222-2222-2222-222222222222','surveyed',
        st_setsrid(st_makepoint(-80.2998,37.7876),4326),'control-point-match','CARTOGRAPHER',true);

insert into core.proposition (proposition_id, entity_id, class, statement_text, null_code, created_by,
                              reference_class, function_set, publication_state, published_at, predicate_args)
values ('bbbbbbbb-0000-0000-0000-000000000001','22222222-2222-2222-2222-222222222222','EXIST',
        'A substantial artificial subsurface structure exists beneath the West Virginia Wing','A01','PROPOSER',
        'RC5','n/a','PUBLISHED', now(), '{}'::jsonb),
       ('bbbbbbbb-0000-0000-0000-000000000002','22222222-2222-2222-2222-222222222222','FUNCTION',
        'The structure served congressional relocation (COG) 1962-1992','A11','PROPOSER',
        'RC5','sensitive','PUBLISHED', now(), '{"function":"COG-COOP"}'::jsonb),
       ('bbbbbbbb-0000-0000-0000-000000000003','22222222-2222-2222-2222-222222222222','LOCATE',
        'The structure is at 37.7876,-80.2998 within 200 m','A01','PROPOSER',
        'RC5','n/a','PUBLISHED', now(), '{"radius_m":200}'::jsonb);

insert into core.alternative_disposition (proposition_id, null_code, is_selected, disposition, reasoning, assessed_by)
values ('bbbbbbbb-0000-0000-0000-000000000001','A01',true,'excluded-by-evidence','County construction record and utility filing place a structure.','REFUTER'),
       ('bbbbbbbb-0000-0000-0000-000000000002','A11',true,'selected-strongest','Cover story (Forsythe Associates) is the strongest surviving alternative pre-1992.','REFUTER'),
       ('bbbbbbbb-0000-0000-0000-000000000003','A01',true,'excluded-by-evidence','Parcel record.','REFUTER');

-- 1991 evidence: county construction record + contemporaneous local press.
insert into core.source_document (document_id, corpus_id, causal_provenance, channel, origin_tier,
                                  title, issuing_body, document_date, identifier, identifier_class)
values ('dddddddd-1991-0000-0000-000000000001',
        (select corpus_id from registry.corpus where slug='chronam'),
        'UNSOLICITED','ORIGIN-HOST','T1','Greenbrier County deed and construction record',
        'Greenbrier County Recorder', date '1959-06-01','GB-1959-0417','COUNTY_PARCEL'),
       ('dddddddd-1991-0000-0000-000000000002',
        (select corpus_id from registry.corpus where slug='chronam'),
        'UNSOLICITED','ORIGIN-HOST','T1','Local press: large excavation at the resort',
        'Greenbrier Valley newspaper', date '1959-08-14', null, null);

insert into core.retrieval_receipt (receipt_id, document_id, requested_url, http_status, receipt_state,
    grammar_pass, resolved_at_issuer, sha256_of_bytes, issuer_metadata_match)
values ('cccccccc-1991-0000-0000-000000000001','dddddddd-1991-0000-0000-000000000001',
        'https://recorder.example/GB-1959-0417',200,'VERIFIED',true,true,'\xaa',true),
       ('cccccccc-1991-0000-0000-000000000002','dddddddd-1991-0000-0000-000000000002',
        'https://www.loc.gov/item/sn12345/1959-08-14/ed-1/seq-1/',200,'VERIFIED',true,true,'\xbb',true);

insert into core.observation (observation_id, proposition_id, document_id, receipt_id, statement,
    sign, magnitude, diagnosticity_source, scope, property_locus, subject_binding_pass, fact_key,
    gate_a_tier,gate_b_receipt,gate_c_instance,gate_d_on_its_face,gate_e_authority,gate_f_unsolicited,
    asserted_by, publication_state)
values ('00000000-1991-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001',
        'dddddddd-1991-0000-0000-000000000001','cccccccc-1991-0000-0000-000000000001',
        'Recorded deed recites a subsurface structure on the parcel','SUPPORTS',4,'GATE',
        'INSTANCE','CLAIM-PROPERTY',true,'greenbrier-structure-exists',
        true,true,true,true,true,true,'ASSESSOR','PUBLISHED'),
       ('00000000-1991-0000-0000-000000000002','bbbbbbbb-0000-0000-0000-000000000001',
        'dddddddd-1991-0000-0000-000000000002','cccccccc-1991-0000-0000-000000000002',
        'Contemporaneous local press describes a large excavation','SUPPORTS',3,'GATE',
        'INSTANCE','CLAIM-PROPERTY',true,'greenbrier-excavation-press',
        true,true,true,true,false,true,'ASSESSOR','PUBLISHED'),
       -- FUNCTION carried only by attributes of the PLACE: CAP-2b must bite.
       ('00000000-1991-0000-0000-000000000003','bbbbbbbb-0000-0000-0000-000000000002',
        'dddddddd-1991-0000-0000-000000000002','cccccccc-1991-0000-0000-000000000002',
        'Anomalous power and comms plant for a resort','SUPPORTS',2,'GATE',
        'INSTANCE','PLACE-PROPERTY',true,'greenbrier-anomalous-plant',
        true,true,true,false,false,true,'ASSESSOR','PUBLISHED'),
       ('00000000-1991-0000-0000-000000000004','bbbbbbbb-0000-0000-0000-000000000003',
        'dddddddd-1991-0000-0000-000000000001','cccccccc-1991-0000-0000-000000000001',
        'Parcel record fixes the location','SUPPORTS',4,'GATE',
        'INSTANCE','CLAIM-PROPERTY',true,'greenbrier-parcel',
        true,true,true,true,true,true,'ASSESSOR','PUBLISHED');

-- receipted canonical searches so negative verdicts are licensed
do $$
declare pid uuid; sl uuid; ep record;
begin
  foreach pid in array array['bbbbbbbb-0000-0000-0000-000000000001',
                             'bbbbbbbb-0000-0000-0000-000000000002',
                             'bbbbbbbb-0000-0000-0000-000000000003']::uuid[]
  loop
    insert into core.search_log (proposition_id, opened_by) values (pid,'SILENCE') returning search_log_id into sl;
    for ep in select css.erp_profile_id from registry.canonical_search_set css
               join core.proposition p on p.proposition_id = pid
              where css.proposition_class = p.class
    loop
      insert into core.search_receipt (search_log_id, proposition_id, erp_profile_id, query_string,
                                       executed_by, result_count, outcome)
      values (sl, pid, ep.erp_profile_id, 'canonical sweep 1991', 'SILENCE', 0, 'NEGATIVE');
    end loop;
  end loop;
end $$;

select core.record_grade('bbbbbbbb-0000-0000-0000-000000000001','INITIAL','scorer-family-a-v1','BES-0.2.0',true);
select core.record_grade('bbbbbbbb-0000-0000-0000-000000000002','INITIAL','scorer-family-a-v1','BES-0.2.0',true);
select core.record_grade('bbbbbbbb-0000-0000-0000-000000000003','INITIAL','scorer-family-a-v1','BES-0.2.0',true);

\echo '=== A. THE HOLE IS CERTAIN, THE FUNCTION IS NOT — three badges, one site'
select p.class, cg.grade, ge.limiting_condition, ge.applied_caps,
       ge.place_derived_weight as place_bar, ge.claim_derived_weight as claim_bar
  from core.proposition p
  join core.proposition_current_grade cg using (proposition_id)
  join core.grade_event ge on ge.grade_event_id = cg.grade_event_id
 where p.entity_id='22222222-2222-2222-2222-222222222222' order by p.class;

\echo '=== B. NEW DISCLOSURE (Gup, WaPo, 31 May 1992) moves FUNCTION, cause recorded'
insert into core.source_document (document_id, corpus_id, causal_provenance, channel, origin_tier,
                                  title, issuing_body, document_date)
values ('dddddddd-1992-0000-0000-000000000001',
        (select corpus_id from registry.corpus where slug='wapo-gup-1992'),
        'UNSOLICITED','ORIGIN-HOST','T2','The Ultimate Congressional Hideaway',
        'The Washington Post', date '1992-05-31');
insert into core.retrieval_receipt (receipt_id, document_id, requested_url, http_status, receipt_state,
    grammar_pass, resolved_at_issuer, sha256_of_bytes, issuer_metadata_match)
values ('cccccccc-1992-0000-0000-000000000001','dddddddd-1992-0000-0000-000000000001',
        'https://www.washingtonpost.com/archive/politics/1992/05/30/',200,'VERIFIED',true,true,'\xcc',true);
insert into core.observation (proposition_id, document_id, receipt_id, statement, sign, magnitude,
    diagnosticity_source, scope, property_locus, subject_binding_pass, fact_key,
    gate_a_tier,gate_b_receipt,gate_c_instance,gate_d_on_its_face,gate_e_authority,gate_f_unsolicited,
    asserted_by, publication_state)
values ('bbbbbbbb-0000-0000-0000-000000000002','dddddddd-1992-0000-0000-000000000001',
        'cccccccc-1992-0000-0000-000000000001',
        'Named the facility, its location and its congressional relocation function','SUPPORTS',4,'GATE',
        'INSTANCE','CLAIM-PROPERTY',true,'greenbrier-cog-function',
        true,true,true,true,true,true,'ASSESSOR','PUBLISHED');
select core.record_grade('bbbbbbbb-0000-0000-0000-000000000002','NEW-DISCLOSURE','scorer-family-a-v1','BES-0.2.0',true);

select seq, grade, previous_grade, direction, transition_cause,
       suppress_from_public_chart, disclosure_annotation, observations_added
  from core.grade_history('bbbbbbbb-0000-0000-0000-000000000002');

\echo '=== C. CANDIDATE DETAIL — one round trip'
select jsonb_pretty(jsonb_build_object(
  'entity',        api.candidate_detail('greenbrier')->'entity'->>'name',
  'n_propositions',jsonb_array_length(api.candidate_detail('greenbrier')->'propositions'),
  'n_evidence',    jsonb_array_length(api.candidate_detail('greenbrier')->'evidence'),
  'geometry',      api.candidate_detail('greenbrier')->'geometry'->>'representation',
  'badges',        (select jsonb_agg(x->>'class' || '=' || (x->>'grade'))
                      from jsonb_array_elements(api.candidate_detail('greenbrier')->'propositions') x)));

\echo '=== D. GRADE AS OF a past instant (regime-change reconstruction)'
select api.grade_as_of('bbbbbbbb-0000-0000-0000-000000000002', now() - interval '1 second')->>'grade' as before_disclosure;

\echo '=== E. MAP: refresh and viewport'
refresh materialized view api.map_feature;
refresh materialized view api.map_cluster;
select jsonb_pretty(api.map_viewport(-81,37,-79,38,12));
select octet_length(api.map_tile(12,1141,1571)) as mvt_bytes;

\echo '=== F. RLS: what anon can and cannot see'
set local role anon;
select 'entities visible to anon' as check, count(*) from core.entity;
select 'published grade events visible' as check, count(*) from core.grade_event;
select 'ingest.agent_run readable?' as check, count(*) from ingest.agent_run;
reset role;

rollback;
