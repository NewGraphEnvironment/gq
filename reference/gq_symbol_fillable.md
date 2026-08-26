# Does a registry shape accept a fill colour?

`star` does not: R has no filled star, so it renders as `pch = 8`, which
is stroked only. A caller that sets `fill` and not `col` on a star gets
tmap's default outline instead of the registry colour — the layer
silently loses its styling.
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
uses this to decide which argument to set.

## Usage

``` r
gq_symbol_fillable(shape)
```

## Arguments

- shape:

  Registry shape string, or `NULL`.

## Value

`TRUE` or `FALSE`. Unknown or absent shapes return `TRUE`, matching
tmap's default circle.

## See also

[`gq_symbol_shape()`](https://newgraphenvironment.github.io/gq/reference/gq_symbol_shape.md)

## Examples

``` r
gq_symbol_fillable("circle")
#> [1] TRUE
gq_symbol_fillable("star")
#> [1] FALSE
```
