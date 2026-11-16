# Progress — Move 4: extractor fidelity and labels (batches 9, 10) (#103)

## Session 2026-11-12

- Plan-mode exploration — phases approved by user
- Created branch `103-extractor-fidelity-and-labels` off origin/main; claimed move #103
- Scaffolded PWF baseline from issue #103 with approved phases
- Next: start Phase 1

## Session 2026-11-13 (UTC)

- Plan review returned (05:29Z); findings and dispositions in `review-plan.md`, folded into `task_plan.md`
- Phase 1 landed: label field/expression, weight, placement and hints; layer opacity fold; casing, railway tick overlay, top-level symbol count; data-defined colour note; `.qlr` and PostgreSQL `table=` sources; `gq_style()` surfaces casing, outline and label
- Fixtures cut from real XML by `data-raw/fixture_extract_template.R`; mutation checks: field read, `./layer` count and opacity fold each turn their test red
- Re-extract: 22 labels (14 field, 8 expression, 3 bold), `source_layer` unchanged on all 48 layers, 14 layers' symbology changed
- QGIS 4.1.0-Master (`qgis/qgis:latest`) cannot parse the streams' data-defined colour expression (`IN ()`), so QGIS draws the category colours; note reworded to hold in every case; filed rfp#430
- Full suite after Phase 1: 397 blocks, 1608 expectations, 0 failed, 1 expected skip (R CMD check gate); currency tests ran against the rfp checkout
- Fixed the halo regression from 799c7da; asked the owner about label units (QGIS units, CSV converted); added `gq_tmap_labels()` and `gq_mapgl_labels()` with tests; vignettes moved to `gq_tmap_labels()`
- Rendered both vignettes against the installed branch and read the PNGs: stream and lake labels draw once, in the registry's blue italic with a white halo, no stray halo copies; Bulkley River sits over two crossing symbols at the confluence (remove_overlap keeps text off text only), as before at a smaller size
- Lints compared per file/linter/line with an origin/main worktree: 4 new, all fixed; `check_pkgdown()` clean
- R CMD check: 1 failure, `test-gq_reg.R:66` pinned the town label at 12 (px); now 9 pt (bcd8bde)
- Filed gq#116 (draw casing/overlay), gq#117 (CSV label_field), soul#847 (cartography recipe reads label units raw)
- /code-check branch round 1 spawned 05:52Z
- Round 1 (`review-round1.md`, ran the suite against CRAN tmap 4.4.1: 0 failed): 5 findings. Fixed 4: tmap read the CSV's `offset_y` up where MapLibre reads it down (now negated; mutation-checked); `perimeter_curved` now follows the line in mapgl; a `...` size mapped to a column skips the halo with a warning; inactive label rules are skipped and not counted (dams note now "2 rules"). Finding 2 (skill recipe reads units raw) is soul#847.

## Session 2026-11-16 (UTC)

- The session restarted; round 2 of the branch review never delivered (no findings file), so it re-runs to `review-round2b.md`
- `main` had moved to v0.22.0 (#115, the QML writer). Merged origin/main (no conflicts). The writer warns on `overlay` but dropped `casing` silently, which after this branch drops MoTi's black casing; it now warns on a layer's or a class's casing, with a test. Writer tests pass on the branch's registry.
