# Add a styled layer and its legend to a MapLibre GL map

Draws one `sf` layer on a gq web map, styled from a registry key, from
classes the caller names, or from one colour, and adds its categorical
legend tied to the layer, so the legend hides when the layer is switched
off in
[`gq_mapgl_controls()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_controls.md).

## Usage

``` r
gq_mapgl_layer(
  map,
  id,
  x = NULL,
  source = id,
  key = NULL,
  classes = NULL,
  color = NULL,
  reg = NULL,
  field = NULL,
  type = NULL,
  width = NULL,
  widths = c(0.6, 3),
  radius = NULL,
  opacity = NULL,
  legend = TRUE,
  legend_title = id,
  popup = NULL,
  visible = TRUE,
  digits = 5L,
  ...
)
```

## Arguments

- map:

  A map from
  [`gq_mapgl_basemap()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_basemap.md).

- id:

  The layer id: what
  [`gq_mapgl_controls()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_controls.md)
  switches, and the legend's `layer_id`.

- x:

  An `sf` to draw, or `NULL` to draw a source already on the map. gq
  checks the data a layer draws: its geometry, and that every column the
  style or popup reads is there. A source it cannot read without
  fetching it (vector tiles, PMTiles, a GeoJSON URL) is drawn unchecked,
  and needs `type` unless `key` gives it. Its coordinates are taken to
  EPSG:4326 and rounded to `digits`; keep only the columns the style and
  popup read, since every one is written into the page.

- source:

  The source id. Defaults to `id`; name an existing source with
  `x = NULL` to draw it again.

- key:

  A registry layer key, such as `"lake"` or `"bec_zone"`.

- classes:

  Classes the caller names, a list of `field` (the column), `values`
  (the values matched), `colors` (one per value), and optionally
  `labels` (the legend's names, default `values`) and `default` (the
  colour of anything else, default `"#cccccc"`).

- color:

  One colour for every feature, when there is no `key` or `classes`.

- reg:

  A registry, as from
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md);
  read only with `key`.

- field:

  Overrides the registry layer's classification field, as in
  [`gq_style()`](https://newgraphenvironment.github.io/gq/reference/gq_style.md),
  when the data names the column differently. A registry layer's legend
  lists only the classes found in this column of `x`.

- type:

  `"line"`, `"fill"` or `"circle"`. Read from the data's geometry when
  not given; a type given must agree with it, except `"line"` over
  polygons, which draws their outlines.

- width:

  A line width in pixels, a MapLibre expression, or the name of a stream
  order column, which draws order 1 at `widths[1]` pixels and order 6
  and above at `widths[2]`.

- widths:

  Width in pixels at order 1 and at order 6, for a `width` column.

- radius:

  A circle radius in pixels, or a MapLibre expression such as one that
  grows with zoom.

- opacity:

  An opacity for every feature, overriding the registry's.

- legend:

  Add the layer's legend.

- legend_title:

  The legend's title, or for one colour the row's name. Defaults to
  `id`.

- popup:

  A column name, or the `expr` of
  [`gq_mapgl_popup()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_popup.md).

- visible:

  `FALSE` adds the layer switched off.

- digits:

  Decimal places kept in the coordinates; 5 is about 1 m.

- ...:

  Further arguments to the mapgl layer function, such as
  `circle_stroke_color`, `filter` or `before_id`.

## Value

`map`, with the layer and its legend added.

## Details

Several layers can draw one source: pass the data once with `x`, then
add the next layer with `x = NULL` and the same `source`. Each layer is
a separate switch, as in a map that colours one set of segments two
ways.

Colours are given to MapLibre as hex. R colour names such as `grey80`
draw in tmap but MapLibre cannot read them and drops the whole layer, so
they are converted here.

Legends stack down the top-left corner in the order the layers were
added, and a hidden layer's legend leaves no gap. mapgl draws every
legend at the corner itself, one over another, so gq adds a stylesheet
beside the map that lets them flow. A one-colour layer's legend is a
single row named by `legend_title`, with no title above it.

## See also

[`gq_mapgl_popup()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_popup.md),
[`gq_mapgl_controls()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_controls.md),
[`gq_mapgl_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_classes.md)

## Examples

``` r
obs <- neexdzii_fish_obs
m <- gq_mapgl_basemap(neexdzii_wsd, "positron") |>
  gq_mapgl_layer("lakes", neexdzii_lakes["gnis_name_1"], key = "lake",
                 reg = gq_reg_main(), legend_title = "Lake") |>
  gq_mapgl_layer("Coho", obs[obs$species_code == "CO", "species_code"],
                 color = "#FF7F00", radius = 6) |>
  gq_mapgl_layer("Rainbow trout", obs[obs$species_code == "RB", "species_code"],
                 color = "steelblue", radius = 6)
vapply(m$x$layers, `[[`, "", "id")
#> [1] "lakes"         "Coho"          "Rainbow trout"
m$x$layers[[3]]$paint[["circle-color"]]     # a colour name, sent as hex
#> [1] "#4682B4"
```
