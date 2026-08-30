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

### Phase 3 — habitat_lateral + translator guards (complete, one commit)

- reg_custom.csv gains two raster rows carrying the QGIS palette; reg_main.json
  rebuilt to 57 layers, idempotent (two runs byte-identical).
- `local_exempt` is now `setNames(character(0), character(0))` — **empty**.
  The issue's acceptance criterion is met.
- Three code fixes, each verified by restoring the bug: `gq_tmap_style()` type
  check moved ahead of the classification branch (was returning `list()`),
  `gq_mapgl_classes()` now refuses a raster (was returning a well-formed match
  expression that resolves against nothing), and `classes[[class_value]]` gets
  `as.character()` (was positional for a numeric key). Reverting each turned
  2 / 1 / 1 tests red respectively.
- Four whole-registry sweeps fixed, not the two the first plan named — the plan
  review found `test-gq_tmap_style.R:355`. Routed through `drawable_keys()`,
  which asserts the excluded SET equals `habitat_lateral` rather than merely
  being non-empty; the weaker premise passed in both wrong directions.
- Code review round 2 returned 3 findings, all applied. One of its claims was
  wrong on probing — it said tightening the mapgl guard broke no existing test;
  it broke one, whose fixture carried no `type` at all. That fixture was how the
  escape hatch nearly shipped.
- lintr down or equal on every changed file (7->5, 2->0); remainder are the
  documented installed-vs-source `object_usage_linter` false positives.

### Phases 4 and 5 — bookkeeping and cross-repo issues (complete)

- Filed gq#71 (per-class opacity dropped; bec_zone renders at full opacity),
  gq#72 (widen Floodplain; needs a source_type for project rasters and a fix for
  colliding layer names), gq#73 (Tracking + habitat parameters unregistered),
  and rfp#229 (edna/monitoring have no declared symbology).
- Repointed `test-template_drift.R`'s "Project Specific" exemption from gq#64 to
  gq#73. The reason stayed true when #64 closed; only its citation went stale.
- Rewrote the #64 body and title — it asserted nothing described the forms and
  asked live-or-stale, both now answered, and offered themes absence as evidence
  that does not hold.
- NEWS.md entry and version bump to 0.12.0.
- `R CMD check`: 0 errors. The 2 warnings and 2 notes are all pre-existing —
  non-ASCII traced to a string literal on main, undocumented example datasets,
  and two `.Rbuildignore` gaps.
