test_that("gq_reg_main loads the master registry", {
  reg <- gq_reg_main()
  expect_true(all(c("name", "version", "source", "layers") %in% names(reg)))
  expect_equal(reg$name, "main")
  expect_true(length(reg$layers) >= 50)
  # Has both QGIS-extracted and CSV layers
  expect_true("lake" %in% names(reg$layers))
  expect_true("bec_zone" %in% names(reg$layers))
  expect_true("dam" %in% names(reg$layers))
})

test_that("gq_reg_read is alias for gq_registry_read", {
  path <- system.file("examples", "mini_registry.json", package = "gq")
  expect_identical(gq_reg_read(path), gq_registry_read(path))
})


# --- gq_reg_custom -------------------------------------------------------

test_that("gq_reg_custom reads classified layer (bec_zone)", {
  path <- system.file("registry", "reg_custom.csv", package = "gq")
  reg <- gq_reg_custom(path)

  expect_true("bec_zone" %in% names(reg$layers))
  bz <- reg$layers$bec_zone
  expect_equal(bz$type, "polygon")
  expect_equal(bz$classification$field, "ZONE")
  expect_length(bz$classification$classes, 11)
  expect_true("SBS" %in% names(bz$classification$classes))
  expect_equal(bz$classification$classes$SBS$color, "#8fbc8f")
})

test_that("gq_reg_custom reads simple polygon layer (rivers_poly)", {
  path <- system.file("registry", "reg_custom.csv", package = "gq")
  reg <- gq_reg_custom(path)

  rp <- reg$layers$rivers_poly
  expect_equal(rp$type, "polygon")
  expect_equal(rp$fill$color, "#7ba7cc")
  expect_equal(rp$fill$opacity, 0.7)
  expect_null(rp$classification)
})

test_that("gq_reg_custom reads point layer with mark and label (dam)", {
  path <- system.file("registry", "reg_custom.csv", package = "gq")
  reg <- gq_reg_custom(path)

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

test_that("gq_reg_custom reads point layer (town)", {
  path <- system.file("registry", "reg_custom.csv", package = "gq")
  reg <- gq_reg_custom(path)

  town <- reg$layers$town
  expect_equal(town$type, "point")
  expect_equal(town$mark$color, "#2c3e50")
  expect_equal(town$label$size, 12)
})

test_that("gq_reg_custom returns standard registry structure", {
  path <- system.file("registry", "reg_custom.csv", package = "gq")
  reg <- gq_reg_custom(path)

  expect_true(all(c("name", "version", "source", "layers") %in% names(reg)))
  expect_equal(reg$source, "reg_custom.csv")
})

test_that("gq_reg_custom errors on missing required columns", {
  tmp <- tempfile(fileext = ".csv")
  writeLines("bad_col,type\nfoo,polygon", tmp)
  expect_error(gq_reg_custom(tmp), "layer_key")
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
  csv_path <- system.file("registry", "reg_custom.csv", package = "gq")
  reg1 <- list(name = "a", source = "a.json",
               layers = list(lake = list(type = "polygon")))

  merged <- gq_reg_merge(reg1, csv = csv_path)
  expect_true("bec_zone" %in% names(merged$layers))
  expect_true("lake" %in% names(merged$layers))
})

test_that("gq_reg_merge errors with no inputs", {
  expect_error(gq_reg_merge(), "No registries")
})

test_that("a numeric class_value keys the class list by name, not position", {
  # `classes[[r$class_value]] <- cls` is POSITIONAL assignment for an integer.
  # read.csv() types class_value by content, so a registry CSV whose class
  # values are all numeric -- which the raster convention invites, since a
  # paletted band keys on pixel value -- would produce an unnamed class list
  # that every downstream lookup misses.
  #
  # reg_custom.csv is safe only by accident: bec_zone's "SBS"/"ESSF" keep the
  # column character. A caller's own CSV has no such accident.
  csv <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)
  # Built from the shipped file's own header rather than from a hand-listed set
  # of columns. gq_reg_custom() validates only layer_key and type as required,
  # then indexes the rest unguarded -- `is.na(NULL)` is logical(0), and `if` on
  # that errors -- so a fixture missing any optional column fails for a reason
  # that has nothing to do with what is under test. Deriving the header means
  # this cannot rot when a column is added.
  hdr <- names(utils::read.csv(
    system.file("registry", "reg_custom.csv", package = "gq"),
    stringsAsFactors = FALSE
  ))
  fx <- as.data.frame(
    stats::setNames(rep(list(rep(NA_character_, 2L)), length(hdr)), hdr),
    stringsAsFactors = FALSE
  )
  fx$layer_key <- "band"
  fx$type <- "raster"
  fx$source_layer <- "band"
  fx$class_field <- "value"
  fx$class_value <- c(1, 2)                 # numeric ON PURPOSE — the trap
  fx$class_label <- c("Lo", "Hi")
  fx$fill_color <- c("#000000", "#ffffff")
  utils::write.csv(fx, csv, row.names = FALSE, quote = TRUE)

  # Premise: the column really did come back numeric, so this fixture can reach
  # the failure. A character column would make the test pass for nothing.
  expect_true(is.numeric(utils::read.csv(csv)$class_value))

  classes <- gq_reg_custom(csv)$layers$band$classification$classes
  expect_equal(names(classes), c("1", "2"))
  expect_equal(classes[["2"]]$color, "#ffffff")
})

test_that("habitat_lateral carries its palette in the master registry", {
  # gq#64. The shipped raster, and the reason the exemption list is empty.
  lyr <- gq_reg_main()$layers$habitat_lateral

  expect_equal(lyr$type, "raster")
  expect_equal(lyr$source_layer, "habitat_lateral")   # the `local` sentinel
  expect_equal(lyr$classification$field, "value")

  cls <- gq_tmap_classes(gq_reg_main(), "habitat_lateral")
  expect_equal(unname(cls$values), c("#b2df8a", "#9f3cca"))
  # The QML's labels, not to_title() of the band values. Without class_label
  # this legend reads "1" and "2".
  expect_equal(unname(cls$labels),
               c("Floodplain", "Floodplain Disconnected by Railway"))
})
