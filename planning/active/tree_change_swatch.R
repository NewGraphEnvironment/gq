# Tree loss / gain colour choice for gq#98: candidates drawn at 0.7 opacity on the blended
# topographic + shaded relief basemap the #98 palette was chosen on (the website's recipe,
# newgraphenvironment.github.io scripts/figure_helpers.R basemap_of()), beside the oranges
# and the pink-adjacent colours they must read apart from. Writes tree_change_swatch.png
# beside this script. Run from the gq repo root:
#
#   Rscript planning/active/tree_change_swatch.R

sf::sf_use_s2(FALSE)
pkgload::load_all(quiet = TRUE)
library(tmap)

# Bulkley River floodplain between Telkwa and Houston, BC Albers
x0 <- 945000; y0 <- 1061000; half <- 3000
bb <- sf::st_bbox(c(xmin = x0 - half * 1.6, xmax = x0 + half * 1.6,
                    ymin = y0 - half, ymax = y0 + half), crs = sf::st_crs(3005))
topo <- gq_basemap_tiles(bb, provider = "Esri.WorldTopoMap", zoom = 13, pad = 0, crs = 3005)
relief <- gq_basemap_tiles(bb, provider = "Esri.WorldShadedRelief", zoom = 13, pad = 0, crs = 3005)
base <- gq_basemap_blend(topo, relief, method = "gamma", gamma = 1)

swatches <- c(
  "first only #d95f02" = "#d95f02", "valley bottom #f2a93b" = "#f2a93b",
  "crops #e49635" = "#e49635", "outside #7b3f98" = "#7b3f98",
  "gain? #ff8c42" = "#ff8c42", "gain? #ff7f00" = "#ff7f00",
  "gain? #ffab73" = "#ffab73", "gain? #fdd49e" = "#fdd49e",
  "loss? #f781bf" = "#f781bf", "loss? #e7298a" = "#e7298a",
  "loss? #de77ae" = "#de77ae", "loss? #c51b7d" = "#c51b7d"
)
n <- length(swatches); ncol <- 4; w <- 2 * half * 1.6 / ncol; h <- 2 * half / 3
cells <- lapply(seq_len(n), function(i) {
  cx <- x0 - half * 1.6 + ((i - 1) %% ncol) * w; cy <- y0 + half - ((i - 1) %/% ncol + 1) * h
  sf::st_polygon(list(cbind(c(cx, cx + w, cx + w, cx, cx) + c(.2, -.2, -.2, .2, .2) * w,
                            c(cy, cy, cy + h, cy + h, cy) + c(.3, .3, -.05, -.05, .3) * h)))
})
sw <- sf::st_sf(name = factor(names(swatches), levels = names(swatches)),
                geometry = sf::st_sfc(cells, crs = 3005))
lab <- sf::st_centroid(sw); lab$geometry <- lab$geometry - c(0, h * 0.25)
lab <- sf::st_sf(name = lab$name, geometry = sf::st_sfc(lab$geometry, crs = 3005))

m <- tm_shape(base, bbox = bb) + tm_rgb() +
  tm_shape(sw) + tm_polygons(fill = "name", fill_alpha = 0.7, col = NA,
                             fill.scale = tm_scale_categorical(values = unname(swatches)),
                             fill.legend = tm_legend_hide()) +
  tm_shape(lab) + tm_text("name", size = 0.6, bgcol = "white", bgcol_alpha = 0.7) +
  tm_layout(frame = FALSE, inner.margins = 0, outer.margins = 0)
out <- file.path("planning", "active", "tree_change_swatch.png")
tmap_save(m, out, width = 8, height = 5, dpi = 120)
message("wrote ", out)
