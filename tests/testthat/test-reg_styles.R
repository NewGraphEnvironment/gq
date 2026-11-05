# Registry styles for floodplain and habitat comparison maps (#98) and the
# land-cover change palette (#67). Data assertions on the shipped reg_main.json:
# these layers exist so that every map of the same class draws it the same way,
# so the colour, label and opacity of each class is the contract.

styles <- function(key) {
  cls <- gq_tmap_classes(gq_reg_main(), key)
  data.frame(key = names(cls$values), color = unname(cls$values),
             label = unname(cls$labels),
             opacity = if (is.null(cls$opacities)) NA_real_ else unname(cls$opacities))
}

test_that("rule comparison carries #98's four classes on rule_class", {
  reg <- gq_reg_main()
  expect_equal(reg$layers$habitat_rule_comparison$type, "line")
  expect_equal(gq_tmap_classes(reg, "habitat_rule_comparison")$field, "rule_class")
  s <- styles("habitat_rule_comparison")
  expect_equal(s$key, c("both", "first", "second", "outside"))
  expect_equal(s$color, c("#1b6ca8", "#d95f02", "#1b9e77", "#7b3f98"))
  expect_equal(s$opacity, c(0.7, 0.7, 0.7, 0.45))
})

test_that("expected use runs low to high in five classes on grade_class", {
  s <- styles("habitat_expected_use")
  expect_equal(s$key, c("0-0.2", "0.2-0.4", "0.4-0.6", "0.6-0.8", "0.8-1"))
  expect_equal(s$color, c("#f7fbff", "#c6dbef", "#6baed6", "#2171b5", "#08306b"))
  expect_true(all(s$opacity == 0.7))
})

test_that("flood factor keys are flooded's scenario ids", {
  expect_equal(gq_tmap_classes(gq_reg_main(), "floodplain_flood_factor")$field,
               "scenario_id")
  s <- styles("floodplain_flood_factor")
  expect_equal(s$key, c("ff02", "ff04", "ff06"))
  expect_equal(s$label, c("Active channel margin", "Functional floodplain",
                          "Valley bottom"))
  expect_equal(s$color, c("#0b3c6f", "#1aa6a6", "#f2a93b"))
})

test_that("tree gain reads apart from the oranges it shares a page with", {
  # #98: gain's orange must not be read as first-rule-only, valley bottom or
  # the land-cover Crops class. CIEDE2000 > 10 is a visible difference; the
  # chosen pair was also checked by eye on the blended basemap (see the PR).
  skip_if_not_installed("farver")
  s <- styles("tree_cover_change")
  expect_equal(s$key, c("loss", "gain"))
  gain <- s$color[s$key == "gain"]
  others <- c("#d95f02", "#f2a93b", "#e49635")
  d <- farver::compare_colour(farver::decode_colour(gain),
                              farver::decode_colour(others),
                              from_space = "rgb", method = "cie2000")
  expect_true(all(d > 10), info = paste(round(d, 1), collapse = ", "))
})

test_that("land-cover change uses drift's IO LULC palette, both renderers", {
  reg <- gq_reg_main()
  expect_equal(gq_tmap_classes(reg, "landcover_change_from")$field, "from_class")
  expect_equal(gq_tmap_classes(reg, "landcover_change_to")$field, "to_class")
  from <- styles("landcover_change_from")
  expect_equal(from[, c("key", "color")], styles("landcover_change_to")[, c("key", "color")])
  expect_length(from$key, 9L)
  expect_false("No Data" %in% from$key)

  # Compared with drift's own table, not a copy kept here: the palette is
  # drift's, and a copy would agree with itself whatever drift ships.
  skip_if_not_installed("drift")
  tbl <- system.file("lulc_classes", "io_lulc_v02.csv", package = "drift")
  skip_if(tbl == "", "installed drift has no io_lulc_v02.csv")
  d <- utils::read.csv(tbl, stringsAsFactors = FALSE)
  d <- d[d$class_name != "No Data", ]
  expect_setequal(from$key, d$class_name)
  expect_equal(tolower(from$color[match(d$class_name, from$key)]), tolower(d$color))
})

test_that("a comparison line draws through tm_lines at its class opacity", {
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  for (code in c("both", "outside")) {
    a <- drawn_gp(tm_shape_classified(reg, "habitat_rule_comparison", code,
                                      field = "rule_class"), "alpha")[1]
    expect_equal(a, if (code == "both") 0.7 else 0.45, info = code)
  }
})
