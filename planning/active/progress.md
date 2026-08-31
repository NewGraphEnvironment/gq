# Progress — `.claude` and `gq.Rproj` ship in the package tarball (#76)

## Session 2026-08-30

- Plan-mode exploration — phases approved by user
- Created branch `76-claude-and-gq-rproj-ship-in-the-packag` off main (`865ebd6`)
- Measured the defect against the artifact before planning: both `.claude/` and
  `gq.Rproj` confirmed present in `gq_0.13.0.tar.gz` built from main
- Established that `.Rbuildignore` is not shipped in the tarball, which is what
  lets the guard discriminate source tree from unpacked tarball without guessing
- First `R CMD check` baseline was measured with the wrong flags and appeared to
  contradict the issue; corrected to `--as-cran` (see `findings.md`)
- Scaffolded PWF baseline from issue #76 with approved phases
- Next: Phase 1 — write the guard and confirm it fails on the live bug
