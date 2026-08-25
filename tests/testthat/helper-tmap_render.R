# Helpers for asking tmap what it actually drew.
#
# Every other test in this suite inspects a list gq built. That cannot see how
# tmap interprets it -- #53 was exactly that gap: tm_scale_categorical() matches
# colours by name but labels by POSITION, so a correct-looking list drew the
# wrong labels. Reading the rendered grob tree is the only way to catch it.

# Collect every text label tmap draws, in draw order.
#
# tmap_grob() needs an open device, hence the png()/dev.off() dance. Legend
# titles come back too (the field name) -- callers should test membership
# rather than equality against the whole vector.
drawn_labels <- function(m) {
  f <- tempfile(fileext = ".png")
  grDevices::png(f)
  g <- suppressMessages(tmap::tmap_grob(m))
  grDevices::dev.off()
  unlink(f)

  out <- character(0)
  walk <- function(x) {
    if (inherits(x, "text")) out <<- c(out, as.character(x$label))
    if (!is.null(x$children)) for (ch in x$children) walk(ch)
  }
  walk(g)
  # nzchar(NA) is TRUE, so the is.na() term is load-bearing, not belt-and-braces.
  unique(out[!is.na(out) & nzchar(out)])
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
