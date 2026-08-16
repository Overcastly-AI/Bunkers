-- =====================================================================
-- BUNKERS REGISTER — calibration harness (§12.7 CI regression suite)
-- Exercises the load-bearing PAIRS. Run with: psql -f 010_calibration_test.sql
-- =====================================================================
begin;

create or replace function t_lineage(l text) returns uuid language plpgsql as $$
declare id uuid;
begin insert into lineage(label) values (l) returning lineage_id into id; return id; end $$;

create or replace function t_doc(
  p_title text, p_tier origin_tier, p_lineage uuid,
  p_self_attesting boolean default false,
  p_channel channel_kind default 'ORIGIN_HOST',
  p_date date default date '1990-01-01')
returns uuid language plpgsql as $$
declare id uuid;
begin
  insert into document(title, origin_tier, lineage_id, self_attesting, channel,
                       document_date, corpus_era)
  values (p_title,p_tier,p_lineage,p_self_attesting,p_channel,p_date,'PRE_2022')
  returning document_id into id; return id;
end $$;

create or replace function t_verified_ev(
  p_prop uuid, p_doc uuid, p_sign evidence_sign, p_diag int,
  p_locus property_locus, p_factkey text,
  p_gate boolean default false, p_null_excl boolean default false,
  p_catalog uuid default null)
returns uuid language plpgsql as $$
declare rid uuid; eid uuid; al uuid; pent uuid;
begin
  insert into retrieval(document_id, requested_url, http_status,
                        sha256_of_bytes, retrieved_at)
  values (p_doc,'https://issuer.example/doc',200,
          repeat('a',64), now()) returning retrieval_id into rid;
  select entity_id into pent from proposition where proposition_id=p_prop;
  select alias_id into al from entity_alias where entity_id=pent limit 1;
  insert into evidence(
    proposition_id, document_id, receipt_state, retrieval_id, quoted_span,
    span_start_offset, span_end_offset, quote_check,
    subject_binding_span, subject_binding_alias_id, subject_binding_pass,
    sign, scope, property_locus, diagnosticity, fact_key,
    gate_a_tier_t1_t2, gate_b_receipt_verified, gate_c_scope_instance,
    gate_d_states_on_face, gate_e_authority_over_fact, gate_f_unsolicited_unchallenged,
    null_excluding, diagnosticity_catalog_id, ea_expected_under_h, ea_expected_under_alt)
  values (
    p_prop, p_doc, 'VERIFIED', rid, 'quoted text', 0, 11, true,
    'FACILITY NAME', al, true,
    p_sign,'INSTANCE',p_locus,p_diag::smallint,p_factkey,
    p_gate,p_gate,p_gate,p_gate,p_gate,p_gate,
    p_null_excl, p_catalog,
    case when p_diag>=2 then 3 else 2 end,
    case when p_null_excl then 0 else 3 end)
  returning evidence_id into eid;
  -- the trigger recomputes null_excluding from the E/A ordinals; force it
  update evidence set null_excluding = p_null_excl where evidence_id = eid;
  return eid;
end $$;

-- A signed UNDERCUTS row with a full receipt, optionally carrying REFUTER's
-- proposed refutation class and the E0-under-H marker that R2 requires.
create or replace function t_undercut_ev(
  p_prop uuid, p_doc uuid, p_diag int, p_locus property_locus, p_factkey text,
  p_refclass refutation_class default null,
  p_authority boolean default false,
  p_e_under_h int default 0, p_a_under_alt int default 3,
  p_documents_null boolean default false,
  p_from_search uuid default null)
