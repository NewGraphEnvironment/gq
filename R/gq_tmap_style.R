#' Translate a registry layer style to tmap v4 arguments
#'
#' Wraps [gq_style()] and returns a named list of arguments suitable for
#' tmap v4 layer functions (tm_polygons, tm_lines, tm_dots, tm_symbols).
#' Handles both simple and classified layers.
#'
#' @inheritParams gq_style
#' @return A named list of tmap arguments. Use with `do.call()`.
#'
#'   For a classified layer every aesthetic the registry defines is mapped
#'   per class, not just colour: line `lwd` and `lty`, point `size`. Each is
#'   returned as the classification field name plus a matching `.scale`, the
#'   same shape `fill`/`col` already used, so `do.call()` callers need no
#'   change. Numeric axes (`lwd`, `size`) fall back to a scalar when the
#'   registry defines the value for only some classes, since a half-mapped
#'   axis would invent a size for the gaps.
#'
#'   Per-class opacity is the exception to that rule. A class with no opacity
#'   is opaque, not unknown, so it is mapped as 1: polygon and point classes
#'   through `fill_alpha`, line classes through `col_alpha`. Opacity shared by
#'   every class is returned as a plain number.
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
#' # Override classification field for alternative data source
#' # (e.g., bcfishpass barrier_status vs WHSE barrier_result_code)
#' gq_tmap_style(reg, "road", field = "my_road_type")
#'
#' # Object-based (backwards compatible)
#' gq_tmap_style(reg$layers$lake)
#'
#' # Use with tmap v4:
#' # tm_shape(lakes_sf) + do.call(tm_polygons, gq_tmap_style(reg, "lake"))
#' # tm_shape(roads_sf) + do.call(tm_lines, gq_tmap_style(reg, "road"))
#'
#' @export
gq_tmap_style <- function(layer_or_reg, name = NULL, field = NULL) {
  sty <- gq_style(layer_or_reg, name, field = field)

  # The type check comes FIRST, ahead of the classification branch. It used to
  # come second, so a classified layer of an unhandled type never reached the
  # switch: tmap_classified() has a branch per geometry and no default, so it
  # returned an empty list. do.call(tm_polygons, list()) then draws tmap's
  # defaults, which is a map that looks fine and is not the registry's.
  #
  # Unreachable until #64 put the first raster in reg_main.json, and that is the
  # point -- the hole was invisible for as long as nothing exercised it.
  if (!sty$type %in% c("polygon", "line", "point")) {
    stop("Unknown layer type: ", sty$type)
  }

  if (!is.null(sty$classification)) {
    return(tmap_classified(sty))
  }

  switch(sty$type,
    polygon = tmap_polygon_args(sty),
    line = tmap_line_args(sty),
    point = tmap_point_args(sty)
  )
}


#' Get classification info for tmap scale functions
#'
#' For categorized/graduated layers, returns the field, color values, and
#' labels suitable for tmap's `tm_scale_categorical()`.
#'
#' @inheritParams gq_style
#' @return A named list with `field`, `values` (named color vector), `labels`
#'   (named by class key, like `values`), `widths` (named line-width vector for
#'   line layers; `NULL` otherwise), `dashes` (named raw-QGIS-dash vector for
#'   classes that are dashed; `NULL` otherwise), and `opacities` (named, `NA`
#'   meaning opaque; `NULL` when no class carries an opacity). The dash value is the raw QGIS encoding (named style like
#'   "dash dot", or custom pattern like "0.66;2") — consumers map it to their
#'   backend's line type (e.g. tmap `lty = "dashed"` for non-NA entries).
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
#' cls$widths
#' cls$dashes
#' cls$opacities
#'
#' # Object-based (backwards compatible)
#' cls <- gq_tmap_classes(reg$layers$road)
#'
#' @export
gq_tmap_classes <- function(layer_or_reg, name = NULL, field = NULL) {
  sty <- gq_style(layer_or_reg, name, field = field)
  cls <- sty$classification
  if (is.null(cls)) stop("Layer does not have classification")
  list(field = cls$field, values = cls$values, labels = cls$labels,
       widths = cls$widths, dashes = cls$dashes, opacities = cls$opacities)
}


# --- tmap-specific internal helpers -----------------------------------------

