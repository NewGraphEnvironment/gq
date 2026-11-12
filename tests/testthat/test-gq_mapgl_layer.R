skip_if_not_installed("mapgl")
skip_if_not_installed("sf")

pts <- function() {
  g <- sf::st_sfc(sf::st_point(c(-126.5, 54.4)), sf::st_point(c(-126.4, 54.45)),
                  sf::st_point(c(-126.45, 54.5)), crs = 4326)
  sf::st_sf(sp = c("CO", "RB", "CO"), n = c(1, NA, 3), geometry = g)
}
polys <- function(code = c("SBS", "ESSF")) {
  sq <- function(o) sf::st_polygon(list(rbind(c(o, 0), c(o + 1, 0), c(o + 1, 1), c(o, 1), c(o, 0))))
  sf::st_sf(ZONE = code, geometry = sf::st_sfc(lapply(seq_along(code), sq), crs = 4326))
}
base <- function(x = pts()) gq_mapgl_basemap(x)
ids <- function(m) vapply(m$x$layers, `[[`, "", "id")

test_that("a single colour draws a circle layer with its legend", {
  m <- base() |> gq_mapgl_layer("co", pts(), color = "#FF7F00", radius = 6,
                                legend_title = "Coho")
  l <- m$x$layers[[1]]
  expect_identical(l$type, "circle")
  expect_identical(l$source, "co")
  expect_identical(l$paint[["circle-color"]], "#FF7F00")       # hex passes through as typed
  expect_identical(l$paint[["circle-radius"]], 6)
  expect_match(m$x$legend_html, 'id="legend_co"')
  expect_match(m$x$legend_html, 'data-layer-id="co"')
  expect_match(m$x$legend_html, "Coho")
})

test_that("an R colour name reaches MapLibre as hex, and NA is refused", {
  m <- base() |> gq_mapgl_layer("a", pts(), color = "grey80")
  expect_identical(m$x$layers[[1]]$paint[["circle-color"]], "#CCCCCC")
  expect_identical(to_hex(c("#1b6ca8", "steelblue", "#11223344")),
                   c("#1b6ca8", "#4682B4", "#11223344"))
  expect_error(gq_mapgl_layer(base(), "a", pts(), color = NA), "missing colour")
  expect_error(gq_mapgl_layer(base(), "a", pts(), color = "notacolour"), "not a colour")
  expect_identical(to_hex(grDevices::rgb(1, 0, 0, 0.5)), "#FF000080")
})

test_that("caller classes keep their value type and default", {
  cls <- list(field = "code", values = 1:2, colors = c("#111111", "#222222"),
              labels = c("one", "two"))
  coded <- pts()
  coded$code <- c(1L, 2L, 1L)
  m <- base() |> gq_mapgl_layer("k", coded, classes = cls)
  col <- m$x$layers[[1]]$paint[["circle-color"]]
  expect_identical(col[[3]], 1L)                               # integers stay integers
  expect_identical(col[[length(col)]], "#cccccc")              # the default
  expect_match(m$x$legend_html, "one")
  expect_error(gq_mapgl_layer(base(), "k", coded, classes = cls[1:2]), "colors")
  expect_error(gq_mapgl_layer(base(), "k", coded,
                              classes = modifyList(cls, list(colors = "#111111"))), "one colour per value")
})

test_that("a classified registry layer takes its colours, opacity and legend from the registry", {
  reg <- gq_reg_main()
  m <- base(polys()) |> gq_mapgl_layer("bec", polys(), key = "bec_zone", reg = reg)
  p <- m$x$layers[[1]]$paint
  expect_identical(m$x$layers[[1]]$type, "fill")
  expect_identical(p[["fill-color"]], gq_mapgl_classes(reg$layers$bec_zone, "fill-color"))
  expect_identical(p[["fill-opacity"]], 0.25)                  # #107
  expect_match(m$x$legend_html, "SBS")
  # field override, as gq_style() takes it
  renamed <- polys()
  names(renamed)[1] <- "zone"
  m2 <- base(renamed) |> gq_mapgl_layer("bec", renamed, key = "bec_zone", reg = reg, field = "zone")
  expect_identical(m2$x$layers[[1]]$paint[["fill-color"]][[2]], list("get", "zone"))
  # without `field`, the match would read a column no feature has (round 2)
  expect_error(gq_mapgl_layer(base(renamed), "bec", renamed, key = "bec_zone", reg = reg),
               "no `ZONE` column.*field =")
})

