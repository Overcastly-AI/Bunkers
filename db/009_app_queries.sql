-- =====================================================================
-- BUNKERS REGISTER — PART 9: the queries the app actually runs.
-- All SECURITY INVOKER, so RLS applies and anon sees only published rows.
-- =====================================================================

-- =====================================================================
-- Q1. MAP VIEWPORT FETCH (req. 10)
--     Server-side clustering below a zoom threshold; individual features
--     above it. The uncertainty geometry is what is returned — a client
--     CANNOT draw a pin the evidence does not support, because render_mode
--     is computed server-side and a 'region' feature carries no point.
-- =====================================================================

create or replace function map_viewport(
  p_west double precision, p_south double precision,
  p_east double precision, p_north double precision,
  p_zoom int,
  p_min_exist_grade grade_band default 'D',
  p_typologies text[] default null,
  p_countries text[] default null)
returns jsonb
language sql stable security invoker
set search_path = public
as $$
with bbox as (
  select st_makeenvelope(p_west, p_south, p_east, p_north, 4326) as g
),
hits as (
  select er.*
  from entity_rollup er, bbox
  where er.is_published
    and er.anchor_geom && bbox.g
    and er.render_mode <> 'list_only'
    and er.exist_grade >= p_min_exist_grade
    and (p_typologies is null or er.typology_code = any(p_typologies))
    and (p_countries  is null or er.country = any(p_countries))
),
-- Below zoom 9 the register clusters. Grid-snapping in 4326 is used rather
-- than ST_ClusterKMeans because it is index-friendly, deterministic across
-- pans, and stable under incremental ingest (a new candidate cannot reshuffle
-- every existing cluster id). Cell size halves per zoom level.
clustered as (
  select st_snaptogrid(anchor_geom, 360.0 / power(2, greatest(p_zoom,1) + 3)) as cell,
         count(*) as n,
         max(exist_grade) as best_grade,
         count(*) filter (where exist_grade >= 'B') as strong_n,
         count(*) filter (where exist_grade = 'R') as refuted_n,
         st_centroid(st_collect(anchor_geom)) as cell_centroid
  from hits group by 1
)
select case when p_zoom < 9 then
  jsonb_build_object(
    'mode','clusters',
    'zoom', p_zoom,
    'features', coalesce((select jsonb_agg(jsonb_build_object(
        'type','Feature',
        'geometry', st_asgeojson(cell_centroid)::jsonb,
        'properties', jsonb_build_object(
          'cluster', true, 'count', n, 'best_grade', best_grade,
          'strong_count', strong_n, 'refuted_count', refuted_n)))
      from clustered), '[]'::jsonb))
else
  jsonb_build_object(
    'mode','features',
    'zoom', p_zoom,
    'features', coalesce((select jsonb_agg(jsonb_build_object(
        'type','Feature',
        -- REGION features carry a polygon and no point. There is no code path
        -- that emits a coordinate for a candidate graded below LOCATE C.
        'geometry', st_asgeojson(h.render_geom)::jsonb,
        'properties', jsonb_build_object(
          'entity_id', h.entity_id, 'name', h.headline,
          'render_mode', h.render_mode,
          'location_precision', h.location_precision,
          'uncertainty_radius_m', h.uncertainty_radius_m,
          'exist_grade', h.exist_grade, 'locate_grade', h.locate_grade,
          'best_grade', h.best_grade, 'worst_grade', h.worst_grade,
          'typology', h.typology_code,
          'proposition_count', h.proposition_count,
          'refuted_count', h.refuted_count,
          'badges', h.badges)))
      from hits h), '[]'::jsonb))
end;
$$;

