#' Load the main gq style registry
#'
#' Returns the merged master registry (`reg_main.json`) that ships with gq.
#' This is the single source of truth for all layer styles — the union of
#' QGIS-extracted registries and hand-curated CSV styles.
#'
#' @return A list with `name`, `version`, `source`, and `layers` elements.
#'
#' @examples
#' reg <- gq_reg_main()
#' names(reg$layers)
#'
#' # Use directly with style translators
#' gq_tmap_style(gq_reg_main()$layers$lake)
#'
#' @export
gq_reg_main <- function() {
  path <- system.file("registry", "reg_main.json", package = "gq")
  if (path == "") stop("reg_main.json not found — reinstall gq")
  gq_registry_read(path)
}


#' Read a gq style registry from JSON (alias)
#'
#' Short alias for [gq_registry_read()].
#'
#' @inheritParams gq_registry_read
#' @return A list with `name`, `version`, `source`, and `layers` elements.
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg <- gq_reg_read(path)
#' names(reg$layers)
#'
#' @export
gq_reg_read <- function(path) {
  gq_registry_read(path)
}


#' Read a gq custom style registry
#'
#' Reads a hand-curated CSV file and converts it to the same list structure as
#' [gq_registry_read()]. Multiple rows per `layer_key` with a `class_field`
#' and `class_value` produce a classification layer. Single rows produce
#' simple fill/stroke/mark/label styles.
#'
#' @section Raster layers:
#' A `type` of `"raster"` carries a QGIS paletted renderer: one row per palette
#' entry, `class_value` holding the band value and `class_label` the palette
#' label. `habitat_lateral` is the shipped example.
#'
#' `class_field` is a **sentinel** for a raster, not a column name. The
#' classification branch here requires a non-NA `class_field`, and a paletted
#' raster keys on pixel value rather than on any attribute — so the convention
#' is the literal string `"value"`, meaning band 1. A consumer with a real band
#' name passes it through `gq_style(field = )`.
#'
#' Give `class_value` at least one non-numeric value across the file, or accept
#' that `read.csv()` will type the column as integer; the reader coerces back to
#' character, but a numeric column reads as an ordinal in every other tool.
#'
#' What a raster row **cannot** carry: QGIS's per-value `rasterTransparency`
#' (`habitat_lateral` sets 30% on top of the renderer's 0.4 opacity), multi-band
#' renderers, and resampling. Those live in the QML, which is lossless — reach
#' for [gq_style_qml()] whenever the consumer is QGIS itself.
#'
#' The tmap and mapgl translators do not render rasters. [gq_tmap_style()],
#' [gq_mapgl_style()] and [gq_mapgl_classes()] all refuse a raster rather than
#' returning something plausible; [gq_tmap_classes()] works, since a palette is
#' a classification like any other.
#'
#' @param path Path to a CSV file with columns: layer_key, type, source_layer,
#'   class_field, class_value, fill_color, fill_opacity, stroke_color,
#'   stroke_width, stroke_opacity, mark_color, mark_shape, mark_radius,
#'   mark_stroke_color, mark_stroke_width, label_color, label_size, label_font,
#'   label_halo_color, label_halo_width, label_offset_x, label_offset_y, note.
#' @return A list with `name`, `version`, `source`, and `layers` elements,
#'   compatible with [gq_tmap_style()], [gq_mapgl_style()], etc.
#'
#' @examples
#' path <- system.file("registry", "reg_custom.csv", package = "gq")
#' reg <- gq_reg_custom(path)
#' names(reg$layers)
#'
#' # Classified layer (multiple rows per layer_key)
#' reg$layers$bec_zone$classification$field
#' names(reg$layers$bec_zone$classification$classes)
#'
#' # Simple layer (single row)
#' reg$layers$rivers_poly$fill
#'
#' @export
gq_reg_custom <- function(path) {
  df <- utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))

  # Coerce numeric columns — read.csv reads mixed columns as character
  num_cols <- c("fill_opacity", "stroke_width", "stroke_opacity",
                "mark_radius", "mark_stroke_width",
                "label_size", "label_halo_width",
                "label_offset_x", "label_offset_y")
  for (col in intersect(num_cols, names(df))) {
    df[[col]] <- suppressWarnings(as.numeric(df[[col]]))
  }

  required <- c("layer_key", "type")
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    stop("CSV missing required columns: ", paste(missing, collapse = ", "))
  }

  layers <- list()
  keys <- unique(df$layer_key)

  for (key in keys) {
    rows <- df[df$layer_key == key, , drop = FALSE]
    row1 <- rows[1, ]
    entry <- list(type = row1$type)

    if (!is.na(row1$source_layer)) entry$source_layer <- row1$source_layer

    has_class <- !is.na(row1$class_field) && !is.na(row1$class_value)

    if (has_class && nrow(rows) > 0) {
      # classification layer
      classes <- list()
      for (i in seq_len(nrow(rows))) {
        r <- rows[i, ]
        cls <- list()
        if (!is.na(r$fill_color)) cls$color <- r$fill_color
        if (!is.na(r$fill_opacity)) cls$opacity <- r$fill_opacity
        if (!is.na(r$stroke_color)) cls$outline_color <- r$stroke_color
        if (!is.na(r$stroke_width)) cls$outline_width <- r$stroke_width
        if (!is.na(r$stroke_opacity)) cls$outline_opacity <- r$stroke_opacity
        if ("class_label" %in% names(r) && !is.na(r$class_label)) {
          cls$label <- r$class_label
        }
        # as.character() is load-bearing, not defensive. read.csv() types a
        # class_value column by content, so a CSV whose values are all numeric
        # yields an integer -- and `classes[[1L]] <- x` is POSITIONAL
        # assignment, producing an unnamed list that every downstream lookup
        # misses. It works today only because bec_zone's "SBS"/"ESSF" keep this
        # file's column character; a caller's own CSV of numeric raster classes
        # would not (#64).
        classes[[as.character(r$class_value)]] <- cls
      }
      entry$classification <- list(field = row1$class_field, classes = classes)

      # shared stroke for all classes (if present)
      if (!is.na(row1$stroke_color)) {
        stroke <- list(color = row1$stroke_color)
        if (!is.na(row1$stroke_width)) stroke$width <- row1$stroke_width
        if (!is.na(row1$stroke_opacity)) stroke$opacity <- row1$stroke_opacity
        entry$stroke <- stroke
      }
    } else {
      # simple layer
      entry <- c(entry, csv_fill(row1), csv_stroke(row1), csv_mark(row1))
    }

    # label (applies to both classified and simple)
    label <- csv_label(row1)
    if (length(label) > 0) entry$label <- label

    layers[[key]] <- entry
  }

  list(
    name = tools::file_path_sans_ext(basename(path)),
    version = "0.1.0",
    source = basename(path),
    layers = layers
  )
}


