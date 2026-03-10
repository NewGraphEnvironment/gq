# Get classification info for tmap scale functions

For categorized/graduated layers, returns the field, color values, and
labels suitable for tmap's `tm_scale_categorical()`.

## Usage

``` r
gq_tmap_classes(layer_or_reg, name = NULL, field = NULL)
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

A named list with `values` (named color vector), `labels`, and `field`.

## Examples

``` r
path <- system.file("examples", "mini_registry.json", package = "gq")
reg <- gq_registry_read(path)

# Name-based lookup
cls <- gq_tmap_classes(reg, "road")
cls$field
#> [1] "road_type"
cls$values
#>   highway  arterial 
#> "#c0392b" "#e67e22" 
cls$labels
#> [1] "Highway"  "Arterial"

# Object-based (backwards compatible)
cls <- gq_tmap_classes(reg$layers$road)
```
