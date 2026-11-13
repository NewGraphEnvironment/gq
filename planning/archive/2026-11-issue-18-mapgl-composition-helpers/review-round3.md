# Code-check round 3 — branch 18-add-mapgl-composition-helpers @ e33d5c0

## Checklist read

- **index_code-check.md, index_code-check-r.md, index_code-check-shell.md, index_code-check-spatial.md**: read in full.
- **code-check.md**: the prose of all 14 H3s under `## Mechanisms` (table rows skipped): A guard that fails toward pass; A fixture that cannot reach the failure mode; A proxy is not the property; Verification that reads its own output; A guard's scope, escape hatches, and remedies; A fix lands in one of two callers that share a harness; Restore the bug and prove the guard fires; A shared working tree, and what generators leave in it; A wrapper's exit is not the work; Zero-length, empty, and unset are three different things; The probe is broken before the world is; Written data outlives the fix; Serialization loses meaning silently; One fact derived twice. The other 24 headings (stand-alone rules, Security, Spreadsheets/PDFs) were not read in full: nothing in the diff touches them.
- **code-check-r.md** (17 read): Base name shadowing in formal args; Cross-function consistency for label/string normalization; `$` on a list partial-matches; `nzchar(NA)` is TRUE; `paste()` with a zero-length argument; `identical()` on two reader results; Under `R CMD check`, tests run from a temp dir; `vapply(..., USE.NAMES = FALSE)`; `tryCatch(warning = )` DISCARDS the value; `match()` treats NA as a matchable VALUE; `expect_message(expr, regexp)` checks only the FIRST condition; `[[` on a named ATOMIC vector; `data.frame()` recycles a scalar; A `pkg::` call in a test; `c(name = x)`; `ifelse()` with an all-NA test; jsonlite writes an empty name. About 104 not read.
- **code-check-spatial.md** (7 read): sf: name validation must account for the geometry column; sf: reproject the polygon to get a lat/lon bbox; GeoJSON in a projected CRS; `terra::densify()` on lon/lat; `sf::st_read()` promotes a mixed POLYGON/MULTIPOLYGON; `sf::st_make_valid()`; `st_union()` fails after `st_transform()`. About 87 not read.
- **code-check-shell.md**: none read in full. The diff has no shell. 71 not read.

Probes ran in a detached worktree of HEAD (removed afterwards) with `devtools::load_all()`, mapgl 0.4.4.9000. MapLibre's behaviour was read from the `maplibre-gl.js` bundled with mapgl. Its `match` evaluates as `(typeOf(input) === this.inputType && this.outputs[this.cases[input]]) || this.otherwise`, so it is type-strict, and it errors on fewer than 5 elements.

## The mechanism

**A guard is keyed to the form of an argument, not to what the guard protects.** Every helper accepts each input in several forms. Each round-1 and round-2 fix was written inside the branch that handled the form in front of it, and the sibling forms still reach the same `match`/`fill`/`add_source` call through a permissive path. Concretely:

- `x` given vs `x = NULL`. The field and legend guards sit under `if (!is.null(x))`.
- registry `key` vs caller `classes`. The field guard sits under `if (!is.null(sty$keys))`.
- inferred vs explicit `type`. The geometry check lives only inside `layer_type()`.
- `gq_mapgl_layer()` vs `gq_mapgl_network()`. Two callers of the same registry→paint translation, and the R1 "no colour" and type guards live only in `layer_paint()`. This is "A fix lands in one of two callers that share a harness".
- each id compared with the map vs with the call's own other ids.

The fix is to key each guard to the outcome. For "will the `match` read a property the drawn features carry?", read the feature properties of the source being drawn, whichever form supplied it: `x`, or the GeoJSON gq already wrote into `map$x$sources`. For "will this layer draw in a registry colour?", route `gq_mapgl_network()` through `layer_paint()`. For "is every source id unique?", check the call's own ids against each other as well as against the map.

