# The roster of Mergin survey forms

The catalogue of field forms a project can carry, vendored from rfp's
`rfp_form_types.csv`. Non-spatial child tables are excluded — this is a
roster of map layers.

## Usage

``` r
gq_form_types()
```

## Value

A data.frame with columns: layer_key, form_type, label, description,
layer_name, geometry, symbol, color, label_expression. One row per
spatial form, ordered by `layer_key`.

## Details

This is a separate table from
[`gq_groups()`](https://newgraphenvironment.github.io/gq/reference/gq_groups.md)
rather than part of it, because the two answer different questions.
Forms are not baked into the QGIS templates: `rfp_qgs_form_add()`
injects them per project, and a project's config selects which. So
`groups.csv` carries the two forms the templates ship, and this carries
every form a project could ask for.

Folding the roster into `groups.csv` would make
[`gq_template_layers()`](https://newgraphenvironment.github.io/gq/reference/gq_template_layers.md)
report thirteen forms for a template that ships two — a project styled
for layers it never downloaded, which is the defect the composition
guards exist to catch.

`symbol` and `color` are `NA` for a form rfp has registered but not
styled. That is a statement about upstream, not a gap here: gq does not
invent symbology for a form whose appearance nobody has decided.

## Examples

``` r
forms <- gq_form_types()
nrow(forms)
#> [1] 13

# the key is derived from rfp's layer name, not from its type — these differ
forms[forms$form_type == "monitoring_fish_passage", c("form_type", "layer_key")]
#>                 form_type                    layer_key
#> 5 monitoring_fish_passage form_fish_passage_monitoring

# which forms rfp has styled, and which are still undecided
forms$layer_key[is.na(forms$color)]
#> [1] "form_edna"        "form_fhap"        "form_fish_sample" "form_monitoring" 

# the subset the shipped templates actually carry
intersect(forms$layer_key, gq_group_layers("Forms")$layer_key)
#> [1] "form_fiss_site" "form_pscis"    
```
