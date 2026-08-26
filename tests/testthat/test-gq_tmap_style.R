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
  # This asserted 2 until #16 -- radius 6 through the old `/ 3` divisor. That
  # was pinning the bug: a circle draws 3.81 mm of ink per size unit, so size 2
  # put the 6 mm QGIS marker on the page at 7.62 mm, 27% oversized. A 6 mm
  # marker must draw as 6 mm.
  expect_equal(args$size, gq_symbol_size(6, "tmap"))
  expect_equal(args$size * 3.81, 6, tolerance = 1e-3)
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
  # This asserted `args$lwd == 2` until #36. mini_registry's road classes have
  # widths 2.0 and 1.5, so that was pinning the bug: lwd collapsed to the first
  # registry class and every road drew at 2. Width is now mapped like colour.
  expect_equal(args$lwd, "road_type")
  expect_s3_class(args$lwd.scale, "tm_scale_categorical")
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


# --- #53: labels align to levels, not to the data's subset --------------------

test_that("a classified layer whose data carries a subset draws its own labels", {
  # tm_scale_categorical() matches colours by NAME and labels by POSITION, and
  # tmap builds levels from the data. With 3 of 26 classes present it therefore
  # took labels[1:3] regardless of which three, and a resource road rendered
  # labelled "Freeway". No list-inspecting test could see this -- the wrong
  # labels only exist inside tmap.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  cls <- gq_tmap_classes(reg, "roads_dra")
  keys <- names(cls$values)

  pick <- keys[c(20, 22, 24)]
  truth <- unique(cls$labels[match(pick, keys)])
  # Guard the fixture: if these three ever stop sharing one label, or stop
  # sitting past the front of the registry order, the test stops exercising
  # the bug and would pass for the wrong reason.
  expect_length(truth, 1)
  expect_false(truth %in% cls$labels[seq_along(pick)])

  labs <- drawn_labels(render_classified(reg, "roads_dra", pick))

  expect_gt(length(labs), 0)
  expect_true(truth %in% labs)
  expect_false(any(cls$labels[seq_along(pick)] %in% labs))
})

test_that("a classified subset draws without the label-recycling warning", {
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  pick <- names(gq_tmap_classes(reg, "roads_dra")$values)[c(20, 22, 24)]
  expect_no_warning(drawn_labels(render_classified(reg, "roads_dra", pick)))
})


test_that("every classified registry layer draws only its data's own labels", {
  # The invariant the roads_dra test above cannot establish on its own. A fix
  # verified on one hand-picked layer is exactly the shape code-check.md warns
  # about -- 10 other layers carry classifications, and a fixture set that
  # cannot reach the failure mode is not validation.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  keys <- names(reg$layers)[vapply(reg$layers,
                                   function(l) !is.null(l$classification),
                                   logical(1))]
  expect_gt(length(keys), 0)

  discriminating <- 0L
  for (k in keys) {
    cls <- gq_tmap_classes(reg, k)
    codes <- names(cls$values)
    # Take from the BACK of registry order: positional recycling reads from the
    # front, so a subset drawn from the front could match by coincidence.
    pick <- utils::tail(codes, 3)
    truth <- unique(cls$labels[match(pick, codes)])
    positional <- unique(cls$labels[seq_along(pick)])

    parts <- drawn_parts(render_classified(reg, k, pick))
    drawn <- setdiff(parts$labels, "code")

    expect_gt(length(drawn), 0)
    expect_true(all(drawn %in% truth), info = k)
    expect_true(all(toupper(unname(cls$values[pick])) %in% parts$colours),
                info = k)

    wrong <- setdiff(positional, truth)
    if (length(wrong)) {
      discriminating <- discriminating + 1L
      expect_false(any(wrong %in% drawn), info = k)
    }
  }

  # Without this the sweep could pass against the unfixed code: if no layer's
  # positional labels differed from its true ones, every assertion above would
  # hold either way and the sweep would prove nothing.
  expect_gt(discriminating, 0)
})

test_that("no classified registry layer warns about label recycling", {
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  keys <- names(reg$layers)[vapply(reg$layers,
                                   function(l) !is.null(l$classification),
                                   logical(1))]
  for (k in keys) {
    pick <- utils::tail(names(gq_tmap_classes(reg, k)$values), 3)
    expect_no_warning(drawn_parts(render_classified(reg, k, pick)))
  }
})


# --- #36: every classified axis is per-class, not just colour -----------------

