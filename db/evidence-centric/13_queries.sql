-- =====================================================================
-- SECTION 13 — THE QUERIES THE APP ACTUALLY RUNS
--
-- Four of them are packaged as SECURITY INVOKER functions so the Next.js
-- app makes ONE round trip per page and RLS still governs every row. The
-- raw SQL each one wraps is written out underneath, because a register
-- whose own queries are opaque has no standing to demand transparency of
-- anyone else.
-- =====================================================================

-- ---------------------------------------------------------------------
-- QUERY 1 — MAP VIEWPORT.
-- api.map_viewport(w,s,e,n,zoom,...) and api.map_tile(z,x,y) in section 10.
-- The underlying shape, for reference:
--
--   select entity_id, slug, canonical_name, exist_grade, representation,
--          locate_precision, st_asgeojson(geom)
--     from api.map_feature
--    where geom && st_makeenvelope($1,$2,$3,$4,4326)
--      and exist_rank >= core.grade_rank('D')
--    limit 2000;
--
-- Index path: map_feature_gix (GiST on geom) then the rank filter. At z<=9
-- the query is served entirely from api.map_cluster, so a continental
-- viewport returns a few hundred pre-aggregated rows rather than the
-- register. Both objects are refreshed CONCURRENTLY by the ingest cron.
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- QUERY 2 — CANDIDATE DETAIL.
-- The entry page leads with the PROPOSITION TABLE, then the
-- alternative-hypothesis disposition table, then the lineage graph, then
-- the evidence rows with receipts — including V0 and quarantined rows
-- shown as inert. The composite does not exist; the decomposition IS the
-- product (BES §10.1).
-- ---------------------------------------------------------------------
create or replace function api.candidate_detail(p_slug text)
returns jsonb
language sql stable security invoker as $$
  with ent as (
    select * from core.entity where slug = p_slug
  ),
  props as (
    select b.* from api.proposition_badge b join ent on ent.entity_id = b.entity_id
  )
  select jsonb_build_object(
    'entity', (select jsonb_build_object(
        'entity_id', e.entity_id, 'slug', e.slug, 'name', e.canonical_name,
        'entity_level', e.entity_level, 'country', e.country_code,
        'typology', e.typology_cached,
        'first_ingested_at', e.first_ingested_at,
        'note', 'A site is a container. It carries identity and geometry and nothing graded.')
      from ent e),

    -- N badges, never one.
    'propositions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'proposition_id', p.proposition_id,
        'class', p.class,
        'statement', p.statement_text,
        'as_of', p.as_of_date,
        'grade', p.grade,
        'awarded_band', p.awarded_band,
        'applied_caps', p.applied_caps,
        'ceiling', p.ceiling, 'at_ceiling', p.at_ceiling,
        'limiting_condition', p.limiting_condition,
        'marginal', p.marginal_flag,
        'silence_reading', p.silence_reading,
        'silence_prose', case p.silence_reading
          when 'UNINFORMATIVE' then 'No public record of this class would be expected for a facility of this type in this period under this authority. The absence is not evidence against.'
          when 'RECORD-DESTROYED' then 'The record class that would have carried this evidence no longer exists.'
          when 'UNSEARCHED' then 'The canonical corpora have not been searched. This is not a low grade; it is the absence of one.'
          else 'The expected record was searched for and not found, and its presence would have been expected.' end,
        'base_rate_reading', p.base_rate_reading,
        'reference_class', p.reference_class,
        'null_code', p.null_code, 'null_label', p.null_label, 'null_state', p.null_state,
        'refutation_state', p.refutation_state,
        'citogenesis', p.citogenesis_flag,
        'lineages_d2', p.l_d2, 'lineages_d3', p.l_d3,
        'v_count', p.v_count, 'u_count', p.u_count, 'v0_count', p.v0_count,
        'sci', p.sci, 'sci_numerator', p.sci_numerator, 'sci_denominator', p.sci_denominator,
        -- TWO BARS, ALWAYS: how much of this grade is the mountain?
        'bars', jsonb_build_object('place_derived', p.place_derived_weight,
                                   'claim_derived', p.claim_derived_weight),
        'conditions', p.condition_results,
        'versions', jsonb_build_object('rubric', p.rubric_version, 'scorer', p.scorer_model_id,
                                       'tier', p.tier_version_id,
                                       'diagnosticity', p.diagnosticity_version_id,
                                       'erp', p.erp_version_id),
        'graded_at', p.graded_at)
        order by array_position(
          array['EXIST','LOCATE','EXTENT','TYPOLOGY','CONTROL','HARDEN','FUNCTION',
                'FEATURE','STATUS','PROGRAM','IDENTITY','ORIGIN']::text[], p.class::text))
      from props p), '[]'::jsonb),

    -- The alternative-hypothesis disposition table.
    'alternatives', coalesce((
      select jsonb_agg(jsonb_build_object(
        'proposition_id', a.proposition_id, 'null_code', a.null_code,
        'label', a.label, 'selected', a.is_selected,
        'disposition', a.disposition, 'reasoning', a.reasoning))
      from api.alternative_table a where a.proposition_id in (select proposition_id from props)),
      '[]'::jsonb),

    'refutations', coalesce((
      select jsonb_agg(jsonb_build_object(
        'proposition_id', r.proposition_id, 'state', r.state,
        'narrative', r.narrative, 'asserted_at', r.asserted_at,
        'next_review_due', r.next_review_due, 'reversed_at', r.reversed_at))
      from core.refutation r where r.proposition_id in (select proposition_id from props)),
      '[]'::jsonb),

    -- Every evidence row, with receipts, tiers, causal provenance and
    -- diagnosticity, INCLUDING the inert ones and why they are inert.
    'evidence', coalesce((
      select jsonb_agg(jsonb_build_object(
        'observation_id', ev.observation_id,
        'proposition_id', ev.proposition_id,
        'statement', ev.statement,
        'sign', ev.sign, 'magnitude', ev.magnitude, 'signed_weight', ev.signed_weight,
        'membership', ev.membership, 'exclusion_reason', ev.exclusion_reason,
        'diagnosticity_source', ev.diagnosticity_source,
        'ea', case when ev.ea_expectedness is not null
                   then ev.ea_expectedness::text || '/' || ev.ea_alternative::text end,
        'scope', ev.scope, 'property_locus', ev.property_locus,
        'subject_binding_pass', ev.subject_binding_pass,
        'gate', jsonb_build_object('a_tier',ev.gate_a_tier,'b_receipt',ev.gate_b_receipt,
                                   'c_instance',ev.gate_c_instance,'d_on_its_face',ev.gate_d_on_its_face,
                                   'e_authority',ev.gate_e_authority,'f_unsolicited',ev.gate_f_unsolicited),
        'source', jsonb_build_object(
            'document_id', ev.document_id, 'title', ev.title,
            'issuing_body', ev.issuing_body, 'author', ev.author_name,
            'date', ev.document_date, 'url', ev.url,
            'identifier', ev.identifier, 'identifier_class', ev.identifier_class,
            'origin_tier', ev.origin_tier, 'channel', ev.channel,
            'causal_provenance', ev.causal_provenance, 'corpus_era', ev.corpus_era,
            'self_attesting', ev.self_attesting,
            'register_echo', ev.register_echo_quarantined,
            'corpus', ev.corpus_name, 'host', ev.corpus_host,
            'adversary_writable', ev.adversary_writable, 'egress_state', ev.egress_state,
            'lineage_id', ev.lineage_id),
        'receipt', jsonb_build_object(
            'state', ev.receipt_state, 'resolved_url', ev.resolved_url,
            'http_status', ev.http_status, 'sha256', ev.sha256,
            'retrieved_at', ev.retrieved_at, 'mirror_only', ev.mirror_only,
            'issuer_metadata_match', ev.issuer_metadata_match,
            'content_drifted', ev.content_drifted),
        'quote', jsonb_build_object('text', ev.quoted_text,
            'start', ev.span_start_offset, 'end', ev.span_end_offset,
            'quote_check', ev.quote_check, 'binding_quote', ev.binding_quote),
        'negative_search', case when ev.negative_search_query is not null then
            jsonb_build_object('query', ev.negative_search_query,
                               'corpus_as_of', ev.negative_search_corpus_date,
                               'result_count', ev.negative_search_result_count,
                               'erp_profile', ev.expected_record_profile,
                               'x_level', ev.expected_record_level) end)
        order by ev.membership, ev.magnitude desc)
      from api.evidence_row ev where ev.proposition_id in (select proposition_id from props)),
      '[]'::jsonb),

    -- Receipted absence, published: it is what licenses F and R.
    'negative_searches', coalesce((
      select jsonb_agg(jsonb_build_object(
        'query', sr.query_string, 'corpus_as_of', sr.corpus_as_of,
        'executed_at', sr.executed_at, 'result_count', sr.result_count,
        'outcome', sr.outcome, 'unsearched_reason', sr.unsearched_reason,
        'erp_profile', ep.profile_key, 'x_level', ep.x_level,
        'destroying_event', ep.destroying_event))
      from core.search_receipt sr
      left join registry.erp_profile ep using (erp_profile_id)
      where sr.proposition_id in (select proposition_id from props)), '[]'::jsonb),

    'geometry', (select jsonb_build_object(
        'representation', rg.representation, 'precision', rg.precision_level,
        'locate_grade', rg.locate_grade, 'uncertainty_radius_m', rg.uncertainty_radius_m,
        'suppression_reason', rg.suppression_reason,
        'geojson', st_asgeojson(rg.geom)::jsonb)
      from ent e cross join lateral core.render_geometry(e.entity_id) rg),

    'distinct_from', coalesce((
      select jsonb_agg(jsonb_build_object('entity_id', r.to_entity_id, 'name', o.canonical_name))
      from core.entity_relation r join core.entity o on o.entity_id = r.to_entity_id
      join ent on ent.entity_id = r.from_entity_id
      where r.kind = 'DISTINCT-FROM' and r.retracted_at is null), '[]'::jsonb)
  )
