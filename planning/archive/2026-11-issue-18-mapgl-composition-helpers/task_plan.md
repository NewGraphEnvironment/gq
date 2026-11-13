# Task: Add mapgl composition helpers (#18)

gq styles mapgl layers (`gq_mapgl_style()`, `gq_mapgl_classes()`) but does not compose the map
around them. Callers build the rest by hand. knowledge's `knw_compare_mapgl()` is the working
example: about 50 lines that choose a basemap, add registry-styled water, scale stream width by
stream order, add one categorical legend per layer, and add a layer toggle. A second caller, a map
of fish sampling sites over a stream network with one toggleable layer per species, is about to
need the same pipeline.

## Decided at the gate (2026-11-12, user)

- **#107 is folded in.** Phase 1 adds per-class opacity to mapgl and closes #107 in this PR.
- **Proof of "no visible change":** a gq test rebuilds `knw_compare_mapgl()`'s map from the
  helpers and asserts the widget spec (`m$x`) is `identical()` to the hand-built one, with the
  hand-built construction copied into the test as a fixture. The real knowledge rewrite is a
  knowledge issue, filed after the gq release.
- **Second caller:** the bundled Neexdzii Kwa fish observations and streams (above).

## Design notes (from exploration)

- mapgl stays in `Suggests`. Each helper errors early with a clear message when mapgl is missing,
  as `gq_tmap_keymap()` does for tmap. Examples use `@examplesIf requireNamespace("mapgl")`.
  Building a widget needs no network, so the examples run.
- Each helper takes a map and returns it, so the helpers pipe (`gq_mapgl_basemap(...) |>
  gq_mapgl_network(...) |> gq_mapgl_layer(...) |> gq_mapgl_controls()`).
- `gq_mapgl_layer()` styles from a registry key **or** from caller classes (`values` + `colors`).
  knowledge's rule and grade classes are not registry layers. It also takes a source id, so two
  layers share one source as in knowledge, and it supports `visibility = "none"`.
- **Hex only.** R colour names become hex before they reach MapLibre, and `NA` errors. MapLibre
  drops a whole layer on `grey80` (cartography convention).
- Coordinates go to EPSG:4326 and are rounded to `digits`, with knowledge's `.round_sfc()` moved
  in as an internal helper. This is what sets the page size.
- The basemaps are `voyager`, `openfreemap`, `esri_topo` and `positron`. knowledge's
  `.esri_topo_style()` moves in with its attribution string, and positron is what the eDNA and
  link maps use.
- The popup is built from a mapgl expression (`concat` / `get`), not a per-feature HTML string.
  knowledge measured the string form at more than double the page size. A missing value shows as
  `"none"`.
- `gq_mapgl_controls()` toggles the layers that were added: a named vector of labels to layer ids.
  Its navigation and scale controls are on by default.
- Leave `gq_mapgl_classes()`'s unused `property` argument alone except where Phase 1 gives it a
  meaning.

## Phase 1: Per-class opacity in mapgl (#107)
- [x] Failing tests: `bec_zone` gives a `fill-opacity` of 0.25 (a scalar: every class shares it).
      A mixed-opacity layer gives 1 for the classes that carry no opacity. A line layer gives
      `line-opacity`.
- [x] Implement it in `R/gq_mapgl_style.R`: `gq_mapgl_classes(layer, property =)` builds the
      opacity match when `property` ends in `-opacity`, and reads `NA` as 1, as
      `tmap_alpha_args()` does.
- [x] Update the roxygen and an example. The commit says `Fixes #107`. (NEWS is written at
      merge by `/gh-pr-merge`, so the branch leaves it alone; the PR body carries the note.)

## Phase 2: Basemap and network
- [x] Tests first. `gq_mapgl_basemap(bbox_or_sf, basemap =)` returns a `maplibregl` widget with
      the expected style and bounds. `esri_topo` carries the attribution. An unknown basemap
      errors.
- [x] `R/gq_mapgl_basemap.R` holds the basemap, the internal esri style helper and
      `round_sfc()`.
- [x] Tests first. `gq_mapgl_network(map, streams =, water =, reg =, order_field =, widths =)`
      adds a water fill styled from registry `lake` and stream lines whose width is an
      `interpolate()` on stream order. Either input may be `NULL`.
- [x] `R/gq_mapgl_network.R`.

