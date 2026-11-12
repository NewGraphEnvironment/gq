#' Add a styled layer and its legend to a MapLibre GL map
#'
#' Draws one `sf` layer on a gq web map, styled from a registry key, from
#' classes the caller names, or from one colour, and adds its categorical
#' legend tied to the layer, so the legend hides when the layer is switched
#' off in [gq_mapgl_controls()].
#'
#' Several layers can draw one source: pass the data once with `x`, then add
#' the next layer with `x = NULL` and the same `source`. Each layer is a
#' separate switch, as in a map that colours one set of segments two ways.
#'
#' Colours are given to MapLibre as hex. R colour names such as `grey80`
#' draw in tmap but MapLibre cannot read them and drops the whole layer, so
#' they are converted here.
#'
#' @param map A map from [gq_mapgl_basemap()].
#' @param id The layer id: what [gq_mapgl_controls()] switches, and the
#'   legend's `layer_id`.
#' @param x An `sf` to draw, or `NULL` to draw a source already on the map.
#'   Its coordinates are taken to EPSG:4326 and rounded to `digits`; keep only
#'   the columns the style and popup read, since every one is written into the
#'   page.
#' @param source The source id. Defaults to `id`; name an existing source
#'   with `x = NULL` to draw it again.
#' @param key A registry layer key, such as `"lake"` or `"bec_zone"`.
#' @param classes Classes the caller names, a list of `field` (the column),
#'   `values` (the values matched), `colors` (one per value), and optionally
#'   `labels` (the legend's names, default `values`) and `default` (the colour
#'   of anything else, default `"#cccccc"`).
#' @param color One colour for every feature, when there is no `key` or
#'   `classes`.
#' @param reg A registry, as from [gq_reg_main()]; read only with `key`.
#' @param field Overrides the registry layer's classification field, as in
#'   [gq_style()], when the data names the column differently.
#' @param type `"line"`, `"fill"` or `"circle"`. Read from `x`'s geometry, or
#'   the registry layer's type, when not given.
#' @param width A line width in pixels, a MapLibre expression, or the name of
#'   a stream order column, which draws order 1 at `widths[1]` pixels and
#'   order 6 and above at `widths[2]`.
#' @param widths Width in pixels at order 1 and at order 6, for a `width`
#'   column.
#' @param radius A circle radius in pixels, or a MapLibre expression such as
#'   one that grows with zoom.
#' @param opacity An opacity for every feature, overriding the registry's.
#' @param legend Add the layer's legend.
#' @param legend_title The legend's title. Defaults to `id`.
#' @param popup A column name, or the `expr` of [gq_mapgl_popup()].
#' @param visible `FALSE` adds the layer switched off.
#' @param digits Decimal places kept in the coordinates; 5 is about 1 m.
#' @param ... Further arguments to the mapgl layer function, such as
#'   `circle_stroke_color`, `filter` or `before_id`.
#' @return `map`, with the layer and its legend added.
#'
#' @seealso [gq_mapgl_popup()], [gq_mapgl_controls()], [gq_mapgl_classes()]
#'
#' @examplesIf requireNamespace("mapgl", quietly = TRUE) && requireNamespace("sf", quietly = TRUE)
#' obs <- neexdzii_fish_obs
#' m <- gq_mapgl_basemap(neexdzii_wsd, "positron") |>
#'   gq_mapgl_layer("lakes", neexdzii_lakes["gnis_name_1"], key = "lake",
#'                  reg = gq_reg_main(), legend_title = "Lake") |>
#'   gq_mapgl_layer("Coho", obs[obs$species_code == "CO", "species_code"],
#'                  color = "#FF7F00", radius = 6) |>
#'   gq_mapgl_layer("Rainbow trout", obs[obs$species_code == "RB", "species_code"],
#'                  color = "steelblue", radius = 6)
#' vapply(m$x$layers, `[[`, "", "id")
#' m$x$layers[[3]]$paint[["circle-color"]]     # a colour name, sent as hex
#'
#' @export
gq_mapgl_layer <- function(map, id, x = NULL, source = id, key = NULL, classes = NULL,
                           color = NULL, reg = NULL, field = NULL, type = NULL,
                           width = NULL, widths = c(0.6, 3), radius = NULL, opacity = NULL,
                           legend = TRUE, legend_title = id, popup = NULL, visible = TRUE,
                           digits = 5L, ...) {
  mapgl_need()
  check_digits(digits)
  if (!is.character(id) || length(id) != 1L || !nzchar(id)) {
    stop("`id` must be one non-empty string", call. = FALSE)
  }
  if (sum(!is.null(key), !is.null(classes), !is.null(color)) != 1L) {
    stop("give exactly one of `key`, `classes` or `color`", call. = FALSE)
  }
  if (!is.null(x) && !nrow(x)) stop("`x` has no rows to draw", call. = FALSE)
  if (is.null(x) && !source %in% vapply(map$x$sources, `[[`, "", "id")) {
    stop("`x` is NULL and the map has no source `", source, "` to draw", call. = FALSE)
  }

  lyr <- NULL
  if (!is.null(key)) {
    if (is.null(reg)) stop("`key` needs `reg`, such as gq_reg_main()", call. = FALSE)
    lyr <- reg_layer(reg, key)
  }
  type <- or_null(type, layer_type(x, lyr, map, source))
  sty <- layer_paint(type, lyr, classes, color, field, key, legend_title)

  args <- list(id = id, source = source)
  if (!is.null(x)) map <- mapgl::add_source(map, source, mapgl_data(x, digits))
  p <- function(prop) paste0(type, "_", prop)
  args[[p("color")]] <- sty$color
  op <- or_null(opacity, sty$opacity)
  if (!is.null(op)) args[[p("opacity")]] <- op
  if (type == "fill" && !is.null(sty$outline)) args$fill_outline_color <- sty$outline
  if (type == "line") {
    w <- if (is.character(width)) order_width(width, widths) else or_null(width, sty$width)
    if (!is.null(w)) args$line_width <- w
    if (!is.null(sty$dash)) args$line_dasharray <- sty$dash
  }
  if (type == "circle") {
    r <- or_null(radius, sty$radius)
    if (!is.null(r)) args$circle_radius <- r
  }
  if (!is.null(popup)) args$popup <- popup
  args$visibility <- if (isTRUE(visible)) "visible" else "none"
  adder <- switch(type, line = mapgl::add_line_layer, fill = mapgl::add_fill_layer,
                  circle = mapgl::add_circle_layer)
  map <- do.call(adder, c(list(map), args, list(...)))

  if (isTRUE(legend)) {
    leg <- list(legend_title = legend_title, values = sty$labels, colors = sty$swatches,
                position = "top-left", layer_id = id, unique_id = paste0("legend_", id),
                add = !is.null(map$x$legend_html))
    if (type == "circle") leg$patch_shape <- "circle"
    map <- do.call(mapgl::add_categorical_legend, c(list(map), leg))
  }
  map
}


