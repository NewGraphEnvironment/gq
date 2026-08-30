# gq#77 — Re-extract the theme roster

**Outcome.** `inst/registry/themes.csv` recorded `High Detail - Crossings` as
enumerating 28 layers in `bcrestoration_mobile` and showing none of them. That
was a faithful extraction of a preset rfp shipped as a stub, repaired upstream in
rfp#217 and released in rfp v0.47.0; gq was the last place holding the old
answer, on the fleet's most-used theme. The roster was regenerated from rfp
v0.47.0 (27 rows flip, `esri_world_topo` stays off, totals unchanged at 232 rows
/ 9 pairs), the test that pinned the zero **as a design** was replaced by guards
that would catch the same drift, and four prose locations that used the zero as
their justification were repointed at evidence that still exists.

Released as **0.13.0** — the change alters the meaning of a shipped `inst/`
artifact for consumers.

**What the issue asked for versus what shipped.** The issue carried a two-step
fix and a ready-made diff, and both were correct as far as they went. Three
things were added after verifying them independently rather than accepting them:

- The proposed test's stub check sat inside a `for (t in shared)` loop, so
  `Land Tenure` — restoration-only, and the exact shape rfp#217 had — was never
  evaluated by a test written to catch stubs. Widened to all 9 pairs.
- "Nothing else to rebuild" was true of the artifacts and not the documentation.
  Four prose locations and two generated `.Rd` files asserted the old fact.
- The proposed `merge(a, b, by = "layer_key")` drops a key present on one side
  only — the drift the guard exists to report is the drift that shrinks the
  comparison — and because testthat continues past a failure it would have
  printed a reassuring "no disagreement" beneath the set failure.

**The end-to-end signal.** rfp's `test-qgs_build_harness.R` cross-checks gq's
roster and was red until this landed. It skips when gq is not checked out, so
neither repo's CI can see it. Run against this branch **before** pushing:
`FAIL 0 | PASS 27 | SKIP 0` — zero skips, so the cross-check actually executed.

**Deferred.** A Plan-agent review's largest finding was that `extract_themes()`
lives in `data-raw/` and is reachable only by the generator, so themes have no
analogue of `groups.csv`'s live-template drift test. The stub guard is a proxy
for one shape of that property's violation, and says so in its own comment.
Deferred deliberately rather than dropped, and filed as **gq#78**.

**The transferable lesson**, recorded in `CLAUDE.md` and in the NEWS entry: the
zero was a defect that had been adopted as the evidence for a schema decision,
then pinned by a test, and it survived a release with the suite green throughout.
When a registry difference is the evidence for a design decision, check that it
is a decision. Both registries had recorded the stub faithfully, because both
derive from the same templates — so a failed cross-check does not mean gq is the
stale side by default.

**Commits:** `642b0dc` (re-extract), `1b1ee9b` (guards), `c29c02c` (docs),
`0a5a20d` (hardening + release).
