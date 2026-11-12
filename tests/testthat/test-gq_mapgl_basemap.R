skip_if_not_installed("mapgl")
skip_if_not_installed("sf")

line_3005 <- function() {
  g <- sf::st_sfc(
    sf::st_linestring(rbind(c(1e6, 1e6, 5), c(1e6 + 500, 1e6 + 300, 6))),
    sf::st_linestring(rbind(c(1e6 + 500, 1e6 + 300, 6), c(1e6 + 900, 1e6 + 800, 7))),
    crs = 3005
  )
  sf::st_sf(stream_order = c(1L, 6L), geometry = g)
}

test_that("gq_mapgl_basemap fits the view to x, in rounded EPSG:4326", {
  x <- line_3005()
  m <- gq_mapgl_basemap(x, digits = 5L)
  expect_s3_class(m, "maplibregl")
  want <- as.numeric(sf::st_bbox(sf::st_transform(sf::st_zm(x), 4326)))
  expect_equal(as.numeric(m$x$additional_params$bounds), round(want, 5), tolerance = 1e-9)
  # a bbox gives the same view as the geometry it bounds, for a rectangle
  bb <- sf::st_bbox(sf::st_transform(sf::st_zm(x), 4326))
  expect_equal(as.numeric(gq_mapgl_basemap(bb)$x$additional_params$bounds),
               round(as.numeric(bb), 5), tolerance = 1e-9)
})

test_that("gq_mapgl_basemap names each basemap's style", {
  x <- line_3005()
  expect_match(gq_mapgl_basemap(x, "voyager")$x$style, "voyager")
  expect_match(gq_mapgl_basemap(x, "positron")$x$style, "positron")
  expect_match(gq_mapgl_basemap(x, "openfreemap")$x$style, "liberty")
  esri <- gq_mapgl_basemap(x, "esri_topo")$x$style
  expect_equal(esri$sources$esri_topo$type, "raster")
  expect_match(esri$sources$esri_topo$attribution, "Powered by .*Esri")
})

test_that("gq_mapgl_basemap refuses what it cannot fit", {
  x <- line_3005()
  expect_error(gq_mapgl_basemap(x, "google"), "should be one of")
  expect_error(gq_mapgl_basemap(data.frame(a = 1)), "sf, an sfc or a bbox")
  expect_error(gq_mapgl_basemap(x[0, ]), "no geometry")
  expect_error(gq_mapgl_basemap(x, digits = 1.5), "whole number")
})

test_that("round_sfc rounds every coordinate and keeps structure", {
  g <- sf::st_sfc(sf::st_polygon(list(rbind(c(0.123456789, 0), c(1, 0.987654321),
                                            c(0, 1), c(0.123456789, 0)))), crs = 4326)
  r <- round_sfc(g, 3)
  expect_s3_class(r, "sfc_POLYGON")
  expect_identical(unclass(r[[1]])[[1]][1, 1], 0.123)
  expect_identical(sf::st_crs(r), sf::st_crs(g))
})

test_that("mapgl_data keeps attributes and gives a bare geometry an id", {
  x <- line_3005()
  d <- mapgl_data(x, 5L)
  expect_identical(names(d), c("stream_order", "geometry"))
  expect_identical(sf::st_crs(d)$epsg, 4326L)
  expect_false(any(grepl("Z", class(sf::st_geometry(d)[[1]]))))
  bare <- mapgl_data(sf::st_geometry(x), 5L)
  expect_identical(bare$id, 1:2)
})

test_that("gq_mapgl_network styles water from `lake` and streams from `streams_all`", {
  reg <- gq_reg_main()
  ring <- rbind(c(1e6, 1e6), c(1e6 + 200, 1e6), c(1e6 + 200, 1e6 + 200), c(1e6, 1e6))
  water <- sf::st_sf(kind = "lake", geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = 3005))
  m <- gq_mapgl_basemap(line_3005()) |>
    gq_mapgl_network(streams = line_3005(), water = water, reg = reg)
  ids <- vapply(m$x$layers, `[[`, "", "id")
  expect_identical(ids, c("gq_water", "gq_streams"))         # water under streams
  lake <- gq_mapgl_style(reg$layers$lake)$paint
  w <- m$x$layers[[1]]$paint
  expect_identical(w[["fill-color"]], lake[["fill-color"]])
  expect_identical(w[["fill-opacity"]], lake[["fill-opacity"]])
  expect_identical(w[["fill-outline-color"]], lake[["fill-outline-color"]])
  s <- m$x$layers[[2]]$paint
  first <- reg$layers$streams_all$classification$classes[[1]]
  expect_identical(s[["line-color"]], first$color)          # no feature_code: first class
  expect_identical(s[["line-opacity"]], first$opacity)
  expect_identical(s[["line-width"]],
                   mapgl::interpolate("stream_order", values = c(1, 6), stops = c(0.6, 3)))
})

