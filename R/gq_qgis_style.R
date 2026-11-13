#' Translate a registry layer style to a QGIS QML document
#'
#' Builds the QGIS-native form of a registry layer's symbology, so a layer
#' defined only in a custom registry CSV ([gq_reg_custom()]) can be handed to
#' QGIS coloured as [gq_tmap_style()] and [gq_mapgl_style()] draw it. A
#' classified line or polygon becomes a categorized renderer with one category
#' per class; an unclassified one becomes a single-symbol renderer.
#'
#' For a layer gq ships a QML for, prefer [gq_style_qml()]: that file is what
#' QGIS itself wrote, and carries what the registry does not model (labels,
#' multi-layer symbols, casing, scale-dependent rendering). This function writes
#' only what the registry holds.
#'
#' What each registry property becomes:
#'
#' * class value and label: a `<category>`'s `value` and `label`;
#' * colour: QGIS's `r,g,b,a` form, from hex or an R colour name;
#' * line width and polygon outline width: millimetres, as the registry holds
#'   them (QGIS's default of 0.26 mm where the registry gives none);
#' * line dash: a named QGIS `line_style` (`dash`, `dot`, `dash dot`, ...) or,
#'   for a pattern such as `"4;2"`, a custom dash;
#' * line opacity: the symbol's `alpha`; polygon fill and outline opacity: the
#'   alpha of each colour (to the nearest 1/255), so the two can differ as the
#'   registry allows;
#' * a polygon class's outline: its own `outline_color` and `outline_width`
#'   when the registry has them, else the layer's `stroke`, else no outline.
#'
#' Not written: labels, a line's `overlay` (a warning says so), and point and
#' raster layers, which error. An unclassified layer the registry gives no fill
#' or stroke colour (one whose QGIS symbol it could not model) errors too.
#'
#' @inheritParams gq_style
#' @param path Optional file path. When given, the QML is also written there
#'   (UTF-8), and returned invisibly.
#'
#' @return A length-one character string holding the QML document. Put it in a
#'   `.qml` file beside a layer, or into a GeoPackage's `layer_styles` table
#'   with [gq_gpkg_style_write()].
#'
#' @seealso [gq_gpkg_style_write()] to store it in a GeoPackage,
#'   [gq_style_qml()] for the QML files gq ships.
#'
#' @examples
#' reg <- gq_reg_custom(system.file("registry", "reg_custom.csv", package = "gq"))
#'
#' # a classified line: one category per class
#' qml <- gq_qgis_style(reg, "habitat_rule_comparison")
#' doc <- xml2::read_xml(qml)
#' cats <- xml2::xml_find_all(doc, ".//categories/category")
#' data.frame(
#'   value = xml2::xml_attr(cats, "value"),
#'   label = xml2::xml_attr(cats, "label")
#' )
#' # each class's colour, in QGIS's r,g,b,a form
#' xml2::xml_attr(
#'   xml2::xml_find_all(doc, ".//symbols/symbol//Option[@name='line_color']"),
#'   "value"
#' )
#'
#' # an unclassified polygon: a single symbol
#' xml2::xml_attr(
#'   xml2::xml_find_first(xml2::read_xml(gq_qgis_style(reg, "rivers_poly")),
#'                        ".//renderer-v2"),
#'   "type"
#' )
#'
#' # write it beside a layer
#' out <- tempfile(fileext = ".qml")
#' gq_qgis_style(reg, "bec_zone", path = out)
#' file.exists(out)
#'
#' @export
gq_qgis_style <- function(layer_or_reg, name = NULL, field = NULL, path = NULL) {
  layer <- resolve_layer(layer_or_reg, name)
  sty <- gq_style(layer, field = field)
  what <- name %||% "layer"

  if (!sty$type %in% c("line", "polygon")) {
    stop("gq_qgis_style() writes line and polygon layers; '", what, "' is a ",
         sty$type, " layer. For a layer gq ships, use gq_style_qml().",
         call. = FALSE)
  }
  if (!is.null(layer$overlay)) {
    warning("'", what, "': the registry's overlay is not written to the QML; ",
            "only the base line is", call. = FALSE)
  }

  doc <- xml2::xml_new_root("qgis", styleCategories = "Symbology",
                            version = qml_version)
  if (is.null(sty$classification)) {
    qml_single(doc, sty, what)
  } else {
    qml_categorized(doc, sty, layer, what)
  }
  xml2::xml_add_child(doc, "layerGeometryType",
                      if (identical(sty$type, "line")) "1" else "2")

  qml <- as.character(doc)
  if (!is.null(path)) {
    writeLines(enc2utf8(qml), path, sep = "", useBytes = TRUE)
    return(invisible(qml))
  }
  qml
}


