poly <- list(
  type = "polygon",
  fill = list(color = "#c6ddf0", opacity = 0.85),
  stroke = list(color = "#7ba7cc", width = 0.4)
)
line <- list(type = "line", stroke = list(color = "#000000", width = 1.2))
pt <- list(type = "point", mark = list(color = "#e74c3c", radius = 3))

classified <- list(
  type = "line",
  classification = list(
    field = "road_type",
    classes = list(
      RH1 = list(color = "#c0392b", width = 2.0, label = "Highway"),
      RA1 = list(color = "#e67e22", width = 1.8, label = "Arterial"),
      RA2 = list(color = "#f1c40f", width = 1.4, label = "Secondary")
    )
  )
)

mini <- function(...) list(layers = list(...))


# --- partitioning -------------------------------------------------------------

test_that("gq_tmap_legend partitions layers by geometry type", {
  reg <- mini(lake = poly, railway = line, falls = pt)
  leg <- gq_tmap_legend(reg, c("lake", "railway", "falls"))

  expect_named(leg, c("polygons", "lines", "symbols"))
  expect_equal(leg$polygons$type, "polygons")
  expect_equal(leg$lines$type, "lines")
  expect_equal(leg$symbols$type, "symbols")
})

test_that("gq_tmap_legend omits geometry types that are not present", {
  leg <- gq_tmap_legend(mini(lake = poly), "lake")
  expect_named(leg, "polygons")
})

test_that("simple and classified layers merge into one geometry group", {
  # The case the hand-written pattern gets wrong: a plain line layer and a
  # classified one are two tm_add_legend() calls unless something merges them.
  reg <- mini(railway = line, roads = classified)
  leg <- gq_tmap_legend(reg, c("railway", "roads"))

  expect_named(leg, "lines")
  expect_equal(leg$lines$labels, c("Railway", "Highway", "Arterial", "Secondary"))
  expect_equal(leg$lines$col,
               c("#000000", "#c0392b", "#e67e22", "#f1c40f"))
  expect_equal(leg$lines$lwd, c(1.2, 2.0, 1.8, 1.4))
})


# --- labels -------------------------------------------------------------------

test_that("an unnamed key becomes a title-cased label", {
  leg <- gq_tmap_legend(mini(lake = poly), "lake")
  expect_equal(leg$polygons$labels, "Lake")
})

test_that("names override the derived label", {
  leg <- gq_tmap_legend(mini(lake = poly), c("Waterbody" = "lake"))
  expect_equal(leg$polygons$labels, "Waterbody")
})

test_that("registry class labels win over the key", {
  leg <- gq_tmap_legend(mini(roads = classified), "roads")
  expect_equal(leg$lines$labels, c("Highway", "Arterial", "Secondary"))
})


# --- present filtering --------------------------------------------------------

test_that("present cuts classified entries to the values in the data", {
  # A legend naming classes the map does not draw is quiet and common.
  reg <- mini(roads = classified)
  leg <- gq_tmap_legend(reg, "roads", present = list(roads = c("RH1", "RA2")))

  expect_equal(leg$lines$labels, c("Highway", "Secondary"))
  expect_equal(leg$lines$col, c("#c0392b", "#f1c40f"))
})

test_that("a layer with no present values drops out entirely", {
  reg <- mini(lake = poly, roads = classified)
  leg <- gq_tmap_legend(reg, c("lake", "roads"),
                        present = list(roads = "NOT_A_CLASS"))
  expect_named(leg, "polygons")
})

test_that("present only affects the layer it names", {
  reg <- mini(railway = line, roads = classified)
  leg <- gq_tmap_legend(reg, c("railway", "roads"),
                        present = list(roads = "RH1"))
  expect_equal(leg$lines$labels, c("Railway", "Highway"))
})


# --- argument shape -----------------------------------------------------------

test_that("returned lists are ready for do.call(tm_add_legend, x)", {
  leg <- gq_tmap_legend(mini(lake = poly), "lake")
  expect_type(leg$polygons, "list")
  expect_true(all(nzchar(names(leg$polygons))))
  expect_equal(leg$polygons$fill, "#c6ddf0")
  expect_equal(leg$polygons$col, "#7ba7cc")
})

test_that("parallel vectors are equal length across aesthetics", {
  # tm_add_legend() sets item count from the longest vector, so a short one
  # recycles silently into the wrong row.
  leg <- gq_tmap_legend(mini(railway = line, roads = classified),
                        c("railway", "roads"))
  n <- length(leg$lines$labels)
  for (p in setdiff(names(leg$lines), "type")) {
    expect_length(leg$lines[[p]], n)
  }
})

