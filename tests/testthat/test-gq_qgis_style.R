# gq_qgis_style() writes what the registry holds in the form QGIS writes. The
# round trips below read the QML back with gq's own extractor (parse_categorized
# and parse_single_symbol in gq_qgs_extract.R), written long before the writer
# and against QML QGIS itself saved, so the writer is checked against an
# independent reader rather than against itself. The XML checks beside them
# read the attributes directly, so a reader that forgave a defect would not
# hide it.

fixture_reg <- function() gq_reg_custom(testthat::test_path("fixtures", "qml_registry.csv"))

qml_renderer <- function(qml) {
  xml2::xml_find_first(xml2::read_xml(qml), ".//renderer-v2")
}

test_that("a classified line comes back with every class's value, label and colour", {
  reg <- fixture_reg()
  sty <- gq_style(reg, "cls_line")
  r <- qml_renderer(gq_qgis_style(reg, "cls_line"))
  expect_equal(xml2::xml_attr(r, "type"), "categorizedSymbol")
  expect_equal(xml2::xml_attr(r, "attr"), "kind")

  # directly from the XML: one category per class, in registry order
  cats <- xml2::xml_find_all(r, "./categories/category")
  expect_equal(xml2::xml_attr(cats, "value"), names(sty$classification$values))
  expect_equal(xml2::xml_attr(cats, "label"), unname(sty$classification$labels))
  syms <- xml2::xml_find_all(r, "./symbols/symbol")
  expect_equal(length(syms), length(cats))
  expect_setequal(xml2::xml_attr(syms, "name"), xml2::xml_attr(cats, "symbol"))

  # through the extractor
  back <- parse_categorized(r, "line")
  expect_equal(back$classification$field, "kind")
  expect_equal(names(back$classification$classes),
               names(sty$classification$values))
  for (k in names(sty$classification$values)) {
    cls <- back$classification$classes[[k]]
    expect_equal(cls$color, unname(sty$classification$values[[k]]), info = k)
    # the extractor keeps a label only where it differs from the value
    expect_equal(cls$label %||% k, unname(sty$classification$labels[[k]]),
                 info = k)
  }
  cl <- back$classification$classes
  expect_equal(cl[["a & b"]]$width, 0.6)
  expect_equal(cl[["a & b"]]$dash, "4;2")
  expect_equal(cl[["a & b"]]$opacity, 0.5)
  expect_equal(cl[["c, d"]]$width, 0.3)
  expect_equal(cl[["c, d"]]$dash, "dot")
  expect_null(cl[["c, d"]]$opacity)
  expect_equal(cl[["10"]]$width, 0.26)   # QGIS's default where the registry has none
  expect_null(cl[["10"]]$dash)
})

test_that("a classified polygon keeps fill and outline opacity apart", {
  reg <- fixture_reg()
  r <- qml_renderer(gq_qgis_style(reg, "cls_poly"))
  back <- parse_categorized(r, "polygon")$classification$classes
  expect_equal(names(back), c("SBS", "ESSF"))
  expect_equal(back$SBS$color, "#8fbc8f")
  expect_equal(back$SBS$label, "Sub-Boreal Spruce")
  # colour alpha is a byte, so an opacity comes back to the nearest 1/255
  expect_lt(abs(back$SBS$opacity - 0.25), 1 / 255)
  expect_equal(back$SBS$outline_width, 0.5)
  expect_equal(back$ESSF$color, "#b0c4de")
  expect_null(back$ESSF$opacity)

  sbs <- xml2::xml_find_first(r, "./symbols/symbol[@name='0']")
  opt <- function(n) {
    xml2::xml_attr(xml2::xml_find_first(sbs, paste0(".//Option[@name='", n, "']")),
                   "value")
  }
  expect_equal(opt("color"), "143,188,143,64")            # fill at 0.25
  expect_equal(opt("outline_color"), "136,136,136,102")   # outline at 0.4
  expect_equal(opt("outline_style"), "solid")
  expect_equal(xml2::xml_attr(sbs, "alpha"), "1")
})

