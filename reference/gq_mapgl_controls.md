# Add navigation, a scale bar and a layer switch to a MapLibre GL map

The last call of a gq web map. The layer switch lists the layers by the
names a reader sees, so a layer's id can stay short. The four corners
each get one element: legends top left (from
[`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md)),
the switch at `position`, navigation bottom right and the scale bar
bottom left.

## Usage

``` r
gq_mapgl_controls(
  map,
  layers = NULL,
  position = "top-right",
  navigation = TRUE,
  scale = TRUE
)
```

## Arguments

- map:

  A map from
  [`gq_mapgl_basemap()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_basemap.md).

- layers:

  The layers to switch: a named character vector, label = layer id
  (`c(Habitat = "rules")`), or unnamed ids, which are shown as they are.
  `NULL` switches every layer on the map. `character(0)` adds no switch.

- position:

  The switch's corner.

- navigation:

  Add zoom and compass buttons.

- scale:

  Add a scale bar.

## Value

`map`, with the controls added.

## See also

[`gq_mapgl_layer()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_layer.md)

## Examples

``` r
obs <- neexdzii_fish_obs
m <- gq_mapgl_basemap(neexdzii_wsd, "positron") |>
  gq_mapgl_layer("co", obs[obs$species_code == "CO", "species_code"],
                 color = "#FF7F00", legend_title = "Coho") |>
  gq_mapgl_layer("rb", obs[obs$species_code == "RB", "species_code"],
                 color = "#377EB8", legend_title = "Rainbow trout") |>
  gq_mapgl_controls(c(Coho = "co", "Rainbow trout" = "rb"))
m$x$layers_control$layers
#>          Coho Rainbow trout 
#>          "co"          "rb" 
```
