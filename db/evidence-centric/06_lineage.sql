-- =====================================================================
-- SECTION 06 — THE CITATION GRAPH, LINEAGES, AND ORIGIN TRACING
--
-- Hard requirements 5 and 6.
--
-- "A claim on 400 websites is not 400 sources; it is one source and 399
-- copies, and the register must say so." Saying so is a GRAPH PROPERTY, not
-- a COUNT(*). Everything in this section exists to answer one question:
-- how many genuinely independent lineages support this proposition?
--
-- The graph is CYCLIC in the real world. Citogenesis loops are literally
-- cycles: a T3 publication rests on unattributable T5 testimony and is then
-- cited as though primary by a source the T5 later cites back. Every
-- traversal below terminates explicitly — CYCLE clause plus a depth cap,
-- belt and braces, because an unterminated recursive CTE in an ingest cron
-- is an outage.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A lineage is a connected component of the derivation graph, after the
-- collapse rules. It is computed, then MATERIALISED here so that grade
-- events can pin the lineage assignment that was in force when they ran.
-- ---------------------------------------------------------------------
create table core.lineage (
  lineage_id     bigint generated always as identity primary key,
  label          text,
  terminus_document_id uuid references core.source_document(document_id),
  terminus_kind  text not null default 'document' check (terminus_kind in
                   ('document','witness','agent-model-family','compiler','unknown')),
  -- BES §5.1.2: all findings from agents sharing a base model are ONE
  -- lineage, capped at 1 by construction. N prompts over one set of weights
  -- is one witness speaking N times in different words.
  agent_model_family text,
  first_appearance_date date,
  computed_at    timestamptz not null default now(),
  computation_version text not null default 'lineage-0.2.0'
);
create unique index lineage_one_per_model_family
  on core.lineage(agent_model_family) where agent_model_family is not null;

alter table core.source_document
  add constraint document_lineage_fk foreign key (lineage_id)
  references core.lineage(lineage_id);

-- Which rule assigned this document to this lineage: auditability of the
-- collapse itself (BES §5.1.1-8).
create table core.lineage_membership (
  document_id   uuid not null references core.source_document(document_id) on delete restrict,
  lineage_id    bigint not null references core.lineage(lineage_id),
  rule_applied  text not null check (rule_applied in
                  ('same-author-org-publication','model-family-collapse',
                   'transparent-compiler-passthrough','opaque-compiler-terminus',
                   'replication-not-independence','semantic-cluster',
                   'counterfactual-same','counterfactual-distinct',
                   'self-exclusion-quarantine','default-same-under-uncertainty')),
  decided_by    text not null,
  decided_at    timestamptz not null default now(),
  quorum_votes  jsonb not null default '[]'::jsonb,  -- across model families
  disagreement  boolean not null default false,      -- logged, never hidden
  primary key (document_id, lineage_id)
);
create index lineage_membership_lineage_idx on core.lineage_membership(lineage_id);

-- ---------------------------------------------------------------------
-- THE CITATION GRAPH. Sources cite sources. Directed, cyclic, typed.
-- ---------------------------------------------------------------------
create table core.document_citation (
  citation_id   bigint generated always as identity primary key,
  citing_document_id uuid not null references core.source_document(document_id) on delete restrict,
  cited_document_id  uuid not null references core.source_document(document_id) on delete restrict,

  edge_kind     text not null check (edge_kind in
                  ('explicit-citation',      -- names it
                   'mirror-of',              -- faithful mirror, same bytes
                   'replication',            -- database replication of geometry/records
                   'paraphrase',             -- same strings, reworded
                   'semantic-derivation',    -- regeneration: shares no strings, cites nothing
                   'compiler-exposes',       -- transparent compiler -> its primary
                   'quotes-testimony')),     -- asserter -> quoted person

  detection_method text not null check (detection_method in
                     ('explicit-reference','minhash-shingle','semantic-cluster',
                      'wayback-cdx-digest','first-observation-dating','manual','quorum')),
  similarity     double precision check (similarity between 0 and 1),

  -- BES §5.1.7, one of exactly TWO surviving judgement calls in the model.
  -- "Would this source have produced this claim if the prior source had
  -- never existed?" Default under uncertainty is SAME lineage.
  counterfactual_verdict text not null default 'same-lineage'
    check (counterfactual_verdict in ('same-lineage','independent','undetermined')),
  quorum_votes   jsonb not null default '[]'::jsonb,
  quorum_disagreement boolean not null default false,

  -- Does this edge collapse the two documents into one lineage?
  -- compiler-exposes does NOT: a critical edition citing forty Signal
  -- Agency documents is forty lineages, and the compiler is neither counted
  -- nor penalised (BES §5.1.3 — this is what drags PEF Cartwheel out of D).
  collapses_lineage boolean generated always as (
    edge_kind <> 'compiler-exposes'
    and counterfactual_verdict <> 'independent'
  ) stored,

  asserted_by   text not null,
  asserted_at   timestamptz not null default now(),
  retracted_at  timestamptz,
  note          text,
  check (citing_document_id <> cited_document_id),
  unique (citing_document_id, cited_document_id, edge_kind)
);
create index citation_citing_idx on core.document_citation(citing_document_id)
  where retracted_at is null;
