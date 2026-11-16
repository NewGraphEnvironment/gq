# Extract layer styles from a QGIS project file

Parses a `.qgs` project, or a `.qlr` layer definition file, and extracts
symbology (fill, stroke, casing, overlay, classification, labels) for
all vector layers into a list suitable for writing to registry.json.
Both formats keep their layers as `<maplayer>` nodes, so one reader
serves both.

## Usage

``` r
gq_qgs_extract(path)
```

## Arguments

- path:

  Path to a .qgs or .qlr file.

## Value

A list with `name`, `version`, `source`, and `layers` elements. Each
layer contains type, source_layer, fill/stroke/casing/overlay/
classification/label as applicable, and a `note` naming any symbol layer
or renderer it does not model.

## Details

The registry models what tmap and mapgl can render, not every property
QGIS stores. A symbol layer it cannot express (a pattern fill, a stacked
marker) and a renderer it does not read are named in the layer's `note`.
Cap and join style and symbol-layer pass order are not read and not
noted. The QML from
[`gq_style_qml()`](https://newgraphenvironment.github.io/gq/reference/gq_style_qml.md)
carries all of it losslessly.

Labels carry the label column as `field`, or the raw QGIS expression as
`expression` when the label is computed (`concat(...)`, `CASE ...`),
never both, so a consumer reading `field` as a column cannot be handed
an expression. `placement` is QGIS's placement mode as a word (`"line"`,
`"around_point"`, ...). `merge_lines` and `min_feature_size` (mm) are
hints for the consumer's data prep: QGIS joins connected lines that
share a label and skips short features, which tmap and MapLibre cannot
do, so dissolve by the label field and drop short features before
drawing.

A symbol's opacity and the layer's own (`<layerOpacity>`) are folded
into every opacity the layer emits, as QGIS composes them.

A label's size is recorded in points and its halo width in millimetres,
converted from QGIS's millimetres or inches where the project uses them.
A size in pixels, map units or a percentage has no fixed print size, so
it is left out and the label's `note` says so.

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

# Labels — field, font, size, weight, halo all captured
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
