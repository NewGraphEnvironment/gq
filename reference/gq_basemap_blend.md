# Multiply a basemap by a relief layer

Shades a flat raster basemap with terrain so relief reads as backdrop
rather than as subject. Both inputs are `terra` rasters; the relief is
resampled onto the basemap grid, reduced to one band if it has several,
and multiplied through.

## Usage

``` r
gq_basemap_blend(
  base,
  relief,
  method = c("gamma", "weight"),
  gamma = 0.5,
  weight = 0.35,
  relief_max = NULL,
  as_stars = TRUE
)
```

## Arguments

- base:

  A `SpatRaster` basemap, values in 0-255. RGB is fine.

- relief:

  A `SpatRaster` relief or hillshade. Multi-band input is averaged to
  one band. Values in 0-255, or 0-1 — see `relief_max`.

- method:

  `"gamma"` or `"weight"`. See details.

- gamma:

  Exponent for `method = "gamma"`. Lower is lighter.

- weight:

  Maximum darkening for `method = "weight"`, in `[0, 1]`.

- relief_max:

  Value corresponding to full brightness in `relief`.
  [`terra::shade()`](https://rspatial.github.io/terra/reference/shade.html)
  returns 0-1; a tile service returns 0-255. Defaults to detecting which
  from the data.

- as_stars:

  Convert the result for
  [`tmap::tm_rgb()`](https://r-tmap.github.io/tmap/reference/tm_rgb.html),
  which takes a `stars` object rather than a `SpatRaster`.

## Value

A `SpatRaster`, or a `stars` object when `as_stars = TRUE`.

## Two operators, deliberately

`"gamma"` raises the normalised relief to a power before multiplying:
`base * relief^gamma`. Lower gamma means lighter shading. This suits a
relief *tile service*, whose values already span the full range.

`"weight"` pulls the relief toward 1 linearly:
`base * (1 - w * (1 - relief))`. `w` is the maximum darkening, so
`w = 0.35` can never remove more than 35% of the basemap's brightness.
This suits a hillshade derived from a DEM, which can be far more
contrasty than a tile service and at full strength turns the map into a
greyscale DEM with lines on it.

Both are in use across the reporting repos, and the two were believed to
be the same operator with different inputs — one implementation says so
in its own documentation. They are not: at the same nominal strength
they produce visibly different maps. Naming them is the point.

## Examples

``` r
if (requireNamespace("terra", quietly = TRUE)) {
  base <- terra::rast(nrows = 4, ncols = 4, vals = 200)
  relief <- terra::rast(nrows = 4, ncols = 4, vals = 128)

  # gamma barely darkens a mid-grey relief
  round(terra::values(gq_basemap_blend(base, relief, as_stars = FALSE))[1])

  # weight caps how much can ever be removed
  round(terra::values(
    gq_basemap_blend(base, relief, method = "weight", as_stars = FALSE)
  )[1])
}
#> [1] 165
```
