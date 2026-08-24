# Task: tmap composition helpers and vignette (gq#17)

**Branch:** `tmap-composition`
**Split from:** gq#14
**PR target:** `main`
**SRED:** Relates to NewGraphEnvironment/sred-2025-2026#13

## Goal

Add tmap map composition helpers and a vignette demonstrating full map
composition using registry styles on Neexdzii Kwa (Upper Bulkley) data.

## Phases

### Phase 1: Data and documentation `status:complete`
- [x] Generate Neexdzii Kwa spatial data via fresh (`data-raw/neexdzii_kwa.R`)
- [x] Save as package data (`data/*.rda`)
- [x] Document datasets in `R/data.R` (roxygen)
- [x] Run `devtools::document()` to generate `.Rd` files
- [x] Commit: data generation script, data files, documentation (c89a2d8)

### Phase 2: Vignette draft `status:complete`
- [x] Draft `vignettes/gq-tmap-composition.Rmd`
- [x] Render vignette, check output — renders clean
- [x] Fix Z/M dimension issue (GEOS compat) — fixed at data source
- [x] Fix `reg$layers$stream` → `streams_all` classification lookup
- [x] All colors from registry — no hardcoded hex except white overlay
- [x] Visual check: map fills frame, four-corner rule, keymap works
- [ ] Width scaling issue (gq#16) — manual `* 2` multiplier for now
- [x] Commit: vignette (8cd070a)

### Phase 3: Composition helper functions `status:not_started`
- [ ] `gq_tmap_basemap()` — maptiles provider + alpha blending
- [ ] `gq_tmap_legend()` — position, sizing, background defaults
- [ ] Tests for helpers
- [ ] Update vignette to use helpers
- [ ] Commit: functions, tests, vignette update

### Phase 4: Polish and PR `status:not_started`
- [ ] `devtools::test()` passes
- [ ] `devtools::check()` clean
- [ ] `lintr::lint_package()` clean
- [ ] Push branch, open PR

## Key decisions

- Data: Neexdzii Kwa subbasin, Johnny David Creek to Richfield Creek on Bulkley
  mainstem (BLK 360873822, DRM 214900–217800). ~212 km², 1074 streams, 42 lakes.
- tmap fork at `~/Projects/repo/tmap` available for fixing upstream issues.
  Enable issues on fork, branch, fix, potentially PR upstream.
- Helper functions return argument lists for `do.call()` pattern (consistent
  with existing `gq_tmap_style()`).

## Errors encountered

| Error | Attempt | Resolution |
|-------|---------|------------|
| (none yet) | | |
