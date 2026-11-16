# Code-check round 4: branch 103-extractor-fidelity-and-labels (HEAD 6d79c32)

## Checklist read

- **code-check.md:** I read the prose of all 14 H3s under `## Mechanisms` and skipped the evidence tables. I paid closest attention to "A fix lands in one of two callers that share a harness", "A proxy is not the property", "A guard's scope, escape hatches, and remedies" and "Restore the bug and prove the guard fires". From "Rules that stand alone" I read only the index lines. Documentation Staleness is cited below from its index line.
- **code-check-r.md:** I read these in full:
  - "`$` on a list partial-matches, so a longer sibling key answers for a missing one"
  - "A replacement function on an `xml_missing` node is a silent no-op"
  - "`package_version()` errors on a pre-release version string"
  - "`nzchar(NA)` is TRUE"
  - "Cross-function consistency for label/string normalization"

  For the rest I read the index only.
- **code-check-spatial.md:** I read "QGIS embeds a layer's style in the `.qgs`…" in full. It does not apply: the extractor reads styles, and the QML writer writes a standalone `.qml`. For the rest I read the index only.
- **code-check-shell.md:** I read the index only. The diff contains no shell.

## Method

- Every measurement below was taken on HEAD 6d79c32.
- Tests ran in a detached worktree at HEAD with `NOT_CRAN=true`, tmap 4.4.1 and mapgl 0.5.2. The worktree has since been removed.
- Probe scripts are in `/private/tmp/claude-501/-Users-airvine-Projects-repo-gq/cf479d2d-046d-4bd1-a28f-bd777d73b352/scratchpad/r4/`: `probe1.R` to `probe5.R` and `mut.R`.
- I enumerated the symbol-layer reads by grepping every `xml_find_*` in `R/gq_qgs_extract.R`, then every other file in `R/` and `data-raw/`.
- I enumerated the opacity reads and writes by grepping `opacity|alpha` across `R/`.

## Enumeration

### 1. Which symbol layers count

| Path | Agree? | Evidence |
|---|---|---|
| `symbol_read()` :323, called by single, categorized and graduated | agree | `./layer[not(@enabled='0')]`. Mutation "drop the filter" turns the categorized test red. |
| `parse_single_symbol` :364 | agree | `.//symbol` finds the first symbol, which is `./symbols/symbol` for a singleSymbol renderer. |
| `parse_categorized` / `parse_graduated` :475 and :517 | agree | `.//symbols/symbol` plus `symbol_named()`. Sub-symbols sit under `<layer>`, not `<symbols>`, so they are never selected. |
| `tick_overlay()` sub-symbol :276 | **DISAGREE** | `./symbol/layer` has no `enabled` filter. probe1 A: a tick marker with `enabled="0"` still produces `overlay {#000000, 2.4, "0.2;2.8"}`, the same as the enabled control. QGIS draws nothing for it. Round 3 said this path "fails safe"; it does so only for length != 1. No live instance: 0 disabled sub-symbol layers in either rfp template. (**F1**) |
| `color_data_defined()` :166 | **DISAGREE** with the modelled set | It reads enabled **top-level** layers. symbol_read **models** the first layer, the casing pair and the tick marker inside the MarkerLine. probe1 B: an active `outlineColor` on the tick marker, whose colour is the overlay colour, returns FALSE. probe1 C: an expression on an unmodelled top-level FontMarker returns TRUE, so the note says QGIS draws the expression's colour "instead of these", while the registry's SimpleLine colour is unaffected. No live instance: all 36 active colour expressions in the template are on single-layer SimpleLine symbols of `streams_salmon`, `streams_st` and `streams_bt` (probe3). (**F2**) |
| categories with `render="false"` | agree, no live instance | Both parsers include them as classes. 0 in the template (probe2). |
| `parse_labels` :575 | agree | `.//settings[not(ancestor::rule[@active='0'])]`, held by the test "a rule switched off…". |
| `data-raw/fixture_extract_template.R` | agree | It keeps `renderer-v2` whole. I regenerated it in the worktree with both env vars set and `git status` came back clean, so the fixtures are byte-identical. |

### 2. Unmodelled layers named

