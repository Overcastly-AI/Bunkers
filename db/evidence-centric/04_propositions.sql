-- =====================================================================
-- SECTION 04 — PROPOSITIONS ARE FIRST-CLASS
--
-- Hard requirement 1. The unit of grading is a PROPOSITION, not a place.
-- "The hole is certain, the function is not" is expressed natively: two
-- rows in this table, two independent grade histories, two badges.
--
-- Historian failure #2 / IC failure #2 are both fixed here and only here.
-- A well-documented real installation can no longer launder its
-- documentation onto every claim attached to it, because evidence attaches
-- to proposition_id and nothing else.
-- =====================================================================

create table core.proposition (
  proposition_id   uuid primary key default gen_random_uuid(),
  entity_id        uuid not null references core.entity(entity_id) on delete restrict,
  class            core.proposition_class not null,

  -- The subject is normally the entity, but IDENTITY and ORIGIN take a
  -- second subject (entity B, or a claim), so it is explicit.
  subject_entity_id uuid references core.entity(entity_id),
  object_entity_id  uuid references core.entity(entity_id),   -- IDENTITY B side
  claim_id          uuid,                                     -- ORIGIN: which claim

  -- Class-specific arguments, validated per class by trigger below.
  --   EXTENT   {"dimension":"depth_m","claimed_value":300}
  --   HARDEN   {"threats":["blast","EMP"]}
  --   CONTROL  {"entity":"US Army Corps of Engineers"}
  --   FUNCTION {"function":"COG-COOP"}
  --   STATUS   {"status":"never-built"}
  --   LOCATE   {"radius_m":1000}
  --   PROGRAM  {"program":"DUCC","state":"cancelled"}
  --   ORIGIN   {"claim":"underground city with a lake","artifact":"..." }
  predicate_args   jsonb not null default '{}'::jsonb,

  statement_text   text not null,     -- rendered human-readable proposition
  as_of_date       date,              -- STATUS / CONTROL / FUNCTION are time-bound
  valid_period     daterange,

  -- BES §4.1: null_hypothesis is NOT NULLABLE. An observation contributes
  -- in proportion to its power to discriminate the proposition from the
  -- NAMED alternative, so there is always a named alternative.
  null_code        char(3) not null references registry.null_hypothesis(null_code),
  -- A11 is a MANDATORY CO-NULL on any proposition whose positive support
  -- includes a T5 lineage; both scorings run and the LOWER grade publishes.
  co_null_code     char(3) references registry.null_hypothesis(null_code),

  typology_profile core.typology not null default 'unknown-anomaly',
  reference_class  core.reference_class,      -- publication only, never arithmetic
  function_set     text not null default 'n/a'
                     check (function_set in ('sensitive','mundane','n/a')),

  -- The monotone clamp (BES §1.4): a published child grade may not exceed
  -- its parent's. PROGRAM and ORIGIN are EXEMPT — that exemption is what
  -- makes DUCC (PROGRAM A, EXIST R) and Dulce (ORIGIN A, FUNCTION R)
  -- representable at all.
  parent_proposition_id uuid references core.proposition(proposition_id),
  clamp_exempt     boolean not null default false,

  candidate_set_id bigint references registry.candidate_set(candidate_set_id),

  created_at       timestamptz not null default now(),
  created_by       text not null,        -- PROPOSER agent id
  publication_state core.publication_state not null default 'INTERNAL',
  published_at     timestamptz,
  withdrawn_reason text,

  constraint proposition_no_self_parent check (parent_proposition_id <> proposition_id),
  constraint proposition_identity_has_object
    check (class <> 'IDENTITY' or object_entity_id is not null),
  constraint proposition_origin_has_claim
    check (class <> 'ORIGIN' or claim_id is not null),
  constraint proposition_published_has_date
    check (publication_state <> 'PUBLISHED' or published_at is not null)
);

-- One EXIST proposition per entity per as-of date: the clamp parent must be
-- unambiguous.
create unique index proposition_one_exist
  on core.proposition(entity_id, coalesce(as_of_date,'0001-01-01'::date))
  where class = 'EXIST';
create index proposition_entity_idx  on core.proposition(entity_id, class);
create index proposition_parent_idx  on core.proposition(parent_proposition_id);
create index proposition_class_idx   on core.proposition(class);
create index proposition_args_gin    on core.proposition using gin (predicate_args jsonb_path_ops);
create index proposition_pub_idx     on core.proposition(publication_state) where publication_state='PUBLISHED';