-- Vector-tile variant for MapLibre at scale. Same gates, MVT bytes.
create or replace function map_tile(p_z int, p_x int, p_y int)
returns bytea
language sql stable security invoker
set search_path = public
as $$
with env as (select st_tileenvelope(p_z, p_x, p_y) as g),
mvt as (
  select er.entity_id, er.headline, er.exist_grade::text as exist_grade,
         er.locate_grade::text as locate_grade, er.render_mode::text as render_mode,
         er.location_precision::text as location_precision, er.typology_code,
         st_asmvtgeom(st_transform(er.render_geom, 3857), env.g, 4096, 64, true) as geom
  from entity_rollup er, env
  where er.is_published and er.render_mode <> 'list_only'
    and st_transform(er.render_geom, 3857) && env.g
)
select st_asmvt(mvt.*, 'candidates', 4096, 'geom') from mvt where geom is not null;
$$;

-- =====================================================================
-- Q2. CANDIDATE DETAIL — full proposition breakdown with citations.
--     "The composite does not exist; the decomposition is the product."
-- =====================================================================

create or replace function candidate_detail(p_slug text)
returns jsonb
language sql stable security invoker
set search_path = public
as $$
with e as (select * from entity where slug = p_slug and is_published),
props as (
  select pr.*, p.statement, p.predicate_key, p.predicate_args, p.as_of_date,
         p.null_hypothesis_code, nh.label as null_label,
         p.parent_proposition_id, p.clamp_exempt
  from proposition_rollup pr
  join proposition p using (proposition_id)
  left join null_hypothesis nh on nh.code = p.null_hypothesis_code
  where pr.entity_id = (select entity_id from e) and pr.is_published
),
ev as (
  select ev.proposition_id,
         jsonb_agg(jsonb_build_object(
           'evidence_id', ev.evidence_id,
           'sign', ev.sign,
           'diagnosticity', ev.diagnosticity,
           'signed_diagnosticity', ev.signed_diagnosticity,
           'scope', ev.scope,
           'property_locus', ev.property_locus,
           'origin_tier', ev.origin_tier,
           'channel', ev.channel,
           'causal_provenance', ev.causal_provenance,
           'corpus_era', ev.corpus_era,
           -- V0 rows are RETAINED AND DISPLAYED, marked inert (§2.2).
           'receipt_state', ev.receipt_state,
           'inert', (ev.receipt_state <> 'VERIFIED'
                     or ev.self_attesting or ev.register_echo_quarantined
                     or ev.scope <> 'INSTANCE'),
           'self_attesting', ev.self_attesting,
           'quarantined', ev.register_echo_quarantined,
           'gate_pass', ev.gate_pass,
           'gate_conditions', jsonb_build_object(
              'a_tier', ev.gate_a_tier_t1_t2, 'b_receipt', ev.gate_b_receipt_verified,
              'c_instance', ev.gate_c_scope_instance, 'd_on_face', ev.gate_d_states_on_face,
              'e_authority', ev.gate_e_authority_over_fact,
              'f_unsolicited', ev.gate_f_unsolicited_unchallenged),
           'fact_key', ev.fact_key,
           'lineage_id', ev.lineage_id,
           'ea', case when ev.ea_expected_under_h is not null
                      then jsonb_build_object('E', ev.ea_expected_under_h,
                                              'A', ev.ea_expected_under_alt) end,
           'refutation_class', ev.refutation_class,
           'rebutted', ev.rebutted,
           'document', jsonb_build_object(
              'document_id', d.document_id, 'title', d.title, 'author', d.author,
              'issuing_authority', d.issuing_authority, 'date', d.document_date,
              'identifier', d.identifier, 'identifier_class', d.identifier_class,
              'origin_tier', d.origin_tier, 'source', s.name, 'source_url', s.url),
           -- the receipt, in full: this is the citation the reader checks
           'receipt', jsonb_build_object(
              'resolved_url', r.resolved_url, 'http_status', r.http_status,
              'sha256', r.sha256_of_bytes, 'retrieved_at', r.retrieved_at,
              'mirror_only', r.mirror_only,
              'quoted_span', ev.quoted_span,
              'span', jsonb_build_array(ev.span_start_offset, ev.span_end_offset),
              'subject_binding_span', ev.subject_binding_span,
              'subject_binding_pass', ev.subject_binding_pass))
           order by ev.sign, ev.diagnosticity desc) as rows
  from evidence ev
  left join document d on d.document_id = ev.document_id
  left join source   s on s.source_id   = d.source_id
  left join retrieval r on r.retrieval_id = ev.retrieval_id
  where ev.proposition_id in (select proposition_id from props) and ev.is_published
  group by ev.proposition_id
),
silence as (
  select sr.proposition_id,
         jsonb_agg(jsonb_build_object(
           'query', sr.query_string, 'corpus', sr.corpus,
           'corpus_version', sr.corpus_version, 'executed_at', sr.executed_at,
           'result_count', sr.result_count, 'outcome', sr.outcome,
           'expected_record', ep.label, 'x_level', ep.x,
           'x0_reason', ep.x0_reason, 'destroying_event', ep.destroying_event)
           order by sr.executed_at) as rows
  from search_receipt sr
  left join erp_profile ep on ep.erp_profile_id = sr.erp_profile_id
  where sr.proposition_id in (select proposition_id from props) and sr.is_published
  group by sr.proposition_id
)
select jsonb_build_object(
  'entity', jsonb_build_object(
     'entity_id', e.entity_id, 'slug', e.slug, 'name', e.display_name,
     'entity_level', e.entity_level, 'country', e.country,
     'typology', e.typology_code, 'reference_class', e.reference_class,
     'location_precision', e.location_precision,
     'uncertainty_radius_m', e.uncertainty_radius_m,
     'geometry', st_asgeojson(er.render_geom)::jsonb,
     'render_mode', er.render_mode,
     'aliases', (select jsonb_agg(a.alias order by a.alias)
                 from entity_alias a where a.entity_id = e.entity_id),
     'distinct_from', (select jsonb_agg(jsonb_build_object('entity_id', x.entity_id,
                          'name', x.display_name, 'note', rel.note))
                       from entity_relation rel join entity x on x.entity_id = rel.to_entity_id
                       where rel.from_entity_id = e.entity_id and rel.kind='DISTINCT_FROM')),
  -- THE PROPOSITION TABLE leads the page (§10.1). N badges, never one.
  'propositions', (select jsonb_agg(jsonb_build_object(
      'proposition_id', pp.proposition_id, 'class', pp.class,
      'statement', pp.statement, 'as_of_date', pp.as_of_date,
      'grade', pp.grade, 'grade_pre_clamp', pp.grade_pre_clamp,
      'awarded_band', pp.awarded_band,
      'ceiling', pp.ceiling, 'at_ceiling', pp.at_ceiling,
      'ceiling_reason', pp.ceiling_reason,
      'limiting_condition', pp.limiting_condition,
      'marginal', pp.marginal_flag,
      'caps_applied', pp.caps_applied,
      'refutation_state', pp.refutation_state,
      'null_hypothesis', jsonb_build_object('code', pp.null_hypothesis_code,
                                            'label', pp.null_label,
                                            'state', pp.null_state),
      'silence_reading', pp.silence_reading,
      'silence_prose', case pp.silence_reading
         when 'UNINFORMATIVE' then
           'No public record of this class would be expected for a facility of '
           'this type in this period under this authority. The absence is not '
           'evidence against.'
         when 'RECORD_DESTROYED' then
           'The record class that would have carried this evidence no longer exists.'
         when 'UNSEARCHED' then 'Not yet searched.'
         else 'Searched; negative receipts logged.' end,
      'base_rate_reading', pp.base_rate_reading,
      'reference_class', pp.reference_class,
      'sci', pp.sci, 'sci_numerator', pp.sci_numerator,
      'sci_denominator', pp.sci_denominator,
      'citogenesis', pp.citogenesis,
      -- §10.2 TWO BARS, ALWAYS: how much of the grade is the mountain.
      'two_bars', jsonb_build_object('place_derived', pp.place_derived_count,
                                     'claim_derived', pp.claim_derived_count),
      'counts', jsonb_build_object('v_total', pp.v_total, 'v_claim', pp.v_claim,
                 'l_d2', pp.l_d2, 'l_d3', pp.l_d3,
                 'undercuts_d3_unrebutted', pp.u_d3_unrebutted,
                 'v0_unresolved', pp.v0_unresolved, 'quarantined', pp.quarantined),
      'evidence', coalesce(ev.rows, '[]'::jsonb),
      'search_receipts', coalesce(silence.rows, '[]'::jsonb),
      'versions', jsonb_build_object('rubric', pp.rubric_version,
                    'tier', pp.tier_table_version,
                    'diagnosticity', pp.diagnosticity_table_version,
                    'erp', pp.erp_table_version))
      order by array_position(
        array['EXIST','LOCATE','EXTENT','TYPOLOGY','HARDEN','CONTROL','FUNCTION',
              'STATUS','FEATURE','PROGRAM','IDENTITY','ORIGIN']::text[], pp.class::text))
    from props pp
    left join ev using (proposition_id)
    left join silence using (proposition_id)),
  'provenance_beacon', jsonb_build_object(
     'rubric','BES v0.2','generated_at', now(),
     'note','Every grade is a statement about the record, not about the world.')
)
from e
left join entity_rollup er on er.entity_id = e.entity_id;
$$;

