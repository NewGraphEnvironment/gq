# --- groups -------------------------------------------------------------------

test_that("gq_groups returns all group mappings", {
  df <- gq_groups()
  expect_s3_class(df, "data.frame")
  expect_true(all(c("group", "subgroup", "layer_key", "order") %in% names(df)))
  expect_gt(nrow(df), 40)
})

test_that("gq_groups with registry joins source_layer and type", {
  reg <- gq_reg_main()
  df <- gq_groups(registry = reg)
  expect_true(all(c("source_layer", "type") %in% names(df)))
  # lake should have a source_layer
  lake_row <- df[df$layer_key == "lake", ]
  expect_equal(lake_row$source_layer, "whse_basemapping.fwa_lakes_poly")
  expect_equal(lake_row$type, "polygon")
})

test_that("gq_group_layers returns correct group", {
  df <- gq_group_layers("Basemap")
  expect_s3_class(df, "data.frame")
  expect_true(all(df$group == "Basemap"))
  expect_true("lake" %in% df$layer_key)
  expect_true("watershed_group_boundary" %in% df$layer_key)
})

test_that("gq_group_layers includes subgroups", {
  df <- gq_group_layers("Streams")
  # direct children
  expect_true("streams_all" %in% df$layer_key)
  # subgroup children
  expect_true("streams_bt" %in% df$layer_key)
  expect_true(any(df$subgroup == "Habitat models", na.rm = TRUE))
})

test_that("gq_group_layers returns empty for unknown group", {
  df <- gq_group_layers("NonexistentGroup")
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 0)
})

test_that("gq_group_layers with registry joins info", {
  reg <- gq_reg_main()
  df <- gq_group_layers("Crossings", registry = reg)
  expect_true("source_layer" %in% names(df))
  # crossings_pscis_assessment should have source_layer
  row <- df[df$layer_key == "crossings_pscis_assessment", ]
  expect_equal(row$source_layer, "whse_fish.pscis_assessment_svw")
})

test_that("all registry keys appear in groups.csv", {
  reg <- gq_reg_main()
  groups_df <- gq_groups()
  reg_keys <- names(reg$layers)
  groups_keys <- unique(groups_df$layer_key)
  missing <- setdiff(reg_keys, groups_keys)
  expect_equal(
    length(missing), 0,
    info = paste("Missing:", paste(missing, collapse = ", "))
  )
})


# --- templates ----------------------------------------------------------------

test_that("gq_templates returns all templates", {
  df <- gq_templates()
  expect_s3_class(df, "data.frame")
  expect_true(all(c("template", "group", "group_order") %in% names(df)))
  expect_true("bcfishpass_mobile" %in% df$template)
  expect_true("bcrestoration_mobile" %in% df$template)
})

test_that("gq_template_groups returns ordered groups", {
  df <- gq_template_groups("bcfishpass_mobile")
  expect_s3_class(df, "data.frame")
  expect_true(all(df$template == "bcfishpass_mobile"))
  # Should be ordered by group_order
  expect_equal(df$group_order, sort(df$group_order))
  expect_true("Forms" %in% df$group)
  expect_true("Crossings" %in% df$group)
})

test_that("gq_template_groups returns empty for unknown template", {
  df <- gq_template_groups("nonexistent")
  expect_equal(nrow(df), 0)
})

test_that("gq_template_layers resolves full layer list", {
  df <- gq_template_layers("bcfishpass_mobile")
  expect_s3_class(df, "data.frame")
  cols <- c("template", "group", "group_order", "subgroup",
            "layer_key", "order", "source_layer", "type")
  expect_true(all(cols %in% names(df)))
  # Should have layers from multiple groups
  expect_true("crossings_pscis_assessment" %in% df$layer_key)
  expect_true("lake" %in% df$layer_key)
  expect_true("streams_all" %in% df$layer_key)
  # All rows should be bcfishpass_mobile
  expect_true(all(df$template == "bcfishpass_mobile"))
})

test_that("gq_template_layers returns empty for unknown template", {
  df <- gq_template_layers("nonexistent")
  expect_equal(nrow(df), 0)
})

test_that("bcrestoration_mobile has Floodplain and Restoration groups", {
  df <- gq_template_layers("bcrestoration_mobile")
  expect_true("floodplains" %in% df$layer_key)
  expect_true("harvest_area" %in% df$layer_key)
  expect_true("planting_site" %in% df$layer_key)
})


# --- themes -------------------------------------------------------------------

test_that("gq_themes returns the layer-granular roster", {
  df <- gq_themes()
  expect_s3_class(df, "data.frame")
  expect_true(all(c("template", "theme", "layer_key", "visible") %in% names(df)))
  expect_type(df$visible, "logical")
  expect_false(any(is.na(df$visible)))
})

test_that("gq_themes names only themes the templates ship", {
  df <- gq_themes()
  expect_true("High Detail - Crossings" %in% df$theme)
  # the roster used to name three themes that exist in no template
  expect_false(any(c("Field View", "Analysis View", "UAV View") %in% df$theme))
})

test_that("gq_themes filters by template, and Land Tenure is restoration-only", {
  expect_equal(unique(gq_themes("bcfishpass_mobile")$template),
               "bcfishpass_mobile")
  expect_false("Land Tenure" %in% gq_themes("bcfishpass_mobile")$theme)
  expect_true("Land Tenure" %in% gq_themes("bcrestoration_mobile")$theme)
})

test_that("one theme name carries different content per template", {
  # The case the old group-granular schema could not represent, and the reason
  # `template` is part of the key rather than a filter.
  xing <- gq_theme_layers("High Detail - Crossings")
  expect_setequal(unique(xing$template),
                  c("bcfishpass_mobile", "bcrestoration_mobile"))
  visible_by_template <- tapply(xing$visible, xing$template, sum)
  expect_gt(visible_by_template[["bcfishpass_mobile"]], 0)
  expect_equal(visible_by_template[["bcrestoration_mobile"]], 0)
})

test_that("gq_theme_layers without template concatenates both templates", {
  # Documented behaviour: the caller checks the template column, or passes it.
  both <- gq_theme_layers("High Detail - Crossings")
  one <- gq_theme_layers("High Detail - Crossings",
                         template = "bcfishpass_mobile")
  expect_gt(nrow(both), nrow(one))
  expect_equal(unique(one$template), "bcfishpass_mobile")
})

test_that("gq_theme_layers returns empty for unknown theme", {
  expect_equal(nrow(gq_theme_layers("Nonexistent Theme")), 0)
})

test_that("every theme layer_key exists in groups.csv", {
  # Mirror of the registry-keys integrity test above. A theme naming a layer the
  # roster does not carry is the dangling reference the extraction script aborts
  # on; this pins it for the committed data too.
  missing <- setdiff(unique(gq_themes()$layer_key), unique(gq_groups()$layer_key))
  expect_equal(
    length(missing), 0,
    info = paste("Missing from groups.csv:", paste(missing, collapse = ", "))
  )
})

test_that("parse_visible rejects values it cannot interpret", {
  expect_equal(parse_visible(c("true", "false")), c(TRUE, FALSE))
  expect_equal(parse_visible(c(TRUE, FALSE)), c(TRUE, FALSE))
  expect_error(parse_visible(c("true", "1")), "must be true or false")
  expect_error(parse_visible(c("yes", "no")), "must be true or false")
})
