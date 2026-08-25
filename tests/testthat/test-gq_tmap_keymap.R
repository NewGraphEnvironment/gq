box_sfc <- function(xmin, ymin, xmax, ymax) {
  sf::st_as_sfc(sf::st_bbox(
    c(xmin = xmin, ymin = ymin, xmax = xmax, ymax = ymax), crs = 3005
  ))
}

aoi <- function() box_sfc(1.0e6, 9.0e5, 1.1e6, 1.0e6)
context <- function() box_sfc(0.5e6, 5.0e5, 1.8e6, 1.4e6)


# --- placement arithmetic (no device needed) ----------------------------------

test_that("keymap_viewport puts each corner an equal margin from the edge", {
  # A viewport is positioned by its CENTRE, which is why every copy of this
  # carries different-looking magic numbers that all mean the same thing.
  w <- 0.25
  h <- 0.22
  m <- 0.03

  br <- keymap_viewport("bottomright", w, h, m)
  bl <- keymap_viewport("bottomleft", w, h, m)
  tr <- keymap_viewport("topright", w, h, m)
  tl <- keymap_viewport("topleft", w, h, m)

  expect_equal(as.numeric(br$x), 1 - w / 2 - m)
  expect_equal(as.numeric(br$y), h / 2 + m)
  expect_equal(as.numeric(bl$x), w / 2 + m)
  expect_equal(as.numeric(tl$y), 1 - h / 2 - m)

  # right corners mirror left, top mirrors bottom
  expect_equal(as.numeric(br$x) + as.numeric(bl$x), 1)
  expect_equal(as.numeric(tr$y) + as.numeric(br$y), 1)
})

test_that("keymap_viewport keeps the inset inside the device", {
  for (corner in c("bottomright", "bottomleft", "topright", "topleft")) {
    vp <- keymap_viewport(corner, 0.25, 0.22, 0.03)
    expect_gte(as.numeric(vp$x) - 0.25 / 2, 0)
    expect_lte(as.numeric(vp$x) + 0.25 / 2, 1)
    expect_gte(as.numeric(vp$y) - 0.22 / 2, 0)
    expect_lte(as.numeric(vp$y) + 0.22 / 2, 1)
  }
})

test_that("keymap_viewport margin is the gap to the frame, not to the centre", {
  # The distinction the hardcoded copies blur. Growing the inset must not
  # change its distance from the edge.
  small <- keymap_viewport("bottomright", 0.20, 0.20, 0.05)
  large <- keymap_viewport("bottomright", 0.40, 0.40, 0.05)
  gap <- function(vp, w) 1 - (as.numeric(vp$x) + w / 2)
  expect_equal(gap(small, 0.20), gap(large, 0.40))
  expect_equal(gap(small, 0.20), 0.05)
})


# --- the returned object ------------------------------------------------------

test_that("gq_tmap_keymap returns a tmap object and a viewport", {
  skip_if_not_installed("tmap")
  km <- gq_tmap_keymap(aoi(), context())

  expect_named(km, c("map", "viewport"))
  expect_s3_class(km$map, "tmap")
  expect_s3_class(km$viewport, "viewport")
})

test_that("gq_tmap_keymap defaults to the bottom-right corner", {
  skip_if_not_installed("tmap")
  km <- gq_tmap_keymap(aoi(), context())
  expect_equal(as.numeric(km$viewport$x), 1 - 0.25 / 2 - 0.03)
  expect_equal(as.numeric(km$viewport$y), 0.22 / 2 + 0.03)
})

test_that("gq_tmap_keymap honours corner and size", {
  skip_if_not_installed("tmap")
  km <- gq_tmap_keymap(aoi(), context(), corner = "topleft",
                       width = 0.3, height = 0.3, margin = 0.05)
  expect_equal(as.numeric(km$viewport$x), 0.3 / 2 + 0.05)
  expect_equal(as.numeric(km$viewport$y), 1 - 0.3 / 2 - 0.05)
  expect_equal(as.numeric(km$viewport$width), 0.3)
})

test_that("gq_tmap_keymap takes its colours from the registry", {
  # Every copy this replaces hardcodes hex here -- including one that accepts a
  # registry argument and then never reads it.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  expect_silent(km <- gq_tmap_keymap(aoi(), context(), reg = reg))
  expect_s3_class(km$map, "tmap")

  # a key that is not in the registry must fail loudly rather than draw grey
  expect_error(
    gq_tmap_keymap(aoi(), context(), reg = reg, aoi_layer = "not_a_layer"),
    "not found"
  )
})

test_that("gq_tmap_keymap rejects an unknown corner", {
  skip_if_not_installed("tmap")
  expect_error(gq_tmap_keymap(aoi(), context(), corner = "middle"), "arg")
})
