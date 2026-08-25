# Third pass — `R/gq_tmap_legend.R` and the vignette only

Verifying `30594b2` ("Fix the incomplete B1 and six more from the verification
pass"). Scope held to the two files named.

```r
pkgload::load_all("/Users/airvine/Projects/repo/gq")
```

Suite **FAIL 0 | WARN 1 | SKIP 1 | PASS 715** (was 655). Vignette knits clean.
Whole-registry legend carries **zero NAs in any aesthetic** and renders.

**Counts — 7 of 7 fixed. New: 2 Gap, 1 Acceptance, 1 Observation. Nothing
blocking; all three actionable items are about making the *next* defect loud
rather than about a defect that is live now.**

Your instinct was right that the third edit is where to look, but not in the way
you expected: I could not find a fourth instance of the bug. What I found is that
the *mechanism* which produced instances two and three is still in place, and
that one of the four new tests cannot fail.

---

# Part 1 — your four questions, answered with evidence

## Q1 — Is `legend_na_default` complete? **Yes. Computed, not eyeballed.**

Extracted the emitted property names from the three arg builders' own bodies
plus `legend_entries()`, and differenced against the default list:

```r
src  <- c(deparse(body(tmap_polygon_args)), deparse(body(tmap_line_args)),
          deparse(body(tmap_point_args)))
emit <- sub("^args\\$", "", unique(unlist(regmatches(src, gregexpr("args\\$[A-Za-z_]+", src)))))
le   <- deparse(body(legend_entries))
emit <- c(emit, sub("^row\\$", "", unique(unlist(regmatches(le, gregexpr("row\\$[A-Za-z_]+", le))))))
setdiff(setdiff(sort(unique(emit)), names(legend_na_default)), c("type", "label"))
#> character(0)
setdiff(names(legend_na_default), emit)
#> character(0)
```

Both directions empty. The union is exactly
`col, col_alpha, fill, fill_alpha, lty, lwd, size`, and `legend_na_default` has
exactly those seven keys — no missing aesthetic, and no dead entry either.

Confirmed dynamically over the whole registry rather than by inspection:

```r
reg <- gq_reg_main(); keys <- names(reg$layers)
leg <- gq_tmap_legend(reg, keys)
#   polygons  rows=45  props with NA: (none)
#   lines     rows=57  props with NA: (none)
#   symbols   rows=20  props with NA: (none)
#   RENDER ALL: OK
```

And over combinations, which is where mixed-aesthetic rows actually meet:

```r
set.seed(1); pairs <- t(replicate(120, sample(keys, 2)))
# 202 legend groups from 120 random pairs; 0 carry an NA
```

The `lake` + `fire_severity` case from last round now returns
`fill_alpha = c(0.7, 1, 1, 1, 1)` and renders.

**But see NEW-1** — the answer is "yes today", and the reason it was "no" twice
is structural rather than a lapse of enumeration.

## Q2 — `legend_key()`: does it separate and join correctly? **Yes, for everything reachable.**

```r
K <- legend_key
K(list(a = NA));   K(list(a = "NA"))     #> "a logical:NA"  /  "a character:NA"     distinct
K(list(a = 1L));   K(list(a = 1.0))      #> "a integer:1"   /  "a double:1"         distinct
K(list(a = TRUE)); K(list(a = "TRUE"))   #> "a logical:TRUE"/  "a character:TRUE"   distinct
K(list(a = factor("a"))) ; K(list(a="a"))#> "a integer:a"   /  "a character:a"      distinct
K(list(a = 1.2345)); K(list(a = 1.2349)) #> "a double:1.2345" / "a double:1.2349"   distinct
K(list(a = list(1)))                     #> "a list:1"       length-1 list is fine
K(list(a = NULL))                        #> "a NULL:NULL"
```

The type prefix is doing real work: it is what keeps `1L` from `1.0` and
`factor("a")` from `"a"`, and `format()` alone would merge both.

**Three collisions exist and none is reachable:**

| collision | why | reachable? |
|---|---|---|
| `NA_character_` vs `"NA"` | both `format()` to `"NA"`, both `typeof()` `"character"` | **No** — `legend_entries()` replaces an `NA` label with `to_title(key)`, and `gq_style()` replaces `NA` class labels with `to_title(keys)`, so no `NA_character_` ever reaches a row |
| `factor("1")` vs `1L` | `typeof(factor)` is `"integer"`, `format()` gives the level | **No** — no registry path produces a factor-valued aesthetic |
| `0.1 + 0.2` vs `0.3` | differ at ~1e-17, below `digits = 15` | **No**, and merging them would be correct for a legend anyway |

**Option and locale stability — verified by measurement, not by reading:**

```r
a <- list(type="lines", label="R", col="#484848", lwd=1.32)
b <- list(type="lines", label="R", col="#484848", lwd=1.03)
identical(K(a), K(b))                                          #> FALSE
withr::with_options(list(str = strOptions(digits.d = 1)), identical(K(a), K(b)))  #> FALSE
withr::with_options(list(digits = 3),                  identical(K(a), K(b)))     #> FALSE
withr::with_options(list(scipen = 100),                identical(K(a), K(b)))     #> FALSE
```

`options(OutDec = ",")` does change the key *text* (`"a double:1,5"`), but it
changes it for every value in the same run, so no pair merges or splits that
would not otherwise. R's `format()` takes its decimal mark from `OutDec`, not
from the C locale, so there is no locale hazard beyond that. Keys are never
persisted or compared across sessions, so consistent-within-a-run is the
property that matters and it holds.

**One separator nit, not a defect.** `paste(names(r), vals, collapse = "\x1f")`
uses the default `sep = " "`, so name and value are joined by a space. A property
*name* containing a space could in principle shift the boundary
(`"a b" + "c"` vs `"a" + "b c"`) — but aesthetic names never contain spaces, and I
confirmed the two do not actually collide as written. Mentioning it only so the
`\x1f` is not mistaken for a complete escaping scheme; `sep = "\x1e"` would close
it for free.

## Q3 — Did removing the five variables break anything in an unrun branch? **No.**

Answered statically, so branch reachability does not matter. Purled the vignette
and walked the whole parse tree collecting every symbol:

```r
knitr::purl("vignettes/gq-tmap-composition.Rmd", output = "/tmp/vg.R", quiet = TRUE)
# ... walk(parse("/tmp/vg.R")) collecting names ...
intersect(c("xing_cls","road_cls","road_in","road_leg_values","road_leg_labels","bbox_sf"), used)
#> character(0)
```

Zero references to any of the six removed names, anywhere in the file, inside or
outside a conditional.

For completeness, every `if (nrow(...) > 0)` branch is in fact TRUE with the
bundled data, so the render did exercise them all:

```
neexdzii_railway  nrow=1     neexdzii_fish_obs nrow=63    neexdzii_falls  nrow=5
neexdzii_lakes    nrow=42    neexdzii_streams  nrow=1074  neexdzii_roads  nrow=44
```

The five `gq_style()` results that remain (`stream_sty`, `railway_sty`,
`fish_sty`, `falls_sty`, `lake_sty`) are all still consumed — 175-179 stay.

## Q4 — Is the `is.null(streams_display)` guard around everything? **Yes, there is only one consumer.**

```bash
grep -n 'streams_display' vignettes/gq-tmap-composition.Rmd
#>  80: streams_display <- neexdzii_streams[neexdzii_streams$stream_order >= 3, ]
#> 137: streams_display <- gq_bbox_clip(streams_display, bbox)
#> 201: if (!is.null(streams_display)) {
#> 203:     tm_shape(streams_display) +
```

Line 203 is the only use and 201 guards it. Nothing else derives from it —
`streams_named` and `stream_labels` come from `neexdzii_streams` directly, not
from `streams_display`, so they are unaffected by the clip either way.

Re-running the basemap chunk is idempotent (clipping an already-clipped set to
the same bbox is a no-op, and `gq_bbox_clip(NULL, bbox)` returns `NULL`), so the
cross-chunk reassignment at 137 is safe.

The keymap comment is now accurate — `keymap` really does carry three
`tm_shape()` calls (BC, watershed groups, subbasin) against `gq_tmap_keymap()`'s
two.

---

# Part 2 — new findings

## NEW-1 · GAP — the completeness of `legend_na_default` is a coincidence, not a check

`R/gq_tmap_legend.R`, `collect_legend()`:

```r
na <- vapply(vals, function(v) is.na(v), logical(1))
if (all(na)) next
if (any(na) && !is.null(legend_na_default[[p]])) {
  vals[na] <- legend_na_default[[p]]
}
out[[p]] <- unlist(vals, use.names = FALSE)
```

When a property has *some* NAs and **no entry in the lookup table**, the
condition is FALSE and the NA is passed straight through to `tm_add_legend()` —
which is the exact failure mode of rounds two and three. The set difference is
empty today (Q1), so nothing is broken now. But the code cannot tell you that:
the invariant "every emitted aesthetic has a default" is enforced by two
independent lists happening to agree, and both have been edited three times.

### Reproduction

```r
pkgload::load_all("/Users/airvine/Projects/repo/gq")
rows <- list(list(type = "symbols", label = "A", fill = "#111111", shape = 21),
             list(type = "symbols", label = "B", fill = "#222222"))
collect_legend(rows)$shape
#> [1] 21 NA
```

No error, no warning — the same silent NA that took two rounds to find, in the
same function, one property over.

### `shape` is the near-term case, not a hypothetical

The registry already carries shape data that nothing reads yet:

```r
reg <- gq_reg_main()
sum(vapply(names(reg$layers),
           function(k) !is.null(gq_style(reg, k)$mark$shape), logical(1)))
#> [1] 15                                     # simple point layers with a shape
gq_style(reg, "crossings_pscis_assessment")$classification$shapes
#>   BARRIER  PASSABLE POTENTIAL   UNKNOWN
#>  "circle"  "circle"  "circle"  "circle"
```

And the vignette hardcodes `shape = 24` and `shape = 22` for fish observations
and falls (lines 244, 251) *because* gq does not translate shape yet. So "wire
`shape` through `tmap_point_args()`" is an obvious next commit, 15 layers carry
the data, and the moment it lands with a layer that lacks a shape in the same
legend, the render error returns — silently, from a lookup table nobody thought
to update.

### Fix direction — make the guard fail loud

Two lines, and it converts the fourth instance from a cryptic tmap error into a
self-naming one at construction:

```r
if (any(na)) {
  if (is.null(legend_na_default[[p]])) {
    stop("Legend property '", p, "' is missing on entry ",
         paste(which(na), collapse = ", "),
         " and has no entry in `legend_na_default`. Add one.", call. = FALSE)
  }
  vals[na] <- legend_na_default[[p]]
}
```

This is the same shape as the non-scalar guard directly above it — which already
chooses "refuse rather than produce something wrong" for exactly this reason.
The NA branch is the only place in the function that still prefers silence.

Per `CLAUDE.md` ("*prove the alarm can fire*"), pair it with a test that removes
a key and asserts the stop. I verified the mechanism works by patching the
namespace:

```r
ns <- asNamespace("gq"); orig <- get("legend_na_default", ns)
unlockBinding("legend_na_default", ns)
assign("legend_na_default", orig[setdiff(names(orig), "fill_alpha")], ns)
# whole-registry legend: 1 property now carries NA   <- would stop() with the fix
assign("legend_na_default", orig, ns); lockBinding("legend_na_default", ns)
```

---

## NEW-2 · GAP — `legend_key()` now pre-empts the non-scalar guard, so the good error message is unreachable

`R/gq_tmap_legend.R` — `legend_key()` runs inside `gq_tmap_legend()`'s dedup,
which is *before* `collect_legend()`.

`c8c8cdf` added this deliberately, and documented who it is for:

> Refuse a non-scalar rather than flatten it. […] Every registry property is
> scalar today, so nothing built from a registry can trip this; **it guards
> hand-built rows.**

`legend_key()`'s `vapply(r, ..., character(1))` sees those hand-built rows first
and dies with a message that names neither the property nor the entry:

```r
rows <- list(list(type = "lines", label = "A", lwd = c(1, 2)),
             list(type = "lines", label = "B", lwd = 1))

vapply(rows, legend_key, character(1))
#> Error : values must be length 1,
#>          but FUN(X[[1]]) result is length 2

collect_legend(rows)                                   # what you get if you skip the dedup
#> Error : Legend property 'lwd' is not length 1 for entry 1
```

The second message is the one that was written for this case and it is now dead
code on the only path that reaches it. Not reachable from the registry, so
nothing is broken — but the guard has quietly become decoration, which is the
state it was added to escape.

### Fix direction

Either check scalarity before the dedup:

```r
rows <- Filter(function(e) identical(e$type, type), entries)
if (length(rows) == 0L) next
for (r in rows) {                                   # or a vapply
  long <- lengths(r) != 1L
  if (any(long)) stop("Legend property '", paste(names(r)[long], collapse = "', '"),
                      "' is not length 1", call. = FALSE)
}
```

…or make `legend_key()` tolerant, which is one word:

```r
vapply(r, function(v) paste0(typeof(v), ":",
                             paste(format(v, digits = 15), collapse = ",")),
       character(1))
```

The second is smaller and keeps `collect_legend()`'s message as the single place
that explains the rule.

---

## NEW-3 · ACCEPTANCE — the `options(str=)` test cannot fail

`tests/testthat/test-gq_tmap_legend.R`:

```r
test_that("the dedup key does not depend on str() display options", {
  reg <- gq_reg_main()
  before <- gq_tmap_legend(reg, "roads_dra")$lines
  old <- options(str = utils::strOptions(digits.d = 1))
  on.exit(options(old), add = TRUE)
  expect_identical(gq_tmap_legend(reg, "roads_dra")$lines, before)
})
```

I restored the **old, buggy** `str()` key in the namespace and re-ran the
assertion. It still passes:

```r
ns <- asNamespace("gq")
str_key <- function(r) paste(utils::capture.output(utils::str(r[order(names(r))])),
                             collapse = "|")
unlockBinding("legend_key", ns); assign("legend_key", str_key, ns)

reg <- gq_reg_main()
before <- gq_tmap_legend(reg, "roads_dra")$lines
old <- options(str = utils::strOptions(digits.d = 1))
identical(gq_tmap_legend(reg, "roads_dra")$lines, before)
#> [1] TRUE          <- the assertion holds for the BROKEN implementation
```

Why: `roads_dra`'s widths are `0.26 0.46 1.0348 1.3182`, which stay distinct even
at one decimal, and its rows differ in colour and label anyway. The fixture
cannot reach the failure mode — the same pattern as the 0.75 scale-breaks
threshold from round one, and the third time in this PR that a test's subject and
its fixture have come apart.

The sibling test ("close-but-distinct widths are not merged") *does* fire —
verified: with the `str()` key it returns 1 row instead of 2. So the file has one
working alarm and one that only looks like one.

### Fix — route it through the synthetic layer, not the registry

I searched for a width pair that collides under `digits.d = 1` but not under the
value key, and verified the alarm:

| widths | `str()` key @ `digits.d=1` | `str()` key, default | `legend_key()` |
|---|---|---|---|
| 1.2345 / 1.2349 | 1 row | **1 row** | 2 rows |
| **1.32 / 1.34** | **1 row** | 2 rows | **2 rows** |
| 1.32 / 1.03 | 1 row | 2 rows | 2 rows |
| 0.46 / 0.44 | 2 rows | 2 rows | 2 rows |

`1.32 / 1.34` is the one you want — it isolates the *option* sensitivity
specifically (the default-options `str()` key gets it right; only `digits.d = 1`
merges it), where `1.2345 / 1.2349` is already covered by the widths test.

```r
test_that("the dedup key does not depend on str() display options", {
  layer <- list(type = "line", classification = list(field = "f", classes = list(
    A = list(color = "#484848", width = 1.32, label = "Road"),
    B = list(color = "#484848", width = 1.34, label = "Road")
  )))
  before <- gq_tmap_legend(mini(x = layer), "x")$lines
  withr::local_options(str = utils::strOptions(digits.d = 1))
  expect_identical(gq_tmap_legend(mini(x = layer), "x")$lines, before)
  expect_length(before$labels, 2L)      # and pin the count, so a merge is caught
})
```

Both `1.32` and `1.03` (the pair named in your own comment on that test) work as
well — the fixture idea was right, only the routing through real registry data
defeated it.

---

## NEW-4 · OBSERVATION — the closing bullet list still says something false, in the bullet you did not rewrite

`vignettes/gq-tmap-composition.Rmd:320`

> - **Simple layers** (lake, wetland, streams, railway) use `gq_tmap_style(reg, "name")` directly

Two errors, both pre-existing (identical at `c8c8cdf`), so not caused by this
round — but the paragraph was edited this round and this is the bullet directly
above the one that was fixed:

1. **`streams` and `railway` do not use `gq_tmap_style()`.** Streams are drawn at
   lines 201-206 with `tm_lines(col = stream_sty$classification$values[[1]], …)`,
   railway at 226-232 with `tm_lines(col = railway_sty$stroke$color, …)`. Only
   `lake` and `wetland` of the four go through `gq_tmap_style()`.
2. **`streams_all` is not a simple layer.** It is classified — which is why the
   code reaches into `$classification$values[[1]]` to pull one class out, and why
   the legend for it produced two rows (`Stream`, `Stream - intermittent`). The
   in-code comment at line 197 calls it "simple style" for the same reason.

```bash
sed -n '318,323p' vignettes/gq-tmap-composition.Rmd
git show c8c8cdf:vignettes/gq-tmap-composition.Rmd | sed -n '314p'   # same text
```

The second and third bullets are accurate. Suggested rewrite of the first:

> - **Simple layers** (lake, wetland) use `gq_tmap_style(reg, "name")` directly.
>   Streams and railway are drawn by hand because each needs something the
>   registry does not model — one class pulled out of a classified layer, and a
>   white casing over a black line.

Which is also a more honest advertisement, since it names the two gaps.

---

# Part 3 — the seven, confirmed

| # | fix | verdict |
|---|---|---|
| 1 | `fill_alpha = 1`, `col_alpha = 1` added | **fixed** — set difference empty both ways; 0 NAs across all 54 layers, all-together, and 202 groups from 120 random pairs; whole-registry legend renders |
| 2 | `legend_key()` replaces the `str()` digest | **fixed** — full precision, type-prefixed, immune to `str`/`digits`/`scipen`; three residual collisions all unreachable |
| 3 | whole-registry NA sweep test | **fixed, and the alarm fires** — removing `fill_alpha` or `lty` from the defaults makes it report a NA-carrying property |
| 4 | whole-registry render test | **fixed** — renders (with a benign tmap "components too high, rescaling" message) |
| 5 | `options(str=)` test | **passes, but cannot fail** — NEW-3 |
| 6 | close-but-distinct widths test | **fixed, and the alarm fires** — 1 row under the `str()` key, 2 under `legend_key()` |
| 7 | vignette: 5 variables removed, `streams_display` guarded, keymap comment, closing prose | **fixed** — Q3/Q4 above; one older bullet still wrong, NEW-4 |

`test-gq_scale_breaks.R`'s loose test is now named
`"gq_scale_breaks stays well inside the frame at representative widths"`
rather than claiming to be the `share` guard — that reads correctly against the strict
sweep beside it.

`NEWS.md` is accurate: duplicate keys do collapse, and a layer named twice with
two different labels does still yield two rows, because the label is in the key.

---

# Verdict

**Merge-able.** Nothing here blocks: NEW-1 and NEW-2 are latent, NEW-3 is a test
that passes for the wrong reason, NEW-4 is prose that predates the branch.

If you want one thing before merging, make it **NEW-1** — it is four lines and it
is the only one of the three that would have caught rounds two and three by
itself. NEW-3 is the natural companion (a test that cannot fail is the other half
of the same problem), and both are small enough to land together.
