#' Add water and a stream network to a MapLibre GL map, styled from the registry
#'
#' Lakes and rivers take the registry's `lake` style, and streams the
#' `streams_all` style, drawn wider by stream order so a mainstem reads over
#' its headwaters. Water goes on first, so streams draw over it.
#'
#' `streams_all` is classified by FWA `feature_code`. A network carrying that
#' column is coloured class by class; one without it, as from a
#' `fwa_stream_networks_sp` query that leaves the code out, is drawn as the
#' registry's first class, `Stream`, at its opacity.
#'
#' @param map A map from [gq_mapgl_basemap()].
#' @param streams An `sf` of stream lines, or `NULL`.
#' @param water An `sf` of lake and river polygons, or `NULL`. Keep only the
#'   columns you need: every one is written into the page.
#' @param reg A registry, as from [gq_reg_main()].
#' @param ids Source and layer ids, `c(water = , streams = )`. Name them to
#'   switch them in [gq_mapgl_controls()].
#' @param order_field The stream order column of `streams`.
#' @param widths Line width in pixels at order 1 and at order 6 and above.
#' @param legend Add a legend for each layer drawn: `Lake`, and the stream
#'   classes the network holds, or one row named by the registry's first
#'   class (`Stream`) when it carries no `feature_code`.
#' @param digits Decimal places kept in the coordinates; 5 is about 1 m.
#' @return `map`, with the layers added.
#'
#' @seealso [gq_mapgl_basemap()], [gq_mapgl_layer()]
#'
#' @examplesIf requireNamespace("mapgl", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)
#' reg <- gq_reg_main()
#' m <- gq_mapgl_basemap(neexdzii_wsd, "positron") |>
#'   gq_mapgl_network(streams = neexdzii_streams[c("gnis_name", "stream_order")],
#'                    water = neexdzii_lakes["gnis_name_1"], reg = reg)
#' vapply(m$x$layers, `[[`, "", "id")
#'
#' @export
gq_mapgl_network <- function(map, streams = NULL, water = NULL, reg = gq_reg_main(),
                             ids = c(water = "gq_water", streams = "gq_streams"),
                             order_field = "stream_order", widths = c(0.6, 3),
                             legend = FALSE, digits = 5L) {
  mapgl_need()
  check_digits(digits)
  ids <- as.list(ids)
  # Both layers go through gq_mapgl_layer(), so they get its checks on the data
  # they draw: geometry, columns, ids. A second translation of the registry here
  # had skipped them (gq#18 review round 3).
  if (!is.null(water) && nrow(water)) {
    id <- or_null(ids[["water"]], stop("`ids` must name a water id", call. = FALSE))
    map <- gq_mapgl_layer(map, id, water, key = "lake", reg = reg, type = "fill", legend = legend,
                          legend_title = "Lake", digits = digits)
  }
  if (!is.null(streams) && nrow(streams)) {
    id <- or_null(ids[["streams"]], stop("`ids` must name a streams id", call. = FALSE))
    if (!order_field %in% names(streams)) {
      stop("`streams` has no `", order_field, "` column to scale width by; ",
           "set `order_field`", call. = FALSE)
    }
    # streams must be lines: the `type = "line"` below would otherwise draw
    # polygon outlines in stream style
    layer_type(as.character(sf::st_geometry_type(streams)), "line")
    lyr <- reg_layer(reg, "streams_all")
    if (lyr$classification$field %in% names(streams)) {
      map <- gq_mapgl_layer(map, id, streams, key = "streams_all", reg = reg, type = "line",
                            width = order_field, widths = widths, legend = legend,
                            legend_title = "Streams", digits = digits)
    } else {
      keys <- setdiff(names(lyr$classification$classes), "__empty__")
      first <- lyr$classification$classes[[keys[1]]]
      map <- gq_mapgl_layer(map, id, streams, color = first$color, type = "line",
                            opacity = or_null(first$opacity, 1), width = order_field,
                            widths = widths, legend = legend,
                            legend_title = or_null(first$label, "Stream"), digits = digits)
    }
  }
  map
}

#' A registry layer by key, or an error naming it
#' @noRd
reg_layer <- function(reg, key) {
  lyr <- reg$layers[[key]]
  if (is.null(lyr)) stop("the registry has no layer `", key, "`", call. = FALSE)
  lyr
}
