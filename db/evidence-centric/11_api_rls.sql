-- =====================================================================
-- SECTION 11 — THE PUBLISHED PROJECTION, AND ROW-LEVEL SECURITY
--
-- Hard requirement 9: anonymous read on published data; ingest and
-- adjudication state writable only by the service role; no leakage of
-- unpublished adjudication state to anonymous readers.
--
-- Three independent layers, so that any one of them failing is not a breach:
--   1. PostgREST is pointed at the `api` schema ONLY. core/ingest/registry
--      are not in db-schemas, so they have no HTTP surface at all.
--   2. RLS on every core table, with anon policies that require
--      publication_state = 'PUBLISHED' all the way up the chain.
--   3. api views are SECURITY INVOKER, so they inherit (2) rather than
--      bypassing it. The two materialised views cannot inherit RLS, so
--      their WHERE clauses are written as the boundary and are grant-scoped.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 11.1 — Enable RLS everywhere in core and ingest. Default deny.
-- ---------------------------------------------------------------------
do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables
            where schemaname in ('core','ingest','registry')
  loop
    execute format('alter table %I.%I enable row level security', t.schemaname, t.tablename);
    execute format('alter table %I.%I force row level security', t.schemaname, t.tablename);
  end loop;
end $$;

-- service_role has BYPASSRLS in Supabase, but state it explicitly so the
-- intent survives a role change.
do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables
            where schemaname in ('core','ingest','registry')
  loop
    execute format(
      'create policy service_all on %I.%I as permissive for all to service_role using (true) with check (true)',
      t.schemaname, t.tablename);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 11.2 — Anonymous read policies. Published-only, chained.
--
-- Note what is NOT here: ingest.*, core.adjudication state, curation
-- proposals, canaries, leads, double-scoring, null returns, agent runs.
-- Those tables have no anon policy, which means RLS denies every row.
-- ---------------------------------------------------------------------

-- Reference data is public: the register publishes its own instrument.
create policy anon_read on registry.country          for select to anon, authenticated using (true);
create policy anon_read on registry.admin_area       for select to anon, authenticated using (true);
create policy anon_read on registry.null_hypothesis  for select to anon, authenticated using (true);
create policy anon_read on registry.corpus           for select to anon, authenticated using (true);
create policy anon_read on registry.egress_probe     for select to anon, authenticated using (true);
create policy anon_read on registry.identifier_grammar for select to anon, authenticated using (true);
create policy anon_read on registry.diagnosticity_catalog for select to anon, authenticated using (true);
create policy anon_read on registry.erp_profile      for select to anon, authenticated using (true);
create policy anon_read on registry.canonical_search_set for select to anon, authenticated using (true);
create policy anon_read on registry.candidate_set    for select to anon, authenticated using (true);
create policy anon_read on registry.candidate_set_member for select to anon, authenticated using (true);
create policy anon_read on registry.base_rate        for select to anon, authenticated using (true);
create policy anon_read on registry.table_version    for select to anon, authenticated using (true);
create policy anon_read on registry.rubric_version   for select to anon, authenticated using (true);
create policy anon_read on registry.scorer_model     for select to anon, authenticated using (true);

-- Entities: published, non-canary.
create policy anon_read on core.entity for select to anon, authenticated
  using (publication_state = 'PUBLISHED' and is_canary = false);

create policy anon_read on core.entity_alias for select to anon, authenticated
  using (retired_at is null and exists (
    select 1 from core.entity e where e.entity_id = entity_alias.entity_id
      and e.publication_state='PUBLISHED' and not e.is_canary));

