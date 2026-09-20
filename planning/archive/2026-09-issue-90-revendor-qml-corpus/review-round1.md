# Review round 1 — gq#90 re-vendor `inst/styles` after rfp repairs

Branch `90-re-vendor-inst-styles-rfp-has-repaired`. Reviewed the staged diff
(`data-raw/styles_vendor.R` comment + 2 QML files), read every changed file in
full, and re-derived each of the five claims by an independent route.

## Findings

Two real issues. Both are the *same class the diff exists to fix* — a
restatement whose population moved — left standing in a second location.

- **[fragile] `tests/testthat/test-gq_style_qml.R:46-51` — the diff repaired the
  stale skipped-raster restatement in `data-raw/styles_vendor.R` and left a
  verbatim copy of it, with the same wrong rationale, in the test.**

  ```r
  # rfp ships two raster styles no template references — dem_hillshade and
  # dem_turbo, which back rfp_raster_styles() and carry a
  # renderer/companion/stretch dimension gq vendors none of. ...
  expect_false(any(c("dem_hillshade", "dem_turbo") %in% idx$layer_key))
  ```

  Two defects in five lines:

  1. **The count is stale the same way.** The script now reports **three**
     skipped rasters — I confirmed by running it, not by reading it:
     `skipping raster style(s) no template uses: airphoto_gray, dem_hillshade, dem_turbo`.
     The comment still says "two".
  2. **It repeats the rationale this diff's new comment explicitly says is
     wrong** — "which back `rfp_raster_styles()`". The new comment's whole point
     is that membership in `rfp_raster_styles()` is *not* the skip rule
     (`habitat_lateral` is in that roster and *is* vendored). So the repo now
     asserts the corrected rule in one file and the superseded one in another.
  3. **Line 51 is a live guard whose hardcoded set is one member short.**
     `airphoto_gray` is refused by nothing in the test suite. If the roster
     resolution in `styles_vendor.R` ever regressed to the globbing it replaced,
     `dem_hillshade`/`dem_turbo` would be caught by name and `airphoto_gray`
     would sail through. (`expect_setequal(on_disk, indexed)` in the sibling test
     does not cover it — that catches an *unindexed* file, not a wrongly-indexed
     one.)

  Checklist mechanisms: "A guard's scope, escape hatches, and remedies" — *a
  literal set used as a filter covers whatever the data happens to contain today
  and grows blind as it grows*; and "A fix lands in one of two callers" — *when
  you find one instance stale, grep for the sentence, not the file*.

- **[fragile] `data-raw/styles_vendor.R:280-281` — a second stale restatement in
  the file the diff edited, 90 lines below the one it repaired.**

  ```r
  # Reported, not fatal. The 4 forms are owned by rfp_form_build() and are out of
  # scope by design; the rest are genuine gaps worth naming rather than hiding.
  ```

  Measured. At `6bf069d`, the commit that introduced the comment,
  `inst/registry/groups.csv` carried **4** form keys (`form_edna`,
  `form_fiss_site`, `form_monitoring`, `form_pscis`). Today it carries **2**
  (`form_fiss_site`, `form_pscis`). The live run prints:

  ```
  groups.csv keys with no QML (8): town, rivers_poly, bec_zone, dam,
    form_pscis, form_fiss_site, harvest_area, planting_site
  ```

  So a reader of that message is told 4 of the 8 are out-of-scope forms and 4 are
  genuine gaps; the truth is 2 and 6. Present tense, no time qualifier, so by the
  convention's own rule ("a present-tense justification for a live guard must
  track") it is a claim that should have moved. Comment-only, not executable —
  hence `fragile`, not `bug`.

Nothing else. No correctness, security or data-loss defect in the diff.

---

## Claim-by-claim verification

### 1. "Exactly 2 files changed, `index.csv` byte-unchanged" — VERIFIED, and stronger

`git status --porcelain` shows exactly three paths (the two QMLs + the script),
no untracked residue, and `index.csv` appears in neither the staged diff nor the
working tree.

I also closed the harder half — that the script's `unlink()`-and-rebuild really
does reproduce this tree. Non-destructively: copied the script, redirected only
`dest` to a scratch path, ran it with `RFP_STYLES_DIR` at the checkout, then

```
command diff -rq <scratch>/rebuild inst/styles   -> IDENTICAL (61 files each)
```

(`command diff`, because `diff` is aliased to `git diff` on this machine.) So the
vendor script is idempotent against the current source and `index.csv`
reproduces byte-for-byte — the "regenerated artifacts churn git" hazard does not
apply here.

