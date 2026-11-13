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
#' Legends stack down the top-left corner in the order the layers were added,
#' and a hidden layer's legend leaves no gap. mapgl draws every legend at the
#' corner itself, one over another, so gq adds a stylesheet beside the map
#' that lets them flow. A one-colour layer's legend is a single row named by
#' `legend_title`, with no title above it.
#'
#' @param map A map from [gq_mapgl_basemap()].
#' @param id The layer id: what [gq_mapgl_controls()] switches, and the
#'   legend's `layer_id`.
#' @param x An `sf` to draw, or `NULL` to draw a source already on the map.
#'   gq checks the data a layer draws: its geometry, and that every column the
#'   style or popup reads is there. A source it cannot read without fetching
#'   it (vector tiles, PMTiles, a GeoJSON URL) is drawn unchecked, and needs
#'   `type` unless `key` gives it.
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
#'   [gq_style()], when the data names the column differently. A registry
#'   layer's legend lists only the classes found in this column of `x`.
#' @param type `"line"`, `"fill"` or `"circle"`. Read from the data's
#'   geometry when not given; a type given must agree with it, except
#'   `"line"` over polygons, which draws their outlines.
#' @param width A line width in pixels, a MapLibre expression, or the name of
#'   a stream order column, which draws order 1 at `widths[1]` pixels and
#'   order 6 and above at `widths[2]`.
#' @param widths Width in pixels at order 1 and at order 6, for a `width`
#'   column.
#' @param radius A circle radius in pixels, or a MapLibre expression such as
#'   one that grows with zoom.
#' @param opacity An opacity for every feature, overriding the registry's.
#' @param legend Add the layer's legend.
#' @param legend_title The legend's title, or for one colour the row's name.
#'   Defaults to `id`.
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
  # MapLibre throws on a second source or layer with an id already on the map,
  # and every source and layer after it then fails to draw
  if (id %in% vapply(map$x$layers, `[[`, "", "id")) {
    stop("the map already has a layer `", id, "`", call. = FALSE)
  }

  # Every check below is made on the data the layer will draw, whichever way it
  # arrives -- as `x`, or as a source already on the map -- because a guard
  # written against one form of an argument let the other forms through to a
  # map drawn wrong without an error (gq#18 review rounds 1-3).
  have_src <- vapply(map$x$sources, `[[`, "", "id")
  if (!is.null(x)) {
    if (!inherits(x, c("sf", "sfc"))) stop("`x` must be an sf or sfc", call. = FALSE)
    if (source %in% have_src) {
      stop("the map already has a source `", source, "`; give `x = NULL` to draw it again, ",
           "or another `source`", call. = FALSE)
    }
    if (!length(sf::st_geometry(x))) stop("`x` has no rows to draw", call. = FALSE)
    d <- mapgl_data(x, digits)
    drawn <- list(props = sf::st_drop_geometry(d),
                  types = as.character(sf::st_geometry_type(d)[!sf::st_is_empty(d)]))
  } else {
    if (!source %in% have_src) {
      stop("`x` is NULL and the map has no source `", source, "` to draw", call. = FALSE)
    }
    # NULL for a source gq cannot read without fetching it: tiles, PMTiles, a
    # GeoJSON URL. Those are drawn as told, unchecked; never fetched here.
    drawn <- source_frame(map, source)
  }

  lyr <- NULL
  if (!is.null(key)) {
    if (is.null(reg)) stop("`key` needs `reg`, such as gq_reg_main()", call. = FALSE)
    lyr <- reg_layer(reg, key)
  }
  if (is.null(drawn)) {
    type <- or_null(type, switch(or_null(lyr$type, ""), line = "line", polygon = "fill",
                                 point = "circle", NULL))
    if (is.null(type)) {
      stop("give `type`: source `", source, "` is not GeoJSON on the map, so gq cannot read ",
           "its geometry", call. = FALSE)
    }
  } else {
    # outlines only where no registry style asserts a geometry of its own
    type <- layer_type(drawn$types, type, outline_ok = is.null(key))
  }
  sty <- layer_paint(type, lyr, classes, color, field, key, legend_title)
  if (!is.null(drawn) && !is.null(sty$keys) && !sty$field %in% names(drawn$props)) {
    stop("the data has no `", sty$field, "` column, which registry layer `", key,
         "` is classified on; name the column with `field =`", call. = FALSE)
  }
  if (!is.null(drawn)) {
    check_reads(list(sty$color, opacity, sty$opacity, radius,
                     if (is.character(width)) list("get", width) else width,
                     if (is.character(popup)) list("get", popup) else popup),
                drawn$props, source)
  }
  if (!is.null(sty$keys)) {
    # A legend naming classes the map does not draw is a common and quiet error, so
    # a registry layer's legend lists only the classes in the data, one row per look.
    # a source gq cannot read lists every class: there is no data to cut it to
    keep <- if (is.null(drawn)) rep(TRUE, length(sty$keys)) else sty$keys %in% drawn$props[[sty$field]]
    # Collapse looks among the classes kept, not before: QGIS groups several keys
    # under one look (roads_dra's Highway is RRP, RH1 and RH2), and dropping the
    # first key before the filter dropped the row for data holding only the others.
    keep[keep] <- !duplicated(paste(sty$labels, sty$swatches)[keep])
    if (!any(keep)) stop("the data has none of registry layer `", key, "`'s classes in `",
                         sty$field, "`", call. = FALSE)
    sty$labels <- sty$labels[keep]
    sty$swatches <- sty$swatches[keep]
  }

  args <- list(id = id, source = source)
  if (!is.null(x)) map <- mapgl::add_source(map, source, d)
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
    # The legend id is a CSS selector in mapgl's stylesheet, so a layer id with a
    # space ("rainbow trout") left its legend unstyled: no swatch, no box.
    leg <- list(legend_title = if (isTRUE(sty$single)) NULL else legend_title,
                values = sty$labels, colors = sty$swatches, position = "top-left",
                layer_id = id, unique_id = paste0("legend_", gsub("[^A-Za-z0-9_-]", "_", id)),
                add = !is.null(map$x$legend_html))
    if (type == "circle") leg$patch_shape <- "circle"
    if (type == "line" && isTRUE(sty$single)) leg$patch_shape <- "line"
    map <- do.call(mapgl::add_categorical_legend, c(list(map), leg))
    map <- legend_stack(map)
  }
  map
}

