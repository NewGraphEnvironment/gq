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
