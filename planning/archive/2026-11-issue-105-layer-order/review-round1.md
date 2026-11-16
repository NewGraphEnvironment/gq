# Review round 1 — gq#105 branch diff

## Checklist read

- **code-check.md** — read the prose of all 14 H3s under `## Mechanisms` (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice). Not read: 24 other headings.
- **code-check-r.md** — read 7: `sort()` and `order()` collate by `LC_COLLATE`…; `nzchar(NA)` is TRUE…; `paste()` with a zero-length argument…; Under `R CMD check`, tests run from a temp dir against the INSTALLED package; CSV whitespace: `trim_ws` and `strip.white`…; Tests that silently do not run; `expect_gt()` and friends take no `info` argument. Not read: 114.
- **code-check-shell.md** — read 0 (the diff has no shell). Not read: 71.
- **code-check-spatial.md** — read 0 (no terra/sf/GDAL in the diff). Not read: 94.

## What was checked (measured, 2026-11-15, branch HEAD c004f56 vs merge-base a5bbc30)

- Ran an independent order comparison (own code, not `order_drift()`) of old and new `groups.csv` against `template_layers.csv`: old drifts in exactly 7 paths in both templates (Base - misc, Basemap, Basemap/Waterbodies, Crossings, Roads,Railways,Pipelines, Streams/Habitat models, Web Mapping Services), matching NEWS / issue / `order_groups_105`; new drifts in 0.
- Membership + `source_type` identical old vs new (62 rows each, set-equal on group|subgroup|layer_key|source_type); 10 groups — CLAUDE.md "62 rows, 10 groups" holds.
- `order` contiguous 1..n in every group path; no duplicates.
- gq-only layers keep the neighbour above them, old and new: town under glaciers, rivers_poly under first_nation_reserve, dam under moti_major_structures, bec_zone under terrain_mapping_project_boundaries.
- Roxygen claims: `Waterbodies` is order 4 among `Basemap`'s children in both `template_groups.csv` templates; `Stream labels` is order 1 above `Habitat models` 2 in both; `gq_group_layers()` / `gq_template_layers()` code does sort own layers first and subgroups by name (confirmed in output). NEWS "Esri Satellite now heads the basemaps, ESRI World Topo last" matches the new `Base - misc` rows.
- gq#104 body carries the shared-order-key decision the docs hand off to; gq#105 title matches.
- `test-template_drift.R` (68 pass), `test-composition_integrity.R` (58), `test-gq_groups.R` (80): 0 failed, 0 error, 0 skipped via `testthat::test_file()` after `load_all()`.
- `order_drift()`: NA subgroup handled before `nzchar()`; `paths` sorted with `method = "radix"`; zero-row result is a typed empty frame so `expect_equal(d, d[0, ])` compares like with like; the swap test asserts a red case and the real-table green case, and the premise test covers the >1-shared-layer condition. `templates` is defined at line 92 of the file. `read_template_layers_csv()` reads via `system.file()`, so it works under `R CMD check`.
- No other consumer in R/, tests/, vignettes or README depends on the old within-group order.

## Clean
No issues found.
