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

- [ ] `R/gq_groups.R:284-285` (`gq_theme_layers` roxygen) — "`High Detail -
      Crossings` is the live example: it ships in both templates with **materially
      different content**" is now flatly false. Repoint the concatenation caveat at
      the behaviour itself rather than a per-template-content example.
- [ ] `R/gq_groups.R:291-294` (`@examples`) — the comment `# the same theme differs
      by template` becomes wrong, and the printed output changes `27 / 0` → `27 / 27`.
- [ ] `R/gq_groups.R:243-247` (`gq_themes` roxygen) — "can therefore carry different
      content" survives as a *capability* claim, but its rationale needs the
      `Land Tenure` witness now that no shared theme differs.
- [ ] `devtools::document()` → regenerates `man/gq_themes.Rd`, `man/gq_theme_layers.Rd`.
      **Read what it prints** — an unexpected `Writing`/`Deleting` line is the tell
      for a rebound `@export`.
- [ ] `CLAUDE.md:191` — replace the now-false parenthetical with `Land Tenure`
- [ ] `README.md:93` — restate against the surviving evidence
- [ ] **Not touched:** `NEWS.md:340-341` (dated 0.3.0 entry — historical record) and
      `planning/archive/2026-08-issue-46-themes-roster/`. Confirmed unaffected:
      `CLAUDE.md:271` and `NEWS.md:336` both cite 232/9, which still hold.

## Phase 4: Verify and land

- [ ] `devtools::test()` — expect ~1054 pass, 0 fail
- [ ] `lintr::lint_package()` — diff against the `HEAD` baseline, not against zero
- [ ] `/code-check` on the staged diff
- [ ] `/planning-archive`, then `/gh-pr-push`
- [ ] PR body: `Relates to NewGraphEnvironment/rfp#217` **and** the sred ref from
      machine-local memory (`sred-experiment-refs`)
- [ ] After merge, re-run rfp's `test-qgs_build_harness.R` with gq checked out —
      that red cross-check is the only signal this fixed anything

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion

## Note for next time

Both registries recorded the stub faithfully, because both derive from the same
templates. A failed cross-check does **not** mean gq is the stale side by
default — check which one moved.
