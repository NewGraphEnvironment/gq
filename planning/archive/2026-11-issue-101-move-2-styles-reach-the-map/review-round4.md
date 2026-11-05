# Review round 4 — branch 101 (87f7677...HEAD), round-3 fixes first

## Checklist read

- Read the index of all four files in /private/tmp/claude-501/-Users-airvine-Projects-repo-gq/7d7e8d18-f413-459a-9be0-b7bbf07847f3/scratchpad/checklist_r1.txt. None is marked `read in full`.
- code-check.md, `## Mechanisms`: read the full prose of "A guard that fails toward pass", "A proxy is not the property", "A guard's scope, escape hatches, and remedies", "One fact derived twice" and "Zero-length, empty, and unset are three different things". Worked from the index for the others ("Restore the bug and prove the guard fires", "Verification that reads its own output", "Serialization loses meaning silently", and the rest).
- code-check-r.md: read the full section of "CSV whitespace", and checked the diff against the index lines for `$` partial matching, `nzchar(NA)`, `ifelse()` all-NA, `paste()` zero-length, `[[` on a named atomic vector, `vapply` dimnames, `expect_warning`/`expect_message` regexp anchoring, and a `pkg::` call in tests. None applies beyond the finding below.
- code-check-shell.md and code-check-spatial.md: no tool, shape or pattern they cover appears in this diff (R and CSV only, no shell or GDAL). Index only.

## Round-3 fixes

- **class_opacity()** (R/gq_tmap_style.R:169, used at R/gq_tmap_style.R:183 and R/gq_tmap_legend.R:171): correct. Names are kept. NULL passes through, so a layer with no opacity still adds no legend column. The legend's positional `pick()` indexes the same `keep`-filtered vector that gq_style() builds `values` from. The map and the legend now take this fact from one helper.
- **Label assertion** (test-gq_style.R): sound. `c("RH1", "RF")` read by key gives `Highway, Freeway`. Read by position it gives `Freeway, Highway`, so the test can tell the two apart.
- **Unstyled-layer warning** (R/gq_reg.R:182-196): it fires on the case it was written for, it does not fire on reg_custom.csv, and the targeted tests pass (test-gq_reg 69, test-gq_style 43, test-gq_tmap_style 227, test-gq_tmap_legend 126, no failures). Its predicate is too narrow, though. Finding below.

## Findings

- **[severity: bug]** R/gq_reg.R:187-188 — The warning tests for a proxy (no top-level `fill`/`stroke`/`mark`/`classification`/`label` key) instead of the property (a misspelled header produced a wrong layer). Every misspelling on the classified path still passes silently. Main errored on each case below, because `!is.na(NULL)` is `logical(0)`, which errors in `&&` and in `if`. So this is the round-3 regression, still open on its most-used path. Probed in a worktree at HEAD; none of these warns:
  1. `class_feild` misspelled on a two-row polygon key. `has_class` is FALSE, so the key falls to the simple branch and becomes one `fill` taken from row 1. Row 2 and the whole classification are dropped. Example result: `list(type = "polygon", fill = list(color = "#111111"))`.
  2. `fill_colour` misspelled on a classified polygon. `classification` is present, so the check passes, but every class is `list()`. gq_style() returns `values = c(SBS = NA, ESSF = NA)`, and gq_tmap_style() passes `values = NA, NA` to `tm_scale_categorical`. gq_mapgl_classes() returns its `#888888` fallback, so nothing reports it.
  3. `stroke_colour` misspelled on a classified line. Classes carry `width` only, with no colour.
  4. `stroke_colour` misspelled on a simple line that also fills `label_color`. The layer has only a `label`, which counts as styled, so the stroke is lost with no message.

  Why it matters: this is the main way a consumer's CSV goes wrong. The result is a single-colour or colourless layer drawn with no message, which is the outcome the round-3 warning was added to prevent. A fix stays within the accepted `notes` tradeoff: warn when the layer has a classification in which any class has no `color`, or a key has more than one row but no classification. In both cases name the unread columns. Pin cases 1 and 2 in test-gq_reg.R next to the existing `trk` test.
  - **Rule:** code-check.md "A proxy is not the property" (and "A guard's scope, escape hatches, and remedies": the predicate covers only the shape of the one fixture it was written against)

Nothing else found. The `styled` literal at R/gq_reg.R:187 restates the keys the CSV builders write. That is a contract the repo chose, not a fact derived twice, and every key the CSV path writes today is in it.
