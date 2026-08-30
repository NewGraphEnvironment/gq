# Code review — round 1 (#77)

Reviewed: `77-re-extract-the-theme-roster-high-detail` at **`0a5a20d`** vs `main`.
Date: 2026-08-30. Reviewer: code-review subagent.

> **Note on a moving target.** The review opened against `c29c02c`. Mid-review the
> session committed `0a5a20d` ("Harden the theme guards, and book the release"),
> which independently fixed three of the four real weaknesses found. Everything
> below was re-verified against the final tip — the committed
> `tests/testthat/test-gq_groups.R` is md5 `511c3be1…`, byte-identical to the
> snapshot every restored-defect run was executed against. The main working tree
> was never written to; all execution happened in a detached worktree, since
> removed.

## Verdict

**Clean**, with one latent gap and one wrong cross-reference, both minor. Nothing
that causes a failure, security problem, or data loss on the shipped data.

---

## Findings

- **[fragile] `tests/testthat/test-gq_groups.R:167-180`** — the agreement guard
  derives `shared` from **all** templates (`Reduce(intersect, ...)` over
  `split(df, df$template)`) but compares only the two hardcoded names
  `bcfishpass_mobile` / `bcrestoration_mobile`. If a third template were added
  that carried all four shared themes, `shared` would be unchanged and the third
  template's copies would never be compared — the guard would report clean over a
  set it did not check. This is the pooled-guard shape `CLAUDE.md` records from
  gq#66 ("walking all the sources and then comparing against their union is a
  different check from comparing against each").

  Latent, and well fenced today: `expect_setequal(shared, c(<4 themes>))` at
  :172-176 and `expect_setequal(unique(xing$template), c(<2 templates>))` at
  :157-158 would both fire on most third-template shapes. It survives only the
  narrow case of a third template sharing exactly those four theme names. Raised
  because the derivation and the consumption disagree about scope, not because
  it is reachable now.

- **[nit] `tests/testthat/test-gq_groups.R:176`** — the comment reads "which is
  why the roster test **above** pins there being none". That test
  (`"the roster's shape is what the generator reports"`) is at line **230**, 89
  lines *below* the agreement test at line 141. The dependency it names is real
  and correctly asserted — only the direction is wrong. Worth fixing because the
  comment is the sole documentation of a load-bearing premise.

---

## Verified sound (the areas flagged as highest-risk)

Each of these was probed by execution, not by reading.

### 1. The `mapply` comparison — every hypothesized failure checked

| hypothesis | result |
|---|---|
| `keys` empty → `!mapply(...)` errors on `list()` | **Not a bug.** `mapply` on zero-length returns `list()` of length 0, and `!list()` returns `logical(0)` without error. Unreachable anyway: `shared` derives from themes that exist, so both sides have ≥1 row. |
| key present on one side only → `NA` mishandled | **Correct.** `va[keys]` gives `NA`; `identical(NA, TRUE)` is `FALSE`, so the key lands in `disagree` and is reported. Confirmed by defect D4. |
| `mapply` simplifies to a non-logical | **No.** `logical` for length 1 and for length *n*; only the zero-length case yields `list`, handled above. |
| duplicate `layer_key` within one pair silently masked | **Was real at `c29c02c`, fixed at `0a5a20d`.** See "Fixed in flight" below. |
| `expect_setequal` premise load-bearing and undocumented | **Now documented and asserted.** :176-178 states the first-wins reliance, and :243 pins `anyDuplicated(...) == 0L`. Matches the "assert the premise beside the assertion" convention. |

### 2. The stub test's `tapply` rewrite

`tapply(df$visible, list(df$template, df$theme), sum)` plus
`which(..., arr.ind = TRUE)` was verified end to end:

- Absent pairs (`bcfishpass_mobile` × `Land Tenure`) are `NA`, not `0`; `NA == 0`
  is `NA` and `which()` drops it — **no false stub reported**.
- `colnames(zero)` really are `row` / `col` on this matrix (`names(dimnames())`
  is `NULL`, so `arrayInd` falls back to those). Not assumed — printed.
- Empty result: `zero` is a 0×2 matrix, `rownames(m)[integer(0)]` is
  `character(0)`, and `paste(character(0), character(0), sep = " / ")` returns
  `character(0)` — **not** the phantom one-element vector the `paste0()` entry in
  `code-check.md` warns about. That trap needs a *mixed* zero/non-zero argument;
  both are zero-length here.
- Forced single stub reports exactly `"bcrestoration_mobile / Land Tenure"`.

The `" / "` separator injection concern is **eliminated** by this rewrite — there
is no pasted key left to collide. (It was also unreachable before, since template
names are a hardcoded literal vector in `data-raw/reg_extract_themes.R:28` and
contain no `/`.)

### 3. Every guard proven capable of failing

Defects restored from exact committed bytes (`git show main:…`), not
hand-reconstructions, in a throwaway worktree:

