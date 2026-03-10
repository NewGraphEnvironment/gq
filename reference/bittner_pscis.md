# Bittner Creek PSCIS assessments

Fish passage assessments from PSCIS within expanded Bittner Creek
watershed.

## Usage

``` r
bittner_pscis
```

## Format

An `sf` data frame with columns:

- stream_crossing_id:

  PSCIS crossing identifier

- road_name:

  Road name at crossing

- stream_name:

  Stream name at crossing

- barrier_result_code:

  Assessment result (BARRIER, PASSABLE, POTENTIAL, UNKNOWN)

- geom:

  Point geometry (WGS 84)

## Source

PSCIS via newgraph database
