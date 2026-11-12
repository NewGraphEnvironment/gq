test_that("gq_mapgl_popup writes display text and the browser expression", {
  x <- data.frame(so = c(3L, 5L), g = c(0.0372, NA), w = c(2.2, 15.04), f = c(TRUE, NA),
                  nm = c("Bulkley", NA))
  pop <- gq_mapgl_popup(x, c("Order" = "so", "Gradient" = "g", "Width (m)" = "w",
                             "Fish" = "f", "Name" = "nm"))
  expect_identical(pop$data$popup_1, c("3", "5"))
  expect_identical(pop$data$popup_2, c("0.0372", "none"))      # per value, NA as text
  expect_identical(pop$data$popup_3, c("2.2", "15"))            # no shared notation
  expect_identical(pop$data$popup_4, c("yes", "none"))
  expect_identical(pop$data$popup_5, c("Bulkley", "none"))
  expect_identical(pop$expr[1:5], list("concat", "Order: ", list("get", "popup_1"),
                                       "<br>Gradient: ", list("get", "popup_2")))
  # the columns read are left as they were, so a layer can still style on them
  expect_identical(pop$data[names(x)], x)
  expect_length(pop$expr, 1 + 2 * 5)
})

test_that("gq_mapgl_popup keeps an sf an sf, and takes its own missing text", {
  skip_if_not_installed("sf")
  x <- sf::st_sf(a = c(NA, 1), geometry = sf::st_sfc(sf::st_point(c(0, 0)), sf::st_point(c(1, 1))))
  pop <- gq_mapgl_popup(x, c(A = "a"), missing = "-")
  expect_s3_class(pop$data, "sf")
  expect_identical(pop$data$popup_1, c("-", "1"))
  expect_identical(pop$data$a, c(NA, 1))
})

test_that("gq_mapgl_popup refuses fields it cannot read", {
  x <- data.frame(a = 1)
  expect_error(gq_mapgl_popup(x, "a"), "named")
  expect_error(gq_mapgl_popup(x, c(A = "b")), "no column `b`")
  expect_error(gq_mapgl_popup(list(a = 1), c(A = "a")), "data frame")
  expect_error(gq_mapgl_popup(x, c(A = "a"), digits = 0), "1 or more")
  expect_error(gq_mapgl_popup(data.frame(a = 1, popup_1 = 2), c(A = "a")), "already has")
})
