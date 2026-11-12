# Progress — Add mapgl composition helpers (#18)

## Session 2026-11-12

- Plan-mode exploration — phases approved by user
- Created branch `18-add-mapgl-composition-helpers` off origin/main
- Scaffolded PWF baseline from issue #18 with approved phases
- Next: start Phase 1
- Phase 1 (#107): `gq_mapgl_classes(layer, property = "*-opacity")` builds per-class opacity,
  absent read as 1, a scalar when all classes share one. 5 new tests; file 39 pass.
- Plan correction: NEWS is written at merge by `/gh-pr-merge`; no NEWS edits on the branch.
- Phase 2: `gq_mapgl_basemap()` (voyager, positron, openfreemap, esri_topo) and
  `gq_mapgl_network()` (water from `lake`, streams from `streams_all`, width by order); internal
  `mapgl_need()`, `check_digits()`, `mapgl_geom()`, `mapgl_data()`, `round_sfc()`,
  `esri_topo_style()`, `order_width()`, `reg_layer()`. 33 tests pass.
- Found: `maplibre(bounds =)` reduces an `sf` to its bbox but stores an `sfc` raw, so the basemap
  wraps the geometry in an `sf`.
- Plan review (Plan agent) landed as Phase 3 began: `planning/active/review-plan.md`. Already met
  by the Phase 3 draft: 2, 4-9 (fixed legend ids, computed `add`, `width` column, typed classes,
  hex passthrough, typed adders, source sharing). Taken now: 17 (property check restricted to
  `^(fill|line|circle)-(color|opacity)$`, test added), 15 (plan text). Folded into the plan: 12,
  13, 19 (Phase 5), 1/3/11/21/22 (Phase 4 parity test: seeded, controls off, water in fixture,
  default-removal mutation). 16 (14 stacked legends) is checked in the browser in Phase 4.
