-- =====================================================================
-- BUNKERS REGISTER — PART 6: rollup maintenance, publication, RLS
-- Requirements 3, 9, 10.
-- =====================================================================

-- =====================================================================
-- 16. INCREMENTAL ROLLUP MAINTENANCE
--     Writes enqueue; a worker (or the same transaction, for single-row
--     adjudication writes) recomputes. Recompute is scoped to ONE
--     proposition, so it is O(evidence-on-that-proposition), not O(table).
-- =====================================================================

create or replace function bes_enqueue_regrade() returns trigger
language plpgsql as $$
declare pid uuid;
begin
  pid := coalesce(new.proposition_id, old.proposition_id);
  insert into ops_regrade_queue (proposition_id, reason)
  values (pid, case TG_TABLE_NAME
                 when 'search_receipt' then 'NEW_SEARCH'::transition_cause
                 else 'NEW_VERIFICATION'::transition_cause end)
  on conflict (proposition_id) do update set enqueued_at = now();
  return coalesce(new, old);
end $$;

create trigger evidence_regrade after insert or update or delete on evidence
  for each row execute function bes_enqueue_regrade();
create trigger search_receipt_regrade after insert or update on search_receipt
  for each row execute function bes_enqueue_regrade();
create trigger prop_erp_regrade after insert or update or delete on proposition_erp
  for each row execute function bes_enqueue_regrade();

-- Denormalise document provenance onto evidence so V(P) is one index scan.
-- The mirrors are NOT independently writable: the trigger always wins.
create or replace function bes_sync_evidence_provenance() returns trigger
language plpgsql as $$
declare d document%rowtype;
begin
  if new.document_id is not null then
    select * into d from document where document_id = new.document_id;
    new.origin_tier := d.origin_tier;
    new.channel     := d.channel;
    new.causal_provenance := d.causal_provenance;
    new.corpus_era  := d.corpus_era;
    new.self_attesting := d.self_attesting;
    new.register_echo_quarantined := d.register_echo_quarantined;
    new.lineage_id  := coalesce(new.lineage_id, d.lineage_id);
  end if;

  -- §2.3 subject binding gates scope. Enforced, not trusted.
  if not new.subject_binding_pass and new.scope = 'INSTANCE' then
    new.scope := 'CLASS';
  end if;

  -- §3.2 PENDING sources score as T4: they can support C and D, never A or B.
  if new.origin_tier = 'PENDING' and new.diagnosticity > 2 then
    new.diagnosticity := 2;
  end if;

  -- §4.6 "cannot produce" written test, derived from the catalog or the matrix.
  if new.diagnosticity_catalog_id is not null then
    select (select p.null_hypothesis_code from proposition p
             where p.proposition_id = new.proposition_id) = any(dc.null_excluding_for)
      into new.null_excluding
    from diagnosticity_catalog dc where dc.catalog_id = new.diagnosticity_catalog_id;
  elsif new.ea_expected_under_alt is not null then
    new.null_excluding := new.ea_expected_under_alt <= 1;
  end if;
  new.null_excluding := coalesce(new.null_excluding, false);
  return new;
end $$;

create trigger evidence_sync_provenance before insert or update on evidence
  for each row execute function bes_sync_evidence_provenance();

-- §5.4 attestation custody: if custody fails, the lineage terminus is the
-- ASSERTER, not the person quoted. Both "independent" witnesses collapse.
create or replace function bes_attestation_custody() returns trigger
language plpgsql as $$
begin
  if not new.custody_pass then
    select d.lineage_id into new.effective_lineage_id
    from document d where d.document_id = new.document_id;
  end if;
  return new;
end $$;
create trigger attestation_custody before insert or update on attestation
  for each row execute function bes_attestation_custody();

-- Entity rollup: badges + render gate. Derived from proposition_rollup.
create or replace function bes_recompute_entity(p_entity uuid) returns void
language plpgsql as $$
declare
  ex grade_band; lo grade_band; e entity%rowtype; rm render_mode; rg geometry;