returns uuid language plpgsql as $$
declare rid uuid; eid uuid; al uuid; pent uuid;
begin
  insert into retrieval(document_id, requested_url, http_status, sha256_of_bytes)
  values (p_doc,'https://issuer.example/neg',200,repeat('b',64)) returning retrieval_id into rid;
  select entity_id into pent from proposition where proposition_id=p_prop;
  select alias_id into al from entity_alias where entity_id=pent limit 1;
  insert into evidence(
    proposition_id, document_id, receipt_state, retrieval_id, quoted_span,
    span_start_offset, span_end_offset, quote_check, subject_binding_span,
    subject_binding_alias_id, subject_binding_pass, sign, scope, property_locus,
    diagnosticity, fact_key, refutation_class, gate_e_authority_over_fact,
    ea_expected_under_h, ea_expected_under_alt, documents_null,
    derived_from_search_receipt_id)
  values (p_prop, p_doc, 'VERIFIED', rid, 'quoted negation', 0, 15, true,
          'FACILITY NAME', al, true, 'UNDERCUTS','INSTANCE',p_locus,
          p_diag::smallint, p_factkey, p_refclass, p_authority,
          p_e_under_h::smallint, p_a_under_alt::smallint, p_documents_null,
          p_from_search)
  returning evidence_id into eid;
  return eid;
end $$;

create or replace function t_entity(p_slug text, p_name text, p_prec location_precision default 'surveyed')
returns uuid language plpgsql as $$
declare id uuid;
begin
  insert into entity(slug, display_name, country, location_precision, point_geom,
                     extent_geom, typology_code, reference_class)
  values (p_slug,p_name,'US',p_prec,
          case when p_prec in ('surveyed','approximate')
               then st_setsrid(st_point(-104.848,38.744),4326) end,
          case when p_prec <> 'non_located'
               then st_buffer(st_setsrid(st_point(-104.848,38.744),4326)::geometry,0.01) end,
          'buried-rural','RC1')
  returning entity_id into id;
  insert into entity_alias(entity_id, alias, alias_kind) values (id, p_name, 'name');
  return id;
end $$;

create or replace function t_prop(p_ent uuid, p_class proposition_class, p_null text,
                                  p_key text default 'default', p_fnset text default 'na')
returns uuid language plpgsql as $$
declare id uuid;
begin
  insert into proposition(entity_id, class, predicate_key, statement,
                          null_hypothesis_code, typology_code, reference_class,
                          base_rate_table_version, predicate_args)
  values (p_ent,p_class,p_key,p_class::text||' assertion',p_null,'buried-rural','RC1',
          'BR-0.2.0', jsonb_build_object('function_set',p_fnset))
  returning proposition_id into id;
  return id;
end $$;

-- =====================================================================
\echo '--- CASE B2: Site CARDINAL (canary). V = empty -> CAP-5 -> F'
-- =====================================================================
select t_entity('site-cardinal','Site CARDINAL') as e \gset
select t_prop(:'e','EXIST','A01') as p \gset
-- five format-valid but unresolvable identifiers, retained and inert (V0)
insert into evidence(proposition_id, document_id, receipt_state, sign, scope,
                     property_locus, diagnosticity, fact_key, subject_binding_pass)
select :'p', t_doc('confabulated CREST cite '||g,'T1',t_lineage('canary'||g)),
       'UNRESOLVED','SUPPORTS','CLASS','CLAIM_PROPERTY',0,'fk'||g,false
from generate_series(1,5) g;
select bes_apply_grade(:'p','INITIAL','test') as grade;

-- =====================================================================
\echo '--- Documentary sufficiency: ONE gate-passing D4 row -> A'
\echo '    (historian fatal #6; DECIBAN returns B, TIERED/BES return A)'
-- =====================================================================
select t_entity('raven-rock','Raven Rock Mountain Complex') as e2 \gset
select t_prop(:'e2','EXIST','A01') as p2 \gset
select t_verified_ev(:'p2', t_doc('MILCON line item naming it','T1',t_lineage('milcon')),
                     'SUPPORTS',4,'CLAIM_PROPERTY','rr_milcon', true, true) as ev;
select bes_apply_grade(:'p2','INITIAL','test') as grade;

