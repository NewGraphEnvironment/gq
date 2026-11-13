# Task: Move 4: extractor fidelity and labels (batches 9, 10) (#103)

**If we do it:** the registry carries each label's field and weight, overlays and layer opacity as QGIS draws them, and a map can take its labels from the registry. **If we never do:** 0 of 25 labelled layers carry a label field, the railway keeps drawing as a plain black line, and every map hard-codes its `tm_text()` settings.

## Context

Move 4 of `planning/backlog.md`. `gq_qgs_extract()` drops or misreads what the template draws:

- 0 of 25 labelled layers in `reg_main.json` carry a label field.
- Label weight is never set. The extractor reads `fontBold`, which appears 0 times in the template. QGIS writes `fontWeight` (here 50, 75 and 87 on Qt5's scale).
- `railway` carries only the note `3 symbol layers`.
- Layer opacity is never read: `roads_ften` draws at 0.7 in QGIS and at 1 through gq.
- `streams_salmon`/`_st`/`_bt` colour through a data-defined `CASE` the registry knows nothing about.

Batch 10 adds the label translators, which need batch 9's label field.

Measured 2026-11-12 against rfp `origin/main` (v0.94.0+3). The template is byte-identical to v0.93.0, the last extract, so every change to `reg_qgis_restoration.json` comes from the extractor.

- 53 vector layers; 48 registry keys.
- 26 layers with `labelsEnabled="1"`. 4 of them have no settings, 19 use simple labelling, 3 use rule-based labelling.
- Of the 25 `fieldName` values, 10 are QGIS expressions.
- 10 single-symbol layers have more than one top-level symbol layer:
  - two-line casing: `moti_major_structures`
  - line plus MarkerLine ticks: `railway`
  - pattern fills: `wetland`, `fire_historical_burn`, `pipeline_permit`
  - outline-only fill stacks: `municipalities`
  - stacked markers: 4 point layers
- The current count is also wrong. `.//layer` counts nested sub-symbol layers, so railway reads 3 when it has 2.
- The test fixture `mini_project.qgs` writes the label field as an `<Option name="fieldName">` and uses `fontBold`. Neither is QGIS's real shape, which is why the test passes on the bug.
- The streams' data-defined `CASE` has empty `IN ()` lists in every branch. What QGIS actually draws is unmeasured.
- `bcfishpass_30k.qlr` (upstream, last edited 2024-03) already parses with the current extractor: 49 layers, 5 rule-based.

## Decided at the gate (owner, 2026-11-12)

1. **Label field uses two keys.** `label.field` holds a plain column only. `label.expression` holds the raw QGIS expression otherwise. The translators refuse an expression unless the caller passes `field =`.
2. **#24 goes into the registry and `gq_style()` only.** The extractor writes:
   - `casing` `{color, width}` when a wider SimpleLine sits under a narrower one, with `stroke` = the core (the same convention as the categorized `casing_color`/`casing_width`);
   - `overlay` `{color, width, dash}` for railway's line-marker ticks, written as a wide dashed line.

   `gq_style()` surfaces `casing` and the per-class `casing_colors`/`casing_widths`. Drawing them in tmap and mapgl goes to a new issue. Ticks can draw only in mapgl: a tmap/grid dash cannot be thinner than its line.
3. **#23 closes with a test.** A small `.qlr` fixture pins that the format parses, and the roxygen mentions `.qlr`. No `reg_qgis_bcfishpass.json`.
4. **The label hints are carried.** `label.placement`, `label.merge_lines` and `label.min_feature_size` (mm). The translators use `placement`. The other two are documented as the caller's data prep.

Recommended, and taken unless you object at approval:
- **#38 cap/join and pass order are declined.** tmap cannot draw cap or join, and nothing consumes pass order. The QML corpus carries all three losslessly. The registry instead documents that casing draws beneath its core, and beneath every core where QGIS uses symbol levels (Roads - DRA's pass 0/1; MoTi's two layers are both pass 0) (review #13).
- **Layer opacity is folded into the emitted opacities** rather than stored as a separate key, so every consumer gets it with no change.

## Phase 1: Extractor fidelity (batch 9: #6, #24, #38, #23)

- [x] Move `mini_project.qgs`'s label (both copies) to QGIS's real shape (`fieldName` on `<text-style>`, `fontWeight`). Cut `tests/testthat/fixtures/template_excerpt.qgs` (11 layers) and `bcfishpass_excerpt.qlr` (2 layers) from the real files with `data-raw/fixture_extract_template.R`. Write failing tests first. (Plan review #9.)
- [x] `parse_labels()`:
  - `field` or `expression`, chosen by `isExpression`, trimmed;
  - `weight = "bold"` when `fontWeight` ≥ 63 on Qt5's scale (≤ 99) or ≥ 600 on Qt6's, keeping the `fontBold` fallback;
  - `placement` as a word (codes 0-8; `line` on a polygon is `perimeter`; an unknown code is omitted) (review #6);
  - `opacity` from `textOpacity` when below 1 (review #8);
  - `merge_lines` and `min_feature_size` only when set;
  - rule-based labelling takes the first rule's settings and records `label$note` naming the rule count when there is more than one.
- [x] Layer opacity: read `<layerOpacity>` and multiply it into `fill`/`stroke`/per-class `opacity` in the single, categorized and graduated parsers. Opacity is still recorded only below 1.
- [x] `parse_single_symbol()`:
  - count top-level symbol layers only (`./layer`);
  - two SimpleLines with the lower one wider become `casing` + `stroke` = core;
  - a SimpleLine plus a MarkerLine of `line` markers becomes `overlay` `{color, width = marker size, dash = "<outline width>;<interval − outline width>"}`;
  - anything else keeps a `note` that names what is not modelled (pattern fill, stacked markers, outline-only fill) and points at `gq_style_qml()`.
- [x] Data-defined colour: when a symbol layer has an active `fillColor`/`outlineColor` expression, set the layer `note` to say the renderer's colours may not be what QGIS draws.
- [x] Measure what QGIS draws for `streams_salmon` with its `IN ()` expression, using rfp's QGIS container. File an rfp issue with the result.
- [x] `gq_style()` passes `casing` and `label` through, plus per-class `casing_colors`/`casing_widths` and `outline_colors`/`outline_widths`/`outline_opacities` (#31's remainder), named by class key (as #55 requires). `radii`/`shapes` in `gq_tmap_classes()` declined: no consumer. Add tests. (Review #3, #4.)
- [x] Categorized casing: top-level layers only, and only when the lower line is wider (review #7).
- [x] `.qlr`: add a 2-layer fixture cut from `bcfishpass_30k.qlr` and a test; read a PostgreSQL `table="s"."t"` datasource as `source_layer`; update the roxygen. (Review #2.)
- [x] Re-extract `reg_qgis_restoration.json` from the rfp checkout (`RFP_TEMPLATE`), rebuild `reg_main.json`, and update the provenance comment in `data-raw/reg_extract_restoration.R`.
- [x] Assert on the rebuilt registry:
  - 22 labelled layers in `reg_qgis_restoration.json` (reg_main's other 3 are CSV: dam, town, planting_site);
  - every template label has `field` or `expression`: 14 field, 8 expression (review #1, #14);
  - `source_layer` unchanged for every template layer (review #2);
  - `railway` has an `overlay`;
  - `moti_major_structures` has a `casing`;
  - `roads_ften` classes have opacity 0.7.
- [x] Update CLAUDE.md's schema example: railway's real overlay, `casing`, the label keys, and the declined #38 items.

## Phase 2: Label translators (batch 10: #7)

- [ ] `R/gq_tmap_labels.R`: `gq_tmap_labels(layer_or_reg, name = NULL, field = NULL)`. It returns `do.call(tm_text, ...)` args:
  - `text`, `size`, `col`, `fontface` (plain/bold/italic/bold.italic);
  - `options = opt_tm_text(along_lines = placement == "line", shadow = <halo present>, remove_overlap = TRUE)`.

  CSV `offset_x`/`offset_y` → `xmod`/`ymod`; `label.opacity` → `col_alpha`. It errors on an expression with no `field`, on a label with neither `field` nor `expression` (the CSV labels: pass `field =`), and on a layer with no label. Measure the pt-to-tmap `size` constant against a rendered PNG rather than guessing it.
- [ ] `R/gq_mapgl_labels.R`: `gq_mapgl_labels(layer, field = NULL)`. It returns `list(layout, paint)` for `add_symbol_layer()`:
  - `text-field` as a `get` expression;
  - `text-size` in px (pt × 96/72);
  - `symbol-placement = "line"` for line placement;
  - `text-color`, `text-halo-color` and `text-halo-width`, converted from mm to px after checking QGIS's `bufferSizeUnits`.

  Font family and italics are left to the basemap's glyphs, and the roxygen says so.
- [ ] Tests for both, with runnable `@examples` on `reg_main` layers:
  - a plain field (`lake`);
  - a line placement (`stream_labels`);
  - an expression refused and then accepted with `field =` (`crossings_pscis_assessment`);
  - a custom-CSV label (no `field` key);
  - `merge_lines`/`min_feature_size` documented as the caller's job.
- [ ] `_pkgdown.yml` reference entries; `pkgdown::check_pkgdown()`.
- [ ] Vignettes: replace the hard-coded `tm_text()` settings in `gq-intro.Rmd` and `gq-tmap-composition.Rmd` with `gq_tmap_labels()`, and correct the composition vignette's railway prose (a black line with ticks, now in the registry as `overlay`) (review #15). Render both and read the PNGs: labels are along the lines, the halo shows, and the size matches the old maps.
- [ ] NEWS entry; CLAUDE.md lists both exports.

## Owed at the end (reported, done after merge)

- [ ] File a gq issue: draw `casing` and `overlay` in tmap and mapgl (#24's remainder, with the tmap dash limit; MapLibre dasharray is in line-width units and needs butt caps).
- [ ] File a gq issue: a `label_field` column in `reg_custom.csv` for dam, town and planting_site, with source columns measured (review #1).
- [ ] Close #23 with the measurements (done by the merge's `Fixes`, with the comment in the PR body).
- [x] rfp issue on the streams `IN ()` expression: rfp#430

## Validation

- [ ] Tests pass (`devtools::test()`; the gated currency tests with `RFP_TEMPLATE_DIR`/`RFP_LOOKUPS_DIR` set to the rfp checkout)
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] `lintr::lint_package()` with no new lints compared with `origin/main`; `devtools::check()` clean
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:
- Restore the bug for each new extractor test (revert `parse_labels()`'s field read, the `./layer` count and the opacity fold) and watch it go red.
- Fixtures are cut from real template XML, so they can reach the failure mode.
- The rebuilt-registry assertions above pin the measured counts.
- Vignette PNGs are read at their published width.

Branch: `103-extractor-fidelity-and-labels` (hand-named; the generated slug truncates mid-word). One PR closes #6, #24, #38, #23, #7 and #103. SRED: per machine-local memory at PR time.

