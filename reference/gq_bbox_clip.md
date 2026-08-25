# Restrict features to a bounding box, returning NULL when nothing is left

[`tmap::tm_shape()`](https://r-tmap.github.io/tmap/reference/tm_shape.html)
errors with "subscript out of bounds" on an empty geometry set rather
than skipping it, so a map assembled from optional layers has to test
each one. Returning `NULL` rather than a zero-row object lets the caller
write `if (!is.null(x))` once instead of checking
[`nrow()`](https://rdrr.io/r/base/nrow.html) at every use.

## Usage

``` r
gq_bbox_clip(x, bbox, crop = FALSE)
```

## Arguments

- x:

  An `sf` or `sfc` object, or `NULL`.

- bbox:

  A `bbox`, or anything
  [`sf::st_as_sfc()`](https://r-spatial.github.io/sf/reference/st_as_sfc.html)
  accepts.

- crop:

  Cut geometries at the boundary instead of selecting whole features
  that intersect it.

## Value

An object of the same class as `x` with at least one feature, or `NULL`.

## Selecting versus cutting

`crop = FALSE` (the default) keeps whole features that touch the box,
selecting on
[`sf::st_intersects()`](https://r-spatial.github.io/sf/reference/geos_binary_pred.html).
`crop = TRUE` truncates geometries at the boundary, via
[`sf::st_crop()`](https://r-spatial.github.io/sf/reference/st_crop.html).

These are genuinely different maps: a stream leaving the frame is drawn
to its end under the default and stops at the edge under `crop = TRUE`.
Both spellings exist in the reporting repos this was extracted from,
under names close enough to be mistaken for each other, so the
distinction is an argument here rather than two functions a caller might
pick between by accident.

## Examples

``` r
pts <- sf::st_as_sf(
  data.frame(x = c(0, 10), y = c(0, 10)),
  coords = c("x", "y"), crs = 3005
)
bb <- sf::st_bbox(c(xmin = -1, ymin = -1, xmax = 1, ymax = 1), crs = 3005)

nrow(gq_bbox_clip(pts, bb))
#> [1] 1

# nothing in range gives NULL, not a zero-row frame
far <- sf::st_bbox(c(xmin = 100, ymin = 100, xmax = 101, ymax = 101),
                   crs = 3005)
is.null(gq_bbox_clip(pts, far))
#> [1] TRUE
```
