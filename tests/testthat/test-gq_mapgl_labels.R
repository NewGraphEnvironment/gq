reg <- gq_reg_main()

test_that("a plain-column label converts QGIS points and mm to MapLibre px (#7)", {
  a <- gq_mapgl_labels(reg$layers$lake)
  expect_equal(a$text_field, list("get", "gnis_name_1"))
  expect_equal(a$symbol_placement, "point")
  expect_equal(a$text_size, round(reg$layers$lake$label$size * 96 / 72, 2))
  expect_equal(a$text_color, reg$layers$lake$label$color)
  expect_equal(a$text_halo_color, reg$layers$lake$label$halo$color)
  expect_equal(a$text_halo_width, round(reg$layers$lake$label$halo$width * 96 / 25.4, 2))
})

test_that("a line label follows the line (#7)", {
  expect_equal(gq_mapgl_labels(reg$layers$stream_labels)$symbol_placement, "line")
  expect_equal(gq_mapgl_labels(reg$layers$roads_dra)$symbol_placement, "line")
})

test_that("an expression label is refused until a column is named (#6, #7)", {
  layer <- reg$layers$crossings_pscis_assessment
  expect_error(gq_mapgl_labels(layer), "QGIS expression .*concat.*field =")
  expect_equal(gq_mapgl_labels(layer, field = "label")$text_field, list("get", "label"))
})

test_that("a CSV label needs a column, and keeps its look in px (#7)", {
  expect_error(gq_mapgl_labels(reg$layers$town), "names no column")
  a <- gq_mapgl_labels(reg$layers$town, field = "name")
  # The CSV was written for MapLibre at 12 px and a 1.5 px halo; stored now in
  # points and mm, it must come back to the same pixels.
  expect_equal(a$text_size, 12)
  expect_equal(a$text_halo_width, 1.51)
  expect_equal(a$text_offset, c(0, 1.2))
})

test_that("a layer with no label is an error", {
  expect_error(gq_mapgl_labels(reg$layers$railway), "has no label")
})

test_that("every registry label with a column translates", {
  labelled <- Filter(function(x) !is.null(x$label$field), reg$layers)
  expect_gt(length(labelled), 10)
  for (k in names(labelled)) {
    a <- gq_mapgl_labels(labelled[[k]])
    expect_equal(a$text_field[[2]], labelled[[k]]$label$field, info = k)
    expect_false(any(vapply(a, function(v) any(is.na(unlist(v))), TRUE)), info = k)
  }
})

test_that("every line-following placement the extractor writes follows the line", {
  for (p in c("line", "curved", "perimeter", "perimeter_curved")) {
    layer <- list(type = "polygon", label = list(field = "n", placement = p))
    expect_equal(gq_mapgl_labels(layer)$symbol_placement, "line", info = p)
  }
  for (p in c("around_point", "over_point", "horizontal", "free", "ordered", "outside_polygons")) {
    layer <- list(type = "point", label = list(field = "n", placement = p))
    expect_equal(gq_mapgl_labels(layer)$symbol_placement, "point", info = p)
  }
})
