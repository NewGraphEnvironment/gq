# Task: Registry and shipped templates disagree on groups, names and order, with nothing checking (#66)

`inst/registry/templates.csv` and `groups.csv` declare a group structure that no
shipped `.qgs` has. Nothing ever compared them, so the declaration drifted into
fiction — and twice now that has cost a field user a layer, because a group
hand-added at whatever position the person was standing in lands **last in the
tree**, which is beneath the opaque raster basemap the themes turn on.

## Decisions taken (2026-08-28)

- **Names are the join key, one per thing — template spelling.**
  `rfp_project_create()` copies the template and trims, so a project's tree node
  is literally `Roads,Railways,Pipelines`. Two spellings is a broken join in both
  directions. This is not "the template outranks gq".
- **Order and composition stay gq's to declare.** The guard is directional:
  where gq's order is deliberate it stands and rfp catches up.
- **But only where deliberate.** The Roads/Streams swap is unchecked drift;
  claiming rfp must match an accident is how one issue becomes twenty. Adopt the
  template order there. Hold gq's order for `Floodplain` only.
- **Exemption list of two** (`Floodplain`, `Restoration`) → **one** rfp issue.
- The 9 genuine layer-placement disagreements are **out of scope** — measured,
  recorded in `findings.md`, filed as a gq follow-up.

## Phase 1: Extractor and vendored artifact

The QML-corpus shape: gq is public, rfp is private, so CI cannot read a `.qgs`.
Vendor a committed artifact; the live comparison skips when rfp is absent.

- [x] `R/utils_qgs_groups.R` — internal `qgs_group_table(path)` walking
      `/qgis/layer-tree-group/layer-tree-group`, returning `group_path`, `depth`,
      `order`. Names byte-exact. `order` indexes group **and** layer element
      children (rfp `data-raw/qgs/extract_roster.R:50-53` — indexing layers alone
      cannot place a subgroup). In `R/`, not `data-raw/`, so the alarm-can-fire
      test can call it.
- [x] `data-raw/reg_extract_template_groups.R` — `RFP_TEMPLATE_DIR`, then
      installed rfp, then stop with instructions. Copy `reg_extract_themes.R`'s
      preamble; the reason is identical.
- [x] `inst/registry/template_groups.csv`, **quoted**. `Roads,Railways,Pipelines`
      carries a comma; `Model Parameters - bcfishpass ` a trailing space.
- [x] Read with `utils::read.csv()`, never `readr` — `trim_ws = TRUE` eats the
      trailing space and silently breaks every path match.

## Phase 2: Guards, each seen to fail

`tests/testthat/test-template_drift.R`.

- [x] Every `templates.csv` group exists in `template_groups.csv`; every
      `groups.csv` group/subgroup path likewise. Exemptions carry a reason plus
      the rfp issue that removes them, and each is asserted **still needed** —
      the `test-composition_integrity.R:74-79` pattern.
- [x] Relative order of groups present on both sides agrees, same exemptions.
- [x] **Narrow check** — no group declared below the bottom-most template group.
      Red today on `Base - Orthoimagery`.
- [x] **Premise beside the assertion** — the bottom template group holds
      `esri_world_topo`, `bing_aerial`, `esri_satellite`, `google_satellite`. If
      that moves, the rule's basis moved and the test says which.
- [x] Round-trip: `Model Parameters - bcfishpass ` survives write→read
      byte-exact.
- [x] **Alarm can fire** — a small `.qgs` fixture with one group renamed; assert
      it is reported.
- [x] Restore the bug: confirm every guard goes red before moving on. A guard
      nobody has seen fail is decoration.

## Phase 3: Adopt template names as the key

- [x] `groups.csv`: `Other Point Features` → `Other point features`;
      `Roads/Rails/Pipelines` → `Roads,Railways,Pipelines`; subgroup
      `Habitat Models` → `Habitat models`; `BEC` → `Terrestrial Ecology`.
      Write quoted.
- [x] `templates.csv`: same names, quoted.
- [x] Three gq call sites: `tests/testthat/test-gq_groups.R:34`,
      `tests/testthat/test-gq_trail_style.R:86`, `R/gq_groups.R:137`.
- [x] ~~`reg_extract_themes.R`'s unquoted-comma guard~~ — **dropped, premise
      false.** That guard scans the `themes` data frame; group names never enter
      `themes.csv`. Verified before editing. Touching it would have been a net
      loss.

## Phase 4: Fix the ordering bug, settle composition

- [x] Delete `Base - Orthoimagery`; `orthophoto_tiles` → `Basemap` /
      `Terrestrial Ecology`, where the template has it.
- [x] ~~Declare `Project Specific` and `Base - lidar`~~ — **not
      representable.** `Base - lidar` is EMPTY in both templates and
      `Project Specific` holds only gq#64 layers; `groups.csv` is one row per
      layer, so neither can be declared. Exempted instead, in the second
      exemption list, each asserted still needed.
- [x] Adopt Roads-before-Streams (template order); it was never a decision.
- [x] `Floodplain` above `Basemap` — deliberate, kept, exempted with the reason
      (46% of change area is water-class, hidden by Basemap's waterbody fills).
- [x] `Restoration` kept, exempted — `local` layers, no template equivalent.
- [x] Third exemption the plan missed: `Basemap/Terrestrial Ecology` is
      bcrestoration-only and `groups.csv` has no `template` column, so declaring
      it declares it for bcfishpass too. Path guard rewritten per-template.
- [x] `devtools::document()` — `man/gq_templates.Rd` had no `Ordering` section.
- [x] Correct `gq_templates()`'s `@section Ordering:` evidence. Rule stays.
- [x] Reconcile `test-composition_integrity.R`'s `restoration_only` assertion
      with the new exemptions.

## Phase 5: One rfp issue, and the deferred work

- [x] **One** rfp issue, with a table: add `Floodplain` above `Basemap` and
      `Restoration` to both templates. Two secondary notes: `Land Tenure` appears
      once in `bcrestoration_mobile.qgs` but in neither layer tree; and
      `rfp/R/rfp_qgs_theme_add.R:13-14` attributes non-portable theme group rows
      to names diverging *between the templates* — they do not, both carry
      identical names, and the mechanism is the differing root prefix
      (`bcfishpass Mobile ` / `bcrestoration Mobile `) plus
      `Basemap/Terrestrial Ecology` existing only in bcrestoration.
- [x] gq follow-up issue for the 9 layer-placement disagreements, measurement in
      the body.
- [x] Reconcile #66's body: the templates are structurally identical, not
      divergent as its table implies; `Base - Orthoimagery` and `Basemap/BEC`
      never existed; the narrow check fails on the registry itself.

## Phase 6: Land it

- [x] `NEWS.md` + `DESCRIPTION` 0.10.0 → **0.11.0**. Minor: `gq_groups()`,
      `gq_group_layers()` and `gq_template_groups()` return different group
      strings, visible to any consumer matching on name.
- [x] `/planning-archive`, `/gh-pr-push`.

## Validation

- [x] `devtools::test()` — 992 passing (962 baseline, +30)
- [x] `lintr` clean on changed files (baseline 0)
- [x] `devtools::check()` no new ERROR/WARNING/NOTE against main's 0/2/2
- [x] `/code-check` clean on each commit
- [x] PWF checkboxes match landed work
- [x] `/planning-archive` on completion
