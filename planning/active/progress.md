# Progress — Re-extract the theme roster (#77)

## Session 2026-08-30

- Plan-mode exploration — verified the issue's claims independently against
  `rfp` v0.47.0 templates before planning (232/9, 27 flips, `esri_world_topo`
  stays off, no stubs remain, `Land Tenure` restoration-only 26/22)
- Explore-agent sweep found the full staleness surface: 1 breaking assertion,
  4 prose locations, 2 generated `.Rd` files
- Two deviations from the issue's proposed diff approved by user:
  split the test in two, and widen the stub guard to all 9 template-theme pairs
  so `Land Tenure` is covered
- Created branch `77-re-extract-the-theme-roster-high-detail` off main
- Scaffolded PWF baseline with approved phases
- Next: Phase 1 — re-extract the roster

### Phase 1 — roster re-extracted

- `RFP_TEMPLATE_DIR=~/Projects/repo/rfp/inst/templates Rscript data-raw/reg_extract_themes.R`
- `themes.csv built: 232 rows, 9 template-theme pairs`; diff is 27 insertions /
  27 deletions in `inst/registry/themes.csv` only
- Verified the diff contains nothing else: 0 changed lines outside the expected
  block, 0 that are not a flag flip, identical key sets either side
- rfp provenance: v0.47.0, `bb3862c`, templates byte-identical to `origin/main`
  `da115d4` and clean. The checkout had moved off `main` mid-task; checked rather
  than assumed
- Suite is knowingly red at this commit: `test-gq_groups.R:149` asserts the stub.
  Phase 2 replaces it.
- Next: Phase 2 — rewrite the theme tests
