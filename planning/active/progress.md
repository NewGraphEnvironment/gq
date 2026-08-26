# Progress — classified layers lose every axis except colour (#36)

## Session 2026-08-26

- Plan-mode exploration; phases approved by user
- Measured the defect per feature: streams_bt draws spawn/rear/access all at
  1.70 when the registry says 1.70/1.00/0.40
- Found dash is the same defect one step worse — the legend already emits
  per-class `lty` while the map never has, so the two disagree today
- Confirmed #36 item 3 (unknown values abort) was fixed by #54; item 2
  (`labels` unnamed) split to its own issue
- Verified the per-axis scale fix works per feature before committing to it
- Created branch `36-classified-layers-lose-non-colour-axes` off main
- Next: Phase 1 — failing tests
