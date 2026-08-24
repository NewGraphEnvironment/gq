# Findings — themes.csv describes themes that do not ship (#46)

## Measured before implementation (2026-08-24)

### Real themes in the templates

| template | themes |
|---|---|
| `bcfishpass_mobile` | High Detail - Crossings; Low Detail - Bull Trout / Salmon / Steelhead Model (4) |
| `bcrestoration_mobile` | the same four, plus Land Tenure (5) |

Zero overlap with `themes.csv`'s Field View / Analysis View / UAV View.

### `High Detail - Crossings` diverges across templates

Same name, materially different content — 27 layers visible in fishpass, **0** in
restoration. This is why `template` must be a column rather than an optional filter.
Restoration also has empty self-closing `<checked-group-nodes/>` despite
`has-checked-group-info="1"` — irrelevant here since group nodes are ignored, but
worth knowing if anything ever reads them.

### Layer resolution rate

Theme `<layer id>` -> `<maplayer><layername>` -> normalize -> `groups.csv$layer_key`:

```
bcfishpass_mobile     High Detail - Crossings       28 layers, 27 resolved, 27 visible
                      Low Detail - * Model (x3)     25 layers, 24 resolved, 21 visible
bcrestoration_mobile  High Detail - Crossings       28 layers, 27 resolved,  0 visible
                      Land Tenure                   26 layers, 25 resolved, 22 visible
                      Low Detail - * Model (x3)     25 layers, 24 resolved, 21 visible
```

The single unresolved key is `habitat_lateral`, in all 9 themes.

### `habitat_lateral`

Absent from both `groups.csv` and `reg_main.json`. It is a raster
(`<datasource>./habitat_lateral.tif`), which is why the vector-only
`gq_qgs_extract()` (`maplayer[@type='vector']`) never saw it. Sits in `Base - misc`.

Adding it to `groups.csv` without a `reg_main.json` entry breaks nothing:
`join_registry()` (`R/gq_groups.R:234-248`) returns `NA` for an unmatched key, and
`form_edna` / `form_monitoring` (`groups.csv:48-49`) are existing precedent. The
integrity test at `test-gq_groups.R:52` is one-directional (registry keys subset of
groups keys), so it is unaffected. Downstream, rfp filters `NA` source_layers
(`rfp_project_create.R:207-208`) and `local` is not a refreshable manifest type.

### The basemap motivating case is not in the data

Of the four xyz basemaps, only `esri_world_topo` appears in any preset:

```
esri_world_topo    in presets: TRUE   (both templates)
bing_aerial        in presets: FALSE
esri_satellite     in presets: FALSE
google_satellite   in presets: FALSE
```

All four exist as `<maplayer>` nodes; the presets were saved before they landed
(gq `a579752`) and never re-saved. So the schema *can* express the case and the
extracted data *will not*, until rfp#185 re-saves the presets. Decision: extract
truthfully now, re-run after. The schema change stands on the other two grounds.

### The normalizer already exists twice

`normalize_layer_name()` (`R/gq_style.R:104-107`) is byte-identical to the inline
copy at `R/gq_qgs_extract.R:57-58`. Use the existing one. The rule uses `sub` with
an alternation, not `gsub`, so only the first boundary underscore is stripped —
`"_foo_"` -> `"foo_"`. No existing test exercises that; the extractor fixture
names are all clean. (`%||%` is duplicated the same way at
`gq_qgs_extract.R:394` and `gq_reg.R:270-271` — noted, out of scope.)

### Template source ambiguity

Installed rfp is **0.25.1**; the source checkout is **0.30.1**. They disagree —
fishpass `High Detail - Crossings` has 28 visible in the installed copy, 27 in
source. Any test asserting a count pins an undeclared rfp dependency.
`reg_extract_restoration.R:15-38` already carries a comment about this exact trap.

### No downstream caller of the retiring API

Nothing outside gq calls `gq_theme_groups()` or `gq_themes()`. rfp's only gq call
is `gq::gq_template_layers()` (`rfp/R/rfp_project_layers.R:27`). `_pkgdown.yml` has
no `reference:` index. Retirement is safe.

## Issue context

## Problem

`inst/registry/themes.csv` is the roster of map themes for the QGIS templates —
which layers a template shows under each theme. It has two problems.

### It describes themes that do not exist

The file is 15 rows over 3 themes: *Field View*, *Analysis View*, *UAV View*.

