# Task: Move 2: styles reach the map (batches 3, 4, 5) (#101)

**If we do it:** a classified layer draws at the opacity the registry gives it, a hand-written CSV can carry a dashed classified line, and the floodplain and habitat comparison styles come from one registry entry. **If we never do:** every BEC zone keeps drawing at full opacity, and each map of rule comparisons, expected use or tree change types its own colours.

Branch `101-move-2-styles-reach-the-map-batches-3-4` off origin/main @ 87f7677. Plan approved 2026-11-05.

## Context

Registry symbology is being lost between the registry and the map: `gq_style()` reads no
per-class opacity, so all 11 `bec_zone` classes (fill_opacity 0.25) draw opaque; `labels`
is positional beside a named `values`, so indexing by class key returns `NA`; and
`gq_reg_custom()` writes `outline_width` and no `dash` for a classified line, and errors on
a CSV missing any optional column. Batch 5 then registers the floodplain/habitat
comparison styles and the land-cover palette, which depend on per-class opacity. One
branch `101-move-2-styles-reach-the-map-batches-3-4`, one phase per batch, one PR.

## Decided at the gate (owner, 2026-11-05)

- **#55:** name `labels` by class key in `gq_style()` and `gq_tmap_classes()`. tmap still
  reads them by position, so maps are unchanged.
- **#67 palette:** drift's IO LULC table (`drift/inst/lulc_classes/io_lulc_v02.csv`), not
  the Esri Living Atlas hex in #67's body, so a drift map and a gq map of the same classes
  agree. #67's body is edited to say so.
