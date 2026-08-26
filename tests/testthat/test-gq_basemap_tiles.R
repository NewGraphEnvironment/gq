# gq_basemap_tiles() had no tests at all until #57, while the sibling file's
# header claimed the fetch wrapper was "skipped by default". There was no
# skipped test -- the comment described an intention nobody implemented, and a
# watermarked basemap shipped to the public site underneath it.
#
# What is testable offline is the flat-tile guard, and that is where the value
# is: it is the only placeholder class measurement showed to be detectable.

skip_if_no_terra <- function() testthat::skip_if_not_installed("terra")

r_const <- function(v, n = 4, nlyr = 1) {
  terra::rast(nrows = n, ncols = n, nlyrs = nlyr,
              vals = rep(v, length.out = n * n * nlyr))
}

# Bands held at DIFFERENT constants -- one flat colour, not one flat number.
r_solid <- function(vals, n = 4) {
  terra::rast(nrows = n, ncols = n, nlyrs = length(vals),
              vals = unlist(lapply(vals, rep, times = n * n)))
}


test_that("tile_is_flat spots a single-value tile", {
  skip_if_no_terra()
  # Esri.WorldTerrain over the vignette bbox returns exactly this: every pixel
  # 254, fetched without error. Measured sd 0.00, 1 unique value (#57).
  expect_true(tile_is_flat(r_const(254, nlyr = 3)))
  expect_true(tile_is_flat(r_const(0)))
})

test_that("tile_is_flat spots a solid colour whose bands differ", {
  skip_if_no_terra()
  # The band values are 0/0/255, so counting distinct NUMBERS across the raster
  # gives 2 and misses it. Flatness is a property of the pixel colour, not of
  # the value set -- comparing min to max PER BAND is what gets this right.
  expect_true(tile_is_flat(r_solid(c(0, 0, 255))))
  expect_true(tile_is_flat(r_solid(c(12, 200, 7))))
})

test_that("tile_is_flat treats an all-NA tile as flat", {
  skip_if_no_terra()
  # minmax() returns NaN here rather than erroring, so a bare min == max
  # comparison would give NA and fail an if(). A tile with no data is as broken
  # as a tile with one value.
  expect_true(tile_is_flat(r_const(NA_real_, nlyr = 3)))
})

test_that("tile_is_flat passes a file-backed raster with no cached statistics", {
  skip_if_no_terra()
  # Every other fixture here is built in memory by rast(vals = ), so all of them
  # have min/max cached and none can reach this. A file-backed raster has no
  # cached statistics, and minmax() then reports Inf/-Inf rather than computing
  # them -- so without compute = TRUE the guard calls this richly varied image
  # flat, and fires on every real tile.
  #
  # It survives against maptiles today only because get_tiles(crop = TRUE)
  # computes min/max on the way past. That is an upstream internal, not a
  # contract, which is exactly why the fixture has to be file-backed.
  png <- system.file("logo", "nge_icon_200.png", package = "gq")
  skip_if(png == "", "bundled logo not found")
  r <- suppressWarnings(terra::rast(png))
  expect_false(all(terra::hasMinMax(r)))   # the precondition the bug needs
  expect_false(tile_is_flat(r))
})

test_that("tile_is_flat passes a real basemap", {
  skip_if_no_terra()
  # The guard's whole value is that it does not fire on ordinary tiles. Every
  # real provider measured in #57 had >= 53 distinct luminances; the closest to
  # flat was Esri.WorldGrayCanvas at sd 3.28.
  set.seed(1)
  varied <- terra::rast(nrows = 8, ncols = 8, nlyrs = 3,
                        vals = stats::runif(192, 0, 255))
  expect_false(tile_is_flat(varied))

  # A tile that is constant except for one differing pixel is not flat.
  nearly <- r_const(200, n = 8, nlyr = 1)
  nearly[1] <- 199
  expect_false(tile_is_flat(nearly))
})

