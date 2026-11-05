# Findings — Move 2: styles reach the map (batches 3, 4, 5) (#101)

## Issue context

**If we do it:** a classified layer draws at the opacity the registry gives it, a hand-written
CSV can carry a dashed classified line, and the floodplain and habitat comparison styles come
from one registry entry. **If we never do:** every BEC zone keeps drawing at full opacity, and
each map of rule comparisons, expected use or tree change types its own colours.

Move 2 of `planning/backlog.md`. Batch 3: #71, #31, #55 (translator opacity and labels).
Batch 4: #42, #75 (custom CSV reader). Batch 5: #98, #67 (register styles).

## Plan-mode exploration (2026-11-05, main @ 87f7677)

- `bec_zone` has **11** classes in both `reg_custom.csv` and `reg_main.json`, not the 15
  #71's body states. Each carries `opacity 0.25`, `outline_opacity 0.4`.
- tmap 4.4.1 maps per-class `fill_alpha` with `fill_alpha.scale = tm_scale_categorical(values
  = c(0.25, 0.7), levels = ...)`; the rendered `pathgrob` carries `gp$alpha` per feature.
  So the render check reads `gp$alpha`, not a hex alpha suffix.
- The extractor (`R/gq_qgs_extract.R:237`, `:248`) writes per-class `opacity` only when
  alpha < 1, so a missing per-class opacity means 1.
- `gq_tmap_legend()` classified rows carry no `fill_alpha`/`col_alpha`; its own comment
  (`R/gq_tmap_legend.R:240`) names this gap.
- `gq_mapgl_classes()` builds a colour match expression only; opacity there is out of scope.
- `stream_labels` already exists in `reg_main.json` (italic `#1f78b4`, white halo 0.3), so
  #98's stream-label request is already met.
- drift ships `inst/lulc_classes/io_lulc_v02.csv` (drift origin/main @ 0ac0397), a palette
  that differs from the Esri hex in #67's body. Owner chose drift's.
- Consumers of #98's colours: knowledge `R/compare_map.R` (`rule_class`, `grade_class`,
  keys `0-0.2` … `0.8-1`), website `scripts/figure_knowledge-bulkley.R`
  (both/current/tested/neither). flooded's `fl_scenarios()` uses `scenario_id`
  `ff02`/`ff04`/`ff06` for active channel / functional floodplain / valley bottom.
- No website script draws tree loss/gain yet (website issue #71 open), so no hex to adopt.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| In-memory `assign()` of an old function into the namespace left tests calling the new export | Tests resolve exported functions from the attached package env, not the namespace; restore a bug in a `git worktree` instead |
| `write_reg_csv()` fixture deleted its file when an inner helper returned | Pass the caller's frame as the `withr::defer()` envir |

## Phase 1 measurements

- Classified layers with per-class opacity in `reg_main.json`: `bec_zone` (0.25 on all 11),
  `fire_severity` (0.4 on some), `roads_dra` (0.6 on some), `streams_all` (0.65 on some),
  `habitat_lateral` (raster, 0.4). So #71 changes how `fire_severity`, `roads_dra` and
  `streams_all` draw too, not only `bec_zone`.
- tmap 4.4.1 draws per-class line alpha as `gp$alpha` on `polyline` grobs and polygon alpha
  on `pathgrob`, so one `drawn_gp(m, "alpha", grob_class)` read covers both.

## Phase 2 measurements

- `data-raw/reg_build_main.R` on unchanged sources reproduces `reg_main.json` byte for byte
  (57 layers), before and after the reader change and the new `dash` column.

## Phase 3 measurements

CIEDE2000 from the oranges a tree-gain swatch shares a page with (`#d95f02` first rule
only / the website link map's crossing, `#f2a93b` valley bottom, `#e49635` drift Crops):

| candidate | d95f02 | f2a93b | e49635 | on the basemap |
|---|---:|---:|---:|---|
| `#ff8c42` (chosen) | 12.7 | 14.1 | 10.3 | lighter salmon-orange, reads on its own |
| `#ff7f00` | 11.0 | 13.9 | 9.7 | reads as a blend of the existing oranges |
| `#ffab73` | 19.6 | 11.8 | 10.9 | peach, weak at 0.7 opacity |
| `#fdd49e` | 30.7 | 13.6 | 17.0 | scores best, washes into the topo basemap |

Loss: `#e7298a` (23.0 from plum `#7b3f98`, 27.1 from Built Area `#c4281b`) over the lighter
`#f781bf`, so the restoration signal is the stronger of the pair.

The orange space between the three existing oranges tops out near 10-14 ΔE; nothing in it
clears all three by a wide margin while staying visible on a light basemap.
