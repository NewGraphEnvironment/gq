# Unit conversion for point symbols.
#
# The registry stores QGIS marker sizes in millimetres. Every backend needs them
# in its own units, and before #16 each guessed: tmap divided by 3, mapgl
# divided by nothing. They disagreed with each other by 3x and neither matched
# QGIS -- fiss_obstacles rendered its 2.0 mm marker at 3.39 mm.
#
# Both constants below are unit conversions, not calibrations. They are stated
# as named constants rather than inlined so that a reader meets a quantity with
# a source, not another bare divisor.

# Millimetres drawn per tmap size unit, at tmap's default `scale`.
#
# Measured rather than looked up -- tmap does not document it. A tm_symbols()
# drawn at size = 1 has a diameter of 5.08 mm (0.2 inch), linear in diameter and
# independent of both canvas dimensions and dpi. tests/testthat/test-gq_symbol.R
# asserts it, so a future tmap change names itself.
#
# `tmap_options(scale = )` multiplies this. gq does NOT compensate: a caller
# scaling a whole map expects the symbols to scale with the text.
tmap_mm_per_size <- 5.08

# CSS pixels per millimetre. 96 px to the inch by definition, 25.4 mm to the
# inch. Not measured because it is a definition.
px_per_mm <- 96 / 25.4


#' Convert a registry symbol size to a rendering target's units
#'
#' The registry's `radius` field is a **diameter**, in millimetres. The name is a
#' misnomer inherited at extraction: [gq_qgs_extract()] reads the QGIS
#' `SimpleMarker` option literally named `size` — the marker's overall extent —
#' and stores it under `radius`. Treating it as a true radius would draw every
#' symbol at twice its intended size.
#'
#' Each target measures symbols differently, so the conversion differs:
#'
#' \describe{
#'   \item{`"tmap"`}{Divides by 5.08, the millimetres tmap draws per size unit.
#'     A 3 mm QGIS marker lands on the page as 3 mm. tmap's `size` is also a
#'     diameter, so no halving is involved.}
#'   \item{`"mapgl"`}{MapLibre's `circle-radius` is a true **radius**, in CSS
#'     pixels — so the value is halved and then converted at 96 px per inch.}
#' }
#'
#' @param radius Registry size in millimetres. May be a named vector (a
#'   classified layer's per-class sizes), `NA`, or `NULL` for a layer that
#'   defines no mark at all. Names are preserved, because
#'   `tm_scale_categorical()` matches values by name.
#' @param target One of `"tmap"` or `"mapgl"`.
#' @param scale Uniform multiplier applied after conversion. The knob for a
#'   dense map that needs every symbol smaller — one number applied once,
#'   rather than a hand-tuned value per layer, which is what this function
#'   exists to replace.
#'
#' @return A numeric vector in the target's units, or `NULL` if `radius` is
#'   `NULL`.
#'
#' @examples
#' gq_symbol_size(3, "tmap")            # a 3 mm marker draws as 3 mm
#' gq_symbol_size(3, "mapgl")           # circle-radius in CSS pixels
#' gq_symbol_size(3, "tmap", scale = 0.5)
#'
#' # Per-class sizes keep their names
#' gq_symbol_size(c(BARRIER = 3, PASSABLE = 2), "tmap")
#'
#' @seealso [gq_symbol_shape()]
#' @export
gq_symbol_size <- function(radius, target = c("tmap", "mapgl"), scale = 1) {
  # Not match.arg(): its message is "'arg' should be one of ...", which names
  # the formal of match.arg rather than of this function, so a caller reading it
  # cannot tell which argument they got wrong.
  target <- target[1]
  if (!target %in% c("tmap", "mapgl")) {
    stop("unsupported `target`: '", target, "'. Use \"tmap\" or \"mapgl\".",
         call. = FALSE)
  }
  if (is.null(radius)) return(NULL)
  out <- switch(target,
    tmap = radius / tmap_mm_per_size,
    mapgl = radius / 2 * px_per_mm
  )
  out * scale
}


#' Translate a registry symbol shape to a rendering target
#'
#' The registry carries a `shape` on every mark — `circle`, `square`, `star` and
#' `triangle` are the complete vocabulary across all three registry files. Until
#' #16 no renderer consumed it, so maps hardcoded their own marker codes.
#'
#' `star` maps to `pch = 8`, which draws a star but takes **no fill** — R's
#' fillable symbols (21–25) are circle, square, diamond, triangle-up and
#' triangle-down, and none is a star. Substituting a filled circle would silently
#' discard the distinction that made the layer a star in QGIS, so the unfillable
#' code is returned instead and the caller sees an unfilled star.
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
#' gq_symbol_shape("star", "tmap")     # 8 -- drawn unfilled
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

  pch <- c(circle = 21L, square = 22L, triangle = 24L, star = 8L)
  # `pch[[shape]]` throws subscriptOutOfBounds on a miss rather than returning
  # NULL, so `%||%` never gets the chance to fire. Test membership instead.
  if (!shape %in% names(pch)) {
    warning("unknown symbol shape '", shape, "'; leaving it to the renderer",
            call. = FALSE)
    return(NULL)
  }
  pch[[shape]]
}
