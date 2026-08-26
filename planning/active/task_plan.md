# Task: Add symbol size/shape translator for tmap and mapgl (#16)

Every point symbol on gq's flagship map is on a different scale:

| layer | registry | source of `size` | drawn |
|---|---|---|---|
| PSCIS crossings | 3.0 mm | registry, `radius / 3` | **1.00** |
| Falls | 2.0 mm | hardcoded in the vignette | 0.20 |
| Fish observations | 2.4 mm | hardcoded in the vignette | 0.12 |

The crossings draw **5× the falls and 8× the fish observations**, burying the
stream network and the three per-class habitat widths that v0.6.0 exists to
render.

**The issue's stated premise is false and must be corrected at merge.** #16 says
a registry radius of 2.4 "becomes nearly invisible" — symbols too *small*. The
opposite is true: `radius / 3` draws them **69% oversized**. The premise died
when the `/ 3` divisor was introduced.

## What measurement settled

**1. tmap `size` is a physical unit.** `drawn_mm = size × 5.08`, exactly linear
and **canvas-independent** (verified at 7×6, 14×12 and 4×3 in). The conversion
is arithmetic, not calibration — `/ 3` is simply the wrong constant.

**2. The registry value is a diameter in millimetres; "radius" is a misnomer.**
`gq_qgs_extract.R:185` reads the QGIS `SimpleMarker` option named **`size`** —
the marker's overall extent — and stores it as `radius`. All 130 QML occurrences
carry `size_unit = MM`. Treating it as a true radius would double every symbol.
⇒ **tmap: `size = mm / 5.08`.**

**3. mapgl is wrong in the other direction.** `gq_mapgl_style.R:86` passes the
value through raw as `circle-radius`, which MapLibre reads as a **radius in
pixels**. The backends disagree by 3× and neither is right.
⇒ **mapgl: `circle-radius = (mm / 2) × 96 / 25.4`**, i.e. `mm × 1.88976`.

**4. Shape is already in the registry and every renderer drops it.** `circle`
×12, `square`, `star`, `triangle` on marks. Extracted, carried, consumed by
nothing — `gq-tmap-composition.Rmd:255` says so out loud.

**5. The divisor lives in 4 sites across 2 files** — `gq_tmap_style.R:181,184,244`
and `gq_tmap_legend.R:191`.

**6. Nothing renders a point and measures it.** The whole size pipeline has
**one** numeric assertion behind it: `test-gq_tmap_style.R:66` (`6/3 == 2`).

## Approach

`gq_symbol_size(radius, target, scale)` and `gq_symbol_shape(shape, target)` as
the single place unit conversion happens; route all four divisor sites and the
mapgl path through them.

**Default is QGIS-true 1:1** — user-approved. `scale` is a uniform multiplier for
when a dense map needs everything smaller: one number applied once, instead of
per-layer guessing. That is the knob the issue was really asking for.

Visible consequences, stated up front:

- PSCIS crossings **shrink 41%** (1.00 → 0.59) — they stop dominating
- Falls **double** (0.20 → 0.39)
- Fish observations **quadruple** (0.12 → 0.47)

Whether the map then reads as too busy is a question only rendering answers —
Phase 5.

## Phase 1 — Failing tests first

- [x] Extend `helper-tmap_render.R` with a points-grob reader returning drawn
      **mm** (`convertUnit(x$size, "mm")`), the missing half of `drawn_gp()`
- [x] Pin the tmap constant by measurement, not by faith: assert `size = 1` draws
      5.08 mm and is unchanged across two canvas sizes. If tmap ever changes
      this, that test names the cause
- [x] Assert a registry layer renders at its QGIS millimetre size: `fiss_obstacles`
      (2 mm) and `bcfishobs_fiss_fish_observations` (2.4 mm) — measured on `main`
      at **3.39 mm** and **4.06 mm**, i.e. 70% and 69% oversized
- [x] `gq_symbol_size()` unit cases incl. `scale`, and `NULL`/`NA` radius —
      `crossings_pscis_modelled_dams` is `rule_based` with no `mark` at all
- [x] `gq_symbol_shape()` for all four registry values, both targets
- [x] Confirm every new test fails on current `main` — 9/9 fail; the two
      end-to-end cases fail as *Failures* (rendered, wrong millimetres), not as
      missing-function errors

**Found while writing these:** `tmap_options(scale = )` multiplies the drawn
size — `scale = 2` gives 10.16 mm. So 5.08 is the constant *at the default
scale*, any absolute-millimetre assertion must pin it, and gq deliberately does
not compensate: a caller scaling a whole map expects symbols to scale with the
text. `local_tmap_scale()` added to the helper.

## Phase 2 — The converters

- [ ] `R/gq_symbol.R`: `gq_symbol_size()`, `gq_symbol_shape()`, exported
- [ ] Constants named and documented with the measurement that produced them —
      `5.08 mm` per tmap size unit, `96/25.4` px per mm. A bare `/ 5.08` in the
      body is the same unexplained magic number as `/ 3`
- [ ] `star` has no fillable base-R `pch` (21–25 are circle/square/diamond/
      triangle-up/triangle-down). Decide and document: `8` renders a star but
      takes no fill. Do not silently substitute a circle
- [ ] Roxygen states plainly that the registry's `radius` is a **diameter**

## Phase 3 — Route every site through them

- [ ] `gq_tmap_style.R:181,184,244` and `gq_tmap_legend.R:191` — all four
- [ ] `gq_mapgl_style.R:86` — currently raw mm as pixel radius
- [ ] `test-gq_tmap_style.R:66` pins the old divisor (`6/3 == 2`) and must
      change; say in the commit why the old assertion was wrong
- [ ] `test-gq_mapgl_style.R:38` asserts pass-through — same
- [ ] Add shape to `tmap_point_args()`. **`test-gq_tmap_legend.R:330` guards
      against rows that mix shape-bearing and shapeless** — that guard will fire

## Phase 4 — Vignettes drop their hand-tuned constants

- [ ] `gq-tmap-composition.Rmd:261,268` — fish obs and falls stop hardcoding
      `size` and `shape`, and the `#16` comment at `:255` goes
- [ ] `gq-intro.Rmd:176,186` — PSCIS dots (`0.5`) and the legend swatch (`0.8`),
      which currently disagree with each other

## Phase 5 — Verify by looking

- [ ] Render both vignettes, extract the figures, **read them**
- [ ] Confirm the crossings no longer bury the stream network, and that the three
      habitat widths (0.4 / 1.0 / 1.7) are finally visible
- [ ] If 1:1 reads too busy, set a package default `scale` — and record the
      render that justified the number, not a preference
- [ ] Re-check `cartography.md`'s seven-point list

## Phase 6 — Land it

- [ ] Correct #16's body: the "nearly invisible" premise is false, and the
      measured conversion replaces the guessed one
- [ ] `NEWS.md` + `DESCRIPTION` 0.7.0 → **0.8.0**. Minor: every point layer's
      rendered size changes, and two exports are added
- [ ] Note what is still not done — mapgl cannot express shape on a `circle`
      layer (needs `symbol` + sprites), and `gq_mapgl_style()` has no
      classification branch, so per-class radius is tmap-only
- [ ] `/planning-archive`, `/gh-pr-push`

## Validation

- [ ] `devtools::test()` — 849 passing plus new
- [ ] `lintr` clean on changed files
- [ ] `devtools::check()` no new ERROR/WARNING/NOTE (main carries 2+2, #51)
- [ ] `/code-check` per commit; PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
