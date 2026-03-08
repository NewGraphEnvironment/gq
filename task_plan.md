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
- [ ] Document datasets in `R/data.R` (roxygen)
- [ ] Run `devtools::document()` to generate `.Rd` files
- [ ] Commit: data generation script, data files, documentation

### Phase 2: Vignette draft `status:not_started`
- [ ] Draft `vignettes/gq-tmap-composition.Rmd` (already written, needs render test)
- [ ] Render vignette, check output
- [ ] Fix any tmap issues (use fork at `~/Projects/repo/tmap` if needed)
- [ ] Commit: vignette

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
