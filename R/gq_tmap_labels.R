#' Translate a registry label to tmap text arguments
#'
#' Returns `tm_text()` arguments that draw a layer's registry label: the
#' column, size, colour, weight and slant, along the line for a line label, and
#' a halo. Splice them in with `do.call()`, as [gq_tmap_style()] is used.
#'
#' The halo is tmap's own (`opt_tm_text(halo = TRUE)`, tmap 4.3 and later):
#' copies of the text in the halo colour drawn around it, which is a halo rather
#' than the offset copy of `shadow` or the box of `bgcol`.
#'
#' Sizes follow QGIS: the registry holds the font size in points and the halo
#' width in millimetres, and tmap's text `size = 1` is 12 points. tmap sets the
#' halo width in lines of text, so it is computed for the registry's size; a
#' size changed afterwards scales the halo with it. Line labels (`placement`
#' `"line"` or `"curved"`) follow their line. QGIS's `merge_lines` and
#' `min_feature_size` are not applied here, because tmap places one label per
#' feature: dissolve by the label column and drop short features first, or a
#' river cut into segments is labelled once per segment. The registry's font
#' family is not passed, since QGIS's fonts are rarely installed where R
#' renders.
#'
#' @inheritParams gq_style
#' @param field Optional column to label with. Required when the registry
#'   labels the layer with a QGIS expression (`label$expression`), which tmap
#'   cannot evaluate: compute it as a column first. Also required for a label
#'   from the custom CSV, which names no column.
#' @return A named list of `tm_text()` arguments: `text`, `fontface` and
#'   `options`, and `size`, `col`, `col_alpha`, `xmod`, `ymod` where the
#'   registry gives them.
#'
#' @examples
#' reg <- gq_reg_main()
#'
#' # Lake names: the gnis_name_1 column, 10 pt italic, with a halo
#' str(gq_tmap_labels(reg, "lake")[c("text", "size", "col", "fontface")])
#'
#' # The registry labels PSCIS crossings with a QGIS expression, so tmap needs
#' # the label as a column
#' reg$layers$crossings_pscis_assessment$label$expression
#'
#' if (requireNamespace("tmap", quietly = TRUE) &&
#'     requireNamespace("sf", quietly = TRUE)) {
#'   lakes <- sf::st_sf(
#'     gnis_name_1 = "Tachick Lake",
#'     geometry = sf::st_sfc(sf::st_point(c(1200000, 1000000)), crs = 3005)
#'   )
#'   tmap::tm_shape(lakes) +
#'     do.call(tmap::tm_text, gq_tmap_labels(reg, "lake"))
#'
#'   crossings <- sf::st_sf(
#'     stream_crossing_id = 123456,
#'     geometry = sf::st_sfc(sf::st_point(c(1200000, 1000000)), crs = 3005)
#'   )
#'   crossings$label <- paste("PSCIS", crossings$stream_crossing_id)
#'   tmap::tm_shape(crossings) +
#'     do.call(tmap::tm_text,
#'             gq_tmap_labels(reg, "crossings_pscis_assessment", field = "label"))
#' }
#'
#' @export
gq_tmap_labels <- function(layer_or_reg, name = NULL, field = NULL) {
  if (!requireNamespace("tmap", quietly = TRUE)) {
    stop("tmap is required for gq_tmap_labels()", call. = FALSE)
  }
  lab <- label_get(layer_or_reg, name)
  src <- label_source(lab, field, "tmap")

  args <- list(text = src)
  if (!is.null(lab$size)) args$size <- lab$size / 12
  if (!is.null(lab$color)) args$col <- lab$color
  if (!is.null(lab$opacity)) args$col_alpha <- lab$opacity
  args$fontface <- label_fontface(lab)
  # Offsets are ems, as MapLibre's text-offset reads them: positive y is DOWN.
  # tmap's ymod is positive UP, so y flips; both are near enough one text
  # height that the magnitude carries over.
  if (!is.null(lab$offset_x)) args$xmod <- lab$offset_x
  if (!is.null(lab$offset_y)) args$ymod <- -lab$offset_y

  opts <- list(remove_overlap = TRUE)
  if (isTRUE(lab$placement %in% c("line", "curved"))) opts$along_lines <- TRUE
  if (!is.null(lab$halo$width) && lab$halo$width > 0) {
    # tmap offsets each halo copy by halo.width lines of text at the text's
    # size: a line is 1.2 times the text height, which is size x 12 points of
    # 0.3528 mm.
    size <- args[["size"]] %||% 1
    opts$halo <- TRUE
    opts$halo.col <- lab$halo$color %||% "#ffffff"
    opts$halo.width <- lab$halo$width / (size * 12 * 1.2 * 0.3528)
    opts$halo.alpha <- 1
  }
  args$options <- do.call(tmap::opt_tm_text, opts)
  args
}