create index citation_cited_idx  on core.document_citation(cited_document_id)
  where retracted_at is null;
create index citation_collapse_idx on core.document_citation(citing_document_id, cited_document_id)
  where collapses_lineage and retracted_at is null;

-- ---------------------------------------------------------------------
-- ORIGIN TRACE. Cycle-safe by construction.
--
-- Walks the graph backwards from a document toward its earliest traceable
-- appearance. Returns the full path so the interface can render it, plus
-- an explicit is_cycle flag on the edge that closed a loop. PostgreSQL's
-- CYCLE clause (14+) stops traversal at the repeat; max_depth is a second
-- independent stop so a pathological graph cannot pin a worker.
-- ---------------------------------------------------------------------
create or replace function core.trace_origin(
  p_document_id uuid,
  p_max_depth   integer default 24
)
returns table (
  depth integer,
  document_id uuid,
  title text,
  origin_tier core.origin_tier,
  document_date date,
  first_observed_date date,
  edge_kind text,
  path uuid[],
  is_cycle boolean,
  is_terminus boolean
)
language sql stable parallel safe as $$
  -- Two independent termination guarantees:
  --   (a) the SQL-standard CYCLE clause, which stops the moment a
  --       document_id repeats on the current branch;
  --   (b) an explicit depth cap.
  -- The visible uuid[] path is maintained by hand because the CYCLE
  -- clause's own path column is an array of row-records, not of uuids.
  with recursive walk (depth, document_id, edge_kind, seen) as (
      select 0, p_document_id, null::text, array[p_document_id]
    union all
      select w.depth + 1, dc.cited_document_id, dc.edge_kind,
             w.seen || dc.cited_document_id
        from walk w
        join core.document_citation dc
          on dc.citing_document_id = w.document_id
         and dc.retracted_at is null
       where w.depth < p_max_depth
  ) cycle document_id set cycle_hit using cycle_path
  select w.depth,
         w.document_id,
         d.title,
         d.origin_tier,
         d.document_date,
         d.first_observed_date,
         w.edge_kind,
         w.seen,
         w.cycle_hit,
         not exists (select 1 from core.document_citation x
                      where x.citing_document_id = w.document_id
                        and x.retracted_at is null) as is_terminus
    from walk w
    join core.source_document d using (document_id)
$$;

comment on function core.trace_origin is
  'Cycle-safe backward traversal of the citation graph. CYCLE clause terminates on repeat; p_max_depth is an independent second stop. is_cycle marks the edge that closed the loop rather than hiding it.';

-- The earliest traceable appearance of a claim: the ORIGIN proposition's
-- factual content. Prefers a receipted document date, falls back to first
-- observation (Wayback CDX collapse=digest).
create or replace function core.claim_origin(p_claim_id uuid, p_max_depth integer default 24)
returns table (
  document_id uuid, title text, origin_tier core.origin_tier,
  effective_date date, dating_basis text, reached_via_cycle boolean
)
language sql stable as $$
  with seeds as (
    select distinct o.document_id
      from core.observation o
      join core.proposition p on p.proposition_id = o.proposition_id
     where p.claim_id = p_claim_id and o.document_id is not null
  ),
  walked as (
    select t.* from seeds s
    cross join lateral core.trace_origin(s.document_id, p_max_depth) t
  )
  select w.document_id, w.title, w.origin_tier,
         coalesce(w.document_date, w.first_observed_date) as effective_date,
         case when w.document_date is not null then 'document-date'
              when w.first_observed_date is not null then 'first-observation'
              else 'undated' end as dating_basis,
         bool_or(w.is_cycle) over (partition by w.document_id) as reached_via_cycle
    from walked w
   where w.is_terminus or w.is_cycle
   order by coalesce(w.document_date, w.first_observed_date) nulls last
$$;

