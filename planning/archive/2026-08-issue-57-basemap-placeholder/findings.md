# Findings — gq_basemap_tiles() returns watermarked placeholder tiles as success (#57)

## How it was found

Not by a test — by rendering the vignettes and **looking at the figures**. The user asked how
solid the vignettes were; the answer required opening the PNG. Every automated check in the
package was green while a watermarked basemap was live on the public site.

Confirmed on the published artifact, not just locally:

```
https://www.newgraphenvironment.com/gq/articles/gq-tmap-composition_files/figure-html/map-composition-1.png
-> HTTP 200, 1191473 bytes, "API KEY REQUIRED / carto.com/basemaps/apikey" x3
```

## Measurements

All from the vignette's own bbox: `gq_bbox_aspect(neexdzii_wsd, asp = 7/9)`, `pad = 0`,
`crs = NULL`. maptiles 0.11.0.

### The watermark is zoom-dependent

| zoom | keyless Carto |
|---|---|
| 9 | clean |
| **10** | **watermarked** — the vignette hardcodes this |
| 11 | watermarked |
| 12 | function default |

### A content probe cannot detect it

| provider | zoom | state | `frac<200` | `frac<160` |
|---|---|---|---|---|
| CartoDB.PositronNoLabels | 9 | **clean** | 0.0088 | 0.0073 |
| CartoDB.PositronNoLabels | 10 | watermarked | 0.0170 | 0.0128 |
| CartoDB.PositronNoLabels | 11 | watermarked | 0.0092 | **0.0068** |

**The watermarked z11 tile has fewer dark pixels than the clean z9 tile.** No threshold on a
global luminance statistic separates them — the watermark is a small pixel fraction and real
map content (roads, water) swamps it.

This is the load-bearing negative result. Building the "obvious" detector here would ship a
guard that fails toward "pass" — the exact defect the issue is about, reintroduced by the fix
for it. Same shape as the `lty`-inside-the-`lty`-fix blocker in gq#52.

### A second failure mode exists, and it IS detectable

| provider | sd | unique values | mean |
|---|---|---|---|
| Esri.WorldTerrain | **0.00** | **1** | 254.0 |
| Esri.WorldGrayCanvas | 3.28 | 53 | 238.6 |
| Esri.WorldTopoMap | 10.99 | 134 | 231.7 |
| Esri.WorldStreetMap | 12.08 | 132 | 215.1 |
| CartoDB.PositronNoLabels | 15.91 | 53 | 240.7 |

`Esri.WorldTerrain` returns a completely constant tile over this extent — every pixel 254.
Clean separation from every real basemap, so a unique-value guard has no false positives among
them.

Found by accident while shortlisting replacements. It fetches without error and would have
shipped as a silently blank basemap — the same success-shaped failure one step over. Worth
noting in the issue so nobody adopts it next.

### Replacement

`Esri.WorldGrayCanvas` — keyless, label-free, light, verified clean at z9/10/11 and visually
checked. Flatter than Positron (sd 3.28 vs 15.91), so the hillshade blend now carries more of
the texture; watch for a washed-out result in Phase 5.

`Esri.WorldShadedRelief` (the relief layer) is unaffected and stays.

## Code surface

Complete provider-string inventory — 2 distinct strings, 9 lines, 6 files:

| file:line | string | kind |
|---|---|---|
| `R/gq_basemap_blend.R:146` | CartoDB.PositronNoLabels | function default |
| `man/gq_basemap_tiles.Rd:9` | CartoDB.PositronNoLabels | roxygen output — regenerate |
| `README.md:80` | CartoDB.PositronNoLabels | **positional** arg |
| `README.md:81` | Esri.WorldShadedRelief | README |
| `vignettes/gq-intro.Rmd:104` | CartoDB.PositronNoLabels | direct `get_tiles()` |
| `vignettes/gq-intro.Rmd:105` | Esri.WorldShadedRelief | direct `get_tiles()` |
| `vignettes/gq-tmap-composition.Rmd:117` | CartoDB.PositronNoLabels | via `gq_basemap_tiles()` |
| `vignettes/gq-tmap-composition.Rmd:119` | Esri.WorldShadedRelief | via `gq_basemap_tiles()` |
| `planning/archive/.../review-52.md:640` | both | prose, `.Rbuildignore`d |

`whse_basemapping.*` (~50 hits) is a BC Data Catalogue PostGIS schema, not a tile provider.
`inst/styles/services/*.qml` are QGIS service definitions, not maptiles strings.

## Two asymmetries worth naming

1. **`gq-intro.Rmd` never migrated** to `gq_basemap_tiles()`/`gq_basemap_blend()`. It calls
   `maptiles::get_tiles()` directly with a hand-rolled gamma blend and hand-rolled degree
   padding, so it has no `NULL` contract — a tile hiccup hard-fails the vignette build — and
   any guard added to `gq_basemap_tiles()` does not protect it.

2. **`gq_basemap_tiles()` has zero tests**, while `tests/testthat/test-gq_basemap_blend.R:1-2`
   says the fetch wrapper "is skipped by default". There is no skipped test; the comment
   describes an intention never implemented. Nothing in the suite touches the network.

## Package context

`maptiles` is in **Suggests** (`DESCRIPTION:22`). House guard idiom is
`if (!requireNamespace(x, quietly = TRUE)) stop("<pkg> is required")`.

**No credential handling exists anywhere.** Every `Sys.getenv()` points at a local rfp path
with a `""` default. So an API-key mechanism would be built from nothing — which is why moving
to a keyless provider is the cheaper fix.