-- =====================================================================
\echo '--- CASE H10: "The Montauk Project". Self-attestation -> V empty -> F'
\echo '    (TIERED as submitted returned R; BES §2.5 returns F)'
-- =====================================================================
select t_entity('camp-hero','Camp Hero AFS') as e3 \gset
select t_prop(:'e3','EXIST','A01') as p3e \gset
select t_verified_ev(:'p3e', t_doc('NARA unit records','T1',t_lineage('nara-ch')),
                     'SUPPORTS',4,'CLAIM_PROPERTY','ch_nara', true, true);
select bes_apply_grade(:'p3e','INITIAL','test');

select t_prop(:'e3','FUNCTION','A11','montauk_project','sensitive') as p3f \gset
-- Nichols 1992: the book is real, the bytes resolve, the span quotes. It is
-- excluded from V because the author IS the claimant and the content IS the
-- claim (§2.5) — not because the receipt failed.
select t_verified_ev(:'p3f', t_doc('Nichols & Moon 1992','T5',t_lineage('nichols'),true),
                     'SUPPORTS',0,'CLAIM_PROPERTY','nichols');
select bes_apply_grade(:'p3f','INITIAL','test') as grade;

-- =====================================================================
\echo '--- CASE H12: DUCC. PROGRAM A (clamp-exempt) / EXIST R'
-- =====================================================================
select t_entity('ducc','Deep Underground Command Center','non_located') as e4 \gset
select t_prop(:'e4','EXIST','A01') as p4e \gset
select t_prop(:'e4','PROGRAM','A01','ducc_program') as p4p \gset
-- FRUS/JCS memoranda: the program is documented at D4.
select t_verified_ev(:'p4p', t_doc('FRUS 1964-68 vol X, JCS memoranda','T1',t_lineage('frus')),
                     'SUPPORTS',4,'CLAIM_PROPERTY','ducc_frus', true, true);
-- The FY1965 appropriations record documents NON-CONSTRUCTION: R3.
-- Congress has AUTHORITY OVER THE FACT of its own appropriation (§3.4e).
select t_undercut_ev(:'p4e', t_doc('FY1965 appropriations record','T1',t_lineage('approps')),
                     3,'CLAIM_PROPERTY','ducc_approps','R3_CONTRADICTED', true);
select bes_apply_grade(:'p4e','INITIAL','test') as exist_grade;
select bes_apply_grade(:'p4p','INITIAL','test') as program_grade;

-- =====================================================================
\echo '--- CASE H4/H4b: Greenbrier 1991. EXIST B, FUNCTION(COG) E via CAP-2b'
-- =====================================================================
select t_entity('greenbrier','The Greenbrier / Project Greek Island') as e5 \gset
select t_prop(:'e5','EXIST','A01') as p5e \gset
-- Three verified CLAIM-property lineages at D2, one rooted at T1 (BES §14.3
-- item 3): county construction record, contemporaneous local press, utility
-- filing. B1's SECOND clause — L(D2)>=3 with a T1/T2 root — not A1.
select t_verified_ev(:'p5e', t_doc('county construction record','T1',t_lineage('gb-county')),
                     'SUPPORTS',2,'CLAIM_PROPERTY','gb_construction', false, true);
select t_verified_ev(:'p5e', t_doc('contemporaneous local press','T3',t_lineage('gb-press')),
                     'SUPPORTS',2,'CLAIM_PROPERTY','gb_press', false, true);
select t_verified_ev(:'p5e', t_doc('utility filing','T1',t_lineage('gb-utility')),
                     'SUPPORTS',2,'CLAIM_PROPERTY','gb_utility', false, true);
select bes_apply_grade(:'p5e','INITIAL','test') as exist_grade_1991;

-- 31 May 1992: Ted Gup, Washington Post. ZERO change to any physical fact.
-- The transition cause is NEW_DISCLOSURE and the chart must say so: "the
-- publication record changed; the world did not" (§11.2, historian #14).
select t_verified_ev(:'p5e', t_doc('Gup, Washington Post, 31 May 1992','T2',
                                   t_lineage('gup'), false, 'ORIGIN_HOST', date '1992-05-31'),
                     'SUPPORTS',4,'CLAIM_PROPERTY','gb_gup', true, true);
