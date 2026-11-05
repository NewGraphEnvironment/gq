# Findings — Move 1: vendored artifacts current and guarded (batches 1, 2) (#100)

## Issue context

**If we do it:** the rosters and styles gq copies from the template repo are current, the registry and the templates agree on where each layer sits, and a copy going stale fails a test. **If we never do:** the drift test keeps passing against a copy vendored months ago, and every consumer of gq's groups and themes reads a roster the templates have moved past.

Move 1 of `planning/backlog.md`, which holds the order, the measurements and each batch's section. Run `/planning-init` on this issue: one plan, one phase per batch, one PR. `/gh-pr-merge` ticks the move when it merges.

## First, a read of the peer repos

Themes and groups are being reworked in the two repos that consume these rosters: the template repo, and the repo that holds each field project's config (owner, 2026-11-04). Open there on 2026-11-04: themes composed in project config as a base plus additions and removals, a reconciler for layer group placement after a project is created, floodplain theme names being retired and merged, a Terrain group and theme for the templates, and a test fixture failing against the current registries. Before the plan gate, search both repos' open issues and pull requests for `themes` and `groups`, read each adjacent body, and settle with them which side owns each roster. Nothing in the two batches below is decided until that read is done.

## Batch 1: Template agreement

**Why here:** one checkout of the template repo at one version and one run of the extractors pays for all four.

**Touches:** `inst/registry/template_groups.csv`, `form_types.csv`, `groups.csv`; `tests/testthat/test-template_drift.R`, `test-gq_forms.R`; `data-raw/reg_extract_template_groups.R`.

**Decided at the gate:** whether `groups.csv` gains a `template` column; for each of the six layer placements in #68, whether gq's side was a decision or unchecked drift; register or exempt the three layers in #73.

| issue | title |
|---|---|
| #70 | Delete the three template-drift exemptions |
| #94 | Re-vendor form roster: eDNA is now styled |
| #68 | Registry and templates disagree on the group six layers belong to |
| #73 | Tracking and the two habitat-parameter layers ship in the templates with no groups.csv row |

## Batch 2: Vendored-artifact guards

**Why here:** the same extractor scripts, run after batch 1 has made the copies current, against the roster shape the peer repos are moving to.

**Touches:** `R/utils_qgs_groups.R` and a sibling for themes; `data-raw/reg_extract_*.R`, `data-raw/styles_vendor.R`; a corpus-wide QML test.

**Decided at the gate:** where the guard runs now the templates are build output; whether gq becomes the single QML store, which flips where the fix for #86 lands; the `bcfishobs_fiss_fish_observations` key rename.

| issue | title |
|---|---|
| #78 | gq's vendored artifacts have no currency guard: 2 of 3 were silently stale |
| #86 | bcfishobs QML: 4 dangling tags remain |
| #92 | A causal claim about the template repo is settled by reading it, not by re-measuring its output |



## Errors Encountered

| Error | Resolution |
|-------|------------|
