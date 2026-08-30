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
#>                       group            subgroup
#> 1                   Basemap                <NA>
#> 2                   Basemap                <NA>
#> 3                   Basemap                <NA>
#> 4                   Basemap                <NA>
#> 5                   Basemap                <NA>
#> 6                   Basemap                <NA>
#> 7                   Basemap                <NA>
#> 8                   Basemap                <NA>
#> 9                   Basemap                <NA>
#> 10                  Basemap                <NA>
#> 11                  Basemap                <NA>
#> 12                  Basemap                <NA>
#> 13                  Basemap                <NA>
#> 14                  Basemap         Waterbodies
#> 15                  Basemap         Waterbodies
#> 16                  Basemap         Waterbodies
#> 17                  Basemap         Waterbodies
#> 18                  Basemap Terrestrial Ecology
#> 19                  Basemap Terrestrial Ecology
#> 20                  Basemap Terrestrial Ecology
#> 21                Crossings                <NA>
#> 22                Crossings                <NA>
#> 23                Crossings                <NA>
#> 24                Crossings                <NA>
#> 25                Crossings                <NA>
#> 26                Crossings                <NA>
#> 27                Crossings                <NA>
#> 28                Crossings                <NA>
#> 29                Crossings                <NA>
#> 30                  Streams                <NA>
#> 31                  Streams                <NA>
#> 32                  Streams                <NA>
#> 33                  Streams      Habitat models
#> 34                  Streams      Habitat models
#> 35                  Streams      Habitat models
#> 36     Other point features                <NA>
#> 37     Other point features                <NA>
#> 38     Other point features                <NA>
#> 39     Other point features                <NA>
#> 40 Roads,Railways,Pipelines                <NA>
#> 41 Roads,Railways,Pipelines                <NA>
#> 42 Roads,Railways,Pipelines                <NA>
#> 43 Roads,Railways,Pipelines                <NA>
#> 44 Roads,Railways,Pipelines                <NA>
#> 45 Roads,Railways,Pipelines                <NA>
#> 46 Roads,Railways,Pipelines                <NA>
#> 47 Roads,Railways,Pipelines                <NA>
#> 48                    Forms                <NA>
#> 49                    Forms                <NA>
#> 50               Floodplain                <NA>
#> 51              Restoration                <NA>
#> 52              Restoration                <NA>
#> 53     Web Mapping Services                <NA>
#> 54     Web Mapping Services                <NA>
#> 55              Base - misc                <NA>
#> 56              Base - misc                <NA>
#> 57              Base - misc                <NA>
#> 58              Base - misc                <NA>
#> 59              Base - misc                <NA>
#> 60              Base - misc                <NA>
#> 61              Base - misc                <NA>
#> 62              Base - misc                <NA>
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
#> 18                                       orthophoto_tiles     1      bcdata
#> 19                                               bec_zone     2      bcdata
#> 20                biogeoclimatic_ecosystem_classification     3      bcdata
#> 21                             crossings_pscis_assessment     1      bcdata
#> 22                           crossings_pscis_confirmation     2      bcdata
#> 23                                 crossings_pscis_design     3      bcdata
#> 24                             crossings_pscis_remedation     4      bcdata
#> 25                                     crossings_modelled     5         aws
#> 26                          crossings_pscis_modelled_dams     6         aws
#> 27                                          moti_culverts     7      bcdata
#> 28                                  moti_major_structures     8      bcdata
#> 29                                                    dam     9         aws
#> 30                                            streams_all     1         aws
#> 31                                          stream_labels     2         fwa
#> 32                         fisheries_sensitive_watersheds     3      bcdata
#> 33                                             streams_bt     1         aws
#> 34                                         streams_salmon     2         aws
#> 35                                             streams_st     3         aws
#> 36                               fiss_stream_sample_sites     1      bcdata
#> 37                       bcfishobs_fiss_fish_observations     2         aws
#> 38                                         fiss_obstacles     3         aws
#> 39                hydrometric_stations_environment_canada     4      bcdata
#> 40                                              roads_dra     1         aws
#> 41                                             roads_ften     2         aws
#> 42                                                railway     3      bcdata
#> 43                                     pipeline_installed     4      bcdata
#> 44                                        pipeline_permit     5      bcdata
#> 45                                   pipeline_application     6      bcdata
#> 46                                      transmission_line     7      bcdata
#> 47                                                 trails     8         osm
#> 48                                             form_pscis     1       local
#> 49                                         form_fiss_site     2       local
#> 50                                            floodplains     1      bcdata
#> 51                                           harvest_area     1       local
#> 52                                          planting_site     2       local
#> 53                                fire_perimeters_current     1         wms
#> 54                                   frep_rip2021_mar2022     2         wms
#> 55                                        habitat_lateral     1       local
#> 56                                              utm_zones     2      bcdata
#> 57 terrestrial_ecosystem_information_scanned_map_boundary     3      bcdata
#> 58                     terrain_mapping_project_boundaries     4      bcdata
#> 59                                        esri_world_topo     5         wms
#> 60                                            bing_aerial     6         wms
#> 61                                         esri_satellite     7         wms
#> 62                                       google_satellite     8         wms