$$;

-- ---------------------------------------------------------------------
-- QUERY 3 — LINEAGE AND ORIGIN TRACE.
-- "Show me every assertion about this site, who said it, when, who they got
-- it from, and what it argues for or against."
-- The recursion is cycle-safe in two independent ways; see core.trace_origin.
-- ---------------------------------------------------------------------
create or replace function api.lineage_trace(p_proposition_id uuid)
returns jsonb
language sql stable security invoker as $$
  select jsonb_build_object(
    'proposition_id', p_proposition_id,

    -- The independence answer. NOT a COUNT(*): a graph property computed
    -- after fact-key merge, model-family collapse and component collapse.
    'independent_lineages', jsonb_build_object(
      'at_d2', (select count(*) from core.independent_lineages(p_proposition_id, 2::smallint)),
      'at_d3', (select count(*) from core.independent_lineages(p_proposition_id, 3::smallint)),
      'detail', coalesce((select jsonb_agg(jsonb_build_object(
          'lineage_key', il.lineage_key, 'kind', il.lineage_kind,
          'best_magnitude', il.best_magnitude, 'observations', il.observation_count,
          'representative', il.representative_title, 'tier', il.origin_tier))
        from core.independent_lineages(p_proposition_id, 2::smallint) il), '[]'::jsonb),
      'note', 'A claim on 400 websites is not 400 sources. Copies, paraphrase, machine regeneration and replication collapse to the component they came from; agents sharing a base model collapse to one.'),

    -- The graph itself, for rendering.
    'nodes', coalesce((select jsonb_agg(distinct jsonb_build_object(
        'document_id', d.document_id, 'title', d.title, 'tier', d.origin_tier,
        'date', d.document_date, 'first_observed', d.first_observed_date,
        'channel', d.channel, 'causal_provenance', d.causal_provenance,
        'corpus_era', d.corpus_era, 'self_attesting', d.self_attesting))
      from core.observation o join core.source_document d on d.document_id = o.document_id
      where o.proposition_id = p_proposition_id), '[]'::jsonb),

    'edges', coalesce((select jsonb_agg(jsonb_build_object(
        'from', dc.citing_document_id, 'to', dc.cited_document_id,
        'kind', dc.edge_kind, 'detection', dc.detection_method,
        'similarity', dc.similarity,
        'counterfactual', dc.counterfactual_verdict,
        'collapses_lineage', dc.collapses_lineage,
        'quorum_disagreement', dc.quorum_disagreement))
      from core.document_citation dc
      where dc.retracted_at is null
        and (dc.citing_document_id in (select document_id from core.observation
                                        where proposition_id = p_proposition_id)
          or dc.cited_document_id in (select document_id from core.observation
                                        where proposition_id = p_proposition_id))),
      '[]'::jsonb),

    -- Backward trace to the earliest traceable appearance, per seed.
    'origin_trace', coalesce((select jsonb_agg(jsonb_build_object(
        'seed', seeds.document_id, 'depth', t.depth,
        'document_id', t.document_id, 'title', t.title, 'tier', t.origin_tier,
        'date', t.document_date, 'first_observed', t.first_observed_date,
        'edge_kind', t.edge_kind, 'path', t.path,
        'is_cycle', t.is_cycle, 'is_terminus', t.is_terminus)
        order by t.depth)
      from (select distinct document_id from core.observation
             where proposition_id = p_proposition_id and document_id is not null) seeds
      cross join lateral core.trace_origin(seeds.document_id, 24) t), '[]'::jsonb),

    'citogenesis', coalesce((select jsonb_agg(jsonb_build_object(
        'state', cl.state, 'laundering_document_id', cl.laundering_document_id,
        't5_root', cl.t5_root_document_id, 'path', cl.loop_path,
        'narrative', cl.narrative))
      from core.citogenesis_loop cl where cl.proposition_id = p_proposition_id), '[]'::jsonb),

    'attestations', coalesce((select jsonb_agg(jsonb_build_object(
        'witness', w.display_name, 'resolvable', w.resolvable,
        'resolving_record_kind', w.resolving_record_kind,
        'custody', a.custody,
        'lineage_terminus_is', 'the asserting document, never the quoted person'))
      from core.attestation a
      join core.witness w on w.witness_id = a.witness_id
      join core.observation o on o.observation_id = a.observation_id
      where o.proposition_id = p_proposition_id), '[]'::jsonb)
  )
