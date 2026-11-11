# Pull real spatial data for Bittner Creek near Prince George -- no database.
#
# The watershed polygon is the one input that needs fwapg, so it is computed once
# by data-raw/bittner_wsd.R and read here from data-raw/bittner_wsd.gpkg. Every
# other layer is fetched over HTTP and clipped to it:
#   - streams, lakes, railway and PSCIS assessments from the BC Data Catalogue
#     with bcdata, queried by a rectangle and filtered here;
#   - roads from bcfishpass's public GeoParquet copy of the Digital Road Atlas
#     `transport_line`, the only no-database source carrying
#     `transport_line_type_code`, which the registry's `roads_dra` style
#     classifies on (the catalogue's web layer carries `ROAD_CLASS` instead).
#
# Everything is worked in BC Albers and transformed to WGS 84 at the end.

library(sf)

# A read that fails partway can return the rows it got with only a warning, which
# would bundle a short layer. Treat any warning as a failed read: note it in the
# handler and stop once the call has returned, since GDAL's warnings arrive from C++.
read_strict <- function(expr, what) {
  warned <- character()
  x <- withCallingHandlers(expr, warning = function(w) {
    warned <<- c(warned, conditionMessage(w))
    invokeRestart("muffleWarning")
  })
  if (length(warned) > 0) {
    stop("reading ", what, " warned, so it may be incomplete: ",
         paste(warned, collapse = "; "), call. = FALSE)
  }
  x
}

ws <- st_read("data-raw/bittner_wsd.gpkg", quiet = TRUE)
stopifnot(nrow(ws) == 1L, st_crs(ws) == st_crs(3005), all(st_is_valid(ws)))
wsg <- st_geometry(ws)

# The watershed's bounding box grown by `d` metres on every side, as PostGIS's
# ST_Expand() gave the earlier database queries.
box <- function(d) {
  b <- st_bbox(wsg)
  b[c("xmin", "ymin")] <- b[c("xmin", "ymin")] - d
  b[c("xmax", "ymax")] <- b[c("xmax", "ymax")] + d
  st_as_sfc(b)
}

# Features of a catalogue layer that intersect `area`. The query sends only the
# rectangle around `area`; the exact test happens here.
bcdc_within <- function(record, area) {
  q_box <- st_as_sfc(st_bbox(area))
  x <- read_strict(
    bcdata::bcdc_query_geodata(record) |>
      bcdata::filter(bcdata::INTERSECTS(q_box)) |>
      bcdata::collect(),
    record
  )
  stopifnot(st_crs(x) == st_crs(3005))
  x[lengths(st_intersects(x, area)) > 0, ]
}

# -- Watershed polygon --
bittner_wsd <- st_sf(
  area_ha = ws$area_ha,
  geom = st_transform(st_simplify(wsg, preserveTopology = TRUE, dTolerance = 50), 4326)
)

# -- Streams (order >= 2, no subsurface or construction-line edges, clipped) --
s <- bcdc_within("WHSE_BASEMAPPING.FWA_STREAM_NETWORKS_SP", wsg)
s <- s[!s$EDGE_TYPE %in% c(1100, 1200, 1300, 1400, 1500, 1600) &
         s$STREAM_ORDER >= 2, ]
bittner_streams <- st_sf(
  gnis_name = s$GNIS_NAME,
  stream_order = as.integer(s$STREAM_ORDER),
  geom = st_transform(st_intersection(st_geometry(s), wsg), 4326)
)

# -- Lakes (whole polygons that touch the watershed) --
l <- bcdc_within("WHSE_BASEMAPPING.FWA_LAKES_POLY", wsg)
bittner_lakes <- st_sf(
  name = l$GNIS_NAME_1,
  area_ha = as.numeric(st_area(l)) / 10000,
  geom = st_transform(st_cast(st_geometry(l), "MULTIPOLYGON"), 4326)
)

# -- Roads (DRA, within 5 km of the watershed's box) --
# The GDAL that sf links is often built without the Parquet driver, so the
# rectangle is cut out with the command-line ogr2ogr, which must have it. The
# file has no bbox column, so GDAL still reads every row group (~36 s, 2026-11-11).
road_types <- c("RH1", "RA1", "RA2", "RC2", "RLO")
road_box <- box(5000)
fmts <- suppressWarnings(system2("ogrinfo", "--formats", stdout = TRUE, stderr = TRUE))
if (!is.null(attr(fmts, "status")) || !any(grepl("^\\s*Parquet ", fmts))) {
  stop("the command-line ogrinfo/ogr2ogr needs GDAL's Parquet driver for the roads",
       call. = FALSE)
}
road_gpkg <- tempfile(fileext = ".gpkg")
out <- suppressWarnings(system2("ogr2ogr", c(
  "-f", "GPKG", road_gpkg,
  "/vsicurl/https://nrs.objectstore.gov.bc.ca/bchamp/bcdata/whse_basemapping.transport_line.parquet",
  "-spat", st_bbox(road_box)[c("xmin", "ymin", "xmax", "ymax")],
  "-where", shQuote(sprintf("transport_line_type_code IN (%s)",
                            paste0("'", road_types, "'", collapse = ", "))),
  "-select", "transport_line_type_code",
  "-nln", "roads"
), stdout = TRUE, stderr = TRUE))
if (!is.null(attr(out, "status")) || any(grepl("ERROR", out))) {
  stop("ogr2ogr could not read transport_line:\n", paste(out, collapse = "\n"),
       call. = FALSE)
}
r <- read_strict(st_read(road_gpkg, quiet = TRUE), "transport_line")
stopifnot(st_crs(r) == st_crs(3005), nrow(r) > 0)
r <- r[lengths(st_intersects(r, road_box)) > 0, ]
bittner_roads <- st_sf(
  road_type = r$transport_line_type_code,
  geom = st_transform(
    st_cast(st_simplify(st_geometry(r), dTolerance = 20), "MULTILINESTRING"),
    4326
  )
)

# -- Railway (within 5 km of the watershed's box) --
rw <- bcdc_within("WHSE_BASEMAPPING.GBA_RAILWAY_TRACKS_SP", box(5000))
bittner_railway <- st_sf(
  track_classification = rw$TRACK_CLASSIFICATION,
  geom = st_transform(
    st_cast(st_simplify(st_geometry(rw), dTolerance = 20), "MULTILINESTRING"),
    4326
  )
)

# -- PSCIS assessments (within 2 km of the watershed's box) --
p <- bcdc_within("WHSE_FISH.PSCIS_ASSESSMENT_SVW", box(2000))
bittner_pscis <- st_sf(
  stream_crossing_id = as.integer(p$STREAM_CROSSING_ID),
  road_name = p$ROAD_NAME,
  stream_name = p$STREAM_NAME,
  barrier_result_code = p$BARRIER_RESULT_CODE,
  geom = st_transform(st_cast(st_geometry(p), "MULTIPOINT"), 4326)
)

# An earlier pull, simplified without preserving topology, came out invalid
# ("Edge 145 crosses edge 148"): gq-intro's st_difference() mask then fails at
# the pkgdown build, far from here. The watershed is now simplified with
# preserveTopology = TRUE; refuse to save an invalid one regardless.
stopifnot(all(st_is_valid(bittner_wsd)))

# Save
usethis::use_data(
  bittner_wsd, bittner_streams, bittner_lakes,
  bittner_roads, bittner_railway, bittner_pscis,
  overwrite = TRUE
)