test_that("a mixed-opacity registry layer gets an opacity expression on its field", {
  reg <- gq_reg_main()
  g <- sf::st_sfc(sf::st_linestring(rbind(c(-126.5, 54.4), c(-126.4, 54.5))), crs = 4326)
  ln <- sf::st_sf(road = "RH1", geometry = g)
  m <- base(ln) |> gq_mapgl_layer("roads", ln, key = "roads_dra", reg = reg, field = "road")
  op <- m$x$layers[[1]]$paint[["line-opacity"]]
  expect_identical(op[[1]], "match")
  expect_identical(op[[2]], list("get", "road"))
})

test_that("a simple registry layer takes its paint", {
  reg <- gq_reg_main()
  m <- base(polys("x")) |> gq_mapgl_layer("lake", polys("x"), key = "lake", reg = reg)
  want <- gq_mapgl_style(reg$layers$lake)$paint
  p <- m$x$layers[[1]]$paint
  expect_identical(p[["fill-color"]], want[["fill-color"]])
  expect_identical(p[["fill-opacity"]], want[["fill-opacity"]])
  expect_identical(p[["fill-outline-color"]], want[["fill-outline-color"]])
  expect_error(gq_mapgl_layer(base(), "x", pts(), key = "lake", reg = reg), "polygon layer")
  expect_error(gq_mapgl_layer(base(), "x", pts(), key = "lake"), "needs `reg`")
})

test_that("two layers can draw one source, and the second legend is added to the first", {
  m <- base() |>
    gq_mapgl_layer("a", pts(), source = "s", color = "#111111") |>
    gq_mapgl_layer("b", source = "s", color = "#222222", visible = FALSE)
  expect_length(m$x$sources, 1L)
  expect_identical(vapply(m$x$layers, `[[`, "", "source"), c("s", "s"))
  expect_identical(m$x$layers[[2]]$type, "circle")             # read from the layer drawing "s"
  expect_identical(m$x$layers[[2]]$layout$visibility, "none")
  expect_false(startsWith(m$x$legend_html, " "))               # first legend: add = FALSE
  expect_match(m$x$legend_html, "legend_a.*legend_b")
  expect_error(gq_mapgl_layer(base(), "c", source = "nope", color = "#000000"), "no source")
})

test_that("width by stream order, a radius expression, popup and extra arguments", {
  g <- sf::st_sfc(sf::st_linestring(rbind(c(-126.5, 54.4), c(-126.4, 54.5))), crs = 4326)
  ln <- sf::st_sf(stream_order = 3L, geometry = g)
  ln$x <- "a"
  m <- base(ln) |> gq_mapgl_layer("s", ln, color = "#000000", width = "stream_order", popup = "x")
  expect_identical(m$x$layers[[1]]$paint[["line-width"]],
                   mapgl::interpolate("stream_order", values = c(1, 6), stops = c(0.6, 3)))
  expect_identical(m$x$layers[[1]]$popup, "x")
  r <- list("interpolate", list("linear"), list("zoom"), 6, 3, 16, 8)
  m <- base() |> gq_mapgl_layer("p", pts(), color = "#000000", radius = r,
                                circle_stroke_color = "#222222", legend = FALSE)
  expect_identical(m$x$layers[[1]]$paint[["circle-radius"]], r)
  expect_identical(m$x$layers[[1]]$paint[["circle-stroke-color"]], "#222222")
  expect_null(m$x$legend_html)
})

