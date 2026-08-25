# --- legend construction ------------------------------------------------------

#' Build tmap legend arguments from registry layers
#'
#' Turns a set of layer keys into argument lists for [tmap::tm_add_legend()],
#' one per geometry type, pulling every colour, width, dash and symbol from the
#' registry rather than from parallel vectors typed by hand.
#'
#' Classified layers expand to one entry per class; simple layers contribute a
#' single entry. Both kinds can appear in the same call and are merged into the
#' right geometry group.
#'
#' # What this does not do
#'
#' Layout. tmap 4.4 handles ordering (`z`), grouping (`group_id`), stacking and
#' framing ([tmap::tm_components()]), and bulk placement
#' (`tm_place_legends_*()`) — all of it better than a wrapper could, because it
#' can see the whole map object. `z` and `group_id` are passed straight through
#' so those facilities keep working.
#'
#' What tmap cannot do is read a style registry, because it has no concept of
#' one. That translation is the whole of this function.
#'
#' @param reg A registry, as from [gq_reg_main()].
#' @param layers Layer keys. An unnamed character vector uses each layer's
#'   title-cased key as its label; a named vector or list uses the names as
#'   labels (`c("Lake" = "lake")`).
#' @param present Optional named list restricting classified layers to the
#'   values actually in the data, e.g. `list(roads_dra = unique(x$road_type))`.
#'   A legend naming classes the map does not draw is a common and quiet error.
#' @param field Optional named character vector overriding the classification
#'   field per layer, matching [gq_style()]'s `field`.
#' @param titles Optional named character vector of legend titles per geometry
#'   type, e.g. `c(symbols = "Crossings")`.
#' @param ... Extra arguments merged into every returned list — `z`,
#'   `group_id`, `orientation`, `position` and so on.
#'
#' @return A named list of argument lists, one per geometry type present
#'   (`polygons`, `lines`, `symbols`). Each is ready for
#'   `do.call(tmap::tm_add_legend, x)`.
#'
#' @seealso [gq_tmap_style()] for drawing the layers themselves,
#'   [tmap::tm_components()] for arranging the results.
#'
#' @examples
#' reg <- gq_reg_main()
#'
#' # mixed geometry types partition automatically
#' leg <- gq_tmap_legend(reg, c("lake", "railway"))
#' names(leg)
#' leg$polygons$labels
#'
#' # a classified layer expands to one entry per class
#' roads <- gq_tmap_legend(reg, "roads_dra")
#' length(roads$lines$labels)
#'
#' # ... and can be cut down to the classes the data actually contains
#' some <- gq_tmap_legend(reg, "roads_dra",
#'                        present = list(roads_dra = c("RH1", "RA1")))
#' length(some$lines$labels)
#'
#' # labels come from the names when supplied
#' gq_tmap_legend(reg, c("Waterbody" = "lake"))$polygons$labels
#'
#' @export
gq_tmap_legend <- function(reg, layers, present = NULL, field = NULL,
                           titles = NULL, ...) {
  if (length(layers) == 0L) {
    stop("`layers` must name at least one layer", call. = FALSE)
  }
  keys <- unlist(layers, use.names = TRUE)
  labs <- names(keys)
  if (is.null(labs)) labs <- rep(NA_character_, length(keys))
  labs[!nzchar(labs)] <- NA_character_

  entries <- list()
  for (i in seq_along(keys)) {
    key <- keys[[i]]
    fld <- if (is.null(field)) NULL else field[[key]]
    sty <- gq_style(reg, key, field = fld)
    cls <- if (is.null(sty$classification)) {
      NULL
    } else {
      gq_tmap_classes(reg, key, field = fld)
    }
    entries <- c(entries,
                 legend_entries(sty, cls, key, labs[[i]], present[[key]]))
  }

  extra <- list(...)
  out <- list()
  for (type in c("polygons", "lines", "symbols")) {
    rows <- Filter(function(e) identical(e$type, type), entries)
    if (length(rows) == 0L) next
    out[[type]] <- c(
      list(type = type),
      collect_legend(rows),
      if (!is.null(titles[[type]])) list(title = titles[[type]]),
      extra
    )
  }
  out
}


#' One layer to zero or more legend rows
#'
#' Kept separate from the assembly so the geometry-type mapping and the
#' classified expansion can be tested without building a whole legend.
#'
#' `sty` is a [gq_style()] result and `cls` a [gq_tmap_classes()] result or
#' `NULL`. The classification is passed in already flattened rather than read
#' off `sty$classification`, which is the nested per-class form.
#' @noRd
legend_entries <- function(sty, cls, key, label, present) {
  type <- switch(if (is.null(sty$type)) "" else sty$type,
    polygon = "polygons",
    line    = "lines",
    point   = "symbols",
    stop("Layer '", key, "' has unsupported type: ",
         if (is.null(sty$type)) "NULL" else sty$type, call. = FALSE)
  )

  if (is.null(cls)) {
    args <- switch(type,
      polygons = tmap_polygon_args(sty),
      lines    = tmap_line_args(sty),
      symbols  = tmap_point_args(sty)
    )
    lab <- if (is.na(label)) to_title(key) else label
    return(list(c(list(type = type, label = lab), args)))
  }

  vals <- cls$values
  nms <- names(vals)
  if (is.null(nms)) nms <- as.character(seq_along(vals))
  keep <- if (is.null(present)) rep(TRUE, length(vals)) else nms %in% present
  if (!any(keep)) {
    return(list())
  }

  # cls$labels is already title-cased by gq_tmap_classes()'s fallback, and an
  # explicit registry label wins over that -- so use it as-is rather than
  # re-casing, which would flatten acronyms like BEC zone codes.
  labs <- if (is.null(cls$labels)) nms else cls$labels
  pick <- function(v, j, fallback = NULL) {
    if (is.null(v) || j > length(v)) return(fallback)
    unname(v[[j]])
  }

  lapply(which(keep), function(j) {
    row <- list(type = type, label = unname(labs[[j]]))
    col <- unname(vals[[j]])
    if (type == "polygons") {
      row$fill <- col
      row$col <- sty$stroke$color
    } else if (type == "lines") {
      row$col <- col
      row$lwd <- pick(cls$widths, j, sty$stroke$width)
      row$lty <- dash_to_lty(pick(cls$dashes, j, sty$stroke$dash))
    } else {
      row$fill <- col
      radius <- pick(cls$radii, j, sty$mark$radius)
      if (!is.null(radius)) row$size <- radius / 3
    }
    row
  })
}


#' Gather rows into the parallel vectors tm_add_legend() expects
#'
#' `tm_add_legend()` takes one vector per aesthetic, with item count set by the
#' longest. A property absent from every row is dropped entirely rather than
#' passed as NA, since tmap treats an explicit NA as "draw nothing" for some
#' aesthetics and as a default for others.
#' @noRd
collect_legend <- function(rows) {
  props <- setdiff(unique(unlist(lapply(rows, names))), "type")
  out <- list()
  for (p in props) {
    vals <- lapply(rows, function(r) if (is.null(r[[p]])) NA else r[[p]])
    if (all(vapply(vals, function(v) length(v) == 1L && is.na(v), logical(1)))) {
      next
    }
    out[[p]] <- unlist(vals, use.names = FALSE)
  }
  names(out)[names(out) == "label"] <- "labels"
  out
}