| restored defect | result |
|---|---|
| control (as committed) | `FAIL 0 \| PASS 73` |
| pre-fix roster from `main` | **FAIL 2** — agreement guard names all 27 keys; stub guard names the pair |
| `Land Tenure` forced all-false | **FAIL 2** — the unshared-theme case a shared-only loop could not reach |
| duplicate `layer_key`, conflicting flag | **FAIL 2** — (was `FAIL 0` at `c29c02c`) |
| roster truncated to 100 rows | **FAIL** — agreement guard fires on all four shared themes |
| `esri_world_topo` switched on | **FAIL 2** — basemap guard + the `Land Tenure` 26/22 pin |

No guard is decoration.

### 4. Factual claims in changed prose — all counted, all true

| claim | location | verified |
|---|---|---|
| `gq_theme_layers("High Detail - Crossings")` returns 56 rows | `R/gq_groups.R:287`, `man/gq_theme_layers.Rd` | **56** ✓ |
| 232 rows / 9 template-theme pairs | `CLAUDE.md`, `NEWS.md`, test :239-240 | **232 / 9** ✓ |
| `Land Tenure` ships in `bcrestoration_mobile` only | `R/gq_groups.R:246-247`, `README.md`, `CLAUDE.md` | ✓ (26 rows, one template) |
| `Land Tenure` at 26/22 | `NEWS.md`, test :249-250 | **26 rows, 22 visible** ✓ |
| every shared theme agrees layer for layer | `R/gq_groups.R:249-250`, `CLAUDE.md` | ✓ all 4, zero disagreements |
| `esri_world_topo` named by all 9 pairs, off in every one | test :258-262 | **9 rows, all `false`** ✓ |
| 27 rows flip to visible | `NEWS.md` | ✓ diff is 27/27 |
| 28 layers, 27 visible, both templates | — | ✓ `table()` gives 27 TRUE / 1 FALSE each side |
| `gq#78` tracks the live-template drift test | test :214 | ✓ issue exists, OPEN |

No stale statement of the old fact survives outside deliberately-preserved
history (`NEWS.md:373` in the dated 0.3.0 entry, and
`planning/archive/2026-08-issue-46-themes-roster/`) — which `findings.md`
correctly identifies as the record rather than an error.

### 5. Generated artifacts are committed, not merely generated

Ran `devtools::document()` in a clean worktree at the tip: **no diff**.
`man/gq_themes.Rd` and `man/gq_theme_layers.Rd` match what roxygen produces from
`R/gq_groups.R`, and `NAMESPACE` is unchanged. The
"Running a generator is not committing what it generated" trap does not apply.

### 6. Suite, examples, lint

- `devtools::test()` — `FAIL 0 | WARN 1 | SKIP 0 | PASS 1054`. The single warning
  is pre-existing (`test-gq_registry_read.R:25`, a jsonlite warning beside an
  `expect_error`) and unrelated to this branch.
- `devtools::run_examples()` — the changed `@examples` in both roxygen blocks
  execute cleanly.
- `lintr` — 0 on `R/gq_groups.R` and 0 on `tests/testthat/test-gq_groups.R`.
- `inst/registry/themes.csv` diff contains **only** `true`/`false` flips in the
  `bcrestoration_mobile,High Detail - Crossings` block; no row shuffle, no other
  registry artifact touched.

---

## Fixed in flight (`c29c02c` → `0a5a20d`)

Recorded because they were real, and because they would have shipped had the
branch been merged at `c29c02c`. All three are resolved at the tip; **no action
needed**.

1. **Duplicate `layer_key` masking — silent, and the worst of the three.**
   `setNames()` keeps both entries but `va[keys]` returns first-match only, and
   `expect_setequal()` ignores duplicates, so a roster carrying
   `bcrestoration_mobile,High Detail - Crossings,lake,false` *alongside* the
   `true` row passed the entire file: `FAIL 0 | PASS 66`. Contradictory shipped
   data, no signal. The generator's own duplicate guard
   (`reg_extract_themes.R:125-128`) was the only protection, and it does not run
   against the committed CSV — unlike the dangling-key guard, which the suite had
   already mirrored at :278-287. Now closed by `anyDuplicated(...) == 0L`.
2. **`paste(template, theme, sep = " / ")`** as a `tapply` key — replaced by
   `list(df$template, df$theme)`, removing the collision surface entirely.
3. **`expect_gt(length(shared), 0L)`** — would have passed having compared a
   single theme if rfp dropped three from a template. Replaced by
   `expect_setequal` on the pinned four-theme set.

---

## Not raised (checked, out of scope or not defects)

- `parse_visible()` (`R/gq_groups.R:34-49`) lets a genuinely-`NA` cell through
  (`bad <- is.na(out) & !is.na(x)` is `FALSE` for `NA` input, which `read.csv`
  produces from an empty field via `na.strings`). Caught downstream by the
  pre-existing `expect_false(any(is.na(df$visible)))` at :124. Unchanged by this
  branch.
- `CLAUDE.md` says `groups.csv` has "62 rows, 10 groups" while `README.md` says
  "11 groups; 62 layer rows". Pre-existing, neither line touched by this branch.
- The stub guard only detects the all-zero shape — a 24-of-25-off regression
  passes. This is stated plainly in the comment at :211-215 and tracked as gq#78,
  so it is a declared bound rather than an unexamined proxy.
