# Findings — Restoration template layers are never downloaded (#40)

## Issue context

## Problem

Nine layers across the two shipped QGIS templates point at tables that
`gq_template_layers()` never lists, so a project built from the template
displays cartography for data that was never downloaded.

For `bcrestoration_mobile` (7 layers) the cause is **not** missing registry
entries — 5 of the 7 already have symbology in `reg_main.json` *and* a
`groups.csv` row. They break one join later: their groups are not mapped to the
template in `templates.csv`.

```
groups.csv                                                       source_type
  Other Point Features   fiss_obstacles                           aws
  Other Point Features   bcfishobs_fiss_fish_observations         bcdata
  Other Point Features   fiss_stream_sample_sites                 bcdata
  Other Point Features   hydrometric_stations_environment_canada  aws
  Base - Orthoimagery    orthophoto_tiles                         bcdata

templates.csv, groups mapped to bcrestoration_mobile
  Forms, Crossings, Streams, Roads/Rails/Pipelines, Basemap,
  Floodplain, Restoration, Web Mapping Services, Base - misc
```

`Other Point Features` is mapped to `bcfishpass_mobile` only; `Base -
Orthoimagery` is mapped to neither template.

The remaining two — `national_park` and `old_growth_management_areas` — have no
`groups.csv` row at all and need real registry work. `bcfishpass_mobile`'s 2
missing layers are these same two.

## Proposed Solution

**1. Two rows in `templates.csv`** covers 5 of the 7:

```csv
bcrestoration_mobile,Other Point Features,<order>
bcrestoration_mobile,Base - Orthoimagery,<order>
```

**2. Registry entries for the two genuinely missing layers.** Evidence that they
are wanted rather than incidental — `gq_qgs_extract()` run across a corpus of 16
QGIS projects (1024 layer entries, 220 distinct `source_layer` values) finds both,
corroborated across independent projects:

| source_layer | projects using it |
|---|---|
| `whse_land_use_planning.rmp_ogma_non_legal_current_svw` | **6 of 16** |
| `whse_admin_boundaries.clab_national_parks` | 2 of 16 |

OGMA is the most-used layer in the corpus that the registry does not carry.

**3. Decide per layer: wanted or retired.** Where a layer is not wanted, remove
it from the template so the cartography does not outlive the data.

## Other candidates from the same sweep

Information, not a recommendation — the corpus includes older projects, so some
of this is stale or one-off. Of 178 `source_layer` values absent from
`reg_main`, only 19 are schema-qualified BC data layers; the rest are
project-local (forms, GPS imports, year-stamped copies) or unqualified names.
Corroborated by 2+ projects:

| source_layer | projects |
|---|---|
| `whse_land_use_planning.rmp_ogma_non_legal_current_svw` | 6 |
| `whse_fish.wdic_waterbody_route_line_svw` | 3 |
| `bcfishobs.observations` | 2 |
| `whse_admin_boundaries.clab_national_parks` | 2 |
| `whse_basemapping.bcgs_5k_grid` | 2 |

Separately worth knowing: 6 layers appear under **unqualified** names
(`transport_line`, `fwa_named_streams`, `fwa_watershed_groups_poly`,
`ften_road_section_lines_svw`, `fiss_obstacles_pnt_sp`,
`fiss_fish_obsrvtn_events_vw`) in older projects. Those are tables the registry
already carries, from before the schema-prefix convention — duplicates in
disguise rather than new layers.

## Context

Consumers now reconcile a project's `.qgs` to the data actually present, so
these layers are trimmed out rather than shipped broken. The registry is the
delivery mechanism for adding them back, and the same path serves layers we want
from new sources such as STAC collections.

