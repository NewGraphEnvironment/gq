test_that("gq_qgs_extract parses mini project", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  expect_type(reg, "list")
  expect_equal(reg$version, "0.1.0")
  expect_true("layers" %in% names(reg))
})

test_that("gq_qgs_extract finds all 4 layers", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  expect_equal(length(reg$layers), 4)
  expect_true("lakes" %in% names(reg$layers))
  expect_true("streams" %in% names(reg$layers))
  expect_true("crossings" %in% names(reg$layers))
  expect_true("roads" %in% names(reg$layers))
})

test_that("gq_qgs_extract parses polygon fill correctly", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  lake <- reg$layers$lakes
  expect_equal(lake$type, "polygon")
  expect_equal(lake$fill$color, "#c6ddf0")
  expect_equal(lake$stroke$color, "#7ba7cc")
  expect_equal(lake$stroke$width, 0.5)
})

test_that("gq_qgs_extract parses line stroke correctly", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  stream <- reg$layers$streams
  expect_equal(stream$type, "line")
  expect_equal(stream$stroke$color, "#7ba7cc")
  expect_equal(stream$stroke$width, 0.4)
})

test_that("gq_qgs_extract parses point marker correctly", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  crossing <- reg$layers$crossings
  expect_equal(crossing$type, "point")
  expect_equal(crossing$mark$color, "#e74c3c")
  expect_equal(crossing$mark$radius, 4)
  expect_equal(crossing$mark$shape, "circle")
})

test_that("gq_qgs_extract parses categorized renderer", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  road <- reg$layers$roads
  expect_equal(road$type, "line")
  expect_true("classification" %in% names(road))
  expect_equal(road$classification$field, "road_type")
  expect_true("highway" %in% names(road$classification$classes))
  expect_true("arterial" %in% names(road$classification$classes))
  expect_equal(road$classification$classes$highway$color, "#c0392b")
  expect_equal(road$classification$classes$highway$width, 2.0)
})

test_that("gq_qgs_extract parses labels", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  road <- reg$layers$roads
  expect_true("label" %in% names(road))
  expect_equal(road$label$field, "road_name")
  expect_equal(road$label$font, "Arial")
  expect_equal(road$label$size, 10)
  expect_equal(road$label$weight, "bold")
  expect_equal(road$label$halo$width, 1.5)
})

test_that("gq_qgs_extract captures dash on classified line classes (#32)", {
  path <- test_path("fixtures", "mini_project.qgs")
  reg <- gq_qgs_extract(path)

  classes <- reg$layers$roads$classification$classes
  # arterial uses use_custom_dash=1 + customdash; raw pattern is preserved
  expect_equal(classes$arterial$dash, "0.66;2")
  # highway is solid — no dash field
  expect_null(classes$highway$dash)
})

test_that("parse_dash reads named, custom, and solid line styles (#32)", {
  line_layer <- function(...) {
    opts <- list(...)
    opt_xml <- paste0(
      sprintf('<Option name="%s" value="%s"/>', names(opts), unlist(opts)),
      collapse = ""
    )
    xml2::read_xml(paste0(
      '<layer class="SimpleLine"><Option type="Map">', opt_xml, "</Option></layer>"
    ))
  }

  # named style (e.g. transmission_line "dash dot")
  expect_equal(
    parse_dash(line_layer(line_style = "dash dot", use_custom_dash = "0")),
    "dash dot"
  )
  # custom dash flag wins even though line_style stays "solid"
  expect_equal(
    parse_dash(line_layer(
      line_style = "solid", use_custom_dash = "1", customdash = "0.66;2"
    )),
    "0.66;2"
  )
  # plain solid line -> no dash
  expect_true(is.na(
    parse_dash(line_layer(line_style = "solid", use_custom_dash = "0"))
  ))
})

test_that("gq_qgs_extract errors on missing file", {
  expect_error(gq_qgs_extract("nonexistent.qgs"))
})


# --- real template XML (#103) -------------------------------------------------
# template_excerpt.qgs is cut from rfp's bcrestoration_mobile.qgs by
# data-raw/fixture_extract_template.R, so these read the shapes QGIS writes.

excerpt <- function() {
  gq_qgs_extract(testthat::test_path("fixtures", "template_excerpt.qgs"))
}

test_that("a plain label field is read from <text-style fieldName> (#6)", {
  lab <- excerpt()$layers$lake$label
  expect_equal(lab$field, "gnis_name_1")
  expect_null(lab$expression)
  expect_equal(lab$style, "italic")
  expect_null(lab$weight)
  expect_equal(lab$placement, "around_point")
})

test_that("an expression label goes to `expression`, never `field` (#6)", {
  lab <- excerpt()$layers$crossings_pscis_assessment$label
  expect_null(lab$field)
  expect_equal(lab$expression, "concat( 'PSCIS', ' ', \"stream_crossing_id\" )")
})

