# Findings — Re-extract the theme roster (#77)

## Independent verification of the issue's claims

Rather than trusting the issue's "Verified" section, the post-fix roster was
computed directly from `~/Projects/repo/rfp/inst/templates/*.qgs` at rfp
**v0.47.0** (clean working tree, on `main`, level with `origin/main`) before any
plan was written.

| check | result |
|---|---|
| total rows / template-theme pairs | **232 / 9** — unchanged |
| `High Detail - Crossings` | 28 layers, **27 visible** in *both* templates |
| the one `false` row | `ESRI_World_Topo` in both (rfp#162, present-and-off) |
| shared themes | 4: High Detail - Crossings, Low Detail - {Bull Trout, Salmon, Steelhead} Model |
| shared themes agreeing | all 4 — identical `layer_key` sets, **zero** visible-flag differences |
| stub themes remaining | **none** |
| `Land Tenure` | restoration-only, 26 layers / 22 visible |

All of the issue's claims hold.

## Two gaps the issue did not name

### 1. The proposed test never stub-checks `Land Tenure`

The issue's replacement puts `expect_gt(sum(a$visible), 0L)` **inside** the
`for (t in shared)` loop. `Land Tenure` ships only in `bcrestoration_mobile`, so
it is not in `shared` and is never checked — which is precisely the shape rfp#217
had, a stub preset living in one template.

Resolved by splitting into two separately-named tests: one asserting the shared
themes agree layer-for-layer (the drift guard), one asserting no theme in *either*
template is a stub, over all 9 template-theme pairs. A failure then names its own
cause rather than one test meaning two things.

### 2. Four prose locations state the old fact

The issue says "nothing else to rebuild", which is true of the *artifacts* and not
of the *documentation*.

| location | status after the flip |
|---|---|
| `R/gq_groups.R:284-285` | "ships in both templates with **materially different content**" — flatly false |
| `R/gq_groups.R:291-294` `@examples` | comment `# the same theme differs by template` false; output changes `27 / 0` → `27 / 27`. Still runs, so nothing breaks — it just demonstrates nothing |
| `R/gq_groups.R:243-247` | "can therefore carry different content" survives as a capability claim, but loses its witness |
| `CLAUDE.md:191` | "(shows 27 layers in bcfishpass, 0 in bcrestoration)" — false |
| `README.md:93` | "because the same theme name carries different content" — no longer demonstrable |
| `man/gq_themes.Rd`, `man/gq_theme_layers.Rd` | roxygen-generated; fixed via `devtools::document()` |

Deliberately **not** touched: `NEWS.md:340-341` states the same fact in a dated
0.3.0 entry. It is a historical record of what was true at that release, and the
trail rfp#217 sits on. Same for `planning/archive/2026-08-issue-46-themes-roster/`.

Confirmed still true and left alone: `CLAUDE.md:271` and `NEWS.md:336`, both
citing 232 rows / 9 pairs.

## Why `template` stays in the key

After the fix, no shared theme differs between templates, so the original
justification loses its example. The key is still right, on two grounds:

- `Land Tenure` ships in `bcrestoration_mobile` only — a theme name is not global.
- Nothing *structurally* guarantees agreement. The templates are separate files
  that drift independently; the new agreement test is what would report it.

## Environment

- `RFP_TEMPLATE_DIR` points at `<rfp>/inst/templates` (`data-raw/reg_extract_themes.R:37`).
  The issue body writes it as `inst/lookups/../templates`, which resolves to the
  same place but reads oddly.
- Installed rfp is **0.36.0**; the checkout is **0.47.0**. Without the env var the
  script would silently regenerate from the stale installed copy — the exact trap
  the script's own comment at lines 30-36 warns about.
- `parse_visible()` (`R/gq_groups.R:34`) coerces to logical and refuses anything
  that is not literal `true`/`false`, so `sum(x$visible)` in the tests is type-safe.

## Errors Encountered

| Error | Resolution |
|-------|------------|
| A regex probe on the `.qgs` preset returned 0 layers | Attribute order is `expanded=... id=... style=... visible=...`, not `id=... visible=...`. Parsed with `ElementTree` instead of assuming attribute order. |
| A `grep -v ',false$\|,true$'` filter matched nothing it should have excluded | `\|` is a GNU BRE extension; BSD grep on macOS reads it as a literal. Used `grep -Ev ',(false\|true)$'`. Already in `code-check.md`; met it anyway. |

## The rfp checkout changed branch mid-task

Between verification and the regeneration run, `~/Projects/repo/rfp` moved from
`main` to `227-qgis-roundtrip-verification` — a parallel session sharing the one
working tree, the hazard `karpathy.md` and the worktree convention both describe.

It turned out harmless here, but only because that was **checked rather than
assumed**:

```
HEAD bb3862c on 227-qgis-roundtrip-verification
git diff --quiet origin/main HEAD -- inst/templates   -> identical
git status --porcelain -- inst/templates              -> clean
```

So `themes.csv` is reproducible from rfp `origin/main` at `da115d4`, which is
what provenance actually requires. Had the branch carried template edits, this
roster would have been generated from work nobody had merged and the commit
could not have been reproduced.

## Phase 1 verification

Beyond the counts the issue predicts, the diff was checked for what it should
*not* contain:

| assertion | result |
|---|---|
| changed lines outside `bcrestoration_mobile,High Detail - Crossings` | **0** |
| changed lines that are not a `true`/`false` flip | **0** |
| `layer_key` sets identical on the `-`/`+` sides of the flip | identical — a pure flag change, no row shuffle |
| suite state after Phase 1 | `FAIL 1 | PASS 57` in `test-gq_groups.R`, the single failure being line 149 (`27` vs `0`) — exactly the predicted one, and nothing else |

## Issue context

## Problem

`inst/registry/themes.csv` records the `High Detail - Crossings` theme as showing
**nothing** in `bcrestoration_mobile` — all 28 layer rows `visible = false`.

That is faithful to what the template said, and the template was wrong. rfp
shipped that preset as a stub: 28 layers enumerated, none visible, and no group
checked. Repaired in NewGraphEnvironment/rfp#217, released in rfp **v0.47.0**.
gq's roster is extracted from those templates, so it is now the last place
holding the old answer.

It is the most used theme in the fleet, so it is worth being right.

## Fix — two steps, ~3 minutes

**1. Re-extract the roster** from an rfp checkout at v0.47.0 or later:

```bash
RFP_TEMPLATE_DIR=/path/to/rfp/inst/lookups/../templates \
  Rscript data-raw/reg_extract_themes.R
```

(i.e. `RFP_TEMPLATE_DIR=<rfp>/inst/templates`.)

Expected: `themes.csv built: 232 rows, 9 template-theme pairs`, and a diff of
**27 insertions / 27 deletions** — every `bcrestoration_mobile,High Detail -
Crossings` row flipping to `true` **except `esri_world_topo`**, which stays
`false` in both templates (rfp#162, present-and-off).

Nothing else to rebuild — `reg_main.json` and `groups.csv` are untouched.

**2. `tests/testthat/test-gq_groups.R` needs a rewrite**, or it fails.

It currently pins the zero as a *design*:

```r
test_that("one theme name carries different content per template", {
  ...
  expect_equal(visible_by_template[["bcrestoration_mobile"]], 0)
})
```

That was describing a bug. `template` is still rightly part of the key — `Land
Tenure` is restoration-only — but the illustration has to change, because after
the fix every theme both templates carry agrees layer for layer. The replacement
asserts that, plus that no theme is a stub, which is what would catch the same
drift again:

```diff
diff --git a/tests/testthat/test-gq_groups.R b/tests/testthat/test-gq_groups.R
index e714403..d4dfb53 100644
--- a/tests/testthat/test-gq_groups.R
+++ b/tests/testthat/test-gq_groups.R
@@ -138,15 +138,37 @@ test_that("gq_themes filters by template, and Land Tenure is restoration-only",
   expect_true("Land Tenure" %in% gq_themes("bcrestoration_mobile")$theme)
 })
 
-test_that("one theme name carries different content per template", {
-  # The case the old group-granular schema could not represent, and the reason
-  # `template` is part of the key rather than a filter.
+test_that("a theme name is keyed per template, and the two now agree", {
+  # `template` is part of the key rather than a filter because a theme name is
+  # not a global key - `Land Tenure` is restoration-only, and two templates may
+  # legitimately record different content under one name.
+  #
+  # This test used to demonstrate that with `High Detail - Crossings`, whose
+  # restoration copy had every layer switched off. That was not a legitimate
+  # difference: bcrestoration shipped the preset as a STUB, enumerating 28
+  # layers and showing none of them, and rfp#217 repaired it. Pinning the zero
+  # made a defect look like a design, so the assertion is now that the shared
+  # themes agree - which is what would break if a template drifted again.
   xing <- gq_theme_layers("High Detail - Crossings")
   expect_setequal(unique(xing$template),
                   c("bcfishpass_mobile", "bcrestoration_mobile"))
-  visible_by_template <- tapply(xing$visible, xing$template, sum)
-  expect_gt(visible_by_template[["bcfishpass_mobile"]], 0)
-  expect_equal(visible_by_template[["bcrestoration_mobile"]], 0)
+
+  df <- gq_themes()
+  shared <- intersect(unique(df$theme[df$template == "bcfishpass_mobile"]),
+                      unique(df$theme[df$template == "bcrestoration_mobile"]))
+  expect_gt(length(shared), 0L)
+  for (t in shared) {
+    a <- df[df$theme == t & df$template == "bcfishpass_mobile", ]
+    b <- df[df$theme == t & df$template == "bcrestoration_mobile", ]
+    expect_setequal(a$layer_key, b$layer_key)
+    m <- merge(a[, c("layer_key", "visible")], b[, c("layer_key", "visible")],
+               by = "layer_key")
+    expect_equal(sum(m$visible.x != m$visible.y), 0L, info = t)
+    # ... and none of them is a stub. A preset showing nothing is the shape of
+    # rfp#217 and reads as a deliberate minimal variant.
+    expect_gt(sum(a$visible), 0L)
+    expect_gt(sum(b$visible), 0L)
+  }
 })
 
 test_that("gq_theme_layers without template concatenates both templates", {
```

## Verified

Both steps were run against `main` at `a238c45` with rfp at v0.47.0:

- 27 rows flip, `esri_world_topo` stays `false`
- `devtools::test()` — **1054 pass, 0 fail**

## Why this matters beyond one theme

rfp's `test-qgs_build_harness.R` cross-checks gq's roster against rfp's registry
and is red until this lands. It skips when gq is not checked out, so CI cannot
see it — this is the only signal.

Worth noting for next time: **both** registries recorded the stub faithfully,
because both derive from the same templates. A failure of that cross-check does
not mean gq is the stale side by default; check which one moved.

Relates to NewGraphEnvironment/rfp#217


## Phase 2: proving the guards can fail

`code-check.md` — a guard nobody has seen fail is decoration, and a fixture that
cannot reach the failure mode is not validation. Both new tests were run against
a restored defect:

| roster | agreement guard | stub guard | result |
|---|---|---|---|
| as regenerated (control) | pass | pass | `FAIL 0 | PASS 66` |
| pre-fix, from `HEAD~1` | **fires**, naming all 27 disagreeing keys | **fires**, naming `bcrestoration_mobile / High Detail - Crossings` | `FAIL 2 | PASS 64` |
| `Land Tenure` rows forced to `false` | pass — correct, it is not a shared theme | **fires**, naming `bcrestoration_mobile / Land Tenure` | `FAIL 1 | PASS 65` |

The third row is the whole argument for widening the stub check. `Land Tenure`
ships in one template, so the issue's `for (t in shared)` loop never evaluates it
— a stub there would have been invisible to a test written specifically to catch
stubs.

The defect was restored from `git show HEAD~1:inst/registry/themes.csv`, i.e. the
exact committed bytes, not a hand-reconstruction — a reconstruction is a different
program and tends to fail *more* tests than the real defect did.

### `merge()` was rejected for the comparison

The issue's diff joins the two templates' rows with `merge(a, b, by = "layer_key")`.
An inner join **drops a key present on only one side**, which is precisely the
drift the guard reports. `expect_setequal()` runs first and would usually catch it,
but the two assertions would then be reporting the same fact by luck of ordering.
Named-vector lookup over `union(names(va), names(vb))` compares every key on either
side, so the count cannot be quietly right.
