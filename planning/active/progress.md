# Progress — Three local layers grouped and shipped with no registry entry (#64)

## Session 2026-08-29

- Plan-mode exploration — two subagent surveys (rfp form artifacts, and the
  `restoration_wedzin_kwa` / Nelson projects). Phases approved by user.
- Established that the issue body's two premises were wrong: the forms are real
  (rfp ships gpkg + QML for both, with collected field data in live Mergin
  projects), and theme absence is not a staleness signal (30 of 64 keys are
  absent from `themes.csv`).
- Established the design constraint: forms are injected per-project by
  `rfp_qgs_form_add()`, so a 12-row `Forms` group in `groups.csv` would
  reintroduce gq#40's defect at 6x scale. Roster goes in its own vendored table.
- Created branch `64-three-local-layers-no-registry-entry` off main.
- Scaffolded PWF baseline with approved phases.
- Next: Phase 1, vendor rfp's form roster.
