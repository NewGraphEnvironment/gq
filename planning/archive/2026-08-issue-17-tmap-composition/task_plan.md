# Task: Add tmap composition helpers and composition vignette (#17)

Dents #14 (the composition umbrella). mapgl (#18) and leaflet (#19) untouched.

## Context

gq translates *styles* but not *composition*. Basemaps, bbox padding, legends,
keymaps and scale breaks are copy-pasted across every report. Measured:

| helper | copies in the wild |
|---|---|
| bbox ↔ aspect match | 4 (gq vignette, fraser `0420`, SKILL.md ×2) |
| topo × hillshade blend | 4 (gq vignette, fraser `0420`, SKILL.md ×2) |
| keymap inset | 5 (gq vignette, fraser `0420`, SKILL.md ×3 renderers) |
| clip-to-bbox-return-NULL | 4 spellings in one repo (`crop_sf`, `clip`, `cut`, `lyr`) |
| registry → `tm_add_legend()` | gq vignette, fraser `0420`, SKILL.md |

`fish_passage_fraser_2025_reporting/scripts/02_reporting/0420-map-site.R` is
1014 lines, **byte-identical in skeena, fraser and the template repo**, and two
of its functions say in their own docstrings that they port
`gq/vignettes/gq-tmap-composition.Rmd`. gq code, copied out of a gq vignette,
into three repos.

Scope chosen: **six tmap/generic helpers**, proven by refactoring fraser's 0420
to call them. mapgl (#18) and leaflet (#19) stay untouched. #14 stays the
umbrella; this closes #17.

### Three findings that shape the design

- **tmap 4.4.1 is installed, not 4.2, and it resolved what #27 was waiting on.**
  `tm_add_legend()` now takes `z` and `group_id`; `tm_components()` accepts them
  for stacking, framing and placement. The archived note (2026-03-10) calls
  tmap#1179 a blocker and prescribes a workaround that is now the supported API.
  So `gq_tmap_legend()` is **thinner than #27 scoped** — registry → legend args,
  with all layout delegated upstream. tmap has no concept of a registry, so the
  remaining half is the half only gq can own.
- **The two aspect-match implementations disagree deliberately.** The vignette
  (`:111-141`) applies a `cos(lat)` correction; `lfpr_bbox_asp()` drops it
  *because its CRS is projected* (3005). Copying either one is a bug in the
  other's context. The extracted function must branch on
  `sf::st_is_longlat()`. The vignette also ends `st_set_crs(4326)` rather than
  `st_transform` — a latent bug to fix, not port.
- **`!!!` splice does not work in tmap.** Every helper returns a plain named
  list for `do.call()`, matching `gq_tmap_classes()` (`R/gq_tmap_style.R:76`).

### House style to match (measured, not assumed)

Bare `stop("...", call. = FALSE)` — **no `chk`, no `cli`, no `rlang`** in
bodies. `::` everywhere, no `@import`, no `R/gq-package.R`. `requireNamespace()`
guards for Suggests. `@noRd` internals with a *why* paragraph when the helper
encodes a non-obvious decision. Runnable `@examples` off shipped data, no
`\dontrun{}`. Section banners `# --- name ---…` to ~78 col.

**No DESCRIPTION change needed** — `maptiles`, `terra`, `stars`, `sf`, `tmap`
are already in Suggests and unused by gq's code today.

---

## Phase 1 — Pure geometry core

No network, no tmap, no Suggests. Fully testable.

- [x] `R/gq_bbox.R` — `gq_bbox_aspect(x, asp, margin = 0.02)`: pad a bbox to a
      target aspect ratio. Branch on `sf::st_is_longlat()` for the `cos(lat)`
      correction rather than taking it as an argument — the two existing copies
      differ on exactly this and neither knew it was conditional
- [x] `gq_bbox_clip(x, bbox)` — clip and return **NULL, not a zero-row frame**.
      Reconciles four spellings; the rationale (tmap errors on empty geometry)
      goes in the roxygen, since every copy carries that comment
- [x] `R/gq_scale_breaks.R` — `gq_scale_breaks(bbox, n = 3)`, from
      `lfpr_scale_breaks()` (`0420:486-492`)
- [x] Tests for all three against hand-built bboxes, both CRS branches

## Phase 2 — Basemap blend

- [x] `R/gq_basemap_blend.R` — `gq_basemap_blend(bbox, provider_base, provider_relief, zoom, gamma = 0.5, as_stars = TRUE)`
- [x] Split the arithmetic into an `@noRd` pure core taking two rasters, so the
      blend is testable on a synthetic `terra::rast()` **with no network**. The
      fetch wrapper is the thin part
- [x] `requireNamespace()` guards for `maptiles`, `terra`, `stars` — the first
      Suggests-guarded function in the package
- [x] Tests: pure core unguarded; the fetch path `skip_if_not_installed()` and
      skipped offline. **First use of `skip_if_not_installed()` in this suite**

## Phase 3 — Legend

- [x] `R/gq_tmap_legend.R` — `gq_tmap_legend(reg, layers, ...)` returning a list
      of `tm_add_legend()` argument lists, one per geometry type
- [x] Auto-partition mixed layers into polygons / lines / symbols; merge simple
      and classified layers into one entry set; filter classified values to
      those present in the data; title-case via the existing `to_title()`
- [x] Delegate ordering and stacking to `z` / `group_id` / `tm_components()`.
      **Do not reimplement layout** — that is the half tmap 4.4.1 now covers
- [x] Tests on hand-built registry lists, per `test-gq_mapgl_style.R` style

## Phase 4 — Keymap

- [x] `R/gq_tmap_keymap.R` — `gq_tmap_keymap(aoi, context, reg, ...)` returning
      the tmap object plus a `grid::viewport()` spec
- [x] Encode the placement rule as the default rather than the magic numbers
      every copy hardcodes: `x = 1 - width/2 - margin`, `y = height/2 + margin`
- [x] Colours from the registry. All five existing copies hardcode hex here —
      including `lfpr_keymap_survey()`, which duplicates registry rows verbatim
      while taking `reg` as an argument it never uses
- [x] Tests: structure of the returned object and viewport, no rendering

## Phase 5 — Prove it

- [x] **Baseline attempted, then bettered.** Re-render fraser's four site maps from the existing
      cache and keep the PNGs. Compare **pixels, not bytes** (`magick`/`png`) —
      tmap PNGs carry run-varying metadata
- [ ] ~~Rewrite `0420-map-site.R`~~ **deferred to a follow-up PR** — fraser
      installs gq from GitHub, so the helpers must land here first. Equivalence
      is proven numerically below rather than assumed
- [x] Equivalence proven on fraser's real cached rasters: 4 sites, 14.7M cells,
      **max|diff| exactly 0** for aspect, scale breaks and the blend
- [x] Recorded, for the follow-up: do **not** port the three dead functions — `lfpr_grob_north()`,
      `lfpr_convergence()`, `lfpr_label_mapping_code()` are defined and never
      called anywhere in the repo. Also drop the unused `label_max_modelled`
      formal and fix the roxygen documenting a `@param extent` that does not exist
- [x] Update `vignettes/gq-tmap-composition.Rmd` to use the helpers — #17's
      unticked box. Its hardcoded hex (`#2c3e50`, `#ef4545`, `#1a5276`, `grey60`)
      contradicts its own "all colors from registry" claim; fix while there
- [x] Resolve the `tm_scalebar()` contradiction: `findings.md` says it crashes
      (`object 'sbW' not found`), the merged vignette calls it, installed is
      4.4.1. Establish which is true before anything depends on it

## Phase 6 — Land it

- [x] `soul/skills/cartography/SKILL.md` — repoint its tmap blocks at the new
      helpers, and fix the drift found en route: `gq_reg_read_csv()` ×3 (real
      name `gq_reg_custom()`), `reg_csv_custom.csv` (real name `reg_custom.csv`),
      **seven phantom layer keys** that make the tmap legend block and script
      skeleton error today, and an unbalanced fence rendering 19 prose lines as
      R. Same phantom function in `soul/conventions/cartography.md:31`
- [x] `_pkgdown.yml` has no `reference:` index, so no entry needed — verify
- [x] README + CLAUDE.md: composition alongside the style translators
- [x] `NEWS.md` + `DESCRIPTION` 0.4.0 → **0.5.0** as the final commit
- [ ] Close #17. Note on #14 what remains (#18, #19, and the `inst/assets/logo.png`
      line is stale — `inst/logo/nge_icon_200.png` already ships and the vignette
      already uses it)

