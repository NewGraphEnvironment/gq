skip_if_not_installed("mapgl")
skip_if_not_installed("sf")

two_layers <- function() {
  p <- sf::st_sf(a = 1:2, geometry = sf::st_sfc(sf::st_point(c(-126.5, 54.4)),
                                                sf::st_point(c(-126.4, 54.5)), crs = 4326))
  gq_mapgl_basemap(p) |>
    gq_mapgl_layer("a", p, color = "#111111") |>
    gq_mapgl_layer("b", p, color = "#222222")
}

test_that("gq_mapgl_controls adds navigation, scale and a named switch", {
  m <- gq_mapgl_controls(two_layers(), c(First = "a", Second = "b"))
  expect_false(is.null(m$x$navigation_control))
  expect_false(is.null(m$x$scale_control))
  expect_identical(m$x$layers_control$layers, c(First = "a", Second = "b"))
})

test_that("gq_mapgl_controls switches every layer by default, and can add nothing else", {
  m <- gq_mapgl_controls(two_layers(), navigation = FALSE, scale = FALSE)
  expect_identical(m$x$layers_control$layers, c("a", "b"))
  expect_null(m$x$navigation_control)
  expect_null(m$x$scale_control)
  expect_null(gq_mapgl_controls(two_layers(), character(0))$x$layers_control)
})

test_that("gq_mapgl_controls refuses a layer the map does not have", {
  expect_error(gq_mapgl_controls(two_layers(), c(X = "c")), "no layer `c`")
})

test_that("a partly named switch shows the ids it was not given names for", {
  m <- gq_mapgl_controls(two_layers(), c(First = "a", "b"))
  expect_identical(m$x$layers_control$layers, c(First = "a", b = "b"))
})
