#' Translate a registry label to tmap text layers
#'
#' Returns the `tm_text()` layers that draw a layer's registry label: the
#' column, size, colour, weight and slant, and a halo. Add it after the layer's
#' `tm_shape()`.
#'
#' tmap has no halo, and its `shadow` and `bgcol` draw an offset copy and a box,
#' so the halo is eight copies of the text in the halo colour, offset by the
#' halo width around it, under the coloured one. That is why this returns
#' layers rather than `do.call()` arguments, unlike [gq_tmap_style()].
#'
#' Sizes follow QGIS: the registry holds the font size in points and the halo
#' width in millimetres, and tmap's text `size = 1` is 12 points. Line labels
#' (`placement` `"line"` or `"curved"`) follow their line. QGIS's
#' `merge_lines` and `min_feature_size` are not applied here, because tmap
#' places one label per feature: dissolve by the label column and drop short
#' features first, or a river cut into segments is labelled once per segment.
#' The registry's font family is not passed, since QGIS's fonts are rarely
#' installed where R renders.
#'
#' @inheritParams gq_style
#' @param field Optional column to label with. Required when the registry
#'   labels the layer with a QGIS expression (`label$expression`), which tmap
#'   cannot evaluate: compute it as a column first. Also required for a label
#'   from the custom CSV, which names no column.
#' @param ... Arguments passed to every `tm_text()` call, overriding the
#'   registry's (e.g. `size = 0.6`). The halo copies keep the halo colour.
#' @return A tmap object of `tm_text()` layers.
#'
#' @examples
#' reg <- gq_reg_main()
#'
#' # A plain column: lakes are labelled with gnis_name_1, in italic
#' reg$layers$lake$label$field
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
#'   tmap::tm_shape(lakes) + gq_tmap_labels(reg, "lake")
#'
#'   crossings <- sf::st_sf(
#'     stream_crossing_id = 123456,
#'     geometry = sf::st_sfc(sf::st_point(c(1200000, 1000000)), crs = 3005)
#'   )
#'   crossings$label <- paste("PSCIS", crossings$stream_crossing_id)
#'   tmap::tm_shape(crossings) +
#'     gq_tmap_labels(reg, "crossings_pscis_assessment", field = "label")
#' }
#'
#' @export
gq_tmap_labels <- function(layer_or_reg, name = NULL, field = NULL, ...) {
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
  args$options <- do.call(tmap::opt_tm_text, opts)

  over <- list(...)
  args[names(over)] <- over
  main <- do.call(tmap::tm_text, args)

  if (is.null(lab$halo$width) || lab$halo$width <= 0) return(main)

  # The halo's offset is arithmetic on size and position, so it needs them as
  # numbers; one mapped to a column (`size = "area"`) varies by feature.
  mapped <- vapply(args[intersect(c("size", "xmod", "ymod"), names(args))],
                   function(v) !is.numeric(v), logical(1))
  if (any(mapped)) {
    warning("gq_tmap_labels(): ", paste(names(mapped)[mapped], collapse = ", "),
            " mapped to a column, so the label is drawn without its halo",
            call. = FALSE)
    return(main)
  }

  # Offset in tmap's lines: a line is 1.2 times the text height, and the text
  # is `size` x 12 points (0.3528 mm each).
  size <- args$size %||% 1
  step <- lab$halo$width / (size * 12 * 1.2 * 0.3528)
  dirs <- list(c(1, 0), c(-1, 0), c(0, 1), c(0, -1),
               c(.7, .7), c(-.7, .7), c(.7, -.7), c(-.7, -.7))
  halo <- lapply(dirs, function(d) {
    a <- args
    a$col <- lab$halo$color %||% "#ffffff"
    a$col_alpha <- NULL
    a$xmod <- (args$xmod %||% 0) + d[1] * step
    a$ymod <- (args$ymod %||% 0) + d[2] * step
    do.call(tmap::tm_text, a)
  })
  Reduce(`+`, c(halo, list(main)))
}
