# Task: Move 1: vendored artifacts current and guarded (batches 1, 2) (#100)

**If we do it:** the rosters and styles gq copies from the template repo are current, the registry and the templates agree on where each layer sits, and a copy going stale fails a test. **If we never do:** the drift test keeps passing against a copy vendored months ago, and every consumer of gq's groups and themes reads a roster the templates have moved past.

## Context

gq copies four artifacts from rfp, the private repo that builds the QGIS templates: `template_groups.csv`, `themes.csv`, `form_types.csv` and the QML corpus. The drift tests compare against those copies, so a copy that goes stale keeps the suite green. This move brings every copy up to date with rfp **v0.93.0** (`80bff2c4`). It then makes the registry agree with the templates on where each layer sits, and makes a stale copy fail a test. Two batches, one phase each, one PR. The PR body carries `Relates to NewGraphEnvironment/sred#<N>`, taken from memory.

### Peer read (done before the gate, 2026-11-05)

I read the open themes and groups work in rfp and rtj: rfp#188, #211, #300, #342, #409, PR #412, #128 and #229, and rtj#319, #324, #372, #406, #329, #273 and #285. The read settled who owns what:

| roster | owner | effect on this move |
|---|---|---|
| group tree, layer placement | rfp: the roster CSVs under `data-raw/qgs/roster/` build the `.qgs` (rfp#335, v0.77.0); rtj#324 says "Structure is owned by two roster files" | gq takes rfp's placement. `template_groups.csv` stays a copy of the built `.qgs` |
| themes | rfp registry, plus per-project base/add/drop in rtj (rtj#319) | the template themes have not changed: 268 rows over 9 pairs, as vendored. Floodplain theme retirements (#412, rtj#406) are per-project, not per-template, so nothing moves here |
| form roster | rfp (rfp#229: "the intended handshake") | re-vendor |
| QML store | gq is the intended owner (rfp#188), but rfp still holds the store today | the guard is built here. Where the 4-tag fix lands waits on rfp#188 |
| `source_type` | contested (rtj#273); no issue settles it | out of scope |

rfp#128 is now `Base - lidar` plus a DEM theme, not a Terrain group. Nothing moves until it ships, and the currency guard will catch it when it does.

### Measured against rfp v0.93.0 (in memory, gq's own walkers)

- **`template_groups.csv` is stale.** bcrestoration is missing `Floodplain` (7) and `Restoration` (8), and four orders have shifted. This is exactly the diff #70 recorded.
- **`themes.csv` is current:** 0 rows differ, and no key is missing from `groups.csv`.
- **`form_types.csv` is stale.** eDNA is now styled (#94). Four forms are new: `monitoring_general`, `scan`, `observation` and `tree`. `trail_feature` was retired upstream (rfp `3a83239d`). There are now 16 spatial forms, up from 13.
- **QML:** every file both stores hold is byte-identical. rfp also holds `raster/dem_*`, `airphoto_gray`, `osm.trail`, `forms/` and `seed/`. This is by design: rfp#188 says "raster styling stays wholly here", and `osm.trail` has no index row.
- **Six placements differ (#68)**, all from gq's first commit `3cee619` with no measurement behind them. Each layer sits in the same group in both templates.
- **The three layers in #73 are no-geometry tables** in rfp's roster (`wkb_type NoGeometry`).

## Decided at the gate (owner, 2026-11-05)

1. **No `template` column** in `groups.csv`. Keep the `Basemap/Terrestrial Ecology` exemption and rewrite its reason to cite rfp#216's decision. Add the column question to #104 (move 5).
2. **Adopt the templates' placement** for all six layers in #68. gq's rows were unchecked drift.
3. **Exempt** Tracking and the two parameters tables (#73). They are non-spatial, so there is nothing to style or order.
4. **Keep the `bcfishobs_fiss_fish_observations` key.** The rename goes with rtj#318's coordinated change.

Decided by me (mechanism), recorded here:

- The live comparison runs in gq, gated on `RFP_*_DIR`. **Detection in CI belongs in rfp**: rfp's CI clones the public gq with no credential. I file that as an rfp issue. No auto-PR, and never auto-merge (#78).
- The fix for the 4 dangling tags (#86) waits on rfp#188, the one open rfp item that changes this move's order. gq pins those 4 as a known set that "must still be needed". The tier-1 check reads gq's own corpus, so it is correct whichever repo ends up holding the store.
- No rfp backlog sweep before this move. Of the 17 rfp/rtj items read, only rfp#188 changes what is built here. The rest are per-project, or the new currency guard catches them when they ship (rfp#128, #211, #229, rtj#329).
- Vendor from a detached rfp worktree at tag v0.93.0, in the scratchpad, not from the local checkout, which is 21 commits behind.

## Phase 1: Template agreement (#70, #94, #68, #73)

- [x] Create a detached rfp worktree at `v0.93.0` in the scratchpad. Re-vendor `template_groups.csv`, with `RFP_TEMPLATE_DIR` pointing at the worktree, and `form_types.csv`, with `RFP_LOOKUPS_DIR` pointing at it. Run `themes.csv` and `styles_vendor.R` too, to confirm they are unchanged. Record the rfp version in each commit message.
- [x] Watch `test-template_drift.R` go red: that proves the guard reads the new copy. Then delete the `Floodplain` and `Restoration` exemptions (#70).
- [x] Rewrite the `Basemap/Terrestrial Ecology` reason: rfp#216 decided bcfishpass does not carry the group, and the template column is deferred to #104. Edit #104's body to add the `template` column question.
- [x] Rewrite the `Project Specific` reason (#73): the group holds three no-geometry tables and Field Data, and gq styles nothing a map draws. Cite #73.
- [x] Shrink the `test-gq_forms.R` unstyled pin to `form_fhap, form_fish_sample, form_monitoring` (#94). Check the re-vendored roster's new forms against the test's assumptions. `trail_feature` is retired upstream, so fix any references outside `form_types.csv`.
- [x] Move the six rows in `groups.csv` to the templates' paths (#68): `streams_all` and `first_nation_reserve` to `Basemap/Waterbodies`, `fisheries_sensitive_watersheds` to `Basemap`, `stream_labels` to `Streams/Stream labels`, and the two terrain boundary layers to `Basemap/Terrestrial Ecology`. Renumber `order` to match the template's relative order. Rebuild `reg_main.json` only if a build input changed.
- [x] Layer-level guard (#68). Add `qgs_layer_table()` to `R/utils_qgs_groups.R`, beside `qgs_group_table()`, so the existing walker also emits layers. Vendor its output as `inst/registry/template_layers.csv` from `reg_extract_template_groups.R`. Add a test: for each layer present in both, per template, gq's group path equals the template's, with an empty exemption list. Add a perturbed-fixture alarm that moves one layer, plus a check that the assertion discriminates.
- [x] Fix whatever downstream pins the moves break (`test-composition_integrity.R`, `test-gq_groups.R`, the vignette legend coverage). Read each failure before changing a pin. Update the counts in `CLAUDE.md`: forms 13 → 16, and the `groups.csv` description.

## Phase 2: Vendored-artifact guards (#78, #86, #92)

- [x] Move `extract_themes()` into `R/utils_qgs_themes.R` (#78), and the form-roster derivation into `R/` as well. Make the `data-raw/` generators call those functions, and re-run both to show the output is byte-identical.
- [x] Add one currency test, `tests/testthat/test-vendored_currency.R`, covering the four roster copies: template groups, template layers, themes and forms. Move the template-groups live check there from `test-template_drift.R`. Each check is gated on its `RFP_*_DIR`, with an installed-rfp fallback, and each skip reason names its artifact. The QML byte-identity check **stays where it is** in `test-gq_style_qml.R`: rfp#188 item 4 deletes it once gq holds the store, so moving it now would be work done twice. A comment in the new file points to it and to rfp#188.
- [x] Add a perturbed themes fixture (a small `.qgs` with presets) to show the themes alarm firing, plus the discriminating check, following the existing fixture's pattern.
- [x] Add a tier-1 QML consistency test over the whole corpus (#86). A tag that configures one field (`<field name>`, `<column name type="field">`, `editable`, `labelOnTop`, `reuseLastValue`, alias, default, constraint) must name a field in that QML's own roster, or the test fails. Expressions (`previewExpression`, the label `fieldName`, the renderer `attr`) that are not in the roster go to an "undecidable" list, not a failure. Positive pin: exactly the 4 `fish_obsrvtn_pnt_distinct_id` hits, as a set that must still be needed. Negative control: `species_name` is not refused. Prove the test fires by injecting a bad reference into a copy of another QML.
- [x] #86 tier 2: check whether `fid` and `linear_feature_id` are columns of `bcfishobs.observations`, through db-newgraph. If the database is unreachable, leave that item open on #86 and say so.
- [ ] File one rfp issue: rfp's CI clones gq and runs `test-vendored_currency.R` with `RFP_*_DIR` pointing at its own checkout. For the 4 dangling tags, add them to rfp#188's body as a worked case instead of filing a separate repair issue. Which repo repairs them follows from #188's store decision, so a separate issue now could need writing twice.
- [ ] Mechanically enumerate the causal and behavioural claims about rfp in the `data-raw/*.R` comment blocks and in `CLAUDE.md`'s repo-relationship sections (#92). A script lists each sentence that names rfp. In `findings.md`, give each one a named rfp source (file:line, test or README) or mark it as a local decision. Fix the false ones, including those the re-vendor falsifies: the nelson `trail_feature` example, and "parent populated only on cabin_visit_pebble", which `tree_visit` and the eDNA child now contradict.
- [x] Rewrite `CLAUDE.md`'s "The witness itself is unguarded" paragraph to describe the guard as built.

## Owed at the end (reported, done after merge)

- [ ] When rfp fixes the 4 tags, re-vendor the QML and delete the pin. The pin's "must still be needed" check fails at that point and says so.

## Validation

- [ ] Tests pass (`devtools::test()`, with the `RFP_*_DIR` variables pointing at the v0.93.0 worktree, so the live checks run and do not skip. Read the SKIP count as well as the FAIL count)
- [ ] `devtools::test()` without the variables: the new currency checks skip (env-gated only, review #7); the older template-groups live check may still run against an installed rfp
- [ ] `/code-check` clean (once over the branch with `/code-check branch`)
- [ ] `lintr` per-file diff against `origin/main`; `devtools::document()`; `pkgdown::check_pkgdown()` (no new exports expected)
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

How each change is proved: each new guard is shown red by restoring the defect (the stale copy, a moved layer, a perturbed preset, an injected bad QML reference) before it is shown green. Each re-vendor is reproduced from the v0.93.0 tag. Refactoring the generators is proved by byte-identical output.
