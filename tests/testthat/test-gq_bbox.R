asp_of <- function(b) {
  unname((b[["xmax"]] - b[["xmin"]]) / (b[["ymax"]] - b[["ymin"]]))
}

bb_proj <- function(w = 1e5, h = 1e5) {
  sf::st_bbox(c(xmin = 1e6, ymin = 9e5, xmax = 1e6 + w, ymax = 9e5 + h),
              crs = 3005)
}

bb_geo <- function() {
  sf::st_bbox(c(xmin = -127, ymin = 54, xmax = -126, ymax = 55), crs = 4326)
}


# --- gq_bbox_aspect -----------------------------------------------------------

test_that("gq_bbox_aspect hits the requested ratio in a projected CRS", {
  for (a in c(7 / 9, 9 / 7, 1)) {
    expect_equal(asp_of(gq_bbox_aspect(bb_proj(), asp = a)), a,
                 tolerance = 1e-9)
  }
})

test_that("gq_bbox_aspect pads the short side and keeps the extent centred", {
  bb <- bb_proj(w = 2e5, h = 1e5)          # too wide for a square canvas
  out <- gq_bbox_aspect(bb, asp = 1, margin = 0)

  # width untouched, height grown
  expect_equal(out[["xmin"]], bb[["xmin"]])
  expect_equal(out[["xmax"]], bb[["xmax"]])
  expect_lt(out[["ymin"]], bb[["ymin"]])
  expect_gt(out[["ymax"]], bb[["ymax"]])

  # symmetric, so the original centre is preserved
  mid <- function(b, a) (b[[paste0(a, "min")]] + b[[paste0(a, "max")]]) / 2
  expect_equal(mid(out, "y"), mid(bb, "y"))
  expect_equal(mid(out, "x"), mid(bb, "x"))
})

test_that("gq_bbox_aspect applies the latitude correction only when geographic", {
  # The difference the two implementations this replaces disagreed on. At 54.5N
  # a degree of longitude is ~0.58 of a degree of latitude, so a 1x1 degree box
  # is landscape on the ground and portrait in coordinates -- the two branches
  # therefore pad DIFFERENT axes for the same requested ratio.
  geo <- gq_bbox_aspect(bb_geo(), asp = 1, margin = 0)
  prj <- gq_bbox_aspect(
    sf::st_bbox(c(xmin = -127, ymin = 54, xmax = -126, ymax = 55), crs = 3005),
    asp = 1, margin = 0
  )

  # projected: already 1:1 in coordinates, nothing to do
  expect_equal(asp_of(prj), 1, tolerance = 1e-9)
  expect_equal(prj[["xmax"]] - prj[["xmin"]], 1, tolerance = 1e-9)

  # geographic: x span widened so the GROUND ratio is 1, not the coordinate one
  expect_gt(geo[["xmax"]] - geo[["xmin"]], 1)
  k <- cos(54.5 * pi / 180)
  ground <- (geo[["xmax"]] - geo[["xmin"]]) * k /
    (geo[["ymax"]] - geo[["ymin"]])
  expect_equal(unname(ground), 1, tolerance = 1e-9)
})

test_that("gq_bbox_aspect treats an unknown CRS as projected", {
  # st_is_longlat() gives NA here; NA must not propagate into the arithmetic.
  bare <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = 2, ymax = 1))
  expect_true(is.na(sf::st_is_longlat(bare)))
  out <- gq_bbox_aspect(bare, asp = 2, margin = 0)
  expect_false(any(is.na(unclass(out))))
  expect_equal(asp_of(out), 2, tolerance = 1e-9)
})

test_that("gq_bbox_aspect margin scales both dimensions and preserves the ratio", {
  plain <- gq_bbox_aspect(bb_proj(), asp = 7 / 9, margin = 0)
  padded <- gq_bbox_aspect(bb_proj(), asp = 7 / 9, margin = 0.1)
  expect_equal(asp_of(padded), asp_of(plain), tolerance = 1e-9)
  expect_gt(padded[["xmax"]] - padded[["xmin"]],
            plain[["xmax"]] - plain[["xmin"]])
})

