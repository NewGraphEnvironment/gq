# Findings — Move 1: vendored artifacts current and guarded (batches 1, 2) (#100)

## Issue context

**If we do it:** the rosters and styles gq copies from the template repo are current, the registry and the templates agree on where each layer sits, and a copy going stale fails a test. **If we never do:** the drift test keeps passing against a copy vendored months ago, and every consumer of gq's groups and themes reads a roster the templates have moved past.

Move 1 of `planning/backlog.md`, which holds the order, the measurements and each batch's section. Run `/planning-init` on this issue: one plan, one phase per batch, one PR. `/gh-pr-merge` ticks the move when it merges.

## First, a read of the peer repos

Themes and groups are being reworked in the two repos that consume these rosters: the template repo, and the repo that holds each field project's config (owner, 2026-11-04). Open there on 2026-11-04: themes composed in project config as a base plus additions and removals, a reconciler for layer group placement after a project is created, floodplain theme names being retired and merged, a Terrain group and theme for the templates, and a test fixture failing against the current registries. Before the plan gate, search both repos' open issues and pull requests for `themes` and `groups`, read each adjacent body, and settle with them which side owns each roster. Nothing in the two batches below is decided until that read is done.

## Batch 1: Template agreement

**Why here:** one checkout of the template repo at one version and one run of the extractors pays for all four.

**Touches:** `inst/registry/template_groups.csv`, `form_types.csv`, `groups.csv`; `tests/testthat/test-template_drift.R`, `test-gq_forms.R`; `data-raw/reg_extract_template_groups.R`.

**Decided at the gate:** whether `groups.csv` gains a `template` column; for each of the six layer placements in #68, whether gq's side was a decision or unchecked drift; register or exempt the three layers in #73.

| issue | title |
|---|---|
| #70 | Delete the three template-drift exemptions |
| #94 | Re-vendor form roster: eDNA is now styled |
| #68 | Registry and templates disagree on the group six layers belong to |
| #73 | Tracking and the two habitat-parameter layers ship in the templates with no groups.csv row |

## Batch 2: Vendored-artifact guards

**Why here:** the same extractor scripts, run after batch 1 has made the copies current, against the roster shape the peer repos are moving to.

**Touches:** `R/utils_qgs_groups.R` and a sibling for themes; `data-raw/reg_extract_*.R`, `data-raw/styles_vendor.R`; a corpus-wide QML test.

**Decided at the gate:** where the guard runs now the templates are build output; whether gq becomes the single QML store, which flips where the fix for #86 lands; the `bcfishobs_fiss_fish_observations` key rename.

| issue | title |
|---|---|
| #78 | gq's vendored artifacts have no currency guard: 2 of 3 were silently stale |
| #86 | bcfishobs QML: 4 dangling tags remain |
| #92 | A causal claim about the template repo is settled by reading it, not by re-measuring its output |



## Errors Encountered

| Error | Resolution |
|-------|------------|

## Phase 1 measurements (2026-11-05, rfp v0.93.0 `80bff2c4`, detached worktree)

- Re-vendor changed two files only: `template_groups.csv` (+`Floodplain` 7, `Restoration` 8 in bcrestoration, four orders shifted) and `form_types.csv` (eDNA styled; `general_monitoring`, `observation`, `scan`, `tree` new; `trail_feature` retired upstream in rfp `3a83239d`). `themes.csv` and the QML corpus re-ran byte-identical.
- The drift guard went red on the fresh copy exactly where expected: `each exemption is still needed` (Floodplain, Restoration), and the forms pin (eDNA).
- The refactored walker (`qgs_tree_nodes()`) reproduces `template_groups.csv` byte for byte.
- `template_layers.csv`: 113 layers (bcfishpass 54, bcrestoration 59). Every key joins to `groups.csv` except `tracking` and the two `parameters_habitat_*` tables, all `NoGeometry` in rfp's roster.
- Guards proven: restoring `streams_all` to `Streams` fails the placement test once per template, and deleting the `wetland` row fails the registered-or-exempt test.
- Placement moves inserted each layer after its previous sibling in the template, where gq holds that sibling. Order within a group still disagrees with the templates in 7 groups, identically in both templates. #68 covers group membership only, so this is filed as gq#105.
- `reg_build_main.R` reads neither `groups.csv` nor the form roster, so `reg_main.json` needs no rebuild.

## Plan review dispositions (review-100.md, delivered after the phase 1 commit)