| Path | Agree? | Evidence |
|---|---|---|
| single `unmodelled_note(sr$unmodelled)` | agree | Uses an index `setdiff`, so a first layer the registry cannot model is named. Test "a first symbol layer…" is red under mutation. Live: `pipeline_permit` now reads "LinePatternFill, SimpleLine". |
| class `class_style()` attr → `class_note()` | agree | The same `unmodelled`. A class overlay is named as `MarkerLine` (:450). Mutation "drop the MarkerLine append" leaves the suite **green**: that guard is untested. |
| RuleRenderer arm :93 | agree | It carries a note. |
| any other renderer type (fall-through at :87-96) | **DISAGREE** with the roxygen `@return` | probe4: `invertedPolygonRenderer`, `pointCluster` and `heatmapRenderer` each yield only `type` and `source_layer`, with no note. No live instance: the rfp templates and the qlr fixture use only single, categorized and rule renderers. (**F4**) |
| symbol-layer pass order / symbol levels | **DISAGREE** with the roxygen at :8-11 | The roxygen says pass order "is named in the layer's note". No code names it, and CLAUDE.md:190 says it was declined. **Live:** `Roads - DRA` and `Trails` have non-zero `pass`, and `roads_dra` has `note = NULL` in `reg_main.json`. (**F4**) |

### 3. Opacity composed or read

| Path | Agree? | Evidence |
|---|---|---|
| extractor single fill :377 | agree | `sr$alpha * colour alpha` |
| extractor single polygon outline :387 | agree | Mutation "drop `sr$alpha`" is red. Mutation "drop the outline colour alpha" is **green**, because the fixture outline is opaque, so that guard is untested. Live: `municipalities` stroke 0.347 = fill 0.347. |
| extractor single line and casing `line_stroke(…, sr$alpha)` | agree | |
| extractor overlay `tick_overlay(…, alpha)` | agree | Mutation "drop `alpha`" is red. The mutations "drop the sub-symbol alpha" and "drop the tick colour alpha" are both **green**, so neither guard is tested. |
| extractor class fill and line `class_style()` | agree | |
| extractor class casing | dropped | The schema has no `casing_opacity`. No live instance: every casing in the template is at opacity 1. |
| extractor class polygon outline | not emitted | `class_style` records `outline_width` only, with no colour and no opacity. This predates the branch (main:238). |
| extractor markers (single and class) | none emitted | Consistent between the two. No live marker with symbol alpha < 1 or `layerOpacity` < 1. |
| extractor label `opacity` :610 | `textOpacity` only | `layerOpacity` is not folded in, and the textColor alpha is dropped. No live instance: 0 of 49 textColors have alpha < 255. Whether QGIS applies layer opacity to labels is unmeasured. |
| `gq_style` | pass-through | `opacities`, `outline_opacities` and simple `stroke` / `casing` / `overlay` objects as held |
| tmap simple polygon `col_alpha` :273 | agree | Red under mutation. `utm_zones` (fill_alpha 0, col_alpha 0.999) renders with 0 warnings. |
| tmap simple line :304, classified `tmap_alpha_args` | agree | |
| tmap legend `tmap_polygon_args` → `col_alpha` | agree | `legend_na_default` has `col_alpha = 1`. test-gq_tmap_legend: 126 pass. |
| mapgl polygon `mapgl_polygon()` | **DISAGREE, predates the branch** | MapLibre's `fill-opacity` also governs the outline, and `stroke$opacity` is never read. Live: `utm_zones` (fill 0, stroke 0.999), `orthophoto_tiles` and `terrain_mapping_project_boundaries` draw no outline in mapgl, while tmap now draws the utm_zones outline. `R/gq_mapgl_style.R` is not in the diff, and main had fill opacity 0 for utm_zones. Not raised as a finding. |
| QML writer single line / polygon / categorized | agree | Line opacity becomes symbol `alpha`. Polygon fill and outline opacities go into each colour's alpha with symbol alpha 1. The round trip through the round-3 extractor rule is consistent. |
| QML writer casing / overlay | warn | Lines 83-96 warn on each. |

### 4. Label translators: every field read

