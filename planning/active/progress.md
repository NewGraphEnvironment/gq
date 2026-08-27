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

### Phase 1 — ACCESS labels corrected (commit beefd6f)

- Correction lives in `data-raw/reg_build_main.R`, not in `reg_main.json`: that
  file is a build artifact and a hand-edit is reverted on the next rebuild.
  `reg_custom.csv` was not viable either — `gq_reg_custom()`'s classified branch
  carries no per-class width or dash field, so re-authoring there would silently
  drop the three habitat widths (#16) and the intermittent dashes (#36).
- Restore-the-bug verified manually (the correction is script code testthat
  cannot reach): reverting `reg_main.json` to HEAD turned the new tests red, and
  the corrected file was restored to a matching md5.
- Obsolescence guard proved against both known answers: bug present corrects 30
  and builds; a pre-corrected source stops with instructions to delete the block.

### Phase 2 — legend coverage (this commit)

- Line legend is **13** entries, not the 12 predicted — `ACCESS;MODELLED` is
  present in the data too. The count came from running it, not from arithmetic.
- The coverage guard needed three attempts and each failure was instructive:
  regex-on-raw-source read `gq_tmap_style(reg, "name")` out of a markdown code
  span and swept comment prose into the legend set; then `names()` on a call
  with no named arguments is `NULL`, and `logical(0) | TRUE` is `logical(0)`, so
  every unnamed call subset to nothing and only the `field =` calls were found.
- **The first draft of the guard could not fail.** It listed all nine drawn
  layers as exemptions with the reason "drawn and legended", which exempts
  everything. Now `character(0)`, with a comment saying that empty is the
  correct state and why.

### Plan review (planning/active/review-61.md)

- 26 findings. **B1 was a blocker in my own claim**: I attributed the empty band
  above the watershed to `gq_bbox_aspect()`. It pads symmetrically — measured
  21.7% above and 21.7% below. The lower band is hidden under the legend. Acting
  on it would have introduced an asymmetry into a correct exported function.
  Corrected in the plan, findings, and the issue body.
- Confirmed before acting rather than accepting: the padding was re-measured
  directly, and AC3's line-length claim turned out to rest on an assumed lintr
  default — the repo already carries 30 lines over 80 and lints clean.
- Next: Phase 3 — outstanding decisions are the 130 `POTENTIAL` crossings (89%
  of point symbols) and the canvas aspect. G2/G5 (the other shipped registries,
  and the dead `registry/registry.json`) to be decided in Phase 3/6.

### Phase 3 — cartography (render-and-look)

Four renders. What each one taught:

- **v2 (containment + type)** — habitat legend labels legible for the first
  time, AOI reads as the subject. Two failures still obvious: the legend covered
  real watershed, and the orange still buried everything.
- **v3 (assessed crossings only)** — the change that mattered. Removing the 130
  modelled crossings made the salmon habitat network visible, which is the whole
  subject of the map.
- **v4 (legend top-left)** — a regression, and the useful one. Top-left is the
  emptier corner, so it looked like the right answer; hung from it, a 19-row
  legend covers the northwest arm and hides the barrier crossings. Reverted.
  "Least important terrain" has to be read off the rendered image.
- **final** — byte-identical to v3 (md5 confirmed), so the revert is exact.

Review gate AC2 passes: no `component.autoscale` rescale warning, so the legend
now fits the frame. It was firing before this phase.

Basemap deliberately left unchanged — the contrast complaint turned out to be
mostly a containment problem, and swapping provider to tick a box would be a
change without a render to justify it.
