# Progress — Layer order within a group disagrees with the templates in 7 groups (#105)

## Session 2026-11-15

- Plan-mode exploration — phases approved by user
- Created branch `105-layer-order-within-a-group-disagrees-wit` off origin/main
- Scaffolded PWF baseline from issue #105 with approved phases
- Next: start Phase 1
- Phase 1: `order_drift()` and three tests in `test-template_drift.R`. Red on the current
  `groups.csv`, naming exactly the 7 group paths in both templates; the premise test passes
  (each of the 7 compared on 2+ layers in both). The swap alarm is red until Phase 2,
  because the real table still drifts.