-- =====================================================================
-- Q3. LINEAGE / ORIGIN TRACE (req. 5, 6)
--     Recursive over a CYCLIC graph. Termination is guaranteed twice over:
--     the SQL:2023 CYCLE clause, and a hard depth cap.
-- =====================================================================

create or replace function origin_trace(
  p_claim_key text, p_max_depth int default 25)
returns jsonb
language sql stable security invoker
set search_path = public
as $$
with recursive seeds as (
  select dc.document_id from document_claim dc
  where dc.claim_key = p_claim_key and dc.is_published
),
walk as (
  select s.document_id as root, s.document_id as node, 0 as depth,
         array[s.document_id] as path, null::citation_edge_kind as via
  from seeds s
  union all
  select w.root, c.cited_document_id, w.depth + 1,
         w.path || c.cited_document_id, c.edge_kind
  from walk w
  join citation c on c.citing_document_id = w.node
  where w.depth < p_max_depth
    and c.is_published
) cycle node set is_cycle using cycle_path
select jsonb_build_object(
  'claim_key', p_claim_key,
  -- The ORIGIN: the earliest-dated node with no outbound citation, i.e. a
  -- graph terminus.
  'origin', (select jsonb_build_object(
       'document_id', d.document_id, 'title', d.title, 'author', d.author,
       'date', d.document_date, 'first_observed', d.first_observed_date,
       'wayback_first_capture', d.wayback_first_capture,
       'origin_tier', d.origin_tier, 'self_attesting', d.self_attesting,
       'method','graph_terminus')
     from walk w join document d on d.document_id = w.node
     where not w.is_cycle
       and not exists (select 1 from citation c2
                       where c2.citing_document_id = w.node and c2.is_published)
     order by coalesce(d.document_date, d.first_observed_date) nulls last, w.depth desc
     limit 1),
  -- If EVERY path cycles there is no graph terminus. The register does not
  -- invent one: it falls back to first-observation dating, labels the method,
  -- and says the trace is inconclusive. A closed citation loop with no dated
  -- entry point is itself a finding about the claim.
  'origin_by_dating', (select jsonb_build_object(
       'document_id', d.document_id, 'title', d.title,
       'date', d.document_date, 'first_observed', d.first_observed_date,
       'origin_tier', d.origin_tier, 'method','earliest_first_observation',
       'caveat','no acyclic terminus exists; this is a dating inference, not a graph fact')
     from walk w join document d on d.document_id = w.node
     order by coalesce(d.first_observed_date, d.document_date,
                       d.wayback_first_capture) nulls last
     limit 1),
  'cycles_detected', (select count(*) from walk where is_cycle) > 0,
  'cycle_paths', coalesce((select jsonb_agg(distinct w.path) from walk w where w.is_cycle),'[]'::jsonb),
  'depth_capped', (select max(depth) from walk) >= p_max_depth,
  -- CITOGENESIS: a T1/T2/T3 publication resting on unattributable T5
  -- testimony, subsequently cited as though primary. The whole loop is ONE
  -- lineage and the laundered proposition is capped at E (§5.3).
  'citogenesis_loops', coalesce((select jsonb_agg(jsonb_build_object(
       'laundering_document', dl.title, 'laundering_tier', dl.origin_tier,
       'underlying_document', du.title, 'underlying_tier', du.origin_tier,
       'edge', c.edge_kind))
     from citation c
     join document dl on dl.document_id = c.citing_document_id
     join document du on du.document_id = c.cited_document_id
     where dl.origin_tier in ('T1','T2','T3') and du.origin_tier = 'T5'
       and dl.document_id in (select node from walk)),'[]'::jsonb),
  'nodes', (select jsonb_agg(jsonb_build_object(
       'document_id', d.document_id, 'title', d.title, 'depth', w.depth,
       'origin_tier', d.origin_tier, 'lineage_id', d.lineage_id,
       'via', w.via, 'is_cycle', w.is_cycle, 'path_length', array_length(w.path,1))
     order by w.depth)
     from walk w join document d on d.document_id = w.node));
