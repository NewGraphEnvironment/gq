# Findings — tmap composition helpers (#17)

## tmap 4.4.1 resolved what #27 was waiting on

The archived #17 `findings.md` (2026-03-10) records tmap#1179 as blocking
grouped legends and prescribes `tm_components("tm_legend", stack = "horizontal")`
as a workaround. Installed is **4.4.1**, and that workaround is now the
supported API:

- `tm_add_legend()` gained **`z`** (explicit z-index) and **`group_id`**
- `tm_components()` (renamed from `tm_comp_group` in 4.2) takes a matching
  `group_id` plus `position`, `stack`, `frame_combine`, `equalize`,
  `resize_as_group`, `stack_margin`, `offset`
- `tm_place_legends_*()` handles outside-the-frame placement
- `tm_legend_hide()` is the clean form of `tm_legend(show = FALSE)`

Still absent upstream: any **structured** legend builder. `tm_legend_combine()`
merges two visual variables on *one* layer, not across layers or geometry
types. So the split is clean:

| | owner |
|---|---|
| entries per geometry type, ordering, stacking, framing, placement | **tmap** |
| registry layer spec → legend arguments, geometry-type partitioning, present-values filtering, title casing | **gq** |

tmap has no concept of a style registry, so the gq half is not something
upstream would want. This makes `gq_tmap_legend()` **thinner** than #27 scoped,
and weakens that issue's "propose upstream" plan.

## The two aspect-match implementations disagree on purpose

`vignettes/gq-tmap-composition.Rmd:111-141` applies a latitude correction:

```r
cos_lat <- cos(lat_mid * pi / 180)
geo_asp <- (dx * cos_lat) / dy
```

`lfpr_bbox_asp()` (fraser `0420:163-185`) does not, and its roxygen says why —
its CRS is projected (BC Albers, 3005), where a degree correction is wrong.

Neither copy knows the other exists. Porting either one into gq unchanged is a
bug in the other's context, so the extracted function branches on
`sf::st_is_longlat()` rather than taking a flag.

The vignette also ends `st_as_sfc(bbox) |> st_set_crs(4326)` — `set`, not
`transform`. That is a latent bug: it asserts a CRS rather than converting to
one, and is only correct because the input happened to be lat/lon already.

## `clip` and `crop_sf` are different operations

Both exist in the fish passage repos under near-identical names and comments,
and they are not the same:

```r
# fraser 0420:597 — SELECTS features that intersect
clip <- function(x) {
  if (is.null(x) || nrow(x) == 0) return(NULL)
  out <- sf::st_filter(x, bb_sfc)
  if (nrow(out) == 0) NULL else out
}
# peace 0760:317 / fraser 0720:220 — CUTS geometries at the boundary
crop_sf <- function(x) {
  if (is.null(x) || nrow(x) == 0L) return(NULL)
  out <- suppressWarnings(sf::st_crop(x, inset_bbox))
  if (nrow(out) == 0L) NULL else out
}
```

`st_filter` keeps whole features; `st_crop` truncates them at the edge. For a
stream running out of frame these give visibly different maps. Collapsing them
into one function would be the bug rather than the fix, so `gq_bbox_clip()`
carries a `crop` argument and documents the difference.

What they genuinely share — and the reason all four copies exist — is the
NULL-not-zero-row return. Every copy carries the same comment: `tm_shape()`
errors with "subscript out of bounds" on an empty geometry set rather than
skipping it.

## `lfpr_scale_breaks()` encodes a non-obvious constant

```r
lfpr_scale_breaks <- function(bb, n = 3, share = 0.35)
```

`share` exists because sizing off `span/3` per interval overruns the frame;
tmap then reports "not all scale bar breaks could be plotted" and **silently
drops every label but the last**. Worth carrying the rationale into the roxygen
— it is the kind of thing that gets "simplified" away.

## Dead code not to port

Verified by repo-wide grep of the fraser checkout (excluding `renv/`):

| symbol | status |
|---|---|
| `lfpr_grob_north()` | defined, never called — `lfpr_map_site()`'s `north = TRUE` branch uses `tmap::tm_logo()` directly |
| `lfpr_convergence()` | defined, never called |
| `lfpr_label_mapping_code()` | defined, never called |
| `label_max_modelled = 25` | formal of `lfpr_map_site()`, never referenced in the body |
| `@param extent` | documented on `lfpr_map_site()`; the real argument is `scale` |

## The cartography skill's tmap examples would error today

`soul/skills/cartography/SKILL.md`:

- `gq_reg_read_csv()` ×3 (lines 58, 288, 297) — no such export; real name is
  `gq_reg_custom()`. Also once in `soul/conventions/cartography.md:31`
- `system.file("registry", "reg_csv_custom.csv", ...)` — the shipped file is
  `reg_custom.csv`, and `system.file()` returns `""` on a miss, so this fails
  silently downstream
- **Seven phantom layer keys**: `reg$layers$road` (→ `roads_dra`),
  `$pscis_assessment` (→ `crossings_pscis_assessment`), `$park` (→
  `provincial_park`), `$road_highway` and `$road_arterial` (no such keys —
  those are classes *inside* `roads_dra`), `$watershed` (→
  `watershed_group_boundary`), `$stream` (→ `streams_all`)
- An unbalanced fence at line 1160 renders lines 1161–1179 of prose as R
- The entire groups/templates/themes subsystem (12 exports) is unmentioned

The tmap legend block and the script skeleton are the two that would actually
error. This is the cost of code-in-prose and part of the argument for the
extraction.

## House style, measured

`chk`, `cli` and `rlang` appear in **no** function body — `rlang` is in
Suggests but unused. All 25 guards are bare `stop()`, about half with
`call. = FALSE`. Enumerated args use `match.arg()`. Suggests packages are
guarded with `requireNamespace(..., quietly = TRUE)`. No `@import` anywhere and
no `R/gq-package.R`; everything is `::`-qualified.

`!!!` splice does not work in tmap (archived findings), which is why every
helper returns a plain named list for `do.call()` — the shape
`gq_tmap_classes()` already uses.

No test currently uses `skip_if_not_installed()`, because nothing tested needs
a Suggests package. The basemap tests are the first that would — hence
splitting the blend arithmetic into a pure core testable on a synthetic raster
with no network.

## Logo: #14's path is stale

#14 says "Ship NGE logo as `inst/assets/logo.png`". There is no `inst/assets/`.
`inst/logo/nge_icon_200.png` (200×200, RGBA) already ships and the vignette
already resolves it at line 179. `man/figures/logo*.png` are the gq hex
sticker, not the NGE logo. Record the real path; a `gq_tmap_logo()` would
encapsulate it anyway.
