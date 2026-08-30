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
  # Asserted a raw pass-through of 4 until #16. The registry stores a DIAMETER
  # in millimetres and MapLibre reads circle-radius as a RADIUS in CSS pixels,
  # so passing it through unconverted made mapgl and tmap disagree by 3x with
  # neither matching QGIS.
  expect_equal(style$paint[["circle-radius"]], gq_symbol_size(4, "mapgl"))
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
    # `type` added in #64. This fixture carried none, which is how the raster
    # guard nearly shipped with a `!is.null(layer$type) &&` escape hatch that
    # would have let an untyped layer through -- the same silent-wrong outcome
    # the guard exists to stop, and a disagreement with gq_mapgl_style(), which
    # has always required a type.
    type = "line",
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

test_that("gq_mapgl_classes refuses a raster instead of answering", {
  # The worse half of the gq_tmap_style hole, in the other backend. That one
  # returned an empty list; this one returned a perfectly well-formed match
  # expression -- ["match", ["get", "value"], "1", "#b2df8a", ...] -- whose
  # ["get", ...] reads a FEATURE PROPERTY. A raster source has none, so the
  # expression resolves against nothing and every pixel takes the fallback.
  #
  # Nothing errors, nothing warns, and the map draws one flat colour. Silent
  # and wrong beats loud and wrong every time it is measured (#64).
  raster <- list(
    type = "raster",
    classification = list(field = "value", classes = list(
      `1` = list(color = "#b2df8a"), `2` = list(color = "#9f3cca")
    ))
  )
  expect_error(gq_mapgl_classes(raster), "Unknown layer type")

  # Premise: the classification is well-formed, so the refusal is about the
  # TYPE and not about a malformed fixture that would fail either way.
  vector_twin <- raster
  vector_twin$type <- "polygon"
  expect_equal(gq_mapgl_classes(vector_twin)[[1]], "match")
})

test_that("gq_mapgl_style refuses a raster", {
  expect_error(gq_mapgl_style(list(type = "raster")), "Unknown layer type")
})

test_that("gq_mapgl_classes refuses a layer with no type at all", {
  # Absent is not "fine", it is unknown -- and the permissive spelling of the
  # raster guard (`!is.null(layer$type) && ...`) let exactly this through while
  # gq_mapgl_style() refused the same input. A guard with an escape hatch that
  # covers the untested case is where the guard goes to die.
  untyped <- list(classification = list(field = "road_type",
                                        classes = list(a = list(color = "#000"))))
  expect_null(untyped$type)                                   # premise
  expect_error(gq_mapgl_classes(untyped), "Unknown layer type")
})
