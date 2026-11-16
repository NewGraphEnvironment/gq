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
#> 18                  Basemap         Waterbodies
#> 19                  Basemap         Waterbodies
#> 20                  Basemap Terrestrial Ecology
#> 21                  Basemap Terrestrial Ecology
#> 22                  Basemap Terrestrial Ecology
#> 23                  Basemap Terrestrial Ecology
#> 24                  Basemap Terrestrial Ecology
#> 25                Crossings                <NA>
#> 26                Crossings                <NA>
#> 27                Crossings                <NA>
#> 28                Crossings                <NA>
#> 29                Crossings                <NA>
#> 30                Crossings                <NA>
#> 31                Crossings                <NA>
#> 32                Crossings                <NA>
#> 33                Crossings                <NA>
#> 34                  Streams       Stream labels
#> 35                  Streams      Habitat models
#> 36                  Streams      Habitat models
#> 37                  Streams      Habitat models
#> 38     Other point features                <NA>
#> 39     Other point features                <NA>
#> 40     Other point features                <NA>
#> 41     Other point features                <NA>
#> 42 Roads,Railways,Pipelines                <NA>
#> 43 Roads,Railways,Pipelines                <NA>
#> 44 Roads,Railways,Pipelines                <NA>
#> 45 Roads,Railways,Pipelines                <NA>
#> 46 Roads,Railways,Pipelines                <NA>
#> 47 Roads,Railways,Pipelines                <NA>
#> 48 Roads,Railways,Pipelines                <NA>
#> 49 Roads,Railways,Pipelines                <NA>
#> 50                    Forms                <NA>
#> 51                    Forms                <NA>
#> 52               Floodplain                <NA>
#> 53              Restoration                <NA>
#> 54              Restoration                <NA>
#> 55     Web Mapping Services                <NA>
#> 56     Web Mapping Services                <NA>
#> 57              Base - misc                <NA>
#> 58              Base - misc                <NA>
#> 59              Base - misc                <NA>
#> 60              Base - misc                <NA>
#> 61              Base - misc                <NA>
#> 62              Base - misc                <NA>
#>                                                 layer_key order source_type
#> 1                                watershed_group_boundary     1      bcdata
#> 2                                          municipalities     2      bcdata
#> 3                                                glaciers     3      bcdata
#> 4                                                    town     4      bcdata
#> 5                                    fire_historical_burn     5      bcdata
#> 6                                           fire_severity     6      bcdata
#> 7                             old_growth_management_areas     7      bcdata
#> 8                                           national_park     8      bcdata
#> 9                                          land_ownership     9         aws
#> 10                                           range_tenure    10         aws
#> 11                         fisheries_sensitive_watersheds    11      bcdata
#> 12                                        provincial_park    12      bcdata
#> 13                                            conservancy    13      bcdata
#> 14                                    manmade_waterbodies     1      bcdata
#> 15                                                   lake     2      bcdata
#> 16                                                wetland     3      bcdata
#> 17                                            streams_all     4         aws
#> 18                                   first_nation_reserve     5      bcdata
#> 19                                            rivers_poly     6      bcdata
#> 20                                       orthophoto_tiles     1      bcdata
#> 21 terrestrial_ecosystem_information_scanned_map_boundary     2      bcdata
#> 22                     terrain_mapping_project_boundaries     3      bcdata
#> 23                                               bec_zone     4      bcdata
#> 24                biogeoclimatic_ecosystem_classification     5      bcdata
#> 25                                          moti_culverts     1      bcdata
#> 26                                     crossings_modelled     2         aws
#> 27                             crossings_pscis_assessment     3      bcdata
#> 28                           crossings_pscis_confirmation     4      bcdata
#> 29                                 crossings_pscis_design     5      bcdata
#> 30                             crossings_pscis_remedation     6      bcdata
#> 31                          crossings_pscis_modelled_dams     7         aws
#> 32                                  moti_major_structures     8      bcdata
#> 33                                                    dam     9         aws
#> 34                                          stream_labels     1         fwa
#> 35                                         streams_salmon     1         aws
#> 36                                             streams_st     2         aws
#> 37                                             streams_bt     3         aws
#> 38                               fiss_stream_sample_sites     1      bcdata
#> 39                       bcfishobs_fiss_fish_observations     2         aws
#> 40                                         fiss_obstacles     3         aws
#> 41                hydrometric_stations_environment_canada     4      bcdata
#> 42                                        pipeline_permit     1      bcdata
#> 43                                     pipeline_installed     2      bcdata
#> 44                                   pipeline_application     3      bcdata
#> 45                                      transmission_line     4      bcdata
#> 46                                                railway     5      bcdata
#> 47                                             roads_ften     6         aws
#> 48                                              roads_dra     7         aws
#> 49                                                 trails     8         osm
#> 50                                             form_pscis     1       local
#> 51                                         form_fiss_site     2       local
#> 52                                            floodplains     1      bcdata
#> 53                                           harvest_area     1       local
#> 54                                          planting_site     2       local
#> 55                                   frep_rip2021_mar2022     1         wms
#> 56                                fire_perimeters_current     2         wms
#> 57                                        habitat_lateral     1         aws
#> 58                                              utm_zones     2      bcdata
#> 59                                         esri_satellite     3         wms
#> 60                                            bing_aerial     4         wms
#> 61                                       google_satellite     5         wms
#> 62                                        esri_world_topo     6         wms

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
#> 18                  Basemap         Waterbodies
#> 19                  Basemap         Waterbodies
#> 20                  Basemap Terrestrial Ecology
#> 21                  Basemap Terrestrial Ecology
#> 22                  Basemap Terrestrial Ecology
#> 23                  Basemap Terrestrial Ecology
#> 24                  Basemap Terrestrial Ecology
#> 25                Crossings                <NA>
#> 26                Crossings                <NA>
#> 27                Crossings                <NA>
#> 28                Crossings                <NA>
#> 29                Crossings                <NA>
#> 30                Crossings                <NA>
#> 31                Crossings                <NA>
#> 32                Crossings                <NA>
#> 33                Crossings                <NA>
#> 34                  Streams       Stream labels
#> 35                  Streams      Habitat models
#> 36                  Streams      Habitat models
#> 37                  Streams      Habitat models
#> 38     Other point features                <NA>
#> 39     Other point features                <NA>
#> 40     Other point features                <NA>
#> 41     Other point features                <NA>
#> 42 Roads,Railways,Pipelines                <NA>
#> 43 Roads,Railways,Pipelines                <NA>
#> 44 Roads,Railways,Pipelines                <NA>
#> 45 Roads,Railways,Pipelines                <NA>
#> 46 Roads,Railways,Pipelines                <NA>
#> 47 Roads,Railways,Pipelines                <NA>
#> 48 Roads,Railways,Pipelines                <NA>
#> 49 Roads,Railways,Pipelines                <NA>
#> 50                    Forms                <NA>
#> 51                    Forms                <NA>
#> 52               Floodplain                <NA>
#> 53              Restoration                <NA>
#> 54              Restoration                <NA>
#> 55     Web Mapping Services                <NA>
#> 56     Web Mapping Services                <NA>
#> 57              Base - misc                <NA>
#> 58              Base - misc                <NA>
#> 59              Base - misc                <NA>
#> 60              Base - misc                <NA>
#> 61              Base - misc                <NA>
#> 62              Base - misc                <NA>
#>                                                 layer_key order source_type
#> 1                                watershed_group_boundary     1      bcdata
#> 2                                          municipalities     2      bcdata
#> 3                                                glaciers     3      bcdata
#> 4                                                    town     4      bcdata
#> 5                                    fire_historical_burn     5      bcdata
#> 6                                           fire_severity     6      bcdata
#> 7                             old_growth_management_areas     7      bcdata
#> 8                                           national_park     8      bcdata
#> 9                                          land_ownership     9         aws
#> 10                                           range_tenure    10         aws
#> 11                         fisheries_sensitive_watersheds    11      bcdata
#> 12                                        provincial_park    12      bcdata
#> 13                                            conservancy    13      bcdata
#> 14                                    manmade_waterbodies     1      bcdata
#> 15                                                   lake     2      bcdata
#> 16                                                wetland     3      bcdata
#> 17                                            streams_all     4         aws
#> 18                                   first_nation_reserve     5      bcdata
#> 19                                            rivers_poly     6      bcdata
#> 20                                       orthophoto_tiles     1      bcdata
#> 21 terrestrial_ecosystem_information_scanned_map_boundary     2      bcdata
#> 22                     terrain_mapping_project_boundaries     3      bcdata
#> 23                                               bec_zone     4      bcdata
#> 24                biogeoclimatic_ecosystem_classification     5      bcdata
#> 25                                          moti_culverts     1      bcdata
#> 26                                     crossings_modelled     2         aws
#> 27                             crossings_pscis_assessment     3      bcdata
#> 28                           crossings_pscis_confirmation     4      bcdata
#> 29                                 crossings_pscis_design     5      bcdata
#> 30                             crossings_pscis_remedation     6      bcdata
#> 31                          crossings_pscis_modelled_dams     7         aws
#> 32                                  moti_major_structures     8      bcdata
#> 33                                                    dam     9         aws
#> 34                                          stream_labels     1         fwa
#> 35                                         streams_salmon     1         aws
#> 36                                             streams_st     2         aws
#> 37                                             streams_bt     3         aws
#> 38                               fiss_stream_sample_sites     1      bcdata
#> 39                       bcfishobs_fiss_fish_observations     2         aws
#> 40                                         fiss_obstacles     3         aws
#> 41                hydrometric_stations_environment_canada     4      bcdata
#> 42                                        pipeline_permit     1      bcdata
#> 43                                     pipeline_installed     2      bcdata
#> 44                                   pipeline_application     3      bcdata
#> 45                                      transmission_line     4      bcdata
#> 46                                                railway     5      bcdata
#> 47                                             roads_ften     6         aws
#> 48                                              roads_dra     7         aws
#> 49                                                 trails     8         osm
#> 50                                             form_pscis     1       local
#> 51                                         form_fiss_site     2       local
#> 52                                            floodplains     1      bcdata
#> 53                                           harvest_area     1       local
#> 54                                          planting_site     2       local
#> 55                                   frep_rip2021_mar2022     1         wms
#> 56                                fire_perimeters_current     2         wms
#> 57                                        habitat_lateral     1         aws
#> 58                                              utm_zones     2      bcdata
#> 59                                         esri_satellite     3         wms
#> 60                                            bing_aerial     4         wms
#> 61                                       google_satellite     5         wms
#> 62                                        esri_world_topo     6         wms
#>                                                    source_layer    type
#> 1                    whse_basemapping.fwa_watershed_groups_poly polygon
#> 2            whse_legal_admin_boundaries.abms_municipalities_sp polygon
#> 3                            whse_basemapping.fwa_glaciers_poly polygon
#> 4                    whse_basemapping.gns_geographical_names_sp   point
#> 5  whse_land_and_natural_resource.prot_historical_fire_polys_sp polygon
#> 6                   whse_forest_vegetation.veg_burn_severity_sp polygon
#> 7         whse_land_use_planning.rmp_ogma_non_legal_current_svw polygon
#> 8                     whse_admin_boundaries.clab_national_parks polygon
#> 9                     whse_cadastre.pmbc_parcel_fabric_poly_svw polygon
#> 10                  whse_forest_tenure.ften_range_poly_carto_vw polygon
#> 11          whse_wildlife_management.wcp_fish_sensitive_ws_poly polygon
#> 12                          whse_tantalis.ta_park_ecores_pa_svw polygon
#> 13                       whse_tantalis.ta_conservancy_areas_svw polygon
#> 14                whse_basemapping.fwa_manmade_waterbodies_poly polygon
#> 15                              whse_basemapping.fwa_lakes_poly polygon
#> 16                           whse_basemapping.fwa_wetlands_poly polygon
#> 17                                        bcfishpass.streams_vw    line
#> 18                   whse_admin_boundaries.clab_indian_reserves polygon
#> 19                             whse_basemapping.fwa_rivers_poly polygon
#> 20        whse_imagery_and_base_maps.aimg_orthophoto_tiles_poly polygon
#> 21         whse_terrestrial_ecology.ste_scanned_map_boundary_sp polygon
#> 22      whse_terrestrial_ecology.ste_ter_project_boundaries_svw polygon
#> 23               whse_forest_vegetation.bec_biogeoclimatic_poly polygon
#> 24               whse_forest_vegetation.bec_biogeoclimatic_poly polygon
#> 25                   whse_imagery_and_base_maps.mot_culverts_sp   point
#> 26                                      bcfishpass.crossings_vw   point
#> 27                               whse_fish.pscis_assessment_svw   point
#> 28                     whse_fish.pscis_habitat_confirmation_svw   point
#> 29                          whse_fish.pscis_design_proposal_svw   point
#> 30                              whse_fish.pscis_remediation_svw   point
#> 31                                      bcfishpass.crossings_vw   point
#> 32             whse_imagery_and_base_maps.mot_road_structure_sp    line
#> 33                                              bcfishpass.dams   point
#> 34                           whse_basemapping.fwa_named_streams    line
#> 35                                        bcfishpass.streams_vw    line
#> 36                                        bcfishpass.streams_vw    line
#> 37                                        bcfishpass.streams_vw    line
#> 38                        whse_fish.fiss_stream_sample_sites_sp   point
#> 39                                       bcfishobs.observations   point
#> 40                              whse_fish.fiss_obstacles_pnt_sp   point
#> 41      whse_environmental_monitoring.envcan_hydrometric_stn_sp   point
#> 42               whse_mineral_tenure.og_pipeline_area_permit_sp polygon
#> 43            whse_mineral_tenure.og_pipeline_segment_permit_sp    line
#> 44                 whse_mineral_tenure.og_pipeline_area_appl_sp polygon
#> 45                   whse_basemapping.gba_transmission_lines_sp    line
#> 46                       whse_basemapping.gba_railway_tracks_sp    line
#> 47               whse_forest_tenure.ften_road_section_lines_svw    line
#> 48                              whse_basemapping.transport_line    line
#> 49                                                    osm.trail    line
#> 50                                                   form_pscis   point
#> 51                                               form_fiss_site   point
#> 52                 whse_basemapping.cwb_floodplains_bc_area_svw polygon
#> 53                                                 harvest_area polygon
#> 54                                                planting_site   point
#> 55                                                         <NA>   point
#> 56                                                         <NA>    <NA>
#> 57                                          habitat_lateral.tif  raster
#> 58                           whse_basemapping.utmg_utm_zones_sp polygon
#> 59                                                         <NA>    <NA>
#> 60                                                         <NA>    <NA>
#> 61                                                         <NA>    <NA>
#> 62                                                         <NA>    <NA>
```