| Field | tmap | mapgl | Agree? |
|---|---|---|---|
| `field` / `expression` | `label_source()` | `label_source()` | agree |
| `size` (pt) | `/12` | `*96/72` | agree |
| `color` | `col` | `text_color` | agree |
| `opacity` | `col_alpha`; the halo stays at `halo.alpha = 1` | `text_opacity`, which MapLibre also applies to the halo | disagree on halo fade. Only live case is `crossings_pscis_assessment` at 0.997, which is immaterial. |
| `weight` / `style` | `fontface` | not read (documented) | by design |
| `placement` | along the line for line and curved | line for line, curved, perimeter and perimeter_curved | by design and documented. 0 perimeter placements are shipped. |
| `halo$width` | > 0 → `halo.width` in lines | non-NULL → px | agree in effect: width 0 draws nothing in either |
| `halo$color` | `%||% "#ffffff"` | `%||% "#ffffff"` when there is a width | agree. Mutation red for mapgl. 0 of 14 shipped halos lack a colour. |
| `offset_x` / `offset_y` | `xmod`, `-ymod` | `text_offset` | agree (the magnitude is an accepted tradeoff) |
| `font`, `merge_lines`, `min_feature_size`, `note` | not read | not read | agree (documented) |
| units behind `size` and `halo$width` | assumed pt and mm | assumed pt and mm | **neither the extractor nor the translators check them** (probe5). (**F3**) |
| tmap >= 4.3 check | `packageVersion >= "4.3"` | n/a | agree with DESCRIPTION and tmap NEWS ("# tmap 4.3 :: tm_text: halo…"). Mutation is green because it cannot be tested on 4.4.1. |

### 5. Doc claims

| Claim | Agree? | Evidence |
|---|---|---|
| CLAUDE.md:185-188 "folded into every opacity it emits, a polygon outline's and an overlay's included" | agree | Section 3: no emitted symbol opacity is unfolded |
| CLAUDE.md:187 "One reader, `symbol_read()`, decides for all three renderer parsers" | agree | The scope is the renderer parsers, and the colour scan is not one (F2) |
| CLAUDE.md:193 "A layer whose colour has an active data-defined expression carries a note" | **partly** | It misses the tick sub-symbol and over-claims on unmodelled layers (F2) |
| CLAUDE.md:194-196 "What the registry does not model … is named in the layer's note" | agree for multi-layer symbols | |
| CLAUDE.md:251-258 label translators, the tmap 4.3 halo | agree | |
| `gq_qgs_extract` roxygen :8-11 "(… symbol-layer pass order) is named in the layer's `note`" | **no** | Live on `roads_dra` and `trails` (F4) |
| `gq_qgs_extract` roxygen `@return` "a `note` where QGIS draws something the registry does not model" | **no** | Unhandled renderer types and pass order (F4) |
| `gq_qgs_extract` roxygen :22 "layer opacity folded into every opacity it emits" | ambiguous | The label `opacity` is not folded (section 3) |
| `color_data_defined` roxygen "as `symbol_read()` reads them" | **no** | symbol_read also reads the tick sub-symbol (F2) |
| `gq_style` roxygen casing and outline vectors | agree | |
| `gq_qgis_style` roxygen "overlay and casing (a warning names each)" | agree | |
| `gq_reg` roxygen sizes in pt/mm, offsets in ems | agree | Round 3's doc point is fixed |
| `gq_tmap_labels` / `gq_mapgl_labels` roxygen | agree | |

### 6. Derived artifacts (measured this round)

| Artifact | Result |
|---|---|
| `reg_qgis_restoration.json` | A fresh extract from rfp's template has the same md5 (`bf145cef…`) |
| `reg_main.json` | A rebuild via `reg_main_build()` has the same md5 (`5ce0b269…`) |
| `template_excerpt.qgs`, `bcfishpass_excerpt.qlr` | Regenerated byte-identical |

Tests: every file passed with 0 failures and 0 errors.

| File | Passes |
|---|---|
| extract | 125 |
| style | 54 |
| tmap_labels | 22 |
| mapgl_labels | 55 |
| qgis_style | 113 |
| tmap_style | 230 |
| reg | 74 |
| reg_build_currency | 5 |
| tmap_legend | 126 |
| gpkg_style_write | 33 |

### 7. Mutation table for round 3's guards

Each guard was deleted alone, and its own test file was run.

| Guard | Result |
|---|---|
| symbol_read enabled filter | red (1) |
| first layer counted only if modelled | red (2) |
| graduated reads the casing | red (4) |
| overlay gets the symbol and layer alpha | red (1) |
| overlay gets the sub-symbol alpha | **green** |
| overlay gets the tick colour alpha | **green** |
| outline gets the symbol and layer alpha | red (1) |
| outline gets the outline colour alpha | **green** |
| dd scan: enabled only | red (1) |
| dd scan: excludes `<source-symbol>` | **green** |
| tmap polygon `col_alpha` | red (1) |
| tmap version check | green (cannot be tested on 4.4.1) |
| mapgl white halo | red (1) |
| class overlay named as MarkerLine | **green** |

