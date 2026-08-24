# Task: themes.csv describes themes that do not ship, and cannot express a theme within a group (#46)

## Problem

`inst/registry/themes.csv` is fiction. Its 3 themes (`Field View`, `Analysis
View`, `UAV View`) have **zero overlap** with the 9 themes the templates
actually ship, and its `theme,group,visible` schema cannot round-trip a real
theme — QGIS models themes as per-layer `<layer id=… visible="0|1"/>`, with
groups appearing only as `<checked-group-nodes>` UI state.

## Approved decisions

1. Schema `template,theme,layer_key,visible` — template-first like
   `templates.csv`. Required, not optional: `Land Tenure` is restoration-only,
   and `High Detail - Crossings` ships in both templates with different content
   (27 visible in fishpass, 0 in restoration).
2. Pure layer rows. No group shorthand — extraction never emits one (YAGNI).
3. `habitat_lateral` gets a `groups.csv` row so its theme rows resolve.
4. Retire `gq_theme_groups()`, add `gq_theme_layers()`. Breaking → 0.3.0.
5. Extract truthfully: only `esri_world_topo` among the basemaps, because that
   is what the presets contain. rfp#185 tracks re-saving them upstream.

## Phase 1 — Shared normalizer

- [x] Point `gq_qgs_extract()` at the existing `normalize_layer_name()`
      (`R/gq_style.R:104`) instead of its byte-identical inline copy at
      `R/gq_qgs_extract.R:57-58`. Do **not** create a new helper — that would be
      a third home for one rule
- [x] Preserve the rule exactly: `sub("^_|_$", …)` is `sub`, not `gsub`, so only
      the first boundary underscore is stripped. "Tidying" it to `gsub` changes
      keys
- [x] Add a `normalize_layer_name()` unit test covering leading, trailing and
      doubled separators. No current test would catch a regression — the
      extractor fixture's layer names (`Lakes`, `Streams`, `Crossings`, `Roads`)
      are all clean

## Phase 2 — Extraction script

- [x] Add `data-raw/reg_extract_themes.R` following
      `data-raw/reg_extract_restoration.R`
- [x] **Resolve the template-source ambiguity explicitly.** Installed rfp is
      0.25.1, the source checkout is 0.30.1, and they yield different
      visible-counts (28 vs 27). Take a template *directory* override
      (env var, defaulting to `system.file`), and record the rfp version used in
      a comment header of the generated CSV
- [x] Parse `//visibility-presets/visibility-preset`; per `<layer>`, resolve
      `id` → `<maplayer><layername>` → `normalize_layer_name()`
- [x] Emit `template,theme,layer_key,visible` sorted by template, theme,
      layer_key
- [x] Abort loudly on any `layer_key` absent from `groups.csv` — a silent drop
      would recreate the fiction this issue removes

## Phase 3 — Data, reader and API (single commit — see note)

- [x] Add `habitat_lateral` to `groups.csv`: `Base - misc`, no subgroup,
      `source_type = local`, `order = 1`, shifting the group's existing 1-7 to
      2-8. (The two templates disagree on its tree position and the existing
      orders already do not match either tree; ordering fidelity for
      `Base - misc` is #40's problem, not this one)
- [x] Run the script; commit the regenerated `themes.csv` (~232 rows, 9
      template-theme pairs)
- [x] `gq_themes()` returns the 4-column frame; add a `template = NULL` filter
- [x] Replace `gq_theme_groups()` with `gq_theme_layers(theme, template = NULL)`
      — NAMESPACE, roxygen, runnable `@examples`
- [x] Document what an absent layer means: presets govern 25-28 of 54-59
      layers, so a returned set is partial and says nothing about the rest
- [x] Make the `as.logical()` at `R/gq_groups.R:205` a real guard that errors on
      unparseable values, or drop it — today it is a no-op
- [x] `devtools::document()`

**Why one commit:** the data, reader and tests must land together. Committing
the 4-column CSV while the reader and tests still expect 3 columns leaves the
tree red at `tests/testthat/test-gq_groups.R:122,123,127-136`, which the
`/code-check`-clean-per-commit gate forbids.

## Phase 4 — Tests

- [x] Rewrite the three theme tests
      (`tests/testthat/test-gq_groups.R:119,127,138`) against real theme names
- [x] Mirror the integrity test at `:52`: every `themes.csv$layer_key` appears
      in `groups.csv`
- [x] Assert both templates' `High Detail - Crossings` coexist with different
      visibility — the case the old schema could not represent
- [x] Pin the documented behaviour of `gq_theme_layers(theme)` with no
      `template` (returns both templates' rows concatenated)
- [x] Assert empty return for an unknown theme
- [x] Keep `expect_type(df$visible, "logical")`

## Phase 5 — Docs

- [x] `README.md:81` — theme concept row still says `"habitat"/"barriers"/"all"`
- [x] `README.md:70` — `gq_group_layers("fish_passage_pscis")`; no such group
- [x] `README.md:83` — "12 canonical groups, 53 layer keys" is stale at 62 rows
- [x] `README.md:110` — claims the tmap vignette composes "from groups + themes";
      that vignette has no theme reference. Fix the claim, not the vignette
- [x] `CLAUDE.md:175-181` registry-sources list omits `groups.csv`,
      `templates.csv`, `themes.csv` entirely
- [x] `NEWS.md` 0.3.0 section; `DESCRIPTION` 0.2.1 → 0.3.0 as the **final**
      commit of the branch

## Validation

- [x] `devtools::test()` — record the pre-change baseline first, then compare
- [x] `lintr::lint_package()` clean on changed files
- [x] `devtools::check()` no new ERROR/WARNING
- [x] `/code-check` clean on each commit
- [x] Re-running `reg_extract_themes.R` is idempotent against a pinned rfp
- [x] PWF checkboxes match landed work
- [ ] `/planning-archive`, then `/gh-pr-push`