# --- internal helpers --------------------------------------------------------

#' The MapLibre layer type for an sf's geometry, a registry layer's type, or
#' the type of a layer already drawing the same source
#' @noRd
layer_type <- function(x, lyr, map = NULL, source = NULL) {
  if (!is.null(x)) {
    g <- unique(as.character(sf::st_geometry_type(x)))
    if (all(g %in% c("LINESTRING", "MULTILINESTRING"))) return("line")
    if (all(g %in% c("POLYGON", "MULTIPOLYGON"))) return("fill")
    if (all(g %in% c("POINT", "MULTIPOINT"))) return("circle")
    stop("cannot draw mixed or unsupported geometry: ", paste(g, collapse = ", "),
         call. = FALSE)
  }
  t <- lyr$type
  if (is.null(t)) {
    same <- Filter(function(l) identical(l$source, source), map$x$layers)
    if (length(same)) return(same[[1]]$type)
    stop("give `type`: `x` is NULL, there is no `key`, and no layer draws `", source, "` yet",
         call. = FALSE)
  }
  switch(t, line = "line", polygon = "fill", point = "circle",
         stop("Unknown layer type: ", t, call. = FALSE))
}

#' Colour, opacity, width and legend entries for one layer, from one source
#' @noRd
layer_paint <- function(type, lyr, classes, color, field, key, legend_title) {
  if (!is.null(color)) {
    col <- to_hex(color, "color")
    if (length(col) != 1L) stop("`color` must be one colour", call. = FALSE)
    return(list(color = col, labels = legend_title, swatches = col))
  }
  if (!is.null(classes)) {
    need <- c("field", "values", "colors")
    miss <- setdiff(need, names(classes))
    if (length(miss)) {
      stop("`classes` needs ", paste(miss, collapse = ", "), call. = FALSE)
    }
    cols <- to_hex(classes$colors, "classes$colors")
    if (length(cols) != length(classes$values)) {
      stop("`classes` needs one colour per value", call. = FALSE)
    }
    labs <- or_null(classes$labels, as.character(classes$values))
    if (length(labs) != length(classes$values)) {
      stop("`classes` needs one label per value", call. = FALSE)
    }
    def <- to_hex(or_null(classes$default, "#cccccc"), "classes$default")
    expr <- mapgl::match_expr(classes$field, values = classes$values, stops = cols,
                              default = def)
    return(list(color = expr, labels = labs, swatches = cols))
  }

  # a registry layer
  want <- switch(type, line = "line", fill = "polygon", circle = "point")
  if (!identical(lyr$type, want)) {
    stop("registry layer `", key, "` is a ", or_null(lyr$type, "<none>"),
         " layer, not a ", want, " one", call. = FALSE)
  }
  if (is.null(lyr$classification)) {
    p <- gq_mapgl_style(lyr)$paint
    pre <- paste0(type, "-")
    dash <- p[["line-dasharray"]]
    return(list(color = p[[paste0(pre, "color")]], opacity = p[[paste0(pre, "opacity")]],
                outline = p[["fill-outline-color"]], width = p[["line-width"]],
                radius = p[["circle-radius"]], dash = dash,
                labels = legend_title, swatches = p[[paste0(pre, "color")]]))
  }
  col <- gq_mapgl_classes(lyr, paste0(type, "-color"))
  op <- gq_mapgl_classes(lyr, paste0(type, "-opacity"))
  if (!is.null(field)) {
    col[[2]] <- list("get", field)
    if (is.list(op)) op[[2]] <- list("get", field)
  }
  if (identical(op, 1)) op <- NULL
  # one legend row per appearance, as gq_tmap_legend() collapses them
  keys <- setdiff(names(lyr$classification$classes), "__empty__")
  labs <- vapply(keys, function(k) {
    cl <- lyr$classification$classes[[k]]
    or_null(cl$label, to_title(k))
  }, character(1))
  sw <- vapply(keys, function(k) lyr$classification$classes[[k]]$color, character(1))
  keep <- !duplicated(paste(labs, sw))
  list(color = col, opacity = op, labels = unname(labs[keep]), swatches = unname(sw[keep]))
}

#' Colours as hex, leaving hex untouched
#'
#' MapLibre cannot parse an R colour name and drops the whole layer, and
#' `col2rgb(NA)` is transparent white rather than an error. Hex passes through
#' as typed, so a caller's own hex is what reaches the page.
#' @noRd
to_hex <- function(x, what) {
  x <- as.character(x)
  if (anyNA(x) || !all(nzchar(x))) stop("`", what, "` has a missing colour", call. = FALSE)
  hex <- grepl("^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$", x)
  if (any(!hex)) {
    m <- tryCatch(grDevices::col2rgb(x[!hex], alpha = TRUE), error = function(e) {
      stop("`", what, "` is not a colour: ", conditionMessage(e), call. = FALSE)
    })
    x[!hex] <- ifelse(m[4, ] == 255,
                      grDevices::rgb(t(m[1:3, , drop = FALSE]), maxColorValue = 255),
                      grDevices::rgb(t(m[1:3, , drop = FALSE]), alpha = m[4, ], maxColorValue = 255))
  }
  x
}
