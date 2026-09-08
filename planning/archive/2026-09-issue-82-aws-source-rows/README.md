## Outcome

Three `aws` rows in the registry disagreed with what the `newgraph` bucket actually
stages. Exploration falsified the issue's central premise — `rfp/inst/lookups/rfp_source_aws.txt`
is **not** the list a project build acts on; `rfp_project_create()` resolves its layer
set through `gq::gq_template_layers()`, so gq's registry was the sole cause of both
failed downloads rather than one of two disagreeing lists. That changed the work from a
cross-repo negotiation into a gq fix plus two upstream reports.

`habitat_lateral` was retyped `local` → `aws` with `source_layer = habitat_lateral.tif`
(it had never been requested, so every project clipped the raster by hand);
`bcfishobs_fiss_fish_observations` follows an upstream rename to `bcfishobs.observations`;
`dam` was deliberately left alone because nothing stages `bcfishpass.dams` and dropping
the row would hide the gap rather than fix it. The durable knowledge about how rfp
resolves and fetches layers is in [`research/rfp_layer_sourcing.md`](../../../research/rfp_layer_sourcing.md).

Two design points worth carrying. The `bcfishobs` correction went into
`data-raw/reg_build_main.R` rather than the extracted `reg_qgis_restoration.json`,
following the pattern that script already used for bcfishpass#13 — the JSON is a
transcript of rfp's template, so editing it would make the file lie about its provenance
*and* be reverted by the next re-extraction, while `reg_custom.csv` was ruled out because
`gq_reg_merge()` replaces a layer entry rather than merging fields. And the `aws` source
rule was rewritten: it checked `grepl(".", source_layer, fixed = TRUE)` while claiming to
test schema-qualification, which `habitat_lateral.tif` satisfies by accident.

The drift guard that would have caught all three rows was scoped out deliberately and
stays with #78, which already owns the currency problem for gq's rfp-vendored artifacts.

## Measurement

Bucket resolution for gq's distinct `aws` `source_layer` values, anonymous HTTP HEAD
against `https://newgraph.s3.us-west-2.amazonaws.com/` — the same request rfp's own
`wget` makes, so no credentials and no `aws s3 ls`:

| | before | after |
|---|---|---|
| resolve 200 | **7 of 9** | **9 of 10** |
| 404 | `bcfishobs.fiss_fish_obsrvtn_events_vw`, `bcfishpass.dams` | `bcfishpass.dams` only |

The set grew by one because `habitat_lateral.tif` joined it. The remaining 404 is the
deliberately-kept row, filed at NewGraphEnvironment/db_newgraph#20.

What changed because of it: `habitat_lateral` stops being hand-clipped per project, and
the fish-observations download stops failing on every build — though the layer does not
return to the map until NewGraphEnvironment/rfp#305 lands, because `source_layer` is
simultaneously the S3 object stem, the GeoPackage table name and the `.qgs` `layername=`.

Two wrong turns, both kept because they are the useful part:

- An assertion that the file target does **not** match `^schema\.table$` was written,
  and went red on correct data — `habitat_lateral.tif` matches it, because `tif` is a
  valid table token. No regex separates a filename from a qualified table; the
  discriminator has to be a human naming the row, which is why the exemption is a named
  list rather than a cleverer pattern.
- The approved plan said to edit the extracted JSONs. That was changed mid-run on
  finding the existing bcfishpass#13 correction block, which solves the same problem
  better.

`devtools::test()` reports 1111 pass, 2 fail. Both failures are **pre-existing on
`origin/main`** at identical lines (`test-gq_style_qml.R:201`,
`test-template_drift.R:353`), verified by running those two files in a throwaway
worktree detached at `e3b0178`; this branch touches neither test's inputs. They are the
stale rfp-vendored artifacts of #70 and #78, and they only fire at all because rfp is
checked out on this machine — in CI both skip, which is the weakness #78 exists for.

Closed by: PR for #82
