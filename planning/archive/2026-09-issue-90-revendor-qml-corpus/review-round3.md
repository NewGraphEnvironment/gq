# Review round 3 — #90 (`90-re-vendor-inst-styles-rfp-has-repaired`, HEAD `2216e80`)

Scope: full three-dot branch diff, every changed file read in full, plus the upstream
sources every new claim rests on. `command diff` / `cmp` / `readBin` used throughout;
no `&&` chained past a bare `grep -c`.

---

## Findings

- **[bug]** `data-raw/styles_vendor.R:209` — **"So authorship does not discriminate." is
  false, and rfp states the opposite cause in three places.** This is the fifth instance
  of the branch's class, on the same axis as round 2's, inside round 2's own fix.

- **[fragile]** `DESCRIPTION:3` vs `NEWS.md:1` — `Version: 0.15.0` while NEWS opens
  `# gq 0.16.0`. The repo's own precedent lands these in one commit (`78fd7cd` did, for
  0.15.0). If `/gh-pr-merge` step 7 is the intended home, fine; as the tree stands the two
  files disagree.

Everything else below is verification, not a finding.

---

## 1. The [bug], in full

### What the comment says

`data-raw/styles_vendor.R:205-213`:

> The cause is deliberately NOT stated. This comment used to explain the split as
> "QGIS-authored sidecars rather than lifted `<maplayer>` blocks", and that is refuted by
> rfp's own reference nodes: all nine in `inst/testdata/nodes/` are what QGIS itself
> writes, and all nine — `raster_hillshade.qml` included — open with `<flags>`. **So
> authorship does not discriminate.** … If the mechanism is ever wanted, measure it rather
> than inferring it.

### Why it is false

rfp states the cause outright, three times, in three different artifacts:

**1. `rfp/R/rfp_qgs_style_export.R:31-33`** (roxygen on `.rfp_qgs_style_src_tags()`):

```
# A shipped raster `.qml` carrying `map-layer-style-manager` as its first
# child is not evidence against this - those were exported by rfp, so they
# report this scan back rather than QGIS's opinion.
```

**2. `rfp/tests/testthat/test-rfp_qgs_style_set.R:460-462`:**

```
# Both `dem_turbo.qml` and `dem_hillshade.qml` carry `map-layer-style-manager` FIRST -
# rfp's own output under the old `order =` override, not a pre-#130 leak - and were
# refused as one …
```

**3. `rfp/inst/testdata/nodes/README.md:86-88`:**

> a shipped raster `.qml` carrying `map-layer-style-manager` as its first child is rfp
> reporting this scan back, not QGIS's opinion. The sidecar answers it: **QGIS writes no
> `noData` in a raster's style file, and that file begins at `flags`, exactly as a
> vector's does.**

And git's own copy detection supplies the other half — the file the comment names as the
counter-example is a **byte copy of a QGIS-authored sidecar**:

```
$ cd ~/Projects/repo/rfp && git log --follow --name-status --oneline \
    -- inst/extdata/styles/raster/airphoto_gray.qml
4938318c  M     inst/extdata/styles/raster/airphoto_gray.qml
11ec65fc  C100  inst/testdata/nodes/raster_gdal.qml -> inst/extdata/styles/raster/airphoto_gray.qml
```

`C100` — a 100% copy of `raster_gdal.qml`, which is one of the nine QGIS-authored nodes.
rfp's nodes README says the same in prose (`README.md:30-31`: *"rfp's shipped
`airphoto_gray.qml` carries `raster_gdal`'s renderer … so it was lifted from it"*).

So the actual partition of the four shipped rasters is authorship, cleanly:

| file | first child | authored by |
|---|---|---|
| `airphoto_gray.qml` | `flags` | QGIS (`C100` copy of `raster_gdal.qml`) |
| `habitat_lateral.qml` | `flags` | QGIS, 3.30-era asset (nodes README:65) |
| `dem_hillshade.qml` | `map-layer-style-manager` | **rfp's own export**, old `order =` override |
| `dem_turbo.qml` | `map-layer-style-manager` | **rfp's own export**, old `order =` override |

