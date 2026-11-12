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
                             digits = 5L) {
  mapgl_need()
  check_digits(digits)
  ids <- as.list(ids)
  if (!is.null(water) && nrow(water)) {
    id <- or_null(ids[["water"]], stop("`ids` must name a water id", call. = FALSE))
    paint <- gq_mapgl_style(reg_layer(reg, "lake"))$paint
    map <- map |>
      mapgl::add_source(id, mapgl_data(water, digits)) |>
      mapgl::add_fill_layer(id, source = id, fill_color = paint$`fill-color`,
                            fill_opacity = paint$`fill-opacity`,
                            fill_outline_color = paint$`fill-outline-color`)
  }
  if (!is.null(streams) && nrow(streams)) {
    id <- or_null(ids[["streams"]], stop("`ids` must name a streams id", call. = FALSE))
    if (!order_field %in% names(streams)) {
      stop("`streams` has no `", order_field, "` column to scale width by; ",
           "set `order_field`", call. = FALSE)
    }
    lyr <- reg_layer(reg, "streams_all")
    fld <- lyr$classification$field
    if (fld %in% names(streams)) {
      col <- gq_mapgl_classes(lyr, "line-color")
      op <- gq_mapgl_classes(lyr, "line-opacity")
    } else {
      first <- lyr$classification$classes[[setdiff(names(lyr$classification$classes), "__empty__")[1]]]
      col <- first$color
      op <- or_null(first$opacity, 1)
    }
    map <- map |>
      mapgl::add_source(id, mapgl_data(streams, digits)) |>
      mapgl::add_line_layer(id, source = id, line_color = col, line_opacity = op,
                            line_width = order_width(order_field, widths))
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
