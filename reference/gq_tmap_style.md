# Translate a registry layer style to tmap v4 arguments

Takes a single layer entry from the registry and returns a named list of
arguments suitable for tmap v4 layer functions (tm_polygons, tm_lines,
tm_dots).

## Usage

``` r
gq_tmap_style(layer)
```

## Arguments

- layer:

  A layer entry from the registry (e.g., `reg$layers$lake`).

## Value

A named list of tmap arguments. Use with
[`do.call()`](https://rdrr.io/r/base/do.call.html) or `!!!`.

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_registry_read(path)

# Polygon: returns fill, fill_alpha, col, lwd ready for tm_polygons()
gq_tmap_style(reg$layers$lake)
#> $fill
#> [1] "#c6ddf0"
#> 
#> $fill_alpha
#> [1] 0.85
#> 
#> $col
#> [1] "#7ba7cc"
#> 
#> $lwd
#> [1] 0.5
#> 

# Line: returns col, lwd, col_alpha ready for tm_lines()
gq_tmap_style(reg$layers$stream)
#> $col
#> [1] "#7ba7cc"
#> 
#> $lwd
#> [1] 0.4
#> 
#> $col_alpha
#> [1] 0.8
#> 

# Point: returns fill, size ready for tm_dots()
gq_tmap_style(reg$layers$crossing)
#> $fill
#> [1] "#e74c3c"
#> 
#> $size
#> [1] 1.333333
#> 
#> $fill_alpha
#> [1] 0.9
#> 

# Use with tmap v4:
# tm_shape(lakes_sf) + do.call(tm_polygons, gq_tmap_style(reg$layers$lake))
```
