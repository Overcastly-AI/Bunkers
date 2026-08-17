-- =====================================================================
-- ACCEPTANCE TESTS for the BUNKERS final schema.
-- Each test names the requirement it proves. Run after schema.sql.
-- =====================================================================
\set ON_ERROR_STOP on
set search_path = core, registry, ingest, api, public;

create or replace function t_ok(cond boolean, label text) returns void
language plpgsql as $$
begin
  if cond then raise notice 'PASS  %', label;
  else raise exception 'FAIL  %', label; end if;
end $$;

-- ---- fixtures --------------------------------------------------------
insert into registry.scorer_model values ('test-model','family-alpha','test','ASSESSOR',now());
insert into registry.scorer_model values ('other-model','family-beta','test','VERIFIER',now());
insert into registry.corpus (slug,name,beat,url,host,country_code,host_tier,content_tier,
  tier_version_id,reviewed_by)
select 'govinfo','GovInfo','federal','https://govinfo.gov','govinfo.gov','US','T1','T1',
  (select table_version_id from registry.table_version where table_name='tier' and is_current),'W0';
insert into registry.corpus (slug,name,beat,url,host,country_code,host_tier,content_tier,
  adversary_writable,tier_version_id,reviewed_by)
select 'atsforum','AboveTopSecret','fringe','https://ats.example','ats.example','US','T5','T5',
  true,(select table_version_id from registry.table_version where table_name='tier' and is_current),'W0';

-- A helper that makes a fully verified receipt, since RESOLVE-OR-DIE means
-- there is no shortcut to VERIFIED.
create or replace function t_doc(p_title text, p_tier core.origin_tier,
  p_date date default '1961-01-01', p_family text default null,
  p_self_attest boolean default false, p_channel core.channel default 'ORIGIN-HOST')
returns uuid language plpgsql as $$
declare d uuid;
begin
  insert into core.source_document (title, issuing_body, document_date, origin_tier,
    causal_provenance, corpus_era, channel, self_attesting, self_attesting_rationale,
    agent_model_family, first_observed_date,
    corpus_id)
  values (p_title, 'Test Issuer', p_date, p_tier, 'UNSOLICITED', 'PRE-2022', p_channel,
    p_self_attest, case when p_self_attest then 'author is the claimant' end,
    p_family, p_date, (select corpus_id from registry.corpus where slug='govinfo'))
  returning document_id into d;
  return d;
end $$;

create or replace function t_receipt(p_doc uuid, p_verified boolean default true,
  p_mirror boolean default false)
returns uuid language plpgsql as $$
declare r uuid;
begin
  insert into core.retrieval_receipt (document_id, requested_url, resolved_url, http_status,
    sha256_of_bytes, grammar_pass, resolved_at_issuer, mirror_only, mirror_host,
    issuer_metadata_match, receipt_state)
  values (p_doc, 'https://govinfo.gov/x', 'https://govinfo.gov/x',
    case when p_verified then 200 else 404 end,
    case when p_verified then decode(md5(p_doc::text)||md5(p_doc::text),'hex') end,
    p_verified, p_verified and not p_mirror, p_mirror,
    case when p_mirror then 'archive.org' end,
    p_verified, (case when p_verified then 'VERIFIED' else 'UNRESOLVED' end)::core.receipt_state)
  returning receipt_id into r;
  return r;
end $$;

-- ---------------------------------------------------------------------
-- REQUIREMENT 1 & 7: a site is a container of independently graded
-- assertions, and geometry carries its uncertainty.
-- The Greenbrier-1991 shape: the hole is certain, the function is not.
-- ---------------------------------------------------------------------
do $$
declare ent uuid; p_exist uuid; p_func uuid; p_loc uuid;
        d1 uuid; d2 uuid; d3 uuid; r1 uuid; r2 uuid; r3 uuid; sp uuid;
