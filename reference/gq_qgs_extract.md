# Extract layer styles from a QGIS project file

Parses a .qgs XML file and extracts symbology (fill, stroke,
classification, labels) for all vector layers into a list suitable for
writing to registry.json.

## Usage

``` r
gq_qgs_extract(path)
```

## Arguments

- path:

  Path to a .qgs file.

## Value

A list with `name`, `version`, `source`, and `layers` elements. Each
layer contains type, source_layer, fill/stroke/classification/label as
applicable.

## Examples

``` r
path <- system.file("examples", "mini_project.qgs", package = "gq")
reg <- gq_qgs_extract(path)

# Shows all layers extracted from the QGIS project
names(reg$layers)
#> [1] "lakes"     "streams"   "crossings" "roads"    

# Polygon layer — fill and stroke extracted from SimpleFill symbol
reg$layers$lakes
#> $type
#> [1] "polygon"
#> 
#> $source_layer
#> [1] "lakes"
#> 
#> $fill
#> $fill$color
#> [1] "#c6ddf0"
#> 
#> $fill$opacity
#> [1] 0.851
#> 
#> 
#> $stroke
#> $stroke$color
#> [1] "#7ba7cc"
#> 
#> $stroke$width
#> [1] 0.5
#> 
#> 

# Categorized layer — classification field and per-class colors
reg$layers$roads$classification
#> $field
#> [1] "road_type"
#> 
#> $classes
#> $classes$highway
#> $classes$highway$color
#> [1] "#c0392b"
#> 
#> $classes$highway$width
#> [1] 2
#> 
#> $classes$highway$label
#> [1] "Highway"
#> 
#> 
#> $classes$arterial
#> $classes$arterial$color
#> [1] "#e67e22"
#> 
#> $classes$arterial$width
#> [1] 1.5
#> 
#> $classes$arterial$label
#> [1] "Arterial"
#> 
#> 
#> 

# Labels — font, size, weight, halo all captured
reg$layers$roads$label
#> $field
#> [1] "road_name"
#> 
#> $font
#> [1] "Arial"
#> 
#> $size
#> [1] 10
#> 
#> $weight
#> [1] "bold"
#> 
#> $color
#> [1] "#1a3c5e"
#> 
#> $halo
#> $halo$color
#> [1] "#ffffff"
#> 
#> $halo$width
#> [1] 1.5
#> 
#> 
```
