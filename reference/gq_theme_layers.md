# Get layer visibility for a theme

Returns which layers a theme shows or hides.

## Usage

``` r
gq_theme_layers(theme, template = NULL)
```

## Arguments

- theme:

  Character. Theme name, e.g. `"High Detail - Crossings"`.

- template:

  Character. Optional template name to restrict to.

## Value

A data.frame with columns: template, theme, layer_key, visible. Returns
an empty data.frame if the theme is not found.

## Details

Without `template`, a theme name that ships in more than one template
returns every template's rows concatenated — check the `template`
column, or pass it, when you want one project's answer.
`High Detail - Crossings` is the live example: it ships in both
templates with materially different content.

## Examples

``` r
# the same theme differs by template
xing <- gq_theme_layers("High Detail - Crossings")
tapply(xing$visible, xing$template, sum)
#>    bcfishpass_mobile bcrestoration_mobile 
#>                   27                    0 

# one template's answer
head(gq_theme_layers("Land Tenure", template = "bcrestoration_mobile"))
#>               template       theme                        layer_key visible
#> 1 bcrestoration_mobile Land Tenure bcfishobs_fiss_fish_observations   FALSE
#> 2 bcrestoration_mobile Land Tenure                      conservancy    TRUE
#> 3 bcrestoration_mobile Land Tenure                  esri_world_topo   FALSE
#> 4 bcrestoration_mobile Land Tenure             first_nation_reserve    TRUE
#> 5 bcrestoration_mobile Land Tenure                   fiss_obstacles   FALSE
#> 6 bcrestoration_mobile Land Tenure         fiss_stream_sample_sites   FALSE
```
