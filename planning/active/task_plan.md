# Task: Re-vendor inst/styles/: rfp has repaired both drifted QMLs, floodplains fully and bcfishobs partially (#90)

`tests/testthat/test-gq_style_qml.R:201` ("the vendored corpus is byte-identical to
rfp's") has been **red on a developer machine** since at least 2026-09-14, and green
in CI, because it `skip_if_not`s without an rfp checkout — the same inversion as the
theme roster in #88.

Both drifts are **rfp repairs gq has not pulled**. The direction is upstream-fixed /
gq-stale, so the remedy is `Rscript data-raw/styles_vendor.R`, not an edit here.

## Measured this session (2026-09-20)

Full byte sweep over `inst/styles/index.csv` — **60 files checked, exactly 2 drifted**:

| file | drift |
|---|---|
| `vector/floodplains.qml` | 1 line: `previewExpression` `"feature_name"` → `"floodplain_name"` |
| `vector/bcfishobs_fiss_fish_observations.qml` | 62 lines: 5 dead fields removed across roster/alias/policy/default/constraint blocks, plus `previewExpression` `"fish_obsrvtn_pnt_distinct_id"` → `"species_name"` |

Index rosters already agree (53 vector rows each side, no set difference), so
`inst/styles/index.csv` is expected byte-unchanged. Asserted in Phase 2, not assumed.

## Phase 1: Re-vendor

- [x] Re-assert the rfp precondition: `git -C ~/Projects/repo/rfp status --porcelain -- inst/extdata/styles data-raw/qgs/roster` and `git diff --stat origin/main...HEAD -- inst/extdata/styles data-raw/qgs/roster` both empty
- [x] Run from the **package root** — `dest`, `groups.csv` and `load_all()` are all relative paths in the script
- [x] `RFP_STYLES_DIR=~/Projects/repo/rfp/inst/extdata/styles Rscript data-raw/styles_vendor.R`
- [x] Read the script's **full stdout**, not two named message classes. (Revised: the
      original bullet said "no new orphan/roster-gap messages" and `airphoto_gray`
      arrived via a *third* class — the raster-skip message — so that filter would have
      missed it. It is what surfaced the two defects below.)

## Phase 1b: Two defects the script's stdout surfaced (unplanned, in scope)

The skip message went from two names to three. Both the comment and the test that
record which rasters are excluded had gone stale, and neither could see it.

- [x] `data-raw/styles_vendor.R:188` — comment named 2 skipped rasters, run reports 3.
      Rewritten, and its stated *reason* corrected: the skip rule is absence from the
      template roster, **not** membership in `rfp_raster_styles()` — those are different
      sets, and the fourth member of that roster (`habitat_lateral`) **is** vendored
- [x] `tests/testthat/test-gq_style_qml.R` — the guard was a **negative literal set**
      (`expect_false(any(c("dem_hillshade","dem_turbo") %in% ...))`), so it went blind
      the moment upstream added a raster nobody had written down. Replaced with a
      **positive set pin** on the raster and service kinds, which cannot be outgrown
- [x] Proved the new guard fires: PASS as shipped; FAIL on an unanticipated raster, on
      `airphoto_gray` specifically, and on a dropped service; and the **old** guard PASSES
      on `airphoto_gray` — the blindness, demonstrated rather than asserted

## Phase 2: Verify the change is exactly the expected files

- [x] `git status --porcelain -- inst/styles/` names **only** the two QMLs — `index.csv` unchanged
- [x] `git diff HEAD --stat` (not bare `git diff` — the tree is staged, so that reads empty)
- [x] Byte sweep re-run: 60 checked, **0 drifted**
- [x] Vendor script re-run a second time: still exactly 2 changed paths — idempotent
- [x] Filtered run for the drift guard, with `RFP_STYLES_DIR` set: `FAIL 0 | SKIP 0 | PASS 103`.
      **`SKIP 0` is the observable** — unset or mistyped, the env var falls through to an
      installed rfp with no store, the guard skips, and the run still prints `FAIL 0`.
      That vacuous pass is the very inversion this issue is about
- [x] Full `devtools::test()` for "nothing else moves" — a filtered run structurally cannot
      show that. `FAIL 1 | WARN 1 | SKIP 0 | PASS 1117`, both pre-existing (below)
- [x] Use `devtools::test()`, never `testthat::test_file()`: the guard reads gq's copy via
      `system.file()`, which without `load_all()` resolves to the **installed** gq (0.14.0,
      still carrying the pre-repair bytes) and would report the drift as unfixed
- [x] `/code-check` — see "Review rounds" below

## Phase 1c: A defect inside my own fix (review round 2)

