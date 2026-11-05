# Plan review — #100 (Plan agent, spawned 2026-11-05T16:50Z, delivered after phase 1 commit)

Delivered as reply text (Plan agents cannot write); recorded here verbatim in substance.

1. **Blocker** — tier-1 QML check cannot yield "exactly the 4": `editable`/`labelOnTop`/`reuseLastValue`/`column[@type=field]` name fields outside `fieldConfiguration` ~1315 times in 83 (file, tag) pairs across 29 files (conservancy, streams_all, stream_labels, wetland, …). alias/default/constraint/constraintExpressions/policies/attributeEditorField: 0 hits. The 4 bcfishobs hits sit only in the noisy tag types. Expressions outside roster: 15 in 14 files.
2. **Assumption** — `R/gq_groups.R:111,230` sort a group's own layers before its subgroups; the template puts `Basemap/Waterbodies` 4th among Basemap's children, so order across a subgroup boundary cannot be expressed. rfp's `rfp_project_layers.R:27-31` uses membership and source_type only.
3. **Gap** — within-group order unguarded; differs in 7 paths.
4. Layer join is clean (54/59); unmatched template-side: tracking + 2 parameters; gq-side: town, rivers_poly, bec_zone, dam, harvest_area, planting_site. Guard must be one-way and assert per-template unique keys.
5. **Assumption** — `NoGeometry` also on national_park and old_growth_management_areas in the built `.qgs`; cite rfp `R/rfp-constants.R:174-176` for rfp_tracking instead.
6. Forms — guards hold; new key is `form_general_monitoring`; stale "13" at `R/gq_forms.R:20` (roxygen) and `reg_extract_form_types.R:13`; parent claim at `:205`; trail_feature retirement needs NEWS; pin edna/tree child exclusions; `test-gq_groups.R:31` breaks.
7. **Acceptance** — validation step 2 wrong: installed rfp 0.92.0 is byte-identical, so checks run, not skip; on an older install they would fail falsely. Gate the new test on env vars only; `RFP_STYLES_DIR` needed too.
8. **Scope** — fifth rfp-derived artifact: `reg_qgis_restoration.json` (`data-raw/reg_extract_restoration.R`). Add or record why excluded.
9. **Acceptance** — #86 items 4–5 not meetable this cycle: PR says "Relates to #86". #70 closing note must cite the gate decision (2 of 3 deleted, no column).
10. **Ordering** — red-test proof needs the stale copy restored.

## Dispositions

See findings.md, "Plan review dispositions".
