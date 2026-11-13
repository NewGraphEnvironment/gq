# Plan review — #103 (Plan agent, 2026-11-13 ~05:29Z)

Verdict and disposition. Each claim was probed before acting.

| # | class | finding | disposition |
|---|---|---|---|
| 1 | Blocker | reg_main's 25 labelled layers = 22 template + 3 CSV (dam, town, planting_site); CSV has no label field column, so "every label has field or expression" fails on reg_main and `gq_tmap_labels(reg, "town")` refuses | Reproduced. Assert 22 on `reg_qgis_restoration`; CSV labels take `field =`; `label_field` CSV column declined here (source columns unmeasured, no DB reachable) → follow-up issue |
| 2 | Blocker | `.qlr` test needs `table=` parsing, not just a test | Already done in `datasource_layer()`; check the re-extract leaves the template's sources alone |
| 3 | Gap | `gq_style()` drops per-class `outline_color/opacity/width` (#31 remainder carried to #24); `radii`/`shapes` in `gq_tmap_classes()` | Surface `outline_*` per class in `gq_style()`; decline tmap radii/shapes (no consumer), state it |
| 4 | Gap | `gq_style()` returns no `label`; gq-intro's `label_sty` is NULL today | Pass `label` through `gq_style()`; vignettes move to `gq_tmap_labels()` |
| 5 | Gap | railway overlay colour must be the marker's `outline_color` | Already so (`tick_overlay()` reads outline_color from the sub-marker); test pins `#000000` |
| 6 | Gap | placement 7, 8, unknown; 2 on a polygon is perimeter | 7/8 mapped; unknown omitted; polygon 2 → `"perimeter"` |
| 7 | Gap | categorized casing counts `.//layer`, never checks width | `./layer` already; add the wider-underneath check |
| 8 | Gap | CSV `offset_x/y`, `textOpacity`, `overlapHandling`; `gq_mapgl_labels()` has no `name =` | Map offsets → `xmod`/`ymod` and `text-offset`; extract `textOpacity` < 1 as `label.opacity`; `overlapHandling` declined (remove_overlap stays TRUE); mapgl keeps the layer-object signature of its family |
| 9 | Ordering | plan text still says grow `mini_project.qgs` | Plan text updated to the excerpt fixtures |
| 10-11 | Assumption | fontWeight threshold, tick-to-dash conversion | Confirmed; dasharray unit note goes in the drawing follow-up issue |
| 12 | Assumption | opacity fold darkens overlaps vs QGIS's layer composite; only roads_ften | Accepted, documented |
| 13 | Assumption | MoTi's casing is pass 0/0, no symbol levels: "every casing beneath every core" holds for DRA only | Roxygen reworded: casing under its core; under every core only where QGIS uses symbol levels |
| 14 | Acceptance | 22 labels = 14 field / 8 expression by first rule | Pinned in the rebuilt-registry assertion |
| 15 | Scope | gq-tmap-composition railway prose contradicts the new overlay | Fixed in Phase 2's vignette checkbox |
