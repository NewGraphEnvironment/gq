# Plan review — #76

Plan subagent, spawned concurrently with Phase 1 per `planning.md`. It reviewed
`task_plan.md`, not the implementation, so several findings describe plan text
that the code had already diverged from. Every finding below was probed before
being accepted or rejected.

## Accepted and fixed

| # | Finding | Probe | Fix |
|---|---|---|---|
| B2/B3 | `auto_excluded` omits R's own tarball-name rule, so `R CMD build .` in-tree reddens the suite naming `gq_0.13.0.tar.gz` — for a file R excludes anyway. The issue's own verification step tells you to run that command. | `grepl("^gq_[0-9.-]+\\.(tar\\.gz\|...)$", "gq_0.13.0.tar.gz")` → TRUE, and nothing else in `r_auto_excluded()` matched it | Added the rule, with `pkgname` a parameter. New test asserts it covers `.tar.gz`/`.tgz`/`gq.Rcheck`/`gqOld`, does **not** cover `.claude`, and does not excuse *another* package's tarball |
| A3 | `.gitignore` excludes `.venv/`, `__pycache__/`, `dist/`, `.vscode/`, `.idea/`, `*.egg-info/`, `Thumbs.db`; `.Rbuildignore` excludes none of them and R auto-excludes none of them. On any machine where one exists, it ships. | Confirmed all seven unmatched by `get_exclude_patterns()` and absent from `.hidden_file_exclusions` | Added to `.Rbuildignore`. `build` deliberately **not** added — R CMD build creates `build/` itself for vignette metadata. Rebuild diff: 226 entries, none lost, none gained |
| G5 | Nothing asserts `.claude/visibility` stays tracked. Gitignoring it is the tempting wrong fix and would silently flip the repo to "internal" for `claude-md-init`. Prose is not a guard. | — | New test asserting `git ls-files .claude` contains it, with `shQuote()` on the path per `CLAUDE.md` |
| G2 | Guard is top-level only; `inst/.claude` would ship unnoticed. Residual must be *stated*, not left unlikely. | — | Stated in the file, with the reason it is covered: R's own hidden-files check is recursive |

## Accepted as correct, no change needed

- **B6 / AC1** — the before/after must use `--as-cran`. Already done in execution;
  the plan text was silent. Also adopted the reviewer's better form: assert the
  **absence of the two specific NOTE texts** rather than a count, since
  `--as-cran` adds a CRAN-incoming NOTE of its own that flaps with the network.
- **AC2** — "compare test count against main" is unfalsifiable when the branch
  adds tests. Restated as a delta.

## Rejected — already handled in the implementation

- **B1 (rated the top blocker): "an empty `.Rbuildignore` line matches
  everything."** Real hazard, correctly identified in R's own code — and already
  guarded: `rbuildignore_excluded()` filters `patterns[nzchar(patterns)]`, with a
  test (`expect_false(rbuildignore_excluded("R", c("", "^nope$")))`). The
  reviewer was reading the plan, which did not mention it.
- **B4 depth, for this file.** `../00_pkg_src/gq` is indeed wrong — but
  `build_root()` builds candidates from `c("..", "../..", "../../..")`, so it
  generates the correct `../../00_pkg_src/gq`. Verified against a real
  `gq.Rcheck`: `../00_pkg_src/gq` missing, `../../00_pkg_src/gq` EXISTS.
- **G2 `.`/`..`** — already handled by `no.. = TRUE` plus an explicit `setdiff`.
- **A4 `grep -c` exits 1 on zero** — real rule, but the command as run wraps it
  in `echo "count: $(...)"`, so nothing chains off the exit status.

## Rejected — but produced a real finding elsewhere

- **B4, applied to the precedent file.** `test-vignette_legend_coverage.R:28`
  uses `../00_pkg_src/gq/vignettes`, which is the off-by-one that does *not*
  exist. It has never mattered because the `system.file("doc", ...)` fallback
  catches it — so under `R CMD check` that guard reads the **installed** copy,
  not the source. Harmless today, dead code that reads as live coverage. Filed
  as a follow-up rather than fixed here: out of scope for #76 and it deserves its
  own restore-the-bug check.

## Considered and declined, with reasons

- **S1: drop the testthat guard, add `_R_CHECK_TOPLEVEL_FILES_: true` to CI plus
  a log-grep step.** The argument is that R's own check is recursive, maintained
  by R core, and evaluated against the artifact — strictly stronger. True, with
  one decisive exception the reviewer noted itself: `.github/workflows/R-CMD-check.yaml`
  sets `error-on: '"error"'`, so that NOTE has printed on **every CI run since CI
  landed and blocked nothing**. A test failure is an ERROR in `checking tests`,
  so the testthat guard is what converts the top-level case into an actual gate
  *within the existing policy*, rather than requiring that policy be renegotiated
  (which the workflow comment explains at length is deliberate, pending #51).
  The two are complementary and the file now says so. Not adopting the CI change
  here: it is a third change to a workflow whose gating policy has its own issue.
- **G1: pin `ships` against R's `known` top-level list.** The right instinct —
  it is the "terminate by enumeration" remedy. Declined because `known` is a
  literal inside the body of `tools:::.check_packages`, not an exported object,
  so pinning to it means deparsing a function body and regex-extracting a vector:
  a more fragile coupling than the eleven-name list it would protect. The list is
  instead bounded from the other end — tarball mode asserts the built artifact
  contains nothing outside `ships` + `generated`, so an over-broad `ships` shows
  up as an entry in the tarball.

## Not adopted

- **O1: build a tarball from the Phase-1 commit to see tarball mode go red.**
  Correct that mode 2 has never been observed firing on a true positive. The
  synthetic test covers the classification logic, and mode 2's assertion is three
  `expect_equal`s against `setdiff`, but the reviewer is right that mode
  *selection* is unexercised. Recorded as a known gap rather than closed.
