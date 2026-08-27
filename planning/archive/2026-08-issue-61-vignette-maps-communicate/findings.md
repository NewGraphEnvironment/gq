# Findings — Vignette maps are correct but do not communicate (#61)

## Issue context

## Problem

The vignette maps are correct and hard to read. Every colour traces to
`gq_reg_main()` — which is what the vignettes were built to prove — but proving
that every layer is *styled* from the registry is not the same as making a map
that *communicates*, and the two vignettes currently optimise for the first at
the cost of the second.

Both figures were re-rendered and read on 2026-08-26 before filing.

## A real defect: the legend does not describe the map

The most visually prominent linework in `gq-tmap-composition.Rmd` is the salmon
habitat network — 397 features, `ACCESS;ASSESSED` → `#ef4545`, drawn bright red
across the whole subbasin. The `gq_tmap_legend()` call at
`vignettes/gq-tmap-composition.Rmd:284` lists lake, wetland, `streams_all`,
`roads_dra`, railway, crossings, fish obs and falls. It does **not** list
`streams_salmon`.

So a reader sees red dominating the map with nothing saying what red means. The
prose directly beneath the figure then describes that layer's three registry
widths and its intermittent dash (#36) — a feature the reader cannot locate.

This is the class of bug the legend work was meant to end, and it is in our own
flagship example.

## Not a defect, recorded so it is not re-raised

The purple `Unknown` crossing entry looked like a phantom legend row. There is
exactly **1** `UNKNOWN` crossing in `neexdzii_crossings`. The legend is honest;
the symbol is simply lost among the orange. `present =` is correctly applied to
roads and correctly not needed here.

## The editorial problem: 89% of the point symbols are modelled

`neexdzii_crossings` is 130 `POTENTIAL` of 146 total. At registry-true 3 mm
(#16, correct) on a whole-subbasin overview, those 130 orange dots *are* the
map — they bury the stream network that the salmon habitat classification exists
to describe.

Nothing is wrong with the sizing. The map is showing a modelled-crossing density
that QGIS never displays at this scale because you would be zoomed in. A static
overview has to make an editorial choice, and the vignette should make one and
explain it — that is a more useful lesson than "turn every layer on".

## Secondary, in rough order of cost

- **The basemap contributes nothing.** `Esri.WorldGrayCanvas` ×
  `Esri.WorldShadedRelief` at `gamma = 0.5`, zoom 10, is a featureless grey
  field. It adds no terrain reading and lowers the contrast of everything drawn
  over it.
- **The AOI has no containment.** Inside and outside the watershed render
  identically; only a thin dark boundary separates them, so the subject of the
  map is not visually obvious.
- **~40% of the frame height is padding**, split evenly above and below. The
  band above reads as dead space; its twin below is merely hidden under the
  legend. This is **not** a `gq_bbox_aspect()` defect — measured, it pads
  symmetrically (21.7% each side). It is the cost of asking a ~1.32:1 landscape
  watershed to fill a 7:9 portrait frame, so the fix is the aspect choice, not
  the function.
- **Text is sized for the render, not the publication.** A 7×9 in figure is
  squeezed into `html_vignette`'s ~700 px column, so `legend.text.size = 0.5`
  and `size = 0.45` labels land at a few pixels on the site.
- **Both vignettes are `rmarkdown::html_vignette` with no `fig.cap`**, against
  the r-packages convention that specifies `bookdown::html_vignette2` with
  numbered figures.
- **`gq-intro.Rmd`'s subject is a minority of its own symbols** — most crossings
  drawn sit outside the Bittner Creek AOI — and it has no scale bar and no
  keymap, so the four-corner rule is not demonstrated there at all.

## Why the existing self-review did not catch this

After #16 this map was reported as passing all seven of `cartography.md`'s
self-review checks. That was accurate and worthless: every one of those checks
is about **element placement** — corners, overlap, spacing, white bands, bbox
ratio. None asks whether the map communicates. A map can satisfy the whole list
and still fail to say what it is about.

The convention gap is being fixed separately in soul.

## Scope

1. Add `streams_salmon` to the legend.
2. Make an editorial decision about `POTENTIAL` crossings and state it in prose.
3. Give the AOI containment; pick a basemap treatment with real contrast.
4. Size type for the published column width.
5. Move both vignettes to `bookdown::html_vignette2` with captions.
6. Bring `gq-intro.Rmd` up to the same standard, or narrow it deliberately.

## Acceptance

Re-render both vignettes and **read the figures**, against the extended
`cartography.md` self-review. The test is not that the checks pass — it is that
someone who has never seen this watershed can tell what the map is about, and
can find every prominent feature in the legend.


## Phase 5 — self-review against the extended checklist (soul#78)

First real use of the "does it communicate" half added to
`cartography.md`. Verdict on `gq-tmap-composition.Rmd`'s figure:

### Placement (checks 1–7)

| # | check | verdict |
|---|---|---|
| 1 | correct study area | pass — Neexdzii Kwa subbasin, from source data |
| 2 | map fills the page | pass — basemap edge to edge, no bands |
| 3 | keymap in frame with spacing | pass — bottom-right |
| 4 | no element overlap | pass — four distinct corners |
| 5 | legend over least-important terrain | pass, **and this one was earned**: top-left renders better on paper and hides the barrier crossings. Settled by rendering both |
| 6 | consistent spacing | pass |
| 7 | scale bar breaks | pass — 0/2/4/6 km over a ~20 km extent |

### Does it communicate (checks 8–12)

**8. Every prominent feature in the legend.** Ranked by measured ink
(length x registry width), not by eye:

```
salmon habitat        154114     <- was absent from the legend
streams (order>=3)     51931
roads                  11266
crossings (assessed)   16 pts
```

All four are legended. The layer that outranks everything else by a factor of
three is precisely the one #61 was filed about — which is the argument for
ranking the rendered image rather than reading the layer list.

**9. Subject obvious.** Pass, via the containment mask. It was failing before:
inside and outside the watershed rendered identically.

**10. Symbology hierarchy.** Pass after the editorial cut. Was failing badly —
89% of point symbols were one modelled class.

**11. Basemap earns its contrast cost.** Marginal pass. With the AOI knocked
back the relief blend does read as terrain. Left unchanged deliberately; the
complaint in #61 turned out to be mostly a containment problem.

**12. Type sized for the published width.** Pass — sized for the ~700 px column
rather than the 7 in render.

### Residual, recorded rather than fixed

Review finding AC1: dropping the `;INTERMITTENT` legend rows removes the single
most-drawn habitat class (`ACCESS;ASSESSED;INTERMITTENT`, 178 of 397 — 45%).
Tracing a dashed red line to "Accessible; known barrier" requires reading the
prose. Accepted: the alternative is eighteen line entries, which reintroduces
the overflow this phase removed. Revisit if a reader reports it.

### On the checklist itself

Check 8 is the one that would have caught gq#61, and it only works because it
says to rank the *rendered image*. Check 5 turned out to need the same
discipline — reasoning about which corner is emptiest gave the wrong answer,
and only rendering both settled it. Worth folding back into soul.
