# Adversarial review — PR #52 (`17-add-tmap-composition-helpers-and-composi`)

Reviewed at working-tree state of 2026-08-24 (post `c8c8cdf`, plus the
uncommitted edits to `gq_bbox.R`, `gq_scale_breaks.R`, `gq_tmap_legend.R`,
`gq_tmap_keymap.R` that landed during this review).

Load line used for every reproduction below:

```r
pkgload::load_all("/Users/airvine/Projects/repo/gq")
```

Baseline: `devtools::test()` → **FAIL 0 | WARN 1 | SKIP 1 | PASS 544**. Every
finding below is reproduced against that green suite.

**Counts — 3 Blocker, 6 Gap, 1 Acceptance, 2 Assumption, 1 doc nit.**

---

## BLOCKER 1 — `gq_tmap_legend()` emits `lty = NA` and tmap refuses to render it

`R/gq_tmap_legend.R:161` (emission), `R/gq_tmap_legend.R:203` (the drop rule
that lets it through)

`dash_to_lty()` returns `NULL` for a class that is not dashed. Assigning `NULL`
to `row$lty` deletes the element, so `collect_legend()` substitutes `NA`
(`R/gq_tmap_legend.R:188`). The `next` on line 203 drops a property only when
**every** row is `NA`. A classified line layer where *some* classes are dashed
therefore produces `lty = c(NA, NA, …, "dashed")`.

`tm_add_legend()` rejects that vector at draw time. It is not a cosmetic
default — it is a hard error, and it happens in the function's own flagship
example layer.

Five registry layers are affected, all classified lines, including the two
most-used families:

| layer | classes | undashed → NA |
|---|---|---|
| `roads_dra` | 26 | 16 |
| `streams_bt` / `streams_salmon` / `streams_st` | 30 | 15 |
| `streams_all` | 13 | 12 |

### Reproduction

```r
pkgload::load_all("/Users/airvine/Projects/repo/gq")
library(tmap); library(sf)
reg <- gq_reg_main()

leg <- gq_tmap_legend(reg, "roads_dra")$lines
any(is.na(leg$lty))
#> [1] TRUE

pts <- st_as_sf(data.frame(x = c(0, 1), y = c(0, 1)), coords = c("x", "y"), crs = 3005)
m <- tm_shape(pts) + tm_dots() + do.call(tm_add_legend, leg)
png(tempfile()); print(m); dev.off()
#> Error : Values assigned to map variable lty in tm_legend incorrect
```

Lower-level confirmation that `NA` is not a benign "use the default":

```r
png(tempfile()); grid::grid.lines(c(.1,.9), c(.5,.5), gp = grid::gpar(lty = NA)); dev.off()
#> Error in grid.Call.graphics(...) : invalid line type
```

### Why the suite is green

`@examples` for `gq_tmap_legend()` calls `length(roads$lines$labels)` — it never
renders. 18 tests in `test-gq_tmap_legend.R` inspect the returned list and none
hand it to `tm_add_legend()`. This is the *"a round-trip through your own reader
proves nothing about interop"* class from `CLAUDE.md`: the structure is
inspected, the consumer is never asked.

### Fix direction

A parallel-vector legend cannot express "absent" per row — only "solid". Either
have `legend_entries()` emit `"solid"` when any sibling class is dashed, or give
`collect_legend()` a per-property default to substitute instead of `NA`. The
guard immediately above (lines 190–201) already refuses a non-scalar precisely
because it "would give a legend that is wrong rather than absent"; this is the
same failure one branch over, and it is worse because it aborts the render.

Add a test that actually prints:
`expect_no_error(print(tm_shape(pts) + tm_dots() + do.call(tm_add_legend, leg)))`.

---

## BLOCKER 2 — documented `titles` usage errors with "subscript out of bounds"

`R/gq_tmap_legend.R:98`, doc at `R/gq_tmap_legend.R:33-34`

The roxygen says *"Optional named **character vector** of legend titles per
geometry type, e.g. `c(symbols = "Crossings")`"*. `titles[[type]]` is evaluated
for each of `polygons`, `lines`, `symbols` that is present. `[[` on an **atomic
vector** with an unmatched name is an error, not `NULL` — unlike a list. So the
documented call works only when the vector names *every* geometry type in the
result.

