# --- bbox helpers -------------------------------------------------------------

#' Pad a bounding box to a target aspect ratio
#'
#' A map whose bbox does not match its canvas aspect ratio renders with white
#' bands along two edges — the most common cause of dead space in a saved map.
#' This pads the *shorter* dimension until the box matches the canvas, then adds
#' a small margin so features never touch the frame.
#'
#' Padding is symmetric, so the original extent stays centred.
#'
#' # Geographic versus projected input
#'
#' In a geographic CRS a degree of longitude is shorter than a degree of
#' latitude by `cos(latitude)`, so the ratio of coordinate spans is not the
#' ratio of ground distances and the correction is required. In a projected CRS
#' the coordinates are already linear and applying it would skew the result.
#'
#' The branch is taken from the CRS rather than offered as an argument,
#' because the two implementations this replaces each hardcoded one answer and
#' neither knew the other case existed. A bbox with an unknown CRS is treated as
#' projected — the coordinates are all that is known, so use them as given.
#'
#' @param x An `sf`/`sfc` object or a `bbox`.
#' @param asp Target width/height, i.e. `fig.width / fig.height`.
#' @param margin Fraction of each dimension added on all sides so features do
#'   not touch the frame. Applied after the aspect padding, so it does not
#'   change the ratio.
#'
#' @return A `bbox` with the same CRS as `x`.
#'
#' @examples
#' bb <- sf::st_bbox(
#'   c(xmin = 1e6, ymin = 9e5, xmax = 1.1e6, ymax = 1e6),
#'   crs = 3005
#' )
#' out <- gq_bbox_aspect(bb, asp = 7 / 9)
#'
#' # the padded box carries the ratio that was asked for
#' round(unname((out["xmax"] - out["xmin"]) / (out["ymax"] - out["ymin"])), 4)
#'
#' @export
gq_bbox_aspect <- function(x, asp, margin = 0.02) {
  if (!requireNamespace("sf", quietly = TRUE)) stop("sf is required")
  if (!is.numeric(asp) || length(asp) != 1L || is.na(asp) || asp <= 0) {
    stop("`asp` must be a single positive number", call. = FALSE)
  }
  if (!is.numeric(margin) || length(margin) != 1L || is.na(margin) ||
        margin < 0) {
    stop("`margin` must be a single non-negative number", call. = FALSE)
  }

  bb <- if (inherits(x, "bbox")) x else sf::st_bbox(x)

  dx <- bb[["xmax"]] - bb[["xmin"]]
  dy <- bb[["ymax"]] - bb[["ymin"]]
  if (!isTRUE(dx > 0) || !isTRUE(dy > 0)) {
    stop("bbox has zero or undefined extent", call. = FALSE)
  }

  # isTRUE(): st_is_longlat() returns NA on an unknown CRS, and NA must fall to
  # the projected branch rather than propagating into the arithmetic.
  k <- 1
  if (isTRUE(sf::st_is_longlat(bb))) {
    k <- cos(((bb[["ymin"]] + bb[["ymax"]]) / 2) * pi / 180)
  }

  # Compare ground spans, pad in coordinate units. Only the x span is scaled,
  # so dividing the correction back out converts the pad to degrees.
  if ((dx * k) / dy > asp) {
    pad <- (((dx * k) / asp) - dy) / 2
    bb[["ymin"]] <- bb[["ymin"]] - pad
    bb[["ymax"]] <- bb[["ymax"]] + pad
  } else {
    pad <- (((dy * asp) / k) - dx) / 2
    bb[["xmin"]] <- bb[["xmin"]] - pad
    bb[["xmax"]] <- bb[["xmax"]] + pad
  }

  mx <- (bb[["xmax"]] - bb[["xmin"]]) * margin
  my <- (bb[["ymax"]] - bb[["ymin"]]) * margin
  bb[["xmin"]] <- bb[["xmin"]] - mx
  bb[["xmax"]] <- bb[["xmax"]] + mx
  bb[["ymin"]] <- bb[["ymin"]] - my
  bb[["ymax"]] <- bb[["ymax"]] + my
  bb
}


#' Restrict features to a bounding box, returning NULL when nothing is left
#'
#' `tmap::tm_shape()` errors with "subscript out of bounds" on an empty geometry
#' set rather than skipping it, so a map assembled from optional layers has to
#' test each one. Returning `NULL` rather than a zero-row object lets the caller
#' write `if (!is.null(x))` once instead of checking `nrow()` at every use.
#'
#' # Selecting versus cutting
#'
#' `crop = FALSE` (the default) keeps whole features that touch the box, via
#' [sf::st_filter()]. `crop = TRUE` truncates geometries at the boundary, via
#' [sf::st_crop()].
#'
#' These are genuinely different maps: a stream leaving the frame is drawn to
#' its end under the default and stops at the edge under `crop = TRUE`. Both
#' spellings exist in the reporting repos this was extracted from, under names
#' close enough to be mistaken for each other, so the distinction is an argument
#' here rather than two functions a caller might pick between by accident.
#'
#' @param x An `sf` object, or `NULL`.
#' @param bbox A `bbox`, or anything [sf::st_as_sfc()] accepts.
#' @param crop Cut geometries at the boundary instead of selecting whole
#'   features that intersect it.
#'
#' @return An `sf` object with at least one row, or `NULL`.
#'
#' @examples
#' pts <- sf::st_as_sf(
#'   data.frame(x = c(0, 10), y = c(0, 10)),
#'   coords = c("x", "y"), crs = 3005
#' )
#' bb <- sf::st_bbox(c(xmin = -1, ymin = -1, xmax = 1, ymax = 1), crs = 3005)
#'
#' nrow(gq_bbox_clip(pts, bb))
#'
#' # nothing in range gives NULL, not a zero-row frame
#' far <- sf::st_bbox(c(xmin = 100, ymin = 100, xmax = 101, ymax = 101),
#'                    crs = 3005)
#' is.null(gq_bbox_clip(pts, far))
#'
#' @export
gq_bbox_clip <- function(x, bbox, crop = FALSE) {
  if (!requireNamespace("sf", quietly = TRUE)) stop("sf is required")
  if (is.null(x) || nrow(x) == 0L) {
    return(NULL)
  }

  box <- if (inherits(bbox, "sfc")) bbox else sf::st_as_sfc(bbox)
  out <- if (crop) suppressWarnings(sf::st_crop(x, box)) else sf::st_filter(x, box)
  if (nrow(out) == 0L) NULL else out
}
