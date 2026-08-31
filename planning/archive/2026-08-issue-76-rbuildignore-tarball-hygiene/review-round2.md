# Review round 2 — `tests/testthat/test-build_hygiene.R` + `.Rbuildignore` (gq#76)

Reviewed the five fixes applied since round 1. **The tree moved twice during this
review** — I started on `2aef601`, and `1d54c39` ("Stop putting prose in
`.Rbuildignore`…") and `3818454` landed mid-read. Everything below is measured
against **`3818454`**, the current HEAD. Two things I was independently
converging on — `.Rbuildignore` comment lines being live regexes, and `auto` not
being checked against `ships` — were fixed by `1d54c39` before I could report
them, and are recorded under "Verified clean" rather than as findings.

Environment: R 4.5.2. `test_file("tests/testthat/test-build_hygiene.R")` →
`FAIL 0 | WARN 0 | SKIP 0 | PASS 31`.

---

## Findings

### 1. **[bug]** `test-build_hygiene.R:236-241` — the silent direction is guarded only in **source** mode, and `R CMD check` can never select source mode. A `.Rbuildignore` line that drops `tests/`, `man/`, `data/` or `vignettes/` from the tarball leaves CI **green**.

This is the round-1 finding-2 class reappearing *inside* fix 2 — the gq#52 shape
the brief asked me to look for. Fix 2 is correct, and it landed in the branch CI
never runs; the branch CI does run has the built artifact in hand and does not
make the check.

**Why source mode is unreachable under check.** `tools:::.check_packages`
creates `00_pkg_src` only under `if (is_tar)` — deparse lines 5932-5949 — and
`r-lib/actions/check-r-package@v2` drives `rcmdcheck`, which builds a tarball and
checks *that*. So `is_tar` is always TRUE in CI, `00_pkg_src/gq` always exists,
and fix 3 (correctly) prefers it. Exercised `build_root()` against four real
layouts:

| cwd | mode |
|---|---|
| `gq.Rcheck/tests/testthat` (neutral check dir) | `tarball` |
| `repo/gq.Rcheck/tests/testthat` (check dir inside the repo) | `tarball` |
| `repo/tests/testthat`, with a stale `repo/gq.Rcheck` present | `source` |
| the live gq checkout | `source` |

`.github/workflows/` holds exactly two workflows: `R-CMD-check.yaml` (rcmdcheck)
and `pkgdown.yaml` (`build_site_github_pages`, no tests). **There is no
`devtools::test()` job.** So in CI the following never execute, and a `skip_if`
is indistinguishable from a pass in the summary line:

- `unexplained` (213)
- `shipped_but_excluded` — fix 2 itself (228-229)
- `setdiff(ships, entries)` (234)
- both premise checks (209-210)
- the entire new anchoring test (297-319)
- the entire `.claude/visibility` test (345-362) — so plan-review finding G5's
  guard does not gate a PR either

**Measured consequence.** Real tarball top level, built from this branch:
`build data DESCRIPTION inst LICENSE man NAMESPACE NEWS.md R README.md tests
vignettes` (12 entries, 226 paths). Simulating the four tarball-mode assertions
against a tarball with a shipped directory removed:

```
correct tarball                    undeclared:T forbidden:T dotfiles:T size:T -> GREEN
tests/ dropped                     undeclared:T forbidden:T dotfiles:T size:T -> GREEN
man/ dropped                       undeclared:T forbidden:T dotfiles:T size:T -> GREEN
data/ + vignettes/ dropped         undeclared:T forbidden:T dotfiles:T size:T -> GREEN
```

`setdiff(entries, c(ships, generated))` is empty for a *subset* as readily as for
the full set, and `expect_gt(length(entries), 5)` survives losing four
directories. `R CMD check` itself does not reliably catch it either — a dropped
`tests/` or `vignettes/` produces no ERROR under `error-on: '"error"'`.

**Fix is one line in the `else` branch, and it is the stronger form of the
assertion because it reads the artifact rather than the source:**

```r
    # Every declared entry must be PRESENT in the built package, not merely
    # absent from the undeclared set. setdiff() the other way round is blind to
    # a directory an over-broad .Rbuildignore line removed.
    expect_equal(setdiff(ships, entries), character(0))
```

Verified: empty against the real tarball, and returns the dropped name in each
simulated case above. (The existing line 234 is the same assertion, in the branch
that does not run.)

Secondary, same root cause: consider whether the `.claude/visibility` guard
should also be reachable in CI, since gitignoring that marker is a commit and CI
is where a commit gets caught.

---

### 2. **[fragile]** `test-build_hygiene.R:318` and `.Rbuildignore:20` — the new anchoring test asserts a **proxy** for anchoring, and this diff already contains a line that passes it while being unanchored.

```r
expect_equal(lines[!startsWith(lines, "^")], character(0))
```

`startsWith(line, "^")` does not establish anchoring. The diff's own
`^.*\.egg-info$` is `^` immediately followed by `.*`, which is exactly *no* start
anchor, and PCRE `.` matches `/`, so it matches any relative path at any depth:

```r
grepl("^.*\\.egg-info$", "inst/registry/x.egg-info", perl = TRUE)   # TRUE
grepl("^test", "tests", perl = TRUE)                                 # TRUE
```

The comment at 306-310 overstates what the line enforces — it calls the rule
"the root-cause fix for the silent direction below" and says it makes a bare
`test` line "impossible to add unnoticed". `^test` passes the assertion and still
excludes `tests/`; so would `^.*test.*$`. What actually catches `^test` is
`shipped_but_excluded` at 228, which per finding 1 does not run in CI. Per
CLAUDE.md's *"a guard that encodes the cause you measured is a proxy for the
property you want"*, the condition here names the mechanism (`starts with ^`)
where the requirement is the capability (`cannot match more than intended`).

**The uncovered case is nested, and nothing else in the file reaches it.** A
pattern of the `^.*\.csv$` shape passes the anchoring test, matches no *top-level*
entry (so `unexplained` and `shipped_but_excluded` stay silent), and strips every
file under `inst/registry/`. Tarball mode is top-level only. The file states its
top-level scope for the "something shipped that shouldn't" direction and cites
R's recursive hidden-files check as cover — R has no equivalent cover for the
*dropping* direction, and `^.*\.egg-info$` is the first depth-agnostic pattern
this repo has ever carried.

Current state is clean, measured: none of the 24 patterns matches any nested path
(0 hits across 1,022 repo paths excluding `.git`, and 0 across the 226 tarball
paths); each of the seven fix-5 patterns matches 0 paths today.

Either assert anchoring at **both** ends with the one genuinely depth-agnostic
pattern declared as a named exemption, or reduce the comment's claim to what the
assertion enforces (it excludes prose, which is real and worth keeping — it just
is not a root-cause fix for over-matching).

---

### 3. **[fragile]** `test-build_hygiene.R:228` + `321-341` — the `| auto` half of `shipped_but_excluded` has no restore-the-bug case.

```r
shipped_but_excluded <- entries[(ignored | auto) & entries %in% ships]
```

The `| auto` addition is correct and its comment honestly records that it is
unreachable with today's `ships` (I confirmed: `entries[auto & entries %in%
ships]` is empty on the live tree, and no rule in `.build_packages` 846-866
touches any of the eleven names). But the synthetic test written specifically to
prove this assertion can go red (321-341) builds only `ignored_bad` — nothing
exercises the `auto` side. So one half of the assertion has been seen to fail and
the other half has not, which is the decoration case the repo's own convention
warns about. One extra pair in that same test covers it: an `isdir` entry ending
`Old`, or `"check"`, against a locally-widened `ships`.

Low severity — unreachable-today, not wrong.

---

## Verified clean

Recorded so a round 3 does not re-litigate them.

- **Fix 3 (reorder `build_root`) introduced no defect.** Tarball mode requires
  `<up>/00_pkg_src/gq` *with a DESCRIPTION naming gq*; `00_pkg_src` is created
  only for `is_tar` (deparse 5932), and it is not cleaned up mid-check — R's own
  "non-standard things in the check directory" allowlist names it (deparse 6201),
  so it is present while tests run. A `devtools::test()` in a repo that still
  holds a stale in-tree `gq.Rcheck/` correctly resolves to **source** (the
  candidates are `tests/00_pkg_src`, `repo/00_pkg_src`, `parent/00_pkg_src`, none
  of which is under `gq.Rcheck/`). An unrelated package's check dir cannot match:
  the path segment is literally `gq` *and* `names_gq()` reads DESCRIPTION.
- **Fix 1: `r_auto_excluded()` is now a complete top-level transcription.**
  Reconciled rule by rule against `tools:::.build_packages` 846-866 in R 4.5.2:
  846 `inRbuildignore` (split across the two helpers), 848 `check`/`chm`/
  `.vc_dir_names`, 850 `([Oo]ld|\.Rcheck)$`, 852 `Read-and-delete-me`/
  `GNUMakefile`, 854 `._`, 862 `^.Rbuildindex[.]`, 863 `.hidden_file_exclusions`,
  865 the tarball-name rule — all modelled. 855/857 (`src/`), 859 (`inst/doc/`,
  `vignettes/`) cannot produce a top-level match, and the comment at 54-57 now
  says so accurately. Nothing further missing.
- **Fix 4: `generated <- "build"` is exactly right.** `R CMD build` *unlinks*
  `MD5` unless `--md5` is passed (deparse 995-999) and only *updates* `INDEX` if
  one already exists (130-131); gq has neither, and CI's
  `build_args: c("--no-manual","--compact-vignettes=gs+qpdf")` carries no
  `--md5`. The real tarball top level is `ships` + `build`, nothing else.
- **Fix 5: the seven new `.Rbuildignore` patterns do not over-match.** Each
  matched 0 of 1,022 repo paths and 0 of 226 tarball paths. `^dist$`,
  `^\.venv$`, `^__pycache__$`, `^\.vscode$`, `^\.idea$`, `^Thumbs\.db$` are
  fully anchored, so top-level only — narrower than their `.gitignore`
  counterparts, which is the safe direction. `^.*\.egg-info$` is the depth-
  agnostic one; see finding 2.
- **Comment lines in `.Rbuildignore`** — `tools:::inRbuildignore` strips nothing
  and skips nothing, so every non-empty line is a live regex. The five prose
  lines added in `801c9be` were live patterns (they happened to match 0 paths).
  Already removed in `1d54c39`; the replacement test forbids their return.
- **`system2` quoting in the visibility test.** `system2()` pastes args onto the
  command and hands the result to a shell, so `shQuote(root$path)` is required
  and correct; a repo path containing a space would otherwise return empty and
  pass for the wrong reason.
- **Tarball-mode assertions hold on the real artifact.** `setdiff(entries,
  c(ships, generated))`, `intersect(entries, forbidden)` and
  `entries[startsWith(entries, ".")]` are all empty against the tarball I built
  from this branch (`gq_0.13.0.tar.gz`, 226 paths, exit 0).
- **`.claude/visibility` is tracked** — `git ls-files .claude` returns exactly
  `.claude/visibility`.

## Minor, not filed as findings

- `test-build_hygiene.R:359` — `skip_if(!is.null(attr(out, "status")), "git
  unavailable")` treats *any* non-zero git exit as "git unavailable" and skips,
  which is the fail-toward-skip direction CLAUDE.md names. Exposure is small
  given the `.git` existence check at 352, and the whole test skips in CI anyway
  (finding 1), so fixing it in isolation buys little.
- `.Rbuildignore` omits `build` deliberately and the reason is now recorded in
  `findings.md` rather than in the file itself (comments being regexes). Worth
  making sure that reason survives somewhere a future editor will read before
  re-adding `^build$`, which would break vignette metadata.
