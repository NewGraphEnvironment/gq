# Get layers in a group

Returns all layers belonging to a group, including any nested subgroups.
Layers are ordered by z-order within the group.

## Usage

``` r
gq_group_layers(group, registry = NULL)
```

## Arguments

- group:

  Character. Group name (e.g., `"Basemap"`, `"Crossings"`).

- registry:

  Optional registry list (from
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)).
  If provided, `source_layer` and `type` columns are joined from the
  style registry.

## Value

A data.frame with columns: group, subgroup, layer_key, order, and
optionally source_layer and type. Returns empty data.frame if group not
found.

## Examples

``` r
gq_group_layers("Basemap")
#>      group            subgroup
#> 1  Basemap                <NA>
#> 2  Basemap                <NA>
#> 3  Basemap                <NA>
#> 4  Basemap                <NA>
#> 5  Basemap                <NA>
#> 6  Basemap                <NA>
#> 7  Basemap                <NA>
#> 8  Basemap                <NA>
#> 9  Basemap                <NA>
#> 10 Basemap                <NA>
#> 11 Basemap                <NA>
#> 12 Basemap                <NA>
#> 13 Basemap                <NA>
#> 14 Basemap Terrestrial Ecology
#> 15 Basemap Terrestrial Ecology
#> 16 Basemap Terrestrial Ecology
#> 17 Basemap Terrestrial Ecology
#> 18 Basemap Terrestrial Ecology
#> 19 Basemap         Waterbodies
#> 20 Basemap         Waterbodies
#> 21 Basemap         Waterbodies
#> 22 Basemap         Waterbodies
#> 23 Basemap         Waterbodies
#> 24 Basemap         Waterbodies
#>                                                 layer_key order source_type
#> 1                                watershed_group_boundary     1      bcdata
#> 2                                          municipalities     2      bcdata
#> 3                                         provincial_park     3      bcdata
#> 4                                           national_park     4      bcdata
#> 5                                             conservancy     5      bcdata
#> 6                             old_growth_management_areas     6      bcdata
#> 7                                            range_tenure     7         aws
#> 8                          fisheries_sensitive_watersheds     8      bcdata
#> 9                                          land_ownership     9         aws
#> 10                                   fire_historical_burn    10      bcdata
#> 11                                          fire_severity    11      bcdata
#> 12                                               glaciers    12      bcdata
#> 13                                                   town    13      bcdata
#> 14                                       orthophoto_tiles     1      bcdata
#> 15 terrestrial_ecosystem_information_scanned_map_boundary     2      bcdata
#> 16                     terrain_mapping_project_boundaries     3      bcdata
#> 17                                               bec_zone     4      bcdata
#> 18                biogeoclimatic_ecosystem_classification     5      bcdata
#> 19                                                   lake     1      bcdata
#> 20                                                wetland     2      bcdata
#> 21                                            streams_all     3         aws
#> 22                                   first_nation_reserve     4      bcdata
#> 23                                            rivers_poly     5      bcdata
#> 24                                    manmade_waterbodies     6      bcdata
gq_group_layers("Streams")
#>     group       subgroup      layer_key order source_type
#> 1 Streams Habitat models     streams_bt     1         aws
#> 2 Streams Habitat models streams_salmon     2         aws
#> 3 Streams Habitat models     streams_st     3         aws
#> 4 Streams  Stream labels  stream_labels     1         fwa

# With source_layer info
reg <- gq_reg_main()
gq_group_layers("Crossings", registry = reg)
#>       group subgroup                     layer_key order source_type
#> 1 Crossings     <NA>    crossings_pscis_assessment     1      bcdata
#> 2 Crossings     <NA>  crossings_pscis_confirmation     2      bcdata
#> 3 Crossings     <NA>        crossings_pscis_design     3      bcdata
#> 4 Crossings     <NA>    crossings_pscis_remedation     4      bcdata
#> 5 Crossings     <NA>            crossings_modelled     5         aws
#> 6 Crossings     <NA> crossings_pscis_modelled_dams     6         aws
#> 7 Crossings     <NA>                 moti_culverts     7      bcdata
#> 8 Crossings     <NA>         moti_major_structures     8      bcdata
#> 9 Crossings     <NA>                           dam     9         aws
#>                                       source_layer  type
#> 1                   whse_fish.pscis_assessment_svw point
#> 2         whse_fish.pscis_habitat_confirmation_svw point
#> 3              whse_fish.pscis_design_proposal_svw point
#> 4                  whse_fish.pscis_remediation_svw point
#> 5                          bcfishpass.crossings_vw point
#> 6                          bcfishpass.crossings_vw point
#> 7       whse_imagery_and_base_maps.mot_culverts_sp point
#> 8 whse_imagery_and_base_maps.mot_road_structure_sp  line
#> 9                                  bcfishpass.dams point
```
