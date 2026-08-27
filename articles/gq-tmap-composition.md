# Map composition with gq and tmap

gq translates registry styles into tmap arguments. This vignette shows a
complete map composition — basemap, layers, legend, logo, keymap —
following New Graph cartographic conventions.

## Study area: Neexdzii Kwa subbasin

A subbasin of the Neexdzii Kwa (Upper Bulkley River) in the traditional
territory of the Wet’suwet’en, bounded by Johnny David Creek
(downstream) and Richfield Creek (upstream). ~212 km², pulled from the
BC Freshwater Atlas via
[fresh](https://github.com/NewGraphEnvironment/fresh).

``` r

library(gq)
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE
library(tmap)

sf_use_s2(FALSE)
#> Spherical geometry (s2) switched off

data(neexdzii_wsd, neexdzii_streams, neexdzii_habitat,
     neexdzii_lakes, neexdzii_wetlands,
     neexdzii_crossings, neexdzii_fish_obs, neexdzii_falls,
     neexdzii_roads, neexdzii_railway, neexdzii_bc, neexdzii_wsg,
     package = "gq")

cat("Watershed:", round(as.numeric(st_area(neexdzii_wsd)) / 10000), "ha\n")
#> Watershed: 21218 ha
cat("Streams:", nrow(neexdzii_streams), "| Habitat:", nrow(neexdzii_habitat), "\n")
#> Streams: 1074 | Habitat: 397
cat("Crossings:", nrow(neexdzii_crossings), "| Fish obs:", nrow(neexdzii_fish_obs),
    "| Falls:", nrow(neexdzii_falls), "\n")
#> Crossings: 146 | Fish obs: 63 | Falls: 5
cat("Lakes:", nrow(neexdzii_lakes), "| Wetlands:", nrow(neexdzii_wetlands), "\n")
#> Lakes: 42 | Wetlands: 175
cat("Roads:", nrow(neexdzii_roads), "| Railway:", nrow(neexdzii_railway), "\n")
#> Roads: 44 | Railway: 1
```

## Load styles from the registry

One call to
[`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)
loads the master registry.
[`gq_style()`](https://newgraphenvironment.github.io/gq/reference/gq_style.md)
resolves any layer by name — no manual color extraction needed.

``` r

reg <- gq_reg_main()

# gq_style() returns backend-agnostic style info by name
gq_style(reg, "lake")
#> $type
#> [1] "polygon"
#> 
#> $fill
#> $fill$color
#> [1] "#dcecf4"
#> 
#> $fill$opacity
#> [1] 0.7
#> 
#> 
#> $stroke
#> $stroke$color
#> [1] "#1f78b4"
#> 
#> $stroke$width
#> [1] 0.2
gq_style(reg, "railway")
#> $type
#> [1] "line"
#> 
#> $stroke
#> $stroke$color
#> [1] "#000000"
#> 
#> $stroke$width
#> [1] 0.4

# gq_tmap_style() wraps gq_style() with tmap-specific args
# For classified layers it wires up tm_scale_categorical() automatically
gq_tmap_style(reg, "crossings_pscis_assessment")
#> $fill
#> [1] "barrier_result_code"
#> 
#> $fill.scale
#> $FUN
#> [1] "tmapScaleCategorical"
#> 
#> $n.max
#> [1] 30
#> 
#> $values
#>   BARRIER  PASSABLE POTENTIAL   UNKNOWN 
#> "#ca3c3c" "#33a02c" "#ff7f00" "#bf2ac4" 
#> 
#> $values.repeat
#> [1] TRUE
#> 
#> $values.range
#> [1] NA
#> 
#> $values.scale
#> [1] NA
#> 
#> $value.na
#> [1] NA
#> 
#> $value.null
#> [1] NA
#> 
#> $value.neutral
#> [1] NA
#> 
#> $levels
#> [1] "BARRIER"   "PASSABLE"  "POTENTIAL" "UNKNOWN"  
#> 
#> $levels.drop
#> [1] TRUE
#> 
#> $labels
#> [1] "Barrier"   "Passable"  "Potential" "Unknown"  
#> 
#> $label.na
#> [1] NA
#> 
#> $label.null
#> [1] NA
#> 
#> $label.format
#> list()
#> 
#> attr(,"class")
#> [1] "tm_scale_categorical" "tm_scale"             "list"                
#> 
#> $fill.legend
#> $show
#> [1] FALSE
#> 
#> $called
#> [1] "show"
#> 
#> $title
#> [1] NA
#> 
#> $xlab
#> [1] NA
#> 
#> $ylab
#> [1] NA
#> 
#> $group_id
#> [1] NA
#> 
#> $group_type
#> [1] "tm_legend"
#> 
#> $z
#> [1] NA
#> 
#> attr(,"class")
#> [1] "tm_legend"    "tm_component" "list"        
#> 
#> $size
#> [1] "barrier_result_code"
#> 
#> $size.scale
#> $FUN
#> [1] "tmapScaleCategorical"
#> 
#> $n.max
#> [1] 30
#> 
#> $values
#> [1] 0.7874016 0.7874016 0.7874016 0.7874016
#> 
#> $values.repeat
#> [1] TRUE
#> 
#> $values.range
#> [1] NA
#> 
#> $values.scale
#> [1] NA
#> 
#> $value.na
#> [1] NA
#> 
#> $value.null
#> [1] NA
#> 
#> $value.neutral
#> [1] NA
#> 
#> $levels
#> [1] "BARRIER"   "PASSABLE"  "POTENTIAL" "UNKNOWN"  
#> 
#> $levels.drop
#> [1] TRUE
#> 
#> $labels
#> NULL
#> 
#> $label.na
#> [1] NA
#> 
#> $label.null
#> [1] NA
#> 
#> $label.format
#> list()
#> 
#> attr(,"class")
#> [1] "tm_scale_categorical" "tm_scale"             "list"                
#> 
#> $size.legend
#> $show
#> [1] FALSE
#> 
#> $called
#> [1] "show"
#> 
#> $title
#> [1] NA
#> 
#> $xlab
#> [1] NA
#> 
#> $ylab
#> [1] NA
#> 
#> $group_id
#> [1] NA
#> 
#> $group_type
#> [1] "tm_legend"
#> 
#> $z
#> [1] NA
#> 
#> attr(,"class")
#> [1] "tm_legend"    "tm_component" "list"
```

## Data prep

Filter streams by order and build label points. Where the bundled data
comes from a different source than the registry (e.g., bcfishpass vs
WHSE), the `field` parameter in
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
maps the alternative column name to the same style — no column renames
needed. See `inst/registry/xref_layers.csv` for the cross-reference.

``` r

# Streams: order >= 3 for display, >= 5 for labels
streams_display <- neexdzii_streams[neexdzii_streams$stream_order >= 3, ]

# Stream labels: dissolve named streams to single point per name
streams_named <- neexdzii_streams[
  !is.na(neexdzii_streams$gnis_name) & neexdzii_streams$stream_order >= 5, ]

if (nrow(streams_named) > 0) {
  stream_labels <- do.call(rbind, lapply(
    split(streams_named, streams_named$gnis_name),
    function(x) {
      combined <- st_union(x)
      pt <- st_point_on_surface(combined)
      st_sf(gnis_name = x$gnis_name[1], geometry = pt, crs = st_crs(x))
    }
  ))
} else {
  stream_labels <- streams_named[0, ]
}
#> although coordinates are longitude/latitude, st_union assumes that they are
#> planar
#> Warning in st_point_on_surface.sfc(combined): st_point_on_surface may not give
#> correct results for longitude/latitude data
#> although coordinates are longitude/latitude, st_union assumes that they are
#> planar
#> Warning in st_point_on_surface.sfc(combined): st_point_on_surface may not give
#> correct results for longitude/latitude data

# Lake labels
lakes_named <- neexdzii_lakes[!is.na(neexdzii_lakes$gnis_name_1) &
                                neexdzii_lakes$gnis_name_1 != "", ]
```

## Basemap: gray canvas x hillshade blend

A muted raster basemap gives terrain relief without competing with our
own labels. At sub-watershed scale a gray canvas blended with hillshade
works well.

Note the zoom. `Esri.WorldGrayCanvas` carries faint place labels of its
own, which appear as you zoom in — at `zoom = 10` over this area none
are visible, at `zoom = 12` lake names are. If you raise the zoom, check
the basemap is not competing with the labels you place yourself.

Pick a **keyless** provider deliberately. This vignette used Carto’s
Positron until Carto made their basemaps key-only and began serving an
“API KEY REQUIRED” watermark instead — which is a valid image, so
nothing errored and the watermarked map shipped to the published site
(gq#57).

``` r

# Pad the bbox to the canvas aspect ratio (7:9) so the map fills the page. The
# latitude correction a geographic CRS needs is applied from the CRS rather
# than by hand -- this data is lat/lon, so it fires here and would not in BC
# Albers.
bbox <- gq_bbox_aspect(neexdzii_wsd, asp = 7 / 9)

canvas <- gq_basemap_tiles(bbox, provider = "Esri.WorldGrayCanvas",
                           zoom = 10, pad = 0, crs = NULL)
relief <- gq_basemap_tiles(bbox, provider = "Esri.WorldShadedRelief",
                           zoom = 10, pad = 0, crs = NULL)

# gq_basemap_tiles() returns NULL on a failed fetch so the caller can draw an
# unshaded map rather than lose the figure. Honour that here rather than only
# documenting it -- a tile hiccup during a pkgdown build should not fail it.
#
# Build the whole LAYER conditionally, not just the data. tm_shape() rejects
# NULL outright ("not a recognized/supported spatial data class"), so setting
# the stars object to NULL and passing it on only moves the failure sixty lines
# down -- the guard reads as if it works and does not. `NULL + tm_shape(...)`
# composes fine, so an absent layer is the shape that actually holds.
basemap <- if (is.null(canvas) || is.null(relief)) {
  NULL
} else {
  # A relief tile service spans the full range, so the gamma operator suits it.
  # A hillshade derived from a DEM is far more contrasty and wants
  # `method = "weight"`, which caps how much brightness can be removed.
  tm_shape(gq_basemap_blend(canvas, relief, method = "gamma", gamma = 0.5)) +
    tm_rgb()
}

# Now that the frame is known, drop anything outside it. gq_bbox_clip() returns
# NULL rather than a zero-row object, which is what tm_shape() needs -- it
# errors on an empty geometry set instead of skipping it.
streams_display <- gq_bbox_clip(streams_display, bbox)
#> although coordinates are longitude/latitude, st_intersects assumes that they
#> are planar
```

## Keymap inset

Small overview map showing the subbasin within the Bulkley/Morice
watershed groups and BC.

``` r

# Watershed group fill matches lake stroke color from registry
lake_sty <- gq_style(reg, "lake")

keymap <- tm_shape(neexdzii_bc) +
  tm_borders(col = "grey60", lwd = 0.5) +
tm_shape(neexdzii_wsg) +
  tm_polygons(fill = lake_sty$stroke$color, fill_alpha = 0.5,
              col = lake_sty$stroke$color, lwd = 0.5) +
tm_shape(neexdzii_wsd) +
  tm_polygons(fill = "#ef4545", col = "#ef4545", lwd = 0.3) +
tm_layout(
  frame = TRUE,
  bg.color = "white",
  inner.margins = c(0.02, 0.02, 0.02, 0.02)
)
```

## Main map

Draw order matters: polygons first, then habitat lines, base streams,
lakes on top, transport, point features (crossings, fish, falls), then
labels last.

``` r

bb_box <- st_as_sfc(bbox, crs = st_crs(neexdzii_wsd))
logo_path <- system.file("logo", "nge_icon_200.png", package = "gq")

tmap_mode("plot")
#> ℹ tmap modes "plot" - "view"
#> ℹ toggle with `tmap::ttm()`

# Pull styles from registry — all colors trace back to gq_reg_main()
stream_sty <- gq_style(reg, "streams_all")
railway_sty <- gq_style(reg, "railway")
fish_sty <- gq_style(reg, "bcfishobs_fiss_fish_observations")
falls_sty <- gq_style(reg, "fiss_obstacles")
lake_sty <- gq_style(reg, "lake")

# Polygon layers — do.call() with gq_tmap_style() directly
# Contain the AOI. Without this, inside and outside the watershed render
# identically and only a thin boundary line separates them, so the subject of
# the map is not visually obvious -- a reader has to be told where to look.
# Knocking back everything outside does that without hiding the context, which
# a hard clip would.
#
# Note the frame is 41% padding by height, split evenly above and below (7:9
# portrait against a ~1.32:1 landscape watershed). That padding is where the
# scalebar, logo, legend and keymap live, so it is element space rather than
# waste -- but it only reads that way once the AOI itself stands out.
aoi_mask <- sf::st_difference(bb_box, sf::st_geometry(neexdzii_wsd))
#> although coordinates are longitude/latitude, st_difference assumes that they
#> are planar

m <- basemap +
tm_shape(bb_box) +
  tm_borders(lwd = 0, col = NA) +
tm_shape(aoi_mask) +
  tm_polygons(fill = "white", fill_alpha = 0.45, col = NA, lwd = 0) +
tm_shape(neexdzii_wsd) +
  tm_polygons(fill_alpha = 0, col = "#2c3e50", lwd = 1.5) +
tm_shape(neexdzii_wetlands) +
  do.call(tm_polygons, gq_tmap_style(reg, "wetland"))

# Salmon habitat — classified by mapping_code (xref: streams_salmon_vw uses
# mapping_code, registry expects mapping_code_salmon from WHSE source)
m <- m +
tm_shape(neexdzii_habitat) +
  do.call(tm_lines, gq_tmap_style(reg, "streams_salmon", field = "mapping_code"))

# Base streams on top of habitat — simple style, width scaled up for display.
# gq_bbox_clip() returns NULL when nothing survives the frame, so test for it
# rather than handing tm_shape() an empty geometry set — the same guard the
# basemap uses above, and the one the file already applies to railway and falls.
if (!is.null(streams_display)) {
  m <- m +
    tm_shape(streams_display) +
    tm_lines(col = stream_sty$classification$values[[1]],
             lwd = stream_sty$classification$widths[[1]] * 2)
}
m <- m +
tm_shape(neexdzii_lakes) +
  do.call(tm_polygons, gq_tmap_style(reg, "lake"))

# Lake labels — color from registry
if (nrow(lakes_named) > 0) {
  m <- m + tm_shape(lakes_named) +
    tm_text("gnis_name_1", size = 0.7, col = lake_sty$stroke$color,
            fontface = "italic",
            options = opt_tm_text(shadow = TRUE))
}

# Roads — classified by transport_line_type_code, bundled data column is
# road_type (xref: alias from data-raw query)
m <- m +
tm_shape(neexdzii_roads) +
  do.call(tm_lines, gq_tmap_style(reg, "roads_dra", field = "road_type"))

# Railway — base + white dashed overlay, colors from registry
if (nrow(neexdzii_railway) > 0) {
  m <- m + tm_shape(neexdzii_railway) +
    tm_lines(col = railway_sty$stroke$color,
             lwd = railway_sty$stroke$width * 2) +
  tm_shape(neexdzii_railway) +
    tm_lines(col = "white", lwd = railway_sty$stroke$width, lty = "42")
}

# Crossings — classified by barrier_status (xref: bcfishpass.crossings uses
# barrier_status, registry expects barrier_result_code from PSCIS WHSE)
#
# An editorial decision, and the reason for it: 130 of these 146 crossings are
# POTENTIAL -- modelled candidates for assessment rather than surveyed sites.
# At their true registry size (3 mm, correct since #16) they are 89% of the
# point symbols on the map and they bury the stream network the habitat
# classification exists to describe. QGIS never shows this because you would be
# zoomed in; a static overview has to choose.
#
# So this map shows the assessed inventory and says so. The modelled crossings
# are not wrong and are not mis-sized -- they are a different map's subject.
# Note what is NOT done here: hand-tuning `size` down for one class would
# reintroduce exactly the per-map guessing #16 removed.
crossings_assessed <- neexdzii_crossings[
  neexdzii_crossings$barrier_status != "POTENTIAL", ]

m <- m +
tm_shape(crossings_assessed) +
  do.call(tm_dots, gq_tmap_style(reg, "crossings_pscis_assessment",
                                  field = "barrier_status"))

# Fish observations — colour, size AND shape now all come from the registry.
# These two layers hardcoded `size` and `shape` until #16: the registry carries
# a mark shape for 15 layers that nothing translated, and its millimetre sizes
# converted through a guessed divisor, so every map hand-tuned its own numbers.
# `col` is still set to the fill colour to give the symbol a matching edge.
if (nrow(neexdzii_fish_obs) > 0) {
  fish_args <- gq_tmap_style(reg, "bcfishobs_fiss_fish_observations")
  m <- m + tm_shape(neexdzii_fish_obs) +
    do.call(tm_symbols, c(fish_args, list(col = fish_sty$mark$color)))
}

# Falls — same, straight from the registry
if (nrow(neexdzii_falls) > 0) {
  falls_args <- gq_tmap_style(reg, "fiss_obstacles")
  m <- m + tm_shape(neexdzii_falls) +
    do.call(tm_symbols, c(falls_args, list(col = falls_sty$mark$color)))
}

# Stream labels
if (nrow(stream_labels) > 0) {
  m <- m + tm_shape(stream_labels) +
    tm_text("gnis_name", size = 0.65, fontface = "italic", col = "#1a5276",
            options = opt_tm_text(shadow = TRUE, remove_overlap = TRUE))
}

# Legends from the registry. gq_tmap_legend() partitions by geometry type,
# expands classified layers to one entry per class, merges simple and classified
# layers of the same type into one legend, and collapses classes that render
# identically. `present` cuts road classes to the ones the data actually has.
# Salmon habitat is the most prominent linework on this map, and it was absent
# from this list until #61 -- the reader saw red dominating the figure with
# nothing saying what red meant, while the prose below described its widths and
# dashes in detail. Building the legend from the layer list answers "did I list
# my layers", which always says yes. The check that catches this is the other
# direction: rank what draws the eye in the rendered image, then confirm each of
# those is here.
#
# `present` cuts each classified layer to the classes its data actually carries.
# Habitat drops its `;INTERMITTENT` variants too -- they differ from their solid
# twins by a dash alone, and carrying all twelve would put eighteen entries in
# one box on a figure published about 700 px wide. The dash is explained once in
# prose instead. Note this is a narrowing decision, not a collapse:
# gq_tmap_legend() keys its dedup on the whole row including the label, so the
# repeated colours here do not merge on their own.
habitat_classes <- unique(neexdzii_habitat$mapping_code)
habitat_legend <- grep(";INTERMITTENT$", habitat_classes,
                       value = TRUE, invert = TRUE)

leg <- gq_tmap_legend(
  reg,
  c("Lake" = "lake", "Wetland" = "wetland", "Stream" = "streams_all",
    "streams_salmon",
    "roads_dra", "Railway" = "railway",
    "crossings_pscis_assessment",
    "Fish obs" = "bcfishobs_fiss_fish_observations",
    "Falls" = "fiss_obstacles"),
  present = list(roads_dra = unique(neexdzii_roads$road_type),
                 streams_salmon = habitat_legend,
                 crossings_pscis_assessment = unique(
                   crossings_assessed$barrier_status))
)

m <- Reduce(`+`, c(list(m), lapply(leg, function(x) do.call(tm_add_legend, x))))

# Layout: four-corner rule -- each element gets a corner of its own.
#
# The scalebar sat at bottom-CENTRE until #16, which is not a corner: it is the
# gap between the bottom-left legend and the bottom-right keymap. That survived
# only while the legend was narrow. Once the symbols grew to their true registry
# sizes the legend got taller and wider, overlapped the bar and clipped its own
# last entry. Top-left was the free corner all along.
# - Legend:   bottom-left
# - Logo:     top-right
# - Scalebar: top-left
# - Keymap:   bottom-right (via grid viewport)
#
# Bottom-left is where "legend over least-important terrain" lands here, and it
# was settled by rendering both, not by reasoning. Top-left looks like the
# better corner -- the upper band is empty ground outside the AOI -- but a
# nineteen-row legend hung from it reaches down over the northwest arm and hides
# the barrier crossings, which are the most important points on the map. The
# bottom-left box overlaps the southwest arm instead, where nothing is
# obscured. Read the PNG; the emptiest corner of the frame is not necessarily
# the least important.
m <- m +
tm_scalebar(
  # gq_scale_breaks() needs metre units and says so, so project the bbox first
  breaks = gq_scale_breaks(st_bbox(st_transform(st_as_sfc(bbox), 3005))),
  text.size = 0.7,
  position = c("left", "top"),
  margins = c(0, 0, 0, 0)
) +
tm_logo(logo_path, position = c("right", "top"), height = 2.5,
        margins = c(0, 0, 0, 0)) +
tm_layout(
  frame = TRUE,
  frame.lwd = 0.5,
  asp = 0,
  legend.position = c("left", "bottom"),
  legend.frame = TRUE,
  legend.bg.color = "white",
  legend.bg.alpha = 0.85,
  # Sized for the width the figure is PUBLISHED at, not the width it is
  # rendered at. A 7 in figure lands in roughly a 700 px column, so it is scaled
  # to about 60% -- text set to look right in the render is a few pixels on the
  # page.
  legend.text.size = 0.7,
  legend.title.size = 0.8,
  inner.margins = c(0.001, 0.001, 0.001, 0.001),
  outer.margins = c(0.003, 0.003, 0.003, 0.003),
  meta.margins = 0
)

print(m)
# gq_tmap_keymap() supplies the PLACEMENT here, not the map: it derives the
# viewport centre from the corner and margin and sizes it off the canvas aspect,
# which is the arithmetic every hand-rolled inset hardcodes. Its own two-layer
# map is discarded in favour of `keymap` above, which carries a third layer
# (watershed groups) that the (aoi, context) signature cannot express.
km <- gq_tmap_keymap(neexdzii_wsd, neexdzii_bc, asp = 7 / 9)
print(keymap, vp = km$viewport)
```

![Map of a Neexdzii Kwa subbasin showing salmon habitat, crossings, fish
observations, streams, lakes, wetlands, roads, and railway styled from
the gq
registry](gq-tmap-composition_files/figure-html/map-composition-1.png)

Neexdzii Kwa subbasin: salmon habitat classified by use and barrier
status, over the assessed PSCIS crossing inventory. Every colour, width
and dash resolves from the gq registry.

Every color on this map traces back to
[`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md):

- **Simple layers** (lake, wetland) use `gq_tmap_style(reg, "name")`
  directly. Streams and railway are drawn by hand because each needs
  something the registry does not model — one class pulled out of a
  classified layer, and a white casing over a black line
- **Classified layers** (crossings, roads, habitat) use
  [`do.call()`](https://rdrr.io/r/base/do.call.html) with
  [`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
  — classification field, colors, labels, **line widths and dashes** all
  come from the registry. Labels follow the classes the data actually
  carries: the registry’s 26 road classes are matched to the handful
  present rather than recycled positionally over them (#53). Every
  aesthetic is mapped per class, so salmon habitat draws spawning,
  rearing and access reaches at their three registry widths and
  intermittent reaches dashed — the `mapping_code` layers encode habitat
  use in width and barrier status in colour, and both axes render (#36)
- **The legend** is built by
  [`gq_tmap_legend()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_legend.md)
  from the registry — it partitions by geometry type, expands classified
  layers, collapses classes that render identically, and cuts each
  classified layer to the classes present in the data. Change a colour
  in the registry and every element updates

**Reading the habitat lines.** Width is habitat use — spawning is
widest, accessible-only is thinnest — and colour is the barrier status
downstream. A **dashed** line of any width or colour is an intermittent
reach. The legend lists the solid variants only: each dashed class
differs from its solid twin by the dash alone, so showing both would
double the habitat entries to explain one distinction. That is a
deliberate narrowing rather than something
[`gq_tmap_legend()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_legend.md)
did on its own — its dedup keys on the whole entry including the label,
so classes sharing a colour do not merge by themselves.
