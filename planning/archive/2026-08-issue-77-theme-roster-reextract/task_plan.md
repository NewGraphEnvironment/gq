# Task: Re-extract the theme roster: High Detail - Crossings shows nothing in bcrestoration_mobile (#77)

`inst/registry/themes.csv` records the `High Detail - Crossings` theme as showing
**nothing** in `bcrestoration_mobile` — all 28 layer rows `visible = false`.

That is faithful to what the template said, and the template was wrong. rfp
shipped that preset as a stub: 28 layers enumerated, none visible, and no group
checked. Repaired in NewGraphEnvironment/rfp#217, released in rfp **v0.47.0**.
gq's roster is extracted from those templates, so it is now the last place
holding the old answer.

It is the most used theme in the fleet, so it is worth being right.

rfp's `test-qgs_build_harness.R` cross-checks gq's roster against rfp's registry
and is red until this lands. It skips when gq is not checked out, so CI cannot
see it — this is the only signal.

## Verified before planning (not taken from the issue body)

Parsed `~/Projects/repo/rfp/inst/templates/*.qgs` directly at **v0.47.0**
(clean, on `main`, level with `origin/main`):

| check | result |
|---|---|
| total rows / template-theme pairs | **232 / 9** — unchanged |
| `High Detail - Crossings` | 28 layers, **27 visible** in *both* templates |
| the one `false` row | `ESRI_World_Topo` in both (rfp#162, present-and-off) |
| all 4 shared themes | identical `layer_key` sets, **zero** visible-flag differences |
| stub themes remaining | **none** |
| `Land Tenure` | restoration-only, 26 layers / 22 visible |

The issue's claims hold. Two things it does **not** mention were found in
exploration and are folded into Phases 2 and 3.

## Phase 1: Re-extract the roster

- [x] Run against the v0.47.0 checkout (env var is `RFP_TEMPLATE_DIR`, pointing at
      `inst/templates` — `data-raw/reg_extract_themes.R:37`)
- [x] Confirm the run message reads `themes.csv built: 232 rows, 9 template-theme pairs`
- [x] Confirm `git diff --stat` shows **27 insertions / 27 deletions**, in
      `inst/registry/themes.csv` **only** — `reg_main.json` and `groups.csv` untouched
- [x] Confirm `esri_world_topo` is still `false` in the changed block, and that the
      27 flips are all `false` → `true`
- [x] Confirm the `layer_key` sets are identical either side of the flip. A
      regeneration that changed a key *and* a flag is also 27 insertions /
      27 deletions, so the counts alone do not establish it
- [x] Record the rfp version + sha in the commit message (the script prints it)

## Phase 2: Rewrite the theme tests

`tests/testthat/test-gq_groups.R:141-150` pins the zero as a *design*
(`expect_equal(visible_by_template[["bcrestoration_mobile"]], 0)`). It was
describing a bug. It is the **only** hard failure in the suite.

Replaced by **two** separately-named tests, so a future failure names its own
cause instead of one test meaning two things:

- [x] `"a theme shipping in both templates agrees layer for layer"` — for each
      of the 4 shared themes, `expect_setequal` on `layer_key` and zero
      visible-flag differences. This is the drift guard.
- [x] `"no theme is a stub"` — over **all 9** template-theme pairs, not just the
      shared ones. The issue's version puts this inside the shared-themes loop, so
      `Land Tenure` (restoration-only) is never checked — which is *exactly* the
      shape rfp#217 had. Widening it is the point of splitting.
- [x] Keep the existing `"Land Tenure is restoration-only"` test (lines 134-139)
      untouched — it becomes the surviving witness for why `template` is in the key
- [x] **Restore the bug and confirm the new stub test goes red.** Done three ways:
      current roster `FAIL 0 | PASS 66`; pre-fix roster from `HEAD~1` fires **both**
      guards naming all 27 keys; `Land Tenure` stubbed alone fires **only** the stub
      guard — the case the issue's shared-only loop could not reach.
- [x] Compare by named lookup, not `merge()` — `merge()` drops a key present on
      one side only, which is the drift the guard exists to report.

## Phase 3: Correct the stale prose

Four locations state the old fact. `man/*.Rd` are roxygen-generated — the fix
belongs in `R/gq_groups.R` followed by `devtools::document()`.

- [x] `R/gq_groups.R:284-285` (`gq_theme_layers` roxygen) — "materially different
      content" replaced; the caveat now points at the concatenation behaviour
      itself (56 rows rather than 28), which is what the argument is about.
- [x] `R/gq_groups.R:291-294` (`@examples`) — `tapply(...)` printing `27 / 0`
      replaced by `table(xing$template, xing$visible)`, which shows the
      concatenation the docs describe. Verified it runs: 56 rows, 27/1 either side.
- [x] `R/gq_groups.R:243-247` (`gq_themes` roxygen) — rationale repointed at
      `Land Tenure` plus independent template drift.
- [x] `devtools::document()` — wrote exactly `gq_themes.Rd` and
      `gq_theme_layers.Rd`, nothing else. NAMESPACE unchanged, 30 exports.
- [x] `CLAUDE.md:191` — parenthetical replaced, plus a note recording that the
      zero was a stub mistaken for a design (the transferable lesson)
- [x] `README.md:93` — restated against the surviving evidence
- [x] **Not touched:** `NEWS.md:340-341` (dated 0.3.0 entry — historical record) and
      `planning/archive/2026-08-issue-46-themes-roster/`. Confirmed unaffected:
      `CLAUDE.md:271` and `NEWS.md:336` both cite 232/9, which still hold.

## Phase 4: Verify and land

- [x] `devtools::test()` — acceptance is `test-gq_groups.R` at `FAIL 0 | PASS 73`
      (12 tests → 15), not a whole-suite count: the split changed the assertion
      count, so "~1054" from the issue cannot discriminate
- [x] `lintr::lint_package()` — diff against the `HEAD` baseline, not against zero
- [x] Plan-agent review — 1 blocker, 7 gaps; dispositions in `review-plan.md`.
      Acted on all but G4/G5, deferred deliberately and filed as gq#78
- [x] Test hardening from the review: pin the `shared` set, pin roster shape
      (232/9, no duplicate key, `Land Tenure` 26/22), guard opaque basemaps,
      `tapply` over a list rather than a pasted key. Each proven to fail.
- [x] NEWS entry + `DESCRIPTION` 0.12.0 → 0.13.0. This changes the meaning of a
      shipped `inst/` artifact, and `/gh-pr-merge`'s release gate has been
      observed to misread exactly this diff shape (CLAUDE.md:622-624)
- [ ] `devtools::check()` — this PR is the 0.13.0 release
- [ ] Run rfp's `test-qgs_build_harness.R` **before** pushing, not after merge
- [ ] `/code-check` on the branch diff
- [ ] `/planning-archive`, then `/gh-pr-push`
- [ ] PR body: `Relates to NewGraphEnvironment/rfp#217` **and** the sred ref from
      machine-local memory (`sred-experiment-refs`)
- [ ] After merge, confirm the pkgdown deploy landed on this HEAD (a green run is
      not a current site — CLAUDE.md:531)

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Note for next time

Both registries recorded the stub faithfully, because both derive from the same
templates. A failed cross-check does **not** mean gq is the stale side by
default — check which one moved.