create policy anon_read on core.entity_identifier for select to anon, authenticated
  using (exists (select 1 from core.entity e where e.entity_id = entity_identifier.entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

create policy anon_read on core.entity_relation for select to anon, authenticated
  using (retracted_at is null
     and exists (select 1 from core.entity a where a.entity_id = entity_relation.from_entity_id
                   and a.publication_state='PUBLISHED' and not a.is_canary)
     and exists (select 1 from core.entity b where b.entity_id = entity_relation.to_entity_id
                   and b.publication_state='PUBLISHED' and not b.is_canary));

create policy anon_read on core.entity_merge_event for select to anon, authenticated
  using (exists (select 1 from core.entity e where e.entity_id = entity_merge_event.surviving_entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

create policy anon_read on core.geometry_assertion for select to anon, authenticated
  using (exists (select 1 from core.entity e where e.entity_id = geometry_assertion.entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

-- Propositions: published, and their entity published.
create policy anon_read on core.proposition for select to anon, authenticated
  using (publication_state = 'PUBLISHED'
     and exists (select 1 from core.entity e where e.entity_id = proposition.entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

create policy anon_read on core.claim for select to anon, authenticated
  using (exists (select 1 from core.proposition p where p.claim_id = claim.claim_id
                   and p.publication_state='PUBLISHED'));

-- Observations: published, and their proposition published. V0 and
-- quarantined rows ARE published — retained and displayed as inert, per
-- BES §10.1. Suppressing them would hide the register's own failures.
create policy anon_read on core.observation for select to anon, authenticated
  using (publication_state = 'PUBLISHED'
     and exists (select 1 from core.proposition p
                  where p.proposition_id = observation.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.source_document for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where o.document_id = source_document.document_id
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));

create policy anon_read on core.retrieval_receipt for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where o.receipt_id = retrieval_receipt.receipt_id
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));

create policy anon_read on core.quoted_span for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where (o.probative_span_id = quoted_span.span_id
                        or o.binding_span_id = quoted_span.span_id)
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));

-- Receipted absence is a published artifact: it is what licenses F and R.
create policy anon_read on core.search_receipt for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = search_receipt.proposition_id
                    and p.publication_state='PUBLISHED'));
create policy anon_read on core.search_log for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = search_log.proposition_id
                    and p.publication_state='PUBLISHED'));

-- The citation graph and lineages are the product; they publish.
create policy anon_read on core.lineage for select to anon, authenticated using (true);
create policy anon_read on core.lineage_membership for select to anon, authenticated
  using (exists (select 1 from core.source_document d
                  join core.observation o on o.document_id = d.document_id
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where d.document_id = lineage_membership.document_id
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));
create policy anon_read on core.document_citation for select to anon, authenticated
  using (retracted_at is null);
create policy anon_read on core.citogenesis_loop for select to anon, authenticated
  using (state = 'confirmed'
     and exists (select 1 from core.proposition p
                  where p.proposition_id = citogenesis_loop.proposition_id
                    and p.publication_state='PUBLISHED'));
create policy anon_read on core.witness for select to anon, authenticated using (true);
create policy anon_read on core.attestation for select to anon, authenticated
  using (exists (select 1 from core.observation o
                  join core.proposition p on p.proposition_id = o.proposition_id
                 where o.observation_id = attestation.observation_id
                   and o.publication_state='PUBLISHED' and p.publication_state='PUBLISHED'));

