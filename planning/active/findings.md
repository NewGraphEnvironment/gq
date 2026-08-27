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
- **~20% of the frame is empty** above the watershed — `gq_bbox_aspect()` put
  nearly all of the 7:9 slack on one side.
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