-- ---------------------------------------------------------------------
-- CONNECTED COMPONENTS over the collapsing subgraph.
--
-- This is how "independent lineage" is actually computed. A recursive CTE
-- cannot compute components on a cyclic undirected graph without either
-- exploding or terminating early, so this is an explicit iterative
-- label-propagation with a bounded iteration count. Deterministic,
-- terminating, and auditable — which matters more here than elegance.
-- ---------------------------------------------------------------------
create or replace function core.lineage_components(p_document_ids uuid[])
returns table (document_id uuid, component_root uuid)
language sql stable parallel safe as $$
  with recursive
  -- Lineage identity is UNDIRECTED even though citation is not: if B copied
  -- A, they are one lineage whichever end you start from.
  undirected as (
    select citing_document_id as a, cited_document_id as b
      from core.document_citation
     where collapses_lineage and retracted_at is null
    union all
    select cited_document_id, citing_document_id
      from core.document_citation
     where collapses_lineage and retracted_at is null
  ),
  -- UNION (not UNION ALL) is the termination guarantee: the recursive term
  -- deduplicates (seed, node) pairs, so on a finite graph the working set
  -- empties in at most |V| iterations no matter how many cycles exist.
  -- Citogenesis loops ARE cycles; this is the code path that survives them.
  reach (seed, node) as (
      select d, d from unnest(p_document_ids) d
    union
      select r.seed, u.b
        from reach r
        join undirected u on u.a = r.node
  )
  -- PostgreSQL has no min(uuid); order on the text rendering. Any total
  -- order works — the root only has to be stable and order-independent.
  select r.seed, min(r.node::text)::uuid as component_root
    from reach r
   group by r.seed
$$;

comment on function core.lineage_components is
  'Connected components of the collapsing subgraph. UNION-dedup terminates on cyclic graphs by construction; the component root is the minimum reachable document_id, which is stable and order-independent.';

-- ---------------------------------------------------------------------
-- L(Dk): the count of DISTINCT INDEPENDENT LINEAGES containing at least one
-- V-member observation at diagnosticity >= k, after fact-key merge.
--
-- Four collapses happen here, in order, and the order matters:
--   1. membership filter        (BES §2.4)  — only V rows count
--   2. fact-key merge           (BES §5.5)  — one fact is one lineage even
--                                             through four record types
--   3. model-family collapse    (BES §5.1.2)— all one-family agent findings
--                                             become a single lineage
--   4. graph component collapse (BES §5.1.6-7) — copies, paraphrase,
--                                             regeneration, replication
-- ---------------------------------------------------------------------
create or replace function core.independent_lineages(
  p_proposition_id uuid,
  p_min_magnitude  smallint default 2
)
returns table (
  lineage_key text,
  lineage_kind text,
  best_magnitude smallint,
  observation_count integer,
  representative_document_id uuid,
  representative_title text,
  origin_tier core.origin_tier
)
language sql stable as $$
  with v as (
    select o.*, d.agent_model_family, d.title, d.origin_tier as tier
      from core.observation o
      left join core.source_document d on d.document_id = o.document_id
     where o.proposition_id = p_proposition_id
       and o.membership = 'V'
       and o.magnitude >= p_min_magnitude
  ),
  -- 2. fact-key merge: keep the strongest row per fact within the proposition
  merged as (
    select distinct on (coalesce(fact_key, observation_id::text))
           *
      from v
     order by coalesce(fact_key, observation_id::text), magnitude desc, asserted_at asc
  ),
  comp as (
    select * from core.lineage_components(
      (select coalesce(array_agg(distinct document_id) filter (where document_id is not null), '{}')
         from merged))
  ),
  keyed as (
    select m.*,
           case
             -- 3. model-family collapse dominates everything else
             when m.agent_model_family is not null
               then 'model-family:' || m.agent_model_family
             -- 4. graph component
             when c.component_root is not null
               then 'component:' || c.component_root::text
             -- a receipted negative search is its own lineage: the corpus
             when m.derived_from_search_receipt_id is not null
               then 'negative-search:' || m.derived_from_search_receipt_id::text
             else 'orphan:' || m.observation_id::text
           end as lkey,
           case when m.agent_model_family is not null then 'agent-model-family'
                when m.derived_from_search_receipt_id is not null then 'negative-search'
                else 'document' end as lkind
      from merged m
      left join comp c on c.document_id = m.document_id
  )
  select k.lkey,
         min(k.lkind),
         max(k.magnitude)::smallint,
         count(*)::integer,
         (array_agg(k.document_id order by k.magnitude desc))[1],
         (array_agg(k.title       order by k.magnitude desc))[1],
         (array_agg(k.tier        order by k.magnitude desc))[1]
    from keyed k
   group by k.lkey
$$;

create or replace function core.lineage_count(p_proposition_id uuid, p_min_magnitude smallint default 2)
returns integer language sql stable as $$
  select count(*)::integer from core.independent_lineages(p_proposition_id, p_min_magnitude)
