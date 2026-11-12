# Progress — Add mapgl composition helpers (#18)

## Session 2026-11-12

- Plan-mode exploration — phases approved by user
- Created branch `18-add-mapgl-composition-helpers` off origin/main
- Scaffolded PWF baseline from issue #18 with approved phases
- Next: start Phase 1
- Phase 1 (#107): `gq_mapgl_classes(layer, property = "*-opacity")` builds per-class opacity,
  absent read as 1, a scalar when all classes share one. 5 new tests; file 39 pass.
- Plan correction: NEWS is written at merge by `/gh-pr-merge`; no NEWS edits on the branch.
