# Pull real spatial data for Bittner Creek near Prince George
# Requires SSH tunnel to newgraph DB on port 63333 (see db-newgraph skill)

library(sf)
library(DBI)
library(RPostgres)

conn <- dbConnect(
  Postgres(),
  host = "localhost", port = 63333,

  dbname = "bcfishpass", user = "newgraph"
)

blk <- 356342733  # Bittner Creek blue_line_key

# -- Watershed polygon --
bittner_wsd <- st_read(conn, query = sprintf("
  SELECT ST_Transform(ST_Simplify(geom, 50), 4326) as geom,
         ST_Area(geom) / 10000 as area_ha
  FROM fwa_watershedatmeasure(%d, 0)
", blk))

# -- Streams (all orders, clipped to watershed) --
bittner_streams <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, 0)
  )
  SELECT s.gnis_name, s.stream_order,
         ST_Transform(ST_Intersection(s.geom, ws.geom), 4326) as geom
  FROM whse_basemapping.fwa_stream_networks_sp s, ws
  WHERE ST_Intersects(s.geom, ws.geom)
    AND s.edge_type NOT IN (1100, 1200, 1300, 1400, 1500, 1600)
    AND s.stream_order >= 2
", blk))

# -- Lakes --
bittner_lakes <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, 0)
  )
  SELECT l.gnis_name_1 as name,
         ST_Transform(l.geom, 4326) as geom,
         ST_Area(l.geom) / 10000 as area_ha
  FROM whse_basemapping.fwa_lakes_poly l, ws
  WHERE ST_Intersects(l.geom, ws.geom)
", blk))

# -- Roads (DRA, clipped to expanded watershed) --
bittner_roads <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, 0)
  )
  SELECT t.transport_line_type_code as road_type,
         ST_Transform(ST_Simplify(t.geom, 20), 4326) as geom
  FROM whse_basemapping.transport_line t, ws
  WHERE ST_Intersects(t.geom, ST_Expand(ws.geom, 5000))
    AND t.transport_line_type_code IN ('RH1', 'RA1', 'RA2', 'RC2', 'RLO')
", blk))

# -- Railway --
bittner_railway <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, 0)
  )
  SELECT r.track_classification,
         ST_Transform(ST_Simplify(r.geom, 20), 4326) as geom
  FROM whse_basemapping.gba_railway_tracks_sp r, ws
  WHERE ST_Intersects(r.geom, ST_Expand(ws.geom, 5000))
", blk))

# -- PSCIS assessments (the real crossing data) --
bittner_pscis <- st_read(conn, query = sprintf("
  WITH ws AS (
    SELECT geom FROM fwa_watershedatmeasure(%d, 0)
  )
  SELECT a.stream_crossing_id, a.road_name, a.stream_name,
         a.barrier_result_code,
         ST_Transform(a.geom, 4326) as geom
  FROM whse_fish.pscis_assessment_svw a, ws
  WHERE ST_Intersects(a.geom, ST_Expand(ws.geom, 2000))
", blk))

dbDisconnect(conn)

# Save
usethis::use_data(
  bittner_wsd, bittner_streams, bittner_lakes,
  bittner_roads, bittner_railway, bittner_pscis,
  overwrite = TRUE
)
