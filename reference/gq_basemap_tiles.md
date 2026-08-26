# Fetch basemap tiles for a bounding box

Thin wrapper over
[`maptiles::get_tiles()`](https://rdrr.io/pkg/maptiles/man/get_tiles.html)
that adds the padding a projected map needs and reprojects the result.

## Usage

``` r
gq_basemap_tiles(
  bbox,
  provider = "Esri.WorldGrayCanvas",
  zoom = 12,
  pad = 0.1,
  crs = 3005
)
```

## Arguments

- bbox:

  A `bbox`. Reprojected to EPSG:4326 for the request.

- provider:

  A `maptiles` provider name. Defaults to a keyless one – Carto's
  basemaps became key-only and now serve a watermark without one. The
  default carries faint place labels of its own that appear as you zoom
  in: none at `zoom = 10` over a BC watershed, lake names by
  `zoom = 12`. Worth a look if you are placing your own labels.

- zoom:

  Tile zoom level.

- pad:

  Fraction of each bbox dimension to expand by before requesting.
  Applied to width and height independently.

- crs:

  CRS to reproject tiles into. `NULL` keeps Web Mercator.

## Value

A `SpatRaster`, or `NULL` if the request failed. A single-colour tile
warns but is still returned.

## Details

Tiles arrive in Web Mercator. Reprojecting them to a projected CRS turns
the covered area into a slightly rotated quadrilateral, so requesting
exactly the frame leaves empty white wedges in the corners. `pad`
requests a larger area so the rotated coverage still spans the frame.
The rotation is a fixed angular effect, so it is proportionally *more*
significant at small extents.

## Placeholder tiles

A tile server can answer HTTP 200 with a structurally valid image that
is not a map. gq detects one such case and cannot detect the other.

**Detected:** a tile of a single flat colour, which warns.
`Esri.WorldTerrain` returns exactly this over parts of BC – every pixel
254, fetched without error. The warning does not suppress the tile,
because a genuinely uniform extent (open ocean) is indistinguishable
from a broken one and dropping it would destroy valid data. `NULL` is
still returned for a real fetch failure.

**Not detected:** a watermarked tile, such as the "API KEY REQUIRED"
image Carto now serves without a key. This is deliberate, not an
oversight. Measured over one bbox at three zooms, the fraction of dark
pixels was 0.0073 for a *clean* tile and 0.0068 for a *watermarked* one
– the watermark is a small share of pixels and ordinary map content
swamps it, so no threshold separates them. A detector built on that
would pass watermarked tiles while looking like a check, which is worse
than no check at all.

The guard against that class is choosing keyless providers and looking
at the rendered figure. See the live canary in
`test-gq_basemap_tiles.R`.

## Examples

``` r
if (FALSE) { # interactive() && requireNamespace("maptiles", quietly = TRUE)
bb <- sf::st_bbox(
  c(xmin = 1e6, ymin = 9e5, xmax = 1.02e6, ymax = 9.2e5),
  crs = 3005
)
tiles <- gq_basemap_tiles(bb, zoom = 11)
}
```
