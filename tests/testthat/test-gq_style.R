test_that("gq_style returns simple polygon", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  sty <- gq_style(reg, "lake")
  expect_equal(sty$type, "polygon")
  expect_equal(sty$fill$color, "#c6ddf0")
  expect_equal(sty$stroke$color, "#7ba7cc")
  expect_null(sty$classification)
})

test_that("gq_style returns simple line", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  sty <- gq_style(reg, "stream")
  expect_equal(sty$type, "line")
  expect_equal(sty$stroke$color, "#7ba7cc")
})

test_that("gq_style returns simple point", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  sty <- gq_style(reg, "crossing")
  expect_equal(sty$type, "point")
  expect_equal(sty$mark$color, "#e74c3c")
})

test_that("gq_style returns classified layer with field/values/labels", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  sty <- gq_style(reg, "road")
  expect_equal(sty$type, "line")
  expect_equal(sty$classification$field, "road_type")
  expect_length(sty$classification$values, 2)
  expect_equal(unname(sty$classification$values[["highway"]]), "#c0392b")
  expect_equal(sty$classification$labels, c("Highway", "Arterial"))
})

test_that("gq_style normalizes display names", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  sty <- gq_style(reg, "Lake")
  expect_equal(sty$fill$color, "#c6ddf0")
})

test_that("gq_style errors with helpful message for bad name", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  expect_error(gq_style(reg, "nonexistent"), "not found")
})

test_that("gq_style works with layer object directly", {
  layer <- list(
    type = "polygon",
    fill = list(color = "#aabbcc")
  )
  sty <- gq_style(layer)
  expect_equal(sty$fill$color, "#aabbcc")
})

test_that("gq_style includes widths for classified lines", {
  reg <- list(layers = list(
    roads = list(
      type = "line",
      classification = list(
        field = "road_type",
        classes = list(
          HWY = list(color = "#ff0000", width = 2.0, label = "Highway"),
          LOCAL = list(color = "#888888", width = 0.5, label = "Local")
        )
      )
    )
  ))
  sty <- gq_style(reg, "roads")
  expect_equal(sty$classification$widths, c(HWY = 2.0, LOCAL = 0.5))
})

test_that("gq_style includes radii for classified points", {
  reg <- list(layers = list(
    xing = list(
      type = "point",
      classification = list(
        field = "status",
        classes = list(
          BARRIER = list(color = "#ca3c3c", radius = 3),
          PASSABLE = list(color = "#33a02c", radius = 3)
        )
      )
    )
  ))
  sty <- gq_style(reg, "xing")
  expect_equal(sty$classification$radii, c(BARRIER = 3, PASSABLE = 3))
})
