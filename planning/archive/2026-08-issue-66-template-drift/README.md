# 2026-08 — #66 registry and shipped templates disagree

gq declared a group structure that no shipped `.qgs` had, and nothing checked.
Measured rather than assumed: the two templates are **structurally identical**
(same ten top-level groups, same order), while gq declared different sets and
different orders for each — so the issue's template-vs-template framing was
wrong, it was registry-vs-both. Adopted the templates' group names as a single
join key (four renames, both CSVs now quoted because `Roads,Railways,Pipelines`
carries a comma), kept order as gq's to declare but only where deliberate, and
deleted `Base - Orthoimagery` — a group that had never existed in any template,
added by #40 at a `group_order` **below** `Base - misc`, so the registry itself
was declaring `orthophoto_tiles` beneath four opaque basemaps.

The deliverable is the guard: `inst/registry/template_groups.csv` vendored from
the templates (gq is public, rfp is private, CI can never read a `.qgs`) plus
`tests/testthat/test-template_drift.R` — composition both directions, byte-exact
names, relative order on the intersection, and nothing declared below the bottom
of the template's stack. Every assertion was written first and seen red, then
re-verified against `git show main:` versions of both CSVs.

A concurrent plan review caught two defects in the fix itself: declaring
`Basemap/Terrestrial Ecology` declared it for `bcfishpass` too (this issue's own
failure mode at depth 2, invisible to a union-based check), and `Base - lidar` is
empty in both templates so cannot be declared at all.

Closed by a877534 / PR #69. Released 0.11.0. Follow-ups: rfp#216 (three groups
the templates lack), gq#68 (six layer-placement disagreements).
