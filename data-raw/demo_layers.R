# Create small demo sf layers for vignette and examples
# Fictional features loosely placed in central BC

library(sf)

# -- Watershed polygons (2 zones) --
watershed <- st_sf(
  name = c("Elk Creek", "Pine River"),
  watershed = c("Zone A", "Zone B"),
  area_km2 = c(145, 230),
  geometry = st_sfc(
    st_polygon(list(matrix(c(
      -122.80, 54.00,
      -122.80, 54.10,
      -122.60, 54.12,
      -122.50, 54.05,
      -122.60, 53.98,
      -122.80, 54.00
    ), ncol = 2, byrow = TRUE))),
    st_polygon(list(matrix(c(
      -122.50, 54.05,
      -122.60, 54.12,
      -122.40, 54.15,
      -122.30, 54.08,
      -122.35, 54.00,
      -122.50, 54.05
    ), ncol = 2, byrow = TRUE))),
    crs = 4326
  )
)

# -- Lakes (3 small polygons) --
lake <- st_sf(
  name = c("Moose Lake", "Pine Lake", "Elk Pond"),
  geometry = st_sfc(
    st_polygon(list(matrix(c(
      -122.70, 54.04,
      -122.69, 54.05,
      -122.67, 54.045,
      -122.68, 54.035,
      -122.70, 54.04
    ), ncol = 2, byrow = TRUE))),
    st_polygon(list(matrix(c(
      -122.45, 54.08,
      -122.44, 54.09,
      -122.42, 54.085,
      -122.43, 54.075,
      -122.45, 54.08
    ), ncol = 2, byrow = TRUE))),
    st_polygon(list(matrix(c(
      -122.55, 54.06,
      -122.54, 54.065,
      -122.53, 54.06,
      -122.54, 54.055,
      -122.55, 54.06
    ), ncol = 2, byrow = TRUE))),
    crs = 4326
  )
)

# -- Streams (4 lines) --
stream <- st_sf(
  gnis_name = c("Elk Creek", "Pine Creek", "Moose Creek", "South Fork"),
  stream_order = c(5L, 4L, 3L, 6L),
  geometry = st_sfc(
    st_linestring(matrix(c(
      -122.78, 54.02, -122.72, 54.04, -122.65, 54.05, -122.58, 54.06
    ), ncol = 2, byrow = TRUE)),
    st_linestring(matrix(c(
      -122.48, 54.10, -122.44, 54.08, -122.40, 54.07
    ), ncol = 2, byrow = TRUE)),
    st_linestring(matrix(c(
      -122.70, 54.08, -122.65, 54.06, -122.60, 54.05
    ), ncol = 2, byrow = TRUE)),
    st_linestring(matrix(c(
      -122.75, 54.00, -122.68, 54.03, -122.60, 54.05, -122.50, 54.06, -122.42, 54.08
    ), ncol = 2, byrow = TRUE)),
    crs = 4326
  )
)

# -- Roads (3 segments, classified) --
road <- st_sf(
  road_name = c("Highway 16", "Elk Valley Rd", "Pine Forest Rd"),
  road_type = c("highway", "arterial", "local"),
  geometry = st_sfc(
    st_linestring(matrix(c(
      -122.80, 54.03, -122.60, 54.05, -122.40, 54.07, -122.30, 54.09
    ), ncol = 2, byrow = TRUE)),
    st_linestring(matrix(c(
      -122.65, 54.01, -122.63, 54.04, -122.60, 54.07, -122.55, 54.10
    ), ncol = 2, byrow = TRUE)),
    st_linestring(matrix(c(
      -122.50, 54.03, -122.48, 54.06, -122.45, 54.09
    ), ncol = 2, byrow = TRUE)),
    crs = 4326
  )
)

# -- Crossings (5 points, classified) --
crossing <- st_sf(
  crossing_id = c(101, 102, 103, 104, 105),
  status = c("passable", "barrier", "unknown", "passable", "barrier"),
  geometry = st_sfc(
    st_point(c(-122.72, 54.04)),
    st_point(c(-122.60, 54.05)),
    st_point(c(-122.48, 54.07)),
    st_point(c(-122.55, 54.06)),
    st_point(c(-122.44, 54.08)),
    crs = 4326
  )
)

# Save to data/
usethis::use_data(watershed, lake, stream, road, crossing, overwrite = TRUE)
