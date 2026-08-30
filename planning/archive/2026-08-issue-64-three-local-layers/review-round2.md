# Code review — round 2, gq#64 staged diff

Reviewed the staged diff (13 files) on branch `64-three-local-layers-no-registry-entry`.
Everything below was verified by running it, not by reading.

## Findings

- **[fragile]** `tests/testthat/helper-tmap_render.R:20-29` — `drawable_keys()` excludes
  *any* type outside `{polygon, line, point}`, but its premise assertion only requires
  that **at least one** such layer exist. The two are not the same claim. A layer that
  becomes non-drawable *by accident* would be silently dropped from every whole-registry
  sweep while the premise still returns green, because the raster satisfies it.

  This is reachable, not hypothetical: `gq_qgs_extract()` maps any geometry attribute it
  does not recognise to the literal string `"unknown"`
  (`R/gq_qgs_extract.R:49-54`, the `switch()` default). A future extraction that emits an
  `"unknown"`-typed layer into `reg_main.json` would be exempted from the legend sweep,
  the classified-label sweep and the recycling sweep, with no test failing. There are
  currently 0 such layers in all three shipped registry JSONs, so nothing is broken today.

  The mirror direction is the likelier one: when `tm_raster` support lands, the sweeps
  will keep excluding the raster and the new support goes uncovered — and the premise
  assertion will still pass, because the exclusion still excluded something.

  The guard proves *an* exclusion happened; it does not prove it excluded only what was
  intended. Cheap fix — assert the excluded **set**, not its non-emptiness:

  ```r
  out <- unname(keys[!is.na(types) & types %in% c("polygon", "line", "point")])
  testthat::expect_setequal(setdiff(keys, out), "habitat_lateral")
  ```

  or assert the excluded *types* are exactly `"raster"`. Either turns "something was
  filtered" into "this was filtered", which is what the comment above the function
  already claims the assertion does.

- **[fragile]** `R/gq_mapgl_style.R:139` — the new raster guard is gated on
  `!is.null(layer$type)`, so a classification-carrying layer with **no** `type` bypasses
  it and still receives a well-formed match expression — precisely the silent-wrong the
  guard exists to close. Its sibling `gq_mapgl_style()` (`R/gq_mapgl_style.R:30`) errors
  on a NULL type, so the two functions now disagree about the same input:

  ```r
  gq_mapgl_style(list(classification = ...))    # "Layer must have a 'type' field"
  gq_mapgl_classes(list(classification = ...))  # returns ["match", ["get", ...], ...]
  ```

  No registry layer can reach it (`gq_style()` and `gq_reg_custom()` both always set
  `type`, and all 57 layers in `reg_main.json` carry one — verified). But
  `gq_mapgl_classes()`'s documented signature takes a raw layer object, so a hand-built
  one is the exposed path. Dropping the `!is.null()` term and letting a missing type fail
  costs nothing: no existing test passes a typeless layer to it (checked
  `test-gq_mapgl_style.R` in full).

- **[fragile]** `CLAUDE.md:160` — "`gq_reg_main()` — load the master registry (**56
  layers**, no arguments needed)". This diff makes it 57. `CLAUDE.md` is published by
  pkgdown and the last commit before this branch (`c87fb5a`) was specifically a stale-count
  fix, so the count is treated as load-bearing here. No other doc, roxygen block, README
  or test carries a hardcoded layer count (`grep`ed for `5[0-9] layers`, `length(reg$layers)`
  — the only assertion is `expect_true(length(reg$layers) >= 50)` in `test-gq_reg.R:5`,
  which is fine).

Nothing else. No correctness, security or data-loss defect found in the three code fixes,
the registry rows or the regenerated JSON.

---

## Answers to the six specific questions

### 1. Does emptying `local_exempt` leave both assertions meaningful?

**No — the second one is now unconditionally true.** Measured:

```
offenders now: 0
assertion A  setdiff(offenders, names(local_exempt))  -> live
assertion B  setdiff(names(local_exempt), offenders)  -> length 0 for ALL offenders
```

- **Line 80** (`expect_setequal(setdiff(offenders, names(local_exempt)), character(0))`)
  is fully live and *can* fail. Proved by perturbation: dropping `source_layer` from
  `habitat_lateral` in the registry makes `offenders` = `c("habitat_lateral")` and the
  assertion goes red.
- **Line 86** (`expect_setequal(setdiff(names(local_exempt), offenders), character(0))`)
  is vacuous — `setdiff(character(0), anything)` is `character(0)` regardless of input,
  so it cannot fail for any registry.

