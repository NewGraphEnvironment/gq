# Translate a registry layer style to mapgl arguments

Takes a single layer entry from the registry and returns a named list
with `paint` and `layout` elements suitable for mapgl's
`add_fill_layer()`, `add_line_layer()`, `add_circle_layer()`, or generic
`add_layer()`.

## Usage

``` r
gq_mapgl_style(layer)
```

## Arguments

- layer:

  A layer entry from the registry (e.g., `reg$layers$lake`).

## Value

A named list with `paint` and optionally `layout` elements.

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_registry_read(path)

# Polygon: returns paint list with fill-color, fill-opacity, fill-outline-color
style <- gq_mapgl_style(reg$layers$lake)
style$layer_type
#> [1] "fill"
style$paint
#> $`fill-color`
#> [1] "#c6ddf0"
#> 
#> $`fill-opacity`
#> [1] 0.85
#> 
#> $`fill-outline-color`
#> [1] "#7ba7cc"
#> 

# Line: returns paint list with line-color, line-width, line-opacity
gq_mapgl_style(reg$layers$stream)
#> $paint
#> $paint$`line-color`
#> [1] "#7ba7cc"
#> 
#> $paint$`line-width`
#> [1] 0.4
#> 
#> $paint$`line-opacity`
#> [1] 0.8
#> 
#> 
#> $layout
#> list()
#> 
#> $layer_type
#> [1] "line"
#> 

# Point: returns paint list with circle-color, circle-radius
gq_mapgl_style(reg$layers$crossing)
#> $paint
#> $paint$`circle-color`
#> [1] "#e74c3c"
#> 
#> $paint$`circle-radius`
#> [1] 4
#> 
#> $paint$`circle-opacity`
#> [1] 0.9
#> 
#> 
#> $layer_type
#> [1] "circle"
#> 

# Use with mapgl:
# maplibre() |>
#   add_fill_layer(source = lakes_src, paint = style$paint)
```
