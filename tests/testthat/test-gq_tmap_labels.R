reg <- gq_reg_main()

# The tm_text() layers a call returns, and one aesthetic's constant value.
# tmap keeps a constant as the single value of `mapping.aes[[aes]]`.
text_layers <- function(x) Filter(function(l) identical(l$layer, "text"), unclass(x))
aes_value <- function(l, aes) unname(unlist(l$mapping.aes[[aes]]$value))

test_that("a plain-column label sizes in tmap's 12-point units (#7)", {
  skip_if_not_installed("tmap")
  lab <- reg$layers$lake$label
  ly <- text_layers(gq_tmap_labels(reg, "lake"))
  expect_length(ly, 9)                     # eight halo copies, then the text
  main <- ly[[9]]
  expect_equal(aes_value(main, "text"), "gnis_name_1")
  expect_equal(aes_value(main, "size"), lab$size / 12)
  expect_equal(aes_value(main, "fontface"), "italic")
})

test_that("the text is last, in the registry colour; the halo copies are under it (#7)", {
  skip_if_not_installed("tmap")
  x <- gq_tmap_labels(reg, "lake")
  cols <- vapply(text_layers(x), aes_value, "", aes = "col")
  expect_equal(cols[9], reg$layers$lake$label$color)
  expect_true(all(cols[1:8] == reg$layers$lake$label$halo$color))
})

test_that("an expression label is refused until a column is named (#6, #7)", {
  skip_if_not_installed("tmap")
  expect_error(gq_tmap_labels(reg, "crossings_pscis_assessment"), "QGIS expression")
  expect_s3_class(gq_tmap_labels(reg, "crossings_pscis_assessment", field = "label"), "tmap")
})

test_that("a CSV label needs a column (#7)", {
  skip_if_not_installed("tmap")
  expect_error(gq_tmap_labels(reg, "town"), "names no column")
  expect_s3_class(gq_tmap_labels(reg, "town", field = "name"), "tmap")
})

test_that("a label with no halo is one layer", {
  skip_if_not_installed("tmap")
  layer <- list(type = "point", label = list(field = "n", size = 9, color = "#000000"))
  expect_length(text_layers(gq_tmap_labels(layer)), 1)
})

test_that("label_fontface combines weight and slant", {
  expect_equal(label_fontface(list(weight = "bold", style = "italic")), "bold.italic")
  expect_equal(label_fontface(list(weight = "bold")), "bold")
  expect_equal(label_fontface(list(style = "italic")), "italic")
  expect_equal(label_fontface(list()), "plain")
})

test_that("line labels follow their line, and overrides reach every layer (#7)", {
  skip_if_not_installed("tmap")
  ly <- text_layers(gq_tmap_labels(reg, "stream_labels", size = 0.5))
  expect_true(all(vapply(ly, function(l) isTRUE(l$trans.args$along_lines), TRUE)))
  expect_true(all(vapply(ly, aes_value, 0, aes = "size") == 0.5))
})
