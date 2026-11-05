# Code-check round 3: branch 100-move-1-vendored-artifacts-current-and-gu at e229939

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms` (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice), plus Documentation Staleness. 15 of 37 H3s read; 22 not read.
- **code-check-r.md**: `sort()` and `order()` collate by `LC_COLLATE`…; Read-back shape must match write-back shape; `identical()` on two reader results tests the reader…; CSV whitespace…; Under `R CMD check`, tests run from a temp dir against the INSTALLED package; A `skip_if_not()` skips only its own `test_that()` block. 6 of 117 read; 111 not read.
- **code-check-shell.md**: none. The diff has no shell code. 0 of 70 read.
- **code-check-spatial.md**: QGIS embeds a layer's style in the `.qgs`… 1 of 94 read; 93 not read.

## What I ran (worktree copy at HEAD, removed afterwards)

- `devtools::test()` filtered to vendored_currency, template_drift, gq_forms, gq_groups, qml_consistency and composition, with `RFP_TEMPLATE_DIR` and `RFP_LOOKUPS_DIR` pointing at rfp v0.93.0. Result: FAIL 0, SKIP 0, PASS 234. The live currency checks ran and passed under testthat's C collation.
- Ran all three generators (`reg_extract_template_groups.R`, `reg_extract_themes.R`, `reg_extract_form_types.R`) with `Rscript` under `en_US.UTF-8`. `git status` stayed clean, so the committed files are byte-identical to what the generators write in the other locale.
- `inst/styles/index.csv` is in radix order and in locale order; the two agree on this data.
- Every `inst/registry` CSV the builders write is ASCII-only, so neither encoding nor `LC_CTYPE` can split generator from test.
- In rfp v0.93.0, every `<layer-tree-layer name>` matches its `<maplayer><layername>`: 54 of 54 in bcfishpass and 59 of 59 in bcrestoration.

## Mechanism

One fact gets derived or stated in two places, and nothing ties the two copies together. They agree only because of something nobody declared. In R1/R2 that was the session collation, which decided the row order of the generator's file and of the test's file. In the second R2 instance, a rewrite of one sentence had to happen to find every other sentence stating the same fact. The same mechanism also reaches a third kind of copy that the author's two enumerations did not cover: an **order key that is never written down**. `groups.csv` declares `order` within a group but no order for sibling subgroups. `gq_group_layers()` and `gq_template_layers()` therefore fill that gap by sorting subgroup **names**. That sort is a second derivation of z-order, and it agrees with the templates only while alphabetical order happens to match tree order.

Where it reaches, and whether each place is sound:

- **Sorts feeding committed files**: `template_groups_build`, `template_layers_build`, `themes_build`, `form_types_build` and `styles_vendor.R`'s index. All use radix, and all sort on keys that are unique: each builder or the index enforces it. Proven by the cross-locale byte-identity run above. **Sound.**
- **Sorts in R/ that feed no committed file**: `gq_groups.R:230` (bare `order()` on `subgroup`) and `gq_tmap_legend.R:212`. No stored copy to drift from. **Sound** for the collation mechanism. The z-order consequence of the line-111 and line-230 sort is the finding below.
- **Other writers of committed files**: `reg_build_main.R` and `reg_extract_restoration.R` write with `jsonlite::write_json`, in list order. No test regenerates their output and compares it. **Not a generated-vs-compared pair; sound.**
- **Other generated-vs-compared pairs**: only `test-vendored_currency.R` (four rosters) and the QML byte check in `test-gq_style_qml.R` (it copies files and sorts nothing). **Sound.**
- **Hard-coded `templates` vector** in `reg_extract_template_groups.R`, `reg_extract_themes.R`, `test-template_drift.R` and `test-vendored_currency.R`: four copies of one list. If they diverge, `expect_setequal(unique(tbl$template), templates)` fails loudly. **Sound.**
- **`group_keys`**: the generator reads `unique(read.csv("inst/registry/groups.csv")$layer_key)` and the test uses `gq_groups()$layer_key`. Same values. **Sound.**
- **`layer_key` from the tree name vs from `<layername>`**: `template_layers.csv` and the registry/themes take the key from two different producers. They agree today (measured above), but nothing enforces it. **Sound today, unguarded.**
- **Prose restating the nine rewritten facts**: form count (13 to 16), `trail_feature` gone, eDNA styled, the edna_sample/tree_visit children, the bcfishobs rename (checked against rfp: `18e0004d` is first in v0.68.0, and both v0.93.0 templates read `layername=bcfishobs.observations`), the Floodplain/Restoration exemptions, where the live test lives, `Project Specific` contents, rfp's slugify. Checked the counts quoted elsewhere: CLAUDE.md "62 rows, 10 groups" (still 62/10) and test-gq_groups.R:301 "7 vs 8, 9 vs 10" (these are `templates.csv` group_order values, unchanged). `R/utils_qgs_groups.R:31` "this reads … 10" still holds for bcfishpass (rfp's roster gives 11, gq's gives 10). README, vignettes and man carry no count or membership claim for the moved layers. **Sound.**
- **Z-order of the six moved layers in gq's own ordered outputs**: `streams_all` and `fisheries_sensitive_watersheds` now sit under Basemap, as in the templates. The `first_nation_reserve` interleave gap is recorded on gq#105. `stream_labels` is **not sound**; see the finding.

## Findings

- **[severity: fragile]** inst/registry/groups.csv:35 (`"Streams","Stream labels",stream_labels,1,fwa`) with R/gq_groups.R:111 and R/gq_groups.R:230. Moving `stream_labels` into a new `Stream labels` subgroup reverses its draw order against the habitat-model lines in gq's documented z-order.
  - `gq_group_layers()` claims "Layers are ordered by z-order within the group", and `gq_template_layers()` sorts the same way.
  - Both order sibling subgroups by **name**, because `groups.csv` has no column for subgroup position. "Habitat models" sorts before "Stream labels".
  - Measured at HEAD: `gq_template_layers("bcfishpass_mobile")` for Streams now returns streams_bt, streams_salmon, streams_st, then stream_labels.
  - On main, `stream_labels` was the direct child at order 2, which sorts ahead of every subgroup. So it came **before** the habitat lines, which matches the templates. Both templates put `Streams/Stream labels` at order 1 above `Streams/Habitat models` at order 2, and the first node draws on top.
  - This branch therefore turns a correct relative order into a wrong one. The labels now rank beneath the lines they label.
  - Nothing reports it. The group-order test compares depth-1 groups only, and the new placement test compares group path, not position.
  - gq#105 does not cover it. gq#105 records order within a group and a subgroup interleaved among its parent's layers; neither is the order between sibling subgroups. Its table lists `Streams/Habitat models` alone.
  - No in-repo consumer draws from this order, which is why this is fragile and not a bug. Any external consumer that trusts the documented z-order now draws the labels under the habitat lines.
  - Remedy: add sibling-subgroup order to gq#105's "A limit to know first", naming this inversion. The fix belongs with the shared order key gq#105 already assigns to #104. Renaming the subgroup is not available, because the name must match the template.
  - **Rule:** code-check.md "One fact derived twice" ; code-check.md "A guard's scope, escape hatches, and remedies"

No other findings. Clean on the collation mechanism, on the round-trip and currency pairs, and on the prose restatements.
