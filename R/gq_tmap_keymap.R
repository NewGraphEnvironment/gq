# --- keymap inset -------------------------------------------------------------

#' Build an overview keymap and the viewport to place it in
#'
#' A keymap is a small inset showing where the mapped area sits in a wider
#' region. This returns the inset as its own `tmap` object plus a
#' [grid::viewport()] positioning it, so the caller prints the main map and then
#' the keymap over it.
#'
#' # Why a viewport rather than a component
#'
#' tmap has no inset-map component, so every implementation of this prints a
#' second `tmap` object into a viewport. The placement arithmetic is where they
#' diverge — each of the copies this replaces hardcodes a different pair of
#' centre coordinates, and a viewport's `x`/`y` are its *centre*, so the numbers
#' are not the margin they look like. `corner` and `margin` compute them, so
#' moving a keymap between corners does not mean re-deriving them by eye.
#'
#' @param aoi The area of interest — the thing being located.
#' @param context Wider context, drawn beneath. A province or basin outline.
#' @param reg A registry for the fill and stroke colours. Defaults to
#'   [gq_reg_main()]. The copies this replaces all hardcode hex here, including
#'   one that takes a registry argument and then does not use it.
#' @param aoi_layer,context_layer Registry keys supplying the two styles.
#' @param corner Which corner to place the inset in.
#' @param width,height Size as a fraction of the device.
#' @param margin Gap between the inset and the frame edge, as a fraction of the
#'   device. The four-corner convention wants this equal for every element.
#'
#' @return A list with `map` (a `tmap` object) and `viewport` (a
#'   [grid::viewport()]). Print `map` into `viewport` after the main map.
#'
#' @examplesIf requireNamespace("tmap", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)
#' aoi <- sf::st_as_sfc(sf::st_bbox(
#'   c(xmin = 1.0e6, ymin = 9.0e5, xmax = 1.1e6, ymax = 1.0e6), crs = 3005
#' ))
#' context <- sf::st_as_sfc(sf::st_bbox(
#'   c(xmin = 0.5e6, ymin = 5.0e5, xmax = 1.8e6, ymax = 1.4e6), crs = 3005
#' ))
#'
#' km <- gq_tmap_keymap(aoi, context)
#' class(km$map)
#'
#' # bottom-right by default, and the viewport centre reflects the margin
#' round(c(km$viewport$x, km$viewport$y), 3)
#'
#' @export
gq_tmap_keymap <- function(aoi, context, reg = NULL,
                           aoi_layer = "watershed_group_boundary",
                           context_layer = "provincial_park",
                           corner = c("bottomright", "bottomleft",
                                      "topright", "topleft"),
                           width = 0.25, height = 0.22, margin = 0.03) {
  if (!requireNamespace("tmap", quietly = TRUE)) stop("tmap is required")
  if (!requireNamespace("grid", quietly = TRUE)) stop("grid is required")
  corner <- match.arg(corner)

  if (is.null(reg)) reg <- gq_reg_main()
  ctx <- gq_style(reg, context_layer)
  area <- gq_style(reg, aoi_layer)

  map <- tmap::tm_shape(context) +
    tmap::tm_polygons(
      fill = ctx$fill$color, col = ctx$stroke$color, lwd = 0.5
    ) +
    tmap::tm_shape(aoi) +
    tmap::tm_polygons(
      fill = area$fill$color, col = area$stroke$color, lwd = 0.6
    ) +
    tmap::tm_layout(
      frame = TRUE, bg.color = "white",
      inner.margins = rep(0.02, 4), outer.margins = rep(0, 4)
    )

  list(map = map,
       viewport = keymap_viewport(corner, width, height, margin))
}


#' Viewport centre for a corner placement
#'
#' A viewport is positioned by its centre, so a caller thinking in margins has
#' to convert — which is why every copy of this carries different-looking magic
#' numbers that all mean "bottom right, a bit in from the edge". Pure, so the
#' arithmetic is testable without a device.
#' @noRd
keymap_viewport <- function(corner, width, height, margin) {
  x <- if (grepl("right", corner)) 1 - width / 2 - margin else width / 2 + margin
  y <- if (grepl("top", corner)) 1 - height / 2 - margin else height / 2 + margin
  grid::viewport(x = x, y = y, width = width, height = height)
}
