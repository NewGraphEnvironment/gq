# tmap composition helpers and vignette (#17) — superseded

> **Resumed and completed the same day.** See
> `../2026-08-issue-17-tmap-composition/` for the work that shipped in v0.5.0,
> and its `review-52*.md` for three adversarial passes. #17 is closed.
>
> This directory is kept as the record of the paused state, because it is the
> reason the resumed plan scoped six helpers rather than the two the issue
> named — nothing here started, so the scope was set by measuring the
> duplication instead. Everything below describes 2026-08-24, before that.

Archived 2026-08-24 to free `planning/active/` for #46.

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
