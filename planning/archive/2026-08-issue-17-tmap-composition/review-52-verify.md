# Verification pass — PR #52 fixes (`17-add-tmap-composition-helpers-and-composi`)

Verifying `749a509` ("Fix 13 defects found by adversarial review") against the
findings in `planning/archive/2026-08-issue-17-tmap-composition/review-52.md`.
HEAD at review time: `5a85d07`.

```r
pkgload::load_all("/Users/airvine/Projects/repo/gq")
```

Suite: **FAIL 0 | WARN 1 | SKIP 1 | PASS 655** (was 544). Vignette knits clean
end to end (`rmarkdown::render`, 15/15 chunks, live tile fetch).

**Counts — 12 of 13 fixed, 1 fixed incompletely. New: 1 Blocker, 5 Gap,
1 Acceptance, 3 Observation.**

---

# Part 1 — the 13, one by one

| # | claim | verdict |
|---|---|---|
| B1 | `legend_na_default` substitutes per-aesthetic defaults | **INCOMPLETE** — see NEW-1 |
| B2 | `titles` `as.list()`-coerced | fixed |
| B3 | `field` `as.list()`-coerced (and `present`) | fixed |
| 4 | largest nice step at or below `raw`; test sweeps 100 widths | fixed |
| 5 | geographic bbox `stop()`s | fixed |
| 6 | vignette moved onto all six helpers; `bbox_sf` removed | fixed, with residue — NEW-3/4/5/6 |
| 7 | `margin_y <- margin * asp`, fit guard, example comment | fixed |
| 8 | `gq_bbox_clip()` accepts `sfc` | fixed |
| 9 | dead `$stroke`/`$mark` fallbacks removed | fixed |
| 10 | `test-gq_scale_breaks.R` split out | fixed, with residue — NEW-7 |
| 11 | vignette guards the NULL contract | fixed for the basemap, not for the clip — NEW-6 |
| 12 | identical rows collapsed (`roads_dra` 26 → 8) | fixed, key is fragile — NEW-2 |
| nit | `pad` documented for both axes | fixed |

## The sentinel values in `legend_na_default` are all genuinely invisible

Your guesses were right, and each is independently sufficient. Measured by
counting dark pixels in a rendered 400x300 legend:

```r
draw <- function(args, f) { png(f, 400, 300)
  print(tm_shape(pts) + tm_dots() + do.call(tm_add_legend, args)); dev.off() }
dark <- function(f) { a <- png::readPNG(f); sum(a[,,1]<0.4 & a[,,2]<0.4 & a[,,3]<0.4) }
```

| legend | dark px | reading |
|---|---|---|
| `symbols size = c(1,1)` | 248 | two swatches |
| `symbols size = c(0,0)` | **54** | text only — `size = 0` draws nothing |
| `symbols fill = c("#00000000","#00000000")`, size 1 | 57 | text only (control) |
| `symbols size = c(1,0)` | 149 | one swatch |
| `polygons col = c("#000000","#000000")`, lwd 4 | 302 | two borders |
| `polygons col = c("#000000","#00000000")`, lwd 4 | **177** | one border — transparent col is invisible |
| `polygons col = c("#000000","#000000")`, lwd `c(4,0)` | **177** | identical — `lwd = 0` is *also* invisible |
| `lines col = c("#000000","#00000000")`, lwd 4 | 81 | one line |
| `lines col = c("#000000","#000000")`, lwd `c(4,0)` | 81 | identical |

So `col`/`lwd` are belt-and-braces: either alone suppresses the mark, and
`lwd = 0` does **not** render as a hairline on this device. `size = 0` lands at
the text-only control (54 vs 57), i.e. no residual dot. No sentinel renders as
black or grey anywhere.

The three real registry mixes all render:

```r
reg <- gq_reg_main()
gq_tmap_legend(reg, "roads_dra")$lines                                   # lty mix   -> RENDER OK
gq_tmap_legend(reg, c("lake", "wetland"))$polygons                       # col/lwd   -> RENDER OK
gq_tmap_legend(reg, c("crossings_pscis_assessment",
                      "bcfishobs_fiss_fish_observations"))$symbols       # size      -> RENDER OK
```

## The rest, verified