The green rows are untested guards, not defects. The code of each is correct on reading.

## Findings

- **[fragile] R/gq_qgs_extract.R:276 (`tick_overlay`).** `marks <- xml2::xml_find_all(marker_line, "./symbol/layer")` does not apply the enabled filter that `symbol_read()` applies to top-level layers.
  - A railway MarkerLine whose single tick marker is disabled (`enabled="0"`) still emits a full `overlay`, although QGIS draws no ticks. probe1 A: the disabled and enabled markers give identical overlays.
  - This is the round-2/round-3 "which layers count" rule one level down, inside the sub-symbol.
  - No live instance: 0 disabled sub-symbol layers in either rfp template.
  - Fix: `./symbol/layer[not(@enabled='0')]`.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[fragile] R/gq_qgs_extract.R:166-181 (`color_data_defined`).** The scan's predicate is "enabled top-level layer", which is neither the drawn set nor the modelled set.
  - (a) It skips the tick marker inside a MarkerLine, whose colour **is** the registry's `overlay$color`. An active expression there gives no note (probe1 B: FALSE).
  - (b) It flags an expression on a layer the registry does not model. The note then says QGIS draws the expression's colour "instead of these", but the registry's colours come from a different layer that has no expression (probe1 C: a FontMarker over a SimpleLine).
  - The roxygen claims it reads "as `symbol_read()` reads them". symbol_read's modelled set is `used` plus the tick marker.
  - All 36 shipped active expressions sit on single-layer SimpleLine symbols, so the shipped notes are right.
  - Fix: have `symbol_read()` return the nodes it modelled (the `used` layers plus the overlay's mark), and scan only those.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"; code-check.md "A proxy is not the property"

- **[fragile] R/gq_qgs_extract.R:598-626 (`parse_labels`).** `fontSize` and `bufferSize` are written without reading `fontSizeUnit` or `bufferSizeUnits`, yet both translators convert as points and millimetres.
  - probe5: a 13 Pixel or MapUnit label with a 1 Pixel or MapUnit halo becomes `text_size` 17.33 px and a 3.78 px halo, exactly like 13 pt and 1 mm.
  - The overlay path refuses non-MM units (`tick_overlay` :273, :283-284). The label path, the other place where this branch made units load-bearing, does not.
  - No live instance: all 49 text-styles are `Point` and all 21 buffers `MM` across both rfp templates.
  - Fix: record the size only for `Point`/`MM` (QGIS's defaults when the attribute is absent), else add a note.
  - **Rule:** code-check.md "A proxy is not the property"

- **[fragile, doc] R/gq_qgs_extract.R:8-11 and :27-29 (roxygen, regenerated into man/gq_qgs_extract.Rd).** The description says symbol-layer pass order "is named in the layer's `note`". `@return` promises a `note` "where QGIS draws something the registry does not model". Neither holds:
  - **Live:** `Roads - DRA` and `Trails` have `symbollevels="1"` with non-zero `pass`, and `reg_main.json`'s `roads_dra` has no note. CLAUDE.md:190-191 says pass order was declined, contradicting the roxygen.
  - probe4: `invertedPolygonRenderer`, `pointCluster` and `heatmapRenderer` fall through the renderer dispatch (:87-96) with only `type` and `source_layer`, no style and no note. `gq_qgis_style()` then errors "neither a fill nor a stroke colour", and tmap draws its default.
  - Fix: drop "symbol-layer pass order" from the roxygen sentence, as CLAUDE.md has it. Add an `else` arm that notes an unhandled renderer type, as the RuleRenderer arm does.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"; code-check.md "Documentation Staleness"

Outside the diff, not a finding: `mapgl_polygon()` never reads `stroke$opacity`, and MapLibre's `fill-opacity` governs the outline. So `utm_zones`, `orthophoto_tiles` and `terrain_mapping_project_boundaries` (fill 0) draw no outline in mapgl. This predates the branch: `R/gq_mapgl_style.R` is unchanged, and main already had fill opacity 0 for `utm_zones`.

/Users/airvine/Projects/repo/gq/planning/active/review-round4.md
