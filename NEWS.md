# gq 0.2.1

- The four xyz basemaps (`esri_world_topo`, `bing_aerial`, `esri_satellite`,
  `google_satellite`) join the roster in `Base - misc`. They were modelled
  nowhere before — baked into the upstream templates only — while the two data
  services in `Web Mapping Services` were already here. Measured against the
  templates rather than assumed: the six remote layers do **not** share a group.

# gq 0.2.0

- **Trail symbology.** The registry carried no trail, path, footway, cycleway or
  bridleway layer, so a project that added a trail network had nothing to style
  it with. `trails` is now a classified line layer on `highway` — the only tag
  populated on every feature, where `bicycle` sits on 16.4% and would put most
  features in a fallback class. Classes differ by colour, dash *and* width, so
  the map reads in printed greyscale as well as in colour.
- The style is **authored in a QGIS project and extracted**, not hand-written as
  registry rows. A classified line authored through `reg_custom.csv` comes back
  with per-class `width` and `dash` both `NULL`, because that path emits
  `outline_width`/`outline_color` while the translators read `width`/`dash` —
  and dash is exactly what distinguishes a trail from a road.
- `data-raw/reg_extract_restoration.R` accepts `RFP_TEMPLATE`, pointing at a
  source checkout. Without it `system.file()` resolves to the installed package,
  which is routinely behind: when this style was extracted the installed copy was
  three releases old and its template carried no trail layer, so the run would
  have silently produced a registry missing the layer it was made for.

# gq 0.1.0

First release.

* Capture the QGIS dash pattern on classified line layers (#32). The extractor
  previously dropped per-class line style, so dashed classes (e.g. the
  `;INTERMITTENT` stream classes in `streams_salmon`) came out solid.
  `gq_style()` now surfaces a per-class `dashes` vector, `gq_tmap_classes()`
  returns it, and `gq_mapgl_style()` consumes the exact pattern. The raw QGIS
  value is stored so each backend renders it as it can (mapgl uses the exact
  `line-dasharray`; tmap maps to `lty`).

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