**B2/B3** — every container shape now works, including the one neither of us
named (an *unnamed* character vector; `list("x")[["a"]]` is `NULL`, so the
coercion covers it):

```r
names(gq_tmap_legend(reg, c("lake","railway"), titles = c(lines = "Rail")))   #> "polygons" "lines"
gq_tmap_legend(reg, c("lake","railway"), titles = c(lines = "Rail"))$lines$title  #> "Rail"
names(gq_tmap_legend(reg, "lake", field  = c(roads_dra = "x")))              #> "polygons"
names(gq_tmap_legend(reg, "roads_dra", present = c(roads_dra = "RH1")))      #> "lines"
names(gq_tmap_legend(reg, "lake", field = "road_type"))                      #> "polygons"
```

**GAP 4** — `share` is now a bound. Swept 1,240 widths x 6 values of `n`
(7,440 combinations, 1 km to 10,000 km):

```r
bbp <- function(w) sf::st_bbox(c(xmin=0,ymin=0,xmax=w,ymax=1e5), crs=3005)
fails <- 0
for (w in c(seq(1e3,1e5,by=250), seq(1e5,1e7,by=2.5e4))) for (n in 1:6) {
  br <- gq_scale_breaks(bbp(w), n = n)
  if (max(br)/((w/1000)*0.35) > 1 + 1e-12) fails <- fails + 1
}
fails
#> [1] 0
```

The three widths that broke the old rule (`15`, `74`, `150` km, ratios 1.14–1.16)
are all inside that sweep and all pass now. The new test sweeps 100 widths
against `share` itself, which is the right shape.

**GAP 5** — refused, and from an `sf` object too (`st_bbox()` carries the CRS
through):

```r
gq_scale_breaks(sf::st_bbox(c(xmin=-127,ymin=54,xmax=-126,ymax=55), crs=4326))
#> Error : `bbox` must be projected with metre units; got a geographic CRS. …
gq_scale_breaks(sf::st_as_sf(data.frame(x=c(-127,-126), y=c(54,55)),
                             coords = c("x","y"), crs = 4326))
#> Error : `bbox` must be projected with metre units …
```

A bbox with **no** CRS still passes (`st_is_longlat()` → `NA` → `isTRUE()` FALSE
→ treated as projected). That matches `gq_bbox_aspect()`'s stated policy for an
unknown CRS, so it is consistent rather than a hole.

**GAP 7** — the arithmetic is right on the canvas the docs cite. On 7x9
(`fig.width = 7`, `fig.height = 9`, so `asp = 7/9`, which is what the vignette
passes):

```r
width <- 0.25; asp <- 7/9; margin <- 0.03
c(inset_w_in = width * 7,            inset_h_in = width * asp * 9)   #> 1.75  1.75
c(margin_x_in = margin * 7,          margin_y_in = margin * asp * 9) #> 0.21  0.21
```

Square inset, equal gaps. The fit guard fires:

```r
gq_tmap_keymap(aoi, ctx, width = 0.5, asp = 3)
#> Error : inset does not fit: width/height plus margins exceed the device
```

`keymap_viewport()` takes `margin_y` with a `= margin` default, so the
`asp = NULL` path is unchanged.

**GAP 8** — `sfc` in, `sfc` out, both branches, and a real error for anything
else:

```r
gq_bbox_clip(sf::st_geometry(pts), bb)              #> sfc_POINT, length 1
gq_bbox_clip(sf::st_geometry(pts), bb, crop = TRUE) #> sfc_POINT, length 1
gq_bbox_clip(sf::st_sfc(crs = 3005), bb)            #> NULL
gq_bbox_clip(data.frame(a = 1), bb)
#> Error : `x` must be an sf or sfc object, or NULL
```

The `sf` path is untouched — class, `agr` and tibble subclass all still survive
(`c("sf","tbl_df","tbl","data.frame")`), and the terminal check moved to
`length(sf::st_geometry(out))`, which is correct for both.

**GAP 9** — `gq_tmap_legend(reg, "fire_severity")$polygons` now carries exactly
`type, labels, fill`; no phantom `col`.

**GAP 12 / A12** — the collapse is real and conservative. `roads_dra` 26 → 8,
`streams_all` 13 → 2, and because `label` is part of the key it can only ever
merge rows that are identical *including their text*. Confirmed in the rendered
vignette: the road legend reads Highway / Arterial / Local, one row each.

