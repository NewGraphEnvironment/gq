# Review round 5 — `cb064e6` only (gq#76)

Scope as briefed: the `^\.git$` line, the `dir.exists` → `file.exists` change, and
the two comments. Nothing from rounds 1–4 marked "Verified clean" is re-opened.

**The tree moved during this review.** I started at `cb064e6` and `f00859b`
("Record the worktree .git finding and the review summary") was already HEAD by
my second command. `f00859b` touches only `planning/`, so every measurement
below is unaffected; I say so explicitly because round 4 hit the same thing.

Environment: R 4.5.2, macOS. Working tree never modified — all probes ran in the
scratchpad against a `git worktree add --detach`, a `git clone --local`, a
`git archive` extraction, and a purpose-built minimal package. Worktree removed,
`git status --porcelain` empty afterwards.

**Verdict: the fix is correct and I could not find a defect inside it.** One
coverage gap, one behaviour change worth stating, one stale number.

---

## The central claim is CORRECT — reproduced from both ends

You asked me to say plainly if you were wrong about R shipping a worktree's
`.git`. You are not wrong. I reproduced it independently of gq, with a
four-file package whose only unusual property is that `.git` is a file:

```
$ printf 'gitdir: /Users/airvine/Projects/repo/gq/.git/worktrees/secret\n' > tp/.git
$ R CMD build tp && tar tzf tp_0.0.1.tar.gz
  tp/.git                      <-- shipped
  tp/.github/ ...
$ tar xzf tp_0.0.1.tar.gz -O tp/.git
  gitdir: /Users/airvine/Projects/repo/gq/.git/worktrees/secret
```

Then the second known answer, with `^\.git$` as the *only* `.Rbuildignore` line:

```
  tp/.github/          <- survives
  tp/.github/workflows/x.yaml
  tp/DESCRIPTION  tp/inst/keep.txt  tp/LICENSE  tp/NAMESPACE  tp/R/f.R
                       <- tp/.git gone, and nothing else lost
```

The mechanism is where you said it is — `tools:::.build_packages` lines 847-849:

```r
isdir <- dir.exists(allfiles)
exclude <- exclude | (isdir & (bases %in% c("check", "chm", .vc_dir_names)))
```

`.gitignore`, `.gitattributes` and `.gitmodules` are covered separately by
`.hidden_file_exclusions`, which is **not** `isdir`-gated. `.git` is the one
version-control name that has a legitimate file form and no ungated rule, so it
is the whole of the exposure. The `.Rbuildignore` line was the right call.

---

## Findings

### 1. **[fragile]** `.Rbuildignore:9` — `^\.git$` has no guard in the layout CI actually runs, so it can be deleted and nothing will notice.

This is the only finding I would ask you to act on. The fix works; what is
missing is the alarm.

Measured, both known answers, by removing exactly that one line and re-running
`test-build_hygiene.R`:

| checkout layout | `.git` is | removing `^\.git$` |
|---|---|---|
| `git worktree add --detach` | a **file** | **1 FAILURE** — `unexplained` = `".git"` at line 220 |
| `git clone --local` (= `actions/checkout`) | a **directory** | **38 pass, 0 fail — undetected** |

In the directory layout, `.git` is auto-excluded by R's own `isdir` rule, so
`unexplained` stays empty whether or not the pattern exists. The line is dead
weight there and live protection only in a worktree.

Two things compound it. CI checks out with `actions/checkout`, which produces a
directory. And per the round-2 comment at lines 250-255, `R CMD check` always
resolves to **tarball** mode, where `.Rbuildignore` is not shipped and both
`.Rbuildignore`-reading tests skip outright. So the line that stops an absolute
developer path reaching a published tarball is pinned by nothing any automated
run executes — it survives on a human happening to work in a worktree, which is
the same "guard nobody has seen fail" shape rounds 1–4 have been closing.

The remedy is one unconditional line, because the property does not depend on
the layout — it is a fact about the pattern file, not about this checkout. In
the source-mode branch, beside the existing premise checks:

