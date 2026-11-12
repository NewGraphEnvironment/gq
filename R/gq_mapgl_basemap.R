#' Start a MapLibre GL map on a named basemap, fitted to the data
#'
#' The first call of a gq web map: [mapgl::maplibre()] on one of four keyless
#' basemaps, its view fitted to `x`. The layers go on with
#' [gq_mapgl_network()] and [gq_mapgl_layer()], and the switches with
#' [gq_mapgl_controls()].
#'
#' Esri's World Topographic Map needs no key, and Esri allows free
#' noncommercial use with attribution, which the map shows: the service's own
#' credit, after "Powered by Esri".
#'
#' @param x The extent to fit: an `sf` or `sfc` in any CRS, or an
#'   [sf::st_bbox()]. Its coordinates are taken to EPSG:4326 and rounded to
#'   `digits` decimal places, as [gq_mapgl_layer()] rounds the layers, so the
#'   view fits exactly what is drawn.
#' @param basemap `"voyager"` (Carto Voyager), `"positron"` (Carto Positron,
#'   pale grey), `"openfreemap"` (OpenFreeMap Liberty) or `"esri_topo"` (Esri
#'   World Topographic Map raster tiles).
#' @param digits Decimal places kept in the coordinates; 5 is about 1 m.
#' @return A `maplibregl` htmlwidget.
#'
#' @seealso [gq_mapgl_network()], [gq_mapgl_layer()], [gq_mapgl_controls()]
#'
#' @examplesIf requireNamespace("mapgl", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)
#' m <- gq_mapgl_basemap(neexdzii_wsd, basemap = "positron")
#' class(m)
#' m$x$additional_params$bounds
#'
#' @export
gq_mapgl_basemap <- function(x, basemap = c("voyager", "positron", "openfreemap", "esri_topo"),
                             digits = 5L) {
  mapgl_need()
  basemap <- match.arg(basemap)
  check_digits(digits)
  if (inherits(x, "bbox")) x <- sf::st_as_sfc(x)
  if (!inherits(x, c("sf", "sfc"))) {
    stop("`x` must be an sf, an sfc or a bbox", call. = FALSE)
  }
  if (length(sf::st_geometry(x)) == 0L) stop("`x` has no geometry to fit", call. = FALSE)
  style <- switch(basemap,
                  voyager = mapgl::carto_style("voyager"),
                  positron = mapgl::carto_style("positron"),
                  openfreemap = mapgl::openfreemap_style("liberty"),
                  esri_topo = esri_topo_style())
  # An sf, not an sfc: maplibre() reduces an sf to its bbox but stores an sfc
  # as given, and MapLibre cannot fit to a polygon.
  mapgl::maplibre(style = style, bounds = sf::st_sf(geometry = mapgl_geom(x, digits)))
}


# --- internal helpers --------------------------------------------------------

#' Stop early, and say so, when mapgl or sf is missing
#' @noRd
mapgl_need <- function() {
  for (p in c("mapgl", "sf")) {
    if (!requireNamespace(p, quietly = TRUE)) {
      stop("the ", p, " package is needed for gq's mapgl helpers", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' @noRd
check_digits <- function(digits) {
  whole <- is.numeric(digits) && length(digits) == 1L && !is.na(digits) &&
    digits == round(digits) && digits >= 0
  if (!whole) {
    stop("`digits` must be one whole number, 0 or more", call. = FALSE)
  }
  invisible(TRUE)
}

#' A geometry in EPSG:4326 with Z dropped and every coordinate rounded
#'
#' What sets a web map's size: each coordinate is written into the page once
#' per vertex, so 5 decimal places (about 1 m) rather than 15.
#' @noRd
mapgl_geom <- function(x, digits) {
  g <- sf::st_geometry(sf::st_zm(x, drop = TRUE))
  round_sfc(sf::st_transform(g, 4326), digits)
}

#' An sf ready for a MapLibre source: EPSG:4326, rounded, attributes kept
#'
#' An sf with no attribute column gets `id`: geojsonsf writes a geometry-only
#' sf as bare geometries rather than a FeatureCollection, which MapLibre will
#' not read as a source.
#' @noRd
mapgl_data <- function(x, digits) {
  if (inherits(x, "sfc")) x <- sf::st_sf(geometry = x)
  if (!inherits(x, "sf")) stop("layer data must be an sf or sfc", call. = FALSE)
  att <- sf::st_drop_geometry(x)
  if (ncol(att) == 0L) att <- data.frame(id = seq_len(nrow(x)))
  sf::st_sf(att, geometry = mapgl_geom(x, digits))
}

#' Round every coordinate of an sfc, keeping its structure
#' @noRd
round_sfc <- function(g, digits) {
  rnd <- function(x) {
    y <- if (is.list(x)) lapply(x, rnd) else round(as.numeric(unclass(x)), digits)
    attributes(y) <- attributes(x)
    y
  }
  sf::st_sfc(lapply(g, rnd), crs = sf::st_crs(g))
}

#' Esri's World Topographic Map as a MapLibre raster style
#'
#' Its tile service needs no key, and Esri allows free noncommercial use with
#' attribution; the attribution is the service's own `copyrightText`
#' (World_Topo_Map/MapServer, read 2026-10-21) after "Powered by Esri", shown
#' in the map's attribution control.
#' @noRd
esri_topo_style <- function() {
  attribution <- paste0("Powered by <a href=\"https://www.esri.com\">Esri</a> | Sources: Esri, HERE, Garmin, ",
                        "Intermap, increment P Corp., GEBCO, USGS, FAO, NPS, NRCAN, GeoBase, IGN, Kadaster NL, ",
                        "Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), (c) OpenStreetMap contributors, ",
                        "and the GIS User Community")
  tiles <- "https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}"
  src <- list(type = "raster", tiles = list(tiles), tileSize = 256, maxzoom = 19, attribution = attribution)
  list(version = 8, sources = list(esri_topo = src),
       layers = list(list(id = "esri_topo", type = "raster", source = "esri_topo")))
}

#' Line width by stream order, as a MapLibre interpolate expression
#'
#' Order 1 draws at `widths[1]` pixels and order 6 and above at `widths[2]`,
#' so a mainstem reads over its headwaters.
#' @noRd
order_width <- function(field, widths = c(0.6, 3)) {
  if (!is.numeric(widths) || length(widths) != 2L || anyNA(widths) || any(widths <= 0)) {
    stop("`widths` must be two positive numbers: order 1, then order 6", call. = FALSE)
  }
  mapgl::interpolate(field, values = c(1, 6), stops = widths)
}
