# Findings — gq_tmap_style() mislabels classified layers (#53)

## Pre-plan measurement (2026-08-25)

Four probes run before writing the plan, against tmap 4.4.1 and the real
`reg_main.json`. All scripts written to files rather than `Rscript -e`, per
`code-check.md`.

### The instrument

Pixel comparison turned out to be the wrong tool — it confounds a label change
with legend re-layout, and two of my reference constructions were simply wrong
(both candidate references compared FALSE, which is impossible if one of them
is right). Switched to reading the drawn text straight out of the grob tree:

```r
drawn <- function(m) {
  f <- tempfile(fileext = ".png"); png(f, width = 900, height = 900)
  g <- tmap::tmap_grob(m); dev.off(); unlink(f)
  out <- character(0)
  walk <- function(x) {
    if (inherits(x, "text")) out <<- c(out, as.character(x$label))
    if (!is.null(x$children)) for (ch in x$children) walk(ch)
  }
  walk(g); out
}
```

This is the readback the issue's acceptance criterion asks for, and it is the
only instrument here that answers the question directly rather than by
inference.

### Result 1 — the bug, confirmed exactly

`roads_dra`, codes `RU`/`RRD`/`RRC` (registry positions 20, 22, 24):

| | drawn labels |
|---|---|
| current | `Freeway`, `Highway` |
| with `levels=` | `Resource/recreation/other` |
| truth | `Resource/recreation/other` |

Separately confirmed positional (not name-matched) recycling by pixel identity
against a synthetic 4-class/2-level case: current render was byte-identical to
the *buggy* candidate and differed from the correct one.

### Result 2 — `levels` + `levels.drop` fixes it, no API change

`tm_scale_categorical()` formals include `levels` and `levels.drop`. Passing
`levels = names(cls$values)` alongside `labels = cls$labels` makes alignment
structural: both derive from one ordered registry vector, so they cannot drift
regardless of what the data holds.

- `levels=` alone → correct labels, but the legend lists all 26 classes
- `levels=` + `levels.drop = TRUE` → **pixel-identical** to a
  correct-by-construction reference, no warning

So the `present =` / `data =` API the issue proposes is unnecessary. Better
than unnecessary: an automatic fix cannot be forgotten, and a `present =`
argument can.

### Result 3 — the drawn map was never wrong

`tmap_classified()` sets `fill.legend = tm_legend(show = FALSE)` on every
classified layer, and colours match by *name*. With the legend hidden:

| case | max abs pixel diff, current vs fixed |
|---|---|
| subset (3 of 26) | **0** |
| all 26 present | **0** |

The mislabeled labels were never rendered by gq's own path. This contradicts
the issue's "the legend is correct and the layer it describes is not" — the
layer was correct; the *suppressed* legend was not.

Real impact, therefore:
- a spurious warning on every classified layer draw
- a wrong legend only for a caller who overrides `fill.legend` to show it

Impact is narrower than filed, and the fix is still worth making: the warning
trains people to ignore tmap warnings, and the latent legend defect is real.

### Result 4 — all-classes-present is not broken

Initially suspected the all-present path mislabels too, on the theory that tmap
derives levels alphabetically while the registry order is not alphabetical
(`RF, RRP, RH1, RH2, RA1, RA2…` vs `RA, RA1, RA2, RC1…`). The grob readback
disproved it: current and fixed draw the *same* labels in the same order
(`Freeway | Highway | Arterial | Collector | Local | Lane/driveway/alley |
Resource/recreation/other`). tmap orders by the `values` names, not
alphabetically. The issue's table is right about that row.

Worth recording because a pixel probe had suggested otherwise
(`all-present, fixed == current: FALSE`) — that difference is legend re-layout
under `levels.drop`, with identical text. Reading the labels settled in one
run what pixels had muddied across three.

### Edge cases checked

| case | result |
|---|---|
| data carries a code absent from the registry | no error, no warning |
| data column is a `factor` with reversed levels | correct labels |
| all classes present | no regression |

## Scope

11 layers in `reg_main.json` carry `classification`; 7 have more than 5 classes,
where a data subset is near-certain. `roads_dra` is the worst case — 26 classes
collapsing to 8 distinct labels, so the positional pick is almost never right.

`crossings_pscis_assessment` is the only layer with per-class `radius` and the
only one with per-class `shape`. `shape` is flattened by `gq_style()` and read
by nothing — that is #16, out of scope here.

## Issue context

<!-- full body of #53 as filed, for the record -->

See `gh issue view 53`. Body asserts two things this work disproves; both are
corrected in the issue before merge, per the issue-editing convention:

1. "as of v0.5.0 the legend is correct and the layer it describes is not" —
   backwards (Result 3)
2. the proposed `present =` / `data =` API — unnecessary (Result 2)

## Phase 3 — how much of the registry actually discriminates

The sweep is only meaningful for layers whose positional labels differ from
their true ones. Measured across all 11 classified layers, picking the last 3
classes of each:

| layer | classes | would have drawn |
|---|---:|---|
| `roads_dra` | 26 | Freeway, Highway |
| `streams_bt` / `streams_salmon` / `streams_st` | 30 | Spawning; no known barriers (+2) |
| `bec_zone` | 11 | SBS, ESSF, ICH |
| `land_ownership` | 8 | Crown agency, Crown provincial, Federal |
| `crossings_pscis_assessment` | 4 | Barrier |
| `fire_severity` | 4 | High |
| `roads_ften` | 4 | Forest service road |
| `trails` | 4 | Trail |
| `streams_all` | 13 | — (12 of 13 classes share the label "Stream") |

**10 of 11 discriminate.** `crossings_pscis_assessment` is the one that matters
most in practice — it is the central point layer of every fish passage map, and
a passable crossing would have appeared in a shown legend as "Barrier".

The sweep asserts this count is non-zero. Without that guard every assertion in
it would hold against the unfixed code too, and the sweep would prove nothing.

## The vignette's own data is the reproduction case

`neexdzii_roads` carries 3 of the registry's 26 road classes:

| | |
|---|---|
| codes present | `RA2`, `RH1`, `RLO` |
| true labels | Arterial \| Highway \| Local |
| drawn pre-fix | Freeway \| Highway |

Three classes, two labels — an arterial and a local road both drew as something
they are not, and one label was lost entirely. Rendered before and after with
the namespace patch: the warning is present pre-fix and absent after.

`crossings_pscis_assessment` in the same vignette has all 4 of its classes
present, so it neither warned nor mislabeled — consistent with Result 4.
