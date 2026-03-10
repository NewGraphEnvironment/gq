#' Extract layer styles from a QGIS project file
#'
#' Parses a .qgs XML file and extracts symbology (fill, stroke, classification,
#' labels) for all vector layers into a list suitable for writing to registry.json.
#'
#' @param path Path to a .qgs file.
#' @return A list with `name`, `version`, `source`, and `layers` elements.
#'   Each layer contains type, source_layer, fill/stroke/classification/label as applicable.
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
#' # Labels — font, size, weight, halo all captured
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

    # extract source layer name from datasource string
    source_layer <- sub(".*layername=([^|]+).*", "\\1", datasource)
    if (source_layer == datasource) source_layer <- NA_character_

    geom_type <- switch(tolower(geom %||% ""),
      polygon = "polygon",
      line = "line",
      point = "point",
      "unknown"
    )

    # make a clean key from the layer name
    layer_key <- tolower(gsub("[^a-zA-Z0-9]+", "_", trimws(layer_name)))
    layer_key <- sub("^_|_$", "", layer_key)

    renderer <- xml2::xml_find_first(layer_node, ".//renderer-v2")
    if (is.na(renderer)) next

    renderer_type <- xml2::xml_attr(renderer, "type")

    entry <- list(type = geom_type)
    if (!is.na(source_layer)) entry$source_layer <- source_layer

    if (renderer_type == "singleSymbol") {
      entry <- c(entry, parse_single_symbol(renderer, geom_type))
    } else if (renderer_type == "categorizedSymbol") {
      entry <- c(entry, parse_categorized(renderer, geom_type))
    } else if (renderer_type == "graduatedSymbol") {
      entry <- c(entry, parse_graduated(renderer, geom_type))
    } else if (renderer_type == "RuleRenderer") {
      entry$renderer <- "rule_based"
      entry$note <- "Rule-based renderer — manual review needed"
    }

    # labels
    labels_enabled <- xml2::xml_attr(layer_node, "labelsEnabled")
    if (identical(labels_enabled, "1")) {
      label_info <- parse_labels(layer_node)
      if (length(label_info) > 0) entry$label <- label_info
    }

    result$layers[[layer_key]] <- entry
  }

  result
}


# --- internal helpers --------------------------------------------------------

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

#' Parse a singleSymbol renderer
#' @noRd
parse_single_symbol <- function(renderer, geom_type) {
  sym <- xml2::xml_find_first(renderer, ".//symbol")
  if (is.na(sym)) return(list())

  sym_alpha <- as.numeric(xml2::xml_attr(sym, "alpha") %||% "1")
  sym_layer <- xml2::xml_find_first(sym, ".//layer")
  if (is.na(sym_layer)) return(list())

  sym_class <- xml2::xml_attr(sym_layer, "class")
  out <- list()

  if (sym_class == "SimpleFill") {
    color <- opt_val(sym_layer, "color")
    outline_color <- opt_val(sym_layer, "outline_color")
    outline_width <- opt_val(sym_layer, "outline_width")
    outline_style <- opt_val(sym_layer, "outline_style")

    fill <- list(color = rgba_to_hex(color))
    fill_alpha <- sym_alpha * rgba_alpha(color)
    if (fill_alpha < 1) fill$opacity <- round(fill_alpha, 3)
    out$fill <- fill

    stroke <- list(color = rgba_to_hex(outline_color))
    if (!is.na(outline_width)) stroke$width <- as.numeric(outline_width)
    if (!is.na(outline_style) && outline_style == "no") stroke$style <- "none"
    out$stroke <- stroke

  } else if (sym_class == "SimpleLine") {
    color <- opt_val(sym_layer, "line_color")
    width <- opt_val(sym_layer, "line_width")
    style <- opt_val(sym_layer, "line_style")
    dash <- opt_val(sym_layer, "customdash")

    stroke <- list(color = rgba_to_hex(color))
    if (!is.na(width)) stroke$width <- as.numeric(width)
    if (!is.na(style) && style != "solid") stroke$dash <- style
    if (!is.na(dash) && !is.na(style) && style == "custom_dash") stroke$dash <- dash

    stroke_alpha <- sym_alpha * rgba_alpha(color)
    if (stroke_alpha < 1) stroke$opacity <- round(stroke_alpha, 3)
    out$stroke <- stroke

  } else if (sym_class == "SimpleMarker") {
    color <- opt_val(sym_layer, "color")
    size <- opt_val(sym_layer, "size")
    shape <- opt_val(sym_layer, "name")

    mark <- list(color = rgba_to_hex(color))
    if (!is.na(shape)) mark$shape <- shape
    if (!is.na(size)) mark$radius <- as.numeric(size)
    out$mark <- mark
  }

  # check for additional symbol layers (overlay / casing)
  all_sym_layers <- xml2::xml_find_all(sym, ".//layer")
  if (length(all_sym_layers) > 1) {
    out$note <- paste0(length(all_sym_layers), " symbol layers — overlay/casing may apply")
  }

  out
}

