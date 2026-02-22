# Read a gq style registry from JSON (alias)

Short alias for
[`gq_registry_read()`](https://newgraphenvironment.github.io/gq/reference/gq_registry_read.md).

## Usage

``` r
gq_reg_read(path)
```

## Arguments

- path:

  Path to a registry.json file.

## Value

A list with `name`, `version`, `source`, and `layers` elements.

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_reg_read(path)
names(reg$layers)
#> [1] "lake"     "stream"   "crossing" "road"    
```
