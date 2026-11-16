#' Extract layer styles from a QGIS project file
#'
#' Parses a `.qgs` project, or a `.qlr` layer definition file, and extracts
#' symbology (fill, stroke, casing, overlay, classification, labels) for all
#' vector layers into a list suitable for writing to registry.json. Both
#' formats keep their layers as `<maplayer>` nodes, so one reader serves both.
#'
#' The registry models what tmap and mapgl can render, not every property QGIS
#' stores. What it cannot express (pattern fills, stacked markers, symbol-layer
#' pass order) is named in the layer's `note`; the QML from [gq_style_qml()]
#' carries it losslessly.
#'
#' Labels carry the label column as `field`, or the raw QGIS expression as
#' `expression` when the label is computed (`concat(...)`, `CASE ...`), never
#' both, so a consumer reading `field` as a column cannot be handed an
#' expression. `placement` is QGIS's placement mode as a word (`"line"`,
#' `"around_point"`, ...). `merge_lines` and `min_feature_size` (mm) are hints
#' for the consumer's data prep: QGIS joins connected lines that share a label
#' and skips short features, which tmap and MapLibre cannot do, so dissolve by
#' the label field and drop short features before drawing.
#'
#' A layer's own opacity (`<layerOpacity>`) is folded into every opacity it
#' emits, as QGIS composes them.
#'
#' @param path Path to a .qgs or .qlr file.
#' @return A list with `name`, `version`, `source`, and `layers` elements.
#'   Each layer contains type, source_layer, fill/stroke/casing/overlay/
#'   classification/label as applicable, and a `note` where QGIS draws
#'   something the registry does not model.
#'
#' @examples
#' path <- system.file("examples", "mini_project.qgs", package = "gq")
#' reg <- gq_qgs_extract(path)
#'
#' # Shows all layers extracted from the QGIS project
#' names(reg$layers)
#'
#' # Polygon layer — fill and stroke extracted from SimpleFill symbol
#' reg$layers$lakes
#'
#' # Categorized layer — classification field and per-class colors
#' reg$layers$roads$classification
#'
#' # Labels — field, font, size, weight, halo all captured
#' reg$layers$roads$label
#'
#' @export
gq_qgs_extract <- function(path) {
  if (!requireNamespace("xml2", quietly = TRUE)) stop("xml2 is required")

  doc <- xml2::read_xml(path)
  layers <- xml2::xml_find_all(doc, ".//maplayer[@type='vector']")

  result <- list(
    name = tools::file_path_sans_ext(basename(path)),
    version = "0.1.0",
    source = basename(path),
    layers = list()
  )

  for (layer_node in layers) {
    layer_name <- xml2::xml_text(xml2::xml_find_first(layer_node, ".//layername"))
    datasource <- xml2::xml_text(xml2::xml_find_first(layer_node, ".//datasource"))
    geom <- xml2::xml_attr(layer_node, "geometry")

    source_layer <- datasource_layer(datasource)

    geom_type <- switch(tolower(geom %||% ""),
      polygon = "polygon",
      line = "line",
      point = "point",
      "unknown"
    )

    # make a clean key from the layer name
    layer_key <- normalize_layer_name(layer_name)

    renderer <- xml2::xml_find_first(layer_node, ".//renderer-v2")
    if (is.na(renderer)) next

    renderer_type <- xml2::xml_attr(renderer, "type")
    layer_opacity <- layer_opacity_read(layer_node)

    entry <- list(type = geom_type)
    if (!is.na(source_layer)) entry$source_layer <- source_layer

    if (renderer_type == "singleSymbol") {
      entry <- c(entry, parse_single_symbol(renderer, geom_type, layer_opacity))
    } else if (renderer_type == "categorizedSymbol") {
      entry <- c(entry, parse_categorized(renderer, geom_type, layer_opacity))
    } else if (renderer_type == "graduatedSymbol") {
      entry <- c(entry, parse_graduated(renderer, geom_type, layer_opacity))
    } else if (renderer_type == "RuleRenderer") {
      entry$renderer <- "rule_based"
      entry$note <- "Rule-based renderer - manual review needed"
    }

    if (color_data_defined(renderer)) {
      # Worded for every case: QGIS draws the expression's colour wherever it
      # evaluates and the symbol's own where it does not, which includes an
      # expression that fails to parse, as the restoration template's streams
      # layers' does (every `IN ()` list is empty).
      entry <- note_add(entry, paste(
        "colour has an active data-defined expression (fillColor/outlineColor):",
        "QGIS draws its colour instead of these wherever it evaluates"
      ))
    }

    # labels
    labels_enabled <- xml2::xml_attr(layer_node, "labelsEnabled")
    if (identical(labels_enabled, "1")) {
      label_info <- parse_labels(layer_node, geom_type)
      if (length(label_info) > 0) entry$label <- label_info
    }

    result$layers[[layer_key]] <- entry
  }

  result
}


