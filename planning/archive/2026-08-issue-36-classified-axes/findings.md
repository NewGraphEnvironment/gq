# Findings — classified layers lose every axis except colour (#36)

## Pre-plan measurement (2026-08-26)

### The defect, per feature

`streams_bt`, reading `lwd` off the drawn polyline grobs one feature at a time:

| class | registry width | drawn today |
|---|---:|---:|
| `SPAWN;NONE` | 1.70 | 1.70 |
| `REAR;NONE` | 1.00 | **1.70** |
| `ACCESS;NONE` | 0.40 | **1.70** |

`tmap_classified()` emits `lwd = unname(cls$widths[1])` — the *first registry
class*, not anything derived from the data. Because `SPAWN;NONE` happens to be
first, every reach draws at spawning width.

### Why it matters more than a wrong number

The `mapping_code` layers encode **two orthogonal variables** in one composite
class key, `<habitat use>;<barrier status>[;INTERMITTENT]`:

- habitat use → **width** (SPAWN 1.7, REAR 1.0, ACCESS 0.4)
- barrier status → **colour** (NONE `#129bdb`, MODELLED `#ff9f85`,
  ASSESSED `#ef4545`, DAM `#ae7dd6`, REMEDIATED `#33a02c`)
- intermittency → **dash**

Colour renders correctly. So exactly half the information the layer carries
disappears, and the map looks entirely plausible unless you already know what
the widths should be. That is the same "wrong in a way that looks fine" shape as
#53, one axis over.

### Dash: the map and the legend already disagree

`cls$dashes` is never read by `tmap_classified()` at all, but
`gq_tmap_legend()` *does* emit per-class `lty` (`R/gq_tmap_legend.R:181`, added
by #32). As of v0.5.1 the legend therefore draws a dashed key beside a line the
map draws solid — 15 of 30 stream classes, 10 of 26 road classes.

That disagreement is invisible to any test that inspects only one of the two,
which is why it survived #32 and #52.

### The fix, verified per feature before planning

Mapping each axis through its own `tm_scale_categorical()` on the same field:

| class | reg lwd | drawn | reg dash | drawn lty |
|---|---:|---:|---|---|
| `SPAWN;NONE` | 1.70 | 1.70 | — | solid |
| `REAR;NONE` | 1.00 | 1.00 | — | solid |
| `ACCESS;NONE` | 0.40 | 0.40 | — | solid |
| `SPAWN;NONE;INTERMITTENT` | 1.70 | 1.70 | `0.66;2` | dashed |
| `ACCESS;ASSESSED;INTERMITTENT` | 0.40 | 0.40 | `0.66;2` | dashed |

**Rendering all three at once returns the right set in the wrong order** — the
grob walk yields draw order, which is level order, not feature order. Tested one
feature at a time for that reason; a three-feature assertion would have passed
on a coincidence.

## Two of #36's three items are already resolved

### Item 3 — "unknown class values abort the render" — fixed by #54

#36 reports `roads_dra` erroring on FWA `transport_line`'s `T` (trail) with
`All levels should occur in the vector names of values: T are missing`.
Confirmed by restoring the pre-#53 code in the namespace:

| | result |
|---|---|
| post-#53 (current `main`) | rendered OK |
| pre-#53 (bug restored) | `ERROR: All levels should occur in the vector names of values: T are missing` |

Passing `levels = names(cls$values)` is what fixed it — tmap no longer derives
levels from the data, so a value absent from the registry no longer contradicts
the scale. An unplanned benefit of #54; nothing to do here beyond noting it.

### Item 2 — `labels` is positional, not named — split out

Real, and it does cause `labels[c("RRD","RU")]` to return `NA`. But it is a
return-shape question rather than a lost-aesthetic one, and `gq_style()` unnames
deliberately: `tm_scale_categorical()` matches `values` by name and `labels` by
position, so a named vector would misrepresent how it is consumed.

Blast radius if changed: 4 test assertions (`test-gq_style.R:39`, `:115`,
`test-gq_tmap_style.R:105`, `:150`). Small, but a different story — filed
separately to keep this PR's single.

## Registry inventory

11 classified layers. Which axes each carries:

| layer | type | classes | width | dash | radius |
|---|---|---:|---|---|---|
| `streams_bt` / `streams_salmon` / `streams_st` | line | 30 | all | 15/30 | — |
| `roads_dra` | line | 26 | all | 10/26 | — |
| `streams_all` | line | 13 | all | 1/13 | — |
| `roads_ften` | line | 4 | all | — | — |
| `trails` | line | 4 | all | all | — |
| `crossings_pscis_assessment` | point | 5 | — | — | all |
| `bec_zone`, `land_ownership`, `fire_severity` | polygon | 11/9/5 | — | — | — |

Distinct widths: `roads_dra` 4 across 26 classes; streams 3; `trails` 3;
`roads_ften` 2; `streams_all` 2. Every line layer loses a real axis today.

## Known trap being re-entered

`dash_to_lty()` (`R/gq_tmap_style.R:159`) returns `NULL` for an undashed class.
In #52 that produced `lty = c(NA, …, "dashed")` and tmap rejected the whole
vector **at draw time**, invisible to 18 structure-inspecting tests. The vector
form here must map `NULL` → `"solid"` explicitly.

## Phase 5 — the vignette, measured against shipped data

| layer | classes present | registry widths | drawn | drawn lty |
|---|---:|---|---|---|
| salmon habitat | 12 of 30 | 0.4, 1.0, 1.7 | 0.4, 1.0, 1.7 | dashed, solid |
| `roads_dra` | 3 of 26 | 0.46, 1.035 | 0.46, 1.035 | solid |

The call sites did not change — `do.call(tm_lines, gq_tmap_style(...))` is the
same line it always was. Only what it draws changed.

The `[[1]]` block at `gq-tmap-composition.Rmd:197-206` **is not** a workaround
for this bug and stays: it deliberately draws base streams at one uniform
colour and width, scaled `* 2` for display, on top of the classified habitat.
