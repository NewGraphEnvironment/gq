# Resolve template to layers

Expands a template through its groups to produce a flat data.frame of
every layer needed for that project type. Joins with the style registry
to include `source_layer` and `type`.

## Usage

``` r
gq_template_layers(template, registry = NULL)
```

## Arguments

- template:

  Character. Template name (e.g., `"bcfishpass_mobile"`).

- registry:

  Optional registry list (from
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)).
  If `NULL`, loads via
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md).

## Value

A data.frame with columns: template, group, group_order, subgroup,
layer_key, order, source_layer, source_type, type.

## Examples

``` r
gq_template_layers("bcfishpass_mobile")
#>             template                    group group_order            subgroup
#> 1  bcfishpass_mobile                    Forms           1                <NA>
#> 2  bcfishpass_mobile                    Forms           1                <NA>
#> 3  bcfishpass_mobile                    Forms           1                <NA>
#> 4  bcfishpass_mobile                    Forms           1                <NA>
#> 5  bcfishpass_mobile                Crossings           2                <NA>
#> 6  bcfishpass_mobile                Crossings           2                <NA>
#> 7  bcfishpass_mobile                Crossings           2                <NA>
#> 8  bcfishpass_mobile                Crossings           2                <NA>
#> 9  bcfishpass_mobile                Crossings           2                <NA>
#> 10 bcfishpass_mobile                Crossings           2                <NA>
#> 11 bcfishpass_mobile                Crossings           2                <NA>
#> 12 bcfishpass_mobile                Crossings           2                <NA>
#> 13 bcfishpass_mobile                Crossings           2                <NA>
#> 14 bcfishpass_mobile     Other point features           3                <NA>
#> 15 bcfishpass_mobile     Other point features           3                <NA>
#> 16 bcfishpass_mobile     Other point features           3                <NA>
#> 17 bcfishpass_mobile     Other point features           3                <NA>
#> 18 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 19 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 20 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 21 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 22 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 23 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 24 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 25 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 26 bcfishpass_mobile                  Streams           5                <NA>
#> 27 bcfishpass_mobile                  Streams           5                <NA>
#> 28 bcfishpass_mobile                  Streams           5                <NA>
#> 29 bcfishpass_mobile                  Streams           5      Habitat models
#> 30 bcfishpass_mobile                  Streams           5      Habitat models
#> 31 bcfishpass_mobile                  Streams           5      Habitat models
#> 32 bcfishpass_mobile                  Basemap           6                <NA>
#> 33 bcfishpass_mobile                  Basemap           6                <NA>
#> 34 bcfishpass_mobile                  Basemap           6                <NA>
#> 35 bcfishpass_mobile                  Basemap           6                <NA>
#> 36 bcfishpass_mobile                  Basemap           6                <NA>
#> 37 bcfishpass_mobile                  Basemap           6                <NA>
#> 38 bcfishpass_mobile                  Basemap           6                <NA>
#> 39 bcfishpass_mobile                  Basemap           6                <NA>
#> 40 bcfishpass_mobile                  Basemap           6                <NA>
#> 41 bcfishpass_mobile                  Basemap           6                <NA>
#> 42 bcfishpass_mobile                  Basemap           6                <NA>
#> 43 bcfishpass_mobile                  Basemap           6                <NA>
#> 44 bcfishpass_mobile                  Basemap           6                <NA>
#> 45 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 46 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 47 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 48 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 49 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 50 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 51 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 52 bcfishpass_mobile     Web Mapping Services           7                <NA>
#> 53 bcfishpass_mobile     Web Mapping Services           7                <NA>
#> 54 bcfishpass_mobile              Base - misc           8                <NA>
#> 55 bcfishpass_mobile              Base - misc           8                <NA>
#> 56 bcfishpass_mobile              Base - misc           8                <NA>
#> 57 bcfishpass_mobile              Base - misc           8                <NA>
#> 58 bcfishpass_mobile              Base - misc           8                <NA>
#> 59 bcfishpass_mobile              Base - misc           8                <NA>
#> 60 bcfishpass_mobile              Base - misc           8                <NA>
#> 61 bcfishpass_mobile              Base - misc           8                <NA>
#>                                                 layer_key order
#> 1                                              form_pscis     1
#> 2                                          form_fiss_site     2
#> 3                                               form_edna     3
#> 4                                         form_monitoring     4
#> 5                              crossings_pscis_assessment     1
#> 6                            crossings_pscis_confirmation     2
#> 7                                  crossings_pscis_design     3
#> 8                              crossings_pscis_remedation     4
#> 9                                      crossings_modelled     5
#> 10                          crossings_pscis_modelled_dams     6
#> 11                                          moti_culverts     7
#> 12                                  moti_major_structures     8
#> 13                                                    dam     9
#> 14                               fiss_stream_sample_sites     1
#> 15                       bcfishobs_fiss_fish_observations     2
#> 16                                         fiss_obstacles     3
#> 17                hydrometric_stations_environment_canada     4
#> 18                                              roads_dra     1
#> 19                                             roads_ften     2
#> 20                                                railway     3
#> 21                                     pipeline_installed     4
#> 22                                        pipeline_permit     5
#> 23                                   pipeline_application     6
#> 24                                      transmission_line     7
#> 25                                                 trails     8
#> 26                                            streams_all     1
#> 27                                          stream_labels     2
#> 28                         fisheries_sensitive_watersheds     3
#> 29                                             streams_bt     1
#> 30                                         streams_salmon     2
#> 31                                             streams_st     3
#> 32                               watershed_group_boundary     1
#> 33                                         municipalities     2
#> 34                                        provincial_park     3
#> 35                                          national_park     4
#> 36                                            conservancy     5
#> 37                            old_growth_management_areas     6
#> 38                                   first_nation_reserve     7
#> 39                                           range_tenure     8
#> 40                                         land_ownership     9
#> 41                                   fire_historical_burn    10
#> 42                                          fire_severity    11
#> 43                                               glaciers    12
#> 44                                                   town    13
#> 45                                       orthophoto_tiles     1
#> 46                                               bec_zone     2
#> 47                biogeoclimatic_ecosystem_classification     3
#> 48                                                   lake     1
#> 49                                                wetland     2
#> 50                                            rivers_poly     3
#> 51                                    manmade_waterbodies     4
#> 52                                fire_perimeters_current     1
#> 53                                   frep_rip2021_mar2022     2
#> 54                                        habitat_lateral     1
#> 55                                              utm_zones     2
#> 56 terrestrial_ecosystem_information_scanned_map_boundary     3
#> 57                     terrain_mapping_project_boundaries     4
#> 58                                        esri_world_topo     5
#> 59                                            bing_aerial     6
#> 60                                         esri_satellite     7
#> 61                                       google_satellite     8
#>                                                    source_layer source_type
#> 1                                                    form_pscis       local
#> 2                                                form_fiss_site       local
#> 3                                                          <NA>       local
#> 4                                                          <NA>       local
#> 5                                whse_fish.pscis_assessment_svw      bcdata
#> 6                      whse_fish.pscis_habitat_confirmation_svw      bcdata
#> 7                           whse_fish.pscis_design_proposal_svw      bcdata
#> 8                               whse_fish.pscis_remediation_svw      bcdata
#> 9                                       bcfishpass.crossings_vw         aws
#> 10                                      bcfishpass.crossings_vw         aws
#> 11                   whse_imagery_and_base_maps.mot_culverts_sp      bcdata
#> 12             whse_imagery_and_base_maps.mot_road_structure_sp      bcdata
#> 13                                              bcfishpass.dams         aws
#> 14                        whse_fish.fiss_stream_sample_sites_sp      bcdata
#> 15                        bcfishobs.fiss_fish_obsrvtn_events_vw         aws
#> 16                              whse_fish.fiss_obstacles_pnt_sp         aws
#> 17      whse_environmental_monitoring.envcan_hydrometric_stn_sp      bcdata
#> 18                              whse_basemapping.transport_line         aws
#> 19               whse_forest_tenure.ften_road_section_lines_svw         aws
#> 20                       whse_basemapping.gba_railway_tracks_sp      bcdata
#> 21            whse_mineral_tenure.og_pipeline_segment_permit_sp      bcdata
#> 22               whse_mineral_tenure.og_pipeline_area_permit_sp      bcdata
#> 23                 whse_mineral_tenure.og_pipeline_area_appl_sp      bcdata
#> 24                   whse_basemapping.gba_transmission_lines_sp      bcdata
#> 25                                                    osm.trail         osm
#> 26                                        bcfishpass.streams_vw         aws
#> 27                           whse_basemapping.fwa_named_streams         fwa
#> 28          whse_wildlife_management.wcp_fish_sensitive_ws_poly      bcdata
#> 29                                        bcfishpass.streams_vw         aws
#> 30                                        bcfishpass.streams_vw         aws
#> 31                                        bcfishpass.streams_vw         aws
#> 32                   whse_basemapping.fwa_watershed_groups_poly      bcdata
#> 33           whse_legal_admin_boundaries.abms_municipalities_sp      bcdata
#> 34                          whse_tantalis.ta_park_ecores_pa_svw      bcdata
#> 35                    whse_admin_boundaries.clab_national_parks      bcdata
#> 36                       whse_tantalis.ta_conservancy_areas_svw      bcdata
#> 37        whse_land_use_planning.rmp_ogma_non_legal_current_svw      bcdata
#> 38                   whse_admin_boundaries.clab_indian_reserves      bcdata
#> 39                  whse_forest_tenure.ften_range_poly_carto_vw         aws
#> 40                    whse_cadastre.pmbc_parcel_fabric_poly_svw         aws
#> 41 whse_land_and_natural_resource.prot_historical_fire_polys_sp      bcdata
#> 42                  whse_forest_vegetation.veg_burn_severity_sp      bcdata
#> 43                           whse_basemapping.fwa_glaciers_poly      bcdata
#> 44                   whse_basemapping.gns_geographical_names_sp      bcdata
#> 45        whse_imagery_and_base_maps.aimg_orthophoto_tiles_poly      bcdata
#> 46               whse_forest_vegetation.bec_biogeoclimatic_poly      bcdata
#> 47               whse_forest_vegetation.bec_biogeoclimatic_poly      bcdata
#> 48                              whse_basemapping.fwa_lakes_poly      bcdata
#> 49                           whse_basemapping.fwa_wetlands_poly      bcdata
#> 50                             whse_basemapping.fwa_rivers_poly      bcdata
#> 51                whse_basemapping.fwa_manmade_waterbodies_poly      bcdata
#> 52                                                         <NA>         wms
#> 53                                                         <NA>         wms
#> 54                                                         <NA>       local
#> 55                           whse_basemapping.utmg_utm_zones_sp      bcdata
#> 56         whse_terrestrial_ecology.ste_scanned_map_boundary_sp      bcdata
#> 57      whse_terrestrial_ecology.ste_ter_project_boundaries_svw      bcdata
#> 58                                                         <NA>         wms
#> 59                                                         <NA>         wms
#> 60                                                         <NA>         wms
#> 61                                                         <NA>         wms
#>       type
#> 1    point
#> 2    point
#> 3     <NA>
#> 4     <NA>
#> 5    point
#> 6    point
#> 7    point
#> 8    point
#> 9    point
#> 10   point
#> 11   point
#> 12    line
#> 13   point
#> 14   point
#> 15   point
#> 16   point
#> 17   point
#> 18    line
#> 19    line
#> 20    line
#> 21    line
#> 22 polygon
#> 23 polygon
#> 24    line
#> 25    line
#> 26    line
#> 27    line
#> 28 polygon
#> 29    line
#> 30    line
#> 31    line
#> 32 polygon
#> 33 polygon
#> 34 polygon
#> 35 polygon
#> 36 polygon
#> 37 polygon
#> 38 polygon
#> 39 polygon
#> 40 polygon
#> 41 polygon
#> 42 polygon
#> 43 polygon
#> 44   point
#> 45 polygon
#> 46 polygon
#> 47 polygon
#> 48 polygon
#> 49 polygon
#> 50 polygon
#> 51 polygon
#> 52    <NA>
#> 53   point
#> 54    <NA>
#> 55 polygon
#> 56 polygon
#> 57 polygon
#> 58    <NA>
#> 59    <NA>
#> 60    <NA>
#> 61    <NA>
```
