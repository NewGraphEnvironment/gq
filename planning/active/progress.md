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
