# xref_layers.csv: alternative sources for a classified layer (#84).
#
# Nothing reads this file in code; it tells a person which `field =` to pass
# when data comes from somewhere other than the registry's own source. Each row
# names the DATABASE table the bundled data was queried from
# (data-raw/neexdzii_kwa.R), not an object in the bucket rfp downloads: #84
# compared `bcfishpass.crossings` with the bucket, found a 404, and was
# comparing the wrong artifact. What can drift is checked here.

xref <- utils::read.csv(system.file("registry", "xref_layers.csv", package = "gq"),
                        colClasses = "character", na.strings = character(0))

test_that("every xref row names a classified registry layer", {
  reg <- gq_reg_main()
  expect_gt(nrow(xref), 0)
  expect_true(all(xref$name_qgis_snake %in% names(reg$layers)))
  for (key in xref$name_qgis_snake) {
    expect_false(is.null(reg$layers[[key]][["classification"]]), info = key)
  }
})

test_that("every xref row differs from the registry's own field", {
  # A row exists only because the alternative source classifies on a column
  # the registry does not. A row whose class_field equals the registry's is
  # noise at best, and at worst sends `field =` to a column the data lacks.
  reg <- gq_reg_main()
  own <- vapply(xref$name_qgis_snake, function(key) {
    reg$layers[[key]][["classification"]][["field"]]
  }, character(1))
  expect_true(all(nzchar(xref$class_field)))
  expect_true(all(xref$class_field != own),
              info = paste(xref$name_qgis_snake[xref$class_field == own],
                           collapse = ", "))
})