### Reproduction

```r
reg <- gq_reg_main()

# a title for one of two present types — the documented shape
gq_tmap_legend(reg, c("lake", "railway"), titles = c(lines = "Rail"))
#> Error in ... : subscript out of bounds

# works only by accident, when the one type named is the only type present
names(gq_tmap_legend(reg, "railway", titles = c(lines = "Rail")))
#> [1] "lines"

# a list is fine — but that is not what the docs say
gq_tmap_legend(reg, c("lake", "railway"), titles = list(lines = "Rail"))$lines$title
#> [1] "Rail"
```

The doc's own example value, `c(symbols = "Crossings")`, fails on any map that
also has polygons or lines — i.e. every real map.

### Fix direction

`titles[[type]]` → `titles[type]`-style lookup that tolerates a miss, e.g.

```r
ttl <- if (!is.null(titles) && type %in% names(titles)) titles[[type]] else NULL
```

…or coerce `titles <- as.list(titles)` once at the top. Same for `present` /
`field` (below) so the three arguments behave alike.

---

## BLOCKER 3 — documented `field` usage errors the same way

`R/gq_tmap_legend.R:79`, doc at `R/gq_tmap_legend.R:31-32`

*"Optional named **character vector** overriding the classification field per
layer"*. `field[[key]]` on an atomic vector missing `key` → error. The whole
point of the argument is per-layer override, so the common case is a vector
naming one layer out of several.

### Reproduction

```r
reg <- gq_reg_main()

gq_tmap_legend(reg, "lake", field = c(roads_dra = "road_type"))
#> Error in ... : subscript out of bounds

# and the realistic multi-layer call
gq_tmap_legend(reg, c("lake", "roads_dra"), field = c(roads_dra = "road_type"))
#> Error in ... : subscript out of bounds

# a list works
names(gq_tmap_legend(reg, "lake", field = list(roads_dra = "road_type")))
#> [1] "polygons"
```

Note `present` (documented as a *list*) is correct — `list(a=1)[["b"]]` is
`NULL`. Verified:

```r
names(gq_tmap_legend(reg, c("lake", "roads_dra"), present = list(roads_dra = "RH1")))
#> [1] "polygons" "lines"
```

So two of the three per-layer arguments are broken and the third is fine, purely
because of the container type the docs chose. Align all three.

---

## GAP 4 — `gq_scale_breaks()` overruns `share` by up to 1.39×, and its guard test cannot fire

`R/gq_scale_breaks.R:53`; test at `tests/testthat/test-gq_bbox.R:169-177`

The roxygen states the reason the function exists:

> The whole bar is sized to `share` of the frame width — *not* `share` per
> interval. Sizing per interval overruns the frame, at which point tmap reports
> "not all scale bar breaks could be plotted"…

But the step is chosen by **nearest** 1/2/5, `nice[which.min(abs(nice - raw/mag))]`,
which rounds *up* as often as down. `share` is therefore a target, not a bound,
and the bar exceeds it routinely.

### Reproduction

```r
chk <- function(w, n = 3, share = 0.35) {
  bb <- sf::st_bbox(c(xmin = 0, ymin = 0, xmax = w, ymax = 1e5), crs = 3005)
  br <- gq_scale_breaks(bb, n, share)
  c(bar_km = max(br), allowed_km = (w/1000) * share, ratio = max(br)/((w/1000)*share))
}
chk(15e3)   #> bar 6    allowed 5.25   ratio 1.143
chk(74e3)   #> bar 30   allowed 25.9   ratio 1.158
chk(150e3)  #> bar 60   allowed 52.5   ratio 1.143
```

Worst case is `raw/mag` just above 3.5 (→ 5) or just above 7.5 (→ 10): ~1.39×
and ~1.32×.

### The test cannot catch it

