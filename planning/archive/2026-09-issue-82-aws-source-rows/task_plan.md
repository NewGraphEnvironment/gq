# Task: Registry disagrees with rfp's aws source list on three rows, including habitat_lateral (#82)

Three rows where gq's registry and rfp's aws sourcing disagree. Two cost a silent
failure on every project build; one costs hand-clipping a raster per project. Found
building `thompson_20260907` (rtj#316, rtj#318).

Exploration changed the shape of the issue — see `findings.md`. The short version:
**gq's registry is the cause of the two failed requests**, not a bystander to rfp's
list. `rfp_project_create()` resolves its layer set through `gq::gq_template_layers()`,
not through `rfp/inst/lookups/rfp_source_aws.txt`.

Decisions taken at the plan gate, 2026-09-07:

| row | decision |
|---|---|
| `habitat_lateral` | `source_type = aws`, `source_layer = habitat_lateral.tif` |
| `bcfishobs_fiss_fish_observations` | rename to `bcfishobs.observations` now; file rfp with the exact template lines |
| `dam` | keep the row; file **NewGraphEnvironment/db_newgraph** (our fork, not smnorris) |
| drift guard | **not in scope** — defer to gq#78 |

## Phase 1: Tests first (failing)

- [x] Split the `aws` rule in `tests/testthat/test-composition_integrity.R` into
      table-targets (`^schema.table$`) and a named file-target exemption, so
      `habitat_lateral.tif` is deliberate rather than an accidental pass of
      `grepl(".", fixed = TRUE)`
- [x] Pin the three registry values: `habitat_lateral` -> `aws` / `habitat_lateral.tif`;
      `bcfishobs_fiss_fish_observations` -> `bcfishobs.observations`; `dam` ->
      `bcfishpass.dams` unchanged, citing the db_newgraph issue
- [x] Pin that `bcfishobs_fiss_fish_observations` still carries its `mark` and `label`
      (the `gq_reg_merge()` replace-semantics trap)
- [x] Confirm every new assertion FAILS against HEAD before implementing

## Phase 2: habitat_lateral -> aws

- [x] `inst/registry/groups.csv` — `habitat_lateral` `local` -> `aws`
- [x] `inst/registry/reg_custom.csv` — `source_layer` -> `habitat_lateral.tif` on both
      palette rows
- [x] Rebuild `reg_main.json` via `data-raw/reg_build_main.R`
- [x] Update `tests/testthat/test-gq_reg.R` if it asserts the old `source_layer`
- [x] `CLAUDE.md` — record that `habitat_lateral` is `aws` with a file target

## Phase 3: bcfishobs rename

- [x] Correct `source_layer` -> `bcfishobs.observations` in `data-raw/reg_build_main.R`,
      NOT in the extracted JSONs. Changed from the approved plan: the repo already has
      this exact pattern (the bcfishpass#13 ACCESS block), and it is strictly better —
      the transcript stays an honest record of the template, a re-extraction cannot
      silently revert it, and the symbology is not duplicated
- [x] Rebuild `reg_main.json` — one line moved
- [x] Guard stops the build when rfp's templates are regenerated, or when the name
      moves again; both arms proven to fire against a mutated source, then restored
      byte-identical

## Phase 4: Cross-repo issues and body reconciliation

- [x] File rfp issue — rfp#305. FOUR lines, not two: each template carries the old
      name in both the `<datasource>` element and the layer-tree `source=` attribute
- [x] File NewGraphEnvironment/db_newgraph issue — db_newgraph#20
- [x] Edit gq#82's body — corrected in place, and retitled: the counterparty is the
      bucket, not rfp's list
- [x] Comment on rtj#318 pointing at the resolution

## Phase 5: Release and PR

- [x] `NEWS.md` + `DESCRIPTION` bump as the final commit
- [ ] `/planning-archive`, then `/gh-pr-push`

## Validation

- [x] `devtools::test()` — 1111 pass; the 2 failures are pre-existing on origin/main
      (gq#70, gq#78 stale vendored artifacts), verified in a worktree at e3b0178
- [x] `devtools::document()` clean; `pkgdown::check_pkgdown()` clean
- [x] `/code-check` on each commit
- [x] PWF checkboxes match landed work
