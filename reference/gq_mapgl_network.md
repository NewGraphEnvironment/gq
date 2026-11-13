# Add water and a stream network to a MapLibre GL map, styled from the registry

Lakes and rivers take the registry's `lake` style, and streams the
`streams_all` style, drawn wider by stream order so a mainstem reads
over its headwaters. Water goes on first, so streams draw over it.

## Usage

``` r
gq_mapgl_network(
  map,
  streams = NULL,
  water = NULL,
  reg = gq_reg_main(),
  ids = c(water = "gq_water", streams = "gq_streams"),
  order_field = "stream_order",
  widths = c(0.6, 3),
  legend = FALSE,
  digits = 5L
)
```

## Arguments

- map:

  A map from
  [`gq_mapgl_basemap()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_basemap.md).

- streams:

  An `sf` of stream lines, or `NULL`.

- water:

  An `sf` of lake and river polygons, or `NULL`. Keep only the columns
  you need: every one is written into the page.

- reg:

  A registry, as from
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md).

- ids:

  Source and layer ids, `c(water = , streams = )`. Name them to switch
  them in
  [`gq_mapgl_controls()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_controls.md).

- order_field:

  The stream order column of `streams`.

- widths:

  Line width in pixels at order 1 and at order 6 and above.

- legend:

  Add a legend for each layer drawn: `Lake`, and the stream classes the
  network holds, or one row named by the registry's first class
  (`Stream`) when it carries no `feature_code`.

- digits:

  Decimal places kept in the coordinates; 5 is about 1 m.

## Value

`map`, with the layers added.

## Details

`streams_all` is classified by FWA `feature_code`. A network carrying
that column is coloured class by class; one without it, as from a
`fwa_stream_networks_sp` query that leaves the code out, is drawn as the
registry's first class, `Stream`, at its opacity.

## See also

[`gq_mapgl_basemap()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_basemap.md),
[`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md)

## Examples

``` r
reg <- gq_reg_main()
m <- gq_mapgl_basemap(neexdzii_wsd, "positron") |>
  gq_mapgl_network(streams = neexdzii_streams[c("gnis_name", "stream_order")],
                   water = neexdzii_lakes["gnis_name_1"], reg = reg)
vapply(m$x$layers, `[[`, "", "id")
#> [1] "gq_water"   "gq_streams"
```