test_that("gq_mapgl_layer refuses ambiguous or empty input", {
  expect_error(gq_mapgl_layer(base(), "a", pts()), "exactly one")
  expect_error(gq_mapgl_layer(base(), "a", pts(), color = "#000000", key = "lake"), "exactly one")
  expect_error(gq_mapgl_layer(base(), "a", pts()[0, ], color = "#000000"), "no rows")
  expect_error(gq_mapgl_layer(base(), "", pts(), color = "#000000"), "non-empty")
  g <- sf::st_sfc(sf::st_linestring(rbind(c(0, 0), c(1, 1))), crs = 4326)
  mixed <- rbind(pts()[1, "sp"], sf::st_sf(sp = "x", geometry = g))
  expect_error(gq_mapgl_layer(base(), "a", mixed, color = "#000000"), "mixed")
})

test_that("legends get CSS-safe ids, one stacking stylesheet, and a one-colour row has no title", {
  m <- base() |>
    gq_mapgl_layer("rainbow trout", pts(), color = "#377EB8") |>
    gq_mapgl_layer("coho", pts(), color = "#FF7F00")
  expect_match(m$x$legend_html, 'id="legend_rainbow_trout"')
  expect_match(m$x$legend_html, 'data-layer-id="rainbow trout"')   # still tied to the layer id
  expect_match(m$x$legend_html, "<h2></h2>")                        # untitled
  stack <- vapply(m$prepend, function(x) identical(attr(x, "gq"), "legend_stack"), logical(1))
  expect_identical(sum(stack), 1L)                                  # once, not per legend
  expect_match(as.character(m$prepend[[which(stack)]]), "position: static")
  # classes keep their title
  cls <- list(field = "sp", values = c("CO", "RB"), colors = c("#111111", "#222222"))
  m2 <- base() |> gq_mapgl_layer("k", pts(), classes = cls, legend_title = "Species")
  expect_match(m2$x$legend_html, "<h2>Species</h2>")
  # no legend, no stylesheet
  expect_null(gq_mapgl_layer(base(), "a", pts(), color = "#000000", legend = FALSE)$prepend)
})

test_that("a registry layer's legend lists only the classes in the data", {
  reg <- gq_reg_main()
  m <- base(polys("SBS")) |> gq_mapgl_layer("bec", polys("SBS"), key = "bec_zone", reg = reg)
  expect_match(m$x$legend_html, ">SBS<")
  expect_no_match(m$x$legend_html, ">ESSF<")
  # the colour expression still carries every class
  expect_identical(m$x$layers[[1]]$paint[["fill-color"]],
                   gq_mapgl_classes(reg$layers$bec_zone, "fill-color"))
  expect_error(gq_mapgl_layer(base(polys("XX")), "bec", polys("XX"), key = "bec_zone", reg = reg),
               "none of registry layer")
})

test_that("a legend keeps a shared look whichever of its keys the data holds", {
  # roads_dra's Highway is RRP, RH1 and RH2 under one look; collapsing looks before
  # the filter to the data's classes dropped the row for data with only RH1 (round 1)
  reg <- gq_reg_main()
  cls <- reg$layers$roads_dra$classification$classes
  hw <- names(cls)[vapply(cls, function(x) identical(x$label, "Highway"), logical(1))]
  expect_gt(length(hw), 1L)                                     # premise: a shared look
  later <- hw[length(hw)]
  mk <- function(code) {
    g <- sf::st_sfc(lapply(seq_along(code), function(i) {
      sf::st_linestring(rbind(c(-126.5, 54.4 + i / 100), c(-126.4, 54.5)))
    }), crs = 4326)
    sf::st_sf(transport_line_type_code = code, geometry = g)
  }
  m <- base(mk(later)) |> gq_mapgl_layer("r", mk(later), key = "roads_dra", reg = reg)
  expect_match(m$x$legend_html, ">Highway<")
  two <- mk(c(later, "RF"))
  m2 <- base(two) |> gq_mapgl_layer("r", two, key = "roads_dra", reg = reg)
  expect_match(m2$x$legend_html, ">Highway<")
})

