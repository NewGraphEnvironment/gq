# Plan review — #77 (Plan agent, 2026-08-30)

Spawned concurrently with implementation; returned after Phase 3 was in the
working tree. Reviewed the plan *and* the landed code.

## Independently confirmed by the reviewer

232 rows, 9 pairs; `High Detail - Crossings` 28 rows / 27 visible in both;
all four shared themes identical on `layer_key,visible`; zero duplicate
`template,theme,layer_key` rows; `esri_world_topo` present and `false` in all 9
pairs. Visible per pair: 27, 21, 21, 21 (fishpass); 27, 22, 21, 21, 21
(restoration).

Also confirmed the `merge()` hazard the plan designed out was real: `merge()`
defaults to `all = FALSE`, so a one-sided key is dropped from the comparison —
and because testthat continues past a failure, the next assertion would have
printed a reassuring "no disagreement" in the same output. Two problems reported
as one failure plus one pass.

## Disposition

| # | Finding | Disposition |
|---|---|---|
| B1 | No NEWS entry, no version bump. This changes the meaning of a shipped `inst/` artifact and rewrites two exported functions' rationale. `/gh-pr-merge`'s release gate has been observed to misread exactly this diff shape (CLAUDE.md:622-624). | **Fixed** — 0.13.0 + NEWS |
| G1 | `expect_gt(length(shared), 0L)` passes having compared one theme if rfp drops three. `test-template_drift.R:104` pins the *set*. | **Fixed** — pinned to the four names |
| G2 | Nothing pins 232/9; the stub test passes on a zero-row roster (`tapply` over an empty frame → `length(stubs) == 0`). "An empty result set is not a pass" is in code-check.md. | **Fixed** — shape + duplicate pin |
| G3 | `esri_world_topo` — the one row the issue says must not flip — is unguarded. | **Fixed** |
| G6 | `expect_setequal` takes no `info`, so a key-set divergence fails without naming the theme. | **Fixed** |
| A2 | The stub guard fires only at `sum(visible) == 0`. A regression flipping 24 of 25 off in `Land Tenure` passes both guards. The comment reads as broader coverage than it has. | **Fixed** — comment says it is a tripwire for one shape |
| A3 | `Land Tenure` is the only theme with no content assertion (26 rows / 22 visible). | **Fixed** — pinned |
| S1 | The drift guard is hard equality against an independently-moving private upstream. When rfp legitimately diverges, gq goes red for a decision that is not gq's — and the path of least resistance is deleting the test, which is how the last guard here rotted. | **Fixed** — comment states a legitimate divergence edits the test |
| O1 | Phase 4 ran rfp's harness *after* merge — the only end-to-end check, past the point of no return. | **Fixed** — moved before push |
| S3 | No `devtools::check()`, though per B1 this is a release. | **Fixed** |
| A4 | Phase 1 checked flip counts but not key sets — a regeneration changing a `layer_key` *and* a flag is also 27/27. | **Fixed** in plan text (was done in execution) |
| Ac1 | "~1054 pass" cannot discriminate; the split changed the assertion count. | **Fixed** — uses `FAIL 0 | PASS 66` |
| Ac2 | Leaving `NEWS.md:339-341` unedited is right, but leaving it *unanswered* is not — the changelog carries an uncorrected claim with nothing linking it to the correction. | **Fixed** — new entry corrects by reference |
| Ac3 | Phase 3 line references stale post-edit. | **Fixed** |
| **G4** | **`extract_themes()` lives in `data-raw/` and is reachable only by the generator, so `themes.csv` has no analogue of `test-template_drift.R:326-354` — the test that asserts the vendored table equals what the templates say *now*. That is the actual property; the stub guard is a proxy for one shape of its violation. Moving it to `R/` beside `qgs_group_table()` would give gq its own signal instead of relying on rfp's private harness.** | **Deferred — filed as a follow-up issue** |
| G5 | Commit a perturbed fixture so the guards' failure is reproducible in-repo, mirroring `test-template_drift.R:264-300`. | **Deferred** — same issue as G4 |

### Why G4/G5 are deferred rather than done

They are correct and they are the most valuable findings here. They are also a
different piece of work: moving a generator function into the package surface,
plus a fixture and an `RFP_TEMPLATE_DIR`-gated test. #77 is a data correction
with a two-step fix in its body. Bundling an architecture change into it would
make the PR hard to review and would put the roster fix behind work that needs
its own design pass.

Filed as a follow-up rather than dropped — the deferral is the decision the
reviewer asked for, made explicitly.