# --- internal helpers --------------------------------------------------------

#' The source table a datasource names
#'
#' A file source names it after `layername=` (`x.gpkg|layername=schema.table`);
#' a PostgreSQL source as `table="schema"."table"`, which is what a `.qlr`
#' written against a database carries (#23).
#' @noRd
datasource_layer <- function(datasource) {
  if (is.na(datasource)) return(NA_character_)
  if (grepl("layername=", datasource, fixed = TRUE)) {
    return(sub(".*layername=([^|]+).*", "\\1", datasource))
  }
  pg <- regmatches(datasource, regexec('table="([^"]+)"\\."([^"]+)"', datasource))[[1]]
  if (length(pg) == 3) return(paste0(pg[2], ".", pg[3]))
  NA_character_
}

#' A layer's own opacity, `<layerOpacity>`, 1 when absent
#' @noRd
layer_opacity_read <- function(layer_node) {
  node <- xml2::xml_find_first(layer_node, "./layerOpacity")
  if (is.na(node)) return(1)
  op <- suppressWarnings(as.numeric(xml2::xml_text(node)))
  if (length(op) != 1 || is.na(op)) 1 else op
}

#' Append a sentence to an entry's `note`
#' @noRd
note_add <- function(x, msg) {
  x$note <- if (is.null(x$note)) msg else paste0(x$note, "; ", msg)
  x
}

#' Does any symbol layer take its colour from an active data-defined property?
#'
#' A colour driven by an expression overrides the renderer's own, so the
#' renderer no longer describes what QGIS draws (#38). Only an active property
#' with an expression or a field counts: QGIS also writes inactive stubs. Only
#' the drawn symbols' enabled top-level layers are read, as [symbol_read()]
#' reads them: a categorized renderer's `<source-symbol>` is a template, not
#' drawn.
#' @noRd
color_data_defined <- function(renderer) {
  props <- xml2::xml_find_all(
    renderer,
    paste0("./symbols/symbol/layer[not(@enabled='0')]/data_defined_properties",
           "//Option[@name='properties']",
           "/Option[@name='fillColor' or @name='outlineColor']")
  )
  dd_val <- function(p, k) {
    v <- xml2::xml_attr(xml2::xml_find_first(p, paste0("./Option[@name='", k, "']")), "value")
    if (is.na(v)) "" else v
  }
  any(vapply(props, function(p) {
    identical(dd_val(p, "active"), "true") &&
      (nzchar(trimws(dd_val(p, "expression"))) || nzchar(trimws(dd_val(p, "field"))))
  }, logical(1)))
}

#' Convert QGIS RGBA string "r,g,b,a" to hex color
#' @noRd
rgba_to_hex <- function(rgba_str) {
  if (is.na(rgba_str) || rgba_str == "") return(NA_character_)
  parts <- as.integer(strsplit(rgba_str, ",")[[1]])
  if (length(parts) < 3) return(NA_character_)
  sprintf("#%02x%02x%02x", parts[1], parts[2], parts[3])
}

#' Extract alpha from QGIS RGBA string (0-1 scale)
#' @noRd
rgba_alpha <- function(rgba_str) {
  parts <- as.integer(strsplit(rgba_str, ",")[[1]])
  if (length(parts) >= 4) parts[4] / 255 else 1
}