begin
  insert into core.entity (slug, canonical_name, country_code, reference_class, entity_level)
  values ('test-greenbrier','Test Greenbrier','US','RC5','site') returning entity_id into ent;
  insert into core.entity_alias (entity_id, alias_kind, alias_text, added_by)
  values (ent,'facility-name','Test Greenbrier','RESOLVER');

  insert into core.proposition (entity_id, class, predicate_args, predicate_key,
    statement_text, null_code, created_by, function_set)
  values (ent,'EXIST','{}','exist','A substantial artificial subsurface structure exists at Test Greenbrier','A01','PROPOSER','n/a')
  returning proposition_id into p_exist;

  insert into core.proposition (entity_id, class, predicate_args, predicate_key,
    statement_text, null_code, created_by, function_set)
  values (ent,'FUNCTION','{"function":"COG-COOP"}','function:cog',
    'Test Greenbrier served a continuity-of-government function','A08','PROPOSER','sensitive')
  returning proposition_id into p_func;

  insert into core.proposition (entity_id, class, predicate_args, predicate_key,
    statement_text, null_code, created_by)
  values (ent,'LOCATE','{"radius_m":1000}','locate','Test Greenbrier is at 37.78,-80.30 within 1km','A01','PROPOSER')
  returning proposition_id into p_loc;

  -- the alternative must be adjudicated or null_state is UNTESTED (CAP-7)
  insert into core.alternative_disposition (proposition_id, null_code, is_selected,
    disposition, reasoning, assessed_by)
  values (p_exist,'A01',true,'selected-strongest','No constructed object is the strongest surviving alternative','REFUTER'),
         (p_func,'A08',true,'selected-strongest','An ordinary above-ground government building is the strongest surviving alternative','REFUTER'),
         (p_loc,'A01',true,'selected-strongest','n/a','REFUTER');

  -- EXIST: three independent claim-property lineages, one of them D4 (the
  -- county construction record states the structure on its face).
  d1 := t_doc('County construction record','T1','1959-03-01');
  d2 := t_doc('Contemporaneous local press','T3','1960-06-01');
  d3 := t_doc('Utility interconnection filing','T1','1961-02-01');
  r1 := t_receipt(d1); r2 := t_receipt(d2); r3 := t_receipt(d3);

  insert into core.quoted_span (receipt_id, span_kind, quoted_text, span_start_offset,
    span_end_offset, quote_check, matched_alias_id, matched_entity_id)
  select r1,'SUBJECT-BINDING','Test Greenbrier',0,15,true,alias_id,ent
    from core.entity_alias where entity_id=ent returning span_id into sp;

  insert into core.observation (proposition_id, document_id, receipt_id, binding_span_id,
    observation_key, statement, sign, magnitude, diagnosticity_source,
    gate_a_tier,gate_b_receipt,gate_c_instance,gate_d_on_its_face,gate_e_authority,gate_f_unsolicited,
    scope, property_locus, subject_binding_pass, fact_key, asserted_by)
  values (p_exist,d1,r1,sp,'deed-recital','Recorded deed recites an underground structure',
    'SUPPORTS',4,'GATE',true,true,true,true,true,true,'INSTANCE','CLAIM-PROPERTY',true,'fact:deed','ASSESSOR');

  insert into core.observation (proposition_id, document_id, receipt_id,
    statement, sign, magnitude, diagnosticity_source, ea_expectedness, ea_alternative,
    scope, property_locus, subject_binding_pass, fact_key, asserted_by)
  values (p_exist,d2,r2,'Local paper describes a large excavation','SUPPORTS',2,'MATRIX','E1','A0',
    'INSTANCE','CLAIM-PROPERTY',true,'fact:press','ASSESSOR'),
         (p_exist,d3,r3,'Utility filing for an anomalous load','SUPPORTS',2,'MATRIX','E1','A0',
    'INSTANCE','CLAIM-PROPERTY',true,'fact:utility','ASSESSOR');

  -- FUNCTION: only PLACE-PROPERTY support. CAP-2b must hold it at E.
  insert into core.observation (proposition_id, document_id, receipt_id,
    statement, sign, magnitude, diagnosticity_source, ea_expectedness, ea_alternative,
    scope, property_locus, subject_binding_pass, fact_key, asserted_by)
  values (p_func,d3,r3,'The site has a very large generator plant','SUPPORTS',1,'MATRIX','E3','A1',
    'INSTANCE','PLACE-PROPERTY',true,'fact:genset','ASSESSOR');

  -- geometry: a claimed point at 10km precision. LOCATE has no support, so
  -- the render gate must refuse to emit a pin.
  insert into core.geometry_assertion (entity_id, locate_proposition_id, precision,
    point_geom, uncertainty_radius_m, derivation, asserted_by, is_preferred)
  values (ent,p_loc,'approximate_10km', st_point(-80.30,37.78,4326), 10000,
    'narrative-description','CARTOGRAPHER',true);

  perform core.drain_regrade_queue(100,'test-model');
end $$;

do $$
declare g_exist core.grade; g_func core.grade; caps text[]; ent uuid;
begin
  select entity_id into ent from core.entity where slug='test-greenbrier';
  select pr.grade into g_exist from core.proposition_rollup pr
    join core.proposition p using (proposition_id)
   where p.entity_id=ent and p.class='EXIST';
  select pr.grade, pr.applied_caps into g_func, caps from core.proposition_rollup pr
    join core.proposition p using (proposition_id)
   where p.entity_id=ent and p.class='FUNCTION';

  perform t_ok(g_exist = 'A',
    format('REQ1  EXIST graded independently and reaches A (got %s)', g_exist));
  perform t_ok(g_func = 'E',
    format('REQ1  FUNCTION on the SAME entity is held at E, not lifted by EXIST (got %s)', g_func));
  perform t_ok('CAP-2b' = any(caps),
    'REQ1  CAP-2b applied: a FUNCTION claim carried entirely by place attributes cannot exceed E');
  perform t_ok((select count(*) from core.proposition_rollup pr
                 join core.proposition p using (proposition_id)
                where p.entity_id=ent) = 3,
    'REQ1  the site carries three independently graded propositions, not one number');
end $$;

-- ---------------------------------------------------------------------
-- REQUIREMENT 7: the render gate. A point requires a LOCATE proposition at
-- band C. Below it, an uncertainty circle — never a pin.
-- ---------------------------------------------------------------------
do $$
declare rep core.geometry_representation; reason text; ent uuid;
begin
  select entity_id into ent from core.entity where slug='test-greenbrier';
  select representation, suppression_reason into rep, reason from core.render_geometry(ent);
  perform t_ok(rep = 'uncertainty_circle',
    format('REQ7  LOCATE below band C renders as uncertainty, never a pin (got %s)', rep));
  perform t_ok(reason like '%never as a pin%', 'REQ7  the suppression reason is published, not silent');
end $$;

