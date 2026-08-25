# tmap composition helpers (#17) — complete

Shipped in **v0.5.0**. Closes #17; dents #14. Resumed and finished the same day
the earlier PWF was archived as *paused, not complete*.

## Outcome

Six helpers — `gq_bbox_aspect()`, `gq_bbox_clip()`, `gq_scale_breaks()`,
`gq_basemap_tiles()` / `gq_basemap_blend()`, `gq_tmap_legend()`,
`gq_tmap_keymap()`. Each replaces three to five copies scattered across the fish
passage reporting repos, gq's own vignette, and the cartography skill. Two of
those copies documented themselves as ports *of this vignette*, so the code had
already made the round trip out of gq and back.

## What extraction settled that copying would have preserved

Three disagreements the copies did not know they had:

- **The latitude correction is conditional.** The vignette applies `cos(lat)`;
  fraser's `lfpr_bbox_asp()` deliberately does not, because it runs in BC
  Albers. Each is wrong for the other's input. `gq_bbox_aspect()` takes the
  branch from `sf::st_is_longlat()`, via `isTRUE()` so an unknown CRS falls to
  projected rather than propagating NA.
- **The blend is two operators, not one.** fraser's docstring says it is "the
  same operator as the vignette; only the relief source differs." The relief
  source does differ — a DEM hillshade, because Esri's shaded relief caps at
  zoom 13 — but so does the arithmetic: gamma versus a capped linear pull. At
  mid-grey they give 141 and 165 out of 200. Both ship, named.
- **`clip` and `crop_sf` are different sf calls.** `st_filter` keeps whole
  features, `st_crop` truncates them. Near-identical names, same comment above
  each, visibly different maps for a stream leaving the frame. `crop` is an
  argument rather than a second function to pick by accident.

`gq_tmap_legend()` came out **thinner** than #27 scoped: tmap 4.4.1 resolved the
grouped-legend blocker the archived notes recorded against 4.2, so ordering,
stacking, framing and placement are upstream's and only the registry
translation is gq's.

## Proof

The planned pixel diff of fraser's four site maps was **not achievable** —
`lfpr_map_site()` needs globals from fraser's upstream pipeline, which needs the
database, and `0410` refuses to run without `update_gis` by its own guard.

What replaced it is stronger and needed neither: the three originals were copied
verbatim out of `0420` and run against the new functions over fraser's **real
cached rasters**. Aspect padding and scale breaks identical; the blend
**bit-identical, max|diff| exactly 0 across 14.7 million cells**, all four sites.

## The bug 527 passing tests could not see

`sf::st_filter()` dispatches through **dplyr**, which gq does not depend on. The
suite passed because the developing session had dplyr attached; `R CMD check` in
a clean environment gave `FAIL 4` and a failing example. Replaced with
`st_intersects()` indexing and re-verified under `Rscript --vanilla`.

Exactly the class the `R-CMD-check` workflow added in #50 exists to catch — a
dependency a warm session hides.

## Two loose ends settled by measurement

- `tm_scalebar()` does **not** crash. The archived `object 'sbW' not found` was
  specific to tmap 4.2; 4.4.1 renders it, which is why the merged vignette calls
  it without trouble.
- The vignette's `st_set_crs(4326)` was a no-op, not a live bug —
  `neexdzii_wsd` is already 4326. The replacement inherits the CRS instead.

## Also fixed upstream

`soul` commit `58f0ff9` — the cartography skill had four defects that would have
failed on execution: a function that never existed (`gq_reg_read_csv()`, ×3 plus
once in the conventions), a wrong bundled filename that failed *silently*
because `system.file()` returns `""`, seven phantom registry layer keys, and an
unbalanced fence rendering nineteen lines of prose as R.

## Deferred, filed not forgotten

- **Rewriting fraser's `0420` onto these helpers** — its own PR, because fraser
  installs gq from GitHub and these had to land first.

  The plan's "delete the local copies" **over-promised**, and the keymap is
  where. `lfpr_keymap_survey()` is ~130 lines carrying context waterbodies,
  streams, roads and railway, classified habitat lines, a two-part ring+core
  crossing symbol, staggered paired labels, road-name-on-longest-segment, eDNA
  points and its own scalebar. `gq_tmap_keymap()`'s `(aoi, context, reg)`
  signature expresses the vignette's three-layer inset and nothing more. It also
  places the inset *over* the map, while fraser puts it in a legend panel
  outside the frame — one default cannot serve both. Expect that one to stay
  local, thinned rather than deleted. `gq_basemap_blend()` likewise does not
  crop to frame or return NULL on an absent basemap, so fraser's wrapper keeps
  those guards.

  When it happens: do not
  port `lfpr_grob_north()`, `lfpr_convergence()` or `lfpr_label_mapping_code()`
  (all defined, never called), drop the unused `label_max_modelled` formal, and
  fix the roxygen documenting a `@param extent` that does not exist.
- **#16** — two `* 2` width fudges remain live in the vignette.
- **#18 / #19** — mapgl and leaflet composition, untouched.
