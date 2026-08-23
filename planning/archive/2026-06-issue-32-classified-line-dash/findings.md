# Findings — Classified line layers drop QGIS dash pattern (#32)

## Verify-first: how the `.qgs` encodes the dash

Source: `~/Projects/repo/rfp/inst/templates/bcrestoration_mobile.qgs`
(private rfp package template; feeds `reg_qgis_restoration.json`).

Two distinct dash encodings observed:

| Layer | Branch | line_style | use_custom_dash | customdash | Current capture |
|-------|--------|-----------|-----------------|-----------|-----------------|
| `transmission_line` | simple | `dash dot` | `0` | `5;2` | ✅ `dash: "dash dot"` (line 159) |
| `streams_salmon` `;INTERMITTENT` | classified | `solid` | `1` | `0.66;2` | ❌ dropped — no dash field |

**Key insight:** the intermittent classes use `use_custom_dash="1"` with
`line_style="solid"`. The simple branch's line 160
(`style == "custom_dash"`) would NOT catch this either — that condition assumes
QGIS sets `line_style="custom_dash"`, but QGIS keeps it `"solid"` and uses a
separate boolean flag. So the capture must key off `use_custom_dash`, not
`line_style`. This is why a literal "mirror lines 153-160" (as the issue
suggested) is insufficient — hence the shared `parse_dash()` helper.

## Current registry symptom

`inst/registry/reg_main.json` — `streams_salmon` `;INTERMITTENT` classes carry
identical `color`/`width` to their non-intermittent siblings and no dash:

```
SPAWN;NONE             -> {color:#129bdb, width:1.7, label:...}
SPAWN;NONE;INTERMITTENT -> {color:#129bdb, width:1.7, label:...}   # should be dashed
```

## Code locations

- `R/gq_qgs_extract.R:113` — `opt_val()` reader (reads `Option[@name=...]`)
- `R/gq_qgs_extract.R:151-164` — simple SimpleLine branch (has dash logic)
- `R/gq_qgs_extract.R:223-229` — classified SimpleLine branch (NO dash logic)
- `R/gq_style.R:59,67,78` — `widths` vector pattern to mirror for `dashes`
- `R/gq_tmap_style.R:71-77` — `gq_tmap_classes()` return list
- `R/gq_tmap_style.R:137-139` — `tmap_line_args` already maps `stroke$dash` → `lty`

## Does the dash *length* land in the recipes? (backend asymmetry)

Storing raw preserves the length; whether it renders depends on the backend:

- **mapgl: yes, exact.** `gq_mapgl_style()` (`R/gq_mapgl_style.R:72`) splits the
  dash on `[; ]`, so `"0.66;2"` → `line-dasharray = c(0.66, 2)`. Real mm length
  renders. (Note: named styles like `"dash dot"` → `as.numeric` NA → dropped in
  mapgl — pre-existing, out of scope.)
- **tmap: no.** R `lty` only takes named types (`"dashed"`, …) or hex, not a mm
  pattern. The exact length cannot survive; best a consumer can do is non-NA →
  `"dashed"` (what `link`'s vignette does).

### Consequence for Phase 1 (shared helper)

There is a **simple (singleSymbol)** layer `"Pipeline installed"` that also uses
`use_custom_dash="1"` + `customdash="0.66;2"` (`line_style="solid"`). Five
SimpleLine symbols in the `.qgs` use `use_custom_dash=1`:

```
categorizedSymbol  Streams - all   2.5;3.5
categorizedSymbol  streams_bt      0.66;2
categorizedSymbol  streams_salmon  0.66;2
categorizedSymbol  streams_st      0.66;2
singleSymbol       Pipeline installed  0.66;2
```

Once `parse_dash()` captures these, `"Pipeline installed"` gets `dash:"0.66;2"`
in its `stroke`, which flows into `tmap_line_args` → `lty="0.66;2"` — tmap
can't render that. Today it captures nothing (no break). So Phase 3 must add a
`dash_to_lty()` normalization in the tmap path: raw pattern / unknown →
`"dashed"`, valid named lty passes through. Raw stays in the registry for
mapgl's exact length; tmap degrades safely.

## Registry provenance gap

`reg_qgis_restoration.json` is committed (1c1c425) but there is NO data-raw
script recording how it was extracted from the `.qgs`. `data-raw/reg_build_main.R`
only merges the already-extracted JSON + CSV. Phase 2 adds
`data-raw/reg_extract_restoration.R` to close this gap (dev-only, references
private rfp template via `system.file`).

## Issue context

(full issue body — see `gh issue view 32`)
- Distinct from #31 (which surfaces dimensions already in the registry).
- Downstream want: `link`'s PARS habitat-connectivity vignette currently sets
  `lty = "dashed"` locally off `grepl(";INTERMITTENT", token)` — wants the dash
  to come from the registry instead.
