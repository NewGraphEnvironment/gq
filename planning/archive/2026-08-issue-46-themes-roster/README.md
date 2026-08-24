# themes.csv describes themes that do not ship (#46) — COMPLETE

Landed 2026-08-24 in `v0.3.0`.

## Outcome

`themes.csv` was fiction: three theme names that exist in no template, at a
granularity QGIS does not use. It is now extracted from the two templates as
`template,theme,layer_key,visible` — 232 rows, 9 template-theme pairs — by
`data-raw/reg_extract_themes.R`, and re-running is byte-identical.

`template` became part of the key rather than a filter, because measurement
showed the same theme name carries different content per template
(`High Detail - Crossings`: 27 layers visible in bcfishpass, 0 in
bcrestoration). `gq_theme_groups()` was retired for
`gq_theme_layers(theme, template = NULL)`.

## What the plan review changed

A Plan-agent pass before the baseline commit caught three blockers, all verified
before acting:

1. **The issue's motivating case is not in the data.** Three of the four xyz
   basemaps appear in zero presets, so extraction could never produce the
   "one aerial on, the rest present-but-off" behaviour #46 argued from. Filed
   rfp#185; extracted truthfully instead. The schema change stood on its other
   two grounds.
2. `normalize_layer_name()` already existed — the plan would have created a
   third copy of one rule.
3. Installed rfp (0.25.1) and the checkout (0.30.1) disagree on visible-counts,
   so `RFP_TEMPLATE_DIR` makes the source explicit.

Also found while committing: `planning/active/` was gitignored from the scaffold
commit, making the PWF convention impossible to follow. Removed.

## Follow-ups

- **rfp#185** — re-save the templates' presets with all four xyz basemaps, then
  re-run `data-raw/reg_extract_themes.R` here
- `habitat_lateral` has a `groups.csv` row but no `reg_main.json` entry (it is a
  raster; the extractor reads only vector maplayers)
