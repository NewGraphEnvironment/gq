# Task: `.claude` and `gq.Rproj` ship in the package tarball (#76)

## Problem

`R CMD build` ships every top-level entry not matched by `.Rbuildignore`, so
`.claude/` and `gq.Rproj` land in the tarball and therefore in the library of
anyone installing gq from GitHub.

Measured before planning, against `gq_0.13.0.tar.gz` built from `main` at
`865ebd6`:

```
$ tar tzf gq_0.13.0.tar.gz | awk -F/ '{print $2}' | sort -u
.claude          <- ships (2 entries: the dir and .claude/visibility)
build data DESCRIPTION
gq.Rproj         <- ships
inst LICENSE man NAMESPACE NEWS.md R README.md tests vignettes
```

`R CMD check` reports both as NOTEs — one for hidden files, one for
non-standard top-level files.

This is the class `CLAUDE.md` already documents, which found 20 hits across 16
repos when last swept. gq covers `planning` and `dev` but was not swept for
`.claude`. Nothing in the repo would catch the next top-level addition, so the
fix is two `.Rbuildignore` lines **plus** a guard that makes the next one fail
at `devtools::test()` rather than in someone's library.

Note: `.claude/visibility` is *tracked in git on purpose* — it tells
`claude-md-init` this is a public repo. `.Rbuildignore` removes it from the
tarball only. Do not "fix" this by gitignoring it.

## Phase 1: Write the guard, and watch it fail

Tests first — and the bug is currently live, so this doubles as the
restore-the-bug check `CLAUDE.md` requires. A guard nobody has seen fail is
decoration.

New file `tests/testthat/test-build_hygiene.R`, following the house style of
`tests/testthat/test-vignette_legend_coverage.R` (layout-aware root resolution,
a declared allowlist with reasons, and a companion test that always runs).

Every top-level entry must fall into exactly one of three categories, or the
test fails naming it:

1. **`auto_excluded`** — R CMD build's own built-in exclusions (`.git`,
   `.gitignore`, `.Rbuildignore`, `.Rproj.user`, `.DS_Store`). Cite R-exts;
   keep it to R's documented list so it does not become a dumping ground.
   Verified empirically: `.gitignore` is absent from the tarball despite having
   no `.Rbuildignore` pattern.
2. **matched by an `.Rbuildignore` pattern** — `grepl(pat, entry, perl = TRUE,
   ignore.case = TRUE)`. Partial match, not anchored, which is why the existing
   patterns all carry `^...$`.
3. **`ships`** — the declared allowlist of what gq intends to publish
   (`DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `README.md`, `LICENSE`, `R`, `data`,
   `inst`, `man`, `tests`, `vignettes`).

- [ ] Write `test-build_hygiene.R` with the three-category assertion
- [ ] Resolve the root by testing for the **`.Rbuildignore` file**, never for a
      directory of the right name — walk `..`, `../..`, `../../..`. Under
      `R CMD check` the source is at `../00_pkg_src/gq`, which is the second
      mode below
- [ ] Two modes, so the guard is not a pure skip:
      - **source tree** (`.Rbuildignore` found) → the full three-category
        assertion above
      - **unpacked tarball** (`../00_pkg_src/gq` found, no `.Rbuildignore` —
        confirmed absent from the tarball) → assert the forbidden entries are
        not present. This is evidence from the artifact itself
      - neither → `skip()` with a message naming the layouts expected, so a
        skip reads as a skip
- [ ] Companion test on **synthetic** input that runs unconditionally: feed the
      matcher a fake top-level listing plus a fake `.Rbuildignore` and assert it
      reports the unexplained entry. Without this, a skip leaves the logic
      entirely unexercised
- [ ] Assert every `ships` entry still exists — a stale allowlist entry is a
      decision nobody re-made. Do **not** assert the same of `.Rbuildignore`
      patterns: `^Rplots\.pdf$`, `^doc$`, `^Meta$` are transient build artifacts
      that legitimately do not exist
- [ ] Run `devtools::test()` and **confirm the new test FAILS**, naming
      `.claude` and `gq.Rproj`. If it passes here, the guard cannot fire and the
      rest of this plan is theatre
- [ ] Commit (test + checkbox flip)

## Phase 2: The fix

- [ ] Add `^\.claude$` and `^gq\.Rproj$` to `.Rbuildignore`
- [ ] `devtools::test()` — the guard from Phase 1 now passes
- [ ] `/code-check` on the staged diff
- [ ] Commit (fix + checkbox flip)

## Phase 3: Verify against the artifacts, not the config

The `.Rbuildignore` regex is easy to get subtly wrong, so neither of these is
optional and neither substitutes for the other.

- [ ] Tarball: `R CMD build . && tar tzf gq_*.tar.gz | grep -cE '^gq/(\.claude|gq\.Rproj)'` → **0**
- [ ] `R CMD check`: capture the NOTE count **before and after** and report both
      numbers. Expect a drop of 2. Baseline taken against the `main` tarball
      (`865ebd6`), so the comparison is measured rather than recalled
- [ ] Full `devtools::test()` green (suite is ~1050 tests; the count drifts, so
      compare against a run on `main`, not against a remembered number)
- [ ] Commit any fallout + checkbox flip

## Phase 4: Close-out

- [ ] File follow-up issues for the two out-of-scope warnings the issue names:
      non-ASCII in `R/gq_qgs_extract.R` / `R/gq_reg.R`, and the undocumented
      example datasets `crossing`/`lake`/`road`/`stream`/`watershed`
- [ ] `NEWS.md` — judgement call at the time; this is a packaging fix with no
      user-visible API change, so probably no entry. Decide, don't drift
- [ ] `/planning-archive`, then `/gh-pr-push`

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