$$;

-- INDEPENDENT LINEAGE COUNT (req. 6): a graph property, not a COUNT(*).
-- Same document set can be 1 lineage or 9; the answer is the number of
-- distinct causal clusters surviving deduplication, fact-key merge, the
-- model-family collapse, and the compiler-transparency pass-through.
create or replace function independent_lineages(p_prop uuid, p_min_diag int default 2)
returns jsonb
language sql stable security invoker
set search_path = public
as $$
select jsonb_build_object(
  'proposition_id', p_prop,
  'min_diagnosticity', p_min_diag,
  'document_count', count(*),
  'lineage_count', count(distinct v.lineage_id),
  -- The delta between these two numbers IS the register's whole point:
  -- "a claim on 400 websites is not 400 sources; it is one source and
  --  399 copies, and the register must say so."
  'copies_collapsed', count(*) - count(distinct v.lineage_id),
  'lineages', (select jsonb_agg(jsonb_build_object(
      'lineage_id', l.lineage_id, 'label', l.label, 'kind', l.kind,
      'model_family', l.model_family,
      'terminus', (select d.title from document d where d.document_id = l.terminus_document_id),
      'documents_in_lineage', (select count(*) from v_evidence_merged v2
                               where v2.proposition_id = p_prop and v2.lineage_id = l.lineage_id),
      'quarantined', l.is_quarantined))
    from lineage l where l.lineage_id in (select distinct lineage_id from v_evidence_merged
                                          where proposition_id = p_prop
                                            and sign='SUPPORTS'
                                            and diagnosticity >= p_min_diag)))
