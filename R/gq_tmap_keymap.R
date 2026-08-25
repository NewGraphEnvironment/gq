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
#' # Sizing
#'
#' `width` and `height` are fractions of the *device*, so on a non-square canvas
#' equal fractions do not give a square inset. Pass `asp` — the canvas
#' width/height — and the height is derived so the inset comes out square. On
#' the 9x7 canvas the fish passage maps use, the alternative is an inset 1.46
#' times wider than tall.
#'
#' @param aoi The area of interest — the thing being located.
#' @param context Wider context, drawn beneath.
#' @param reg A registry for the fill and stroke colours. Defaults to
#'   [gq_reg_main()]. The copies this replaces all hardcode hex here, including
#'   one that takes a registry argument and then does not use it.
#' @param aoi_layer Registry key supplying the AOI style.
#' @param context_layer Registry key supplying the context style, or `NULL` for
#'   a neutral grey. Grey is the default because the context is a backdrop: the
#'   registry has no province-outline layer, and the nearest candidates are
#'   greens that leave a green AOI barely legible on top.
#' @param corner Which corner to place the inset in.
#' @param width Width as a fraction of the device.
#' @param height Height as a fraction of the device. Ignored when `asp` is given.
#' @param asp Canvas aspect ratio (`fig.width / fig.height`). When supplied,
#'   `height` is computed as `width * asp` so the inset renders square.
#' @param margin Gap between the inset and the frame edge, as a fraction of the
#'   device width. The four-corner convention wants this equal for every
#'   element, so when `asp` is supplied the vertical gap is derived from it the
#'   same way `height` is — otherwise a single device fraction is 29% larger
#'   horizontally than vertically on a 9x7 canvas.
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
#' # on a 9x7 canvas, asp makes the inset square IN INCHES -- the viewport
#' # fractions are not equal, because the device is not square
#' sq <- gq_tmap_keymap(aoi, context, asp = 9 / 7)
#' round(c(w_in = as.numeric(sq$viewport$width) * 9,
#'         h_in = as.numeric(sq$viewport$height) * 7), 3)
#'
#' @export
gq_tmap_keymap <- function(aoi, context, reg = NULL,
                           aoi_layer = "watershed_group_boundary",
                           context_layer = NULL,
                           corner = c("bottomright", "bottomleft",
                                      "topright", "topleft"),
                           width = 0.25, height = 0.22, asp = NULL,
                           margin = 0.03) {
  if (!requireNamespace("tmap", quietly = TRUE)) stop("tmap is required")
  if (!requireNamespace("grid", quietly = TRUE)) stop("grid is required")
  corner <- match.arg(corner)
  if (!is.null(asp)) {
    if (!is.numeric(asp) || length(asp) != 1L || is.na(asp) || asp <= 0) {
      stop("`asp` must be a single positive number", call. = FALSE)
    }
    height <- width * asp
    margin_y <- margin * asp
  } else {
    margin_y <- margin
  }
  if (width + 2 * margin > 1 || height + 2 * margin_y > 1) {
    stop("inset does not fit: width/height plus margins exceed the device",
         call. = FALSE)
  }

  if (is.null(reg)) reg <- gq_reg_main()
  area <- gq_style(reg, aoi_layer)
  ctx <- if (is.null(context_layer)) {
    list(fill = list(color = "#e8e8e8"), stroke = list(color = "#999999"))
  } else {
    gq_style(reg, context_layer)
  }

  # fill_alpha carried through rather than dropped: the registry stores opacity
  # on the fill, and an inset that ignores it cannot reproduce a semi-transparent
  # AOI over its context -- which is how every existing copy draws it.
  map <- tmap::tm_shape(context) +
    tmap::tm_polygons(
      fill = ctx$fill$color, fill_alpha = ctx$fill$opacity %||% 1,
      col = ctx$stroke$color, lwd = 0.5
    ) +
    tmap::tm_shape(aoi) +
    tmap::tm_polygons(
      fill = area$fill$color, fill_alpha = area$fill$opacity %||% 1,
      col = area$stroke$color, lwd = 0.6
    ) +
    tmap::tm_layout(
      frame = TRUE, bg.color = "white",
      inner.margins = rep(0.02, 4), outer.margins = rep(0, 4)
    )

  list(map = map,
       viewport = keymap_viewport(corner, width, height, margin, margin_y))
}


#' Viewport centre for a corner placement
#'
#' A viewport is positioned by its centre, so a caller thinking in margins has
#' to convert — which is why every copy of this carries different-looking magic
#' numbers that all mean "bottom right, a bit in from the edge". Pure, so the
#' arithmetic is testable without a device.
#' @noRd
keymap_viewport <- function(corner, width, height, margin, margin_y = margin) {
  x <- if (grepl("right", corner)) 1 - width / 2 - margin else width / 2 + margin
  y <- if (grepl("top", corner)) {
    1 - height / 2 - margin_y
  } else {
    height / 2 + margin_y
  }
  grid::viewport(x = x, y = y, width = width, height = height)
}