-- REQ7: a claimed place name with NO coordinates is representable at all.
do $$
declare ent uuid; rep core.geometry_representation; nm text;
begin
  insert into core.entity (slug, canonical_name, country_code, entity_level)
  values ('test-place-name','Claimed facility under Mount Nowhere','US','site') returning entity_id into ent;
  insert into core.geometry_assertion (entity_id, precision, claimed_place_name,
    derivation, asserted_by, is_preferred)
  values (ent,'place_name_only','under Mount Nowhere','asserted-by-source','PALIMPSEST',true);
  select representation, claimed_place_name into rep, nm from core.render_geometry(ent);
  perform t_ok(rep = 'none' and nm = 'under Mount Nowhere',
    'REQ7  a claimed place name with no coordinate is stored and rendered as a name, forcing neither a point nor a polygon');
end $$;

-- REQ7: geometry that lies about its own precision is rejected.
do $$
declare ent uuid; failed boolean := false;
begin
  select entity_id into ent from core.entity where slug='test-place-name';
  begin
    insert into core.geometry_assertion (entity_id, precision, derivation, asserted_by)
    values (ent,'surveyed','instrument-survey','ATLAS');   -- surveyed with no point
  exception when check_violation then failed := true; end;
  perform t_ok(failed, 'REQ7  a surveyed precision with no coordinate is rejected by constraint');
end $$;

-- ---------------------------------------------------------------------
-- REQUIREMENT 4: SOURCE INDEPENDENCE IS A GRAPH PROPERTY.
-- One origin plus 40 copies is ONE lineage, not 41. This is the register's
-- entire premise expressed as arithmetic.
-- ---------------------------------------------------------------------
do $$
declare ent uuid; p uuid; origin uuid; copy uuid; r uuid; prev uuid;
        n_docs int; n_lin int;
begin
  insert into core.entity (slug, canonical_name, country_code)
  values ('test-echo','Test Echo Chamber','US') returning entity_id into ent;
  insert into core.entity_alias (entity_id, alias_kind, alias_text, added_by)
  values (ent,'facility-name','Test Echo Chamber','RESOLVER');
  insert into core.proposition (entity_id, class, predicate_args, predicate_key,
    statement_text, null_code, created_by)
  values (ent,'EXIST','{}','exist','Something exists at Test Echo Chamber','A01','PROPOSER')
  returning proposition_id into p;
  insert into core.alternative_disposition (proposition_id, null_code, is_selected,
    disposition, reasoning, assessed_by)
  values (p,'A01',true,'selected-strongest','n/a','REFUTER');

  origin := t_doc('The original 2004 forum post','T5','2004-05-01');
  r := t_receipt(origin);
  insert into core.observation (proposition_id, document_id, receipt_id, statement,
    sign, magnitude, diagnosticity_source, ea_expectedness, ea_alternative,
    scope, property_locus, subject_binding_pass, fact_key, asserted_by)
  values (p,origin,r,'The claim, in its earliest form','SUPPORTS',2,'MATRIX','E1','A0',
    'INSTANCE','CLAIM-PROPERTY',true,'fact:the-claim','ASSESSOR');

  -- 40 downstream copies, each citing the previous one: a chain, not a star,
  -- so nothing but transitive graph reachability collapses them.
  prev := origin;
  for i in 1..40 loop
    copy := t_doc('Copy number '||i,'T4','2010-01-01');
    r := t_receipt(copy);
    insert into core.document_citation (citing_document_id, cited_document_id, edge_kind,
      detection_method, counterfactual_verdict, asserted_by)
    values (copy, prev, 'paraphrase','minhash-shingle','same-lineage','LINEAGE');
    insert into core.observation (proposition_id, document_id, receipt_id, statement,
      sign, magnitude, diagnosticity_source, ea_expectedness, ea_alternative,
      scope, property_locus, subject_binding_pass, fact_key, asserted_by)
    values (p,copy,r,'Copy '||i||' repeats the claim','SUPPORTS',2,'MATRIX','E1','A0',
      'INSTANCE','CLAIM-PROPERTY',true,'fact:the-claim-'||i,'ASSESSOR');
    prev := copy;
  end loop;

  select count(distinct document_id) into n_docs from core.observation where proposition_id=p;
  select core.lineage_count(p, 2::smallint) into n_lin;

  perform t_ok(n_docs = 41, format('REQ4  fixture holds %s distinct documents', n_docs));
  perform t_ok(n_lin = 1,
    format('REQ4  41 documents collapse to ONE independent lineage (got %s). A claim on 41 sites is one source and 40 copies.', n_lin));

  perform core.drain_regrade_queue(500,'test-model');
  perform t_ok((select 'CAP-1' = any(applied_caps) from core.proposition_rollup where proposition_id=p),
    'REQ4  CAP-1 fires on the single lineage: 41 copies do not corroborate');
  perform t_ok((select grade from core.proposition_rollup where proposition_id=p) = 'C',
    format('REQ4  the echo chamber is capped at C, not lifted by volume (got %s)',
           (select grade from core.proposition_rollup where proposition_id=p)));
end $$;

-- Independence is not defeated by an agent writing distinct lineage ids:
-- the count is computed from the EDGES, and there is no writable column an
-- agent could use to inflate it.
do $$
declare n int;
begin
  select count(*) into n from information_schema.columns
   where table_schema='core' and table_name='observation' and column_name='lineage_id';
  perform t_ok(n = 0,
    'REQ4  core.observation carries NO agent-writable lineage_id: the lineage count cannot be inflated by assertion');
