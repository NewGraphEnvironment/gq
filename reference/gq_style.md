# Get backend-agnostic style for a registry layer

Resolves a layer by name and returns a plain list of style properties.
No backend-specific objects (tmap, mapgl, etc.) — just colors, widths,
shapes, classification fields, and values.

## Usage

``` r
gq_style(layer_or_reg, name = NULL, field = NULL)
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

A named list with `type` and style properties. For simple layers:
`fill`, `stroke`, `mark` as applicable. For classified layers: adds
`classification` with `field`, `values` (named color vector), `labels`,
and per-class `widths`/`radii` when available.

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_registry_read(path)

# Simple polygon
gq_style(reg, "lake")
#> $type
#> [1] "polygon"
#> 
#> $fill
#> $fill$color
#> [1] "#c6ddf0"
#> 
#> $fill$opacity
#> [1] 0.85
#> 
#> 
#> $stroke
#> $stroke$color
#> [1] "#7ba7cc"
#> 
#> $stroke$width
#> [1] 0.5
#> 
#> 

# Simple line
gq_style(reg, "stream")
#> $type
#> [1] "line"
#> 
#> $stroke
#> $stroke$color
#> [1] "#7ba7cc"
#> 
#> $stroke$width
#> [1] 0.4
#> 
#> $stroke$opacity
#> [1] 0.8
#> 
#> 

# Classified line — includes field, values, labels
gq_style(reg, "road")
#> $type
#> [1] "line"
#> 
#> $classification
#> $classification$field
#> [1] "road_type"
#> 
#> $classification$values
#>   highway  arterial 
#> "#c0392b" "#e67e22" 
#> 
#> $classification$labels
#> [1] "Highway"  "Arterial"
#> 
#> $classification$widths
#>  highway arterial 
#>      2.0      1.5 
#> 
#> 

# Override classification field for alternative data source
gq_style(reg, "road", field = "my_road_type")
#> $type
#> [1] "line"
#> 
#> $classification
#> $classification$field
#> [1] "my_road_type"
#> 
#> $classification$values
#>   highway  arterial 
#> "#c0392b" "#e67e22" 
#> 
#> $classification$labels
#> [1] "Highway"  "Arterial"
#> 
#> $classification$widths
#>  highway arterial 
#>      2.0      1.5 
#> 
#> 

# Object-based (backwards compatible)
gq_style(reg$layers$lake)
#> $type
#> [1] "polygon"
#> 
#> $fill
#> $fill$color
#> [1] "#c6ddf0"
#> 
#> $fill$opacity
#> [1] 0.85
#> 
#> 
#> $stroke
#> $stroke$color
#> [1] "#7ba7cc"
#> 
#> $stroke$width
#> [1] 0.5
#> 
#> 
```
