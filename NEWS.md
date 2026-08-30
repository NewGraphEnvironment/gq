# gq 0.13.0

- **`High Detail - Crossings` shows its layers in `bcrestoration_mobile` again.**
  The roster recorded that theme as enumerating 28 layers and showing none of
  them. That was a faithful extraction of a template rfp shipped as a stub,
  repaired upstream in NewGraphEnvironment/rfp#217 and released in rfp v0.47.0.
  27 rows flip to visible; `esri_world_topo` stays off, as it is in
  `bcfishpass_mobile` too. Totals are unchanged at 232 rows over 9
  template-theme pairs, and `reg_main.json` and `groups.csv` are untouched.

  It is the most used theme in the fleet, so it is worth being right.

- **The 0.3.0 note below is wrong, and is left standing as the record.** That
  entry justified keying themes by template with "`High Detail - Crossings`
  shows 27 layers in `bcfishpass_mobile` and 0 in `bcrestoration_mobile`". The
  zero was the stub, not a design. `template` is still rightly part of the key —
  `Land Tenure` ships in one template only, and the two templates are separate
  files free to drift — but the illustration was a defect mistaken for evidence.

  The general form is worth carrying: when a registry difference is the evidence
  for a schema decision, check that it is a decision.

- **The assertion that pinned the zero is replaced by two guards.** One reports
  drift between templates sharing a theme name; one reports any theme that shows
  nothing, over every template-theme pair rather than only the shared ones — the
  stub shipped in a single template, so a shared-only check could not have seen
  it. Alongside them the roster's shape is now pinned (232 rows, 9 pairs, no
  duplicate key, `Land Tenure` at 26/22) and no theme may switch an opaque
  basemap on. Each was run against a restored defect rather than assumed to work.

  What none of them assert is that the roster still equals what the templates
  say; that needs a live-template test and is tracked separately.

# gq 0.12.0

- **`gq_form_types()` — the roster of Mergin survey forms**, vendored from rfp
  into `inst/registry/form_types.csv`. gq declared four forms; rfp registers
  fourteen. The roster is a separate table from `groups.csv` because the two
  answer different questions: `rfp_qgs_form_add()` injects forms per project and
  a project's config selects which, while `groups.csv` models per-template
  contents. Folding the roster in would have made `gq_template_layers()` report
  thirteen forms for a template shipping two.

  `form_edna` and `form_monitoring` leave `groups.csv` and land here. They are
  real forms with collected field data; neither is in either shipped template.

- **`habitat_lateral` is registered, and it is the registry's first raster.** It
  carries the full QGIS palette — band values 1 and 2, the QML's colours and
  labels, and the renderer's 0.4 opacity. `gq_tmap_classes()` reads it; the
  translators do not render rasters, so `gq_style_qml()` remains the answer for
  anything QGIS-facing.

- **Breaking: `gq_tmap_style()` and `gq_mapgl_classes()` now refuse a layer
  whose type they cannot render**, where both previously answered. The first
  returned an empty argument list, which `do.call(tm_polygons, list())` turns
  into tmap's own defaults — a map that looks fine and is not the registry's.
  The second returned a well-formed MapLibre match expression whose
  `["get", field]` reads a feature property, so on a raster source it resolved
  against nothing and painted every pixel the fallback colour.

  `gq_mapgl_classes()` also now requires a `type`, matching `gq_mapgl_style()`,
  which has always required one.

- `gq_reg_custom()` coerces `class_value` to character before using it as a
  class key. It was positional assignment for a numeric key, which the new
  raster convention — a paletted band keys on pixel value — invites.

# gq 0.11.0

- **Group names now match the shipped QGIS templates, and four of them
  changed.** `rfp_project_create()` copies a template and trims it, so a
  project's tree node is literally the template's string. gq spelling a group
  differently made the join fail in both directions, silently.

  | was | is |
  |---|---|
  | `Other Point Features` | `Other point features` |
  | `Roads/Rails/Pipelines` | `Roads,Railways,Pipelines` |
  | `Streams` / `Habitat Models` | `Streams` / `Habitat models` |
  | `Basemap` / `BEC` | `Basemap` / `Terrestrial Ecology` |

  **Grep your code for the four old strings.** `gq_group_layers()` returns a
  zero-row data frame for an unknown group, with no error and no warning, so a
  hardcoded old name gets an empty result and no signal — the same silent-drop
  class this release exists to remove. `rfp` is the only known consumer and does
  not pass group names, so no shim is shipped.

- **`Base - Orthoimagery` is gone; it never existed in any template.** 0.10.0
  added its `templates.csv` row from `groups.csv` without checking a `.qgs`, at
  `group_order` 11 — *below* `Base - misc`, which holds all four opaque xyz
  basemaps. The registry was declaring `orthophoto_tiles` beneath ESRI World
  Topo, which is exactly the failure that has twice cost a field user a layer.
  `orthophoto_tiles` moves to `Basemap/Terrestrial Ecology`, where the template
  keeps it.

- **`Floodplain` and `Restoration` move above `Basemap`** in
  `bcrestoration_mobile`. `Basemap` holds the waterbody fills that draw over a
  land-cover change product — 46% of one project's change area is water-class.

- **New guard: `inst/registry/template_groups.csv` and
  `tests/testthat/test-template_drift.R`.** The registry is now checked against
  the group tree of the shipped templates — composition both directions, byte-
  exact names, relative order on the intersection, and no group declared below
  the bottom of the template's stack. Divergences are declared exemptions
  carrying a reason and an issue, each asserted still needed. #66

# gq 0.10.0

