# Neexdzii Kwa salmon habitat

Modelled salmon habitat segments from bcfishpass within the Neexdzii Kwa
subbasin, fetched via network query.

## Usage

``` r
neexdzii_habitat
```

## Format

An `sf` data frame with columns including:

- gnis_name:

  Stream name

- stream_order:

  Strahler stream order

- mapping_code:

  Habitat mapping code (e.g. SPAWN;NONE, REAR;MODELLED)

- spawning:

  Spawning habitat indicator

- rearing:

  Rearing habitat indicator

- access:

  Access type (e.g. ACCESSIBLE)

- geom:

  Linestring geometry (WGS 84)

## Source

bcfishpass via newgraph database and fresh package
