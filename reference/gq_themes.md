# List all visibility themes

Returns a data.frame of all themes defined in the registry, showing
which groups are visible or hidden in each theme.

## Usage

``` r
gq_themes()
```

## Value

A data.frame with columns: theme, group, visible.

## Examples

``` r
gq_themes()
#>            theme                 group visible
#> 1     Field View                 Forms    TRUE
#> 2     Field View               Basemap    TRUE
#> 3     Field View             Crossings   FALSE
#> 4     Field View               Streams   FALSE
#> 5     Field View  Other Point Features   FALSE
#> 6     Field View Roads/Rails/Pipelines   FALSE
#> 7  Analysis View                 Forms    TRUE
#> 8  Analysis View             Crossings    TRUE
#> 9  Analysis View               Streams    TRUE
#> 10 Analysis View               Basemap    TRUE
#> 11 Analysis View  Other Point Features    TRUE
#> 12 Analysis View Roads/Rails/Pipelines    TRUE
#> 13      UAV View                 Forms   FALSE
#> 14      UAV View               Basemap    TRUE
#> 15      UAV View             Crossings   FALSE
```