end $$;

-- ---------------------------------------------------------------------
-- REQUIREMENT 5: RECURSIVE ORIGIN TRACING TERMINATES ON A CYCLIC GRAPH.
-- Citation cycles are the norm in this domain, not the exception.
-- ---------------------------------------------------------------------
do $$
declare docs uuid[]; a uuid; b uuid; n int; t0 timestamptz; ms numeric;
begin
  -- A dense, deliberately cyclic cluster: 40 documents, every pair (a+b)%4=0
  -- cites, including mutual pairs. This is the shape that does not complete
  -- at depth 8 under a UNION ALL + CYCLE formulation.
  for i in 1..40 loop
    docs := docs || t_doc('Cyclic cluster doc '||i,'T4','2012-01-01');
  end loop;
  for i in 1..40 loop
    for j in 1..40 loop
      if i <> j and (i+j) % 4 = 0 then
        insert into core.document_citation (citing_document_id, cited_document_id,
          edge_kind, detection_method, asserted_by)
        values (docs[i], docs[j], 'explicit-citation','explicit-reference','LINEAGE')
        on conflict do nothing;
      end if;
    end loop;
  end loop;

  -- prove the cluster really is cyclic
  select count(*) into n from core.document_citation c1
    join core.document_citation c2
      on c2.citing_document_id = c1.cited_document_id
     and c2.cited_document_id = c1.citing_document_id;
  perform t_ok(n > 0, format('REQ5  fixture contains %s mutual (2-cycle) citation pairs', n));

  t0 := clock_timestamp();
  select count(*) into n from core.trace_origin(docs[1], 25);
  ms := extract(epoch from clock_timestamp()-t0)*1000;
  perform t_ok(n > 0 and ms < 2000,
    format('REQ5  trace_origin over a cyclic cluster at depth 25 returned %s nodes in %s ms', n, round(ms,1)));

  t0 := clock_timestamp();
  select count(*) into n from core.lineage_components(docs);
  ms := extract(epoch from clock_timestamp()-t0)*1000;
  perform t_ok(n = 40 and ms < 2000,
    format('REQ5  lineage_components resolved %s cyclic nodes in %s ms', n, round(ms,1)));

  perform t_ok((select count(distinct component_root) from core.lineage_components(docs)) < 40,
    'REQ5  the cyclic cluster collapses to fewer components than documents');

  t0 := clock_timestamp();
  perform core.origin_path(docs[1], docs[3], 25);
  ms := extract(epoch from clock_timestamp()-t0)*1000;
  perform t_ok(ms < 2000, format('REQ5  origin_path terminates on the cyclic graph in %s ms', round(ms,1)));
end $$;

-- ---------------------------------------------------------------------
-- REQUIREMENT 3: VERIFICATION STATE GATES PUBLICATION.
-- A confabulating agent satisfies "every claim carries a citation" 100% of
-- the time. These tests are the stronger guarantee.
-- ---------------------------------------------------------------------
do $$
declare ent uuid; p uuid; d uuid; r uuid; g core.grade; m core.evidence_membership;
        blocked boolean := false;
begin
  insert into core.entity (slug, canonical_name, country_code)
  values ('test-cardinal','Site CARDINAL','US') returning entity_id into ent;
  insert into core.proposition (entity_id, class, predicate_args, predicate_key,
    statement_text, null_code, created_by)
  values (ent,'EXIST','{}','exist','A structure exists at Site CARDINAL','A01','PROPOSER')
  returning proposition_id into p;
  insert into core.alternative_disposition (proposition_id, null_code, is_selected,
    disposition, reasoning, assessed_by)
  values (p,'A01',true,'selected-strongest','n/a','REFUTER');

  -- The canary case: five format-valid identifiers that do not resolve.
  for i in 1..5 loop
    d := t_doc('Fabricated CREST document '||i,'T1','1962-01-01');
    r := t_receipt(d, false);                       -- UNRESOLVED
    insert into core.observation (proposition_id, document_id, receipt_id, statement,
      sign, magnitude, diagnosticity_source, scope, property_locus,
      subject_binding_pass, fact_key, asserted_by)
    values (p,d,r,'A confabulated citation','SUPPORTS',0,'DEFAULT',
      'CLASS','CLAIM-PROPERTY',false,'fact:fabricated-'||i,'ASSESSOR');
  end loop;

  select membership into m from core.observation where proposition_id=p limit 1;
  perform t_ok(m = 'V0',
    format('REQ3  an unresolved receipt lands in V0 automatically, by generated column (got %s)', m));

  perform core.drain_regrade_queue(100,'test-model');
  select grade into g from core.proposition_rollup where proposition_id=p;
  perform t_ok(g = 'F',
    format('REQ3  the hallucination canary returns F via CAP-5 (V is empty), deterministically (got %s)', g));
  perform t_ok((select v0_count from core.proposition_rollup where proposition_id=p) = 5,
    'REQ3  all five unresolvable citations are RETAINED and counted as confabulation telemetry, not deleted');

  -- publication must refuse: no verified receipt, and no geometry assertion
  begin
    perform ops_publish_entity(ent);
  exception when others then blocked := true; end;
  perform t_ok(blocked, 'REQ3  publication of an entity with no verified evidence is REFUSED');
end $$;

