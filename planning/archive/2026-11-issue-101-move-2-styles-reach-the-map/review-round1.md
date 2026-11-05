# Review round 1: branch 101 (git diff 87f7677...HEAD)

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms` (table rows skipped). Did not read the other 23 headings (Rules that stand alone, Security, Spreadsheets and PDFs). Their index lines name nothing this diff uses.
- **code-check-r.md**, read by heading: "`$` on a list partial-matches, so a longer sibling key answers for a missing one"; "CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests"; "`data.frame()` recycles a scalar against a zero-length column"; "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared"; "`vapply(..., USE.NAMES = FALSE)` strips ALL dimnames, row names included"; "`[[` on a named ATOMIC vector with an absent key is an error, not `NULL`"; "Tests that silently do not run"; "Cross-function consistency for label/string normalization". That is 8 read and 109 not read.
- **code-check-shell.md**: none read (0 of 70). The diff adds no shell.
- **code-check-spatial.md**: none read (0 of 94). The diff calls no terra, sf, GDAL or bcdata code.

What I checked and found sound, so the next round need not repeat it:
- tmap 4.4.1 `tmapScaleCategorical` matches **named** labels by name against the levels (`labs[nms2] <- labels[nms2]`). So the named `labels` are safe, and the comment "tmap reads labels by position" is only imprecise.
- `tmap_options()$value.na` is 1 for both `fill_alpha` and `col_alpha`. A data value missing from the registry therefore still draws opaque under the mapped alpha scale.
- The new CSV rows: every row has 25 fields. `gq_reg_custom()` of the shipped CSV reproduces the `reg_main.json` entries exactly (`identical()` on `habitat_rule_comparison`, `all.equal()` on `bec_zone`).
- Every class key in `reg_main.json` (`casing_*`, `color`, `dash`, `label`, `opacity`, `outline_*`, `radius`, `shape`, `width`) was checked: none prefix-matches another, so `x$opacity` cannot partial-match. Filling absent CSV columns also removes the old `$.data.frame` partial-match risk.
- Org consumers that read `labels` (wet `readme_figure.R` and `short-record-flow.Rmd`, fresh `fwa-network-query.Rmd`) either index by position or apply `setNames()` themselves. Neither is broken by the names.
- Org custom CSVs (wet, drift, the fish_passage reporting repos) carry classified lines through `fill_color` only. The new `stroke_color`-then-`fill_color` fallback keeps them unchanged.

## Findings

- **[severity: fragile]** R/gq_reg.R:153-156 (the `!is_line &&` shared-stroke guard). The comment claims a classified line's shared `stroke` is "a second colour that nothing reads". That is false. `gq_mapgl_style()` → `mapgl_line()` (R/gq_mapgl_style.R:67-75) reads `layer$stroke` and emits `line-color`, `line-width`, `line-opacity` and `line-dasharray`. Before this branch, a caller's CSV classified line with `stroke_width` gave mapgl a `line-width`. Now `gq_mapgl_style()` returns an empty paint list for that layer, and MapLibre falls back to its 1 px default with no message. No shipped row and no org consumer CSV found hits this today. The new comparison lines carry no `stroke_width`, and the consumer classified lines use `fill_color` only. It is still a silent regression on the documented caller-CSV path, and the comment's justification is what hides it. Either keep a shared stroke for lines built from the first row's width and opacity, or correct the comment and note the mapgl loss beside gq#107.
  - **Rule:** none

- **[severity: fragile]** tests/testthat/test-gq_reg.R:686-703 ("CSV and extractor write a classified line in one vocabulary (#42)"). The "extracted" reference comes from every classified line in `gq_reg_main()`. `reg_main.json` now contains two classified lines written by the CSV route itself (`habitat_rule_comparison`, `habitat_expected_use`), so after a rebuild the reference partly is the CSV writer's own output. I confirmed this in a detached worktree: renaming `cls$opacity` to `cls$line_opacity` in `csv_line_class()` and re-running `data-raw/reg_build_main.R` left this test **green**. The test's own comment says "a rename on either side fails". Only the neighbouring test "a classified line from CSV keeps per-class width and dash" went red, through `cls$opacities`. The hard-coded backstop covers `color`, `width` and `dash` but not `opacity`. Build `extracted` from `gq_reg_read("inst/registry/reg_qgis_restoration.json")` (the extractor's output alone), or drop the layers whose keys appear in `reg_custom.csv`.
  - **Rule:** code-check.md "Verification that reads its own output"
