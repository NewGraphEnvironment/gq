# Code review, round 2: branch 18-add-mapgl-composition-helpers (HEAD 2e6418a, base 5c4b03e)

## Checklist read

- **Index files:** all four read in full.
- **code-check.md:** read the prose of all 14 H3s under `## Mechanisms`, skipping the table
  rows. The 17 "Rules that stand alone" headings and the Security and Spreadsheets/PDFs
  headings were read from the index only, because none names a tool or shape in this diff.
- **code-check-r.md:** six sections read in full:
  - "`$` on a list partial-matches, so a longer sibling key answers for a missing one". I
    checked it against reg_main.json's layer, class, classification and fill/stroke/mark key
    sets and found no prefix collision with any key the helpers read.
  - "`ifelse()` with an all-NA test returns a logical vector, whatever `yes` and `no` are".
    `popup_text()`'s logical branch is rescued by `out[is.na(v)] <- missing`.
  - "`nzchar(NA)` is TRUE — non-empty checks silently pass NA". `to_hex` and `popup` test
    `anyNA` first.
  - "`paste()` with a zero-length argument returns length ONE, not zero". `keep[keep] <-`
    on an all-FALSE `keep` assigns nothing.
  - "jsonlite writes an empty name as the element's position".
  - "A library call that dispatches on a global option is not a pure function".
  - "`c(name = x)` keeps `x`'s own name, so a value from a named vector becomes `name.X`".

  I applied "A `pkg::` call in a test passes `devtools::test()` and fails `R CMD check` if
  `pkg` is undeclared" from its index line: jsonlite, sf, withr, grDevices and mapgl are all
  declared. About 128 other sections were not read in full.
- **code-check-spatial.md:** one section read in full, "sf: reproject the polygon to get a
  lat/lon bbox, never transform the projected bbox corners". About 120 not read.
- **code-check-shell.md:** the diff has no shell, so 0 sections were read and about 75 were not.

**How I probed:** I ran the probes in a detached worktree of HEAD, now removed. All six
`test-gq_mapgl_*.R` files pass there with `NOT_CRAN=true`: 0 failed, 0 errors, 0 skipped.

**The round-1 fixes:**
- Each new test goes red against its defect when read against the prior code.
- Fix 1 (dedupe among the kept rows) is correct as written.
- Fix 2 (`popup_N` columns, with a clash check) is correct, and the test pins the numeric
  column.
- Fix 4: the only two registry entries with no colour are the two it names. No polygon in
  reg_main is outline-only, so no styled layer is refused.
- Two findings below concern fix 3, and one concerns the guard that fix 1 sits inside.

## Findings

- **[severity: bug]** R/gq_mapgl_basemap.R:123-126: **fix 3 is a regression for a
  degenerate projected bbox.** For a single point, `max(xmax - xmin, ymax - ymin) / 100` is
  0, and `sf::st_segmentize()` stops with the bare message "argument dfMaxLength should be
  positive". Example: `gq_mapgl_basemap(sf::st_bbox(<one point in EPSG:3005>))`.
  - **At 649837b (before the fix)** the same call returned bounds
    (`-126 54.00349 -126 54.00349`).
  - **On an sf of that same point**, HEAD still fits, so the two input forms of one extent
    now disagree.
  - **A zero-height or zero-width bbox, such as a horizontal line,** still works, because
    only the longer side has to be non-zero.
  - **Fix:** segmentize only when that length is positive.
  - **Rule:** code-check.md "Zero-length, empty, and unset are three different things"

- **[severity: fragile]** R/gq_mapgl_basemap.R:118-127: **the densify fix landed on the
  `bbox` input only. An sfc or sf of the same rectangle still fits by its four corners.**
  `sf::st_as_sfc(sf::st_bbox(aoi))` is the usual way to pass an extent, and the roxygen
  calls `x` "the extent to fit". Measured at HEAD with round 1's provincial BC Albers box
  (400000-1800000 x 400000-1700000):

  | input | north bound |
  |---|---|
  | `gq_mapgl_basemap(bb)` | 60.283 |
  | `gq_mapgl_basemap(sf::st_as_sfc(bb))` | 59.873 |

  That is the ~45 km cut that fix 3 was written to remove. Round 1 noted that the same
  applies to "any sparse-vertex projected polygon given as `x`". A drawn layer's own
  vertices fit correctly, because MapLibre draws the straight segments between them. An
  extent that is not drawn does not.
  - **Fix:** segmentize any projected input's geometry before `mapgl_geom()`, not only a
    `bbox`. Its bbox is all that `maplibre()` keeps.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: bug]** R/gq_mapgl_layer.R:105: the legend filter that fix 1 sits inside
  falls back to `TRUE` (every class) whenever `sty$field` is not a column of `x`. That is
  the state where the map is most wrong.
  - **The cause:** forgetting `field =` on data that names the column differently, which is
    exactly the case the vignette's crossings map and CLAUDE.md's example document.
  - **What happens:** the paint becomes `["match", ["get", "barrier_result_code"], ...]`
    over features that have no such property. Every feature draws in the fallback
    `#888888`, and the legend lists all four registry classes, including `Potential`,
    which the data does not hold.
  - **Probe:** `gq_mapgl_layer(m, "c", neexdzii_crossings[status != "POTENTIAL",
    c("barrier_status", "gnis_stream_name")], key = "crossings_pscis_assessment", reg = reg)`
    with no `field`. There was no error or warning, and the legend HTML showed Barrier,
    Passable, Potential and Unknown.
  - **Why it matters:** the comment above the filter says it exists because "a legend
    naming classes the map does not draw is a common and quiet error". This is that error,
    passing through the guard's escape hatch.
  - **Fix:** when `x` is given and the classification field is not among its columns,
    stop and name the field and `field =`. The `x = NULL` arm cannot check, and can stay
    as it is.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: fragile]** R/gq_mapgl_layer.R:91-93,118: the function refuses `x = NULL`
  for a source that is not on the map. It does not refuse the converse: an `x` for a
  source id that already is on the map.
  - **What the map gets:** `mapgl::add_source()` appends a second source with the same id.
    Measured: `gq_mapgl_layer("a", s, source = "seg", ...) |> gq_mapgl_layer("b", s,
    source = "seg", ...)` gives `x$sources` ids `"seg" "seg"`. Calling
    `gq_mapgl_layer("gq_streams", s, ...)` after `gq_mapgl_network()` likewise gives
    duplicate source ids and duplicate layer ids.
  - **What the browser does:** in mapgl's widget JS (`htmlwidgets/maplibregl.js`, the
    `x.sources.forEach` at ~line 1131), `map.addSource()` is not inside a `try`. The bundled
    `maplibre-gl.js` **throws** `Source "<id>" already exists.` on a duplicate. So the
    load handler aborts at the second copy, and every source and layer after it fails to
    draw. A duplicate layer id only fires an error event and drops that one layer.
  - **Why it is likely:** the roxygen describes sharing a source ("pass the data once with
    `x`, then ... `x = NULL`"). Passing the data twice is the natural slip, and nothing in R
    reports it. I read the browser behaviour from the shipped JS and did not render it.
  - **Fix:** stop when `!is.null(x)` and `source` is already among `map$x$sources` ids, and
    likewise when `id` is already among `map$x$layers` ids.
  - **Rule:** none
