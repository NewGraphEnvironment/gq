# --- basemap blending ---------------------------------------------------------

#' Multiply a basemap by a relief layer
#'
#' Shades a flat raster basemap with terrain so relief reads as backdrop rather
#' than as subject. Both inputs are `terra` rasters; the relief is resampled onto
#' the basemap grid, reduced to one band if it has several, and multiplied
#' through.
#'
#' @section Two operators, deliberately:
#'
#' `"gamma"` raises the normalised relief to a power before multiplying:
#' `base * relief^gamma`. Lower gamma means lighter shading. This suits a relief
#' *tile service*, whose values already span the full range.
#'
#' `"weight"` pulls the relief toward 1 linearly: `base * (1 - w * (1 - relief))`.
#' `w` is the maximum darkening, so `w = 0.35` can never remove more than 35% of
#' the basemap's brightness. This suits a hillshade derived from a DEM, which
#' can be far more contrasty than a tile service and at full strength turns the
#' map into a greyscale DEM with lines on it.
#'
#' Both are in use across the reporting repos, and the two were believed to be
#' the same operator with different inputs — one implementation says so in its
#' own documentation. They are not: at the same nominal strength they produce
#' visibly different maps. Naming them is the point.
#'
#' @param base A `SpatRaster` basemap, values in 0-255. RGB is fine.
#' @param relief A `SpatRaster` relief or hillshade. Multi-band input is
#'   averaged to one band. Values in 0-255, or 0-1 — see `relief_max`.
#' @param method `"gamma"` or `"weight"`. See details.
#' @param gamma Exponent for `method = "gamma"`. Lower is lighter.
#' @param weight Maximum darkening for `method = "weight"`, in `[0, 1]`.
#' @param relief_max Value corresponding to full brightness in `relief`.
#'   `terra::shade()` returns 0-1; a tile service returns 0-255. Defaults to
#'   detecting which from the data.
#' @param as_stars Convert the result for `tmap::tm_rgb()`, which takes a
#'   `stars` object rather than a `SpatRaster`.
#'
#' @return A `SpatRaster`, or a `stars` object when `as_stars = TRUE`.
#'
#' @examples
#' if (requireNamespace("terra", quietly = TRUE)) {
#'   base <- terra::rast(nrows = 4, ncols = 4, vals = 200)
#'   relief <- terra::rast(nrows = 4, ncols = 4, vals = 128)
#'
#'   # gamma barely darkens a mid-grey relief
#'   round(terra::values(gq_basemap_blend(base, relief, as_stars = FALSE))[1])
#'
#'   # weight caps how much can ever be removed
#'   round(terra::values(
#'     gq_basemap_blend(base, relief, method = "weight", as_stars = FALSE)
#'   )[1])
#' }
#'
#' @export
gq_basemap_blend <- function(base, relief, method = c("gamma", "weight"),
                             gamma = 0.5, weight = 0.35, relief_max = NULL,
                             as_stars = TRUE) {
  if (!requireNamespace("terra", quietly = TRUE)) stop("terra is required")
  method <- match.arg(method)
  if (as_stars && !requireNamespace("stars", quietly = TRUE)) {
    stop("stars is required when as_stars = TRUE")
  }
  if (!is.numeric(weight) || length(weight) != 1L || is.na(weight) ||
        weight < 0 || weight > 1) {
    stop("`weight` must be a single number in [0, 1]", call. = FALSE)
  }
  if (!is.numeric(gamma) || length(gamma) != 1L || is.na(gamma) || gamma <= 0) {
    stop("`gamma` must be a single positive number", call. = FALSE)
  }

  out <- blend_multiply(base, relief, method = method, gamma = gamma,
                        weight = weight, relief_max = relief_max)
  if (as_stars) stars::st_as_stars(out) else out
}