The templates it is meant to describe carry these, measured against
`rfp/inst/templates/`:

| template | themes |
|---|---|
| `bcfishpass_mobile` | `High Detail - Crossings`, `Low Detail - Bull Trout Model`, `Low Detail - Salmon Model`, `Low Detail - Steelhead Model` |
| `bcrestoration_mobile` | the same four, plus `Land Tenure` |

**Zero overlap.** Nothing in the roster names a theme that ships, so anything
reading it to drive a template build gets a set of themes no user has seen.

### It is the wrong granularity

The schema is `theme,group,visible` — a theme turns a whole group on or off.

QGIS does not model themes that way. A `<visibility-preset>` enumerates
`<layer id=... visible="0|1"/>` per layer; groups appear only in
`<checked-group-nodes>`, a slash-path record of tree-node UI state. So the
current schema cannot round-trip a real theme even with the names corrected.

The concrete cost is any theme that discriminates *within* a group. The four
xyz basemaps share a single `Base - misc` group, and a group-granular row can
only say `Base - misc: true`, which turns on all four — one visible image while
fetching four tile streams.

## Proposed solution

Make the roster layer-granular and true, populated by extraction from the
templates rather than hand-authored.

Schema `template,theme,layer_key,visible`:

- **`template` is required, not optional.** `Land Tenure` ships only in
  restoration, and `High Detail - Crossings` ships in both with materially
  different content — 27 layers visible in fishpass, **0** in restoration.
  Without the column those collide. This also matches `templates.csv`, which is
  already keyed template-first.
- `layer_key` as `groups.csv` keys layers. Pure layer rows: extraction never
  emits a group row, so group-level shorthand would be untested code serving a
  hypothetical.

Populate from the themes the templates actually ship, so the roster describes
reality before anything is built from it.

## What measurement established

**The slug bridge already exists for this direction.** Theme `<layer id>` →
`<maplayer><layername>` → snakify → `groups.csv$layer_key` resolves all but one
layer across all 9 themes in both templates. Extraction needs no new mapping
table; it reuses `normalize_layer_name()` (`R/gq_style.R:104`).

**`habitat_lateral` is the sole unresolved key**, in all 9 themes, absent from
both `groups.csv` and `reg_main.json`. It is a raster (`./habitat_lateral.tif`),
which is why the vector-only `gq_qgs_extract()` never saw it. It gets a
`groups.csv` row in `Base - misc` (`source_type = local`) so the reference
resolves.

**The basemap case cannot be populated yet, and that is upstream.** Of the four
xyz basemaps only `esri_world_topo` appears in any preset; `bing_aerial`,
`esri_satellite` and `google_satellite` appear in none. The presets were saved
before those layers landed and were never re-saved, so the templates do not
encode the behaviour described above. Tracked in
NewGraphEnvironment/rfp#185. This roster will honestly record only
`esri_world_topo` among the basemaps until that lands, then pick the rest up on
a re-run. The schema change stands on its own — per-layer granularity and the
per-template divergence are both independently required.

## API

`gq_theme_groups()` returns group-visibility rows and cannot survive the schema
change. It is retired in favour of `gq_theme_layers(theme, template = NULL)`.
Breaking, but the function it replaces described themes that never existed.

## Scope: this is the template roster, not a portable theme applier

Originally this issue also proposed holding themes as reusable data to apply to
any project. **That half has moved to the consumer** — see
NewGraphEnvironment/rfp#178.

The reason is a missing bridge in the *other* direction, and it constrains this
issue too. A QGIS map theme references layers by **display name**
(`Provincial park`); this registry keys them by slug (`provincial_park`).
Extraction can go name → slug by normalizing, but nothing goes slug → name:

- `groups.csv` has no name column
- `reg_main.json`'s `label` field is label *styling* — font, size, colour
- `xref_layers.csv` is 2 rows

So a theme applier keyed on this registry cannot resolve a layer to write it
into a project today. The applier therefore keys on display names and lives with
the consumer, which needs no translation.

**Building that slug → display-name bridge belongs with the template build**
(NewGraphEnvironment/rfp#174), which needs it anyway to name layers it generates
from scratch. If it lands, the two representations can converge; until then this
registry's job is to describe what the templates ship.

Relates to NewGraphEnvironment/rfp#174, NewGraphEnvironment/rfp#178,
NewGraphEnvironment/rfp#185, #40