#' The stylesheet that stacks a map's legends down its top-left corner
#'
#' mapgl wraps the legends in one element and positions each at the corner
#' absolutely, so a second legend is drawn over the first. Measured in the
#' browser on mapgl 0.4.4.9000. These rules let the legends flow in the
#' wrapper instead, and drop the empty heading of an untitled legend. They sit
#' beside the widget's spec (`map$prepend`), not in it.
#' @noRd
legend_stack_css <- paste(
  ".maplibregl-map > .mapboxgl-legend { position: absolute; top: 0; left: 0;",
  "width: auto; height: auto; z-index: 1002; pointer-events: none; display: flex;",
  "flex-direction: column; align-items: flex-start; }",
  ".maplibregl-map > .mapboxgl-legend > .mapboxgl-legend.top-left { position: static !important;",
  "pointer-events: auto; margin: 6px 0 0 10px !important; padding: 6px 12px !important; }",
  ".maplibregl-map .mapboxgl-legend h2:empty { display: none; }"
)

#' @noRd
legend_stack <- function(map) {
  have <- vapply(map$prepend, function(x) identical(attr(x, "gq"), "legend_stack"), logical(1))
  if (any(have)) return(map)
  tag <- htmltools::tags$style(htmltools::HTML(legend_stack_css))
  attr(tag, "gq") <- "legend_stack"
  htmlwidgets::prependContent(map, tag)
}


# --- internal helpers --------------------------------------------------------

#' The MapLibre layer type for the geometry a layer draws
#'
#' Read from the data, never from the registry or an existing layer: those name
#' what the layer should be, and only the data says what it would draw. A
#' `type` the caller gives must agree with it.
#' @noRd
layer_type <- function(types, type = NULL, outline_ok = FALSE) {
  g <- unique(toupper(types))
  if (!length(g)) stop("the data has no geometry to draw", call. = FALSE)
  drawn <- if (all(g %in% c("LINESTRING", "MULTILINESTRING"))) {
    "line"
  } else if (all(g %in% c("POLYGON", "MULTIPOLYGON"))) {
    "fill"
  } else if (all(g %in% c("POINT", "MULTIPOINT"))) {
    "circle"
  } else {
    stop("cannot draw mixed or unsupported geometry: ", paste(g, collapse = ", "), call. = FALSE)
  }
  # a line layer over polygons draws their outlines, which MapLibre allows
  if (outline_ok && identical(type, "line") && drawn == "fill") return("line")
  if (!is.null(type) && !identical(type, drawn)) {
    stop("`type` is \"", type, "\", but the data is drawn as \"", drawn, "\"", call. = FALSE)
  }
  drawn
}

