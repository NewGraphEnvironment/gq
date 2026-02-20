#' Translate a registry layer style to tmap v4 arguments
#'
#' Takes a single layer entry from the registry and returns a named list
#' of arguments suitable for tmap v4 layer functions (tm_polygons, tm_lines,
#' tm_dots).
#'
#' @param layer A layer entry from the registry (e.g., `reg$layers$lake`).
#' @return A named list of tmap arguments. Use with `do.call()` or `!!!`.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_registry_read(path)
#'
#' # Polygon: returns fill, fill_alpha, col, lwd ready for tm_polygons()
#' gq_tmap_style(reg$layers$lake)
#'
#' # Line: returns col, lwd, col_alpha ready for tm_lines()
#' gq_tmap_style(reg$layers$stream)
#'
#' # Point: returns fill, size ready for tm_dots()
#' gq_tmap_style(reg$layers$crossing)
#'
#' # Use with tmap v4:
#' # tm_shape(lakes_sf) + do.call(tm_polygons, gq_tmap_style(reg$layers$lake))
#' # tm_shape(lakes_sf) + tm_polygons(!!!gq_tmap_style(reg$layers$lake))
#'
#' @export
gq_tmap_style <- function(layer) {
  type <- layer$type
  if (is.null(type)) stop("Layer must have a 'type' field (polygon, line, point)")

  switch(type,
    polygon = tmap_polygon(layer),
    line = tmap_line(layer),
    point = tmap_point(layer),
    stop("Unknown layer type: ", type)
  )
}


# --- internal helpers --------------------------------------------------------

#' @noRd
tmap_polygon <- function(layer) {
  args <- list()

  if (!is.null(layer$fill)) {
    args$fill <- layer$fill$color
    if (!is.null(layer$fill$opacity)) args$fill_alpha <- layer$fill$opacity
  }

  if (!is.null(layer$stroke)) {
    if (!identical(layer$stroke$style, "none")) {
      args$col <- layer$stroke$color
      if (!is.null(layer$stroke$width)) args$lwd <- layer$stroke$width
    } else {
      args$col <- NA
    }
  }

  args
}

#' @noRd
tmap_line <- function(layer) {
  args <- list()

  if (!is.null(layer$stroke)) {
    args$col <- layer$stroke$color
    if (!is.null(layer$stroke$width)) args$lwd <- layer$stroke$width
    if (!is.null(layer$stroke$opacity)) args$col_alpha <- layer$stroke$opacity
    if (!is.null(layer$stroke$dash) && layer$stroke$dash != "no") {
      args$lty <- layer$stroke$dash
    }
  }

  args
}

#' @noRd
tmap_point <- function(layer) {
  args <- list()

  if (!is.null(layer$mark)) {
    args$fill <- layer$mark$color
    if (!is.null(layer$mark$radius)) args$size <- layer$mark$radius / 3
  }

  if (!is.null(layer$fill)) {
    args$fill <- layer$fill$color
    if (!is.null(layer$fill$opacity)) args$fill_alpha <- layer$fill$opacity
  }

  args
}


#' Get a named list of tmap arguments for each class in a classified layer
#'
#' For categorized/graduated layers, returns the fill or col values suitable
#' for tmap's scale functions.
#'
#' @param layer A classified layer entry from the registry.
#' @return A named list with `values` (named color vector), `labels`, and `field`.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_registry_read(path)
#'
#' # Extract classification — field name, color vector, and labels
#' cls <- gq_tmap_classes(reg$layers$road)
#' cls$field
#' cls$values
#' cls$labels
#'
#' # Use with tmap v4:
#' # tm_shape(roads_sf) +
#' #   tm_lines(
#' #     col = cls$field,
#' #     col.scale = tm_scale_categorical(values = cls$values, labels = cls$labels)
#' #   )
#'
#' @export
gq_tmap_classes <- function(layer) {
  cls <- layer$classification
  if (is.null(cls)) stop("Layer does not have classification")

  values <- vapply(cls$classes, function(x) x$color %||% NA_character_, character(1))
  labels <- vapply(cls$classes, function(x) x$label %||% NA_character_, character(1))

  # use class keys as labels where label is missing
  keys <- names(cls$classes)
  labels[is.na(labels)] <- keys[is.na(labels)]

  # remove __empty__ class
  keep <- keys != "__empty__"
  values <- values[keep]
  labels <- labels[keep]
  keys <- keys[keep]

  names(values) <- keys

  list(
    field = cls$field,
    values = values,
    labels = unname(labels)
  )
}

