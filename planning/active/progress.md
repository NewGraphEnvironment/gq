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
- Next: Phase 1 — `data-raw/styles_vendor.R`
