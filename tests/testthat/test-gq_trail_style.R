# Trail symbology in the registry (#41).
#
# The style is authored in rfp's `bcrestoration_mobile.qgs` and reaches here by
# extraction (`data-raw/reg_extract_restoration.R`), which is what that
# script's header already describes: gq owns the canonical styles, rfp owns the
# upstream project. So one authored artifact feeds three consumers - rfp styles
# every project it creates from the project's own `.qgs`, rfp's vector writer
# has a style to apply, and this registry gives tmap and mapgl theirs.
#
# The route matters and is the reason these tests assert what they do. A
# classified line authored the other way - by hand in `reg_custom.csv` - comes
# back with `widths` and `dashes` both NULL, because that writer emits
# `outline_width`/`outline_color` while `gq_style()` and `gq_tmap_classes()`
# read per-class `width`/`dash`. Dash is exactly what distinguishes a trail
# from a road, so the "did it survive" assertions below are not ceremony.

trail <- function() gq_reg_main()$layers$trails

test_that("the registry carries a trail layer", {
  expect_false(is.null(trail()))
  expect_equal(trail()$type, "line")
  expect_equal(trail()$source_layer, "osm.trail")
})

test_that("it is classified on highway, the only universally populated tag", {
  # Measured over 13,245 real features: `highway` 100% populated, `bicycle`
  # 16.4%, `name` 15.3%. Classifying on `bicycle` would put 84% in a fallback
  # class - and would assert that an unsurveyed tag means prohibited.
  cls <- trail()$classification
  expect_equal(cls$field, "highway")
  expect_setequal(names(cls$classes),
                  c("path", "footway", "cycleway", "bridleway"))
})

test_that("per-class width and dash survive into the translators", {
  # THE test. This is the property the hand-curated CSV route cannot produce -
  # it returns NULL for both - so a green here is also the evidence for why the
  # style is authored in a QGIS project and extracted rather than written by
  # hand as registry rows.
  cls <- gq_tmap_classes(trail())
  expect_equal(cls$field, "highway")
  expect_false(is.null(cls$widths))
  expect_false(is.null(cls$dashes))
  expect_length(cls$widths, 4L)
  expect_length(cls$dashes, 4L)
  expect_true(all(!is.na(cls$dashes)))
  expect_true(all(cls$widths > 0))
})

test_that("classes are distinguishable by more than colour", {
  # Colour alone fails twice over: printed greyscale, and a phone screen in
  # direct sun. Asserted as a property - all four distinct on (dash, width) -
  # rather than by pinning values, so restyling upstream does not fail this
  # while a collapse into indistinguishable classes still does.
  cls <- gq_tmap_classes(trail())
  expect_equal(length(unique(paste(cls$dashes, cls$widths))), 4L)
  expect_equal(length(unique(cls$values)), 4L)   # ...and by colour too
})

test_that("each class carries a human label, not the raw OSM tag value", {
  cls <- gq_tmap_classes(trail())
  expect_length(cls$labels, 4L)
  expect_true(all(nzchar(cls$labels)))
  expect_false(any(cls$labels %in% names(trail()$classification$classes)))
})

test_that("mapgl gets a usable dash array", {
  # `gq_mapgl_style()` parses a dash by splitting on ";" or " ", so a raw
  # customdash string like "5;2" works and a QGIS style NAME like "dash" is
  # passed through. Asserted because the choice of `line_style` names over
  # `customdash` was made for tmap's benefit, and must not have broken mapgl.
  s <- gq_mapgl_style(trail())
  expect_type(s, "list")
  expect_gt(length(s), 0L)
})

test_that("trails are in both templates, in the roads group", {
  # `groups.csv` is what makes `rfp_project_layers()` return the layer, so a
  # style with no row here is invisible to project creation.
  for (t in c("bcfishpass_mobile", "bcrestoration_mobile")) {
    l <- gq_template_layers(t)
    r <- l[l$layer_key == "trails", , drop = FALSE]
    expect_equal(nrow(r), 1L, info = t)
    expect_equal(r$source_layer[[1]], "osm.trail", info = t)
    expect_equal(r$source_type[[1]], "osm", info = t)
    expect_equal(r$group[[1]], "Roads,Railways,Pipelines", info = t)
  }
})

test_that("the source_layer matches what rfp downloads", {
  # `source_layer` is parsed from `layername=` in the template's datasource, and
  # rfp's osm lookup is keyed by exactly that string. A mismatch means the
  # project downloads a table the style never reaches.
  expect_equal(trail()$source_layer, "osm.trail")
  expect_match(trail()$source_layer, "^[a-z][a-z0-9_]*[.][a-z][a-z0-9_]*$")
})
