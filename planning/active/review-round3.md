# Review round 3 — consumers and interop (gq#105)

Reviewed at gq HEAD c004f56; rfp at origin/main 122b8a7a (fetched 2026-11-15, working tree on main).

## Checklist read

- code-check-r.md: read "CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests", "`nzchar(NA)` is TRUE — non-empty checks silently pass NA", "Tests that silently do not run", "`paste()` with a zero-length argument returns length ONE, not zero", "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent" (5 read; 116 not read; "`expect_gt()` and friends take no `info` argument" read by index line only).
- code-check.md: read the prose of all 14 H3s under `## Mechanisms` (table rows skipped); 24 not read (Rules that stand alone, Security, Spreadsheets/PDFs — none applicable).
- code-check-shell.md: 0 read in full; 71 not read (the diff contains no shell; my probes used `git show`/three-dot only).
- code-check-spatial.md: 0 read; 94 not read (no spatial code in the diff).

## Consumers checked

gq:
- `read_groups_csv()` (utils::read.csv, `na.strings = c("", "NA")`) feeds `gq_groups()`, `gq_group_layers()`, `gq_template_layers()`. The new CSV parses to 62 rows x 5 columns, 10 groups, `Roads,Railways,Pipelines` intact; `readr::read_csv()` gives the same group column and 62x5. A merge of old and new on (group, subgroup, layer_key, source_type) matches all 62 rows with no orphan: only `order` moved, membership and `source_type` unchanged.
- `data-raw/styles_vendor.R` reads groups.csv for `layer_key` only (order-blind).
- No vignette, README or R/ prose depends on the old within-group order (searched for World Topo / top basemap / town position). `test-template_drift.R:227` "beneath ESRI World Topo" is a historical sentence about group order, still true.
- test-template_drift.R (68 pass), test-gq_groups.R (80 pass), test-composition_integrity.R (58 pass), all under NOT_CRAN=true, 0 failed / 0 error / 0 skipped.

rfp (the only consumer outside gq):
- rfp never reads groups.csv itself; its sole route is `rfp_project_layers()` -> `gq::gq_template_layers()`, keeping `order` as a column.
- `rfp_project_create()`: download pass order comes from `rfp_manifest_types()`, not from row order; within a type, row order only changes the sequence of `layers =` handed to `rfp_source()`, with nothing indexing `layers[1]`. The QGIS layer tree comes from the copied template, not from gq order. `.qgs_trim_absent()`, forms, themes and services don't read gq order.
- Manifest (`.manifest_config_types()`/`.manifest_finalize()`) dedups and then sorts by type and name, so it doesn't depend on order.
- `rfp_project_audit()` / `rfp_project_update()` use set operations on `source_layer`, so order doesn't matter to them.
- `rfp_source_test()` dedups with `!duplicated(source_layer)` and reports the first row's `group`. The duplicated source_layers (crossings_vw x2 in Crossings, streams_vw x3 in Streams plus streams_all in Basemap, bec poly x2 in Basemap/Terrestrial Ecology) still have their first occurrence in the same group as before, so the reported `group` is unchanged.
- rfp tests calling `rfp_project_layers()` (test-manifest_from_layer_config.R, test-rfp_project_identity.R) assert set membership and manifest validity only.

## Prose claims executed

- NEWS "disagreed with both QGIS templates in seven groups": `order_drift()` against origin/main's groups.csv returns exactly the 7 paths in `order_groups_105`, for each template.
- "town moves up to sit after glaciers"; rivers_poly after first_nation_reserve; dam after moti_major_structures: each holds in the new CSV.
- Roxygen "Waterbodies is the fourth child of Basemap": template_groups.csv `Basemap/Waterbodies` order 4 in both templates, with glaciers 3 and fire_historical_burn 5.
- Roxygen "subgroups sort by name, so Habitat models lists before Stream labels, which both templates draw on top": Stream labels order 1, Habitat models 2 in both templates; gq sorts by name, so Habitat models comes first.
- CLAUDE.md "(62 rows, 10 groups)" still holds.

## Clean

No issues found.
