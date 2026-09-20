# Progress — Re-vendor inst/styles/ (#90)

## Session 2026-09-20

- Plan-mode exploration — read `data-raw/styles_vendor.R`, `test-gq_style_qml.R:167-202`,
  issue #86, and the rfp store. Phases approved by user.
- Independently reproduced every claim in #90 before touching anything: 60 files
  checked, 2 drifted, exact diffs recorded in `findings.md`.
- Created branch `90-re-vendor-inst-styles-rfp-has-repaired` off main (level with origin).
- Scaffolded PWF baseline.
- Next: Phase 1 — re-vendor.
