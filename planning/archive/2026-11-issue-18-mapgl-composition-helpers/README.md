## Outcome

gq#18 added five MapLibre GL composition helpers, `gq_mapgl_basemap()`, `gq_mapgl_network()`,
`gq_mapgl_layer()`, `gq_mapgl_popup()` and `gq_mapgl_controls()`, extracted from knowledge's
`knw_compare_mapgl()`, and folded in gq#107 (per-class opacity through
`gq_mapgl_classes(property = "*-opacity")`). A test rebuilds knowledge's map on the helpers and
asserts the widget spec is `identical()` to a copy of the original (knowledge eac16623), seeded
because mapgl names its layer switch with `sample()`. The second caller is the bundled Neexdzii Kwa
fish observations, one switchable layer per species, drawn in a new article. Checking it in a
browser showed that mapgl draws every legend at the same corner, one over another, and that a
legend id with a space escapes mapgl's CSS. gq now adds a stylesheet beside the spec to stack the
legends, and makes legend ids CSS-safe. Five review rounds then showed that guards written for one
form of an argument let the other forms through to wrong maps with no error. That ended in a
restructure: `gq_mapgl_layer()` checks the data it draws, whether it comes as `x` or as an inline
GeoJSON source already on the map, and `gq_mapgl_network()` draws through it.

## Measurement

- Knowledge parity: `identical(ours$x, hand$x)` on voyager and esri_topo, with water and without.
  The one visible difference is that legends now stack when both layers are switched on, an
  improvement. Mutants that pass no `unique_id`, always set `add = TRUE`, or remove the hex
  passthrough all turn the test red.
- Projected bbox: fitted by its four corners, a provincial BC Albers box lost 45 km off the north
  (59.873° against 60.283°). It is now densified first.
- Enumeration that ended the review: 52 of 54 `stop()` sites in `R/gq_mapgl_*.R` are reached by a
  test, measured by instrumenting a worktree copy. The two not reached are the missing-mapgl
  message and an internal sf check that every exported caller makes first.
- Review: 5 rounds, finding 4, 4, 9, 4 and 2 defects, all fixed. Rounds 2 to 5 each found defects
  inside the previous round's fixes. With the plan review, that is 6 reviewer agents.
- Final: `devtools::test()` 1542 expectations, 0 failed; `devtools::check()` 0 errors, 0 warnings,
  0 notes.

## Owed

- File a knowledge issue: rewrite `knw_compare_mapgl()` on gq's helpers and pin gq to the
  release. (A draft is ready; file it after the gq release.)
- Draft (not post) an upstream mapgl issue: `add_layers_control()` stores a named layer vector
  that jsonlite flags for future array serialisation; and `add = TRUE` legends overprint.
  (mapgl issue 45 added `add = TRUE`; no open issue covers the overprint.)
- Note the eDNA reporting maps as later callers in that issue or a gq comment. Do not file in
  each repo.

Closed by: PR for branch `18-add-mapgl-composition-helpers` (Fixes #18, Fixes #107)
