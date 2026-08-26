# Task: gq_tmap_style() silently drops the line-width axis of classified layers (#36)

## Context

`tmap_classified()` (`R/gq_tmap_style.R:108-130`) maps **colour** through a
proper per-class scale and then collapses everything else:

```r
if (!is.null(cls$widths)) args$lwd  <- unname(cls$widths[1])   # first class wins
if (!is.null(cls$radii))  args$size <- unname(cls$radii[1]) / 3
# cls$dashes -- never read at all
```

**Measured.** `streams_bt`, reading `lwd` back off the drawn polylines:

| class | registry width | drawn today |
|---|---:|---:|
| `SPAWN;NONE` | 1.70 | 1.70 |
| `REAR;NONE` | 1.00 | **1.70** |
| `ACCESS;NONE` | 0.40 | **1.70** |

The `mapping_code` layers encode **two orthogonal variables**: habitat use drives
width (spawn 1.7 / rear 1.0 / access 0.4), barrier status drives colour. Colour
renders correctly, so half the layer's information silently disappears and the
map looks fine unless you know what the widths should be. The vignette's own
salmon-habitat line (`gq-tmap-composition.Rmd:195`) is the reproducing case, as
is `roads_dra` at `:223` — 26 classes, 4 distinct widths, all drawn at 0.26.

**Dash is the same defect, one step worse.** `cls$dashes` is never read by
`tmap_classified()`, yet `gq_tmap_legend()` *does* emit per-class `lty`
(`R/gq_tmap_legend.R:181`). So as of v0.5.1 the legend draws a dashed key for a
line the map draws solid — 15 of 30 stream classes and 10 of 26 road classes.
Fixing width alone would leave that disagreement in place.

**Verified the fix works, per feature, before planning.** Mapping each axis
through its own `tm_scale_categorical()` keyed on the same field:

| class | reg lwd | drawn | reg dash | drawn lty |
|---|---:|---:|---|---|
| `SPAWN;NONE` | 1.70 | 1.70 | — | solid |
| `REAR;NONE` | 1.00 | 1.00 | — | solid |
| `ACCESS;NONE` | 0.40 | 0.40 | — | solid |
| `SPAWN;NONE;INTERMITTENT` | 1.70 | 1.70 | `0.66;2` | dashed |

This mirrors what colour already does, and what #53 just made correct — the
`levels=` argument is what keeps every axis aligned to the same class order.

### Two of #36's three items are already resolved

- **"Unknown class values abort the render"** — **fixed by #54.** Confirmed by
  restoring the pre-#53 code: a `roads_dra` layer whose data carries `T` (trail,
  present in FWA `transport_line`, absent from the registry) errors with exactly
  the message #36 quotes, and renders fine on current `main`. Nothing to do;
  note it when closing.
- **"`$classification$labels` is positional, not named"** — real, but a
  different defect about a return shape rather than about lost aesthetics.
  Recommend **splitting to its own issue** rather than bundling: it changes an
  exported function's documented output, and this PR's story should stay single.

## Approach

Give each axis the treatment colour already gets. One helper, three call sites.

```r
tmap_axis <- function(cls, v) {
  tmap::tm_scale_categorical(values = unname(v), levels = names(cls$values),
                             levels.drop = TRUE)
}
```