| # | finding | probe | disposition |
|---|---|---|---|
| 1 | tier-1 QML noise | Reproduced: 26 of the vector QMLs name fields in `editable`/`labelOnTop`/`reuseLastValue`/`column` that their `fieldConfiguration` lacks, 497 names in all (crossings_pscis_assessment 70, crossings_pscis_modelled_dams 69, …). Those tags are a stale snapshot of every column QGIS once saw. | Plan corrected (not a stored-data fork): tier-1 checks only the field-scoped tags that are clean corpus-wide (alias, default, constraint, constraintExpression, attributeEditorField). Expressions outside the roster go to an "undecidable" inventory. The snapshot-tag inventory goes to rfp#188 as evidence for the store cleanup. #86 acceptance 1 is amended in its body, so the 4 bcfishobs tags are not caught by tier-1 |
| 2 | subgroup interleave cannot be expressed | Reproduced in `R/gq_groups.R` sort | Recorded on gq#105 as a limit that needs a schema change, with #104 |
| 3 | within-group order unguarded | Same measurement as Phase 1 | Already filed as gq#105 |
| 4 | one-way guard, unique keys | — | Comment added. The test now asserts per-template key uniqueness on the committed file |
| 5 | NoGeometry is weak evidence | Reproduced: rfp's roster shows the same empty geometry for `clab_national_parks` | Reasons now cite rfp's `.rfp_audit_whitelist` ("Non-spatial rfp-owned tables", `R/rfp-constants.R`) |
| 6 | forms loose ends | Reproduced | "thirteen" in `R/gq_forms.R` roxygen and the parent claim fixed; edna/tree child exclusions pinned. The `trail_feature` retirement goes in the PR body for NEWS. `test-gq_groups.R` was already fixed in phase 1 |
| 7 | validation step 2 wrong | Correct: installed rfp 0.92.0 has byte-identical templates | The currency test is gated on the env vars only, with no installed-rfp fallback, so a stale install cannot fail it falsely. Validation step reworded |
| 8 | `reg_qgis_restoration.json` is a fifth rfp-derived artifact | Reviewer measured 48/48 matching v0.93.0, apart from the corrected bcfishobs source_layer and float noise | Excluded: it is a lossy registry extract that feeds `reg_main.json`, not a vendored copy, and it belongs to batch 8 (registry build inputs, #102/#85). Noted on #102 |
| 9 | #86 and #70 cannot close as written | — | PR: "Relates to #86". #70 closes with the gate decision cited (2 of 3 exemptions deleted, column deferred to #104) |
| 10 | red proof | The suite was run after the re-vendor and before the exemption edits: `each exemption is still needed` and the forms pin failed (phase 1 findings) | No action |

## Phase 2: currency guard (#78)

- Builders (`template_groups_build`, `template_layers_build`, `themes_build`, `form_types_build`) and the one writer (`vendored_write`) live in `R/utils_vendored.R`, and the theme walker in `R/utils_qgs_themes.R`. All three generators re-ran against v0.93.0 with byte-identical output.
- `test-vendored_currency.R` writes each live roster through `vendored_write()` to a tempfile and compares lines with the committed file. It is gated on `RFP_TEMPLATE_DIR` and `RFP_LOOKUPS_DIR` only (review #7). Without them its 4 live checks skip; with them, 12 pass.
- Proven: with `origin/main`'s stale `template_groups.csv` and `form_types.csv` restored, and one `themes.csv` row flipped, the three matching live checks fail, then pass once the files are restored.

## Phase 2: QML consistency (#86)

- Tier 1 as built (`test-qml_consistency.R`): `alias`, `default`, `constraint`, `constraintExpression` and `attributeEditorField` must name a roster field. All 60 files are clean today. Bare expression references outside the roster (6) are pinned as undecidable in both directions, `species_name` among them, as #86's negative control. The snapshot tags (`editable`, `labelOnTop`, `reuseLastValue`, attribute-table `column`) are excluded: 26 of the vector files, 497 names in all. The 4 bcfishobs tags are among them.
- Proven: a planted bad alias in `railway.qml` fails the corpus sweep; the test also injects a bad alias and a bad preview into a copy of `conservancy.qml`.
- Tier 2, against the newgraph DB (2026-11-05, tunnel on 63333). `bcfishobs.observations` has 34 columns (matching rfp#307): `linear_feature_id` and `species_name` resolve. `fid` is not a view column; it is the key OGR adds to the GeoPackage layer the style is applied to, so it is legitimate. `fish_obsrvtn_pnt_distinct_id` is absent, so the 4 tags are dead, as #86 said. #86's original "7 dead fields" is superseded: `fid` and `linear_feature_id` are both fine.
- Other undecidables: `national_park:english_name` resolves. `conservancy:protected_lands_name`, `first_nation_reserve:IR_NAME` and `roads_dra:structured_name_1_id` are not in the DB copies, but those copies are column subsets (7 to 16 columns) of the BC WFS layers rfp downloads through bcdata, so the result is inconclusive. `rmp_ogma_non_legal_current_svw` is not in the DB at all. All stay pinned.
