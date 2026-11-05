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
  expect_equal(sty$classification$labels, c(highway = "Highway", arterial = "Arterial"))
})

test_that("gq_style surfaces a per-class dashes vector (#32)", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  sty <- gq_style(reg, "road")
  # arterial is dashed, highway is not -> dashes present, NA where solid
  expect_equal(unname(sty$classification$dashes[["arterial"]]), "0.66;2")
  expect_true(is.na(sty$classification$dashes[["highway"]]))
  # parallel to widths: one entry per non-__empty__ class
  expect_length(sty$classification$dashes, 2)
})

test_that("gq_style omits dashes when no class is dashed (#32)", {
  layer <- list(
    type = "line",
    classification = list(
      field = "x",
      classes = list(a = list(color = "#000"), b = list(color = "#111"))
    )
  )
  sty <- gq_style(layer)
  expect_null(sty$classification$dashes)
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

test_that("gq_style field override replaces classification field", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  sty <- gq_style(reg, "road", field = "my_road_col")
  expect_equal(sty$classification$field, "my_road_col")
  # values and labels unchanged
  expect_length(sty$classification$values, 2)
  expect_equal(sty$classification$labels, c(highway = "Highway", arterial = "Arterial"))
})

test_that("gq_style field override ignored for simple layers", {
  reg <- gq_registry_read(
    system.file("examples", "mini_registry.json", package = "gq")
  )
  sty <- gq_style(reg, "lake", field = "ignored")
  expect_null(sty$classification)
  expect_equal(sty$fill$color, "#c6ddf0")
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


# --- normalize_layer_name -----------------------------------------------------
# Shared by gq_style()'s name lookup and gq_qgs_extract()'s key generation, so a
# change here silently re-keys the registry. The extractor fixture's layer names
# are all clean, which is why these cases are pinned explicitly.

test_that("normalize_layer_name lowercases and collapses separators", {
  expect_equal(normalize_layer_name("Provincial Park"), "provincial_park")
  expect_equal(normalize_layer_name("Crossings - PSCIS assessment"),
               "crossings_pscis_assessment")
  expect_equal(normalize_layer_name("Roads,Railways,Pipelines"),
               "roads_railways_pipelines")
})

test_that("normalize_layer_name trims whitespace before normalizing", {
  # QGIS layer trees carry names with a leading space (e.g. " Form PSCIS")
  expect_equal(normalize_layer_name(" Form PSCIS"), "form_pscis")
  expect_equal(normalize_layer_name("lake  "), "lake")
})

test_that("normalize_layer_name strips one boundary underscore, not both", {
  # sub() with an alternation, not gsub() — only the FIRST boundary match goes.
  # Pinned because "tidying" this to gsub() would re-key every affected layer.
  expect_equal(normalize_layer_name("_foo_"), "foo_")
  expect_equal(normalize_layer_name("-lake"), "lake")
  expect_equal(normalize_layer_name("lake-"), "lake")
})

test_that("normalize_layer_name is idempotent on an already-clean key", {
  expect_equal(normalize_layer_name("habitat_lateral"), "habitat_lateral")
  expect_equal(normalize_layer_name("bec_zone"), "bec_zone")
})

# --- #71 / #31: per-class opacity; #55: labels keyed like values -------------

test_that("gq_style surfaces per-class opacity, keyed on the class (#71)", {
  entry <- list(type = "polygon", classification = list(field = "value", classes = list(
    `1` = list(color = "#b2df8a", opacity = 0.4, label = "Floodplain"),
    `2` = list(color = "#9f3cca", label = "Disconnected"),
    `__empty__` = list(color = "#888888", opacity = 0.1)
  )))
  cls <- gq_style(entry)$classification
  # NA, not 1: gq_style() reports what the registry holds. The translators read
  # NA as opaque, because the extractor omits `opacity` when alpha is 1.
  expect_equal(cls$opacities, c(`1` = 0.4, `2` = NA))
})

test_that("gq_style omits opacities when no class carries one (#71)", {
  entry <- list(type = "line", classification = list(field = "x", classes = list(
    a = list(color = "#000000"), b = list(color = "#111111")
  )))
  expect_null(gq_style(entry)$classification$opacities)
})

test_that("bec_zone carries its registry opacity through gq_style (#71)", {
  cls <- gq_style(gq_reg_main(), "bec_zone")$classification
  expect_length(cls$opacities, length(cls$values))
  expect_true(all(cls$opacities == 0.25))
})

test_that("labels index by class key the way values do (#55)", {
  # Positional labels beside named values: indexing both by key returned the
  # colours and NA, NA -- a legend built the obvious way labelled its rows "NA".
  cls <- gq_style(gq_reg_main(), "roads_dra")$classification
  # Out of registry order (RF comes first), so the read is by key, not position.
  codes <- c("RH1", "RF")
  expect_identical(names(cls$labels), names(cls$values))
  expect_equal(unname(cls$labels[codes]), c("Highway", "Freeway"))
})
