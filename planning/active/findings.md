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
two. `airphoto_gray` is an ordinary QML; rfp repaired it out of the bare-sidecar form
after rfp#235 ("`airphoto_gray` no longer renders flat as a bare sidecar", rfp NEWS).

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
