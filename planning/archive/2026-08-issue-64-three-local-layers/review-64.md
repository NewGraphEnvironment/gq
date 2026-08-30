# Plan review — gq#64

Plan agent, 2026-08-29, against `task_plan.md` + the codebase. Every finding
below was re-probed locally before being accepted; the probe output is recorded
where it decided something.

Verdict: the design is sound — forms are per-project, `groups.csv` is
per-template, so vendor the roster — but the plan as written does not land green.

## Blockers (all confirmed by probe)

### B1. Emptying `local_exempt` breaks the acceptance test

`test-composition_integrity.R:87` calls `names(local_exempt)`. Both obvious ways
of emptying it give `NULL`, and `expect_setequal()` refuses `NULL`:

```
  NULL           names()=NULL         -> ERROR: `object` must be a vector, not `NULL`.
  character(0)   names()=NULL         -> ERROR: `object` must be a vector, not `NULL`.
  setNames       names()=character(0) -> PASS
```

Fix: `stats::setNames(character(0), character(0))`, with a comment saying why.
Do **not** delete the "still needed" assertion — it is the tripwire for whoever
adds the next entry, and deleting it is what turns the block back into a backlog.

Also: the 10-line prose block at `:66-76` describes three exemptions that will be
gone. It has to go with them.

### B2. Per-class `opacity` is dead data — and `bec_zone` is already losing it

`gq_style()`'s classification branch reads `color`, `label`, `width`, `radius`,
`shape`, `dash`. Not `opacity`. Probed:

```
classification names: field, values, labels
```

So `fill_opacity` on a classified row reaches `reg_main.json` and is dropped by
the tmap translator. **This is pre-existing, not introduced here**: `bec_zone`
carries `fill_opacity 0.25` on all 15 of its rows, so every BEC zone renders at
full opacity today.

Decision: keep `fill_opacity` in the habitat_lateral rows — it is the truth from
the QML and consumers reading the registry directly do get it — and file a gq
issue for the translator gap, naming `bec_zone` as the live case.

### B3. `class_label` was missing from the plan's field list

Without it `gq_style()` falls back to `to_title(keys)`. Probed:

```
labels WITHOUT class_label:  1 | 2
labels WITH class_label:     Floodplain | Floodplain Disconnected by Railway
```

A legend reading "1 / 2" with the real labels sitting in the QML is the gq#61
failure with the answer already in hand. Both rows get `class_label`.

### B4. The restore-the-bug harness would fail for the wrong reason

A `broken` function defined in a test file has its enclosing environment set to
the test env, and `tmap_classified()` is `@noRd`. The patched copy would die with
`could not find function` rather than returning `list()` — a false green, and the
harness-is-broken failure mode named in CLAUDE.md.

Fix: `local_mocked_bindings(.package = "gq")` (auto-restores; `DESCRIPTION`
already pins testthat >= 3.2.0), and assert `length(...) == 0L` — a value that can
only come from the broken version — rather than a bare `expect_error()`.

## Gaps

### G1. Phase 4 misses half its consumers

The plan names two sweeps. Probed, there are more:

| location | what happens |
|---|---|
| `test-gq_tmap_legend.R:269`, `:297` | `stop("unsupported type: raster")` — named in plan |
| `test-gq_tmap_style.R:316` | via `helper-tmap_render.R` — named in plan |
| **`test-gq_tmap_style.R:355`** | same filter, no type restriction — **missed** |
| **`helper-tmap_render.R:154-163`** | `geom_for()` is what actually errors — **missed** |
| **`helper-tmap_render.R:146`** | `switch()` defaults to `tm_dots`, so a raster would silently become a point layer if `geom_for()` did not error first — **latent** |
| **`gq_mapgl_style()`** | errors on raster — same hole, other backend — **missed** |
| **`gq_mapgl_classes()`** | **silently succeeds**, returning `["match", ["get","value"], "1", "#b2df8a", ...]` — a `get` expression is meaningless on a raster source. This is the silent-wrong direction Phase 4 exists to close, in the backend Phase 4 forgets |

Verified safe: `test-gq_tmap_style.R:427`/`:459` (filter on `type == "line"`),
`test-gq_reg.R:5`, `test-reg_labels.R`, `test-gq_symbol.R`, `test-gq_tmap_keymap.R`,
`test-gq_groups.R:52`, `reg_build_main.R`. Vignettes and `man/` examples only
print `names(reg$layers)` — no snapshot, no sweep.

### G2. The extractor's "oracle" is non-discriminating

