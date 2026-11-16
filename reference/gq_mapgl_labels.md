# Translate a registry label to mapgl symbol-layer arguments

Returns a named list of `add_symbol_layer()` arguments that draw a
layer's registry label: the column, size, colour, halo, placement and
offset. Splice it in with
[`do.call()`](https://rdrr.io/r/base/do.call.html), as
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
is used.

## Usage

``` r
gq_mapgl_labels(layer, field = NULL)
```

## Arguments

- layer:

  A layer entry from the registry (e.g., `reg$layers$lake`).

- field:

  Optional column to label with. Required when the registry labels the
  layer with a QGIS expression (`label$expression`), which MapLibre
  cannot evaluate: compute it as a column first. Also required for a
  label from the custom CSV, which names no column.

## Value

A named list of `add_symbol_layer()` arguments: `text_field`,
`symbol_placement`, and `text_size`, `text_color`, `text_opacity`,
`text_halo_color`, `text_halo_width`, `text_offset` where the registry
gives them.

## Details

Sizes follow QGIS: the registry holds the font size in points and the
halo width in millimetres, converted here to MapLibre's pixels at 96
dpi. A line label (`placement` `"line"`, `"curved"`, `"perimeter"` or
`"perimeter_curved"`) follows its line. QGIS's `merge_lines` and
`min_feature_size` are not applied, and MapLibre does not merge labels
across features: dissolve by the label column and drop short features
first. The font family and slant are left to the basemap's glyphs,
because MapLibre can only draw a font its glyph server carries; pass
`text_font` to choose one.

## Examples

``` r
reg <- gq_reg_main()

# Lake names: 10 pt in QGIS, 13.33 px in MapLibre, with a white halo
str(gq_mapgl_labels(reg$layers$lake))
#> List of 6
#>  $ text_field      :List of 2
#>   ..$ : chr "get"
#>   ..$ : chr "gnis_name_1"
#>  $ symbol_placement: chr "point"
#>  $ text_size       : num 13.3
#>  $ text_color      : chr "#1f78b4"
#>  $ text_halo_color : chr "#ffffff"
#>  $ text_halo_width : num 1.13

# Stream names follow the stream
gq_mapgl_labels(reg$layers$stream_labels)$symbol_placement
#> [1] "line"

# Towns come from the custom CSV, which names no column
str(gq_mapgl_labels(reg$layers$town, field = "name"))
#> List of 7
#>  $ text_field      :List of 2
#>   ..$ : chr "get"
#>   ..$ : chr "name"
#>  $ symbol_placement: chr "point"
#>  $ text_size       : num 12
#>  $ text_color      : chr "#2c3e50"
#>  $ text_halo_color : chr "white"
#>  $ text_halo_width : num 1.51
#>  $ text_offset     : num [1:2] 0 1.2

# Use with mapgl:
# do.call(mapgl::add_symbol_layer, c(
#   list(map = m, id = "lake-labels", source = lakes_sf),
#   gq_mapgl_labels(reg$layers$lake)
# ))
```