## Enumeration

Legend: **OK** = handled correctly; **REF** = refused (loud); **SW** = silently wrong; **perm** = permissive but defensible or caller's choice (not a finding). "probe" = run in the worktree.

### gq_mapgl_basemap(x, basemap, digits)

| arg | form | path | verdict | evidence |
|---|---|---|---|---|
| x | sf / sfc projected (polygon, line) | densify_extent → mapgl_geom | OK | test "projected bbox fits the whole area" |
| x | bbox projected | st_as_sfc → densify | OK | same test |
| x | sf/sfc/bbox in 4326 or other lon/lat | `!isFALSE(st_is_longlat)` → return g | OK | basemap.R densify_extent line 1 |
| x | one point / zero-extent bbox | `len <= 0` → return g | OK | test "an extent with no size" |
| x | mixed POINT+LINE, GEOMETRYCOLLECTION (projected) | segmentize | OK | probe: bounds finite |
| x | point + one EMPTY geometry | bbox ignores empty | OK | probe |
| x | rows present, **every** geometry EMPTY | `length(st_geometry(x)) == 0` passes, bbox NA, `!is.finite(len)` → return g | **SW** | probe: bounds `NA NA NA NA`, no error (finding 8) |
| x | 0-row sf / empty sfc | length guard | REF | test |
| x | NA CRS | st_transform | REF | st_transform errors |
| x | data.frame / other | class guard | REF | test |
| basemap | one of four | match.arg | OK / REF | test |
| digits | whole ≥ 0 | check_digits | OK / REF | test |

### gq_mapgl_network(map, streams, water, reg, ids, order_field, widths, legend, digits)

| arg | form | path | verdict | evidence |
|---|---|---|---|---|
| streams/water | NULL | skipped | OK | test |
| streams/water | 0-row sf | `&& nrow()` skip, no layer, no legend | perm | probe 7: 0 layers. `gq_mapgl_layer()` refuses 0 rows, so the contract differs, but the result is visible on the map |
| streams/water | sfc | `!is.null(x) && nrow(x)` | REF | probe: "invalid 'y' type in 'x && y'" (an obscure message, but loud) |
| water | polygons | lake paint | OK | test |
| water | **lines** | fill layer, no geometry check | **SW** (fragile) | probe 8: `type: fill` on LineStrings, no error (finding 6) |
| streams | lines | streams_all | OK | test |
| streams | **points** | line layer, no geometry check | **SW** | probe 8b: `type: line` on Points. MapLibre's line bucket draws nothing for a single-vertex line (finding 6) |
| streams | carries `feature_code` | classes expr + opacity expr | OK | test |
| streams | no `feature_code` | first class colour and opacity | OK (documented) | test |
| streams | missing `order_field` | refused | REF | test |
| reg | `lake` simple polygon with colour | gq_mapgl_style | OK | test |
| reg | `lake` with **no fill colour** (project override) | `paint$\`fill-color\`` NULL → add_fill_layer(NULL) | **SW** | probe 6: fill-color NULL, no error. The same registry through `gq_mapgl_layer(key = "lake")` → "carries no colour" (finding 5) |
| reg | `lake` typed **line** | gq_mapgl_style → line paint; fill-color NULL | **SW** | probe 6c (finding 5) |
| reg | `streams_all` unclassified (override) | `if (fld %in% ...)` with NULL fld | REF | `if (logical(0))` errors "argument is of length zero" (an obscure message, but loud) |
| reg | no `lake` / `streams_all` | reg_layer | REF | reg_layer |
| ids | default / named subset | or_null(ids[[..]], stop()) | OK / REF | test |
| ids | id already on map | `taken` | REF | test (R2 fix) |
| ids | **water id == streams id** | `taken` compares with the map only | **SW** | probe 1: sources `"x" "x"`, no error (finding 1) |
| widths | 2 positive | order_width | OK / REF | test |
| legend | TRUE | one row per layer, first class label/colour | OK | streams_all classes all `#a9e0ff`, so one row is accurate today |
| digits | — | check_digits | OK / REF | — |

