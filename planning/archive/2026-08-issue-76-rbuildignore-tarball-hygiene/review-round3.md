# Review round 3 — the five fixes in `e6db503` (gq#76)

Scoped to `e6db503` only, per the brief. Rounds 1/2 "Verified clean" sections not
re-litigated. Measured against `e6db503` (HEAD), R 4.5.2.

Baseline reproduced: `test_file("tests/testthat/test-build_hygiene.R")` →
`FAIL 0 | WARN 0 | SKIP 0 | PASS 35`.

**Verdict: NOT converged.** One real bug, inside fix 3 — the same
defect-inside-the-fix shape as gq#52 and as round 2's finding 1.

---

## Findings

### 1. **[bug]** `test-build_hygiene.R:357-358` — the new sweep omits `include.dirs = TRUE`, so it never examines a single nested directory. A `.Rbuildignore` line matching a nested directory deletes it and everything under it, and the sweep stays green.

Fix 3 replaced a spelling-based proxy (`startsWith(lines, "^")`) with the real
property — "no pattern may match a path we ship" — and then samples the path set
it matches against with:

```r
rel <- list.files(file.path(root$path, d), recursive = TRUE,
                  all.files = TRUE, no.. = TRUE)
```

`list.files(recursive = TRUE)` returns **files only**. R does not:

```
tools:::.build_packages
 842|  allfiles <- dir(".", all.files = TRUE, recursive = TRUE,
 843|      full.names = TRUE, include.dirs = TRUE)     <- DIRECTORIES INCLUDED
 844|  allfiles <- substring(allfiles, 3L)
 846|  exclude <- inRbuildignore(allfiles, pkgdir)     <- matched against them
 867|  unlink(allfiles[exclude], recursive = TRUE, ...) <- and unlinked WHOLE
```

So R matches `.Rbuildignore` against directory paths and removes a matched
directory **recursively**. The sweep cannot see that category at all.

**Measured coverage gap** on the live tree — 12 paths R matches against that the
sweep never constructs, every one a directory:

```
inst/examples          inst/styles/raster                        man/figures
inst/logo              inst/styles/services                      tests/testthat
inst/registry          inst/styles/vector                        tests/testthat/fixtures
inst/styles            inst/styles/vector/overrides
                       inst/styles/vector/overrides/bcfishpass_mobile
```

**Restored the bug, twice, and built real tarballs** (`R CMD build
--no-build-vignettes --no-manual` from `git archive HEAD` into a scratch tree, so
the working tree was untouched):

| `.Rbuildignore` line added | committed sweep | anchoring test | tarball |
|---|---|---|---|
| *(none — control)* | green | green | `inst/registry` 11 files, `man/figures` 3 files |
| `^inst/registry$` | **green** | green | **`inst/registry` count: 0** |
| `^man/figures$` | **green** | green | **`man/figures` count: 0** |

`inst/registry` is `reg_main.json`, `groups.csv`, `themes.csv` — the package's
stated single source of truth. `gq_reg_main()` breaks for every installed user
and the guard written to prevent exactly that reports green.

**No other assertion in the file reaches it.** `shipped_but_excluded` (228) and
`setdiff(ships, entries)` (234, 253) are top-level only, and `inst` itself is
untouched — `^inst/registry$` does not match `inst`. The anchoring test passes:
the line is fully anchored at both ends. It is a *correct-looking, correctly
anchored* line.

**Why this is the reachable case rather than an exotic one.** 21 of the 24 lines
in gq's `.Rbuildignore` name a directory. Directories are what people write
`.Rbuildignore` lines *for*, and the near-miss is one keystroke from a real line
the file already carries — `^registry$` is line 13, and `^inst/registry$` is what
someone writes on being told "it's under inst".

**Severity is not uniform, and it is worth stating honestly.** Grepping `tests/`
and `R/` for each missed directory: `inst/registry` (29 files), `inst/examples`
(19), `inst/styles` (11), `tests/testthat/fixtures` (4) would surface downstream
as test failures under `R CMD check`, so those are loud-but-misattributed.
**`man/figures` is referenced in 0 test or R files** — losing it is completely
silent, and `inst/logo` in 1.

**Fix is one argument, and it is verified against both known answers:**

```r
    rel <- list.files(file.path(root$path, d), recursive = TRUE,
                      all.files = TRUE, no.. = TRUE, include.dirs = TRUE)
```

```
base  include.dirs=FALSE n=206  hits: <none>         -> green
base  include.dirs=TRUE  n=218  hits: <none>         -> green    <- no false alarm today
bad   include.dirs=TRUE  n=218  hits: inst/registry  -> RED
bad2  include.dirs=TRUE  n=218  hits: man/figures    -> RED
```

