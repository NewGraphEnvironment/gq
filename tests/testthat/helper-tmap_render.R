# Helpers for asking tmap what it actually drew.
#
# Every other test in this suite inspects a list gq built. That cannot see how
# tmap interprets it -- #53 was exactly that gap: tm_scale_categorical() matches
# colours by name but labels by POSITION, so a correct-looking list drew the
# wrong labels. Reading the rendered grob tree is the only way to catch it.

# Walk a rendered map once, returning both the text drawn and the colours used.
#
# tmap_grob() needs an open device, hence the png()/dev.off() dance. Legend
# titles come back among the labels (the field name), and the colours include
# tmap's own frame and background -- callers should test membership rather than
# equality against the whole vector.
#
# Colours are read from the grob tree rather than from rendered pixels
# deliberately: pixel comparison confounds a label change with legend
# re-layout, which sent three probes down the wrong path while investigating
# #53. It also would have cost a png dependency for no gain.
drawn_parts <- function(m) {
  f <- tempfile(fileext = ".png")
  grDevices::png(f)
  g <- suppressMessages(tmap::tmap_grob(m))
  grDevices::dev.off()
  unlink(f)

  labels <- character(0)
  colours <- character(0)
  walk <- function(x) {
    if (inherits(x, "text")) labels <<- c(labels, as.character(x$label))
    if (!is.null(x$gp)) {
      colours <<- c(colours, as.character(x$gp$col), as.character(x$gp$fill))
    }
    if (!is.null(x$children)) for (ch in x$children) walk(ch)
  }
  walk(g)

  keep <- function(x) unique(x[!is.na(x) & nzchar(x)])
  # nzchar(NA) is TRUE, so the is.na() term is load-bearing, not belt-and-braces.
  list(labels = keep(labels), colours = toupper(keep(colours)))
}

drawn_labels <- function(m) drawn_parts(m)$labels

# Read one graphical parameter off the drawn geometry grobs.
#
# `what` is a gpar name ("lwd", "lty"). Restricted to the grob class carrying
# the geometry so tmap's frame and legend furniture do not contribute.
#
# Render ONE feature at a time when asserting a per-class value. A multi-feature
# render returns values in draw order, which is level order rather than feature
# order -- so comparing the returned vector against the input order passes on a
# coincidence and fails to notice a mapping that is right only as a set.
drawn_gp <- function(m, what, grob_class = "polyline") {
  f <- tempfile(fileext = ".png")
  grDevices::png(f)
  g <- suppressMessages(tmap::tmap_grob(m))
  grDevices::dev.off()
  unlink(f)

  out <- NULL
  walk <- function(x) {
    if (inherits(x, grob_class) && !is.null(x$gp[[what]])) {
      out <<- c(out, x$gp[[what]])
    }
    if (!is.null(x$children)) for (ch in x$children) walk(ch)
  }
  walk(g)
  out
}

# Render a registry layer over the given codes with gq's own legend settings
# left alone (classified layers hide their legend). Use this when reading
# geometry gpar -- render_classified() forces the legend on, and legend keys are
# polyline grobs too, so they would pollute a drawn_gp("lwd") read.
tm_shape_classified <- function(reg, key, codes, field = "code") {
  type <- reg$layers[[key]]$type
  args <- gq_tmap_style(reg, key, field = field)
  fn <- switch(type, line = tmap::tm_lines, polygon = tmap::tm_polygons,
               tmap::tm_dots)
  tmap::tm_shape(geom_for(type, codes, field)) + do.call(fn, args)
}

# Minimal sf carrying one row per code, with geometry matching a layer type.
geom_for <- function(type, codes, field) {
  n <- length(codes)
  geom <- switch(type,
    point = sf::st_sfc(lapply(seq_len(n), function(i) sf::st_point(c(i, i)))),
    line = sf::st_sfc(lapply(seq_len(n), function(i) {
      sf::st_linestring(cbind(c(i, i + 0.5), c(i, i + 0.5)))
    })),
    polygon = sf::st_sfc(lapply(seq_len(n), function(i) {
      sf::st_polygon(list(cbind(c(i, i + 1, i + 1, i, i),
                                c(i, i, i + 1, i + 1, i))))
    })),
    stop("Unsupported type: ", type)
  )
  d <- sf::st_sf(code = codes, geometry = sf::st_sfc(geom, crs = 3005))
  names(d)[1] <- field
  d
}

# Render a registry layer over data carrying `codes`, with the legend forced ON.
#
# gq_tmap_style() sets tm_legend(show = FALSE) on classified layers -- the
# legend is expected to come from gq_tmap_legend(). Reading labels therefore
# means overriding that, which is also the real-world case where the defect is
# visible: a caller who turns the legend back on.
render_classified <- function(reg, key, codes, field = "code") {
  type <- reg$layers[[key]]$type
  args <- gq_tmap_style(reg, key, field = field)
  d <- geom_for(type, codes, field)

  if (type == "line") {
    args$col.legend <- tmap::tm_legend(show = TRUE)
    fn <- tmap::tm_lines
  } else if (type == "polygon") {
    args$fill.legend <- tmap::tm_legend(show = TRUE)
    fn <- tmap::tm_polygons
  } else {
    args$fill.legend <- tmap::tm_legend(show = TRUE)
    fn <- tmap::tm_dots
  }
  tmap::tm_shape(d) + do.call(fn, args)
}