### gq_mapgl_layer(map, id, x, source, key, classes, color, reg, field, type, width, widths, radius, opacity, legend, legend_title, popup, visible, digits, ...)

| arg | form | path | verdict | evidence |
|---|---|---|---|---|
| id | non-empty string | check | OK / REF | test |
| id | already a layer | refused | REF | test (R2) |
| id | two ids that sanitise to one legend id (`"a b"`, `"a_b"`) | duplicate DOM id | perm | probe 16: two `id="legend_a_b"`. mapgl's toggling reads `data-layer-id` (maplibregl.js:2324), and the duplicated CSS is identical, so nothing visible breaks |
| x | sf, one geometry family | layer_type | OK | tests |
| x | mixed / unsupported geometry | layer_type | REF | test |
| x | 0 rows | refused | REF | test |
| x | sfc | `!nrow(x)` | REF | probe: "invalid argument type" |
| x | NULL, source on map | type from `lyr$type` or the existing layer | OK for `color`/`classes` | test "two layers can draw one source" |
| x | **NULL + classified `key`** | `keep <- if (!is.null(x)) … else TRUE`; field guard under `!is.null(x)` | **SW** | probe 2: bec_zone over a source with `zone` not `ZONE` gives no error and a legend of every class, with every feature in the `#888888` fallback. This is exactly R2's defect through the other form of `x` (finding 2) |
| x | **NULL + simple `key` of another geometry** | `layer_type()` returns `lyr$type`, so `want == lyr$type` and the check is vacuous | **SW** | probe 3: `key = "lake"` over a point source → a `fill` layer, no error. The control (probe 3b, `x` given) is refused (finding 3) |
| source | new id, x given | add_source | OK | test |
| source | existing, x given | refused | REF | test (R2) |
| source | absent, x NULL | refused | REF | test |
| key | simple, with colour | gq_mapgl_style paint | OK | test |
| key | simple, no colour | refused | REF | test (R1) |
| key | type ≠ geometry of x (type inferred) | layer_paint `want` | REF | test |
| key | classified, field in x | classes expr, legend filtered and collapsed | OK | tests (R1) |
| key | classified, field absent from x | refused | REF | test (R2) |
| key | classified, field present but **numeric** column vs JSON string keys | `%in%` coerces, so the legend lists the class; MapLibre `match` is type-strict → fallback grey | **SW (latent)** | probe 14: custom layer with keys `"1"`,`"2"` and an integer `stream_order`. The legend has "One", the data holds `"stream_order":1`, and the match label is `"1"`. No shipped vector layer has numeric keys today (only `habitat_lateral`, a raster, which is refused) (finding 7) |
| key without reg | refused | REF | test |
| classes | complete, field in x | match_expr | OK | test, parity |
| classes | missing field/values/colors | refused | REF | test |
| classes | colours ≠ values length; labels ≠ length | refused | REF | test |
| classes | **`field` absent from x** | no check on this path (`sty$keys` is NULL) | **SW** | probe 4: no error; every feature draws `default` under a legend of every class (finding 4) |
| classes | values typed differently from the column (int vs chr) | type-strict match → default | perm | probe: `values = 1:2` over `"1"`,`"2"` → no error. This is the caller's own values, documented "integers stay integers" |
| classes | duplicate values | MapLibre "Branch labels must be unique" in the console | perm | probe 13: no R error. Caller error, and the layer fails visibly |
| color | hex / R name / NA / non-colour / length ≠ 1 | to_hex | OK / REF | tests |
| reg | given without key | ignored | perm | — |
| field | with classified key | rewrites `[[2]]` of colour and opacity expr | OK | test |
| field | with `color` / `classes` / simple key | ignored | perm | probe 10: no error. Harmless, because the parameter is documented for registry layers |
| type | NULL | layer_type | OK | — |
| type | **explicit and ≠ geometry of x** | `or_null(type, layer_type(...))` skips the geometry check, and the registry check compares against `type`, not against x | **SW** | probe 11b: `key = "lake"` (polygon), points x, `type = "fill"` → no error. Probe 11: `color`, points, `type = "fill"` → a fill layer over points (finding 3) |
| type | an invalid string (`"polygon"`) | `switch` returns NULL → do.call error | REF | loud |
| width | number / expression | args$line_width | OK | test |
| width | column name present | order_width | OK | test |
| width | **column name absent from x** | no presence check (network has one) | **SW** | probe 5: no error. MapLibre's `interpolate` on `["get", …]` null raises an evaluation error per feature and falls back to the default `line-width` of 1 (finding 4) |
| width/radius | given for another type | ignored | perm | documented by type |
| widths | validated only via order_width | — | OK | — |
| radius | number / expression | args | OK | test |
| opacity | override / NULL | or_null | OK | — |
| legend | TRUE / FALSE | add_categorical_legend, stylesheet once | OK | tests |
| legend_title | default id / given | single → row name, untitled | OK | test |
| popup | expr from gq_mapgl_popup | args$popup | OK | test |
| popup | column name absent | no check | perm | mapgl shows an empty popup. Not silent at render |
| visible | TRUE / FALSE / other | isTRUE | OK | test |
| digits | — | check_digits | OK / REF | — |
| ... | extra paint/layout args | do.call | OK | test |

