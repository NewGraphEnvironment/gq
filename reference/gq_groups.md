# List all layer groups

Returns a data.frame of all groups defined in the registry, with their
member layers, subgroups, and z-order. Each row is one layer-to-group
mapping.

## Usage

``` r
gq_groups(registry = NULL)
```

## Arguments

- registry:

  Optional registry list (from
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)).
  If provided, `source_layer` and `type` columns are joined from the
  style registry.

## Value

A data.frame with columns: group, subgroup, layer_key, order, and
optionally source_layer and type.

## Examples

``` r
# All groups and their layers
gq_groups()
#>                    group       subgroup
#> 1                Basemap           <NA>
#> 2                Basemap           <NA>
#> 3                Basemap           <NA>
#> 4                Basemap           <NA>
#> 5                Basemap           <NA>
#> 6                Basemap           <NA>
#> 7                Basemap           <NA>
#> 8                Basemap           <NA>
#> 9                Basemap           <NA>
#> 10               Basemap           <NA>
#> 11               Basemap           <NA>
#> 12               Basemap    Waterbodies
#> 13               Basemap    Waterbodies
#> 14               Basemap    Waterbodies
#> 15               Basemap    Waterbodies
#> 16               Basemap            BEC
#> 17               Basemap            BEC
#> 18             Crossings           <NA>
#> 19             Crossings           <NA>
#> 20             Crossings           <NA>
#> 21             Crossings           <NA>
#> 22             Crossings           <NA>
#> 23             Crossings           <NA>
#> 24             Crossings           <NA>
#> 25             Crossings           <NA>
#> 26             Crossings           <NA>
#> 27               Streams           <NA>
#> 28               Streams           <NA>
#> 29               Streams           <NA>
#> 30               Streams Habitat Models
#> 31               Streams Habitat Models
#> 32               Streams Habitat Models
#> 33  Other Point Features           <NA>
#> 34  Other Point Features           <NA>
#> 35  Other Point Features           <NA>
#> 36  Other Point Features           <NA>
#> 37 Roads/Rails/Pipelines           <NA>
#> 38 Roads/Rails/Pipelines           <NA>
#> 39 Roads/Rails/Pipelines           <NA>
#> 40 Roads/Rails/Pipelines           <NA>
#> 41 Roads/Rails/Pipelines           <NA>
#> 42 Roads/Rails/Pipelines           <NA>
#> 43 Roads/Rails/Pipelines           <NA>
#> 44                 Forms           <NA>
#> 45                 Forms           <NA>
#> 46                 Forms           <NA>
#> 47                 Forms           <NA>
#> 48            Floodplain           <NA>
#> 49           Restoration           <NA>
#> 50           Restoration           <NA>
#> 51  Web Mapping Services           <NA>
#> 52  Web Mapping Services           <NA>
#> 53   Base - Orthoimagery           <NA>
#> 54           Base - misc           <NA>
#> 55           Base - misc           <NA>
#> 56           Base - misc           <NA>
#>                                                 layer_key order
#> 1                                watershed_group_boundary     1
#> 2                                          municipalities     2
#> 3                                         provincial_park     3
#> 4                                             conservancy     4
#> 5                                    first_nation_reserve     5
#> 6                                            range_tenure     6
#> 7                                          land_ownership     7
#> 8                                    fire_historical_burn     8
#> 9                                           fire_severity     9
#> 10                                               glaciers    10
#> 11                                                   town    11
#> 12                                                   lake     1
#> 13                                                wetland     2
#> 14                                            rivers_poly     3
#> 15                                    manmade_waterbodies     4
#> 16                                               bec_zone     1
#> 17                biogeoclimatic_ecosystem_classification     2
#> 18                             crossings_pscis_assessment     1
#> 19                           crossings_pscis_confirmation     2
#> 20                                 crossings_pscis_design     3
#> 21                             crossings_pscis_remedation     4
#> 22                                     crossings_modelled     5
#> 23                          crossings_pscis_modelled_dams     6
#> 24                                          moti_culverts     7
#> 25                                  moti_major_structures     8
#> 26                                                    dam     9
#> 27                                            streams_all     1
#> 28                                          stream_labels     2
#> 29                         fisheries_sensitive_watersheds     3
#> 30                                             streams_bt     1
#> 31                                         streams_salmon     2
#> 32                                             streams_st     3
#> 33                               fiss_stream_sample_sites     1
#> 34                       bcfishobs_fiss_fish_observations     2
#> 35                                         fiss_obstacles     3
#> 36                hydrometric_stations_environment_canada     4
#> 37                                              roads_dra     1
#> 38                                             roads_ften     2
#> 39                                                railway     3
#> 40                                     pipeline_installed     4
#> 41                                        pipeline_permit     5
#> 42                                   pipeline_application     6
#> 43                                      transmission_line     7
#> 44                                             form_pscis     1
#> 45                                         form_fiss_site     2
#> 46                                              form_edna     3
#> 47                                        form_monitoring     4
#> 48                                            floodplains     1
#> 49                                           harvest_area     1
#> 50                                          planting_site     2
#> 51                                fire_perimeters_current     1
#> 52                                   frep_rip2021_mar2022     2
#> 53                                       orthophoto_tiles     1
#> 54                                              utm_zones     1
#> 55 terrestrial_ecosystem_information_scanned_map_boundary     2
#> 56                     terrain_mapping_project_boundaries     3

# With style registry info joined
reg <- gq_reg_main()
gq_groups(registry = reg)
#>                    group       subgroup
#> 1                Basemap           <NA>
#> 2                Basemap           <NA>
#> 3                Basemap           <NA>
#> 4                Basemap           <NA>
#> 5                Basemap           <NA>
#> 6                Basemap           <NA>
#> 7                Basemap           <NA>
#> 8                Basemap           <NA>
#> 9                Basemap           <NA>
#> 10               Basemap           <NA>
#> 11               Basemap           <NA>
#> 12               Basemap    Waterbodies
#> 13               Basemap    Waterbodies
#> 14               Basemap    Waterbodies
#> 15               Basemap    Waterbodies
#> 16               Basemap            BEC
#> 17               Basemap            BEC
#> 18             Crossings           <NA>
#> 19             Crossings           <NA>
#> 20             Crossings           <NA>
#> 21             Crossings           <NA>
#> 22             Crossings           <NA>
#> 23             Crossings           <NA>
#> 24             Crossings           <NA>
#> 25             Crossings           <NA>
#> 26             Crossings           <NA>
#> 27               Streams           <NA>
#> 28               Streams           <NA>
#> 29               Streams           <NA>
#> 30               Streams Habitat Models
#> 31               Streams Habitat Models
#> 32               Streams Habitat Models
#> 33  Other Point Features           <NA>
#> 34  Other Point Features           <NA>
#> 35  Other Point Features           <NA>
#> 36  Other Point Features           <NA>
#> 37 Roads/Rails/Pipelines           <NA>
#> 38 Roads/Rails/Pipelines           <NA>
#> 39 Roads/Rails/Pipelines           <NA>
#> 40 Roads/Rails/Pipelines           <NA>
#> 41 Roads/Rails/Pipelines           <NA>
#> 42 Roads/Rails/Pipelines           <NA>
#> 43 Roads/Rails/Pipelines           <NA>
#> 44                 Forms           <NA>
#> 45                 Forms           <NA>
#> 46                 Forms           <NA>
#> 47                 Forms           <NA>
#> 48            Floodplain           <NA>
#> 49           Restoration           <NA>
#> 50           Restoration           <NA>
#> 51  Web Mapping Services           <NA>
#> 52  Web Mapping Services           <NA>
#> 53   Base - Orthoimagery           <NA>
#> 54           Base - misc           <NA>
#> 55           Base - misc           <NA>
#> 56           Base - misc           <NA>
#>                                                 layer_key order
#> 1                                watershed_group_boundary     1
#> 2                                          municipalities     2
#> 3                                         provincial_park     3
#> 4                                             conservancy     4
#> 5                                    first_nation_reserve     5
#> 6                                            range_tenure     6
#> 7                                          land_ownership     7
#> 8                                    fire_historical_burn     8
#> 9                                           fire_severity     9
#> 10                                               glaciers    10
#> 11                                                   town    11
#> 12                                                   lake     1
#> 13                                                wetland     2
#> 14                                            rivers_poly     3
#> 15                                    manmade_waterbodies     4
#> 16                                               bec_zone     1
#> 17                biogeoclimatic_ecosystem_classification     2
#> 18                             crossings_pscis_assessment     1
#> 19                           crossings_pscis_confirmation     2
#> 20                                 crossings_pscis_design     3
#> 21                             crossings_pscis_remedation     4
#> 22                                     crossings_modelled     5
#> 23                          crossings_pscis_modelled_dams     6
#> 24                                          moti_culverts     7
#> 25                                  moti_major_structures     8
#> 26                                                    dam     9
#> 27                                            streams_all     1
#> 28                                          stream_labels     2
#> 29                         fisheries_sensitive_watersheds     3
#> 30                                             streams_bt     1
#> 31                                         streams_salmon     2
#> 32                                             streams_st     3
#> 33                               fiss_stream_sample_sites     1
#> 34                       bcfishobs_fiss_fish_observations     2
#> 35                                         fiss_obstacles     3
#> 36                hydrometric_stations_environment_canada     4
#> 37                                              roads_dra     1
#> 38                                             roads_ften     2
#> 39                                                railway     3
#> 40                                     pipeline_installed     4
#> 41                                        pipeline_permit     5
#> 42                                   pipeline_application     6
#> 43                                      transmission_line     7
#> 44                                             form_pscis     1
#> 45                                         form_fiss_site     2
#> 46                                              form_edna     3
#> 47                                        form_monitoring     4
#> 48                                            floodplains     1
#> 49                                           harvest_area     1
#> 50                                          planting_site     2
#> 51                                fire_perimeters_current     1
#> 52                                   frep_rip2021_mar2022     2
#> 53                                       orthophoto_tiles     1
#> 54                                              utm_zones     1
#> 55 terrestrial_ecosystem_information_scanned_map_boundary     2
#> 56                     terrain_mapping_project_boundaries     3
#>                                                    source_layer    type
#> 1                    whse_basemapping.fwa_watershed_groups_poly polygon
#> 2            whse_legal_admin_boundaries.abms_municipalities_sp polygon
#> 3                           whse_tantalis.ta_park_ecores_pa_svw polygon
#> 4                        whse_tantalis.ta_conservancy_areas_svw polygon
#> 5                    whse_admin_boundaries.clab_indian_reserves polygon
#> 6                   whse_forest_tenure.ften_range_poly_carto_vw polygon
#> 7                     whse_cadastre.pmbc_parcel_fabric_poly_svw polygon
#> 8  whse_land_and_natural_resource.prot_historical_fire_polys_sp polygon
#> 9                   whse_forest_vegetation.veg_burn_severity_sp polygon
#> 10                           whse_basemapping.fwa_glaciers_poly polygon
#> 11                   whse_basemapping.gns_geographical_names_sp   point
#> 12                              whse_basemapping.fwa_lakes_poly polygon
#> 13                           whse_basemapping.fwa_wetlands_poly polygon
#> 14                             whse_basemapping.fwa_rivers_poly polygon
#> 15                whse_basemapping.fwa_manmade_waterbodies_poly polygon
#> 16               whse_forest_vegetation.bec_biogeoclimatic_poly polygon
#> 17               whse_forest_vegetation.bec_biogeoclimatic_poly polygon
#> 18                               whse_fish.pscis_assessment_svw   point
#> 19                     whse_fish.pscis_habitat_confirmation_svw   point
#> 20                          whse_fish.pscis_design_proposal_svw   point
#> 21                              whse_fish.pscis_remediation_svw   point
#> 22                                      bcfishpass.crossings_vw   point
#> 23                                      bcfishpass.crossings_vw   point
#> 24                   whse_imagery_and_base_maps.mot_culverts_sp   point
#> 25             whse_imagery_and_base_maps.mot_road_structure_sp    line
#> 26                                              bcfishpass.dams   point
#> 27                                        bcfishpass.streams_vw    line
#> 28                           whse_basemapping.fwa_named_streams    line
#> 29          whse_wildlife_management.wcp_fish_sensitive_ws_poly polygon
#> 30                                        bcfishpass.streams_vw    line
#> 31                                        bcfishpass.streams_vw    line
#> 32                                        bcfishpass.streams_vw    line
#> 33                        whse_fish.fiss_stream_sample_sites_sp   point
#> 34                        bcfishobs.fiss_fish_obsrvtn_events_vw   point
#> 35                              whse_fish.fiss_obstacles_pnt_sp   point
#> 36      whse_environmental_monitoring.envcan_hydrometric_stn_sp   point
#> 37                              whse_basemapping.transport_line    line
#> 38               whse_forest_tenure.ften_road_section_lines_svw    line
#> 39                       whse_basemapping.gba_railway_tracks_sp    line
#> 40            whse_mineral_tenure.og_pipeline_segment_permit_sp    line
#> 41               whse_mineral_tenure.og_pipeline_area_permit_sp polygon
#> 42                 whse_mineral_tenure.og_pipeline_area_appl_sp polygon
#> 43                   whse_basemapping.gba_transmission_lines_sp    line
#> 44                                                   form_pscis   point
#> 45                                               form_fiss_site   point
#> 46                                                         <NA>    <NA>
#> 47                                                         <NA>    <NA>
#> 48                 whse_basemapping.cwb_floodplains_bc_area_svw polygon
#> 49                                                         <NA> polygon
#> 50                                                         <NA>   point
#> 51                                                         <NA>    <NA>
#> 52                                                         <NA>   point
#> 53        whse_imagery_and_base_maps.aimg_orthophoto_tiles_poly polygon
#> 54                           whse_basemapping.utmg_utm_zones_sp polygon
#> 55         whse_terrestrial_ecology.ste_scanned_map_boundary_sp polygon
#> 56      whse_terrestrial_ecology.ste_ter_project_boundaries_svw polygon
```
