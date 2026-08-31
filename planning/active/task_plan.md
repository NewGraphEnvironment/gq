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

- [x] Write `test-build_hygiene.R` with the three-category assertion
- [x] Resolve the root by testing for the **`.Rbuildignore` file**, never for a
      directory of the right name — walk `..`, `../..`, `../../..`. Under
      `R CMD check` the source is at `../00_pkg_src/gq`, which is the second
      mode below. Also requires `DESCRIPTION` to name `gq`, so a stranger's
      tree one level up cannot satisfy it
- [x] Two modes, so the guard is not a pure skip:
      - **source tree** (`.Rbuildignore` found) → the full three-category
        assertion above
      - **unpacked tarball** (`../00_pkg_src/gq` found, no `.Rbuildignore` —
        confirmed absent from the tarball) → assert the forbidden entries are
        not present. This is evidence from the artifact itself
      - neither → `skip()` with a message naming the layouts expected, so a
        skip reads as a skip
- [x] Companion test on **synthetic** input that runs unconditionally: feed the
      matcher a fake top-level listing plus a fake `.Rbuildignore` and assert it
      reports the unexplained entry. Without this, a skip leaves the logic
      entirely unexercised
- [x] Assert every `ships` entry still exists — a stale allowlist entry is a
      decision nobody re-made. Do **not** assert the same of `.Rbuildignore`
      patterns: `^Rplots\.pdf$`, `^doc$`, `^Meta$` are transient build artifacts
      that legitimately do not exist
- [x] Run `devtools::test()` and **confirm the new test FAILS**, naming
      `.claude` and `gq.Rproj`. If it passes here, the guard cannot fire and the
      rest of this plan is theatre — **confirmed**, `FAIL 1 | PASS 20`, the one
      failure being `unexplained` = `.claude`, `gq.Rproj`
- [x] Commit (test + checkbox flip)

**Deviation from the plan, for the better.** The plan said to hardcode
`auto_excluded` as R CMD build's built-in exclusions "citing R-exts". Probing
`tools:::.build_packages` showed R applies **three** separate mechanisms, and
pinning the guard to R's own objects (`get_exclude_patterns()`,
`.vc_dir_names`, `.hidden_file_exclusions`) rather than transcribing them
avoids the coincidental-scope defect: a hardcoded `c(".git", ".gitignore")`
would have matched today's repo exactly and covered nothing new.

## Phase 2: The fix

- [x] Add `^\.claude$` and `^gq\.Rproj$` to `.Rbuildignore`
- [x] `devtools::test()` — the guard from Phase 1 now passes (`FAIL 0 | PASS 21`;
      the extra pass over Phase 1's 20 is the source-mode assertion going green)
- [x] `/code-check` on the staged diff
- [x] Commit (fix + checkbox flip)

## Phase 3: Verify against the artifacts, not the config

The `.Rbuildignore` regex is easy to get subtly wrong, so neither of these is
optional and neither substitutes for the other.

- [x] Tarball: forbidden entries → **0**. Also diffed the full listing against
      the last known-good build: **226 entries, none lost, none gained**, so the
      new patterns are provably inert rather than merely believed to be
- [x] `R CMD check`: measured like-for-like, both sides `--as-cran` with
      `_R_CHECK_CRAN_INCOMING_=FALSE` so the flaky network check cannot move the
      count. **before `2 WARNINGs, 2 NOTEs` → after `2 WARNINGs`.** Asserted the
      two specific NOTE texts rather than a count, per review — `--as-cran` adds
      a CRAN-incoming NOTE of its own that flaps. The two out-of-scope WARNINGs
      persisting on both sides is the positive control: it proves the check ran
      those sections rather than aborting
- [x] Full `devtools::test()`: **FAIL 0 | PASS 1089** (main 1058 + 31 from the
      new file). The one `WARN` is in `test-gq_registry_read.R`, untouched here
      — confirmed present on `main` in a worktree rather than assumed
- [x] `lintr`: 0, matching the house baseline (three existing test files also
      score 0, so the 2 lints an earlier draft carried were regressions rather
      than house style)
- [x] Commit any fallout + checkbox flip

**Three instrument errors during this phase, all silent, two of them
reassuring** — wrong flags, an aborted run whose grep returned 0 and read as a
pass, and a count regex that missed a check line carrying a `[4s/25s]` timing
prefix. Reconciling against the tool's own `Status:` line catches all three and
costs one command. Written up in `findings.md`.

## Phase 4: Close-out

- [x] Follow-up issues for the two out-of-scope warnings — **not filed, because
      #51 already covers both** and has since the CI workflow landed. The issue
      said "file them if they are worth fixing"; checking first avoided two
      duplicates
- [x] Filed **#80** instead, a genuinely new finding from the plan review:
      `test-vignette_legend_coverage.R` resolves `00_pkg_src` one level too
      shallow under `R CMD check`. Harmless today because a `system.file()`
      fallback catches it, but the dead branch reads as live coverage
- [x] `NEWS.md` — **no entry.** Decided, not drifted: this changes what the
      tarball contains and adds a test, with no user-visible API change, and
      gq's NEWS is written for people reading release notes rather than
      packaging internals
- [ ] `/planning-archive`, then `/gh-pr-push`

## Validation

- [ ] Tests pass
- [ ] `/code-check` clean on each commit
- [ ] PWF checkboxes match landed work
- [ ] `/planning-archive` on completion
