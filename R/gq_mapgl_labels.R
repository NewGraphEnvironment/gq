#' Translate a registry label to mapgl symbol-layer arguments
#'
#' Returns a named list of `add_symbol_layer()` arguments that draw a layer's
#' registry label: the column, size, colour, halo, placement and offset. Splice
#' it in with `do.call()`, as [gq_tmap_style()] is used.
#'
#' Sizes follow QGIS: the registry holds the font size in points and the halo
#' width in millimetres, converted here to MapLibre's pixels at 96 dpi. A line
#' label (`placement` `"line"`, `"curved"`, `"perimeter"` or
#' `"perimeter_curved"`) follows its line.
#' QGIS's `merge_lines` and `min_feature_size` are not applied, and MapLibre
#' does not merge labels across features: dissolve by the label column and drop
#' short features first. The font family and slant are left to the basemap's
#' glyphs, because MapLibre can only draw a font its glyph server carries; pass
#' `text_font` to choose one.
#'
#' @param layer A layer entry from the registry (e.g., `reg$layers$lake`).
#' @param field Optional column to label with. Required when the registry
#'   labels the layer with a QGIS expression (`label$expression`), which
#'   MapLibre cannot evaluate: compute it as a column first. Also required for
#'   a label from the custom CSV, which names no column.
#' @return A named list of `add_symbol_layer()` arguments: `text_field`,
#'   `symbol_placement`, and `text_size`, `text_color`, `text_opacity`,
#'   `text_halo_color`, `text_halo_width`, `text_offset` where the registry
#'   gives them.
#'
#' @examples
#' reg <- gq_reg_main()
#'
#' # Lake names: 10 pt in QGIS, 13.33 px in MapLibre, with a white halo
#' str(gq_mapgl_labels(reg$layers$lake))
#'
#' # Stream names follow the stream
#' gq_mapgl_labels(reg$layers$stream_labels)$symbol_placement
#'
#' # Towns come from the custom CSV, which names no column
#' str(gq_mapgl_labels(reg$layers$town, field = "name"))
#'
#' # Use with mapgl:
#' # do.call(mapgl::add_symbol_layer, c(
#' #   list(map = m, id = "lake-labels", source = lakes_sf),
#' #   gq_mapgl_labels(reg$layers$lake)
#' # ))
#'
#' @export
gq_mapgl_labels <- function(layer, field = NULL) {
  lab <- label_get(layer)
  src <- label_source(lab, field, "MapLibre")

  args <- list(text_field = list("get", src))
  line_modes <- c("line", "curved", "perimeter", "perimeter_curved")
  args$symbol_placement <- if (isTRUE(lab$placement %in% line_modes)) {
    "line"
  } else {
    "point"
  }
  if (!is.null(lab$size)) args$text_size <- round(lab$size * 96 / 72, 2)
  if (!is.null(lab$color)) args$text_color <- lab$color
  if (!is.null(lab$opacity)) args$text_opacity <- lab$opacity
  if (!is.null(lab$halo$color)) args$text_halo_color <- lab$halo$color
  if (!is.null(lab$halo$width)) args$text_halo_width <- round(lab$halo$width * 96 / 25.4, 2)
  if (!is.null(lab$offset_x) || !is.null(lab$offset_y)) {
    args$text_offset <- c(lab$offset_x %||% 0, lab$offset_y %||% 0)
  }
  args
}
