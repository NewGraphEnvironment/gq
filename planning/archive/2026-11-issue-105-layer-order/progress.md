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
- Plan review (Plan agent) returned: no blockers. Folded in: `info=` on the premise test,
  red output and target table recorded in findings.md, NEWS to name the basemap change.
  Full list in review-plan.md.
- Phase 2: `groups.csv` renumbered in the 7 groups. Membership and source_type unchanged;
  drift tests 19/19; full suite FAIL 0 (1696 pass).
- Phase 3: Ordering section in `gq_group_layers()` (linked from `gq_template_layers()`), CLAUDE.md groups.csv line, NEWS entry naming the Base - misc change.
- Phase 4: #104 body gains the shared order key under Batch 11 ("Also decided here"), citing the vendored witness; backlog.md batch 11 gains the same item.
- Validation: lintr 0 on touched files (branch and main). `/code-check branch`: three rounds,
  all Clean, none inside a fix. Round 1 re-derived the seven paths independently, round 2
  ran 13 mutations of the guard (all caught or covered; a tie is caught by the existing
  duplicate-order test), round 3 checked consumers in gq and rfp (no behaviour change).
  Full suite FAIL 0 | WARN 1 | SKIP 6 | PASS 1696.