from v_evidence_merged v
where v.proposition_id = p_prop and v.sign = 'SUPPORTS' and v.diagnosticity >= p_min_diag;
$$;

-- =====================================================================
-- Q4. GRADE HISTORY RECONSTRUCTION (req. 4)
--     What the grade was, what moved it, and whether the world changed or
--     only the publication record did.
-- =====================================================================

create or replace function grade_history(p_prop uuid, p_include_drift boolean default false)
returns jsonb
language sql stable security invoker
set search_path = public
as $$
select jsonb_build_object(
  'proposition_id', p_prop,
  'current', (select grade from proposition_rollup where proposition_id = p_prop),
  'events', coalesce((select jsonb_agg(jsonb_build_object(
      'seq', ge.seq, 'at', ge.occurred_at,
      'from', ge.grade_from, 'to', ge.grade_to,
      'cause', ge.cause,
      -- §11.2: NEW_DISCLOSURE renders visually distinct from NEW_VERIFICATION.
      'annotation', case ge.cause
         when 'NEW_DISCLOSURE' then 'the publication record changed; the world did not'
         when 'STATUS_CHANGE'  then 'the world changed'
         when 'REFUTATION'     then 'affirmative disconfirmation landed'
         when 'CANDIDATE_SET_CHANGE' then 'the denominator moved; adding candidates dilutes'
         else null end,
      'is_instrument_drift', ge.is_instrument_drift,
      'narrative', ge.narrative,
      'moved_by', coalesce((select jsonb_agg(jsonb_build_object(
                     'evidence_id', e2.evidence_id, 'sign', e2.sign,
                     'diagnosticity', e2.diagnosticity,
                     'document', d2.title, 'tier', d2.origin_tier))
                   from evidence e2 left join document d2 on d2.document_id = e2.document_id
                   where e2.evidence_id = any(ge.triggering_evidence_ids) and e2.is_published),
                   '[]'::jsonb),
      'counts_at_time', ge.snapshot->'inputs',
      'versions', jsonb_build_object('rubric', ge.rubric_version,
                    'tier', ge.tier_table_version,
                    'diagnosticity', ge.diagnosticity_table_version,
                    'erp', ge.erp_table_version))
      order by ge.seq)
    from grade_event ge
    where ge.proposition_id = p_prop and ge.is_published
      -- §11.2: instrument drift is SUPPRESSED from the public confidence
      -- chart by default. The chart shows evidence events, not instrument
      -- drift. It remains retrievable, because hiding it entirely would be
      -- the same sin one level up.
      and (p_include_drift or not ge.is_instrument_drift)), '[]'::jsonb));
