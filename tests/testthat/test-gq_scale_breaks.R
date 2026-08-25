bb_proj <- function(w = 1e5, h = 1e5) {
  sf::st_bbox(c(xmin = 1e6, ymin = 9e5, xmax = 1e6 + w, ymax = 9e5 + h),
              crs = 3005)
}


test_that("gq_scale_breaks returns n+1 breaks starting at zero", {
  br <- gq_scale_breaks(bb_proj(w = 1e5))
  expect_length(br, 4L)
  expect_equal(br[[1]], 0)
  expect_true(all(diff(br) == diff(br)[[1]]))
})

test_that("gq_scale_breaks lands on a 1/2/5 step", {
  steps <- vapply(c(2e4, 5e4, 1e5, 4e5, 1e6), function(w) {
    diff(gq_scale_breaks(bb_proj(w = w)))[[1]]
  }, numeric(1))
  mantissa <- steps / 10 ^ floor(log10(steps))
  expect_true(all(mantissa %in% c(1, 2, 5)))
})

test_that("gq_scale_breaks keeps the bar within its share of the frame", {
  # The constraint the `share` argument exists for. Overrun makes tmap drop
  # every label but the last, silently.
  for (w in c(2e4, 1e5, 4e5, 1e6)) {
    br <- gq_scale_breaks(bb_proj(w = w))
    span_km <- w / 1000
    expect_lt(max(br) / span_km, 0.75)
  }
})

test_that("gq_scale_breaks scales with n", {
  expect_length(gq_scale_breaks(bb_proj(), n = 2), 3L)
  expect_length(gq_scale_breaks(bb_proj(), n = 5), 6L)
})

test_that("gq_scale_breaks rejects bad arguments", {
  expect_error(gq_scale_breaks(bb_proj(), n = 0), "positive")
  expect_error(gq_scale_breaks(bb_proj(), share = 0), "in \\(0, 1\\]")
  expect_error(gq_scale_breaks(bb_proj(), share = 2), "in \\(0, 1\\]")
  expect_error(gq_scale_breaks(bb_proj(w = 0)), "zero or undefined")
})

test_that("share is a bound, not a target, across the whole mantissa range", {
  # Rounding to the NEAREST 1/2/5 overran share by up to 1.39x, and the original
  # test could not see it: the threshold was 0.75 against a share of 0.35, and
  # all four widths happened to round down. Sweep instead of hand-picking.
  for (w in seq(1e4, 1e6, by = 1e4)) {
    br <- gq_scale_breaks(bb_proj(w = w))
    expect_lte(max(br) / (w / 1000), 0.35)
  }
})

test_that("a geographic bbox is refused rather than answered in degrees", {
  # Degree spans through the same arithmetic give breaks of 0.0001 "km" -- 10 cm
  # -- shaped like a legitimate answer. There is no correct reading of that.
  geo <- sf::st_bbox(c(xmin = -127, ymin = 54, xmax = -126, ymax = 55),
                     crs = 4326)
  expect_error(gq_scale_breaks(geo), "must be projected")
})
