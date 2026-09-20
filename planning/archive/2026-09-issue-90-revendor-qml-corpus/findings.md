# Findings — Re-vendor inst/styles/ (#90)

## Measurements taken before any change (2026-09-20)

### Full corpus byte sweep

Walked every row of `inst/styles/index.csv`, resolving each to its store path
(`vector/<k>.qml`, `vector/overrides/<template>/<k>.qml`, `raster/<k>.qml`,
`services/<k>.qml`) and `cmp`-ing against
`~/Projects/repo/rfp/inst/extdata/styles/`:

```
DRIFT: vector/bcfishobs_fiss_fish_observations.qml
DRIFT: vector/floodplains.qml
checked 60 files, 2 drifted
```

Two, not more. This is the independent measurement — it does not go through
testthat, so it is not vulnerable to the skip that hid the problem from CI.

### `diff` is shell-aliased to `git diff` on this machine

First diff attempt returned `diff --git` headers and a line count of 1 for a
62-line drift. `code-check-shell.md` names this exactly ("A verification command
can be shadowed by a shell function or alias"). All diffs below used
`command diff`.

### `vector/floodplains.qml` — 1 line

```
534c534
<   <previewExpression>"floodplain_name"</previewExpression>   (rfp)
---
>   <previewExpression>"feature_name"</previewExpression>      (gq)
```

**Invisible to an internal-consistency check.** Both `feature_name` and
`floodplain_name` appear in the file's own `<field configurationFlags>` roster, so
the QML is self-consistent either way. Byte-identity is the only thing that catches
it. This is the evidence that #86's tier-1 check is a *complement* to byte-identity,
not a replacement.

### `vector/bcfishobs_fiss_fish_observations.qml` — 62 lines

Five dead fields removed upstream, each across five blocks (`field
configurationFlags`, `alias`, `policy`, `default`, `constraint` x2):
`fish_obsrvtn_event_id`, `wscode_ltree`, `localcode_ltree`, `waterbody_key`,
`species_id`. Plus:

```
689c749
<   <previewExpression>"species_name"</previewExpression>                  (rfp)
>   <previewExpression>"fish_obsrvtn_pnt_distinct_id"</previewExpression>  (gq)
```

### Residue remaining after the re-vendor — what #86 still covers

Grepped the **new upstream** file:

```
642:      <column hidden="0" name="fish_obsrvtn_pnt_distinct_id" .../>
676:    <field editable="1" name="fish_obsrvtn_pnt_distinct_id"/>
680:    <field labelOnTop="0" name="fish_obsrvtn_pnt_distinct_id"/>
684:    <field name="fish_obsrvtn_pnt_distinct_id" reuseLastValue="0"/>
397:    <field configurationFlags="None" name="fid">
411:    <field configurationFlags="None" name="linear_feature_id">
```

`fish_obsrvtn_pnt_distinct_id` is referenced in 4 tags and is **absent from the
file's own field roster** — so #86's tier-1 internal-consistency check still fires
on this file after the re-vendor. `fid` and `linear_feature_id` remain in the
roster (2 of the 7 dead fields #86 named).

So re-vendoring resolves #86 **partially**. It does not close it.

### Index rosters already agree

53 vector rows on each side, empty set difference both ways. `inst/styles/index.csv`
is therefore expected byte-unchanged by the re-vendor — asserted in Phase 2 rather
than assumed.

## Peer-repo precondition

`~/Projects/repo/rfp` is on branch `335-templates-become-build-output-flip-the-s`,
`v0.76.0-6-ge63fd286`, level with origin, with uncommitted work in
`.github/workflows/`, `CLAUDE.md`, `data-raw/qgs/*.R` and a test file — **none under
the two paths the vendor script reads**:

```
git diff --stat origin/main...HEAD -- inst/extdata/styles data-raw/qgs/roster   -> empty
git status --porcelain      -- inst/extdata/styles data-raw/qgs/roster          -> empty
```

So vendoring from the working checkout is byte-equivalent to vendoring from
`origin/main`, and no throwaway clone is needed. Re-asserted at run time. That repo
is someone's in-flight work — read only, do not tidy.

## The skip message is what found the two real defects

The plan's Phase 1 said to watch for "no new orphan/roster-gap messages". The script
emitted a **third** class instead:

```
skipping raster style(s) no template uses: airphoto_gray, dem_hillshade, dem_turbo
```

Three names where the script's own comment named two. Chasing that produced both
defects below — neither was in the issue, and nothing in the suite could see either.

### 1. The comment's stated reason was wrong, not just its member list

The old comment said the skipped rasters "back `rfp_raster_styles()`, whose
renderer/companion/stretch dimension gq vendors none of". Executed against rfp:

```
rfp_raster_styles() serves 4: dem_turbo, dem_hillshade, habitat_lateral, airphoto_gray
```

`habitat_lateral` is in that roster **and is vendored** — it is gq's one raster. So
membership in `rfp_raster_styles()` is not the skip rule; absence from the *template
roster* is, which is what the code actually computes (`setdiff(store files, roster)`).
The comment named a correlate and called it the cause.

Its superlative held up: `grep -rl '<map-layer-style-manager'` over the store returns
`dem_hillshade` and `dem_turbo` only, so "they alone" is still true — but only of those
two, and **only the observation, not the explanation attached to it.** See below.

### The correction round 2 found, inside this very fix

The comment explained the split as "QGIS-authored sidecars rather than lifted
`<maplayer>` blocks, which is why they alone open with `<map-layer-style-manager>`". I
kept that clause while correcting the member list around it, and added a sentence of my
own beside it. **Both halves are false**, and both are now measured:

- **The cause.** All nine QGIS-authored reference nodes in `rfp/inst/testdata/nodes/`
  open with `<flags>` — including `raster_hillshade.qml`. A QGIS-authored hillshade in
  `<flags>` form, next to a shipped `dem_hillshade.qml` in style-manager form, means
  authorship cannot be the discriminator.
- **The history, which was mine.** "`airphoto_gray` was repaired out of that form
  upstream (rfp#235 follow-up)" — it was never in that form:

  ```
  11ec65fc     <flags     (the commit that creates it)
  4938318c~1   <flags
  4938318c     <flags     (the "follow-up")
  HEAD         <flags
  ```

  `4938318c` repaired the contrast **stretch**, not the document form. rfp's phrase
  "bare sidecar" means a `.qml` applied directly to a raster file with no project — a
  *deployment mode* — and I carried the word across from its commit title with the
  meaning inverted.

### …and the repair for THAT was also wrong (round 3)

The fix above replaced the false cause with "So authorship does not discriminate" and
withheld any explanation. **That is false too**, and the reasoning behind it was invalid.

rfp documents the cause, three times:

| source | says |
|---|---|
| `R/rfp_qgs_style_export.R:31` | "those were exported by rfp, so they report this scan back rather than QGIS's opinion" |
| `test-rfp_qgs_style_set.R:460` | "rfp's own output under the old `order =` override, not a pre-#130 leak" |
| `inst/testdata/nodes/README.md:86` | QGIS "begins at `flags`, exactly as a vector's does" |

And git supplies the other half: `airphoto_gray.qml` entered rfp as **`C100` — a 100% copy
of `raster_gdal.qml`**, one of the QGIS-authored nodes. So the partition is authorship,
cleanly:

| file | first child | authored by |
|---|---|---|
| `airphoto_gray.qml` | `flags` | QGIS (C100 copy of a reference node) |
| `habitat_lateral.qml` | `flags` | QGIS |
| `dem_hillshade.qml` | `map-layer-style-manager` | **rfp's own export** |
| `dem_turbo.qml` | `map-layer-style-manager` | **rfp's own export** |

The original comment's error was **polarity** — it had the style-manager pair as the
QGIS-authored ones. My repair threw out the variable instead of flipping it.

**Why the measurement could not have shown what I read it as showing.** The evidence was
"all nine reference nodes are QGIS-authored, and all nine open with `<flags>`". Every
member of that sample has the **same value of the independent variable**. Such a sample is
equally consistent with authorship discriminating perfectly (the truth) and with it not
mattering at all. To conclude "does not discriminate" I needed a QGIS-authored file opening
with `<map-layer-style-manager>`, or a non-QGIS-authored one opening with `<flags>`.
Neither was looked for. The control was `dem_hillshade.qml`, in the store I had already
grepped.

### …and THAT repair was wrong too (round 4) — a sufficient condition stated as the cause

Attempt three said "the cause is authorship", with the polarity flipped. Round 4 falsified
it with a file **named three lines earlier in the same comment**.

| file | first child | how produced |
|---|---|---|
| `airphoto_gray.qml` | `flags` | QGIS sidecar (`11ec65fc`: "the raster_gdal.qml reference byte for byte") |
| `habitat_lateral.qml` | `flags` | **rfp lifted it out of both templates** (`54389cc0`) |
| `dem_hillshade.qml` | `map-layer-style-manager` | rfp export, old `order =` override |
| `dem_turbo.qml` | `map-layer-style-manager` | rfp export, old `order =` override |

`54389cc0`: *"habitat_lateral was already shipped, styled and paletted, inside both
templates. Lifting it out … its boundary lands on `flags`."* An **rfp-produced file opens
at `flags`**. So QGIS-authored ⟹ `flags` holds, and the converse does not — and
"airphoto_gray opens with `<flags>` **because** it IS a QGIS-authored sidecar" asserts
exactly that converse.

**The real cause is the export boundary**, and rfp states it in one sentence I had not
cited — `R/rfp_qgs_style_set.R:522`: *"rfp's own shipped raster styles carry it FIRST,
because they were exported under the old `order =` override."* Confirmed in the bytes: both
style-manager files' children run `map-layer-style-manager, flags, temporal, …` — the
`<maplayer>` tail from the point a positional scan stopped, that tag being second-to-last
in `.rfp_qgs_style_src_tags()`.

Three wrong shapes in one paragraph, each a different error:

1. **polarity backwards** — style-manager called the QGIS-authored form
2. **variable thrown out** — "authorship does not discriminate", from a sample with no
   variation in it
3. **a sufficient condition stated as the cause** — authorship implies `flags`, `flags`
   implies nothing

And round 4 caught one more thing worth keeping: attempt three **broke its own closing rule
in its own last sentence.** It cited git's `C100` copy-similarity score as provenance —
a measurement of rfp's output — where `11ec65fc` states it in words. A similarity heuristic
is not a provenance record, and the identical heuristic pointing the other way (`C077`,
`dem_hillshade → raster_gdal`) would make the QGIS reference node a copy of an rfp export
if read the same way. Now cited from the commit message.

### The mechanism behind all five

Every one of these claims is about **rfp**, and every sweep measured rfp's **data** —
`grep -rl` over the store, `ls` of the nodes directory, `nrow()` of an index,
`Rscript -e 'rfp_raster_styles()'`. Not one read rfp's **prose**.

That instrument settles three of the six axes and structurally cannot settle two:

| axis | settled by | outcome here |
|---|---|---|
| count | measuring data | instances 1, 3 — found, fixed |
| member list | measuring data | instance 2 — found, fixed |
| superlative | measuring data | held |
| **causal** | **reading the producer's own account** | instances 4 **and 5** |
| **behaviour of a second system** | **reading that system** | settled by running commands, not by reading rfp |
| universal quantifier | either | held |

So the class did not recur because the sweep was narrow — round 2 widened it to all six
axes — it recurred because the widened sweep **still used one instrument**, and that
instrument cannot reach two of the axes.

**The rule that ends it:** a causal or historical claim about rfp is settled by reading
rfp's own account of itself — roxygen at the site, the test that pins the behaviour, the
nearest README, then `git log -S` / `--follow --name-status` for provenance. Re-measuring
rfp's output cannot settle it, because the output is what the claim is *about*. One
`grep -rn '<token>' ~/Projects/repo/rfp/{R,tests}` returns all three sources above, and it
is the call nobody made across two rounds.

**The lesson is narrower than "check your claims".** A member list and a count are cheap to
verify and I did verify them. A *causal* clause reads as context rather than as an
assertion, so it never got measured — twice, in opposite directions, while every countable
thing beside it was right.

### 2. The test guard was a negative literal set, and had gone blind

```r
expect_false(any(c("dem_hillshade", "dem_turbo") %in% idx$layer_key))   # old
```

A list of *bad* members cannot see a bad member written after the list. `airphoto_gray`
arrived upstream and this guard had nothing to say. Replaced with a **positive set pin**
on the raster and service kinds — asserting what the corpus *does* hold, which cannot be
outgrown.

Proven rather than assumed (`/tmp/gq90-guard-probe.R`):

```
as shipped                        -> PASS  (want PASS)
unanticipated raster vendored     -> FAIL  (want FAIL)
airphoto_gray vendored            -> FAIL  (want FAIL)
a service dropped                 -> FAIL  (want FAIL)

OLD guard, airphoto_gray vendored -> PASS  <- the blindness, demonstrated
```

The last line is the point: the defect is not hypothetical, and the old guard passes it.

Checked the empty-input hole too, since a set assertion is exactly where one hides:

```
expect_setequal(character(0), "habitat_lateral")    -> FAIL   (good: non-vacuous)
expect_setequal(character(0), character(0))         -> PASS
expect_false(any(c("a","b") %in% character(0)))     -> PASS   (vacuous on empty)
```

The new pin cannot go vacuous on a truncated or empty `index.csv`, because the
**expected** side is a non-empty literal. The retained `expect_false` *is* vacuous on
empty — which is precisely why it is retained as a named regression beside the setequal
rather than in place of it. To be exact about the old guard: its exclusion half was
vacuous on empty, its `expect_true("habitat_lateral" %in% ...)` half was not; what it
could never do, empty or full, was notice a raster nobody had listed.

### 3. A THIRD stale restatement, 90 lines below the one I fixed

Found by review round 1, and it is the same class again:

```r
# Reported, not fatal. The 4 forms are owned by rfp_form_build() ...
```

Measured — `groups.csv` form keys at `6bf069d`, the commit that wrote the comment, vs
today:

```
then: 4  [form_edna, form_fiss_site, form_monitoring, form_pscis]
now:  2  [form_fiss_site, form_pscis]
```

The live message reports 8 gaps. A reader was told 4 of the 8 were out-of-scope forms;
the truth is **2 forms and 6 genuine gaps**. Present tense, no time qualifier, so by the
convention's own rule it is a claim that should have tracked and did not.

Fixed by **deriving** the split rather than restating it — the message now counts
`startsWith(gaps, "form_")` at run time, so it cannot drift from the file it describes:

```
groups.csv keys with no QML (8 = 2 form, out of scope; 6 genuine): ...
```

**Three instances of one class in one file.** That is the finding worth carrying: this
script's comments enumerate populations that live upstream, and every one of them is a
restatement that ages silently. Two are now derived at run time; the raster one is
pinned by a test.

### Terminating by enumeration — and the first attempt at it was too narrow

Three instances is the point at which "is that all of them?" stops being answerable by
reading, so the candidate set was enumerated mechanically. **The first sweep swept three
of the six axes** the convention names — count, member list, superlative — and declared
the class closed. Round 2 then found a **[bug] on an unswept axis, inside the fix
itself**: a causal claim and a historical claim, in the very paragraph the enumeration
had ticked.

Two ways that sweep was wrong, both worth keeping:

1. **The axes.** The convention names six — count, member list, rank/superlative, what a
   sibling assertion catches, behaviour of a second system, universal quantifier. Only a
   regex for digits and superlatives was run. "Which is why…" matches none of them.
2. **The `:199` row ticked a truncated reading of its own line.** It recorded
   *"dem_hillshade and dem_turbo alone open with `<map-layer-style-manager>`" → ✓*. True.
   The line in the file also said **why**, and that half was false. Enumerating the half
   already believed is how a ✓ lands against a false sentence — the same shape as a guard
   that cannot fail.

Re-run across all six axes, against the final tree:

| line | axis | claim | measured |
|---|---|---|---|
| :70 | count | "the two agree on all **53** current layer names" | rfp index 53, gq vector rows 53 ✓ |
| :97 | count | "the **3** layers that genuinely differ" | 3 override rows, 3 distinct keys ✓ |
| :189 | member list | "**Three** today — airphoto_gray, dem_hillshade, dem_turbo" | the run reports exactly those three ✓ |
| :193 | 2nd system | "`rfp_raster_styles()` serves **four**, fourth is `habitat_lateral`" | `dem_turbo, dem_hillshade, habitat_lateral, airphoto_gray` ✓ |
| :200 | superlative | "the only two files in the store that open with `<map-layer-style-manager>`" | `grep -rl` over all 66 returns exactly those two ✓ |
| :207 | 2nd system | "all nine nodes in `inst/testdata/nodes/` open with `<flags>`" | all nine, `raster_hillshade.qml` included ✓ |
| :55, :110 | 2nd system | "rfp's own guard walks index → file only" | both `store_qmls()` sweeps in rfp are *structural* (source-binding, flags-start); neither is a membership check ✓ |
| :151 | 2nd system | "resolve against rfp's roster" | roster read and used ✓ |
| :290 | 2nd system | "form layers are owned by `rfp_form_build()`" | exists, exported, and rfp's own test says the same ✓ |
| — | member list | `orphans_known` = `vector/osm.trail.qml` | still present upstream; the script's `stale` message correctly stayed silent on all four runs ✓ |
| old :199 | **causal** | "QGIS-authored sidecars … **which is why**" | **FALSE — removed** |
| old :201 | **historical** | "airphoto_gray was repaired out of that form" | **FALSE — removed** |

The remainder are time-qualified — "two were already getting through", and the
form/gap comment's own past-tense note about what `groups.csv` used to carry — which the
convention says are not re-pointed. (That note names the four old form keys but not the
commit; the `6bf069d` citation lives in the commit message and here, not in the file.)

What ends this is the two bottom rows being found and removed, and the axes that found
them now being in the sweep. Not a reviewer returning quiet, and explicitly not the
first enumeration, which returned quiet while being wrong.

## rfp#307 corrected my #86 re-scope — read the upstream issue before asserting

A first draft of the #86 edit reported a new finding: the repaired `previewExpression`
names `species_name`, which is **absent from the file's own 19-name field roster** (the
roster carries `species_code`, and line 689 is `species_name`'s only occurrence). True,
and I framed it as "rfp swapped one dangling reference for another".

Checking rfp#307 before filing anything upstream showed that conclusion was wrong.
rfp#307 enumerates `bcfishobs.observations` as **34 fields — 19 configured, 15 with no
widget — and `species_name` is one of the 15.** The expression resolves. A QML roster is
a *subset* of the layer's columns, so a reference can be roster-absent and perfectly
correct.

That inverts the finding into something more useful: **#86's tier-1 rule as written
("must appear in that QML's own field roster") would refuse a correct file** — and refuse
it on the very file the guard was written for, which is how a guard acquires an exemption
and becomes decoration. The rule needs "resolves against the roster, **or** is undecidable
without the table and handed to tier-2".

rfp#307 also contradicts #86's original "7 dead fields": it measured the surviving 19 as
**0 dangling**, so `fid` and `linear_feature_id` may not be dead at all. Both claims are
now recorded in #86 as an open tier-2 question rather than as a measurement.

The near-miss is the lesson: this was one `gh issue view` away from being filed upstream
as a defect in a correct repair.

## Issue context

<the #90 body, verbatim, is on the issue; the measurements above independently
reproduce every claim in it — except its "4 removed", which lists 5 names and is
5 in fact, roster 24 -> 19>

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `diff` returned `git diff` output; a 62-line drift reported as 1 line | Shell function shadowing. Use `command diff` / `cmp -s` for anything treated as evidence |
| A `&&` chain silently truncated after `grep -c` printed `0` | `grep -c` exits 1 on a zero count, so the rest of the chain never ran and a residue check looked like it had returned nothing. Assign without a fallback and normalise, or use `\|\| echo`; never chain past a bare `grep -c` |
| Reported `species_name` as a new upstream defect | It is a real column (rfp#307). Read the upstream issue before characterising an upstream repair |
