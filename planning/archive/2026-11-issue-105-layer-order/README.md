## Outcome

`groups.csv`'s `order` (z-order within a group, 1 on top) disagreed with both shipped templates in seven groups: `Basemap`, `Basemap/Waterbodies`, `Crossings`, `Streams/Habitat models`, `Roads,Railways,Pipelines`, `Web Mapping Services` and `Base - misc`. None of gq's orders had a measurement behind it, so the templates' order was adopted. Layers only gq carries kept the neighbour above them, so `town` moved after `glaciers`, and `rivers_poly` and `dam` stayed at the bottom. The visible change is `Base - misc`, where Esri Satellite now heads the basemaps. `order_drift()` in `tests/testthat/test-template_drift.R` now holds the order per group path and per template, on the layers both carry. Two things stay out of reach without a schema change, and are handed to #104 (its body and `planning/backlog.md` batch 11): where a subgroup sits among its parent's layers, and the order of sibling subgroups. The research file `research/vendored_artifacts.md` ("Known gaps") is revised to match.

## Measurement

- Red before the renumber: `order_drift()` named exactly the 7 group paths in each template. Shared layers compared per group: Basemap 12, Waterbodies 5, Crossings 8, Habitat models 3, Roads 8, Web Mapping Services 2, Base - misc 6.
- After: 0 paths drift. `gq_groups()` membership and `source_type` are identical (62 rows), and `gq_template_layers()`'s sequence changed in exactly the 7 paths in both templates.
- Code-check round 2 ran 13 mutations of the guard. Every one that should be caught turned the suite red. The exception is a tie in `order`, which `order_drift()` misses because `order()` is stable, and which the existing duplicate-order test in `test-composition_integrity.R` catches instead. Moving a gq-only layer on its own goes undetected, by design.
- Code-check round 3 found that the renumber changes no rfp behaviour. rfp reaches `order` only through `rfp_project_layers()` and never reads it.
- `devtools::test()`: FAIL 0 | WARN 1 | SKIP 6 | PASS 1696.

Closed by: PR (opened next by `/gh-pr-push`), branch `105-layer-order-within-a-group-disagrees-wit`
