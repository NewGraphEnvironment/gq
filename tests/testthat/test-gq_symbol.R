# The registry stores QGIS marker sizes in millimetres. Every backend has to
# convert them into its own units, and until #16 both did it with a guessed
# constant -- tmap divided by 3, mapgl divided by nothing.
#
# These tests measure the DRAWN PRIMITIVE, not the value handed to the grob.
# The first version of this file did the latter and was circular: it read back
# `pointsGrob$size`, reported 5.08 mm for a symbol that draws 3.81 mm, and a
# whole conversion was derived from that number. Ask the renderer what it drew.

skip_if_no_tmap <- function() testthat::skip_if_not_installed("tmap")

one_point <- function() {
  sf::st_sf(id = 1, geometry = sf::st_sfc(sf::st_point(c(0, 0)), crs = 3005))
}


test_that("tmap draws a circle at 0.75 of its nominal size", {
  skip_if_no_tmap()
  skip_if_not_installed("sf")
  skip_if_not_installed("svglite")
  local_tmap_scale(1)

  # tmap sizes symbols in grid "lines" (12pt * 1.2 = 5.08 mm), but R's graphics
  # engine multiplies by a per-pch factor. This is the gap that made the first
  # attempt 25% undersized while documenting itself as exact.
  m <- tmap::tm_shape(one_point()) + tmap::tm_symbols(size = 1, shape = 21)
  expect_equal(drawn_symbol_mm(m), 3.81, tolerance = 0.01)
  expect_false(isTRUE(all.equal(drawn_symbol_mm(m), 5.08, tolerance = 0.01)))

  # Linear, and independent of the canvas.
  m_half <- tmap::tm_shape(one_point()) + tmap::tm_symbols(size = 0.5,
                                                           shape = 21)
  expect_equal(drawn_symbol_mm(m_half), 3.81 / 2, tolerance = 0.01)
  expect_equal(drawn_symbol_mm(m, width = 14, height = 12), 3.81,
               tolerance = 0.01)
})

test_that("each pch draws a different extent at the same nominal size", {
  skip_if_no_tmap()
  skip_if_not_installed("sf")
  skip_if_not_installed("svglite")
  local_tmap_scale(1)

  # Base R normalises pch 21-25 by AREA; QGIS normalises by EXTENT. So one
  # divisor cannot serve every shape, which is why gq_symbol_size() takes it.
  sq <- tmap::tm_shape(one_point()) + tmap::tm_symbols(size = 1, shape = 22)
  tr <- tmap::tm_shape(one_point()) + tmap::tm_symbols(size = 1, shape = 24)
  expect_equal(drawn_symbol_mm(sq, "square"), 3.376, tolerance = 0.01)
  expect_equal(drawn_symbol_mm(tr, "triangle"), 5.129, tolerance = 0.01)
  # A square is ~11% smaller than a circle at the same size. Sizing a square
  # with the circle constant is the bug this guards.
  expect_lt(drawn_symbol_mm(sq, "square"), 3.81)
})

test_that("tmap's global scale multiplies the drawn size", {
  skip_if_no_tmap()
  skip_if_not_installed("sf")
  skip_if_not_installed("svglite")
  # Means an absolute-millimetre assertion is only valid at scale = 1, and that
  # gq deliberately does NOT compensate -- a caller scaling a whole map expects
  # the symbols to scale with the text.
  m <- tmap::tm_shape(one_point()) + tmap::tm_symbols(size = 1, shape = 21)
  local_tmap_scale(2)
  expect_equal(drawn_symbol_mm(m), 3.81 * 2, tolerance = 0.02)
})

test_that("gq_symbol_size converts millimetres per shape", {
  # tmap: divide by the millimetres of ink that shape draws per size unit.
  expect_equal(gq_symbol_size(3.81, "tmap"), 1, tolerance = 1e-4)
  expect_equal(gq_symbol_size(3, "tmap", shape = "square"),
               3 / 3.3761, tolerance = 1e-3)
  expect_true(gq_symbol_size(3, "tmap", shape = "square") >
                gq_symbol_size(3, "tmap", shape = "circle"))

  # mapgl: circle-radius is a true radius in CSS pixels, so it halves. A
  # definition, not a measurement -- and shape does not apply.
  expect_equal(gq_symbol_size(2, "mapgl"), 2 / 2 * 96 / 25.4, tolerance = 1e-6)
  expect_equal(gq_symbol_size(2, "mapgl", shape = "square"),
               gq_symbol_size(2, "mapgl"))
})