test_that("gq_mapgl_network colours by class when the network carries feature_code", {
  reg <- gq_reg_main()
  st <- line_3005()
  st$feature_code <- c("GA24850000", "GA24850150")
  m <- gq_mapgl_basemap(st) |> gq_mapgl_network(streams = st, reg = reg)
  p <- m$x$layers[[1]]$paint
  expect_identical(p[["line-color"]], gq_mapgl_classes(reg$layers$streams_all, "line-color"))
  expect_identical(p[["line-opacity"]], gq_mapgl_classes(reg$layers$streams_all, "line-opacity"))
})

test_that("gq_mapgl_network takes either input alone, and custom ids", {
  st <- line_3005()
  m0 <- gq_mapgl_basemap(st)
  expect_identical(gq_mapgl_network(m0)$x, m0$x)
  m <- gq_mapgl_network(m0, streams = st, ids = c(streams = "net"))
  expect_identical(vapply(m$x$layers, `[[`, "", "id"), "net")
  expect_identical(m$x$sources[[1]]$id, "net")
})

test_that("gq_mapgl_network refuses a network it cannot scale", {
  st <- line_3005()
  names(st)[1] <- "order"
  expect_error(gq_mapgl_network(gq_mapgl_basemap(st), streams = st), "order_field")
  expect_error(gq_mapgl_network(gq_mapgl_basemap(st), streams = st, order_field = "order",
                                widths = c(1, NA)), "two positive numbers")
})

test_that("gq_mapgl_network can legend what it draws, and does not by default", {
  ring <- rbind(c(1e6, 1e6), c(1e6 + 200, 1e6), c(1e6 + 200, 1e6 + 200), c(1e6, 1e6))
  water <- sf::st_sf(kind = "lake", geometry = sf::st_sfc(sf::st_polygon(list(ring)), crs = 3005))
  m0 <- gq_mapgl_basemap(line_3005())
  expect_null(gq_mapgl_network(m0, streams = line_3005(), water = water)$x$legend_html)
  m <- gq_mapgl_network(m0, streams = line_3005(), water = water, legend = TRUE)
  expect_match(m$x$legend_html, 'data-layer-id="gq_water".*Lake')
  expect_match(m$x$legend_html, 'data-layer-id="gq_streams".*Stream')
  expect_match(m$x$legend_html, "legend-shape-line")
})

test_that("a projected bbox fits the whole area, not only its corners", {
  bb <- sf::st_bbox(c(xmin = 400000, ymin = 400000, xmax = 1800000, ymax = 1700000), crs = 3005)
  dense <- sf::st_segmentize(sf::st_as_sfc(bb), 1000)
  want <- as.numeric(sf::st_bbox(sf::st_transform(dense, 4326)))
  got <- as.numeric(gq_mapgl_basemap(bb)$x$additional_params$bounds)
  expect_gt(got[4], 60.2)                                       # corners alone gave 59.87
  expect_equal(got, want, tolerance = 1e-3)
  # the same rectangle as an sfc or sf fits the same (round 2)
  expect_identical(as.numeric(gq_mapgl_basemap(sf::st_as_sfc(bb))$x$additional_params$bounds), got)
  as_sf <- sf::st_sf(geometry = sf::st_as_sfc(bb))
  expect_identical(as.numeric(gq_mapgl_basemap(as_sf)$x$additional_params$bounds), got)
})

test_that("an extent with no size still fits: one projected point, as a bbox or an sf", {
  p <- sf::st_sf(a = 1, geometry = sf::st_sfc(sf::st_point(c(1200000, 1000000)), crs = 3005))
  from_sf <- as.numeric(gq_mapgl_basemap(p)$x$additional_params$bounds)
  expect_identical(as.numeric(gq_mapgl_basemap(sf::st_bbox(p))$x$additional_params$bounds), from_sf)
  expect_identical(from_sf[1], from_sf[3])
})

test_that("an extent whose geometries are all empty is refused", {
  e <- sf::st_sf(a = 1, geometry = sf::st_sfc(sf::st_point(), crs = 3005))
  expect_error(gq_mapgl_basemap(e), "no geometry")
})
