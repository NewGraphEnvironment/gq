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

test_that("gq_tmap_style maps a custom dash pattern to lty 'dashed' (#32)", {
  # raw QGIS mm pattern is not a valid lty -> collapses to "dashed"
  layer <- list(
    type = "line",
    stroke = list(color = "#000", width = 1, dash = "0.66;2")
  )
  expect_equal(gq_tmap_style(layer)$lty, "dashed")
})

test_that("gq_tmap_style passes a valid named lty through, drops solid (#32)", {
  named <- list(type = "line", stroke = list(color = "#000", dash = "dotted"))
  expect_equal(gq_tmap_style(named)$lty, "dotted")

  solid <- list(type = "line", stroke = list(color = "#000", dash = "solid"))
  expect_null(gq_tmap_style(solid)$lty)

  plain <- list(type = "line", stroke = list(color = "#000"))
  expect_null(gq_tmap_style(plain)$lty)
})

test_that("dash_to_lty normalizes raw QGIS dashes (#32)", {
  expect_null(dash_to_lty(NULL))
  expect_null(dash_to_lty(NA_character_))
  expect_null(dash_to_lty("solid"))
  expect_null(dash_to_lty("no"))
  expect_equal(dash_to_lty("dashed"), "dashed")   # already valid
  expect_equal(dash_to_lty("dash dot"), "dashed")  # named QGIS, not valid lty
  expect_equal(dash_to_lty("0.66;2"), "dashed")    # mm pattern
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
    type = "line",
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

test_that("gq_tmap_classes returns a dashes vector for dashed classes (#32)", {
  layer <- list(
    type = "line",
    classification = list(
      field = "road_type",
      classes = list(
        highway = list(color = "#c0392b", label = "Highway"),
        arterial = list(color = "#e67e22", label = "Arterial", dash = "0.66;2")
      )
    )
  )
  cls <- gq_tmap_classes(layer)
  expect_equal(unname(cls$dashes[["arterial"]]), "0.66;2")
  expect_true(is.na(cls$dashes[["highway"]]))
})

test_that("gq_tmap_classes dashes is NULL when no class is dashed (#32)", {
  layer <- list(
    type = "line",
    classification = list(
      field = "road_type",
      classes = list(
        highway = list(color = "#c0392b"),
        arterial = list(color = "#e67e22")
      )
    )
  )
  expect_null(gq_tmap_classes(layer)$dashes)
})

test_that("gq_tmap_classes converts fallback labels to title case", {
  layer <- list(
    type = "point",
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

# --- name-based lookup tests ------------------------------------------------

test_that("gq_tmap_style works with registry + name", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  args <- gq_tmap_style(reg, "lake")
  expect_equal(args$fill, "#c6ddf0")
  expect_equal(args$col, "#7ba7cc")
})

test_that("gq_tmap_style normalizes display names", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  # Spaces and caps should normalize to snake_case key
  args <- gq_tmap_style(reg, "Lake")
  expect_equal(args$fill, "#c6ddf0")
})

test_that("gq_tmap_style returns classified args for categorized layers", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  args <- gq_tmap_style(reg, "road")

  expect_equal(args$col, "road_type")
  expect_s3_class(args$col.scale, "tm_scale_categorical")
  expect_false(is.null(args$col.legend))
  expect_equal(args$lwd, 2)
})

test_that("gq_tmap_style field override works for classified layers", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  args <- gq_tmap_style(reg, "road", field = "alt_road_type")
  expect_equal(args$col, "alt_road_type")
  expect_s3_class(args$col.scale, "tm_scale_categorical")
})

test_that("gq_tmap_classes field override works", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  cls <- gq_tmap_classes(reg, "road", field = "alt_road_type")
  expect_equal(cls$field, "alt_road_type")
  expect_length(cls$values, 2)
})

test_that("gq_tmap_style errors with helpful message for bad name", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  expect_error(gq_tmap_style(reg, "nonexistent_layer"), "not found")
})

test_that("gq_tmap_style errors when registry has no layers field", {
  expect_error(gq_tmap_style(list(foo = 1), "lake"), "registry")
})

test_that("gq_tmap_classes works with registry + name", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  cls <- gq_tmap_classes(reg, "road")
  expect_equal(cls$field, "road_type")
  expect_length(cls$values, 2)
})

test_that("gq_tmap_style handles classified point layers", {
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
  args <- gq_tmap_style(reg, "xing")
  expect_equal(args$fill, "status")
  expect_s3_class(args$fill.scale, "tm_scale_categorical")
})

test_that("gq_tmap_style handles classified polygon layers", {
  reg <- list(layers = list(
    bec = list(
      type = "polygon",
      classification = list(
        field = "zone",
        classes = list(
          CWH = list(color = "#a3c4a3", label = "Coastal Western Hemlock"),
          SBS = list(color = "#d4a373", label = "Sub-Boreal Spruce")
        )
      )
    )
  ))
  args <- gq_tmap_style(reg, "bec")
  expect_equal(args$fill, "zone")
  expect_s3_class(args$fill.scale, "tm_scale_categorical")
})