test_that("label weight is read from fontWeight on both Qt scales (#7)", {
  reg <- excerpt()
  expect_equal(reg$layers$crossings_pscis_assessment$label$weight, "bold") # 75
  expect_equal(reg$layers$municipalities$label$weight, "bold")             # 87
  expect_null(reg$layers$lake$label$weight)                                # 50
  expect_equal(label_weight("700"), "bold")
  expect_equal(label_weight("600"), "bold")
  expect_null(label_weight("400"))
  expect_null(label_weight("50"))
  expect_null(label_weight(NA_character_))
})

test_that("line-label hints are carried where QGIS sets them (#7)", {
  reg <- excerpt()
  dra <- reg$layers$roads_dra$label
  expect_equal(dra$field, "structured_name_1")
  expect_equal(dra$placement, "line")
  expect_true(dra$merge_lines)
  expect_equal(dra$min_feature_size, 11)

  streams <- reg$layers$stream_labels$label
  expect_equal(streams$placement, "line")
  expect_true(streams$merge_lines)
  expect_null(streams$min_feature_size)   # 0 in the template: no minimum

  expect_null(reg$layers$lake$label$merge_lines)
})

test_that("rule-based labelling takes the first rule and says so (#7)", {
  reg <- excerpt()
  ften <- reg$layers$roads_ften$label
  expect_equal(ften$expression, "title(\"road_section_name\")")
  expect_match(ften$note, "2 rules")

  moti <- reg$layers$moti_major_structures$label   # one rule: nothing to say
  expect_match(moti$expression, "chris_hwy_structure_road_id", fixed = TRUE)
  expect_null(moti$note)
})

test_that("labelsEnabled with no settings yields no label", {
  expect_null(excerpt()$layers$crossings_pscis_confirmation$label)
})

test_that("layer opacity is folded into every emitted opacity (#38)", {
  ften <- excerpt()$layers$roads_ften$classification$classes
  expect_true(all(vapply(ften, function(x) isTRUE(all.equal(x$opacity, 0.7)), TRUE)))
})

test_that("a wide line under a narrow one is casing, the narrow one the stroke (#24)", {
  moti <- excerpt()$layers$moti_major_structures
  expect_equal(moti$casing, list(color = "#000000", width = 2.06))
  expect_equal(moti$stroke$color, "#ff6011")
  expect_equal(moti$stroke$width, 1.46)
  expect_null(moti$note)
})

test_that("railway ticks become a wide dashed overlay (#24)", {
  rail <- excerpt()$layers$railway
  expect_equal(rail$stroke, list(color = "#000000", width = 0.4))
  expect_equal(rail$overlay, list(color = "#000000", width = 2.4, dash = "0.2;2.8"))
  expect_null(rail$note)
})

test_that("an unmodelled symbol layer is named in the note (#24)", {
  reg <- excerpt()
  expect_match(reg$layers$wetland$note, "PointPatternFill")
  expect_match(reg$layers$wetland$note, "gq_style_qml")
  expect_match(reg$layers$municipalities$note, "SimpleFill")
})

test_that("a data-defined colour is flagged on the layer (#38)", {
  expect_match(excerpt()$layers$streams_salmon$note, "data-defined")
})

test_that("a QGIS layer definition file (.qlr) parses (#23)", {
  reg <- gq_qgs_extract(test_path("fixtures", "bcfishpass_excerpt.qlr"))
  expect_setequal(names(reg$layers), c("railway", "lake"))
  expect_equal(reg$layers$railway$type, "line")
  # PostgreSQL sources name the table, not a layername=
  expect_equal(reg$layers$railway$source_layer, "whse_basemapping.gba_railway_tracks_sp")
})

test_that("a categorized casing needs the lower line to be wider (#24)", {
  dra <- excerpt()$layers$roads_dra$classification$classes
  cased <- Filter(function(x) !is.null(x$casing_color), dra)
  expect_gt(length(cased), 0)
  expect_true(all(vapply(cased, function(x) x$casing_width > x$width, TRUE)))
})

test_that("Line placement on a polygon reads as perimeter", {
  layer <- xml2::read_xml(paste0(
    '<maplayer type="vector" geometry="Polygon" labelsEnabled="1"><labeling type="simple">',
    '<settings><text-style fieldName="name" isExpression="0" textOpacity="0.5"/>',
    '<placement placement="2"/></settings></labeling></maplayer>'
  ))
  lab <- parse_labels(layer, "polygon")
  expect_equal(lab$placement, "perimeter")
  expect_equal(lab$opacity, 0.5)
  expect_equal(parse_labels(layer, "line")$placement, "line")
})


