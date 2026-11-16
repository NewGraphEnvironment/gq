reg <- gq_reg_main()

# opt_tm_text() splits its options between placement (trans.args) and drawing
# (mapping.args); read them as one list
opts <- function(a) c(a$options$trans.args, a$options$mapping.args)

test_that("a plain-column label sizes in tmap's 12-point units (#7)", {
  skip_if_not_installed("tmap", "4.3")
  lab <- reg$layers$lake$label
  a <- gq_tmap_labels(reg, "lake")
  expect_equal(a$text, "gnis_name_1")
  expect_equal(a$size, lab$size / 12)
  expect_equal(a$col, lab$color)
  expect_equal(a$fontface, "italic")
  expect_s3_class(do.call(tmap::tm_text, a), "tmap")
})

test_that("the halo is tmap's own, in the registry colour and width (#7)", {
  skip_if_not_installed("tmap", "4.3")
  lab <- reg$layers$lake$label
  halo <- opts(gq_tmap_labels(reg, "lake"))
  expect_true(isTRUE(halo$halo))
  expect_equal(halo$halo.col, lab$halo$color)
  expect_equal(halo$halo.alpha, 1)
  # halo.width is in lines of text at the text's size: back to mm it is the
  # registry's width
  expect_equal(halo$halo.width * (lab$size / 12) * 12 * 1.2 * 0.3528, lab$halo$width)
})

test_that("a label with no halo asks tmap for none", {
  skip_if_not_installed("tmap", "4.3")
  layer <- list(type = "point", label = list(field = "n", size = 9, color = "#000000"))
  expect_false(isTRUE(opts(gq_tmap_labels(layer))$halo))
})

test_that("line labels follow their line (#7)", {
  skip_if_not_installed("tmap", "4.3")
  expect_true(isTRUE(opts(gq_tmap_labels(reg, "stream_labels"))$along_lines))
  expect_false(isTRUE(opts(gq_tmap_labels(reg, "lake"))$along_lines))
})

test_that("an expression label is refused until a column is named (#6, #7)", {
  skip_if_not_installed("tmap", "4.3")
  expect_error(gq_tmap_labels(reg, "crossings_pscis_assessment"), "QGIS expression")
  expect_equal(gq_tmap_labels(reg, "crossings_pscis_assessment", field = "label")$text, "label")
})

test_that("a CSV label needs a column (#7)", {
  skip_if_not_installed("tmap", "4.3")
  expect_error(gq_tmap_labels(reg, "town"), "names no column")
  expect_equal(gq_tmap_labels(reg, "town", field = "name")$text, "name")
})

test_that("an offset reads as MapLibre does: positive y is below the point", {
  skip_if_not_installed("tmap", "4.3")
  # The town label sits 1.2 ems below its dot in gq_mapgl_labels(); tmap's ymod
  # is positive up, so the same label must get a negative ymod.
  expect_equal(gq_mapgl_labels(reg$layers$town, field = "name")$text_offset[2], 1.2)
  expect_equal(gq_tmap_labels(reg, "town", field = "name")$ymod, -1.2)
})

test_that("label_fontface combines weight and slant", {
  expect_equal(label_fontface(list(weight = "bold", style = "italic")), "bold.italic")
  expect_equal(label_fontface(list(weight = "bold")), "bold")
  expect_equal(label_fontface(list(style = "italic")), "italic")
  expect_equal(label_fontface(list()), "plain")
})