```r
# tests/testthat/test-gq_bbox.R:169
test_that("gq_scale_breaks keeps the bar within its share of the frame", {
  # The constraint the `share` argument exists for. …
  for (w in c(2e4, 1e5, 4e5, 1e6)) {
    br <- gq_scale_breaks(bb_proj(w = w))
    span_km <- w / 1000
    expect_lt(max(br) / span_km, 0.75)      # <- share is 0.35
  }
})
```

Two independent reasons it is decoration:

1. The threshold is **0.75**, not `share = 0.35`. A bar occupying 2.14× the
   requested share passes.
2. All four widths are ones that happen to round *down*. `1.5e4`, `7.4e4`,
   `1.5e5` all overrun and none is in the set.

This is the `CLAUDE.md` *"a fixture set that cannot reach the failure mode is not
validation"* pattern, with the loosened threshold on top.

### Fix direction

Take the largest nice step **at or below** `raw` (`max(nice[nice <= raw/mag])`,
falling back to `1` and stepping `mag` down), which makes `share` a genuine
bound. Then tighten the test to `expect_lte(max(br)/span_km, share)` and sweep
widths across the whole mantissa range rather than four hand-picked values:

```r
for (w in seq(1e4, 1e6, by = 1e4)) {
  br <- gq_scale_breaks(bb_proj(w = w))
  expect_lte(max(br) / (w/1000), 0.35)
}
```

---

## GAP 5 — a geographic bbox fails silently, not loudly

`R/gq_scale_breaks.R:45`, doc at `R/gq_scale_breaks.R:12-13`

The doc warns *"A geographic bbox has degree spans, so the returned breaks would
not be kilometres."* Nothing enforces it. A 1° box yields breaks of 0.0001 "km"
— 10 cm — with no error, no warning, and a shape (`0, x, 2x, 3x`) that looks
entirely legitimate.

### Reproduction

```r
geo <- sf::st_bbox(c(xmin = -127, ymin = 54, xmax = -126, ymax = 55), crs = 4326)
gq_scale_breaks(geo)
#> [1] 0e+00 1e-04 2e-04 3e-04
```

This matters more than usual here because **the vignette's own bbox is lat/lon**
(`gq_bbox_aspect(neexdzii_wsd, …)` on 4326 data), so the one worked example in
the package is exactly the input this silently mishandles — see GAP 6, where
the vignette hardcodes `breaks = c(0, 2, 4, 6)` rather than calling the helper.

### Fix direction

The check is one line and the information is already on the object:

```r
if (isTRUE(sf::st_is_longlat(bbox))) {
  stop("`bbox` must be projected with metre units; got a geographic CRS. ",
       "Transform it first (e.g. sf::st_transform(x, 3005)).", call. = FALSE)
}
```

`stop` over `warning`: there is no correct interpretation of the result, and a
scale bar reading "0 0.0001 0.0002" on a printed map is a defect that ships.

---

## GAP 6 — the vignette was not moved onto four of the six helpers, but the commit, PR and NEWS say it was

`vignettes/gq-tmap-composition.Rmd`; claims at commit `38f2d64`, PR #52 body,
`NEWS.md:3-12`, `planning/archive/2026-08-issue-17-tmap-composition/README.md`

What the vignette actually adopted (commit `38f2d64`, basemap chunk only):
`gq_bbox_aspect()`, `gq_basemap_tiles()`, `gq_basemap_blend()`.

What it still does by hand, in the very shapes the new helpers' roxygen names as
the thing being replaced:

| helper | vignette still does | line |
|---|---|---|
| `gq_tmap_legend()` | three hand-built `tm_add_legend()` calls with parallel `labels`/`col`/`lwd`/`lty` vectors, plus a manual `road_in <- names(…) %in% unique(…)` filter — which is literally `present =` | 173-175, 253-282 |
| `gq_tmap_keymap()` | a hand-built inset **and** `grid::viewport(x = 0.86, y = 0.12, width = 0.25, height = 0.22)` — the exact hardcoded centre coordinates the keymap roxygen says it exists to compute | 139-150, 307-309 |
| `gq_scale_breaks()` | `tm_scalebar(breaks = c(0, 2, 4, 6))` | 283-288 |
| `gq_bbox_clip()` | `neexdzii_streams[neexdzii_streams$stream_order >= 3, ]` etc. | 80-84 |

