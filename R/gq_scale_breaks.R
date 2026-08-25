#' Scale bar breaks appropriate to a map extent
#'
#' Returns breaks in kilometres, rounded to a 1/2/5 sequence so the bar reads
#' cleanly at any extent.
#'
#' The whole bar is sized to at most `share` of the frame width — *not* `share`
#' per interval. Sizing per interval overruns the frame, at which point tmap
#' reports "not all scale bar breaks could be plotted" and then silently drops
#' every label but the last, which looks like a styling problem rather than a
#' sizing one.
#'
#' `share` is a **bound**, not a target: the step is the largest 1/2/5 value that
#' fits, so the bar is always at or under it. Rounding to the *nearest* nice
#' value instead overruns by up to 1.39x, which is the failure the bound exists
#' to prevent.
#'
#' @param bbox A `bbox` in a projected CRS with metre units. A geographic bbox
#'   has degree spans, so the returned breaks would not be kilometres.
#' @param n Number of intervals.
#' @param share Fraction of the frame width the whole bar should occupy.
#'
#' @return A numeric vector of length `n + 1`, starting at 0, in kilometres.
#'
#' @examplesIf requireNamespace("sf", quietly = TRUE)
#' bb <- sf::st_bbox(
#'   c(xmin = 1e6, ymin = 9e5, xmax = 1.1e6, ymax = 1e6),
#'   crs = 3005
#' )
#' gq_scale_breaks(bb)
#'
#' # a wider extent steps up to the next round number
#' wide <- bb
#' wide[["xmax"]] <- wide[["xmin"]] + 400000
#' gq_scale_breaks(wide)
#'
#' @export
gq_scale_breaks <- function(bbox, n = 3, share = 0.35) {
  if (!inherits(bbox, "bbox")) {
    if (!requireNamespace("sf", quietly = TRUE)) stop("sf is required", call. = FALSE)
    bbox <- sf::st_bbox(bbox)
  }
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1) {
    stop("`n` must be a single positive number", call. = FALSE)
  }
  if (!is.numeric(share) || length(share) != 1L || is.na(share) ||
        share <= 0 || share > 1) {
    stop("`share` must be a single number in (0, 1]", call. = FALSE)
  }

  # A geographic bbox has degree spans, so the arithmetic below would return
  # breaks of 0.0001 "km" -- 10 cm -- in the shape of a legitimate answer, with
  # no error anywhere. There is no correct interpretation of that, and a scale
  # bar reading "0 0.0001 0.0002" on a printed map is a defect that ships.
  if (isTRUE(sf::st_is_longlat(bbox))) {
    stop("`bbox` must be projected with metre units; got a geographic CRS. ",
         "Transform it first, e.g. sf::st_transform(x, 3005).", call. = FALSE)
  }

  span_km <- (bbox[["xmax"]] - bbox[["xmin"]]) / 1000
  if (!isTRUE(span_km > 0)) {
    stop("bbox has zero or undefined width", call. = FALSE)
  }

  raw <- span_km * share / n
  mag <- 10 ^ floor(log10(raw))
  nice <- c(1, 2, 5, 10)
  # Largest nice value AT OR BELOW raw, so share bounds the bar. which.min() on
  # the distance rounds up as often as down and made share a target.
  fits <- nice[nice <= raw / mag]
  step <- if (length(fits)) max(fits) * mag else 5 * (mag / 10)
  seq(0, step * n, by = step)
}