```r
# .git as a FILE (a git worktree) is NOT covered by R's isdir-gated vc rule,
# so the .Rbuildignore line is the only thing excluding it. Asserted here
# because in a .git-DIRECTORY checkout its removal is otherwise invisible.
expect_true(rbuildignore_excluded(".git", patterns))
```

Both answers verified: TRUE with the line present, FALSE with it removed,
independent of whether `.git` is a file or a directory on the running machine.
The synthetic test at line 264 cannot substitute — it passes `isdir = TRUE` for
`.git` and asserts the `auto` path, which is the branch that is already safe.

### 2. **[minor]** `tests/testthat/test-build_hygiene.R:456` — `file.exists` converts a dangling worktree pointer from *skip* to *fail*.

Not a defect, and it fails in the safe direction, but it is a real behaviour
change this commit introduces and the comment above it does not cover the case.

The comment justifies the skip as "a source tree obtained without git (a GitHub
zip) has no `.git` at all". There is a third state: a `.git` **file** whose
gitdir target does not exist. Measured, by copying the worktree and pointing its
`.git` at a nonexistent path:

```
── Failure ('test-build_hygiene.R:473'): Expected attr(out, "status") to be NULL.
   actual is an integer vector (128)
── Failure ('test-build_hygiene.R:474'): ".claude/visibility" %in% out -> FALSE
```

Under `dir.exists` this skipped. It is reachable without anything being broken
in the repo: `cp -R` or rsync of a worktree, a restored backup, the main repo
moving, and — most plausibly here — `COPY . /pkg` in a Docker build run from a
worktree checkout, which copies the pointer file into a container where the
target path does not exist.

