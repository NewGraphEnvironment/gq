# Progress — Three local layers grouped and shipped with no registry entry (#64)

## Session 2026-08-29

- Plan-mode exploration — two subagent surveys (rfp form artifacts, and the
  `restoration_wedzin_kwa` / Nelson projects). Phases approved by user.
- Established that the issue body's two premises were wrong: the forms are real
  (rfp ships gpkg + QML for both, with collected field data in live Mergin
  projects), and theme absence is not a staleness signal (30 of 64 keys are
  absent from `themes.csv`).
- Established the design constraint: forms are injected per-project by
  `rfp_qgs_form_add()`, so a 12-row `Forms` group in `groups.csv` would
  reintroduce gq#40's defect at 6x scale. Roster goes in its own vendored table.
- Created branch `64-three-local-layers-no-registry-entry` off main.
- Scaffolded PWF baseline with approved phases.
- Next: Phase 1, vendor rfp's form roster.

### Phase 1 — vendor rfp's form roster (complete)

- `data-raw/reg_extract_form_types.R` + `inst/registry/form_types.csv`
  (13 spatial forms of 14 registered) + `gq_form_types()` + tests.
- Code review round 1 returned 6 findings, all fixed: a provenance check that
  could not distinguish a failed git command from a clean file; `system2()` args
  unquoted so a checkout path with a space read as "not a git checkout"; a
  pkgdown example captioned "the two" over code printing four; a round-trip
  comment claiming a guard it does not have; `all(nzchar(x))` which cannot fail
  because `nzchar(NA)` is TRUE; and a tripwire whose message excluded the
  legitimate cause.
- Provenance guard verified against three states — non-repo, clean repo at a
  path containing a space, and a modified roster. The space case is what proves
  the quoting fix.
- Plan review returned 4 blockers and 6 gaps; all re-probed and confirmed. The
  worst is that emptying `local_exempt` the obvious way *errors* the acceptance
  test. Phases 3-5 rewritten accordingly; review saved to `review-64.md`.

### Phase 2 — groups.csv back to template contents (complete)

- `Forms` drops to `form_pscis`, `form_fiss_site`. Two of three exemptions gone.
- Full suite green. Nothing else moved: the draw-order test does not require
  contiguity (and the removed rows were the tail anyway), uniqueness cannot
  break by removal, and the group survives so no template mapping changes.
