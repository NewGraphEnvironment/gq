# Code review, round 1: branch 103-extractor-fidelity-and-labels (base a7f5aced)

## Checklist read

- **code-check.md**: the prose of all 14 H3s under `## Mechanisms` (A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice), plus Documentation Staleness. 23 of 38 headings not read.
- **code-check-r.md**: Read-back shape must match write-back shape; A replacement function on an `xml_missing` node is a silent no-op; A `data-raw/` script must load the source tree, not the installed package; Tests that silently do not run; `expect_gt()` and friends take no `info` argument; Cross-function consistency for label/string normalization; `$` on a list partial-matches, so a longer sibling key answers for a missing one; `nzchar(NA)` is TRUE — non-empty checks silently pass NA; Under `R CMD check`, tests run from a temp dir against the INSTALLED package; A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared. 111 of 121 not read.
- **code-check-spatial.md**: QGIS embeds a layer's style in the `.qgs`, so rewriting the `.qml` sidecar changes nothing. 93 of 94 not read.
- **code-check-shell.md**: none. The diff has no shell code beyond a usage comment. 71 of 71 not read.

## What was run (in a detached worktree, removed afterwards)

- CI installs tmap from CRAN (4.4.1), and this machine has 4.2.0.9000. So CRAN tmap 4.4.1 went into a scratch library and the full suite ran against it with `NOT_CRAN=true`: 1675 expectations, 0 failed, 0 errors, 6 skips (the vendored-currency and R CMD check gates).
- Both changed vignettes render under tmap 4.4.1, and the maps look right: halos draw and the labels sit in place.
- I rendered a town label through `gq_tmap_labels()` (finding 1) and probed the perimeter_curved mapping and the `size =` override (findings 3 and 4).
- The template and bcfishpass_30k.qlr write every label as `fontSizeUnit="Point"` and `bufferSizeUnits="MM"`, so the unchecked label units cause no harm today. No symbol layer is `enabled="0"`, and every active data-defined colour sits on a drawn category symbol, never the `source-symbol`.

## Findings

- **[severity: bug]** R/gq_tmap_labels.R:72-73 (against R/gq_mapgl_labels.R:60-61). The two translators read the registry's `offset_y` with opposite signs. MapLibre's `text-offset` treats positive y as down, and tmap's `ymod` treats positive y as up: in tmap 4.4.1, `tmapGridDataPlot.tm_data_text` computes `coords[,2] + yIn*lineIn*cex*ymod`. The CSV values (town 1.2, dam 1.5, planting_site 1.5) were written for MapLibre, to put the label below the dot. `test-gq_mapgl_labels.R` pins `text_offset = c(0, 1.2)`, and the soul cartography skill passes them straight to `text_offset`. So `gq_tmap_labels(reg, "town", field = "name")` draws the name *above* the dot, while `gq_mapgl_labels()` draws it *below*. I rendered the tmap case to confirm. The comment at line 70 covers units ("ems ... what xmod/ymod measure in lines") but not direction. The fix is `args$ymod <- -lab$offset_y`, and the halo copies follow because they read `args$ymod`. No test pins the sign.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** inst/registry/reg_custom.csv, the dam, town and planting_site rows. The CSV's label units changed from MapLibre px to QGIS pt/mm (12 to 9, 11 to 8.25, halo 1.5 to 0.4). A documented consumer still reads them as pixels: soul `skills/cartography/SKILL.md:439-444` and `:705-710` pass `reg$layers$town$label$size` to `text_size` and `label$halo$width` to `text_halo_width`. Every map built from the skill now draws town labels at 9 px with a 0.4 px halo instead of 12 px and 1.5 px, and nothing errors. The new `gq_mapgl_labels()` converts correctly; the risk is any consumer that reads the registry fields directly.
  - **Rule:** code-check.md "Written data outlives the fix" ; code-check.md "Documentation Staleness"

- **[severity: fragile]** R/gq_mapgl_labels.R:50. `symbol_placement` is `"line"` only for `c("line", "curved", "perimeter")`. The extractor also emits `"perimeter_curved"` (`label_placements["7"]`, QGIS's "Using perimeter (curved)" on a polygon), and `gq_mapgl_labels()` maps it to `"point"`. I confirmed this with a probe. No shipped layer carries it today, so the literal set covers today's data and misses a value the extractor can write.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** R/gq_tmap_labels.R:79, 87-88. The halo arithmetic runs after the `...` overrides. When `size`, `xmod` or `ymod` is overridden with a data column name, which tmap supports (e.g. `size = "area"`), it fails with "non-numeric argument to binary operator" (probed). The roxygen documents `...` as passed to every `tm_text()` call, so a documented use errors in gq's own code before tmap sees it.
  - **Rule:** none

- **[severity: fragile]** R/gq_qgs_extract.R:563, 628-631. Rule-based labelling counts and selects `.//settings` without checking the rule's `active` attribute. On the restoration template, "Crossings - PSCIS, modelled, dams" has three rules and the third is `active="0"`. The shipped registry note therefore says "3 rules, the first taken" where QGIS draws 2. A template whose first rule is inactive would have that disabled rule recorded as the label. Symbol layers already filter `[not(@enabled='0')]`, so the two paths disagree.
  - **Rule:** code-check.md "A proxy is not the property"
