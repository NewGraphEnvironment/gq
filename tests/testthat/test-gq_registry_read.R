test_that("gq_registry_read loads JSON and returns expected structure", {
  path <- test_path("fixtures", "mini_registry.json")
  reg <- gq_registry_read(path)

  expect_type(reg, "list")
  expect_equal(reg$name, "test")
  expect_equal(reg$version, "0.1.0")
  expect_true("layers" %in% names(reg))
  expect_true("lake" %in% names(reg$layers))
  expect_true("stream" %in% names(reg$layers))
  expect_true("crossing" %in% names(reg$layers))
  expect_true("road" %in% names(reg$layers))
})

test_that("gq_registry_read preserves layer types", {
  path <- test_path("fixtures", "mini_registry.json")
  reg <- gq_registry_read(path)

  expect_equal(reg$layers$lake$type, "polygon")
  expect_equal(reg$layers$stream$type, "line")
  expect_equal(reg$layers$crossing$type, "point")
})

test_that("gq_registry_read errors on missing file", {
  expect_error(gq_registry_read("nonexistent.json"))
})