- **#98 class keys:** short codes, readable text in `class_label`. Rule comparison
  `both`/`first`/`second`/`outside` on `rule_class`; expected use `0-0.2` … `0.8-1` on
  `grade_class` (as knowledge's `compare_map.R` already writes them); flood factor
  `ff02`/`ff04`/`ff06` on `scenario_id` (flooded's `fl_scenarios()`). Other column names
  go through `gq_style(field = )`.
- **Tree loss/gain hex:** picked by me on the blended topo + relief basemap beside
  `#d95f02` and `#f2a93b`, with the comparison PNG committed for review in the PR.

Decided by me (conventional defaults, reject the plan to change):
- New layer keys: `habitat_rule_comparison`, `habitat_expected_use`,
  `floodplain_flood_factor`, `tree_cover_change` (field `tree_change`, classes
  `loss`/`gain`), `landcover_change_from` (field `from_class`), `landcover_change_to`
  (field `to_class`); land-cover class keys are drift's class names (`Water`,
  `Flooded Vegetation`, `Snow/Ice` …), drift's `No Data` excluded. `habitat_rule_comparison` and `habitat_expected_use`
  are typed `line` (knowledge draws them with `tm_lines` on segments; corrected by the
  plan review from a first draft of "all polygon"); the other four
  `polygon`. Raster consumers take values/labels/opacities from `gq_tmap_classes()`,
  which is type-agnostic. Land-cover classes carry no opacity: no source gives one.
- `tree_cover_change` **is** #67's "Trees → *" third style; #67 and #98 both say so.
- **#98's stream label is already shipped**: `stream_labels` in `reg_main.json` is italic
  `#1f78b4`, white halo 0.3, the same as `lake`. No row added; #98 closes saying so.
- **#67 QML is not written here.** gq vendors QML and does not author it, so the QML goes
  to the upstream style store as an issue there; gq's public text names no private issue.
- **#31's remainder** (casing, outline, point radii/shapes in `gq_tmap_classes()`): #31
  closes on opacity; surfacing casing through `gq_style()` is added to #24's body, which
  extracts casing (batch 9).
- **CSV `dash` column:** accepts QGIS `line_style` names (`solid`, `no`, `dash`, `dot`,
  `dash dot`, `dash dot dot`) or a raw customdash pattern (`^[0-9.]+([; ][0-9.]+)+$`);
  anything else errors naming the layer and value. Read for classified **and** simple
  strokes (`csv_stroke()`), since the extractor writes `stroke$dash` too.
- **Classified line columns in the CSV:** per class `color` ← `stroke_color`, falling back
  to `fill_color` (what #42's probe used); `width` ← `stroke_width`; `opacity` ←
  `stroke_opacity`, falling back to `fill_opacity`; `dash` ← `dash`. Polygon classes keep
  `color`/`opacity`/`outline_*`, which is what the extractor writes for them.
- Per-class opacity `NA` means **1**, not unknown: the extractor omits `opacity` when alpha
  is 1, so a partial vector is real. Uniform opacity is emitted as a scalar
  `fill_alpha`/`col_alpha`; varied opacity is mapped per class like `lwd`.

## Phase 1: Translator opacity and labels (#71, #31, #55)

- [x] Failing tests first: `gq_style()` returns `classification$opacities` named by class
  key; `labels` named by class key; `gq_tmap_classes()` returns `opacities`; render test
  reads `gp$alpha` off the drawn `pathgrob` for `bec_zone` = 0.25 (helper-tmap_render.R
  `drawn_gp(m, "alpha", grob_class = "pathgrob")`, one feature at a time); a line layer
  with varied per-class opacity renders each class at its own `col_alpha`
- [x] `R/gq_style.R`: extract per-class `opacity`, drop `__empty__` like the others, name
  `labels` (remove `unname()`), roxygen `@return` updated
- [x] `R/gq_tmap_style.R`: `gq_tmap_classes()` returns `opacities`; `tmap_classified()`
  maps polygon/point → `fill_alpha`, line → `col_alpha` via `tmap_scale_axis()` keyed on
  `names(cls$values)`, scalar when uniform, NA → 1; roxygen updated
- [x] `R/gq_tmap_legend.R`: classified rows carry `fill_alpha` / `col_alpha` per class so
  the swatch matches the map (`legend_na_default` already has both)
- [x] Update the 4 assertions #55 names (`test-gq_style.R:39`, `:115`,
  `test-gq_tmap_style.R:105`, `:150`) to named vectors
- [x] Restore the bug (drop the opacity extraction) and watch the render test go red
- [x] `devtools::document()`; commit `Fixes #71`, `Fixes #31`, `Fixes #55`; edit #24's body
  to carry the casing/outline surfacing half of #31

## Phase 2: Custom CSV reader (#42, #75)

- [x] Confirm `source("data-raw/reg_build_main.R")` on the branch tip runs and reproduces
  `reg_main.json` byte for byte (moved here from Phase 3 by the plan review: this phase
  rebuilds first)
- [x] Failing tests first: a CSV of only `layer_key, type, source_layer, class_field,
  class_value, fill_color` reads without error (#75); a classified line from CSV yields
  non-NULL `widths` and `dashes` from `gq_tmap_classes()`; key-set test comparing a
  CSV-authored classified line class against an extracted one (`roads_dra`) so the two
  paths cannot drift; an invalid `dash` value errors naming layer and value
- [x] `R/gq_reg.R`: after `read.csv()`, add every absent optional column as `NA` (one
  `cols_optional` vector, also used by the numeric coercion list); classified branch emits
  `color`/`width`/`opacity`/`dash`/`label` for `type == "line"`; `dash` validated and read
  in `csv_stroke()` too
- [x] `@param path` roxygen: `layer_key` and `type` required, every other column optional
  and treated as absent; `dash` documented with its accepted spellings
- [x] Add an empty `dash` column to `inst/registry/reg_custom.csv` (after
  `stroke_opacity`); rebuild `reg_main.json` and confirm the diff is empty
- [x] Restore the bug and watch the minimal-CSV test go red; commit `Fixes #42`,
  `Fixes #75`

## Phase 3: Register styles (#98, #67)

- [x] Pick tree loss (pink) and gain (orange): render candidates as swatches on the blended
  basemap (`gq_basemap_tiles()` + `gq_basemap_blend()`) beside `#d95f02` (also the website link
  map's crossing orange), `#f2a93b`, drift's Crops `#e49635` and the other #98 classes; choose by CIEDE2000 distance from the existing oranges plus a look;
  script and PNG under `planning/active/` (archived with the PWF)
- [x] Rows in `reg_custom.csv`: `habitat_rule_comparison` (4), `habitat_expected_use` (5),
  `floodplain_flood_factor` (3), `tree_cover_change` (2), `landcover_change_from` (9),
  `landcover_change_to` (9), colours and opacities from #98's table and drift's palette,
  `note` naming each source
- [x] Rebuild `reg_main.json`; data test asserts each new layer's classes, colours and
  per-class opacities, and that `landcover_change_*` colours equal drift's table as
  committed here (a copied value, so the test names the drift file and commit it came from)
- [x] These layers are in no template, so they take no `groups.csv` row: pin them as a
  named registry-only set in `test-gq_groups.R` ("all registry keys appear in
  groups.csv"), each with its reason, so an unplaced layer still fails (plan review
  blocker); run `test-composition_integrity.R` and `test-reg_labels.R`
- [x] File a gq follow-up: `gq_mapgl_classes()` drops per-class opacity (plan review)
- [x] Edit #67's body (drift palette, `tree_cover_change` is its third style, QML upstream)
  and #98's (keys, tree hex, stream label already shipped); file the QML issue in the
  upstream style store
- [x] Commit `Fixes #98`, `Fixes #67`

## Phase 4: Docs and wrap

- [x] `CLAUDE.md` / README: drop the volatile layer count ("57 layers") rather than correct it;
  document per-class opacity and the CSV `dash` column where the translators are described
- [x] `lintr` per-file diff against an `origin/main` worktree; `pkgdown::check_pkgdown()`

## Owed at the end (reported, done after merge)

- [ ] `/gh-pr-merge` ticks move 2 and batches 3–5 in `planning/backlog.md`
- [ ] The QML for #67's three styles lands in the upstream style store (issue filed there 2026-11-05) and is vendored by `data-raw/styles_vendor.R`

## Validation

- [x] Tests pass (`devtools::test()`, failures and errors both counted)
- [x] `/code-check branch` clean
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion

Verification: each fix lands with a test that fails on `main` (shown by restoring the bug);
`bec_zone` opacity is read off the rendered grob, not the args list; `reg_main.json`
rebuild is shown reproducible before rows are added, so its diff is only the new layers;
the tree-hex choice is a committed PNG reviewed in the PR.