# With style registry info joined
reg <- gq_reg_main()
gq_groups(registry = reg)
#>                       group            subgroup
#> 1                   Basemap                <NA>
#> 2                   Basemap                <NA>
#> 3                   Basemap                <NA>
#> 4                   Basemap                <NA>
#> 5                   Basemap                <NA>
#> 6                   Basemap                <NA>
#> 7                   Basemap                <NA>
#> 8                   Basemap                <NA>
#> 9                   Basemap                <NA>
#> 10                  Basemap                <NA>
#> 11                  Basemap                <NA>
#> 12                  Basemap                <NA>
#> 13                  Basemap                <NA>
#> 14                  Basemap         Waterbodies
#> 15                  Basemap         Waterbodies
#> 16                  Basemap         Waterbodies
#> 17                  Basemap         Waterbodies
#> 18                  Basemap Terrestrial Ecology
#> 19                  Basemap Terrestrial Ecology
#> 20                  Basemap Terrestrial Ecology
#> 21                Crossings                <NA>
#> 22                Crossings                <NA>
#> 23                Crossings                <NA>
#> 24                Crossings                <NA>
#> 25                Crossings                <NA>
#> 26                Crossings                <NA>
#> 27                Crossings                <NA>
#> 28                Crossings                <NA>
#> 29                Crossings                <NA>
#> 30                  Streams                <NA>
#> 31                  Streams                <NA>
#> 32                  Streams                <NA>
#> 33                  Streams      Habitat models
#> 34                  Streams      Habitat models
#> 35                  Streams      Habitat models
#> 36     Other point features                <NA>
#> 37     Other point features                <NA>
#> 38     Other point features                <NA>
#> 39     Other point features                <NA>
#> 40 Roads,Railways,Pipelines                <NA>
#> 41 Roads,Railways,Pipelines                <NA>
#> 42 Roads,Railways,Pipelines                <NA>
#> 43 Roads,Railways,Pipelines                <NA>
#> 44 Roads,Railways,Pipelines                <NA>
#> 45 Roads,Railways,Pipelines                <NA>
#> 46 Roads,Railways,Pipelines                <NA>
#> 47 Roads,Railways,Pipelines                <NA>
#> 48                    Forms                <NA>
#> 49                    Forms                <NA>
#> 50               Floodplain                <NA>
#> 51              Restoration                <NA>
#> 52              Restoration                <NA>
#> 53     Web Mapping Services                <NA>
#> 54     Web Mapping Services                <NA>
#> 55              Base - misc                <NA>
#> 56              Base - misc                <NA>
#> 57              Base - misc                <NA>
#> 58              Base - misc                <NA>
#> 59              Base - misc                <NA>
#> 60              Base - misc                <NA>
#> 61              Base - misc                <NA>
#> 62              Base - misc                <NA>
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
#> 18                                       orthophoto_tiles     1      bcdata
#> 19                                               bec_zone     2      bcdata
#> 20                biogeoclimatic_ecosystem_classification     3      bcdata
#> 21                             crossings_pscis_assessment     1      bcdata
#> 22                           crossings_pscis_confirmation     2      bcdata
#> 23                                 crossings_pscis_design     3      bcdata
#> 24                             crossings_pscis_remedation     4      bcdata
#> 25                                     crossings_modelled     5         aws
#> 26                          crossings_pscis_modelled_dams     6         aws
#> 27                                          moti_culverts     7      bcdata
#> 28                                  moti_major_structures     8      bcdata
#> 29                                                    dam     9         aws
#> 30                                            streams_all     1         aws
#> 31                                          stream_labels     2         fwa
#> 32                         fisheries_sensitive_watersheds     3      bcdata
#> 33                                             streams_bt     1         aws
#> 34                                         streams_salmon     2         aws
#> 35                                             streams_st     3         aws
#> 36                               fiss_stream_sample_sites     1      bcdata
#> 37                       bcfishobs_fiss_fish_observations     2         aws
#> 38                                         fiss_obstacles     3         aws
#> 39                hydrometric_stations_environment_canada     4      bcdata
#> 40                                              roads_dra     1         aws
#> 41                                             roads_ften     2         aws
#> 42                                                railway     3      bcdata
#> 43                                     pipeline_installed     4      bcdata
#> 44                                        pipeline_permit     5      bcdata
#> 45                                   pipeline_application     6      bcdata
#> 46                                      transmission_line     7      bcdata
#> 47                                                 trails     8         osm
#> 48                                             form_pscis     1       local
#> 49                                         form_fiss_site     2       local
#> 50                                            floodplains     1      bcdata
#> 51                                           harvest_area     1       local
#> 52                                          planting_site     2       local
#> 53                                fire_perimeters_current     1         wms
#> 54                                   frep_rip2021_mar2022     2         wms
#> 55                                        habitat_lateral     1       local
#> 56                                              utm_zones     2      bcdata
#> 57 terrestrial_ecosystem_information_scanned_map_boundary     3      bcdata
#> 58                     terrain_mapping_project_boundaries     4      bcdata
#> 59                                        esri_world_topo     5         wms
#> 60                                            bing_aerial     6         wms
#> 61                                         esri_satellite     7         wms
#> 62                                       google_satellite     8         wms
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
#> 18        whse_imagery_and_base_maps.aimg_orthophoto_tiles_poly polygon
#> 19               whse_forest_vegetation.bec_biogeoclimatic_poly polygon
#> 20               whse_forest_vegetation.bec_biogeoclimatic_poly polygon
#> 21                               whse_fish.pscis_assessment_svw   point
#> 22                     whse_fish.pscis_habitat_confirmation_svw   point
#> 23                          whse_fish.pscis_design_proposal_svw   point
#> 24                              whse_fish.pscis_remediation_svw   point
#> 25                                      bcfishpass.crossings_vw   point
#> 26                                      bcfishpass.crossings_vw   point
#> 27                   whse_imagery_and_base_maps.mot_culverts_sp   point
#> 28             whse_imagery_and_base_maps.mot_road_structure_sp    line
#> 29                                              bcfishpass.dams   point
#> 30                                        bcfishpass.streams_vw    line
#> 31                           whse_basemapping.fwa_named_streams    line
#> 32          whse_wildlife_management.wcp_fish_sensitive_ws_poly polygon
#> 33                                        bcfishpass.streams_vw    line
#> 34                                        bcfishpass.streams_vw    line
#> 35                                        bcfishpass.streams_vw    line
#> 36                        whse_fish.fiss_stream_sample_sites_sp   point
#> 37                        bcfishobs.fiss_fish_obsrvtn_events_vw   point
#> 38                              whse_fish.fiss_obstacles_pnt_sp   point
#> 39      whse_environmental_monitoring.envcan_hydrometric_stn_sp   point
#> 40                              whse_basemapping.transport_line    line
#> 41               whse_forest_tenure.ften_road_section_lines_svw    line
#> 42                       whse_basemapping.gba_railway_tracks_sp    line
#> 43            whse_mineral_tenure.og_pipeline_segment_permit_sp    line
#> 44               whse_mineral_tenure.og_pipeline_area_permit_sp polygon
#> 45                 whse_mineral_tenure.og_pipeline_area_appl_sp polygon
#> 46                   whse_basemapping.gba_transmission_lines_sp    line
#> 47                                                    osm.trail    line
#> 48                                                   form_pscis   point
#> 49                                               form_fiss_site   point
#> 50                 whse_basemapping.cwb_floodplains_bc_area_svw polygon
#> 51                                                 harvest_area polygon
#> 52                                                planting_site   point
#> 53                                                         <NA>    <NA>
#> 54                                                         <NA>   point
#> 55                                              habitat_lateral  raster
#> 56                           whse_basemapping.utmg_utm_zones_sp polygon
#> 57         whse_terrestrial_ecology.ste_scanned_map_boundary_sp polygon
#> 58      whse_terrestrial_ecology.ste_ter_project_boundaries_svw polygon
#> 59                                                         <NA>    <NA>
#> 60                                                         <NA>    <NA>
#> 61                                                         <NA>    <NA>
#> 62                                                         <NA>    <NA>
```