Round 2 found a **[bug] in the comment this branch rewrote**, on the one axis the
enumeration had not swept — and half of it was a sentence the fix itself added.

- [x] `data-raw/styles_vendor.R` — the comment explained the `<map-layer-style-manager>`
      split as "QGIS-authored sidecars … **which is why**". False: all nine QGIS-authored
      reference nodes in `rfp/inst/testdata/nodes/` open with `<flags>`, `raster_hillshade.qml`
      included, so authorship does not discriminate. I preserved that clause while
      correcting the member list around it
- [x] …and added "`airphoto_gray` was repaired out of that form upstream (rfp#235
      follow-up)". Also false — `<flags>` at `11ec65fc` (creation), `4938318c~1`,
      `4938318c` and HEAD. rfp's "bare sidecar" names a *deployment mode*, not a document
      form, and I inverted its meaning carrying it across from a commit title
- [x] Both removed. The comment now states the **observation with its measurement date**
      and says explicitly that the cause is withheld
- [x] Re-ran the enumeration across **all six** axes the convention names, not the three
      that are greppable for digits. Table in findings.md

### Pre-existing, not touched by this branch

Verified in a throwaway worktree detached at `origin/main` — identical results there:

| | baseline | this branch |
|---|---|---|
| `test-gq_style_qml` drift guard | FAIL 1 — "Drifted: bcfishobs…, floodplains" | **FAIL 0** |
| `test-template_drift.R:353` | FAIL 1 | FAIL 1 — gq#70, open |
| `test-gq_registry_read.R:25` | WARN 1 | WARN 1 |

`template_drift` keys off `RFP_TEMPLATE_DIR`, a *different* variable from the one this
issue uses, and reads only `template_groups.csv` and rfp's `.qgs` templates — nothing
this diff touches.

## Phase 3: Re-scope #86 (its premise has expired)

- [x] Edit #86's body: correct the expired "guard is green" premise, narrow to the residue
- [x] Retitle #86
- [x] **Read rfp#307 before asserting anything about the residue.** This changed the
      conclusion — see findings.md. A first draft of the #86 edit claimed the repaired
      `previewExpression` was "still dangling"; rfp#307 had already measured
      `bcfishobs.observations` at 34 columns with `species_name` among them, so the
      expression resolves and it is **tier-1's naive rule that is wrong**, not the file
- [ ] Comment on #86 pointing at this PR

## Review rounds

One Plan review plus four `/code-check` rounds. Past the usual bound, because rounds 2, 3
and 4 each found a defect **inside the previous round's fix** — the skill's explicit
trigger to continue.

| round | findings | fixed | accepted | inside previous fix? |
|---|---|---|---|---|
| Plan | 9 | 7 | 2 (0.16.0 bump; index warrant) | — |
| 1 | 2 | 2 | 0 | n (one was already fixed independently) |
| 2 | 3 | 3 | 0 | **y** — a false cause preserved, plus a false history the fix added |
| 3 | 2 | 2 | 0 | **y** — the repair for round 2 was itself false |
| 4 | 1 | 1 | 0 | **y** — the repair for round 3 was itself false |

**How it ended: by removing the surface, not by a quiet round.** All three of rounds 2–4
found the same paragraph asserting a wrong *cause*, in three different shapes — polarity
backwards, then a sample with no variation in the variable under test, then a sufficient
condition stated as the cause. A fifth attempt was the wrong move. Nothing in the script
reads the element order and the skip rule is the roster, so the comment now points at
rfp's one-sentence explanation instead of carrying a fourth copy of it.

The mechanism — every sweep measured rfp's *data*, never rfp's *prose* — is filed as #92
for the sibling `data-raw/` scripts.

## Phase 4: Release bookkeeping

- [x] `NEWS.md` entry under `# gq 0.16.0` — **minor, not patch**. The directly analogous
      precedent is #88, an rfp re-extract into `inst/registry/themes.csv` that took
      0.15.0; this likewise changes bytes `gq_style_qml()` hands to consumers
- [x] Did **not** carry #90's "4 removed" into NEWS — the issue body says 4 and lists 5.
      The roster went 24 → 19, so it is **5**
- [x] Every NEWS figure re-derived from the artifact, twice: by me, and independently by
      rounds 2 and 3
- [ ] Bump `DESCRIPTION` to `0.16.0` as the **final** commit of the branch

## Out of scope

- **Any CI guard for the skip inversion** — that is #78, where the automation design
  (GitHub Action, and in which repo) is written up.
- **rfp#335** — the corpus is vendored from rfp's *store*, not a `.qgs`;
  `styles_vendor.R` never reads a template.

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
