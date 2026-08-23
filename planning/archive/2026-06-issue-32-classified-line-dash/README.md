# gq#32 — classified line layers drop the QGIS dash pattern

## Outcome

The extractor's classified-line branch captured colour and width but not
`line_style` / `customdash`, so every dashed class in a classified line layer
came through the registry as solid — dashed roads and streams rendered as plain
lines in tmap and mapgl. `parse_dash()` is now shared by the simple and
classified branches, and the shipped registries were regenerated.

Closed by: PR #34 · released in v0.1.0 · closed 2026-06-04

## Note on this archive

These files sat in `planning/active/` from 2026-06-04 until 2026-08-22 — the
work shipped but `/planning-archive` was never run. Archived retrospectively;
the `task_plan.md` checkbox state (19 done, 1 open) is as the session left it,
and the one open item is the archive step itself.