begin
  select * into e from entity where entity_id = p_entity;
  if not found then return; end if;

  select coalesce(max(grade) filter (where class='EXIST'),'X'),
         coalesce(max(grade) filter (where class='LOCATE'),'X')
    into ex, lo
  from proposition_rollup where entity_id = p_entity;

  -- §10.3 PUBLICATION GATES, computed here so no client can bypass them:
  --  * nothing below band D renders as a map pin;
  --  * LOCATE below band C renders as a region, NEVER a point — a precise
  --    pin manufactured from imprecise evidence is the register performing
  --    its own citogenesis at the interface layer (historian #12).
  if ex < 'D' or e.location_precision = 'non_located' then
    rm := 'list_only'; rg := null;
  elsif e.location_precision = 'surveyed'
        or (lo >= 'C' and e.point_geom is not null) then
    rm := 'point'; rg := e.point_geom;
  else
    rm := 'region'; rg := e.extent_geom;
  end if;

  insert into entity_rollup as er (
    entity_id, exist_grade, locate_grade, best_grade, worst_grade,
    proposition_count, refuted_count, unassessed_count,
    render_mode, render_geom, anchor_geom, location_precision,
    uncertainty_radius_m, typology_code, country, badges, headline, computed_at)
  select p_entity, ex, lo,
         coalesce(agg.best,'X'), coalesce(agg.worst,'X'),
         coalesce(agg.n,0), coalesce(agg.n_r,0), coalesce(agg.n_x,0),
         rm, rg, e.anchor_geom, e.location_precision, e.uncertainty_radius_m,
         e.typology_code, e.country, coalesce(agg.badges,'[]'::jsonb),
         e.display_name, now()
  from (
    select max(pr.grade) as best, min(pr.grade) as worst, count(*) as n,
           count(*) filter (where pr.grade='R') as n_r,
           count(*) filter (where pr.grade='X') as n_x,
           jsonb_agg(jsonb_build_object(
             'proposition_id', pr.proposition_id, 'class', pr.class,
             'grade', pr.grade, 'ceiling', pr.ceiling, 'at_ceiling', pr.at_ceiling,
             'limiting_condition', pr.limiting_condition,
             'marginal', pr.marginal_flag, 'null_state', pr.null_state,
             'silence', pr.silence_reading, 'base_rate', pr.base_rate_reading,
             'sci', pr.sci, 'statement', p.statement,
             'place_derived', pr.place_derived_count,
             'claim_derived', pr.claim_derived_count)
             order by pr.class) as badges
    from proposition_rollup pr
    join proposition p using (proposition_id)
    where pr.entity_id = p_entity
  ) agg
  on conflict (entity_id) do update set
    exist_grade=excluded.exist_grade, locate_grade=excluded.locate_grade,
    best_grade=excluded.best_grade, worst_grade=excluded.worst_grade,
    proposition_count=excluded.proposition_count, refuted_count=excluded.refuted_count,
    unassessed_count=excluded.unassessed_count, render_mode=excluded.render_mode,
    render_geom=excluded.render_geom, anchor_geom=excluded.anchor_geom,
    location_precision=excluded.location_precision,
    uncertainty_radius_m=excluded.uncertainty_radius_m,
    typology_code=excluded.typology_code, country=excluded.country,
    badges=excluded.badges, headline=excluded.headline, computed_at=now();
end $$;

create or replace function bes_prop_rollup_fanout() returns trigger
language plpgsql as $$
begin
  perform bes_recompute_entity(new.entity_id);
  return new;
end $$;
create trigger prop_rollup_entity_fanout after insert or update on proposition_rollup
  for each row execute function bes_prop_rollup_fanout();

-- Geometry change must re-derive the render gate.
create or replace function bes_entity_geom_fanout() returns trigger
language plpgsql as $$
begin
  perform bes_recompute_entity(new.entity_id);
  return new;
end $$;
create trigger entity_geom_fanout after update of point_geom, extent_geom,
  location_precision, typology_code on entity
  for each row execute function bes_entity_geom_fanout();

-- Drain the queue. Called by pg_cron / an edge function / the ingest worker.
create or replace function bes_drain_regrade_queue(p_limit int default 500)
returns int language plpgsql as $$
declare n int := 0; q record;
begin
  for q in select * from ops_regrade_queue order by enqueued_at limit p_limit loop
    begin
      perform bes_apply_grade(q.proposition_id, q.reason, 'worker');
      n := n + 1;
    exception when others then
      update ops_regrade_queue
         set attempts = attempts + 1, last_error = sqlerrm
       where proposition_id = q.proposition_id;
    end;
  end loop;
  return n;
end $$;

-- =====================================================================
-- 17. PUBLICATION — one deliberate, transactional act (req. 3, 9).
--     Nothing is deleted, ever. Withdrawal flips flags and logs.
-- =====================================================================

create or replace function ops_publish_entity(p_entity uuid, p_actor text default 'curator')
returns void language plpgsql security definer set search_path = public as $$
begin
  update entity set is_published = true, published_at = coalesce(published_at, now())
   where entity_id = p_entity;

  -- §10.3: E, F and R propositions ARE published — they live in the claims
  -- register with their origin work, which is the product. X is published too
  -- (an honestly mostly-X register is more credible than a dishonestly
  -- mostly-C one). Publication is not a quality gate; RENDERING is.
  update proposition set is_published = true, published_at = coalesce(published_at, now())
   where entity_id = p_entity;
  update proposition_rollup set is_published = true where entity_id = p_entity;
  update evidence e set is_published = true
   from proposition p where p.proposition_id = e.proposition_id and p.entity_id = p_entity;
  update grade_event ge set is_published = true
   from proposition p where p.proposition_id = ge.proposition_id and p.entity_id = p_entity;
  update search_receipt sr set is_published = true
   from proposition p where p.proposition_id = sr.proposition_id and p.entity_id = p_entity;

  update document d set is_published = true
   where exists (select 1 from evidence e join proposition p using (proposition_id)
                 where e.document_id = d.document_id and p.entity_id = p_entity);

  -- Publish the TRANSITIVE CITATION CLOSURE of those documents. Without this
  -- the origin trace is truncated at the first unpublished hop, and the
  -- register would show the laundered claim while hiding the T5 forum post it
  -- rests on — exactly the failure it exists to expose. The graph is cyclic,
  -- so the walk carries both a CYCLE clause and a depth cap.
  with recursive closure as (
    select d.document_id, 0 as depth
    from document d where d.is_published
    union all
    select c.cited_document_id, cl.depth + 1
    from closure cl
    join citation c on c.citing_document_id = cl.document_id
    where cl.depth < 25
  ) cycle document_id set is_cycle using path
  update document d2 set is_published = true
   from (select distinct document_id from closure) cl
   where d2.document_id = cl.document_id and not d2.is_published;

  update retrieval r set is_published = true
   where exists (select 1 from document d where d.document_id = r.document_id and d.is_published);
  update citation c set is_published = true
   where exists (select 1 from document d1 where d1.document_id=c.citing_document_id and d1.is_published)
     and exists (select 1 from document d2 where d2.document_id=c.cited_document_id and d2.is_published);
  update document_claim dc set is_published = true
   where exists (select 1 from document d where d.document_id=dc.document_id and d.is_published);
  update attestation a set is_published = true
   where exists (select 1 from document d where d.document_id=a.document_id and d.is_published);

  insert into register_publication_log (entity_id, action, actor)
  values (p_entity, 'PUBLISH', p_actor);

  perform bes_recompute_entity(p_entity);
  update entity_rollup set is_published = true where entity_id = p_entity;
end $$;

revoke all on function ops_publish_entity(uuid,text) from public, anon, authenticated;

-- =====================================================================
-- 18. ROW LEVEL SECURITY (req. 9)
--     anon/authenticated: SELECT only, only where is_published.
--     service_role: full access (BYPASSRLS in Supabase).
--     ops schema: no grants at all.
-- =====================================================================

alter table entity                enable row level security;
alter table entity_alias          enable row level security;
alter table entity_relation       enable row level security;
alter table entity_merge_event    enable row level security;
alter table entity_typology_history enable row level security;
alter table jurisdiction          enable row level security;
alter table proposition           enable row level security;
alter table proposition_rollup    enable row level security;
alter table proposition_erp       enable row level security;
alter table evidence              enable row level security;
alter table document              enable row level security;
alter table retrieval             enable row level security;
alter table citation              enable row level security;
alter table document_claim        enable row level security;
alter table attestation           enable row level security;
alter table lineage               enable row level security;
alter table lineage_decision      enable row level security;
alter table search_receipt        enable row level security;
alter table grade_event           enable row level security;
alter table entity_rollup         enable row level security;
alter table register_publication_log enable row level security;
alter table candidate_set         enable row level security;
alter table candidate_set_member  enable row level security;
alter table source                enable row level security;
alter table source_host           enable row level security;
alter table tier_definition       enable row level security;
alter table null_hypothesis       enable row level security;
alter table typology_profile      enable row level security;
alter table diagnosticity_catalog enable row level security;
alter table ea_matrix             enable row level security;
alter table erp_profile           enable row level security;
alter table base_rate_table       enable row level security;
alter table canonical_corpus      enable row level security;
alter table table_version         enable row level security;
alter table ops_lead              enable row level security;
alter table ops_regrade_queue     enable row level security;

-- ---- Published-gated read -------------------------------------------
create policy anon_read on entity            for select to anon, authenticated using (is_published);
create policy anon_read on proposition       for select to anon, authenticated using (is_published);
create policy anon_read on proposition_rollup for select to anon, authenticated using (is_published);
create policy anon_read on evidence          for select to anon, authenticated using (is_published);
create policy anon_read on document          for select to anon, authenticated using (is_published);
create policy anon_read on retrieval         for select to anon, authenticated using (is_published);
create policy anon_read on citation          for select to anon, authenticated using (is_published);
create policy anon_read on document_claim    for select to anon, authenticated using (is_published);
create policy anon_read on attestation       for select to anon, authenticated using (is_published);
create policy anon_read on search_receipt    for select to anon, authenticated using (is_published);
create policy anon_read on grade_event       for select to anon, authenticated using (is_published);
create policy anon_read on entity_rollup     for select to anon, authenticated using (is_published);

-- Children of published parents.
create policy anon_read on entity_alias for select to anon, authenticated
  using (exists (select 1 from entity e where e.entity_id = entity_alias.entity_id and e.is_published));
create policy anon_read on entity_relation for select to anon, authenticated
  using (exists (select 1 from entity a where a.entity_id = entity_relation.from_entity_id and a.is_published)
     and exists (select 1 from entity b where b.entity_id = entity_relation.to_entity_id   and b.is_published));
create policy anon_read on entity_typology_history for select to anon, authenticated
  using (exists (select 1 from entity e where e.entity_id = entity_typology_history.entity_id and e.is_published));
create policy anon_read on entity_merge_event for select to anon, authenticated
  using (exists (select 1 from entity e where e.entity_id = entity_merge_event.surviving_entity_id and e.is_published));
create policy anon_read on proposition_erp for select to anon, authenticated
  using (exists (select 1 from proposition p where p.proposition_id = proposition_erp.proposition_id and p.is_published));
create policy anon_read on lineage for select to anon, authenticated
  using (exists (select 1 from document d where d.lineage_id = lineage.lineage_id and d.is_published));
create policy anon_read on lineage_decision for select to anon, authenticated
  using (exists (select 1 from evidence e where e.evidence_id = lineage_decision.evidence_id and e.is_published));
create policy anon_read on candidate_set_member for select to anon, authenticated
  using (exists (select 1 from entity e where e.entity_id = candidate_set_member.entity_id and e.is_published));
create policy anon_read on register_publication_log for select to anon, authenticated
  using (exists (select 1 from entity e where e.entity_id = register_publication_log.entity_id and e.is_published));

-- ---- Reference data: public by design. The rubric is published WITH an
-- ---- explicit warning that it is a public optimisation target (§13).
create policy anon_read on jurisdiction        for select to anon, authenticated using (true);
create policy anon_read on source              for select to anon, authenticated using (true);
create policy anon_read on source_host         for select to anon, authenticated using (true);
create policy anon_read on tier_definition     for select to anon, authenticated using (true);
create policy anon_read on null_hypothesis     for select to anon, authenticated using (true);
create policy anon_read on typology_profile    for select to anon, authenticated using (true);
create policy anon_read on diagnosticity_catalog for select to anon, authenticated using (true);
create policy anon_read on ea_matrix           for select to anon, authenticated using (true);
create policy anon_read on erp_profile         for select to anon, authenticated using (true);
create policy anon_read on base_rate_table     for select to anon, authenticated using (true);
create policy anon_read on canonical_corpus    for select to anon, authenticated using (true);
create policy anon_read on table_version       for select to anon, authenticated using (true);
create policy anon_read on candidate_set       for select to anon, authenticated using (true);

-- ops_lead and ops_regrade_queue: RLS enabled, ZERO policies => deny all.
-- (Adjudication state. Naming a lead would leak an unpublished candidate.)

-- ---- Grants ----------------------------------------------------------
revoke all on all tables in schema public from anon, authenticated;
revoke all on schema ops from anon, authenticated;

grant usage on schema public to anon, authenticated;
grant select on
  entity, entity_alias, entity_relation, entity_merge_event, entity_typology_history,
  jurisdiction, proposition, proposition_rollup, proposition_erp, evidence, document,
  retrieval, citation, document_claim, attestation, lineage, lineage_decision,
  search_receipt, grade_event, entity_rollup, register_publication_log,
  candidate_set, candidate_set_member, source, source_host, tier_definition,
  null_hypothesis, typology_profile, diagnosticity_catalog, ea_matrix,
  erp_profile, base_rate_table, canonical_corpus, table_version
to anon, authenticated;

-- Explicitly NOT granted: ops_lead, ops_regrade_queue, everything in ops.
grant usage on schema ops to service_role;
grant all on all tables in schema ops to service_role;
grant all on all tables in schema public to service_role;

alter default privileges in schema ops grant all on tables to service_role;
alter default privileges in schema public revoke all on tables from anon, authenticated;
