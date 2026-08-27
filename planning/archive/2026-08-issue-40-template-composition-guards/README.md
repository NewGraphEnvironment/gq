# gq#40 — layers styled for data nobody downloads

**Outcome:** shipped in v0.10.0. Both templates gained the layers they were
missing (`bcrestoration_mobile` 57 → 64, `bcfishpass_mobile` 58 → 61), and the
composition chain now has guards, so the same gap fails the suite instead of a
field day.

**The missing rows were the symptom.** `templates.csv → groups.csv →
reg_main.json` is three joins deep and none of them reported a miss:
`join_registry()` turned an absent registry entry into `NA_character_` silently,
and the groups-to-templates step is a plain `%in%`, so an unmapped group simply
contributed no rows. `Base - Orthoimagery` was mapped to **zero** templates for
the entire history of the file, with a green suite the whole time.

**The guard is derived, not listed.** The plan proposed an eleven-entry
exemption list; `source_type` already encoded the same information. That matters
for the direction it fails in — a list has to be extended per layer, so a layer
added tomorrow defaults to *exempt*, where a derived rule defaults to *checked*.
The exemption list went from eleven proposed entries to zero, then to three
tracked against #64. A census settled it: `wms` is *exactly* `index.csv
kind == "service"`, two hand-maintained columns in perfect agreement, now pinned
to each other.

**One layer pair was mis-diagnosed by me, and the fix would have wasted a day.**
I read `harvest_area` and `planting_site` as bcdata layers missing their table.
Their own registry notes say "buffered river corridor" and "proposed restoration
planting location" — project-authored layers. The wrong field was `source_type`,
not the missing `source_layer`, and chasing the cutblock table I named would
have found nothing.

**I was wrong about the two new layers, twice, and both corrections came from
outside.** I "corrected" the issue by claiming gq already shipped symbology for
`national_park` and `old_growth_management_areas`, on the evidence that a 13 KB
QML exists for each. Both QMLs contain **zero** `renderer-v2` elements — they
are attribute-form configs whose only `<symbol>` nodes are QGIS elevation-profile
defaults. So does the source `.qgs`. Presence of a file is not presence of
content, which is the same error as trusting a green run without reading what it
checked. The issue was right and my correction of it was wrong.

Then the user asked whether a QML could come from `sern_peace_fwcp_2023` rather
than being invented — a better question than either option I had framed. The
answer was one of each: that project carries OGMA with a real `singleSymbol`
renderer, so its colours are **extracted**; `national_park` is unstyled
everywhere and is **authored**, labelled as authored, reusing
`provincial_park`'s exact colours so no new hue was invented.

**Two defects in my own landed commits, both found by review.** A test asserting
`group_order` is sorted in file order — inside the very test written to protect
the freedom to number 10/20/30, so appending a group with a mid-range value
would have failed it. And a checked box for documentation that did not exist
outside a test comment; its other half turned out to be impossible anyway, since
`read.csv()` defaults `comment.char = ""` and a `#` header line parses as data.

**A third I introduced and caught by looking:** shifting the `Basemap` z-order
tail to insert two rows collided with an inserted value, putting `conservancy`
and OGMA both on 6. Nothing complained, because `order` had no uniqueness guard —
and a duplicate makes draw order depend on row position in the file rather than
on the value. Guarded now, along with `layer_key` uniqueness, which
`gq_template_layers()`'s existing no-duplicates assertion silently rested on.

**On ordering, the concern inverted.** Asked whether `group_order` survives many
project types: it is read by two `order()` calls and validated nowhere, so any
future template can number however it likes. The real risk is someone inferring
that contiguity is *required* from the two templates that happen to have it. Now
documented in roxygen and pinned by a test. Related: the two shipped templates
already disagree beyond their first three groups, so "mirror bcfishpass" was
only ever a local consistency.

Split out: **#64** (`form_edna`, `form_monitoring`, `habitat_lateral` — grouped
and shipped with no registry entry at all; nothing in the repo says whether they
are live or stale).

Suite 922 → 962. Commits `de34ed5`..`<release>`. PR #65.