select bes_apply_grade(:'p5e','NEW_DISCLOSURE','test',
                       'Gup disclosure; no physical fact changed') as exist_grade_1992;

select t_prop(:'e5','FUNCTION','A11','cog','sensitive') as p5f \gset
-- Everything available in 1991 is a property of the PLACE, not the CLAIM.
select t_verified_ev(:'p5f', t_doc('anomalous power draw','T1',t_lineage('gb-power')),
                     'SUPPORTS',2,'PLACE_PROPERTY','gb_power', false, false);
select t_verified_ev(:'p5f', t_doc('worker lore, unresolvable','T5',t_lineage('gb-lore')),
                     'SUPPORTS',0,'PLACE_PROPERTY','gb_lore', false, false);
insert into proposition_erp(proposition_id, erp_profile_id, applicable, resolved_x, searched)
select :'p5f', erp_profile_id, true, x, true from erp_profile
where version='ERP-0.2.0' and code in ('ANY_ACTIVE_COMMERCIAL_COVER','MILCON_CLASSIFIED_SCOPE','NIP_MIP_CONSTRUCTION');
select bes_apply_grade(:'p5f','INITIAL','test') as function_grade;

-- =====================================================================
\echo '--- CASE H8: SubTropolis as hardened. R2 (affirmative inconsistency)'
-- =====================================================================
select t_entity('subtropolis','SubTropolis, Kansas City') as e6 \gset
select t_prop(:'e6','HARDEN','A02','hardened') as p6 \gset
-- Universal-D0 place signals: adits, substation, rail spur. Zero conditions.
select t_verified_ev(:'p6', t_doc('adit/portal imagery','T2',t_lineage('st-imagery')),
                     'SUPPORTS',0,'PLACE_PROPERTY','st_portal', false, false);
select t_verified_ev(:'p6', t_doc('rail spur record','T1',t_lineage('st-rail')),
                     'SUPPORTS',0,'PLACE_PROPERTY','st_rail', false, false);
-- The null (A02) is itself affirmatively documented by a verified T1 record:
-- this is what makes null_state DOMINANT, which R2 requires.
select t_undercut_ev(:'p6', t_doc('MSHA regulated-mine permit','T1',t_lineage('st-msha')),
                     1,'PLACE_PROPERTY','st_msha', null, false, 1, 3, true);
-- Two independent UNDERCUTS lineages at D2+ whose content is E0 under H:
-- a published tenant lease list and operator-run public ticketed tours.
select t_undercut_ev(:'p6', t_doc('published tenant lease list','T1',t_lineage('st-leases')),
                     3,'CLAIM_PROPERTY','st_leases','R2_AFFIRMATIVELY_INCONSISTENT');
select t_undercut_ev(:'p6', t_doc('operator-run public ticketed tours','T1',t_lineage('st-tours')),
                     3,'CLAIM_PROPERTY','st_tours','R2_AFFIRMATIVELY_INCONSISTENT');
select bes_apply_grade(:'p6','INITIAL','test') as harden_grade;

-- =====================================================================
\echo '--- CASE I2: Sauder 129 DUMBs. Deep negative stack alone must NOT'
\echo '    license R (§8.4). DECIBAN returned R; BES returns F.'
-- =====================================================================
select t_entity('dumb-129','129 Deep Underground Military Bases','non_located') as e7 \gset
select t_prop(:'e7','EXIST','A11','dumb_network') as p7 \gset
select t_verified_ev(:'p7', t_doc('Sauder, self-published','T5',t_lineage('sauder'),true),
                     'SUPPORTS',0,'CLAIM_PROPERTY','sauder');
-- Two X3 expected-record negatives. Receipted, signed, and by themselves inert
-- as to refutation: R requires at least one AFFIRMATIVE row.
with sr as (
  insert into search_receipt(proposition_id, erp_profile_id, query_string, corpus,
                             executed_by, result_count, outcome)
  select :'p7', erp_profile_id, 'DUMB network construction', code, 'SILENCE', 0, 'NEGATIVE'
  from erp_profile where version='ERP-0.2.0' and code in ('PROCUREMENT_50M','SPOIL_VOLUME_IMAGERY')
  returning search_receipt_id, erp_profile_id)
