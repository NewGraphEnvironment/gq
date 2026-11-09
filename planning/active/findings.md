# Findings: Move 3: package face and check gate (batches 6, 7, 8) (#102)

## Issue context

**If we do it:** a new `R CMD check` warning fails the build, the README and intro vignette describe and demonstrate the package as it is, maps carry their tile credit, and every registry file gq ships is either read by something or marked as a record. **If we never do:** the check workflow stays pinned to errors only, the README lists shipped work as in flight, and published figures carry no basemap credit.

Move 3 of `planning/backlog.md`, which holds the order, the measurements and each batch's section. Run `/planning-init` on this issue: one plan, one phase per batch, one PR. `/gh-pr-merge` ticks the move when it merges.

## Batch 6: Check gate

**Why here:** one `R CMD check` run proves both. Lands before batch 9, which rewrites one of the three string literals.

**Touches:** `R/gq_qgs_extract.R`, `R/gq_reg.R`, `R/data.R`, `.github/workflows/R-CMD-check.yaml`, `tests/testthat/test-vignette_legend_coverage.R`.

**Decided at the gate:** nothing.

| issue | title |
|---|---|
| #51 | R CMD check: clear the two pre-existing WARNINGs so CI can gate on them |
| #80 | Vignette legend guard resolves 00_pkg_src at the wrong depth under R CMD check |

## Batch 7: README and vignette

**Why here:** one pkgdown render and one figure review at published width.

**Touches:** `README.md`, `vignettes/gq-intro.Rmd`, `vignettes/gq-tmap-composition.Rmd`, `R/gq_basemap*.R`.

**Decided at the gate:** narrow the crossings to the AOI or widen the AOI and retitle; where a credit goes when the four corners are taken; what a blended basemap credits.

| issue | title |
|---|---|
| #95 | README: move finished roadmap items into the function overview |
| #62 | Re-compose gq-intro: no registry legend, no scale bar or keymap, and 87% of its crossings are outside the AOI |
| #58 | Basemap attribution is dropped: gq maps carry no tile credit |

## Batch 8: Registry build inputs

**Why here:** one script, `data-raw/reg_build_main.R`, and what it reads.

**Touches:** `data-raw/reg_build_main.R`, `inst/registry/reg_qgis_fishpassage.json`, `inst/registry/xref_layers.csv`, possibly a workflow.

**Decided at the gate:** delete, fold into the merge, or annotate the fish passage registry; generate the cross-reference from the registry or keep it by hand; a bot commit or a test that fails when the rebuild differs.

Also here, from move 1 (#100): `inst/registry/reg_qgis_restoration.json` is extracted from the template repo's `bcrestoration_mobile.qgs` by `data-raw/reg_extract_restoration.R`, and no currency guard covers it. #100's guard covers the vendored rosters, not registry inputs. Measured 2026-11-05 against the template repo's v0.93.0: 48 of 48 layers match, apart from the bcfishobs `source_layer` that `reg_build_main.R` corrects and float noise in `roads_dra` widths. Decide whether the rebuild test this batch adds re-extracts it too.

| issue | title |
|---|---|
| #11 | Auto-rebuild reg_main.json via GitHub Action |
| #84 | xref_layers.csv names a layer the bucket does not have |
| #85 | reg_qgis_fishpassage.json is an input to nothing and ships a superseded name |




## Exploration (2026-11-09, main @ 7d0ce85)

- Demo datasets `crossing`, `lake`, `road`, `stream`, `watershed`: no reader in R/, vignettes/, tests/, README. Added 63c78f7 (first vignette), orphaned by 533a53b the same day.
- `vignette_source()` under `R CMD check`: wd is `<pkg>.Rcheck/tests/testthat`, so `../00_pkg_src` never exists. Also `../../../vignettes` hits the repo source when gq.Rcheck sits inside the repo, the source-first hazard `build_root()` documents.
- maptiles 0.11.0 `get_credit()`: Esri.WorldGrayCanvas "Tiles © Esri - Esri, DeLorme, NAVTEQ"; Esri.WorldShadedRelief "Tiles © Esri - Source: Esri"; CartoDB.PositronNoLabels "© OpenStreetMap contributors © CARTO".
- README: `python/gq/` holds only `.gitkeep`; quick start calls `gq_mapgl_style(reg, "x")` (takes a layer) and adds `gq_tmap_style()` with `+`. DESCRIPTION and GitHub About repeat leaflet/ggplot2/PyQGIS claims.
- #84 premise: `xref_layers.csv` rows match the DB tables `data-raw/neexdzii_kwa.R` queried (`bcfishpass.crossings`, `bcfishpass.streams_salmon_vw`); the 404 came from probing the bucket, a different artifact. Registry source_layers for those keys are `whse_fish.pscis_assessment_svw` and `bcfishpass.streams_vw`.
- `reg_qgis_fishpassage.json`: 42 layers, no generator, no reader in R/, tests/, data-raw/.
- rfp checkout at v0.93.0-30-gf09e1d78 for the re-extract.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `tm_credits(position = tm_pos_out(...))` with `tm_layout(meta.margins = 0)`: tmap 4.2.0.9000 stops with `missing value where TRUE/FALSE needed` (`if (scaleS > 1.01)`). A non-zero bottom meta margin avoids it but shrinks the frame off the 7:9 canvas (basemap bands left/right) and the device-placed keymap spills past the frame. | Credit drawn with `grid::grid.text()` in a 0.25 in strip below a map viewport; keymap nested in that viewport; `fig.height = 9.25`. Possible upstream report on tmap, not filed. |

## R CMD check on 9ea4d8d (Phase 1), 2026-11-09

`devtools::check(args = "--no-manual")` from a detached worktree: 0 errors, 0 warnings, 0 notes. Tests under check: `[ FAIL 0 | WARN 1 | SKIP 8 | PASS 1268 ]`; the gq#80 tarball test is not among the 8 skips, so it ran and passed against `00_pkg_src`.

## Attributes through terra and stars (terra 1.9.46)

An attribute on a SpatRaster survives `r * 2`, `clamp()` and `project()` (only the first operand's), and is dropped by `stars::st_as_stars()`. So the blend sets its credit explicitly on the result.