I am filing it as *minor* and not as a bug because it is consistent with the
rule round 2 deliberately established two lines below ("a git that RAN and
reported a problem is a failure, not a skip"), and 128 is exactly that. If you
want the narrower behaviour, the two states are distinguishable — skip when
`git -C <path> rev-parse --is-inside-work-tree` fails (not a usable repo), and
keep the failure for `ls-files` returning nothing inside a repo that works.
That preserves round 2's property rather than trading it away. Doing nothing is
also defensible; the comment is then the thing to widen, since it currently
names one of the two reasons the guard skips.

### 3. **[minor]** `tests/testthat/test-build_hygiene.R:360` — the comment says "all 24"; the same commit made it 25.

`cb064e6` added the 25th pattern and, in the same diff, added
`# 0 hits per pattern across all 24)`. The commit message carries the same
number. The *measurement* is still true — I re-ran it over all 25 patterns
against all 218 shipped paths and every per-pattern count is 0 — so only the
count is stale. Flagging it because this repo's standard is that a measured
claim in a comment is checkable, and the number went stale in the commit that
wrote it.

---

## Verified clean

Recorded so a round 6 does not re-open them.

- **`^\.git$` anchoring is exact.** Tested against 18 candidate paths with R's
  own call (`grepl(p, x, perl = TRUE, ignore.case = TRUE)`). It matches `.git`
  and `.GIT` and nothing else — not `.github`, `.github/workflows/pkgdown.yaml`,
  `.gitignore`, `.gitattributes`, `.gitmodules`, `.gitkeep`, `x.git`, `git`,
  `.git/config`, `inst/.git`, `R/.git`, `inst/registry/.git`, `a/.gitignore`,
  `inst/foo/.github`.
- **`.github` is still excluded by its own line, independently.** Re-ran the
  match with `^\.git$` deleted from the pattern set: `.github` is still hit, by
  `^\.github$`. The two lines do not depend on each other in either direction.
- **`.gitignore` and `.gitattributes` are matched by *no* `.Rbuildignore` line,
  before or after.** They are excluded by `tools:::.hidden_file_exclusions`, and
  that is unchanged — so nothing about their handling moved.
- **Nothing that should ship was dropped.** Swept all 25 patterns across all 218
  real paths under the 11 `ships` entries at every depth: per-pattern hit count
  is 0 for every pattern, and the total paths hit by *any* pattern is 0. The new
  line matches 0 of them.
- **The `file.exists` case matrix is right in every case briefed.** Measured, not
  reasoned: `git archive` extraction (no `.git`) → **1 SKIP, 0 failures**;
  `git clone` (`.git` dir) → **38 pass**; `git worktree` (`.git` file) →
  **38 pass**; tarball mode → never reaches the line, short-circuited by the
  `root$mode` check at 446. A submodule's `.git` file resolves through
  `git -C` the same way a worktree's does. The only state that changed is
  finding 2.
- **No third consumer, and the second is unreachable.** Confirming round 4's
  enumeration at the level that matters for *this* pattern: `tools::pkgVignettes`
  line 31 calls `inRbuildignore` on
  `list.files(docdir, all.files = FALSE, full.names = TRUE)` reduced to
  dir-relative form — i.e. `vignettes/<name>`, one level, **no dotfiles**.
  `^\.git$` cannot match anything in that set. Repo-wide, the only other mention
  of `.Rbuildignore` is a prose comment in `data-raw/styles_vendor.R:154`.
- **No defect inside the fix.** The pattern is anchored at both ends, contains no
  metacharacter beyond the escaped dot, removes exactly one tarball entry
  (measured 1 → 0), and adds no interaction with the 24 lines around it. The
  `file.exists` change is a strict widening of a skip condition, and the widened
  set is exactly `{.git as a directory} ∪ {.git as a file}` — there is no third
  form of `.git`, so the scope is closed by enumeration rather than by
  coincidence.
- **`lintr::lint("tests/testthat/test-build_hygiene.R")` → no lints.** Guard file
  38 pass in both the clone and the worktree, matching your measured state.

---

## Convergence

**Converged on the defect-inside-the-fix class.** Neither finding 1 nor finding 2
is one: finding 1 is a *missing* assertion rather than a wrong one, and finding 2
is a stated consequence of a rule round 2 chose deliberately. Neither can let a
bad tarball through green — finding 1 fails to *notice* a regression that would
have to be introduced by hand, and finding 2 fails loud.

Confidence, with the repo's own caution that "this is terminal" has now been
wrong three times on this branch:

- **High** that the R claim is correct and the fix is the right one. Reproduced
  end to end against `R CMD build` with both known answers, on a package built
  for the purpose, plus the mechanism read out of `.build_packages` itself.
  This did not rest on reading either side alone.
- **High** on finding 1. Both answers measured by deleting the line and running
  the real test file in two real checkouts, not reasoned from the code.
- **High** that `^\.git$` has no unintended effect. The candidate set for a
  regex is enumerable and I enumerated it — 18 hand-picked adversarial paths
  plus all 218 real shipped paths, 0 hits.
- **Moderate-high** on finding 2 being minor rather than a bug. That is a
  judgement about how often a dangling worktree pointer shows up in this org's
  workflows, and the Docker case is the one I would watch.

**What would change this verdict:** evidence of a `.git` form that is neither a
directory nor a file (there is none), or a `.Rbuildignore` consumer outside
`tools` that applies patterns to a path set including top-level dotfiles. The
second is the residual round 4 left open; `pkgVignettes` is closed above, and
`devtools::build()` shells out to `R CMD build`, so it inherits the fix rather
than reimplementing it.

## Method note

Working tree never modified. Probes: a synthetic package under the scratchpad for
the `R CMD build` two-answer test; `git worktree add --detach` for the file
layout, removed with `git worktree remove --force` and `git worktree prune`;
`git clone --local` for the directory layout; `git archive HEAD | tar -x` for the
no-git layout; a `cp -R` of the worktree with its pointer broken for finding 2.
Line removals for the restore-the-bug runs were done inside those copies with
`grep -vxF`, and the resulting one-line diff was printed before each run.
`git status --porcelain` empty at the end.
