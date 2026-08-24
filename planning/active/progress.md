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
