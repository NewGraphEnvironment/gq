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
#> 3  bcfishpass_mobile                Crossings           2                <NA>
#> 4  bcfishpass_mobile                Crossings           2                <NA>
#> 5  bcfishpass_mobile                Crossings           2                <NA>
#> 6  bcfishpass_mobile                Crossings           2                <NA>
#> 7  bcfishpass_mobile                Crossings           2                <NA>
#> 8  bcfishpass_mobile                Crossings           2                <NA>
#> 9  bcfishpass_mobile                Crossings           2                <NA>
#> 10 bcfishpass_mobile                Crossings           2                <NA>
#> 11 bcfishpass_mobile                Crossings           2                <NA>
#> 12 bcfishpass_mobile     Other point features           3                <NA>
#> 13 bcfishpass_mobile     Other point features           3                <NA>
#> 14 bcfishpass_mobile     Other point features           3                <NA>
#> 15 bcfishpass_mobile     Other point features           3                <NA>
#> 16 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 17 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 18 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 19 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 20 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 21 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 22 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 23 bcfishpass_mobile Roads,Railways,Pipelines           4                <NA>
#> 24 bcfishpass_mobile                  Streams           5                <NA>
#> 25 bcfishpass_mobile                  Streams           5                <NA>
#> 26 bcfishpass_mobile                  Streams           5                <NA>
#> 27 bcfishpass_mobile                  Streams           5      Habitat models
#> 28 bcfishpass_mobile                  Streams           5      Habitat models
#> 29 bcfishpass_mobile                  Streams           5      Habitat models
#> 30 bcfishpass_mobile                  Basemap           6                <NA>
#> 31 bcfishpass_mobile                  Basemap           6                <NA>
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
#> 43 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 44 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 45 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 46 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 47 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 48 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 49 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 50 bcfishpass_mobile     Web Mapping Services           7                <NA>
#> 51 bcfishpass_mobile     Web Mapping Services           7                <NA>
#> 52 bcfishpass_mobile              Base - misc           8                <NA>
#> 53 bcfishpass_mobile              Base - misc           8                <NA>
#> 54 bcfishpass_mobile              Base - misc           8                <NA>
#> 55 bcfishpass_mobile              Base - misc           8                <NA>
#> 56 bcfishpass_mobile              Base - misc           8                <NA>
#> 57 bcfishpass_mobile              Base - misc           8                <NA>
#> 58 bcfishpass_mobile              Base - misc           8                <NA>
#> 59 bcfishpass_mobile              Base - misc           8                <NA>
#>                                                 layer_key order
#> 1                                              form_pscis     1
#> 2                                          form_fiss_site     2
#> 3                              crossings_pscis_assessment     1
#> 4                            crossings_pscis_confirmation     2
#> 5                                  crossings_pscis_design     3
#> 6                              crossings_pscis_remedation     4
#> 7                                      crossings_modelled     5
#> 8                           crossings_pscis_modelled_dams     6
#> 9                                           moti_culverts     7
#> 10                                  moti_major_structures     8
#> 11                                                    dam     9
#> 12                               fiss_stream_sample_sites     1
#> 13                       bcfishobs_fiss_fish_observations     2
#> 14                                         fiss_obstacles     3
#> 15                hydrometric_stations_environment_canada     4
#> 16                                              roads_dra     1
#> 17                                             roads_ften     2
#> 18                                                railway     3
#> 19                                     pipeline_installed     4
#> 20                                        pipeline_permit     5
#> 21                                   pipeline_application     6
#> 22                                      transmission_line     7
#> 23                                                 trails     8
#> 24                                            streams_all     1
#> 25                                          stream_labels     2
#> 26                         fisheries_sensitive_watersheds     3
#> 27                                             streams_bt     1
#> 28                                         streams_salmon     2
#> 29                                             streams_st     3
#> 30                               watershed_group_boundary     1
#> 31                                         municipalities     2
#> 32                                        provincial_park     3
#> 33                                          national_park     4
#> 34                                            conservancy     5
#> 35                            old_growth_management_areas     6
#> 36                                   first_nation_reserve     7
#> 37                                           range_tenure     8
#> 38                                         land_ownership     9
#> 39                                   fire_historical_burn    10
#> 40                                          fire_severity    11
#> 41                                               glaciers    12
#> 42                                                   town    13
#> 43                                       orthophoto_tiles     1
#> 44                                               bec_zone     2
#> 45                biogeoclimatic_ecosystem_classification     3
#> 46                                                   lake     1
#> 47                                                wetland     2
#> 48                                            rivers_poly     3
#> 49                                    manmade_waterbodies     4
#> 50                                fire_perimeters_current     1
#> 51                                   frep_rip2021_mar2022     2
#> 52                                        habitat_lateral     1
#> 53                                              utm_zones     2
#> 54 terrestrial_ecosystem_information_scanned_map_boundary     3
#> 55                     terrain_mapping_project_boundaries     4
#> 56                                        esri_world_topo     5
#> 57                                            bing_aerial     6
#> 58                                         esri_satellite     7
#> 59                                       google_satellite     8
#>                                                    source_layer source_type
#> 1                                                    form_pscis       local
#> 2                                                form_fiss_site       local
#> 3                                whse_fish.pscis_assessment_svw      bcdata
#> 4                      whse_fish.pscis_habitat_confirmation_svw      bcdata
#> 5                           whse_fish.pscis_design_proposal_svw      bcdata
#> 6                               whse_fish.pscis_remediation_svw      bcdata
#> 7                                       bcfishpass.crossings_vw         aws
#> 8                                       bcfishpass.crossings_vw         aws
#> 9                    whse_imagery_and_base_maps.mot_culverts_sp      bcdata
#> 10             whse_imagery_and_base_maps.mot_road_structure_sp      bcdata
#> 11                                              bcfishpass.dams         aws
#> 12                        whse_fish.fiss_stream_sample_sites_sp      bcdata
#> 13                        bcfishobs.fiss_fish_obsrvtn_events_vw         aws
#> 14                              whse_fish.fiss_obstacles_pnt_sp         aws
#> 15      whse_environmental_monitoring.envcan_hydrometric_stn_sp      bcdata
#> 16                              whse_basemapping.transport_line         aws
#> 17               whse_forest_tenure.ften_road_section_lines_svw         aws
#> 18                       whse_basemapping.gba_railway_tracks_sp      bcdata
#> 19            whse_mineral_tenure.og_pipeline_segment_permit_sp      bcdata
#> 20               whse_mineral_tenure.og_pipeline_area_permit_sp      bcdata
#> 21                 whse_mineral_tenure.og_pipeline_area_appl_sp      bcdata
#> 22                   whse_basemapping.gba_transmission_lines_sp      bcdata
#> 23                                                    osm.trail         osm
#> 24                                        bcfishpass.streams_vw         aws
#> 25                           whse_basemapping.fwa_named_streams         fwa
#> 26          whse_wildlife_management.wcp_fish_sensitive_ws_poly      bcdata
#> 27                                        bcfishpass.streams_vw         aws
#> 28                                        bcfishpass.streams_vw         aws
#> 29                                        bcfishpass.streams_vw         aws
#> 30                   whse_basemapping.fwa_watershed_groups_poly      bcdata
#> 31           whse_legal_admin_boundaries.abms_municipalities_sp      bcdata
#> 32                          whse_tantalis.ta_park_ecores_pa_svw      bcdata
#> 33                    whse_admin_boundaries.clab_national_parks      bcdata
#> 34                       whse_tantalis.ta_conservancy_areas_svw      bcdata
#> 35        whse_land_use_planning.rmp_ogma_non_legal_current_svw      bcdata
#> 36                   whse_admin_boundaries.clab_indian_reserves      bcdata
#> 37                  whse_forest_tenure.ften_range_poly_carto_vw         aws
#> 38                    whse_cadastre.pmbc_parcel_fabric_poly_svw         aws
#> 39 whse_land_and_natural_resource.prot_historical_fire_polys_sp      bcdata
#> 40                  whse_forest_vegetation.veg_burn_severity_sp      bcdata
#> 41                           whse_basemapping.fwa_glaciers_poly      bcdata
#> 42                   whse_basemapping.gns_geographical_names_sp      bcdata
#> 43        whse_imagery_and_base_maps.aimg_orthophoto_tiles_poly      bcdata
#> 44               whse_forest_vegetation.bec_biogeoclimatic_poly      bcdata
#> 45               whse_forest_vegetation.bec_biogeoclimatic_poly      bcdata
#> 46                              whse_basemapping.fwa_lakes_poly      bcdata
#> 47                           whse_basemapping.fwa_wetlands_poly      bcdata
#> 48                             whse_basemapping.fwa_rivers_poly      bcdata
#> 49                whse_basemapping.fwa_manmade_waterbodies_poly      bcdata
#> 50                                                         <NA>         wms
#> 51                                                         <NA>         wms
#> 52                                              habitat_lateral       local
#> 53                           whse_basemapping.utmg_utm_zones_sp      bcdata
#> 54         whse_terrestrial_ecology.ste_scanned_map_boundary_sp      bcdata
#> 55      whse_terrestrial_ecology.ste_ter_project_boundaries_svw      bcdata
#> 56                                                         <NA>         wms
#> 57                                                         <NA>         wms
#> 58                                                         <NA>         wms
#> 59                                                         <NA>         wms
#>       type
#> 1    point
#> 2    point
#> 3    point
#> 4    point
#> 5    point
#> 6    point
#> 7    point
#> 8    point
#> 9    point
#> 10    line
#> 11   point
#> 12   point
#> 13   point
#> 14   point
#> 15   point
#> 16    line
#> 17    line
#> 18    line
#> 19    line
#> 20 polygon
#> 21 polygon
#> 22    line
#> 23    line
#> 24    line
#> 25    line
#> 26 polygon
#> 27    line
#> 28    line
#> 29    line
#> 30 polygon
#> 31 polygon
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
#> 42   point
#> 43 polygon
#> 44 polygon
#> 45 polygon
#> 46 polygon
#> 47 polygon
#> 48 polygon
#> 49 polygon
#> 50    <NA>
#> 51   point
#> 52  raster
#> 53 polygon
#> 54 polygon
#> 55 polygon
#> 56    <NA>
#> 57    <NA>
#> 58    <NA>
#> 59    <NA>
```
