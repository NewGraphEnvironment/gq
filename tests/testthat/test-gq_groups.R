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

test_that("a theme shipping in both templates agrees layer for layer", {
  # `template` is part of the key rather than a filter because a theme name is
  # not global -- `Land Tenure` is restoration-only, asserted above. That is the
  # surviving witness. It is NOT that the shared themes differ.
  #
  # This test used to demonstrate the point with `High Detail - Crossings`, whose
  # restoration copy had every layer switched off. That was not a legitimate
  # difference: bcrestoration shipped the preset as a STUB, enumerating 28 layers
  # and showing none, and rfp#217 repaired it. Pinning the zero made a defect
  # look like a design.
  #
  # What replaces it is a drift guard. The templates are separate .qgs files that
  # can move independently, and nothing structural keeps a shared theme in step.
  # A failure here means one template moved -- which is a decision for a human,
  # not necessarily a bug in either.
  #
  # So this is deliberately hard equality against an upstream free to diverge.
  # If rfp legitimately gives one template different content under a shared
  # name, the right response is to EDIT this test and record why -- not to
  # delete it, and not to loosen it until it stops failing. Deleting it is how
  # the assertion it replaced came to pin a bug as a design.
  xing <- gq_theme_layers("High Detail - Crossings")
  expect_setequal(unique(xing$template),
                  c("bcfishpass_mobile", "bcrestoration_mobile"))

  df <- gq_themes()

  # Assert the premise the comparison below rests on. `shared` is derived from
  # EVERY template, but the loop compares two named ones -- so a third template
  # sharing those themes would never be compared while this reported clean.
  # That is the pooled-guard shape gq#66 recorded: a check that looks per-source
  # and is not. Pinning the set means a third template fails here, naming the
  # real cause, instead of passing silently.
  expect_setequal(unique(df$template),
                  c("bcfishpass_mobile", "bcrestoration_mobile"))

  by_template <- split(df, df$template)
  shared <- Reduce(intersect, lapply(by_template, function(x) unique(x$theme)))

  # Pin the SET, not that it is non-empty. `expect_gt(length(shared), 0L)` would
  # pass having compared one theme if rfp dropped the other three from a
  # template — a comparison over a shrunken set passes for almost nothing.
  expect_setequal(shared, c("High Detail - Crossings",
                            "Low Detail - Bull Trout Model",
                            "Low Detail - Salmon Model",
                            "Low Detail - Steelhead Model"))

  for (th in shared) {
    a <- df[df$theme == th & df$template == "bcfishpass_mobile", ]
    b <- df[df$theme == th & df$template == "bcrestoration_mobile", ]

    # Compare by named lookup rather than merge(): merge() defaults to
    # all = FALSE, so a key present on one side only is dropped from the
    # comparison — the drift being reported is exactly the drift that shrinks
    # it. And because testthat continues past a failure, the flag check would
    # then print a reassuring "no disagreement" beneath the set failure.
    #
    # Named lookup gives NA for a one-sided key, and identical(NA, TRUE) is
    # FALSE, so it lands in `disagree`. First-wins on a duplicate key would be
    # silent, which is why "the roster's shape is what the generator reports"
    # below pins there being none.
    expect_setequal(a$layer_key, b$layer_key)  # theme named in the flag check
    va <- stats::setNames(a$visible, a$layer_key)
    vb <- stats::setNames(b$visible, b$layer_key)
    keys <- union(names(va), names(vb))
    disagree <- keys[!mapply(identical, va[keys], vb[keys])]
    expect_equal(
      length(disagree), 0L,
      info = paste0(th, ": key sets or flags differ between templates; ",
                    "disagreeing keys: ", paste(disagree, collapse = ", "))
    )
  }
})

test_that("no theme is a stub", {
  # rfp#217's shape: a preset that enumerates layers and shows none of them. It
  # reads as a deliberate minimal variant, so nothing downstream reports it.
  #
  # Deliberately over ALL template-theme pairs, not only the shared ones,
  # because `Land Tenure` is restoration-only and a shared-scoped check cannot
  # see an unshared theme at all.
  #
  # Note what that argument is NOT. `High Detail - Crossings` ships in both
  # templates, so the shared-scoped version WOULD have caught rfp#217. The
  # widening is not justified by the stub that prompted it; it is justified by
  # the theme the stub happened to miss.
  #
  # Be honest about the reach: this is a cheap tripwire for ONE shape, the
  # all-zero preset. A regression switching 24 of 25 layers off passes it, and
  # would pass the agreement guard too if the theme is unshared. The property
  # actually wanted is "themes.csv equals what the templates say", which needs a
  # live-template drift test (gq#78) -- not this.
  df <- gq_themes()
  # tapply over a list, not a pasted key: a separator can appear in a name and
  # silently merge two pairs into one group, masking a stub.
  visible_by_pair <- tapply(df$visible, list(df$template, df$theme), sum)
  zero <- which(visible_by_pair == 0, arr.ind = TRUE)
  stubs <- paste(rownames(visible_by_pair)[zero[, "row"]],
                 colnames(visible_by_pair)[zero[, "col"]], sep = " / ")
  expect_equal(
    length(stubs), 0L,
    info = paste("themes showing nothing:", paste(stubs, collapse = "; "))
  )
})

