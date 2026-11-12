# Code review, round 1: branch 18-add-mapgl-composition-helpers (base 5c4b03e)

## Checklist read

- **index files**: all four read in full (index_code-check.md, index_code-check-r.md,
  index_code-check-shell.md, index_code-check-spatial.md).
- **code-check.md**: I read the prose of all 14 H3s under `## Mechanisms`, skipping the
  table rows. None of the 17 "Rules that stand alone", Security or Spreadsheets/PDFs
  headings names a tool or shape this diff uses, so I read their index lines only:
  **0 full-text sections read outside Mechanisms**.
- **code-check-spatial.md**: 1 section read in full, "sf: reproject the polygon to get a
  lat/lon bbox, never transform the projected bbox corners". I checked the other sf
  headings in the index that touch this diff ("GeoJSON in a projected CRS is silently
  non-portable", "sf: name validation must account for the geometry column") against the
  code from their index lines and found no instance, so I did not read their full text.
  **93 not read in full.**
- **code-check-r.md**: I applied these headings from their index lines against the diff
  and found no instance: "`$` on a list partial-matches…" (checked against the registry's
  key set: `opacity` vs `outline_opacity`, `label`), "`[[` on a named ATOMIC vector…",
  "`nzchar(NA)` is TRUE…", "`ifelse()` with an all-NA test…", "`c(name = x)` keeps
  `x`'s own name…", "`vapply(..., USE.NAMES = FALSE)`…", "Base name shadowing in formal
  args" (`missing` as a formal: a shadow, not a failure), "A `pkg::` call in a test passes
  `devtools::test()`…" (jsonlite is in Imports, withr in Suggests), "Under `R CMD check`,
  tests run from a temp dir…", "Tests that silently do not run", "A duplicate knitr chunk
  label…", "Cross-function consistency for label/string normalization" (the `label` /
  `to_title` fallback matches gq_style()). **0 sections read in full text; about 125 not
  read.**
- **code-check-shell.md**: the diff has no shell. **0 read; 71 not read.**

I ran the probes in a detached worktree of HEAD, now removed. The mapgl test files pass
there (196 expectations, 0 failed, 0 errors).

## Findings

- **[severity: bug]** R/gq_mapgl_layer.R:105-106: the legend's de-duplication runs over
  **every** registry class, before the filter to the classes present in the data. Where
  several class keys share one label and colour (QGIS grouped categories), and the first
  key in registry order is absent from `x`, that key is filtered out and every later key
  with the same look is marked `duplicated()`. The row disappears even though those
  features are drawn. If no other class is present, the function stops with a false
  "`x` has none of registry layer … classes" error. Measured on `roads_dra`, whose
  Highway class is RRP, RH1 and RH2 in that order:
  - data `"RH1"` or `"RH2"` → ERROR "`x` has none of registry layer `roads_dra`'s classes"
  - data `"RRP"` → legend shows Highway
  - data `c("RH1", "RF")` → legend shows only Freeway (Highway missing)
  - data `c("RA2", "RF")` → legend shows only Freeway (Arterial missing; RA1 comes first)

  Three registry layers carry such shared looks: `roads_dra` (18 duplicate rows),
  `streams_all` (11) and `roads_ften` (2). The test, "a registry layer's legend lists only
  the classes in the data", uses `bec_zone`, which has no shared looks, so it cannot reach
  this. Fix: de-duplicate among the kept rows only, e.g.
  `keep[keep] <- !duplicated(paste(sty$labels, sty$swatches)[keep])`.
  - **Rule:** code-check.md "A fixture that cannot reach the failure mode"

- **[severity: bug]** R/gq_mapgl_popup.R:51: `gq_mapgl_popup()` overwrites each popup
  column **in place** with display text, and its docs say to pass that `data` as the
  layer's `x`. The roxygen example uses `c("Stream order" = "stream_order")`. Any popup
  column that the layer also styles on therefore reaches MapLibre as a string:
  - `width = "stream_order"` builds `["interpolate", …, ["get", "stream_order"]]`, which
    needs a number.
  - A `classes` match on an integer column (which the code goes out of its way to keep
    integer: "integers stay integers") compares `1` with `"1"`.

  Probed: `pop <- gq_mapgl_popup(neexdzii_streams[c("gnis_name","stream_order")], c(Stream = "gnis_name", "Stream order" = "stream_order"))`,
  then `gq_mapgl_layer("s", pop$data, color = …, width = "stream_order", popup = pop$expr)`.
  The source GeoJSON carries `"stream_order":"1"`. In the browser that means default line
  widths and every class falling to the default colour, with no R error. knowledge's map
  avoids this only because it keeps `rc`, `gc` and `stream_order` apart from the popup's
  own columns (`so`, `gr`, …). The helper's API does not: it writes the text into the same
  column the style reads. Possible fixes: write the text into new columns (e.g. a prefixed
  copy) and point `expr` at those, or refuse a popup column the layer styles on.
  - **Rule:** none

- **[severity: fragile]** R/gq_mapgl_basemap.R:35,47: for a `bbox` input (documented:
  "an sf::st_bbox()"), `sf::st_as_sfc(bbox)` builds a 4-corner polygon, and
  `mapgl_geom()` transforms only those corners to EPSG:4326. A projected rectangle's edges
  bow under reprojection, so the fitted view is too short on one axis.
  - At subbasin scale the error is nil: the neexdzii bbox in BC Albers is identical to a
    densified version.
  - For a provincial BC Albers bbox (400000–1800000 × 400000–1700000) the north bound comes
    out 59.873° against 60.283° densified. That is about 45 km of the area cut out of the
    initial view.

  The same happens for any sparse-vertex projected polygon given as `x`. Fix:
  `sf::st_segmentize()` the bbox polygon (in its own CRS) before the transform.
  - **Rule:** code-check-spatial.md "sf: reproject the polygon to get a lat/lon bbox, never transform the projected bbox corners"

- **[severity: fragile]** R/gq_mapgl_layer.R:235-242: a simple registry layer with no
  colour reaches mapgl unguarded. `gq_mapgl_style()` returns an empty `paint` for the
  unstyled registry entries: `crossings_pscis_modelled_dams` (rule-based renderer, "manual
  review needed") and `pipeline_permit` ("3 symbol layers"). With `legend = TRUE`, both
  fail with mapgl's "'colors' must be a single value or have the same length as 'values'",
  which does not name the cause. With `legend = FALSE` the layer is drawn silently in
  MapLibre's default colour. I found this by running every registry key through
  `gq_mapgl_layer()` with matching geometry; these were the only two failures (raster
  `habitat_lateral` excluded). A `stop()` naming the key when `sty$color` is NULL would
  close it, in the spirit of `gq_mapgl_classes()`'s refusal of silent-wrong output.
  - **Rule:** code-check.md "A guard that fails toward pass"

/Users/airvine/Projects/repo/gq/planning/active/review-round1.md