The old comment's error was **polarity** — it had the style-manager form as the
QGIS-authored one when it is the rfp-exported one. That is a smaller, fixable error than
"authorship does not discriminate," which is simply wrong.

### Why the measurement could not have shown what it was read as showing

The evidence offered is *"all nine nodes are QGIS-authored, and all nine open with
`<flags>`."* Every member of that sample has the **same value of the independent
variable**. A sample with no variation in the treatment cannot discriminate the treatment
— it is consistent with authorship discriminating perfectly (which is the truth) and
equally consistent with it not mattering at all.

To conclude "authorship does not discriminate" you need one of:
- a QGIS-authored file opening with `<map-layer-style-manager>`, or
- a non-QGIS-authored file opening with `<flags>`.

Neither was found, because neither was looked for. The control was in the same store:
`dem_hillshade.qml`, which rfp says three times is its own export.

This is `code-check.md`'s *"A fixture that cannot reach the failure mode"* arriving in a
prose claim, and its *"Restore the bug and prove the guard fires"* corollary — *before
restoring anything, ask what would have to change for the predicate to be true.* Nothing
in the nine-node corpus could ever have made it false.

### Why it costs something rather than being merely wrong

The two sentences are load-bearing in opposite directions and they compound:

1. *"authorship does not discriminate"* tells the next reader the correct answer is a dead
   end, and it is the first place anyone would look.
2. *"If the mechanism is ever wanted, measure it rather than inferring it"* sends them to
   run an experiment for something that is **documented upstream** and reachable with
   `grep -rn 'map-layer-style-manager' ~/Projects/repo/rfp/R ~/Projects/repo/rfp/tests`.

And the paragraph's framing is itself off: it opens *"The cause is deliberately NOT
stated"* and then states a cause-shaped claim. Withholding a cause and asserting a
non-cause are different acts; only the first is what the paragraph advertises.

### Smallest fix

Replace the refutation-and-withholding with the fact, cited. The polarity correction is
one clause and it is what the next reader needs:

```r
  # The two style-manager files are rfp's OWN export under an old `order =`
  # override, not QGIS's output — rfp says so in R/rfp_qgs_style_export.R (the
  # `.rfp_qgs_style_src_tags()` roxygen), in test-rfp_qgs_style_set.R ("rfp's own
  # output under the old `order =` override"), and in inst/testdata/nodes/README.md.
  # airphoto_gray is `<flags>` because it is a byte copy of the QGIS-authored
  # raster_gdal.qml node (git records the copy as C100 at 11ec65fc). So authorship
  # IS the discriminator; the comment this replaced had its polarity backwards.
```

Whatever wording is chosen, the two sentences that must go are *"So authorship does not
discriminate"* and *"measure it rather than inferring it."*

---

## 2. The mechanism behind all five instances

**The shared assumption: every claim in this block is about `rfp`, and the sweep has only
ever measured rfp's *data* — never rfp's *prose*.**

Look at what each of the eleven rows in `findings.md`'s six-axis table was settled with:
`grep -rl` over store files, `ls`/count of `inst/testdata/nodes/`, `nrow()` of an index
CSV, `Rscript -e 'rfp_raster_styles()'`, `list.files()` inside an rfp test. All of them
read rfp's **artifacts**. Not one reads rfp's README, roxygen, test comments or commit
messages.

That works for three of the six axes and structurally cannot work for the other three:

| axis | settled by | outcome in this branch |
|---|---|---|
| count | measuring data | instances 1, 3 — found and fixed |
| member list | measuring data | instance 2 — found and fixed |
| rank / superlative | measuring data | held (`grep -rl` → exactly 2) |
| **causal** | **reading the producer's own account** | instance 4 (round 2), **instance 5 (this round)** |
| **behaviour of a second system** | **reading that system** | the three "2nd system" rows were all settled by running a command, not by reading rfp |
| universal quantifier | either | held |