### 2. "60 files checked, 0 drifted" — VERIFIED by an independent route, with a working positive control

I did not re-use the shell loop. Re-derived in Python with `csv.DictReader`
(handles the quoting natively), resolving each row independently and walking the
tree in **both** directions:

```
index rows: 60
resolved paths: 60   distinct: 60
qml files on disk in gq: 60
index rows with NO file: []
files with NO index row: []
compared: 60   identical: 60   DIFFERENT: 0   absent-in-rfp: 0
rfp qml total: 66
rfp qml NOT vendored: forms/form_fiss_site.qml, forms/form_pscis.qml,
  raster/airphoto_gray.qml, raster/dem_hillshade.qml, raster/dem_turbo.qml,
  vector/osm.trail.qml
```

**Attacking the sweep for vacuity, as asked:**

- It cannot pass on a skipped row: `compared: 60` equals the row count, and the
  three counts (rows / resolved / on-disk) agree at 60 with 60 *distinct* paths,
  so no two rows collapsed onto one file.
- The kind mapping covers every value present (`vector`, `raster`, `service`) and
  `sys.exit(1)`s on anything else — an unrecognised `kind` aborts rather than
  silently skipping. A count check: 53 vector + 6 service + 1 raster = 60.
- The quoted CSV and the leading-space layer name are non-issues by construction:
  paths are built from `layer_key`, never from `layer`, and `csv.DictReader`
  parses the embedded commas correctly (verified — `Crossings - PSCIS,  modelled,
  dams` parses as one field).
- **Positive control** (the thing that makes "0 drifted" mean something): the
  pre-diff `HEAD` copies of the two changed files, compared by the same code
  against the same rfp paths, come back **DIFFERENT** for both. The comparison
  discriminates.

**Second independent reference.** The suite's own drift test
(`test-gq_style_qml.R`) resolves rfp through `system.file()` because
`RFP_STYLES_DIR` is **unset** in this environment — so it compares against
*installed* rfp 0.74.0, not the checkout my sweep used. I checked those two
references against each other: **66 QML files, zero name differences, zero byte
differences.** And `devtools::test(filter="gq_style_qml")` reports 0 failures.
Two references that could have disagreed, agreeing.

### 3. "A pure upstream pull, no gq-side content decision" — VERIFIED

Both files byte-identical to rfp's copies (`cmp`). Both changes trace to rfp
commits that are **ancestors of `origin/main`**:

