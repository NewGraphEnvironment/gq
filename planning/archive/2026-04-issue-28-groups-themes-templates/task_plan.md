# Task Plan — Issue #28: Registry Groups, Themes, Templates

## Goal

Extend gq with three CSVs (`groups.csv`, `templates.csv`, `themes.csv`) that model how layers compose into QGIS projects. Reader functions parse CSVs; query functions join CSV data with the existing style registry. Styles stay in JSON, composition in CSV.

## Phase 1: groups.csv and group functions
- [x] Create `inst/registry/groups.csv` from issue draft, reconciling with actual registry keys
- [x] Create `R/gq_groups.R` with `gq_groups()` and `gq_group_layers()` reader/query functions
- [x] Create `tests/testthat/test-gq_groups.R` with tests
- [x] Run `devtools::document()` and `devtools::test()`

## Phase 2: templates.csv and template functions
- [x] Create `inst/registry/templates.csv` from issue draft
- [x] Add `gq_templates()`, `gq_template_groups()`, `gq_template_layers()` to `R/gq_groups.R`
- [x] Add template tests to test file
- [x] Verify `gq_template_layers("bcfishpass_mobile")` returns expected data.frame (52 layers, 8 groups)

## Phase 3: themes.csv and theme functions
- [x] Create `inst/registry/themes.csv` from issue draft
- [x] Add `gq_themes()` and `gq_theme_groups()` to `R/gq_groups.R`
- [x] Add theme tests

## Phase 4: Validation and cleanup
- [x] All tests pass (215 pass, 0 fail)
- [x] `lintr::lint_package()` clean on new files (pre-existing vignette lints untouched)
- [x] `devtools::check()` — 0 errors, 2 pre-existing warnings (non-ASCII in other files, undocumented datasets), no new issues
- [x] No new Imports needed (uses only base R + utils)