### Reproduction

```bash
cd /Users/airvine/Projects/repo/gq
grep -c 'gq_tmap_legend\|gq_tmap_keymap\|gq_scale_breaks\|gq_bbox_clip' \
  vignettes/gq-tmap-composition.Rmd
#> 0
grep -n 'grid::viewport' vignettes/gq-tmap-composition.Rmd
#> 307:print(keymap, vp = grid::viewport(
```

Against which:

- commit `38f2d64` title: *"Prove the helpers against fraser, **move the vignette
  onto them**"* — its own body is accurate ("The vignette basemap chunk now uses
  gq_bbox_aspect(), gq_basemap_tiles() and gq_basemap_blend()"); the title is not.
- PR #52 table: `gq_tmap_legend()` | replaces **gq vignette**, fraser `0420`,
  SKILL.md — the vignette copy is still there.
- PR #52: *"`gq_tmap_keymap()` | replaces 5 copies across 3 renderers"* — the
  gq-vignette copy is still there.
- `NEWS.md`: *"Each replaces three to five copies scattered across the reporting
  repos, **the package's own vignette** and the cartography skill."*
- archive README *Deferred* section is candid about fraser's `lfpr_keymap_survey()`
  staying local, but says nothing about gq's own vignette not adopting four of six.

This is the claim most likely to be believed and least likely to be re-checked —
a future reader greps the vignette for a usage example of `gq_tmap_legend()` and
finds none, having been told it is there.

### Also in this file

**`bbox_sf` is dead.** `vignettes/gq-tmap-composition.Rmd:116` defines
`bbox_sf <- st_as_sfc(bbox)`; nothing consumes it. In the pre-`38f2d64` chunk it
was the argument to `get_tiles()`; the rewrite passes `bbox` directly and left
the assignment behind. The map chunk builds its own `bb_box` at line 159.
Verified: `grep -n 'bbox_sf' vignettes/gq-tmap-composition.Rmd` → 116 only.

### Fix direction

Either move the vignette the rest of the way (it is the package's only end-to-end
proof, and four helpers currently have no worked example anywhere), or soften the
three claims to match `38f2d64`'s body. The first is better: the vignette is the
regression test for these helpers and right now it exercises half of them.

---

## GAP 7 — `gq_tmap_keymap()`'s `margin` is not equal spacing on a non-square canvas

`R/gq_tmap_keymap.R:73` (default), `R/gq_tmap_keymap.R:42-43` (the claim)

The roxygen: *"@param margin Gap between the inset and the frame edge, as a
fraction of the device. **The four-corner convention wants this equal for every
element.**"*

`margin` is a single fraction applied to both axes in `keymap_viewport()`. Device
fractions are per-axis, so on a non-square canvas the horizontal and vertical
gaps differ in real units. The new `asp` argument exists precisely *because* the
canvas is non-square — it corrects `height` and leaves `margin` uncorrected, so
the two halves of the same function disagree about whether the canvas is square.

### Reproduction

```r
# the 9 x 7 canvas the roxygen and fish-passage maps use
m <- 0.03
c(horizontal_in = m * 9, vertical_in = m * 7)
#> horizontal_in   vertical_in
#>          0.27          0.21     # 29% apart
```

Meanwhile `asp` does its job correctly, which is what makes the inconsistency
visible:

```r
w <- 0.25; h <- w * (9/7)
c(inset_w_in = w * 9, inset_h_in = h * 7)
#> 2.25 2.25    # square, as documented
```

### Fix direction

Derive the y margin from `asp` the same way `height` is: `margin_y <- margin * asp`
when `asp` is supplied. Cheap, and it makes the roxygen's claim true.

### Also — `height` is unbounded

```r
0.25 * 5      # gq_tmap_keymap(..., width = 0.25, asp = 5)
#> [1] 1.25    # a viewport taller than the device, silently
```

`asp` is validated as "a single positive number" but nothing checks that
`width * asp + 2 * margin <= 1`. A stop or a warning there costs one line.