# --- internal helpers --------------------------------------------------------

#' The QGIS version the generated QML declares
#'
#' QGIS reads a style from an older version and upgrades it only for versions
#' far older than this one, so an LTR both 3.x and 4.x read is the safe claim.
#' @noRd
qml_version <- "3.40.0-Bratislava"

#' QGIS's default line and outline width, mm
#' @noRd
qml_width_default <- 0.26

#' A colour in QGIS's `r,g,b,a` form, with an opacity folded into the alpha
#' @noRd
qml_color <- function(x, opacity = NA_real_, what = "colour") {
  if (is.null(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    stop(what, " has no colour", call. = FALSE)
  }
  m <- tryCatch(grDevices::col2rgb(x, alpha = TRUE), error = function(e) {
    stop(what, ": '", x, "' is not a colour", call. = FALSE)
  })
  a <- m[4, 1]
  if (!is.na(opacity)) a <- round(a * opacity)
  paste(m[1, 1], m[2, 1], m[3, 1], a, sep = ",")
}

#' A number as QGIS writes it in an Option value
#' @noRd
qml_num <- function(x) format(x, scientific = FALSE, trim = TRUE, digits = 15)

#' Opacity, reading NA and NULL as opaque
#' @noRd
qml_opacity <- function(x) {
  if (is.null(x) || length(x) == 0L || is.na(x)) 1 else as.numeric(x)
}

#' The dash Options of a SimpleLine, from a registry dash value
#'
#' The inverse of `parse_dash()` in gq_qgs_extract.R: a named style is
#' `line_style`, a pattern is `use_custom_dash = 1` with `line_style` left solid,
#' which is how QGIS stores it.
#' @noRd
qml_dash <- function(dash, what) {
  dash <- if (is.null(dash) || length(dash) == 0L) NA_character_ else dash
  dash <- csv_dash(dash, what)
  if (is.na(dash) || dash %in% c("solid", "no", "dash", "dot", "dash dot",
                                 "dash dot dot")) {
    style <- if (is.na(dash)) "solid" else dash
    return(c(line_style = style, use_custom_dash = "0", customdash = "5;2"))
  }
  c(line_style = "solid", use_custom_dash = "1",
    customdash = gsub(" ", ";", dash, fixed = TRUE))
}

#' Options of a SimpleLine symbol layer, in the full set QGIS writes
#' @noRd
qml_line_opts <- function(color, width, dash, what) {
  c(
    align_dash_pattern = "0",
    capstyle = "square",
    customdash_map_unit_scale = "3x:0,0,0,0,0,0",
    customdash_unit = "MM",
    dash_pattern_offset = "0",
    dash_pattern_offset_map_unit_scale = "3x:0,0,0,0,0,0",
    dash_pattern_offset_unit = "MM",
    draw_inside_polygon = "0",
    joinstyle = "bevel",
    line_color = color,
    line_width = qml_num(if (is.na(width)) qml_width_default else width),
    line_width_unit = "MM",
    offset = "0",
    offset_map_unit_scale = "3x:0,0,0,0,0,0",
    offset_unit = "MM",
    ring_filter = "0",
    trim_distance_end = "0",
    trim_distance_end_map_unit_scale = "3x:0,0,0,0,0,0",
    trim_distance_end_unit = "MM",
    trim_distance_start = "0",
    trim_distance_start_map_unit_scale = "3x:0,0,0,0,0,0",
    trim_distance_start_unit = "MM",
    tweak_dash_pattern_on_corners = "0",
    width_map_unit_scale = "3x:0,0,0,0,0,0",
    qml_dash(dash, what)
  )
}

#' Options of a SimpleFill symbol layer
#'
#' `outline` is NULL for no outline, else a list of color (QGIS form), width
#' and style.
#' @noRd
qml_fill_opts <- function(color, outline) {
  c(
    border_width_map_unit_scale = "3x:0,0,0,0,0,0",
    color = color %||% "0,0,0,0",
    joinstyle = "bevel",
    offset = "0,0",
    offset_map_unit_scale = "3x:0,0,0,0,0,0",
    offset_unit = "MM",
    outline_color = if (is.null(outline)) "35,35,35,255" else outline$color,
    outline_style = if (is.null(outline)) "no" else outline$style,
    outline_width = qml_num(if (is.null(outline)) qml_width_default
                            else outline$width),
    outline_width_unit = "MM",
    style = if (is.null(color)) "no" else "solid"
  )
}

#' QGIS's empty data-defined property collection
#' @noRd
qml_add_ddp <- function(node) {
  ddp <- xml2::xml_add_child(node, "data_defined_properties")
  map <- xml2::xml_add_child(ddp, "Option", type = "Map")
  xml2::xml_add_child(map, "Option", name = "name", type = "QString", value = "")
  xml2::xml_add_child(map, "Option", name = "properties")
  xml2::xml_add_child(map, "Option", name = "type", type = "QString",
                      value = "collection")
  invisible(node)
}

#' Add one `<symbol>` with a single symbol layer to `parent`
#'
#' Options are written sorted by name, as QGIS writes them.
#' @noRd
qml_add_symbol <- function(parent, sym_name, type, alpha, layer_class, opts) {
  sym <- xml2::xml_add_child(
    parent, "symbol",
    alpha = qml_num(alpha), clip_to_extent = "1", force_rhr = "0",
    frame_rate = "10", is_animated = "0", name = sym_name, type = type
  )
  qml_add_ddp(sym)
  lyr <- xml2::xml_add_child(sym, "layer", class = layer_class, enabled = "1",
                             locked = "0", pass = "0")
  map <- xml2::xml_add_child(lyr, "Option", type = "Map")
  for (k in sort(names(opts), method = "radix")) {
    xml2::xml_add_child(map, "Option", name = k, type = "QString",
                        value = opts[[k]])
  }
  qml_add_ddp(lyr)
  invisible(sym)
}

#' The polygon outline a class or a simple layer draws, or NULL for none
#' @noRd
qml_outline <- function(color, width, opacity, style, dash, what) {
  if (identical(style, "none") || is.null(color) || is.na(color)) return(NULL)
  dash <- if (is.null(dash) || length(dash) == 0L) NA_character_ else dash
  dash <- csv_dash(dash, what)
  # A SimpleFill outline takes a named style only; a custom pattern draws as
  # QGIS's plain dash rather than solid, so the outline still reads as dashed.
  named <- c("solid", "no", "dash", "dot", "dash dot", "dash dot dot")
  out_style <- if (is.na(dash)) "solid" else if (dash %in% named) dash else "dash"
  list(
    color = qml_color(color, qml_opacity(opacity), what),
    width = if (is.null(width) || is.na(width)) qml_width_default else width,
    style = out_style
  )
}

#' Write a singleSymbol renderer into `doc`
#' @noRd
qml_single <- function(doc, sty, what) {
  r <- xml2::xml_add_child(doc, "renderer-v2", enableorderby = "0",
                           forceraster = "0", referencescale = "-1",
                           symbollevels = "0", type = "singleSymbol")
  syms <- xml2::xml_add_child(r, "symbols")

  if (identical(sty$type, "line")) {
    s <- sty$stroke
    if (is.null(s$color)) stop("'", what, "' has no stroke colour", call. = FALSE)
    opts <- qml_line_opts(qml_color(s$color, what = what),
                          s$width %||% NA_real_, s$dash, what)
    qml_add_symbol(syms, "0", "line", qml_opacity(s$opacity), "SimpleLine", opts)
  } else {
    f <- sty$fill
    s <- sty$stroke
    if (is.null(f$color) && is.null(s$color)) {
      stop("'", what, "' has neither a fill nor a stroke colour", call. = FALSE)
    }
    fill <- if (is.null(f$color)) NULL else
      qml_color(f$color, qml_opacity(f$opacity), what)
    outline <- qml_outline(s$color, s$width, s$opacity, s$style, s$dash, what)
    qml_add_symbol(syms, "0", "fill", 1, "SimpleFill",
                   qml_fill_opts(fill, outline))
  }
  xml2::xml_add_child(r, "rotation")
  xml2::xml_add_child(r, "sizescale")
  invisible(doc)
}

#' Write a categorizedSymbol renderer into `doc`
#'
#' Categories come from `gq_style()`, which has already dropped the `__empty__`
#' class and filled missing labels; a polygon's per-class outline is read from
#' the raw layer, because `gq_style()` does not carry it.
#' @noRd
qml_categorized <- function(doc, sty, layer, what) {
  cls <- sty$classification
  keys <- names(cls$values)
  if (length(keys) == 0L) stop("'", what, "' has no classes", call. = FALSE)
  is_line <- identical(sty$type, "line")
  raw <- layer$classification$classes

  r <- xml2::xml_add_child(doc, "renderer-v2", attr = cls$field,
                           enableorderby = "0", forceraster = "0",
                           referencescale = "-1", symbollevels = "0",
                           type = "categorizedSymbol")
  cats <- xml2::xml_add_child(r, "categories")
  syms <- xml2::xml_add_child(r, "symbols")

  first <- NULL
  for (i in seq_along(keys)) {
    k <- keys[[i]]
    sym_name <- as.character(i - 1L)
    where <- paste0("'", what, "' class '", k, "'")
    xml2::xml_add_child(cats, "category", label = unname(cls$labels[[k]]),
                        render = "true", symbol = sym_name, type = "string",
                        value = k)
    opacity <- qml_opacity(cls$opacities[k])
    if (is_line) {
      dash <- if (is.null(cls$dashes)) NA_character_ else unname(cls$dashes[[k]])
      width <- if (is.null(cls$widths)) NA_real_ else unname(cls$widths[[k]])
      args <- list("line", opacity, "SimpleLine",
                   qml_line_opts(qml_color(unname(cls$values[[k]]), what = where),
                                 width, dash, where))
    } else {
      rc <- raw[[k]]
      s <- layer$stroke
      outline <- qml_outline(
        rc$outline_color %||% s$color,
        rc$outline_width %||% s$width,
        rc$outline_opacity %||% s$opacity,
        s$style, NULL, where
      )
      fill <- qml_color(unname(cls$values[[k]]), opacity, where)
      args <- list("fill", 1, "SimpleFill", qml_fill_opts(fill, outline))
    }
    do.call(qml_add_symbol, c(list(syms, sym_name), args))
    if (is.null(first)) first <- args
  }

  # QGIS writes the symbol a new category would take; the first class's is a
  # neutral choice and keeps the document in the shape QGIS reads.
  src <- xml2::xml_add_child(r, "source-symbol")
  do.call(qml_add_symbol, c(list(src, "0"), first))
  xml2::xml_add_child(r, "rotation")
  xml2::xml_add_child(r, "sizescale")
  invisible(doc)
}