-- Grades: PUBLISHED events only. An unpublished grade event is exactly the
-- adjudication state requirement 9 forbids leaking, and blind double-scores
-- must never be visible or the blind is not blind.
create policy anon_read on core.grade_event for select to anon, authenticated
  using (published_at is not null
     and not is_blind_double_score
     and exists (select 1 from core.proposition p
                  where p.proposition_id = grade_event.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.grade_event_observation for select to anon, authenticated
  using (exists (select 1 from core.grade_event g
                  where g.grade_event_id = grade_event_observation.grade_event_id
                    and g.published_at is not null and not g.is_blind_double_score));

create policy anon_read on core.proposition_current_grade for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = proposition_current_grade.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.refutation for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = refutation.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.alternative_disposition for select to anon, authenticated
  using (exists (select 1 from core.proposition p
                  where p.proposition_id = alternative_disposition.proposition_id
                    and p.publication_state='PUBLISHED'));

create policy anon_read on core.clamp_event for select to anon, authenticated
  using (exists (select 1 from core.grade_event g
                  where g.grade_event_id = clamp_event.grade_event_id
                    and g.published_at is not null));

create policy anon_read on core.publication_log for select to anon, authenticated
  using (exists (select 1 from core.entity e where e.entity_id = publication_log.entity_id
                   and e.publication_state='PUBLISHED' and not e.is_canary));

-- ---------------------------------------------------------------------
-- 11.3 — Grants. SELECT only, and only on what a policy can protect.
-- No INSERT/UPDATE/DELETE grant exists for anon or authenticated anywhere.
-- ---------------------------------------------------------------------
do $$
declare t record;
begin
  for t in select schemaname, tablename from pg_tables
            where schemaname in ('core','registry')
  loop
    -- grant SELECT only where an anon policy exists; RLS then filters rows.
    if exists (select 1 from pg_policies pp
                where pp.schemaname = t.schemaname and pp.tablename = t.tablename
                  and pp.policyname = 'anon_read') then
      execute format('grant select on %I.%I to anon, authenticated', t.schemaname, t.tablename);
    end if;
  end loop;
end $$;

grant all on all tables    in schema core, registry, ingest to service_role;
grant all on all sequences in schema core, registry, ingest to service_role;
grant usage on schema core, registry, ingest to service_role;

-- ---------------------------------------------------------------------
-- 11.4 — THE PUBLISHED PROJECTION.
-- All security_invoker, so RLS above is the single source of truth.
-- ---------------------------------------------------------------------

-- The proposition table that leads every entry page (BES §10.1).
-- "The composite does not exist; the decomposition is the product."
create view api.proposition_badge with (security_invoker = true) as
select
  p.proposition_id,
  p.entity_id,
  e.slug                        as entity_slug,
  e.canonical_name              as entity_name,
  p.class,
  p.statement_text,
  p.predicate_args,
  p.as_of_date,
  cg.grade,
  core.grade_rank(cg.grade)     as grade_rank,
  ge.awarded_band,
  ge.applied_caps,
  ge.ceiling,
  ge.at_ceiling,
  ge.limiting_condition,
  ge.marginal_flag,
  ge.silence_reading,
  ge.base_rate_reading,
  ge.reference_class,
  ge.null_state,
  p.null_code,
  nh.label                      as null_label,
  ge.refutation_state,
  ge.l_d2, ge.l_d3, ge.v_count, ge.u_count, ge.v0_count, ge.v_claim_count,
  ge.sci, ge.sci_numerator, ge.sci_denominator,
  -- the two bars, always (BES §10.2)
  ge.place_derived_weight,
  ge.claim_derived_weight,
  ge.condition_results,
  ge.transition_cause,
  ge.rubric_version,
  ge.scorer_model_id,
  ge.tier_version_id, ge.diagnosticity_version_id, ge.erp_version_id,
  cg.published_at               as graded_at,
  exists (select 1 from core.citogenesis_loop cl
           where cl.proposition_id = p.proposition_id and cl.state='confirmed') as citogenesis_flag
from core.proposition p
join core.entity e on e.entity_id = p.entity_id
join core.proposition_current_grade cg on cg.proposition_id = p.proposition_id
join core.grade_event ge on ge.grade_event_id = cg.grade_event_id
join registry.null_hypothesis nh on nh.null_code = p.null_code;

-- Every evidence row with its receipt, tier, provenance and diagnosticity,
-- INCLUDING V0 and quarantined rows shown as inert (BES §10.1).
create view api.evidence_row with (security_invoker = true) as
select
  o.observation_id,
  o.proposition_id,
  o.statement,
  o.observation_key,
  o.sign,
  o.magnitude,
  o.signed_weight,
  o.membership,
  o.exclusion_reason,
  o.diagnosticity_source,
  o.ea_expectedness, o.ea_alternative,
  o.scope, o.property_locus, o.subject_binding_pass, o.fact_key,
  o.gate_a_tier, o.gate_b_receipt, o.gate_c_instance,
  o.gate_d_on_its_face, o.gate_e_authority, o.gate_f_unsolicited,
  d.document_id, d.title, d.issuing_body, d.author_name, d.document_date, d.url,
  d.identifier, d.identifier_class,
  d.origin_tier, d.channel, d.causal_provenance, d.corpus_era,
  d.self_attesting, d.register_echo_quarantined,
  d.lineage_id,
  c.name  as corpus_name,
  c.host  as corpus_host,
  c.adversary_writable,
  c.egress_state,
  rr.receipt_state, rr.resolved_url, rr.http_status,
  encode(rr.sha256_of_bytes,'hex') as sha256,
  rr.retrieved_at, rr.mirror_only, rr.issuer_metadata_match, rr.content_drifted,
  qs.quoted_text, qs.span_start_offset, qs.span_end_offset, qs.quote_check,
  bs.quoted_text as binding_quote,
  sr.query_string as negative_search_query,
  sr.corpus_as_of as negative_search_corpus_date,
  sr.result_count as negative_search_result_count,
  ep.profile_key  as expected_record_profile,
  ep.x_level      as expected_record_level
from core.observation o
left join core.source_document d   on d.document_id = o.document_id
left join registry.corpus c        on c.corpus_id  = d.corpus_id
left join core.retrieval_receipt rr on rr.receipt_id = o.receipt_id
left join core.quoted_span qs      on qs.span_id = o.probative_span_id
left join core.quoted_span bs      on bs.span_id = o.binding_span_id
left join core.search_receipt sr   on sr.search_receipt_id = o.derived_from_search_receipt_id
left join registry.erp_profile ep  on ep.erp_profile_id = sr.erp_profile_id;

-- The alternative-hypothesis disposition table. IC failure #6: the single
-- most valuable artifact the register could show a skeptical reader.
create view api.alternative_table with (security_invoker = true) as
select ad.proposition_id, ad.null_code, nh.label, nh.description,
       ad.is_selected, ad.disposition, ad.reasoning, ad.excluding_observation_ids
  from core.alternative_disposition ad
  join registry.null_hypothesis nh using (null_code);

-- The claims register: E, F and R live here with their origin work, which
-- is the product. Nothing is deleted; refuted entries keep their refutations.
create view api.claims_register with (security_invoker = true) as
select p.proposition_id, p.entity_id, e.slug, e.canonical_name,
       p.class, p.statement_text, cg.grade, ge.limiting_condition,
       ge.silence_reading, ge.refutation_state,
       cl.claim_text,
       cl.first_appearance_date, cl.first_appearance_confidence,
       (select jsonb_agg(jsonb_build_object('state', rf.state, 'narrative', rf.narrative))
          from core.refutation rf
         where rf.proposition_id = p.proposition_id and rf.reversed_at is null) as refutations,
       exists (select 1 from core.citogenesis_loop x
                where x.proposition_id = p.proposition_id and x.state='confirmed') as citogenesis
  from core.proposition p
  join core.entity e on e.entity_id = p.entity_id
  join core.proposition_current_grade cg on cg.proposition_id = p.proposition_id
  join core.grade_event ge on ge.grade_event_id = cg.grade_event_id
  left join core.claim cl on cl.claim_id = p.claim_id
 where cg.grade in ('E','F','R','X');

-- Coverage and instrument honesty, published (tradeoff #7, fleet demand #0).
create view api.methodology_coverage with (security_invoker = true) as
select c.slug, c.name, c.beat, c.host, c.host_tier, c.content_tier,
       c.value, c.robots_posture, c.rate_limits,
       c.egress_state, c.egress_probed_at, c.adversary_writable
  from registry.corpus c;

create view api.expected_record_table with (security_invoker = true) as
select ep.profile_key, ep.description, ep.x_level, ep.authority_note,
       ep.silence_override, ep.destroying_event, ep.era_from, ep.era_to
  from registry.erp_profile ep;

grant select on api.proposition_badge, api.evidence_row, api.alternative_table,
                api.claims_register, api.methodology_coverage, api.expected_record_table
  to anon, authenticated;
grant select on api.map_feature, api.map_cluster to anon, authenticated;
grant execute on function api.map_viewport(double precision,double precision,double precision,double precision,integer,core.grade,core.typology[],text[]) to anon, authenticated;
grant execute on function api.map_tile(integer,integer,integer) to anon, authenticated;

-- Traversal functions the app calls directly. STABLE + security invoker, so
-- they see only what the caller may see.
grant execute on function core.trace_origin(uuid,integer)          to anon, authenticated;
grant execute on function core.claim_origin(uuid,integer)          to anon, authenticated;
grant execute on function core.independent_lineages(uuid,smallint) to anon, authenticated;
grant execute on function core.lineage_count(uuid,smallint)        to anon, authenticated;
grant execute on function core.grade_history(uuid)                 to anon, authenticated;
grant execute on function core.grade_at(uuid,timestamptz)          to anon, authenticated;
grant execute on function core.grade_rank(core.grade)              to anon, authenticated;
grant execute on function core.rank_grade(smallint)                to anon, authenticated;
grant execute on function core.render_geometry(uuid)               to anon, authenticated;

-- Explicitly NOT granted to anon: core.evaluate_proposition (it reads
-- unpublished rows to compute a provisional grade), core.record_grade,
-- api.refresh_map, and everything in ingest.
revoke all on function core.evaluate_proposition(uuid) from public, anon, authenticated;
revoke all on function core.record_grade(uuid,core.transition_cause,text,text,boolean,boolean)
  from public, anon, authenticated;
grant execute on function core.evaluate_proposition(uuid) to service_role;
grant execute on function core.record_grade(uuid,core.transition_cause,text,text,boolean,boolean)
  to service_role;
