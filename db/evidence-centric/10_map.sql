-- =====================================================================
-- SECTION 10 — RENDERING UNCERTAINTY, AND FAST VIEWPORT QUERIES
--
-- Hard requirements 7 and 10.
--
-- Historian failure #12: "a precise pin derived from imprecise evidence is
-- the register manufacturing exactly the kind of durable false fact it
-- exists to dismantle." So the map geometry is not the stored geometry —
-- it is a FUNCTION of the stored geometry AND the grade of the LOCATE
-- proposition. Below band C a point is structurally unavailable: the
-- renderer cannot draw one because the API never emits one.
-- =====================================================================

-- ---------------------------------------------------------------------
-- The render rule, in one place, applied everywhere.
-- ---------------------------------------------------------------------
create or replace function core.render_geometry(p_entity_id uuid)
returns table (
  representation core.geometry_representation,
  geom geometry(Geometry,4326),
  precision_level core.locate_precision,
  locate_grade core.grade,
  uncertainty_radius_m double precision,
  suppression_reason text
)
language plpgsql stable as $$
declare
  ga core.geometry_assertion;
  lg core.grade;
  aa registry.admin_area;
begin
  select * into ga from core.geometry_assertion
   where entity_id = p_entity_id and is_preferred and superseded_at is null;
  if ga is null then
    select * into ga from core.geometry_assertion
     where entity_id = p_entity_id and superseded_at is null
     order by array_position(enum_range(null::core.locate_precision), precision)
     limit 1;
  end if;

  if ga is null then
    return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
                        null::core.locate_precision, null::core.grade, null::double precision,
                        'no geometry assertion on file';
    return;
  end if;

  select cg.grade into lg
    from core.proposition p
    join core.proposition_current_grade cg using (proposition_id)
   where p.entity_id = p_entity_id and p.class = 'LOCATE'
   order by cg.published_at desc limit 1;

  -- NON-LOCATED is documented-but-unlocated. It is epistemically distinct
  -- from claimed-only and it belongs in the claims register, not on the map.
  if ga.precision = 'non_located' then
    return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
                        ga.precision, lg, null::double precision,
                        'non-located: documented, coordinates genuinely unknown';
    return;
  end if;

  -- THE HARD GATE. A point requires BOTH a precise assertion AND a LOCATE
  -- proposition graded C or better. Everything else degrades to an area.
  if ga.point_geom is not null
     and ga.precision in ('surveyed','approximate_1km')
     and coalesce(core.grade_rank(lg), 0) >= core.grade_rank('C') then
    return query select 'point'::core.geometry_representation, ga.point_geom,
                        ga.precision, lg, ga.uncertainty_radius_m, null::text;
    return;
  end if;

  if ga.point_geom is not null then
    return query select 'uncertainty_circle'::core.geometry_representation,
                        st_buffer(ga.point_geom::geography,
                                  coalesce(ga.uncertainty_radius_m,
                                    case ga.precision
                                      when 'approximate_1km'  then 1000
                                      when 'approximate_10km' then 10000
                                      else 25000 end))::geometry,
                        ga.precision, lg,
                        coalesce(ga.uncertainty_radius_m,
                          case ga.precision when 'approximate_1km' then 1000
                                            when 'approximate_10km' then 10000
                                            else 25000 end),
                        case when coalesce(core.grade_rank(lg),0) < core.grade_rank('C')
                             then 'LOCATE proposition below band C: rendered as uncertainty, never as a pin'
                             else 'coordinate precision below approximate_1km' end;
    return;
  end if;

  if ga.region_geom is not null then
    return query select 'region_polygon'::core.geometry_representation, ga.region_geom::geometry,
                        ga.precision, lg, null::double precision, null::text;
    return;
  end if;

  if ga.admin_area_id is not null then
    select * into aa from registry.admin_area where admin_area_id = ga.admin_area_id;
    return query select 'admin_polygon'::core.geometry_representation, aa.geom::geometry,
                        ga.precision, lg, null::double precision,
                        'located only to administrative area';
    return;
  end if;

  return query select 'none'::core.geometry_representation, null::geometry(Geometry,4326),
                      ga.precision, lg, null::double precision, 'no renderable shape';
end $$;