#' Get an Option value by name from a symbol layer node
#' @noRd
opt_val <- function(layer_node, name) {
  node <- xml2::xml_find_first(
    layer_node,
    paste0(".//Option[@name='", name, "']")
  )
  if (is.na(node)) return(NA_character_)
  xml2::xml_attr(node, "value")
}

#' A numeric Option value, `NA` when absent or not a number
#' @noRd
opt_num <- function(layer_node, name) {
  suppressWarnings(as.numeric(opt_val(layer_node, name)))
}

#' Extract a dash pattern from a SimpleLine symbol layer
#'
#' QGIS encodes dashes two ways: a named `line_style` (e.g. "dash dot"), or a
#' custom pattern flagged by `use_custom_dash="1"` + `customdash` (e.g. "0.66;2")
#' with `line_style` left "solid". Returns the raw QGIS value — named style or
#' custom pattern — or `NA` for a solid line. The custom-dash flag takes
#' precedence, since QGIS keeps `line_style="solid"` even when a custom pattern
#' is active.
#' @noRd
parse_dash <- function(layer_node) {
  use_custom <- opt_val(layer_node, "use_custom_dash")
  if (!is.na(use_custom) && use_custom == "1") {
    custom <- opt_val(layer_node, "customdash")
    if (!is.na(custom)) return(custom)
  }
  style <- opt_val(layer_node, "line_style")
  if (!is.na(style) && style != "solid") return(style)
  NA_character_
}

#' The stroke a SimpleLine symbol layer draws, `alpha` being the symbol's and
#' the layer's opacity already multiplied together
#' @noRd
line_stroke <- function(sym_layer, alpha = 1) {
  color <- opt_val(sym_layer, "line_color")
  width <- opt_val(sym_layer, "line_width")
  dash <- parse_dash(sym_layer)

  stroke <- list(color = rgba_to_hex(color))
  if (!is.na(width)) stroke$width <- as.numeric(width)
  if (!is.na(dash)) stroke$dash <- dash

  stroke_alpha <- alpha * rgba_alpha(color)
  if (stroke_alpha < 1) stroke$opacity <- round(stroke_alpha, 3)
  stroke
}

#' Railway-style ticks as a wide dashed line
#'
#' A MarkerLine that places a `line` marker at a fixed interval, rotated to the
#' line, draws a tick across it every `interval` mm. The same picture is a line
#' as wide as the tick is long, dashed with the tick's thickness on and the rest
#' of the interval off. Returns that overlay, or `NULL` when the MarkerLine is
#' anything else (other markers, other placements, units other than mm).
#' @noRd
tick_overlay <- function(marker_line, alpha = 1) {
  own <- function(k) {
    v <- xml2::xml_attr(
      xml2::xml_find_first(marker_line, paste0("./Option/Option[@name='", k, "']")),
      "value"
    )
    if (is.na(v)) NA_character_ else v
  }
  placement <- own("placements")
  if (is.na(placement)) placement <- own("placement")
  if (!identical(placement, "Interval") && !identical(placement, "interval")) return(NULL)
  if (!identical(own("rotate"), "1")) return(NULL)
  if (!identical(own("interval_unit"), "MM")) return(NULL)
  interval <- suppressWarnings(as.numeric(own("interval")))

  marks <- xml2::xml_find_all(marker_line, "./symbol/layer")
  if (length(marks) != 1) return(NULL)
  mark <- marks[[1]]
  if (!identical(xml2::xml_attr(mark, "class"), "SimpleMarker")) return(NULL)
  if (!identical(opt_val(mark, "name"), "line")) return(NULL)
  angle <- opt_num(mark, "angle")
  if (is.na(angle) || !angle %in% c(0, 180)) return(NULL)
  if (!identical(opt_val(mark, "size_unit"), "MM")) return(NULL)
  if (!identical(opt_val(mark, "outline_width_unit"), "MM")) return(NULL)
  size <- opt_num(mark, "size")
  tick <- opt_num(mark, "outline_width")
  if (anyNA(c(interval, size, tick)) || tick <= 0 || interval <= tick) return(NULL)

  fmt <- function(x) as.character(round(x, 6))
  color <- opt_val(mark, "outline_color")
  out <- list(
    color = rgba_to_hex(color),
    width = size,
    dash = paste0(fmt(tick), ";", fmt(interval - tick))
  )
  # The ticks' own sub-symbol alpha, the parent symbol's and the layer's
  mark_alpha <- as.numeric(xml2::xml_attr(xml2::xml_find_first(marker_line, "./symbol"), "alpha") %||% "1")
  tick_alpha <- alpha * mark_alpha * rgba_alpha(color)
  if (tick_alpha < 1) out$opacity <- round(tick_alpha, 3)
  out
}

