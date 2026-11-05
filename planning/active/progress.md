# Progress — Move 1: vendored artifacts current and guarded (batches 1, 2) (#100)

## Session 2026-11-05

- Plan-mode exploration: peer read of rfp/rtj themes and groups work (17 items), in-memory diff of every vendored artifact against rfp v0.93.0; phases approved by user
- Gate question raised by owner: sweep rfp's backlog first? Answered no: only rfp#188 changes this move's order; the two items that depend on it were reshaped (byte-identity test stays put; the 4 tags go to rfp#188's body)
- Created branch `100-move-1-vendored-artifacts-current-and-gu` off origin/main
- Scaffolded PWF baseline from issue #100 with approved phases
- Phase 1 done: re-vendored against rfp v0.93.0, exemptions retired or rewritten, six placements adopted, layer-level guard with fixture; filed gq#105 (within-group order); #104 body gained the template-column question
- Next: Phase 2
