# Getting started with gq

**gq** is a style management system for cartography. Define your map
styles once in a JSON registry, then translate them to any rendering
target — tmap, mapgl, leaflet, ggplot2. Change a color in one place and
every map updates.

## The problem

NGE produces maps across multiple tools — QGIS for field work, tmap for
bookdown reports, MapLibre GL for web maps. Symbology (colors, line
weights, classification breaks) is duplicated manually across each tool.
Change a color in QGIS → manually update R code → manually update web
styles. It doesn’t scale.

## The solution

A canonical style registry that serves as the single source of truth:

    QGIS Project (.qgs)
      ↓ gq_qgs_extract()
    registry.json
      ↓ gq_tmap_style() / gq_mapgl_style()
    tmap, mapgl, leaflet, ggplot2

## Real data: Bittner Creek

gq ships with real spatial data for Bittner Creek near Prince George — a
~56 km² watershed pulled from the BC Freshwater Atlas and bcfishpass via
the newgraph database. This includes the watershed boundary, FWA
streams, lakes, DRA roads, CN railway, and 95 PSCIS fish passage
assessments.

``` r
library(gq)
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.8.4, PROJ 9.4.0; sf_use_s2() is TRUE

data(bittner_wsd, bittner_streams, bittner_lakes,
     bittner_roads, bittner_railway, bittner_pscis,
     package = "gq")

cat("Watershed:", round(bittner_wsd$area_ha), "ha\n")
#> Watershed: 5600 ha
cat("Streams:", nrow(bittner_streams), "segments\n")
#> Streams: 150 segments
cat("Lakes:", nrow(bittner_lakes), "\n")
#> Lakes: 12
cat("Roads:", nrow(bittner_roads), "\n")
#> Roads: 5576
cat("PSCIS crossings:", nrow(bittner_pscis), "\n")
#> PSCIS crossings: 95
```

## Load the style registry

