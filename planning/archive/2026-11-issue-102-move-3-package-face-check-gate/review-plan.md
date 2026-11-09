# Plan review: #102 (Plan agent, spawned 2026-11-09T21:14Z, delivered after Phase 2)

Findings as returned in the agent's reply (Plan agents cannot write), condensed to the
claim, evidence and fix; the disposition of each is in progress.md.

## Blocker
- B1 `bittner_wsd` is invalid; under s2 `st_intersects`/`st_difference` error ("Edge 145 crosses edge 148"). Works with s2 off or in 3005. Fix: build filter/mask there; assert 12 crossings drawn.
- B2 "every colour from the registry" is impossible as worded: `bittner_streams` has no `feature_code`; railway overlay is not modelled. Fix: say Phase 3 follows the composition pattern (roads via `field=`, streams and railway coloured from registry values, drawn by hand).

## Gap
- G1 `inst/examples/reg_demo.json` is read only by gq-intro; orphaned by Phase 3. Delete it (breaking line) or keep and say why.
- G2 leaflet/ggplot2 claims also in gq-intro prose and CLAUDE.md (lines 9, 50-52, 70, 348-350; "GitHub Action (gq#11)" under Future is superseded by decision 7).
- G3 Stale text: `test-build_hygiene.R:112` (error-on "error"); `test-composition_integrity.R:219-242` bcfishobs test name becomes false after re-extract (rewrite, not flip); `:180-198` comment; `reg_build_main.R:91-119`.
- G4 Roxygen says render with `tm_credits()`, which fails below the frame with `meta.margins = 0`; three copies of the grid-strip arithmetic loom (composition, intro, README figure). Document the pattern; decide on a helper.
- G5 mapgl takes a layer, not `(reg, "x")`; `R/gq_reg.R:15` example still uses the old tmap signature.
- G6 Legend guard: `drawn_keys()` sees only `gq_tmap_style(reg, "<key>")` calls; `expect_gt(length(drawn), 3)` may fail for intro. Make the minimum per-vignette.
- G7 One JSON writer for script and tests; never put the rfp sha in the JSON (the extract would compare unequal forever) - commit message and script header instead.
- G8 Phase 1 box says "with a NEWS entry" but NEWS.md is untouched; plan text should say PR body.
- G9 `gh repo edit --description` publishes before merge; move to Owed at the end.
- G10 README figure script would copy gq-intro and drift; evaluate the vignette's chunk or save from its render.

## Ordering
- O1 Phase 5: re-extract, delete the bcfishobs block, rebuild, rewrite pins in one commit; then extract the builder and add the byte test (else the block's guard stops mid-way).
- O2 README rewrite must already omit fishpassage and use the corrected xref wording.
- O3 Phases 2 -> 3 -> 4 order is right.

## Assumption
- A1 `tm_pos_out` exists but fails with `meta.margins = 0`; non-zero margin shrinks the frame and the keymap is device-placed. Plan text still says `tm_pos_out`.
- A2 credit attr survives terra project/arith/clamp/resample/crop/`[[`; dropped by `mean()`, `st_as_stars()`, stars `[` and `st_crop`. One line in `@return`.
- A3 Byte rebuild is deterministic today (in-memory rebuild identical to shipped, 1949 lines; `write_json` digits = 4). Compare in memory; failure message should name jsonlite formatting as a possible cause.
- A4 Re-extract: same 48 keys; content differs only in the 11 notes (dash) and bcfishobs `source_layer`; no roads_dra float noise at 4 digits; but layer ORDER changes, so reg_main reorders (1492 positional diffs) - review by semantic compare. ACCESS correction still needed (bcfishpass#13 open). rfp checkout is on a feature branch; the template is identical to v0.93.0 - extract against the tag.
- A5 The builder must live in R/: `data-raw` is build-ignored.
- A6 Decisions 1, 5, 6 premises hold.
- A7 `pkgdown::check_pkgdown()` is close to vacuous (no `reference:` section).

## Scope (noticed, not this PR)
- `neexdzii_bc` documented as 1 row; has 28001 rows, 12 MB.
- `python/` stays once the README drops the PyQGIS claim.
- No `man/gq-package.Rd`.

## Acceptance
- AC1 gq#80 test should key on `testthat::is_checking()` and fail rather than skip under check.
- AC2 Phase 3 mechanical: 12 crossings drawn; no `#rrggbb` in the map chunk beyond named exceptions; guard runs on the intro chunk.
- AC3 Phase 5 re-extract: semantic compare, not diff-reading.
- AC4 Rebuild restore-the-bug as a committed test (temp inputs, one value changed, expect mismatch).
- AC5 `devtools::check()` again at the end.