**Verdict: acceptable, no change needed.** This is the dormant half of a paired guard
whose whole purpose is to fire when an exemption stops being necessary; with zero
exemptions there is nothing for it to check, and it becomes live again the moment anyone
adds one. It is not the dangerous shape from the conventions ("a loop over nothing
reports success") because it makes no affirmative claim the live sibling does not already
make. Worth being explicit in the comment that line 86 is dormant while the list is
empty, so a future reader does not mistake it for coverage.

The `stats::setNames(character(0), character(0))` spelling is **load-bearing and the
comment is accurate** — confirmed both halves:

```
names(character(0)) is NULL:                          TRUE
expect_setequal(setdiff(NULL, offenders), character(0)) -> try-error
```

### 2. Did `drawable_keys()` drop any previously-covered layer?

**No.** Exact counts:

| | keys covered |
|---|---|
| `reg_main.json` at HEAD (pre-diff) | 56, all `polygon`/`line`/`point` |
| `reg_main.json` now | 57 (`polygon` 27, `line` 12, `point` 17, `raster` 1) |
| `drawable_keys(reg)` now | 56 |
| excluded | `habitat_lateral`, and nothing else |

Zero layers have a NULL/NA `type`, so the `%||% NA_character_` fallback never fires and
cannot silently drop anything. The two `test-gq_tmap_style.R` sweeps that switched from
`names(...)[vapply(...)]` to `Filter(..., drawable_keys(reg))` cover the same 11
classified drawable layers as before (12 classified now, minus the raster).

Premise assertion verified against **both** answers:

```
with habitat_lateral present : PASS  (drawable 56 of 57, excluded: habitat_lateral)
with habitat_lateral removed : FAIL  ("registry contains a non-drawable layer ...")
```

### 3. Did the new `gq_tmap_style()` type check change behaviour for any existing layer?

**No.** All 57 registry layers enumerated: every one is `polygon`, `line`, `point` or the
new `raster`. For the 56 drawable ones the check is a no-op and control reaches exactly
the same branch as before.

The only behaviour deltas are:

| input | before | after |
|---|---|---|
| unhandled type, **no** classification | `stop("Unknown layer type: ...")` (switch default) | same message, raised earlier |
| unhandled type, **with** classification | `list()` — silent | `stop("Unknown layer type: ...")` |

Removing the `switch()` default is safe because the earlier check is total over the same
three values.

Note the fix is broader than raster: `gq_qgs_extract()` emits `"unknown"` for any
unrecognised geometry, so classified `"unknown"` layers were subject to the same
silent-empty hole.

### 4. Do the two new CSV rows round-trip, and does `reg_main.json` match?

**Yes, all three ways.**

- `identical(gq_reg_custom("inst/registry/reg_custom.csv")$layers$habitat_lateral,
  gq_reg_main()$layers$habitat_lateral)` → `TRUE`.
- Re-ran `data-raw/reg_build_main.R`: output **byte-identical** to the committed
  `reg_main.json` (`cmp -s`, via `command cmp` to dodge the shell-function shadowing
  trap), and `git diff` afterwards is 0 bytes — the committed JSON is the current build,
  not a stale one.
- CSV shape: 24 columns, all 21 lines the same width; the new rows put `class_label` at
  field 6 and `fill_color` at field 7, which matches the real header (the `@param path`
  roxygen list omits `class_label` — pre-existing, not introduced here).
- The quoted `""` cells in the new rows do **not** leak empty strings, because
  `gq_reg_custom()` reads with `na.strings = c("", "NA")` — confirmed the parsed entry has
  exactly `type`, `source_layer`, `classification` and each class exactly
  `color`/`opacity`/`label`.
- Values traced back to their source rather than to the issue text —
  `inst/styles/raster/habitat_lateral.qml` carries `opacity="0.4"`,
  `<paletteEntry value="1" color="#b2df8a" label="Floodplain"/>`,
  `<paletteEntry value="2" color="#9f3cca" label="Floodplain Disconnected by Railway"/>`
  and `<pixelListEntry min="1" percentTransparent="30" max="2"/>`. Every value in the CSV
  and every factual claim in the new `@section Raster layers` block checks out, including
  the 30% transparency figure and "`gq_tmap_classes()` works".
- `gq_style_qml("habitat_lateral")` resolves (`inst/styles/index.csv:2`), so the roxygen's
  "reach for `gq_style_qml()`" advice is not a dead pointer.

### 5. Any test in the diff that cannot fail?

Only `test-composition_integrity.R:86`, covered in Q1. Every other new or changed
assertion was proved failable by restoring the defect — independently re-run here, not
taken on trust, patching **both** `asNamespace("gq")` and `as.environment("package:gq")`
and printing a value that could only come from the broken version:

| bug restored | patch proved live | result |
|---|---|---|
| `classes[[r$class_value]]` (positional) | body deparse shows old form | `test-gq_reg.R` **fail = 2** — "a numeric class_value keys the class list by name" |
| type check after the classification branch | raster returns `length 0` | `test-gq_tmap_style.R` **fail = 1** — "a CLASSIFIED layer of an unhandled type errors rather than emptying" |
| `gq_mapgl_classes()` without the type guard | raster returns `"match"` expr | `test-gq_mapgl_style.R` **fail = 1** — "gq_mapgl_classes refuses a raster instead of answering" |

Worth recording: with the tmap ordering bug restored, the **pre-existing**
"gq_tmap_style errors on unknown type" test still passed — its fixture has no
classification and so structurally cannot reach the hole. The new `expect_null(fixture$classification)`
premise line beside it names exactly that, which is the right treatment.

The other new tests are also failable rather than decorative: `expect_gt(length(gq_tmap_style(poly)), 0)`
(the classified path still works for real geometry), `expect_equal(gq_mapgl_classes(vector_twin)[[1]], "match")`
(the fixture is well-formed, so the refusal is about the type), and
`expect_true(is.numeric(read.csv(csv)$class_value))` (the fixture really did come back
numeric, so it reaches the trap).

### 6. Is `%||%` available to `drawable_keys()` in the test environment?

**Yes, three ways over, no risk.**

- gq defines `%||%` unconditionally in the package namespace (`R/gq_qgs_extract.R:393`),
  plus a conditional re-definition in `R/gq_reg.R:302-303` that is a no-op on modern R.
- testthat runs test and helper files in an environment whose parent is the package
  namespace, so an internal operator resolves under `devtools::test()`, `test_local()`
  and `R CMD check` alike.
- Base R has supplied `%||%` since 4.4.0; this machine is 4.5.2
  (`exists("%||%", asNamespace("base"), inherits = FALSE)` → `TRUE`), so even a lookup
  that escaped the namespace would find it.
- Empirically: `test-gq_tmap_legend.R` (the file that calls `drawable_keys()`) runs
  **120 passing, 0 failing**.

---

## Verification run log

| check | result |
|---|---|
| full suite `devtools::test()` | `FAIL 0 \| WARN 1 \| SKIP 0 \| PASS 1037` |
| the 1 warning | `test-gq_registry_read.R:25` — pre-existing, unrelated (a jsonlite connection warning on a deliberately absent file) |
| `test-composition_integrity.R` | pass 39, fail 0 |
| `test-gq_reg.R` | pass 48, fail 0 |
| `test-gq_tmap_style.R` | pass 168, fail 0 |
| `test-gq_mapgl_style.R` | pass 26, fail 0 |
| `test-gq_tmap_legend.R` | pass 120, fail 0 |
| `devtools::document()` | no further changes — `man/` is in sync with `R/`, so the `man/gq_form_types.Rd` edit is a legitimate regeneration of a prior commit's roxygen (`R/gq_forms.R:44`), not a hand edit |
| `data-raw/reg_build_main.R` re-run | byte-identical, `git diff` 0 bytes |
| lintr, changed files vs `git show HEAD:` | every file down or equal: `gq_reg.R` 2→0, `gq_tmap_style.R` 7→5, `helper-tmap_render.R` 3→1, `gq_mapgl_style.R` 1→1, all four test files 0→0 |
| `tools::checkRd()` on both changed `.Rd` | only non-ASCII notes, matching 20 other pre-existing `man/` files; `DESCRIPTION` declares `Encoding: UTF-8` |
| working tree after all probing | unchanged (`git diff` 0 bytes) |

## Checked and clean (no finding)

- `!sty$type %in% c(...)` and `!is.null(x) && !x %in% c(...)` — precedence is correct in
  both; `%in%` binds tighter than `!`.
- `gq_style()` errors on a NULL `type` before `gq_tmap_style()`'s new check runs, so
  `sty$type` is never NULL there.
- `switch(type, line =, polygon =, point =, stop(...))` in `tm_shape_classified()` — the
  unnamed `stop()` is the default arm, correct.
- `gq_tmap_legend()` already refused a raster before this diff (`R/gq_tmap_legend.R:133-138`),
  so the two updated sweeps in `test-gq_tmap_legend.R` needed exactly the change they got.
- The `test-gq_reg.R` fixture derives its header from the shipped CSV rather than
  hand-listing columns, so it cannot rot when a column is added; `as.data.frame(check.names)`
  does not mangle any of the 24 names.
- `expect_length(tmap_classified(gq_style(raster)), 0)` reaches an internal — fine under
  both `devtools::test()` and `R CMD check`, since both parent the test env on the namespace.
- No other whole-registry sweep exists anywhere in `tests/`, `vignettes/` or `README`;
  the two remaining `names(reg$layers)[vapply(...)]` sweeps in `test-gq_tmap_style.R`
  (lines 459, 491) filter on `identical(l$type, "line")` and already exclude the raster.
- `themes.csv` already referenced `habitat_lateral` in 9 rows; adding the registry entry
  makes those joins resolve rather than breaking anything.
- Per-class `opacity` reaching the JSON but not tmap, the unread `note` column,
  `gq_reg_custom()` erroring on a CSV missing an optional column, and the absence of
  `tm_raster` — all confirmed as the stated pre-existing / deliberate tradeoffs, not
  flagged.