The styles come from a QGIS project extracted with
[`gq_qgs_extract()`](https://newgraphenvironment.github.io/gq/reference/gq_qgs_extract.md).
The registry maps layer names to rendering properties — fill colors,
stroke weights, classification breaks:

``` r
reg_path <- system.file("examples", "demo_registry.json", package = "gq")
reg <- gq_registry_read(reg_path)

# Lake style — fill, stroke, opacity all defined once
reg$layers$lake
#> $type
#> [1] "polygon"
#> 
#> $source_layer
#> [1] "whse_basemapping.fwa_lakes_poly"
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
```

## tmap: static map for reports

[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
converts registry entries directly to tmap v4 arguments. Here’s a study
area map following NGE cartographic conventions:

``` r
library(tmap)
sf_use_s2(FALSE)
#> Spherical geometry (s2) switched off

# Filter streams for display
streams_display <- bittner_streams[bittner_streams$stream_order >= 3, ]

# Roads by class for visual hierarchy
roads_hwy <- bittner_roads[bittner_roads$road_type == "RH1", ]
roads_art <- bittner_roads[bittner_roads$road_type %in% c("RA1", "RA2"), ]

# PSCIS classification from the registry — same colors as QGIS
pscis_cls <- gq_tmap_classes(reg$layers$crossing)

m <- tm_shape(bittner_wsd) +
  do.call(tm_polygons, gq_tmap_style(reg$layers$watershed)) +
tm_shape(bittner_lakes) +
  do.call(tm_polygons, gq_tmap_style(reg$layers$lake)) +
tm_shape(streams_display) +
  do.call(tm_lines, gq_tmap_style(reg$layers$stream)) +
tm_shape(bittner_railway) +
  tm_lines(col = "black", lwd = 1.2) +
tm_shape(bittner_railway) +
  tm_lines(col = "white", lwd = 0.6, lty = "42") +
tm_shape(roads_hwy) +
  tm_lines(col = "#c0392b", lwd = 2.0) +
tm_shape(roads_art) +
  tm_lines(col = "#e67e22", lwd = 1.4) +
tm_shape(bittner_pscis) +
  tm_dots(
    fill = pscis_cls$field,
    fill.scale = tm_scale_categorical(
      values = pscis_cls$values,
      labels = pscis_cls$labels
    ),
    size = 0.3
  ) +
tm_layout(
  frame = TRUE,
  inner.margins = c(0, 0, 0, 0),
  legend.position = c("left", "top"),
  legend.frame = TRUE,
  legend.bg.color = "white",
  legend.bg.alpha = 0.85
)

m
```

![Study area map of Bittner Creek watershed near Prince George showing
streams, lakes, roads, railway, and PSCIS
crossings](gq-intro_files/figure-html/tmap-study-area-1.png)

Every color on that map traces back to the registry. The PSCIS crossing
colors (red = barrier, green = passable, orange = potential, purple =
unknown) match the QGIS project exactly because they come from the same
`registry.json`.

## How the style translation works

The registry stores canonical properties.
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
translates them to tmap’s parameter names:

``` r
# Registry → tmap for a polygon layer
gq_tmap_style(reg$layers$lake)
#> $fill
#> [1] "#dcecf4"
#> 
#> $fill_alpha
#> [1] 0.7
#> 
#> $col
#> [1] "#1f78b4"
#> 
#> $lwd
#> [1] 0.2

# Registry → tmap for a line layer
gq_tmap_style(reg$layers$stream)
#> $col
#> [1] "#7ba7cc"
#> 
#> $lwd
#> [1] 1.2
```

For classified layers,
[`gq_tmap_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_classes.md)
extracts the field name, color vector, and labels — ready for
[`tm_scale_categorical()`](https://r-tmap.github.io/tmap/reference/tm_scale_categorical.html):

``` r
gq_tmap_classes(reg$layers$crossing)
#> $field
#> [1] "barrier_result_code"
#> 
#> $values
#>   BARRIER  PASSABLE POTENTIAL   UNKNOWN 
#> "#ca3c3c" "#33a02c" "#ff7f00" "#bf2ac4" 
#> 
#> $labels
#> [1] "Barrier"           "Passable"          "Potential Barrier"
#> [4] "Unknown"
```

## MapLibre GL: interactive web map

The same registry produces MapLibre GL paint properties for web maps via
[`gq_mapgl_style()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_style.md):

``` r
library(mapgl)

# PSCIS match expression from registry — same classification as tmap
pscis_expr <- gq_mapgl_classes(reg$layers$crossing)

# Watershed style
wsd_style <- gq_mapgl_style(reg$layers$watershed)
lake_style <- gq_mapgl_style(reg$layers$lake)
stream_style <- gq_mapgl_style(reg$layers$stream)

maplibre(
  bounds = as.numeric(st_bbox(bittner_wsd))
) |>
  add_fill_layer(
    id = "watershed",
    source = bittner_wsd,
    fill_color = wsd_style$paint[["fill-color"]],
    fill_opacity = wsd_style$paint[["fill-opacity"]]
  ) |>
  add_fill_layer(
    id = "lakes",
    source = bittner_lakes,
    fill_color = lake_style$paint[["fill-color"]],
    fill_opacity = lake_style$paint[["fill-opacity"]]
  ) |>
  add_line_layer(
    id = "streams",
    source = streams_display,
    line_color = stream_style$paint[["line-color"]],
    line_width = 1
  ) |>
  add_line_layer(
    id = "railway",
    source = bittner_railway,
    line_color = "black",
    line_width = 1.5
  ) |>
  add_line_layer(
    id = "roads-hwy",
    source = roads_hwy,
    line_color = "#c0392b",
    line_width = 2
  ) |>
  add_circle_layer(
    id = "pscis",
    source = bittner_pscis,
    circle_color = pscis_expr,
    circle_radius = 5,
    circle_stroke_color = "white",
    circle_stroke_width = 1
  )
```

The PSCIS crossings use a MapLibre `match` expression built from the
registry:

``` r
str(pscis_expr)
#> List of 11
#>  $ : chr "match"
#>  $ :List of 2
#>   ..$ : chr "get"
#>   ..$ : chr "barrier_result_code"
#>  $ : chr "BARRIER"
#>  $ : chr "#ca3c3c"
#>  $ : chr "PASSABLE"
#>  $ : chr "#33a02c"
#>  $ : chr "POTENTIAL"
#>  $ : chr "#ff7f00"
#>  $ : chr "UNKNOWN"
#>  $ : chr "#bf2ac4"
#>  $ : chr "#888888"
```

Same classification, same colors — one source of truth for both static
and interactive maps.

## Extract from QGIS

If you have an existing QGIS project,
[`gq_qgs_extract()`](https://newgraphenvironment.github.io/gq/reference/gq_qgs_extract.md)
parses the .qgs XML and builds a registry — no PyQGIS needed:

``` r
qgs_path <- system.file("examples", "mini_project.qgs", package = "gq")
extracted <- gq_qgs_extract(qgs_path)
names(extracted$layers)
#> [1] "lakes"     "streams"   "crossings" "roads"
```

Write it out as your registry:

``` r
jsonlite::write_json(extracted, "registry.json", pretty = TRUE, auto_unbox = TRUE)
```

## One source of truth

The workflow:

1.  Design styles in **QGIS** (the best visual tool for cartography)
2.  Extract with
    [`gq_qgs_extract()`](https://newgraphenvironment.github.io/gq/reference/gq_qgs_extract.md)
    → `registry.json`
3.  In R:
    [`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
    for static report maps,
    [`gq_mapgl_style()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_style.md)
    for web
4.  Change a color in the registry → every map updates

No more copy-pasting hex codes across files.