#' Merge multiple gq registries
#'
#' Takes any number of registry list objects and merges their layers into
#' a single master registry. For duplicate layer keys, the `priority` argument
#' controls which source wins. Conflicts are logged as an attribute.
#'
#' @param ... Registry list objects (from [gq_reg_read()], [gq_reg_custom()],
#'   or [gq_registry_read()]).
#' @param csv Optional character vector of CSV file paths to include.
#'   Each is read via [gq_reg_custom()] and appended to the merge inputs.
#' @param priority Either `"last"` (default, later sources win) or `"first"`
#'   (earlier sources win) for duplicate layer keys.
#' @return A merged registry list. Conflicts are stored in a `"conflicts"`
#'   attribute (a data.frame with columns: layer_key, source_a, source_b).
#'
#' @examples
#' path <- system.file("examples", "mini_registry.json", package = "gq")
#' reg1 <- gq_reg_read(path)
#' reg2 <- gq_reg_read(path)
#' merged <- gq_reg_merge(reg1, reg2)
#' length(merged$layers)
#'
#' @export
gq_reg_merge <- function(..., csv = NULL, priority = c("last", "first")) {
  priority <- match.arg(priority)
  regs <- list(...)

  if (!is.null(csv)) {
    csv_regs <- lapply(csv, gq_reg_custom)
    regs <- c(regs, csv_regs)
  }

  if (length(regs) == 0) stop("No registries to merge")

  merged_layers <- list()
  layer_source <- character()  # tracks which source owns each key
  conflicts <- data.frame(
    layer_key = character(), source_a = character(), source_b = character(),
    stringsAsFactors = FALSE
  )

  for (reg in regs) {
    src <- reg$source %||% "unknown"
    for (key in names(reg$layers)) {
      if (key %in% names(merged_layers)) {
        # conflict
        conflicts <- rbind(conflicts, data.frame(
          layer_key = key, source_a = layer_source[[key]], source_b = src,
          stringsAsFactors = FALSE
        ))
        if (priority == "last") {
          merged_layers[[key]] <- reg$layers[[key]]
          layer_source[[key]] <- src
        }
        # if "first", keep existing
      } else {
        merged_layers[[key]] <- reg$layers[[key]]
        layer_source[[key]] <- src
      }
    }
  }

  result <- list(
    name = "merged",
    version = "0.1.0",
    source = paste(vapply(regs, function(r) r$source %||% "unknown", character(1)),
                   collapse = " + "),
    layers = merged_layers
  )

  if (nrow(conflicts) > 0) attr(result, "conflicts") <- conflicts

  result
}


