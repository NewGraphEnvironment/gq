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
  # railway plus every road class, in one lines group
  expect_gt(length(leg$lines$labels), 20)
  expect_equal(leg$lines$labels[[1]], "Railway")
})
