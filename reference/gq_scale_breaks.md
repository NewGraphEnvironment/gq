# Scale bar breaks appropriate to a map extent

Returns breaks in kilometres, rounded to a 1/2/5 sequence so the bar
reads cleanly at any extent.

## Usage

``` r
gq_scale_breaks(bbox, n = 3, share = 0.35)
```

## Arguments

- bbox:

  A `bbox` in a projected CRS with metre units. A geographic bbox has
  degree spans, so the returned breaks would not be kilometres.

- n:

  Number of intervals.

- share:

  Fraction of the frame width the whole bar should occupy.

## Value

A numeric vector of length `n + 1`, starting at 0, in kilometres.

## Details

The whole bar is sized to at most `share` of the frame width — *not*
`share` per interval. Sizing per interval overruns the frame, at which
point tmap reports "not all scale bar breaks could be plotted" and then
silently drops every label but the last, which looks like a styling
problem rather than a sizing one.

`share` is a **bound**, not a target: the step is the largest 1/2/5
value that fits, so the bar is always at or under it. Rounding to the
*nearest* nice value instead overruns by up to 1.39x, which is the
failure the bound exists to prevent.

## Examples

``` r
bb <- sf::st_bbox(
  c(xmin = 1e6, ymin = 9e5, xmax = 1.1e6, ymax = 1e6),
  crs = 3005
)
gq_scale_breaks(bb)
#> [1]  0 10 20 30

# a wider extent steps up to the next round number
wide <- bb
wide[["xmax"]] <- wide[["xmin"]] + 400000
gq_scale_breaks(wide)
#> [1]  0 20 40 60
```