None of gq's 24 current patterns matches any of the 12 nested directories, so the
change is green on the correct tree. Worth adding one of these as a restore-the-bug
case beside the `ignored_bad` pair at 386, since a sweep that has never been seen
to go red on a nested path is the decoration case again.

---

### 2. **[fragile]** `test-build_hygiene.R:417,423-424` — fix 5's replacement skip is unreachable, and on a machine without git the test **errors** instead of skipping.

Round 2's complaint (skip on *any* non-zero status) was correct and is fixed. The
replacement cannot do the job its own comment claims — "Skip only when git could
not run at all" — for two independent reasons.

**First: `system2()` raises an R error when the command does not exist.** It does
not return a status attribute, and `suppressWarnings()` does not catch an error.
Measured, running the exact lines 416-424 with git off `PATH`:

```
Sys.which('git') = ''
*** system2 RAISED AN R ERROR:  error in running command
*** the skip_if on the next line is never reached -> test ERRORS
```

vs. git present: `status = NULL, length(out) = 1`, skip condition `FALSE`, assertion PASS.

**Second: the condition is self-contradictory even if the call returned.**
`is.null(attr(out, "status"))` means the command exited 0, which means git ran;
`!nzchar(Sys.which("git"))` means git is not on `PATH`. `Sys.which()` reads the
same `PATH` the shell inherits, so the two conjuncts cannot both hold. The
`skip_if` is dead code.