#' Read one QGIS symbol: which of its layers the registry models, and how
#'
#' The one reader every renderer parser calls, so they cannot disagree about
#' which layers count or how opacity composes (#103's review found each rule
#' fixed in one parser and missing from its siblings). It takes the symbol's
#' enabled top-level layers (`.//layer` would also reach a MarkerLine's marker
#' or a pattern fill's line), and multiplies the symbol's `alpha` by the
#' layer's `<layerOpacity>`.
#'
#' The first layer carries the style when it is one the registry models
#' (SimpleFill, SimpleLine, SimpleMarker). Two SimpleLines with the lower one
#' wider are a casing under a core; a SimpleLine under railway-style ticks has
#' an overlay. Every other layer, the first one included, is returned in
#' `unmodelled` for the caller's note.
#' @return `NULL` for a symbol with no enabled layer, else a list: `class`,
#'   `layer` (the first), `core` (the line that carries a line style, the core
#'   when cased), `alpha`, `casing`, `overlay` and `unmodelled`.
#' @noRd
symbol_read <- function(sym, layer_opacity = 1) {
  alpha <- as.numeric(xml2::xml_attr(sym, "alpha") %||% "1") * layer_opacity
  layers <- xml2::xml_find_all(sym, "./layer[not(@enabled='0')]")
  if (length(layers) == 0) return(NULL)
  classes <- xml2::xml_attr(layers, "class")

  out <- list(class = classes[1], layer = layers[[1]], core = layers[[1]], alpha = alpha)
  used <- if (classes[1] %in% c("SimpleFill", "SimpleLine", "SimpleMarker")) 1L else integer()

  if (length(layers) == 2 && all(classes == "SimpleLine")) {
    under <- opt_num(layers[[1]], "line_width")
    over <- opt_num(layers[[2]], "line_width")
    if (!anyNA(c(under, over)) && under > over) {
      casing <- line_stroke(layers[[1]], alpha)
      casing$dash <- NULL
      out$casing <- casing
      out$core <- layers[[2]]
      used <- 1:2
    }
  } else if (length(layers) == 2 && identical(classes, c("SimpleLine", "MarkerLine"))) {
    overlay <- tick_overlay(layers[[2]], alpha)
    if (!is.null(overlay)) {
      out$overlay <- overlay
      used <- 1:2
    }
  }

  # Indices, not classes[-used]: a negative empty index selects nothing.
  out$unmodelled <- classes[setdiff(seq_along(classes), used)]
  out
}

#' The note naming symbol layers the registry does not model
#' @noRd
unmodelled_note <- function(classes, what = "symbol layers") {
  if (length(classes) == 0) return(NULL)
  paste0(what, " not modelled: ", paste(classes, collapse = ", "),
         " (the QML from gq_style_qml() carries them)")
}

