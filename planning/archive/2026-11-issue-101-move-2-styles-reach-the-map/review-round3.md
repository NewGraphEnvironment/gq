# Review round 3: branch 101 (87f7677...2d47746)

## Checklist read

- **code-check.md**: read all 14 H3s under `## Mechanisms` (prose only, table rows skipped). Of the 33 other headings (stand-alone rules, Security, Spreadsheets and PDFs), I read none in full: none names a tool or shape this diff uses.
- **code-check-r.md**: read 7 in full: "Read-back shape must match write-back shape", "CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests", "`$` on a list partial-matches, so a longer sibling key answers for a missing one", "`vapply(..., USE.NAMES = FALSE)` strips ALL dimnames, row names included", "`match()` treats NA as a matchable VALUE, so two unknowns join to each other", "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if `pkg` is undeclared", "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are". I checked the rest against the diff by their index lines only.
- **code-check-shell.md**: read 0 in full. The diff has no shell.
- **code-check-spatial.md**: read 0 in full. The diff has no terra, sf, GDAL or bcdata code.

## The mechanism behind rounds 1 and 2

Each earlier finding was **one fact derived in two places that agreed only by coincidence**:
- R1: the CSV writer vs the extractor vocabulary.
- R1: the vocabulary test's reference vs the writer it checked.
- R2: the map's reading of a part-filled width vs the legend's.
- R2: the tree-gain test's colours vs registry copies of them.

Below is every place in this diff where the map and the legend, the two writers, or a test and its reference each derive a per-class value.

### Map (gq_tmap_style.R) vs legend (gq_tmap_legend.R)

| per-class value | map | legend | verdict |
|---|---|---|---|
| colour | `tmap_scale_classified(cls)`, `values` keyed by `levels = names(values)` | `vals[[j]]` from the same `gq_tmap_classes()` vector | sound: one source |
| label | `cls$labels` (named; tmap matches by name) | `labs[[j]]` positional, same order as `values` | sound: same vector |
| width | `complete()`, otherwise `class_axis(cls$widths)[1]` | `pick(class_axis(cls$widths), j)` | sound: shared helper; `class_axis()` returns `v` unchanged when complete |
| radius | `cls$radii` / `class_axis()` (here `cls` is `sty$classification`) | `class_axis(sty$classification$radii)` | sound: same object, same helper, both call `gq_symbol_size()` without a shape |
| dash | `class_ltys()`: NA becomes "solid" via `%||%` | `dash_to_lty()` gives NULL, so NA, which `collect_legend()` defaults to "solid" | sound: two code paths, same result |
| opacity | `tmap_alpha_args()`: NA becomes 1; scalar if uniform, otherwise a scale | `alpha()`: NA becomes 1 (and `collect_legend()` would also default NA to 1) | sound but **implemented twice**, not shared the way widths now are. I probed every layer that carries opacities (fire_severity, roads_dra, streams_all, bec_zone and the four new layers) and the two agree on all of them. tmap 4.4 does draw the legend rows' `fill_alpha`/`col_alpha`: grob alpha was 0.4 for fire_severity's Unburned row and 0.6 for roads_dra's resource rows. No legend has a duplicate label once alpha joins the dedup key. |
| present / levels.drop | data-driven `levels.drop` | `present` filter | sound by design |

### Writer vs writer (CSV vs extractor)

- **Line classes**: both now write `color`/`width`/`dash`/`opacity`, and `gq_style()` reads those keys. Sound.
- **Polygon classes**: the CSV keys are a superset of the extractor's (`outline_color`/`outline_opacity` added). Sound.
- **Dash names**: `csv_dash()`'s six style names are QGIS's complete `line_style` set, and `parse_dash()` passes through anything other than "solid". The pattern separators `[; ]` match `mapgl_line()`'s `strsplit("[; ]")`. Sound.
- **Columns read vs columns padded**: `cols_reg_optional` covers every `r$`/`row$` column the `csv_*` helpers read; I checked this by grep. Padding also closes the data-frame `$` partial-match hole, since every name read is now present exactly. Sound.

### Tests whose expected value comes from the thing they check

- **test-gq_reg.R, vocabulary test**: the reference is `reg_qgis_restoration.json` (extractor output). Sound.
- **test-gq_tmap_style.R, "draws each class at its own opacity"** (fire_severity, roads_dra): expected from `gq_tmap_classes()`, observed from the rendered grob. This tests the translator. `gq_style()`'s own reading is pinned separately by literals (fixture `0.4`/`NA`, bec_zone `0.25`). Sound.
- **"map and legend agree on per-class opacity"**: compares two independent NA-to-1 implementations against each other. The opaque case is also pinned to a literal 1 elsewhere. Sound.
- **"part-filled width"**: `want` is computed inline from the fixture by the spec rule, not by `class_axis()`. Sound.
- **test-gq_style.R, "labels index by class key"**: its third assertion compares `cls$labels` with itself (by name vs by `match()` on identical names), so it cannot fail once the `identical(names)` line passes. The #55 regression (unnamed labels) is still caught by `identical()` and `anyNA()`, and a label shift is caught by the literal label tests on the mini registry. Weak but sound.
- **test-reg_styles.R**: colours, labels and opacities are literals (the contract). Tree gain reads its comparators from the registry, and land-cover reads drift's own table. Sound.
- **test-gq_groups.R `registry_only`**: a literal list, but guarded both ways (it must exist in the registry and must have no groups.csv row). Sound.

## Findings

- **[severity: fragile]** R/gq_reg.R:114-116: an absent optional column is now filled as empty, and nothing reports an unrecognised one, so a misspelled header silently drops that style. Before this branch, a missing column errored, cryptically but loudly. Now `stroke_colour` (or `stroke_widht`, `fill_colour`) yields a layer with no style at all. Probed in a worktree:
  - this branch: `data.frame(layer_key="trk", type="line", stroke_colour="#ff0000", stroke_width=1)` returns `list(type = "line")`, and `gq_tmap_style()` returns `list()`, so tmap draws its defaults with no message.
  - 87f7677 (the base): the same CSV errored.

  A rename shows up as two signals: an expected column missing and an unexpected sibling present. The new code reads only the first, so it cannot tell a rename from an intended absence. This is most likely in a Canadian org's hand-written CSV (the `colour` spelling). One remedy: compare `names(df)` against `c("layer_key", "type", cols_reg_optional)` and warn, naming any unknown column.
  - **Rule:** code-check.md "Serialization loses meaning silently"

No other issues. These test files pass in a detached worktree at 2d47746 with `NOT_CRAN=true`, 0 fail, 0 error, 0 skip: test-gq_style.R, test-gq_tmap_style.R, test-gq_reg.R, test-gq_groups.R, test-gq_trail_style.R, test-reg_styles.R and test-gq_tmap_legend.R. `tools:::.check_packages_used_in_tests` returns empty, so no test uses an undeclared package.
