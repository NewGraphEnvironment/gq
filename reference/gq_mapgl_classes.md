# Get a MapLibre match expression for a classified layer

For categorized layers, returns a MapLibre-style match expression
suitable for use in paint properties.

## Usage

``` r
gq_mapgl_classes(layer, property = NULL)
```

## Arguments

- layer:

  A classified layer entry from the registry.

- property:

  The paint property to set (e.g., "fill-color", "line-color",
  "circle-color").

## Value

A list representing a MapLibre match expression.

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

# Use with mapgl:
# maplibre() |>
#   add_line_layer(
#     source = roads_src,
#     paint = list("line-color" = expr)
#   )
```