insert into evidence(proposition_id, derived_from_search_receipt_id, receipt_state,
                     sign, scope, property_locus, diagnosticity, fact_key,
                     ea_expected_under_h, ea_expected_under_alt, subject_binding_pass)
select :'p7', sr.search_receipt_id, 'NEGATIVE','UNDERCUTS','CLASS','CLAIM_PROPERTY',
       3, 'erp_'||sr.erp_profile_id, 0, 3, false from sr;
insert into proposition_erp(proposition_id, erp_profile_id, applicable, resolved_x, searched)
select :'p7', erp_profile_id, true, x, true from erp_profile
where version='ERP-0.2.0' and code in ('PROCUREMENT_50M','SPOIL_VOLUME_IMAGERY');
select bes_apply_grade(:'p7','INITIAL','test') as dumb_grade;

-- =====================================================================
\echo '--- CASE H14: Mount Weather. Site EXIST A; "underground city" FEATURE E'
\echo '    with a citogenesis flag, on the same page. Cycle in the graph.'
-- =====================================================================
select t_entity('mount-weather','Mount Weather Emergency Operations Center') as e8 \gset
select t_prop(:'e8','EXIST','A01') as p8e \gset
select t_verified_ev(:'p8e', t_doc('NTSB report, TWA 514, 1 Dec 1974','T1',t_lineage('ntsb')),
                     'SUPPORTS',4,'CLAIM_PROPERTY','mw_ntsb', true, true);
select bes_apply_grade(:'p8e','INITIAL','test') as exist_grade;

select t_prop(:'e8','FEATURE','A11','underground_city') as p8f \gset
-- Pollock 1976 is a JOURNALIST reporting others' attestation, not the
-- claimant: it enters V, but at D0 (§2.5 corollary).
select t_doc('Pollock, The Progressive, March 1976','T3',t_lineage('pollock')) as d_pollock \gset
select t_doc('unnamed off-the-record former officials','T5',t_lineage('pollock')) as d_anon \gset
select t_doc('2010s aggregator citing Pollock as primary','T4',t_lineage('aggregator')) as d_agg \gset
select t_verified_ev(:'p8f', :'d_pollock', 'SUPPORTS',0,'CLAIM_PROPERTY','mw_city');
-- The citogenesis loop, WITH A CYCLE: Pollock -> anon testimony -> aggregator
-- -> Pollock. Recursive traversal must terminate.
insert into citation(citing_document_id, cited_document_id, edge_kind, detected_by) values
 (:'d_pollock', :'d_anon', 'ATTRIBUTES_TESTIMONY','manual'),
 (:'d_agg',     :'d_pollock','CITES','explicit_reference'),
 (:'d_anon',    :'d_agg',   'CITES','manual');            -- closes the cycle
select bes_apply_grade(:'p8f','INITIAL','test') as feature_grade;

-- LOCATE stays low: the "underground lake" has no coordinate anyone can
-- resolve. The map must render a REGION, never a point (§10.3).
select t_entity('relocation-arc-site','Unidentified Federal Relocation Arc site','regional') as e9 \gset
select t_prop(:'e9','EXIST','A01') as p9e \gset
select t_prop(:'e9','LOCATE','A01') as p9l \gset
select t_verified_ev(:'p9e', t_doc('OEP declassified program record','T1',t_lineage('oep')),
                     'SUPPORTS',2,'CLAIM_PROPERTY','arc_oep', false, true);
select t_verified_ev(:'p9e', t_doc('GSA disposal record','T1',t_lineage('arc-gsa')),
                     'SUPPORTS',2,'CLAIM_PROPERTY','arc_gsa', false, true);
select bes_apply_grade(:'p9e','INITIAL','test');
select bes_apply_grade(:'p9l','INITIAL','test') as locate_grade;

