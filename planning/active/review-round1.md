# Code-check round 1: branch `100-move-1-vendored-artifacts-current-and-gu` (HEAD c384d28)

## Checklist read

- **code-check.md**: I read every H3 under `## Mechanisms` as prose, skipping the table rows: A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. That is 14 read. I skipped the 23 "Rules that stand alone", Security and Spreadsheet headings (index lines only).
- **code-check-r.md**: 8 read: Read-back shape must match write-back shape; A `data-raw/` script must load the source tree, not the installed package; Tests that silently do not run; A `skip_if_not()` skips only its own `test_that()` block; `identical()` on two reader results tests the reader, not the file; Under `R CMD check`, tests run from a temp dir against the INSTALLED package; CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests; `sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent. The other ~108 were not read beyond the index.
- **code-check-shell.md**: 0 read. The diff has no shell code. All 69 were index-only.
- **code-check-spatial.md**: 0 read in full. The two QGIS index lines (embedded style, value-map GUID) do not apply to this diff. All ~93 were index-only.

## Probes run

All in a detached worktree, removed afterwards. Nothing was modified in the gq or rfp checkouts.

- Full suite: 0 failed, 0 errors, 4 skipped, 1155 passed.
- Currency test with `RFP_TEMPLATE_DIR` and `RFP_LOOKUPS_DIR` pointed at the rfp v0.93.0 checkout: all 7 blocks pass.
- I put main's `groups.csv` back. "every layer sits in the group the template puts it in" then failed with 2 failures, so the placement guard fires.
- `qgs_layer_table()` walks 54 of 54 `layer-tree-layer` nodes in bcfishpass and 59 of 59 in bcrestoration. That matches the `<maplayer>` count, so no root-level layer is missed.
- I ran all four builders under `en_US.UTF-8` and under `C` collation. With today's data the outputs are `identical()` (see finding 1 for why that is luck).
- Collation inside gq's edition-3 tests: `devtools::test()` reports `LC_COLLATE` = `"C"`. Under plain `Rscript` it is `en_US.UTF-8`.

## Findings

- **[severity: fragile]** R/utils_vendored.R:25, 40, 85, 173. All four builders (`template_groups_build`, `template_layers_build`, `themes_build`, `form_types_build`) sort with a bare `order()`. That order fixes the row order of a committed file, so the canonical form depends on the session's `LC_COLLATE`.
  - The generators run under `Rscript` in `en_US.UTF-8`. `test-vendored_currency.R` rebuilds under testthat 3e, which forces `C`, and then compares the two files line by line.
  - Today's group paths, theme names and keys happen to sort the same either way, so the test passes. Two likely upstream names would not:
    - a theme name that differs only by case at some position. Measured: `"Low detail - roads"` vs `"Low Detail - Salmon Model"` swap order between the two locales.
    - a `layer_key` where an underscore meets a digit. Measured: `roads_dra` vs `roads2` swap.
  - When that happens the currency test fails although nothing is stale. Its remedy message ("re-run data-raw/reg_extract_*.R") cannot clear it, because re-running the generator writes the `en_US` order again. That is the exact shape the rule describes: a value pinned outside the suite and verified inside it.
  - `gq_group_layers()` in the same package already uses `method = "radix"`.
  - Fix: add `method = "radix"` to all four `order()` calls, then re-run the generators. Today the output is byte-identical, so no committed file changes.
  - **Rule:** code-check-r.md "`sort()` and `order()` collate by `LC_COLLATE`, so a canonical form is locale-dependent" ; code-check.md "A guard's scope, escape hatches, and remedies"

## Notes (not findings)

- Some comments describe the comparison inconsistently. Neither changes behaviour:
  - The header of `R/utils_vendored.R` says the currency test compares BYTES, but it compares `readLines()` output.
  - The header of `test-vendored_currency.R` calls the QML corpus "the fourth vendored artifact". CLAUDE.md says the test covers four rosters and that the QML is a separate, fifth artifact.
- Checked and clean:
  - `has_spatial == "true"`: `read.csv()` keeps lowercase `true`/`false` as character (measured), so the filter works.
  - `vendored_write()` NA handling round-trips `NA` to `"NA"` consistently.
  - `layer_exempt` is a named empty vector.
  - `groups.csv` keys are unique (pinned in test-composition_integrity.R).
  - `withr` is in Suggests.
  - The data-raw scripts call `load_all()` unconditionally.
  - The fixtures discriminate: lake drifts, wetland does not, and the leading-space name joins.

/Users/airvine/Projects/repo/gq/planning/active/review-round1.md
