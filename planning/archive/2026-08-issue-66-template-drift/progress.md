# Progress — Registry and shipped templates disagree (#66)

## Session 2026-08-28

- Plan-mode exploration — measured the drift directly against
  `rfp/inst/templates/*.qgs` rather than taking the issue body on trust. Three
  corrections to the issue recorded in `findings.md`.
- Two rounds of user decisions: names adopt the template spelling as a single
  join key; order stays gq's to declare but only where deliberate, so the
  exemption list is two entries and rfp gets one issue, not twenty.
- Landed the pending `CLAUDE.md` SR&ED scrub on `main` first (`8fce4c2`) so it
  does not ride onto this branch.
- Created branch `66-registry-and-shipped-templates-disagree` off main.
- Scaffolded PWF baseline with the approved phases.
- Next: Phase 1 — `qgs_group_table()` and the vendored
  `inst/registry/template_groups.csv`.

### Phase 1 — extractor and vendored artifact

- `R/utils_qgs_groups.R`: `qgs_group_table()` plus `read_template_groups_csv()`.
- `data-raw/reg_extract_template_groups.R`, `RFP_TEMPLATE_DIR` preamble copied
  from `reg_extract_themes.R`.
- `inst/registry/template_groups.csv` — 31 groups, bcfishpass 15 /
  bcrestoration 16, quoted.
- Dropped a sibling-order uniqueness check from the extractor before committing:
  `order` is the sibling loop index, so it is distinct by construction and the
  assertion could not have failed.
- Test baseline on this branch: 962 passing, 0 failures (the plan said 941).

### Phases 2-4 — guards, names, composition

- `tests/testthat/test-template_drift.R` (11 tests) plus
  `tests/testthat/fixtures/template_drift_fixture.qgs`.
- Written first and watched fail: 9 failures on the pre-fix registry, every one
  on a real divergence. Re-verified after the fix by running the landed guards
  against `git show main:` versions of both CSVs — narrow check red on both
  templates.
- Four group renames adopted from the templates; `groups.csv` and
  `templates.csv` are now quoted (mandatory, not hygiene:
  `Roads,Railways,Pipelines` would be six fields against a three-column header).
- `Base - Orthoimagery` deleted, `orthophoto_tiles` moved to
  `Basemap/Terrestrial Ecology`; `Floodplain`/`Restoration` above `Basemap`.
- Plan review returned mid-phase; 4 of 6 findings real, folded in. Two of them
  were defects in my own fix. Recorded in `findings.md`.
- `devtools::document()` — `man/gq_templates.Rd` gained the `Ordering` section
  it never had.
- 992 passing, 0 failures. lintr clean on all changed files.

### Phase 5 — issues

- rfp#216 filed: three groups gq declares that the templates lack, with
  positions stated, plus the two prose misattributions.
- gq#68 filed: the six remaining layer-placement disagreements.