test_that("a non-scalar legend property is refused, not flattened", {
  # Found by probing rather than by the suite: unlist() would splice the extra
  # element in and shift every later entry against its label. The equal-length
  # assertion above does not catch it, because every vector grows by the same
  # amount. Nothing built from a registry can reach this -- every registry
  # property is scalar -- which is exactly why the fixtures missed it.
  rows <- list(
    list(type = "lines", label = "A", col = "#111111", lwd = 1),
    list(type = "lines", label = "B", col = c("#222222", "#333333"), lwd = 2)
  )
  expect_error(collect_legend(rows), "not length 1")
})

test_that("an aesthetic absent from every row is dropped, not passed as NA", {
  # tmap reads an explicit NA as "draw nothing" for some aesthetics, so an
  # all-NA vector is not the same as omitting the argument.
  leg <- gq_tmap_legend(mini(railway = line), "railway")
  expect_false("lty" %in% names(leg$lines))
})

test_that("titles and extra arguments pass through", {
  leg <- gq_tmap_legend(mini(lake = poly), "lake",
                        titles = c(polygons = "Waterbodies"),
                        z = 3, group_id = "context")
  expect_equal(leg$polygons$title, "Waterbodies")
  expect_equal(leg$polygons$z, 3)
  expect_equal(leg$polygons$group_id, "context")
})

test_that("extra arguments reach every geometry group", {
  leg <- gq_tmap_legend(mini(lake = poly, railway = line),
                        c("lake", "railway"), z = 2)
  expect_equal(leg$polygons$z, 2)
  expect_equal(leg$lines$z, 2)
})


# --- errors -------------------------------------------------------------------

test_that("gq_tmap_legend rejects empty and unsupported input", {
  expect_error(gq_tmap_legend(mini(lake = poly), character(0)), "at least one")
  expect_error(
    gq_tmap_legend(mini(odd = list(type = "raster")), "odd"),
    "unsupported type"
  )
  expect_error(gq_tmap_legend(mini(lake = poly), "nope"), "not found")
})


# --- against the shipped registry ---------------------------------------------

test_that("gq_tmap_legend works on the real registry", {
  reg <- gq_reg_main()
  leg <- gq_tmap_legend(reg, c("lake", "railway", "roads_dra"))
  expect_named(leg, c("polygons", "lines"))
  expect_equal(leg$polygons$labels, "Lake")
  expect_equal(leg$lines$labels[[1]], "Railway")

  # roads_dra has 26 classes carrying 8 distinct appearances -- nine of them all
  # reading "Resource/recreation/other" in one colour and width. A legend lists
  # appearances, not source classes, so the group is railway + 8, not + 26.
  expect_equal(length(leg$lines$labels), 9L)
  expect_equal(anyDuplicated(leg$lines$labels), 0L)
})

test_that("rows that differ anywhere are kept, not collapsed", {
  # The dedup must not merge two things a reader could tell apart.
  same_label_diff_colour <- list(
    type = "line",
    classification = list(field = "f", classes = list(
      A = list(color = "#111111", width = 1, label = "Road"),
      B = list(color = "#222222", width = 1, label = "Road"),
      C = list(color = "#222222", width = 1, label = "Road")
    ))
  )
  leg <- gq_tmap_legend(mini(x = same_label_diff_colour), "x")
  expect_equal(length(leg$lines$labels), 2L)      # B and C collapse, A stays
  expect_equal(leg$lines$col, c("#111111", "#222222"))
})

test_that("layers that differ in which aesthetics they carry still render", {
  # Found by rendering the vignette, not by the suite. `lake` has a stroke and
  # `wetland` does not, so a legend naming both emitted col = c("#1f78b4", NA)
  # and lwd = c(0.2, NA). tmap rejects that at draw time with "missing value
  # where TRUE/FALSE needed", from inside its legend builder, naming nothing.
  # Same shape as the lty case one aesthetic over.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  leg <- gq_tmap_legend(reg, c("lake", "wetland"))
  expect_false(any(is.na(leg$polygons$col)))
  expect_false(any(is.na(leg$polygons$lwd)))

  pts <- sf::st_as_sf(data.frame(x = c(0, 1), y = c(0, 1)),
                      coords = c("x", "y"), crs = 3005)
  m <- tmap::tm_shape(pts) + tmap::tm_dots() +
    do.call(tmap::tm_add_legend, leg$polygons)
  f <- tempfile(fileext = ".png")
  expect_no_error({
    grDevices::png(f)
    on.exit(grDevices::dev.off(), add = TRUE)
    print(m)
  })
})

