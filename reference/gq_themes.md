# List all visibility themes

Returns the theme roster extracted from the QGIS templates: which layers
each template's map themes show or hide.

## Usage

``` r
gq_themes(template = NULL)
```

## Arguments

- template:

  Character. Optional template name to restrict to, e.g.
  `"bcfishpass_mobile"`. Default `NULL` returns every template.

## Value

A data.frame with columns: template, theme, layer_key, visible.

## Details

Themes are recorded per layer because that is how QGIS stores them — a
`<visibility-preset>` enumerates each layer it governs with an explicit
visible flag. `template` is part of the key rather than a filter applied
afterwards because a theme name is not global: `Land Tenure` ships in
`bcrestoration_mobile` only. The templates are also separate files that
can drift independently, so a name shipping in both is not guaranteed to
carry the same content — at present every shared theme agrees layer for
layer, and the test suite reports it if that stops being true.

A theme governs only the layers it names. Templates carry more layers
than any one theme lists, so a returned set is partial: a layer absent
from a theme is not "hidden by" it, it is simply unmanaged and keeps
whatever state it had.

## Examples

``` r
# every theme in every template
head(gq_themes())
#>            template                   theme                        layer_key
#> 1 bcfishpass_mobile High Detail - Crossings bcfishobs_fiss_fish_observations
#> 2 bcfishpass_mobile High Detail - Crossings                      conservancy
#> 3 bcfishpass_mobile High Detail - Crossings               crossings_modelled
#> 4 bcfishpass_mobile High Detail - Crossings       crossings_pscis_assessment
#> 5 bcfishpass_mobile High Detail - Crossings                  esri_world_topo
#> 6 bcfishpass_mobile High Detail - Crossings             first_nation_reserve
#>   visible
#> 1    TRUE
#> 2    TRUE
#> 3    TRUE
#> 4    TRUE
#> 5   FALSE
#> 6    TRUE

# which themes a template ships
unique(gq_themes("bcrestoration_mobile")$theme)
#> [1] "High Detail - Crossings"       "Land Tenure"                  
#> [3] "Low Detail - Bull Trout Model" "Low Detail - Salmon Model"    
#> [5] "Low Detail - Steelhead Model" 
```
