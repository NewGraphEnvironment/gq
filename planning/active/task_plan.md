# Task: gq_tmap_style() mislabels classified layers when the data carries a subset of the classes (#53)

`tmap_classified()` (`R/gq_tmap_style.R:88-115`) hands `tm_scale_categorical()`
the registry's **whole** class set. tmap matches colours by *name* but labels by
*position*, and builds its levels from the data — so with 3 of 26 classes
present it takes `labels[1:3]` regardless of which three, and warns in terms
that read as cosmetic.

**Measured before planning.** Rendering and reading the drawn text back out of
the grob tree, on the real registry, `roads_dra`, codes `RU`/`RRD`/`RRC`:

| | drawn legend labels |
|---|---|
| current | `Freeway`, `Highway` |
| truth | `Resource/recreation/other` |

Two findings reshape the issue, both disproving something its body asserts.

**1. No API change is needed.** The issue proposes a `present =` (or `data =`)
argument mirroring `gq_tmap_legend()`. That is not required.
`tm_scale_categorical()` takes `levels` and `levels.drop`, and passing
`levels = names(cls$values)` alongside `labels = cls$labels` makes the
alignment **structural** — both come from the same ordered registry vector, so
they cannot drift no matter what the data holds. Verified pixel-identical to a
correct-by-construction reference, warning gone. This is strictly better than
`present =`, because there is nothing for a caller to remember.

**2. The drawn map was never wrong.** The issue says "as of v0.5.0 the legend
is correct and the layer it describes is not." The opposite is true.
`tmap_classified()` sets `fill.legend = tm_legend(show = FALSE)` on every
classified layer, and colours match by name — so the mislabeled labels were
never rendered by gq's own path. Measured `max|diff| = 0` between current and
fixed with the legend hidden, on both the subset and all-classes cases.

The real impact is therefore narrower and worth stating plainly:

- a spurious warning on **every** classified layer draw, which trains people to
  ignore tmap warnings
- a genuinely wrong legend for any caller who overrides `fill.legend` to show it

Also checked, and **not** broken: the all-classes-present path. tmap orders
levels by the `values` names, not alphabetically, so current and fixed draw
identical labels there. The issue's table is right about that row.

## Approach

Two arguments inside one internal function. No exported signature changes.

```r
tmap::tm_scale_categorical(
  values = cls$values, labels = cls$labels,
  levels = names(cls$values), levels.drop = TRUE
)
```

`levels.drop = TRUE` keeps the shown-legend case honest — only classes the data
carries appear, matching what `gq_tmap_legend(present =)` already does.

Deliberately **not** doing: adding `present =`/`data =` to `gq_tmap_style()` or
`gq_tmap_classes()` (unnecessary, per finding 1); touching per-class `shape`
(that is #16 — `gq_style()` emits `shapes` and nothing consumes it).

## Phase 1 — Failing test first

- [ ] Add a `drawn_labels()` test helper: render via `tmap::tmap_grob()`, walk
      the grob tree, collect `text` grob labels. This is the interop readback
      the issue asks for — 18 existing legend tests inspect our own list and
      none could have caught this (`code-check.md`, "a round-trip through your
      own reader proves nothing")
- [ ] Test: `roads_dra` with `RU`/`RRD`/`RRC` draws only
      `Resource/recreation/other`
- [ ] Test: that path emits no `labels do not have the same length` warning
- [ ] Confirm both fail against current `R/gq_tmap_style.R`

## Phase 2 — Fix

- [ ] `tmap_classified()` — add `levels` + `levels.drop` to all three geometry
      branches (polygon `:94`, line `:100`, point `:107`)
- [ ] Roxygen note on why `levels` is passed: labels align to it positionally,
      so supplying both from one ordered source is what makes it correct
- [ ] Confirm Phase 1 tests pass

## Phase 3 — Registry-wide invariant

Hand-picked fixtures cannot prove this class of fix — the probe used `roads_dra`
alone, and 10 other layers carry classifications.

- [ ] Sweep all 11 classified layers in `reg_main.json`. For each, render a
      subset of its classes and assert every drawn label is a true label **for
      those classes**, and that no recycling warning fires
- [ ] Assert the drawn map is unchanged with the legend hidden (`max|diff| = 0`)
      — the no-regression guarantee for every existing consumer

## Phase 4 — Restore the bug

- [ ] Namespace-patch `tmap_classified()` back to the unfixed call, re-run
      Phases 1 and 3, confirm they fail, restore. Per `code-check.md` — a test
      nobody has seen fail is decoration

## Phase 5 — Land it

- [ ] Correct the **issue body** before merge: the legend-vs-layer claim is
      backwards, and the proposed API is unnecessary. Per the issue-editing
      convention — a premise disproved by measurement gets named, not quietly
      dropped
- [ ] Vignette: state why the two hardcoded `shape =` values stay (#16), per
      the issue's own acceptance wording
- [ ] `NEWS.md` + `DESCRIPTION` 0.5.0 → **0.5.1** (patch: bug fix, no API
      change) as the final commit
- [ ] `/planning-archive`, `/gh-pr-push`

## Validation

- [ ] `devtools::test()` — 527 existing pass, plus new
- [ ] `lintr` clean on changed files, against the `HEAD` baseline
- [ ] `devtools::check()` no new ERROR/WARNING/NOTE over main (main carries 2
      WARNINGs — gq#51)
- [ ] `/code-check` per commit; PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