#' Parse a singleSymbol renderer
#' @noRd
parse_single_symbol <- function(renderer, geom_type, layer_opacity = 1) {
  sym <- xml2::xml_find_first(renderer, ".//symbol")
  if (is.na(sym)) return(list())
  sr <- symbol_read(sym, layer_opacity)
  if (is.null(sr)) return(list())

  out <- list()
  if (sr$class == "SimpleFill") {
    color <- opt_val(sr$layer, "color")
    outline_color <- opt_val(sr$layer, "outline_color")
    outline_width <- opt_val(sr$layer, "outline_width")
    outline_style <- opt_val(sr$layer, "outline_style")

    fill <- list(color = rgba_to_hex(color))
    fill_alpha <- sr$alpha * rgba_alpha(color)
    if (fill_alpha < 1) fill$opacity <- round(fill_alpha, 3)
    out$fill <- fill

    # The symbol's and the layer's opacity reach the outline as well as the fill
    stroke <- list(color = rgba_to_hex(outline_color))
    if (!is.na(outline_width)) stroke$width <- as.numeric(outline_width)
    if (!is.na(outline_style) && outline_style == "no") {
      stroke$style <- "none"
    } else if (!is.na(outline_color)) {
      outline_alpha <- sr$alpha * rgba_alpha(outline_color)
      if (outline_alpha < 1) stroke$opacity <- round(outline_alpha, 3)
    }
    out$stroke <- stroke

  } else if (sr$class == "SimpleLine") {
    out$stroke <- line_stroke(sr$core, sr$alpha)

  } else if (sr$class == "SimpleMarker") {
    color <- opt_val(sr$layer, "color")
    size <- opt_val(sr$layer, "size")
    shape <- opt_val(sr$layer, "name")

    mark <- list(color = rgba_to_hex(color))
    if (!is.na(shape)) mark$shape <- shape
    if (!is.na(size)) mark$radius <- as.numeric(size)
    out$mark <- mark
  }

  if (!is.null(sr$casing)) out$casing <- sr$casing
  if (!is.null(sr$overlay)) out$overlay <- sr$overlay
  out$note <- unmodelled_note(sr$unmodelled)
  out
}

#' A class's style from its symbol, for the categorized and graduated parsers
#'
#' Returns the class fields and, as attribute `unmodelled`, the symbol layers it
#' could not model. A class has no `overlay` field, so a class's overlay is one
#' of those.
#' @noRd
class_style <- function(sym, layer_opacity) {
  sr <- symbol_read(sym, layer_opacity)
  if (is.null(sr)) return(NULL)
  cls <- list()

  if (sr$class == "SimpleFill") {
    color <- opt_val(sr$layer, "color")
    cls$color <- rgba_to_hex(color)
    fill_alpha <- sr$alpha * rgba_alpha(color)
    if (fill_alpha < 1) cls$opacity <- round(fill_alpha, 3)
    outline_w <- opt_val(sr$layer, "outline_width")
    if (!is.na(outline_w)) cls$outline_width <- as.numeric(outline_w)
  } else if (sr$class == "SimpleLine") {
    s <- line_stroke(sr$core, sr$alpha)
    cls$color <- s$color
    cls$width <- s$width
    cls$dash <- s$dash
    cls$opacity <- s$opacity
    if (!is.null(sr$casing)) {
      cls$casing_color <- sr$casing$color
      cls$casing_width <- sr$casing$width
    }
  } else if (sr$class == "SimpleMarker") {
    color <- opt_val(sr$layer, "color")
    size <- opt_val(sr$layer, "size")
    shape <- opt_val(sr$layer, "name")
    cls$color <- rgba_to_hex(color)
    if (!is.na(shape)) cls$shape <- shape
    if (!is.na(size)) cls$radius <- as.numeric(size)
  }

  unmodelled <- sr$unmodelled
  if (!is.null(sr$overlay)) unmodelled <- c(unmodelled, "MarkerLine")
  attr(cls, "unmodelled") <- unmodelled
  cls
}

#' The layer note for class symbol layers no class could model
#' @noRd
class_note <- function(unmodelled) {
  if (length(unmodelled) == 0) return(list())
  list(note = unmodelled_note(sort(unique(unmodelled), method = "radix"),
                              "class symbol layers"))
}

#' Find a renderer's symbol by name
#' @noRd
symbol_named <- function(symbols, name) {
  for (s in symbols) if (identical(xml2::xml_attr(s, "name"), name)) return(s)
  NULL
}