test_that("a classified line layer draws each class at its own width", {
  # tmap_classified() emitted lwd = cls$widths[1] -- the FIRST REGISTRY CLASS,
  # nothing to do with the data. streams_bt encodes two orthogonal variables in
  # one key: habitat use drives width, barrier status drives colour. Colour
  # rendered correctly, so half the layer silently vanished and the map looked
  # fine unless you knew what the widths should be.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  cls <- gq_tmap_classes(reg, "streams_bt")

  pick <- c("SPAWN;NONE", "REAR;NONE", "ACCESS;NONE")
  expect_length(unique(cls$widths[pick]), 3)  # fixture must span the axis

  for (code in pick) {
    m <- tm_shape_classified(reg, "streams_bt", code)
    expect_equal(drawn_gp(m, "lwd")[1], unname(cls$widths[[code]]), info = code)
  }
})

test_that("a classified line layer draws per-class dash", {
  # cls$dashes was never read by tmap_classified() at all, while
  # gq_tmap_legend() has emitted per-class lty since #32 -- so the legend drew a
  # dashed key beside a line the map drew solid. Invisible to any test looking
  # at only one of the two.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  cls <- gq_tmap_classes(reg, "streams_bt")

  dashed <- "SPAWN;NONE;INTERMITTENT"
  solid <- "SPAWN;NONE"
  expect_false(is.na(cls$dashes[[dashed]]))
  expect_true(is.na(cls$dashes[[solid]]))

  expect_equal(drawn_gp(tm_shape_classified(reg, "streams_bt", dashed), "lty")[1],
               "dashed")
  expect_equal(drawn_gp(tm_shape_classified(reg, "streams_bt", solid), "lty")[1],
               "solid")
})

test_that("a classified point layer carries per-class size", {
  # No classified size assertion existed at all. crossings_pscis_assessment is
  # the only layer with per-class radius and the central point layer of every
  # fish passage map.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  sty <- gq_style(reg, "crossings_pscis_assessment")
  expect_false(is.null(sty$classification$radii))

  args <- gq_tmap_style(reg, "crossings_pscis_assessment", field = "code")
  # size becomes the field name, mapped through a scale -- as fill already is.
  expect_equal(args$size, "code")
  expect_s3_class(args$size.scale, "tm_scale_categorical")
})


test_that("every classified layer draws each class at its registry width", {
  # Per-feature, across the whole registry. The single-layer test above cannot
  # establish this: 6 line layers carry widths and each loses a real axis.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  keys <- names(reg$layers)[vapply(reg$layers, function(l) {
    identical(l$type, "line") && !is.null(l$classification)
  }, logical(1))]
  expect_gt(length(keys), 0)

  spanning <- 0L
  for (k in keys) {
    cls <- gq_tmap_classes(reg, k)
    if (is.null(cls$widths) || anyNA(cls$widths)) next
    codes <- names(cls$values)
    # One code per distinct width, so the check spans the axis rather than
    # sampling one end of it.
    pick <- codes[match(unique(cls$widths), cls$widths)]
    if (length(unique(cls$widths)) > 1) spanning <- spanning + 1L

    for (code in pick) {
      got <- drawn_gp(tm_shape_classified(reg, k, code), "lwd")[1]
      expect_equal(got, unname(cls$widths[[code]]), info = paste(k, code))
    }
  }

  # Without a layer whose widths differ, every assertion above holds against the
  # scalar-collapse code too and the sweep proves nothing.
  expect_gt(spanning, 0)
})

test_that("map and legend agree on per-class dash", {
  # gq_tmap_legend() has emitted per-class lty since #32 while the map never
  # read cls$dashes at all, so the legend drew a dashed key beside a solid line.
  # A test looking at either side alone cannot see a disagreement.
  skip_if_not_installed("tmap")
  reg <- gq_reg_main()
  keys <- names(reg$layers)[vapply(reg$layers, function(l) {
    identical(l$type, "line") && !is.null(l$classification)
  }, logical(1))]

  checked <- 0L
  for (k in keys) {
    cls <- gq_tmap_classes(reg, k)
    if (is.null(cls$dashes)) next
    leg <- gq_tmap_legend(reg, k)$lines
    codes <- names(cls$values)

    for (code in codes[c(1, length(codes))]) {
      j <- match(unname(cls$labels[match(code, codes)]), leg$labels)
      if (is.na(j)) next
      map_lty <- drawn_gp(tm_shape_classified(reg, k, code), "lty")[1]
      leg_lty <- leg$lty[[j]]
      expect_equal(map_lty, leg_lty, info = paste(k, code))
      checked <- checked + 1L
    }
  }
  expect_gt(checked, 0)
})