## Phase 3: Layers, legends, popups, controls
- [x] Tests first. `gq_mapgl_layer()`:
      - draws a registry key and a classified registry key, and gives a classified registry
        layer its per-class opacity from Phase 1;
      - draws caller classes (`values` + `colors`);
      - converts R colour names to hex;
      - takes a shared source id and `visibility = "none"`;
      - adds the categorical legend tied to `layer_id`, with a unique legend id;
      - has a circle-radius expression for point layers.
- [x] `R/gq_mapgl_layer.R`.
- [x] Tests first. `gq_mapgl_popup(x, fields)` (named labels to columns) returns the properties
      and the `concat` expression. A missing value reads `"none"`, and numbers keep their
      formatting per value.
- [x] `R/gq_mapgl_popup.R`.
- [x] Tests first. `gq_mapgl_controls(map, layers =, position =)` adds navigation, scale and the
      layer toggle for the named layers.
- [x] `R/gq_mapgl_controls.R`.

## Phase 4: Prove both callers
- [x] `tests/testthat/test-gq_mapgl_compose.R` builds the knowledge fixture by hand and with the
      helpers on a small synthetic segment set, and checks `expect_identical(helper$x, hand$x)`.
      A restore-the-bug check proves it can fail: change one colour or one width and watch it go
      red.
- [x] A second-caller test builds the bundled Neexdzii fish observations, one layer per species,
      over the streams and lakes in a few calls. It checks one layer and one legend per species
      present, and a toggle listing them all.
- [x] New article `vignettes/gq-mapgl-composition.Rmd` covers the Neexdzii species map and a short
      classified-layer example, written per `writing.md` (answer first, plain terms).

## Phase 5: Docs and release prep
- [x] `devtools::document()`, the examples for all five exports, `lintr` with a per-file
      comparison against main, and the README / CLAUDE.md function lists (the Components list
      gains the composition (mapgl) entries).
- [x] CLAUDE.md: drop "mapgl does not read per-class opacity yet (gq#107)" (review 12), add the
      mapgl composition functions, and name the known gaps: classified registry layers carry no
      per-class width or dash in mapgl, and a registry point shape draws as a circle (review 19).
- [x] Legend coverage (review 13): the new article either legends what `gq_mapgl_network()` draws
      or `test-vignette_legend_coverage.R` records why it is exempt.
- [x] NEWS: none on the branch; the PR body's summary is what `/gh-pr-merge` writes from.

## Owed at the end (reported, done after merge)
- [ ] File a knowledge issue: rewrite `knw_compare_mapgl()` on gq's helpers and pin gq to the
      release.
- [ ] Draft (not post) an upstream mapgl issue: `add_layers_control()` stores a named layer vector
      that jsonlite flags for future array serialisation; and `add = TRUE` legends overprint.
      Check mapgl's open issues first; show the draft to the user.
- [ ] Note the eDNA reporting maps as later callers in that issue or a gq comment. Do not file in
      each repo.

## Validation
- [x] Tests pass (`devtools::test()`, 0 failures)
- [x] `/code-check` clean (once over the branch with `/code-check branch`)
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion

**How each change is proved:**
- **Opacity:** `bec_zone` gives 0.25, and the mixed layer carries 1 where a class
  has no opacity.
- **knowledge parity:** the widget spec is `identical()`, and the mutation turns it red.
- **Second caller:** the test counts layers and legends against the species present in the data.
- **In the browser:** save the vignette's maps and the knowledge-parity map with
  `htmlwidgets::saveWidget()`, open them in Chrome, and check that the console has no
  `Could not parse color` or `Cannot style non-existing layer`. Every toggle shows and hides its
  layer and its legend. Popups open with values.
- **Package checks:** `devtools::check()` with no new NOTE, and the article renders under
  pkgdown.


## Context (from the plan)

**Done when:** `knw_compare_mapgl()` can be rebuilt on the helpers with no visible change, and the
second caller's map takes a few calls.

**Second caller, settled at the gate:** fish observations as one toggleable circle layer per
species, over a stream network. It is built from data **already bundled**: `neexdzii_fish_obs`
(63 FISS points, 14 species, WGS 84), `neexdzii_streams` (1,074 FWA segments, `stream_order` 1–6)
and `neexdzii_lakes`. No database and no new data. `edna_map.R` is a shape reference only.

