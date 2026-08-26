# Unit conversion for point symbols.
#
# The registry stores QGIS marker sizes in millimetres. Every backend needs them
# in its own units, and before #16 each guessed: tmap divided by 3, mapgl
# divided by nothing. They disagreed with each other by 3x and neither matched
# QGIS.
#
# The first draft of this file got the tmap constant wrong in an instructive
# way, so the derivation is spelled out below rather than left as a decimal.

# tmap draws symbols with grid::pointsGrob(size = unit(<size>, "lines")), and
# one "line" is grid's default fontsize x lineheight:
#
#   12 pt * 1.2 = 14.4 pt = 0.2 in = 5.08 mm
#
# 5.08 is therefore a TYPOGRAPHIC unit, not the size of any drawn symbol. R's
# graphics engine then multiplies it by a per-pch factor (GESymbol() in
# src/main/engine.c uses RADIUS 0.375 for circles, hence 0.75 of the nominal
# box), and those factors differ per shape because base R normalises pch 21-25
# by area rather than by extent.
#
# So the millimetres of ink per tmap size unit are per-shape. Measured off the
# rendered SVG primitives -- the drawn geometry, not the value handed to the
# grob:
#
#   pch 21 circle    diameter 0.7500 * 14.4 pt = 3.8100 mm
#   pch 22 square    side     0.6646 * 14.4 pt = 3.3761 mm
#   pch 24 triangle  base     1.0097 * 14.4 pt = 5.1294 mm
#   pch  8 star      extent   1.0611 * 14.4 pt = 5.3904 mm
#
# QGIS is extent-normalised the other way: every point QML in inst/styles/
# carries `scale_method = "diameter"` and renders the marker into a size x size
# box, so a 2 mm square is 2 mm on a side. A single divisor therefore cannot
# make circle, square and triangle all land at their registry millimetres --
# which is why this takes the shape as an argument.
tmap_pt <- 12 * 1.2                      # one "line", in points
tmap_mm_per_size <- c(
  circle   = 0.7500 * tmap_pt / 72 * 25.4,
  square   = 0.6646 * tmap_pt / 72 * 25.4,
  triangle = 1.0097 * tmap_pt / 72 * 25.4,
  star     = 1.0611 * tmap_pt / 72 * 25.4
)

# CSS pixels per millimetre. 96 px to the inch by definition, 25.4 mm to the
# inch. Not measured, because it is a definition.
px_per_mm <- 96 / 25.4

# Base R's fillable symbols are pch 21-25 -- circle, square, diamond,
# triangle-up, triangle-down. There is no filled star, so `star` maps to 8,
# which is drawn with strokes only and ignores `fill`. Callers need to know so
# they can set `col` instead of silently losing the colour.
tmap_pch <- c(circle = 21L, square = 22L, triangle = 24L, star = 8L)
tmap_pch_fillable <- c(circle = TRUE, square = TRUE, triangle = TRUE,
                       star = FALSE)


#' Convert a registry symbol size to a rendering target's units
#'
#' The registry's `radius` field is a **diameter**, in millimetres. The name is a
#' misnomer inherited at extraction: [gq_qgs_extract()] reads the QGIS
#' `SimpleMarker` option literally named `size` — the marker's overall extent —
#' and stores it under `radius`. Every point QML in the corpus confirms it by
#' carrying `scale_method = "diameter"` alongside.
#'
#' Each target measures symbols differently:
#'
#' \describe{
#'   \item{`"tmap"`}{Depends on `shape`. tmap sizes symbols in grid "lines"
#'     (5.08 mm), but R's graphics engine then applies a per-`pch` factor, and
#'     base R normalises those by *area* where QGIS normalises by *extent*. A
#'     circle draws 3.81 mm of ink per size unit, a square 3.38, a triangle
#'     5.13. Passing the wrong shape leaves the symbol 11–35% out.}
#'   \item{`"mapgl"`}{MapLibre's `circle-radius` is a true **radius**, in CSS
#'     pixels — so the value is halved and converted at 96 px per inch. `shape`
#'     does not apply: a MapLibre `circle` layer has only circles.}
#' }
#'
#' A constant `circle-radius` is deliberate for mapgl, not a simplification: it
#' holds a fixed screen size at every zoom, which is exactly QGIS marker
#' semantics. An interpolated expression would be a departure from the registry,
#' not a correction to it.
#'
#' @param radius Registry size in millimetres. May be a named vector (a
#'   classified layer's per-class sizes), `NA`, or `NULL` for a layer that
#'   defines no mark at all. Names are preserved, because
#'   `tm_scale_categorical()` matches values by name.
#' @param target One of `"tmap"` or `"mapgl"`.
#' @param shape Registry shape, for `target = "tmap"`. Defaults to `"circle"`,
#'   which is what tmap itself draws when no shape is given.
#' @param scale Uniform multiplier applied after conversion. The knob for a
#'   dense map that needs every symbol smaller — one number applied once,
#'   rather than a hand-tuned value per layer, which is what this function
#'   exists to replace.
#'
#' @return A numeric vector in the target's units, or `NULL` if `radius` is
#'   `NULL`.
#'
#' @examples
#' # A 3 mm circular marker, drawn as 3 mm of ink
#' gq_symbol_size(3, "tmap")
#'
#' # The same millimetres as a square need a different size, because base R
#' # normalises pch by area and QGIS by extent
#' gq_symbol_size(3, "tmap", shape = "square")
#'
#' gq_symbol_size(3, "mapgl")           # circle-radius in CSS pixels
#' gq_symbol_size(3, "tmap", scale = 0.5)
#'
#' # Per-class sizes keep their names
#' gq_symbol_size(c(BARRIER = 3, PASSABLE = 2), "tmap")
#'
#' @seealso [gq_symbol_shape()]
#' @export
gq_symbol_size <- function(radius, target = c("tmap", "mapgl"),
                           shape = "circle", scale = 1) {
  # Not match.arg(): its message is "'arg' should be one of ...", which names
  # the formal of match.arg rather than of this function, so a caller reading it
  # cannot tell which argument they got wrong.
  target <- target[1]
  if (!target %in% c("tmap", "mapgl")) {
    stop("unsupported `target`: '", target, "'. Use \"tmap\" or \"mapgl\".",
         call. = FALSE)
  }
  if (is.null(radius)) return(NULL)

  if (target == "mapgl") return(radius / 2 * px_per_mm * scale)

  shape <- if (is.null(shape) || is.na(shape)) "circle" else shape
  if (!shape %in% names(tmap_mm_per_size)) {
    warning("unknown symbol shape '", shape, "'; sizing it as a circle",
            call. = FALSE)
    shape <- "circle"
  }
  radius / tmap_mm_per_size[[shape]] * scale
}