test_that("an unclassified line and polygon write a single symbol", {
  reg <- fixture_reg()
  rl <- qml_renderer(gq_qgis_style(reg, "simple_line"))
  expect_equal(xml2::xml_attr(rl, "type"), "singleSymbol")
  line <- parse_single_symbol(rl, "line")$stroke
  expect_equal(line$color, "#000000")
  expect_equal(line$width, 0.4)
  expect_equal(line$dash, "dash dot")
  expect_equal(line$opacity, 0.8)

  rp <- qml_renderer(gq_qgis_style(reg, "simple_poly"))
  poly <- parse_single_symbol(rp, "polygon")
  expect_equal(poly$fill$color, "#dcecf4")
  expect_lt(abs(poly$fill$opacity - 0.7), 1 / 255)
  expect_equal(poly$stroke$color, "#1f78b4")
  expect_equal(poly$stroke$width, 0.2)
})

test_that("the document declares its geometry and only symbology", {
  reg <- fixture_reg()
  for (k in c("cls_line", "simple_line", "cls_poly", "simple_poly")) {
    doc <- xml2::read_xml(gq_qgis_style(reg, k))
    root <- xml2::xml_root(doc)
    expect_equal(xml2::xml_name(root), "qgis", info = k)
    expect_equal(xml2::xml_attr(root, "styleCategories"), "Symbology", info = k)
    # QGIS refuses a style whose geometry type differs from the layer's
    expect_equal(
      xml2::xml_text(xml2::xml_find_first(doc, "./layerGeometryType")),
      if (grepl("line", k)) "1" else "2", info = k
    )
  }
})

test_that("field overrides the categorized attribute", {
  reg <- fixture_reg()
  r <- qml_renderer(gq_qgis_style(reg, "cls_line", field = "my_kind"))
  expect_equal(xml2::xml_attr(r, "attr"), "my_kind")
})

test_that("a layer object works as well as a registry and name", {
  reg <- fixture_reg()
  expect_identical(gq_qgis_style(reg$layers$cls_line), gq_qgis_style(reg, "cls_line"))
})

test_that("path writes the same document it returns", {
  reg <- fixture_reg()
  f <- withr::local_tempfile(fileext = ".qml")
  out <- gq_qgis_style(reg, "cls_line", path = f)
  expect_true(file.exists(f))
  expect_identical(readChar(f, file.size(f), useBytes = TRUE), out)
})

test_that("point and raster layers, and an overlay, are refused or flagged", {
  reg <- fixture_reg()
  expect_error(gq_qgis_style(reg, "simple_point"), "line and polygon")
  custom <- gq_reg_custom(system.file("registry", "reg_custom.csv", package = "gq"))
  expect_error(gq_qgis_style(custom, "habitat_lateral"), "raster")

  railway <- list(type = "line", stroke = list(color = "#000000", width = 1),
                  overlay = list(color = "#ffffff", width = 0.5, dash = "4 2"))
  expect_warning(gq_qgis_style(railway), "overlay")
})

test_that("a bad colour or dash stops, naming the class", {
  classes <- list(a = list(color = "#000000"), b = list(color = "notacolour"))
  bad_col <- list(type = "line",
                  classification = list(field = "f", classes = classes))
  expect_error(gq_qgis_style(bad_col), "class 'b'")
  classes <- list(a = list(color = "#000000", dash = "dashed"))
  bad_dash <- list(type = "line",
                   classification = list(field = "f", classes = classes))
  expect_error(gq_qgis_style(bad_dash), "dashed")
})

test_that("every main-registry line and polygon layer builds a parseable QML", {
  # The extractor's registry is the other source a caller hands this function,
  # so build every line and polygon layer it holds and parse the result.
  reg <- gq_reg_main()
  keys <- names(reg$layers)[vapply(reg$layers, function(l) {
    l$type %in% c("line", "polygon")
  }, logical(1))]
  expect_gt(length(keys), 30)
  # a layer whose QGIS symbol the registry could not model has no colour at
  # all, and is refused rather than written as an invisible symbol
  modelled <- vapply(keys, function(k) {
    l <- reg$layers[[k]]
    !is.null(l$classification) || !is.null(l$fill$color) || !is.null(l$stroke$color)
  }, logical(1))
  for (k in keys[!modelled]) {
    expect_error(gq_qgis_style(reg, k), "neither a fill nor a stroke", info = k)
  }
  for (k in keys[modelled]) {
    qml <- suppressWarnings(gq_qgis_style(reg, k))
    r <- qml_renderer(qml)
    n_cls <- length(gq_style(reg, k)$classification$values)
    if (n_cls > 0) {
      expect_equal(length(xml2::xml_find_all(r, "./categories/category")), n_cls,
                   info = k)
    } else {
      expect_equal(xml2::xml_attr(r, "type"), "singleSymbol", info = k)
    }
  }
})
