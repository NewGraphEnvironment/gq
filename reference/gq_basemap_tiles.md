# Fetch basemap tiles for a bounding box

Thin wrapper over
[`maptiles::get_tiles()`](https://rdrr.io/pkg/maptiles/man/get_tiles.html)
that adds the padding a projected map needs and reprojects the result.

## Usage

``` r
gq_basemap_tiles(
  bbox,
  provider = "CartoDB.PositronNoLabels",
  zoom = 12,
  pad = 0.1,
  crs = 3005
)
```

## Arguments

- bbox:

  A `bbox`. Reprojected to EPSG:4326 for the request.

- provider:

  A `maptiles` provider name.

- zoom:

  Tile zoom level.

- pad:

  Fraction of each bbox dimension to expand by before requesting.
  Applied to width and height independently.

- crs:

  CRS to reproject tiles into. `NULL` keeps Web Mercator.

## Value

A `SpatRaster`, or `NULL` if the request failed.

## Details

Tiles arrive in Web Mercator. Reprojecting them to a projected CRS turns
the covered area into a slightly rotated quadrilateral, so requesting
exactly the frame leaves empty white wedges in the corners. `pad`
requests a larger area so the rotated coverage still spans the frame.
The rotation is a fixed angular effect, so it is proportionally *more*
significant at small extents.

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
