# The registry stores QGIS marker sizes in millimetres. Every backend has to
# convert them into its own units, and until #16 both did it with a guessed
# constant -- tmap divided by 3, mapgl divided by nothing. These tests pin the
# conversion to a measured physical quantity instead.

skip_if_no_tmap <- function() testthat::skip_if_not_installed("tmap")


test_that("one tmap size unit is 5.08 mm, and that is measured not assumed", {
  skip_if_no_tmap()
  skip_if_not_installed("sf")
  local_tmap_scale(1)

  pts <- sf::st_sf(id = 1, geometry = sf::st_sfc(sf::st_point(c(0, 0)),
                                                 crs = 3005))
  m <- tmap::tm_shape(pts) + tmap::tm_symbols(size = 1)

  # This is the constant gq_symbol_size() is built on. If tmap ever changes it,
  # this test names the cause instead of leaving every map subtly wrong.
  expect_equal(drawn_pt_mm(m), TMAP_MM_PER_SIZE, tolerance = 0.01)

  # Canvas-independent -- which is what makes a fixed conversion correct rather
  # than a calibration that would have to know the figure dimensions.
  expect_equal(drawn_pt_mm(m, width = 14, height = 12), TMAP_MM_PER_SIZE,
               tolerance = 0.01)

  # Linear in diameter, not area.
  m_half <- tmap::tm_shape(pts) + tmap::tm_symbols(size = 0.5)
  expect_equal(drawn_pt_mm(m_half), TMAP_MM_PER_SIZE / 2, tolerance = 0.01)
})

test_that("tmap's global scale multiplies the constant", {
  skip_if_no_tmap()
  skip_if_not_installed("sf")
  # Not a curiosity: it means an absolute-millimetre assertion is only valid at
  # scale = 1, and that gq deliberately does NOT compensate -- a caller who
  # scales a whole map expects the symbols to scale with the text.
  pts <- sf::st_sf(id = 1, geometry = sf::st_sfc(sf::st_point(c(0, 0)),
                                                 crs = 3005))
  m <- tmap::tm_shape(pts) + tmap::tm_symbols(size = 1)

  local_tmap_scale(2)
  expect_equal(drawn_pt_mm(m), TMAP_MM_PER_SIZE * 2, tolerance = 0.02)
})

test_that("gq_symbol_size converts millimetres to each target's units", {
  # The registry value is a QGIS marker EXTENT -- a diameter. tmap size is a
  # diameter too, so that conversion is a straight unit change. mapgl's
  # circle-radius is a true radius in CSS pixels, so it also halves.
  expect_equal(gq_symbol_size(5.08, "tmap"), 1)
  expect_equal(gq_symbol_size(3, "tmap"), 3 / 5.08, tolerance = 1e-6)
  expect_equal(gq_symbol_size(2, "mapgl"), 2 / 2 * 96 / 25.4, tolerance = 1e-6)

  # A 3 mm QGIS marker must draw as 3 mm.
  expect_equal(gq_symbol_size(3, "tmap") * TMAP_MM_PER_SIZE, 3,
               tolerance = 1e-6)
})

test_that("gq_symbol_size scale is a uniform multiplier", {
  expect_equal(gq_symbol_size(3, "tmap", scale = 0.5),
               gq_symbol_size(3, "tmap") / 2)
  expect_equal(gq_symbol_size(3, "mapgl", scale = 2),
               gq_symbol_size(3, "mapgl") * 2)
  # Vectorised, because a classified layer converts a whole named vector and
  # must keep its names -- tm_scale_categorical matches values by name.
  v <- c(BARRIER = 3, PASSABLE = 2)
  out <- gq_symbol_size(v, "tmap")
  expect_named(out, c("BARRIER", "PASSABLE"))
  expect_equal(unname(out), c(3, 2) / 5.08, tolerance = 1e-6)
})

test_that("gq_symbol_size tolerates a layer with no radius", {
  # crossings_pscis_modelled_dams is a rule_based renderer with no mark block at
  # all, so NULL reaches here from real registry data, not just in theory.
  expect_null(gq_symbol_size(NULL, "tmap"))
  expect_true(is.na(gq_symbol_size(NA_real_, "tmap")))
  expect_error(gq_symbol_size(3, "leaflet"), "target")
})

test_that("gq_symbol_shape maps every shape the registry actually holds", {
  # circle, square, star and triangle are the complete vocabulary in
  # reg_main.json -- verified across all three registry files.
  expect_equal(gq_symbol_shape("circle", "tmap"), 21)
  expect_equal(gq_symbol_shape("square", "tmap"), 22)
  expect_equal(gq_symbol_shape("triangle", "tmap"), 24)

  # star has no FILLABLE pch -- 21-25 are circle, square, diamond, triangle-up,
  # triangle-down. pch 8 draws a star and ignores fill. Mapping it to a circle
  # would silently lose the distinction that made form_pscis a star.
  expect_equal(gq_symbol_shape("star", "tmap"), 8)

  expect_null(gq_symbol_shape(NULL, "tmap"))
  expect_warning(gq_symbol_shape("hexagon", "tmap"), "unknown")
})

test_that("gq_symbol_shape reports that mapgl cannot express shape", {
  # A MapLibre `circle` layer has no shape concept; anything else needs a
  # `symbol` layer with an icon sprite. Returning NULL and saying so beats
  # returning a pch number that means nothing to the renderer.
  expect_null(gq_symbol_shape("square", "mapgl"))
})

test_that("a registry point layer draws at its QGIS millimetre size", {
  skip_if_no_tmap()
  skip_if_not_installed("sf")
  local_tmap_scale(1)
  reg <- gq_reg_main()

  # The end-to-end property, and the one that matters: what the registry says in
  # millimetres is what lands on the page. Both of these are hardcoded in
  # gq-tmap-composition.Rmd today precisely because this did not hold.
  for (key in c("fiss_obstacles", "bcfishobs_fiss_fish_observations")) {
    mm <- reg$layers[[key]]$mark$radius
    pts <- sf::st_sf(id = 1, geometry = sf::st_sfc(sf::st_point(c(0, 0)),
                                                   crs = 3005))
    args <- gq_tmap_style(reg, key)
    m <- tmap::tm_shape(pts) + do.call(tmap::tm_symbols, args)
    expect_equal(drawn_pt_mm(m), mm, tolerance = 0.05,
                 label = paste(key, "drawn diameter"))
  }
})
