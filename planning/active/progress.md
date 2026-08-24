# Progress — Host the canonical QML corpus (#39)

## Session 2026-08-24

- Plan-mode exploration — two Explore agents (gq extraction/registry layout, rfp
  QML machinery). Found #39's premise superseded by rfp#174 Phase A.
- Scoping decision put to the user: host in gq / accessor only / close as
  satisfied elsewhere. **Chose: host in gq**, with rfp keeping its copy for now
  and a follow-up rfp issue to repoint its builder.
- Measured before planning: slugifier agreement (0 disagreements over 53 names),
  roster overlap (45/50), and the unindexed `osm.trail.qml` leftover.
- Created branch `39-host-the-canonical-qml-corpus-so-qgis-st` off main
- Scaffolded PWF baseline with approved phases
- **Phase 1 done** — `data-raw/styles_vendor.R`, 62 files into `inst/styles/`
  (53 vector, 6 service, 3 raster), 3.4 MB. Verified idempotent by tree digest
  (`md5`, not `diff -q` — that is a shell function here delegating to `git diff`).
- Guard proven against both answers: it aborted on `vector/osm.trail.qml`
  (real, unindexed upstream) before I declared that one exception with a reason,
  and passed after. An alarm nobody has seen fire is decoration.
- Measured en route: `(layer_key, template)` has **zero** collisions across the
  53 index rows, so the schema needs no styleName-style discriminator. The 3
  doubled keys are exactly the shared+override pairs.
- Next: Phase 2 — `gq_style_qml()`
- **Phase 2 done** — `R/gq_style_qml.R`: `gq_style_qml(layer_key, template)`
  plus `@noRd` `read_styles_index()` / `styles_path()` / `styles_rel()`.
  Location is derived from scope rather than stored, so the index cannot
  disagree with the layout.
- Near-miss suggestions rank by `adist()`, not `agrep()`. agrep's max.distance
  is a fraction of the *pattern*, so a short key matched loosely into long ones
  and buried the answer — "lakes" suggested `habitat_lateral` before `lake`.
- `devtools::run_examples()` executes the whole `@examples` block.
- Next: Phase 3 — guards
- **Phase 3 done** — `tests/testthat/test-gq_style_qml.R`, 101 assertions.
  Suite 390 pass / 0 fail.
- The drift test failed first time against the INSTALLED rfp (0.25.1, 3 raster
  QMLs, no store) and reported 59 false drifts. That is the installed-vs-source
  trap `reg_extract_themes.R` already warns about; the test now takes
  `RFP_STYLES_DIR` first and skips when upstream predates rfp#174. Verified both
  answers: skips on installed, 101 pass against the checkout.
- `WARN 1` in `test-gq_registry_read.R:25` is baseline — untouched by this
  branch, fires in isolation.
- `lintr` clean on all three new files.
- Next: Phase 4 — build and docs
