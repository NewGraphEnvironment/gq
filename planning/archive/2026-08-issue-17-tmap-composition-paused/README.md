# tmap composition helpers and vignette (#17) — PAUSED, not complete

Archived 2026-08-24 to free `planning/active/` for #46. **The issue remains open.**

## What landed

The composition vignette shipped in PR #26.

## What did not

Neither helper was built:

```
gq_tmap_basemap      exported: 0
gq_tmap_legend       exported: 0
```

Ten checkboxes in `task_plan.md` are unticked. Last worked 2026-03-09.

## Why archived rather than closed

PR #44 moved this PWF from the repo root into `planning/active/` on the
reasoning that the work is genuinely in-flight, and flagged the resume-or-close
call as due. #46 then needed the single `active/` slot, so the artifacts move
here — but archiving them is a filing decision, not a claim that the work
finished. Marking these phases complete would have been false.

`gq_tmap_legend()` is also tracked separately as #27, which notes tmap upstream
should be checked first — that check may change the remaining scope.

## Picking it up

Restore these three files to `planning/active/` (once it is free) and continue
from the unticked Phase boxes in `task_plan.md`. `findings.md` holds the Neexdzii
Kwa reference data the vignette work was built against.
