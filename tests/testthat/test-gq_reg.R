test_that("gq_reg_read is alias for gq_registry_read", {
  path <- system.file("examples", "mini_registry.json", package = "gq")
  expect_identical(gq_reg_read(path), gq_registry_read(path))
})


# --- gq_reg_read_csv -------------------------------------------------------

test_that("gq_reg_read_csv reads classified layer (bec_zone)", {
  path <- system.file("registry", "reg_csv_custom.csv", package = "gq")
  reg <- gq_reg_read_csv(path)

  expect_true("bec_zone" %in% names(reg$layers))
  bz <- reg$layers$bec_zone
  expect_equal(bz$type, "polygon")
  expect_equal(bz$classification$field, "ZONE")
  expect_length(bz$classification$classes, 11)
  expect_true("SBS" %in% names(bz$classification$classes))
  expect_equal(bz$classification$classes$SBS$color, "#8fbc8f")
})

test_that("gq_reg_read_csv reads simple polygon layer (rivers_poly)", {
  path <- system.file("registry", "reg_csv_custom.csv", package = "gq")
  reg <- gq_reg_read_csv(path)

  rp <- reg$layers$rivers_poly
  expect_equal(rp$type, "polygon")
  expect_equal(rp$fill$color, "#7ba7cc")
  expect_equal(rp$fill$opacity, 0.7)
  expect_null(rp$classification)
})

test_that("gq_reg_read_csv reads point layer with mark and label (dam)", {
  path <- system.file("registry", "reg_csv_custom.csv", package = "gq")
  reg <- gq_reg_read_csv(path)

  dam <- reg$layers$dam
  expect_equal(dam$type, "point")
  expect_equal(dam$mark$color, "#c0392b")
  expect_equal(dam$mark$shape, "circle")
  expect_equal(dam$mark$radius, 7)
  expect_equal(dam$mark$stroke_color, "white")
  expect_equal(dam$label$color, "#c0392b")
  expect_equal(dam$label$font, "Open Sans Bold")
  expect_equal(dam$label$halo$color, "white")
})

test_that("gq_reg_read_csv reads point layer (town)", {
  path <- system.file("registry", "reg_csv_custom.csv", package = "gq")
  reg <- gq_reg_read_csv(path)

  town <- reg$layers$town
  expect_equal(town$type, "point")
  expect_equal(town$mark$color, "#2c3e50")
  expect_equal(town$label$size, 12)
})

test_that("gq_reg_read_csv returns standard registry structure", {
  path <- system.file("registry", "reg_csv_custom.csv", package = "gq")
  reg <- gq_reg_read_csv(path)

  expect_true(all(c("name", "version", "source", "layers") %in% names(reg)))
  expect_equal(reg$source, "reg_csv_custom.csv")
})

test_that("gq_reg_read_csv errors on missing required columns", {
  tmp <- tempfile(fileext = ".csv")
  writeLines("bad_col,type\nfoo,polygon", tmp)
  expect_error(gq_reg_read_csv(tmp), "layer_key")
})


# --- gq_reg_merge -----------------------------------------------------------

test_that("gq_reg_merge unions non-overlapping layers", {
  reg1 <- list(name = "a", version = "0.1.0", source = "a.json",
               layers = list(lake = list(type = "polygon")))
  reg2 <- list(name = "b", version = "0.1.0", source = "b.json",
               layers = list(road = list(type = "line")))

  merged <- gq_reg_merge(reg1, reg2)
  expect_equal(sort(names(merged$layers)), c("lake", "road"))
  expect_null(attr(merged, "conflicts"))
})

test_that("gq_reg_merge last wins by default", {
  reg1 <- list(name = "a", source = "a.json",
               layers = list(lake = list(type = "polygon", fill = list(color = "red"))))
  reg2 <- list(name = "b", source = "b.json",
               layers = list(lake = list(type = "polygon", fill = list(color = "blue"))))

  merged <- gq_reg_merge(reg1, reg2)
  expect_equal(merged$layers$lake$fill$color, "blue")

  conflicts <- attr(merged, "conflicts")
  expect_equal(nrow(conflicts), 1)
  expect_equal(conflicts$layer_key, "lake")
})

test_that("gq_reg_merge first wins with priority", {
  reg1 <- list(name = "a", source = "a.json",
               layers = list(lake = list(type = "polygon", fill = list(color = "red"))))
  reg2 <- list(name = "b", source = "b.json",
               layers = list(lake = list(type = "polygon", fill = list(color = "blue"))))

  merged <- gq_reg_merge(reg1, reg2, priority = "first")
  expect_equal(merged$layers$lake$fill$color, "red")
})

test_that("gq_reg_merge accepts csv parameter", {
  csv_path <- system.file("registry", "reg_csv_custom.csv", package = "gq")
  reg1 <- list(name = "a", source = "a.json",
               layers = list(lake = list(type = "polygon")))

  merged <- gq_reg_merge(reg1, csv = csv_path)
  expect_true("bec_zone" %in% names(merged$layers))
  expect_true("lake" %in% names(merged$layers))
})

test_that("gq_reg_merge errors with no inputs", {
  expect_error(gq_reg_merge(), "No registries")
})
