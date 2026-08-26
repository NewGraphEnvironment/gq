# Findings — Add symbol size/shape translator for tmap and mapgl (#16)

## How it surfaced

Not from the issue. From looking at the rendered flagship map after #57 removed
the watermark and asking whether the vignette was actually good. It was not: the
crossings were burying the stream network and the habitat widths.

## CORRECTION — the first measurement was circular

The table below was taken with a helper that read `pointsGrob$size` back off the
grob. That returns the value tmap was *handed*, not the ink: R's graphics engine
applies a per-`pch` factor the grob slot never records. Measured properly, off
the rendered SVG primitives:

| pch | shape | mm of ink per size unit |
|---|---|---|
| 21 | circle | **3.810** |
| 22 | square | **3.376** |
| 24 | triangle | **5.129** |
| 8 | star | **5.390** |

So `size = 1` draws a **3.81 mm** circle, not 5.08. Every figure below derived
from 5.08 is wrong by that factor, including the headline: the old `/ 3` divisor
drew a circle **27% oversized**, not 69%. Because base R normalises pch by area
and QGIS by extent, the conversion also has to take the shape.

Caught by the concurrent plan review, which measured the drawn primitive instead
of the grob input. Left below as written so the error is legible.

## Measurements (as first taken — see correction above)

### tmap `size` is a physical unit, canvas-independent

| `size` | drawn diameter | 7x6in | 14x12in | 4x3in |
|---|---|---|---|---|
| 0.12 | 0.61 mm | | | |
| 0.20 | 1.016 mm | | | |
| 0.50 | 2.54 mm | 2.54 | 2.54 | 2.54 |
| 1.00 | 5.08 mm | | | |

`drawn_mm = size * 5.08`, exact and linear. Canvas size does not enter into it,
which is what makes a fixed conversion correct rather than a calibration.

### The registry's `radius` is a diameter in millimetres

`gq_qgs_extract.R:185` reads the QGIS `SimpleMarker` option named **`size`** --
the marker's overall extent -- and stores it under the key `radius`. Every one
of the 130 QML occurrences carries `size_unit = MM`. The field name is a
misnomer inherited at extraction time. Treating it as a true radius would double
every symbol on every map.

### Current state of both backends

| backend | code | implicit factor | correct |
|---|---|---|---|
| tmap | `radius / 3` | 1/3 | `mm / 5.08` |
| mapgl | `radius` raw | 1 | `mm * 1.88976` |

So tmap draws **69% oversized** and mapgl about **1.9x undersized**, and the two
disagree with each other by 3x. Nothing reconciles them.

mapgl's `circle-radius` is a true radius in CSS pixels, so the conversion is
`(mm / 2) * 96 / 25.4`.

### Registry radius distribution

10 distinct values across 17 point layers. `1.8` x1, `2` x5, `2.4` x1, `2.5` x1,
`3` x5 (all one layer's classes), `4` x2, `5` x1, `5.2` x1, `6.6` x1, `7` x2.
Range 1.8-7 mm.

Two point layers have no radius at all and any converter must tolerate it:
`crossings_pscis_modelled_dams` (`rule_based` renderer, no `mark` block) and
`crossings_pscis_assessment` (radius only on the classification).

### Hand-tuned vignette values vs the registry

| layer | registry | `/3` gives | hand-tuned | ratio |
|---|---|---|---|---|
| PSCIS dots (gq-intro) | 3.0 | 1.00 | 0.5 | 0.50x |
| Falls | 2.0 | 0.667 | 0.2 | 0.30x |
| Fish obs | 2.4 | 0.8 | 0.12 | 0.15x |

Every hand value is smaller than `/3`, by ratios spanning 3.3x. No single factor
reproduces them, so "keep today's look" is not achievable without keeping the
per-layer overrides -- which is the thing the issue exists to remove.

Note also `gq-intro.Rmd:176` uses `0.5` on the map and `:186` uses `0.8` for the
legend swatch of the same layer. They already disagree with each other.

## Shape exists and is dropped

The registry stores `mark.shape` and per-class `shape`: `circle` x12, `square`
(`fiss_obstacles`), `star` (`form_pscis`), `triangle`
(`bcfishobs_fiss_fish_observations`). Extracted by `gq_qgs_extract.R:186`,
carried through `gq_style.R:84,92`, and consumed by **no renderer**.
`gq-tmap-composition.Rmd:255` documents this in prose.

`star` has no fillable base-R `pch` -- 21-25 are circle, square, diamond,
triangle-up, triangle-down. `8` draws a star but takes no fill. This needs a
stated decision rather than a silent substitution.

mapgl cannot express shape on a `circle` layer at all; it would need `symbol`
layers with an icon sprite.

## Code surface

The divisor is at `gq_tmap_style.R:181` (`cls$radii / 3`), `:184`
(`cls$radii[1] / 3`), `:244` (`sty$mark$radius / 3`) and `gq_tmap_legend.R:191`.
Four sites, two files. The simple-legend path reaches `:244` indirectly via
`legend_entries()`, so all paths funnel through these four literals.

CLAUDE.md's old claim of "three files" is gone from the file; only
`planning/archive/2026-08-issue-36-classified-axes/task_plan.md:83` still says it.

## Test coverage is one assertion deep

**No test renders a point layer and reads back the drawn symbol size.**
`helper-tmap_render.R`'s `drawn_gp()` defaults to `grob_class = "polyline"` and
is used only for `lwd`/`lty`. The four divisor sites have exactly one numeric
assertion between them: `test-gq_tmap_style.R:66` (`6 / 3 == 2`).

Two tests will need to change, and both were pinning the wrong behaviour:
`test-gq_tmap_style.R:66` and `test-gq_mapgl_style.R:38` (raw pass-through).

`test-gq_tmap_legend.R:330` guards against legend rows that mix shape-bearing
and shapeless entries. Adding shape to `tmap_point_args()` will fire it.
