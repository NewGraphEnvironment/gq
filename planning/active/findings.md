# Findings — Three local layers grouped and shipped with no registry entry (#64)

## Issue context

Three `groups.csv` layers are grouped, ordered and shipped in both templates but
have no registry entry, so `gq_template_layers()` returns them with
`source_layer = NA`. Found by the derived-rule guard added in #40. Exempted in
`test-composition_integrity.R` with a pointer here. Acceptance: exemption list
returns to empty.

## The forms are real — the issue body was wrong about this

rfp's committed `origin/main` ships, for both:

| artifact | form_edna | form_monitoring |
|---|---|---|
| GeoPackage | `inst/extdata/forms/form_edna.gpkg` | `form_monitoring.gpkg` |
| QML | `form_edna.qml`, 57/57 fields styled | `form_monitoring.qml`, 125/125 |
| roster row | `rfp_form_types.csv:6` | `:7` |
| harvest provenance | `" Form eDNA"` in `restoration_wedzin_kwa` | `" Form Monitoring"` in `sern_peace_fwcp_2023` |
| collected field data | 3 Mergin projects | 2 Mergin projects |

## Theme absence is not evidence

The issue cites "no `themes.csv` entry" as a staleness signal. **30 of 64**
`groups.csv` keys never appear in `themes.csv`, including `bec_zone`, `glaciers`,
`town`, `orthophoto_tiles`. A theme governs only the layers it names; absence
means unmanaged, not missing. The `.qgs` scan is what settles the question.

## Neither form is in either template — and that is structural

rfp `origin/main`, both templates: the `Forms` group holds exactly
`' Form PSCIS'` and `' Form FISS Site'`. A case-insensitive scan of every
`<maplayer>` name for `edna|monitor` returns nothing (the 8 raw string hits are
all inside the layer id `whse_environmental_monitoring_envcan_hydrometric_stn_sp`).

The reason: **forms are not baked into templates**. `rfp_qgs_form_add()` injects
them per project. rtj's `scripts/gis/projects/nelson/project.yml` carries
`forms: [trail_feature, viewscape, cabin_visit]` — a per-project selection.

So form membership is per-project while `groups.csv` models per-template
contents. That is the seam the three exemptions sit on.

**Consequence that decided the design:** putting all 12 spatial forms into
`groups.csv` would make `gq_template_layers("bcrestoration_mobile")` return 12
forms for a template shipping 2 — the gq#40 defect ("a project shows cartography
for five layers it never downloaded") at 6x scale.

## The layer_key rule: derive from label, never from type

`.rfp_form_layer_name(row)` is `paste0(" Form ", row$label)`
(`rfp/R/rfp_qgs_form_add.R:187`). gq then applies
`normalize_layer_name()` = `tolower(gsub("[^a-zA-Z0-9]+", "_", trimws(x)))`
with leading/trailing `_` stripped.

The discriminating case — and the reason a type-derived key is a defect:

| rfp `type` | rfp `label` | layer name | **layer_key** |
|---|---|---|---|
| `pscis` | PSCIS | `" Form PSCIS"` | `form_pscis` |
| `fiss_site` | FISS Site | `" Form FISS Site"` | `form_fiss_site` |
| `edna` | eDNA | `" Form eDNA"` | `form_edna` |
| `monitoring` | Monitoring | `" Form Monitoring"` | `form_monitoring` |
| **`monitoring_fish_passage`** | **Fish Passage Monitoring** | `" Form Fish Passage Monitoring"` | **`form_fish_passage_monitoring`** |

A key derived from the `type` column gives `form_monitoring_fish_passage` for
that row. Wrong, and nothing downstream would report it — the exact class of
defect the "a value nothing reads is wrong silently" rule covers. The oracle is
`reg_main.json`'s existing `form_pscis` / `form_fiss_site` keys, which QGIS
itself produced.

## edna and monitoring have no declared symbology anywhere

Checked the renderers rather than assuming, on rfp `origin/main`:

| form | roster `symbol` / `color` | QML `renderer-v2` colour |
|---|---|---|
| `pscis` | `marker_star_shadow` / `#B80808` | `184,8,8` — agrees |
| `cabin_visit` | `marker_circle` / `#6A3D9A` | `106,61,154` — agrees |
| **`edna`** | **empty** | `255,255,255` — QGIS default |
| **`monitoring`** | **empty** | `255,255,255` — QGIS default |

