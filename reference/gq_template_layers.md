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

## Details

Rows sort by `group_order`, then by `order` within each group, with a
group's own layers before its subgroups and subgroups by name. See the
Ordering section of
[`gq_group_layers()`](https://newgraphenvironment.github.io/gq/reference/gq_group_layers.md)
for what that does and does not match in the templates.

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
#> 24 bcfishpass_mobile                  Streams           5      Habitat models
#> 25 bcfishpass_mobile                  Streams           5      Habitat models
#> 26 bcfishpass_mobile                  Streams           5      Habitat models
#> 27 bcfishpass_mobile                  Streams           5       Stream labels
#> 28 bcfishpass_mobile                  Basemap           6                <NA>
#> 29 bcfishpass_mobile                  Basemap           6                <NA>
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
#> 41 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 42 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 43 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 44 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 45 bcfishpass_mobile                  Basemap           6 Terrestrial Ecology
#> 46 bcfishpass_mobile                  Basemap           6         Waterbodies
#> 47 bcfishpass_mobile                  Basemap           6         Waterbodies
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
#>                                                 layer_key order
#> 1                                              form_pscis     1
#> 2                                          form_fiss_site     2
#> 3                                           moti_culverts     1
#> 4                                      crossings_modelled     2
#> 5                              crossings_pscis_assessment     3
#> 6                            crossings_pscis_confirmation     4
#> 7                                  crossings_pscis_design     5
#> 8                              crossings_pscis_remedation     6
#> 9                           crossings_pscis_modelled_dams     7
#> 10                                  moti_major_structures     8
#> 11                                                    dam     9
#> 12                               fiss_stream_sample_sites     1
#> 13                       bcfishobs_fiss_fish_observations     2
#> 14                                         fiss_obstacles     3
#> 15                hydrometric_stations_environment_canada     4
#> 16                                        pipeline_permit     1
#> 17                                     pipeline_installed     2
#> 18                                   pipeline_application     3
#> 19                                      transmission_line     4
#> 20                                                railway     5
#> 21                                             roads_ften     6
#> 22                                              roads_dra     7
#> 23                                                 trails     8
#> 24                                         streams_salmon     1
#> 25                                             streams_st     2
#> 26                                             streams_bt     3
#> 27                                          stream_labels     1
#> 28                               watershed_group_boundary     1
#> 29                                         municipalities     2
#> 30                                               glaciers     3
#> 31                                                   town     4
#> 32                                   fire_historical_burn     5
#> 33                                          fire_severity     6
#> 34                            old_growth_management_areas     7
#> 35                                          national_park     8
#> 36                                         land_ownership     9
#> 37                                           range_tenure    10
#> 38                         fisheries_sensitive_watersheds    11
#> 39                                        provincial_park    12
#> 40                                            conservancy    13
#> 41                                       orthophoto_tiles     1
#> 42 terrestrial_ecosystem_information_scanned_map_boundary     2
#> 43                     terrain_mapping_project_boundaries     3
#> 44                                               bec_zone     4
#> 45                biogeoclimatic_ecosystem_classification     5
#> 46                                    manmade_waterbodies     1
#> 47                                                   lake     2
#> 48                                                wetland     3
#> 49                                            streams_all     4
#> 50                                   first_nation_reserve     5
#> 51                                            rivers_poly     6
#> 52                                   frep_rip2021_mar2022     1
#> 53                                fire_perimeters_current     2
#> 54                                        habitat_lateral     1
#> 55                                              utm_zones     2
#> 56                                         esri_satellite     3
#> 57                                            bing_aerial     4
#> 58                                       google_satellite     5
#> 59                                        esri_world_topo     6
#>                                                    source_layer source_type
#> 1                                                    form_pscis       local
#> 2                                                form_fiss_site       local
#> 3                    whse_imagery_and_base_maps.mot_culverts_sp      bcdata
#> 4                                       bcfishpass.crossings_vw         aws
#> 5                                whse_fish.pscis_assessment_svw      bcdata
#> 6                      whse_fish.pscis_habitat_confirmation_svw      bcdata
#> 7                           whse_fish.pscis_design_proposal_svw      bcdata
#> 8                               whse_fish.pscis_remediation_svw      bcdata
#> 9                                       bcfishpass.crossings_vw         aws
#> 10             whse_imagery_and_base_maps.mot_road_structure_sp      bcdata
#> 11                                              bcfishpass.dams         aws
#> 12                        whse_fish.fiss_stream_sample_sites_sp      bcdata
#> 13                                       bcfishobs.observations         aws
#> 14                              whse_fish.fiss_obstacles_pnt_sp         aws
#> 15      whse_environmental_monitoring.envcan_hydrometric_stn_sp      bcdata
#> 16               whse_mineral_tenure.og_pipeline_area_permit_sp      bcdata
#> 17            whse_mineral_tenure.og_pipeline_segment_permit_sp      bcdata
#> 18                 whse_mineral_tenure.og_pipeline_area_appl_sp      bcdata
#> 19                   whse_basemapping.gba_transmission_lines_sp      bcdata
#> 20                       whse_basemapping.gba_railway_tracks_sp      bcdata
#> 21               whse_forest_tenure.ften_road_section_lines_svw         aws
#> 22                              whse_basemapping.transport_line         aws
#> 23                                                    osm.trail         osm
#> 24                                        bcfishpass.streams_vw         aws
#> 25                                        bcfishpass.streams_vw         aws
#> 26                                        bcfishpass.streams_vw         aws
#> 27                           whse_basemapping.fwa_named_streams         fwa
#> 28                   whse_basemapping.fwa_watershed_groups_poly      bcdata
#> 29           whse_legal_admin_boundaries.abms_municipalities_sp      bcdata
#> 30                           whse_basemapping.fwa_glaciers_poly      bcdata
#> 31                   whse_basemapping.gns_geographical_names_sp      bcdata
#> 32 whse_land_and_natural_resource.prot_historical_fire_polys_sp      bcdata
#> 33                  whse_forest_vegetation.veg_burn_severity_sp      bcdata
#> 34        whse_land_use_planning.rmp_ogma_non_legal_current_svw      bcdata
#> 35                    whse_admin_boundaries.clab_national_parks      bcdata
#> 36                    whse_cadastre.pmbc_parcel_fabric_poly_svw         aws
#> 37                  whse_forest_tenure.ften_range_poly_carto_vw         aws
#> 38          whse_wildlife_management.wcp_fish_sensitive_ws_poly      bcdata
#> 39                          whse_tantalis.ta_park_ecores_pa_svw      bcdata
#> 40                       whse_tantalis.ta_conservancy_areas_svw      bcdata
#> 41        whse_imagery_and_base_maps.aimg_orthophoto_tiles_poly      bcdata
#> 42         whse_terrestrial_ecology.ste_scanned_map_boundary_sp      bcdata
#> 43      whse_terrestrial_ecology.ste_ter_project_boundaries_svw      bcdata
#> 44               whse_forest_vegetation.bec_biogeoclimatic_poly      bcdata
#> 45               whse_forest_vegetation.bec_biogeoclimatic_poly      bcdata
#> 46                whse_basemapping.fwa_manmade_waterbodies_poly      bcdata
#> 47                              whse_basemapping.fwa_lakes_poly      bcdata
#> 48                           whse_basemapping.fwa_wetlands_poly      bcdata
#> 49                                        bcfishpass.streams_vw         aws
#> 50                   whse_admin_boundaries.clab_indian_reserves      bcdata
#> 51                             whse_basemapping.fwa_rivers_poly      bcdata
#> 52                                                         <NA>         wms
#> 53                                                         <NA>         wms
#> 54                                          habitat_lateral.tif         aws
#> 55                           whse_basemapping.utmg_utm_zones_sp      bcdata
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
#> 16 polygon
#> 17    line
#> 18 polygon
#> 19    line
#> 20    line
#> 21    line
#> 22    line
#> 23    line
#> 24    line
#> 25    line
#> 26    line
#> 27    line
#> 28 polygon
#> 29 polygon
#> 30 polygon
#> 31   point
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
#> 44 polygon
#> 45 polygon
#> 46 polygon
#> 47 polygon
#> 48 polygon
#> 49    line
#> 50 polygon
#> 51 polygon
#> 52   point
#> 53    <NA>
#> 54  raster
#> 55 polygon
#> 56    <NA>
#> 57    <NA>
#> 58    <NA>
#> 59    <NA>
```