#' Build the categorical scale shared by all three geometry types
#'
#' `tm_scale_categorical()` matches `values` by **name** but `labels` by
#' **position**, and derives its levels from the data. Supplying only
#' `values` + `labels` therefore breaks the moment the data carries a subset
#' of the registry's classes: tmap takes `labels[seq_along(levels)]`
#' regardless of *which* classes are present, so a resource road rendered
#' labelled "Freeway" (#53).
#'
#' Passing `levels` from the same ordered vector the labels came from makes the
#' alignment structural — the two cannot drift, whatever the data holds. That is
#' why this is a fix rather than an argument callers must remember to pass.
#' `levels.drop` then keeps classes the data lacks out of a shown legend.
#' @noRd
tmap_scale_classified <- function(cls) {
  tmap::tm_scale_categorical(
    values = cls$values, labels = cls$labels,
    levels = names(cls$values), levels.drop = TRUE
  )
}

#' Map a non-colour aesthetic across the same classes as the colour scale
#'
#' Colour has always been per-class; width, dash and radius were collapsed to
#' the *first registry class* and emitted as a scalar (#36). For the
#' `mapping_code` layers that is severe: habitat use drives width and barrier
#' status drives colour, so half the layer rendered correctly and half silently
#' did not.
#'
#' `levels` comes from `names(cls$values)` so every axis is keyed on the one
#' ordered class vector — the same property that makes the colour scale correct.
#' @noRd
tmap_scale_axis <- function(cls, v) {
  tmap::tm_scale_categorical(
    values = unname(v), levels = names(cls$values), levels.drop = TRUE
  )
}

#' Per-class `lty`, with undashed classes made explicit
#'
#' [dash_to_lty()] returns `NULL` for an undashed class, which is right for a
#' scalar and wrong for a vector: in #52 the `NULL`s collapsed to
#' `c(NA, ..., "dashed")` and tmap rejected the whole vector at *draw* time,
#' invisible to every structure-inspecting test. `NA` means "solid" here, so say
#' so rather than leaving a hole.
#' @noRd
class_ltys <- function(dashes) {
  vapply(dashes, function(d) dash_to_lty(d) %||% "solid", character(1))
}

#' Per-class opacity as tmap arguments under the given aesthetic name
#'
#' Returns an empty list when no class carries an opacity, a scalar when every
#' class shares one, and the field plus a categorical scale otherwise. `NA` is
#' read as 1, not as a gap: the extractor records opacity only below 1, so
#' `roads_dra` and `streams_all` carry it on some classes by design (#71).
#' @noRd
tmap_alpha_args <- function(cls, aes) {
  op <- cls$opacities
  if (is.null(op)) return(list())
  op[is.na(op)] <- 1
  out <- if (length(unique(op)) == 1L) {
    list(unname(op[1]))
  } else {
    list(cls$field, tmap_scale_axis(cls, op), tmap::tm_legend(show = FALSE))
  }
  names(out) <- paste0(aes, c("", ".scale", ".legend"))[seq_along(out)]
  out
}

#' One reading of a per-class numeric axis, for the map and the legend alike
#'
#' A width or radius the registry gives only some classes is drawn at one
#' value for all of them, since a half-mapped axis would invent a size for the
#' gaps. That value is the first class that has one: taking `v[1]` gave `NA`
#' when the first class was the blank one, and tmap then drew every class at
#' its default. Returned at full length, so the legend can index it by class
#' and draw each key at the width the map drew, rather than at 0 for a blank.
#' `NULL` when no class has a value.
#' @noRd
class_axis <- function(v) {
  if (is.null(v) || all(is.na(v))) return(NULL)
  if (!anyNA(v)) return(v)
  v[] <- v[!is.na(v)][1]
  v
}

