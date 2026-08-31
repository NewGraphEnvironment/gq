# Progress — `.claude` and `gq.Rproj` ship in the package tarball (#76)

## Session 2026-08-30 / 2026-08-31

- Plan-mode exploration — phases approved by user
- Created branch `76-claude-and-gq-rproj-ship-in-the-packag` off main (`865ebd6`)
- Measured the defect against the artifact before planning: both `.claude/` and
  `gq.Rproj` confirmed present in `gq_0.13.0.tar.gz` built from main
- Established that `.Rbuildignore` is not shipped in the tarball, which is what
  lets the guard discriminate source tree from unpacked tarball without guessing
- First `R CMD check` baseline was measured with the wrong flags and appeared to
  contradict the issue; corrected to `--as-cran` (see `findings.md`)

### Phase 1 — the guard (`31dacbf`)

- Probed `tools:::.build_packages` and found R applies **three** exclusion
  mechanisms, not one; pinned the guard to R's own objects rather than
  transcribing them
- Confirmed the guard **fails on the live bug**: `FAIL 1 | PASS 20`, naming
  `.claude` and `gq.Rproj`

### Phase 2 — the fix (`38dc736`)

- Two `.Rbuildignore` lines; guard goes green with that change and nothing else

### Review — folded in as follow-up commits (`801c9be`, `2aef601`, `1d54c39`)

Plan review and two `/code-check` rounds, spawned concurrently and not blocked
on, per `planning.md`. Findings and triage in `review-plan.md`,
`review-round1.md`, `review-round2.md`. Five real defects, each probed before
being accepted — and three of the reviewers' highest-rated findings were already
handled in code, because they were reviewing the plan text rather than the
implementation.

The two that mattered most were both **silent**:

1. The guard enforced only half its property — nothing checked that a `ships`
   entry *survives* `.Rbuildignore`. A bare `test` line drops `tests/` from the
   tarball and every assertion still passed, with `sum(ignored)` going *up*, so
   the premise checks were satisfied more comfortably by the broken tree.
2. `build_root()` searched source-first, so an in-repo `R CMD check` took source
   mode and the assertions that read the *artifact* never ran locally.

Then a defect found by re-reading my own file: the explanatory comments I had
added to `.Rbuildignore` were **live regexes**, since that file has no comment
syntax. Benign as written (measured: all compile, none match any of 226 shipped
paths) and removed anyway, with a new assertion that every line is anchored —
which is the root-cause fix for (1).

### Phase 3 — verification

- Tarball: forbidden 0; full listing diffed against known-good — 226 entries,
  none lost, none gained
- `R CMD check --as-cran`, like-for-like: `2 WARNINGs, 2 NOTEs` → `2 WARNINGs`
- Suite `FAIL 0 | PASS 1089`; the single `WARN` confirmed pre-existing on `main`
- `lintr` 0, matching the house baseline

### Phase 4

- #51 already covers both out-of-scope warnings — no duplicates filed
- Filed #80 for the vignette-guard path depth found during review
- No `NEWS.md` entry: packaging change, no user-visible API change

- Next: `/planning-archive`, then `/gh-pr-push`