- **width** (line `lwd`) and **radius** (point `size`) are numeric: emit the
  per-class scale only when the vector has no `NA`, else keep today's scalar.
  A partially-populated width is a custom-registry possibility (#42), and a
  half-mapped axis is worse than a documented scalar.
- **dash** (line `lty`): `NA` legitimately means "solid", so no completeness
  rule. Reuse `dash_to_lty()` (`R/gq_tmap_style.R:159`) per class, mapping its
  `NULL` to `"solid"`. **This is the #52 trap in vector form** — `dash_to_lty()`
  returning `NULL` for undashed classes once produced `lty = c(NA, …, "dashed")`
  and tmap rejected the whole vector at draw time.
- Each axis gets `*.legend = tm_legend(show = FALSE)`, matching colour — the
  legend comes from `gq_tmap_legend()`.

Not in scope: `#16` (symbol shape, and the undocumented `radius / 3` divisor
repeated in three files) — that is unit conversion, a different problem from
per-class vs scalar.

## Phase 1 — Failing tests first

- [ ] Extend `tests/testthat/helper-tmap_render.R` with a `drawn_gp()` that
      reads `lwd`/`lty` off the rendered polyline grobs — the #53 helper reads
      text and colours only
- [ ] `streams_bt`: assert each of spawn/rear/access draws at **its own** width.
      Render one feature at a time; a three-feature render returns the right
      *set* in the wrong order and would pass on a coincidence
- [ ] `streams_bt`: assert an `;INTERMITTENT` class draws `lty = "dashed"` and a
      non-intermittent one `"solid"`
- [ ] Classified **point** `size`: `crossings_pscis_assessment` — no classified
      size test exists at all today
- [ ] Confirm all fail on current `main`

## Phase 2 — Fix

- [ ] `tmap_classified()` — per-class `lwd`/`lty` for lines, `size` for points,
      via the shared `tmap_axis()` helper
- [ ] `R/gq_tmap_style.R:184` **existing test `expect_equal(args$lwd, 2)` pins
      the bug** and must change: `mini_registry`'s `road` classes have widths
      2.0 and 1.5, so `lwd` becomes the field name. Update it to assert the
      scale, and say in the commit why the old assertion was wrong
- [ ] Roxygen: `@return` currently promises tmap args; note which axes are now
      per-class and the completeness rule for numeric ones

## Phase 3 — Registry-wide invariant

- [ ] Extend the #53 sweep: for every classified layer carrying widths, assert
      the drawn width equals the registry width **for each class**, not that the
      set matches
- [ ] Assert map and legend now agree on dash — the disagreement this fixes is
      invisible to any test that looks at only one of them
- [ ] Guard against vacuity: assert at least one layer has >1 distinct width,
      else the sweep passes against unfixed code

## Phase 4 — Restore the bug

- [ ] Namespace-patch `tmap_classified()` back, confirm Phases 1 and 3 fail,
      assert the patch took before trusting the result, restore

## Phase 5 — Land it

- [ ] File the `labels`-naming item as its own issue; note in #36 that item 3
      was fixed by #54
- [ ] Vignette: the salmon-habitat and roads lines now render correctly with no
      change to the call — state that in the prose. Reassess whether the manual
      `[[1]]` workaround at `:197-206` is still needed
- [ ] `NEWS.md` + `DESCRIPTION` 0.5.1 → **0.6.0**. Minor, not patch: `args$lwd`
      changes from a number to a field name and the returned list gains
      `lwd.scale`/`lty`/`lty.scale`. `do.call()` callers are unaffected, but the
      documented output shape changes
- [ ] `/planning-archive`, `/gh-pr-push`

## Validation

- [ ] `devtools::test()` — 782 existing pass, plus new
- [ ] `lintr` clean on changed files
- [ ] `devtools::check()` no new ERROR/WARNING/NOTE (main carries 2+2, gq#51)
- [ ] `/code-check` per commit; PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Verification

```r
devtools::load_all()
reg <- gq_reg_main()
args <- gq_tmap_style(reg, "streams_bt", field = "code")
args$lwd        # "code", not 1.7
args$lty        # "code"

# per feature, not per set
for (k in c("SPAWN;NONE", "REAR;NONE", "ACCESS;NONE")) print(drawn_gp(one(k), "lwd"))
#> 1.7 / 1.0 / 0.4
```

Cross-check that matters: re-render the vignette and confirm salmon habitat now
shows three distinct stream weights, and that intermittent reaches are dashed on
the map as well as in the legend.