$$;

-- ---------------------------------------------------------------------
-- QUERY 4 — GRADE HISTORY RECONSTRUCTION.
-- Every re-grade is versioned, so a candidate's confidence history is
-- itself visible. Disclosure-driven movement renders visually distinct from
-- evidence-driven movement, and instrument drift is suppressed entirely
-- from the public chart (BES §11.2).
-- ---------------------------------------------------------------------
create or replace function api.grade_history(p_proposition_id uuid)
returns jsonb
language sql stable security invoker as $$
  select jsonb_build_object(
    'proposition_id', p_proposition_id,
    'series', coalesce((select jsonb_agg(jsonb_build_object(
        'seq', h.seq, 'grade', h.grade, 'previous_grade', h.previous_grade,
        'direction', h.direction,
        'cause', h.transition_cause,
        'suppress_from_public_chart', h.suppress_from_public_chart,
        'annotation', h.disclosure_annotation,
        'published_at', h.published_at,
        'observations_added', h.observations_added,
        'observations_removed', h.observations_removed,
        'limiting_condition', h.limiting_condition) order by h.seq)
      from core.grade_history(p_proposition_id) h), '[]'::jsonb),

    -- What moved it: the exact rows that entered or left between events.
    'movement', coalesce((select jsonb_agg(jsonb_build_object(
        'seq', ge.seq, 'grade', ge.grade, 'cause', ge.transition_cause,
        'evidence_state_hash', encode(ge.evidence_state_hash,'hex'),
        'entered', (select jsonb_agg(jsonb_build_object(
              'observation_id', geo.observation_id,
              'statement', o.statement, 'sign', o.sign, 'magnitude', o.magnitude,
              'source', d.title, 'tier', d.origin_tier))
            from core.grade_event_observation geo
            join core.observation o on o.observation_id = geo.observation_id
            left join core.source_document d on d.document_id = o.document_id
            where geo.grade_event_id = ge.grade_event_id
              and (ge.supersedes_id is null or not exists (
                    select 1 from core.grade_event_observation prev
                     where prev.grade_event_id = ge.supersedes_id
                       and prev.observation_id = geo.observation_id))))
        order by ge.seq)
      from core.grade_event ge
      where ge.proposition_id = p_proposition_id
        and ge.published_at is not null and not ge.is_blind_double_score), '[]'::jsonb)
  )
