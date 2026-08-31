# Review round 4 — the five fixes in `ff8b89c` (gq#76)

**The tree moved during this review.** I started on `ff8b89c` and `e3d55b3`
("Make the sweep premise able to fail") landed mid-measurement. Everything below
is measured against **`e3d55b3`**, the current HEAD, and I say explicitly where
that changed a finding.

Environment: R 4.5.2. `test_file("tests/testthat/test-build_hygiene.R")` at
`e3d55b3` → `FAIL 0 | PASS 38`. `lintr::lint()` → no lints.

**Verdict: CONVERGED on the defect class.** No silent-direction hole remains.
Two `fragile` items, both fail-loud or fail-to-skip, neither able to let a
broken tarball through green.

---

## Findings

### 1. **[fragile]** `test-build_hygiene.R:432` — the `.claude/visibility` guard silently skips inside a **git worktree**, which is the checkout layout this repo's own conventions prescribe.

```r
skip_if(!dir.exists(file.path(root$path, ".git")), "not a git checkout")
```

In a worktree created by `git worktree add`, `.git` is a **file** (`gitdir: …`),
not a directory. `dir.exists()` is FALSE, so the test skips — while git works
perfectly there and returns the right answer. Measured, against a real worktree
of this repo:

```
worktree .git is a FILE : TRUE
dir.exists(.git)        : FALSE   -> test SKIPS
git actually works there: status = NULL   out = .claude/visibility
```

This line predates `ff8b89c`, and rounds 2 and 3 both read past it. I am filing
it because it sits **inside fix 5's skip chain** — the commit reasoned carefully
about skip-versus-assert two lines below it and left the other skip in the same
`test_that` untouched, and because CLAUDE.md mandates *"one worktree per
session — `git worktree add ../<repo>-<task> -b <branch>`"*. Under the repo's own
prescribed workflow this guard never runs, which is the fail-toward-skip shape
the same document names.

The guard is not redundant, so deleting the check is not the fix: `R CMD build`
excludes `.Rbuildignore`, so a built tarball resolves to `tarball` mode and skips
at line 431 anyway — the `.git` check exists for a source checkout obtained
without git (a GitHub zip download), where `git ls-files` would exit 128 and
`expect_null()` would fail for the wrong reason.

**Fix is one function:**

```r
skip_if(!file.exists(file.path(root$path, ".git")), "not a git checkout")
```

`file.exists()` is TRUE for both a directory and a worktree's gitdir file.
Verified against both known answers: TRUE in the worktree, TRUE in the primary
checkout, FALSE in a `git archive` extraction.

---

### 2. **[fragile]** `test-build_hygiene.R:375-376` — `include.dirs = TRUE` raises no false alarm on any of the 24 current patterns, but it makes a **deliberate** nested exclusion red the suite, and the file offers no route to declare one.

This is the residual of the brief's question A, and it is the only way that
question has a "yes" in it. For the patterns that exist today the answer is a
clean no — see Verified clean below.

A nested exclusion is a normal `.Rbuildignore` use: "we ship `inst/`, but not
`inst/examples/`". Before `ff8b89c` such a line was invisible to the sweep;
now it is a hit. Measured, adding one line at a time to the real file:

```
adding ^inst/examples$        -> sweep hit: inst/examples        (guard RED)
adding ^man/figures$          -> sweep hit: man/figures          (guard RED)
adding ^inst/styles/raster$   -> sweep hit: inst/styles/raster   (guard RED)
```

`ships` is a **top-level** allowlist, so there is no way to say "gq ships `inst/`
except `inst/examples`". The only way to make the suite green is to weaken the
sweep — which is how a guard stops being a guard. The direction is safe (red,
not green) and nothing in gq needs such a line today, which is why this is
`fragile` and last rather than a bug.

**Cheapest closure is to state the residual** where the scope is already stated
(the block at 101-108 does exactly this for the top-level-only scope), or to add
a named, reasoned exemption vector — empty today, with a comment saying that
`character(0)` is the healthy state, per CLAUDE.md's exemption-list rule.

---

## Converged on independently — already fixed at `e3d55b3`

