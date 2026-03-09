#' Translate a registry layer style to tmap v4 arguments
#'
#' Wraps [gq_style()] and returns a named list of arguments suitable for
#' tmap v4 layer functions (tm_polygons, tm_lines, tm_dots, tm_symbols).
#' Handles both simple and classified layers.
#'
#' @inheritParams gq_style
#' @return A named list of tmap arguments. Use with `do.call()`.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_registry_read(path)
#'
#' # Name-based lookup
#' gq_tmap_style(reg, "lake")
#' gq_tmap_style(reg, "stream")
#' gq_tmap_style(reg, "road")
#'
#' # Object-based (backwards compatible)
#' gq_tmap_style(reg$layers$lake)
#'
#' # Use with tmap v4:
#' # tm_shape(lakes_sf) + do.call(tm_polygons, gq_tmap_style(reg, "lake"))
#' # tm_shape(roads_sf) + do.call(tm_lines, gq_tmap_style(reg, "road"))
#'
#' @export
gq_tmap_style <- function(layer_or_reg, name = NULL) {
  sty <- gq_style(layer_or_reg, name)

  if (!is.null(sty$classification)) {
    return(tmap_classified(sty))
  }

  switch(sty$type,
    polygon = tmap_polygon_args(sty),
    line = tmap_line_args(sty),
    point = tmap_point_args(sty),
    stop("Unknown layer type: ", sty$type)
  )
}


#' Get classification info for tmap scale functions
#'
#' For categorized/graduated layers, returns the field, color values, and
#' labels suitable for tmap's `tm_scale_categorical()`.
#'
#' @inheritParams gq_style
#' @return A named list with `values` (named color vector), `labels`, and `field`.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_registry_read(path)
#'
#' # Name-based lookup
#' cls <- gq_tmap_classes(reg, "road")
#' cls$field
#' cls$values
#' cls$labels
#'
#' # Object-based (backwards compatible)
#' cls <- gq_tmap_classes(reg$layers$road)
#'
#' @export
gq_tmap_classes <- function(layer_or_reg, name = NULL) {
  sty <- gq_style(layer_or_reg, name)
  cls <- sty$classification
  if (is.null(cls)) stop("Layer does not have classification")
  list(field = cls$field, values = cls$values, labels = cls$labels)
}


# --- tmap-specific internal helpers -----------------------------------------

#' @noRd
tmap_classified <- function(sty) {
  cls <- sty$classification
  args <- list()

  if (sty$type == "polygon") {
    args$fill <- cls$field
    args$fill.scale <- tmap::tm_scale_categorical(
      values = cls$values, labels = cls$labels
    )
    args$fill.legend <- tmap::tm_legend(show = FALSE)
  } else if (sty$type == "line") {
    args$col <- cls$field
    args$col.scale <- tmap::tm_scale_categorical(
      values = cls$values, labels = cls$labels
    )
    args$col.legend <- tmap::tm_legend(show = FALSE)
    if (!is.null(cls$widths)) args$lwd <- unname(cls$widths[1])
  } else if (sty$type == "point") {
    args$fill <- cls$field
    args$fill.scale <- tmap::tm_scale_categorical(
      values = cls$values, labels = cls$labels
    )
    args$fill.legend <- tmap::tm_legend(show = FALSE)
    if (!is.null(cls$radii)) args$size <- unname(cls$radii[1]) / 3
  }

  args
}

#' @noRd
tmap_polygon_args <- function(sty) {
  args <- list()
  if (!is.null(sty$fill)) {
    args$fill <- sty$fill$color
    if (!is.null(sty$fill$opacity)) args$fill_alpha <- sty$fill$opacity
  }
  if (!is.null(sty$stroke)) {
    if (!identical(sty$stroke$style, "none")) {
      args$col <- sty$stroke$color
      if (!is.null(sty$stroke$width)) args$lwd <- sty$stroke$width
    } else {
      args$col <- NA
    }
  }
  args
}

#' @noRd
tmap_line_args <- function(sty) {
  args <- list()
  if (!is.null(sty$stroke)) {
    args$col <- sty$stroke$color
    if (!is.null(sty$stroke$width)) args$lwd <- sty$stroke$width
    if (!is.null(sty$stroke$opacity)) args$col_alpha <- sty$stroke$opacity
    if (!is.null(sty$stroke$dash) && sty$stroke$dash != "no") {
      args$lty <- sty$stroke$dash
    }
  }
  args
}

#' @noRd
tmap_point_args <- function(sty) {
  args <- list()
  if (!is.null(sty$mark)) {
    args$fill <- sty$mark$color
    if (!is.null(sty$mark$radius)) args$size <- sty$mark$radius / 3
  }
  if (!is.null(sty$fill)) {
    args$fill <- sty$fill$color
    if (!is.null(sty$fill$opacity)) args$fill_alpha <- sty$fill$opacity
  }
  args
}
