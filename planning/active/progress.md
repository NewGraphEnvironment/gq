# Progress — Restoration template layers are never downloaded (#40)

## Session 2026-08-26

- Plan-mode exploration; phases approved by user.
- The issue diagnosis is right but stops one level short. The composition chain
  **fails silently at every join**: `join_registry()` (`R/gq_groups.R:290-304`)
  turns a registry miss into `NA_character_` with no warning, and nothing
  asserts a group is mapped to any template. `Base - Orthoimagery` has been
  mapped to zero templates for the file's whole history with a green suite.
- Three corrections measured against the files: 7 distinct layers not 9 (the 9
  counts layer x template pairs); gq **already ships QMLs** for `national_park`
  and `old_growth_management_areas`, so those need registry rows not symbology;
  and 11 `groups.csv` keys currently resolve to `NA` source_layer, which the
  issue misses entirely.
- Ordering: `group_order` is validated nowhere, so the model already scales to
  new project types. The risk is the inverse of the one raised — that someone
  infers contiguity is required. Mirror bcfishpass now, write the freedom down,
  pin it with a test.
- Created branch `40-restoration-template-layers-are-never-do` off main.
- Next: Phase 1 — guards that fail on today's data.
