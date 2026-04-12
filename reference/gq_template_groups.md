# Get groups in a template

Returns the groups that make up a project template, in layer-panel
order.

## Usage

``` r
gq_template_groups(template)
```

## Arguments

- template:

  Character. Template name (e.g., `"bcfishpass_mobile"`).

## Value

A data.frame with columns: template, group, group_order. Returns empty
data.frame if template not found.

## Examples

``` r
gq_template_groups("bcfishpass_mobile")
#>            template                 group group_order
#> 1 bcfishpass_mobile                 Forms           1
#> 2 bcfishpass_mobile             Crossings           2
#> 3 bcfishpass_mobile  Other Point Features           3
#> 4 bcfishpass_mobile Roads/Rails/Pipelines           4
#> 5 bcfishpass_mobile               Streams           5
#> 6 bcfishpass_mobile               Basemap           6
#> 7 bcfishpass_mobile  Web Mapping Services           7
#> 8 bcfishpass_mobile           Base - misc           8
```
