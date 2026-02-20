test_that("gq_qgs_extract parses mini project", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  expect_type(reg, "list")
  expect_equal(reg$version, "0.1.0")
  expect_true("layers" %in% names(reg))
})

test_that("gq_qgs_extract finds all 4 layers", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  expect_equal(length(reg$layers), 4)
  expect_true("lakes" %in% names(reg$layers))
  expect_true("streams" %in% names(reg$layers))
  expect_true("crossings" %in% names(reg$layers))
  expect_true("roads" %in% names(reg$layers))
})

test_that("gq_qgs_extract parses polygon fill correctly", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  lake <- reg$layers$lakes
  expect_equal(lake$type, "polygon")
  expect_equal(lake$fill$color, "#c6ddf0")
  expect_equal(lake$stroke$color, "#7ba7cc")
  expect_equal(lake$stroke$width, 0.5)
})

test_that("gq_qgs_extract parses line stroke correctly", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  stream <- reg$layers$streams
  expect_equal(stream$type, "line")
  expect_equal(stream$stroke$color, "#7ba7cc")
  expect_equal(stream$stroke$width, 0.4)
})

test_that("gq_qgs_extract parses point marker correctly", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  crossing <- reg$layers$crossings
  expect_equal(crossing$type, "point")
  expect_equal(crossing$mark$color, "#e74c3c")
  expect_equal(crossing$mark$radius, 4)
  expect_equal(crossing$mark$shape, "circle")
})

test_that("gq_qgs_extract parses categorized renderer", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  road <- reg$layers$roads
  expect_equal(road$type, "line")
  expect_true("classification" %in% names(road))
  expect_equal(road$classification$field, "road_type")
  expect_true("highway" %in% names(road$classification$classes))
  expect_true("arterial" %in% names(road$classification$classes))
  expect_equal(road$classification$classes$highway$color, "#c0392b")
  expect_equal(road$classification$classes$highway$width, 2.0)
})

test_that("gq_qgs_extract parses labels", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  road <- reg$layers$roads
  expect_true("label" %in% names(road))
  expect_equal(road$label$field, "road_name")
  expect_equal(road$label$font, "Arial")
  expect_equal(road$label$size, 10)
  expect_equal(road$label$weight, "bold")
  expect_equal(road$label$halo$width, 1.5)
})

test_that("gq_qgs_extract errors on missing file", {
  expect_error(gq_qgs_extract("nonexistent.qgs"))
})