Direction is safe (false alarm, not false pass), and the `dir.exists(.git)` guard
at 411 covers the common non-repo case — so this is low severity. But the escape
hatch is decoration, which is the class CLAUDE.md names ("a guard's escape hatches
are where it goes to die"), and a container running `devtools::test()` over a
bind-mounted checkout without git installed reds the suite with
`error in running command` — an error that reads as a broken test, not a missing tool.

**Fix is to test for git before calling it, not after:**

```r
  skip_if(!nzchar(Sys.which("git")), "git not installed")
  args <- c("-C", shQuote(root$path), "ls-files", ".claude")
  out <- suppressWarnings(system2("git", args, stdout = TRUE, stderr = FALSE))
  expect_null(attr(out, "status"))
```

`expect_null()` then keeps the round-2 property: a git that *ran* and reported a
problem is a failure, not a skip.

---

## Verified clean — the other three fixes

Recorded so a round 4 does not re-open them.

- **Fix 1 (`expect_equal(setdiff(ships, entries), character(0))` in tarball mode,
  line 253) raises no false alarm on a legitimate build.** The brief's specific
  worry — `--no-build-vignettes` — does not hold. Built the committed tree with
  `R CMD build --no-build-vignettes --no-manual`: tarball top level is
  `data DESCRIPTION inst LICENSE man NAMESPACE NEWS.md R README.md tests vignettes`
  — **`vignettes/` survives** (3 files present); only `build/` is absent, and
  `build` is in `generated`, an allowlist, so `setdiff(entries, c(ships, generated))`
  is empty either way. All 11 `ships` present, so the new line is empty. `R CMD build`
  exposes no option that drops a `ships` entry, and `--compact-vignettes` /
  `--no-manual` / `--md5` touch none of them. The assertion is correct and the
  direction it adds is the one CI can actually reach.
- **Fix 2 (`^[^/]+\.egg-info$`) is correct for its intent.** Measured:
  matches `gq.egg-info`, `foo.egg-info`; does **not** match
  `inst/registry/x.egg-info` or `a/b.egg-info` (the old `^.*\.egg-info$` matched
  both). It does not match `gq.egg-info/PKG-INFO`, but neither did the old
  pattern and it does not need to — R unlinks a matched directory recursively
  (line 867 above). Top-level-only is consistent with the six sibling patterns
  and is the safe direction relative to `.gitignore`'s `*.egg-info/`.
- **Fix 4 (the `auto` restore-the-bug case, lines 389-397) is non-vacuous.**
  `r_auto_excluded(c("DESCRIPTION","chm","toolsOld"), c(FALSE,TRUE,TRUE))` returns
  `F,T,T` by two different R rules — `chm` via the
  `c("check","chm",.vc_dir_names)` membership at line 59, `toolsOld` via the
  `([Oo]ld|\.Rcheck)$` rule at line 60 — and the assertion selects exactly both.
  `wider` is used, not dead. Isolating `auto` from `ignored` is the right shape
  here; it mirrors the `ignored_bad` pair above it.

## Noted, not filed as findings

- **`test-build_hygiene.R:361` is a redundant duplicate append.**
  `paths <- c(paths, intersect(ships, list.files(root$path)))` re-adds all 11
  top-level names that the `c(d, file.path(d, rel))` inside the `lapply` already
  contributed. Measured: `length(paths) = 217`, `unique = 206`, and the 11
  duplicates are exactly the `ships` names. No behavioural effect —
  `rbuildignore_excluded()` is elementwise and duplicates cannot change the
  result — so this is redundancy, not a defect. It does inflate the
  `expect_gt(length(paths), 100)` premise by 11, which is immaterial at 206.
- **`expect_gt(length(paths), 100)` is adequate for what it claims** ("the sweep
  must actually be looking at something"): a wrong `root$path` yields
  `length(paths) == 0` and it fires. It cannot detect finding 1 — 206 clears 100
  as comfortably as 218 does — but that is finding 1's problem, not a second one.

---

## Convergence

**Not converged.** Finding 1 is a genuine silent-direction hole in the guard,
demonstrated against two real tarballs, and it sits inside the fix written to
close the previous silent-direction hole — the third occurrence of that pattern
on this branch.

**Confidence, stated per the repo's own rule that "this is terminal" has been
wrong three times before:**

- **High** that finding 1 is real and the one-argument fix closes it: it is
  proven end-to-end against built artifacts (`tar tzf` counts, not simulation),
  and the fix is verified against both a must-pass and a must-fail tree.
- **High** that finding 2 is real: reproduced by running the exact lines with
  `PATH` stripped of git.
- **Moderate** that these are the last of the class. What I did *not* exhaustively
  enumerate is whether R matches `.Rbuildignore` against any path form beyond
  `dir(include.dirs = TRUE)` output — I read lines 842-867 of `.build_packages`
  and `inRbuildignore`, and that is the whole path set for the exclusion pass,
  but I did not walk the vignette-staging or `inst/doc` passes that run later.
  A pattern that survives the sweep and is applied at a later stage would be
  instance six.

**What would change the verdict to converged:** `include.dirs = TRUE` landed with
a restore-the-bug case pinning a nested directory, plus the `Sys.which()` reorder.
At that point the sweep's path set equals R's own for the shipped subtree
(218 == 218, measured), which is termination by enumeration against the source of
truth rather than by assertion — the form CLAUDE.md says actually ends the
recursion.

---

---

## Addendum — both fixes landed mid-review, and are verified

The tree moved while this was being written (the same thing happened in rounds 1
and 2). `ff8b89c` "Fold in review round 3: the sweep never looked at a directory"
and `e3d55b3` "Make the sweep premise able to fail" applied both findings. Both
re-measured against `e3d55b3`:

**Finding 1 — closed, and closed by enumeration rather than by assertion.**
`include.dirs = TRUE` added, redundant append at 361 removed. The sweep's path set
is now **identical to R's own** for the shipped subtree:

```
paths: 219   duplicates: 0
R's set: 219   sweep set: 219
in R but NOT swept: 0      swept but not in R: 0      SETS IDENTICAL: TRUE
```

That is the termination condition — the sweep now matches the complete candidate
set `tools:::.build_packages` builds at line 842, so there is no level above its
source left to check.

**The new premise is not decoration, which was the live risk in the fix.** The
obvious form (`any(dir.exists(paths))`) would have passed under the restored bug,
since the top-level `ships` entries satisfy it alone; the committed form requires a
**nested** directory. Measured against both answers:

| sweep | `nested_dirs` | `expect_gt(., 0)` |
|---|---|---|
| as committed (`include.dirs = TRUE`) | 13 | passes |
| bug restored (files only) | **0** | **fails** |

The restore-the-bug pair at the end (`expect_true("inst/registry" %in% paths)` then
`expect_equal(paths[rbuildignore_excluded(paths, "^inst/registry$")],
"inst/registry")`) also carries its own premise beside its assertion, so a future
rename of that directory fails on the premise line naming the real cause rather
than on the behaviour line blaming the sweep.

**Finding 2 — closed.** `skip_if(!nzchar(Sys.which("git")), "git not installed")`
now precedes the `system2()` call, so the error path is unreachable. Verified with
`PATH` stripped of git: `Sys.which('git') = ''`, skip condition `TRUE`.
`expect_null(attr(out, "status"))` retained, so a git that *ran* and reported a
problem is still a failure rather than a skip.

**Guard file at `e3d55b3`: `FAIL 0 | WARN 0 | SKIP 0 | PASS 38`** (35 before).

**Revised verdict: converged**, on the ground I named above — the sweep's path set
now provably equals the source of truth's, both new premises were tested against a
must-pass and a must-fail tree, and the residual I flagged as moderate confidence
(a later vignette-staging exclusion pass) is unaffected by anything in these two
commits and is not a defect in them.

---

## Method note

The working tree was never modified. Both bug restorations used
`git archive HEAD | tar -x` into the session scratchpad, and the exact committed
sweep code was copied verbatim rather than paraphrased, per the repo's rule that
a hand-rewritten "previous version" is a different program.
