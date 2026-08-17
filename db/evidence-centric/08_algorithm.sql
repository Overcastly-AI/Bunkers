-- =====================================================================
-- SECTION 08 — GRADE(P): the algorithm, in the database
--
-- BES §9.4. Every step is deterministic given the evidence table. The
-- function is here rather than in application code for one reason: the
-- grade must be recomputable from the rows alone, by anyone, forever. An
-- external scorer that cannot be re-run is an unauditable scorer.
--
-- Order is load-bearing: refutation first (it overrides all bands), then
-- the SCI floor, then the bands top-down, then the caps, then the clamp.
-- =====================================================================

-- pgcrypto's digest() is not guaranteed enabled; fall back to a stable
-- built-in so the schema installs on a bare project. Swap for
-- digest(x,'sha256') where pgcrypto is available.
create or replace function digest_placeholder(t text)
returns bytea language sql immutable as $$
  select decode(md5(coalesce(t,'')), 'hex')
$$;

create or replace function core.evaluate_proposition(p_proposition_id uuid)
returns jsonb
language plpgsql stable as $$
declare
  p              core.proposition;
  e              core.entity;
  r              record;
  cond           jsonb := '{}'::jsonb;
  v_null_state   core.null_state;
  n_v int; n_u int; n_v0 int; n_vclaim int;
  l_d2 int; l_d3 int;
  has_d4 boolean; d3_lineages int;
  unrebutted_d3_undercut boolean;
  a1 boolean; a1alt boolean; a2 boolean; a3 boolean; a4 boolean; a5 boolean; a6 boolean;
  b1 boolean; b2 boolean; b3 boolean; b4 boolean;
  c1a boolean; c1b boolean; c1c boolean; c2 boolean; c3 boolean;
  d1 boolean; d2c boolean;
  e1 boolean; e2 boolean;
  awarded core.grade;
  final   core.grade;
  caps    text[] := '{}';
  refstate core.refutation_state := 'R0';
  v_sci numeric; v_sci_num int; v_sci_den int;
  mirror_only_a1 boolean;
  place_w int; claim_w int;
  limiting text;