## Validation

- [ ] `devtools::test()` — 391 existing pass, plus new
- [ ] `lintr` clean on changed files, against the `HEAD` baseline
- [ ] `devtools::check()` no new ERROR/WARNING/NOTE over main (main carries 2
      WARNINGs + 2 NOTEs — gq#51)
- [ ] `/code-check` per commit; PWF checkboxes match landed work
- [ ] `/planning-archive`, then `/gh-pr-push`

## Verification

```r
devtools::load_all()

# the CRS branch the two existing copies disagreed on
b_geo  <- sf::st_bbox(c(xmin=-127,ymin=54,xmax=-126,ymax=55), crs=4326)
b_proj <- sf::st_bbox(c(xmin=1e6,ymin=9e5,xmax=1.1e6,ymax=1e6), crs=3005)
gq_bbox_aspect(b_geo,  7/9)   # cos(lat) applied
gq_bbox_aspect(b_proj, 7/9)   # not applied
# both must return the requested ratio:
asp <- function(b) unname((b["xmax"]-b["xmin"]) / (b["ymax"]-b["ymin"]))

gq_bbox_clip(sf::st_sf(geometry = sf::st_sfc()), b_proj)   # NULL, not 0 rows

leg <- gq_tmap_legend(gq_reg_main(), c("lake", "railway", "roads_dra"))
lengths(leg)          # partitioned by geometry type
```

Cross-repo, the one that matters: fraser's four site maps must re-render
**pixel-identical** from the same cache after the refactor. Capture the baseline
*before* touching `0420`, compare with `magick`, and name every difference.
