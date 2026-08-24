# Progress — themes.csv describes themes that do not ship (#46)

## Session 2026-08-24

- Plan-mode exploration against both rfp templates; phases approved by user
- Plan-agent review before baseline caught three blockers, all verified
  independently before acting on them:
  - the four-basemap motivating case is **not** in the templates' presets
    (3 of 4 basemaps appear in zero presets) — extraction cannot produce it
  - `normalize_layer_name()` already exists at `R/gq_style.R:104`; the original
    plan would have created a third copy of one rule
  - installed rfp (0.25.1) and the source checkout (0.30.1) give different
    visible-counts, so "which templates" must be explicit
  - plus: the original phase order committed the 4-column CSV before the reader,
    leaving the tree red mid-branch
- Filed rfp#185 for the stale visibility presets; decision is to extract
  truthfully now and re-run once that lands
- Corrected #46's body — its basemap premise was disproved by measurement; the
  two findings that hold (fictional names, wrong granularity) kept, and the
  `template`-column requirement plus `habitat_lateral` recorded
- Archived #17's PWF to `planning/archive/2026-08-issue-17-tmap-composition-paused/`
  with a README stating paused-not-complete; #17 stays open
- Created branch `46-themes-csv-describes-themes-that-do-not-` off main
- Scaffolded PWF baseline with approved phases
- Next: Phase 1 — point `gq_qgs_extract()` at the existing normalizer and add
  the boundary-separator unit test that nothing currently covers
