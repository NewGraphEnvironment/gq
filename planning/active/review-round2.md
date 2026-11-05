# Code review, round 2: branch 101-move-2-styles-reach-the-map-batches-3-4 (HEAD f879496)

## Checklist read

- code-check.md: I read the prose of all 14 H3s under `## Mechanisms`, skipping the `|` tables and evidence blocks. Outside Mechanisms I read no headings: none names a tool or shape this diff uses (no security, YAML, URL or spreadsheet code).
- code-check-r.md, read by heading: "CSV whitespace: `trim_ws` and `strip.white` do not do what the name suggests", "Tests that silently do not run" and "`tolerance` in testthat is RELATIVE…". I checked these against the diff from their index lines only: "`$` on a list partial-matches…", "`[[` on a named ATOMIC vector…", "`vapply(..., USE.NAMES = FALSE)`…", "`read.delim()` quotes by default…", "`nzchar(NA)` is TRUE", "`paste()` with a zero-length argument…", "`ifelse()` with an all-NA test…", "Cross-function consistency for label/string normalization", "A `data-raw/` script must load the source tree…", "Under `R CMD check`, tests run from a temp dir…" and "A `pkg::` call in a test…" (farver is in Suggests and drift is behind `skip_if_not_installed`). I did not open the other ~150 headings: they cover tools the diff does not use.
- code-check-shell.md: none read (0 of ~95). The diff has no shell.
- code-check-spatial.md: none read (0 of ~120). The diff touches no terra, sf or GDAL code; tests build sf lines only to feed tmap.

## Round 1 fixes: verdict

**(a) The layer-level `stroke` is back for classified CSV lines.** The fix is right and complete.
- In a worktree at HEAD, I rebuilt every `gq_reg_custom("inst/registry/reg_custom.csv")` layer and compared it with the matching layer in `reg_main.json`. All 15 are `all.equal`, so the two `stroke` blocks the commit added to `reg_main.json` are what the code now writes.
- Mutation check: I put back `!is_line &&` and ran the file. "a classified line from CSV still gives mapgl its stroke width" fails.
- Neither of the two new comparison lines has a `stroke_width`, so mapgl still gets no width for them. That comes from the data, not the code.
- Row 1's opacity is applied to every class in mapgl (0.7 where the `outside` class is 0.45). That is the known gap (gq#107).

**(b) The vocabulary test now reads `reg_qgis_restoration.json`.** The fix is right.
- Mutation check: renaming `width` to `line_width` in `csv_line_class()` fails the vocabulary test, along with three others.
- The reference is a committed extract, so a rename in the extractor would not reach this test until the next re-extraction. `test-gq_qgs_extract.R` pins `$width` and `dash` on live extractor output, and the shipped data does not change until a re-extraction anyway. So the comment's claim, "a rename on either side fails", holds where it matters.
- Test files run at HEAD: test-gq_reg, test-reg_styles, test-gq_mapgl_style, test-gq_tmap_legend and test-gq_groups. All have 0 failed and 0 errors.

## Findings

- **[severity: bug]** R/gq_tmap_style.R:208 with R/gq_tmap_legend.R:190: if a CSV line leaves `stroke_width` blank on some of its classes, the map and the legend draw different widths. This branch made that input reachable, and its own comment says so ("A CSV-authored line leaving stroke_width blank on some rows produces a partial vector, so this is reachable"). Before #42 the CSV route never produced `widths`. The two readers handle a blank width differently:
  - The map falls back to the scalar `unname(cls$widths[1])`.
  - The legend reads each class's width and fills a missing one with `legend_na_default$lwd = 0`.

  Probe: a CSV with classes a and b, `stroke_width = c(NA, 2)`.
  - `gq_tmap_style()` gives `lwd = NA`, and tmap draws both classes at lwd 1. Class b's 2 is thrown away with no warning, and this is not the "documented scalar" the comment promises.
  - `gq_tmap_legend()` gives `lwd = c(0, 2)`. Class a's key is invisible, and class b's key is twice as wide as the line drawn on the map.

  With the blank on a later row instead (`c(1.2, NA)`), the map draws every class at 1.2 and the blank class's legend key is still invisible. The branch already solved this for opacity, where both readers treat NA as opaque. Width has no shared reading.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** tests/testthat/test-reg_styles.R:48: the tree-gain colour test compares against three hard-coded colours, `others <- c("#d95f02", "#f2a93b", "#e49635")`. Those copy three registry colours: first-rule-only, valley bottom (ff06) and Crops. The test's claim is that gain stays distinct from whatever those classes are, but a registry change re-pins the other tests in this file and leaves this list alone. Someone could move `first` to an orange next to gain, update the pin in the rule-comparison test, and this test would still pass against the old literal. The land-cover test in the same file makes this exact point ("a copy would agree with itself whatever drift ships"). This is the round-1 (b) mistake again: the reference is not read from the artifact it describes. Taking the three colours from `styles("habitat_rule_comparison")`, `styles("floodplain_flood_factor")` and `styles("landcover_change_from")` would fix it.
  - **Rule:** code-check.md "One fact derived twice"
