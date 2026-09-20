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

- [ ] Re-assert the rfp precondition: `git -C ~/Projects/repo/rfp status --porcelain -- inst/extdata/styles data-raw/qgs/roster` and `git diff --stat origin/main...HEAD -- inst/extdata/styles data-raw/qgs/roster` both empty
- [ ] `RFP_STYLES_DIR=~/Projects/repo/rfp/inst/extdata/styles Rscript data-raw/styles_vendor.R`
- [ ] Read the script's own output: `styles vendored: 60 files`, no new orphan/roster-gap messages

## Phase 2: Verify the change is exactly the two files

- [ ] `git status --porcelain -- inst/styles/` names **only** the two QMLs — `index.csv` unchanged
- [ ] `git diff --stat` shows 1 line on `floodplains.qml`, 62 on `bcfishobs_…`
- [ ] Byte sweep re-run: 60 checked, **0 drifted**
- [ ] `devtools::test()` — drift test green and **run, not skipped**; nothing else moves
- [ ] `/code-check` on the staged diff

## Phase 3: Re-scope #86 (its premise has expired)

- [ ] Edit #86's body: correct the expired "guard is green" premise, narrow to the residue
- [ ] Retitle #86 to drop "and the byte-identity guard is green"
- [ ] Comment on #86 pointing at this PR

## Phase 4: Release bookkeeping

- [ ] `NEWS.md` entry under `# gq 0.15.1`
- [ ] Bump `DESCRIPTION` to `0.15.1` as the **final** commit of the branch

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
