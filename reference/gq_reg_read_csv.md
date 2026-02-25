# Read a gq style registry from CSV

Reads a CSV file and converts it to the same list structure as
[`gq_registry_read()`](https://newgraphenvironment.github.io/gq/reference/gq_registry_read.md).
Multiple rows per `layer_key` with a `class_field` and `class_value`
produce a classification layer. Single rows produce simple
fill/stroke/mark/label styles.

## Usage

``` r
gq_reg_read_csv(path)
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

## Examples

``` r
path <- system.file("registry", "reg_csv_custom.csv", package = "gq")
reg <- gq_reg_read_csv(path)
names(reg$layers)
#> [1] "bec_zone"      "rivers_poly"   "dam"           "town"         
#> [5] "harvest_area"  "planting_site"

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