### Minor — the `@examples` line reads as a contradiction

```r
#' # on a 9x7 canvas, asp keeps the inset square
#' round(as.numeric(sq$viewport$width) / as.numeric(sq$viewport$height), 3)
```

prints `0.778`, not `1`. The value is correct (device fractions, not inches) but
the comment above it says "square", so the example appears to disprove itself.
Multiply through by the canvas in the example, or say what the number means.

---

## GAP 8 — `gq_bbox_clip()` on an `sfc` fails with an error that names nothing

`R/gq_bbox.R:158`

`nrow()` on an `sfc` is not a row count, so the length-0/NA result reaches `||`
and the guard blows up before any of the function's own logic runs.

### Reproduction

```r
library(sf)
pts <- st_as_sf(data.frame(x = c(0,10), y = c(0,10)), coords = c("x","y"), crs = 3005)
bb  <- st_bbox(c(xmin = -1, ymin = -1, xmax = 1, ymax = 1), crs = 3005)

gq_bbox_clip(st_geometry(pts), bb)
#> Error in ... : missing value where TRUE/FALSE needed
```

Three reasons this is worth a line of code rather than a doc note:

- `sf::st_filter()` — named in the roxygen as the thing being replaced until
  `3a907b4`, and still named in the archive README and PR body — accepts `sfc`.
- The sibling helper **does** accept `sfc`: `gq_basemap_tiles()` opens with
  `box <- if (inherits(bbox, "sfc")) bbox else sf::st_as_sfc(bbox)`.
- The error names neither the argument nor the type.

`if (!inherits(x, "sf")) stop("`x` must be an sf object or NULL", call. = FALSE)`
is enough, or accept `sfc` via `length()`.

### Related, lower — CRS mismatch surfaces from inside sf

```r
gq_bbox_clip(pts, st_bbox(c(xmin=-1,ymin=-1,xmax=1,ymax=1)))   # no crs
#> Error : st_crs(x) == st_crs(y) is not TRUE
```

Same message as `st_filter` would give, so not a regression — but the two
functions in this file are otherwise careful to say what is wrong.

---

## GAP 9 — dead fallbacks in `legend_entries()` for every classified layer

`R/gq_tmap_legend.R:157`, `:160`, `:170`

`gq_style()` **returns early** for a classified layer (`R/gq_style.R:85`), so the
result carries `type` and `classification` and nothing else — no `$stroke`, no
`$mark`. Every fallback in the classified branch that reads them is therefore
unreachable:

```r
reg <- gq_reg_main()
names(gq_style(reg, "roads_dra"))
#> [1] "type"           "classification"
is.null(gq_style(reg, "roads_dra")$stroke)                      #> TRUE
is.null(gq_style(reg, "crossings_pscis_assessment")$mark)       #> TRUE
```

Consequences:

- `row$col <- sty$stroke$color` (line 157) is always `NULL` → **classified polygon
  legend swatches never get an outline colour**, silently. Verified on `fire_severity`, whose legend carries only `type, labels, fill`.
- `pick(cls$widths, j, sty$stroke$width)` (line 160) and
  `pick(sty$classification$radii, j, sty$mark$radius)` (line 170) have fallbacks
  that can never be taken. Harmless today, but they read as live safety and will
  be trusted by the next editor.

Not a blocker — but the comment at 163-168 explains at length *where* the radius
comes from, and the line beneath it still carries a fallback to a field that
cannot exist. Either drop the dead fallbacks or have `gq_style()` carry
`stroke`/`mark` through for classified layers.

---

## ACCEPTANCE 10 — `gq_scale_breaks()` has no test file

Convention (`CLAUDE.md`, *One Function, One File*): *"Each exported function gets
its own R file and its own test file — `R/fl_mask.R` → `tests/testthat/test-fl_mask.R`."*

```bash
ls tests/testthat/ | grep scale
#> (nothing)
grep -c 'gq_scale_breaks' tests/testthat/test-gq_bbox.R
#> 10
```