#' The properties and geometry types of a GeoJSON source already on the map
#' @noRd
source_frame <- function(map, source) {
  src <- Filter(function(s) identical(s$id, source), map$x$sources)[[1]]
  if (identical(src$type, "raster") || identical(src$type, "raster-dem")) {
    stop("source `", source, "` is a raster; gq draws vector layers", call. = FALSE)
  }
  inline <- identical(src$type, "geojson") && is.character(src$data) && length(src$data) == 1L &&
    startsWith(trimws(src$data), "{")
  if (!inline) return(NULL)
  j <- jsonlite::fromJSON(src$data, simplifyVector = TRUE)
  f <- j$features
  if (!length(f) || !NROW(f)) stop("source `", source, "` has no features", call. = FALSE)
  props <- if (is.data.frame(f$properties)) f$properties else data.frame(row.names = seq_len(NROW(f)))
  types <- f$geometry$type
  list(props = props, types = types[!is.na(types)])
}

#' Refuse a paint expression or popup that reads what the data does not hold
#'
#' MapLibre reads a missing property as null and a mismatched one as no match,
#' so either draws the fallback colour or width with no error anywhere. Every
#' `["get", column]` must name a column, and a `match` must compare like with
#' like: its comparison is type-strict, so text keys never match numbers.
#' @noRd
check_reads <- function(exprs, props, source) {
  gets <- character()
  walk <- function(e) {
    if (!is.list(e)) return()
    if (length(e) == 2L && identical(e[[1]], "get") && is.character(e[[2]])) {
      gets <<- c(gets, e[[2]])
      return()
    }
    if (length(e) >= 4L && identical(e[[1]], "match") && is.list(e[[2]]) &&
          identical(e[[2]][[1]], "get")) {
      col <- e[[2]][[2]]
      labels <- e[seq(3L, length(e) - 1L, by = 2L)]
      if (col %in% names(props) && length(labels)) {
        if (value_kind(props[[col]]) != value_kind(labels[[1]])) {
          stop("column `", col, "` holds ", value_kind(props[[col]]), "s but its classes are ",
               value_kind(labels[[1]]), "s, and MapLibre matches neither to the other; ",
               "convert the column", call. = FALSE)
        }
      }
    }
    for (k in e) walk(k)
  }
  for (e in exprs) walk(e)
  miss <- setdiff(unique(gets), names(props))
  if (length(miss)) {
    stop("the data for `", source, "` has no column ", paste0("`", miss, "`", collapse = ", "),
         ", which the layer's style or popup reads", call. = FALSE)
  }
  invisible(TRUE)
}

#' The JSON kind a value is written as
#' @noRd
value_kind <- function(v) {
  if (is.numeric(v)) "number" else if (is.logical(v)) "boolean" else "string"
}

#' Colour, opacity, width and legend entries for one layer, from one source
#' @noRd
layer_paint <- function(type, lyr, classes, color, field, key, legend_title) {
  if (!is.null(color)) {
    col <- to_hex(color, "color")
    if (length(col) != 1L) stop("`color` must be one colour", call. = FALSE)
    return(list(color = col, labels = legend_title, swatches = col, single = TRUE))
  }
  if (!is.null(classes)) {
    need <- c("field", "values", "colors")
    miss <- setdiff(need, names(classes))
    if (length(miss)) {
      stop("`classes` needs ", paste(miss, collapse = ", "), call. = FALSE)
    }
    check_labels(classes$values)
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
    if (is.null(p[[paste0(pre, "color")]])) {
      # an entry the extractor could not style (a rule-based renderer, say) would
      # draw in MapLibre's default colour, as if it were styled
      stop("registry layer `", key, "` carries no colour to draw", call. = FALSE)
    }
    dash <- p[["line-dasharray"]]
    return(list(color = p[[paste0(pre, "color")]], opacity = p[[paste0(pre, "opacity")]],
                outline = p[["fill-outline-color"]], width = p[["line-width"]],
                radius = p[["circle-radius"]], dash = dash, single = TRUE,
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
  list(color = col, opacity = op, labels = unname(labs), swatches = unname(sw), keys = keys,
       field = or_null(field, lyr$classification$field))
}

#' Refuse class values MapLibre cannot use as `match` labels
#'
#' MapLibre takes a branch label only as a string or a whole number, and drops
#' the whole layer otherwise, leaving its legend behind. Checked here, on the
#' values themselves, so it holds whatever source the layer draws.
#' @noRd
check_labels <- function(values) {
  if (is.logical(values)) {
    stop("`classes` values are TRUE and FALSE, which MapLibre cannot match; ",
         "convert the column and the values to text", call. = FALSE)
  }
  if (!length(values) || anyNA(values)) {
    stop("`classes` values must be given, with none missing", call. = FALSE)
  }
  if (is.numeric(values) && any(!is.finite(values) | values != round(values))) {
    stop("`classes` values must be whole numbers or text: MapLibre matches no other number",
         call. = FALSE)
  }
  if (!is.numeric(values) && !is.character(values)) {
    stop("`classes` values must be text or whole numbers", call. = FALSE)
  }
  if (anyDuplicated(values)) stop("`classes` values must be unique", call. = FALSE)
  invisible(TRUE)
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
