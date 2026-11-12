# Findings — Add mapgl composition helpers (#18)

## Issue context

**If we do it:** an interactive map of any registry-styled data takes a few gq calls instead of a
hand-built mapgl pipeline, and every package's web maps share one basemap, legend and control
layout. **If we never do:** each package keeps its own copy of that pipeline, and the copies
drift apart.

## Problem

gq styles mapgl layers (`gq_mapgl_style()`, `gq_mapgl_classes()`) but does not compose the map
around them. Callers build the rest by hand. knowledge's `knw_compare_mapgl()` is the working
example: about 50 lines that choose a basemap (`carto_style("voyager")`,
`openfreemap_style("liberty")`, Esri topo), add registry-styled water, scale stream width by
stream order (`interpolate("stream_order", ...)`), add one categorical legend per layer, and
add a layer toggle (`add_layers_control()`). A second caller, a map of fish sampling sites
over a stream network with one toggleable layer per species, is about to need the same
pipeline.

The tmap composition helpers this issue was waiting on have landed (#14, closed).

## Proposed Solution

Extract from `knw_compare_mapgl()`, and design against both callers:

| Function | Purpose |
|----------|---------|
| `gq_mapgl_basemap()` | `maplibre()` on a named basemap (voyager, openfreemap, Esri topo), fitted to a bbox |
| `gq_mapgl_network()` | streams and lakes from the registry, stream width by stream order |
| `gq_mapgl_layer()` | add an sf layer styled from a registry key or classes, with its categorical legend |
| `gq_mapgl_controls()` | navigation, scale bar, and the layer toggle over the layers added |
| `gq_mapgl_popup()` | a popup template from column names |

- Per-class opacity must survive into these layers: #107.
- Done when `knw_compare_mapgl()` can be rewritten on these helpers with no visible change, and
  the second caller's map is a few calls.


## Exploration (2026-11-12)

- `knw_compare_mapgl()` read from knowledge origin/main eac16623 (`R/compare_map.R`): shared
  source `knw_seg` for two line layers (`rules`, `grade` hidden), integer class codes `rc`/`gc`
  with `match_expr()`, width `interpolate("stream_order", c(1, 6), c(0.6, 3))`, water fill
  merged over defaults from `gq_mapgl_style(reg$layers$lake)`, two categorical legends tied by
  `layer_id`, `add_layers_control(layers = c(Habitat = "rules", Grade = "grade"))`, popup as a
  `concat`/`get` expression, coords rounded by `.round_sfc()`, Esri topo raster style.
- eDNA maps (`fish_passage_{skeena,peace,fraser}_2025_reporting/scripts/edna_map*.R`): carto
  positron, one `add_circle_layer()` per species with zoom-interpolated radius, hidden QA layers.
- Bundled second-caller data: `neexdzii_fish_obs` (63 pts, 14 species, 4326), `neexdzii_streams`
  (1,074 segs, `stream_order` 1–6), `neexdzii_lakes` (42).
- mapgl installed 0.4.4.9000; in gq `Suggests`. No reference index in `_pkgdown.yml`.
- `gq_mapgl_classes()` has an unused `property` argument (Phase 1 gives it a meaning).

## Errors Encountered

| Error | Resolution |
|-------|------------|
