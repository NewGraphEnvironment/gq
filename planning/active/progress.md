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

### Phases 1-2 — structural guards, and the rows they found

- The "every group is mapped to a template" guard fired on exactly one name:
  `Base - Orthoimagery`. Confirmed red before the fix, green after.
- Four other guards written alongside it pass on current data, which is the
  point — they pin the chain end to end so a future change has to break them.
- Worth recording before anyone "fixes" it: **the two templates already
  disagree on ordering.** bcfishpass runs Roads(4) then Streams(5); restoration
  runs Streams then Roads. So mirroring `Other Point Features` into position 3
  is a local consistency, not a global one, and the existing divergence was
  preserved deliberately rather than flattened.
- `Base - Orthoimagery` added to **both** templates, not just restoration. The
  issue proposed restoration only because it was scoped there; the group was
  mapped to neither, and bcfishpass was missing `orthophoto_tiles` for the same
  reason.
- Measured: restoration 57 -> 62 layers, bcfishpass 58 -> 59, no duplicates in
  either, all five named layers present.
- 11 layers still resolve to `NA` source_layer. That is Phase 4, and it is the
  larger version of the same bug.
