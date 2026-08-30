# gq#64 — Three grouped-and-shipped layers with no registry entry

Closed by PR (branch `64-three-local-layers-no-registry-entry`), released as
0.12.0.

The issue read as three instances of one problem. It was two problems, and the
framing of the first was wrong in a way that decided the design.

`form_edna` and `form_monitoring` are **real** — rfp ships a GeoPackage and a
QML for each, and three live Mergin projects hold collected field data. The
issue's claim that nothing described them was true of gq and false of the world.
Its supporting evidence, an absent `themes.csv` entry, proved nothing either
way: 30 of 64 `groups.csv` keys never appear in that file. What settled it was
reading the shipped `.qgs` — and finding that forms are not baked into templates
at all. `rfp_qgs_form_add()` injects them per project, so form membership is
per-project while `groups.csv` models per-template contents. That seam is what
the two rows were sitting on.

So the roster moved to its own vendored table (`form_types.csv`, 13 spatial
forms from rfp's 14 registered types) and `groups.csv` went back to describing
what the templates ship. Putting the roster into `groups.csv` instead would have
made `gq_template_layers()` report 13 forms for a template carrying 2 — the #40
defect at six times the scale.

`habitat_lateral` was the narrower half: a real paletted raster, correctly
placed, missing only an entry. Registering it made the registry's first raster,
which in turn made two latent translator holes reachable — `gq_tmap_style()`
returning an empty argument list, and `gq_mapgl_classes()` returning a
well-formed match expression that resolves against nothing. Both now refuse.

The exemption list is empty, which is the state it documents as correct.

## What the reviews changed

Worth recording, because the plan would not have landed green without them.

- Emptying `local_exempt` the obvious way **errors** the acceptance test —
  `names(character(0))` is `NULL` and `expect_setequal()` refuses it. The fix is
  `setNames(character(0), character(0))`.
- The first plan named two whole-registry sweeps to fix. There were four, plus a
  test helper whose `switch()` defaulted to `tm_dots`, so a raster would have
  silently rendered as points.
- `class_label` was missing from the first draft of the raster rows, which would
  have produced a legend reading "1" and "2" with the real labels sitting in the
  QML.
- A round-2 finding was itself wrong on probing — it claimed tightening the
  mapgl type guard broke no existing test. It broke one, whose fixture carried
  no `type` at all. That fixture was precisely how the guard's escape hatch
  nearly shipped.

## Found on the way past

`gq_style()` drops per-class `opacity`, so `bec_zone` — which carries
`fill_opacity 0.25` on all 15 rows — renders at full opacity today. Pre-existing,
filed as #71.

## Split out

- #71 per-class opacity dropped
- #72 widen the Floodplain group (19 layers in the field against 1 declared);
  blocked on a `source_type` for project rasters and on colliding layer names
- #73 `Tracking` and the two habitat-parameter layers
- NewGraphEnvironment/rfp#229 `edna` and `monitoring` have no declared symbology
