# Neexdzii Kwa stream network

FWA stream segments within the Neexdzii Kwa subbasin, fetched via
network query (not spatial clip).

## Usage

``` r
neexdzii_streams
```

## Format

An `sf` data frame with columns including:

- gnis_name:

  Stream name from BC geographic names

- stream_order:

  Strahler stream order

- geom:

  Linestring geometry (WGS 84)

## Source

BC Freshwater Atlas via newgraph database and fresh package