# --- CSV field helpers (internal) -------------------------------------------

#' @noRd
csv_fill <- function(row) {
  if (is.na(row$fill_color)) return(list())
  fill <- list(color = row$fill_color)
  if (!is.na(row$fill_opacity)) fill$opacity <- row$fill_opacity
  list(fill = fill)
}

#' @noRd
csv_stroke <- function(row) {
  if (is.na(row$stroke_color)) return(list())
  stroke <- list(color = row$stroke_color)
  if (!is.na(row$stroke_width)) stroke$width <- row$stroke_width
  if (!is.na(row$stroke_opacity)) stroke$opacity <- row$stroke_opacity
  list(stroke = stroke)
}

#' @noRd
csv_mark <- function(row) {
  if (is.na(row$mark_color)) return(list())
  mark <- list(color = row$mark_color)
  if (!is.na(row$mark_shape)) mark$shape <- row$mark_shape
  if (!is.na(row$mark_radius)) mark$radius <- row$mark_radius
  if (!is.na(row$mark_stroke_color)) mark$stroke_color <- row$mark_stroke_color
  if (!is.na(row$mark_stroke_width)) mark$stroke_width <- row$mark_stroke_width
  list(mark = mark)
}

#' @noRd
csv_label <- function(row) {
  if (is.na(row$label_color)) return(list())
  label <- list(color = row$label_color)
  if (!is.na(row$label_size)) label$size <- row$label_size
  if (!is.na(row$label_font)) label$font <- row$label_font
  if (!is.na(row$label_offset_x)) label$offset_x <- row$label_offset_x
  if (!is.na(row$label_offset_y)) label$offset_y <- row$label_offset_y
  if (!is.na(row$label_halo_color) || !is.na(row$label_halo_width)) {
    halo <- list()
    if (!is.na(row$label_halo_color)) halo$color <- row$label_halo_color
    if (!is.na(row$label_halo_width)) halo$width <- row$label_halo_width
    label$halo <- halo
  }
  label
}

# base R null coalesce (also defined in gq_qgs_extract.R)
if (!exists("%||%", envir = asNamespace("base"), inherits = FALSE)) {
  `%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a)) b else a
}