#' The blend arithmetic, with no fetching
#'
#' Kept separate from anything that touches the network so it can be tested
#' against a synthetic raster. Every bug worth catching here is arithmetic.
#' @noRd
blend_multiply <- function(base, relief, method, gamma, weight,
                           relief_max = NULL) {
  if (terra::nlyr(relief) > 1L) relief <- terra::mean(relief)
  # compareGeom(), not dim(): two rasters can share nrow/ncol and have unrelated
  # extents or CRSs, in which case skipping the resample makes the multiply fail
  # from deep inside terra with a message about neither of these rasters.
  if (!isTRUE(terra::compareGeom(relief, base, stopOnError = FALSE))) {
    relief <- terra::resample(relief, base, method = "bilinear")
  }

  # terra::shade() returns 0-1 while a tile service returns 0-255, and treating
  # one as the other either blackens the map or does nothing at all. Detect
  # rather than assume, but let the caller override for a raster whose observed
  # range does not reach its nominal maximum.
  if (is.null(relief_max)) {
    rng <- terra::minmax(relief)
    top <- suppressWarnings(max(rng, na.rm = TRUE))
    # An all-NA relief gives -Inf here, which would silently pick the 0-1 scale
    # and hand back an all-NA basemap -- a blank map with no error. A relief
    # layer that is entirely missing is a broken input, not a shading choice.
    if (!is.finite(top)) {
      stop("`relief` has no finite values", call. = FALSE)
    }
    relief_max <- if (top > 1) 255 else 1
  }

  r <- terra::clamp(relief / relief_max, 0, 1)
  shade <- switch(method,
    gamma  = r ^ gamma,
    weight = 1 - weight * (1 - r)
  )
  terra::clamp((base / 255) * shade * 255, lower = 0, upper = 255)
}


#' Fetch basemap tiles for a bounding box
#'
#' Thin wrapper over [maptiles::get_tiles()] that adds the padding a projected
#' map needs and reprojects the result.
#'
#' Tiles arrive in Web Mercator. Reprojecting them to a projected CRS turns the
#' covered area into a slightly rotated quadrilateral, so requesting exactly the
#' frame leaves empty white wedges in the corners. `pad` requests a larger area
#' so the rotated coverage still spans the frame. The rotation is a fixed
#' angular effect, so it is proportionally *more* significant at small extents.
#'
#' @param bbox A `bbox`. Reprojected to EPSG:4326 for the request.
#' @param provider A `maptiles` provider name.
#' @param zoom Tile zoom level.
#' @param pad Fraction of each bbox dimension to expand by before requesting.
#'   Applied to width and height independently.
#' @param crs CRS to reproject tiles into. `NULL` keeps Web Mercator.
#'
#' @return A `SpatRaster`, or `NULL` if the request failed.
#'
#' @examplesIf interactive() && requireNamespace("maptiles", quietly = TRUE)
#' bb <- sf::st_bbox(
#'   c(xmin = 1e6, ymin = 9e5, xmax = 1.02e6, ymax = 9.2e5),
#'   crs = 3005
#' )
#' tiles <- gq_basemap_tiles(bb, zoom = 11)
#'
#' @export
gq_basemap_tiles <- function(bbox, provider = "CartoDB.PositronNoLabels",
                             zoom = 12, pad = 0.10, crs = 3005) {
  if (!requireNamespace("maptiles", quietly = TRUE)) stop("maptiles is required")
  if (!requireNamespace("terra", quietly = TRUE)) stop("terra is required")
  if (!requireNamespace("sf", quietly = TRUE)) stop("sf is required")

  box <- if (inherits(bbox, "sfc")) bbox else sf::st_as_sfc(bbox)
  bb <- sf::st_bbox(box)

  # Expand the bbox arithmetically rather than with st_buffer(). Under s2 -- on
  # by default, and gq does not turn it off -- a buffer distance on a lon/lat
  # geometry is read as METRES, so a 0.1-degree pad widens the box by about
  # 0.04 degrees instead of 0.2. Measured on a 1-degree box: 1.041 out, 1.2
  # expected. Padding the coordinates has no such ambiguity in either CRS.
  dx <- (bb[["xmax"]] - bb[["xmin"]]) * pad
  dy <- (bb[["ymax"]] - bb[["ymin"]]) * pad
  bb[["xmin"]] <- bb[["xmin"]] - dx
  bb[["xmax"]] <- bb[["xmax"]] + dx
  bb[["ymin"]] <- bb[["ymin"]] - dy
  bb[["ymax"]] <- bb[["ymax"]] + dy
  padded <- sf::st_as_sfc(bb)

  tiles <- try(
    maptiles::get_tiles(sf::st_transform(padded, 4326), provider = provider,
                        zoom = zoom, crop = TRUE),
    silent = TRUE
  )
  # A tile fetch is a network call in the middle of a map build. Returning NULL
  # lets the caller draw an unshaded map rather than lose the whole figure --
  # the same reason gq_bbox_clip() returns NULL.
  if (inherits(tiles, "try-error")) {
    warning("tile fetch failed for provider '", provider, "'", call. = FALSE)
    return(NULL)
  }
  if (is.null(crs)) return(tiles)
  # WKT rather than paste0("EPSG:", $epsg): a CRS with no authority code gives
  # NA there, and "EPSG:NA" reaches terra as a parse error.
  terra::project(tiles, sf::st_crs(crs)$wkt, method = "bilinear")
}