-- PROGRAM and ORIGIN are clamp-exempt by construction, not by choice.
create or replace function core.set_clamp_exemption() returns trigger
language plpgsql as $$
begin
  new.clamp_exempt := (new.class in ('PROGRAM','ORIGIN'));
  return new;
end $$;
create trigger proposition_clamp_exemption
  before insert or update of class on core.proposition
  for each row execute function core.set_clamp_exemption();

-- ---------------------------------------------------------------------
-- predicate_args validation per class. An agent may not invent a class and
-- may not emit an under-specified proposition.
-- ---------------------------------------------------------------------
create or replace function core.validate_predicate_args() returns trigger
language plpgsql as $$
declare req text[];
begin
  req := case new.class
    when 'EXTENT'   then array['dimension','claimed_value','unit']
    when 'HARDEN'   then array['threats']
    when 'CONTROL'  then array['controlling_entity']
    when 'FUNCTION' then array['function']
    when 'STATUS'   then array['status']
    when 'LOCATE'   then array['radius_m']
    when 'FEATURE'  then array['feature']
    when 'PROGRAM'  then array['program','program_state']
    when 'ORIGIN'   then array['claim_text']
    when 'TYPOLOGY' then array['typology']
    when 'IDENTITY' then array['basis']
    else array[]::text[] end;

  if req <> array[]::text[] and not (new.predicate_args ?& req) then
    raise exception 'proposition class % requires predicate_args keys %, got %',
      new.class, req, (select array_agg(k) from jsonb_object_keys(new.predicate_args) k);
  end if;

  -- Closed vocabularies inside the jsonb are checked, not trusted.
  if new.class = 'STATUS' then
    perform 1 from unnest(enum_range(null::core.status_value)) s
      where s::text = new.predicate_args->>'status';
    if not found then raise exception 'STATUS.status % not in closed vocabulary',
      new.predicate_args->>'status'; end if;
  end if;
  if new.class = 'TYPOLOGY' then
    perform 1 from unnest(enum_range(null::core.typology)) t
      where t::text = new.predicate_args->>'typology';
    if not found then raise exception 'TYPOLOGY.typology % not in closed vocabulary',
      new.predicate_args->>'typology'; end if;
  end if;
  return new;
end $$;
create trigger proposition_validate_args
  before insert or update of class, predicate_args on core.proposition
  for each row execute function core.validate_predicate_args();

-- ---------------------------------------------------------------------
-- CLAIMS. A claim is the assertion itself, independent of any artifact
-- that carries it. It is the node the ORIGIN proposition is about and the
-- node semantic clustering collapses onto (BES §5.1.6). Paraphrase and
-- machine regeneration share no strings and cite nothing; they share a claim.
-- ---------------------------------------------------------------------
create table core.claim (
  claim_id       uuid primary key default gen_random_uuid(),
  claim_text     text not null,
  claim_norm     text generated always as (core.norm_token(claim_text)) stored,
  entity_id      uuid references core.entity(entity_id),
  cluster_key    text,          -- semantic cluster on the ASSERTION, not the wording
  first_appearance_document_id uuid,
  first_appearance_date        date,
  first_appearance_confidence  text check (first_appearance_confidence in
                                 ('receipted','inferred','unknown')),
  created_at     timestamptz not null default now()
);
create index claim_cluster_idx on core.claim(cluster_key);
create index claim_norm_trgm   on core.claim using gin (claim_norm gin_trgm_ops);

alter table core.proposition
  add constraint proposition_claim_fk foreign key (claim_id) references core.claim(claim_id);

-- Wire up the deferred FKs from the registry section.
alter table registry.candidate_set
  add constraint candidate_set_program_fk
  foreign key (program_proposition_id) references core.proposition(proposition_id);
alter table registry.candidate_set_member
  add constraint candidate_set_member_entity_fk
  foreign key (entity_id) references core.entity(entity_id);
alter table core.entity
  add constraint entity_typology_prop_fk
  foreign key (typology_proposition_id) references core.proposition(proposition_id);
alter table core.entity_alias
  add constraint entity_alias_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.entity_relation
  add constraint entity_relation_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.entity_merge_event
  add constraint merge_identity_fk
  foreign key (identity_proposition_id) references core.proposition(proposition_id);
alter table core.geometry_assertion
  add constraint geometry_locate_prop_fk
  foreign key (locate_proposition_id) references core.proposition(proposition_id);
