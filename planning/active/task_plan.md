# Task: Three local layers are grouped and shipped with no registry entry: form_edna, form_monitoring, habitat_lateral (#64)

Three `groups.csv` layers are grouped, ordered and shipped in both templates but
have no registry entry at all, so `gq_template_layers()` returns them with
`source_layer = NA` — styled for data that is never fetched. They are exempted
in `tests/testthat/test-composition_integrity.R` with a pointer to this issue,
so the guard is green by a **tracked decision** rather than by being narrowed.

Acceptance: the exemption list returns to empty, which is its correct state.

## What the exploration changed

Two of the issue body's premises were wrong.

- **"Nothing in the repo describes the two forms."** True of gq, false of the
  world. rfp ships `form_edna.{gpkg,qml}` (57 fields styled) and
  `form_monitoring.{gpkg,qml}` (125 fields), registers both in
  `inst/lookups/rfp_form_types.csv`, and three live Mergin projects hold
  collected data. They are real.
- **"No `themes.csv` entry"**, offered as evidence of staleness. 30 of 64
  `groups.csv` keys never appear in `themes.csv`, including `bec_zone` and
  `glaciers`. Theme absence proves nothing.

What is true: neither form is in either shipped `.qgs`. The reason is
structural — forms are **not baked into templates**. `rfp_qgs_form_add()`
injects them per project, and rtj's `nelson/project.yml` selects
`forms: [trail_feature, viewscape, cabin_visit]`. Form membership is
per-project; `groups.csv` models per-template contents. Putting all 12 spatial
forms into `groups.csv` would make `gq_template_layers()` report 12 forms for a
template shipping 2 — reintroducing the gq#40 defect at 6x scale.

Resolution: gq vendors rfp's form roster into its own table, and `groups.csv`
returns to describing what the templates actually ship.

## Phase 1: Vendor rfp's form roster

- [ ] `data-raw/reg_extract_form_types.R`, mirroring `reg_extract_themes.R` and
      `reg_extract_template_groups.R`: `pkgload::load_all()` unconditionally,
      `RFP_LOOKUPS_DIR` env override with a `system.file()` fallback and a clear
      stop when rfp is absent, rfp version printed for the commit message
- [ ] Derive `layer_key` by rfp's own rule —
      `normalize_layer_name(paste0(" Form ", label))` — not from the `type`
      column. Discriminating case: `monitoring_fish_passage` has label
      "Fish Passage Monitoring", so its key is `form_fish_passage_monitoring`
- [ ] Drop non-spatial rows (`has_spatial != "true"`) — excludes
      `cabin_visit_pebble`, a child table with no geometry
- [ ] Write `inst/registry/form_types.csv`, quoted (`label_expression` carries
      commas and embedded quotes)
- [ ] `R/gq_forms.R` — `gq_form_types()` reader with a runnable `@examples`
      block, following `gq_themes()` in shape

## Phase 2: groups.csv back to template contents

- [ ] Remove `form_edna` and `form_monitoring` rows from `groups.csv`
- [ ] Drop those two entries from `local_exempt`
- [ ] `tests/testthat/test-forms_roster.R` — roster shape, the derived-key
      oracle against `reg_main.json`, the `monitoring_fish_passage` pin, and
      premise assertions so the `has_spatial` filter cannot become a no-op

## Phase 3: Register habitat_lateral with its palette

- [ ] Two `reg_custom.csv` rows: `type="raster"`, sentinel `source_layer`,
      `class_field="value"`, values 1/2, `#b2df8a` / `#9f3cca`, opacity 0.4
- [ ] Document the raster convention in `gq_reg_custom()` roxygen, including
      what the schema cannot carry (the QML's 30% per-value transparency)
- [ ] Rebuild `reg_main.json`; verify idempotence with a second run and `cmp`
- [ ] Remove the third `local_exempt` entry — list empty

## Phase 4: Close the silent-empty hole in gq_tmap_style

- [ ] `gq_tmap_style()` errors for any type outside `polygon|line|point` even
      when classification is present (today it returns `list()` silently)
- [ ] Restore the bug and confirm the test fails, patching both
      `asNamespace("gq")` and `as.environment("package:gq")`
- [ ] Exclude raster from the two whole-registry sweeps, each with a premise
      assertion that at least one raster exists
- [ ] Give `test-gq_tmap_style.R:90`'s negative fixture its premise

## Phase 5: Cross-repo issues

- [ ] rfp issue — `edna` and `monitoring` have empty `symbol`/`color` and
      QGIS-default white QMLs; gq will not invent colours
- [ ] gq issue — widen `Floodplain` and register project rasters
- [ ] gq issue — `Tracking`, `parameters_habitat_method`,
      `parameters_habitat_thresholds` ship with no `groups.csv` row; then update
      `test-template_drift.R`'s "Project Specific" reason which cites gq#64
- [ ] Edit the #64 body so it reads correctly top to bottom

## Validation

- [ ] Tests pass
- [ ] `local_exempt` is empty and the "still needed" assertion passes
- [ ] `reg_build_main.R` run twice → `cmp` reports no change
- [ ] `lintr` compared against the `HEAD` baseline, not against zero
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
