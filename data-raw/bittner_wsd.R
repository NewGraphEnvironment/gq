# Bittner Creek's watershed polygon, the one input bittner_creek.R cannot fetch
# without a database.
#
# Needs a PostgreSQL database with fwapg (fwa_watershedatmeasure()) and the FWA
# stream network and river polygons. The connection comes from the standard libpq
# variables -- PGHOST, PGPORT, PGUSER, PGDATABASE (default bcfishpass).
#
# Writes the exact, unsimplified polygon in BC Albers to data-raw/bittner_wsd.gpkg.
# Run it only to move the pour point; bittner_creek.R reads the file and needs no
# database.

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

wsd <- st_read(conn, query = sprintf("
  SELECT %d AS blue_line_key, %f AS downstream_route_measure,
         ST_Area(geom) / 10000 AS area_ha, geom
  FROM fwa_watershedatmeasure(%d, %f)
", blk, drm, blk, drm))

dbDisconnect(conn)

stopifnot(nrow(wsd) == 1L, st_crs(wsd) == st_crs(3005), all(st_is_valid(wsd)))

# A fixed write date, so an unchanged polygon rewrites byte-identical.
st_write(wsd, "data-raw/bittner_wsd.gpkg", layer = "bittner_wsd",
         delete_dsn = TRUE, quiet = TRUE,
         config_options = c(OGR_CURRENT_DATE = "2000-01-01T00:00:00.000Z"))
