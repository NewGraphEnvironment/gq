# gq 0.7.0

- **The default basemap provider changed, because the old one started serving a
  watermark.** Carto made their basemaps key-only; without a key they return an
  "API KEY REQUIRED" image. That image is a structurally valid PNG, so nothing
  errored, and a watermarked map reached the published documentation site.
  `gq_basemap_tiles()` now defaults to `Esri.WorldGrayCanvas` — keyless, and
  verified clean over BC extents.

  If you passed `provider` explicitly you are unaffected. If you relied on the
  default, your basemap changes appearance: the gray canvas is flatter than
  Positron, so a hillshade blend carries more of the terrain. In gq's own
  vignettes the result is more legible, not less.

- **New: a flat-tile warning.** A provider can answer HTTP 200 with an image
  that is not a map. `gq_basemap_tiles()` now warns when a tile comes back as a
  single flat colour — `Esri.WorldTerrain` does exactly this over parts of BC.
  The tile is still returned, since a genuinely uniform extent (open ocean)
  looks identical and dropping it would destroy valid data.

  Watermarked tiles are deliberately *not* detected. Measured across zoom
  levels, a clean tile and a watermarked one have indistinguishable dark-pixel
  fractions, so any threshold would pass watermarks while looking like a check.
  `?gq_basemap_tiles` carries the numbers and the reasoning.

- **Fixed: the documented "a failed tile fetch costs the basemap, not the
  figure" pattern never worked.** Both vignettes held a `NULL` raster and passed
  it to `tm_shape()`, which rejects `NULL` outright — so the guard moved the
  failure into map composition instead of preventing it. If you copied that
  block, build the whole *layer* conditionally rather than the data:

  ```r
  basemap <- if (is.null(canvas) || is.null(relief)) NULL else
    tm_shape(gq_basemap_blend(canvas, relief)) + tm_rgb()
  m <- basemap + tm_shape(aoi) + ...
  ```

  `NULL + tm_shape(...)` composes correctly, so an absent layer is the shape
  that holds.

# gq 0.6.0

- **Classified layers now render every aesthetic the registry defines, not just
  colour.** Line width, line dash and point size were collapsed to the *first
  registry class* and emitted as a scalar. For the `mapping_code` habitat layers
  that meant half the layer silently disappeared: habitat use drives width and
  barrier status drives colour, so every reach — spawning, rearing and access —
  drew at spawning width while the colours rendered correctly.

  Each axis now maps through its own scale, keyed on the same ordered class
  vector as colour. `do.call()` callers need no change.

  Dash had a second symptom worth naming: `gq_tmap_legend()` has emitted
  per-class `lty` since 0.3.0 while the map never read it, so the legend drew a
  dashed key beside a line the map drew solid — 15 of 30 stream classes.

- The returned list changes shape for classified layers: `lwd` and `size` are
  now the classification field name rather than a number, alongside new
  `lwd.scale` / `lty.scale` / `size.scale` entries. Numeric axes fall back to
  the old scalar when the registry defines the value for only some classes.

- Unknown class values no longer abort the render. Fixed as a side effect of
  0.5.1 passing `levels` — a layer whose data carries a code absent from the
  registry used to error with `All levels should occur in the vector names of
  values`.

# gq 0.5.1

- **Classified layers no longer mislabel when the data carries a subset of the
  registry's classes.** `tm_scale_categorical()` matches colours by name but
  labels by position, and derives its levels from the data — so with 3 of 26
  road classes present, tmap took the first three labels whichever classes
  those were. The package's own vignette was an instance: its arterial, highway
  and local roads drew as "Freeway" and "Highway".

  `gq_tmap_style()` now passes `levels` alongside `labels`, from the same
  ordered registry vector, so the two cannot drift whatever the data holds. No
  signature changed — there is nothing for callers to pass or remember.

  Scope was narrower than it first appeared: classified layers set
  `tm_legend(show = FALSE)`, and colours already matched by name, so the drawn
  map was never wrong. What changes is the warning on every classified draw,
  and the legend for anyone who turns it back on.

# gq 0.5.0