test_that("the roster's shape is what the generator reports", {
  # `data-raw/reg_extract_themes.R` prints "232 rows, 9 template-theme pairs" as
  # its acceptance criterion and nothing in the suite held it. Without this, a
  # truncated or empty roster passes every theme test above: the stub check
  # tapply()s over an empty frame and finds no stubs, which reads as health.
  #
  # These move when rfp changes a template, and are meant to be re-pinned
  # deliberately when that happens -- not loosened until they stop failing.
  df <- gq_themes()
  expect_equal(nrow(df), 232L)
  expect_equal(nrow(unique(df[c("template", "theme")])), 9L)

  # No duplicate key within a pair. The generator refuses to emit one
  # (data-raw/reg_extract_themes.R), and the agreement guard's named lookup is
  # first-wins, so a duplicate would be silently invisible there. Asserting the
  # premise here is what keeps that reliance from being undocumented.
  expect_equal(anyDuplicated(df[c("template", "theme", "layer_key")]), 0L)

  # Land Tenure is restoration-only and therefore never enters the agreement
  # loop -- the one theme with no content assertion otherwise.
  lt <- df[df$theme == "Land Tenure", ]
  expect_equal(nrow(lt), 26L)
  expect_equal(sum(lt$visible), 22L)
})

test_that("no theme turns an opaque basemap on", {
  # The regression that would put an opaque raster over a field map -- NEWS
  # records it as having twice cost a field user a layer.
  #
  # `Base - misc` holds FOUR opaque xyz basemaps. themes.csv names only
  # esri_world_topo today, so asserting that key alone would scope the guard by
  # coincidence rather than by the property. That coincidence has a known
  # expiry: data-raw/reg_extract_themes.R:18-20 anticipates rfp#185 re-saving
  # the presets "to include the other three xyz basemaps". At that regeneration
  # the shape counts above would be re-pinned as routine roster growth -- which
  # is what this file's own comment tells the next person to do -- and a live
  # satellite layer would ride through on a green suite.
  opaque <- c("esri_world_topo", "bing_aerial", "esri_satellite",
              "google_satellite")
  df <- gq_themes()

  # Pin the list against groups.csv, which is where the set is actually
  # defined. Kept as a literal rather than derived: `Base - misc` + wms is an
  # exact proxy today, but it is a proxy, and "is this opaque" is a judgement
  # that belongs written down rather than inferred from a filter. Pinning gets
  # the coverage without moving the judgement into the query.
  #
  # Without this the guard is scoped by coincidence one level up: a fifth
  # opaque basemap added to `Base - misc` and switched on in a theme passes
  # every assertion here. `Base - misc` gained all four of its current basemaps
  # in a single commit, so that is the demonstrated rate of change, not a
  # hypothetical one.
  g <- gq_groups()
  expect_setequal(opaque,
                  g$layer_key[g$group == "Base - misc" &
                                g$source_type == "wms"])

  # And pin which of them the roster names today, so the regeneration that adds
  # the other three (rfp#185) fails HERE, naming the reason, rather than
  # silently enlarging what the check below is responsible for.
  expect_setequal(intersect(unique(df$layer_key), opaque), "esri_world_topo")

  # The property: whichever of the four the roster names, no theme shows it.
  on <- df[df$layer_key %in% opaque & df$visible, ]
  expect_equal(
    nrow(on), 0L,
    info = paste("opaque basemap switched on:",
                 paste(unique(paste(on$template, on$theme, on$layer_key)),
                       collapse = "; "))
  )

  # esri_world_topo specifically is named by all 9 pairs -- it is the one row
  # gq#77's re-extraction had to leave alone.
  expect_equal(nrow(df[df$layer_key == "esri_world_topo", ]), 9L)
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