Instances 4 and 5 are both on the causal axis, and in both cases the response to a
data-unanswerable question was **another data measurement**. Round 2's inference
(polarity) happened to be right as a *refutation*; round 3's inference (authorship is
irrelevant) is invalid and its conclusion is false. So the class did not recur because the
sweep was narrow — round 2 widened it to all six axes — it recurred because the widened
sweep still uses one instrument, and that instrument cannot reach two of the six axes.

**The operational rule that ends it:** a causal or historical claim about `rfp` is settled
by reading rfp's own account of itself, in this order — roxygen and code comments at the
site, the test that pins the behaviour, the nearest `README.md`, then `git log -S` /
`--follow --name-status` for provenance. Re-measuring rfp's output cannot settle it,
because the output is what the claim is *about*.

A concrete, cheap version for this file: for each assertive sentence about rfp, run
`grep -rn '<the distinctive token>' ~/Projects/repo/rfp/R ~/Projects/repo/rfp/tests
~/Projects/repo/rfp/inst/**/README.md`. For `map-layer-style-manager` that returns the
three sources above in one call, and it is the call nobody made across two rounds.

### One secondary tell, already named once and still present

`findings.md:248-252` correctly identifies that the old `:199` row *"ticked a truncated
reading of its own line."* The same shape survives, benignly, in the re-run table:

- Row `:70` states the claim *"the two [slugifiers] agree on all 53 current layer names"*
  and records the measurement *"rfp index 53, gq vector rows 53"* — two counts matching,
  which is not agreement. (I checked the claim itself: `normalize_layer_name(ri$layer) ==
  ri$slug` over rfp's 53 index rows, **0 disagreements**. The claim holds; the table's
  evidence for it does not reach it.)
- Row `:55, :110` records *"neither `store_qmls()` sweep is a membership check"*, which is
  true, and the claim in the file is *"rfp's own guard walks index → file only, so a stray
  file is invisible to it."* A stray file **is** walked by both sweeps
  (`test-rfp_qgs_style_store.R:58, 74`) — just not for membership. Accurate as written, one
  reading away from not being.

Neither is a defect. Both are the instrument-matching problem again: the evidence column
records what was convenient to measure, not the proposition.

---

## 3. Is the six-axis enumeration complete? — **No.**

I re-derived every row and then enumerated the file's assertive comment claims
independently. **All eleven rows check out** (details below), but the table covers about
eleven of roughly twenty assertive claims in the file. The regexes the sweep describes
(digits, superlatives) match none of the missing ones.

### The eleven rows, re-measured independently

| row | measured this round | verdict |
|---|---|---|
| `:70` "53 current layer names" | rfp index 53 rows, 50 distinct names, `normalize_layer_name` vs `slug` → 0 disagreements | ✓ (evidence narrower than claim — §2) |
| `:97` "the 3 layers that genuinely differ" | `index.csv` override rows 3, distinct keys 3; rfp's own test pins the same 3 by name | ✓ |
| `:189` "Three today — airphoto_gray, dem_hillshade, dem_turbo" | `setdiff(stem(raster/*.qml), roster)` → exactly those 3 | ✓ |
| `:193` "`rfp_raster_styles()` serves four, fourth is `habitat_lateral`" | 4 members, `habitat_lateral` vendored | ✓ |
| `:200` "the only two files in the store" | `grep -rl '<map-layer-style-manager'` over all 66 → `dem_hillshade`, `dem_turbo` | ✓ |
| `:202` "all 66 store QMLs" | `find . -name '*.qml' \| wc -l` → **66** (51 vector + 3 overrides + 4 raster + 6 services + **2 forms**) | ✓ |
| `:202` "airphoto_gray is an ordinary `<flags>` QML" | first child = `flags` | ✓ |
| `:207` "all nine in `inst/testdata/nodes/`" | exactly 9 `.qml`, all first child `flags`, `raster_hillshade.qml` included | ✓ |
| `:209` "So authorship does not discriminate" | — | **✗ FALSE — the [bug]** |
| `:211` "`<flags>` at every revision including the one that created it" | `11ec65fc` creates it (`54389cc0`/`fff6f7c7` are rename ancestry, file ABSENT there); `flags` at `11ec65fc`, `4938318c`, HEAD | ✓ |
| `:55, :110` "rfp's guard walks index → file only" | `test-rfp_qgs_style_store.R:119-127` is index→file; :58/:74 are structural | ✓ (§2) |
| `:151` "resolve against rfp's roster" | roster read at `:169`, used at `:178` | ✓ |
| `:290` "form layers owned by `rfp_form_build()`" | exported in rfp `NAMESPACE`; rfp's store test says the same at line 41 | ✓ |
| — `orphans_known` = `vector/osm.trail.qml` | still present upstream (31 KB, tracked) | ✓ |