-- ---------------------------------------------------------------------
-- THE MAP PROJECTION.
--
-- A materialised view because viewport queries must not walk the evidence
-- graph. It is built ONLY from published rows and only from entities whose
-- EXIST proposition reaches band D — BES §10.3: "Nothing below band D
-- renders as a map pin; E, F and R live in the claims register with their
-- origin work, which is the product."
--
-- Materialised views do not enforce RLS, so the WHERE clause below IS the
-- security boundary for this object and is written to be read as such.
-- ---------------------------------------------------------------------
create materialized view api.map_feature as
select
  e.entity_id,
  e.slug,
  e.canonical_name,
  e.entity_level,
  e.country_code,
  e.typology_cached                          as typology,
  exist_cg.grade                             as exist_grade,
  core.grade_rank(exist_cg.grade)            as exist_rank,
  rg.representation,
  rg.precision_level                         as locate_precision,
  rg.locate_grade,
  rg.uncertainty_radius_m,
  rg.suppression_reason,
  rg.geom,
  st_transform(rg.geom, 3857)                as geom_3857,
  st_pointonsurface(rg.geom)                 as label_point,
  -- badge counts: a site page renders N badges, never one
  (select count(*) from core.proposition p2
     join core.proposition_current_grade c2 using (proposition_id)
    where p2.entity_id = e.entity_id and p2.publication_state='PUBLISHED')  as proposition_count,
  (select count(*) from core.proposition p3
     join core.proposition_current_grade c3 using (proposition_id)
    where p3.entity_id = e.entity_id and c3.grade = 'R')                    as refuted_count,
  (select count(*) from core.proposition p4
     join core.proposition_current_grade c4 using (proposition_id)
    where p4.entity_id = e.entity_id and c4.grade = 'X')                    as unassessed_count,
  exist_ge.silence_reading,
  exist_ge.base_rate_reading,
  exist_ge.at_ceiling,
  exist_ge.marginal_flag,
  exist_cg.published_at                      as graded_at
from core.entity e
join core.proposition exist_p
  on exist_p.entity_id = e.entity_id and exist_p.class = 'EXIST'
 and exist_p.publication_state = 'PUBLISHED'
join core.proposition_current_grade exist_cg
  on exist_cg.proposition_id = exist_p.proposition_id
join core.grade_event exist_ge
  on exist_ge.grade_event_id = exist_cg.grade_event_id
cross join lateral core.render_geometry(e.entity_id) rg
where e.publication_state = 'PUBLISHED'
  and e.is_canary = false                                  -- canaries never publish
  and rg.geom is not null
  and rg.representation <> 'none'
  and core.grade_rank(exist_cg.grade) >= core.grade_rank('D');

create unique index map_feature_pk    on api.map_feature(entity_id);
create index map_feature_gix          on api.map_feature using gist (geom);
create index map_feature_gix_3857     on api.map_feature using gist (geom_3857);
create index map_feature_rank_idx     on api.map_feature(exist_rank desc);
create index map_feature_typology_idx on api.map_feature(typology);
create index map_feature_country_idx  on api.map_feature(country_code);

comment on materialized view api.map_feature is
  'Published map projection. The WHERE clause is the security boundary: materialised views do not enforce RLS.';

-- ---------------------------------------------------------------------
-- Server-side clustering. Pre-aggregated per zoom bucket so a continental
-- viewport at z3 returns a few hundred rows instead of the whole register,
-- which is what keeps the map fast as the candidate count grows without
-- bound.
-- ---------------------------------------------------------------------
create materialized view api.map_cluster as
with z as (
  select generate_series(2,9) as zoom
),
snapped as (
  select z.zoom,
         -- ~256 px cells in Web Mercator at each zoom
         st_snaptogrid(f.geom_3857, 40075016.686 / (2 ^ z.zoom) / 4) as cell,
         f.entity_id, f.exist_rank, f.typology, f.country_code
    from api.map_feature f cross join z
)
select zoom,
       row_number() over (partition by zoom order by cell) as cluster_id,
       count(*)::integer                        as feature_count,
       max(exist_rank)                          as best_exist_rank,
       core.rank_grade(max(exist_rank))         as best_exist_grade,
       mode() within group (order by typology)  as modal_typology,
       min(country_code)                        as country_code,
       st_centroid(st_collect(cell))            as centroid_3857,
       st_transform(st_centroid(st_collect(cell)), 4326) as centroid,
       st_transform(st_envelope(st_collect(cell)), 4326) as bbox,
       array_agg(entity_id order by exist_rank desc)
         filter (where true)                    as entity_ids
  from snapped
 group by zoom, cell;

