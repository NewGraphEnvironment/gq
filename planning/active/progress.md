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
- Phase 1 check: `devtools::check()` on 9ea4d8d, 0 errors / 0 warnings / 0 notes; the gq#80 test ran under check.
- Phase 2: `gq_basemap_tiles()` attaches `maptiles::get_credit(provider)` as attribute `"credit"`; `gq_basemap_blend()` sets the de-duplicated union on its result (SpatRaster and stars). Mutation: removing either assignment turns its test red.
  - Composition vignette: credit drawn below the frame with grid in a 0.25 in strip; `tm_pos_out()` route abandoned (see findings). Render read: frame, legend, keymap identical to main's render, credit line below.
- Plan review (Plan agent, spawned 21:14Z) delivered after Phase 2: `review-plan.md`. Folded in: plan text amended (credit mechanism, NEWS via PR body, About owed after merge, Phase 5 order, single JSON writer, semantic compare, reg_demo.json deletion, G2 claims). All accepted; none disputed. B1 (invalid `bittner_wsd`) was already met and fixed in the render.
- Review fold-in landed: roxygen documents the strip pattern and stars dropping the attribute; `test-build_hygiene.R` comment; gq#80 test keyed on `testthat::is_checking()` (emulated check layout: passes; old path 2 failures; no tree 1 failure, not a skip).
- Phase 3: gq-intro rewritten on `gq_reg_main()`; 12 crossings inside `bittner_wsd`; legend, scale bar, logo, keymap, credit strip. Legend guard parametrized (`legend_coverage(file, chunk, min_drawn)`) and extended to `map-intro`, with a hex-literal check; mutations (drop lake from legend; type `#ffffff`) both go red. `inst/examples/reg_demo.json` deleted.
  - Render read found `bittner_wsd` takes in ~500 ha (9%) of Fraser/Nechako river corridor (250 m opening: 5,016 ha core, 11 of 12 crossings); one "inside" crossing is on the Fraser and the frame widens over downtown Prince George. Owner chose: re-pull the Bittner data in this PR. DB tunnel (localhost:63333) was down at 21:5xZ; waiting on it.
- Phase 5 (step 1): `reg_qgis_restoration.json` re-extracted from rfp v0.93.0 (80bff2c4; template byte-identical to the checkout). Semantic compare: top level identical, same 48 keys in a new order, only bcfishobs `source_layer` differs (old -> `bcfishobs.observations`), 11 notes differ only by the dash. bcfishobs block deleted from `reg_build_main.R`; rebuilt `reg_main.json`: 63 layers, content identical to before apart from notes, order changed. ACCESS correction still fires (30). Suite: 316 blocks, 0 failed.
