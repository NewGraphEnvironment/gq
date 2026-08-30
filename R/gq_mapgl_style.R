#' Translate a registry layer style to mapgl arguments
#'
#' Takes a single layer entry from the registry and returns a named list
#' with `paint` and `layout` elements suitable for mapgl's `add_fill_layer()`,
#' `add_line_layer()`, `add_circle_layer()`, or generic `add_layer()`.
#'
#' @param layer A layer entry from the registry (e.g., `reg$layers$lake`).
#' @return A named list with `paint` and optionally `layout` elements.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_registry_read(path)
#'
#' # Polygon: returns paint list with fill-color, fill-opacity, fill-outline-color
#' style <- gq_mapgl_style(reg$layers$lake)
#' style$layer_type
#' style$paint
#'
#' # Line: returns paint list with line-color, line-width, line-opacity
#' gq_mapgl_style(reg$layers$stream)
#'
#' # Point: returns paint list with circle-color, circle-radius
#' gq_mapgl_style(reg$layers$crossing)
#'
#' # Use with mapgl:
#' # maplibre() |>
#' #   add_fill_layer(source = lakes_src, paint = style$paint)
#'
#' @export
gq_mapgl_style <- function(layer) {
  type <- layer$type
  if (is.null(type)) stop("Layer must have a 'type' field (polygon, line, point)")

  switch(type,
    polygon = mapgl_polygon(layer),
    line = mapgl_line(layer),
    point = mapgl_point(layer),
    stop("Unknown layer type: ", type)
  )
}


# --- internal helpers --------------------------------------------------------

#' @noRd
mapgl_polygon <- function(layer) {
  paint <- list()

  if (!is.null(layer$fill)) {
    paint[["fill-color"]] <- layer$fill$color
    if (!is.null(layer$fill$opacity)) paint[["fill-opacity"]] <- layer$fill$opacity
  }

  if (!is.null(layer$stroke) && !identical(layer$stroke$style, "none")) {
    paint[["fill-outline-color"]] <- layer$stroke$color
  }

  list(paint = paint, layer_type = "fill")
}

#' @noRd
mapgl_line <- function(layer) {
  paint <- list()
  layout <- list()

  if (!is.null(layer$stroke)) {
    paint[["line-color"]] <- layer$stroke$color
    if (!is.null(layer$stroke$width)) paint[["line-width"]] <- layer$stroke$width
    if (!is.null(layer$stroke$opacity)) paint[["line-opacity"]] <- layer$stroke$opacity
    if (!is.null(layer$stroke$dash) && !layer$stroke$dash %in% c("no", "solid")) {
      # convert QGIS dash string "2.5 3.5" to MapLibre dasharray [2.5, 3.5]
      parts <- as.numeric(strsplit(layer$stroke$dash, "[; ]")[[1]])
      if (!any(is.na(parts))) paint[["line-dasharray"]] <- parts
    }
  }

  list(paint = paint, layout = layout, layer_type = "line")
}

#' @noRd
mapgl_point <- function(layer) {
  paint <- list()

  if (!is.null(layer$mark)) {
    paint[["circle-color"]] <- layer$mark$color
    # circle-radius is a true radius in CSS pixels; the registry stores a
    # diameter in millimetres. Passing it through raw made mapgl and tmap
    # disagree by 3x, with neither matching QGIS (#16).
    if (!is.null(layer$mark$radius)) {
      paint[["circle-radius"]] <- gq_symbol_size(layer$mark$radius, "mapgl")
    }
  }

  if (!is.null(layer$fill)) {
    paint[["circle-color"]] <- layer$fill$color
    if (!is.null(layer$fill$opacity)) paint[["circle-opacity"]] <- layer$fill$opacity
  }

  list(paint = paint, layer_type = "circle")
}


#' Get a MapLibre match expression for a classified layer
#'
#' For categorized layers, returns a MapLibre-style match expression
#' suitable for use in paint properties.
#'
#' @param layer A classified layer entry from the registry.
#' @param property The paint property to set (e.g., "fill-color", "line-color",
#'   "circle-color").
#' @return A list representing a MapLibre match expression.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_registry_read(path)
#'
#' # Build a MapLibre match expression for classified roads
#' expr <- gq_mapgl_classes(reg$layers$road)
#' # Returns: ["match", ["get", "road_type"], "highway", "#c0392b", "arterial", "#e67e22", "#888888"]
#' str(expr)
#'
#' # Use with mapgl:
#' # maplibre() |>
#' #   add_line_layer(
#' #     source = roads_src,
#' #     paint = list("line-color" = expr)
#' #   )
#'
#' @export
gq_mapgl_classes <- function(layer, property = NULL) {
  cls <- layer$classification
  if (is.null(cls)) stop("Layer does not have classification")

  # A match expression reads a FEATURE PROPERTY -- `["get", field]` -- so it is
  # meaningful only for a vector source. Handed a raster it produced a perfectly
  # well-formed expression that resolves against nothing, which is worse than
  # the sibling error in gq_mapgl_style(): that one refuses, this one used to
  # answer. Silent-wrong is the direction this whole guard exists to close (#64).
  # isTRUE() rather than `!is.null(x) && !x %in% ...`: that spelling let a layer
  # with NO type through, which is the same silent-wrong outcome by a different
  # route, and it made this disagree with gq_mapgl_style() on identical input.
  # Absent is not "fine", it is unknown.
  if (!isTRUE(layer$type %in% c("polygon", "line", "point"))) {
    stop("Unknown layer type: ", layer$type %||% "<none>",
         " (a match expression reads a feature property, so it cannot address ",
         "a raster band)")
  }

  # build match expression: ["match", ["get", field], val1, color1, val2, color2, ..., fallback]
  expr <- list("match", list("get", cls$field))

  for (key in names(cls$classes)) {
    if (key == "__empty__") next
    cl <- cls$classes[[key]]
    expr <- c(expr, list(key, cl$color))
  }

  # fallback color (gray)
  expr <- c(expr, list("#888888"))

  expr
}