#' Translate a registry symbol shape to a rendering target
#'
#' The registry carries a `shape` on every mark — `circle`, `square`, `star` and
#' `triangle` are the complete vocabulary across all three registry files. Until
#' #16 no renderer consumed it, so maps hardcoded their own marker codes.
#'
#' `star` maps to `pch = 8`, which draws a star with **strokes only** and ignores
#' `fill` entirely. R has no filled star — its fillable symbols (21–25) are
#' circle, square, diamond, triangle-up and triangle-down. Substituting a filled
#' circle would silently discard the distinction that made the layer a star in
#' QGIS, so the unfillable code is returned and callers are expected to set `col`
#' rather than `fill`; [gq_tmap_style()] does this. Use
#' `gq_symbol_fillable()` to ask.
#'
#' `mapgl` returns `NULL` for every shape. A MapLibre `circle` layer has no shape
#' concept at all; anything else requires a `symbol` layer with an icon sprite,
#' which the registry has no source data for. `NULL` says "not expressible here"
#' rather than handing back a `pch` number the renderer cannot read.
#'
#' @param shape Registry shape string, or `NULL`.
#' @param target One of `"tmap"` or `"mapgl"`.
#'
#' @return For `"tmap"`, an integer `pch`. For `"mapgl"`, `NULL`. `NULL` in
#'   gives `NULL` out.
#'
#' @examples
#' gq_symbol_shape("circle", "tmap")
#' gq_symbol_shape("triangle", "tmap")
#' gq_symbol_shape("star", "tmap")       # 8 -- stroked, never filled
#' gq_symbol_fillable("star")            # FALSE
#'
#' @seealso [gq_symbol_size()]
#' @export
gq_symbol_shape <- function(shape, target = c("tmap", "mapgl")) {
  target <- target[1]
  if (!target %in% c("tmap", "mapgl")) {
    stop("unsupported `target`: '", target, "'. Use \"tmap\" or \"mapgl\".",
         call. = FALSE)
  }
  if (is.null(shape) || is.na(shape)) return(NULL)
  if (target == "mapgl") return(NULL)

  # `tmap_pch[[shape]]` throws subscriptOutOfBounds on a miss rather than
  # returning NULL, so a `%||%` fallback could never fire. Test membership.
  if (!shape %in% names(tmap_pch)) {
    warning("unknown symbol shape '", shape, "'; leaving it to the renderer",
            call. = FALSE)
    return(NULL)
  }
  tmap_pch[[shape]]
}


#' Does a registry shape accept a fill colour?
#'
#' `star` does not: R has no filled star, so it renders as `pch = 8`, which is
#' stroked only. A caller that sets `fill` and not `col` on a star gets tmap's
#' default outline instead of the registry colour — the layer silently loses its
#' styling. [gq_tmap_style()] uses this to decide which argument to set.
#'
#' @param shape Registry shape string, or `NULL`.
#' @return `TRUE` or `FALSE`. Unknown or absent shapes return `TRUE`, matching
#'   tmap's default circle.
#'
#' @examples
#' gq_symbol_fillable("circle")
#' gq_symbol_fillable("star")
#'
#' @seealso [gq_symbol_shape()]
#' @export
gq_symbol_fillable <- function(shape) {
  if (is.null(shape) || is.na(shape)) return(TRUE)
  if (!shape %in% names(tmap_pch_fillable)) return(TRUE)
  tmap_pch_fillable[[shape]]
}
