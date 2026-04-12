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
#>      group    subgroup                               layer_key order
#> 1  Basemap        <NA>                watershed_group_boundary     1
#> 2  Basemap        <NA>                          municipalities     2
#> 3  Basemap        <NA>                         provincial_park     3
#> 4  Basemap        <NA>                             conservancy     4
#> 5  Basemap        <NA>                    first_nation_reserve     5
#> 6  Basemap        <NA>                            range_tenure     6
#> 7  Basemap        <NA>                          land_ownership     7
#> 8  Basemap        <NA>                    fire_historical_burn     8
#> 9  Basemap        <NA>                           fire_severity     9
#> 10 Basemap        <NA>                                glaciers    10
#> 11 Basemap        <NA>                                    town    11
#> 12 Basemap         BEC                                bec_zone     1
#> 13 Basemap         BEC biogeoclimatic_ecosystem_classification     2
#> 14 Basemap Waterbodies                                    lake     1
#> 15 Basemap Waterbodies                                 wetland     2
#> 16 Basemap Waterbodies                             rivers_poly     3
#> 17 Basemap Waterbodies                     manmade_waterbodies     4
gq_group_layers("Streams")
#>     group       subgroup                      layer_key order
#> 1 Streams           <NA>                    streams_all     1
#> 2 Streams           <NA>                  stream_labels     2
#> 3 Streams           <NA> fisheries_sensitive_watersheds     3
#> 4 Streams Habitat Models                     streams_bt     1
#> 5 Streams Habitat Models                 streams_salmon     2
#> 6 Streams Habitat Models                     streams_st     3

# With source_layer info
reg <- gq_reg_main()
gq_group_layers("Crossings", registry = reg)
#>       group subgroup                     layer_key order
#> 1 Crossings     <NA>    crossings_pscis_assessment     1
#> 2 Crossings     <NA>  crossings_pscis_confirmation     2
#> 3 Crossings     <NA>        crossings_pscis_design     3
#> 4 Crossings     <NA>    crossings_pscis_remedation     4
#> 5 Crossings     <NA>            crossings_modelled     5
#> 6 Crossings     <NA> crossings_pscis_modelled_dams     6
#> 7 Crossings     <NA>                 moti_culverts     7
#> 8 Crossings     <NA>         moti_major_structures     8
#> 9 Crossings     <NA>                           dam     9
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
