# Start a MapLibre GL map on a named basemap, fitted to the data

The first call of a gq web map:
[`mapgl::maplibre()`](https://walker-data.com/mapgl/reference/maplibre.html)
on one of four keyless basemaps, its view fitted to `x`. The layers go
on with
[`gq_mapgl_network()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_network.md)
and
[`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md),
and the switches with
[`gq_mapgl_controls()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_controls.md).

## Usage

``` r
gq_mapgl_basemap(
  x,
  basemap = c("voyager", "positron", "openfreemap", "esri_topo"),
  digits = 5L
)
```

## Arguments

- x:

  The extent to fit: an `sf` or `sfc` in any CRS, or an
  [`sf::st_bbox()`](https://r-spatial.github.io/sf/reference/st_bbox.html).
  Its coordinates are taken to EPSG:4326 and rounded to `digits` decimal
  places, as
  [`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md)
  rounds the layers, so the view fits exactly what is drawn.

- basemap:

  `"voyager"` (Carto Voyager), `"positron"` (Carto Positron, pale grey),
  `"openfreemap"` (OpenFreeMap Liberty) or `"esri_topo"` (Esri World
  Topographic Map raster tiles).

- digits:

  Decimal places kept in the coordinates; 5 is about 1 m.

## Value

A `maplibregl` htmlwidget.

## Details

Esri's World Topographic Map needs no key, and Esri allows free
noncommercial use with attribution, which the map shows: the service's
own credit, after "Powered by Esri".

## See also

[`gq_mapgl_network()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_network.md),
[`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md),
[`gq_mapgl_controls()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_controls.md)

## Examples

``` r
m <- gq_mapgl_basemap(neexdzii_wsd, basemap = "positron")
class(m)
#> [1] "maplibregl" "htmlwidget"
m$x$additional_params$bounds
#> [1] -126.49395   54.49313 -126.11216   54.66072
```
