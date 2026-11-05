# Code-check round 2 — branch `100-move-1-vendored-artifacts-current-and-gu` @ 2ad92c1

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms`, with table rows and evidence blocks skipped: A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. From the index only: "Documentation Staleness". All other full sections not read.
- **code-check-r.md**, read in full: `sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent; Read-back shape must match write-back shape; CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests; `identical()` on two reader results tests the reader, not the file. Applied from the index line only: `$` partial matching; `[[` on a named atomic vector; `paste()` with zero-length input; `nzchar(NA)`; `vapply(..., USE.NAMES = FALSE)`; A data-raw script must load the source tree; Tests under R CMD check; A `pkg::` call in a test (checked with `tools:::.check_packages_used_in_tests`); `expect_gt()` and friends take no `info`. All other sections not read.
- **code-check-shell.md**: index only. No shell in this diff.
- **code-check-spatial.md**: index only. Applied from the index: "QGIS embeds a layer's style in the `.qgs`…" and "A QGIS value map's empty choice…". Neither is touched by this diff.

## Verification done (in a detached worktree, since removed)

- Ran the full suite at 2ad92c1 with no env vars: 1160 expectations, 0 failed, 0 errors, 4 skips (the four currency checks).
- Ran the vendored_currency, template_drift, qml_consistency, gq_forms and gq_groups tests with RFP_TEMPLATE_DIR and RFP_LOOKUPS_DIR pointed at rfp v0.93.0: 0 failed, 0 errors, 0 skips.
- Ran all three generators under Rscript (LC_COLLATE en_US.UTF-8, ICU on) against v0.93.0. `git status` was clean afterwards, so every committed roster is reproduced byte for byte under en_US. testthat checks them under C, so the radix fix holds in both locales.
- The comment's collation examples are correct as stated. Under en_US, "Low detail - roads" sorts before "Low Detail - Salmon Model" and `roads_dra` before `roads2`; C and radix order both pairs the other way.
- Checked these claims against rfp v0.93.0, and all hold:
  - 18e0004d is the first commit in v0.68.0, and both templates now say `layername=bcfishobs.observations` with no trace of the old name.
  - `slugify()` lives in tests/testthat/test-rfp_qgs_style_store.R and pins `idx$slug`.
  - `.rfp_audit_whitelist` holds exactly rfp_tracking and the two parameters tables, under the comment "Non-spatial rfp-owned tables".
  - The three non-spatial children key as form_cabin_pebbles, form_edna_samples and form_tree_visits, so the new negative assertion in test-gq_forms.R is not vacuous.
  - groups.csv has 62 rows and 10 groups, with no duplicate layer_key.
  - The themes.csv comment "byte-identical to that output" holds: a re-run produced no diff.
- `read.csv()` keeps lowercase `"true"` as character, because `type.convert` does not read it as logical. So the `has_spatial == "true"` filter and the builder test's two-row fixtures behave as written.

## Findings

- **[severity: fragile]** data-raw/styles_vendor.R:289: `corpus[order(corpus$kind, corpus$layer_key, corpus$template), ]` is a bare `order()`, and it decides the row order of the committed `inst/styles/index.csv`. It is the only remaining sort whose output reaches a committed file. The radix fix converted the four roster builders, and the header of R/utils_vendored.R now says "Every sort is method = "radix"", but this one was left alone. Today it is latent: the current 57 rows sort the same under en_US, C and radix (measured). The first `layer_key` pair that differs only by `_` against a digit, or by case, will make a re-vendor's output depend on the session locale. That is the same `roads_dra`/`roads2` swap the new comment describes, and it shows up as index.csv churn with nothing changed upstream. No test compares index.csv line by line today, so nothing fails yet. It becomes a false failure the day the corpus joins the currency test, which is where rfp's store-move issue points. The fix is one argument, `method = "radix"`.
  - **Rule:** code-check-r.md "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent"

- **[severity: fragile]** data-raw/reg_build_main.R:112-114 and :133-134: the rewritten paragraph at :95-101 now states that rfp's templates carry the new name from v0.68.0. Verified true. That contradicts two unchanged lines in the same block:
  - The comment at :112-114 still says the layer "stays absent from the map until rfp updates its templates -- tracked in the rfp issue named from gq#82". That is now false: rfp has updated its templates.
  - The `stop()` at :133-134 still tells the operator "rfp's templates have been regenerated -- delete this block". But the new DELETE note at :116-119 makes the real trigger the re-extraction of `reg_qgis_restoration.json` (gq#102), and the templates were regenerated long ago. The action, delete the block, is still right; the reason it gives is wrong.

  Both only mislead; neither can break a build. They are listed because the brief asked whether a rewritten comment now says something false, and the rewrite left its neighbours saying the opposite.
  - **Rule:** code-check.md "Documentation Staleness"

Nothing else found. The other places that decide order were checked:
- `template_groups_build`, `template_layers_build`, `themes_build` and `form_types_build` all sort radix on keys that are unique, and the builders refuse duplicates, so the order is total and stable.
- `qgs_tree_nodes` and `qgs_theme_table` return rows in document order.
- `merge()` in test-vendored_currency.R feeds only a set comparison of length 1.
- `gq_group_layers()` already sorts radix.
- `gq_template_layers()` uses a bare `order()` on subgroup, but its output is never stored or compared across locales.
