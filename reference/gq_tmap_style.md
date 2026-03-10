# Translate a registry layer style to tmap v4 arguments

Wraps
[`gq_style()`](https://newgraphenvironment.github.io/gq/reference/gq_style.md)
and returns a named list of arguments suitable for tmap v4 layer
functions (tm_polygons, tm_lines, tm_dots, tm_symbols). Handles both
simple and classified layers.

## Usage

``` r
gq_tmap_style(layer_or_reg, name = NULL, field = NULL)
```

## Arguments

- layer_or_reg:

  Either a layer entry from the registry (e.g., `reg$layers$lake`) or a
  full registry list when using name-based lookup.

- name:

  Optional layer name for name-based lookup. Accepts `name_qgis_snake`
  (e.g., `"lake"`) or `name_qgis` (e.g.,
  `"Crossings - PSCIS assessment"`). Normalized to match registry keys.

- field:

  Optional character string to override the classification field name.
  Useful when data comes from an alternative source with a different
  column name (e.g., bcfishpass `barrier_status` vs WHSE
  `barrier_result_code`). See `inst/registry/xref_layers.csv` for known
  alternatives.

## Value

A named list of tmap arguments. Use with
[`do.call()`](https://rdrr.io/r/base/do.call.html).

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_registry_read(path)

# Name-based lookup
gq_tmap_style(reg, "lake")
#> $fill
#> [1] "#c6ddf0"
#> 
#> $fill_alpha
#> [1] 0.85
#> 
#> $col
#> [1] "#7ba7cc"
#> 
#> $lwd
#> [1] 0.5
#> 
gq_tmap_style(reg, "stream")
#> $col
#> [1] "#7ba7cc"
#> 
#> $lwd
#> [1] 0.4
#> 
#> $col_alpha
#> [1] 0.8
#> 
gq_tmap_style(reg, "road")
#> $col
#> [1] "road_type"
#> 
#> $col.scale
#> $FUN
#> [1] "tmapScaleCategorical"
#> 
#> $n.max
#> [1] 30
#> 
#> $values
#>   highway  arterial 
#> "#c0392b" "#e67e22" 
#> 
#> $values.repeat
#> [1] TRUE
#> 
#> $values.range
#> [1] NA
#> 
#> $values.scale
#> [1] NA
#> 
#> $value.na
#> [1] NA
#> 
#> $value.null
#> [1] NA
#> 
#> $value.neutral
#> [1] NA
#> 
#> $levels
#> NULL
#> 
#> $levels.drop
#> [1] FALSE
#> 
#> $labels
#> [1] "Highway"  "Arterial"
#> 
#> $label.na
#> [1] NA
#> 
#> $label.null
#> [1] NA
#> 
#> $label.format
#> list()
#> 
#> attr(,"class")
#> [1] "tm_scale_categorical" "tm_scale"             "list"                
#> 
#> $col.legend
#> $show
#> [1] FALSE
#> 
#> $called
#> [1] "show"
#> 
#> $title
#> [1] NA
#> 
#> $xlab
#> [1] NA
#> 
#> $ylab
#> [1] NA
#> 
#> $group_id
#> [1] NA
#> 
#> $group_type
#> [1] "tm_legend"
#> 
#> $z
#> [1] NA
#> 
#> attr(,"class")
#> [1] "tm_legend"    "tm_component" "list"        
#> 
#> $lwd
#> [1] 2
#> 

# Override classification field for alternative data source
# (e.g., bcfishpass barrier_status vs WHSE barrier_result_code)
gq_tmap_style(reg, "road", field = "my_road_type")
#> $col
#> [1] "my_road_type"
#> 
#> $col.scale
#> $FUN
#> [1] "tmapScaleCategorical"
#> 
#> $n.max
#> [1] 30
#> 
#> $values
#>   highway  arterial 
#> "#c0392b" "#e67e22" 
#> 
#> $values.repeat
#> [1] TRUE
#> 
#> $values.range
#> [1] NA
#> 
#> $values.scale
#> [1] NA
#> 
#> $value.na
#> [1] NA
#> 
#> $value.null
#> [1] NA
#> 
#> $value.neutral
#> [1] NA
#> 
#> $levels
#> NULL
#> 
#> $levels.drop
#> [1] FALSE
#> 
#> $labels
#> [1] "Highway"  "Arterial"
#> 
#> $label.na
#> [1] NA
#> 
#> $label.null
#> [1] NA
#> 
#> $label.format
#> list()
#> 
#> attr(,"class")
#> [1] "tm_scale_categorical" "tm_scale"             "list"                
#> 
#> $col.legend
#> $show
#> [1] FALSE
#> 
#> $called
#> [1] "show"
#> 
#> $title
#> [1] NA
#> 
#> $xlab
#> [1] NA
#> 
#> $ylab
#> [1] NA
#> 
#> $group_id
#> [1] NA
#> 
#> $group_type
#> [1] "tm_legend"
#> 
#> $z
#> [1] NA
#> 
#> attr(,"class")
#> [1] "tm_legend"    "tm_component" "list"        
#> 
#> $lwd
#> [1] 2
#> 

# Object-based (backwards compatible)
gq_tmap_style(reg$layers$lake)
#> $fill
#> [1] "#c6ddf0"
#> 
#> $fill_alpha
#> [1] 0.85
#> 
#> $col
#> [1] "#7ba7cc"
#> 
#> $lwd
#> [1] 0.5
#> 

# Use with tmap v4:
# tm_shape(lakes_sf) + do.call(tm_polygons, gq_tmap_style(reg, "lake"))
# tm_shape(roads_sf) + do.call(tm_lines, gq_tmap_style(reg, "road"))
```
