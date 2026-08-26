# Translate a registry symbol shape to a rendering target

The registry carries a `shape` on every mark — `circle`, `square`,
`star` and `triangle` are the complete vocabulary across all three
registry files. Until \#16 no renderer consumed it, so maps hardcoded
their own marker codes.

## Usage

``` r
gq_symbol_shape(shape, target = c("tmap", "mapgl"))
```

## Arguments

- shape:

  Registry shape string, or `NULL`.

- target:

  One of `"tmap"` or `"mapgl"`.

## Value

For `"tmap"`, an integer `pch`. For `"mapgl"`, `NULL`. `NULL` in gives
`NULL` out.

## Details

`star` maps to `pch = 8`, which draws a star with **strokes only** and
ignores `fill` entirely. R has no filled star — its fillable symbols
(21–25) are circle, square, diamond, triangle-up and triangle-down.
Substituting a filled circle would silently discard the distinction that
made the layer a star in QGIS, so the unfillable code is returned and
callers are expected to set `col` rather than `fill`;
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
does this. Use
[`gq_symbol_fillable()`](https://newgraphenvironment.github.io/gq/reference/gq_symbol_fillable.md)
to ask.

`mapgl` returns `NULL` for every shape. A MapLibre `circle` layer has no
shape concept at all; anything else requires a `symbol` layer with an
icon sprite, which the registry has no source data for. `NULL` says "not
expressible here" rather than handing back a `pch` number the renderer
cannot read.

## See also

[`gq_symbol_size()`](https://newgraphenvironment.github.io/gq/reference/gq_symbol_size.md)

## Examples

``` r
gq_symbol_shape("circle", "tmap")
#> [1] 21
gq_symbol_shape("triangle", "tmap")
#> [1] 24
gq_symbol_shape("star", "tmap")       # 8 -- stroked, never filled
#> [1] 8
gq_symbol_fillable("star")            # FALSE
#> [1] FALSE
```
