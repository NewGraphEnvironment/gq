# gq#57 — a watermarked basemap shipped to the public site, and nothing objected

**Outcome:** fixed in v0.7.0. Carto made their basemaps key-only and began
serving an "API KEY REQUIRED" image. It is a structurally valid PNG — right
dimensions, right CRS, right band count — so `gq_basemap_tiles()`' existing
fetch-failure guard never fired, `R CMD check` passed, pkgdown built, and the
flagship vignette map went to the published site with the watermark across it
three times. Default provider is now `Esri.WorldGrayCanvas`, keyless.

**Found by looking, not by testing.** The user asked how solid the vignettes
were. Answering meant rendering them and opening the PNG. No automated check in
the package could have caught this, and the visual read is still the only real
acceptance gate — which is why Phase 5 was a phase rather than a footnote.

**The interesting result is a negative one.** The obvious fix is a watermark
detector, and it does not work: measured over one bbox at three zooms, the
*watermarked* z11 tile has **fewer** dark pixels (0.0068) than the *clean* z9
tile (0.0073). The watermark is a small share of pixels and ordinary map content
swamps it. Shipping that detector would have reintroduced this issue's own defect
inside its fix — a guard that fails toward "pass". The roxygen states this with
the numbers so it is not re-litigated.

**A second placeholder class was found by accident and does work.**
`Esri.WorldTerrain` returns a completely flat tile over BC — every pixel 254,
sd 0.00 — and fetches without error. `tile_is_flat()` now warns on it. Compared
min-to-max *per band*, because open ocean is `0/0/255`: one flat colour, two
distinct numbers, so counting distinct values misses the case most likely to
arise legitimately. It warns and still returns the tile — measurement over a
Vancouver Island extent confirmed a genuinely uniform tile is reachable in gq's
own domain, so dropping it would destroy valid data.

**The concurrent plan review earned its keep — two blockers.**
`terra::minmax()` defaults to `compute = FALSE` and returns `Inf`/`-Inf` for a
raster with no cached statistics, so the new guard called *every file-backed
raster* flat; it passed against maptiles only because `get_tiles(crop = TRUE)`
computes min/max in passing. Every fixture was in-memory, so none could reach it.
And `tm_shape(NULL)` errors outright — the "a tile hiccup should not lose the
figure" contract documented since #17 had never worked, and Phase 4 was about to
copy it into a second vignette.

**The review also caught the boundary error.** The provider inventory was
complete *within gq* and stopped at the repo edge: `soul/skills/cartography`
still shipped the keyless Carto snippet, and that is what consumer repos read.
Fixed there too (soul `9ec6c72`).

**Where I was wrong:** I claimed `Esri.WorldGrayCanvas` is label-free and assumed
the house skill saying otherwise was stale. It shows lake names at the function's
own default zoom. The skill was right.

Commits `ecaf715`..`bc5001d`. PR #59. Attribution split to #58.
