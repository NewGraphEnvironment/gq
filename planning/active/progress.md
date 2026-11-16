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
- Post-merge `devtools::test()`: 432 blocks, 1838 expectations, 0 failed, 1 expected skip; currency tests ran against rfp (templates unchanged since 9b73405d)
- Post-merge `R CMD check`: Status OK, 0/0/0 (examples, tests 14s, vignettes rebuilt); installed size 14.1 MB from doc/ and styles/, not this branch
- Round 2 re-spawned 01:14Z to `review-round2b.md`
- Round 2 (`review-round2b.md`): 4 findings. (1) `$` partial match on `...` overrides in the halo code: gone with the code. (2) "tmap has no halo" was true only of the installed tmap 4.2.0.9000; CRAN 4.4-1 (what CI installs) has `opt_tm_text(halo = TRUE)`, eight offset copies. Installed CRAN tmap; `gq_tmap_labels()` back to the planned `do.call()` arguments with tmap's halo, `tmap (>= 4.3)` in Suggests; vignettes re-rendered and read. (3) categorized/graduated parsers now read enabled top-level layers, take a cased class's dash/opacity from the core, and name unmodelled class layers in `note` (mutation-checked; shipped registry unchanged). (4) accepted: the QML writer's roxygen already says multi-layer symbols are not written, and pattern fills were dropped silently before this branch too.
- Round 3 (`review-round3.md`), asked for the mechanism: one symbol-reading rule copied across the single, categorized and graduated parsers, the tick overlay and the data-defined scan, each fix reaching only the copies in view; the graduated miss was inside round 2's fix. Fixed by one `symbol_read()` all parsers call (enabled top-level layers, symbol x layer opacity, casing/overlay, every unmodelled layer named, the first included). Also: overlay and polygon-outline opacity folded (12 polygon layers gain an outline opacity equal to their symbol alpha; tmap's polygon path now reads it as `col_alpha`, mapgl's fill-opacity already covers the outline); data-defined scan reads drawn enabled layers only; `gq_tmap_labels()` checks tmap >= 4.3; mapgl defaults a colourless halo to white as tmap does; pipeline_permit's note now names its hatch. Mutation-checked: 5 restored bugs, each fails its test.
- After round 3: suite 438 blocks, 1864 expectations, 0 failed; vignettes re-rendered against the installed branch and read (outline opacity barely visible at 0.2 mm, labels unchanged)
- Round 4 (`review-round4.md`), the enumeration round: the disagreements left were inside round 3's fixes (tick marker had no enabled filter; the data-defined scan read a different set from what `symbol_read()` models; five round-3 guards had no test that fails without them), plus unchecked label units, unhandled renderer types with no note, and a roxygen claim that pass order is noted. All fixed: `symbol_read()` returns the nodes it modelled and the data-defined scan reads exactly those; `print_size()` converts mm/pt/inch and leaves pixel/map-unit/percent sizes out with a note; an unread renderer is named. The pre-existing mapgl outline gap it measured is gq#120.
- Terminal enumeration, run here rather than by a fifth reviewer: a mutation table over 29 guards the branch introduced (`scratchpad/mutate.py`), each removed in turn with its test file run: 29 of 29 red, checkout restored byte-identical. The tmap >= 4.3 check cannot be exercised with tmap 4.4-1 installed. Every symbol-layer selection in the extractor (3) carries the enabled-only predicate and goes through `symbol_read()`; every symbol opacity write multiplies the same symbol x layer alpha. A fresh re-extract matches the shipped registry, so round 4 changes no shipped data.