`R/gq_scale_breaks.R` exists as its own file; its five tests live in
`test-gq_bbox.R`. Every other helper in this PR follows the convention
(`test-gq_bbox.R`, `test-gq_basemap_blend.R`, `test-gq_tmap_legend.R`,
`test-gq_tmap_keymap.R`). Splitting it out is a `git mv`-scale change and it is
where a reader will look after GAP 4.

---

## ASSUMPTION 11 — the vignette does not honour `gq_basemap_tiles()`'s own NULL contract

`vignettes/gq-tmap-composition.Rmd:118-127`

`gq_basemap_tiles()` returns `NULL` with a warning on a failed fetch, and the
roxygen gives the reason: *"Returning NULL lets the caller draw an unshaded map
rather than lose the whole figure."* The vignette — the only caller in the
package — passes the result straight into `gq_basemap_blend()` unguarded, so a
tile-service hiccup during a pkgdown build turns a designed-for degradation into
a build failure from inside terra, two calls downstream of the warning.

### Reproduction

```r
pkgload::load_all("/Users/airvine/Projects/repo/gq")
gq_basemap_blend(NULL, NULL)
#> Error : unable to find an inherited method for function 'nlyr' for signature 'x = "NULL"'
#>         -- nothing in it mentions the tile fetch
```

The network path is live today (both providers fetched fine during this review,
3 bands each, no alpha), so this is a latent CI failure rather than a current
one. It matters because the vignette is where a user copies the pattern from,
and it copies the pattern that discards the guarantee.

Suggested: `if (is.null(positron) || is.null(relief)) { … draw unshaded … }` —
three lines that also *demonstrate* the contract instead of only documenting it.

---

## ASSUMPTION 12 — `gq_tmap_legend()` de-duplicates nothing, and the registry has duplicates

`R/gq_tmap_legend.R:151-173`

`roads_dra` expands to 26 rows of which only 8 are distinct labels:

```r
reg <- gq_reg_main()
labs <- gq_tmap_legend(reg, "roads_dra")$lines$labels
length(labs); length(unique(labs)); table(labs)
#> 26 / 8
#> Resource/recreation/other  x9
#> Lane/driveway/alley        x7
#> Highway                    x3
```

The PR body cites this expansion as a feature — *"merges simple and classified
layers into one legend per geometry type (`railway` + `roads_dra` → one 27-entry
group), which the hand-written pattern gets wrong"*. The count is right (26 + 1 =
27, verified), but a 27-row legend with nine rows reading "Resource/recreation/
other" is not obviously better than what it replaces, and it collides with the
project's own *four-corner / legend over least-important terrain* convention —
27 rows will occupy a quarter of the frame.

Worth noting that the vignette's hand-built version (line 173) filters to values
present in the data, and the helper's `present =` does the same — so the
realistic count is lower. But `present` is optional and the default is the 26-row
legend, which is what `@examples` shows.

Not a defect in the code; flagging it so the decision is deliberate rather than
inherited. A `unique()` on `(label, colour, lwd, lty)` tuples would collapse it,
and is the behaviour a reader would probably expect.

---

## Doc nit — `pad` is applied to both axes, documented as width only

`R/gq_basemap_blend.R:132`

> `@param pad Fraction of the bbox **width** to buffer before requesting.`

The code (`R/gq_basemap_blend.R:~155-160`) computes `dx` from the width and `dy`
from the **height** and applies `pad` to each. On a non-square bbox the vertical
pad is not `pad × width`. One word: *"Fraction of each bbox dimension"*.

---

# Verified clean — do not spend time re-checking these

Probed during this review and found correct. Recorded so the next pass does not
repeat the work.

**`gq_bbox_clip()` — `x[i, , drop = FALSE]` vs `st_filter()`**
- `sf::st_filter.sf` body is
  `dplyr::filter(x, lengths(.predicate(!!x, !!y, ...)) > 0)` with an explicit
  `requireNamespace("dplyr")` stop — the archive README's dplyr claim is
  **accurate**, verified against the installed sf source.
- The default predicate for `st_filter` **is** `st_intersects`, so the swap is
  predicate-identical. No S2/GEOS difference introduced.