- `18e0004d` Repoint the fish-observations layer, and drop the fields the new schema lost
- `e002b64f` Preview Floodplains on the column that carries a name (#201)

So the content is merged upstream work, not branch-local. (See the note below on
the checkout it was read from — measured, and benign.)

### 4. Every factual claim in the new comment — VERIFIED independently

| claim | how checked | verdict |
|---|---|---|
| "Three today — airphoto_gray, dem_hillshade, dem_turbo" | ran the script; the message names exactly those three | ✓ |
| skip rule is roster absence, not `rfp_raster_styles()` membership | read the code: `setdiff(glob(dir/*.qml), want$layer_key)`, `want` from the roster | ✓ |
| "`rfp_raster_styles()` serves four, and the fourth is `habitat_lateral`" | `rfp/inst/lookups/rfp_raster_styles.csv` — dem_turbo, dem_hillshade, habitat_lateral, airphoto_gray | ✓ |
| habitat_lateral "a template DOES use ... gq's one raster" | `inst/styles/index.csv` has exactly one `raster` row, `habitat_lateral` | ✓ |
| "All three skipped styles happen to back that roster" | all three present in that CSV | ✓ |
| **superlative**: dem_hillshade and dem_turbo "alone" open with `<map-layer-style-manager>` | `grep -rl` across **all 66** QMLs in rfp's store → exactly those two | ✓ |
| "airphoto_gray ... is an ordinary QML" | parsed: root `qgis`, first child `flags` (same shape as habitat_lateral) | ✓ |
| "repaired out of that form upstream (rfp#235 follow-up)" | rfp#235 is *"stretch is a silent no-op on singlebandgray"*, closed by `11ec65fc` (merge `86f11a32`, 2026-08-30); `4938318c` *"Harden the raster stretch writer, and fix airphoto_gray as a bare sidecar"* is a direct descendant, 2026-08-31 | ✓ |

Nothing over-stated. The superlative is the one that could have been wrong and
is not.

### 5. Pre-existing failures — VERIFIED pre-existing, and your control was incomplete (the conclusion still holds)

Reproduced with `NOT_CRAN=true` (per the convention that `test_file()` alone
reports a false SKIP): `test-template_drift.R` FAIL 1, `test-gq_registry_read.R`
WARN 1, `test-gq_style_qml.R` clean.

- **Can this diff reach either?** No. `test-template_drift.R:353` compares
  `inst/registry/template_groups.csv` against rfp's `.qgs` templates;
  `test-gq_registry_read.R:25` reads `tests/testthat/fixtures/mini_registry.json`.
  The diff touches two `inst/styles/*.qml` and one comment. No path.
- **The WARN** is benign and unrelated: `expect_error(gq_registry_read("nonexistent.json"))`
  emits `cannot open file 'nonexistent.json'` from `open.connection()` before the
  error. Nothing to do with styles.
- **Your control does not discriminate what you used it for.** A gq worktree at
  gq `origin/main` varies only the gq side; both runs read the *same* rfp. It
  establishes "the diff did not cause it" (true) but not "this is genuine gq-side
  staleness rather than an artifact of the rfp copy on this machine" — and that
  distinction was live, because rfp's checkout sits on an unmerged branch whose
  commits include *"The templates are build output"*, rewriting
  `inst/templates/*.qgs` by **96,610 and 101,569 lines**. Three different template
  states exist on this machine (installed 0.74.0, rfp `origin/main`, rfp branch
  HEAD), all with different md5s.

  I closed it directly: re-ran the drift test with `RFP_TEMPLATE_DIR` pointed at
  templates extracted from rfp `origin/main`. **It fails identically** (FAILED 1,
  PASS 30). So it is genuine gq-side staleness — the vendored table is missing the
  `Floodplain` and `Restoration` groups, exactly the gq#70 condition CLAUDE.md
  documents. Your conclusion holds; the reasoning needed the extra step.

---

## Verified, no action needed

Recording these so the next reader does not re-derive them.

- **The vendor ran from a dirty rfp checkout on an unmerged branch** — `rfp` is on
  `335-templates-become-build-output-flip-the-s`, 5 commits ahead of
  `origin/main`, with modified/staged files and an untracked `review-round4.md`
  (another session's in-flight work). `styles_vendor.R` has no clean/level guard,
  and the convention prescribes one (`git status --porcelain` empty,
  `rev-list --count HEAD..origin/main` zero). **Benign here, measured:** the two
  inputs the script reads — `inst/extdata/styles` and
  `data-raw/qgs/roster/template_layers.csv` — are byte-identical to `origin/main`
  (`git diff origin/main...HEAD` on those paths is empty) and clean in the working
  tree. Nothing unmerged reached the corpus. Worth knowing because the same
  checkout's `inst/templates` *is* rewritten on that branch, so a re-vendor of
  anything template-derived from it would ship unmerged work.
- **`<alias index=>` now has gaps** in `bcfishobs_fiss_fish_observations.qml`
  (0, 1, 3, 6, 8, …) because upstream dropped five fields without renumbering.
  Looks alarming in the diff; is not a defect. QGIS resolves aliases by name, not
  index (the rfp#186 finding in the conventions), and it is upstream's merged
  artifact, which gq is contractually required to copy byte-for-byte.
- **The new `previewExpression` `"species_name"` is not in that QML's own
  19-field `<fieldConfiguration>` list** — and the *old* one
  (`fish_obsrvtn_pnt_distinct_id`) was, so the file was self-consistent before and
  is not now. Checked before reporting it: rfp's commit message states it measured
  the repointed object at **34 fields**, and `species_name` appears in the same
  `<previewExpression>` in rfp's released `origin/main` templates. The style's
  field list enumerates configured widgets, not the schema. Deliberate upstream
  state, consistent with the template. Not gq's.
- **Drift-test independence** (you asked): not circular in the harmful sense —
  the reference (rfp's store) has a different producer than the subject (gq's
  committed copy), so it can genuinely detect rfp moving. Its weakness is that
  "green" means *gq == whichever rfp copy this machine has*. Here that is not a
  gap: installed 0.74.0's store and the checkout's store are byte-identical across
  all 66 files, so both available references agree.
- **CLAUDE.md / README counts are unaffected.** Recounted against the current
  corpus: 50 shared vector, 3 overrides (`fisheries_sensitive_watersheds`,
  `land_ownership`, `range_tenure`), 1 raster, 6 services, 60 total, 57 distinct
  keys. All match. The re-vendor changed content only, no counts moved.
- `planning/archive/2026-08-issue-39-qml-corpus/` also carries the old
  two-raster sentence. Left alone deliberately — an archive is a dated record of
  what was known then, and the convention says a time-qualified restatement is not
  re-pointed.