test_that("a partly-dashed classified layer renders through tmap", {
  # The gap 18 list-inspecting tests left open: dash_to_lty() returns NULL for
  # an undashed class, so a layer with some dashed classes emitted
  # lty = c(NA, ..., "dashed") and tm_add_legend() rejected the whole vector at
  # DRAW time. Inspecting the structure could never see it -- the consumer has
  # to be asked.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  pts <- sf::st_as_sf(data.frame(x = c(0, 1), y = c(0, 1)),
                      coords = c("x", "y"), crs = 3005)
  for (k in c("roads_dra", "streams_all")) {
    leg <- gq_tmap_legend(reg, k)
    expect_false(any(is.na(leg$lines$lty)))
    m <- tmap::tm_shape(pts) + tmap::tm_dots() +
      do.call(tmap::tm_add_legend, leg$lines)
    f <- tempfile(fileext = ".png")
    expect_no_error({
      grDevices::png(f)
      on.exit(grDevices::dev.off(), add = TRUE)
      print(m)
    })
  }
})

test_that("classified point layers carry their per-class size", {
  # crossings_pscis_assessment is the only registry layer with a per-class
  # radius, and it is the central point layer of every fish passage map. The
  # radius lives on the NESTED classification; gq_tmap_classes() does not
  # return it, so reading it from there dropped size entirely and tmap
  # silently substituted a default.
  reg <- gq_reg_main()
  leg <- gq_tmap_legend(reg, "crossings_pscis_assessment")
  expect_true("size" %in% names(leg$symbols))
  expect_length(leg$symbols$size, length(leg$symbols$labels))
  expect_true(all(leg$symbols$size > 0))
})

test_that("every registry layer, and all of them at once, produce no NA", {
  # The test that would have caught the fill_alpha gap, and the only shape that
  # covers an aesthetic nobody thought to name. Every other test in this file
  # picks layers by hand, so it can only find what was already suspected.
  #
  # "Some rows have it and some do not" IS the failure condition, so checking
  # for NA is sufficient and needs no graphics device.
  reg <- gq_reg_main()
  keys <- names(reg$layers)

  for (k in keys) {
    leg <- gq_tmap_legend(reg, k)
    for (g in leg) {
      bad <- vapply(g[setdiff(names(g), "type")],
                    function(v) any(is.na(v)), logical(1))
      expect_false(any(bad), info = paste(k, paste(names(bad)[bad], collapse = ", ")))
    }
  }

  # and every layer together, which is where mixed-aesthetic rows meet
  leg <- gq_tmap_legend(reg, keys)
  for (g in leg) {
    bad <- vapply(g[setdiff(names(g), "type")],
                  function(v) any(is.na(v)), logical(1))
    expect_false(any(bad), info = paste(names(bad)[bad], collapse = ", "))
  }
})

test_that("the whole-registry legend renders through tmap", {
  # The consumer check for the sweep above. gq_tmap_legend(reg, c("lake",
  # "fire_severity")) inspected fine and failed at draw time with the identical
  # message the NA-default fix was written to remove.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  pts <- sf::st_as_sf(data.frame(x = c(0, 1), y = c(0, 1)),
                      coords = c("x", "y"), crs = 3005)
  leg <- gq_tmap_legend(reg, names(reg$layers))
  m <- Reduce(`+`, c(list(tmap::tm_shape(pts) + tmap::tm_dots()),
                     lapply(leg, function(x) do.call(tmap::tm_add_legend, x))))
  f <- tempfile(fileext = ".png")
  expect_no_error({
    grDevices::png(f)
    on.exit(grDevices::dev.off(), add = TRUE)
    print(m)
  })
})

test_that("the dedup key does not depend on str() display options", {
  # The key was capture.output(str(...)) -- a display function. A line in
  # someone's .Rprofile could change what this function returns, and the failure
  # was a quiet merge rather than an error.
  reg <- gq_reg_main()
  before <- gq_tmap_legend(reg, "roads_dra")$lines
  old <- options(str = utils::strOptions(digits.d = 1))
  on.exit(options(old), add = TRUE)
  expect_identical(gq_tmap_legend(reg, "roads_dra")$lines, before)
})

test_that("close-but-distinct widths are not merged", {
  # str() rounded numerics to 3 significant digits, so 1.2345 and 1.2349 keyed
  # identically. No registry layer trips it today; the point is that it cannot.
  layer <- list(type = "line", classification = list(field = "f", classes = list(
    A = list(color = "#484848", width = 1.2345, label = "Road"),
    B = list(color = "#484848", width = 1.2349, label = "Road")
  )))
  expect_equal(length(gq_tmap_legend(mini(x = layer), "x")$lines$labels), 2L)
})
