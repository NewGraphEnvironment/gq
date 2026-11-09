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
4. **Tile credit sits below the frame**, via `tm_credits(position = tm_pos_out(...))`. A blended basemap credits both providers, de-duplicated and joined with `"; "` (agent's call, conventional).
5. **`reg_qgis_fishpassage.json`: delete it** (#85).
6. **`xref_layers.csv`: keep it by hand, and say what it names.** #84's premise compared it with the wrong artifact. Both rows name the database tables `data-raw/neexdzii_kwa.R` queried (`bcfishpass.crossings`, `bcfishpass.streams_salmon_vw`), not bucket objects. Document that, and add a structural test.
7. **Currency: a CI rebuild test plus a gated re-extract** (#11). There is no bot commit.

## Phase 1: Check gate (batch 6: #51, #80)

- [x] Replace the three non-ASCII string literals with `" - "`, matching `R/gq_groups.R`. They are at `R/gq_qgs_extract.R:75`, `:197` and `R/gq_reg.R:19`. Leave the em dashes in roxygen and comments alone.
- [x] Remove the five demo datasets and `data-raw/demo_layers.R` (decision 1), with a NEWS entry.
- [x] `tests/testthat/test-vignette_legend_coverage.R`: generate the `00_pkg_src/gq/vignettes` candidates from `c("..", "../..", "../../..")` and search them **first**, as `build_root()` in `test-build_hygiene.R` does. Have `vignette_source()` report which layout answered.
- [x] Add a reachability test. When a `00_pkg_src/gq` tree exists, the resolved path must be inside it and not `system.file("doc", ...)`. Restore the old `../00_pkg_src` path and show the test goes red under `R CMD check`.
- [x] `.github/workflows/R-CMD-check.yaml`: drop `error-on: '"error"'` and its comment.
- [x] `devtools::check()` reports 0 errors and 0 warnings. The `.claude` and `gq.Rproj` NOTEs are already handled: both are in `.Rbuildignore`.

## Phase 2: Tile credit (#58)

- [x] `gq_basemap_tiles()` (`R/gq_basemap_blend.R`): set `attr(x, "credit") <- maptiles::get_credit(provider)` on the returned raster, after projection, and document it under `@return`.
- [x] `gq_basemap_blend()`: carry the unique credits of `base` and `relief`, joined with `"; "`, onto its result (both the SpatRaster and the stars form).
- [x] Tests, with the fetch mocked: the credit attribute is present; a blend combines and de-duplicates; the failure path still returns `NULL`.
- [x] `gq-tmap-composition.Rmd`: render the credit below the frame.

## Phase 3: Re-compose gq-intro (#62)

- [ ] Switch to `gq_reg_main()` and the `gq_tmap_style(reg, "x")` signature, replacing `reg_demo.json` and `reg$layers$x`. Every colour that has a registry style comes from the registry; the hand-typed road, stream and railway hex goes.
- [ ] Filter crossings to `bittner_wsd` and dim the exterior, so the subject stays clear.
- [ ] Build the legend with `gq_tmap_legend()`. Add a scale bar from `gq_scale_breaks()` and a keymap from `gq_tmap_keymap()` with `neexdzii_bc` as BC context. Keep the logo, give each element its own corner, and put the credit below the frame.
- [ ] Size type for the published column width.
- [ ] The mapgl section uses the same filtered data and registry styles.
- [ ] Name the map chunk and extend the legend-coverage guard to it.
- [ ] Render both vignettes, then read each PNG against cartography self-review checks 1–13, including at its published width.

## Phase 4: README, DESCRIPTION and About (#95)

- [ ] Rewrite `README.md` in `readme.md`'s order. It opens with what gq is, what it works on and the decision it informs. Then come a figure, a short example with its real output, Learn more, and License.
  - #95's three tasks are resolved inside this rewrite. The roadmap is replaced by a link to the open issues. The reference page carries every export, including `gq_form_types()` and `gq_scale_breaks()`, so the README needs no function table. Registry counts are dropped.
- [ ] Draw the README figure from committed code: `data-raw/readme_figure.R` writes `man/figures/README-map.png` from the gq-intro composition. It gets alt text and a caption, and is checked at its published width.
- [ ] Bring DESCRIPTION `Title` and `Description` in line with the opening, then run `devtools::document()`. Update the About text with `gh repo edit NewGraphEnvironment/gq --description`.
- [ ] Run the mechanical checks: every function the README names is exported, and every link resolves (absolute URLs for files pkgdown does not publish).

## Phase 5: Registry build inputs (batch 8: #85, #84, #11)

- [ ] Delete `inst/registry/reg_qgis_fishpassage.json` (#85). Remove its mentions in the README and in `CLAUDE.md` above the marker.
- [ ] `xref_layers.csv` (#84): say in the `gq_style()` roxygen (`R/gq_style.R:16`) and in `CLAUDE.md` that `name_table` names the database table the bundled data was queried from.
  - Add a test that each row's key is a registry key and that its `class_field` differs from the registry's classification field. That difference is the only reason a row exists.
- [ ] Move the merge and both corrections from `data-raw/reg_build_main.R` into an internal builder (`R/utils_reg_build.R`, following `R/utils_vendored.R`). The script then only calls it and writes the result.
  - Fix the script header's stale name, `build_reg_main.R`.
- [ ] Add a CI test that rebuilds into a tempfile and compares it **byte for byte** with the shipped `reg_main.json` (#11).
  - Restore-the-bug: change one value in `reg_custom.csv` without rebuilding, and the test goes red.
- [ ] Re-extract `reg_qgis_restoration.json` from the rfp checkout's `bcrestoration_mobile.qgs`, recording the rfp sha. Delete the bcfishobs correction block, which asks to be deleted once that happens.
  - Flip the pin in `test-composition_integrity.R`: the extract now carries the new name.
  - Rebuild `reg_main.json` and confirm the diff holds only the expected changes.
- [ ] Add a restoration-currency test to `test-vendored_currency.R`, gated on `RFP_TEMPLATE_DIR` like its siblings: re-extract and compare.

## Phase 6: Docs and NEWS

- [ ] Update `CLAUDE.md` above the marker: the registry sources list, `xref_layers.csv`, the rebuild test, and the demo datasets.
- [ ] Add NEWS entries. Breaking: the demo datasets and `reg_qgis_fishpassage.json` are removed. New: tiles carry a credit attribute.

## Owed at the end (reported, done after merge)

- [ ] `/gh-pr-merge` ticks move 3 in `planning/backlog.md` and does the release bookkeeping (version bump, tag).
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
