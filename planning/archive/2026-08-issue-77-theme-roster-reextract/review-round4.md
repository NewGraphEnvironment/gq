# Review round 4 — gq#77

Scope: one question — **has the recursion terminated?** Target
`tests/testthat/test-gq_groups.R` at `HEAD` (`c0693c9`), branch
`77-re-extract-the-theme-roster-high-detail`.

Control before any perturbation: `test-gq_groups.R` **FAIL 0 | PASS 76**.
Tree clean before and after every experiment (`git status --porcelain` empty).

**Verdict: NOT TERMINAL.** One member of the class remains, and it is
demonstrable rather than argued: the whole suite runs **FAIL 0 | PASS 1056**
under CI conditions with an opaque satellite basemap switched **on** in a theme
in both templates.

The recursion did bottom out in the direction round 3 was chasing — `groups.csv`
is hand-maintained, has no generator, and there is nothing above it to pin
against. It has not bottomed out on the other axis: round 3 pinned how the set
may **grow within `Base - misc`**, and left unpinned the fact that opaque
basemaps only ever land **in `Base - misc`**.

---

## 1. Is round 3's own fix coincidence-scoped?

Yes, on one of the three restored defects. All three were executed, not reasoned
about.

### (a) opaque basemap added to a DIFFERENT group — **NOT CAUGHT**

Perturbation, the realistic shape (rfp adds a fifth xyz basemap; gq vendors it
the normal way):

```
inst/registry/groups.csv   + "Web Mapping Services",,esri_world_imagery,3,wms
inst/styles/index.csv      + "esri_world_imagery",...,"service"
inst/styles/services/esri_world_imagery.qml   (vendored)
inst/registry/themes.csv   + bcfishpass_mobile,High Detail - Crossings,esri_world_imagery,true
                           + bcrestoration_mobile,High Detail - Crossings,esri_world_imagery,true
test-gq_groups.R:255       nrow 232L -> 234L   (the deliberate re-pin :247-248 instructs)
```

Result, `test-gq_groups.R` alone: **FAIL 0 | PASS 76.** Every assertion in
`no theme turns an opaque basemap on` passes:

| assertion | line | result |
|---|---|---|
| `opaque` == `Base - misc` wms | 299-301 | TRUE — the new layer is not in `Base - misc` |
| roster names only `esri_world_topo` of the four | 306 | TRUE — `opaque` is a literal, the new key is not in it |
| no opaque basemap visible | 309-315 | TRUE — same reason |
| `esri_world_topo` in 9 rows | 319 | TRUE |

Full suite under CI conditions (`RFP_STYLES_DIR` / `RFP_TEMPLATE_DIR` pointed at
a nonexistent path, which is what every gq CI run is — gq is public, rfp
private, and both drift tests `skip_if` the store is absent):

```
[ FAIL 0 | WARN 1 | SKIP 2 | PASS 1056 ]
```

Green, with a live satellite raster switched on in a theme. That is the exact
regression `NEWS.md` records as having "twice cost a field user a layer".

With rfp present locally the run showed exactly one failure —
`test-gq_style_qml.R:201` *"esri_world_imagery.qml (absent upstream)"* — which
is an artifact of my synthetic layer having no rfp counterpart. In the real
scenario the layer originates in rfp, so that check passes too. The CI run above
is the decisive one either way.

**Why this is a real exposure, not a hypothetical:**

- `Web Mapping Services` sits at `order` **8** in both templates, above
  `Base - lidar` (9) and `Base - misc` (10) — `inst/registry/template_groups.csv`.
  An opaque layer there occludes *more* than one in `Base - misc`, not less.
- Themes already reach that group: `groups.csv` wms membership is six layers,
  four in `Base - misc` and two (`fire_perimeters_current`,
  `frep_rip2021_mar2022`) in `Web Mapping Services`, and the roster is free to
  name any of them.
- `Base - lidar` is a real template group gq deliberately does not declare. An
  orthoimagery or hillshade layer declared into it later is equally invisible to
  the pin.
- The rate-of-change argument round 3 used (`a579752`, `Base - misc` 3 rows -> 7
  in one commit) says the *set of basemaps* grows in jumps. It says nothing about
  the group they land in.

### (b) existing opaque basemap's `source_type` changed off `wms` — **CAUGHT, three times**

`google_satellite` `wms -> local` in `groups.csv`, plus two `themes.csv` rows
switching it on, count re-pinned to isolate:

```
:299  Expected `opaque` to have the same values as g$layer_key[Base - misc & wms]
      Needs: "google_satellite"
:306  Expected intersect(...) to have the same values as "esri_world_topo"
      Needs: "google_satellite"
:310  opaque basemap switched on: bcfishpass_mobile High Detail - Crossings
      google_satellite; bcrestoration_mobile High Detail - Crossings google_satellite
```

The third message names the real cause exactly. The literal list is what saves
this: because `opaque` does not shrink when the data does, the property check at
:309 keeps working on a layer the pin can no longer see. Round 3's "keep it a
literal" call is vindicated here.

### (c) `Base - misc` gains a NON-opaque wms layer — **fires, correct-but-annoying**

Added `"Base - misc",,some_translucent_overlay,9,wms`:

```
:299  Expected `opaque` to have the same values as g$layer_key[Base - misc & wms]
      Absent: "some_translucent_overlay"
```

One failure, naming the layer. This is a false alarm on a legitimate addition —
and it is the right behaviour: the message reads as "declare whether this is
opaque", which is a decision recorded rather than an omission, and
`test-gq_groups.R:288-291` already tells the next person to widen the pin with a
stated reason. **Not a finding.**

---

