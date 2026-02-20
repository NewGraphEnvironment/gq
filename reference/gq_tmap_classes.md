# Get a named list of tmap arguments for each class in a classified layer

For categorized/graduated layers, returns the fill or col values
suitable for tmap's scale functions.

## Usage

``` r
gq_tmap_classes(layer)
```

## Arguments

- layer:

  A classified layer entry from the registry.

## Value

A named list with `values` (named color vector), `labels`, and `field`.

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_registry_read(path)

# Extract classification — field name, color vector, and labels
cls <- gq_tmap_classes(reg$layers$road)
cls$field
#> [1] "road_type"
cls$values
#>   highway  arterial 
#> "#c0392b" "#e67e22" 
cls$labels
#> [1] "Highway"  "Arterial"

# Use with tmap v4:
# tm_shape(roads_sf) +
#   tm_lines(
#     col = cls$field,
#     col.scale = tm_scale_categorical(values = cls$values, labels = cls$labels)
#   )
```
