# Findings — `.claude` and `gq.Rproj` ship in the package tarball (#76)

## Issue context

`R CMD check` reports two NOTEs, both `.Rbuildignore` gaps:

```
❯ checking for hidden files and directories ... NOTE
  Found the following hidden files and directories:
    .claude

❯ checking top-level files ... NOTE
  Non-standard file/directory found at top level:
    'gq.Rproj'
```

`.claude` is the one that matters. `R CMD build` ships every top-level directory
not in `.Rbuildignore`, so it lands in the tarball and therefore in the library
of anyone installing from GitHub — settings, and any local agent configuration
that accumulates there later.

This is the class `CLAUDE.md` already documents ("`R CMD build` ships every
top-level directory not in `.Rbuildignore`"), which found 20 hits across 16
repos when it was last swept. gq was evidently not in that sweep, or `.claude`
postdates it.

Acceptance: `^\.claude$` and `^gq\.Rproj$` in `.Rbuildignore`; the tarball check
returns 0; `R CMD check` NOTE count drops by 2. The two remaining warnings
(non-ASCII in `R/gq_qgs_extract.R` / `R/gq_reg.R`, and the undocumented example
datasets `crossing`/`lake`/`road`/`stream`/`watershed`) are out of scope.

## Measurements taken before planning

Built from `main` at `865ebd6`, producing `gq_0.13.0.tar.gz`.

**Top-level entries in the tarball:**

```
.claude  build  data  DESCRIPTION  gq.Rproj  inst  LICENSE
man  NAMESPACE  NEWS.md  R  README.md  tests  vignettes
```

Both offenders confirmed present: `.claude/` and `.claude/visibility` (2
entries), and `gq.Rproj` (1).

**`.Rbuildignore` is NOT shipped in the tarball** (`tar tzf ... | grep -c
Rbuildignore` → 0). This is what makes a two-mode guard clean: the presence of
`.Rbuildignore` at the resolved root discriminates "source tree" from "unpacked
tarball" without guessing at the build layout.

**`.gitignore` is not shipped either, despite having no `.Rbuildignore`
pattern.** So R CMD build carries its own built-in exclusion list, and the guard
needs a third category for it or it will flag `.gitignore` and `.git` as
unexplained.

**Both offenders are tracked in git**, so this is not a stray-untracked-file
problem:

```
$ git ls-files .claude gq.Rproj
.claude/visibility
gq.Rproj
```

`.claude/visibility` is tracked deliberately — `.gitignore` carries an explicit
`!.claude/visibility` negation with a comment explaining that the marker tells
`claude-md-init` whether internal-only conventions may be written into
`CLAUDE.md`, and that its absence defaults to internal, which is the wrong
answer for a public repo. `.Rbuildignore` removes it from the tarball without
touching that.

## Existing `.Rbuildignore`

```
^LICENSE\.md$   ^_pkgdown\.yml$   ^docs$      ^pkgdown$    ^\.github$
^CLAUDE\.md$    ^dev$             ^python$    ^scripts$    ^planning$
^registry$      ^data-raw$        ^doc$       ^Meta$       ^Rplots\.pdf$
```

`planning` and `dev` are already covered, which is why the `CLAUDE.md` sweep
script (which checks `comms research planning dev`) would have reported gq
clean. The sweep never looked for `.claude`.

## House style for repo-hygiene guards

`tests/testthat/test-vignette_legend_coverage.R` is the precedent, and it
carries two hard-won lessons directly relevant here (both recorded in
`CLAUDE.md` under "A guard's escape hatches are where it goes to die"):

1. **Test for the file, never for a directory of the right name.** Its first
   version walked up looking for a `vignettes/` directory, matched an unrelated
   one in the temp tree under `R CMD check`, reported "found", then died in
   `readLines()`.
2. **An exemption list that covers every input makes the assertion
   unreachable.** Its first draft listed all nine drawn layers with the reason
   "drawn and legended" — a guard that could not go red.

Both apply to a top-level allowlist. The `ships` list must name only what gq
genuinely intends to publish, and the root must be resolved by testing for
`.Rbuildignore` itself.

## `.Rbuildignore` matching semantics

Per R-exts: patterns are Perl-like regular expressions, matched against the
file/directory paths **relative to the top-level directory**, **case-insensitively**,
and as a **partial** match rather than an anchored one. That is why every
existing pattern carries `^...$`. The guard matches with
`grepl(pat, entry, perl = TRUE, ignore.case = TRUE)`.

## The `gq.Rproj` NOTE only fires under `--as-cran`

A first baseline run reported **1** NOTE, not the 2 the issue claims —
`checking top-level files ... OK`. The issue's premise looked stale.

It was not. `R CMD check` gates that check behind an environment variable that
defaults off:

```r
R_check_toplevel_files <- config_val_to_logical(
  Sys.getenv("_R_CHECK_TOPLEVEL_FILES_", "FALSE"))
```

`--as-cran` sets it, and `devtools::check()` passes `--as-cran` by default
(`cran = TRUE`), which is how the issue author saw it. A plain
`R CMD check <tarball>` does not.

`gq.Rproj` is genuinely absent from R's `known` top-level allowlist
(`tools:::.check_packages`), which is `DESCRIPTION INDEX LICEN[CS]E MD5
NAMESPACE NEWS PORTING COPYING* GPL-* BUGS ChangeLog CHANGES INSTALL README
THANKS TODO README.md NEWS.md configure* cleanup* datafiles R data demo exec
inst man po src tests vignettes build .aspell java tools noweb`. Note the
*hidden* file check has its own separate exclusion list — `.Renviron`,
`.Rprofile`, `.Rproj.user`, ... — which is why `.Rproj.user` never NOTEs but
`.claude` does.

Consequence for this issue: **the before/after NOTE comparison must be run with
`--as-cran` on both sides**, or the `gq.Rproj` NOTE is invisible in both and the
acceptance criterion cannot be evaluated.

This is the "a probe reporting a defect in long-shipped code is usually a broken
probe" rule firing in the reverse direction — a probe reporting that a *reported*
defect does not exist. Same remedy: check the instrument before writing up the
finding.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| Baseline `R CMD check` showed 1 NOTE where the issue claims 2; `checking top-level files ... OK` | `--as-cran` (or `_R_CHECK_TOPLEVEL_FILES_=TRUE`) is required for that check. `devtools::check()` sets it by default; bare `R CMD check` does not. Re-ran both sides with `--as-cran` |
