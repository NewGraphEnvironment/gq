# Get group visibility for a theme

Returns which groups are visible or hidden for a given theme.

## Usage

``` r
gq_theme_groups(theme)
```

## Arguments

- theme:

  Character. Theme name (e.g., `"Field View"`).

## Value

A data.frame with columns: theme, group, visible. Returns empty
data.frame if theme not found.

## Examples

``` r
gq_theme_groups("Field View")
#>        theme                 group visible
#> 1 Field View                 Forms    TRUE
#> 2 Field View               Basemap    TRUE
#> 3 Field View             Crossings   FALSE
#> 4 Field View               Streams   FALSE
#> 5 Field View  Other Point Features   FALSE
#> 6 Field View Roads/Rails/Pipelines   FALSE
```
