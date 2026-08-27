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

### Plan review — and a false claim of mine it caught

26 findings. The blocker was mine: I "corrected" the issue by asserting gq
already ships symbology for `national_park` and `old_growth_management_areas`.
It does not. Both QMLs have **zero** `renderer-v2` elements — they are
attribute-form configs, and their only `<symbol>` nodes are QGIS elevation-
profile defaults. Verified directly before acting: `lake` and `wetland` have 1
renderer each, these have 0.

I had taken "a 13 KB QML exists" as "symbology exists". Presence is not content —
the same shape as trusting a green run without reading what it checked. The
issue was right and my correction of it was wrong; the plan and issue body both
had to be re-corrected.

Two more of my own defects the review found, both in the commit that had just
landed:

- **A test contradicting its own header.** `group_order` sorted-in-file was
  asserted in the very test written to protect the freedom to number 10/20/30.
  Appending a group with a mid-range number would have failed it. Replaced with
  uniqueness, which is the property that actually makes the sort deterministic.
- **A checked box that was not done.** The "document group_order is sort-only"
  bullet was marked `[x]` while no `R/` or `man/` file had been touched — the
  prose existed only in a test comment. Now roxygen on `gq_templates()`. Also
  learned the bullet's other half was impossible: `read.csv()` defaults
  `comment.char = ""`, so a `#` header line in the CSV parses as data.

### Phase 4 — the derived rule

`source_type` turned out to be the discriminator already present in the data, so
the exemption list went from a proposed eleven entries to **zero**. The census
that settled it: aws 13/13 and fwa/osm 1/1 have source_layer, all 6 wms have
none, and wms is *exactly* `index.csv kind == "service"` — two hand-maintained
columns in perfect agreement, now pinned to each other.

`harvest_area`/`planting_site` were mis-diagnosed by me as bcdata layers missing
a table. Their own notes say otherwise; the wrong field was `source_type`.
Chasing the table I named would have wasted someone's afternoon.

`form_edna`, `form_monitoring`, `habitat_lateral` exempted with **gq#64** as the
stated reason, plus an assertion that each exemption is still *needed* — so when
#64 lands the guard fails and says to delete them.
