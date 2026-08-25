# Progress — tmap composition helpers (#17)

## Session 2026-08-24

- Resumed #17, whose PWF was archived earlier today as *paused, not complete*.
  Its Phase 1-2 (data + vignette) shipped in PR #26; Phase 3-4 never started.
- Three Explore agents established the scope: the generic helpers in fraser's
  `0420-map-site.R`, gq's own vignette, and the cartography skill are the same
  four or five procedures written three to five times each.
- Scope put to the user rather than assumed: **six helpers**, proven by
  refactoring fraser's `0420` rather than by a round trip through gq's own
  vignette (which is where two of them came from, so it cannot detect a
  behaviour change).
- Created branch `17-add-tmap-composition-helpers-and-composi` off main
- Scaffolded PWF baseline with approved phases
- Next: Phase 1 — pure geometry core
- **Phase 1 done** — `R/gq_bbox.R` (`gq_bbox_aspect`, `gq_bbox_clip`),
  `R/gq_scale_breaks.R`. 47 assertions, 0 fail, lintr clean.
- The latitude branch is asserted in both directions rather than described: a
  1x1 degree box at 54.5N pads its *x* axis while the same numbers in EPSG:3005
  pad nothing, because the ground ratio and the coordinate ratio differ by
  `cos(lat)`. That is the disagreement between the two implementations this
  replaces, and neither knew it was conditional.
- `st_is_longlat()` returns NA on an unknown CRS, so the branch uses `isTRUE()`
  and falls to projected. Pinned by a test that asserts the NA and then asserts
  no NA reaches the output.
- `gq_bbox_clip()` keeps select-vs-cut distinguishable (`crop=`), tested on a
  line crossing the boundary where the two give lengths 10 and 1.
- Next: Phase 2 — basemap blend
- **Phase 2 done** — `R/gq_basemap_blend.R`: `gq_basemap_blend()` +
  `gq_basemap_tiles()`, with the arithmetic in an `@noRd` `blend_multiply()`
  testable on synthetic rasters. 18 assertions, no network.
- **The four blend copies are not the same arithmetic**, contrary to what
  fraser's `lfpr_basemap_blend()` docstring asserts ("the same operator as the
  vignette; only the relief source differs"). The vignette and SKILL.md use
  `base * relief^0.5` — a gamma. fraser uses `base * (1 - 0.35*(1 - relief))` —
  a linear cap, because its relief is a DEM hillshade rather than a tile
  service and is far more contrasty. Both ship, both named, both tested to
  differ (141 vs 165 out of 200 at mid-grey).
- Relief scale is detected, not assumed: `terra::shade()` returns 0-1 and a tile
  service returns 0-255, and treating one as the other either blackens the map
  or does nothing.
- First `skip_if_not_installed()` in this suite, as expected.
- Next: Phase 3 — legend