$$;

-- =====================================================================
-- Q5. THE CLAIMS REGISTER — E, F and R entries with their origin work.
--     "Nothing below band D renders as a map pin; E, F and R live in the
--      claims register with their origin work, which is the product."
-- =====================================================================

create or replace view claims_register as
select e.slug, e.display_name, pr.class, p.statement, pr.grade,
       pr.refutation_state, pr.citogenesis, pr.limiting_condition,
       pr.base_rate_reading, pr.silence_reading,
       (select jsonb_agg(jsonb_build_object('class', pr2.class, 'grade', pr2.grade))
        from proposition_rollup pr2
        where pr2.entity_id = e.entity_id and pr2.class = 'ORIGIN' and pr2.is_published)
         as origin_propositions
from proposition_rollup pr
join proposition p using (proposition_id)
join entity e on e.entity_id = pr.entity_id
where pr.is_published and pr.grade in ('E','F','R');

grant select on claims_register to anon, authenticated;

grant execute on function map_viewport(double precision,double precision,
  double precision,double precision,int,grade_band,text[],text[]) to anon, authenticated;
grant execute on function map_tile(int,int,int) to anon, authenticated;
grant execute on function candidate_detail(text) to anon, authenticated;
grant execute on function origin_trace(text,int) to anon, authenticated;
grant execute on function independent_lineages(uuid,int) to anon, authenticated;
grant execute on function grade_history(uuid,boolean) to anon, authenticated;
grant execute on function bes_grade_as_of(uuid,timestamptz) to anon, authenticated;
grant execute on function bes_entity_as_of(uuid,timestamptz) to anon, authenticated;

-- Grading functions are service-role only: a public caller must never be
-- able to trigger a rescore, and RLS-filtered inputs would produce a WRONG
-- grade rather than an error, which is far worse.
revoke execute on function bes_recompute_proposition(uuid) from public, anon, authenticated;
revoke execute on function bes_apply_grade(uuid,transition_cause,text,text) from public, anon, authenticated;
revoke execute on function bes_drain_regrade_queue(int) from public, anon, authenticated;
revoke execute on function bes_recompute_entity(uuid) from public, anon, authenticated;
