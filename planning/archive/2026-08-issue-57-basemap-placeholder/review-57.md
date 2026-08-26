# Plan review — gq#57

Plan-agent review, run concurrently with implementation. The agent had no write
tools, so this file is transcribed from its report; the disposition column is
mine, added after verifying each claim.

Everything below was **reproduced before being acted on**, per `karpathy.md` §5.
Two findings were blockers I would otherwise have shipped.

## Disposition

| # | Finding | Verified? | Action |
|---|---|---|---|
| B1 | `minmax()` defaults to `compute = FALSE`, so `tile_is_flat()` calls any file-backed raster flat | **Confirmed** | Fixed — `compute = TRUE` |
| B2 | Every fixture was in-memory, so none could reach B1 | **Confirmed** | Added a file-backed fixture |
| B3 | `tm_shape(NULL)` errors, so the NULL contract never worked | **Confirmed** | Layer built conditionally, both vignettes |
| O1 | Guard placement/predicate under-specified in the plan | Correct, already right in code | Comment now says why |
| O2 | Phase 4's "unchanged apart from provider" is unsatisfiable | Correct | Restated in `task_plan.md` |
| G1 | Nothing offline asserts the provider string is real | Correct | Added `get_providers()` test |
| G2 | `local_mocked_bindings(.package=)` needs testthat >= 3.2.0 | Correct | DESCRIPTION pin bumped |
| G3 | Basemap attribution dropped | Correct, pre-existing | Filed separately, out of scope |
| A1 | "label-free" contradicted by the house skill | **Agent was right** | Claim corrected everywhere |
| A2 | Default `zoom = 12` measured nowhere | Correct | Measured over 3 BC extents |
| S1 | Inventory stops at the repo boundary — soul's cartography skill still ships the keyless Carto snippet | **Correct, and the biggest one** | Skill updated |
| Ac3 | "cannot find function" is not a restore-the-bug check | Correct | Did the namespace patch |

## The two that mattered

**B1.** `terra::minmax(x)` reports only *cached* statistics and returns
`Inf`/`-Inf` when there are none — which is every file-backed raster. Measured
on the package's own logo PNG, a richly varied image:

```
hasMinMax: FALSE FALSE FALSE FALSE
minmax(default):      min Inf Inf Inf Inf / max -Inf -Inf -Inf -Inf
tile_is_flat(r)  ->   TRUE          # wrong
minmax(compute=TRUE): min 0 0 0 0 / max 11 18 18 255   -> FALSE
```

A guard that fires on everything trains people to ignore it — the mirror of this
issue's own complaint. It passed against maptiles only because
`get_tiles(crop = TRUE)` computes min/max in passing: correct by accident, via an
upstream internal that is not a contract.

**B3.** The NULL-on-fetch-failure contract, which `gq-tmap-composition.Rmd` has
documented since #17 and which Phase 4 was about to copy into `gq-intro.Rmd`:

```
tm_shape(NULL) + tm_rgb()
Error : Specified shp argument of tm_shape is a NULL, which is not a
        recognized/supported spatial data class.
```

Setting the raster to `NULL` moves the failure sixty lines down into the map
composition. The guard reads as though it works and does not. Fixed by making
the whole *layer* conditional — `NULL + tm_shape(...)` composes fine.

## Where the agent was wrong, and where I was

**Wrong (mine, corrected):** I claimed `Esri.WorldGrayCanvas` is "label-free".
The soul cartography skill said "with place labels" and I assumed the skill was
stale. Rendering at the function's default `zoom = 12` shows lake names; at the
vignettes' `zoom = 10` none are visible. **The skill was right and I was wrong.**

**Overtaken by measurement (agent's):** the agent argued warn-and-return rested
on a weak premise, since "gq's domain is inland BC watersheds, where a genuinely
uniform tile essentially never occurs". Measured over a Vancouver Island extent,
`Esri.WorldGrayCanvas` returns a solid water colour and the guard fires — at both
zoom 10 and 12. The false-positive path is not hypothetical, it is reachable in
gq's actual domain, which makes warn-and-return required rather than merely
defensible. The agent's cost-asymmetry argument is still the better one and is
now the reason given in the code.

**Already known:** the agent noted `Esri.WorldTerrain`'s blankness was already
documented in the soul skill, so `findings.md` presenting it as an accidental
discovery was overstated. True — though the skill said "blank at zoom 10+ in some
areas" while it is in fact flat at every zoom measured, and nothing enforced it.

## Not done

- **G3, attribution.** `maptiles` carries a per-provider credit that
  `gq_basemap_tiles()` discards, and neither vignette calls `tm_credits()`. Esri
  and OSM/ODbL both require attribution. Pre-existing rather than introduced
  here, but the swap changes who is owed it. Filed as its own issue.
- The composition map still stacks legend and scale bar in the bottom-left
  quadrant, against the four-corner rule. Pre-existing, needs its own issue.
