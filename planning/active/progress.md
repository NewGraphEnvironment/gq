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
- **Phase 3 done** — `R/gq_tmap_legend.R`. Suite at 491 pass / 0 fail.
- Merges simple and classified layers into one group per geometry type, which
  is the thing the hand-written pattern gets wrong: `railway` + `roads_dra`
  becomes a single 27-entry `lines` legend rather than two calls.
- Reads the *flattened* classification from `gq_tmap_classes()` rather than
  `gq_style()$classification`, which is the nested per-class form. Getting that
  backwards produced an empty legend, not an error.
- Avoided the package's own `%||%` (`gq_qgs_extract.R:393`) — its `is.na()` test
  errors on a vector, and several of these values are vectors.
- An aesthetic absent from every row is dropped rather than passed as all-NA,
  since tmap reads an explicit NA as "draw nothing" for some aesthetics.
- `lintr` reports `dash_to_lty` unresolved. Artifact, not a defect: the
  installed gq is **0.0.0.9000** and lacks it, while `to_title` and
  `tmap_line_args` resolve. That is the `exists(..., asNamespace())` diagnostic
  from `code-check.md`; it clears on reinstall.
- Next: Phase 4 — keymap
- **Phase 4 done** — `R/gq_tmap_keymap.R`. Suite at 527 pass / 0 fail.
- The placement arithmetic is an `@noRd` pure function, so the corner maths is
  tested without a graphics device. A viewport is positioned by its *centre*,
  which is why every copy of this carries different-looking magic numbers that
  all mean "bottom right, a bit in from the edge" — asserted directly: growing
  the inset must not change its distance from the frame.
- Colours come from the registry. All five existing copies hardcode hex here,
  including `lfpr_keymap_survey()`, which takes `reg` as an argument and never
  reads it.
- Next: Phase 5 — prove it against fraser
- **Phase 5** — the proof, and one honest scope change.
- The planned pixel baseline is **not achievable here**. `lfpr_map_site()` needs
  globals (`wshds`, `habitat_confirmation_tracks`) that only exist after
  fraser's upstream reporting pipeline has run, and that needs the database.
  `0410` refuses to run without `update_gis`, by its own guard.
- What replaced it is stronger and cheaper: **numerical equivalence against the
  fraser originals on fraser's real cached rasters**, no DB and no network.
  Copied the three originals verbatim out of `0420`, ran both implementations
  over all four sites, compared. Aspect and scale breaks identical; blend
  **max|diff| exactly 0 across 14.7M cells**. Bit-identical, not approximately.
- The `0420` rewrite is **deferred to a follow-up PR**: fraser installs gq from
  GitHub, so these functions have to land first. Filing it rather than leaving
  it implicit.
- `tm_scalebar()` contradiction settled: it renders fine in **4.4.1**. The
  archived note's crash (`object 'sbW' not found`) was specific to 4.2, which is
  also why the merged vignette calls it without trouble.
- The vignette's `st_set_crs(4326)` was a no-op rather than a live bug —
  `neexdzii_wsd` is already 4326. The replacement inherits the CRS, so it stays
  correct if the data ever moves.
- Vignette basemap chunk rewritten onto the helpers and verified end to end:
  tiles fetch, blend yields a 3-band stars, tmap renders it.
- Next: Phase 6 — docs, skill drift, release
