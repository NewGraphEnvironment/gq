# Bittner Creek roads

DRA road segments that touch the Bittner Creek watershed's bounding box
widened by 5 km, kept whole rather than clipped, so some run past it.

## Usage

``` r
bittner_roads
```

## Format

An `sf` data frame with columns:

- road_type:

  Transport line type code (RH1, RA1, RA2, etc.)

- geom:

  Linestring geometry (WGS 84)

## Source

BC Digital Road Atlas, from bcfishpass's public GeoParquet copy