test_that("the providers gq names actually exist in maptiles", {
  skip_if_not_installed("maptiles")
  # The mocked tests below replace get_tiles() wholesale, so the provider string
  # is never looked up and a typo -- or maptiles renaming one upstream -- passes
  # every one of them. This is the offline half of that: it costs no network and
  # catches the whole class.
  provs <- names(maptiles::get_providers())
  expect_true("Esri.WorldGrayCanvas" %in% provs)
  expect_true("Esri.WorldShadedRelief" %in% provs)
  # The default in particular, read off the function rather than retyped here.
  expect_true(formals(gq_basemap_tiles)$provider %in% provs)
})

test_that("gq_basemap_tiles warns on a flat tile but still returns it", {
  skip_if_no_terra()
  skip_if_not_installed("maptiles")
  skip_if_not_installed("sf")

  bb <- sf::st_bbox(c(xmin = 1e6, ymin = 9e5, xmax = 1.02e6, ymax = 9.2e5),
                    crs = 3005)
  flat <- r_const(254, nlyr = 3)
  terra::crs(flat) <- "EPSG:3857"
  terra::ext(flat) <- c(-1.4e7, -1.39e7, 6.5e6, 6.6e6)

  testthat::local_mocked_bindings(
    get_tiles = function(...) flat, .package = "maptiles"
  )

  # Returned, not dropped. An all-ocean extent is legitimately one colour, so
  # this guard has a real false-positive path -- it must not destroy a tile the
  # caller may still want. NULL stays reserved for a genuine fetch failure.
  expect_warning(out <- gq_basemap_tiles(bb, crs = NULL), "single colour")
  expect_false(is.null(out))
  expect_s4_class(out, "SpatRaster")
})

test_that("gq_basemap_tiles is silent on an ordinary tile", {
  skip_if_no_terra()
  skip_if_not_installed("maptiles")
  skip_if_not_installed("sf")

  bb <- sf::st_bbox(c(xmin = 1e6, ymin = 9e5, xmax = 1.02e6, ymax = 9.2e5),
                    crs = 3005)
  set.seed(2)
  varied <- terra::rast(nrows = 8, ncols = 8, nlyrs = 3,
                        vals = stats::runif(192, 0, 255))
  terra::crs(varied) <- "EPSG:3857"
  terra::ext(varied) <- c(-1.4e7, -1.39e7, 6.5e6, 6.6e6)

  testthat::local_mocked_bindings(
    get_tiles = function(...) varied, .package = "maptiles"
  )
  expect_silent(gq_basemap_tiles(bb, crs = NULL))
})

test_that("the providers gq recommends still return real tiles", {
  # The live canary. #57 was a provider changing its terms underneath a working
  # package, which no offline test can see -- so this one has to touch the
  # network.
  #
  # skip_on_ci() is load-bearing, and skip_on_cran() does NOT cover it: devtools
  # sets NOT_CRAN=true on GitHub Actions, so a cran-only skip still runs there
  # and turns any network hiccup into a red build for an unrelated reason. This
  # runs on a developer's machine, where someone is present to read it.
  skip_on_ci()
  skip_on_cran()
  skip_if_not_installed("curl")   # skip_if_offline() errors without it
  skip_if_offline()
  skip_if_no_terra()
  skip_if_not_installed("maptiles")
  skip_if_not_installed("sf")

  bb <- sf::st_bbox(c(xmin = 1.1e6, ymin = 9.7e5, xmax = 1.13e6, ymax = 1e6),
                    crs = 3005)
  for (p in c("Esri.WorldGrayCanvas", "Esri.WorldShadedRelief")) {
    tiles <- gq_basemap_tiles(bb, provider = p, zoom = 10, pad = 0, crs = NULL)
    expect_false(is.null(tiles), label = paste("fetch of", p))
    expect_false(tile_is_flat(tiles), label = paste(p, "is a flat tile"))
  }
})
