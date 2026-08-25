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
  # as.list(): `[[` on an ATOMIC vector with an unmatched name errors with
  # "subscript out of bounds", where on a list it gives NULL. Both arguments are
  # documented as named character vectors and are looked up per layer or per
  # geometry type, so the documented usage failed whenever the vector did not
  # name every one. `present` was already documented as a list, which is why it
  # alone worked. Coerce once and all three behave alike.
  if (!is.null(field)) field <- as.list(field)
  if (!is.null(titles)) titles <- as.list(titles)
  if (!is.null(present)) present <- as.list(present)

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
    # roads_dra expands to 26 classes carrying 8 distinct appearances -- nine
    # rows all reading "Resource/recreation/other" in the same colour and width.
    # A legend is a list of appearances, not of source classes, so collapse rows
    # that are identical in every aesthetic. Anything that differs anywhere is
    # kept, so this cannot merge two things a reader could tell apart.
    rows <- rows[!duplicated(vapply(rows, function(r) {
      paste(utils::capture.output(utils::str(r[order(names(r))])),
            collapse = "|")
    }, character(1)))]
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
#' `NULL`. Both are needed: `cls` carries `widths` and `dashes`,
#' `sty$classification` carries `radii` and `shapes`, and neither is a superset
#' of the other.
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
    # No $stroke or $mark fallbacks here: gq_style() returns early for a
    # classified layer, so its result carries `type` and `classification` and
    # nothing else. Fallbacks to those fields were unreachable and read as live
    # safety. The visible consequence is that a classified polygon swatch has no
    # outline colour -- the registry does not record one per class.
    if (type == "polygons") {
      row$fill <- col
    } else if (type == "lines") {
      row$col <- col
      row$lwd <- pick(cls$widths, j)
      row$lty <- dash_to_lty(pick(cls$dashes, j))
    } else {
      row$fill <- col
      # Per-class radius comes off gq_style()'s classification, which carries
      # `radii` (and `shapes`); gq_tmap_classes() returns only
      # field/values/labels/widths/dashes. crossings_pscis_assessment is the
      # only layer that has one, and it is the central point layer of every
      # fish passage map -- so reading it from the wrong object dropped size
      # from the legend that needs it most and tmap substituted a default.
      radius <- pick(sty$classification$radii, j)
      if (!is.null(radius)) row$size <- radius / 3
    }
    row
  })
}


#' Aesthetics with no meaningful "absent" value in a parallel vector
#'
#' A parallel vector has to be as long as the labels, so a property that only
#' SOME rows carry cannot express the absence by being shorter. NA is not the
#' way to say it either -- tmap rejects the whole vector at draw time with
#' "missing value where TRUE/FALSE needed", from inside the legend builder and
#' naming nothing.
#'
#' Two live cases, both mixing layers that are individually fine:
#'   * `lty` -- `dash_to_lty()` gives NULL for an undashed class, so `roads_dra`
#'     (16 of 26 undashed) produced `c(NA, ..., "dashed")`.
#'   * `col` / `lwd` -- `lake` has a stroke and `wetland` does not, so any legend
#'     naming both produced `c("#1f78b4", NA)`.
#'
#' The defaults are the "draw nothing visible" value for each aesthetic, which is
#' what absence meant on the row that lacked it.
#' @noRd
legend_na_default <- list(lty = "solid", col = "#00000000", lwd = 0,
                          fill = "#00000000", size = 0)

#' Gather rows into the parallel vectors tm_add_legend() expects
#'
#' `tm_add_legend()` takes one vector per aesthetic, with item count set by the
#' longest. A property absent from every row is dropped entirely rather than
#' passed as NA, since tmap treats an explicit NA as "draw nothing" for some
#' aesthetics and as a default for others.
#'
#' Where only SOME rows lack it, dropping is not available -- the vector has to
#' be as long as the labels -- so a default is substituted for the aesthetics
#' that have one. `roads_dra` is the live case: 16 of its 26 classes are
#' undashed, which produced `lty = c(NA, ..., "dashed")` and a hard tmap error.
#' @noRd
collect_legend <- function(rows) {
  props <- setdiff(unique(unlist(lapply(rows, names))), "type")
  out <- list()
  for (p in props) {
    vals <- lapply(rows, function(r) if (is.null(r[[p]])) NA else r[[p]])

    # Refuse a non-scalar rather than flatten it. unlist() would splice the
    # extra elements in and shift every later entry against its label, giving a
    # legend that is wrong rather than absent -- and the equal-length check a
    # caller might write downstream passes, because every vector is longer by
    # the same amount. Every registry property is scalar today, so nothing built
    # from a registry can trip this; it guards hand-built rows.
    long <- vapply(vals, length, integer(1)) != 1L
    if (any(long)) {
      stop("Legend property '", p, "' is not length 1 for entry ",
           paste(which(long), collapse = ", "), call. = FALSE)
    }

    na <- vapply(vals, function(v) is.na(v), logical(1))
    if (all(na)) next
    if (any(na) && !is.null(legend_na_default[[p]])) {
      vals[na] <- legend_na_default[[p]]
    }
    out[[p]] <- unlist(vals, use.names = FALSE)
  }
  names(out)[names(out) == "label"] <- "labels"
  out
}
