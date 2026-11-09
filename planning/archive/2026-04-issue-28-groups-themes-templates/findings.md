# Findings — Issue #28

## Registry cross-check (2026-04-11)

53 layers in `reg_main.json`. The issue's draft `groups.csv` references 43 layer keys.

**4 keys in groups.csv missing from registry:**
- `form_edna` — no style yet, needs adding (or leave unstyled, groups.csv can reference keys not in style registry)
- `form_monitoring` — same
- `fire_perimeters_current` — WMS layer, may not need style
- `frep_rip2021` — registry has `frep_rip2021_mar2022` (date-stamped variant). Rename in groups.csv to match.

**14 registry keys not in draft groups.csv (need mapping):**
- `conservancy` — fits Basemap
- `frep_rip2021_mar2022` — fits Web Mapping Services (or rename to `frep_rip2021`)
- `fire_severity` — fits Basemap or separate Fire group
- `floodplains` — own group (bcrestoration has Floodplain group)
- `biogeoclimatic_ecosystem_classification` / `bec_zone` — Basemap
- `orthophoto_tiles` — Base - Orthoimagery
- `terrestrial_ecosystem_information_scanned_map_boundary` — Base - misc
- `terrain_mapping_project_boundaries` — Base - misc
- `fisheries_sensitive_watersheds` — Streams or Basemap
- `dam` — Crossings or Other Point Features
- `town` — Basemap
- `harvest_area` — project-specific (restoration)
- `planting_site` — project-specific (restoration)

**Decision:** groups.csv should map ALL 53 registry keys. Unmapped keys are orphans — hard to discover. Will add the missing 14 to appropriate groups.

## Existing patterns

- CSV reader pattern: `gq_reg_custom()` uses `utils::read.csv()` with `na.strings`
- All reader functions return lists; query functions should return tibbles for tabular composition data
- No tibble dependency currently — check DESCRIPTION Imports
- `system.file()` used for bundled data access
- One-file-per-function pattern, but grouping related functions (groups/templates/themes) in one file is reasonable since they share the same CSV ecosystem
