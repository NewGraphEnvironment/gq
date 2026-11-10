# Load the main gq style registry

Returns the merged master registry (`reg_main.json`) that ships with gq.
This is the single source of truth for all layer styles — the union of
QGIS-extracted registries and hand-curated CSV styles.

## Usage

``` r
gq_reg_main()
```

## Value

A list with `name`, `version`, `source`, and `layers` elements.

## Examples

``` r
reg <- gq_reg_main()
names(reg$layers)
#>  [1] "utm_zones"                                             
#>  [2] "watershed_group_boundary"                              
#>  [3] "municipalities"                                        
#>  [4] "glaciers"                                              
#>  [5] "fire_historical_burn"                                  
#>  [6] "fire_severity"                                         
#>  [7] "land_ownership"                                        
#>  [8] "range_tenure"                                          
#>  [9] "fisheries_sensitive_watersheds"                        
#> [10] "provincial_park"                                       
#> [11] "conservancy"                                           
#> [12] "orthophoto_tiles"                                      
#> [13] "terrestrial_ecosystem_information_scanned_map_boundary"
#> [14] "terrain_mapping_project_boundaries"                    
#> [15] "biogeoclimatic_ecosystem_classification"               
#> [16] "manmade_waterbodies"                                   
#> [17] "lake"                                                  
#> [18] "wetland"                                               
#> [19] "streams_all"                                           
#> [20] "first_nation_reserve"                                  
#> [21] "moti_culverts"                                         
#> [22] "crossings_modelled"                                    
#> [23] "crossings_pscis_assessment"                            
#> [24] "crossings_pscis_confirmation"                          
#> [25] "crossings_pscis_design"                                
#> [26] "crossings_pscis_remedation"                            
#> [27] "crossings_pscis_modelled_dams"                         
#> [28] "moti_major_structures"                                 
#> [29] "floodplains"                                           
#> [30] "form_pscis"                                            
#> [31] "form_fiss_site"                                        
#> [32] "fiss_stream_sample_sites"                              
#> [33] "bcfishobs_fiss_fish_observations"                      
#> [34] "fiss_obstacles"                                        
#> [35] "hydrometric_stations_environment_canada"               
#> [36] "pipeline_permit"                                       
#> [37] "pipeline_installed"                                    
#> [38] "pipeline_application"                                  
#> [39] "transmission_line"                                     
#> [40] "railway"                                               
#> [41] "roads_ften"                                            
#> [42] "roads_dra"                                             
#> [43] "trails"                                                
#> [44] "streams_salmon"                                        
#> [45] "streams_st"                                            
#> [46] "streams_bt"                                            
#> [47] "stream_labels"                                         
#> [48] "frep_rip2021_mar2022"                                  
#> [49] "bec_zone"                                              
#> [50] "rivers_poly"                                           
#> [51] "dam"                                                   
#> [52] "town"                                                  
#> [53] "harvest_area"                                          
#> [54] "planting_site"                                         
#> [55] "old_growth_management_areas"                           
#> [56] "national_park"                                         
#> [57] "habitat_lateral"                                       
#> [58] "habitat_rule_comparison"                               
#> [59] "habitat_expected_use"                                  
#> [60] "floodplain_flood_factor"                               
#> [61] "tree_cover_change"                                     
#> [62] "landcover_change_from"                                 
#> [63] "landcover_change_to"                                   

# Use directly with style translators
gq_tmap_style(gq_reg_main()$layers$lake)
#> $fill
#> [1] "#dcecf4"
#> 
#> $fill_alpha
#> [1] 0.7
#> 
#> $col
#> [1] "#1f78b4"
#> 
#> $lwd
#> [1] 0.2
#> 
```