- **Map composition, not just style translation.** Six helpers encode the
  cartography conventions as defaults: `gq_bbox_aspect()`, `gq_bbox_clip()`,
  `gq_scale_breaks()`, `gq_basemap_tiles()` / `gq_basemap_blend()`,
  `gq_tmap_legend()` and `gq_tmap_keymap()`.

  Each replaces three to five copies scattered across the reporting repos, the
  package's own vignette and the cartography skill. Two of those copies
  documented themselves as ports of this vignette, so the code had already made
  the round trip out of gq and back.

- Extracting them settled three disagreements the copies did not know they had.
  `gq_bbox_aspect()` applies the latitude correction from the CRS rather than
  hardcoding one answer — a projected copy and a geographic copy each had it
  wrong for the other's input. `gq_basemap_blend()` ships two named operators,
  because the gamma form suited to a relief tile service and the capped linear
  form suited to a DEM hillshade were believed to be the same thing.
  `gq_bbox_clip()` keeps selecting features distinct from cutting them, which
  two near-identically named copies had blurred.

- `gq_tmap_legend()` merges simple and classified layers into one legend per
  geometry type and can cut classified entries to the values present in the
  data. Layout is delegated to tmap 4.4's `z` / `group_id` / `tm_components()`
  rather than reimplemented.

- `gq_tmap_legend()` collapses rows that render identically, so `roads_dra`'s 26
  classes become the 8 distinct appearances they actually draw as. A layer named
  twice therefore yields one entry unless the labels differ — the label is part
  of the key.

- Verified against the fish passage reporting originals on real cached rasters:
  identical bbox padding and scale breaks, and a bit-identical blend across
  14.7 million cells.

# gq 0.4.0

- **The QGIS-native styles now ship alongside the registry.**
  `inst/styles/` carries 60 QML files — 50 shared vector styles, 3 per-template
  overrides, 1 raster, 6 services — and `gq_style_qml(layer_key, template)`
  resolves a key to one.

  The registry models roughly 20 symbol properties and a single symbol layer,
  because that is what tmap and mapgl can render; a QML carries everything QGIS
  authored, including multi-layer symbols, casing and overlay, and per-class
  dash. Use the registry for tmap and mapgl, and the corpus for anything that
  speaks to QGIS — Desktop, Mergin field projects, QGIS Server / QWC2, or a
  `layer_styles` table.

  Passing a template is always safe: an override wins where one exists, the
  shared style otherwise, which covers the 50 of 53 layers that do not diverge.

  Unlike every other export this returns a **file path**, so callers get the
  bytes QGIS wrote without gq re-serializing them.

- gq does not lift QML from a `.qgs`. `data-raw/styles_vendor.R` vendors the
  artifact rfp already extracts and commits, a dev-only dependency matching the
  registry extract scripts. See `?gq_style_qml` and the corpus section of
  `CLAUDE.md`.

# gq 0.3.0

- **Themes describe what the templates actually ship.** `themes.csv` named three
  themes — *Field View*, *Analysis View*, *UAV View* — that exist in no
  template, at a granularity QGIS does not use. It is now extracted from the
  templates by `data-raw/reg_extract_themes.R` as
  `template,theme,layer_key,visible`: 232 rows over the 9 themes the two
  templates carry.

  `template` is part of the key rather than a filter, because the same theme
  name carries different content in different templates — `High Detail -
  Crossings` shows 27 layers in `bcfishpass_mobile` and 0 in
  `bcrestoration_mobile`.

- **Breaking:** `gq_theme_groups()` is replaced by
  `gq_theme_layers(theme, template = NULL)`. Group-granular rows could not
  express a theme that discriminates within a group, which is what QGIS themes
  do. `gq_themes()` gains a `template` argument and returns the four-column
  frame.

- `habitat_lateral` joins `groups.csv`. It is a raster, so the vector-only
  `gq_qgs_extract()` never saw it, yet every theme in both templates references
  it.

- `gq_qgs_extract()` now uses the same `normalize_layer_name()` helper as
  name-based lookup instead of its own copy of the rule.

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
