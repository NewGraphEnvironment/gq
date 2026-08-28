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
