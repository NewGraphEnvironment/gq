# Changelog

## gq 0.5.1

- **Classified layers no longer mislabel when the data carries a subset
  of the registry’s classes.**
  [`tm_scale_categorical()`](https://r-tmap.github.io/tmap/reference/tm_scale_categorical.html)
  matches colours by name but labels by position, and derives its levels
  from the data — so with 3 of 26 road classes present, tmap took the
  first three labels whichever classes those were. The package’s own
  vignette was an instance: its arterial, highway and local roads drew
  as “Freeway” and “Highway”.

  [`gq_tmap_style()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_style.md)
  now passes `levels` alongside `labels`, from the same ordered registry
  vector, so the two cannot drift whatever the data holds. No signature
  changed — there is nothing for callers to pass or remember.

  Scope was narrower than it first appeared: classified layers set
  `tm_legend(show = FALSE)`, and colours already matched by name, so the
  drawn map was never wrong. What changes is the warning on every
  classified draw, and the legend for anyone who turns it back on.

## gq 0.5.0

- **Map composition, not just style translation.** Six helpers encode
  the cartography conventions as defaults:
  [`gq_bbox_aspect()`](https://newgraphenvironment.github.io/gq/reference/gq_bbox_aspect.md),
  [`gq_bbox_clip()`](https://newgraphenvironment.github.io/gq/reference/gq_bbox_clip.md),
  [`gq_scale_breaks()`](https://newgraphenvironment.github.io/gq/reference/gq_scale_breaks.md),
  [`gq_basemap_tiles()`](https://newgraphenvironment.github.io/gq/reference/gq_basemap_tiles.md)
  /
  [`gq_basemap_blend()`](https://newgraphenvironment.github.io/gq/reference/gq_basemap_blend.md),
  [`gq_tmap_legend()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_legend.md)
  and
  [`gq_tmap_keymap()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_keymap.md).

  Each replaces three to five copies scattered across the reporting
  repos, the package’s own vignette and the cartography skill. Two of
  those copies documented themselves as ports of this vignette, so the
  code had already made the round trip out of gq and back.

- Extracting them settled three disagreements the copies did not know
  they had.
  [`gq_bbox_aspect()`](https://newgraphenvironment.github.io/gq/reference/gq_bbox_aspect.md)
  applies the latitude correction from the CRS rather than hardcoding
  one answer — a projected copy and a geographic copy each had it wrong
  for the other’s input.
  [`gq_basemap_blend()`](https://newgraphenvironment.github.io/gq/reference/gq_basemap_blend.md)
  ships two named operators, because the gamma form suited to a relief
  tile service and the capped linear form suited to a DEM hillshade were
  believed to be the same thing.
  [`gq_bbox_clip()`](https://newgraphenvironment.github.io/gq/reference/gq_bbox_clip.md)
  keeps selecting features distinct from cutting them, which two
  near-identically named copies had blurred.

- [`gq_tmap_legend()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_legend.md)
  merges simple and classified layers into one legend per geometry type
  and can cut classified entries to the values present in the data.
  Layout is delegated to tmap 4.4’s `z` / `group_id` /
  [`tm_components()`](https://r-tmap.github.io/tmap/reference/tm_components.html)
  rather than reimplemented.

- [`gq_tmap_legend()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_legend.md)
  collapses rows that render identically, so `roads_dra`’s 26 classes
  become the 8 distinct appearances they actually draw as. A layer named
  twice therefore yields one entry unless the labels differ — the label
  is part of the key.

- Verified against the fish passage reporting originals on real cached
  rasters: identical bbox padding and scale breaks, and a bit-identical
  blend across 14.7 million cells.

## gq 0.4.0

- **The QGIS-native styles now ship alongside the registry.**
  `inst/styles/` carries 60 QML files — 50 shared vector styles, 3
  per-template overrides, 1 raster, 6 services — and
  `gq_style_qml(layer_key, template)` resolves a key to one.

  The registry models roughly 20 symbol properties and a single symbol
  layer, because that is what tmap and mapgl can render; a QML carries
  everything QGIS authored, including multi-layer symbols, casing and
  overlay, and per-class dash. Use the registry for tmap and mapgl, and
  the corpus for anything that speaks to QGIS — Desktop, Mergin field
  projects, QGIS Server / QWC2, or a `layer_styles` table.

  Passing a template is always safe: an override wins where one exists,
  the shared style otherwise, which covers the 50 of 53 layers that do
  not diverge.

  Unlike every other export this returns a **file path**, so callers get
  the bytes QGIS wrote without gq re-serializing them.

- gq does not lift QML from a `.qgs`. `data-raw/styles_vendor.R` vendors
  the artifact rfp already extracts and commits, a dev-only dependency
  matching the registry extract scripts. See
  [`?gq_style_qml`](https://newgraphenvironment.github.io/gq/reference/gq_style_qml.md)
  and the corpus section of `CLAUDE.md`.

## gq 0.3.0

- **Themes describe what the templates actually ship.** `themes.csv`
  named three themes — *Field View*, *Analysis View*, *UAV View* — that
  exist in no template, at a granularity QGIS does not use. It is now
  extracted from the templates by `data-raw/reg_extract_themes.R` as
  `template,theme,layer_key,visible`: 232 rows over the 9 themes the two
  templates carry.

  `template` is part of the key rather than a filter, because the same
  theme name carries different content in different templates —
  `High Detail - Crossings` shows 27 layers in `bcfishpass_mobile` and 0
  in `bcrestoration_mobile`.

- **Breaking:** `gq_theme_groups()` is replaced by
  `gq_theme_layers(theme, template = NULL)`. Group-granular rows could
  not express a theme that discriminates within a group, which is what
  QGIS themes do.
  [`gq_themes()`](https://newgraphenvironment.github.io/gq/reference/gq_themes.md)
  gains a `template` argument and returns the four-column frame.

- `habitat_lateral` joins `groups.csv`. It is a raster, so the
  vector-only
  [`gq_qgs_extract()`](https://newgraphenvironment.github.io/gq/reference/gq_qgs_extract.md)
  never saw it, yet every theme in both templates references it.

- [`gq_qgs_extract()`](https://newgraphenvironment.github.io/gq/reference/gq_qgs_extract.md)
  now uses the same `normalize_layer_name()` helper as name-based lookup
  instead of its own copy of the rule.

## gq 0.2.1

- The four xyz basemaps (`esri_world_topo`, `bing_aerial`,
  `esri_satellite`, `google_satellite`) join the roster in
  `Base - misc`. They were modelled nowhere before — baked into the
  upstream templates only — while the two data services in
  `Web Mapping Services` were already here. Measured against the
  templates rather than assumed: the six remote layers do **not** share
  a group.

## gq 0.2.0

- **Trail symbology.** The registry carried no trail, path, footway,
  cycleway or bridleway layer, so a project that added a trail network
  had nothing to style it with. `trails` is now a classified line layer
  on `highway` — the only tag populated on every feature, where
  `bicycle` sits on 16.4% and would put most features in a fallback
  class. Classes differ by colour, dash *and* width, so the map reads in
  printed greyscale as well as in colour.
- The style is **authored in a QGIS project and extracted**, not
  hand-written as registry rows. A classified line authored through
  `reg_custom.csv` comes back with per-class `width` and `dash` both
  `NULL`, because that path emits `outline_width`/`outline_color` while
  the translators read `width`/`dash` — and dash is exactly what
  distinguishes a trail from a road.
- `data-raw/reg_extract_restoration.R` accepts `RFP_TEMPLATE`, pointing
  at a source checkout. Without it
  [`system.file()`](https://rdrr.io/r/base/system.file.html) resolves to
  the installed package, which is routinely behind: when this style was
  extracted the installed copy was three releases old and its template
  carried no trail layer, so the run would have silently produced a
  registry missing the layer it was made for.

## gq 0.1.0

First release.

- Capture the QGIS dash pattern on classified line layers
  ([\#32](https://github.com/NewGraphEnvironment/gq/issues/32)). The
  extractor previously dropped per-class line style, so dashed classes
  (e.g. the `;INTERMITTENT` stream classes in `streams_salmon`) came out
  solid.
  [`gq_style()`](https://newgraphenvironment.github.io/gq/reference/gq_style.md)
  now surfaces a per-class `dashes` vector,
  [`gq_tmap_classes()`](https://newgraphenvironment.github.io/gq/reference/gq_tmap_classes.md)
  returns it, and
  [`gq_mapgl_style()`](https://newgraphenvironment.github.io/gq/reference/gq_mapgl_style.md)
  consumes the exact pattern. The raw QGIS value is stored so each
  backend renders it as it can (mapgl uses the exact `line-dasharray`;
  tmap maps to `lty`).

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
  `gq_theme_groups()`. All 53 registry layer keys mapped to 12 canonical
  groups.

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