### gq_mapgl_popup(x, fields, missing, digits)

| arg | form | path | verdict | evidence |
|---|---|---|---|---|
| x | data.frame / sf / tibble | `[[<-` keeps the sf | OK | test |
| x | list | refused | REF | test |
| x | already has popup_n | refused | REF | test (R1) |
| fields | named chr, columns present | popup_n columns, concat expr | OK | test |
| fields | unnamed / NA or empty names / absent column | refused | REF | test |
| fields | the sf geometry column | `as.character(sfc)` | perm | probe 15: `"c(-126.5, 54.4)"`. Contrived (spatial "name validation must account for the geometry column") |
| column | numeric (incl. NA, Inf) | per-value formatC fg | OK | test |
| column | logical incl. all-NA | `ifelse` returns logical NA, then `out[is.na(v)] <- missing` coerces to character | OK | the `ifelse()` all-NA rule does not bite, because every NA cell is overwritten |
| column | Date / POSIXct / factor | `is.numeric()` is FALSE → as.character | OK | vignette `observation_date` |
| missing | one string / other | check | OK / REF | test |
| digits | ≥ 1 | check | OK / REF | test |

### gq_mapgl_controls(map, layers, position, navigation, scale)

| arg | form | path | verdict | evidence |
|---|---|---|---|---|
| layers | NULL | all ids | OK | test |
| layers | fully named | label = name | OK | test |
| layers | unnamed | label = id | OK | test |
| layers | character(0) | no switch | OK | test |
| layers | absent id | refused | REF | test |
| layers | non-character | refused | REF | — |
| layers | **partly named** `c(A = "a", "b")` | `!is.null(names(layers))` → mapgl `layers_config` label `""` | **SW** | probe 9: names `c("A", "")`. maplibregl.js:2308 `link.textContent = config.label` → a switch entry with no text (finding 9) |
| position / navigation / scale | — | passed / isTRUE | OK | test |

### gq_mapgl_classes(layer, property) — new `property` branch