### Claims in the file the sweep's regexes would not match at all

Checked anyway — **all of these hold**, so they are evidence for the mechanism rather than
findings:

| line | claim | verdict |
|---|---|---|
| `:10-12` | "`expressionfields` appears in both the source and style blocks, so filtering drops the style copy too" | ✓ — rfp says the same at `test-rfp_qgs_style_store.R:65` and `test-rfp_qgs_style_set.R:485` |
| `:13` | "That was rfp#130, pinned by a QGIS-container oracle" | ✓ — rfp#130 CLOSED, *"Exported QMLs leak source binding…"*; `nodes/README.md:3-5` names `qgis/qgis:4.2` |
| `:123-127` | "`7caeeeb`, 2026-08-22, rfp#171, one day before rfp#174 gave the store an index" | ✓ — `7caeeebd 2026-08-22 (#171)`; `index.csv` added `32db2516 2026-08-23 (#174)` |
| `:127` | "Tracked as rfp#187 — drop this entry once that lands" | ✓ — rfp#187 **OPEN**, so the entry correctly stays |
| `:153-157` | "the roster lives in rfp's `data-raw`, which is `.Rbuildignore`'d" | ✓ |
| `:63-65` | "one layer name begins with a space" | ✓ |
| `:279-281` | layer names carry commas / a leading space | ✓ |
| `:3-7` | "~20 symbol properties of the up-to-73 … one symbol layer of up to five" | not re-derived; pre-existing, unchanged by this branch |

Two of those (`:10-12` causal, `:123-127` historical) are **the same two axes that produced
instances 4 and 5**, in the same file, unswept. They happen to be true. That is luck, not
coverage — and it is the argument for the ordering rule in §2 rather than for another
round.

---

## 4. Does the mechanism reach the sibling `data-raw/` scripts? — Partly. Follow-up warranted.

Sampled every population claim in the siblings against its artifact:

| script | claim | measured | verdict |
|---|---|---|---|
| `reg_extract_themes.R:22-23` | "268 rows over 9 template-theme pairs" | `themes.csv` → 268 rows, 9 pairs | ✓ |
| `reg_extract_form_types.R:13` | "13 forms for a template that ships 2" | `form_types.csv` 13 rows; `groups.csv` 2 `form_` keys | ✓ |
| `reg_extract_template_groups.R` | no numeric population claim | — | n/a |
| `reg_extract_restoration.R` | no numeric population claim | — | n/a |
| `reg_build_main.R` | source list only | — | n/a |
| `CLAUDE.md:254-257` | "50 shared vector styles / 3 overrides / 1 raster / 6 WMS" | 50 / 3 / 1 / 6 | ✓ |
| `CLAUDE.md` (groups) | "62 rows, 10 groups" | `groups.csv` → 62 / 10 | ✓ |

**So the count axis is clean repo-wide today.** The class is not currently live in the
siblings.

