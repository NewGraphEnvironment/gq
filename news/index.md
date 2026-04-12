# Changelog

## gq (development version)

### 0.0.0.9000

- Add groups, templates, and themes composition layer
  ([\#28](https://github.com/NewGraphEnvironment/gq/issues/28)). Three
  CSVs in `inst/registry/` model how layers compose into QGIS projects —
  group membership with nesting and z-order, project templates, and
  visibility themes. Seven new functions:
  [`gq_groups()`](https://newgraphenvironment.github.io/gq/reference/gq_groups.md),
  [`gq_group_layers()`](https://newgraphenvironment.github.io/gq/reference/gq_group_layers.md),
  [`gq_templates()`](https://newgraphenvironment.github.io/gq/reference/gq_templates.md),
  [`gq_template_groups()`](https://newgraphenvironment.github.io/gq/reference/gq_template_groups.md),
  [`gq_template_layers()`](https://newgraphenvironment.github.io/gq/reference/gq_template_layers.md),
  [`gq_themes()`](https://newgraphenvironment.github.io/gq/reference/gq_themes.md),
  [`gq_theme_groups()`](https://newgraphenvironment.github.io/gq/reference/gq_theme_groups.md).
  All 53 registry layer keys mapped to 12 canonical groups.

- Add
  [`gq_style()`](https://newgraphenvironment.github.io/gq/reference/gq_style.md)
  — backend-agnostic style resolver with name-based registry lookup.
  Accepts layer names like `"lake"` or `"Crossings - PSCIS assessment"`,
  normalizes to registry keys, returns plain lists of colors, widths,
  and classification info. No tmap/mapgl dependency.

- [`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
  and
  [`gq_tmap_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_classes.md)
  now accept name-based lookup: `gq_tmap_style(reg, "lake")` instead of
  `gq_tmap_style(reg$layers$lake)`. Classified layers return full
  [`tm_scale_categorical()`](https://r-tmap.github.io/tmap/reference/tm_scale_categorical.html)
  wiring — no manual color extraction needed. Backwards compatible with
  object-based calls.

- Add Neexdzii Kwa subbasin datasets: habitat, crossings, fish
  observations, falls.

- Rename `gq_reg_read_csv()` to
  [`gq_reg_custom()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_custom.md)
  — describes what it does, not the file format.

- [`gq_style()`](https://newgraphenvironment.github.io/gq/reference/gq_style.md),
  [`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md),
  and
  [`gq_tmap_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_classes.md)
  gain a `field` parameter to override the classification field name.
  Useful when data comes from an alternative source with a different
  column name (e.g., bcfishpass `barrier_status` vs WHSE
  `barrier_result_code`). No column renames needed in user code.

- [`gq_qgs_extract()`](https://newgraphenvironment.github.io/gq/reference/gq_qgs_extract.md)
  now handles QGIS grouped categories
  ([\#25](https://github.com/NewGraphEnvironment/gq/issues/25)).
  Categorized renderers that group multiple values under one symbol
  (e.g., Highway = RH1 + RH2 + RRP) are expanded into individual class
  entries. Previously only single-value categories were extracted.

- Add `inst/registry/xref_layers.csv` — cross-reference for layers with
  alternative data sources and different classification field names.

- Update composition vignette: all layer colors trace back to
  [`gq_reg_main()`](https://newgraphenvironment.github.io/gq/reference/gq_reg_main.md)
  via
  [`gq_style()`](https://newgraphenvironment.github.io/gq/reference/gq_style.md)
  and
  [`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md).
  No hardcoded hex values. Field mismatches handled via `field`
  parameter — no column renames.
