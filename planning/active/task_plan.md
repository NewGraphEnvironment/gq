# Task: Move 3: package face and check gate (batches 6, 7, 8) (#102)

**If we do it:** a new `R CMD check` warning fails the build, the README and intro vignette describe and demonstrate the package as it is, maps carry their tile credit, and every registry file gq ships is either read by something or marked as a record. **If we never do:** the check workflow stays pinned to errors only, the README lists shipped work as in flight, and published figures carry no basemap credit.

## Context

This is move 3 of `planning/backlog.md`, eight issues in three batches: one plan, one phase per batch, one PR.

- **Batch 6:** let `R CMD check` fail on a WARNING (#51) and fix the dead `00_pkg_src` branch in the vignette legend guard (#80).
- **Batch 7:** make the package's public face true. That means the README (#95), the intro vignette (#62) and tile credits (#58).
- **Batch 8:** settle what `data-raw/reg_build_main.R` reads and what proves `reg_main.json` is current (#85, #84, #11).

Every issue body was read and none has comments. The code was explored at `main` @ `7d0ce85`.

## Decided at the gate (the owner, 2026-11-09)

1. **Demo datasets: remove.** `crossing`, `lake`, `road`, `stream` and `watershed` came in with the first vignette (63c78f7, 2026-02-20). 533a53b rewrote that vignette onto real Bittner Creek data the same day, and nothing has used them since. Delete `data/{crossing,lake,road,stream,watershed}.rda` and `data-raw/demo_layers.R`, which can be recovered from git history at 63c78f7. NEWS marks this as breaking.
2. **README: rewrite to soul's `readme.md`.** That covers the README, DESCRIPTION `Title` and `Description`, and the GitHub About text. All unbuilt claims go: the PyQGIS extractor (`python/gq/` holds only `.gitkeep`), the leaflet and ggplot2 targets, and the roadmap.
3. **gq-intro: narrow to the watershed.** Crossings are filtered to `bittner_wsd` (12 of 95) and the exterior is dimmed. The title stays, and the bundled data is unchanged.
4. **Tile credit sits below the frame.** (Mechanism amended in Phase 2: `tm_pos_out()` fails with `meta.margins = 0` and shrinks the frame off its canvas otherwise, so the credit is drawn with grid in a strip under a map viewport; review A1.) A blended basemap credits both providers, de-duplicated and joined with `"; "` (agent's call, conventional).
5. **`reg_qgis_fishpassage.json`: delete it** (#85).
6. **`xref_layers.csv`: keep it by hand, and say what it names.** #84's premise compared it with the wrong artifact. Both rows name the database tables `data-raw/neexdzii_kwa.R` queried (`bcfishpass.crossings`, `bcfishpass.streams_salmon_vw`), not bucket objects. Document that, and add a structural test.
7. **Currency: a CI rebuild test plus a gated re-extract** (#11). There is no bot commit.

## Phase 1: Check gate (batch 6: #51, #80)

- [x] Replace the three non-ASCII string literals with `" - "`, matching `R/gq_groups.R`. They are at `R/gq_qgs_extract.R:75`, `:197` and `R/gq_reg.R:19`. Leave the em dashes in roxygen and comments alone.
- [x] Remove the five demo datasets and `data-raw/demo_layers.R` (decision 1). The breaking line goes in the PR body: `/gh-pr-merge` writes NEWS at release (review G8).
- [x] `tests/testthat/test-vignette_legend_coverage.R`: generate the `00_pkg_src/gq/vignettes` candidates from `c("..", "../..", "../../..")` and search them **first**, as `build_root()` in `test-build_hygiene.R` does. Have `vignette_source()` report which layout answered.
- [x] Add a reachability test. When a `00_pkg_src/gq` tree exists, the resolved path must be inside it and not `system.file("doc", ...)`. Restore the old `../00_pkg_src` path and show the test goes red under `R CMD check`.
- [x] `.github/workflows/R-CMD-check.yaml`: drop `error-on: '"error"'` and its comment.
- [x] `devtools::check()` reports 0 errors and 0 warnings. The `.claude` and `gq.Rproj` NOTEs are already handled: both are in `.Rbuildignore`.

## Phase 2: Tile credit (#58)

- [x] `gq_basemap_tiles()` (`R/gq_basemap_blend.R`): set `attr(x, "credit") <- maptiles::get_credit(provider)` on the returned raster, after projection, and document it under `@return`.
- [x] `gq_basemap_blend()`: carry the unique credits of `base` and `relief`, joined with `"; "`, onto its result (both the SpatRaster and the stars form).
- [x] Tests, with the fetch mocked: the credit attribute is present; a blend combines and de-duplicates; the failure path still returns `NULL`.
- [x] `gq-tmap-composition.Rmd`: render the credit below the frame.
- [x] Review fold-in: `@return` documents the strip pattern and that `st_as_stars()`/stars `st_crop` drop the attribute (G4, A2); `test-build_hygiene.R:112` comment no longer cites `error-on: "error"` (G3); the gq#80 test fails rather than skips under `testthat::is_checking()` (AC1).

## Phase 3: Re-compose gq-intro (#62)

- [x] Switch to `gq_reg_main()` and the `gq_tmap_style(reg, "x")` signature (mapgl keeps its layer signature, G5). Follow the composition pattern (B2): roads via `field = "road_type"`; streams and railway coloured from registry values and drawn by hand, since the data has no `feature_code` and the registry has no railway overlay. Delete `inst/examples/reg_demo.json`, read by nothing after this (G1; breaking line in the PR body). Drop the leaflet/ggplot2 claims from the prose (G2).
- [x] Filter crossings to `bittner_wsd` and dim the exterior, so the subject stays clear. (B1: done with s2 off and a `st_make_valid()` copy for the mask.)
- [x] Re-pull the six `bittner_*` datasets (owner, 2026-11-09, mid-run): `bittner_wsd` from `fwa_watershedatmeasure(blk, 0)` includes ~500 ha (9%) of Fraser/Nechako river corridor, one of the 12 "inside" crossings sits on the Fraser, and the strip widens the frame over downtown Prince George. Take the watershed from a measure just above the mouth in `data-raw/bittner_creek.R`. Needs the DB tunnel.
- [x] Build the legend with `gq_tmap_legend()`. Add a scale bar from `gq_scale_breaks()` and a keymap from `gq_tmap_keymap()` with `neexdzii_bc` as BC context. Keep the logo, give each element its own corner, and put the credit below the frame.
- [x] Size type for the published column width.
- [x] The mapgl section uses the same filtered data and registry styles.
- [x] Name the map chunk and extend the legend-coverage guard to it, with the minimum drawn count a per-vignette parameter (G6). Mechanical checks: the crossing count drawn, and no `#rrggbb` in the chunk beyond the named mask and AOI-outline exceptions (AC2).
- [x] Render both vignettes, then read each PNG against cartography self-review checks 1–13, including at its published width.

## Phase 4: README, DESCRIPTION and About (#95)

- [x] Rewrite `README.md` in `readme.md`'s order. It opens with what gq is, what it works on and the decision it informs. Then come a figure, a short example with its real output, Learn more, and License.
  - #95's three tasks are resolved inside this rewrite. The roadmap is replaced by a link to the open issues. The reference page carries every export, including `gq_form_types()` and `gq_scale_breaks()`, so the README needs no function table. Registry counts are dropped.
- [x] Draw the README figure from committed code: `data-raw/readme_figure.R` renders gq-intro and copies its `map-intro` figure to `man/figures/README-map.png`, so the figure cannot drift from the vignette (G10). It gets alt text and a caption, and is checked at its published width.
- [x] The rewrite already omits `reg_qgis_fishpassage.json` and describes `xref_layers.csv` as database tables (O2).
- [x] Bring DESCRIPTION `Title` and `Description` in line with the opening, then run `devtools::document()`. The About text is drafted here and set after merge (G9).
- [x] Run the mechanical checks: every function the README names is exported, and every link resolves (absolute URLs for files pkgdown does not publish).

## Phase 5: Registry build inputs (batch 8: #85, #84, #11)

- [x] Delete `inst/registry/reg_qgis_fishpassage.json` (#85). Remove its mentions in the README and in `CLAUDE.md` above the marker.
- [x] `xref_layers.csv` (#84): say in the `gq_style()` roxygen (`R/gq_style.R:16`) and in `CLAUDE.md` that `name_table` names the database table the bundled data was queried from.
  - Add a test that each row's key is a registry key and that its `class_field` differs from the registry's classification field. That difference is the only reason a row exists.
- [x] In ONE commit (O1): re-extract `reg_qgis_restoration.json` from rfp's `bcrestoration_mobile.qgs` at tag v0.93.0 (identical to the checkout; A4), naming the tag in the commit message and script header, never in the JSON (G7). Delete the bcfishobs correction block; rebuild `reg_main.json`; rewrite (not flip) the bcfishobs test in `test-composition_integrity.R` and its stale comment (G3). Prove it by semantic compare (AC3): same 48 keys, every layer identical once `note` is dropped except bcfishobs `source_layer`, notes differing only by the dash. The ACCESS correction stays (bcfishpass#13 open).
- [x] Then move the merge and the ACCESS correction into `R/utils_reg_build.R` (required: `data-raw` is build-ignored, A5), with one JSON writer the script and the tests share (G7). Fix the script header's stale name, `build_reg_main.R`.
- [x] Add a CI test that rebuilds in memory and compares **byte for byte** with the shipped `reg_main.json` (#11); its failure message names a jsonlite formatting change as a possible cause (A3). Restore-the-bug as a committed test: temp inputs with one `reg_custom.csv` value changed, expect a mismatch (AC4).
- [x] Add a restoration-currency test to `test-vendored_currency.R`, gated on `RFP_TEMPLATE_DIR` like its siblings: re-extract and compare.

## Phase 6: Docs and NEWS

- [x] Update `CLAUDE.md` above the marker: the registry sources list, `xref_layers.csv`, the rebuild test, the demo datasets, and the leaflet/ggplot2 and "GitHub Action (gq#11)" lines under Future (G2).
- [ ] The PR body carries the NEWS lines for `/gh-pr-merge`. Breaking: the demo datasets, `reg_demo.json` and `reg_qgis_fishpassage.json` are removed. New: tiles carry a credit attribute.
- [x] `devtools::check()` again at the end (AC5).

## Owed at the end (reported, done after merge)

- [ ] `/gh-pr-merge` ticks move 3 in `planning/backlog.md` and does the release bookkeeping (version bump, tag).
- [ ] Set the GitHub About text drafted in Phase 4, "One set of map styles for QGIS field projects, report figures and web maps." (`gh repo edit NewGraphEnvironment/gq --description`) (G9).
- [ ] Close #84 with the corrected premise (the database tables, not the bucket). Close #11 with a note that a test replaced the proposed Action and that its source file names are obsolete.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean (each commit, or once over the branch with `/code-check branch`)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved:

- **Check gate:** `devtools::check()` shows 0 warnings. The reachability test goes red against the old path under `R CMD check`.
- **Credit:** unit tests with a mocked fetch, plus the rendered vignettes showing the credit below the frame.
- **gq-intro:** a render, a read of the PNG against checks 1–13, and the legend guard covering its chunk.
- **README:** the export and link checks, and the figure read at its published width.
- **Rebuild:** the byte-compare test, red when a source changes without a rebuild. The re-extract diff is reviewed. The gated test runs green locally with `RFP_TEMPLATE_DIR` set.
- **Throughout:** `lintr` compared per file against `origin/main`, and `pkgdown::check_pkgdown()` after the export and data removals.