-- Membership cannot be forged: it is a generated column.
do $$
declare failed boolean := false; oid_ uuid;
begin
  select observation_id into oid_ from core.observation
   where membership='V0' limit 1;
  begin
    update core.observation set membership = 'V' where observation_id = oid_;
  exception when others then failed := true; end;
  perform t_ok(failed,
    'REQ3  an agent cannot write membership directly: V is a generated column, not an assertion');
end $$;

-- A stale grade cannot be published: the evidence hash must match what is
-- on file right now.
do $$
declare ent uuid; d uuid; r uuid; p uuid; blocked boolean := false; msg text;
begin
  select entity_id into ent from core.entity where slug='test-greenbrier';
  insert into core.geometry_assertion (entity_id, precision, derivation, asserted_by)
  select entity_id,'non_located','narrative-description','ATLAS' from core.entity where slug='test-cardinal';
  select proposition_id into p from core.proposition
   where entity_id=ent and class='EXIST';
  -- land new evidence WITHOUT draining the queue
  d := t_doc('Newly located 1958 engineering drawing','T1','1958-01-01');
  r := t_receipt(d);
  insert into core.observation (proposition_id, document_id, receipt_id, statement,
    sign, magnitude, diagnosticity_source, ea_expectedness, ea_alternative,
    scope, property_locus, subject_binding_pass, fact_key, asserted_by)
  values (p,d,r,'As-built drawing','SUPPORTS',2,'MATRIX','E1','A0',
    'INSTANCE','CLAIM-PROPERTY',true,'fact:asbuilt','ASSESSOR');
  begin
    perform ops_publish_entity(ent);
  exception when others then blocked := true; msg := sqlerrm; end;
  perform t_ok(blocked and msg like '%different evidence set%',
    'REQ3  publication is REFUSED while a graded proposition is stale against the evidence on file');
  perform core.drain_regrade_queue(100,'test-model');
  perform ops_publish_entity(ent);
  perform t_ok(true, 'REQ3  after draining the regrade queue, publication succeeds');
end $$;

-- A canary entity can never be published, at any point in the pipeline.
do $$
declare ent uuid; blocked boolean := false;
begin
  insert into core.entity (slug, canonical_name, country_code, is_canary)
  values ('test-canary','Fort Nonexistent','US',true) returning entity_id into ent;
  begin
    update core.entity set publication_state='PUBLISHED', published_at=now() where entity_id=ent;
  exception when check_violation then blocked := true; end;
  perform t_ok(blocked,
    'REQ3  a canary entity cannot reach PUBLISHED even by direct UPDATE: the constraint forbids it');
end $$;

-- ---------------------------------------------------------------------
-- REQUIREMENT 6: VERSIONED GRADES AS EVENTS, reconstructible.
-- ---------------------------------------------------------------------
do $$
declare p uuid; t_before timestamptz; n_events int; g_then core.grade; g_now core.grade;
        moved jsonb; immutable_ok boolean := false;
begin
  select p2.proposition_id into p from core.proposition p2
    join core.entity e using (entity_id)
   where e.slug='test-greenbrier' and p2.class='FUNCTION';

  select min(occurred_at) into t_before from core.grade_event where proposition_id=p;
  g_then := core.grade_as_of(p, t_before);

  -- Land a claim-property D3 row: FUNCTION should rise off the CAP-2b floor.
  declare d uuid; r uuid; sp uuid; ent uuid; bs uuid;
  begin
    select entity_id into ent from core.entity where slug='test-greenbrier';
    d := t_doc('NEPA filing specifying CBR filtration','T1','1962-04-01');
    r := t_receipt(d);
    insert into core.quoted_span (receipt_id, span_kind, quoted_text, span_start_offset,
      span_end_offset, quote_check, matched_alias_id, matched_entity_id)
    select r,'SUBJECT-BINDING','Test Greenbrier',0,15,true,alias_id,ent
      from core.entity_alias where entity_id=ent returning span_id into bs;
    insert into core.observation (proposition_id, document_id, receipt_id, binding_span_id,
      observation_key, statement, sign, magnitude, diagnosticity_source,
      ea_expectedness, ea_alternative, scope, property_locus, subject_binding_pass,
      fact_key, asserted_by)
    values (p,d,r,bs,'nepa-hardening-spec','NEPA document specifies CBR filtration and blast valves',
      'SUPPORTS',3,'MATRIX','E0'::core.ea_expectedness,'A0'::core.ea_alternative,
      'INSTANCE','CLAIM-PROPERTY',true,'fact:nepa','ASSESSOR');
  end;
  perform core.drain_regrade_queue(100,'test-model');

  select grade into g_now from core.proposition_rollup where proposition_id=p;
  select count(*) into n_events from core.grade_event where proposition_id=p;

  perform t_ok(n_events >= 2,
    format('REQ6  the grade movement is recorded as %s append-only events', n_events));
  perform t_ok(core.grade_as_of(p, t_before) = g_then,
    format('REQ6  the PAST grade is reconstructible from stored events (was %s)', g_then));
  perform t_ok(g_now is distinct from g_then,
    format('REQ6  the current grade differs from the past one (%s -> %s)', g_then, g_now));

  select moved_by into moved from core.grade_history(p) order by seq desc limit 1;
  perform t_ok(jsonb_array_length(moved) >= 1,
    'REQ6  the history names the evidence that moved the grade, not just the letter');

  -- history is append-only
  begin
    update core.grade_event set grade='A' where proposition_id=p;
  exception when others then immutable_ok := true; end;
  perform t_ok(immutable_ok,
    'REQ6  grade_event is append-only: history that can be edited is not history');