**The causal / second-system axis has never been swept anywhere but `styles_vendor.R`**,
and that one sweep produced a false conclusion. The siblings carry the same shape — every
one asserts rfp behaviour ("DEV-ONLY dependency", "system.file() resolves to the INSTALLED
rfp, which is routinely behind", `reg_extract_form_types.R:72` *"cannot be reproduced from
rfp's main. Only the second check sees that."*) — written by the same hand, about the same
upstream.

**Recommendation: file a follow-up. Do not widen #90.** The issue should carry:

- The **mechanism** as stated in §2, not a list of instances: a causal or historical claim
  about `rfp` is settled by reading rfp's own account, and re-measuring rfp's output cannot
  settle it. Cite this round's instance as the evidence, with the three `grep`-reachable
  sources.
- The measurement above showing the count axis is clean, so the issue is explicitly **not**
  "go recount the siblings."
- The scope: every assertive sentence about `rfp` in `data-raw/*.R` and in `CLAUDE.md`'s
  repo-relationship sections, swept once with
  `grep -rn '<token>' ~/Projects/repo/rfp/{R,tests}` per distinctive token.
- The termination condition: enumerate the sentences mechanically (parse the comment blocks,
  list them) and show each has a named upstream source or is marked as a local decision —
  not "a reviewer came back quiet."
- A note that `reg_extract_form_types.R:72` and `reg_extract_themes.R:37` are the two
  highest-value starting points, being behaviour claims about rfp's installed-vs-checkout
  divergence.

---

## 5. Breaking the test guard (`tests/testthat/test-gq_style_qml.R:62-73`)

File runs clean: **PASS 103, FAIL 0, ERROR 0, SKIP 0**.

Round 2 probed: unanticipated raster, `airphoto_gray`, dropped service, empty index. I
probed the axis it did not — **the `kind` column the guard partitions on**
(`/tmp/gq90-r3-probe.R`):

```
as shipped                                   -> PASS  (want PASS)
unanticipated raster, kind=raster            -> FAIL  (want FAIL)
unanticipated raster, MISFILED kind=vector   -> PASS  (want FAIL)   <- hole
airphoto_gray MISFILED kind=vector           -> FAIL  (want FAIL)
7th service                                  -> FAIL  (want FAIL)
habitat_lateral dropped                      -> FAIL  (want FAIL)
kind spelled 'Raster' (case)                 -> PASS  (want FAIL)   <- hole
```

Two holes. **Neither is a finding**, because neither is reachable and both are covered by
siblings in the same file:

- **Mis-`kind`ed row.** The guard is blind to a raster carried as `kind = "vector"`. Not
  reachable: `kind` is written by `styles_vendor.R`, hardcoded `"vector"` for index rows
  and derived from `dir_name` otherwise, and rfp's own exporter walks
  `maplayer[@type='vector']` so a raster cannot enter `vector/index.csv`. Such a file would
  also have to sit at `vector/<key>.qml` and pass the `<flags>`-start assertion at
  `:110`, which `dem_hillshade`/`dem_turbo` do not.
- **Unrecognised `kind` value.** Falls into neither partition, so both `expect_setequal`s
  ignore it. Caught one test earlier: `styles_rel()` (`R/gq_style_qml.R:39`) has
  `stop("Unknown kind in styles index: ", row$kind)`, which the *"every index row resolves
  to a file"* test at `:3-13` reaches.

The only thing I would soften is the comment's *"cannot be outgrown"* at `:57-58`. It is
outgrown along the `kind` axis specifically, and the sentence reads as unconditional.
Optional; nothing actionable behind it.

---

## 6. Other verification

Everything the branch claims numerically, re-measured against the final tree:

| claim | source | measured | verdict |
|---|---|---|---|
| 60 files checked, 0 drifted after | `NEWS.md` | `readBin` compare, all 60 index rows vs rfp | ✓ 60 / 0 |
| `index.csv` byte-unchanged | `NEWS.md` | `git diff origin/main...HEAD -- inst/styles/index.csv` empty | ✓ |
| 5 fields removed, each across five blocks | `NEWS.md` | 6 tag occurrences each over 5 block types (`constraint` x2) | ✓ |
| configured roster 24 → 19 | `NEWS.md` | `grep -c 'field configurationFlags'`: old 24, new 19 | ✓ |
| `previewExpression` now `species_name` | `NEWS.md` | ✓ | ✓ |
| 4 `fish_obsrvtn_pnt_distinct_id` refs remain | `findings.md` | `grep -c` → 4 | ✓ |
| `floodplains.qml` one line, `feature_name`→`floodplain_name` | diff | ✓ single-line change | ✓ |
| rfp#307 "0 dangling among the surviving 19" | `NEWS.md` | rfp#307 body: *"19 entries, 0 dangling"* | ✓ |
| `species_name` is one of the 15 unwidgeted | `findings.md` | rfp#307's 15-column list includes it | ✓ |
| "bare sidecar" = a deployment mode | `findings.md` | rfp `4938318c` body: *"`rfp_styles_apply()`, which writes a `.qml` byte-verbatim as a sidecar"*; *"rendered 99.5% white as a bare sidecar"* | ✓ |
| `4938318c` repaired the stretch, not the form | `findings.md` | commit body is entirely stretch/renderer; first child `flags` before and after | ✓ |
| both `store_qmls()` sweeps structural | `findings.md` | `test-rfp_qgs_style_store.R:53-78` — source-binding, flags-start | ✓ |

Also checked and clean:

- **Vendor script logic.** `is_form <- startsWith(gaps, "form_")` counts against the same
  `gaps` vector the message prints — one producer, so the derived split cannot disagree
  with the list beside it. `sum()` on a zero-length logical is `0L`, and the block is
  already gated on `length(gaps) > 0`, so no `character(0)` phantom.
- **`unlink(dest, recursive = TRUE)` then copy** — the write path is unchanged by this
  branch and `file.copy`'s return is checked at `:274`.
- **`tests/testthat/_problems/`** is gitignored (`.gitignore:39`) and untracked. It is not
  `.Rbuildignore`'d and `tests/` ships, so a `R CMD build` from this checkout would carry
  it — pre-existing, not introduced here, and testthat's collection is non-recursive so it
  never runs. Mentioned only so it is not re-discovered.
- **rfp checkout moved** since `findings.md` recorded it (`e63fd286` → `04282b75`). The
  byte sweep above was re-run against the *current* rfp and is still 60/0, so the
  precondition claim in `findings.md` remains true rather than merely having been true.

---

## 7. Confidence that the mechanism is exhausted — it is not, and here is the count

I am **not** claiming this class is closed, and I would not accept a fourth round returning
quiet as evidence that it is.

What I can state as a count: `data-raw/styles_vendor.R` contains **20 assertive comment
claims about state outside this repo**. Eleven are in the round-2 table; I re-derived all
eleven and found one false. I enumerated the other nine and checked eight (the ninth,
`:3-7`, predates the branch and was not re-derived). Total this round: **19 of 20 claims
independently measured, 1 false.**

The class terminates when the *instrument* changes, not when a round is quiet. Two of the
six axes — causal, and documented behaviour of a second system — cannot be settled by any
measurement of rfp's output, and every sweep so far has been exactly that. §2 states the
substitute rule; §4 recommends where it should be applied next.

---

## Errors encountered

| Error | Resolution |
|-------|------------|
| `git log --follow` listed `54389cc0` and `fff6f7c7` for `airphoto_gray.qml` | Rename/copy ancestry, not revisions of that path. `git ls-tree` per revision shows the file ABSENT at both. `findings.md`'s "`11ec65fc` creates it" is correct; `--name-status` is what shows why (`C100` from `raster_gdal.qml`) — and that is the provenance the whole causal question turned on |
| `diff` shadowed by `git diff` | `command diff` / `readBin` compare throughout, per `code-check-shell.md` |