#' @noRd
tmap_classified <- function(sty) {
  cls <- sty$classification
  args <- list()

  # A numeric axis is only mapped when every class has a value. A half-mapped
  # width silently invents a size for the gaps; a documented scalar does not.
  # A CSV-authored line leaving stroke_width blank on some rows produces a
  # partial vector, so this is reachable.
  complete <- function(v) !is.null(v) && !anyNA(v)

  if (sty$type == "polygon") {
    args$fill <- cls$field
    args$fill.scale <- tmap_scale_classified(cls)
    args$fill.legend <- tmap::tm_legend(show = FALSE)
    args <- c(args, tmap_alpha_args(cls, "fill_alpha"))
  } else if (sty$type == "line") {
    args$col <- cls$field
    args$col.scale <- tmap_scale_classified(cls)
    args$col.legend <- tmap::tm_legend(show = FALSE)
    if (complete(cls$widths)) {
      args$lwd <- cls$field
      args$lwd.scale <- tmap_scale_axis(cls, cls$widths)
      args$lwd.legend <- tmap::tm_legend(show = FALSE)
    } else if (!is.null(class_axis(cls$widths))) {
      args$lwd <- unname(class_axis(cls$widths)[1])
    }
    if (!is.null(cls$dashes)) {
      args$lty <- cls$field
      args$lty.scale <- tmap_scale_axis(cls, class_ltys(cls$dashes))
      args$lty.legend <- tmap::tm_legend(show = FALSE)
    }
    args <- c(args, tmap_alpha_args(cls, "col_alpha"))
  } else if (sty$type == "point") {
    args$fill <- cls$field
    args$fill.scale <- tmap_scale_classified(cls)
    args$fill.legend <- tmap::tm_legend(show = FALSE)
    if (complete(cls$radii)) {
      args$size <- cls$field
      args$size.scale <- tmap_scale_axis(cls, gq_symbol_size(cls$radii, "tmap"))
      args$size.legend <- tmap::tm_legend(show = FALSE)
    } else if (!is.null(class_axis(cls$radii))) {
      args$size <- gq_symbol_size(unname(class_axis(cls$radii)[1]), "tmap")
    }
    args <- c(args, tmap_alpha_args(cls, "fill_alpha"))
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

#' Map a raw QGIS dash value to a valid tmap/grid `lty`
#'
#' The registry stores the raw QGIS dash (named style like "dash dot", or a
#' custom millimetre pattern like "0.66;2"). R's `lty` only accepts a fixed set
#' of named types or hex digits, not a mm pattern, so anything that isn't
#' already a valid named `lty` collapses to "dashed". `NULL`/`NA`/"no"/"solid"
#' return `NULL` (no dash). The raw pattern stays in the registry for backends
#' that can use it (mapgl's `line-dasharray`).
#' @noRd
dash_to_lty <- function(dash) {
  if (is.null(dash) || is.na(dash) || dash %in% c("no", "solid")) return(NULL)
  valid_lty <- c("blank", "solid", "dashed", "dotted", "dotdash",
                 "longdash", "twodash")
  if (dash %in% valid_lty) return(dash)
  "dashed"
}

#' @noRd
tmap_line_args <- function(sty) {
  args <- list()
  if (!is.null(sty$stroke)) {
    args$col <- sty$stroke$color
    if (!is.null(sty$stroke$width)) args$lwd <- sty$stroke$width
    if (!is.null(sty$stroke$opacity)) args$col_alpha <- sty$stroke$opacity
    lty <- dash_to_lty(sty$stroke$dash)
    if (!is.null(lty)) args$lty <- lty
  }
  args
}

#' @noRd
tmap_point_args <- function(sty) {
  args <- list()
  if (!is.null(sty$mark)) {
    args$fill <- sty$mark$color
    if (!is.null(sty$mark$radius)) {
      # Shape is load-bearing here, not decoration: base R normalises pch by
      # area and QGIS by extent, so the same millimetres need a different size
      # for a square than for a circle.
      args$size <- gq_symbol_size(sty$mark$radius, "tmap",
                                  shape = sty$mark$shape)
    }
    shape <- gq_symbol_shape(sty$mark$shape, "tmap")
    if (!is.null(shape)) {
      args$shape <- shape
      # pch 8 (star) is stroked, never filled. Setting only `fill` would hand
      # the layer tmap's default outline and silently drop the registry colour.
      if (!gq_symbol_fillable(sty$mark$shape)) args$col <- sty$mark$color
    }
  }
  if (!is.null(sty$fill)) {
    args$fill <- sty$fill$color
    if (!is.null(sty$fill$opacity)) args$fill_alpha <- sty$fill$opacity
  }
  args
}
