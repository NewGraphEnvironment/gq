# Get the QGIS-native QML style for a layer

Returns the path to a layer's QML — the QGIS-native form of its
symbology, complete in a way the registry is not.
[`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)
and the
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
/
[`gq_mapgl_style()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_style.md)
translators model roughly 20 symbol properties and a single symbol
layer, because that is what tmap and mapgl can render. A QML carries
everything QGIS authored: multi-layer symbols, casing and overlay,
labelling, per-class dash. Use the registry for tmap and mapgl, and this
for anything that speaks to QGIS — Desktop, Mergin field projects, QGIS
Server / QWC2, or a `layer_styles` table.

## Usage

``` r
gq_style_qml(layer_key, template = NULL)
```

## Arguments

- layer_key:

  Layer key, as used by
  [`gq_groups()`](https://newgraphenvironment.github.io/gq/reference/gq_groups.md)
  and the registry (e.g. `"lake"`). See
  [`gq_groups()`](https://newgraphenvironment.github.io/gq/reference/gq_groups.md)
  for the roster.

- template:

  Optional project template (e.g. `"bcfishpass_mobile"`). When supplied,
  a template-specific override wins over the shared style. Must name a
  template
  [`gq_templates()`](https://newgraphenvironment.github.io/gq/reference/gq_templates.md)
  knows. When `NULL` (default) the shared style is returned.

## Value

A length-one character path to a `.qml` file.

## Details

Unlike every other gq export, this returns a **file path** rather than a
list or a data frame. The QML is shipped as-is, byte-for-byte what QGIS
wrote, so handing back a path lets the caller copy it, read it, or write
it into a `layer_styles` row without gq re-serializing it and
introducing drift.

Styles are shared across project templates unless a template genuinely
diverges — measured upstream, 3 layers of 53 do. Passing `template`
returns that template's override when one exists and the shared style
otherwise, so naming a valid template is always safe. An unknown
template name errors rather than falling back, since a silent fallback
would hand back the shared style on exactly the layers where an override
exists because the shared one is wrong for that template.

## See also

[`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)
for the cross-backend registry,
[`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
and
[`gq_mapgl_style()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_style.md)
for the tmap and mapgl translations.

## Examples

``` r
# the QGIS-native style for lakes
qml <- gq_style_qml("lake")
basename(qml)
#> [1] "lake.qml"

# a QML is a full QGIS style document, not a property digest
doc <- xml2::read_xml(qml)
xml2::xml_name(xml2::xml_root(doc))
#> [1] "qgis"

# three layers differ between templates; the rest are shared
basename(dirname(gq_style_qml("land_ownership", "bcfishpass_mobile")))
#> [1] "bcfishpass_mobile"
basename(dirname(gq_style_qml("land_ownership", "bcrestoration_mobile")))
#> [1] "vector"
```