**Doc nit** — `@param pad Fraction of each bbox dimension to expand by before
requesting. Applied to width and height independently.` Matches the code.

---

# Part 2 — new findings

## NEW-1 · BLOCKER — `fill_alpha` is not in `legend_na_default`, so the original render error survives

`R/gq_tmap_legend.R` (`legend_na_default`), fed by `tmap_polygon_args()` in
`R/gq_tmap_style.R`

`legend_na_default` covers `lty, col, lwd, fill, size`. `tmap_polygon_args()`
also emits **`fill_alpha`**, and `tmap_line_args()` emits **`col_alpha`** —
neither is defaulted. Any legend mixing a polygon that has `fill$opacity` with
one that does not produces `fill_alpha = c(0.7, NA)` and fails at draw time with
the identical message the fix was written to eliminate.

This is **not** an edge case. Every classified polygon lacks `fill_alpha`
entirely (`gq_style()` returns early, so there is no `$fill` to read opacity
from), so *any* legend combining a classified polygon with an ordinary one trips
it — which is what most real maps are.

### Reproduction — the realistic shape

```r
pkgload::load_all("/Users/airvine/Projects/repo/gq")
library(tmap); library(sf)
reg <- gq_reg_main()
pts <- st_as_sf(data.frame(x = c(0,1), y = c(0,1)), coords = c("x","y"), crs = 3005)

leg <- gq_tmap_legend(reg, c("lake", "fire_severity"))$polygons
leg$fill_alpha
#> [1] 0.7  NA  NA  NA  NA

png(tempfile()); print(tm_shape(pts) + tm_dots() + do.call(tm_add_legend, leg)); dev.off()
#> Error : missing value where TRUE/FALSE needed
```

### Reproduction — two simple polygons

```r
leg <- gq_tmap_legend(reg, c("conservancy", "pipeline_application"))$polygons
leg$fill_alpha
#> [1] 0.161    NA
# same render error
```

Only two registry polygons lack `fill$opacity` — `pipeline_application` and
`terrestrial_ecosystem_information_scanned_map_boundary` — but combined with the
classified-polygon case above, the whole-registry legend still fails:

```r
keys <- names(reg$layers)                       # all 54 build without error
leg  <- gq_tmap_legend(reg, keys)
sum(is.na(leg$polygons$fill_alpha))
#> [1] 26                                        # of 45 rows
m <- tm_shape(pts) + tm_dots()
for (ty in names(leg)) m <- m + do.call(tm_add_legend, leg[[ty]])
png(tempfile()); print(m); dev.off()
#> Error : missing value where TRUE/FALSE needed
```

The vignette does not hit this only because its two polygons (`lake`, `wetland`)
both carry opacity and it names no classified polygon.

### Fix direction

Add the opacity aesthetics, defaulting to fully opaque — which is what "no
opacity recorded" means:

```r
legend_na_default <- list(lty = "solid", col = "#00000000", lwd = 0,
                          fill = "#00000000", size = 0,
                          fill_alpha = 1, col_alpha = 1)
```

`col_alpha` has no live registry case today (0 of 5 simple line layers carry
`stroke$opacity`), but it is emitted by `tmap_line_args()` on the same
conditional and will behave identically the day one does.

### The test that should have caught it

The gap is that every existing legend test names layers by hand. A sweep is one
`test_that`, and it is the only thing that covers aesthetics nobody thought of:

```r
test_that("every registry layer, and all of them together, render", {
  skip_if_not_installed("tmap")
  reg <- gq_reg_main(); keys <- names(reg$layers)
  leg <- gq_tmap_legend(reg, keys)
  for (a in leg) expect_false(any(vapply(a, function(v) any(is.na(v)), logical(1))))
  # and actually draw it
})
```

Note the NA check alone is enough — no rendering required — because "some rows
have it and some do not" is exactly the condition, and it is cheap.

---

## NEW-2 · GAP — the dedup key is `str()` output, so it depends on numeric formatting and on a global option

`R/gq_tmap_legend.R`, inside `gq_tmap_legend()`:

```r
rows <- rows[!duplicated(vapply(rows, function(r) {
  paste(utils::capture.output(utils::str(r[order(names(r))])), collapse = "|")
}, character(1)))]
```

`str()` is a *display* function. Two of its display conventions leak into
correctness.

### 2a — numerics print at 3 significant digits, so close widths collide

```r
k <- function(r) paste(utils::capture.output(utils::str(r[order(names(r))])), collapse="|")
a <- list(type="lines", label="Road", col="#484848", lwd=1.2345, lty="dashed")
b <- list(type="lines", label="Road", col="#484848", lwd=1.2349, lty="dashed")
identical(k(a), k(b))
#> [1] TRUE            # both render as "$ lwd : num 1.23"
```

Two genuinely different line widths become one legend row, silently. `1.0` vs
`1.04` and `1234.5` vs `1234.9` do *not* collide, so the threshold is precision,
not magnitude.

**No live collision today.** I swept every classified line layer for rows sharing
label + colour + dash whose widths differ beyond 3 s.f. — none. The registry's
whole width vocabulary is
`0.26 0.30 0.40 0.46 0.56 0.86 1.00 1.0348 1.3182 1.70`, and the two 4-decimal
values are far apart. So this is latent, not firing.

### 2b — the key changes if the user has set `options(str = ...)`

```r
a <- list(type="lines", label="Road", col="#484848", lwd=1.32)
b <- list(type="lines", label="Road", col="#484848", lwd=1.03)
identical(k(a), k(b))                                        #> FALSE

old <- options(str = utils::strOptions(digits.d = 1))
identical(k(a), k(b))                                        #> TRUE
options(old)
identical(k(a), k(b))                                        #> FALSE
```

A line in someone's `.Rprofile` changes what `gq_tmap_legend()` returns. That is
the property that makes this worth fixing rather than noting: a package function's
output should not be a function of a display option, and the failure is a *quiet
merge*, not an error.

### 2c — labels truncate at 128 characters

```r
e1 <- list(type="lines", label=paste0(strrep("A",130),"1"), col="#1")
e2 <- list(type="lines", label=paste0(strrep("A",130),"2"), col="#1")
identical(k(e1), k(e2))
#> [1] TRUE            # str()'s nchar.max, "| __truncated__"
```

Registry labels are short, so also latent.

### What does *not* collide (the safe direction)

- `1L` vs `1.0` → `"int 1"` vs `"num 1"` → kept separate.
- A row lacking a property vs a row having it → different element counts → kept
  separate. So dedup runs before `collect_legend()`'s NA substitution and cannot
  merge "absent" with "explicitly the default". That ordering is correct.

### Fix direction

Key on the values, not on their rendering. Full precision, no options, no
truncation, and faster than spawning a text connection per row:

```r
key <- function(r) {
  r <- r[order(names(r))]
  paste(names(r),
        vapply(r, function(v) format(v, digits = 15), character(1)),
        collapse = "\x1f")
}
```

or `vapply(rows, function(r) rlang::hash(r[order(names(r))]), character(1))` if a
hash is preferred — but note `rlang::hash()` serializes, so `1L` and `1.0` stay
distinct there too, which is what you want.

Add a test that pins the option-independence, since that is the part no one will
think to re-check:

```r
test_that("the dedup key does not depend on str() display options", {
  reg <- gq_reg_main()
  before <- gq_tmap_legend(reg, "roads_dra")$lines$labels
  withr::local_options(str = utils::strOptions(digits.d = 1))
  expect_identical(gq_tmap_legend(reg, "roads_dra")$lines$labels, before)
})
```

---

## NEW-3 · GAP — the vignette calls `gq_tmap_keymap()` and throws its map away

`vignettes/gq-tmap-composition.Rmd:309-312`

```r
# gq_tmap_keymap() derives the viewport centre from the corner and margin, and
# sizes the inset off the canvas aspect so it comes out square.
km <- gq_tmap_keymap(neexdzii_wsd, neexdzii_bc, asp = 7 / 9)
print(keymap, vp = km$viewport)
```

`km$map` is discarded; what is printed is `keymap`, the hand-built three-layer
inset from the chunk at lines 145-161, which is still there in full. So the
helper is used for its viewport arithmetic only.