test_that("a registry layer with no colour is refused, not drawn in MapLibre's default", {
  reg <- gq_reg_main()
  expect_null(gq_mapgl_style(reg$layers$crossings_pscis_modelled_dams)$paint[["circle-color"]])
  expect_error(gq_mapgl_layer(base(), "d", pts(), key = "crossings_pscis_modelled_dams",
                              reg = reg, legend = FALSE), "carries no colour")
})

test_that("a popup on a styled column leaves the style reading numbers", {
  g <- sf::st_sfc(sf::st_linestring(rbind(c(-126.5, 54.4), c(-126.4, 54.5))), crs = 4326)
  ln <- sf::st_sf(stream_order = 3L, geometry = g)
  pop <- gq_mapgl_popup(ln, c("Stream order" = "stream_order"))
  m <- base(ln) |> gq_mapgl_layer("s", pop$data, color = "#000000", width = "stream_order",
                                  popup = pop$expr)
  expect_match(m$x$sources[[1]]$data, '"stream_order":3[,}]')
})

test_that("a source or layer id already on the map is refused", {
  m <- base() |> gq_mapgl_layer("a", pts(), source = "s", color = "#111111")
  expect_error(gq_mapgl_layer(m, "b", pts(), source = "s", color = "#222222"), "already has a source")
  expect_error(gq_mapgl_layer(m, "a", source = "s", color = "#222222"), "already has a layer")
  g <- sf::st_sfc(sf::st_linestring(rbind(c(-126.5, 54.4), c(-126.4, 54.5))), crs = 4326)
  ln <- sf::st_sf(stream_order = 1L, geometry = g)
  n <- gq_mapgl_network(base(ln), streams = ln)
  expect_error(gq_mapgl_network(n, streams = ln), "already has a layer `gq_streams`")
  expect_error(gq_mapgl_layer(n, "gq_streams", ln, source = "x", color = "#000000"), "already has a layer")
})

# --- round 3: every check is made on the data drawn, whichever form it arrives in ---------------

test_that("a source already on the map is checked like `x`", {
  reg <- gq_reg_main()
  renamed <- polys()
  names(renamed)[1] <- "zone"
  m <- base(renamed) |> gq_mapgl_layer("a", renamed, source = "s", color = "#111111")
  expect_error(gq_mapgl_layer(m, "b", source = "s", key = "bec_zone", reg = reg),
               "no `ZONE` column.*field =")                     # was all grey, every class
  ok <- gq_mapgl_layer(m, "b", source = "s", key = "bec_zone", reg = reg, field = "zone")
  expect_match(ok$x$legend_html, ">SBS<")
  expect_match(ok$x$legend_html, ">ESSF<")
  mp <- base() |> gq_mapgl_layer("p", pts(), source = "pt", color = "#111111")
  expect_error(gq_mapgl_layer(mp, "l", source = "pt", key = "lake", reg = reg),
               "polygon layer, not a point one")                # was a fill layer over points
})

test_that("an explicit type must agree with the data", {
  expect_error(gq_mapgl_layer(base(), "a", pts(), color = "#000000", type = "fill"),
               "drawn as \"circle\"")
  expect_error(gq_mapgl_layer(base(), "a", pts(), key = "lake", reg = gq_reg_main(), type = "fill"),
               "drawn as \"circle\"")
})

test_that("a column the style reads must be in the data, and match its kind", {
  cls <- list(field = "nope", values = 1:2, colors = c("#111111", "#222222"))
  expect_error(gq_mapgl_layer(base(), "k", pts(), classes = cls), "no column `nope`")
  g <- sf::st_sfc(sf::st_linestring(rbind(c(-126.5, 54.4), c(-126.4, 54.5))), crs = 4326)
  ln <- sf::st_sf(order = 1L, geometry = g)
  expect_error(gq_mapgl_layer(base(ln), "s", ln, color = "#000000", width = "stream_order"),
               "no column `stream_order`")
  expect_error(gq_mapgl_layer(base(), "p", pts(), color = "#000000", popup = "nope"),
               "no column `nope`")
  num <- pts()
  num$sp <- c(1, 2, 1)
  txt <- list(field = "sp", values = c("1", "2"), colors = c("#111111", "#222222"))
  expect_error(gq_mapgl_layer(base(), "k", num, classes = txt), "holds numbers but its classes are strings")
})