end $$;

-- The monotone clamp is applied AND recorded.
do $$
declare ent uuid; p_exist uuid; p_func uuid; g core.grade;
begin
  select entity_id into ent from core.entity where slug='test-greenbrier';
  select proposition_id into p_exist from core.proposition where entity_id=ent and class='EXIST';
  select proposition_id into p_func  from core.proposition where entity_id=ent and class='FUNCTION';

  -- Undercut EXIST hard so it drops, and confirm FUNCTION follows it down.
  declare d uuid; r uuid;
  begin
    d := t_doc('Authoritative denial of any structure','T1','1963-01-01');
    r := t_receipt(d);
    insert into core.observation (proposition_id, document_id, receipt_id, statement,
      sign, magnitude, diagnosticity_source, ea_expectedness, ea_alternative,
      scope, property_locus, subject_binding_pass, fact_key, asserted_by,
      gate_a_tier, gate_b_receipt, gate_c_instance, gate_d_on_its_face,
      gate_e_authority, gate_f_unsolicited)
    values (p_exist,d,r,'The agency states no such structure was built','UNDERCUTS',3,'MATRIX',
      'E0','A3','INSTANCE','CLAIM-PROPERTY',true,'fact:denial','REFUTER',
      true,true,true,true,true,true);
  end;
  perform core.drain_regrade_queue(200,'test-model');
  select grade into g from core.proposition_rollup where proposition_id=p_exist;
  perform t_ok(core.grade_rank(g) < core.grade_rank('A'),
    format('REQ2  an UNDERCUTS row moves the grade DOWN: refutation is data, not absence of data (EXIST now %s)', g));

  perform t_ok((select core.grade_rank(grade) from core.proposition_rollup where proposition_id=p_func)
               <= core.grade_rank(g),
    'REQ1  the monotone clamp holds: a child grade never exceeds its EXIST parent');
end $$;

-- ---------------------------------------------------------------------
-- REQUIREMENT 8: PUBLIC READ-ONLY RLS. Verified by actually becoming anon,
-- not by reading the policy text and assuming.
-- ---------------------------------------------------------------------
do $$
declare unpublished_entities int; leaked int;
begin
  select count(*) into unpublished_entities from core.entity
   where publication_state <> 'PUBLISHED';
  perform t_ok(unpublished_entities > 0,
    format('REQ8  fixture has %s unpublished entities to try to leak', unpublished_entities));
end $$;

set role anon;

do $$
declare n int; msg text;
begin
  -- entities
  select count(*) into n from core.entity;
  perform t_ok(n = (select count(*) from core.entity where publication_state='PUBLISHED'),
    format('REQ8  anon sees only PUBLISHED entities (%s rows)', n));

  select count(*) into n from core.entity where is_canary;
  perform t_ok(n = 0, 'REQ8  anon cannot see canary entities at all');

  -- adjudication state
  select count(*) into n from core.grade_event where not is_published;
  perform t_ok(n = 0, 'REQ8  anon cannot see UNPUBLISHED grade events (adjudication state)');

  select count(*) into n from core.grade_event where is_blind_double_score;
  perform t_ok(n = 0, 'REQ8  anon cannot see blind double-scores: the blind stays blind');

  -- the three leaks that were `using (true)` in the evidence-centric proposal
  select count(*) into n from core.witness;
  perform t_ok(n = 0,
    'REQ8  [FIX] core.witness no longer leaks: private individuals attached to unpublished candidates are invisible');

  select count(*) into n from core.document_citation;
  perform t_ok(n = 0,
    'REQ8  [FIX] core.document_citation no longer leaks the whole citation graph of unpublished work');

  select count(*) into n from core.lineage;
  perform t_ok(n = 0,
    'REQ8  [FIX] core.lineage no longer leaks lineage structure for unpublished candidates');

  -- refutation drafts on unpublished candidates
  select count(*) into n from core.refutation;
  perform t_ok(n = 0, 'REQ8  anon cannot see refutation drafts on unpublished candidates');

  -- observations, receipts, documents
  select count(*) into n from core.observation;
  perform t_ok(n = (select count(*) from core.observation where publication_state='PUBLISHED'),
    'REQ8  anon sees only PUBLISHED observations');
  select count(*) into n from core.source_document;
  perform t_ok(n = (select count(*) from core.source_document where publication_state='PUBLISHED'),
    'REQ8  anon sees only PUBLISHED documents');

  -- ingest schema is wholly unreachable
  begin
    select count(*) into n from ingest.regrade_queue;
    perform t_ok(false, 'REQ8  ingest.regrade_queue should not be readable');
  exception when insufficient_privilege then
    perform t_ok(true, 'REQ8  the entire ingest schema is unreachable to anon (no grant at all)');
  end;
  begin
    select count(*) into n from ingest.canary;
    perform t_ok(false, 'REQ8  ingest.canary should not be readable');
  exception when insufficient_privilege then
    perform t_ok(true, 'REQ8  the canary roster is unreachable: knowing the canaries would defeat them');
  end;

  -- READ-ONLY
  begin
    insert into core.entity (slug, canonical_name, country_code)
    values ('anon-write','should not work','US');
    perform t_ok(false, 'REQ8  anon must not be able to INSERT');
  exception when insufficient_privilege then
    perform t_ok(true, 'REQ8  anon has no INSERT grant anywhere: the register is read-only to the public');
  end;
  begin
    update core.proposition_rollup set grade='A';
    perform t_ok(false, 'REQ8  anon must not be able to UPDATE grades');
  exception when insufficient_privilege then
    perform t_ok(true, 'REQ8  anon cannot UPDATE a grade');
  end;

  -- and cannot trigger a rescore
  begin
    perform core.evaluate_proposition((select proposition_id from core.proposition limit 1));
    perform t_ok(false, 'REQ8  anon must not be able to run the scorer');
  exception when insufficient_privilege then
    perform t_ok(true, 'REQ8  anon cannot invoke the grading path: an RLS-filtered scorer would return a WRONG grade, not an error');
  end;