That may well be the right call — the vignette's inset carries BC + watershed
groups + the subbasin, and `gq_tmap_keymap()`'s `(aoi, context)` signature
expresses two. The archive README already says as much about fraser's
`lfpr_keymap_survey()`. But the comment above it does not say so, and the second
clause — *"sizes the inset off the canvas aspect so it comes out square"* — is
describing `km$map`, which is not the object on the next line. `keymap`'s own
aspect is whatever tmap gives it inside a viewport that happens to be square.

Two honest options: print `km$map` (and lose the watershed-group layer), or keep
`keymap` and rewrite the comment to say the helper is supplying placement only.
Either is fine; the current pairing reads as a demonstration of something that
is not happening.

Reproduction that the map is unused:

```bash
grep -n 'km\$' vignettes/gq-tmap-composition.Rmd
#> 312:print(keymap, vp = km$viewport)
```

---

## NEW-4 · GAP — five dead variables left behind by the legend rewrite

`vignettes/gq-tmap-composition.Rmd:180-185`

Same class as the `bbox_sf` you removed last round, five more of them. All fed
the hand-built `tm_add_legend()` calls that `gq_tmap_legend()` replaced:

```bash
for v in xing_cls road_cls road_in road_leg_values road_leg_labels; do
  echo "$v: $(grep -c "\b$v\b" vignettes/gq-tmap-composition.Rmd) line(s)"
done
#> xing_cls: 1          <- definition only
#> road_cls: 4
#> road_in: 3
#> road_leg_values: 1   <- definition only
#> road_leg_labels: 1   <- definition only
```

Precisely: `xing_cls` (line 180) is defined and never used. `road_cls` (182) is
used only by `road_in` (183); `road_in` only by `road_leg_values` (184) and
`road_leg_labels` (185); and neither of those is used by anything. The whole
block at 180-185 is now orphaned — `present = list(roads_dra = unique(neexdzii_roads$road_type))`
does the same job inline at line 273.

It matters more than tidiness here: the block is a hand-rolled `present` filter
sitting nine lines above the call that made it unnecessary, so a reader copying
the vignette copies both.

Verify after removal that lines 175-179 (`stream_sty`, `railway_sty`, `fish_sty`,
`falls_sty`, `lake_sty`) stay — those are all still used for drawing.

---

## NEW-5 · GAP — the closing prose still credits `gq_style()` for the legend

`vignettes/gq-tmap-composition.Rmd:319`

> - **Legend colors** use `gq_style()` — change a color in the registry, every element updates

They no longer do; they use `gq_tmap_legend()`. The bullet directly above it
(*"Classified layers … use `do.call()` with `gq_tmap_style()`"*) is still true,
which makes the stale one easy to skim past.

```bash
sed -n '315,320p' vignettes/gq-tmap-composition.Rmd
```

Same paragraph is worth a second look generally: it is the summary a reader
takes away, and it now under-sells the change (the legend is the most visible
thing that moved onto a helper).

---

## NEW-6 · GAP — the new `gq_bbox_clip()` line is unguarded, in the same chunk that just fixed the same class of bug

`vignettes/gq-tmap-composition.Rmd:133-137`

```r
# Now that the frame is known, drop anything outside it. gq_bbox_clip() returns
# NULL rather than a zero-row object, which is what tm_shape() needs -- it
# errors on an empty geometry set instead of skipping it.
streams_display <- gq_bbox_clip(streams_display, bbox)
```

The comment states the contract correctly and then the code discards it:
`streams_display` goes to `tm_shape()` at line 205 with no `is.null()` test,
which is precisely what the comment says `tm_shape()` cannot take.

```r
png(tempfile()); print(tmap::tm_shape(NULL) + tmap::tm_lines()); dev.off()
#> Error : Specified shp argument of tm_shape is a NULL, which is not a
#>         recognized/supported spatial data class.
```

Ten lines earlier in the same chunk, `basemap_stars` *is* guarded — with a
comment explaining why. The two halves of one chunk model opposite habits.

Not reachable with the bundled data (the bbox is derived from the watershed the
streams are in), so this is a documentation-by-example defect rather than a live
crash. That is also why it will survive every future render.