## 2. Is there a level above `groups.csv`?

**In the generation direction, no — this is where it bottoms out.**

- `groups.csv` is **hand-maintained**. Nothing in `data-raw/` writes it;
  `styles_vendor.R:272` and `reg_extract_themes.R:109` only *read* it. Its git
  log is hand-authored commits (`9608a64`, `a877534`, `6707492`, `a579752`, …).
- The one generated composition artifact is
  `inst/registry/template_groups.csv`, vendored from the rfp `.qgs` files by
  `data-raw/reg_extract_template_groups.R`, and it **does** have a live-template
  drift test (`test-template_drift.R:326-354`). But `qgs_group_table()`
  (`R/utils_qgs_groups.R`) returns `group_path, depth, order` only — no layer
  membership, no `source_type`. It cannot witness the rows the opaque pin reads.
- So the `.qgs` templates are the ultimate authority for which layer sits in
  which group, and nothing in gq compares that. gq#78 covers `themes.csv` drift
  only, so this is wider than the accepted deferral — but it is a separate,
  larger piece of work (a layer-level `qgs_layer_table()` beside the group one),
  not a further turn of this recursion. Recording it, not raising it as a #77
  blocker.

The consequence for the verdict: round 3's pin **cannot** be pushed one level
further up, because there is no generator to pin it to. The remaining exposure is
one axis **wider**, not one level **up** — the population the judgement is
applied to, rather than the source the population is read from.

---

## 3. Independent re-enumeration of the file

Re-derived from the current file rather than from round 3's table. Literals and
their scoping premises:

| line | literal / assertion | scoped by | verdict |
|---|---|---|---|
| 7 | `nrow > 40` | — | loose bound, fine |
| 16-17 | `lake` source_layer / type | `layer_key` uniqueness, pinned in `test-composition_integrity.R:118` | property |
| 49 | `crossings_pscis_assessment` source_layer | same | property |
| 131 | three dead theme names absent | premise (rfp never ships them) unasserted — but the failure direction is **loud and safe**: rfp shipping "Field View" turns this red and names it | not this class |
| 176-177 | exactly two templates | pinned (round 1) | property |
| 185-188 | the four shared themes | pinned (round 1) | property |
| 202-213 | per-theme key-set + flag agreement | named lookup; premise (no duplicate key) pinned at 267 | property |
| 236-241 | no all-zero pair | premise (non-empty roster) pinned at 255 | property |
| 255-256 | 232 rows, 9 pairs | pinned constants | property |
| 267 | no duplicate key | — | property |
| 272-273 | Land Tenure 26 / 22 | — | property |
| 283-284 | `opaque` four keys | pinned to `Base - misc` wms at 299-301 — **and only there** | **coincidence-scoped, finding (a)** |
| 306 | roster names only `esri_world_topo` | `opaque` | inherits |
| 309-315 | no opaque basemap visible | `opaque` | inherits |
| 319 | `esri_world_topo` × 9 | entailed by 255-256 + 267 | consistency witness |

**One member remains, and it is the same three assertions round 3 touched.**
Nothing else in the file is enforced by two things happening to agree. Round 3's
claim that "with finding 1's pin applied, every invariant in the file is enforced
by the property it asserts" is false in exactly the way rounds 1-3 were false —
the declaration is complete relative to `Base - misc` and incomplete relative to
the world.

---

## Finding

**[fragile]** `tests/testthat/test-gq_groups.R:283-284`, pinned at `:299-301` —
the pin closes growth of `Base - misc`'s wms membership and leaves unpinned the
premise that opaque basemaps *only appear in `Base - misc`*. An opaque basemap
declared into any other group is invisible to all four assertions, and the suite
is green on CI with one switched on (measured above: FAIL 0 | PASS 1056).

**Fix — one line, and it is the same pattern applied to the population instead of
the group.** Partition the whole `wms` set, which is what `groups.csv` actually
enumerates:

```r
  # `Base - misc` is not where opaqueness lives -- `Web Mapping Services` sits
  # ABOVE it in both templates (template_groups.csv order 8 vs 10), so an opaque
  # layer there occludes more, not less. Partition every wms layer instead, so a
  # new tile service anywhere fails here until someone records which kind it is.
  overlay <- c("fire_perimeters_current", "frep_rip2021_mar2022")
  expect_setequal(c(opaque, overlay), g$layer_key[g$source_type == "wms"])
```

Verified discriminating in both directions:

```
against the exploit  ->  FAIL 1, "Absent: esri_world_imagery"   (names the layer)
against clean HEAD   ->  FAIL 0 | PASS 77                        (control)
```

Keep the existing `Base - misc` pin beside it — it is what catches (c), and it
is the one that carries the rfp#185 story.

**Why this one terminates.** After it, the residual is "an opaque basemap could
arrive with a `source_type` other than `wms`". That is not a data coincidence but
close to definitional: `test-composition_integrity.R:35-59` already defines `wms`
as "no table; these are tile/service endpoints", and an xyz basemap is a tile
service by construction. Pinning the wms partition moves the guard from resting
on *where the layers happen to sit* to resting on *what kind of thing they are* —
which is the judgement the comment at :288-291 says belongs written down, applied
to the full population it was always meant to cover. There is no further level:
`groups.csv` is hand-maintained (§2), so nothing above it exists to pin to.

---

## Verdict

**NOT TERMINAL** — one member left, at `test-gq_groups.R:283-284` / `:299-301`.
Next level is the population, not the source: partition all six `wms` layers
rather than the four in `Base - misc`. One line, verified discriminating, and it
is the last one — §2 establishes there is nothing above `groups.csv` to recurse
into.
