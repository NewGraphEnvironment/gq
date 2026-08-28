# Findings — Registry and shipped templates disagree (#66)

## Measurement, 2026-08-28

Against `~/Projects/repo/rfp/inst/templates/*.qgs`, not taken from the issue
body. Probe: `xml2` walk of `/qgis/layer-tree-group/layer-tree-group`, layer
names normalised through gq's own `normalize_layer_name()`.

### The two templates are structurally identical

Both carry the same ten top-level groups in the same document order:

```
Forms, Project Specific, Crossings, Other point features,
Roads,Railways,Pipelines, Streams, Basemap, Web Mapping Services,
Base - lidar, Base - misc
```

`bcrestoration_mobile` adds one subgroup, `Basemap/Terrestrial Ecology`, and one
layer (`Floodplains`, in `Base - misc`). Everything else matches.

gq's `templates.csv` declares **different sets and different orders** for the
two. The issue's table implies the divergence is template-vs-template; it is
registry-vs-both.

### Layer placement, bcrestoration_mobile

| | count |
|---|---|
| template layers | 59 |
| matched to `groups.csv` | 56 |
| placement agrees | 32 |
| **placement disagrees** | **24** |
| — pure naming (`Roads,Railways,Pipelines`, case) | 15 |
| — genuine structural disagreement | 9 |
| gq layers absent from the template | 8 |
| template layers with no `groups.csv` row (gq#64) | 3 |

The nine genuine ones, template path vs gq path — **out of scope here**, filed as
a gq follow-up:

| layer_key | template | gq |
|---|---|---|
| `floodplains` | `Base - misc` | `Floodplain` |
| `fisheries_sensitive_watersheds` | `Basemap` | `Streams` |
| `first_nation_reserve` | `Basemap/Waterbodies` | `Basemap` |
| `streams_all` | `Basemap/Waterbodies` | `Streams` |
| `stream_labels` | `Streams/Stream labels` | `Streams` |
| `biogeoclimatic_ecosystem_classification` | `Basemap/Terrestrial Ecology` | `Basemap/BEC` |
| `orthophoto_tiles` | `Basemap/Terrestrial Ecology` | `Base - Orthoimagery` |
| `terrain_mapping_project_boundaries` | `Basemap/Terrestrial Ecology` | `Base - misc` |
| `terrestrial_ecosystem_information_scanned_map_boundary` | `Basemap/Terrestrial Ecology` | `Base - misc` |

The eight gq layers with no template row: `town`, `rivers_poly`, `bec_zone`,
`dam`, `form_edna`, `form_monitoring`, `harvest_area`, `planting_site`.

The three template layers with no `groups.csv` row: `parameters_habitat_method`,
`parameters_habitat_thresholds` (both in
`Project Specific/Model Parameters - bcfishpass `), and `Tracking` (in
`Project Specific`). These belong to gq#64.

## Three things the issue does not say

### 1. `Base - Orthoimagery` has never existed

`Orthophoto Tiles` lives in `Basemap/Terrestrial Ecology`. gq#40 added the
`templates.csv` row for `Base - Orthoimagery` on 2026-08-27, derived from
`groups.csv`, without checking any template. `Basemap/BEC` is the same class —
the template calls that subgroup `Terrestrial Ecology`.

### 2. The narrow check fails on gq's own registry

`Base - Orthoimagery` is declared at `group_order` 11 for `bcrestoration_mobile`
(9 for `bcfishpass_mobile`), below `Base - misc` (10 / 8). `Base - misc` holds
all four opaque xyz basemaps:

```
Base - misc,,esri_world_topo,5,wms
Base - misc,,bing_aerial,6,wms
Base - misc,,esri_satellite,7,wms
Base - misc,,google_satellite,8,wms
```

So gq currently declares `orthophoto_tiles` beneath ESRI World Topo. The issue
frames this failure as something that happens to hand-edited projects. It is in
the registry.

### 3. `gq_templates()`'s ordering doc cites fiction as evidence

`R/gq_groups.R:137` (written 2026-08-27, gq#40):

> the two already disagree beyond that point (`bcfishpass_mobile` orders
> Roads/Rails/Pipelines before Streams, `bcrestoration_mobile` the reverse)

Both `.qgs` put `Roads,Railways,Pipelines` before `Streams`. The asymmetry is in
gq's registry, cited as a fact about the templates. The **rule** the section
states — `group_order` is a sort key requiring no contiguity or cross-template
agreement — is still right. Only its evidence has to change.

## rfp carries the same mislabel

`rfp/R/rfp_qgs_theme_add.R:13-14` and `rfp/tests/testthat/test-rfp_qgs_theme_add.R:54`
both attribute non-portable theme **group** rows to group names diverging
*between the two shipped templates*, naming
`Other Point Features` / `Other point features` and
`Roads/Rails/Pipelines` / `Roads,Railways,Pipelines` as the pairs.

Measured: both templates carry `Other point features` and
`Roads,Railways,Pipelines`, identically. The pairs named are gq-vs-template, not
template-vs-template.

The conclusion (group rows are not portable) is still correct, but the mechanism
is different: `rfp_qgs_theme_groups.csv` records **root-prefixed** paths —
`bcfishpass Mobile /Basemap` vs `bcrestoration Mobile /Basemap` — so no group
path resolves across templates regardless of the names below the root. Plus
`Basemap/Terrestrial Ecology` genuinely exists only in bcrestoration.

Also: `Land Tenure` appears once in `bcrestoration_mobile.qgs` and in neither
template's layer tree. Not investigated further — noted for the rfp issue.

## Why the artifact has to be vendored

gq is **public**, rfp is **private**. gq's CI cannot read a `.qgs`, and adding
rfp to `Suggests` + `Remotes` would make a public package declare a dependency
nobody outside the org can resolve.

The established shape is already in the repo twice — `data-raw/styles_vendor.R`
(QML corpus) and `data-raw/reg_extract_themes.R` (theme roster). Both take an
`RFP_*_DIR` env var pointing at a **source checkout**, fall back to the installed
rfp, and commit the derived artifact as the shipped source of truth. Structural
tests always run against the committed file; the live-drift comparison skips when
rfp is absent.

`RFP_TEMPLATE_DIR` exists for a measured reason (`reg_extract_themes.R:36-43`):
`system.file()` resolves to the **installed** rfp, which is routinely behind the
checkout — installed 0.25.1 and a 0.30.1 checkout report different visible-counts
for the same theme.

## XML contract

- Root is an **unnamed** `<layer-tree-group>` at `/qgis/layer-tree-group`; the
  single named child is the project root (`bcrestoration Mobile `, **with a
  trailing space**).
- `<layer-tree-group name=...>` and `<layer-tree-layer name=... source=...>`.
- **Order is document order.** No `order`/`index`/`z` attribute anywhere.
  `<custom-order>` is `enabled="0"`, holds only layer ids, and is partial —
  not the source of truth.
- Every node has a `<customproperties>` element child, so positional indexing of
  children must filter by tag name.
- `order` must index group **and** layer children together. rfp's
  `data-raw/qgs/extract_roster.R:50-53`: "Indexing layers alone cannot place a
  subgroup, so a rebuild would silently reorder the tree, which IS draw order."
- Names are byte-exact and must stay that way. `Model Parameters - bcfishpass `
  has a trailing space; `" Form PSCIS"` a leading one. rfp's
  `rfp_qgs_theme_internals.R:17-19`: "a `trimws()` anywhere here silently
  invalidates every group reference in every theme."

## Errors Encountered

| Error | Resolution |
|-------|------------|
| | |