#' Parse a categorizedSymbol renderer
#' @noRd
parse_categorized <- function(renderer, geom_type, layer_opacity = 1) {
  attr_field <- xml2::xml_attr(renderer, "attr")
  categories <- xml2::xml_find_all(renderer, ".//categories/category")
  symbols <- xml2::xml_find_all(renderer, ".//symbols/symbol")

  classes <- list()
  unmodelled <- character()
  for (cat in categories) {
    cat_value <- xml2::xml_attr(cat, "value")
    cat_label <- xml2::xml_attr(cat, "label")

    sym <- symbol_named(symbols, xml2::xml_attr(cat, "symbol"))
    if (is.null(sym)) next
    cls <- class_style(sym, layer_opacity)
    if (is.null(cls)) next
    unmodelled <- c(unmodelled, attr(cls, "unmodelled"))
    attr(cls, "unmodelled") <- NULL

    # Grouped categories: QGIS groups multiple values under one symbol using
    # <val> children instead of a single value attribute (#25)
    val_nodes <- xml2::xml_find_all(cat, ".//val")
    if (length(val_nodes) > 0) {
      if (!is.na(cat_label)) cls$label <- cat_label
      for (vn in val_nodes) {
        vval <- xml2::xml_attr(vn, "value")
        if (!is.na(vval) && vval != "") classes[[vval]] <- cls
      }
    } else {
      if (!is.na(cat_label) && !is.na(cat_value) && cat_label != cat_value) {
        cls$label <- cat_label
      }
      key <- if (is.na(cat_value) || cat_value == "") "__empty__" else cat_value
      classes[[key]] <- cls
    }
  }

  c(list(classification = list(field = attr_field, classes = classes)),
    class_note(unmodelled))
}

#' Parse a graduatedSymbol renderer
#' @noRd
parse_graduated <- function(renderer, geom_type, layer_opacity = 1) {
  attr_field <- xml2::xml_attr(renderer, "attr")
  ranges <- xml2::xml_find_all(renderer, ".//ranges/range")
  symbols <- xml2::xml_find_all(renderer, ".//symbols/symbol")

  classes <- list()
  unmodelled <- character()
  for (r in ranges) {
    lower <- xml2::xml_attr(r, "lower")
    upper <- xml2::xml_attr(r, "upper")
    label <- xml2::xml_attr(r, "label")

    sym <- symbol_named(symbols, xml2::xml_attr(r, "symbol"))
    if (is.null(sym)) next
    style <- class_style(sym, layer_opacity)
    if (is.null(style)) next
    unmodelled <- c(unmodelled, attr(style, "unmodelled"))
    attr(style, "unmodelled") <- NULL

    cls <- c(list(lower = as.numeric(lower), upper = as.numeric(upper)), style)
    if (!is.na(label)) cls$label <- label
    classes[[paste0(lower, "_", upper)]] <- cls
  }

  c(list(classification = list(field = attr_field, type = "graduated", classes = classes)),
    class_note(unmodelled))
}

#' QGIS label placement modes, by the integer QGIS writes
#' @noRd
label_placements <- c(
  "0" = "around_point", "1" = "over_point", "2" = "line", "3" = "curved",
  "4" = "horizontal", "5" = "free", "6" = "ordered", "7" = "perimeter_curved",
  "8" = "outside_polygons"
)

#' `"bold"` for a heavy enough `fontWeight`, else `NULL`
#'
#' QGIS writes Qt's weight, and Qt changed scales: Qt5 runs 0-99 (50 normal,
#' 63 demibold, 75 bold, 87 black), Qt6 1-1000 (400, 600, 700, 900). Demibold
#' and heavier read as bold on either. The old `fontBold` attribute is never
#' written by current QGIS (#7).
#' @noRd
label_weight <- function(x) {
  w <- suppressWarnings(as.numeric(x))
  if (length(w) != 1 || is.na(w)) return(NULL)
  bold <- if (w <= 99) w >= 63 else w >= 600
  if (bold) "bold" else NULL
}

