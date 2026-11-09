## Outcome

Move 3 of `planning/backlog.md`: eight issues in three batches, one PR.

- **Check gate (#51, #80).** `R CMD check` runs clean and the workflow now fails on a WARNING. The five unused demo datasets are removed.
- **Vignette guard (#80).** The legend guard reads the vignette from the unpacked tarball under check, and a test proves that branch is taken.
- **Tile credit (#58).** Tile rasters carry their provider's credit and both vignettes draw it below the frame. `tm_credits(tm_pos_out())` crashes with `meta.margins = 0`, and with a margin it shrinks the frame, so the credit is drawn with grid in a strip under a map viewport.
- **gq-intro (#62).** Re-composed from the registry. Rendering it exposed a data defect: the bundled Bittner watershed, taken at measure 0, included ~500 ha of Fraser and Nechako river corridor. The data was re-pulled from just above the creek's mouth.
- **README (#95).** Rewritten to soul's `readme.md`, with a figure made from gq-intro's map chunk. It no longer claims a PyQGIS extractor or leaflet and ggplot2 support.
- **Registry inputs (#85, #84, #11).** `reg_qgis_fishpassage.json` is deleted. `xref_layers.csv` turned out to name database tables, not bucket objects, so #84 had compared it with the wrong artifact. `reg_qgis_restoration.json` was re-extracted from the template repo's v0.93.0, and a test now fails when `reg_main.json` is not rebuilt from its sources (in place of #11's bot commit).

Three `/code-check` rounds ran. Round 3 found a defect inside round 2's fix, and the loop ended on an enumeration of every claim the fixes wrote. Both reviews kept finding the same mechanism: published text stating a scope, count or behaviour that nothing ran against the code.

## Measurement

- **Bittner watershed by measure** (`fwa_watershedatmeasure(356342733, m)`):

  | measure (m) | area (ha) | river polygon inside (ha) |
  |---|---|---|
  | 0 | 5,600 | |
  | 5-100 | 5,267 | 952 |
  | 125-150 | 5,144 | 844 |
  | 165.97 (segment boundary) | 5,128 | 844 |
  | 166.97 (boundary + 1 m) | 4,008 | 0 |

  The lowest 166 m segment lies inside the Fraser's river polygon.
- **Re-pulled data:**
  - PSCIS: 95 → 23 assessments, 10 inside the watershed (12 counted inside before, one of them on the Fraser).
  - Streams: 150 → 36 segments.
  - Roads: 5,576 → 2,849 segments.
- **Re-extract semantic compare:** same 48 layers, only bcfishobs `source_layer` differs, plus 11 note dashes. Layer order changed, so `reg_main.json` reordered without a content change.
- **R CMD check:** 0 errors, 0 warnings, 0 notes before and after (1,268 → 1,293 passes).

## Owed

- `/gh-pr-merge` ticks move 3 in `planning/backlog.md` and does the release bookkeeping (version bump, tag).
- Set the GitHub About text drafted in Phase 4, "One set of map styles for QGIS field projects, report figures and web maps." (`gh repo edit NewGraphEnvironment/gq --description`) (G9).
- Close #84 with the corrected premise (the database tables, not the bucket). Close #11 with a note that a test replaced the proposed Action and that its source file names are obsolete.

Closed by: PR for #102 (branch `102-move-3-package-face-and-check-gate-batch`)
