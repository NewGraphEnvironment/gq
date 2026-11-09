# Pull real spatial data for Bittner Creek near Prince George
#
# Needs a PostgreSQL database with fwapg (fwa_watershedatmeasure()) and the
# tables queried below: FWA streams, lakes and river polygons, the Digital Road
# Atlas, railway tracks and PSCIS assessments. The connection comes from the
# standard libpq variables -- PGHOST, PGPORT, PGUSER, PGDATABASE (default
# bcfishpass) -- so the script runs against whichever database holds them.

library(sf)
library(DBI)
library(RPostgres)

conn <- dbConnect(Postgres(), dbname = Sys.getenv("PGDATABASE", "bcfishpass"))

blk <- 356342733  # Bittner Creek blue_line_key

# Where the watershed is taken from. Not measure 0: Bittner Creek's lowest
# segment runs inside the Fraser River's polygon, and a watershed taken from a
# point in a river polygon takes in the river corridor too -- at measure 0 that
# was ~500 ha of Fraser and Nechako channel through Prince George, which put one
# Fraser crossing "inside" the watershed and widened every map over downtown
# (#102). So: the lowest measure whose segment lies outside every river polygon,
# plus 1 m, because at the exact boundary fwapg still takes the segment below.
# Measured 2026-11-09: the boundary is 165.97 m; 5,128 ha with 844 ha of river
# polygon there, 4,008 ha with none at +1 m.
drm <- dbGetQuery(conn, sprintf("
  SELECT min(s.downstream_route_measure) AS drm
  FROM whse_basemapping.fwa_stream_networks_sp s
  WHERE s.blue_line_key = %d
    AND NOT EXISTS (
      SELECT 1 FROM whse_basemapping.fwa_rivers_poly r
      WHERE ST_Within(ST_LineInterpolatePoint(ST_Force2D(s.geom), 0.5), r.geom)
    )
", blk))$drm + 1
stopifnot(length(drm) == 1L, is.finite(drm))

river_ha <- dbGetQuery(conn, sprintf("
  SELECT coalesce(sum(ST_Area(ST_Intersection(r.geom, w.geom))), 0) / 10000 AS ha
  FROM whse_basemapping.fwa_rivers_poly r, fwa_watershedatmeasure(%d, %f) w
  WHERE ST_Intersects(r.geom, w.geom)
", blk, drm))$ha
if (river_ha > 1) {
  stop("the watershed at measure ", round(drm, 2), " still holds ",
       round(river_ha), " ha of river polygon", call. = FALSE)
}

# -- Watershed polygon --
bittner_wsd <- st_read(conn, query = sprintf("
  SELECT ST_Transform(ST_Simplify(geom, 50), 4326) as geom,
         ST_Area(geom) / 10000 as area_ha
  FROM fwa_watershedatmeasure(%d, %f)
", blk, drm))

# -- Streams (all orders, clipped to watershed) --
bittner_streams <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, %f)
  )
  SELECT s.gnis_name, s.stream_order,
         ST_Transform(ST_Intersection(s.geom, ws.geom), 4326) as geom
  FROM whse_basemapping.fwa_stream_networks_sp s, ws
  WHERE ST_Intersects(s.geom, ws.geom)
    AND s.edge_type NOT IN (1100, 1200, 1300, 1400, 1500, 1600)
    AND s.stream_order >= 2
", blk, drm))

# -- Lakes --
bittner_lakes <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, %f)
  )
  SELECT l.gnis_name_1 as name,
         ST_Transform(l.geom, 4326) as geom,
         ST_Area(l.geom) / 10000 as area_ha
  FROM whse_basemapping.fwa_lakes_poly l, ws
  WHERE ST_Intersects(l.geom, ws.geom)
", blk, drm))

# -- Roads (DRA, clipped to expanded watershed) --
bittner_roads <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, %f)
  )
  SELECT t.transport_line_type_code as road_type,
         ST_Transform(ST_Simplify(t.geom, 20), 4326) as geom
  FROM whse_basemapping.transport_line t, ws
  WHERE ST_Intersects(t.geom, ST_Expand(ws.geom, 5000))
    AND t.transport_line_type_code IN ('RH1', 'RA1', 'RA2', 'RC2', 'RLO')
", blk, drm))

# -- Railway --
bittner_railway <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, %f)
  )
  SELECT r.track_classification,
         ST_Transform(ST_Simplify(r.geom, 20), 4326) as geom
  FROM whse_basemapping.gba_railway_tracks_sp r, ws
  WHERE ST_Intersects(r.geom, ST_Expand(ws.geom, 5000))
", blk, drm))

# -- PSCIS assessments (the real crossing data) --
bittner_pscis <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, %f)
  )
  SELECT a.stream_crossing_id, a.road_name, a.stream_name,
         a.barrier_result_code,
         ST_Transform(a.geom, 4326) as geom
  FROM whse_fish.pscis_assessment_svw a, ws
  WHERE ST_Intersects(a.geom, ST_Expand(ws.geom, 2000))
", blk, drm))

dbDisconnect(conn)

# Save
usethis::use_data(
  bittner_wsd, bittner_streams, bittner_lakes,
  bittner_roads, bittner_railway, bittner_pscis,
  overwrite = TRUE
)