| arg | form | path | verdict | evidence |
|---|---|---|---|---|
| property | NULL / `*-color` | colour match | OK | test |
| property | `*-opacity`, all equal | scalar | OK | test (bec_zone 0.25) |
| property | `*-opacity`, mixed | match, absent = 1, fallback 1 | OK | test (roads_dra) |
| property | outline/stroke/width/other / length 2 | refused | REF | test |
| property | NA_character_ | `if (NA)` | REF | loud |
| layer | no classification / raster / untyped | refused | REF | existing tests |
| layer | every class is `__empty__` | 3-element `match` (colour) / scalar 1 (opacity) | perm | MapLibre refuses a match shorter than 5 (`t.length<5` in bundle). This predates the branch for colour, and no shipped layer has it |
| class | opacity stored as text (CSV) | vapply numeric(1) | REF | loud |

## Findings

- **[severity: bug]** R/gq_mapgl_network.R:43-57 — `gq_mapgl_network(map, streams = s, water = w, ids = c(water = "x", streams = "x"))` adds the source `"x"` twice and the layer `"x"` twice, with no error. Probe: `vapply(m$x$sources, `[[`, "", "id")` is `"x" "x"`. The R2 fix built `taken` from the call's ids intersected with the ids **already on the map**, so a collision between the call's own two ids never meets the guard. MapLibre throws on the second `addSource`, and every source and layer after it fails to draw, which is the failure R2 set out to stop. Refuse `anyDuplicated()` over the ids actually used.
  - **Rule:** code-check.md "A guard's scope, escape hatches, and remedies"

- **[severity: bug]** R/gq_mapgl_layer.R:115-122 — with `x = NULL` (a second layer on a source already on the map) and a classified registry `key`, both earlier fixes are skipped. The field guard sits under `!is.null(x)`, and `keep <- if (!is.null(x)) … else TRUE` lists every class. Probe: draw a source whose column is `zone`, then `gq_mapgl_layer(m, "bec", source = "s", key = "bec_zone", reg = reg)` gives no error and a legend with every bec_zone class, while every feature draws the `#888888` fallback. That is exactly the R2 defect, reached through the other form of `x`. The data is on the map: gq wrote it as GeoJSON into `map$x$sources[[i]]$data`. So the guard and the filter can read the source's feature properties when `x` is NULL, and fall back only for a source gq did not write.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: bug]** R/gq_mapgl_layer.R:110 and 210-217 — the check that a registry layer matches the geometry it draws holds only when `type` is inferred **from `x`**. In two forms the check is vacuous:
  - `x = NULL` with a `key`: `layer_type()` returns the registry's own type before it looks at the layer already drawing that source. `layer_paint()` then compares `lyr$type` with a `want` derived from `lyr$type`, and the two cannot differ. Probe: `key = "lake"` over a point source → a `fill` layer, no error. The same call with `x` given is refused, "is a polygon layer, not a point one".
  - an explicit `type`: `or_null(type, layer_type(...))` never calls `layer_type()`, so `x`'s geometry is never read. Probe: points, `key = "lake"`, `type = "fill"` gives no error, and so does points with `color = …` and `type = "fill"`.

  The comparison's operands trace back to one source, so it has no true branch in either form. When `x` is NULL, cross-check against the existing layer's type or the source's geometry. When `type` is explicit, check it against `x`'s geometry (allowing `line` over polygons, which is a legitimate outline).
  - **Rule:** code-check.md "Restore the bug and prove the guard fires"

- **[severity: bug]** R/gq_mapgl_layer.R:112-121 and 141 — two column references are never checked against `x`, though a sibling path refuses the same omission:
  - `classes$field`: the R2 field guard is inside `if (!is.null(sty$keys))`, which holds only for a registry layer. Probe: `classes = list(field = "species", …)` over data with `sp` gives no error. Every feature draws `default`, under a legend listing every class, which is the all-grey map R2 refused for registry layers.
  - `width = "<column>"`: `gq_mapgl_network()` refuses a missing `order_field` ("set `order_field`"), but `gq_mapgl_layer()` builds `order_width(width, widths)` unchecked. Probe: `width = "order"` over data with `stream_order` gives no error. MapLibre's `interpolate` over a null `get` raises a per-feature evaluation error and falls back to the default `line-width` of 1, so the order scaling silently disappears.

  Check both against `names(x)`, or against the source's properties when `x` is NULL.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: bug]** R/gq_mapgl_network.R:51-56 — the water layer reads `gq_mapgl_style(reg_layer(reg, "lake"))$paint` and passes `paint$\`fill-color\`` with neither of the guards `layer_paint()` applies for `gq_mapgl_layer(key = "lake")`: the R1 "carries no colour" refusal and the registry-type check.
  - Probe, `lake` overridden with no fill colour: `fill_color = NULL`, no error. `gq_mapgl_layer(key = "lake")` on the same registry refuses with "carries no colour to draw".
  - Probe, `lake` overridden as a `line` layer: `fill_color` NULL again.

  Merging a project CSV over `gq_reg_main()` is the documented override route (CLAUDE.md, "Style precedence"). In both cases MapLibre fills the water in its default black, styled as if from the registry. This is R1's defect, unfixed in the second caller. Route the water paint through `layer_paint("fill", lyr, …)` so both callers share the guards.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** R/gq_mapgl_network.R:49-71 — `gq_mapgl_network()` never checks the geometry of `water` or `streams`, while `gq_mapgl_layer()` refuses a registry layer drawn on the wrong geometry. Probe: streams given as points → a `line` layer on Points, which MapLibre draws as nothing. Water given as lines → a `fill` layer on LineStrings. An empty stream layer with no error is the silent outcome.
  - **Rule:** code-check.md "A fix lands in one of two callers that share a harness"

- **[severity: fragile]** R/gq_mapgl_layer.R:121 — the legend filter `sty$keys %in% x[[sty$field]]` coerces types, so a numeric column "contains" the string key `"1"`. MapLibre's `match` is type-strict (bundle: `typeOf(input) === this.inputType && … || this.otherwise`), so an integer property never matches a string label. Registry class keys are always strings, being JSON names. Probe, a custom classified line layer with keys `"1"`/`"2"` over an integer `stream_order`: the legend lists "One" and every line draws the `#888888` fallback, with no error. The presence check is a proxy for "the match will match". It is latent: no shipped vector layer has numeric keys today (`habitat_lateral` is a raster and is refused), but a project registry classifying on a numeric field reaches it. Compare as the browser will, refusing or converting when the column is not character.
  - **Rule:** code-check.md "A proxy is not the property"

- **[severity: fragile]** R/gq_mapgl_basemap.R:39 — the "no geometry to fit" guard tests `length()`, so an sf whose rows all carry EMPTY geometries passes. `densify_extent()` sees a non-finite length and returns, and the map gets `bounds = c(NA, NA, NA, NA)` with no error (probe). It is the same "fits what is drawn" contract as R1/R2's extent fixes, with the guard on a proxy (row count) rather than the property (a finite extent). Test `all(is.finite(sf::st_bbox(x)))` after the transform.
  - **Rule:** code-check.md "Zero-length, empty, and unset are three different things"

- **[severity: fragile]** R/gq_mapgl_controls.R:117-125 — a partly named `layers` (`c(Habitat = "rules", "grade")`) passes the checks. Because `names()` is non-NULL, mapgl builds `layers_config` with label `""` for the unnamed entry, and maplibregl.js:2308 sets `link.textContent = config.label`, so the switch shows an entry with no text for `grade` (probe: names `c("A", "")`). The roxygen promises two forms, fully named or unnamed, and the mixed form falls through to neither. Fill each empty name with its id, or refuse.
  - **Rule:** none

No defect was found in how the R1/R2 fixes were made within the form each targeted: look-collapse after the filter, `popup_n` columns, densify for any projected input, the colour refusal in `layer_paint()`, the registry field refusal with `x` given, and the duplicate refusal against the map. Each finding above is the same fix missing from a sibling form.
