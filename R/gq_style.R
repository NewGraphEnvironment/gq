#' Get backend-agnostic style for a registry layer
#'
#' Resolves a layer by name and returns a plain list of style properties.
#' No backend-specific objects (tmap, mapgl, etc.) — just colors, widths,
#' shapes, classification fields, and values.
#'
#' @param layer_or_reg Either a layer entry from the registry
#'   (e.g., `reg$layers$lake`) or a full registry list when using name-based
#'   lookup.
#' @param name Optional layer name for name-based lookup. Accepts
#'   `name_qgis_snake` (e.g., `"lake"`) or `name_qgis` (e.g.,
#'   `"Crossings - PSCIS assessment"`). Normalized to match registry keys.
#' @param field Optional character string to override the classification field
#'   name. Useful when data comes from an alternative source with a different
#'   column name (e.g., bcfishpass `barrier_status` vs WHSE
#'   `barrier_result_code`). See `inst/registry/xref_layers.csv` for known
#'   alternatives.
#' @return A named list with `type` and style properties. For simple layers:
#'   `fill`, `stroke`, `mark` as applicable. For classified layers: adds
#'   `classification` with `field`, `values` (named color vector), `labels`,
#'   and per-class `widths`/`radii` when available.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_registry_read(path)
#'
#' # Simple polygon
#' gq_style(reg, "lake")
#'
#' # Simple line
#' gq_style(reg, "stream")
#'
#' # Classified line — includes field, values, labels
#' gq_style(reg, "road")
#'
#' # Override classification field for alternative data source
#' gq_style(reg, "road", field = "my_road_type")
#'
#' # Object-based (backwards compatible)
#' gq_style(reg$layers$lake)
#'
#' @export
gq_style <- function(layer_or_reg, name = NULL, field = NULL) {
  layer <- resolve_layer(layer_or_reg, name)

  type <- layer$type
  if (is.null(type)) stop("Layer must have a 'type' field (polygon, line, point)")

  result <- list(type = type)

  # Classification
  if (!is.null(layer$classification)) {
    cls <- layer$classification
    keys <- names(cls$classes)

    values <- vapply(cls$classes, function(x) x$color %||% NA_character_, character(1))
    labels <- vapply(cls$classes, function(x) x$label %||% NA_character_, character(1))
    labels[is.na(labels)] <- to_title(keys[is.na(labels)])
    widths <- vapply(cls$classes, function(x) x$width %||% NA_real_, numeric(1))
    radii <- vapply(cls$classes, function(x) x$radius %||% NA_real_, numeric(1))
    shapes <- vapply(cls$classes, function(x) x$shape %||% NA_character_, character(1))

    # Remove __empty__ class
    keep <- keys != "__empty__"
    values <- values[keep]
    labels <- labels[keep]
    widths <- widths[keep]
    radii <- radii[keep]
    shapes <- shapes[keep]
    keys <- keys[keep]
    names(values) <- keys

    result$classification <- list(
      field = field %||% cls$field,
      values = values,
      labels = unname(labels)
    )
    if (!all(is.na(widths))) result$classification$widths <- widths
    if (!all(is.na(radii))) result$classification$radii <- radii
    if (!all(is.na(shapes))) result$classification$shapes <- shapes

    return(result)
  }

  # Simple styles
  if (!is.null(layer$fill)) result$fill <- layer$fill
  if (!is.null(layer$stroke)) result$stroke <- layer$stroke
  if (!is.null(layer$mark)) result$mark <- layer$mark
  if (!is.null(layer$overlay)) result$overlay <- layer$overlay

  result
}


# --- internal helpers (shared across backends) ------------------------------

#' Normalize a layer name to registry key format
#' @noRd
normalize_layer_name <- function(name) {
  key <- tolower(gsub("[^a-zA-Z0-9]+", "_", trimws(name)))
  sub("^_|_$", "", key)
}

#' Resolve a layer from either a layer object or registry + name
#' @noRd
resolve_layer <- function(layer_or_reg, name = NULL) {
  if (is.null(name)) {
    return(layer_or_reg)
  }

  reg <- layer_or_reg
  if (is.null(reg$layers)) {
    stop("First argument must be a registry when using name-based lookup")
  }

  key <- normalize_layer_name(name)

  if (!is.null(reg$layers[[key]])) {
    return(reg$layers[[key]])
  }

  available <- names(reg$layers)
  close <- available[agrep(key, available, max.distance = 0.3)]
  hint <- if (length(close) > 0) {
    paste0(". Did you mean: ", paste(close, collapse = ", "), "?")
  } else {
    ""
  }
  stop("Layer '", name, "' (key: '", key, "') not found in registry", hint)
}

#' @noRd
to_title <- function(x) {
  paste0(toupper(substring(x, 1, 1)), tolower(substring(x, 2)))
}
