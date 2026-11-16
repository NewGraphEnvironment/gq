# Task: Layer order within a group disagrees with the templates in 7 groups (#105)

**If we do it:** `groups.csv`'s `order` says the same thing as the templates about which layer draws over which inside a group, and a test keeps it that way. **If we never do:** `gq_template_layers()` sorts layers in an order no template uses, and nothing reports it.

Plan approved by the owner 2026-11-15 at the /planning-init gate.

## Context

`groups.csv`'s `order` column is the z-order within a group (order 1 draws on top, as the
first child does in the QGIS layer tree). #68 (gq#100) aligned **which group** each layer
sits in with the shipped templates. It left **order within a group** alone, and on the layers
both sides carry it differs in 7 groups, the same way in both templates (`Basemap`,
`Basemap/Waterbodies`, `Crossings`, `Streams/Habitat models`, `Roads,Railways,Pipelines`,
`Web Mapping Services`, `Base - misc`). Nothing tests it.

**What gq's side rests on:** every row in those 7 groups dates from the registry's first
commit (`3cee619`) or from #41/#100 insertions, and none was measured. The one prior note is
in the #66 archive's findings: the `Base - misc` basemap order was recorded as "not a defect"
(all four basemaps are opaque) and passed to #68. It records the disagreement and doesn't
argue for gq's order. By the CLAUDE.md reconciliation rule, the templates' order is adopted
in all 7 groups.

**Who reads `order`:** only `gq_group_layers()` and `gq_template_layers()` sort by it. rfp
passes it through `rfp_project_layers()` and never reads it (checked in rfp's `R/`), so the
template repo is unaffected.

## Decided at the gate

- **Adopt the templates' order in all 7 groups.** None of gq's values was a decision (above).
- **Number the column contiguously, 1..N within each group.** The template's sibling index
  has gaps where subgroups sit (Basemap skips 4 for `Waterbodies`). Copying those gaps would
  hint at an interleave that `groups.csv` cannot express.
- **gq-only layers keep the neighbour above them.** This is the rule #100 used for placement.
  The effect on each one:
  - `town` moves from 13 (the bottom of `Basemap`) to 4, after `glaciers`.
  - `rivers_poly` stays after `first_nation_reserve` and so ends up last in `Waterbodies`.
  - `dam` stays last in `Crossings`.
  - `bec_zone` doesn't change (its group already agrees).
  If you'd rather keep `town` at the bottom of `Basemap`, say so at the gate. Neither
  position has been measured.
- **Out of scope, and handed to #104:** placing a subgroup *among* its parent's layers (the
  templates draw `Waterbodies` as Basemap's 4th child), and order between sibling subgroups
  (`Stream labels` above `Habitat models` in both templates, while gq sorts by name). Both
  need an order key that layers and subgroups share, which is a schema change. This PR
  documents the limit and does not pin it as a test: a test that enforces a known defect
  makes it look deliberate (gq#77).

## Phase 1: Failing relative-order test

- [x] In `tests/testthat/test-template_drift.R`, add `order_drift(layers, template)` beside
      `placement_drift()`. For each group path it compares gq's order with the template's,
      on the shared layers only (as the group-order check does). It returns one row per
      group path that disagrees, with both sequences.
- [x] Premise test: each of the 7 groups has at least 2 shared layers in each template.
      Otherwise the comparison would pass with nothing compared.
- [x] Test "layer order within each group agrees with the template", run per template.
- [x] Run it and confirm it is red on the current `groups.csv`, naming exactly the 7 group
      paths in both templates (the guard seen to fire against the real defect).
- [x] Alarm test: swap two `Base - misc` rows' `order` in an in-memory copy of
      `read_template_layers_csv()` and check `order_drift()` reports `Base - misc`. Against
      the real table, after Phase 2, it reports nothing, which shows the test can tell the
      two apart.

## Phase 2: Renumber `groups.csv`

- [x] Renumber `order` in the 7 groups from `inst/registry/template_layers.csv`, inserting
      gq-only layers by the predecessor rule above. Leave `source_type` and membership alone.
- [x] Phase 1 tests green; `test-composition_integrity.R` "draw order is unambiguous" green.
- [x] Confirm `reg_main.json` doesn't need rebuilding: `test-reg_build_currency.R` green, since
      the build doesn't read `groups.csv`.

## Phase 3: Document the order and its limit

- [x] Roxygen for `gq_group_layers()` and `gq_template_layers()`:
  - `order` 1 draws on top, matching the QGIS layer panel.
  - It agrees with the templates within a group.
  - A group's own layers sort before its subgroups, and subgroups sort by name, whereas the
    templates interleave them (#104).
  - Then run `devtools::document()`.
- [x] `CLAUDE.md`: in the `groups.csv` line, say that `order` agrees with the templates within
      a group and that `test-template_drift.R` holds it there.
- [x] `NEWS.md` entry: which layers moved and why.

## Phase 4: Hand the interleave to #104

- [ ] Edit #104's body (Batch 11): add an order key that layers and subgroups share. It would
      cover subgroup-among-layers and sibling-subgroup order, citing #105. Make the same
      addition to batch 11 in `planning/backlog.md`.

## Validation

- [ ] Tests pass (`devtools::test()`, grep for FAIL/ERROR)
- [ ] `lintr::lint_package()`: no new lints in the touched files
- [ ] `/code-check branch` clean (three-round floor)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

**How each change is proved:**
- **The test:** red on the old `groups.csv` naming the 7 groups, green after the renumber,
  and the perturbation alarm reports the swapped group.
- **The renumber:** a diff of `gq_template_layers()` row order before and after, for both
  templates, showing only the 7 groups moved (plus `town`).
- **rfp is unaffected:** it reads `order` nowhere, which a grep of rfp's `R/` already shows.