-- =====================================================================
\echo '--- CYCLE-SAFE ORIGIN TRACE over the citogenesis loop'
-- =====================================================================
with recursive trace as (
  select c.citing_document_id as root, c.cited_document_id as node,
         1 as depth, array[c.citing_document_id, c.cited_document_id] as path
  from citation c where c.citing_document_id = :'d_agg'
  union all
  select t.root, c.cited_document_id, t.depth + 1, t.path || c.cited_document_id
  from trace t join citation c on c.citing_document_id = t.node
  where t.depth < 20
) cycle node set is_cycle using cycle_path
select d.title, t.depth, d.origin_tier, t.is_cycle
from trace t join document d on d.document_id = t.node order by t.depth;

-- =====================================================================
\echo '--- GRADE HISTORY RECONSTRUCTION (req. 4)'
-- =====================================================================
select 'greenbrier EXIST, as of 1991' as label,
       bes_grade_as_of(:'p5e', (select occurred_at from grade_event
                                where proposition_id=:'p5e' and cause='INITIAL')) as grade
union all
select 'greenbrier EXIST, now',
       bes_grade_as_of(:'p5e', now());

select ge.grade_from, ge.grade_to, ge.cause, ge.is_instrument_drift, ge.narrative,
       ge.snapshot->'inputs'->>'l_d2' as l_d2_at_time
from grade_event ge where ge.proposition_id = :'p5e' order by ge.seq;

-- =====================================================================
\echo '--- RESULTS'
-- =====================================================================
select e.slug, pr.class, p.predicate_key, pr.grade, pr.awarded_band,
       pr.refutation_state, pr.null_state, pr.caps_applied,
       pr.limiting_condition, pr.at_ceiling, pr.ceiling,
       pr.v_total, pr.v_claim, pr.l_d2, pr.l_d3, pr.sci
from proposition_rollup pr
join proposition p using (proposition_id)
join entity e on e.entity_id = pr.entity_id
order by e.slug, pr.class;

\echo '--- ENTITY ROLLUP / RENDER GATE (§10.3)'
select e.slug, er.exist_grade, er.locate_grade, er.render_mode,
       er.location_precision, st_geometrytype(er.render_geom) as render_geom_type,
       er.proposition_count, er.refuted_count
from entity_rollup er join entity e using (entity_id) order by e.slug;

\echo '--- GRADE EVENTS (req. 4)'
select e.slug, p.class, ge.grade_from, ge.grade_to, ge.cause, ge.is_instrument_drift
from grade_event ge join proposition p using (proposition_id)
join entity e on e.entity_id=p.entity_id order by ge.seq;

-- =====================================================================
\echo '--- APP QUERY SMOKE TESTS (publish, then read as anon would)'
-- =====================================================================
select ops_publish_entity(entity_id,'test-curator') from entity;
insert into document_claim(document_id, claim_key, claim_text, first_observed_date, is_published)
values (:'d_pollock','mw_underground_city','streets, sidewalks, a small lake, its own transit system', date '1976-03-01', true),
       (:'d_anon','mw_underground_city','unnamed former officials', date '1976-01-01', true),
       (:'d_agg','mw_underground_city','repeated as established fact', date '2014-06-01', true);

\echo '>> Q1 map_viewport, zoom 12 (features)'
select jsonb_pretty(jsonb_build_object(
  'mode', v->'mode',
  'n', jsonb_array_length(v->'features'),
  'render_modes', (select jsonb_agg(distinct f->'properties'->'render_mode')
                   from jsonb_array_elements(v->'features') f),
  'any_point_geom_for_low_locate', (select bool_or(
       (f->'properties'->>'render_mode') = 'point'
       and (f->'properties'->>'locate_grade') < 'C')
     from jsonb_array_elements(v->'features') f)))
from (select map_viewport(-180,-85,180,85,12) as v) t;

\echo '>> Q1 map_viewport, zoom 4 (server-side clusters)'
select jsonb_pretty(map_viewport(-180,-85,180,85,4));

