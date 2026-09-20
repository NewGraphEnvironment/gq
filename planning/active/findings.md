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

## Issue context

<the #90 body, verbatim, is on the issue; the measurements above independently
reproduce every claim in it>

## Errors Encountered

| Error | Resolution |
|-------|------------|
| `diff` returned `git diff` output; a 62-line drift reported as 1 line | Shell function shadowing. Use `command diff` / `cmp -s` for anything treated as evidence |