# --- the shipped restoration registry (#103) ----------------------------------
# Counts measured against rfp's template (v0.93.0 to v0.94.0, unchanged): they
# hold the re-extract to what the template carries, not to what a test expects.

shipped <- function() {
  gq_reg_read(system.file("registry", "reg_qgis_restoration.json", package = "gq"))$layers
}

test_that("every template label names its source: 14 columns, 8 expressions", {
  lab <- Filter(Negate(is.null), lapply(shipped(), `[[`, "label"))
  expect_length(lab, 22)
  has_field <- vapply(lab, function(x) !is.null(x$field), logical(1))
  has_expr <- vapply(lab, function(x) !is.null(x$expression), logical(1))
  expect_true(all(xor(has_field, has_expr)))
  expect_equal(sum(has_field), 14)
  expect_equal(sum(has_expr), 8)
  expect_setequal(names(lab)[vapply(lab, function(x) identical(x$weight, "bold"), TRUE)],
                  c("municipalities", "crossings_pscis_assessment",
                    "crossings_pscis_modelled_dams"))
})

test_that("the shipped registry carries the railway ticks, MoTi casing and FTEN opacity", {
  layers <- shipped()
  expect_equal(layers$railway$overlay, list(color = "#000000", width = 2.4, dash = "0.2;2.8"))
  expect_equal(layers$moti_major_structures$casing, list(color = "#000000", width = 2.06))
  op <- vapply(layers$roads_ften$classification$classes, function(x) x$opacity %||% NA_real_, 1)
  expect_true(all(op == 0.7))
  expect_match(layers$streams_salmon$note, "data-defined")
})

test_that("the halo is read from the nested <text-buffer>", {
  halo <- excerpt()$layers$lake$label$halo
  expect_equal(halo$color, "#ffffff")
  expect_equal(halo$width, 0.3)
})

test_that("every template label with bufferDraw=1 keeps its halo", {
  doc <- xml2::read_xml(test_path("fixtures", "template_excerpt.qgs"))
  n_buf <- 0
  for (m in xml2::xml_find_all(doc, ".//maplayer[@labelsEnabled='1']")) {
    b <- xml2::xml_find_first(m, "./labeling//settings//text-buffer")
    if (identical(xml2::xml_attr(b, "bufferDraw"), "1")) n_buf <- n_buf + 1
  }
  n_halo <- sum(vapply(excerpt()$layers, function(x) !is.null(x$label$halo), TRUE))
  expect_gt(n_buf, 0)
  expect_equal(n_halo, n_buf)
})

test_that("a rule switched off is neither taken nor counted", {
  rules <- function(first_active) {
    xml2::read_xml(paste0(
      '<maplayer type="vector" geometry="Point" labelsEnabled="1"><labeling type="rule-based"><rules>',
      '<rule active="', first_active, '"><settings><text-style fieldName="off" isExpression="0"/></settings></rule>',
      '<rule><settings><text-style fieldName="a" isExpression="0"/></settings></rule>',
      '<rule><settings><text-style fieldName="b" isExpression="0"/></settings></rule>',
      "</rules></labeling></maplayer>"
    ))
  }
  off <- parse_labels(rules("0"), "point")
  expect_equal(off$field, "a")
  expect_match(off$note, "2 rules")
  on <- parse_labels(rules("1"), "point")
  expect_equal(on$field, "off")
  expect_match(on$note, "3 rules")
})

test_that("a categorized class reads symbol layers as a single symbol does (#103)", {
  line <- function(color, width, extra = "") {
    paste0(
      '<layer class="SimpleLine"', extra, '><Option type="Map">',
      '<Option name="line_color" value="', color, '"/>',
      '<Option name="line_width" value="', width, '"/></Option></layer>'
    )
  }
  renderer <- xml2::read_xml(paste0(
    '<renderer-v2 type="categorizedSymbol" attr="code"><categories>',
    '<category value="cased" label="cased" symbol="0"/>',
    '<category value="off" label="off" symbol="1"/>',
    '<category value="stacked" label="stacked" symbol="2"/>',
    "</categories><symbols>",
    # casing: a wide grey line under a dashed, half-transparent core
    '<symbol name="0" alpha="1" type="line">', line("156,156,156,255", "2"),
    '<layer class="SimpleLine"><Option type="Map">',
    '<Option name="line_color" value="255,196,133,128"/><Option name="line_width" value="1"/>',
    '<Option name="use_custom_dash" value="1"/><Option name="customdash" value="2;1"/>',
    "</Option></layer></symbol>",
    # a disabled first layer is not the class's style
    '<symbol name="1" alpha="1" type="line">', line("255,0,0,255", "3", ' enabled="0"'),
    line("0,0,255,255", "1"), "</symbol>",
    # a narrow line under a wider one is not a casing
    '<symbol name="2" alpha="1" type="line">', line("0,0,0,255", "1"),
    line("0,255,0,255", "2"), "</symbol>",
    "</symbols></renderer-v2>"
  ))
  out <- parse_categorized(renderer, "line")
  cls <- out$classification$classes
  expect_equal(cls$cased$casing_color, "#9c9c9c")
  expect_equal(cls$cased$casing_width, 2)
  expect_equal(cls$cased$color, "#ffc485")
  expect_equal(cls$cased$dash, "2;1")              # the core's dash, not the casing's
  expect_equal(cls$cased$opacity, round(128 / 255, 3))
  expect_equal(cls$off$color, "#0000ff")            # the disabled red layer is skipped
  expect_null(cls$off$casing_color)
  expect_null(cls$stacked$casing_color)
  expect_match(out$note, "class symbol layers not modelled: SimpleLine")
})