\echo '>> Q2 candidate_detail (Mount Weather: A on the site, E on the claim)'
select jsonb_pretty(jsonb_build_object(
  'entity', d->'entity'->>'name',
  'render_mode', d->'entity'->>'render_mode',
  'propositions', (select jsonb_agg(jsonb_build_object(
      'class', p->>'class', 'grade', p->>'grade',
      'ceiling', p->>'ceiling', 'at_ceiling', p->'at_ceiling',
      'citogenesis', p->'citogenesis',
      'null', p->'null_hypothesis',
      'silence_prose', p->>'silence_prose',
      'two_bars', p->'two_bars',
      'evidence_rows', jsonb_array_length(p->'evidence')))
    from jsonb_array_elements(d->'propositions') p)))
from (select candidate_detail('mount-weather') as d) t;

\echo '>> Q3 origin_trace over the cyclic citogenesis loop'
select jsonb_pretty(jsonb_build_object(
  'origin', o->'origin'->>'title',
  'origin_tier', o->'origin'->>'origin_tier',
  'cycles_detected', o->'cycles_detected',
  'depth_capped', o->'depth_capped',
  'citogenesis_loops', o->'citogenesis_loops',
  'node_count', jsonb_array_length(o->'nodes')))
from (select origin_trace('mw_underground_city') as o) t;

\echo '>> Q3b independent_lineages (graph property, not COUNT(*))'
select jsonb_pretty(independent_lineages(:'p5e', 2));

\echo '>> Q4 grade_history (Greenbrier: B -> A, cause NEW_DISCLOSURE)'
select jsonb_pretty(jsonb_build_object(
  'current', h->'current',
  'events', (select jsonb_agg(jsonb_build_object(
      'seq', ev->'seq', 'from', ev->'from', 'to', ev->'to',
      'cause', ev->>'cause', 'annotation', ev->>'annotation',
      'moved_by', (select jsonb_agg(m->>'document') from jsonb_array_elements(ev->'moved_by') m),
      'l_d2_at_time', ev->'counts_at_time'->'l_d2'))
    from jsonb_array_elements(h->'events') ev)))
from (select grade_history(:'p5e') as h) t;

\echo '>> Q5 claims_register (E/F/R retained, with origin work attached)'
select slug, class, grade, refutation_state, citogenesis from claims_register order by slug, class;

\echo '>> RLS: what anon actually sees (published only)'
set local role anon;
select 'entity' as t, count(*) from entity
union all select 'proposition', count(*) from proposition
union all select 'evidence', count(*) from evidence
union all select 'grade_event', count(*) from grade_event
union all select 'document', count(*) from document;

\echo '>> RLS: adjudication state must be UNREACHABLE, not merely empty'
do $$
begin
  begin
    perform count(*) from ops_regrade_queue;
    raise exception 'LEAK: anon read ops_regrade_queue';
  exception when insufficient_privilege then
    raise notice 'OK: ops_regrade_queue denied to anon';
  end;
  begin
    perform count(*) from ops.agent_run;
    raise exception 'LEAK: anon read ops.agent_run';
  exception when insufficient_privilege then
    raise notice 'OK: ops.agent_run denied to anon';
  end;
end $$;

\echo '>> RLS: an UNPUBLISHED candidate must be invisible'
reset role;
select t_entity('unpublished-candidate','Unpublished candidate') as e10 \gset
select t_prop(:'e10','EXIST','A01') as p10 \gset
select t_verified_ev(:'p10', t_doc('secret adjudication doc','T1',t_lineage('unpub')),
                     'SUPPORTS',4,'CLAIM_PROPERTY','unpub', true, true);
select bes_apply_grade(:'p10','INITIAL','test');
set local role anon;
select count(*) as unpublished_entities_visible_to_anon
  from entity where slug = 'unpublished-candidate';
select count(*) as unpublished_evidence_visible_to_anon
  from evidence where fact_key = 'unpub';
reset role;

rollback;
