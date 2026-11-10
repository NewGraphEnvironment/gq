# Code-check round 1: branch 102-move-3-package-face-and-check-gate-batch (base 7d0ce85, HEAD c449c78)

## Checklist read

- **code-check.md** (37 headings): read all 14 under `## Mechanisms` (prose, table rows skipped): A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. Not read: 23.
- **code-check-r.md** (117 headings): read Under `R CMD check`, tests run from a temp dir against the INSTALLED package; A `data-raw/` script must load the source tree, not the installed package; Tests that silently do not run; A `skip_if_not()` skips only its own `test_that()` block; `identical()` on two reader results tests the reader, not the file; CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests; `R CMD build` ships every top-level directory not in `.Rbuildignore`. Not read: 110.
- **code-check-shell.md** (70 headings): index read; no section read (the diff has no shell code; the workflow change is one YAML input). Not read: 70.
- **code-check-spatial.md** (94 headings): read sf: `st_intersection()` / `st_difference()` return a GEOMETRYCOLLECTION that QGIS will not draw; `sf::st_make_valid()` rewrites geometry that was already valid (both for gq-intro's mask). Not read: 92.

## Verified, no finding

- Registry JSON: semantic compare of `git show 7d0ce85:` against HEAD for `reg_main.json` (63 keys) and `reg_qgis_restoration.json` (48 keys): same key sets, top-level fields identical, the only differences are 11 `note` strings (em dash to hyphen) and bcfishobs `source_layer` (`bcfishobs.fiss_fish_obsrvtn_events_vw` to `bcfishobs.observations`). Matches the author's claim.
- No reference anywhere in R/, tests/, vignettes/, man/, `_pkgdown.yml` to the deleted demo datasets, `reg_demo.json` or `reg_qgis_fishpassage.json`. `R/data.R` never documented the demo datasets.
- `gq_reg_merge()` / `gq_reg_custom()` do no `sort()`/`order()`, so the byte-for-byte currency test does not depend on `LC_COLLATE`. The only non-ASCII in the sources (an em dash in `reg_custom.csv`'s `note`) never reaches `reg_main.json`, so no encoding sensitivity either.
- `maptiles::get_credit()` 0.11.0 returns NULL for an unknown provider name and `$cit` for a provider object, so `attr<-` either removes or sets; no error path.
- flows `r-cmd-check.yaml@v1` defaults `error-on` to `'"warning"'`, as the workflow comment says. `testthat::is_checking()` exists from 3.1.9; DESCRIPTION floors testthat at 3.2.0.
- gq-intro's `aoi_mask` is MULTIPOLYGON, not a GEOMETRYCOLLECTION.
- In a detached worktree with `load_all()` and `NOT_CRAN=true`: test-reg_build_currency, test-xref_layers, test-gq_basemap_blend, test-gq_basemap_tiles, test-vignette_legend_coverage, test-composition_integrity all 0 failed / 0 error (one expected skip, the gq#80 test outside check).

## Findings

- **[severity: fragile]** tests/testthat/test-vignette_legend_coverage.R:193-200 — the gq#80 test keys on `testthat::is_checking()` as a stand-in for "a tarball was unpacked to `00_pkg_src`", and the two are not equivalent. `is_checking()` reads `TESTTHAT_IS_CHECKING`, which `test_check()` sets under every `R CMD check`; but `tools:::.check_packages` creates `00_pkg_src` only inside `if (is_tar)`. So `R CMD check <source-dir>` (a supported invocation, and the one that also puts `gq.Rcheck/` inside the repo) has `is_checking()` TRUE and no `00_pkg_src`, and the test fails with `Expected length(pkg_src) > 0`. Reproduced: a `gq.Rcheck/tests/testthat/` layout in a detached worktree with `TESTTHAT_IS_CHECKING=true` gives 1 failure on this test (vignette_source resolves to the `source` layout via `../../../vignettes`), everything else green. CI, `devtools::check()` and `rcmdcheck` all check a tarball, so this does not fire there; it turns a directory check red for a reason unrelated to the code. Either state in the test that a directory check is unsupported and expected to fail here, or find a signal that separates a tarball check from a directory check and skip visibly on the latter. Remedy not designed or executed by the reviewer.
  - **Rule:** code-check.md "A proxy is not the property"

No other issues found.
