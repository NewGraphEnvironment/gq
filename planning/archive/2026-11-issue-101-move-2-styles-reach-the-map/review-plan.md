# Plan review — #101 (Plan agent, spawned 2026-11-05 20:15Z, delivered after Phase 1 commit)

Findings as returned, with the disposition of each.

| # | class | finding | disposition |
|---|---|---|---|
| 1 | Blocker | `test-gq_groups.R:54` requires every `reg_main.json` key in `groups.csv`; the six new layers take no row | Verified. Phase 3 pins a named set of registry-only keys in that test, each with its reason, rather than giving derived products a template group (rfp would try to download them) |
| 2 | Assumption | "all typed polygon" does not fit knowledge's `tm_lines` use of `rule_class` / `grade_class`, and #98 says "on one network" | Accepted: `habitat_rule_comparison` and `habitat_expected_use` typed `line`; the areal three stay `polygon`. Raster consumers use `gq_tmap_classes()` either way |
| 3 | Assumption | no source gives land-cover opacity | Accepted: land-cover rows carry none (opaque) |
| 4 | Assumption | swatch set misses the website link map's orange and drift's Crops `#e49635` | Link map's crossing orange is `#d95f02`, already in the set (`figure_link-bulkley.R:35`); Crops added |
| 5 | Gap | key-set test vs `roads_dra` mixed key sets | Test was written as CSV keys ⊆ union of extracted line-class keys, which passes; no change |
| 6 | Gap | polygon alpha read depends on grob order (fill, then border) | Verified (`polygons_*` 0.25, `polygon_borders_*` 1). `drawn_gp()` gained `grob_name`; polygon reads select `^polygons_` |
| 7 | — | alpha interaction checked; value.na alpha is 1 | No change |
| 8 | — | legend dedup count unchanged | Confirmed by `test-gq_tmap_legend.R` passing |
| 9 | Gap | vignette passes `pscis_cls$labels` to tmap | Now named; checked in Phase 4 by rendering the vignette |
| 10 | Scope | `gq_mapgl_classes()` drops per-class opacity | Filed as a follow-up issue; named in the PR |
| 11 | Ordering | rebuild reproducibility check sits in Phase 3 but Phase 2 rebuilds | Moved to the start of Phase 2 |
| 12 | — | CSV change leaves existing JSON unchanged under three conditions; shared `entry$stroke` duplicates for classified lines | Gated on `type == "line"`, NA dash writes no key, layer-level stroke suppressed for classified lines |