test_that("gq_bbox_aspect accepts sf input and keeps the CRS", {
  pts <- sf::st_as_sf(data.frame(x = c(0, 1e5), y = c(0, 2e5)),
                      coords = c("x", "y"), crs = 3005)
  out <- gq_bbox_aspect(pts, asp = 1)
  expect_s3_class(out, "bbox")
  expect_equal(sf::st_crs(out), sf::st_crs(3005))
})

test_that("gq_bbox_aspect rejects bad arguments and degenerate extents", {
  expect_error(gq_bbox_aspect(bb_proj(), asp = 0), "positive")
  expect_error(gq_bbox_aspect(bb_proj(), asp = c(1, 2)), "positive")
  expect_error(gq_bbox_aspect(bb_proj(), asp = 1, margin = -1), "non-negative")
  expect_error(gq_bbox_aspect(bb_proj(w = 0), asp = 1), "zero or undefined")
})


# --- gq_bbox_clip -------------------------------------------------------------

pts_at <- function(xs, ys) {
  sf::st_as_sf(data.frame(x = xs, y = ys), coords = c("x", "y"), crs = 3005)
}

test_that("gq_bbox_clip keeps features inside the box", {
  out <- gq_bbox_clip(pts_at(c(0, 10), c(0, 10)), bb_proj_small <-
                        sf::st_bbox(c(xmin = -1, ymin = -1, xmax = 1, ymax = 1),
                                    crs = 3005))
  expect_s3_class(out, "sf")
  expect_equal(nrow(out), 1L)
})

test_that("gq_bbox_clip returns NULL rather than a zero-row object", {
  # The whole reason the function exists: tm_shape() errors on an empty
  # geometry set rather than skipping it, so callers need a NULL to test.
  far <- sf::st_bbox(c(xmin = 100, ymin = 100, xmax = 101, ymax = 101),
                     crs = 3005)
  expect_null(gq_bbox_clip(pts_at(c(0, 10), c(0, 10)), far))
  expect_null(gq_bbox_clip(NULL, far))

  # suppressWarnings on the FIXTURE, not the call: building a zero-row sf makes
  # sf warn from min()/max() over nothing. gq_bbox_clip() short-circuits on
  # nrow == 0 before touching sf, so the call itself is silent -- asserted here
  # so a future warning from inside the function is not absorbed by the setup.
  empty <- suppressWarnings(pts_at(numeric(0), numeric(0)))
  expect_silent(out <- gq_bbox_clip(empty, far))
  expect_null(out)
})

test_that("gq_bbox_clip selects whole features by default and cuts on request", {
  # A line crossing the boundary is the case where the two differ visibly.
  ln <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(sf::st_linestring(cbind(c(0, 10), c(0, 0))),
                          crs = 3005)
  )
  box <- sf::st_bbox(c(xmin = -1, ymin = -1, xmax = 1, ymax = 1), crs = 3005)

  kept <- gq_bbox_clip(ln, box)
  cut <- gq_bbox_clip(ln, box, crop = TRUE)

  len <- function(x) as.numeric(sf::st_length(x))
  expect_equal(len(kept), 10)   # whole feature survives
  expect_equal(len(cut), 1)     # truncated at the boundary
})

test_that("gq_bbox_clip accepts an sfc box", {
  box <- sf::st_as_sfc(
    sf::st_bbox(c(xmin = -1, ymin = -1, xmax = 1, ymax = 1), crs = 3005)
  )
  expect_equal(nrow(gq_bbox_clip(pts_at(c(0, 10), c(0, 10)), box)), 1L)
})


# --- gq_scale_breaks ----------------------------------------------------------

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

test_that("gq_bbox_aspect warns and clamps rather than leaving the globe", {
  # st_as_sfc() accepts latitude 94 without complaint, so an out-of-range box
  # travels a long way before anything objects -- a tile request for it simply
  # returns nothing.
  # Must be a case that pads the Y axis: a wide, short box at high latitude,
  # where cos(lat) makes the ground ratio large and the height has to grow.
  polar <- sf::st_bbox(c(xmin = -170, ymin = 85, xmax = -70, ymax = 86),
                       crs = 4326)
  expect_warning(out <- gq_bbox_aspect(polar, asp = 0.5), "past the CRS")
  expect_lte(out[["ymax"]], 90)
  expect_gte(out[["ymin"]], -90)

  # a projected box has no such bounds and must not warn
  expect_silent(gq_bbox_aspect(bb_proj(w = 1e6, h = 1e4), asp = 0.5))
})

