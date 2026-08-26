# Task: gq_basemap_tiles() returns watermarked placeholder tiles as success (#57)

The published composition vignette carries **"API KEY REQUIRED / carto.com/basemaps/apikey"**
watermarked diagonally across it, three times, live on the pkgdown site now. Carto has made
their basemaps key-only.

This is not confined to the vignette. `gq_basemap_tiles()` defaults to
`provider = "CartoDB.PositronNoLabels"` (`R/gq_basemap_blend.R:146`), so **every call that
leaves the default alone returns a watermarked raster** — including the roxygen example at
`:143`.

The deeper problem is that gq *reported success*. The function already has a deliberate guard
returning `NULL` on a failed fetch (`:176-179`). It never fired, because nothing failed: Carto
returned HTTP 200 with a structurally valid PNG that has words painted into it. Right
dimensions, right CRS, right band count. The failure is **success-shaped**, so it rendered
through a pkgdown build and onto the public web with nothing objecting.

## Approach

Swap the provider, add the guard that measurement shows *works*, and refuse to add the one it
shows does not. Record why, so it is not re-litigated.

**Not in scope:** an API-key mechanism. No credential handling exists anywhere in the package
(`Sys.getenv` is used only for local rfp paths), and moving to a keyless provider means none
is needed. Adding one now is speculative.

## Phase 1 — Failing tests first

`gq_basemap_tiles()` currently has **zero tests**, despite
`tests/testthat/test-gq_basemap_blend.R:1-2` claiming the fetch wrapper "is skipped by
default". That comment describes an intention never implemented.

- [x] Offline: the degenerate-tile guard warns on a synthetic constant raster and is silent on
      a varied one. Both known answers, no network
- [x] Offline: a legitimately uniform tile (all-ocean extent) is the guard's plausible false
      positive — assert the tile is still **returned**, not dropped
- [x] Network-gated (`skip_if_offline()`, `skip_on_cran()`): each provider gq recommends fetches
      and is non-degenerate over a small fixed bbox
- [x] Confirm the new tests fail against current `main` — 6/6 fail: four cannot find
      `tile_is_flat()`, and the integration test reaches `gq_basemap_tiles()` through a mocked
      transport and reports "Expected to throw a warning"

Added a case the plan did not anticipate: **a solid colour whose bands differ** (0/0/255 —
open ocean). Counting distinct numbers across the raster gives 2 and misses it. Flatness is a
property of the pixel colour, so the comparison has to be min-vs-max *per band*.

## Phase 2 — The guard

- [ ] `gq_basemap_tiles()`: warn when a fetched tile has a single unique value across all bands
- [ ] **Warn and return the tile — do not return `NULL`.** An all-ocean extent is legitimately
      uniform, so this has a real false-positive path; a warning makes it visible without
      destroying a valid basemap. The existing `NULL` contract stays for genuine fetch failure
- [ ] Roxygen: state plainly that watermark/placeholder content is **not** detectable, with the
      z9-vs-z11 numbers. A future reader will otherwise assume it was an oversight

## Phase 3 — Provider swap, every call site

Complete inventory — 2 strings, 9 lines, 6 files. Missing one ships a watermarked map.

- [ ] `R/gq_basemap_blend.R:146` — the default
- [ ] `vignettes/gq-tmap-composition.Rmd:117,119`
- [ ] `vignettes/gq-intro.Rmd:104,105`
- [ ] `README.md:80,81` — also passes the provider **positionally**; make it named
- [ ] `man/gq_basemap_tiles.Rd:9` — regenerate via `devtools::document()`, never hand-edit
- [ ] Roxygen example `R/gq_basemap_blend.R:138-143` uses the default; re-check after the swap

## Phase 4 — Close the asymmetry in gq-intro.Rmd

`gq-intro.Rmd:104-105` never migrated to gq's own helpers — it calls `maptiles::get_tiles()`
directly with a hand-rolled gamma blend and hand-rolled degree padding. It therefore has **no
`NULL` contract and no failure guard**, so a tile hiccup hard-fails the vignette build, and any
guard added in Phase 2 does not protect it.

- [ ] Migrate to `gq_basemap_tiles()` + `gq_basemap_blend(method = "gamma", gamma = 0.5)`,
      matching the composition vignette's `NULL`-handling block
- [ ] Verify the rendered map is unchanged apart from the basemap provider

## Phase 5 — Verify by looking, not by exit code

The whole issue is a failure that passed every automatic check, so the acceptance test is
visual.

- [ ] Render both vignettes; extract the figures; **read them**
- [ ] Confirm: no watermark text anywhere in either figure
- [ ] Confirm the basemap still reads as terrain — `Esri.WorldGrayCanvas` is flatter than
      Positron (sd 3.28 vs 15.91), so the hillshade blend is now carrying more of the texture.
      If it reads as washed out, tune the blend rather than reverting the provider
- [ ] Re-check against `cartography.md`'s self-review list, at minimum "map fills to frame"

## Phase 6 — Land it

- [ ] `NEWS.md` + `DESCRIPTION` 0.6.0 → **0.7.0**. Minor, not patch: the default value of an
      exported function's argument changes, which alters output for callers who pass nothing
- [ ] Note in the issue that `Esri.WorldTerrain` is blank over BC, so nobody adopts it next
- [ ] `/planning-archive`, `/gh-pr-push`

## Validation

- [ ] `devtools::test()` — 829 existing pass, plus new
- [ ] `lintr` clean on changed files
- [ ] `devtools::check()` no new ERROR/WARNING/NOTE (main carries 2+2, gq#51)
- [ ] `/code-check` per commit; PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
