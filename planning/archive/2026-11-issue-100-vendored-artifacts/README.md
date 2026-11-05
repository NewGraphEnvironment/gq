## Outcome

Move 1 of `planning/backlog.md`: gq's copies of rfp's rosters are current against rfp v0.93.0, the registry agrees with the templates on which group every layer sits in, and a stale copy now fails a test.

- **Re-vendor:** `template_groups.csv` was two months stale, missing `Floodplain` and `Restoration`. The form roster gained four forms, lost `trail_feature` and now has eDNA styled; themes and the QML corpus were already current.
- **Placement:** six layers moved to the templates' groups. A new `template_layers.csv` and placement guard keep it that way.
- **Currency test:** the roster builders moved into `R/` behind one writer, so `test-vendored_currency.R` can rebuild each roster from an rfp checkout and compare files.
- **QML check:** `test-qml_consistency.R` holds field-scoped QML tags to their own roster.
- **What was learned:**
  - Rfp owns the group tree, layer placement, themes and forms.
  - #86's four dead bcfishobs tags belong to a corpus-wide class of stale snapshot tags, so no database-free rule can single them out.
  - The generators and testthat collate differently, so every committed sort must be radix.
- **Durable verdicts:** [`research/vendored_artifacts.md`](../../../research/vendored_artifacts.md).

## Measurement

- **Staleness at the start:** `template_groups.csv` was 6 rows behind (2 groups missing, 4 orders shifted) and `form_types.csv` 5 rows (13 → 16 spatial forms: four added, one retired, eDNA's styling). `themes.csv` (268 rows, 9 pairs) and all 60 QML files were byte-identical.
- **Layers:** `template_layers.csv` holds 113 layers (bcfishpass 54, bcrestoration 59). Every key joins to `groups.csv` except the 3 non-spatial tables rfp lists in `.rfp_audit_whitelist`.
- **Placement:** 6 placement disagreements, each from gq's first commit with no measurement behind it, so the templates were adopted. Order within a group still disagrees in 7 groups, and sibling-subgroup order inverts `Stream labels` (gq#105).
- **QML corpus:** the snapshot tags name 497 fields outside their roster in 26 of the 53 vector files. The clean field-scoped tags have 0 misses in 60 files, and 6 bare expression references are undecidable.
- **Tier 2:** `bcfishobs.observations` has 34 columns. `linear_feature_id` and `species_name` resolve, `fid` is the GeoPackage key, and `fish_obsrvtn_pnt_distinct_id` is dead. That supersedes #86's "7 dead fields".
- **Collation:** reproduced the `en_US` vs `C` swaps ("Low detail - roads" / "Low Detail - Salmon Model", `roads_dra` / `roads2`). Radix keeps today's output byte-identical.
- **Tests:** with the rfp variables set, 1159 pass and 0 skip. Without them, 1155 pass and the 4 live checks skip.
- **Wrong turns kept:**
  - The plan's tier-1 design ("exactly the 4 tags") was disproved by the plan review and rebuilt.
  - The #73 exemption first rested on the built `.qgs`'s `NoGeometry`, which rfp stamps on registered polygons too, and was re-sourced to rfp's own whitelist.
  - The first lint comparison printed nothing, because `diff` is a shell function on this machine.
  - A helper named `g` fork-bombed the machine (`g` is aliased to `git`).

## Owed

- When rfp's issue moving the QML store into gq settles where the QML store lives and the snapshot tags (497 names in 26 files, the 4 bcfishobs tags among them) are cleaned there, re-vendor and decide whether `test-qml_consistency.R` can hold those tags to the roster too. Corrected from "delete the pin" after the plan review showed tier 1 cannot single out the 4 tags (review-100.md #1).

Closed by: PR (opened from branch `100-move-1-vendored-artifacts-current-and-gu`). It closes #70, #94, #68, #73, #78 and #92, and relates to #86.