test_that("the network's layers get the same checks", {
  reg <- gq_reg_main()
  g <- sf::st_sfc(sf::st_linestring(rbind(c(-126.5, 54.4), c(-126.4, 54.5))), crs = 4326)
  ln <- sf::st_sf(stream_order = 1L, geometry = g)
  expect_error(gq_mapgl_network(base(ln), streams = ln, water = polys("x"), ids = c(water = "x", streams = "x")),
               "already has a layer `x`")
  pt_streams <- pts()
  pt_streams$stream_order <- 1L
  expect_error(gq_mapgl_network(base(), streams = pt_streams), "drawn as \"circle\"|not a point")
  bad <- reg
  bad$layers$lake$fill$color <- NULL
  expect_error(gq_mapgl_network(base(polys("x")), water = polys("x"), reg = bad), "carries no colour")
  bad$layers$lake$type <- "line"
  expect_error(gq_mapgl_network(base(polys("x")), water = polys("x"), reg = bad), "line layer")
})

# --- round 4 ------------------------------------------------------------------------------------

test_that("a source gq cannot read is drawn as told, and never fetched", {
  m <- base() |>
    mapgl::add_vector_source("v", url = "https://example.invalid/tiles.json") |>
    mapgl::add_source("u", "http://127.0.0.1:9/never-fetched.geojson")
  expect_error(gq_mapgl_layer(m, "a", source = "v", color = "#000000"), "give `type`")
  v <- gq_mapgl_layer(m, "a", source = "v", color = "#000000", type = "line", source_layer = "streams")
  expect_identical(v$x$layers[[1]]$type, "line")
  u <- gq_mapgl_layer(m, "b", source = "u", key = "lake", reg = gq_reg_main())  # type from key
  expect_identical(u$x$layers[[1]]$type, "fill")
})

test_that("a line layer over polygons draws their outlines", {
  m <- base(polys("x")) |> gq_mapgl_layer("edge", polys("x"), color = "#2c3e50", type = "line")
  expect_identical(m$x$layers[[1]]$type, "line")
})

test_that("an expression for width, radius or opacity must read columns the data has", {
  g <- sf::st_sfc(sf::st_linestring(rbind(c(-126.5, 54.4), c(-126.4, 54.5))), crs = 4326)
  ln <- sf::st_sf(stream_order = 1L, geometry = g)
  w <- mapgl::interpolate("order", values = c(1, 6), stops = c(0.6, 3))
  expect_error(gq_mapgl_layer(base(ln), "s", ln, color = "#000000", width = w), "no column `order`")
  expect_error(gq_mapgl_layer(base(), "p", pts(), color = "#000000", radius = list("get", "size")),
               "no column `size`")
  expect_error(gq_mapgl_layer(base(), "p", pts(), color = "#000000", opacity = list("get", "alpha")),
               "no column `alpha`")
  # a zoom expression reads no column, and is fine
  z <- list("interpolate", list("linear"), list("zoom"), 6, 3, 16, 8)
  expect_identical(gq_mapgl_layer(base(), "p", pts(), color = "#000000", radius = z)$x$layers[[1]]$type,
                   "circle")
})

test_that("classes on TRUE and FALSE are refused: MapLibre cannot match them", {
  lg <- pts()
  lg$ok <- c(TRUE, FALSE, TRUE)
  cls <- list(field = "ok", values = c(TRUE, FALSE), colors = c("#111111", "#222222"))
  expect_error(gq_mapgl_layer(base(), "k", lg, classes = cls), "TRUE and FALSE")
})