#' Parse label settings from a maplayer node
#'
#' Rule-based labelling keeps one `<settings>` per rule; the first active
#' rule's is taken, and `note` says how many active rules there were.
#' @noRd
parse_labels <- function(layer_node, geom_type = "unknown") {
  labeling <- xml2::xml_find_first(layer_node, "./labeling")
  if (is.na(labeling)) return(list())

  # A rule switched off (`active="0"`) is not drawn, so it is neither taken nor
  # counted, as a disabled symbol layer is skipped.
  settings <- xml2::xml_find_all(labeling, ".//settings[not(ancestor::rule[@active='0'])]")
  if (length(settings) == 0) return(list())
  first <- settings[[1]]

  font_node <- xml2::xml_find_first(first, "./text-style")
  if (is.na(font_node)) return(list())

  out <- list()

  # QGIS writes the label source on <text-style>, flagged by isExpression (#6).
  # A bare or double-quoted column name marked as an expression is a column.
  source <- trimws(xml2::xml_attr(font_node, "fieldName"))
  if (!is.na(source) && nzchar(source)) {
    bare <- "^\"?([A-Za-z_][A-Za-z0-9_]*)\"?$"
    if (!identical(xml2::xml_attr(font_node, "isExpression"), "1")) {
      out$field <- source
    } else if (grepl(bare, source)) {
      out$field <- sub(bare, "\\1", source)
    } else {
      out$expression <- source
    }
  }

  font_family <- xml2::xml_attr(font_node, "fontFamily")
  font_size <- xml2::xml_attr(font_node, "fontSize")
  font_italic <- xml2::xml_attr(font_node, "fontItalic")
  text_color <- xml2::xml_attr(font_node, "textColor")

  if (!is.na(font_family)) out$font <- font_family
  if (!is.na(font_size)) out$size <- as.numeric(font_size)
  if (identical(font_italic, "1")) out$style <- "italic"
  weight <- label_weight(xml2::xml_attr(font_node, "fontWeight"))
  if (is.null(weight) && identical(xml2::xml_attr(font_node, "fontBold"), "1")) weight <- "bold"
  if (!is.null(weight)) out$weight <- weight
  if (!is.na(text_color)) out$color <- rgba_to_hex(text_color)
  text_opacity <- suppressWarnings(as.numeric(xml2::xml_attr(font_node, "textOpacity")))
  if (!is.na(text_opacity) && text_opacity < 1) out$opacity <- round(text_opacity, 3)

  # buffer/halo
  # <text-buffer> sits inside <text-style>, not beside it
  buffer_node <- xml2::xml_find_first(first, ".//text-buffer")
  if (!is.na(buffer_node)) {
    buf_draw <- xml2::xml_attr(buffer_node, "bufferDraw")
    if (identical(buf_draw, "1")) {
      buf_size <- xml2::xml_attr(buffer_node, "bufferSize")
      buf_color <- xml2::xml_attr(buffer_node, "bufferColor")
      halo <- list()
      if (!is.na(buf_color)) halo$color <- rgba_to_hex(buf_color)
      if (!is.na(buf_size)) halo$width <- as.numeric(buf_size)
      if (length(halo) > 0) out$halo <- halo
    }
  }

  # placement, and the data-prep hints tmap and MapLibre cannot act on (#7)
  placement <- xml2::xml_attr(xml2::xml_find_first(first, "./placement"), "placement")
  if (!is.na(placement) && placement %in% names(label_placements)) {
    out$placement <- unname(label_placements[placement])
    # QGIS's Line mode on a polygon follows its perimeter
    if (out$placement == "line" && geom_type == "polygon") out$placement <- "perimeter"
  }
  rendering <- xml2::xml_find_first(first, "./rendering")
  if (identical(xml2::xml_attr(rendering, "mergeLines"), "1")) out$merge_lines <- TRUE
  min_size <- suppressWarnings(as.numeric(xml2::xml_attr(rendering, "minFeatureSize")))
  if (!is.na(min_size) && min_size > 0) out$min_feature_size <- min_size

  if (length(settings) > 1) {
    out$note <- paste0("rule-based labelling: ", length(settings),
                       " rules, the first taken")
  }

  out
}

# base R null coalesce
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a