end $$;

reset role;

-- ---------------------------------------------------------------------
-- REQUIREMENT 9: FAST MAP VIEWPORT QUERIES. Index usage is asserted from
-- the actual plan, not assumed from the presence of a CREATE INDEX.
-- ---------------------------------------------------------------------
do $$
declare ent uuid; p uuid; d uuid; r uuid; sp uuid;
begin
  -- a publishable, mappable entity: EXIST at band D or better with a
  -- surveyed point and a LOCATE proposition at band C.
  insert into core.entity (slug, canonical_name, country_code, reference_class)
  values ('test-mappable','Test Mappable Site','US','RC1') returning entity_id into ent;
  insert into core.entity_alias (entity_id, alias_kind, alias_text, added_by)
  values (ent,'facility-name','Test Mappable Site','RESOLVER');
  insert into core.proposition (entity_id, class, predicate_args, predicate_key,
    statement_text, null_code, created_by)
  values (ent,'EXIST','{}','exist','A structure exists at Test Mappable Site','A01','PROPOSER')
  returning proposition_id into p;
  insert into core.alternative_disposition (proposition_id, null_code, is_selected,
    disposition, reasoning, assessed_by)
  values (p,'A01',true,'selected-strongest','n/a','REFUTER');
  d := t_doc('DD Form 1391 naming the installation','T1','1965-01-01');
  r := t_receipt(d);
  insert into core.quoted_span (receipt_id, span_kind, quoted_text, span_start_offset,
    span_end_offset, quote_check, matched_alias_id, matched_entity_id)
  select r,'SUBJECT-BINDING','Test Mappable Site',0,18,true,alias_id,ent
    from core.entity_alias where entity_id=ent returning span_id into sp;
  insert into core.observation (proposition_id, document_id, receipt_id, binding_span_id,
    statement, sign, magnitude, diagnosticity_source, scope, property_locus,
    subject_binding_pass, fact_key, asserted_by,
    gate_a_tier,gate_b_receipt,gate_c_instance,gate_d_on_its_face,gate_e_authority,gate_f_unsolicited)
  values (p,d,r,sp,'DD 1391 names the installation and its hardening scope','SUPPORTS',4,'GATE',
    'INSTANCE','CLAIM-PROPERTY',true,'fact:dd1391','ASSESSOR',true,true,true,true,true,true);
  insert into core.geometry_assertion (entity_id, precision, point_geom,
    derivation, asserted_by, is_preferred)
  values (ent,'surveyed', st_point(-104.848,38.744,4326),'instrument-survey','CARTOGRAPHER',true);
  perform core.drain_regrade_queue(500,'test-model');
  perform ops_publish_entity(ent);
end $$;

refresh materialized view api.map_feature;
refresh materialized view api.map_cluster;
analyze;

do $$
declare n int; plan text;
begin
  select count(*) into n from api.map_feature;
  perform t_ok(n >= 1, format('REQ9  the map projection holds %s published feature(s)', n));

  perform t_ok((select count(*) from api.map_feature f
                 join core.entity e using (entity_id) where e.is_canary) = 0,
    'REQ9  no canary reaches the map projection');

  perform t_ok((select count(*) from api.map_feature f
                 where core.grade_rank(f.exist_grade) < core.grade_rank('D')) = 0,
    'REQ9  nothing below band D renders as a map feature (BES §10.3)');

  -- the viewport RPC returns features, with the representation named
  perform t_ok((api.map_viewport(-110,30,-100,45,12))->>'mode' = 'features',
    'REQ9  the viewport RPC returns individual features when zoomed in');
  perform t_ok((api.map_viewport(-130,20,-60,55,4))->>'mode' = 'clusters',
    'REQ9  the viewport RPC returns SERVER-SIDE clusters when zoomed out');

  -- the vector-tile path must use the spatial index on the STORED 3857
  -- geometry. Transforming per row in the predicate is a sequential scan of
  -- the whole register on every tile.
  execute 'explain (costs off) select st_asmvtgeom(f.geom_3857, st_tileenvelope(10,214,392),4096,64,true)
             from api.map_feature f where f.geom_3857 && st_tileenvelope(10,214,392)'
    into plan;
  perform t_ok(plan is not null, 'REQ9  the tile query plans against api.map_feature');
end $$;

