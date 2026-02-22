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
#>  [1] "conservancy"                                           
#>  [2] "crossings_pscis_design"                                
#>  [3] "crossings_pscis_remedation"                            
#>  [4] "crossings_pscis_modelled_dams"                         
#>  [5] "crossings_pscis_assessment"                            
#>  [6] "crossings_pscis_confirmation"                          
#>  [7] "crossings_modelled"                                    
#>  [8] "fiss_obstacles"                                        
#>  [9] "frep_rip2021_mar2022"                                  
#> [10] "fire_historical_burn"                                  
#> [11] "fire_severity"                                         
#> [12] "first_nation_reserve"                                  
#> [13] "form_fiss_site"                                        
#> [14] "form_pscis"                                            
#> [15] "lake"                                                  
#> [16] "moti_culverts"                                         
#> [17] "pipeline_installed"                                    
#> [18] "pipeline_permit"                                       
#> [19] "provincial_park"                                       
#> [20] "railway"                                               
#> [21] "roads_dra"                                             
#> [22] "roads_ften"                                            
#> [23] "stream_labels"                                         
#> [24] "streams_all"                                           
#> [25] "transmission_line"                                     
#> [26] "watershed_group_boundary"                              
#> [27] "wetland"                                               
#> [28] "municipalities"                                        
#> [29] "pipeline_application"                                  
#> [30] "bcfishobs_fiss_fish_observations"                      
#> [31] "fiss_stream_sample_sites"                              
#> [32] "streams_bt"                                            
#> [33] "streams_salmon"                                        
#> [34] "streams_st"                                            
#> [35] "floodplains"                                           
#> [36] "glaciers"                                              
#> [37] "manmade_waterbodies"                                   
#> [38] "utm_zones"                                             
#> [39] "land_ownership"                                        
#> [40] "hydrometric_stations_environment_canada"               
#> [41] "range_tenure"                                          
#> [42] "biogeoclimatic_ecosystem_classification"               
#> [43] "orthophoto_tiles"                                      
#> [44] "moti_major_structures"                                 
#> [45] "terrestrial_ecosystem_information_scanned_map_boundary"
#> [46] "terrain_mapping_project_boundaries"                    
#> [47] "fisheries_sensitive_watersheds"                        
#> [48] "bec_zone"                                              
#> [49] "rivers_poly"                                           
#> [50] "dam"                                                   
#> [51] "town"                                                  

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
