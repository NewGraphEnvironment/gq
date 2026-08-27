# Progress — Vignette maps are correct but do not communicate (#61)

## Session 2026-08-26

- Re-rendered both vignettes and **read the figures** before filing. The
  composition map's most prominent feature — a 397-feature red salmon-habitat
  network — was absent from the legend.
- Checked one claim before asserting it: the purple `Unknown` crossing entry
  looked like a phantom legend row. There is exactly 1 `UNKNOWN` crossing in the
  data. The legend is honest. Recorded in the issue so it is not re-raised.
- Traced the self-contradictory `ACCESS;*` labels to the QML corpus itself —
  gq extracted them faithfully. Already tracked upstream in bcfishpass#13, and
  duplicated in gq#33 and gq#37; worked around independently in three consumer
  repos.
- Plan-mode exploration; phases approved by user.
- Created branch `61-vignette-maps-are-correct-but-do-not-com` off main.
- Next: Phase 1 — correct the ACCESS labels at registry build time.
