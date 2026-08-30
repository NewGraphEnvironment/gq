# Review round 3 — gq#77

Scope: `tests/testthat/test-gq_groups.R` + `NEWS.md`, `main..HEAD`
(`134c089`). Suite green at the time of review: `FAIL 0 | PASS 75` for the
target file.

The round's question was convergence: rounds 1 and 2 found the same mechanism
twice — an invariant enforced by two things happening to agree. **It is present
a third time.** It is not in the place round 2 fixed; it is one level up from
it, in the origin of round 2's own hardcoded list.

---

## Findings

- **[fragile]** `tests/testthat/test-gq_groups.R:278-285` — the `opaque` list is
  pinned against `themes.csv` but never against `groups.csv`, which is where the
  set of opaque basemaps is actually defined. A fifth basemap added to
  `Base - misc` is invisible to every assertion in the guard.

  Round 2's fix asserts the premise *"of the four, `themes.csv` names only
  `esri_world_topo`"*. That closes growth **within** the four. It does not close
  growth **of** the four: `opaque` is a hand-written vector, and nothing
  compares it to `gq_groups()`.

  Restored the defect rather than reasoning about it — added
  `esri_world_imagery_firefly` to `Base - misc` (`source_type = "wms"`) and a
  `themes.csv` row switching it **on**:

  ```
  premise  intersect(themes, opaque) == "esri_world_topo" ?  TRUE
  property nrow(opaque & visible) == 0 ?                     TRUE
  topo rows == 9 ?                                           TRUE
  -> a live satellite layer switched on, guard reports:      NOTHING
  ```

  Every assertion in the test passes with an opaque satellite basemap switched
  on in a theme — the exact regression `NEWS.md:95` records as having "twice
  cost a field user a layer".

  Three things make this more than theoretical:

  1. **The set has grown before, in this repo, by exactly this amount.**
     `a579752` ("Add the four xyz basemaps to the roster (#41)") added all four
     of `esri_world_topo`, `bing_aerial`, `esri_satellite`, `google_satellite`
     to `Base - misc` in one commit, taking the group from 3 rows to 7. The
     list is not a stable fact; it is a snapshot of a group that has already
     quadrupled once.
  2. **The one backstop is documented as the thing to remove.**
     `expect_equal(nrow(df), 232L)` does catch a new roster row today. But
     `test-gq_groups.R:247-248` tells the next person those counts "move when
     rfp changes a template, and are meant to be re-pinned deliberately", and
     `:273-277` names the pending regeneration (rfp#185) at which that will
     happen. At that moment the count is re-pinned as routine growth and the
     new basemap rides through — which is the scenario the guard's own comment
     describes, one basemap out of its reach.
  3. **There is now a second copy of the same list.**
     `tests/testthat/test-template_drift.R:247-248` declares the identical four
     and uses them one-directionally
     (`expect_equal(setdiff(opaque, in_bottom), character(0))` — asserts the
     four are *in* `Base - misc`, not that they are *all of* it). Two
     hand-maintained copies of one set, neither pinned to its source, is the
     round-1 shape reproduced across files.

  `test-composition_integrity.R:95` is not a backstop either: it pins
  `groups.csv` wms keys against `index.csv` service keys — two hand-maintained
  columns witnessing each other. A new basemap added to both (the normal path)
  passes it.

  **Fix (one line, and it is round 2's own pattern applied one level up):**

  ```r
  g <- gq_groups()
  expect_setequal(opaque, g$layer_key[g$group == "Base - misc" &
                                        g$source_type == "wms"])
  ```

  Verified this discriminates: `FALSE` against the perturbed `groups.csv`,
  `TRUE` against the committed one.

- **[fragile]** `NEWS.md` 0.13.0, third bullet — *"the stub shipped in a single
  template, so a shared-only check could not have seen it"* is false. Same
  claim at `tests/testthat/test-gq_groups.R:219-221` (*"a check scoped to shared
  themes could not see either"*).

  `High Detail - Crossings` **is** one of the four shared themes, on `main` as
  well as on `HEAD`. Ran a shared-only stub check against `main`'s
  `themes.csv`:

  ```
  shared themes: High Detail - Crossings | Low Detail - Bull Trout Model |
                 Low Detail - Salmon Model | Low Detail - Steelhead Model
  shared-ONLY stub check on main data would report:
      bcrestoration_mobile / High Detail - Crossings
  agreement guard on main flags High Detail - Crossings : 27 keys
  ```

  A shared-scoped check reports the stub, and so does the agreement guard. The
  `Land Tenure` half of the sentence is correct — a restoration-only theme is
  genuinely out of reach of a shared-scoped check, and that is the real and
  sufficient justification for the all-pairs scope. The stub half is not, and
  it is the half both texts lead with.

  This matters because of what the same NEWS entry is about. The second bullet
  corrects 0.3.0 for asserting a rationale that was a defect mistaken for
  evidence, and closes with "when a registry difference is the evidence for a
  schema decision, check that it is a decision". The third bullet then justifies
  a scope decision with a claim about coverage that was not checked. The scope
  is right; the stated reason for it is wrong, and it is the reason that gets
  copied forward.

  **Fix:** drop the stub clause, keep `Land Tenure`. In NEWS: "…over every
  template-theme pair rather than only the shared ones — `Land Tenure` is
  restoration-only, so a shared-scoped check cannot reach an unshared theme at
  all." Same edit at `test-gq_groups.R:219-221`.

---

## 1. Every invariant in the file, classified

Property-enforced = the assertion holds because of what is being asserted.
Coincidence-scoped = it holds because of something in the current data that
nothing pins.

| # | line | invariant | class |
|---|---|---|---|
| 1 | 7 | `nrow(gq_groups()) > 40` (is 62) | property, loose bound |
| 2 | 16-17 | `lake` → `whse_basemapping.fwa_lakes_poly`, `polygon` | property — `lake` appears once (verified); a second row makes the vector comparison fail |
| 3 | 23-25 | `Basemap` membership | property |
| 4 | 31-34 | `Streams` pulls subgroup children | property |
| 5 | 40 | unknown group → 0 rows | property |
| 6 | 49 | `crossings_pscis_assessment` source_layer | property |
| 7 | 58-61 | every registry key is in `groups.csv` | property, one direction only; vacuous on an empty registry, but #2 fails there |
| 8 | 71-72 | both templates present | property |
| 9 | 80-82 | `group_order` sorted, `Forms`/`Crossings` present | property — the membership checks stop the sort being vacuous |
| 10 | 95-101 | `gq_template_layers` columns and membership | property |
| 11 | 106, 111-113 | unknown template empty; restoration groups | property |
| 12 | 122-124 | roster columns, `visible` logical, no NA | property |
| 13 | 129-131 | `High Detail - Crossings` present; three dead names absent | negative fixture, but **fails loud** if rfp ever ships one of the names |
| 14 | 135-138 | template filter; `Land Tenure` restoration-only | property — `unique()` of an empty filter is `character(0)`, which fails the equality, so not vacuous |
| 15 | 163-164 | `High Detail - Crossings` in both templates | property |
| 16 | 174-175 | **premise:** exactly two templates | property — round 1's fix, correct |
| 17 | 183-186 | **premise:** the shared set is the four named themes | property — stops the `for` loop passing over a shrunken set |
| 18 | 202-211 | per-theme key-set and flag agreement | property — named lookup, `NA` for one-sided keys |
| 19 | 231-238 | no all-zero pair, over all 9 pairs | property; `NA` cells (absent pairs) correctly dropped by `which()` |
| 20 | 250-251 | 232 rows, 9 pairs | property (pinned constants) |
| 21 | 257 | no duplicate `(template, theme, layer_key)` | property — and it is the premise the named lookup at #18 relies on |
| 22 | 262-263 | `Land Tenure` 26 rows / 22 visible | property |
| 23 | 285 | **premise:** of the four, only `esri_world_topo` is named | **coincidence-scoped — see finding 1.** Pins the roster against `opaque`; nothing pins `opaque` against `groups.csv` |
| 24 | 288-294 | no opaque basemap visible | scoped by #23, inherits the gap |
| 25 | 298 | `esri_world_topo` in 9 rows | property, and **entailed**: 9 rows + no dup within a pair + 9 pairs ⟹ exactly one per pair |
| 26 | 306-307 | concatenation returns more rows than one template | property, weak |
| 27 | 311 | unknown theme → 0 rows | property |
| 28 | 318-322 | every theme key exists in `groups.csv` | property, one direction; vacuous on an empty roster, pinned by #20 |
| 29 | 326-329 | `parse_visible` accepts/refuses | property |

**One member of the class remains: #23/#24.** Everything else in the file is
enforced by the property it asserts.

## 2. Is round 2's own list coincidence-scoped?

Yes — finding 1. On the "derive vs hardcode" question specifically:

**Where the four come from.** `inst/registry/groups.csv:60-63` — the rows in
group `Base - misc` with `source_type == "wms"`. Exactly those four, verified.
The group scope is load-bearing: `Web Mapping Services` also carries
`source_type == "wms"` (`fire_perimeters_current`, `frep_rip2021_mar2022`), and
those are overlays that themes may legitimately switch on. An ungrouped
`source_type == "wms"` derivation would be wrong.

**For deriving.** It closes the gap by construction — a fifth basemap is
in-scope the day it lands, which is the property wanted rather than a list that
has to be remembered. It matches how this repo already handles the same
question elsewhere: `test-composition_integrity.R:39` says outright *"The rule
is DERIVED from `source_type` rather than read off a hand-maintained set"*, and
`test-template_drift.R:224-227` derives the bottom group *"rather than a
hand-maintained set of 'groups you must not go below', so a group added
tomorrow is checked by default rather than exempt by default"*. The hardcoded
`opaque` is the odd one out in a file family that already made this call twice.

**Against deriving.** "Opaque" is a cartographic property and `groups.csv` does
not carry it. `group == "Base - misc" & source_type == "wms"` is a *proxy* —
today exact, and CLAUDE.md's own rule ("a guard that encodes the cause you
measured is a proxy for the property you want") cuts both ways here. A
translucent WMS overlay filed under `Base - misc` would enter the derived set
and produce a false failure on a theme that legitimately shows it. Deriving
also erases the declaration: the reader no longer sees *which* layers the guard
considers dangerous, and the semantic judgement moves into a filter expression.

**Recommendation: keep the hardcoded list, and pin it.** Add the
`expect_setequal` in finding 1. This is strictly better than either pure option
— the list stays a readable declaration of "these four are opaque", and the pin
makes growth of `Base - misc`'s wms membership fail *here*, naming the reason,
instead of silently narrowing the guard. If the added layer really is a
translucent overlay, the fix is to widen the pin with a stated reason, which is
a decision recorded rather than an omission. It is also exactly the pattern
round 2 introduced — assert the premise beside the assertion — applied to the
premise round 2 did not go up to.

## 3. Do the pinned counts form a consistent system?

**Consistent, yes — closed, no.**

Arithmetic checks out against the committed CSV: `High Detail - Crossings`
28+28, `Land Tenure` 26, three Low Detail themes 25×2 each = 56+26+150 = **232**
over **9** pairs. `Land Tenure` 26 rows / 22 visible confirmed.
`esri_world_topo` at 9 is entailed by the other three (#25 above), so it is a
consistency witness rather than an independent fact.

But a subset can be satisfied while the roster is wrong. Constructed and ran the
case: move `crossings_modelled` from `High Detail - Crossings` into
`Low Detail - Salmon Model`, **identically in both templates**:

```
rows232  pairs9  nodup  lt_26_22  shared_set  agreement  no_stub  topo9  opaque_off
   TRUE    TRUE   TRUE      TRUE        TRUE       TRUE     TRUE   TRUE        TRUE
```

Everything green on a roster that no longer matches the templates. The per-theme
row counts (28 / 25 / 25 / 25) are not pinned, so the *distribution* inside the
232 is unconstrained. This is the declared gq#78 gap and the file states it
honestly at `:225-227` — **not a finding**, recorded because the round asked.

**Vacuity:** checked each, none is vacuously satisfiable in place.

- `for (th in shared)` over an empty `shared` would be zero iterations and a
  silent pass — the classic empty-loop trap — but `:183-186` pins the set. Round
  1's fix, correct.
- `expect_setequal(unique(df$template), ...)` fails on an empty frame
  (`character(0)` vs two names). Not vacuous.
- `anyDuplicated()` returns `0L` on a 0-row frame — vacuous in isolation, pinned
  by the 232 in the same block.
- The stub check `tapply()`s to nothing on an empty roster and reports health —
  the file names this at `:244-245` and it is why the shape test exists. Pinned.
- `intersect(unique(df$layer_key), opaque)` would be `character(0)` on an empty
  roster and fail the setequal. Not vacuous.

## 4. NEWS.md 0.13.0 against the committed data

Counted, not read. All numeric and factual claims verified except the one in
finding 2.

| claim | check | result |
|---|---|---|
| roster recorded the theme "enumerating 28 layers and showing none" | `main:themes.csv`, bcrestoration/HDC | 28 rows, 0 visible ✓ |
| "27 rows flip to visible" | key-matched diff `main` → `HEAD` | 27 changed, all `false→true`, 0 `true→false` ✓ |
| "`esri_world_topo` stays off, as it is in `bcfishpass_mobile` too" | all 9 topo rows | `visible = false` in every one ✓ |
| "Totals are unchanged at 232 rows over 9 template-theme pairs" | both revisions | 232 / 9 on `main` and on `HEAD` ✓ |
| "`reg_main.json` and `groups.csv` are untouched" | `git diff --name-only main..HEAD` | neither appears ✓ |
| 0.3.0 quoted as "27 layers in `bcfishpass_mobile` and 0 in `bcrestoration_mobile`" | `NEWS.md:377-379` verbatim; `main` data | quote exact, both numbers right ✓ |
| "`Land Tenure` ships in one template only" | roster | restoration only ✓ |
| "the roster's shape is now pinned (232 rows, 9 pairs, no duplicate key, `Land Tenure` at 26/22)" | test + data | all four present and true ✓ |
| "the four opaque xyz basemaps in `Base - misc`" | `groups.csv:60-63` | exactly four wms rows ✓ |
| "with the set the roster currently names pinned beside it" | `test:285` | present ✓ (its own gap is finding 1) |
| "Each guard was run against a restored defect" | round-2 record + re-ran the shared-only variant | corroborated ✓ |
| "the stub shipped in a single template, so a shared-only check could not have seen it" | shared-only stub check vs `main` data | **reports the stub — claim is false** ✗ |

Nothing overstates gq#78's coverage: `NEWS.md`'s "What none of them assert is
that the roster still equals what the templates say" and `test:225-227` are both
accurate, and item 3 above confirms the gap is real and correctly described.

---

## Convergence

Round 1 (derived-set vs two hardcoded names) and round 2 (guard key list vs
roster content) were the same mechanism; this round found it a third time at
`test-gq_groups.R:278-285`, where round 2's fix stops one level short of the
list's source. That is not the pattern being applied by memory — the premise
assertion round 2 added is correct and load-bearing — but it does mean the
mechanism was not chased to its origin, and the origin has already grown by
four members once (`a579752`).

With finding 1's one-line pin applied, every invariant in the file is enforced
by the property it asserts. Recommend re-running only that guard against the
perturbation above; no further round.
