# Build an overview keymap and the viewport to place it in

A keymap is a small inset showing where the mapped area sits in a wider
region. This returns the inset as its own `tmap` object plus a
[`grid::viewport()`](https://rdrr.io/r/grid/viewport.html) positioning
it, so the caller prints the main map and then the keymap over it.

## Usage

``` r
gq_tmap_keymap(
  aoi,
  context,
  reg = NULL,
  aoi_layer = "watershed_group_boundary",
  context_layer = NULL,
  corner = c("bottomright", "bottomleft", "topright", "topleft"),
  width = 0.25,
  height = 0.22,
  asp = NULL,
  margin = 0.03
)
```

## Arguments

- aoi:

  The area of interest — the thing being located.

- context:

  Wider context, drawn beneath.

- reg:

  A registry for the fill and stroke colours. Defaults to
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md).
  The copies this replaces all hardcode hex here, including one that
  takes a registry argument and then does not use it.

- aoi_layer:

  Registry key supplying the AOI style.

- context_layer:

  Registry key supplying the context style, or `NULL` for a neutral
  grey. Grey is the default because the context is a backdrop: the
  registry has no province-outline layer, and the nearest candidates are
  greens that leave a green AOI barely legible on top.

- corner:

  Which corner to place the inset in.

- width:

  Width as a fraction of the device.

- height:

  Height as a fraction of the device. Ignored when `asp` is given.

- asp:

  Canvas aspect ratio (`fig.width / fig.height`). When supplied,
  `height` is computed as `width * asp` so the inset renders square.

- margin:

  Gap between the inset and the frame edge, as a fraction of the device
  width. The four-corner convention wants this equal for every element,
  so when `asp` is supplied the vertical gap is derived from it the same
  way `height` is — otherwise a single device fraction is 29% larger
  horizontally than vertically on a 9x7 canvas.

## Value

A list with `map` (a `tmap` object) and `viewport` (a
[`grid::viewport()`](https://rdrr.io/r/grid/viewport.html)). Print `map`
into `viewport` after the main map.

## Why a viewport rather than a component

tmap has no inset-map component, so every implementation of this prints
a second `tmap` object into a viewport. The placement arithmetic is
where they diverge — each of the copies this replaces hardcodes a
different pair of centre coordinates, and a viewport's `x`/`y` are its
*centre*, so the numbers are not the margin they look like. `corner` and
`margin` compute them, so moving a keymap between corners does not mean
re-deriving them by eye.

## Sizing

`width` and `height` are fractions of the *device*, so on a non-square
canvas equal fractions do not give a square inset. Pass `asp` — the
canvas width/height — and the height is derived so the inset comes out
square. On the 9x7 canvas the fish passage maps use, the alternative is
an inset 1.46 times wider than tall.

## Examples

``` r
aoi <- sf::st_as_sfc(sf::st_bbox(
  c(xmin = 1.0e6, ymin = 9.0e5, xmax = 1.1e6, ymax = 1.0e6), crs = 3005
))
context <- sf::st_as_sfc(sf::st_bbox(
  c(xmin = 0.5e6, ymin = 5.0e5, xmax = 1.8e6, ymax = 1.4e6), crs = 3005
))

km <- gq_tmap_keymap(aoi, context)
class(km$map)
#> [1] "tmap"

# bottom-right by default, and the viewport centre reflects the margin
round(c(km$viewport$x, km$viewport$y), 3)
#> [1] 0.845 0.140

# on a 9x7 canvas, asp makes the inset square IN INCHES -- the viewport
# fractions are not equal, because the device is not square
sq <- gq_tmap_keymap(aoi, context, asp = 9 / 7)
round(c(w_in = as.numeric(sq$viewport$width) * 9,
        h_in = as.numeric(sq$viewport$height) * 7), 3)
#> w_in h_in 
#> 2.25 2.25 
```
