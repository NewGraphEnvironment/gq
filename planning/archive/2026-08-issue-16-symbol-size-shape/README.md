# gq#16 — symbol size was a guessed constant, not a unit conversion

**Outcome:** fixed in v0.8.0. `gq_symbol_size()` and `gq_symbol_shape()` are the
one place registry millimetres become renderer units. Every point layer now
draws at the size QGIS says, and shape reaches the page for the first time.

**The issue's premise was backwards.** #16 said registry sizes render *too
small* — "a radius of 2.4 becomes nearly invisible". The `/ 3` divisor drew
every symbol **27% oversized**. The original observation predates the divisor.
What was right is the sentence after it — *every map manually guesses `size`
through trial and error* — and that is what the fix removes.

**My own first measurement was circular, and the review caught it.** I built the
conversion on "tmap draws 5.08 mm per size unit", measured with a helper that
read `pointsGrob$size` back off the grob — the value tmap was *handed*, not the
ink. R's graphics engine applies a per-`pch` factor the grob slot never records.
A circle actually draws **3.81 mm** per size unit (0.75 of the nominal box), so
the first fix shipped every symbol **25% undersized while documenting itself as
exact** — worse than the bug it replaced, because it was asserted as correct.
The instrument now reads the rendered SVG primitives.

**The conversion also depends on the shape.** Base R normalises pch 21–25 by
*area*; QGIS normalises by *extent* (every point QML carries
`scale_method = "diameter"`). So circle 3.810, square 3.376, triangle 5.129,
star 5.390 mm per size unit — one divisor cannot serve them all, and the two
layers the issue was opened about are the two non-circles. MapLibre's
`circle-radius` is a true radius in CSS pixels, hence `mm / 2 * 96/25.4`.

**A third defect the review found:** `pch = 8` is stroked only and ignores
`fill`, so the registry's one star layer would have lost its colour entirely.
`gq_symbol_fillable()` now decides whether to set `fill` or `col`.

**Two facts the naming hides.** The registry's `radius` is a **diameter** —
`gq_qgs_extract()` reads the QGIS option literally named `size`, the marker's
overall extent. And `tmap_options(scale = )` multiplies the constant, so
absolute-millimetre assertions are only valid at scale 1. gq deliberately does
not compensate for that scale: a caller scaling a whole map expects symbols to
scale with the text.

**Shape had been sitting there since extraction.** 15 layers carry one; no
renderer consumed it. `star` maps to `pch = 8`, which draws a star and takes no
fill — substituting a filled circle would have silently discarded the
distinction that made the layer a star in QGIS.

**The legend guard fired exactly as written, then rotted.** `collect_legend()`'s
mixed-aesthetic check had a comment saying "the day `tmap_point_args()` emits a
shape this fires" — and it did. Its own test then broke, because it had chosen
`shape` *because* nothing supplied a default. Rewritten on `angle` with the
premise asserted beside the property, per the negative-fixture-rot convention
that landed in soul the same day.

**Fixing the sizes broke the layout, and that was in scope.** Bigger symbols
made the legend taller and wider until it overlapped the scalebar and clipped
its own last entry. The scalebar had been at bottom-*centre* — not a corner, but
the gap between the bottom-left legend and bottom-right keymap, which survived
only while the legend was narrow. Moved to top-left. The map now passes all
seven of `cartography.md`'s self-review checks; it failed two before.

**`devtools::check()` earned its place in the checklist**, catching a third
WARNING against a baseline of two: `withr::defer()` in the new test helper was
an undeclared dependency.

**1:1 was not too busy.** No default `scale` was needed — the map got better,
not denser. The three salmon-habitat widths from v0.6.0 are legible for the
first time.

Commits `2f011d4`..`<release>`. PR #60.
