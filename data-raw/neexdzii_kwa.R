# Pull spatial data for Neexdzii Kwa (Upper Bulkley) subbasin
# Johnny David Creek to Richfield Creek on the Bulkley mainstem
# Requires: fresh package, SSH tunnel to newgraph DB on port 63333

library(fresh)
library(sf)

sf_use_s2(FALSE)

blk <- 360873822      # Bulkley River mainstem
drm_ds <- 214900      # just below Johnny David Creek confluence
drm_us <- 217800      # just upstream of Richfield Creek confluence

# -- Subbasin polygon (downstream watershed minus upstream watershed) --
neexdzii_wsd <- frs_watershed_at_measure(blk, drm_ds, upstream_measure = drm_us)
neexdzii_wsd <- st_transform(neexdzii_wsd, 4326)
cat("AOI area:", round(as.numeric(st_area(st_transform(neexdzii_wsd, 3005))) / 10000), "ha\n")

# -- Network features between the two points --
result <- frs_network(blk, drm_ds, upstream_measure = drm_us,
  tables = list(
    streams = "whse_basemapping.fwa_stream_networks_sp",
    lakes = "whse_basemapping.fwa_lakes_poly",
    wetlands = "whse_basemapping.fwa_wetlands_poly",
    crossings = "bcfishpass.crossings",
    fish_obs = "bcfishobs.fiss_fish_obsrvtn_events_vw",
    falls = "bcfishpass.falls_vw"
  )
)

# Transform to WGS84
neexdzii_streams <- st_transform(result$streams, 4326)
neexdzii_lakes <- st_transform(result$lakes, 4326)
neexdzii_wetlands <- st_transform(result$wetlands, 4326)

cat("Streams:", nrow(neexdzii_streams), "\n")
cat("Lakes:", nrow(neexdzii_lakes), "\n")
cat("Wetlands:", nrow(neexdzii_wetlands), "\n")

# -- Roads, FSRs, railway — spatial query against AOI bbox, clip to subbasin --
wsd_3005 <- st_transform(neexdzii_wsd, 3005)
bb <- st_bbox(wsd_3005)
env <- sprintf(
  "ST_MakeEnvelope(%s, %s, %s, %s, 3005)",
  bb["xmin"], bb["ymin"], bb["xmax"], bb["ymax"]
)

roads <- frs_db_query(sprintf(
  "SELECT transport_line_type_code as road_type, geom
   FROM whse_basemapping.transport_line
   WHERE transport_line_type_code IN
     ('RF','RH1','RH2','RA','RA1','RA2','RC1','RC2','RLO')
   AND ST_Intersects(geom, %s)", env
))
roads <- st_collection_extract(st_intersection(roads, wsd_3005), "LINESTRING")
neexdzii_roads <- st_transform(roads, 4326)
cat("Roads:", nrow(neexdzii_roads), "\n")

railway <- frs_db_query(sprintf(
  "SELECT track_name, geom
   FROM whse_basemapping.gba_railway_tracks_sp
   WHERE ST_Intersects(geom, %s)", env
))
if (nrow(railway) > 0) {
  railway <- st_collection_extract(st_intersection(railway, wsd_3005), "LINESTRING")
}
neexdzii_railway <- st_transform(railway, 4326)
cat("Railway:", nrow(neexdzii_railway), "\n")

# -- Keymap data: BC outline + Bulkley/Morice watershed groups --
neexdzii_bc <- st_transform(frs_db_query(
  "SELECT ST_Simplify(geom, 5000) as geom FROM whse_basemapping.fwa_bcboundary"
), 4326)

neexdzii_wsg <- st_transform(frs_db_query(
  "SELECT watershed_group_code, geom
   FROM whse_basemapping.fwa_watershed_groups_poly
   WHERE watershed_group_code IN ('BULK', 'MORR')"
), 4326)

# -- Save as package data --
usethis::use_data(
  neexdzii_wsd, neexdzii_streams, neexdzii_lakes, neexdzii_wetlands,
  neexdzii_roads, neexdzii_railway, neexdzii_bc, neexdzii_wsg,
  overwrite = TRUE
)
