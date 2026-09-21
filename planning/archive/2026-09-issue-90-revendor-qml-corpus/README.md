# #90 — Re-vendor `inst/styles/` after rfp repaired two QMLs

Closed by PR (see `git log --grep '#90'`), released as **0.16.0**.

Two of the 60 vendored QML styles had drifted from rfp's store, both because rfp repaired
them upstream and gq never pulled the repair. The remedy was a re-run of
`data-raw/styles_vendor.R`. That part took one command. Everything else came from reading
the script's own stdout, which reported **three** skipped raster styles where its comment
named two.

## Measurement

Full byte sweep over `inst/styles/index.csv` against rfp's store: **60 files checked, 2
drifted before, 0 after.** `inst/styles/index.csv` byte-unchanged; the vendor script
idempotent across five runs. `floodplains.qml` was one line (`previewExpression`
`feature_name` → `floodplain_name` — a floodplain naming itself by the wrong attribute in
QGIS's identify panel). `bcfishobs_fiss_fish_observations.qml` was 62 lines: 5 fields the
renamed table no longer has, each across five blocks, configured roster **24 → 19**.

The drift guard went `FAIL 1` → `FAIL 0`, with `SKIP 0` — the load-bearing observable,
since an unset `RFP_STYLES_DIR` makes it skip and still print `FAIL 0`.

Two pre-existing failures were confirmed unrelated by running them in a worktree detached
at `origin/main`: `test-template_drift.R:353` (#70, open) and a `test-gq_registry_read.R`
warning.

## What this actually cost, and what it bought

**Six defects, five of one class** — a restatement whose population moved — and three of
those were found *inside the previous fix*:

| # | where | claim | verdict |
|---|---|---|---|
| 1 | `styles_vendor.R` comment | 2 skipped rasters | stale; the run reports 3 |
| 2 | `test-gq_style_qml.R` guard | negative literal set | blind to `airphoto_gray` |
| 3 | `styles_vendor.R` comment | "the 4 forms" | `groups.csv` has 2 |
| 4 | the same paragraph | "QGIS-authored sidecars, **which is why**" | false — polarity backwards |
| 5 | the repair for #4 | "authorship does not discriminate" | false — no variation in the variable |
| 6 | the repair for #5 | "the cause is authorship" | false — a sufficient condition stated as the cause |

**#2 is the one that mattered operationally.** The guard enumerated *bad* members, so a
raster rfp added after the list was written was refused by nothing. Replaced with a
positive set pin, and proven rather than asserted — the old guard demonstrably PASSES on
`airphoto_gray`.

**#4–#6 are the one worth remembering.** Every sweep measured rfp's **data** — `grep -rl`
over the store, `ls` of the reference nodes, `nrow()` of an index, `Rscript -e
'rfp_raster_styles()'`. None read rfp's **prose**. That instrument settles counts, member
lists and superlatives, and structurally cannot settle a causal claim, because the output
is what such a claim is *about*. rfp had documented the answer the whole time, one `grep`
away. Filed as **#92**.

## The wrong turns, kept deliberately

- The first enumeration swept **three of the six axes** the convention names and declared
  the class closed — and ticked the very paragraph that was false, against the half of the
  sentence already believed.
- `species_name` was nearly filed upstream as a defect in rfp's repair. rfp#307 had already
  measured that table at 34 columns with `species_name` among them. The real finding is the
  inverse, and it went into #86: **its proposed tier-1 rule would refuse a correct file**,
  on the very file it was written for.
- The causal paragraph was rewritten three times and ended up **deleted** rather than
  attempted a fourth time. Nothing in the script reads the element order, and the skip rule
  is the roster, so the comment now points at rfp's one sentence.
- A `&&` chain truncated silently after `grep -c` printed `0` (it exits 1), making a residue
  check look like it had returned nothing.
- `diff` is shell-aliased to `git diff` here, which reported a 62-line drift as 1 line.

## Evidence

`review-round1.md` … `review-round4.md` — one Plan review plus four `/code-check` rounds.
Rounds 2, 3 and 4 each found a defect inside the previous round's fix, which is why it ran
past the usual bound. It ended by **removing the surface**, not by a quiet round.

`findings.md` carries the six-axis enumeration table and the per-claim measurements;
`task_plan.md` carries the round summary.

## Related

- #86 — rewritten and retitled; its "the byte-identity guard is green" premise expired
- #92 — the mechanism, scoped to the sibling `data-raw/` scripts, explicitly not a recount
- #78 — why both this and #88 were invisible to CI; not addressed here
- #70 — the pre-existing `template_drift` failure, still open
