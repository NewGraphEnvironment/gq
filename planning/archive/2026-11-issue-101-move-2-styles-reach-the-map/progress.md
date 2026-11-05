# Progress — Move 2: styles reach the map (batches 3, 4, 5) (#101)

## Session 2026-11-05

- Plan-mode exploration — phases approved by user
- Created branch `101-move-2-styles-reach-the-map-batches-3-4` off origin/main
- Scaffolded PWF baseline from issue #101 with approved phases
- Next: start Phase 1
- Phase 1 (batch 3): per-class opacity through gq_style() -> tmap_classified()
  (fill_alpha / col_alpha, scalar when uniform, NA read as 1) and into legend rows; labels
  named by class key. Guards proven by restoring each bug in memory: 6 opacity tests red
  with opacities dropped from gq_style(), the map/legend test red with them dropped from
  legend_entries() alone. The map/legend test first passed vacuously (empty loop) and was
  tightened. Edited #24's body to carry #31's casing/outline remainder.
- Plan review delivered after the Phase 1 commit; findings and dispositions in
  `review-plan.md`, folded into `task_plan.md` (commit a955f42).
- Phase 2 (batch 4): `reg_main.json` rebuild confirmed byte-identical on unchanged
  sources first. Absent optional columns read as empty; classified lines write
  color/width/dash/opacity; `dash` column validated (QGIS style names or a pattern) and
  read for simple strokes too; empty `dash` column added to `reg_custom.csv`; rebuild
  still byte-identical. Guards: all 7 new tests red against main's reader in a worktree;
  the 3 line tests red with only the line branch reverted. An in-memory swap probe was
  wrong (tests resolve the attached export, not the namespace binding) and was redone in
  a worktree.
- Phase 3 (batch 5): 32 rows in `reg_custom.csv` (6 layers); rebuilt `reg_main.json` is
  190 lines added, none removed. Tree loss `#e7298a`, gain `#ff8c42`, chosen from
  `tree_change_swatch.png` (rendered by `tree_change_swatch.R`) and CIEDE2000 scores.
  Registry-only keys pinned in `test-gq_groups.R`; `farver` added to Suggests for the
  colour-distance test. Edited #67 and #98 bodies; filed #107 (mapgl opacity) and the
  QML issue in the upstream style store.
- Phase 4: CLAUDE.md above the marker drops the layer count and documents keyed per-class
  vectors, opacity-as-opaque, the CSV contract and registry-only keys. README needed no
  change (it states no count and no CSV contract). Vignette legend path rendered with named
  labels, no warnings. Lint diff against an `origin/main` worktree: two new indentation
  lints, both fixed; the rest came from gitignored `tests/testthat/_problems/` files dated
  2026-09-07, which exist only in this checkout.
- `/code-check branch`, four rounds (files `review-round1..4.md`):

  | Round | Findings | Fixed | Accepted | Inside previous fix? |
  |---|---|---|---|---|
  | 1 | 2 | 2 | 0 | — |
  | 2 | 2 | 2 | 0 | n |
  | 3 | 1 (+2 notes folded in) | 1 | 0 | n |
  | 4 | 1 | 1 | 0 | y (round 3's warning tested a proxy) |

  Ended by enumeration: the 23 columns `gq_reg_custom()` and its `csv_*` helpers read
  (scanned from the code) are all in `cols_reg_optional` plus the two required; `note` is
  the one listed column never read, deliberately. Pinned as a test. Every real registry
  CSV (gq's own, drift x2, wet x2, fish passage reporting x3) reads with 0 warnings.
  Mechanism behind rounds 1-3 (round 3's naming): one fact derived in two places that agree
  by coincidence. Round 4's was a proxy for the property.
  Agent count for the task: 5 (plan review + 4 rounds), at the agent-operations bound.
