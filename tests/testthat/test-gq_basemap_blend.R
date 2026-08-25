# The blend arithmetic is tested against synthetic rasters with no network. The
# fetch wrapper is the only part that needs one, and it is skipped by default.

skip_if_no_terra <- function() testthat::skip_if_not_installed("terra")

r_const <- function(v, n = 4, nlyr = 1) {
  terra::rast(nrows = n, ncols = n, nlyrs = nlyr,
              vals = rep(v, length.out = n * n * nlyr))
}


test_that("blend_multiply leaves the basemap untouched at full brightness", {
  skip_if_no_terra()
  base <- r_const(200)
  white <- r_const(255)
  for (m in c("gamma", "weight")) {
    out <- blend_multiply(base, white, method = m, gamma = 0.5, weight = 0.35)
    expect_equal(unname(terra::values(out)[, 1]), rep(200, 16))
  }
})

test_that("the two operators differ at the same nominal strength", {
  # The claim this function exists to correct: one implementation documents the
  # gamma blend and the weight blend as "the same operator" with different
  # inputs. At a mid-grey relief they are 141 and 165 out of 200.
  skip_if_no_terra()
  base <- r_const(200)
  relief <- r_const(128)

  g <- terra::values(blend_multiply(base, relief, "gamma", 0.5, 0.35))[1]
  w <- terra::values(blend_multiply(base, relief, "weight", 0.5, 0.35))[1]

  expect_false(isTRUE(all.equal(g, w)))
  expect_lt(g, w)   # gamma darkens harder than a 0.35 cap
})

test_that("weight caps how much brightness can ever be removed", {
  # The property the weight operator is chosen for: a contrasty DEM hillshade
  # cannot turn the map into a greyscale DEM with lines on it.
  skip_if_no_terra()
  base <- r_const(200)
  black <- r_const(0)
  out <- blend_multiply(base, black, "weight", 0.5, weight = 0.35)
  expect_equal(unname(terra::values(out)[, 1]), rep(200 * 0.65, 16))

  # gamma has no such floor
  out_g <- blend_multiply(base, black, "gamma", 0.5, 0.35)
  expect_equal(unname(terra::values(out_g)[, 1]), rep(0, 16))
})

test_that("lower gamma shades more lightly", {
  skip_if_no_terra()
  base <- r_const(200)
  relief <- r_const(128)
  light <- terra::values(blend_multiply(base, relief, "gamma", 0.2, 0.35))[1]
  heavy <- terra::values(blend_multiply(base, relief, "gamma", 1.0, 0.35))[1]
  expect_gt(light, heavy)
})

test_that("relief scale is detected rather than assumed", {
  # terra::shade() gives 0-1 and a tile service gives 0-255. Treating one as the
  # other either blackens the map or does nothing, and both inputs are in use.
  skip_if_no_terra()
  base <- r_const(200)

  half_255 <- blend_multiply(base, r_const(128), "weight", 0.5, 0.35)
  half_01 <- blend_multiply(base, r_const(0.5), "weight", 0.5, 0.35)
  expect_equal(terra::values(half_255)[1], terra::values(half_01)[1],
               tolerance = 0.01)

  # explicit override wins over detection
  forced <- blend_multiply(base, r_const(0.5), "weight", 0.5, 0.35,
                           relief_max = 255)
  expect_lt(terra::values(forced)[1], terra::values(half_01)[1])
})

test_that("multi-band relief is averaged to one band", {
  skip_if_no_terra()
  base <- r_const(200)
  rgb <- r_const(c(0, 255, 128), nlyr = 3)
  out <- blend_multiply(base, rgb, "weight", 0.5, 0.35)
  expect_equal(terra::nlyr(out), 1L)
  expect_false(any(is.na(terra::values(out))))
})

test_that("mismatched relief grid is resampled onto the basemap", {
  skip_if_no_terra()
  base <- r_const(200, n = 8)
  coarse <- r_const(128, n = 2)
  out <- blend_multiply(base, coarse, "weight", 0.5, 0.35)
  expect_equal(dim(out)[1:2], dim(base)[1:2])
})

test_that("output is clamped to the 0-255 range", {
  skip_if_no_terra()
  hot <- r_const(400)
  out <- blend_multiply(hot, r_const(255), "gamma", 0.5, 0.35)
  expect_lte(max(terra::values(out)), 255)
})

test_that("gq_basemap_blend validates its arguments", {
  skip_if_no_terra()
  base <- r_const(200)
  relief <- r_const(128)
  expect_error(gq_basemap_blend(base, relief, weight = 2), "in \\[0, 1\\]")
  expect_error(gq_basemap_blend(base, relief, gamma = 0), "positive")
  expect_error(gq_basemap_blend(base, relief, method = "multiply"), "arg")
})

test_that("gq_basemap_blend returns stars for tm_rgb, SpatRaster otherwise", {
  skip_if_no_terra()
  skip_if_not_installed("stars")
  base <- r_const(200)
  relief <- r_const(128)
  expect_s4_class(gq_basemap_blend(base, relief, as_stars = FALSE),
                  "SpatRaster")
  expect_s3_class(gq_basemap_blend(base, relief, as_stars = TRUE), "stars")
})
