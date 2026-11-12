# Plan review (Plan agent, 2026-11-12, delivered after Phase 2 began)

Findings as delivered, condensed; disposition in the right column of progress.md.

## Blocker
1. `add_layers_control()` sets a random `control_id` via `sample()`; parity `identical()` needs `withr::with_seed()` around each build, and the helpers must make the same `sample()` calls in the same order. (Probed: unseeded builds differ only in `layers_control`; seeded identical.)
2. `add_categorical_legend()` samples when `unique_id` is NULL — helper must pass `paste0("legend_", id)`.
3. knw adds no navigation/scale control; `gq_mapgl_controls()` needs off switches for parity; `layers` passed as a named character vector; must not default to every layer in the parity case.

## Gap
4. Legend `add` must be `!is.null(map$x$legend_html)`; layer before legend (slot order).
5. `gq_mapgl_layer()` needs a width argument for order-scaled width on classified layers; keep `values = c(1, 6)` double.
6. Caller classes need `values` (type kept), `labels`, `colors`, `default`, `legend_title`; `patch_shape` default "square".
7. Hex must pass through untouched (col2rgb recipe uppercases and adds alpha).
8. Use typed `add_*_layer`, never `add_layer(paint =)` (different spec).
9. Source sharing rule: `x` sf → `add_source` + layer; `x` NULL → reference. Species map may need `filter`.
10. knw popup is bespoke; parity passes `pop$expr` through `popup =`, so `gq_mapgl_popup()` is not exercised by parity.
11. Parity fixture should include `water` (pass `water["kind"]`).
12. CLAUDE.md:220-222 "mapgl does not read per-class opacity yet (gq#107)" goes stale.
13. `test-vignette_legend_coverage.R` covers the two tmap vignettes only; new article draws `lake`/`streams_all` via network with no legend.

## Ordering
14. Write the parity test before finishing Phase 3.
15. Plan text says bec_zone gives a match expression; code returns scalar 0.25.

## Assumption
16. 14 species → 14 stacked one-item legends + a 14-entry toggle may overflow at 500px.
17. Phase 1 `grepl("-(color|opacity)$")` accepts `fill-outline-color`, `circle-stroke-*` and answers with the fill class values; restrict to `^(fill|line|circle)-(color|opacity)$`. No class opacity returns 1 where tmap returns nothing.
18. Network falls back to `streams_all`'s first class (#a9e0ff at 0.65) for data without `feature_code`.

## Scope
19. Classified registry mode carries no per-class widths/dashes; registry point `mark$shape` (triangle) cannot be a circle layer — document as gaps.
20. Pin the knowledge rewrite issue to knowledge eac16623.

## Acceptance
21. A stronger mutation: remove a helper default (`unique_id`, match `default`) and confirm red.
22. Missing tests: hex passthrough; `add` FALSE then TRUE; controls off add no slots; integer match keys keep type; mapgl-missing error; skip_if_not_installed in every new test file.
23. Probed fine: basemap bounds equal `bounds = s4`; rounding idempotent.
