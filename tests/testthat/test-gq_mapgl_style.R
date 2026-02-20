test_that("gq_mapgl_style returns fill layer paint", {
  layer <- list(
    type = "polygon",
    fill = list(color = "#c6ddf0", opacity = 0.85),
    stroke = list(color = "#7ba7cc")
  )
  style <- gq_mapgl_style(layer)

  expect_equal(style$layer_type, "fill")
  expect_equal(style$paint[["fill-color"]], "#c6ddf0")
  expect_equal(style$paint[["fill-opacity"]], 0.85)
  expect_equal(style$paint[["fill-outline-color"]], "#7ba7cc")
})

test_that("gq_mapgl_style returns line layer paint", {
  layer <- list(
    type = "line",
    stroke = list(color = "#7ba7cc", width = 0.4, opacity = 0.8)
  )
  style <- gq_mapgl_style(layer)

  expect_equal(style$layer_type, "line")
  expect_equal(style$paint[["line-color"]], "#7ba7cc")
  expect_equal(style$paint[["line-width"]], 0.4)
  expect_equal(style$paint[["line-opacity"]], 0.8)
})

test_that("gq_mapgl_style returns circle layer paint", {
  layer <- list(
    type = "point",
    mark = list(color = "#e74c3c", radius = 4),
    fill = list(color = "#e74c3c", opacity = 0.9)
  )
  style <- gq_mapgl_style(layer)

  expect_equal(style$layer_type, "circle")
  expect_equal(style$paint[["circle-color"]], "#e74c3c")
  expect_equal(style$paint[["circle-radius"]], 4)
  expect_equal(style$paint[["circle-opacity"]], 0.9)
})

test_that("gq_mapgl_style handles line dasharray", {
  layer <- list(
    type = "line",
    stroke = list(color = "#000", width = 1, dash = "2.5 3.5")
  )
  style <- gq_mapgl_style(layer)

  expect_equal(style$paint[["line-dasharray"]], c(2.5, 3.5))
})

test_that("gq_mapgl_style skips outline when stroke style is none", {
  layer <- list(
    type = "polygon",
    fill = list(color = "#fff"),
    stroke = list(color = "#000", style = "none")
  )
  style <- gq_mapgl_style(layer)

  expect_null(style$paint[["fill-outline-color"]])
})

test_that("gq_mapgl_style errors on missing type", {
  expect_error(gq_mapgl_style(list(fill = list(color = "#fff"))), "type")
})

test_that("gq_mapgl_classes builds match expression", {
  layer <- list(
    classification = list(
      field = "road_type",
      classes = list(
        highway = list(color = "#c0392b"),
        arterial = list(color = "#e67e22"),
        `__empty__` = list(color = "#888888")
      )
    )
  )
  expr <- gq_mapgl_classes(layer)

  expect_equal(expr[[1]], "match")
  expect_equal(expr[[2]], list("get", "road_type"))
  expect_equal(expr[[3]], "highway")
  expect_equal(expr[[4]], "#c0392b")
  expect_equal(expr[[5]], "arterial")
  expect_equal(expr[[6]], "#e67e22")
  # fallback is last
  expect_equal(expr[[length(expr)]], "#888888")
})

test_that("gq_mapgl_classes errors without classification", {
  expect_error(gq_mapgl_classes(list(type = "line")), "classification")
})
