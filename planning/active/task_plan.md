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

- [x] `data-raw/reg_extract_form_types.R`, mirroring `reg_extract_themes.R` and
      `reg_extract_template_groups.R`: `pkgload::load_all()` unconditionally,
      `RFP_LOOKUPS_DIR` env override with a `system.file()` fallback and a clear
      stop when rfp is absent, rfp version printed for the commit message
- [x] Derive `layer_key` by rfp's own rule —
      `normalize_layer_name(paste0(" Form ", label))` — not from the `type`
      column. Discriminating case: `monitoring_fish_passage` has label
      "Fish Passage Monitoring", so its key is `form_fish_passage_monitoring`
- [x] Drop non-spatial rows (`has_spatial != "true"`) — excludes
      `cabin_visit_pebble`, a child table with no geometry
- [x] Write `inst/registry/form_types.csv`, quoted (`label_expression` carries
      commas and embedded quotes)
- [x] `R/gq_forms.R` — `gq_form_types()` reader with a runnable `@examples`
      block, following `gq_themes()` in shape

## Phase 2: groups.csv back to template contents

- [ ] Remove `form_edna` and `form_monitoring` rows from `groups.csv`
- [ ] Drop those two entries from `local_exempt`
- [ ] `tests/testthat/test-forms_roster.R` — roster shape, the derived-key
      oracle against `reg_main.json`, the `monitoring_fish_passage` pin, and
      premise assertions so the `has_spatial` filter cannot become a no-op

## Phase 3: habitat_lateral + the translator guards (ONE commit)

Merged, on the plan review's finding: adding the raster to `reg_main.json`
breaks six sweeps that the guard work fixes, and the sweep exclusions need the
raster to exist for their premise assertions. Landing them apart leaves a red
commit either way, which the repo's own convention forbids.

- [ ] Two `reg_custom.csv` rows: `type="raster"`, sentinel `source_layer`,
      `class_field="value"`, values 1/2, **`class_label`** Floodplain /
      Floodplain Disconnected by Railway, `#b2df8a` / `#9f3cca`, opacity 0.4.
      `class_label` was missing from the first draft — without it `gq_style()`
      falls back to `to_title(keys)` and the legend reads "1 / 2"
- [ ] `as.character()` at `R/gq_reg.R:114` — `classes[[r$class_value]]` is
      **positional** for a numeric key, and Phase 3 publishes the
      numeric-class-value convention. Probed: an integer key yields
      `names(classes) == NULL`
- [ ] Document the raster convention in `gq_reg_custom()` roxygen: why
      `class_field` is a sentinel (a paletted raster keys on pixel value, and
      the classification branch requires a non-NA field), and what the schema
      cannot carry (the QML's 30% per-value transparency)
- [ ] `gq_tmap_style()` errors for any type outside `polygon|line|point` even
      when classification is present (today it returns `list()` silently)
- [ ] `gq_mapgl_classes()` — same hole, worse direction. Probed: it **silently
      succeeds**, returning `["match", ["get","value"], ...]`, a `get`
      expression that is meaningless against a raster source
- [ ] Restore the bug via `local_mocked_bindings(.package = "gq")` — a function
      defined in the test file cannot see `tmap_classified()` (`@noRd`), so the
      naive patch dies with "could not find function" and reads as a false
      green. Assert `length(...) == 0L`, a value only the broken version yields
- [ ] `test-gq_tmap_style.R:90` needs a **second fixture carrying a
      classification**, not a premise line. The existing one passes because it
      has none, which is exactly why it never caught the hole
- [ ] Exclude raster from the sweeps the review found — `test-gq_tmap_legend.R`
      `:269` and `:297`, `test-gq_tmap_style.R` `:316` **and `:355`** — each
      with a premise assertion that at least one raster exists
- [ ] `helper-tmap_render.R` — `geom_for()` `:154` is what actually errors, and
      `tm_shape_classified()` `:146` defaults to `tm_dots`, so a raster would
      silently become a point layer if `geom_for()` did not error first
- [ ] Rebuild `reg_main.json`; verify idempotence with a second run and `cmp`
- [ ] Empty `local_exempt` as `stats::setNames(character(0), character(0))` —
      probed: plain `character(0)` and `c()` both give `names() == NULL`, which
      `expect_setequal()` **refuses**, so the obvious spelling breaks the
      acceptance test. Remove the prose block describing the three exemptions
      with them

## Phase 4: Bookkeeping

- [ ] `NEWS.md` — an exported function added (`gq_form_types()`) and an exported
      contract changed (`gq_tmap_style()` now errors where it returned `list()`)
- [ ] `DESCRIPTION` version bump, as the final commit of the branch

## Phase 5: Cross-repo issues

- [ ] rfp issue — `edna` and `monitoring` have empty `symbol`/`color` and
      QGIS-default white QMLs; gq will not invent colours
- [ ] gq issue — `gq_style()` drops per-class `opacity`. Found on the way past
      and **not** introduced here: `bec_zone` carries `fill_opacity 0.25` on all
      15 rows, so every BEC zone renders at full opacity today
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