**Fix 3's `dir.exists` premise was vacuous, exactly as the brief suspected.** I
measured it before seeing `e3d55b3`, and record the measurement because it
confirms the fix is aimed at a real defect rather than a suspected one:

```r
expect_true(any(dir.exists(file.path(root$path, paths))))     # ff8b89c
```

`paths` gains each top-level `ships` entry through `c(d, file.path(d, rel))`, and
six of the eleven are directories, so the premise is satisfied by `R`, `data`,
`inst`, `man`, `tests`, `vignettes` alone — whatever `include.dirs` is set to:

```
include.dirs=FALSE  n=206   any(dir.exists()) = TRUE   <- files-only sweep, premise PASSES
include.dirs=TRUE   n=219   any(dir.exists()) = TRUE
dirs visible to a files-only sweep (6): R, data, inst, man, tests, vignettes
```

It could not detect the regression it was added to detect. **The replacement at
`e3d55b3` can**, verified against both known answers:

```
include.dirs=FALSE  nested_dirs = 0    -> premise FIRES
include.dirs=TRUE   nested_dirs = 13   -> premise PASSES
```

And the restore-the-bug run confirms which assertions do the work. Reverting
**only** the `include.dirs` argument in a `git archive HEAD` extraction (diff
verified to be that one argument, working tree never touched):

```
--- FAIL  Expected `length(nested_dirs)` > 0.  Actual: 0 <= 0
--- FAIL  Expected `"inst/registry" %in% paths` to be TRUE
--- FAIL  Expected paths[rbuildignore_excluded(paths, "^inst/registry$")] to equal "inst/registry"
```

Three assertions fire. Note that at `ff8b89c` only **two** would have — fix 4
alone was carrying the regression, and fix 3 was decoration beside it. So the
`e3d55b3` change is not cosmetic.

---

## Verified clean

Recorded so a round 5 does not re-open them.

- **Fix 1 raises no false alarm on the 24 current patterns.** Per-pattern hit
  counts across all 219 sweep paths: **0 for every one of the 24**. All 13
  newly-visible nested directories (`inst/examples`, `inst/logo`,
  `inst/registry`, `inst/styles{,/raster,/services,/vector,/vector/overrides,
  /vector/overrides/bcfishpass_mobile}`, `man/figures`, `tests/testthat{,/_snaps,
  /fixtures}`) are matched by nothing. Every line is anchored `^…$` and only
  `^[^/]+\.egg-info$` contains a character class, which explicitly excludes `/`.
- **The sweep's path set now equals R's own.** Built R's set directly —
  `dir(".", all.files = TRUE, recursive = TRUE, full.names = TRUE,
  include.dirs = TRUE)` from the package root, `substring(…, 3L)`, restricted to
  the shipped subtrees — and diffed it against the sweep: **218 == 218, zero in
  R not in the sweep, zero in the sweep not in R.** That is termination by
  enumeration against the source of truth, not by assertion.
- **There is no third `.Rbuildignore` call site.** Walked every function in
  `asNamespace("tools")` for a body mentioning it: `.build_packages`,
  `.check_packages`, `get_exclude_patterns`, `inRbuildignore`, `pkgVignettes`.
  `get_exclude_patterns`/`inRbuildignore` are the reader, not call sites.
  **`.check_packages`'s mention is not a pattern read** — line 4553 of the
  deparse, `allowed <- c(".Rbuildignore", ".Rinstignore",
  "vignettes/.install_extras")`, is a filename allowlist inside
  `check_dot_files()`. `pkgVignettes` line 31-34 matches against
  `list.files(docdir, all.files = FALSE, full.names = TRUE)` — `vignettes/*`,
  one level, no dotfiles — a strict subset of the sweep. **The brief's claim of
  exactly two call sites is confirmed.**