begin
  select * into p from core.proposition where proposition_id = p_proposition_id;
  if p is null then raise exception 'no such proposition %', p_proposition_id; end if;
  select * into e from core.entity where entity_id = p.entity_id;

  -- ---- counts over the membership sets -------------------------------
  select count(*) filter (where membership='V'),
         count(*) filter (where membership='U'),
         count(*) filter (where membership='V0'),
         count(*) filter (where membership='V' and property_locus='CLAIM-PROPERTY'),
         bool_or(membership='V' and magnitude=4),
         coalesce(sum(magnitude) filter (where membership='V' and property_locus='PLACE-PROPERTY'),0),
         coalesce(sum(magnitude) filter (where membership='V' and property_locus='CLAIM-PROPERTY'),0)
    into n_v, n_u, n_v0, n_vclaim, has_d4, place_w, claim_w
    from core.observation where proposition_id = p_proposition_id;

  l_d2 := core.lineage_count(p_proposition_id, 2::smallint);
  l_d3 := core.lineage_count(p_proposition_id, 3::smallint);
  v_null_state := core.derive_null_state(p_proposition_id);
  select numerator, denominator, sci into v_sci_num, v_sci_den, v_sci
    from core.search_completeness(p_proposition_id);

  -- an unrebutted verified UNDERCUTS at D3+ blocks A, B and C alike
  select exists (
    select 1 from core.observation o
     where o.proposition_id = p_proposition_id
       and o.membership='U' and o.magnitude >= 3
       and not exists (select 1 from core.observation x
                        where x.proposition_id = p_proposition_id
                          and x.membership='V' and x.fact_key = o.fact_key
                          and x.magnitude >= o.magnitude)
  ) into unrebutted_d3_undercut;

  -- =====================================================================
  -- STEP 1 — REFUTATION. Checked FIRST; overrides all bands.
  -- BES §8.4: expected-record UNDERCUTS rows can NEVER alone license R.
  -- Without an affirmative row, however deep the negative stack, the
  -- proposition publishes F (SILENCE-DOMINATED). This is the countermeasure
  -- to the model's characteristic failure — quietly refuting a real
  -- facility whose cover story is good.
  -- =====================================================================
  select rf.state into refstate
    from core.refutation rf
   where rf.proposition_id = p_proposition_id and rf.reversed_at is null
     and exists (                              -- the affirmative-content gate
       select 1 from unnest(rf.basis_observation_ids) x(oid)
        join core.observation o on o.observation_id = x.oid
       where o.derived_from_search_receipt_id is null
     )
   order by case rf.state when 'R3' then 3 when 'R2' then 2 when 'R1' then 1 end desc
   limit 1;
  refstate := coalesce(refstate, 'R0');

  cond := cond || jsonb_build_object(
    'R', jsonb_build_object(
      'state', refstate,
      'gate_8_4_affirmative_row_present', refstate <> 'R0',
      'note', 'R is not F. F means nothing verified favours the claim; R means something affirmatively resolves against it.'));

  if refstate <> 'R0' then
    return jsonb_build_object(
      'grade','R','awarded_band','R','applied_caps','[]'::jsonb,
      'refutation_state', refstate, 'null_state', v_null_state,
      'conditions', cond, 'l_d2', l_d2, 'l_d3', l_d3,
      'v_count', n_v, 'u_count', n_u, 'v0_count', n_v0, 'v_claim_count', n_vclaim,
      'sci', v_sci, 'sci_numerator', v_sci_num, 'sci_denominator', v_sci_den,
      'place_derived_weight', place_w, 'claim_derived_weight', claim_w,
      'silence_reading', core.silence_reading(p_proposition_id),
      'limiting_condition', null);
  end if;

  -- =====================================================================
  -- STEP 2 — BAND CONDITIONS, top-down. The bands ARE the conditions.
  -- =====================================================================

  -- ---- A — ESTABLISHED ----
  select count(*) into d3_lineages from core.independent_lineages(p_proposition_id, 3::smallint);
  a1 := has_d4 and exists (select 1 from core.observation
                            where proposition_id=p_proposition_id and membership='V'
                              and magnitude=4 and property_locus='CLAIM-PROPERTY')
        or (d3_lineages >= 2 and (select count(*) from core.observation
                                   where proposition_id=p_proposition_id and membership='V'
                                     and magnitude>=3 and property_locus='CLAIM-PROPERTY') >= 2);

  -- A1-alt: direct observation, EXIST/EXTENT/LOCATE/FEATURE only
  a1alt := p.class in ('EXIST','EXTENT','LOCATE','FEATURE')
           and (select count(*) from core.observation o
                 join core.attestation at on at.observation_id = o.observation_id
                 join core.witness w on w.witness_id = at.witness_id
                where o.proposition_id = p_proposition_id and o.membership='V'
                  and w.resolvable
                  and at.custody in ('signed-or-recorded-interview','bylined-quotation',
                                     'deposition','numbered-oral-history-accession')) >= 2
           and exists (select 1 from core.observation o
                        where o.proposition_id=p_proposition_id and o.membership='V'
                          and o.prov_origin_tier='T1' and o.property_locus='PLACE-PROPERTY');

  a2 := not exists (select 1 from core.observation o
                     where o.proposition_id=p_proposition_id and o.membership='V'
                       and o.magnitude>=3
                       and (not o.subject_binding_pass or o.prov_receipt_state<>'VERIFIED'));
  a3 := (v_null_state = 'EXCLUDED');
  a4 := not unrebutted_d3_undercut;
  a5 := not exists (select 1 from core.observation o
                     where o.proposition_id=p_proposition_id and o.membership='V'
                       and o.magnitude>=3
                       and o.prov_causal not in ('UNSOLICITED','SOLICITED-3P'));

  -- A6 — forgery pricing. Forging a document into a public mirror is cheap;
  -- forging one into cia.gov or a county recorder's index with matching
  -- issuer metadata is not.
  select bool_or(rr.mirror_only) into mirror_only_a1
    from core.observation o join core.retrieval_receipt rr on rr.receipt_id = o.receipt_id
   where o.proposition_id=p_proposition_id and o.membership='V' and o.magnitude>=3;
  mirror_only_a1 := coalesce(mirror_only_a1,false);
  a6 := (not mirror_only_a1) or l_d2 >= 2;

  -- ---- B — CORROBORATED ----
  b1 := (l_d3 >= 2)
        or (l_d2 >= 3 and exists (select 1 from core.observation o
                                   where o.proposition_id=p_proposition_id and o.membership='V'
                                     and o.magnitude>=2 and o.prov_origin_tier in ('T1','T2')));
  b2 := v_null_state in ('EXCLUDED','INSUFFICIENT');
  b3 := not unrebutted_d3_undercut;
  b4 := n_vclaim >= 1;

  -- ---- C — SUPPORTED ----
  c1a := exists (select 1 from core.observation o
                  where o.proposition_id=p_proposition_id and o.membership='V'
                    and o.property_locus='CLAIM-PROPERTY' and o.magnitude>=2);
  c1b := (select count(*) from core.independent_lineages(p_proposition_id, 2::smallint) il
           where il.lineage_kind='document') >= 2
         and exists (select 1 from core.observation o
                      where o.proposition_id=p_proposition_id and o.membership='V'
                        and o.property_locus='PLACE-PROPERTY' and o.magnitude>=2);
  -- C1c — the candidate-set rule. C is the CEILING of this path.
  c1c := p.candidate_set_id is not null
         and registry.candidate_set_dilution_ok(p.candidate_set_id)
         and exists (select 1 from registry.candidate_set cs
                      join core.proposition pp on pp.proposition_id = cs.program_proposition_id
                      join core.proposition_current_grade cgp on cgp.proposition_id = pp.proposition_id
                     where cs.candidate_set_id = p.candidate_set_id
                       and cgp.grade in ('A','B'))
         and exists (select 1 from core.observation o
                      where o.proposition_id=p_proposition_id and o.membership='V'
                        and o.scope='INSTANCE' and o.property_locus='CLAIM-PROPERTY'
                        and o.magnitude>=1);
  c2 := v_null_state <> 'UNTESTED';
  c3 := not unrebutted_d3_undercut;

  -- ---- D — INDICATED ----
  d1 := exists (select 1 from core.observation o
                 where o.proposition_id=p_proposition_id and o.membership='V' and o.magnitude>=1)
        or (select count(*) from core.observation o
             where o.proposition_id=p_proposition_id and o.membership='V' and o.magnitude=0) >= 2;
  d2c := v_null_state in ('SURVIVING','DOMINANT','UNTESTED');

  -- ---- E — DOUBTFUL ----
  e1 := n_v > 0;
  e2 := not exists (select 1 from core.observation o
                     where o.proposition_id=p_proposition_id and o.membership='V' and o.magnitude>=2);

  awarded := case
    when (a1 or a1alt) and a2 and a3 and a4 and a5 and a6 then 'A'
    when b1 and b2 and b3 and b4                           then 'B'
    when (c1a or c1b or c1c) and c2 and c3                 then 'C'
    when d1 and d2c                                        then 'D'
    when e1 and e2                                         then 'E'
    else 'F' end::core.grade;

  cond := cond || jsonb_build_object(
    'A', jsonb_build_object('A1',a1,'A1-alt',a1alt,'A2',a2,'A3',a3,'A4',a4,'A5',a5,'A6',a6),
    'B', jsonb_build_object('B1',b1,'B2',b2,'B3',b3,'B4',b4),
    'C', jsonb_build_object('C1a',c1a,'C1b',c1b,'C1c',c1c,'C2',c2,'C3',c3),
    'D', jsonb_build_object('D1',d1,'D2cond',d2c),
    'E', jsonb_build_object('E1',e1,'E2',e2));

  -- =====================================================================
  -- STEP 3 — THE CAPS.
  -- =====================================================================
  final := awarded;

  if l_d2 <= 1 and not (a1 or a1alt) then
    caps := caps || 'CAP-1'::text; final := core.grade_min(final,'C');
  end if;

  -- CAP-2 splits by proposition class. A function, control or hardening
  -- claim carried entirely by attributes of the PLACE has no support for
  -- the CLAIM at all and belongs at E, not D. This is the single hardest
  -- constraint in the anti-gaming ledger.
  if n_vclaim = 0 then
    if p.class in ('EXIST','EXTENT','LOCATE','FEATURE','TYPOLOGY') then
      caps := caps || 'CAP-2a'::text; final := core.grade_min(final,'D');
    else
      caps := caps || 'CAP-2b'::text; final := core.grade_min(final,'E');
    end if;
  end if;

  if exists (select 1 from core.citogenesis_loop
              where proposition_id=p_proposition_id and state='confirmed') then
    caps := caps || 'CAP-3'::text; final := core.grade_min(final,'E');
  end if;

  if n_v > 0 and not exists (
       select 1 from core.observation o
        left join core.source_document d on d.document_id=o.document_id
       where o.proposition_id=p_proposition_id and o.membership='V'
         and coalesce(d.document_date, d.first_observed_date) <= date '2022-11-30') then
    caps := caps || 'CAP-4'::text; final := core.grade_min(final,'D');
  end if;

  if n_v = 0 then
    caps := caps || 'CAP-5'::text; final := core.grade_min(final,'F');
  end if;

  if mirror_only_a1 and not a6 then
    caps := caps || 'CAP-6'::text; final := core.grade_min(final,'B');
  end if;

  if v_null_state = 'UNTESTED' then
    caps := caps || 'CAP-7'::text; final := core.grade_min(final,'D');
  end if;

  if c1c and not (c1a or c1b) then
    final := core.grade_min(final,'C');   -- C is the ceiling of the candidate-set path
  end if;

  -- =====================================================================
  -- STEP 4 — THE SCI FLOOR. X is not a low grade; it is the absence of one.
  -- Grades A, B, C publish at any SCI: positive evidence does not require
  -- exhaustion. A NEGATIVE VERDICT DOES — you may not declare a claim
  -- unsupported without having looked.
  -- =====================================================================
  if coalesce(v_sci,0) < 0.5 and final in ('D','E','F') then
    final := 'X';
  end if;

  -- limiting_condition: the first failed condition of the band ABOVE.
  limiting := case final
    when 'B' then case when not a1 and not a1alt then 'A1' when not a2 then 'A2'
                       when not a3 then 'A3' when not a4 then 'A4'
                       when not a5 then 'A5' else 'A6' end
    when 'C' then case when not b1 then 'B1' when not b2 then 'B2'
                       when not b3 then 'B3' else 'B4' end
    when 'D' then case when not (c1a or c1b or c1c) then 'C1' when not c2 then 'C2' else 'C3' end
    when 'E' then case when not d1 then 'D1' else 'D2cond' end
    when 'F' then case when not e1 then 'E1' else 'E2' end
    when 'X' then 'SCI floor (BES 7.2)'
    else null end;
  if array_length(caps,1) is not null and final <> awarded then
    limiting := coalesce(limiting,'') || ' [capped by ' || array_to_string(caps,', ') || ']';
  end if;

  return jsonb_build_object(
    'grade', final, 'awarded_band', awarded,
    'applied_caps', to_jsonb(caps),
    'refutation_state', refstate,
    'null_state', v_null_state,
    'null_code', p.null_code,
    'conditions', cond,
    'l_d2', l_d2, 'l_d3', l_d3,
    'v_count', n_v, 'u_count', n_u, 'v0_count', n_v0, 'v_claim_count', n_vclaim,
    'sci', v_sci, 'sci_numerator', v_sci_num, 'sci_denominator', v_sci_den,
    'place_derived_weight', place_w, 'claim_derived_weight', claim_w,
    'silence_reading', core.silence_reading(p_proposition_id),
    'base_rate_reading', (select br.reading from registry.base_rate br
                           where br.proposition_class = p.class
                             and br.reference_class = p.reference_class
                             and br.function_set = p.function_set),
    'limiting_condition', limiting,
    -- one contested fact decided the band
    'marginal_flag', (l_d2 = 2 and final='B') or (l_d2 = 1 and final='C')
                     or exists (select 1 from core.document_citation dc
                                 where dc.quorum_disagreement and dc.retracted_at is null
                                   and dc.citing_document_id in
                                     (select document_id from core.observation
                                       where proposition_id=p_proposition_id and membership='V'))
  );