# --- round 5 ------------------------------------------------------------------------------------

test_that("class values are checked whatever the source", {
  m <- base() |> mapgl::add_vector_source("v", url = "https://example.invalid/tiles.json")
  bool <- list(field = "ok", values = c(TRUE, FALSE), colors = c("#111111", "#222222"))
  expect_error(gq_mapgl_layer(m, "k", source = "v", type = "circle", classes = bool), "TRUE and FALSE")
  with_na <- modifyList(bool, list(field = "sp", values = c("CO", NA)))
  expect_error(gq_mapgl_layer(base(), "k", pts(), classes = with_na), "none missing")
  num <- pts()
  num$n <- c(1, 2, 1)
  frac <- modifyList(bool, list(field = "n", values = c(1.5, 2)))
  expect_error(gq_mapgl_layer(base(), "k", num, classes = frac), "whole numbers")
  dupe <- modifyList(bool, list(field = "n", values = c(1, 1)))
  expect_error(gq_mapgl_layer(base(), "k", num, classes = dupe), "unique")
})

test_that("an outline is allowed only where no registry style asserts a geometry", {
  reg <- gq_reg_main()
  expect_error(gq_mapgl_layer(base(polys("x")), "o", polys("x"), key = "streams_all", reg = reg,
                              type = "line"), "drawn as \"fill\"")
  p <- polys("x")
  p$stream_order <- 1L
  expect_error(gq_mapgl_network(base(p), streams = p), "drawn as \"fill\"")
})

test_that("a raster source is refused", {
  m <- base() |> mapgl::add_raster_source("r", tiles = "https://example.invalid/{z}/{x}/{y}.png")
  expect_error(gq_mapgl_layer(m, "a", source = "r", color = "#000000", type = "fill"), "raster")
})

# --- every reachable refusal is exercised (enumeration after round 5) ---------------------------

test_that("each input check refuses what it names", {
  reg <- gq_reg_main()
  expect_error(gq_mapgl_layer(base(), "a", data.frame(a = 1), color = "#000000"), "must be an sf")
  empty <- sf::st_sf(a = 1, geometry = sf::st_sfc(sf::st_point(), crs = 4326))
  expect_error(gq_mapgl_layer(base(), "a", empty, color = "#000000"), "no geometry to draw")
  none <- base() |> mapgl::add_source("z", pts()[0, ])
  expect_error(gq_mapgl_layer(none, "a", source = "z", color = "#000000"), "has no features")
  expect_error(gq_mapgl_layer(base(), "a", pts(), color = c("#000000", "#111111")), "one colour")
  cls <- list(field = "sp", values = c("CO", "RB"), colors = c("#111111", "#222222"))
  expect_error(gq_mapgl_layer(base(), "k", pts(), classes = modifyList(cls, list(labels = "x"))),
               "one label per value")
  expect_error(gq_mapgl_layer(base(), "k", pts(),
                              classes = modifyList(cls, list(values = as.Date(c("2020-01-01", "2020-01-02"))))),
               "text or whole numbers")
  expect_error(gq_mapgl_network(base(polys("x")), water = polys("x"), ids = c(streams = "s")),
               "name a water id")
  g <- sf::st_sfc(sf::st_linestring(rbind(c(-126.5, 54.4), c(-126.4, 54.5))), crs = 4326)
  ln <- sf::st_sf(stream_order = 1L, geometry = g)
  expect_error(gq_mapgl_network(base(ln), streams = ln, ids = c(water = "w")), "name a streams id")
  no_lake <- reg
  no_lake$layers$lake <- NULL
  expect_error(gq_mapgl_network(base(polys("x")), water = polys("x"), reg = no_lake),
               "no layer `lake`")
  expect_error(gq_mapgl_controls(base(), layers = 1), "layer ids")
  expect_error(gq_mapgl_popup(data.frame(a = 1), c(A = "a"), missing = NA), "one string")
})