$$;

-- ---------------------------------------------------------------------
-- CITOGENESIS DETECTION (BES §5.3, CAP-3).
--
-- A T3+ publication resting on unattributable T5 testimony, subsequently
-- cited as though primary. The whole loop is ONE lineage; the laundered
-- proposition is capped at E; the flag attaches to the PROPOSITION, not the
-- site — which is exactly where the historian's Mount Weather entry had
-- nowhere to live under v0.1.
-- ---------------------------------------------------------------------
create table core.citogenesis_loop (
  loop_id        bigint generated always as identity primary key,
  proposition_id uuid not null references core.proposition(proposition_id) on delete restrict,
  laundering_document_id uuid not null references core.source_document(document_id),
  t5_root_document_id    uuid references core.source_document(document_id),
  loop_path      uuid[] not null,
  detected_by    text not null,
  detected_at    timestamptz not null default now(),
  state          text not null default 'suspected'
                   check (state in ('suspected','confirmed','cleared')),
  narrative      text not null,
  collapsed_into_lineage_id bigint references core.lineage(lineage_id)
);
create index citogenesis_prop_idx on core.citogenesis_loop(proposition_id) where state='confirmed';

-- Candidate detector: a T1..T3 document whose entire backward closure
-- terminates in T5 material, reached without an intervening authority.
create or replace function core.detect_citogenesis(p_proposition_id uuid, p_max_depth integer default 16)
returns table (
  laundering_document_id uuid,
  laundering_tier core.origin_tier,
  t5_root_document_id uuid,
  path uuid[],
  closed_a_cycle boolean
)
language sql stable as $$
  with cited as (
    select distinct o.document_id
      from core.observation o
     where o.proposition_id = p_proposition_id and o.document_id is not null
  ),
  launderers as (
    select c.document_id, d.origin_tier
      from cited c join core.source_document d using (document_id)
     where d.origin_tier in ('T1','T2','T3')
  ),
  walked as (
    select l.document_id as launder_id, l.origin_tier as launder_tier, t.*
      from launderers l
      cross join lateral core.trace_origin(l.document_id, p_max_depth) t
     where t.depth > 0
  )
  select w.launder_id, w.launder_tier, w.document_id, w.path, bool_or(w.is_cycle) over ()
    from walked w
   where w.origin_tier = 'T5'
     and (w.is_terminus or w.is_cycle)
     -- no intervening body with authority over the fact broke the chain
     and not exists (
       select 1 from unnest(w.path) pid
        join core.source_document sd on sd.document_id = pid
       where sd.origin_tier in ('T1','T2')
         and sd.document_id <> w.launder_id
     )
$$;

-- ---------------------------------------------------------------------
-- Testimony custody. The lineage terminus is whoever is ASSERTING, never
-- whoever is quoted (BES §5.4). An anonymous claim ABOUT what a named
-- person said is one lineage with the claimant, not with the person.
-- ---------------------------------------------------------------------
create table core.witness (
  witness_id     bigint generated always as identity primary key,
  display_name   text not null,
  -- The resolvability gate: independently locatable in a record that
  -- PREDATES the claim and was created for an UNRELATED purpose.
  resolvable     boolean not null default false,
  resolving_record_kind text check (resolving_record_kind in
                   ('payroll','unit-history','union-roll','obituary','court-filing',
                    'property-record','census','directory','none')),
  resolving_record_document_id uuid references core.source_document(document_id),
  resolving_record_predates_claim boolean,
  resolving_record_unrelated_purpose boolean,
  adjudicated_by text,
  adjudicated_at timestamptz,
  note           text
);

create table core.attestation (
  attestation_id bigint generated always as identity primary key,
  witness_id     bigint not null references core.witness(witness_id),
  observation_id uuid not null references core.observation(observation_id) on delete restrict,
  -- custody path the witness controlled, or a third party recorded
  custody        text not null check (custody in
                   ('signed-or-recorded-interview','bylined-quotation','deposition',
                    'numbered-oral-history-accession','claimant-assertion-only','unknown')),
  custody_document_id uuid references core.source_document(document_id),
  -- who is ASSERTING this attestation: the lineage terminus
  asserting_document_id uuid not null references core.source_document(document_id),
  recorded_at    date,
  note           text
);
create index attestation_obs_idx on core.attestation(observation_id);

comment on table core.attestation is
  'Attestation custody closes posthumous attribution — the cheapest lineage-seeding attack. Seeding two "independent" lineages by attributing invented testimony to two real dead findable people collapses to ONE lineage here, because asserting_document_id is the terminus.';