end $$;

comment on function core.evaluate_proposition is
  'GRADE(P) per BES 9.4. Pure and stable: given the rows, the answer is the same for everyone, forever. Returns the full condition vector, not just a letter, because the decomposition is the product.';

-- Materialise an evaluation as an append-only grade event.
create or replace function core.record_grade(
  p_proposition_id uuid,
  p_cause          core.transition_cause,
  p_scorer_model_id text,
  p_rubric_version text,
  p_publish        boolean default false,
  p_blind_double   boolean default false
) returns uuid
language plpgsql as $$
declare
  ev jsonb; new_id uuid; next_seq integer; fam text; ehash bytea;
begin
  ev := core.evaluate_proposition(p_proposition_id);
  select coalesce(max(seq),0)+1 into next_seq from core.grade_event
   where proposition_id = p_proposition_id;
  select model_family into fam from registry.scorer_model where scorer_model_id = p_scorer_model_id;

  -- Reconstruction key. Same hash + different grade = instrument drift,
  -- which is exactly what TABLE-VERSION-CHANGE and SCORER-CHANGE label.
  select digest_placeholder(string_agg(
           observation_id::text || ':' || membership::text || ':' || signed_weight::text,
           ',' order by observation_id))
    into ehash
    from core.observation where proposition_id = p_proposition_id;

  insert into core.grade_event (
    proposition_id, seq, grade, awarded_band, applied_caps, condition_results,
    limiting_condition, marginal_flag, refutation_state, null_state, null_code,
    silence_reading, base_rate_reading, reference_class,
    l_d2, l_d3, v_count, u_count, v_claim_count, v0_count,
    sci_numerator, sci_denominator, sci,
    place_derived_weight, claim_derived_weight,
    transition_cause, scorer_model_id, scorer_model_family, rubric_version,
    evidence_state_hash, published_at, is_blind_double_score,
    supersedes_id
  )
  select p_proposition_id, next_seq,
         (ev->>'grade')::core.grade, (ev->>'awarded_band')::core.grade,
         array(select jsonb_array_elements_text(ev->'applied_caps')),
         ev->'conditions', ev->>'limiting_condition', (ev->>'marginal_flag')::boolean,
         (ev->>'refutation_state')::core.refutation_state,
         (ev->>'null_state')::core.null_state, ev->>'null_code',
         (ev->>'silence_reading')::core.silence_reading,
         nullif(ev->>'base_rate_reading','')::core.base_rate_reading,
         p.reference_class,
         (ev->>'l_d2')::int, (ev->>'l_d3')::int, (ev->>'v_count')::int,
         (ev->>'u_count')::int, (ev->>'v_claim_count')::int, (ev->>'v0_count')::int,
         (ev->>'sci_numerator')::int, (ev->>'sci_denominator')::int, (ev->>'sci')::numeric,
         (ev->>'place_derived_weight')::int, (ev->>'claim_derived_weight')::int,
         p_cause, p_scorer_model_id, fam, p_rubric_version,
         ehash, case when p_publish then now() end, p_blind_double,
         (select grade_event_id from core.grade_event
           where proposition_id = p_proposition_id and not is_blind_double_score
           order by seq desc limit 1)
    from core.proposition p where p.proposition_id = p_proposition_id
  returning grade_event_id into new_id;

  -- Snapshot the evidence set: this is what makes the event reconstructable.
  insert into core.grade_event_observation
    (grade_event_id, observation_id, membership_at_scoring, signed_weight_at_scoring)
  select new_id, observation_id, membership, signed_weight
    from core.observation where proposition_id = p_proposition_id;

  return new_id;
end $$;