# --- one symbol reader for every renderer (#103, review round 3) ---------------

symbol_str <- function(body, alpha = "1") {
  paste0('<symbol name="0" alpha="', alpha, '" type="line">', body, "</symbol>")
}
symbol_xml <- function(body, alpha = "1") xml2::read_xml(symbol_str(body, alpha))
simple_line <- function(color, width) {
  paste0(
    '<layer class="SimpleLine"><Option type="Map">',
    '<Option name="line_color" value="', color, '"/>',
    '<Option name="line_width" value="', width, '"/></Option></layer>'
  )
}

test_that("a graduated class reads a casing as a categorized class does", {
  sym <- paste0(simple_line("156,156,156,255", "2"), simple_line("255,196,133,255", "1"))
  renderer <- xml2::read_xml(paste0(
    '<renderer-v2 type="graduatedSymbol" attr="v"><ranges>',
    '<range lower="0" upper="1" label="low" symbol="0"/></ranges>',
    "<symbols>", symbol_str(sym), "</symbols></renderer-v2>"
  ))
  cls <- parse_graduated(renderer, "line")$classification$classes[[1]]
  expect_equal(cls$color, "#ffc485")
  expect_equal(cls$width, 1)
  expect_equal(cls$casing_color, "#9c9c9c")
  expect_equal(cls$casing_width, 2)
})

test_that("a first symbol layer the registry cannot model is named too", {
  # pipeline_permit's shape: a hatch fill with an outline line over it
  layers <- xml2::xml_find_all(
    xml2::read_xml(test_path("fixtures", "template_excerpt.qgs")),
    ".//maplayer[layername='Wetland']/renderer-v2/symbols/symbol"
  )
  sr <- symbol_read(layers[[1]])
  expect_equal(sr$unmodelled, "PointPatternFill")       # SimpleFill first: modelled
  hatch <- symbol_xml(paste0('<layer class="LinePatternFill"/>', simple_line("0,0,0,255", "0.6")))
  expect_equal(symbol_read(hatch)$unmodelled, c("LinePatternFill", "SimpleLine"))
  lone <- symbol_xml('<layer class="LinePatternFill"/>')
  expect_equal(symbol_read(lone)$unmodelled, "LinePatternFill")
})

test_that("layer and symbol opacity reach the outline and the overlay too", {
  doc <- xml2::read_xml(test_path("fixtures", "template_excerpt.qgs"))
  rail <- xml2::xml_find_first(doc, ".//maplayer[layername='Railway']/renderer-v2")
  half <- parse_single_symbol(rail, "line", layer_opacity = 0.5)
  expect_equal(half$stroke$opacity, 0.5)
  expect_equal(half$overlay$opacity, 0.5)
  expect_null(parse_single_symbol(rail, "line")$overlay$opacity)

  muni <- xml2::xml_find_first(doc, ".//maplayer[layername='Municipalities']/renderer-v2")
  m <- parse_single_symbol(muni, "polygon")
  expect_equal(m$stroke$opacity, m$fill$opacity)        # symbol alpha 0.347, both opaque colours
})

test_that("a data-defined colour on a disabled layer is not flagged", {
  dd <- paste0(
    '<data_defined_properties><Option type="Map"><Option name="properties" type="Map">',
    '<Option name="outlineColor" type="Map"><Option name="active" value="true"/>',
    '<Option name="expression" value="\'#ff0000\'"/></Option></Option></Option>',
    "</data_defined_properties>"
  )
  renderer <- function(enabled) {
    xml2::read_xml(paste0(
      '<renderer-v2 type="singleSymbol"><symbols><symbol name="0" alpha="1" type="line">',
      '<layer class="SimpleLine" enabled="', enabled, '">', dd, "</layer>",
      "</symbol></symbols></renderer-v2>"
    ))
  }
  expect_true(color_data_defined(renderer("1")))
  expect_false(color_data_defined(renderer("0")))
})
