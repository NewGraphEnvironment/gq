test_that("gq_tmap_style returns polygon args", {
  layer <- list(
    type = "polygon",
    fill = list(color = "#c6ddf0", opacity = 0.85),
    stroke = list(color = "#7ba7cc", width = 0.5)
  )
  args <- gq_tmap_style(layer)

  expect_type(args, "list")
  expect_equal(args$fill, "#c6ddf0")
  expect_equal(args$fill_alpha, 0.85)
  expect_equal(args$col, "#7ba7cc")
  expect_equal(args$lwd, 0.5)
})

test_that("gq_tmap_style returns line args", {
  layer <- list(
    type = "line",
    stroke = list(color = "#7ba7cc", width = 0.4, opacity = 0.8)
  )
  args <- gq_tmap_style(layer)

  expect_equal(args$col, "#7ba7cc")
  expect_equal(args$lwd, 0.4)
  expect_equal(args$col_alpha, 0.8)
})

test_that("gq_tmap_style returns point args", {
  layer <- list(
    type = "point",
    mark = list(color = "#e74c3c", radius = 6)
  )
  args <- gq_tmap_style(layer)

  expect_equal(args$fill, "#e74c3c")
  expect_equal(args$size, 2)
})

test_that("gq_tmap_style handles stroke style none", {
  layer <- list(
    type = "polygon",
    fill = list(color = "#ffffff"),
    stroke = list(color = "#000000", style = "none")
  )
  args <- gq_tmap_style(layer)

  expect_true(is.na(args$col))
})

test_that("gq_tmap_style errors on missing type", {
  expect_error(gq_tmap_style(list(fill = list(color = "#fff"))), "type")
})

test_that("gq_tmap_style errors on unknown type", {
  expect_error(gq_tmap_style(list(type = "raster")), "Unknown")
})

test_that("gq_tmap_classes returns classification info", {
  layer <- list(
    classification = list(
      field = "road_type",
      classes = list(
        highway = list(color = "#c0392b", label = "Highway"),
        arterial = list(color = "#e67e22", label = "Arterial"),
        `__empty__` = list(color = "#888888")
      )
    )
  )
  cls <- gq_tmap_classes(layer)

  expect_equal(cls$field, "road_type")
  expect_length(cls$values, 2)
  expect_equal(unname(cls$values[["highway"]]), "#c0392b")
  expect_equal(cls$labels, c("Highway", "Arterial"))
})

test_that("gq_tmap_classes converts fallback labels to title case", {
  layer <- list(
    classification = list(
      field = "status",
      classes = list(
        BARRIER = list(color = "#ca3c3c"),
        PASSABLE = list(color = "#33a02c")
      )
    )
  )
  cls <- gq_tmap_classes(layer)
  expect_equal(cls$labels, c("Barrier", "Passable"))
})

test_that("gq_tmap_classes errors without classification", {
  expect_error(gq_tmap_classes(list(type = "line")), "classification")
})