$$;

-- Point-in-time reconstruction: "what did the register say on this date?"
-- The Greenbrier regression test is exactly this call at 1991-12-31 and
-- 1992-12-31, and the pair must show cause = NEW-DISCLOSURE.
create or replace function api.grade_as_of(p_proposition_id uuid, p_at timestamptz)
returns jsonb
language sql stable security invoker as $$
  select case when g.grade_event_id is null then null else jsonb_build_object(
    'grade', g.grade, 'awarded_band', g.awarded_band, 'applied_caps', g.applied_caps,
    'limiting_condition', g.limiting_condition, 'null_state', g.null_state,
    'silence_reading', g.silence_reading, 'base_rate_reading', g.base_rate_reading,
    'conditions', g.condition_results,
    'lineages_d2', g.l_d2, 'lineages_d3', g.l_d3,
    'sci', g.sci, 'published_at', g.published_at,
    'rubric_version', g.rubric_version, 'scorer_model_id', g.scorer_model_id,
    'table_versions', jsonb_build_object('tier', g.tier_version_id,
        'diagnosticity', g.diagnosticity_version_id, 'erp', g.erp_version_id),
    'evidence_state_hash', encode(g.evidence_state_hash,'hex')) end
  from core.grade_at(p_proposition_id, p_at) g
