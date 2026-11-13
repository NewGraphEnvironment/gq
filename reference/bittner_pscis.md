# Bittner Creek PSCIS assessments

Fish passage assessments from PSCIS within the Bittner Creek watershed's
bounding box widened by 2 km, so some fall outside the watershed.

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

PSCIS assessments, from the BC Data Catalogue
