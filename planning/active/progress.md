# Progress — Add mapgl composition helpers (#18)

## Session 2026-11-12

- Plan-mode exploration — phases approved by user
- Created branch `18-add-mapgl-composition-helpers` off origin/main
- Scaffolded PWF baseline from issue #18 with approved phases
- Next: start Phase 1
- Phase 1 (#107): `gq_mapgl_classes(layer, property = "*-opacity")` builds per-class opacity,
  absent read as 1, a scalar when all classes share one. 5 new tests; file 39 pass.
- Plan correction: NEWS is written at merge by `/gh-pr-merge`; no NEWS edits on the branch.
- Phase 2: `gq_mapgl_basemap()` (voyager, positron, openfreemap, esri_topo) and
  `gq_mapgl_network()` (water from `lake`, streams from `streams_all`, width by order); internal
  `mapgl_need()`, `check_digits()`, `mapgl_geom()`, `mapgl_data()`, `round_sfc()`,
  `esri_topo_style()`, `order_width()`, `reg_layer()`. 33 tests pass.
- Found: `maplibre(bounds =)` reduces an `sf` to its bbox but stores an `sfc` raw, so the basemap
  wraps the geometry in an `sf`.
- Plan review (Plan agent) landed as Phase 3 began: `planning/active/review-plan.md`. Already met
  by the Phase 3 draft: 2, 4-9 (fixed legend ids, computed `add`, `width` column, typed classes,
  hex passthrough, typed adders, source sharing). Taken now: 17 (property check restricted to
  `^(fill|line|circle)-(color|opacity)$`, test added), 15 (plan text). Folded into the plan: 12,
  13, 19 (Phase 5), 1/3/11/21/22 (Phase 4 parity test: seeded, controls off, water in fixture,
  default-removal mutation). 16 (14 stacked legends) is checked in the browser in Phase 4.
- Phase 3: `gq_mapgl_layer()` (registry key / caller classes / one colour; shared sources; width
  by order; legend tied by id with computed `add`; hex conversion that leaves hex as typed),
  `gq_mapgl_popup()`, `gq_mapgl_controls()` (navigation and scale switchable). gq's `%||%` is
  scalar-only (it calls `is.na()`), so the mapgl files use an internal `or_null()`.
- Phase 4 box 1 (parity): `fixtures/knw_compare_mapgl.R` is knowledge eac16623 lines 147-327 minus
  the `chk::` checks; `test-gq_mapgl_compose.R` asserts `identical(ours$x, hand$x)` under
  `withr::with_seed()`, voyager and esri_topo with water, and voyager with none. Passed on the
  first full run.
- Mutation table (each restored and `cmp`-checked after):

  | mutant | caught by |
  |---|---|
  | legend `unique_id = NULL` | parity (2 failing) |
  | legend `add = TRUE` always | parity (2) |
  | classes default `#cccccc` -> `#888888` | layer unit test (1); parity cannot see it (knowledge passes its default) |
  | hex passthrough removed (all colours via col2rgb) | layer unit (2), parity (2) |
  | popup NA not replaced | popup unit (2) |
- Phase 4 boxes 2-3: second-caller test (Neexdzii species map in a few calls; layers, legends and
  feature counts per species) and `vignettes/gq-mapgl-composition.Rmd` (species map; assessed
  crossings from `crossings_pscis_assessment` with `field = "barrier_status"`; limits).
  Species shown: the salmon, trout and char whose FISS codes resolve in a FISS species table
  (RB, BT, CO, DV, CH, ST, CT); GR, SB, TR were not in it and are left out rather than guessed.
- Browser check (Chrome, local http server, mapgl 0.4.4.9000):
  - mapgl draws every legend absolutely at the corner, so a second legend overprints the first.
    knowledge's map does this too when both its layers are on. Fix: a stylesheet gq prepends
    once (`map$prepend`, outside `m$x`, so parity holds) that lets legends flow; a hidden
    layer's legend leaves no gap (checked by switching rainbow trout off).
  - A legend id with a space ("legend_rainbow trout") is not a CSS selector, so mapgl's own
    styles missed it (no swatch). Legend ids are now sanitised; the `data-layer-id` keeps the id.
  - A one-colour legend repeated its name as title and row; it is now one untitled row.
  - A registry legend listed POTENTIAL on a map that filters it out; the legend now lists only
    classes present in `x`.
  - Article maps were 288 px tall and clipped the legends; now `fig.height = 7` (672 px).
  - Popups open with values and `none` for a missing life stage. Console: no `Could not parse
    color` / `Cannot style non-existing layer`. knowledge parity map with both layers on: the two
    legends stack.
  - mapgl's named layer switch makes jsonlite print a future-deprecation message when the page is
    written (knowledge's map too). Not worked around: changing it would change the spec. Owed:
    an upstream draft for mapgl.
- `gq_mapgl_network(legend = TRUE)` added (review 13): one-row legends `Lake` and `Stream`,
  off by default for parity.
- Phase 5: CLAUDE.md (Composition (mapgl) block, the #107 sentence, the legend stylesheet, known
  gaps, a usage example) and README Learn more. Legend coverage: the article passes
  `legend = TRUE` to the network, so lakes and streams are in its legend; the tmap-only
  `test-vignette_legend_coverage.R` is not extended to mapgl.
- Lint, per file/linter/line against an `origin/main` worktree: 2 new rows. Fixed the test's
  `[[which(ids == k) ]]`; the other is in `fixtures/knw_compare_mapgl.R`, a verbatim copy of
  knowledge, left as copied (there is no `.lintr` to exclude it with).
- `/code-check branch` round 1 (`review-round1.md`): 2 bugs, 2 fragile, all reproduced, all fixed,
  each new test shown red on the pre-fix tree:
  - legend look-collapse ran before the present-class filter (roads_dra RH1 alone errored);
  - `gq_mapgl_popup()` overwrote the columns it read, so a styled column reached MapLibre as text;
    it now writes `popup_1..n`;
  - a projected bbox was fitted by its corners (45 km short of a provincial view); densified first;
  - an unstyled registry layer drew in MapLibre's default colour; now refused.
- Round 2 (`review-round2.md`): 2 bugs, 2 fragile; two INSIDE round 1's bbox fix (a one-point
  projected bbox now errored; an sfc/sf of the same rectangle was still fitted by its corners).
  Fixed: `densify_extent()` for any projected input, skipping points and zero extents; a
  registry layer whose classification field is not a column of `x` is refused (it drew all grey
  under a legend of every class); a duplicate source or layer id is refused (MapLibre throws
  and drops everything after it), in `gq_mapgl_layer()` and `gq_mapgl_network()`. Parity still
  identical with the densified bounds. New tests red on the pre-fix tree.
- Round 3 (`review-round3.md`, mechanism + enumeration): 5 bugs, 4 fragile, every one a round-1/2
  fix missing from a sibling form of an argument. Mechanism named by the reviewer: each guard was
  attached to the form of the argument in front of the fix, not to the outcome it protects.
  Structural fix rather than per-row patches:
  - `gq_mapgl_layer()` now checks the data it draws, from `x` or parsed from the GeoJSON source
    already on the map (`source_frame()`): geometry decides the type (`layer_type()`, a given
    `type` must agree); every `["get", col]` in colour, opacity, width and popup must name a
    column, and a `match` must compare like kinds (`check_reads()`); the registry field check
    and legend filter read the same data.
  - `gq_mapgl_network()` now draws both layers through `gq_mapgl_layer()` (a second registry
    translation had skipped every check), with `type` pinned to fill and line.
  - all-empty extent refused in the basemap; a partly named switch gets the ids as labels.
  Parity still identical; new tests red on the pre-fix tree; article re-rendered.
- Round 4 (`review-round4.md`, terminal enumeration): all nine round-3 SW rows now REF/OK by
  probe; parity green. 1 bug, 3 fragile, all inside round 3's restructure: a tile/PMTiles source
  was refused and a GeoJSON URL source was fetched by R (both drew before); `type = "line"` over
  polygons was refused; `width`/`radius` expressions and an `opacity` override skipped
  `check_reads()`; boolean class labels passed (MapLibre rejects them). Fixed: `source_frame()`
  returns NULL for anything but inline GeoJSON and the layer is drawn as told (type from `type` or
  the registry key, never fetched); line-over-fill allowed; every paint argument goes through
  `check_reads()`; TRUE/FALSE classes refused. Network roxygen legend text corrected.