- Class and attributes survive `[` for every case tried: plain `sf` →
  `c("sf","data.frame")`; `sf`+tibble → `c("sf","tbl_df","tbl","data.frame")`;
  `agr` preserved; a geometry column named `geom` keeps `attr(,"sf_column") == "geom"`.
  Points, and `crop = TRUE` on points, both behave.
- Only difference found vs `dplyr::filter`: `[` preserves original `row.names`
  where `filter` renumbers. Immaterial for tmap.

**`gq_tmap_legend()` — the cases named in the brief**
- Duplicate keys in `layers` → two identical rows, no error, no silent merge.
- Named vector with *some* names empty → `nzchar` guard at line 74 works;
  the unnamed entry falls back to `to_title(key)`.
- `layers` as a **list**, and as a **factor**, both work.
- `present` as a **factor** works (`%in%` coerces); `present` containing `NA`
  works; `present` matching nothing returns `list()` cleanly.
- A classified layer whose `values` has no names → handled at line 136
  (`nms <- as.character(seq_along(vals))`).
- The non-scalar guard (lines 190-201) fires as documented.
- **Known issue 1 (classified point `size`) is now fixed** by the working-tree
  edit at line 170. Confirmed:
  `gq_tmap_legend(reg, "crossings_pscis_assessment")$symbols$size` → `c(1,1,1,1)`.
  Note the source is `sty$classification$radii`, **not**
  `sty$classification$classes[[k]]$radius` as the original brief stated —
  `gq_style()` never returns a `classes` element (`names()` → `field, values,
  labels, radii, shapes`), so the brief's spelling would have returned `NULL`
  silently. The landed fix uses the right one.

**`gq_bbox_aspect()` — beyond the ±90 issue**
- `cos()` at exactly ±90 gives `6.12e-17`, not `0`, so no division by zero; the
  resulting enormous pad is caught by the new clamp with a warning.
- A mid-latitude of exactly 90 with zero height is rejected earlier by the
  zero-extent guard.
- An already-correct-ratio input is a no-op on the ratio (verified for
  `700 x 900`, `asp = 7/9` → out `0.7778`).
- `margin = 10` (1000%) does not invert anything — the box grows symmetrically
  and stays ordered.
- Geographic case: coordinate ratio `1.339`, **ground** ratio exactly `7/9` —
  the correction is applied in the right direction.
- Margin preserves the ratio (both axes scale by `1 + 2 * margin`).
- `sf` object input (not a `bbox`) works.

**`blend_multiply()`**
- `terra::minmax()` on a fresh **disk-backed** GeoTIFF returns real values, not
  `Inf/-Inf` — the new `!is.finite(top)` stop does **not** fire spuriously.
  (`hasMinMax()` → TRUE; blend on a disk-backed relief returned `137.46`.)
- Multi-band output preserved: 3-band base × 1-band relief → 3-band result.
- The vignette's bit-identical claim holds structurally: the old chunk did
  `mean()` *after* `resample()`, the new one does it *before*. Bilinear resampling
  is linear, so the two commute — the archive README's "max|diff| exactly 0
  across 14.7 million cells" is consistent with the rewrite, not in spite of it.
- Both vignette providers return **3 bands, no alpha, no colour table**
  (`CartoDB.PositronNoLabels` minmax [209,250]; `Esri.WorldShadedRelief`
  [144,255]), so the "averaging an alpha band into luminance" concern does **not**
  reproduce for this vignette. It remains theoretically live for a 4-band
  provider; not worth guarding without a case.

**Packaging**
- All seven functions are exported in `NAMESPACE`.
- `_pkgdown.yml` has **no** `reference:` section, so the index is auto-generated
  — no missing-topic build failure from the new functions.
- `DESCRIPTION` is `0.5.0` and `NEWS.md` leads with `# gq 0.5.0`; consistent.
- `st_as_sfc(bbox, crs = …)` at vignette line 159 is valid — the `bbox` method
  takes `crs`.

**Archive / PR claims that check out**
- `railway + roads_dra → 27 entries` — verified (26 + 1).
- `st_filter` really does require dplyr — verified against sf source.
- Test suite is genuinely green at 544 passing, 0 failing.
