# Pad a bounding box to a target aspect ratio

A map whose bbox does not match its canvas aspect ratio renders with
white bands along two edges — the most common cause of dead space in a
saved map. This pads the *shorter* dimension until the box matches the
canvas, then adds a small margin so features never touch the frame.

## Usage

``` r
gq_bbox_aspect(x, asp, margin = 0.02)
```

## Arguments

- x:

  An `sf`/`sfc` object or a `bbox`.

- asp:

  Target width/height, i.e. `fig.width / fig.height`.

- margin:

  Fraction of each dimension added on all sides so features do not touch
  the frame. Applied after the aspect padding, so it does not change the
  ratio.

## Value

A `bbox` with the same CRS as `x`.

## Details

Padding is symmetric, so the original extent stays centred.

## Geographic versus projected input

In a geographic CRS a degree of longitude is shorter than a degree of
latitude by `cos(latitude)`, so the ratio of coordinate spans is not the
ratio of ground distances and the correction is required. In a projected
CRS the coordinates are already linear and applying it would skew the
result.

The branch is taken from the CRS rather than offered as an argument,
because the two implementations this replaces each hardcoded one answer
and neither knew the other case existed. A bbox with an unknown CRS is
treated as projected — the coordinates are all that is known, so use
them as given.

The correction uses the mid-latitude, so it is exact only there. Over a
box a few degrees tall that is immaterial; over one spanning tens of
degrees it is not — [`cos()`](https://rdrr.io/r/base/Trig.html) runs
from 0.71 to 0.34 between 45N and 70N — and no single scalar can be
right for the whole extent. Project the data before framing it if the
extent is that large, which is what a map at that scale wants anyway.

## Examples

``` r
bb <- sf::st_bbox(
  c(xmin = 1e6, ymin = 9e5, xmax = 1.1e6, ymax = 1e6),
  crs = 3005
)
out <- gq_bbox_aspect(bb, asp = 7 / 9)

# the padded box carries the ratio that was asked for
round(unname((out["xmax"] - out["xmin"]) / (out["ymax"] - out["ymin"])), 4)
#> [1] 0.7778
```