$$;

-- ---------------------------------------------------------------------
-- QUERY 5 — THE CLAIMS REGISTER. E, F, R and X entries with their origin
-- work. This is the product, not the leftovers.
-- ---------------------------------------------------------------------
create or replace function api.claims_register_page(
  p_grades core.grade[] default array['E','F','R']::core.grade[],
  p_limit integer default 100, p_offset integer default 0)
returns jsonb
language sql stable security invoker as $$
  select coalesce(jsonb_agg(to_jsonb(t) order by t.grade, t.canonical_name), '[]'::jsonb)
  from (select * from api.claims_register cr
         where cr.grade = any(p_grades)
         order by cr.grade, cr.canonical_name
         limit p_limit offset p_offset) t
$$;

grant execute on function api.candidate_detail(text)              to anon, authenticated;
grant execute on function api.lineage_trace(uuid)                 to anon, authenticated;
grant execute on function api.grade_history(uuid)                 to anon, authenticated;
grant execute on function api.grade_as_of(uuid, timestamptz)      to anon, authenticated;
grant execute on function api.claims_register_page(core.grade[], integer, integer)
  to anon, authenticated;

-- ---------------------------------------------------------------------
-- QUERY 6 — the register's own telemetry, published.
-- A register that states its own measured fabrication rate is more credible
-- than one that implies none.
-- ---------------------------------------------------------------------
create or replace view api.register_telemetry with (security_invoker = true) as
select
  (select count(*) from core.entity where publication_state='PUBLISHED' and not is_canary) as entities_published,
  (select count(*) from core.proposition_current_grade)                                    as propositions_graded,
  (select jsonb_object_agg(grade, n) from (
      select grade, count(*) n from core.proposition_current_grade group by grade) s)      as band_occupancy,
  (select round(100.0*count(*) filter (where grade in ('X','D'))/nullif(count(*),0),1)
     from core.proposition_current_grade)                                                  as pct_modal_bands,
  (select round(100.0*count(*) filter (where grade='C')/nullif(count(*),0),1)
     from core.proposition_current_grade)                                                  as pct_c_band,
  (select count(*) from registry.corpus where egress_state='BLOCKED')                      as corpora_unreachable,
  (select count(*) from registry.corpus)                                                   as corpora_registered,
  'The modal register entry should be X or D. Most candidates are undifferentiated holes; a healthy register says so.'::text as band_note;

grant select on api.register_telemetry to anon, authenticated;
