# Convert a registry symbol size to a rendering target's units

The registry's `radius` field is a **diameter**, in millimetres. The
name is a misnomer inherited at extraction:
[`gq_qgs_extract()`](https://newgraphenvironment.github.io/gq/reference/gq_qgs_extract.md)
reads the QGIS `SimpleMarker` option literally named `size` — the
marker's overall extent — and stores it under `radius`. Every point QML
in the corpus confirms it by carrying `scale_method = "diameter"`
alongside.

## Usage

``` r
gq_symbol_size(
  radius,
  target = c("tmap", "mapgl"),
  shape = "circle",
  scale = 1
)
```

## Arguments

- radius:

  Registry size in millimetres. May be a named vector (a classified
  layer's per-class sizes), `NA`, or `NULL` for a layer that defines no
  mark at all. Names are preserved, because `tm_scale_categorical()`
  matches values by name.

- target:

  One of `"tmap"` or `"mapgl"`.

- shape:

  Registry shape, for `target = "tmap"`. Defaults to `"circle"`, which
  is what tmap itself draws when no shape is given.

- scale:

  Uniform multiplier applied after conversion. The knob for a dense map
  that needs every symbol smaller — one number applied once, rather than
  a hand-tuned value per layer, which is what this function exists to
  replace.

## Value

A numeric vector in the target's units, or `NULL` if `radius` is `NULL`.

## Details

Each target measures symbols differently:

- `"tmap"`:

  Depends on `shape`. tmap sizes symbols in grid "lines" (5.08 mm), but
  R's graphics engine then applies a per-`pch` factor, and base R
  normalises those by *area* where QGIS normalises by *extent*. A circle
  draws 3.81 mm of ink per size unit, a square 3.38, a triangle 5.13.
  Passing the wrong shape leaves the symbol 11–35% out.

- `"mapgl"`:

  MapLibre's `circle-radius` is a true **radius**, in CSS pixels — so
  the value is halved and converted at 96 px per inch. `shape` does not
  apply: a MapLibre `circle` layer has only circles.

A constant `circle-radius` is deliberate for mapgl, not a
simplification: it holds a fixed screen size at every zoom, which is
exactly QGIS marker semantics. An interpolated expression would be a
departure from the registry, not a correction to it.

## See also

[`gq_symbol_shape()`](https://newgraphenvironment.github.io/gq/reference/gq_symbol_shape.md)

## Examples

``` r
# A 3 mm circular marker, drawn as 3 mm of ink
gq_symbol_size(3, "tmap")
#> [1] 0.7874016

# The same millimetres as a square need a different size, because base R
# normalises pch by area and QGIS by extent
gq_symbol_size(3, "tmap", shape = "square")
#> [1] 0.8885814

gq_symbol_size(3, "mapgl")           # circle-radius in CSS pixels
#> [1] 5.669291
gq_symbol_size(3, "tmap", scale = 0.5)
#> [1] 0.3937008

# Per-class sizes keep their names
gq_symbol_size(c(BARRIER = 3, PASSABLE = 2), "tmap")
#>   BARRIER  PASSABLE 
#> 0.7874016 0.5249344 
```