- **Template composition is now guarded, and two groups that were never mapped
  are.** `gq_template_layers()` returns more layers for both shipped templates —
  `bcrestoration_mobile` 57 → 64, `bcfishpass_mobile` 58 → 61. A project built
  from a template was displaying cartography for data it never downloaded,
  because the chain `templates.csv → groups.csv → reg_main.json` is three joins
  deep and none of them reported a miss. `Base - Orthoimagery` had been mapped
  to zero templates for the entire history of the file with a green suite. #40

- **`source_type` now drives a real check, and two layers had the wrong value.**
  `harvest_area` and `planting_site` change from `bcdata` to `local` — a value
  change in a column `gq_groups()` returns, not just extra rows. They are
  project-authored layers ("buffered river corridor", "proposed restoration
  planting location"), never BCGW tables, so they now carry the
  `source_layer == layer_key` sentinel that `form_pscis` and `form_fiss_site`
  already used.

- **Two new registry layers.** `old_growth_management_areas` — the most-used
  layer in a 16-project corpus that the registry did not carry — with symbology
  **extracted** from a project that styles it. `national_park` with symbology
  **authored**, labelled as such in its `note`, reusing `provincial_park`'s
  colours rather than an invented hue. Neither has a renderer in the shipped
  `.qgs` templates, which is why neither was ever extracted.

- `group_order` is documented as a sort key only: per-template, requiring
  neither contiguity, a 1-based start, nor cross-template agreement. The two
  shipped templates happen to have those properties and do not define them.

# gq 0.9.0

- **Breaking for label text: the `ACCESS` `mapping_code` classes are relabelled.**
  `mapping_code` is `<habitat use>;<barrier status>[;INTERMITTENT]`, but the
  source QGIS project labelled token 1 `ACCESS` with the token 2 vocabulary, so
  every ACCESS class read back as a self-contradiction:

  | class | was | now |
  |---|---|---|
  | `ACCESS;NONE` | `No known barriers; no known barriers` | `Accessible; no known barriers` |
  | `ACCESS;MODELLED` | `No known barriers; potential barrier` | `Accessible; potential barrier` |
  | `ACCESS;ASSESSED` | `No known barriers; known barrier` | `Accessible; known barrier` |
  | `ACCESS;DAM` | `No known barriers; dam` | `Accessible; dam` |
  | `ACCESS;REMEDIATED` | `No known barriers; remediated` | `Accessible; remediated` |

  …and the five `;INTERMITTENT` variants of each, on `streams_salmon`,
  `streams_st` and `streams_bt` — 30 classes in all. Colours, widths, dashes and
  class keys are untouched.

  **If your project hand-decodes these tokens, you can delete that code.** At
  least three did. Anything that string-matches the old label text needs
  updating.

  This corrects an upstream authoring bug
  (NewGraphEnvironment/bcfishpass#13) at gq's registry build. `gq_reg_main()` is
  the corrected surface. Deliberately *not* corrected, because both must stay
  faithful to their source: `gq_qgs_extract()`, which copies the category label
  verbatim from whatever `.qgs` you hand it, and the shipped QML corpus
  (`gq_style_qml()`), which is byte-identical to rfp's store — so a style loaded
  into QGIS Desktop or QWC2 still shows the upstream wording until #13 lands.
  The `reg_qgis_*.json` extraction artifacts are likewise left as-extracted.
  Closes #33, #37.

- **The composition vignette's map now describes itself.** Its most prominent
  feature — a 397-feature salmon habitat network — was styled from the registry
  and missing from the legend entirely, while the prose beneath described its
  widths and dashes. Fixed, along with the reason it went unnoticed: a new test
  parses the map chunk and fails the build if any layer drawn from the registry
  is absent from the legend.

  The map also gained AOI containment, type sized for the width it is published
  at, and an editorial cut — 130 of 146 crossings are modelled candidates rather
  than surveyed sites, and at their correct size they buried the network the map
  exists to show. #61.

- Both vignettes moved to `bookdown::html_vignette2` with numbered figure
  captions; `bookdown` added to `Suggests`.

- Removed the dead `registry/` directory at the repo root — a build-ignored
  fossil superseded by `inst/registry/` at the original scaffold.

# gq 0.8.0

- **Point symbols now render at the size the registry says.** The mm-to-renderer
  conversion was a guessed constant in both backends — tmap divided by 3, mapgl
  divided by nothing — so the two disagreed by 3x and neither matched QGIS.
  Measured on the drawn ink, tmap was putting every marker on the page **27%
  oversized**.

  New `gq_symbol_size()` does the actual unit conversion, and it depends on the
  **shape**. tmap sizes symbols in grid "lines" (5.08 mm), but R's graphics
  engine then applies a per-`pch` factor, and base R normalises those by *area*
  where QGIS normalises by *extent*. A circle draws 3.81 mm of ink per size
  unit, a square 3.38, a triangle 5.13 — so one divisor cannot serve them all.
  MapLibre's `circle-radius` is a true radius in CSS pixels, so `mm / 2 * 96/25.4`.

  **Every point layer changes size.** On gq's own vignettes the crossings shrank
  41% and stopped burying the stream network, while the falls doubled and the
  fish observations quadrupled to their true relative weight. A `scale` argument
  shrinks a whole map uniformly if you need that — one number, rather than the
  per-layer hand-tuning this replaces.

  Note the registry's `radius` field is a **diameter**: `gq_qgs_extract()` reads
  the QGIS `SimpleMarker` option named `size`, the marker's overall extent, and
  stores it under a misleading name.

- **New: `gq_symbol_shape()`.** The registry has carried a mark shape for 15
  layers since extraction — circle, square, star, triangle — and nothing
  translated it, so maps hardcoded their own marker codes. `star` becomes
  `pch = 8`, which draws a star and takes no fill; a filled circle would have
  silently discarded the distinction. mapgl returns `NULL`, since a MapLibre
  `circle` layer has no shape concept.

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
