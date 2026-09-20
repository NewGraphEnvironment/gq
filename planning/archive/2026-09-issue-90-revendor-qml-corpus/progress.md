# Progress — Re-vendor inst/styles/ (#90)

## Session 2026-09-20

- Plan-mode exploration — read `data-raw/styles_vendor.R`, `test-gq_style_qml.R:167-202`,
  issue #86, and the rfp store. Phases approved by user.
- Independently reproduced every claim in #90 before touching anything: 60 files
  checked, 2 drifted, exact diffs recorded in `findings.md`.
- Created branch `90-re-vendor-inst-styles-rfp-has-repaired` off main (level with origin).
- Scaffolded PWF baseline.
- Next: Phase 1 — re-vendor.

## Session 2026-09-20 (continued)

- Phase 1 re-vendor: 60 checked, 2 drifted -> 0. `index.csv` byte-unchanged, idempotent
  across five runs.
- Phase 1b/1c: three stale restatements fixed, then the causal paragraph fixed three more
  times before being removed rather than re-attempted.
- Phase 3: #86 rewritten and retitled; rfp#307 corrected the residue before it shipped.
- Filed #92 for the mechanism across the sibling `data-raw/` scripts.
- Phase 4: NEWS 0.16.0, DESCRIPTION bumped as the final commit.
- Commits: 8d6ada5, 69f3285, 8d95de8, 21ab7b0, 2216e80, 35d97cd, a99f280, d031a79, 5d22dbe
- Next: archive, push, PR.
