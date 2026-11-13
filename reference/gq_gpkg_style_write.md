# Store QGIS styles for a layer in a GeoPackage

Writes one or more QML documents into a GeoPackage's `layer_styles`
table, the table QGIS reads when a layer is opened from the file, so the
layer arrives styled with no `.qml` beside it. One style is the default
QGIS applies; the others are listed by name under the layer's
*Properties \> Symbology \> Style \> Load Style... \> From Database*.

## Usage

``` r
gq_gpkg_style_write(
  gpkg,
  layer,
  styles,
  default = names(styles)[1],
  description = NULL
)
```

## Arguments

- gpkg:

  Path to an existing GeoPackage.

- layer:

  Name of a feature table in `gpkg`.

- styles:

  A named character vector (or list of strings) of QML documents, such
  as
  [`gq_qgis_style()`](https://newgraphenvironment.github.io/gq/reference/gq_qgis_style.md)
  returns; names become the `styleName`s and must be unique and
  non-empty.

- default:

  Name of the style QGIS applies when it opens the layer. One of
  `names(styles)`; the first by default.

- description:

  Optional descriptions, one per style, written to the `description`
  column. Empty by default.

## Value

`gpkg`, invisibly.

## Details

Rows are written with the twelve columns QGIS itself writes. The
`f_table_catalog` and `f_table_schema` cells are empty strings, never
NULL, because QGIS matches a row to its layer on all four `f_*` columns,
and a NULL schema leaves the layer unstyled even though the row is
there.

The table is written through GDAL (via sf), which registers it in
`gpkg_contents` as an `attributes` table, as QGIS does: a `layer_styles`
table that is not registered is invisible to QGIS in any GeoPackage that
already carries another attributes table.

A style already stored for `layer` under one of the names in `styles` is
replaced; styles stored under other names, and every other layer's
styles, are kept. The style named by `default` becomes the layer's only
default. When every style is already stored as given, nothing is
written, so a second call leaves the file's bytes as they were.

## See also

[`gq_qgis_style()`](https://newgraphenvironment.github.io/gq/reference/gq_qgis_style.md)
to build a QML from a registry layer,
[`gq_style_qml()`](https://newgraphenvironment.github.io/gq/reference/gq_style_qml.md)
for the QML files gq ships.

## Examples

``` r
reg <- gq_reg_custom(system.file("registry", "reg_custom.csv", package = "gq"))

# a small line layer carrying both classification fields
segs <- sf::st_sf(
  rule_class = c("both", "first"),
  grade_class = c("0.6-0.8", "0-0.2"),
  geom = sf::st_sfc(
    sf::st_linestring(matrix(c(0, 0, 1, 1), 2)),
    sf::st_linestring(matrix(c(1, 2, 1, 3), 2)),
    crs = 3005
  )
)
gpkg <- tempfile(fileext = ".gpkg")
sf::st_write(segs, gpkg, "segments", quiet = TRUE)

# rule class as the default style, grade class as a second named style
gq_gpkg_style_write(gpkg, "segments", styles = c(
  rule = gq_qgis_style(reg, "habitat_rule_comparison"),
  grade = gq_qgis_style(reg, "habitat_expected_use")
))

st <- sf::st_read(gpkg, "layer_styles", quiet = TRUE)
st[, c("f_table_name", "f_geometry_column", "styleName", "useAsDefault")]
#>   f_table_name f_geometry_column styleName useAsDefault
#> 1     segments              geom      rule         TRUE
#> 2     segments              geom     grade        FALSE
```
