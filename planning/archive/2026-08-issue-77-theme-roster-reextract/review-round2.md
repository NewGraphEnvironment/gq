# Code review — round 2 (#77)

Reviewed: `77-re-extract-the-theme-roster-high-detail` at **`264afb2`** vs `main`.
Date: 2026-08-30. Second pass, focused on round 1's fixes (`ea901ce`) and on the
mechanism behind round 1's finding rather than on more instances of it.

All execution happened in a detached worktree under the scratchpad, since
removed. The main working tree was never written to (`git status` clean before
and after).

## Verdict

**One finding.** Round 1's fix is correct and sufficient for the hole it names —
verified by restoring the defect, not by reading. The remaining issue is a
*different* guard with the same shape, and it is the one the round-1 fix did not
generalise to: a proxy hardcoded to the single value the current data happens to
carry, under a test name and a NEWS bullet that both state the general property.

---

## Findings

- **[fragile] `tests/testthat/test-gq_groups.R:266-274`, and the claim in
  `NEWS.md:27-29`** — the guard named *"no theme turns an opaque basemap on"*
  asserts only `esri_world_topo`. `inst/registry/groups.csv` carries **four**
  opaque xyz basemaps in `Base - misc` — `esri_world_topo`, `bing_aerial`,
  `esri_satellite`, `google_satellite` — a count this repo's own changelog
  already states verbatim (`NEWS.md:89-91`: *"`Base - misc`, which holds all four
  opaque xyz basemaps"*, describing *"exactly the failure that has twice cost a
  field user a layer"*). The guard covers one of the four.

  The scope is enforced by nothing but a coincidence: the hardcoded key matches
  the only opaque basemap `themes.csv` names **today**. Nothing asserts that
  premise, so when the data grows the guard silently narrows from "one of one" to
  "one of four" with no signal. This is `code-check.md`'s *"a guard that encodes
  the cause you measured is a proxy for the property you want"* — `esri_world_topo`
  is the row gq#77 measured; "no opaque basemap is on" is the property — combined
  with *"a negative-case fixture rots when the positive set grows"*.

  **It is not hypothetical, and the repo already predicts the exact trigger.**
  `data-raw/reg_extract_themes.R:18-20` says: *"Run after the templates change,
  e.g. once rfp#185 re-saves the presets to include the other three xyz
  basemaps"*. The anticipated next regeneration adds precisely the three keys the
  guard does not cover.

  **Demonstrated, not reasoned.** Simulated that regeneration — added
  `bing_aerial` / `esri_satellite` / `google_satellite` to all 9 template-theme
  pairs with `google_satellite` **on in every one**, then re-pinned the shape
  counts the way the test comment at :246-248 explicitly instructs a maintainer to
  (`232 -> 259`, `Land Tenure` `26/22 -> 29/23`, which are the only assertions
  that fire and which read as routine roster growth):

  ```
  test-gq_groups.R   FAIL 0 | PASS 74
  full suite         FAIL 0 | WARN 1 | SKIP 0 | PASS 1055
  ```

  ```
                     false true
    bing_aerial          9    0
    esri_satellite       9    0
    esri_world_topo      9    0
    google_satellite     0    9      <- an opaque satellite raster on in every theme
  ```

  An opaque imagery basemap over every field map in the fleet, whole suite green,
  under a test literally named for that regression. The re-pin is what carries it
  through — and the re-pin is the documented, expected maintenance action, so
  nobody is being careless.

  **Why the wording matters as much as the code.** `NEWS.md:27-29` tells a reader
  the release added a guard so that *"no theme may switch an opaque basemap on"*.
  That is coverage the assertion does not have, on a package whose consumers use
  the changelog to decide what they no longer need to check themselves. The test
  name says the same thing to the next maintainer.

  Smallest honest fixes, either of which closes it:
  - Assert the premise beside the assertion (the `code-check.md` prescription):
    `expect_setequal(intersect(unique(df$layer_key), <the four keys>), "esri_world_topo")`
    — a third basemap entering the roster then fails *here*, naming the cause,
    instead of passing.
  - Or widen to the property: check all four keys, and pin that each named one is
    present in every pair so the lookup cannot go vacuous. The existing
    `expect_equal(nrow(topo), 9L)` is already the right shape for that; it just
    guards one key.

  Alternatively, if this is deliberately deferred, say so in the test comment and
  soften `NEWS.md:27-29` to name `esri_world_topo` — the branch is otherwise
  scrupulous about declaring its bounds (`:223-227`, and the NEWS paragraph on
  gq#78), and this is the one place a claim outruns the code.

---

## Round 1's fixes — verified

### Fix 1 (the pooled-guard pin) is correct, fires, and is sufficient

`tests/testthat/test-gq_groups.R:174-175`. Restored the defect it was written
for: injected a third template into `themes.csv` carrying all four shared themes,
one flag flipped.

```
Failure ('test-gq_groups.R:163:3')  unique(xing$template)  -> extra "bcthird_mobile"
Failure ('test-gq_groups.R:174:3')  unique(df$template)    -> extra "bcthird_mobile"   <- the fix
Failure ('test-gq_groups.R:250:3')  nrow(df)     335 vs 232
Failure ('test-gq_groups.R:251:3')  pairs        13  vs 9
Failure ('test-gq_groups.R:272:3')  nrow(topo)   13  vs 9
```

Control (as committed): `FAIL 0 | PASS 74`.

Asked directly: **is there a state where the pin passes and the comparison is
still wrong or vacuous?** No. The pin is `expect_setequal` on the *set*, so it
passing means exactly `{bcfishpass_mobile, bcrestoration_mobile}` are present —
no more, no fewer. `by_template` therefore has exactly those two elements,
`shared` is their intersection, and `shared` is itself pinned to four names at
:183-186. Both `a` and `b` at :189-190 are consequently non-empty for every
iteration, so the loop cannot run over nothing and cannot compare a template that
was not derived from. The derivation and the consumption now agree by assertion
rather than by accident, which is the property round 1 asked for.

Two secondary checks:

- `expect_setequal` does not abort on failure, so a third template reddens :174
  *and* the loop still runs. Both failures are reported; the pin names the cause
  first. That is the intended behaviour, not a masking problem.
- The complementary hole — a template vendored into `templates.csv` /
  `template_groups.csv` but **absent** from `themes.csv` — is invisible to this
  file (I confirmed: `test-gq_groups.R` passes 74/74 in that state, because
  `unique(df$template)` reads what `themes.csv` contains, not what gq ships).
  It is caught loudly elsewhere in the suite, so it is not a gap:
  `test-template_drift.R:104` (`expect_setequal(unique(tbl$template), templates)`),
  `test-template_drift.R:353`, and `test-composition_integrity.R:168` all fire.
  Not raised.

### Fix 2 (the comment direction) is correct

`:200-201` now names the test by title rather than by direction, and the named
test (`"the roster's shape is what the generator reports"`, :241) does assert
`anyDuplicated(...) == 0L` at :257. No remaining "above"/"below" claim in the
file is wrong.

---

## The mechanism question — where else does an invariant rest on two things agreeing?

Round 1's finding came from a derivation and a literal disagreeing about scope.
Enumerated every invariant in the changed test file against that shape:

| invariant | enforced by | verdict |
|---|---|---|
| the loop compares every template | `:174` pin + `:183` shared pin | **closed by fix 1** — both sides asserted |
| the theme set is what we think | `:174` (2 templates) + `:251` (9 pairs) + `:183` (4 shared) + `:137-138` (Land Tenure restoration-only) | **sound, and mutually determining**: 9 pairs over 2 templates with 4 shared leaves exactly 1 unshared pair, and :137-138 fixes which. Arithmetic checks: 232 = (28+25+25+25) + (28+26+25+25+25) |
| no duplicate key masks the first-wins lookup | `:257` `anyDuplicated`, asserted in a *different* `test_that` block from the lookup at :203-206 that relies on it | **acceptable** — the reliance is documented at :198-201 and both blocks always run; a break is reported either way |
| the `layer_key` set matches between templates | `:202` + the `NA`-yielding named lookup at :203-206 | **sound** — a one-sided key fails *both* `:202` and `:207`, so the theme name always reaches the reader via the `info` on the flag check. Confirmed by construction (`identical(NA, TRUE)` and `identical(NA, FALSE)` are both `FALSE`) |
| the stub guard's `zero[, "row"]` column names | `which(..., arr.ind = TRUE)` falling back to `row`/`col` because `list(df$template, df$theme)` is **unnamed** | **sound today**; naming that list (`list(template = ..., theme = ...)`) would rename the columns and error. Loud, not silent — not raised |
| **no opaque basemap is on** | a hardcoded key matching the one basemap the data currently names | **the finding above** |

Only the last one is a coincidence rather than an assertion.

---

## Factual claims — counted, not read

Every number below computed from `inst/registry/themes.csv` at `264afb2`.

| claim | location | verified |
|---|---|---|
| 232 rows | `NEWS.md:9`, `CLAUDE.md`, test `:250` | **232** ✓ |
| 9 template-theme pairs | same | **9** ✓ |
| the roster names exactly 2 templates | test `:174` | ✓ |
| `High Detail - Crossings` enumerated 28 layers, showed none | `NEWS.md:5-6` | ✓ 28 rows; pre-branch all `false` |
| 27 rows flip to visible | `NEWS.md:8` | ✓ diff is exactly **27 `+` / 27 `-`**, all in the `bcrestoration_mobile,High Detail - Crossings` block |
| `esri_world_topo` stays off, as in bcfishpass too | `NEWS.md:8-9` | ✓ 9 rows, 0 `true` |
| `reg_main.json` and `groups.csv` untouched | `NEWS.md:10` | ✓ `inst/` diff is `themes.csv` only |
| `Land Tenure` 26 rows / 22 visible | `NEWS.md:27-28`, test `:262-263` | **26 / 22** ✓ |
| `Land Tenure` is restoration-only | `README.md:93`, `CLAUDE.md:190`, `R/gq_groups.R:246-248` | ✓ 0 rows in bcfishpass |
| every shared theme agrees layer for layer | `CLAUDE.md:190-191`, `R/gq_groups.R:249-250` | ✓ all 4, zero disagreements |
| `gq_theme_layers("High Detail - Crossings")` returns 56 rather than 28 | `R/gq_groups.R:287`, `man/gq_theme_layers.Rd:25` | **56** ✓ |
| no duplicate `template,theme,layer_key` | test `:257` | ✓ `anyDuplicated` = 0 |
| gq#78 tracks the deferred live-template test | test `:227`, `NEWS.md:31-32`, archive README | ✓ |
| DESCRIPTION 0.13.0 / 2026-08-30 | `DESCRIPTION:3-4` | ✓ bumped from 0.12.0; date is today |
| **"no theme may switch an opaque basemap on"** | `NEWS.md:27-29` | ✗ **see finding** — one of four |

No stale statement of the old fact survives outside the deliberately-preserved
0.3.0 entry (`NEWS.md:373-374`) and `planning/archive/`. Swept with
`grep -rniE "shows 27\|27 layers\|0 in bcrestoration\|materially different\|carries different content"`
across `.R`, `.Rmd`, `.md`, `.Rd`, `.yml`, `.csv` — the only live hits are the
two deliberate corrections at `NEWS.md:15` and `CLAUDE.md:196-197`. Vignettes
mention no theme content at all.

---

## Honesty of the gq#78 deferral

Checked against the accepted-tradeoffs brief: the question is only whether the
code or docs claim coverage they lack.

- Test comment `:223-227` states the bound plainly — *"a cheap tripwire for ONE
  shape, the all-zero preset. A regression switching 24 of 25 layers off passes
  it"* — and names gq#78 as the real property. Accurate; I confirmed a
  24-of-25-off `Land Tenure` passes.
- `NEWS.md:31-32` — *"What none of them assert is that the roster still equals
  what the templates say; that needs a live-template test and is tracked
  separately."* Accurate.
- Archive `README.md:35-39` — accurate, and correctly identifies the stub guard
  as a proxy.
- `R/gq_groups.R:249-250` and `CLAUDE.md:190-191` say the suite reports it if a
  shared theme *moves relative to the other template*. That is what the guard
  does; both templates drifting identically is out of scope and neither sentence
  claims otherwise. Accurate.

The deferral is represented honestly throughout. The single overstatement on the
branch is the basemap sentence in the finding above, which is unrelated to gq#78.

---

## Also checked, nothing to report

- **Generated artifacts are committed, not merely generated.** `devtools::document()`
  in a clean worktree at the tip produced **no diff** (`git status` empty after).
  `NAMESPACE` unchanged; no unexpected `.Rd` written or deleted — the
  roxygen-block-rebinding trap does not apply. The one `document()` warning
  (`dash_to_lty` undocumented) is pre-existing on `main`.
- **Suite, examples, lint.** `devtools::test()` — `FAIL 0 | WARN 1 | SKIP 0 |
  PASS 1054`. **SKIP 0** matters: nothing on this branch is a snapshot or sits
  behind a skip, so the whole regression net actually runs. The one warning is
  pre-existing (`test-gq_registry_read.R:25`). `devtools::run_examples()` clean —
  the rewritten `table(xing$template, xing$visible)` example runs. `lintr` — 0 on
  both `R/gq_groups.R` and `tests/testthat/test-gq_groups.R`.
- **`.Rbuildignore` covers the new planning content.** `^planning$` is present, so
  the 6 new archive files (including two internal review documents) do not ship in
  the tarball. `planning/active/` is tracked and not gitignored —
  `git check-ignore` returns nothing, so the atomic-commit rule still holds here.
- **pkgdown exposure.** No new root-level `.md` was added, so the "every root
  markdown gets published" hazard is untouched by this branch. `CLAUDE.md` is in
  `.Rbuildignore`; the pkgdown pre-build removal and allowlist gate are
  pre-existing and unchanged.
- **`themes.csv` diff is flags only.** 27 changed lines each side, no row
  reordering, no key change, confined to one template-theme block. A regeneration
  that altered a `layer_key` *and* a flag would also be 27/27 — ruled out by
  reading the diff, which shows the same key on both sides of every pair.
- **No `CITATION.cff`** in this repo, so no stale version to regenerate.
- **`README.md:92`** says *"11 groups; 62 layer rows"* where `groups.csv` has
  **10** groups and 62 rows (`CLAUDE.md` says 10 and is right). Pre-existing on
  `main`, in the table row adjacent to one this branch edited, and already noted
  by round 1. Out of scope, recorded so it is not lost.
- **`parse_visible()` NA hole** (`R/gq_groups.R:34-49`) — pre-existing, unchanged
  by this branch, and caught downstream by `:124`. Not raised.
- Unverifiable from this repo, noted rather than flagged: *"released in rfp
  v0.47.0"* and the archive README's `FAIL 0 | PASS 27 | SKIP 0` from rfp's
  harness. `rfp` is private; both are consistent with the branch's own records.