Cheapest honest fix: wrap the `tm_shape(streams_display)` block in
`if (!is.null(streams_display))`, matching the pattern the file already uses for
`neexdzii_railway`, `neexdzii_fish_obs` and `neexdzii_falls`.

---

## NEW-7 · ACCEPTANCE — the loose scale-breaks test survives next to the strict one, and keeps the comment that claims it is the guard

`tests/testthat/test-gq_scale_breaks.R:22-30` and `:44-52`

Both are now in the file:

```r
test_that("gq_scale_breaks keeps the bar within its share of the frame", {
  # The constraint the `share` argument exists for. Overrun makes tmap drop
  # every label but the last, silently.
  for (w in c(2e4, 1e5, 4e5, 1e6)) { … expect_lt(max(br)/span_km, 0.75) }   # share is 0.35
})

test_that("share is a bound, not a target, across the whole mantissa range", {
  # Rounding to the NEAREST 1/2/5 overran share by up to 1.39x, and the original
  # test could not see it: the threshold was 0.75 against a share of 0.35 …
  for (w in seq(1e4, 1e6, by = 1e4)) { … expect_lte(max(br)/(w/1000), 0.35) }
})
```

The second one's comment explicitly names the first one as the test that could
not see the bug — and the first one is still there, still asserting `0.75`, still
headed *"The constraint the `share` argument exists for."* Two tests with the
same subject and contradictory thresholds, where the weaker one carries the
stronger claim.

Nothing is broken by it. The risk is the ordinary one: someone tightening or
deleting a test picks the wrong one, or reads the 0.75 as the intended contract.
Either delete it, or keep it and change its name and comment to what it now is
(a smoke test on four representative widths).

---

## NEW-8 · OBSERVATION — the vignette map violates the project's own four-corner rule, before and after

Rendered both versions at 7x9in / 150 dpi via `knitr::purl()` + `source()`:

- after: `/tmp/vig_map.png` (HEAD)
- before: `/tmp/vig_map_before.png` (`git show c8c8cdf:vignettes/…`)

**The scale bar is drawn over the bottom of the legend box in both.** In the
"before" render it strikes through *"Fish obs"* and *"Falls"*; in the "after"
render it strikes through *"Falls"*. `tm_scalebar(position = c("center","bottom"))`
lands bottom-left, in the same quadrant as `legend.position = c("left","bottom")`.