This is an rfp-side gap. gq will not invent colours; it gets an rfp issue.

## rfp registers 14 form types, gq declares 4

`fish_sample`, `fhap`, `vri_qa`, `transition_qa`, `exceedance`, `viewscape`,
`monitoring_fish_passage`, `trail_feature`, `cabin_visit` are all registered and
absent from gq. `cabin_visit_pebble` has `has_spatial = false`, empty `geometry`
and `parent = cabin_visit` — a non-spatial child table, correctly excluded from
a layer roster. 13 spatial forms.

## habitat_lateral

A real raster `maplayer` in `Base - misc` in **both** templates — matching
gq's `groups.csv` row exactly. The only `paletted` renderer in either template
or in `restoration_wedzin_kwa`.

```
<rasterrenderer opacity="0.4" type="paletted" band="1">
  <paletteEntry value="1" color="#b2df8a" label="Floodplain"/>
  <paletteEntry value="2" color="#9f3cca" label="Floodplain Disconnected by Railway"/>
```

It never reached `reg_qgis_*.json` because `gq_qgs_extract()` selects only
`.//maplayer[@type='vector']` (`R/gq_qgs_extract.R:30`). Structurally invisible,
not an extraction bug.

The QML also carries a 30% per-value `rasterTransparency` on top of the 0.4
renderer opacity. `reg_custom.csv` cannot express it, and should not pretend to —
the QML stays the lossless copy.

Precedent for the entry shape: `harvest_area` and `planting_site` are
hand-curated in `reg_custom.csv` with sentinel `source_layer == layer_key`
(`reg_custom.csv:16-17`).

## Blast radius of putting a raster in reg_main

Two tests sweep every registry layer and will break:

- `test-gq_tmap_legend.R:269` — `for (k in names(reg$layers)) gq_tmap_legend(reg, k)`,
  and `:297` renders the whole registry. `gq_tmap_legend()` errors
  "unsupported type" on raster.
- `test-gq_tmap_style.R:315` — filters on `!is.null(l$classification)`, which
  `habitat_lateral` will satisfy once it carries a palette.

And a latent hole becomes live: `gq_tmap_style()` returns `tmap_classified(sty)`
**before** the type switch (`R/gq_tmap_style.R`), so a classified raster returns
`list()` with no error. Silent-empty is the wrong failure direction.

## Out of scope, with evidence for the follow-up issues

**Floodplain is one row against 19 in the field.** gq: `Floodplain / floodplains
/ bcdata`. `restoration_wedzin_kwa`: a 19-layer group with `morice`, `neexdzii`
and `classified` sub-groups. Two blockers recorded for the widening issue:

- `source_type` has no term for a COG / `/vsicurl/` / project-local raster. The
  closed set is `aws, bcdata, fwa, local, osm, wms`.
- The `morice` and `neexdzii` sub-groups reuse **6 identical layer names**,
  distinguished only by `./morr/` vs `./` in the datasource. A name-derived
  `layer_key` collapses them.

**Template layers with no groups.csv row:** `Tracking` (`rfp_tracking`),
`parameters_habitat_method`, `parameters_habitat_thresholds`. The last two
already have `index.csv` QML rows. `test-template_drift.R`'s
`template_group_exempt` "Project Specific" reason cites gq#64 for this and will
need repointing.

**Nelson is config, not a project.** `rtj/scripts/gis/projects/nelson/` holds
`project.yml` and a 37-row manifest. Generation 01 (`nelson_20260826`) was
destroyed 2026-08-27 and its generation note says the `.qgs` is not recoverable;
generation 02's local checkout is gone. Re-sync from Mergin via rfp before the
widening work.

## Method notes

rfp's checkout is on branch `218-form-builder-deletes-captured-records-on` at
v0.45.0, and the installed rfp is 0.36.0. Every rfp fact here was read from
**committed `origin/main`**, per the rule that generating from another repo's
working tree copies its half-finished edits. The extractor must do the same.

## Errors Encountered

| Error | Resolution |
|-------|------------|
