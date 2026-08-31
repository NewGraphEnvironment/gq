# #76 — `.claude` and `gq.Rproj` shipped in the package tarball

**Closed** by PR on branch `76-claude-and-gq-rproj-ship-in-the-packag`, 13 commits.

`R CMD build` ships every top-level entry nothing excludes, so `.claude/` and
`gq.Rproj` were landing in the tarball and therefore in the library of anyone
installing gq from GitHub; `R CMD check --as-cran` reported each as a NOTE. The
fix is three `.Rbuildignore` lines. Measured like-for-like on the built tarball,
`Status: 2 WARNINGs, 2 NOTEs` → `Status: 2 WARNINGs`, with the two out-of-scope
warnings (already filed as #51) persisting on both sides as the positive
control. Tarball listing unchanged at 226 paths — none lost, none gained.

The substantive work is `tests/testthat/test-build_hygiene.R`, a guard that
fails the suite when a top-level entry is neither shipped on purpose nor
excluded on purpose. It converts what had been a non-blocking NOTE into a
blocking test failure, without renegotiating the workflow's deliberate
`error-on: '"error"'` policy (see #51).

## What the guard found that nobody was looking for

`R CMD build` **ships the `.git` file when you build from a git worktree.** R
gates its version-control exclusion on `isdir`, and a worktree's `.git` is a
file containing `gitdir: /absolute/path/to/the/developer/machine`. Measured
present in a tarball, and fixed with `^\.git$`.

This matters beyond gq: `CLAUDE.md` prescribes one worktree per session, so any
NGE R package built that way has been shipping it. It stayed hidden because the
guard that would have caught it tested `dir.exists(".git")`, which is false in a
worktree — so in the layout the conventions prescribe, the guard silently
skipped. A guard that cannot run is not a weaker guard; it is an absent one.

## Review — four rounds plus a plan review, 13 defects

The dominant class was a defect sitting **inside the previous round's fix** (the
gq#52 shape), four times over:

| round | the defect inside the previous fix |
|---|---|
| 2 | round 1's silent-direction assertion landed in *source* mode, which `R CMD check` can never select — it sat in the branch CI does not run |
| 3 | round 2's path sweep used `list.files(recursive = TRUE)`, which returns files only, so `^inst/registry$` deleted the registry with the guard green |
| 4 | round 3's `any(dir.exists(...))` premise was satisfied by the top-level entries alone, so it could not detect the regression it was added for |
| 5 | round 4's worktree fix was itself unguarded — removing `^\.git$` is invisible in a `.git`-*directory* checkout, which is what CI uses |

Three "this is now terminal" claims were wrong before one held. What ended it
was not a reviewer saying so, but **enumeration**: the sweep's path set proved
*equal* to R's own over the shipped subtrees, and `.Rbuildignore` shown by a
namespace-wide walk of `tools` to have exactly two consumers, the second a
strict subset of the first. There is no level above that source.

Three of the reviewers' highest-rated findings were already handled in code —
they were reviewing plan text, not the implementation — which is why each was
probed before being accepted or dismissed.

## Also landed

- `.gitignore` excluded `.venv`, `__pycache__`, `dist`, `.vscode`, `.idea`,
  `*.egg-info`, `Thumbs.db`; `.Rbuildignore` excluded none and R auto-excludes
  none, so any machine holding one shipped it. Adopted `.gitignore`'s side,
  since it had decided these and `.Rbuildignore` had never been asked.
- `.Rbuildignore` has **no comment syntax** — every non-empty line is a live
  regex. Five explanatory lines added mid-branch were live patterns; measured
  benign and removed, with an assertion that every line is anchored.

## Follow-ups

- **#80** — `test-vignette_legend_coverage.R` resolves `00_pkg_src` one level too
  shallow under `R CMD check`. Harmless today (a `system.file()` fallback catches
  it), but the dead branch reads as live coverage.
- **#51** — the two pre-existing WARNINGs, deliberately out of scope here.

No `NEWS.md` entry: this changes what the tarball contains, with no user-visible
API change.
