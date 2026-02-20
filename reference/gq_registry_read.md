# Read a gq style registry from JSON

Loads a registry.json file into an R list. The registry maps layer names
to style definitions (fill, stroke, classification, labels).

## Usage

``` r
gq_registry_read(path)
```

## Arguments

- path:

  Path to a registry.json file.

## Value

A list with `name`, `version`, `source`, and `layers` elements.

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_registry_read(path)

# What layers are available?
names(reg$layers)
#> [1] "lake"     "stream"   "crossing" "road"    

# Inspect a single layer — fill color, stroke, opacity all in one place
reg$layers$lake
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
#> [1] 0.85
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
```
