# Read a gq custom style registry

Reads a hand-curated CSV file and converts it to the same list structure
as
[`gq_registry_read()`](https://newgraphenvironment.github.io/gq/reference/gq_registry_read.md).
Multiple rows per `layer_key` with a `class_field` and `class_value`
produce a classification layer. Single rows produce simple
fill/stroke/mark/label styles.

## Usage

``` r
gq_reg_custom(path)
```

## Arguments

- path:

  Path to a CSV file with columns: layer_key, type, source_layer,
  class_field, class_value, fill_color, fill_opacity, stroke_color,
  stroke_width, stroke_opacity, mark_color, mark_shape, mark_radius,
  mark_stroke_color, mark_stroke_width, label_color, label_size,
  label_font, label_halo_color, label_halo_width, label_offset_x,
  label_offset_y, note.

## Value

A list with `name`, `version`, `source`, and `layers` elements,
compatible with
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md),
[`gq_mapgl_style()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_style.md),
etc.

## Raster layers

A `type` of `"raster"` carries a QGIS paletted renderer: one row per
palette entry, `class_value` holding the band value and `class_label`
the palette label. `habitat_lateral` is the shipped example.

`class_field` is a **sentinel** for a raster, not a column name. The
classification branch here requires a non-NA `class_field`, and a
paletted raster keys on pixel value rather than on any attribute — so
the convention is the literal string `"value"`, meaning band 1. A
consumer with a real band name passes it through `gq_style(field = )`.

Give `class_value` at least one non-numeric value across the file, or
accept that [`read.csv()`](https://rdrr.io/r/utils/read.table.html) will
type the column as integer; the reader coerces back to character, but a
numeric column reads as an ordinal in every other tool.

What a raster row **cannot** carry: QGIS's per-value
`rasterTransparency` (`habitat_lateral` sets 30% on top of the
renderer's 0.4 opacity), multi-band renderers, and resampling. Those
live in the QML, which is lossless — reach for
[`gq_style_qml()`](https://newgraphenvironment.github.io/gq/reference/gq_style_qml.md)
whenever the consumer is QGIS itself.

The tmap and mapgl translators do not render rasters.
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md),
[`gq_mapgl_style()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_style.md)
and
[`gq_mapgl_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_classes.md)
all refuse a raster rather than returning something plausible;
[`gq_tmap_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_classes.md)
works, since a palette is a classification like any other.

## Examples

``` r
path <- system.file("registry", "reg_custom.csv", package = "gq")
reg <- gq_reg_custom(path)
names(reg$layers)
#> [1] "bec_zone"                    "rivers_poly"                
#> [3] "dam"                         "town"                       
#> [5] "harvest_area"                "planting_site"              
#> [7] "old_growth_management_areas" "national_park"              
#> [9] "habitat_lateral"            

# Classified layer (multiple rows per layer_key)
reg$layers$bec_zone$classification$field
#> [1] "ZONE"
names(reg$layers$bec_zone$classification$classes)
#>  [1] "SBS"  "ESSF" "ICH"  "BWBS" "CWH"  "MS"   "SBPS" "SWB"  "AT"   "MH"  
#> [11] "BG"  

# Simple layer (single row)
reg$layers$rivers_poly$fill
#> $color
#> [1] "#7ba7cc"
#> 
#> $opacity
#> [1] 0.7
#> 
```
