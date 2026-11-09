# Progress: Move 3: package face and check gate (batches 6, 7, 8) (#102)

## Session 2026-11-09

- Archived the stale gq#28 PWF triple (untracked since April) to `planning/archive/2026-04-issue-28-groups-themes-templates/` (7d0ce85, on main)
- Plan-mode exploration; seven gate decisions taken by the owner; phases approved
- Created branch `102-move-3-package-face-and-check-gate-batch` off origin/main @ 7d0ce85
- Scaffolded PWF baseline from issue #102 with approved phases
- Next: start Phase 1
- Phase 1: non-ASCII literals replaced (`tools:::.check_package_ASCII_code(".")` returns nothing); demo datasets and `data-raw/demo_layers.R` removed; `vignette_source()` searches `00_pkg_src` at three depths, tarball first, and reports its layout; `error-on` dropped (flows' default is `"warning"`).
  - Reachability test proved in an emulated `<pkg>.Rcheck/tests/testthat` layout in the scratchpad: passes with the fix, 2 failures with the one-level `../00_pkg_src` restored.
  - NEWS is written at release by `/gh-pr-merge` (v0.18.0's NEWS landed in the release commit), so the breaking-change lines go in the PR body rather than NEWS.md; Phase 6's NEWS item becomes that.