test_that("gq_symbol_size scale is a uniform multiplier", {
  expect_equal(gq_symbol_size(3, "tmap", scale = 0.5),
               gq_symbol_size(3, "tmap") / 2)
  expect_equal(gq_symbol_size(3, "mapgl", scale = 2),
               gq_symbol_size(3, "mapgl") * 2)
  # Vectorised and name-preserving, because a classified layer converts a whole
  # named vector and tm_scale_categorical() matches values by name.
  out <- gq_symbol_size(c(BARRIER = 3, PASSABLE = 2), "tmap")
  expect_named(out, c("BARRIER", "PASSABLE"))
  expect_equal(unname(out), c(3, 2) / 3.81, tolerance = 1e-3)
})

test_that("gq_symbol_size tolerates a layer with no radius", {
  # crossings_pscis_modelled_dams is a rule_based renderer with no mark block at
  # all, so NULL reaches here from real registry data, not just in theory.
  expect_null(gq_symbol_size(NULL, "tmap"))
  expect_true(is.na(gq_symbol_size(NA_real_, "tmap")))
  expect_error(gq_symbol_size(3, "leaflet"), "target")
  expect_warning(gq_symbol_size(3, "tmap", shape = "hexagon"), "unknown")
})

test_that("gq_symbol_shape maps every shape the registry actually holds", {
  # circle, square, star and triangle are the complete vocabulary across all
  # three registry files.
  expect_equal(gq_symbol_shape("circle", "tmap"), 21)
  expect_equal(gq_symbol_shape("square", "tmap"), 22)
  expect_equal(gq_symbol_shape("triangle", "tmap"), 24)
  expect_equal(gq_symbol_shape("star", "tmap"), 8)

  expect_null(gq_symbol_shape(NULL, "tmap"))
  expect_warning(gq_symbol_shape("hexagon", "tmap"), "unknown")
  # A MapLibre `circle` layer has no shape concept.
  expect_null(gq_symbol_shape("square", "mapgl"))
})

test_that("a star is reported as unfillable, and keeps its colour", {
  skip_if_no_tmap()
  # pch 8 is stroked only and ignores `fill`. A caller setting only `fill` gets
  # tmap's default outline and the layer silently loses its registry colour.
  expect_false(gq_symbol_fillable("star"))
  expect_true(gq_symbol_fillable("circle"))
  expect_true(gq_symbol_fillable(NULL))

  reg <- gq_reg_main()
  args <- gq_tmap_style(reg, "form_pscis")     # the registry's only star
  expect_equal(args$shape, 8)
  expect_equal(args$col, reg$layers$form_pscis$mark$color)
})

test_that("every registry point layer draws at its QGIS millimetre size", {
  skip_if_no_tmap()
  skip_if_not_installed("sf")
  skip_if_not_installed("svglite")
  local_tmap_scale(1)
  reg <- gq_reg_main()

  # The property the issue is about, asserted on drawn ink, one layer per shape
  # so the per-shape factors are all exercised. This fails at four values
  # against a single circle-derived constant and cannot be fixed by a comment.
  cases <- list(
    list(key = "crossings_pscis_design", kind = "circle"),
    list(key = "fiss_obstacles", kind = "square"),
    list(key = "bcfishobs_fiss_fish_observations", kind = "triangle"),
    list(key = "form_pscis", kind = "star")
  )
  for (cs in cases) {
    mm <- reg$layers[[cs$key]]$mark$radius
    expect_equal(reg$layers[[cs$key]]$mark$shape, cs$kind)  # premise
    args <- gq_tmap_style(reg, cs$key)
    m <- tmap::tm_shape(one_point()) + do.call(tmap::tm_symbols, args)
    expect_equal(drawn_symbol_mm(m, cs$kind), mm, tolerance = 0.05,
                 label = paste(cs$key, "drawn extent"))
  }
})
