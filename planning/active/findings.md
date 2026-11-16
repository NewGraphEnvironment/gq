# Findings — Move 4: extractor fidelity and labels (batches 9, 10) (#103)

## Issue context

**If we do it:** the registry carries each label's field and weight, overlays and layer opacity as QGIS draws them, and a map can take its labels from the registry. **If we never do:** 0 of 25 labelled layers carry a label field, the railway keeps drawing as a plain black line, and every map hard-codes its `tm_text()` settings.

Move 4 of `planning/backlog.md`, which holds the order, the measurements and each batch's section. Run `/planning-init` on this issue: one plan, one phase per batch, one PR. `/gh-pr-merge` ticks the move when it merges.

## Batch 9: Extractor fidelity

**Why here:** one file, `R/gq_qgs_extract.R`, one re-extract and one registry rebuild.

**Touches:** `R/gq_qgs_extract.R`, `data-raw/reg_extract_restoration.R`, `inst/registry/reg_qgis_restoration.json`, `reg_main.json`.

**Decided at the gate:** how far the registry goes, given it models what tmap and mapgl can render and the QML corpus is the lossless copy; whether #23 still has a source worth extracting.

| issue | title |
|---|---|
| #6 | Fix label fieldName extraction from QGIS projects |
| #24 | Extract multi-layer symbols (overlay/casing) in gq_qgs_extract() |
| #38 | Rendering detail not captured: layerOpacity, cap/join style, symbol pass order, and a data-defined-colour miss on streams_co |
| #23 | Add QLR file support to gq_qgs_extract() |

## Batch 10: Label translators

**Why here:** needs the label field batch 9 extracts.

**Touches:** new `R/gq_tmap_labels.R` and `R/gq_mapgl_labels.R`, with tests and examples.

**Decided at the gate:** whether `merge_lines` and `min_feature_size` are carried in the registry as hints for the consumer's data prep.

| issue | title |
|---|---|
| #7 | Add label translators: gq_tmap_labels() and gq_mapgl_labels() |

## Plan-mode measurements (2026-11-12)

Source: rfp `origin/main` 9b73405d (v0.94.0+3); `inst/templates/` byte-identical to v0.93.0.

- `fontWeight` in the template: 50 ×21, 75 ×3, 87 ×1 (Qt5 scale). `fontBold`: 0.
- Rule-based labelling: `Crossings - PSCIS, modelled, dams` (3 rules), `MoTi major structures` (1), `Roads - FTEN` (2).
- `labelsEnabled="1"` with no settings: PSCIS confirmation / Design / Remediation, Pipeline application.
- mergeLines on: Roads - FTEN (minFeatureSize 5), Roads - DRA (11), Trails (11), Stream labels (0).
- `<layerOpacity>` ≠ 1: Roads - FTEN 0.7, Pipeline permit 0.993.
- Railway: SimpleLine black 0.4 + MarkerLine (interval 3, rotate, sub SimpleMarker `line` size 2.4, outline black 0.2).
- MoTi major structures: SimpleLine black 2.06 (locked) under orange 1.46.
- Roads - DRA casing: pass 0 / pass 1 in categorized symbols.
- streams_salmon/_st/_bt: active data-defined fillColor/outlineColor `CASE WHEN "model_access_st" IN () THEN ...` — every IN list empty.
- `bcfishpass_30k.qlr`: upstream last commit 01f8d1c9 2024-03-05; current extractor reads 49 layers, 5 rule-based; 14 keys overlap reg_main.
- tmap 4.x `opt_tm_lines()` has no lineend/linejoin; `opt_tm_text()` has `along_lines`, `shadow`, `remove_overlap`.
- `gq_reg_custom()` CSV has no `label_field` column.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `Rscript -e '...' OLD=path` read no env var | env assignment goes before the command: `OLD=path Rscript -e` |
| `D=...; ...; Rscript -e 'Sys.getenv("D")'` empty | `export D` before the R call |

## Measurements after Phase 1 (2026-11-13)

- Re-extracted `reg_qgis_restoration.json`: 22 labelled (14 `field`, 8 `expression`); bold 3 (`municipalities` 87, `crossings_pscis_assessment` 75, `crossings_pscis_modelled_dams` first rule 75). The review's "4 bold" counted rules, not layers.
- `source_layer` identical on all 48 layers; 14 layers' non-label symbology changed (8 notes reworded, railway overlay, MoTi casing, FTEN opacity, 3 streams notes).
- QGIS 4.1.0-Master, `qgis/qgis@sha256:4eb5cd07…`: the streams expression `hasParserError() == True`, `evaluate()` → None. A failed data-defined property falls back to the symbol colour, so the registry's category colours are what QGIS draws for this template. rfp#430.
- reg_main's 25 labels = 22 template + 3 CSV (dam, town, planting_site); the CSV has no label field column.

## Phase 2 measurements (2026-11-13)

- tmap 4.2.0.9000: `tm_text(size = 1)` draws a capital H 36 px tall at 300 dpi, the same as `grid.text(fontsize = 12)`, so `size = pt / 12`.
- The CSV labels (dam, town, planting_site) were authored for MapLibre (size 11/12 px, halo 1.5 px, offsets in ems; the cartography skill passes them straight to `add_symbol_layer()`). Owner chose QGIS units throughout; the CSV rows were converted.
- The first re-extract (commit 799c7da) dropped all 11 halos: `<text-buffer>` sits inside `<text-style>`, and the new code looked for it beside it. No test caught it; two now do, and the fixed re-extract matches v0.93.0's halos on every layer.

| Error | Resolution |
|-------|------------|
| Re-extract dropped every label halo | `.//text-buffer` (it nests under `<text-style>`); tests pin the halo and the bufferDraw count |
| Designed tmap's halo against the installed tmap 4.2.0.9000, which has none | CRAN tmap 4.4-1 (CI's) has `opt_tm_text(halo = TRUE)`; check an installed package against CRAN before designing around a missing feature |

## Branch review: mechanism and closing measurement (2026-11-16)

Rounds 1-4 found the same mechanism each time: one reading rule (which symbol layers count, how opacity composes, what a note names, how the two label translators read the registry) implemented in parallel paths, with each fix reaching only the paths in view. It closed by making the extractor's paths call one `symbol_read()`, then measuring rather than re-reviewing: a 29-row mutation table, all red, and a grep of every layer selection and opacity write.

| round | findings | fixed | accepted | inside previous fix? |
|---|---|---|---|---|
| 1 | 5 | 4 | 1 (soul#847) | — |
| 2 | 4 | 3 | 1 (QML writer silent on pattern fills, documented) | no |
| 3 | 5 | 5 | 0 | yes (graduated got only half of round 2's fix) |
| 4 | 4 (+1 outside the diff, gq#120) | 4 | 0 | yes (tick filter, data-defined set, untested guards) |
