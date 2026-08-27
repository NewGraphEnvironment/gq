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
#> 12               Basemap           <NA>
#> 13               Basemap           <NA>
#> 14               Basemap    Waterbodies
#> 15               Basemap    Waterbodies
#> 16               Basemap    Waterbodies
#> 17               Basemap    Waterbodies
#> 18               Basemap            BEC
#> 19               Basemap            BEC
#> 20             Crossings           <NA>
#> 21             Crossings           <NA>
#> 22             Crossings           <NA>
#> 23             Crossings           <NA>
#> 24             Crossings           <NA>
#> 25             Crossings           <NA>
#> 26             Crossings           <NA>
#> 27             Crossings           <NA>
#> 28             Crossings           <NA>
#> 29               Streams           <NA>
#> 30               Streams           <NA>
#> 31               Streams           <NA>
#> 32               Streams Habitat Models
#> 33               Streams Habitat Models
#> 34               Streams Habitat Models
#> 35  Other Point Features           <NA>
#> 36  Other Point Features           <NA>
#> 37  Other Point Features           <NA>
#> 38  Other Point Features           <NA>
#> 39 Roads/Rails/Pipelines           <NA>
#> 40 Roads/Rails/Pipelines           <NA>
#> 41 Roads/Rails/Pipelines           <NA>
#> 42 Roads/Rails/Pipelines           <NA>
#> 43 Roads/Rails/Pipelines           <NA>
#> 44 Roads/Rails/Pipelines           <NA>
#> 45 Roads/Rails/Pipelines           <NA>
#> 46 Roads/Rails/Pipelines           <NA>
#> 47                 Forms           <NA>
#> 48                 Forms           <NA>
#> 49                 Forms           <NA>
#> 50                 Forms           <NA>
#> 51            Floodplain           <NA>
#> 52           Restoration           <NA>
#> 53           Restoration           <NA>
#> 54  Web Mapping Services           <NA>
#> 55  Web Mapping Services           <NA>
#> 56   Base - Orthoimagery           <NA>
#> 57           Base - misc           <NA>
#> 58           Base - misc           <NA>
#> 59           Base - misc           <NA>
#> 60           Base - misc           <NA>
#> 61           Base - misc           <NA>
#> 62           Base - misc           <NA>
#> 63           Base - misc           <NA>
#> 64           Base - misc           <NA>
#>                                                 layer_key order source_type
#> 1                                watershed_group_boundary     1      bcdata
#> 2                                          municipalities     2      bcdata
#> 3                                         provincial_park     3      bcdata
#> 4                                           national_park     4      bcdata
#> 5                                             conservancy     5      bcdata
#> 6                             old_growth_management_areas     6      bcdata
#> 7                                    first_nation_reserve     7      bcdata
#> 8                                            range_tenure     8         aws
#> 9                                          land_ownership     9         aws
#> 10                                   fire_historical_burn    10      bcdata
#> 11                                          fire_severity    11      bcdata
#> 12                                               glaciers    12      bcdata
#> 13                                                   town    13      bcdata
#> 14                                                   lake     1      bcdata
#> 15                                                wetland     2      bcdata
#> 16                                            rivers_poly     3      bcdata
#> 17                                    manmade_waterbodies     4      bcdata
#> 18                                               bec_zone     1      bcdata
#> 19                biogeoclimatic_ecosystem_classification     2      bcdata
#> 20                             crossings_pscis_assessment     1      bcdata
#> 21                           crossings_pscis_confirmation     2      bcdata
#> 22                                 crossings_pscis_design     3      bcdata
#> 23                             crossings_pscis_remedation     4      bcdata
#> 24                                     crossings_modelled     5         aws
#> 25                          crossings_pscis_modelled_dams     6         aws
#> 26                                          moti_culverts     7      bcdata
#> 27                                  moti_major_structures     8      bcdata
#> 28                                                    dam     9         aws
#> 29                                            streams_all     1         aws
#> 30                                          stream_labels     2         fwa
#> 31                         fisheries_sensitive_watersheds     3      bcdata
#> 32                                             streams_bt     1         aws
#> 33                                         streams_salmon     2         aws
#> 34                                             streams_st     3         aws
#> 35                               fiss_stream_sample_sites     1      bcdata
#> 36                       bcfishobs_fiss_fish_observations     2         aws
#> 37                                         fiss_obstacles     3         aws
#> 38                hydrometric_stations_environment_canada     4      bcdata
#> 39                                              roads_dra     1         aws
#> 40                                             roads_ften     2         aws
#> 41                                                railway     3      bcdata
#> 42                                     pipeline_installed     4      bcdata
#> 43                                        pipeline_permit     5      bcdata
#> 44                                   pipeline_application     6      bcdata
#> 45                                      transmission_line     7      bcdata
#> 46                                                 trails     8         osm
#> 47                                             form_pscis     1       local
#> 48                                         form_fiss_site     2       local
#> 49                                              form_edna     3       local
#> 50                                        form_monitoring     4       local
#> 51                                            floodplains     1      bcdata
#> 52                                           harvest_area     1       local
#> 53                                          planting_site     2       local
#> 54                                fire_perimeters_current     1         wms
#> 55                                   frep_rip2021_mar2022     2         wms
#> 56                                       orthophoto_tiles     1      bcdata
#> 57                                        habitat_lateral     1       local
#> 58                                              utm_zones     2      bcdata
#> 59 terrestrial_ecosystem_information_scanned_map_boundary     3      bcdata
#> 60                     terrain_mapping_project_boundaries     4      bcdata
#> 61                                        esri_world_topo     5         wms
#> 62                                            bing_aerial     6         wms
#> 63                                         esri_satellite     7         wms
#> 64                                       google_satellite     8         wms

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
#> 12               Basemap           <NA>
#> 13               Basemap           <NA>
#> 14               Basemap    Waterbodies
#> 15               Basemap    Waterbodies
#> 16               Basemap    Waterbodies
#> 17               Basemap    Waterbodies
#> 18               Basemap            BEC
#> 19               Basemap            BEC
#> 20             Crossings           <NA>
#> 21             Crossings           <NA>
#> 22             Crossings           <NA>
#> 23             Crossings           <NA>
#> 24             Crossings           <NA>
#> 25             Crossings           <NA>
#> 26             Crossings           <NA>
#> 27             Crossings           <NA>
#> 28             Crossings           <NA>
#> 29               Streams           <NA>
#> 30               Streams           <NA>
#> 31               Streams           <NA>
#> 32               Streams Habitat Models
#> 33               Streams Habitat Models
#> 34               Streams Habitat Models
#> 35  Other Point Features           <NA>
#> 36  Other Point Features           <NA>
#> 37  Other Point Features           <NA>
#> 38  Other Point Features           <NA>
#> 39 Roads/Rails/Pipelines           <NA>
#> 40 Roads/Rails/Pipelines           <NA>
#> 41 Roads/Rails/Pipelines           <NA>
#> 42 Roads/Rails/Pipelines           <NA>
#> 43 Roads/Rails/Pipelines           <NA>
#> 44 Roads/Rails/Pipelines           <NA>
#> 45 Roads/Rails/Pipelines           <NA>
#> 46 Roads/Rails/Pipelines           <NA>
#> 47                 Forms           <NA>
#> 48                 Forms           <NA>
#> 49                 Forms           <NA>
#> 50                 Forms           <NA>
#> 51            Floodplain           <NA>
#> 52           Restoration           <NA>
#> 53           Restoration           <NA>
#> 54  Web Mapping Services           <NA>
#> 55  Web Mapping Services           <NA>
#> 56   Base - Orthoimagery           <NA>
#> 57           Base - misc           <NA>
#> 58           Base - misc           <NA>
#> 59           Base - misc           <NA>
#> 60           Base - misc           <NA>
#> 61           Base - misc           <NA>
#> 62           Base - misc           <NA>
#> 63           Base - misc           <NA>
#> 64           Base - misc           <NA>
#>                                                 layer_key order source_type
#> 1                                watershed_group_boundary     1      bcdata
#> 2                                          municipalities     2      bcdata
#> 3                                         provincial_park     3      bcdata
#> 4                                           national_park     4      bcdata
#> 5                                             conservancy     5      bcdata
#> 6                             old_growth_management_areas     6      bcdata
#> 7                                    first_nation_reserve     7      bcdata
#> 8                                            range_tenure     8         aws
#> 9                                          land_ownership     9         aws
#> 10                                   fire_historical_burn    10      bcdata
#> 11                                          fire_severity    11      bcdata
#> 12                                               glaciers    12      bcdata
#> 13                                                   town    13      bcdata
#> 14                                                   lake     1      bcdata
#> 15                                                wetland     2      bcdata
#> 16                                            rivers_poly     3      bcdata
#> 17                                    manmade_waterbodies     4      bcdata
#> 18                                               bec_zone     1      bcdata
#> 19                biogeoclimatic_ecosystem_classification     2      bcdata
#> 20                             crossings_pscis_assessment     1      bcdata
#> 21                           crossings_pscis_confirmation     2      bcdata
#> 22                                 crossings_pscis_design     3      bcdata
#> 23                             crossings_pscis_remedation     4      bcdata
#> 24                                     crossings_modelled     5         aws
#> 25                          crossings_pscis_modelled_dams     6         aws
#> 26                                          moti_culverts     7      bcdata
#> 27                                  moti_major_structures     8      bcdata
#> 28                                                    dam     9         aws
#> 29                                            streams_all     1         aws
#> 30                                          stream_labels     2         fwa
#> 31                         fisheries_sensitive_watersheds     3      bcdata
#> 32                                             streams_bt     1         aws
#> 33                                         streams_salmon     2         aws
#> 34                                             streams_st     3         aws
#> 35                               fiss_stream_sample_sites     1      bcdata
#> 36                       bcfishobs_fiss_fish_observations     2         aws
#> 37                                         fiss_obstacles     3         aws
#> 38                hydrometric_stations_environment_canada     4      bcdata
#> 39                                              roads_dra     1         aws
#> 40                                             roads_ften     2         aws
#> 41                                                railway     3      bcdata
#> 42                                     pipeline_installed     4      bcdata
#> 43                                        pipeline_permit     5      bcdata
#> 44                                   pipeline_application     6      bcdata
#> 45                                      transmission_line     7      bcdata
#> 46                                                 trails     8         osm
#> 47                                             form_pscis     1       local
#> 48                                         form_fiss_site     2       local
#> 49                                              form_edna     3       local
#> 50                                        form_monitoring     4       local
#> 51                                            floodplains     1      bcdata
#> 52                                           harvest_area     1       local
#> 53                                          planting_site     2       local
#> 54                                fire_perimeters_current     1         wms
#> 55                                   frep_rip2021_mar2022     2         wms
#> 56                                       orthophoto_tiles     1      bcdata
#> 57                                        habitat_lateral     1       local
#> 58                                              utm_zones     2      bcdata
#> 59 terrestrial_ecosystem_information_scanned_map_boundary     3      bcdata
#> 60                     terrain_mapping_project_boundaries     4      bcdata
#> 61                                        esri_world_topo     5         wms
#> 62                                            bing_aerial     6         wms
#> 63                                         esri_satellite     7         wms
#> 64                                       google_satellite     8         wms
#>                                                    source_layer    type
#> 1                    whse_basemapping.fwa_watershed_groups_poly polygon
#> 2            whse_legal_admin_boundaries.abms_municipalities_sp polygon
#> 3                           whse_tantalis.ta_park_ecores_pa_svw polygon
#> 4                     whse_admin_boundaries.clab_national_parks polygon
#> 5                        whse_tantalis.ta_conservancy_areas_svw polygon
#> 6         whse_land_use_planning.rmp_ogma_non_legal_current_svw polygon
#> 7                    whse_admin_boundaries.clab_indian_reserves polygon
#> 8                   whse_forest_tenure.ften_range_poly_carto_vw polygon
#> 9                     whse_cadastre.pmbc_parcel_fabric_poly_svw polygon
#> 10 whse_land_and_natural_resource.prot_historical_fire_polys_sp polygon
#> 11                  whse_forest_vegetation.veg_burn_severity_sp polygon
#> 12                           whse_basemapping.fwa_glaciers_poly polygon
#> 13                   whse_basemapping.gns_geographical_names_sp   point
#> 14                              whse_basemapping.fwa_lakes_poly polygon
#> 15                           whse_basemapping.fwa_wetlands_poly polygon
#> 16                             whse_basemapping.fwa_rivers_poly polygon
#> 17                whse_basemapping.fwa_manmade_waterbodies_poly polygon
#> 18               whse_forest_vegetation.bec_biogeoclimatic_poly polygon
#> 19               whse_forest_vegetation.bec_biogeoclimatic_poly polygon
#> 20                               whse_fish.pscis_assessment_svw   point
#> 21                     whse_fish.pscis_habitat_confirmation_svw   point
#> 22                          whse_fish.pscis_design_proposal_svw   point
#> 23                              whse_fish.pscis_remediation_svw   point
#> 24                                      bcfishpass.crossings_vw   point
#> 25                                      bcfishpass.crossings_vw   point
#> 26                   whse_imagery_and_base_maps.mot_culverts_sp   point
#> 27             whse_imagery_and_base_maps.mot_road_structure_sp    line
#> 28                                              bcfishpass.dams   point
#> 29                                        bcfishpass.streams_vw    line
#> 30                           whse_basemapping.fwa_named_streams    line
#> 31          whse_wildlife_management.wcp_fish_sensitive_ws_poly polygon
#> 32                                        bcfishpass.streams_vw    line
#> 33                                        bcfishpass.streams_vw    line
#> 34                                        bcfishpass.streams_vw    line
#> 35                        whse_fish.fiss_stream_sample_sites_sp   point
#> 36                        bcfishobs.fiss_fish_obsrvtn_events_vw   point
#> 37                              whse_fish.fiss_obstacles_pnt_sp   point
#> 38      whse_environmental_monitoring.envcan_hydrometric_stn_sp   point
#> 39                              whse_basemapping.transport_line    line
#> 40               whse_forest_tenure.ften_road_section_lines_svw    line
#> 41                       whse_basemapping.gba_railway_tracks_sp    line
#> 42            whse_mineral_tenure.og_pipeline_segment_permit_sp    line
#> 43               whse_mineral_tenure.og_pipeline_area_permit_sp polygon
#> 44                 whse_mineral_tenure.og_pipeline_area_appl_sp polygon
#> 45                   whse_basemapping.gba_transmission_lines_sp    line
#> 46                                                    osm.trail    line
#> 47                                                   form_pscis   point
#> 48                                               form_fiss_site   point
#> 49                                                         <NA>    <NA>
#> 50                                                         <NA>    <NA>
#> 51                 whse_basemapping.cwb_floodplains_bc_area_svw polygon
#> 52                                                 harvest_area polygon
#> 53                                                planting_site   point
#> 54                                                         <NA>    <NA>
#> 55                                                         <NA>   point
#> 56        whse_imagery_and_base_maps.aimg_orthophoto_tiles_poly polygon
#> 57                                                         <NA>    <NA>
#> 58                           whse_basemapping.utmg_utm_zones_sp polygon
#> 59         whse_terrestrial_ecology.ste_scanned_map_boundary_sp polygon
#> 60      whse_terrestrial_ecology.ste_ter_project_boundaries_svw polygon
#> 61                                                         <NA>    <NA>
#> 62                                                         <NA>    <NA>
#> 63                                                         <NA>    <NA>
#> 64                                                         <NA>    <NA>
```