**This is pre-existing, not caused by your fixes** — which is the reason I am
recording it rather than filing it against this PR. But it is worth naming
because `CLAUDE.md` states the rule (*"Four-corner rule — legend, logo, scale
bar, keymap each get their own corner. Never stack two in the same quadrant"*)
and its Self-Review checklist asks *"No element overlap?"* — and the vignette is
the package's own worked example of following that convention.

Two other pre-existing items confirmed present in **both** renders, so likewise
not regressions:

- `Warning: labels do not have the same length as levels, so they are repeated`
  x2, from `tm_scale_categorical(values = , labels = )` inside
  `gq_tmap_style()`'s classified path — the registry supplies 26 road classes
  and 30 salmon classes where the data has a handful. Untouched by this PR, but
  it means the *drawn* layers' scales are being label-recycled, which is a
  quieter version of the legend bug you just fixed. Worth its own issue.
- The crossing symbols render very large (registry `radius = 3` → `size = 1`),
  dominating the map.

### What did change visually, and it is an improvement

- The legend gained **"Stream - intermittent"**, a real `streams_all` class the
  hand-built legend omitted entirely.
- Road classes collapsed correctly to Highway / Arterial / Local — `present`
  plus the dedup, working exactly as advertised.
- Symbol swatch sizes now match the drawn symbols (they come from the same
  registry radii) instead of the hardcoded `0.4/0.35/0.4`.
- The scale bar reads `0 2 4 6 km` — **byte-identical to the hardcoded
  `breaks = c(0, 2, 4, 6)` it replaced**, which is the cleanest possible
  confirmation of the GAP 4/5 fix on real data.

---

## NEW-9 · OBSERVATION — the railway legend swatch lost its dash

The hand-built legend drew Railway with `lty = "twodash"`, matching the map,
where the vignette composites a black line plus a white dashed casing
(lines 227-231). The registry-driven legend draws the registry's `railway`,
which is a plain 0.4 solid black stroke:

```r
gq_style(reg, "railway")
#> $stroke$color "#000000" ; $stroke$width 0.4      — no dash, no overlay
gq_tmap_legend(reg, "railway")$lines
#> col "#000000", lwd 0.4                            — no lty
```

Visible in the two renders: dashed before, solid after.

This is the registry being faithful and the *map* being the embellished one —
the casing is the vignette's own hardcoded `lty = "42"`, not something the
registry records. No layer in `reg_main` carries an `overlay` at all:

```r
sum(vapply(names(reg$layers),
           function(k) !is.null(gq_style(reg, k)$overlay), logical(1)))
#> [1] 0
```

So there is nothing for `gq_tmap_legend()` to have read. Recording it because
`CLAUDE.md`'s canonical-format example shows `railway` *with* an `overlay`, so
the day one lands in the registry, `legend_entries()` will need to know what to
do with it — and today it would silently ignore it.

---

## NEW-10 · OBSERVATION — the `else 5 * (mag / 10)` fallback is unreachable

`R/gq_scale_breaks.R`

```r
fits <- nice[nice <= raw / mag]
step <- if (length(fits)) max(fits) * mag else 5 * (mag / 10)
```

Since `mag <- 10^floor(log10(raw))`, `raw / mag` is in `[1, 10)` by construction,
so `1` is always in `fits`. Swept 18,001 spans across nine decades:

```r
hit <- 0
for (w in 10^seq(0, 9, by = 0.0005)) {
  raw <- (w/1000) * 0.35 / 3
  mag <- 10^floor(log10(raw))
  if (!length(c(1,2,5,10)[c(1,2,5,10) <= raw/mag])) hit <- hit + 1
}
hit
#> [1] 0
```

If a floating-point edge ever did make `raw/mag` fall just under 1, the fallback
`mag/2` would still be ≤ `raw` (it needs `raw/mag ≥ 0.5`), so the result stays
sane and the bound still holds — it is safe dead code rather than a trap. Keeping
it as belt-and-braces is defensible; it just deserves a word saying so, since as
written it reads like a case someone hit. `10` being in `nice` is what covers the
opposite edge (an exact power of ten whose `log10` rounds low), and that one *is*
load-bearing.

---

# Part 3 — regressions checked, none found

Everything from the first pass's "verified clean" list, re-run against HEAD:

- `gq_bbox_clip()` on `sf` — class, `agr`, tibble subclass, `geom`-named
  geometry column all still preserved; CRS-mismatch error unchanged.
- `gq_bbox_aspect()` — the ±90 clamp still warns and clamps; projected and
  geographic ratios unchanged; `margin = 10` still does not invert.
- `blend_multiply()` — disk-backed relief still fine (`minmax` computed, no
  spurious `no finite values`); 3-band base preserved.
- `gq_tmap_legend()` — `present` as factor / with `NA` / empty; `layers` as list
  / factor; unnamed names; the non-scalar guard.
- Classified point `size` still lands (`c(1,1,1,1)` for crossings).

**One intentional behaviour change worth naming**, since a downstream caller
could depend on it: duplicate keys in `layers` now collapse.

```r
gq_tmap_legend(reg, c("lake", "lake"))$polygons$labels
#> [1] "Lake"          # was c("Lake", "Lake") before 749a509
```

That is the dedup doing its job, and a caller who lists a layer twice with two
*different* labels still gets two rows (the label is part of the key). Worth a
line in `NEWS.md` all the same.

**One thing I checked because the fix invited it and found clean:** the new
scalebar line reprojects a bbox by transforming its corner polygon —

```r
breaks = gq_scale_breaks(st_bbox(st_transform(st_as_sfc(bbox), 3005)))
```

`CLAUDE.md` warns that transforming a rectangle's corners under-covers the true
extent because the edges bow. Measured against a densified version of the same
polygon on the vignette's actual bbox:

```
corner-transform : 25747.5 x 33138.1 m
densified (0.005 deg) : 25747.5 x 33138.1 m     diff 0.000%
breaks: 0 2 4 6   in both cases
```

Nil at a 0.4-degree extent. It will grow with extent, so it is worth knowing
about if this pattern is copied to a province-scale map, but there is nothing to
fix here.