- **Fix 4's pin cannot stop existing silently.** `expect_true("inst/registry"
  %in% paths)` goes RED if `inst/registry` is renamed or removed — loud, safe
  direction, and the message names the path. The companion
  `expect_equal(paths[rbuildignore_excluded(paths, "^inst/registry$")],
  "inst/registry")` is isolated from the real pattern file, so a `.Rbuildignore`
  edit cannot make it pass or fail for the wrong reason. `^inst/registry$` is
  anchored at both ends and matches exactly one of the 219 paths.
- **Fix 5 is correct in both directions.** Measured with `PATH` stripped:
  `Sys.which("git")` is `""`, the `skip_if` at 443 fires, and the `system2()`
  that *would* have raised `error in running command` is never reached. With git
  present against a non-repo, `attr(out, "status")` is `128L`, so
  `expect_null()` **fails** — the round-2 property (a git that ran and reported
  a problem is a failure, not a skip) is preserved. The `suppressWarnings()`
  still covers the non-zero-exit warning. No remaining path where `system2()`
  errors, given finding 1's `file.exists()` change or without it.
- **Fix 2 (`shipped_dirs` → `shipped_top`, duplicate append removed) is inert
  and correct.** `paths` is now duplicate-free (measured: `n = 219`,
  `sum(duplicated) = 0`, against 217/206 before), and
  `rbuildignore_excluded()` is elementwise, so no assertion changes value.

## Noted, not filed as findings

- **The sweep's path count is not stable across runs** — I measured 219, then
  218, then 219. The mover is `tests/testthat/_snaps`, an **empty, untracked,
  un-gitignored directory** testthat creates on a run. Git does not track empty
  directories, so `git status --porcelain` is clean while it exists. It changes
  no assertion — no pattern matches it, `expect_gt(length(paths), 100)` has
  enormous margin, and `nested_dirs` needs only one — and including it is
  *correct*, since `R CMD build .` on the source tree really would ship it.
  Flagging only so a future measurement of "218 nested paths" is not read as
  drift.
- `expect_gt(length(paths), 100)` remains satisfied by the files-only sweep
  (206 > 100). That is fine now: it is a second, weaker premise sitting beside
  `nested_dirs`, and the comment at 369-375 says so accurately.

---

## Convergence

**Converged**, on the class that has recurred three times on this branch — a
defect sitting inside the previous round's fix. Neither finding above is one:
finding 1 is a pre-existing line in an adjacent guard, and finding 2 is a stated
residual rather than a wrong assertion. Both fail loud or fail to *skip*; neither
can let a broken tarball through with the suite green, which is the property
rounds 1-3 were chasing.

**Confidence, per the repo's rule that "this is terminal" has now been wrong
three times on this branch:**

- **High** that the silent direction is closed. The sweep's path set was proved
  *equal* to R's own for the shipped subtrees (218 == 218, set difference empty
  both ways) rather than merely adequate, and `.Rbuildignore` was shown by
  namespace-wide enumeration to have exactly two consumers with the second a
  strict subset of the first. There is no level above that source — this is the
  enumeration form CLAUDE.md says ends the recursion, not an assertion that it
  has ended.
- **High** on finding 1: reproduced against a real `git worktree` of this repo,
  with the positive control (git returning `.claude/visibility` from inside it)
  printed beside the failing condition.
- **Moderate-high** on finding 2 being merely a residual rather than a defect.
  It is a judgement about whether a future maintainer would weaken the sweep or
  declare an exemption, and judgements of that shape are what the exemption-list
  rule exists to remove.

**What would change this verdict:** evidence that `.Rbuildignore` patterns are
applied to a path form outside `dir(include.dirs = TRUE)` output at a *later*
build stage — round 3's stated residual. I closed the call-site half of it by
enumerating `tools`, and the `pkgVignettes` site is a subset, so the remaining
gap would have to be a non-`tools` consumer (a `pkgbuild`/`devtools` reimplementation
used by `devtools::build()`). That would not affect `R CMD build`, which is what
ships the tarball, so it is a different guard's problem rather than instance six.

---

## Method note

The working tree was never modified. The restore-the-bug run used
`git archive HEAD | tar -x` into the session scratchpad and reverted exactly one
argument, verified by diffing the extraction against `git show HEAD:` before
running. The worktree probe used `git worktree add --detach` into the scratchpad
and was removed afterwards (`git worktree remove --force`, confirmed clean).