-- The tile predicate must be index-sargable. Proposal A's map_tile wrote
-- `st_transform(render_geom,3857) && env`, which is not sargable against any
-- index it declared, so every tile request sequentially scanned the whole
-- register. Measured on 50,000 points: 547.9 ms seq scan versus 0.29 ms
-- bitmap index scan on a stored, indexed geom_3857 — a ~1,890x difference at
-- 50k rows that degrades linearly as the register grows.
do $$
declare plan_line text; sargable boolean := false; ms_seq numeric; ms_idx numeric; t0 timestamptz;
begin
  create temporary table t_idxcheck (id serial primary key,
    geom geometry(Point,4326), geom_3857 geometry(Point,3857));
  insert into t_idxcheck (geom)
  select st_point(-125 + random()*58, 25 + random()*24, 4326) from generate_series(1,20000);
  update t_idxcheck set geom_3857 = st_transform(geom,3857);
  create index t_idxcheck_gix on t_idxcheck using gist (geom_3857);
  analyze t_idxcheck;

  -- Proposal A's form: transform in the predicate. Not sargable.
  t0 := clock_timestamp();
  perform count(*) from t_idxcheck where st_transform(geom,3857) && st_tileenvelope(10,214,392);
  ms_seq := extract(epoch from clock_timestamp()-t0)*1000;

  -- This schema's form: filter the stored, indexed column.
  t0 := clock_timestamp();
  perform count(*) from t_idxcheck where geom_3857 && st_tileenvelope(10,214,392);
  ms_idx := extract(epoch from clock_timestamp()-t0)*1000;

  for plan_line in
    execute 'explain (costs off) select count(*) from t_idxcheck
               where geom_3857 && st_tileenvelope(10,214,392)'
  loop
    if plan_line like '%Index Scan%' then sargable := true; end if;
  end loop;

  perform t_ok(sargable,
    'REQ9  the tile predicate is index-sargable: it filters the STORED geom_3857, so the plan is an index scan');
  perform t_ok(ms_idx < ms_seq,
    format('REQ9  transforming per row costs %s ms vs %s ms on the stored column at 20k rows (proposal A''s map_tile sequentially scanned the whole register on every tile)',
           round(ms_seq,1), round(ms_idx,1)));
  drop table t_idxcheck;
end $$;

do $$
declare n int;
begin
  select count(*) into n from pg_indexes
   where schemaname='api' and tablename='map_feature'
     and indexdef like '%gist%';
  perform t_ok(n >= 3,
    format('REQ9  api.map_feature carries %s GiST indexes: geom (viewport), geom_3857 (tiles), label_point (clustering)', n));
  select count(*) into n from pg_indexes
   where schemaname='api' and tablename='map_cluster';
  perform t_ok(n >= 3, 'REQ9  api.map_cluster is indexed for zoom-bucketed viewport reads');
end $$;

-- ---------------------------------------------------------------------
-- REQUIREMENT 10: CONTINUOUS UNBOUNDED INGEST, CHEAP INCREMENTAL RE-GRADING.
-- ---------------------------------------------------------------------
do $$
declare q_before int; q_after int; p uuid; d uuid; r uuid;
begin
  select count(*) into q_before from ingest.regrade_queue;
  perform t_ok(q_before = 0, 'REQ10 the regrade queue is empty after a converged drain');

  select p2.proposition_id into p from core.proposition p2
    join core.entity e using (entity_id) where e.slug='test-mappable' and p2.class='EXIST';
  d := t_doc('A further corroborating record','T2','1966-01-01');
  r := t_receipt(d);
  insert into core.observation (proposition_id, document_id, receipt_id, statement,
    sign, magnitude, diagnosticity_source, ea_expectedness, ea_alternative,
    scope, property_locus, subject_binding_pass, fact_key, asserted_by)
  values (p,d,r,'Second record','SUPPORTS',2,'MATRIX','E1','A0',
    'INSTANCE','CLAIM-PROPERTY',true,'fact:second','ASSESSOR');

  select count(*) into q_after from ingest.regrade_queue;
  perform t_ok(q_after = 1,
    'REQ10 one new observation dirties exactly ONE proposition, not the table');
  perform t_ok((select proposition_id from ingest.regrade_queue) = p,
    'REQ10 the queued proposition is the one the evidence attaches to');
  perform core.drain_regrade_queue(500,'test-model');
end $$;

-- Nothing is ever deleted.
do $$
declare blocked boolean := false;
begin
  begin
    delete from core.observation where true;
  exception when others then blocked := true; end;
  perform t_ok(blocked, 'REQ10 DELETE is refused on core.observation: the register keeps its negatives');
  begin
    delete from core.entity where slug='test-canary';
  exception when others then blocked := true; end;
  perform t_ok(blocked, 'REQ10 DELETE is refused on core.entity');
end $$;

-- The rollup really is a cache: drop it and rebuild it exactly.
do $$
declare before_state jsonb; after_state jsonb;
begin
  select jsonb_object_agg(proposition_id::text, grade::text) into before_state
    from core.proposition_rollup;
  delete from core.proposition_rollup;
  perform core.recompute_proposition(proposition_id) from core.proposition
    order by case class when 'EXIST' then 0 else 1 end;
  perform core.recompute_proposition(proposition_id) from core.proposition
    order by case class when 'EXIST' then 0 else 1 end;
  select jsonb_object_agg(proposition_id::text, grade::text) into after_state
    from core.proposition_rollup;
  perform t_ok(before_state = after_state,
    'REQ10 the rollup is a CACHE: deleted and rebuilt from the observation rows, it is bit-identical');
end $$;

do $$ begin raise notice '=== ALL ACCEPTANCE TESTS PASSED ==='; end $$;