#' Parse a categorizedSymbol renderer
#' @noRd
parse_categorized <- function(renderer, geom_type) {
  attr_field <- xml2::xml_attr(renderer, "attr")
  categories <- xml2::xml_find_all(renderer, ".//categories/category")
  symbols <- xml2::xml_find_all(renderer, ".//symbols/symbol")

  classes <- list()
  for (cat in categories) {
    cat_value <- xml2::xml_attr(cat, "value")
    cat_label <- xml2::xml_attr(cat, "label")
    cat_symbol_name <- xml2::xml_attr(cat, "symbol")

    # find the matching symbol
    sym <- NULL
    for (s in symbols) {
      if (xml2::xml_attr(s, "name") == cat_symbol_name) {
        sym <- s
        break
      }
    }
    if (is.null(sym)) next

    sym_alpha <- as.numeric(xml2::xml_attr(sym, "alpha") %||% "1")
    sym_layer <- xml2::xml_find_first(sym, ".//layer")
    if (is.na(sym_layer)) next

    sym_class <- xml2::xml_attr(sym_layer, "class")
    cls <- list()

    if (sym_class == "SimpleFill") {
      color <- opt_val(sym_layer, "color")
      cls$color <- rgba_to_hex(color)
      fill_alpha <- sym_alpha * rgba_alpha(color)
      if (fill_alpha < 1) cls$opacity <- round(fill_alpha, 3)
      outline_w <- opt_val(sym_layer, "outline_width")
      if (!is.na(outline_w)) cls$outline_width <- as.numeric(outline_w)
    } else if (sym_class == "SimpleLine") {
      color <- opt_val(sym_layer, "line_color")
      width <- opt_val(sym_layer, "line_width")
      cls$color <- rgba_to_hex(color)
      if (!is.na(width)) cls$width <- as.numeric(width)
      line_alpha <- sym_alpha * rgba_alpha(color)
      if (line_alpha < 1) cls$opacity <- round(line_alpha, 3)
    } else if (sym_class == "SimpleMarker") {
      color <- opt_val(sym_layer, "color")
      size <- opt_val(sym_layer, "size")
      shape <- opt_val(sym_layer, "name")
      cls$color <- rgba_to_hex(color)
      if (!is.na(shape)) cls$shape <- shape
      if (!is.na(size)) cls$radius <- as.numeric(size)
    }

    # check for multi-layer symbols (casing)
    all_sym_layers <- xml2::xml_find_all(sym, ".//layer")
    if (length(all_sym_layers) > 1) {
      # try to get casing from first layer, core from second
      casing_layer <- all_sym_layers[[1]]
      core_layer <- all_sym_layers[[2]]
      casing_color <- opt_val(casing_layer, "line_color")
      casing_width <- opt_val(casing_layer, "line_width")
      core_color <- opt_val(core_layer, "line_color")
      core_width <- opt_val(core_layer, "line_width")
      if (!is.na(casing_color) && !is.na(core_color)) {
        cls$casing_color <- rgba_to_hex(casing_color)
        if (!is.na(casing_width)) cls$casing_width <- as.numeric(casing_width)
        cls$color <- rgba_to_hex(core_color)
        if (!is.na(core_width)) cls$width <- as.numeric(core_width)
      }
    }

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

  list(classification = list(field = attr_field, classes = classes))
}

#' Parse a graduatedSymbol renderer
#' @noRd
parse_graduated <- function(renderer, geom_type) {
  attr_field <- xml2::xml_attr(renderer, "attr")
  ranges <- xml2::xml_find_all(renderer, ".//ranges/range")
  symbols <- xml2::xml_find_all(renderer, ".//symbols/symbol")

  classes <- list()
  for (r in ranges) {
    lower <- xml2::xml_attr(r, "lower")
    upper <- xml2::xml_attr(r, "upper")
    label <- xml2::xml_attr(r, "label")
    sym_name <- xml2::xml_attr(r, "symbol")

    sym <- NULL
    for (s in symbols) {
      if (xml2::xml_attr(s, "name") == sym_name) {
        sym <- s
        break
      }
    }
    if (is.null(sym)) next

    sym_layer <- xml2::xml_find_first(sym, ".//layer")
    if (is.na(sym_layer)) next

    sym_class <- xml2::xml_attr(sym_layer, "class")
    cls <- list(lower = as.numeric(lower), upper = as.numeric(upper))

    if (sym_class == "SimpleFill") {
      cls$color <- rgba_to_hex(opt_val(sym_layer, "color"))
    } else if (sym_class == "SimpleLine") {
      cls$color <- rgba_to_hex(opt_val(sym_layer, "line_color"))
      w <- opt_val(sym_layer, "line_width")
      if (!is.na(w)) cls$width <- as.numeric(w)
    } else if (sym_class == "SimpleMarker") {
      cls$color <- rgba_to_hex(opt_val(sym_layer, "color"))
    }

    if (!is.na(label)) cls$label <- label
    classes[[paste0(lower, "_", upper)]] <- cls
  }

  list(classification = list(field = attr_field, type = "graduated", classes = classes))
}

#' Parse label settings from a maplayer node
#' @noRd
parse_labels <- function(layer_node) {
  labeling <- xml2::xml_find_first(layer_node, ".//labeling")
  if (is.na(labeling)) return(list())

  settings <- xml2::xml_find_first(labeling, ".//settings")
  if (is.na(settings)) return(list())

  # field name
  field_node <- xml2::xml_find_first(settings, ".//text-format/Option[@name='fieldName']")
  field <- if (!is.na(field_node)) xml2::xml_attr(field_node, "value") else NA_character_

  # font
  font_node <- xml2::xml_find_first(settings, ".//text-style")
  if (is.na(font_node)) return(list())

  out <- list()
  if (!is.na(field)) out$field <- field

  font_family <- xml2::xml_attr(font_node, "fontFamily")
  font_size <- xml2::xml_attr(font_node, "fontSize")
  font_italic <- xml2::xml_attr(font_node, "fontItalic")
  font_bold <- xml2::xml_attr(font_node, "fontBold")
  text_color <- xml2::xml_attr(font_node, "textColor")

  if (!is.na(font_family)) out$font <- font_family
  if (!is.na(font_size)) out$size <- as.numeric(font_size)
  if (identical(font_italic, "1")) out$style <- "italic"
  if (identical(font_bold, "1")) out$weight <- "bold"
  if (!is.na(text_color)) out$color <- rgba_to_hex(text_color)

  # buffer/halo
  buffer_node <- xml2::xml_find_first(settings, ".//text-buffer")
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

  out
}

# base R null coalesce
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a
