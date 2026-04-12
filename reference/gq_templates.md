# List all project templates

Returns a data.frame of all templates defined in the registry, showing
which groups each template includes and their order.

## Usage

``` r
gq_templates()
```

## Value

A data.frame with columns: template, group, group_order.

## Examples

``` r
gq_templates()
#>                template                 group group_order
#> 1     bcfishpass_mobile                 Forms           1
#> 2     bcfishpass_mobile             Crossings           2
#> 3     bcfishpass_mobile  Other Point Features           3
#> 4     bcfishpass_mobile Roads/Rails/Pipelines           4
#> 5     bcfishpass_mobile               Streams           5
#> 6     bcfishpass_mobile               Basemap           6
#> 7     bcfishpass_mobile  Web Mapping Services           7
#> 8     bcfishpass_mobile           Base - misc           8
#> 9  bcrestoration_mobile                 Forms           1
#> 10 bcrestoration_mobile             Crossings           2
#> 11 bcrestoration_mobile               Streams           3
#> 12 bcrestoration_mobile Roads/Rails/Pipelines           4
#> 13 bcrestoration_mobile               Basemap           5
#> 14 bcrestoration_mobile            Floodplain           6
#> 15 bcrestoration_mobile           Restoration           7
#> 16 bcrestoration_mobile  Web Mapping Services           8
#> 17 bcrestoration_mobile           Base - misc           9
```
