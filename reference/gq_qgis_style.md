# Translate a registry layer style to a QGIS QML document

Builds the QGIS-native form of a registry layer's symbology, so a layer
defined only in a custom registry CSV
([`gq_reg_custom()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_custom.md))
can be handed to QGIS coloured as
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
and
[`gq_mapgl_style()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_style.md)
draw it. A classified line or polygon becomes a categorized renderer
with one category per class; an unclassified one becomes a single-symbol
renderer.

## Usage

``` r
gq_qgis_style(layer_or_reg, name = NULL, field = NULL, path = NULL)
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
  `barrier_result_code`). `inst/registry/xref_layers.csv` lists the
  known alternatives: for each layer key, the database table the bundled
  data was queried from (`name_table`, e.g. `bcfishpass.crossings`) and
  the column that table classifies on (`class_field`).

- path:

  Optional file path. When given, the QML is also written there (UTF-8),
  and returned invisibly.

## Value

A length-one character string holding the QML document. Put it in a
`.qml` file beside a layer, or into a GeoPackage's `layer_styles` table
with
[`gq_gpkg_style_write()`](https://newgraphenvironment.github.io/gq/reference/gq_gpkg_style_write.md).

## Details

For a layer gq ships a QML for, prefer
[`gq_style_qml()`](https://newgraphenvironment.github.io/gq/reference/gq_style_qml.md):
that file is what QGIS itself wrote, and carries what the registry does
not model (labels, multi-layer symbols, casing, scale-dependent
rendering). This function writes only what the registry holds.

What each registry property becomes:

- class value and label: a `<category>`'s `value` and `label`;

- colour: QGIS's `r,g,b,a` form, from hex or an R colour name;

- line width and polygon outline width: millimetres, as the registry
  holds them (QGIS's default of 0.26 mm where the registry gives none);

- line dash: a named QGIS `line_style` (`dash`, `dot`, `dash dot`, ...)
  or, for a pattern such as `"4;2"`, a custom dash;

- line opacity: the symbol's `alpha`; polygon fill and outline opacity:
  the alpha of each colour (to the nearest 1/255), so the two can differ
  as the registry allows;

- a polygon class's outline: its own `outline_color` and `outline_width`
  when the registry has them, else the layer's `stroke`, else no
  outline.

Not written: labels, a line's `overlay` (a warning says so), and point
and raster layers, which error. An unclassified layer the registry gives
no fill or stroke colour (one whose QGIS symbol it could not model)
errors too.

## See also

[`gq_gpkg_style_write()`](https://newgraphenvironment.github.io/gq/reference/gq_gpkg_style_write.md)
to store it in a GeoPackage,
[`gq_style_qml()`](https://newgraphenvironment.github.io/gq/reference/gq_style_qml.md)
for the QML files gq ships.

## Examples

``` r
reg <- gq_reg_custom(system.file("registry", "reg_custom.csv", package = "gq"))

# a classified line: one category per class
qml <- gq_qgis_style(reg, "habitat_rule_comparison")
doc <- xml2::read_xml(qml)
cats <- xml2::xml_find_all(doc, ".//categories/category")
data.frame(
  value = xml2::xml_attr(cats, "value"),
  label = xml2::xml_attr(cats, "label")
)
#>     value                       label
#> 1    both                  Both rules
#> 2   first             First rule only
#> 3  second            Second rule only
#> 4 outside Floodplain outside the rule
# each class's colour, in QGIS's r,g,b,a form
xml2::xml_attr(
  xml2::xml_find_all(doc, ".//symbols/symbol//Option[@name='line_color']"),
  "value"
)
#> [1] "27,108,168,255" "217,95,2,255"   "27,158,119,255" "123,63,152,255"

# an unclassified polygon: a single symbol
xml2::xml_attr(
  xml2::xml_find_first(xml2::read_xml(gq_qgis_style(reg, "rivers_poly")),
                       ".//renderer-v2"),
  "type"
)
#> [1] "singleSymbol"

# write it beside a layer
out <- tempfile(fileext = ".qml")
gq_qgis_style(reg, "bec_zone", path = out)
file.exists(out)
#> [1] TRUE
```
