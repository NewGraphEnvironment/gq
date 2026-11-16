# Review round 2 — gq#105 (branch 105-layer-order-within-a-group-disagrees-wit, HEAD c004f56)

## Checklist read

- **code-check.md** — Mechanisms prose read in full, table rows skipped: A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice (14 read). Not read: the 22 headings under Rules that stand alone, Security, and Spreadsheets and PDFs. None of them covers anything this diff uses.
- **code-check-r.md** — read: `expect_gt()` and friends take no `info` argument; `sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent; `nzchar(NA)` is TRUE — non-empty checks silently pass NA; `match()` treats NA as a matchable VALUE; Tests that silently do not run; testthat counts an uncaught error under `error`, not `failed`; CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests; `data.frame()` recycles a scalar against a zero-length column; `paste()` with a zero-length argument returns length ONE, not zero (9 read, 112 not read).
- **code-check-shell.md** — 0 read, 71 not read. The diff has no shell code.
- **code-check-spatial.md** — 0 read, 94 not read. The diff has no spatial code. The QGIS-related entries cover QML and `.qgs` I/O, which this diff does not touch.

## Mutation table (new guard: order_drift() and its three tests)

Each mutation was applied in a detached worktree of HEAD and the files restored between runs. For each one, `test-template_drift.R`, `test-composition_integrity.R` and `test-gq_groups.R` were run with `pkgload::load_all(worktree)` and `testthat::test_file()`, counting `failed > 0 | error`.

| # | Mutation | Expected | Result (red arms) |
|---|---|---|---|
| 0 | none (baseline) | green | GREEN |
| M1 | groups.csv: swap crossings_pscis_assessment / _confirmation (Crossings, one of the 7) | red | RED: "layer order within each group agrees with the template", "a swapped pair inside a group is reported" |
| M2 | groups.csv: swap fiss_stream_sample_sites / bcfishobs_fiss_fish_observations (Other point features, NOT one of the 7) | red | RED: same two arms |
| M3 | groups.csv: moti_culverts order 1 -> 2, tying crossings_modelled | red | RED: composition_integrity "draw order is unambiguous within a group". order_drift() alone stays green because `order()` is stable and row order still matches, so the duplicate guard is the backstop that fires. |
| M4 | groups.csv: swap lake / wetland (Basemap/Waterbodies, a subgroup path) | red | RED: order arms |
| M5 | groups.csv: swap streams_salmon / streams_bt (Streams/Habitat models) | red | RED: order arms |
| M6 | groups.csv: swap form_pscis / form_fiss_site (Forms, not one of the 7) | red | RED: order arms |
| M7 | groups.csv: swap town (gq-only) with conservancy | red (conservancy moves) | RED: order arms |
| M8 | groups.csv: swap habitat_lateral / esri_world_topo (Base - misc, not adjacent) | red | RED: order arms |
| M9 | template_layers.csv: rename bcrestoration "Web Mapping Services" -> "Web Map Services", so the intersection of paths shrinks | red via another guard | RED: "every layer sits in the group the template puts it in", "each reordered group is compared on more than one layer" |
| M10 | groups.csv: swap two rows' positions in the file, order values unchanged | green (no behaviour change) | GREEN |
| M11 | template_layers.csv: swap railway / roads_ften in bcfishpass only | red | RED: "layer order within each group agrees with the template" (comparison is per template, not over the union) |
| M12 | groups.csv: three-cycle pipeline_permit / _installed / _application | red | RED: order arms |
| M13 | groups.csv: crossings_modelled order -> NA | red | RED: order arms (NA sorts last) |

A gq-only layer moved alone (for example `town` sent to the end of Basemap without disturbing a shared layer's relative order) is not detected. That is by design: such a layer has no template position to agree with, and the test comment and the brief both say so.

Every mutation that should be caught turned the suite red, and the one behaviour-neutral mutation (M10) stayed green. Path-set shrinkage (M9) is caught by the placement test and by the "more than one layer" premise. The guard also covers groups outside the seven named ones (M2, M6), because order_drift() walks every intersecting path and is not limited to `order_groups_105`.

## Prose claims checked

- roxygen "`Waterbodies` is the fourth child of `Basemap`": template_groups.csv gives order 4 for Basemap/Waterbodies in both templates, and template_layers.csv skips index 4 in Basemap. Holds.
- roxygen "`Habitat models` lists before `Stream labels`, which both templates draw on top": Stream labels has order 1 and Habitat models order 2 in both templates, and gq_group_layers("Streams") lists Habitat models first. Holds.
- NEWS "`town` moves up to sit after `glaciers`" (orders 3 and 4); "Esri Satellite now heads the basemaps, with ESRI World Topo last" (orders 3 and 6 among the wms rows). Both hold.
- CLAUDE.md "(62 rows, 10 groups)": gq_groups() returns 62 rows and 10 unique groups. Holds.
- Test comment naming gq-only layers (`town`, `dam`, `rivers_poly`): none of the three is in template_layers.csv. bcrestoration also has `bec_zone` as gq-only within Basemap/Terrestrial Ecology. The parenthesis reads as examples rather than an exhaustive list, so this is not a defect.

## Clean
No issues found.
