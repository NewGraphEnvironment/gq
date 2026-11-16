# Findings — Layer order within a group disagrees with the templates in 7 groups (#105)

## Issue context

**If we do it:** `groups.csv`'s `order` says the same thing as the templates about which layer draws over which inside a group, and a test keeps it that way. **If we never do:** `gq_template_layers()` sorts layers in an order no template uses, and nothing reports it.

## Measured

Found while doing #68 (gq#100), against rfp v0.93.0's templates via the new `inst/registry/template_layers.csv`. #68 settled which **group** each layer sits in; it left **order within a group** alone. On the layers both sides carry, the relative order differs in 7 groups, identically in both templates:

| group | gq (`groups.csv` order) | template (tree order, first draws on top) |
|---|---|---|
| `Basemap` | wgb, municipalities, provincial_park, national_park, conservancy, ogma, range_tenure, fsw, land_ownership, fire_historical_burn, fire_severity, glaciers | wgb, municipalities, glaciers, fire_historical_burn, fire_severity, ogma, national_park, land_ownership, range_tenure, fsw, provincial_park, conservancy |
| `Basemap/Waterbodies` | lake, wetland, streams_all, first_nation_reserve, manmade_waterbodies | manmade_waterbodies, lake, wetland, streams_all, first_nation_reserve |
| `Crossings` | pscis_assessment … pscis_remedation, modelled, modelled_dams, moti_culverts, moti_major_structures | moti_culverts, modelled, pscis_assessment … pscis_remedation, modelled_dams, moti_major_structures |
| `Streams/Habitat models` | bt, salmon, st | salmon, st, bt |
| `Roads,Railways,Pipelines` | roads_dra, roads_ften, railway, pipeline_installed, pipeline_permit, pipeline_application, transmission_line, trails | pipeline_permit, pipeline_installed, pipeline_application, transmission_line, railway, roads_ften, roads_dra, trails |
| `Web Mapping Services` | fire_perimeters_current, frep | frep, fire_perimeters_current |
| `Base - misc` | habitat_lateral, utm_zones, esri_world_topo, bing_aerial, esri_satellite, google_satellite | habitat_lateral, utm_zones, esri_satellite, bing_aerial, google_satellite, esri_world_topo |

## Before moving anything

Apply the rule #68 used: hold gq's side only where it was a decision. Every row above dates from the registry's first commit (`3cee619`), so the likely answer is to adopt the templates' order, but check each group for a measurement first. `Base - misc` matters most: it holds the four opaque basemaps, and which one draws on top is visible on every device.

## A limit to know first

`groups.csv` cannot place a subgroup **among** its parent's layers: `gq_group_layers()` and `gq_template_layers()` (`R/gq_groups.R`) sort a group's own layers before every subgroup. The templates interleave them. `Basemap/Waterbodies` is the 4th child of `Basemap`, so the templates draw `streams_all` and `first_nation_reserve` above `land_ownership`, `range_tenure` and `fisheries_sensitive_watersheds`, while gq's flattened order puts them below. Renumbering `order` fixes order **within** a group only. Expressing the interleave needs a schema change (an order key shared by layers and subgroups), which belongs with #104. The template repo is unaffected: it reads `groups.csv` for membership and `source_type` only.

The same gap covers **order between sibling subgroups**, which gq derives by sorting subgroup names. Since #68 (gq#100) moved `stream_labels` into its own `Streams/Stream labels` subgroup, `gq_template_layers()` lists `Habitat models` before `Stream labels`. Both templates have it the other way round: `Stream labels` is order 1, above `Habitat models` at order 2. So gq's documented z-order now puts the stream labels beneath the habitat-model lines. Nothing in gq draws from that order today, and the subgroup can't be renamed to sort first, because its name must match the template. The fix is the same shared order key.

## Suggested work

- Renumber `order` from `template_layers.csv`, group by group.
- Add a relative-order check beside the placement check in `tests/testthat/test-template_drift.R` (intersection only, as the group-order check does), with a perturbed-fixture alarm.




## Exploration (2026-11-15)

- `template_layers.csv` `order` is the template's sibling index across layers AND
  subgroups (Basemap skips 4, which is `Waterbodies`; `Terrestrial Ecology` is 14 in
  `template_groups.csv`). Both templates agree identically on every shared group.
- History of `groups.csv`: the 7 groups' orders come from `3cee619` (first commit),
  `a579752` (#41 added the four xyz basemaps; its message measures the *group*, not the
  order) and `b7be0df` (#100 placement insertions). The #66 archive findings note the
  `Base - misc` basemap disagreement as "not a defect" and hand it on; no measurement.
- Consumers of `order`: `gq_group_layers()`, `gq_template_layers()` sort by it; rfp's
  `rfp_project_layers()` passes it through; no `$order` read in rfp `R/` for layers.

## Red before the renumber (2026-11-15, commit 75c1e3e)

`order_drift(read_template_layers_csv(), tpl)` on the old `groups.csv`:

```
bcfishpass_mobile    | Base - misc | Basemap | Basemap/Waterbodies | Crossings | Roads,Railways,Pipelines | Streams/Habitat models | Web Mapping Services
bcrestoration_mobile | Base - misc | Basemap | Basemap/Waterbodies | Crossings | Roads,Railways,Pipelines | Streams/Habitat models | Web Mapping Services
```

Test file: 17 of 19 pass; the two failing are the agreement test and the swap alarm's
clean-table line, as designed. Premise holds: shared layers per group are Basemap 12,
Waterbodies 5, Crossings 8, Habitat models 3, Roads 8, Web Mapping Services 2, Base - misc 6.

## Target order (order 1 draws on top; gq-only layers in brackets)

| group path | new order |
|---|---|
| Basemap | watershed_group_boundary, municipalities, glaciers, [town], fire_historical_burn, fire_severity, old_growth_management_areas, national_park, land_ownership, range_tenure, fisheries_sensitive_watersheds, provincial_park, conservancy |
| Basemap/Waterbodies | manmade_waterbodies, lake, wetland, streams_all, first_nation_reserve, [rivers_poly] |
| Crossings | moti_culverts, crossings_modelled, crossings_pscis_assessment, crossings_pscis_confirmation, crossings_pscis_design, crossings_pscis_remedation, crossings_pscis_modelled_dams, moti_major_structures, [dam] |
| Streams/Habitat models | streams_salmon, streams_st, streams_bt |
| Roads,Railways,Pipelines | pipeline_permit, pipeline_installed, pipeline_application, transmission_line, railway, roads_ften, roads_dra, trails |
| Web Mapping Services | frep_rip2021_mar2022, fire_perimeters_current |
| Base - misc | habitat_lateral, utm_zones, esri_satellite, bing_aerial, google_satellite, esri_world_topo |

## After the renumber

- `gq_groups()` membership and `source_type`, sorted by key: identical before and after.
- `gq_template_layers()` per group path, both templates: sequence changed in exactly the 7
  paths above.
- `devtools::test()`: FAIL 0 | WARN 1 | SKIP 6 | PASS 1696. The warning is the existing
  `test-gq_registry_read.R:25` "cannot open file 'nonexistent.json'".

## Errors Encountered

| Error | Resolution |
|-------|------------|
