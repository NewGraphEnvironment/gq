## Outcome

Move 4 of `planning/backlog.md` (batches 9 and 10).

`gq_qgs_extract()` now reads what the template draws:
- the label source as `field` or `expression` (#6), weight from Qt's `fontWeight`, placement, the data-prep hints, units, and the halo;
- multi-layer symbols through one `symbol_read()`, giving `casing`, the railway's ticks as a dashed `overlay`, and every unmodelled layer named in a `note` (#24);
- `<layerOpacity>` and symbol alpha, folded into every opacity, with active data-defined colours flagged (#38);
- `.qlr` files and PostgreSQL `table=` sources (#23, closed with a test rather than a bcfishpass registry).

`gq_style()` surfaces casing, per-class outline and the label.

Two label translators were added (#7):
- `gq_tmap_labels()` returns `do.call(tm_text, …)` arguments with tmap's own halo;
- `gq_mapgl_labels()` returns `add_symbol_layer()` arguments.

Registry label units are now QGIS's throughout. The three CSV labels written in MapLibre pixels were converted (owner's call, asked mid-run).

The QML writer that landed on `main` meanwhile now warns when it leaves out a casing.

What was learned:
- **A hand-written fixture had encoded the original bug.** It is why the missing label field passed its test. Fixtures are now cut from real XML by a `data-raw/` script.
- **One design rested on a stale package.** The installed tmap 4.2 dev build had no halo, while CRAN's 4.4 does. That cost a detour of eight hand-built halo copies, which review round 2 reverted.
- **The review kept finding one mechanism.** It was one reading rule copied into parallel parsers and translators, each fix reaching only the copy in view. A shared reader and a mutation table ended it, not more rounds.

The durable facts are in `research/qgis_symbology_xml.md`.

## Measurement

- **Template, measured 2026-11-12** (the template repo at v0.94.0+3, byte-identical to v0.93.0):
  - 53 vector layers; 26 with `labelsEnabled="1"`, of which 4 have no settings;
  - 22 labels extracted: 14 columns, 8 expressions, 3 bold (Qt5 weights 75 and 87);
  - 11 halos, identical to the v0.93.0 extract after the halo-path fix (the first re-extract dropped all 11);
  - `source_layer` unchanged on all 48 registry layers.
- **Before the branch, 0 of 25 `reg_main` labels carried a label field.**
- **Registry changes:**
  - `railway` gains `overlay {#000000, 2.4, "0.2;2.8"}`;
  - `moti_major_structures` becomes an orange 1.46 core over a black 2.06 casing;
  - `roads_ften` classes draw at 0.7;
  - 12 polygon outlines gain an opacity equal to their symbol's;
  - notes now name what is not modelled;
  - 3 streams are flagged for a data-defined colour.
- **The streams' colour expression has empty `IN ()` lists.** QGIS 4.1.0-Master (`qgis/qgis@sha256:4eb5cd07…`) reports `hasParserError()` and evaluates it to nothing, so QGIS draws the category colours. Reported to the template repo.
- **tmap text `size = 1` is 12 pt.** A capital H is 36 px at 300 dpi, the same as `grid.text(fontsize = 12)`.
- **CSV labels were converted:** town 12 px → 9 pt, dam and planting_site 11 → 8.25 pt, halo 1.5 px → 0.4 mm. `gq_mapgl_labels()` returns them to 12 px, 11 px and 1.51 px.
- **Branch review** (`/code-check branch`, review-round1/2b/3/4):

  | round | findings | fixed | accepted | inside previous fix? |
  |---|---|---|---|---|
  | 1 | 5 | 4 | 1 | — |
  | 2 (re-run after a session restart lost the first) | 4 | 3 | 1 | no |
  | 3 | 5 | 5 | 0 | yes |
  | 4 | 4 | 4 | 0 | yes |

  It ended on an enumeration rather than a quiet round:
  - a mutation table over 29 guards the branch introduced, each removed in turn: all 29 turn their test red, and the checkout was restored byte-identical;
  - all 3 symbol-layer selections in the extractor carry the enabled-only predicate through `symbol_read()`.

  The tmap ≥ 4.3 check cannot be exercised with tmap 4.4-1 installed. Seven agents in all: a plan review and six review spawns, one of them lost.
- **Final verification:**
  - `devtools::test()`: 445 blocks, 1885 expectations, 0 failed, with the currency tests run against a template-repo checkout;
  - `R CMD check`: Status OK, 0/0/0;
  - lints, compared per file, linter and line with an `origin/main` worktree: 0 new;
  - private-reference check: 0 added.

## Owed

- Close #23 with the measurements (done by the merge's `Fixes`, with the comment in the PR body).

Follow-ups filed: gq#116 (draw casing and overlay), gq#117 (a `label_field` column for the CSV labels), gq#120 (mapgl draws no outline under a transparent fill), and one each with the conventions repo (the cartography recipe reads label units raw) and the template repo (the streams expression).

Closed by: PR (see `git log --grep "#103"`)