`paste0("form_", type)` produces `form_pscis` and `form_fiss_site` identically,
so the oracle cannot separate the correct rule from the wrong one it was written
to reject. The *test* is discriminating
(`expect_false(row$layer_key == paste0("form_", row$form_type))`); the generator
is not. Fix: assert `any(layer_key != paste0("form_", spatial$type))` before
writing.

### G3. `classes[[r$class_value]]` is positional for a numeric key

`R/gq_reg.R:114`. Works today only because `bec_zone`'s `"SBS"`/`"ESSF"` keep the
column character. Probed: an integer key assigns positionally and yields
`names(cl) == NULL`. Phase 3 publishes the numeric-class-value convention, so a
downstream CSV of all-numeric class values would hit it. One-line
`as.character()` fix plus a test.

### G4. Ordering — Phase 3 alone leaves the suite red

Adding the raster to `reg_main.json` breaks the sweeps that Phase 4 fixes, and
the sweep exclusions need the raster to exist for their premise assertions. The
two phases are one atomic unit. Merged.

### G5. Missing bookkeeping

- No `NEWS.md` entry. This adds an exported function (`gq_form_types()`) and
  changes an exported contract (`gq_tmap_style()` now errors where it returned
  `list()`).
- No version bump — as the final commit of the branch, per convention.
- `test-template_drift.R:87` cites gq#64 inside `template_group_exempt`. The
  reason stays true; only the citation goes stale. Repoint it in this PR, after
  the follow-up issue exists.

### G6. The `:90` negative fixture needs a sibling, not a premise

`expect_error(gq_tmap_style(list(type = "raster")), "Unknown")` passes because
the fixture has **no classification**, which is exactly why it never caught the
hole. What it needs is a second fixture *with* classification — `list()` today,
error after the fix. The plan's "give it its premise" was too vague to act on.

## Accepted as-is

- Removing the two form rows makes the guard pass with nothing else breaking —
  traced against the draw-order, uniqueness, group-mapping and template-union
  tests, and against `test-template_drift.R`. Confirmed.
- The layer_key derivation is right for **every** row of rfp's roster. No label
  carries a digit or trailing punctuation, so `normalize_layer_name()`'s
  first-match-only `sub("^_|_$", ...)` is never reached.
- `class_field = "value"` collides with nothing (existing values are all real
  column names). It is forced rather than chosen — `gq_reg_custom()` gates the
  classification branch on a non-NA `class_field` and a paletted raster keys on
  pixel value, so a sentinel is a schema requirement. Documented as such.
- `reg_build_main.R` is idempotent by construction — it never reads its own
  output.

## Open question the plan should answer in prose

After Phase 4, `habitat_lateral` is a registry entry every translator errors on.
That is defensible — the QML is the lossless copy and this is a QGIS-native
artifact — but it has to be written down, or the row is itself a value nothing
reads. Recorded in `findings.md`.

---

# Code review round 1 — Phase 1 staged diff

- **[fragile]** `reg_extract_form_types.R` — `dirty <- length(git("status", ...)) > 0L`
  cannot distinguish a failed command from a clean file; `stdout = TRUE` hides the
  exit status. A failure reads as "clean", and this printout is the thing the
  header says will tell you a parallel session's roster got vendored. **Fixed.**
- **[fragile]** same file — `system2()` shell-quotes the command but not the args,
  so a checkout path containing a space misreports as "not a git checkout".
  **Fixed** with `shQuote()`.
- **[bug]** `R/gq_forms.R` — the `@examples` caption "the two the shipped templates
  actually carry" sits over code that currently prints **four**, and it renders on
  pkgdown. **Fixed** — caption no longer asserts a count.
- **[fragile]** same file — the round-trip guard's comment claims it catches a lost
  leading space. It cannot: `write.csv(quote = TRUE)` preserves the space, and
  `normalize_layer_name()` trims anyway. **Fixed** — comment now says what it
  actually guards, and the check extends to the columns where quoting matters.
- **[fragile]** `test-gq_forms.R` — `expect_true(all(nzchar(f$geometry)))` cannot
  fail: `nzchar(NA)` is TRUE and the reader maps empty to NA, so both reachable
  states pass. **Fixed.**
- **[fragile]** `reg_extract_form_types.R` — the "filter matched everything"
  tripwire blames itself for what could be a legitimate upstream change. **Fixed**
  — message now names that cause.

Verified clean by the reviewer: the generator reproduces the committed CSV
byte-identically; it loads the source tree unconditionally; `has_spatial == "true"`
is a character comparison; docs in sync; every other test can fail.
