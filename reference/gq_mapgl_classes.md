# Get a MapLibre match expression for a classified layer

For categorized layers, returns a MapLibre-style match expression
suitable for use in paint properties: each class's colour, or with an
opacity `property`, each class's opacity.

## Usage

``` r
gq_mapgl_classes(layer, property = NULL)
```

## Arguments

- layer:

  A classified layer entry from the registry.

- property:

  The paint property the expression is for. `NULL` or a colour property
  (`"fill-color"`, `"line-color"`, `"circle-color"`) builds the colour
  expression; an opacity property (`"fill-opacity"`, `"line-opacity"`,
  `"circle-opacity"`) builds the opacity one. An outline or stroke
  property is refused: the registry keeps those per class apart from the
  fill.

## Value

A list representing a MapLibre match expression. For opacity, a single
number when every class shares one, which is 1 when no class carries an
opacity.

## Details

A class with no opacity is drawn opaque, not left unknown: the extractor
records opacity only below 1, which is how the tmap translators read it
too.

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_registry_read(path)

# Build a MapLibre match expression for classified roads
expr <- gq_mapgl_classes(reg$layers$road)
# Returns: ["match", ["get", "road_type"], "highway", "#c0392b", "arterial", "#e67e22", "#888888"]
str(expr)
#> List of 7
#>  $ : chr "match"
#>  $ :List of 2
#>   ..$ : chr "get"
#>   ..$ : chr "road_type"
#>  $ : chr "highway"
#>  $ : chr "#c0392b"
#>  $ : chr "arterial"
#>  $ : chr "#e67e22"
#>  $ : chr "#888888"

# Per-class opacity: one number when every class shares it ...
reg_main <- gq_reg_main()
gq_mapgl_classes(reg_main$layers$bec_zone, "fill-opacity")
#> [1] 0.25

# ... and a match expression, 1 for the opaque classes, when they differ
str(gq_mapgl_classes(reg_main$layers$roads_dra, "line-opacity")[1:6])
#> List of 6
#>  $ : chr "match"
#>  $ :List of 2
#>   ..$ : chr "get"
#>   ..$ : chr "transport_line_type_code"
#>  $ : chr "RF"
#>  $ : num 1
#>  $ : chr "RRP"
#>  $ : num 1

# Use with mapgl:
# maplibre() |>
#   add_line_layer(
#     source = roads_src,
#     paint = list("line-color" = expr)
#   )
```
