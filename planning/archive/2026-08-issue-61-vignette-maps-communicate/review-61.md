# Review — task plan for #61 (vignette maps / ACCESS labels)

Plan agent, 2026-08-26. Reviewed against branch
`61-vignette-maps-are-correct-but-do-not-com`. The tree changed under the
reviewer mid-review (Phase 1 landed uncommitted); findings reflect the later
state.

**1 Blocker · 7 Gap · 3 Ordering · 8 Assumption · 4 Scope · 3 Acceptance (26)**

## Blocker

**B1 — Phase 3's dead-band premise is false; acting on it would damage a correct
function.** The plan said `gq_bbox_aspect()` "put nearly all the 7:9 slack on one
side". It pads symmetrically (`R/gq_bbox.R:76-82`). Measured on the real data:

```
pad bottom: 0.06415504   pad top: 0.06415504   (21.7% of frame each)
pad left:   0.00763595   pad right: 0.00763595
```

`neexdzii_wsd` is ~1.32:1 landscape; the requested canvas is 7:9 portrait, so
41% of frame height is pad, split exactly in half. The observed band above has
an identical twin below — hidden because the legend occupies it. Cause is the
aspect *choice*, not the function. Taking the checkbox literally would introduce
an asymmetry into an exported function and break `test-gq_bbox.R`.

CONFIRMED independently before acting. Plan, findings and the issue body were
corrected.

## Gap

- **G1** Phase 1 landed uncommitted while PWF still said "Next: Phase 1".
  Implementation is *broader* than planned (loops every layer carrying an
  `^ACCESS;` class rather than three named) — better; the plan text was updated
  to match the code rather than the reverse.
- **G2** `inst/registry/reg_qgis_restoration.json` and
  `reg_qgis_fishpassage.json` still carry 30 bad labels each, are shipped under
  `inst/`, and are reachable via `gq_reg_read(system.file(...))`.
  `reg_qgis_fishpassage.json` has **no generator script** and cannot be
  regenerated. Recommendation: leave both uncorrected as faithful extraction
  artifacts, but *state* the decision and say in NEWS that `gq_reg_main()` is
  the corrected surface.
- **G3** `gq_qgs_extract()` is exported and bypasses the correction by design —
  the extractor must stay faithful. Write that decision down; gq#37's wording is
  ambiguous between "fix the extractor" and "fix the registry".
- **G4** The QML corpus keeps the bug and must: `test-gq_style_qml.R:167-201`
  asserts byte-identity with rfp's store. So `gq_reg_main()` will say
  "Accessible" while `gq_style_qml()` hands back a file saying "No known
  barriers". No R function surfaces QML label text, so there is no user-visible
  R inconsistency — but QGIS Desktop / QWC2 / `layer_styles` consumers get the
  bug. One NEWS sentence, one comment on bcfishpass#13.
- **G5** `registry/registry.json` at repo root is dead — `.Rbuildignore`d,
  referenced by no code or workflow, superseded by
  `inst/registry/reg_qgis_restoration.json`. It holds 30 more copies of the bad
  label as a fossil. Worth deleting so a future grep does not re-find a fixed
  bug.
- **G6** The Phase 1 restore-the-bug check has no committable form: the
  correction is inline script code `testthat` cannot reach. Either record the
  manual result, or extract `correct_access_labels(reg)` into `R/` as an
  internal and test both directions.
- **G7** Phase 2's guard is under-specified. Wrapping every `gq_tmap_style()`
  call in a recording helper was rejected — the map chunk is documentation and a
  bespoke wrapper makes the example dishonest about the API. Scraping the chunk
  source is right, with two details the plan omitted: scope it to the
  `map-composition` chunk (a whole-file scan picks up the `load-registry` demo
  chunk and the keymap's `gq_style(reg, "lake")` as false positives), and fail
  loudly when the chunk cannot be found rather than passing vacuously.

## Ordering

- **O1** Legend goes 14 rows → 21 with habitat added, in a framed bottom-left
  box at `legend.text.size = 0.5`. tmap already emits "Some legend items or map
  compoments do not fit well, and are therefore rescaled" in this repo's own
  test run. Phase 3's type sizing and legend placement belong with Phase 2.
- **O2** Phase 4's `bookdown::html_vignette2` switch changes the published
  column width, which is the input to Phase 3's type sizing. As sequenced the
  measurement is taken twice.
- **O3** Phase 6 notifies consumer repos before the version exists — word the
  comments against a released version.

## Assumption (verified)

- **A1 HOLDS** `reg_main.json` is written by `reg_build_main.R:21-22`; a
  hand-edit is lost on the next run.
- **A2 HOLDS, upgrade the reasoning.** The CSV route is *lossy*, not merely
  tedious: `gq_reg_custom()`'s classified branch (`R/gq_reg.R:100-124`) has no
  per-class dash and no per-class width field. Re-authoring there would silently
  drop the intermittent dashes (#36) and the three habitat widths (#16) the
  vignette prose specifically advertises.
- **A3 HOLDS** `legend_key()` hashes every row name including `label`, so
  same-colour rows do not collapse.
- **A4 HOLDS** A caller-supplied name is discarded for classified layers
  (`gq_tmap_legend.R:147` is in the unclassified branch). Write
  `"streams_salmon"` unnamed; a named form is a silent no-op.
- **A5 CORRECTION** There are **7** non-INTERMITTENT keys present, not 6, so the
  line legend is **13 entries, not 12**. Derive the list from the data rather
  than typing it.
- **A6 HOLDS** No existing test breaks — verified by grep across `tests/`,
  `vignettes/`, `R/`, `man/`, `NEWS.md`; no `_snaps/`. `test-gq_tmap_style.R`
  uses `streams_bt` but asserts colour/width/lty, never labels.
- **A7 HOLDS** 0.9.0 is right. NEWS must lead with the breaking-string framing,
  give exact old→new strings, and tell consumers to delete their decoders.
  `DESCRIPTION`'s `Date:` needs bumping alongside `Version:`.
- **A8 HOLDS** 10 bad labels per QML across the three layers.

## Scope

- **S1** With the implementation looping all layers, the "diff touches only
  those 30 labels" check — not the layer list — is the load-bearing
  verification.
- **S2** Split the NEWS entry: the registry label change is consumer-facing and
  must not be buried in map-composition prose.
- **S3** Phase 3's largest item has no stated decision. `neexdzii_crossings` is
  130 `POTENTIAL` of 146 (89%). Name the candidates now so Phase 5 has something
  to judge against.
- **S4** Phase 4's `gq-intro.Rmd` item is a rewrite, not a tweak: no
  `gq_tmap_legend()` call at all, no scalebar, no keymap, and still on the old
  `gq_tmap_style(reg$layers$lake)` signature. Only **12 of 95** crossings fall
  inside the AOI (13%). Consider splitting to its own issue.

## Acceptance

- **AC1** Dropping the `;INTERMITTENT` rows removes the single most-drawn class:
  `ACCESS;ASSESSED;INTERMITTENT` is 178 of 397 habitat features (45%), 2.7x the
  next. Defensible — same colour and width as its retained solid twin, dash
  explained in prose — but in tension with #61's headline complaint. Make it an
  explicit Phase 5 check: a reader must be able to trace a dashed red line to
  "Accessible; known barrier" without re-reading the body.
- **AC2** Phase 5 has no fail state. Add two gates: rank the top three by ink
  weight (expect habitat, crossings, roads) and confirm each is findable in the
  legend; and the legend renders without tmap's `component.autoscale` warning.
- **AC3** `test-reg_labels.R:16` is 81 characters.