create unique index map_cluster_pk  on api.map_cluster(zoom, cluster_id);
create index map_cluster_gix        on api.map_cluster using gist (centroid);
create index map_cluster_zoom_idx   on api.map_cluster(zoom);

-- ---------------------------------------------------------------------
-- Viewport RPC. Returns clusters when zoomed out, features when zoomed in.
-- One round trip, no client-side clustering, no whole-table scan.
-- ---------------------------------------------------------------------
create or replace function api.map_viewport(
  west double precision, south double precision,
  east double precision, north double precision,
  zoom integer,
  min_grade core.grade default 'D',
  typologies core.typology[] default null,
  countries text[] default null
)
returns jsonb
language sql stable parallel safe security invoker as $$
  with bbox as (
    select st_makeenvelope(west, south, east, north, 4326) as g
  )
  select case when zoom <= 9 then
    jsonb_build_object(
      'mode','clusters',
      'zoom', zoom,
      'clusters', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'cluster_id', c.cluster_id,
                 'count', c.feature_count,
                 'best_grade', c.best_exist_grade,
                 'modal_typology', c.modal_typology,
                 'lon', st_x(c.centroid), 'lat', st_y(c.centroid)))
          from api.map_cluster c, bbox
         where c.zoom = map_viewport.zoom
           and c.centroid && bbox.g
           and c.best_exist_rank >= core.grade_rank(min_grade)
           and (countries is null or c.country_code = any(countries))), '[]'::jsonb))
  else
    jsonb_build_object(
      'mode','features',
      'zoom', zoom,
      'features', coalesce((
        select jsonb_agg(jsonb_build_object(
                 'entity_id', f.entity_id,
                 'slug', f.slug,
                 'name', f.canonical_name,
                 'entity_level', f.entity_level,
                 'exist_grade', f.exist_grade,
                 'typology', f.typology,
                 'representation', f.representation,
                 'locate_precision', f.locate_precision,
                 'locate_grade', f.locate_grade,
                 'uncertainty_radius_m', f.uncertainty_radius_m,
                 'suppression_reason', f.suppression_reason,
                 'proposition_count', f.proposition_count,
                 'refuted_count', f.refuted_count,
                 'unassessed_count', f.unassessed_count,
                 'silence_reading', f.silence_reading,
                 'base_rate_reading', f.base_rate_reading,
                 'at_ceiling', f.at_ceiling,
                 'marginal', f.marginal_flag,
                 'geometry', st_asgeojson(f.geom)::jsonb))
          from api.map_feature f, bbox
         where f.geom && bbox.g
           and f.exist_rank >= core.grade_rank(min_grade)
           and (typologies is null or f.typology = any(typologies))
           and (countries  is null or f.country_code = any(countries))
         limit 2000), '[]'::jsonb))
  end
$$;

-- Vector tiles, for MapLibre's native path. Same security boundary: the
-- source is api.map_feature, which is already published-only.
create or replace function api.map_tile(z integer, x integer, y integer)
returns bytea
language sql stable parallel safe security invoker as $$
  with env as (
    select st_tileenvelope(z, x, y) as g
  ),
  src as (
    select f.entity_id, f.slug, f.canonical_name, f.exist_grade, f.exist_rank,
           f.typology, f.representation, f.locate_precision, f.locate_grade,
           f.proposition_count, f.refuted_count,
           st_asmvtgeom(f.geom_3857, env.g, 4096, 64, true) as geom
      from api.map_feature f, env
     where f.geom_3857 && env.g
  )
  select coalesce(st_asmvt(src.*, 'candidates', 4096, 'geom'), ''::bytea)
    from src where geom is not null
$$;

-- Refresh, safe to run concurrently from the ingest cron.
create or replace function api.refresh_map()
returns void language plpgsql security definer set search_path = api, core, registry, public as $$
begin
  refresh materialized view concurrently api.map_feature;
  refresh materialized view concurrently api.map_cluster;
end $$;
revoke all on function api.refresh_map() from public, anon, authenticated;
grant execute on function api.refresh_map() to service_role;
