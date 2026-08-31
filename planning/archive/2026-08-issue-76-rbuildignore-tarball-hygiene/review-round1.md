# Review round 1 — `tests/testthat/test-build_hygiene.R` (gq#76)

Reviewed commit `31dacbf` ("Guard the package tarball against undeclared top-level
entries"). Note the tree moved during the review: `38dc736` ("Keep .claude and
gq.Rproj out of the package tarball") landed mid-read, so every simulation below
used the **post-fix** `.Rbuildignore` (17 lines). The test file itself is
byte-identical to what was reviewed (`git diff HEAD -- tests/testthat/test-build_hygiene.R`
empty).

Environment: R 4.5.2 (2025-10-31).

---

## Findings

### 1. **[bug]** `test-build_hygiene.R:45-53` — `r_auto_excluded()` omits two of R's top-level exclusion rules; a `gq_*.tar.gz` at the repo root reds the suite on a correct tree

The comment on line 45-46 claims the block is "Transcribed from
`tools:::.build_packages`, restricted to the rules that can apply to a TOP-LEVEL
entry -- its `src/` and `inst/doc/` rules cannot." That is not what `.build_packages`
contains. Deparsed at lines 846-866 of `tools:::.build_packages` (R 4.5.2), the full
rule set is:

```
846|  exclude <- inRbuildignore(allfiles, pkgdir)                     modelled
848|  exclude | (isdir & bases %in% c("check","chm", .vc_dir_names))  modelled
850|  exclude | (isdir & grepl("([Oo]ld|\\.Rcheck)$", bases))         modelled
852|  exclude | bases %in% c("Read-and-delete-me","GNUMakefile")      modelled
854|  exclude | startsWith(bases, "._")                               modelled
855|  exclude | (isdir & grepl("^src.*/[.]deps$", allfiles))          src/, correctly skipped
857|  exclude | (allfiles == paste0("src/", pkgname, "_res.rc"))      src/, correctly skipped
859|  exclude | endsWith(allfiles, "inst/doc/.Rinstignore") | ...     inst/doc, correctly skipped
862|  exclude | grepl("^.Rbuildindex[.]", allfiles)                   ** NOT MODELLED, top-level **
863|  exclude | (bases %in% .hidden_file_exclusions)                  modelled
864|  exts <- "\\.(tar\\.gz|tar|tar\\.bz2|tar\\.xz|tgz|zip)"
865|  exclude | grepl(paste0("^", pkgname, "_[0-9.-]+", exts, "$"),   ** NOT MODELLED, top-level **
866|            allfiles)
```

Both omissions match at top level. Measured, comparing the test's function against a
faithful transcription:

```
              entry   test_says   R_says
    gq_0.1.0.tar.gz       FALSE     TRUE
       gq_0.1.0.tgz       FALSE     TRUE
       gq_0.1.0.zip       FALSE     TRUE
   .Rbuildindex.rds       FALSE     TRUE
```

**Why it matters.** `R CMD build .` run from the repo root — the obvious way anyone
verifies gq#76, and what produced the tarball evidence in `findings.md` — leaves
`gq_<version>.tar.gz` at the top level. It is untracked and matched by nothing in
`.gitignore`, so `list.files(all.files = TRUE)` sees it. Simulated against the real
repo listing plus that one entry, using the exact functions from the test file:

```
sum(ignored) = 11   sum(auto) = 3
unexplained: gq_0.1.0.tar.gz
```

i.e. `FAIL` on a tree that `R CMD build` would have excluded, blaming an artifact the
developer just created. The direction is safe (false alarm, not false pass) but per
CLAUDE.md's own "crying wolf is how a guard stops being read", the first person to hit
it will be told the guard is wrong — and they will be right.

Fix is two lines inside `r_auto_excluded()`:

```r
    grepl("^\\.Rbuildindex[.]", entries) |
    grepl("^gq_[0-9.-]+\\.(tar\\.gz|tar|tar\\.bz2|tar\\.xz|tgz|zip)$", entries)
```

Also worth correcting the comment: the omission was not "rules that cannot apply at
top level", it was two rules that do.

---

### 2. **[fragile]** `test-build_hygiene.R:183-189` — the guard enforces only half the property its own name states; an over-broad `.Rbuildignore` line silently drops a declared directory with the suite green

The test is named *"every top-level entry is either shipped on purpose or excluded on
purpose"*, and the file's comments (lines 55-59) go out of their way to explain that R
matches `.Rbuildignore` patterns **partially, not anchored**, so "a pattern written
without them would exclude far more than intended". That hazard is then demonstrated
on synthetic input (lines 239-240) and **never asserted against gq's own
`.Rbuildignore`**. Nothing in source mode checks that a `ships` entry is not itself
matched by an ignore pattern. `expect_equal(setdiff(ships, entries), character(0))`
(line 189) tests only that the name still *exists on disk*.

Measured — one bare unanchored word added to `.Rbuildignore` (`test`, e.g. someone
reaching for `tests/testthat/_snaps` and forgetting the anchors):

```
entries excluded by .Rbuildignore that gq DECLARES it ships:  tests
  unexplained             = <empty>   => PASS
  setdiff(ships, entries) = <empty>   => PASS
  sum(ignored) = 12 > 5              => PASS
  sum(auto)    = 3  > 0              => PASS
=> suite GREEN while tests/ is silently dropped from the tarball
```

The same slip with `man`, `dat`, or `vignette` drops `man/`, `data/`, `vignettes/`.
This is the silent direction, and it is reachable by editing exactly the file the
fix commit just touched.

One line closes it, and it is the natural companion to the existing staleness check:

```r
    # A declared entry must actually survive the build, not just exist on disk.
    # An unanchored .Rbuildignore line excludes far more than its author meant.
    expect_equal(entries[(entries %in% ships) & (auto | ignored)], character(0))
```

Related, same class: the premise checks at lines 180-181 (`sum(ignored) > 5`,
`sum(auto) > 0`) cannot see this. With the over-broad line present `sum(ignored)`
went **up**, to 16 in one variant — the premise is satisfied more comfortably by the
broken state than by the correct one.

---

### 3. **[fragile]** `test-build_hygiene.R:115-131` — `R CMD check` run from inside the repo resolves to **source** mode, so tarball mode is unreachable in the common local check

`up` is searched source-first, and under `R CMD check` the third rung `../../..`
(from `gq.Rcheck/tests/testthat/`) is the directory the check was invoked in. If that
is the repo root, it carries both `.Rbuildignore` and a gq `DESCRIPTION`, so the
source branch wins and `00_pkg_src/gq` is never consulted.

Simulated all three layouts:

| scenario | layout | `build_root()` |
|---|---|---|
| B | check dir in a neutral temp dir (`devtools::check()`) | `tarball` -> `.../gq.Rcheck/00_pkg_src/gq` ✓ |
| C | check dir created **inside** the repo (`R CMD check gq_*.tar.gz` from the root) | `source` -> the live working tree ✗ |
| F | a **non-gq** package one level up from a neutral check dir | `tarball` ✓ — the `names_gq()` requirement works |

Two consequences:

- The tarball-mode assertions — `intersect(entries, forbidden)`, and "no dot-file
  survived the build" (lines 193-196), the only assertions that read the **artifact**
  rather than the source — never run in scenario C. Which half of the guard executes
  is decided by where the `.Rcheck` directory happened to be created, not by intent.
- In scenario C the guard inspects a live working tree that, at that exact moment,
  contains `gq.Rcheck/` (correctly auto-excluded by the `\\.Rcheck$` rule) and very
  likely `gq_<version>.tar.gz` — finding 1, which is why the two compound.

Fix: search the tarball layout **first**, since `00_pkg_src/gq` only exists when a
real check is running and is the stronger evidence; or check both and assert both when
both are found.

Scenario F confirms the headline concern from the plan is genuinely closed — requiring
`DESCRIPTION` to name `gq` does stop a stranger's tree matching. The `up` ordering
(`..`, `../..`, `../../..`) also correctly prefers the shallowest match, so a nested gq
checkout resolves to the near one.

---

## Checked and clean

Recording these so a later round does not re-litigate them.

- **Zero-length / empty-vector behaviour (question 4).** Both matchers early-return
  `logical(0)` on empty `entries`; without the early return `vapply(character(0), f,
  logical(1))` is `logical(0)` and the `|` chain stays `logical(0)` anyway, so the
  guards are belt-and-braces rather than load-bearing. `rbuildignore_excluded(e,
  character(0))` gives all-`FALSE`, which is what R does with no patterns.
  `patterns[nzchar(patterns)]` is safe — `readLines()` never yields `NA`, so the
  `nzchar(NA) == TRUE` trap is not reachable here. `startsWith(character(0), ".")` and
  `entries[logical(0)]` both give `character(0)`. `expect_setequal(unexplained, ...)`
  at line 226 takes `character(0)`, not `NULL` — the `names(character(0))` trap that
  bites `test-vignette_legend_coverage.R`'s exemption idiom does not apply, because
  `ships` is unnamed and no `names()` call is made. All `vapply` calls pass
  `USE.NAMES = FALSE`, so `unexplained` is unnamed and `expect_equal(...,
  character(0))` cannot fail on a names attribute.
- **`match()` NAs in the synthetic test (lines 215-223).** If a probe entry went
  missing, `auto[NA]` is `NA`, `all(NA)`/`any(NA)` is `NA`, and `expect_true(NA)` /
  `expect_false(NA)` error. Loud, in the safe direction.
- **Vacuous pass in tarball mode (question 2).** `setdiff(entries, c(ships,
  generated))` is a literal-vs-literal comparison — nothing user-editable can widen it
  — and `expect_gt(length(entries), 5)` rules out an empty directory. Not vacuous.
  Source mode is vacuous only via finding 2's route.
- **`tools:::` under `R CMD check --as-cran` (question 6).** No NOTE. The
  "Unexported objects imported by ':::' calls" NOTE comes from
  `tools:::.check_packages_used`, which runs over the package's **R code**, not tests.
  Verified directly: a synthetic package whose only test calls
  `tools:::get_exclude_patterns()` returns
  `others=chr(0), imports=chr(0), data=chr(0)` from
  `tools:::.check_packages_used_in_tests()` — no unstated-dependency NOTE either,
  since `tools` is a base-priority package. All three pinned objects exist in R 4.5.2
  and the canary test at lines 139-155 names the cause if a future R drops them
  (`tools:::missing` errors rather than returning `NULL`, so it surfaces as a red test
  in this file rather than a stack trace elsewhere).
- **`ships` membership claim (question 5).** The comment at lines 69-70 asserts every
  entry is on R's own `known` top-level list. Verified against
  `tools:::.check_packages` lines 1078-1089 — all 11 are present, **including the six
  directories** (`R`, `data`, `inst`, `man`, `tests`, `vignettes` are in that same
  vector, alongside `build`, `demo`, `exec`, `po`, `src`). The claim is accurate. The
  list is a deliberate *narrowing* of `known` (gq does not want to bless `src`,
  `demo`, `java`, `tools`), which CLAUDE.md explicitly blesses as the case where a
  literal set is correct. `known` is a local inside `.check_packages`, not a reachable
  object, so it cannot be pinned to without re-transcribing it — no change
  recommended.
- **`generated` (question 5).** Not a dumping ground in practice, but two of its three
  entries are unreachable in the mode that uses it. `MD5` is written only by
  `R CMD build --md5` (opt-in) and `INDEX` is only *updated* if it already exists —
  `.build_packages` never creates either. So in `00_pkg_src/gq` only `build/` can
  appear. Harmless allowlist slack, no failure path; flagging only because it was
  asked about.
- **Untracked/gitignored roots in source mode.** `.venv/`, `.vscode/`, `__pycache__/`
  and friends would be reported as unexplained — correctly, since `R CMD build` really
  does ship them. `.DS_Store`, `.Rhistory`, `.RData`, `.Rproj.user` are all covered by
  `get_exclude_patterns()` / `.hidden_file_exclusions`. Confirmed against the live
  listing: `sum(ignored) = 11`, `sum(auto) = 3`, `unexplained` empty on the current
  post-fix tree.
- **"Restore the bug" test (lines 200-233).** Genuinely reaches the failure mode —
  `expect_setequal(unexplained, c(".claude", "gq.Rproj"))` on synthetic input that no
  `.Rbuildignore` line and no R rule covers, plus the complementary
  "and the fix clears it" assertion. Runs unconditionally, so a skip of the main test
  never leaves the classifier unexercised. This is the pattern CLAUDE.md prescribes and
  it is correctly done.
- **`skip_if` reachability.** The skip fires only when neither layout resolves. It is
  not reachable under `devtools::test()` or under any `R CMD check` of a tarball, and
  the message names both expected layouts.

---

## Summary

Three issues, in priority order:

1. **[bug]** `r_auto_excluded()` under-models R by the tarball-name and `.Rbuildindex`
   rules — `R CMD build .` in the repo root reds the suite. Two lines.
2. **[fragile]** No assertion that a `ships` entry survives `.Rbuildignore`; one
   unanchored pattern silently drops `tests/`, `man/` or `data/` from the tarball with
   the suite green. One line.
3. **[fragile]** Source mode wins over tarball mode when `R CMD check` runs inside the
   repo, so the artifact-reading assertions never execute there. Reorder the search.
