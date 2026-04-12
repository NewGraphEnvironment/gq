# gq (development version)

## 0.0.0.9000

* Add groups, templates, and themes composition layer (#28). Three CSVs
  in `inst/registry/` model how layers compose into QGIS projects — group
  membership with nesting and z-order, project templates, and visibility
  themes. Seven new functions: `gq_groups()`, `gq_group_layers()`,
  `gq_templates()`, `gq_template_groups()`, `gq_template_layers()`,
  `gq_themes()`, `gq_theme_groups()`. All 53 registry layer keys mapped
  to 12 canonical groups.

* Add `gq_style()` — backend-agnostic style resolver with name-based registry
  lookup. Accepts layer names like `"lake"` or `"Crossings - PSCIS assessment"`,
  normalizes to registry keys, returns plain lists of colors, widths, and
  classification info. No tmap/mapgl dependency.

* `gq_tmap_style()` and `gq_tmap_classes()` now accept name-based lookup:
  `gq_tmap_style(reg, "lake")` instead of `gq_tmap_style(reg$layers$lake)`.
  Classified layers return full `tm_scale_categorical()` wiring — no manual
  color extraction needed. Backwards compatible with object-based calls.

* Add Neexdzii Kwa subbasin datasets: habitat, crossings, fish observations,
  falls.

* Rename `gq_reg_read_csv()` to `gq_reg_custom()` — describes what it does,
  not the file format.

* `gq_style()`, `gq_tmap_style()`, and `gq_tmap_classes()` gain a `field`
  parameter to override the classification field name. Useful when data
  comes from an alternative source with a different column name (e.g.,
  bcfishpass `barrier_status` vs WHSE `barrier_result_code`). No column
  renames needed in user code.

* `gq_qgs_extract()` now handles QGIS grouped categories (#25). Categorized
  renderers that group multiple values under one symbol (e.g., Highway =
  RH1 + RH2 + RRP) are expanded into individual class entries. Previously
  only single-value categories were extracted.

* Add `inst/registry/xref_layers.csv` — cross-reference for layers with
  alternative data sources and different classification field names.

* Update composition vignette: all layer colors trace back to
  `gq_reg_main()` via `gq_style()` and `gq_tmap_style()`. No hardcoded
  hex values. Field mismatches handled via `field` parameter — no column
  renames.
