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

## Session 2026-08-26 (continued)

- Phase 1 `bfdc631` — drawn_gp() helper + 5 failing tests
- Phase 2 `b11fc2e` — per-class lwd/lty/size via tmap_scale_axis()
- Phase 3 `b7dae0a` — registry width sweep + map-vs-legend dash agreement
- Phase 4 `dc963a0` — restore-the-bug, 27 failures / 0 errors
- Phase 5 — vignette prose, NEWS + DESCRIPTION 0.5.1 → 0.6.0, #55 filed
- Verified against shipped data: salmon habitat draws 0.4/1.0/1.7 and both dash
  states; roads 0.46/1.035
- FAIL 0 | PASS 829; check 0 errors, same 2 warnings + 2 notes as main
