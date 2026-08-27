# gq#61 — the vignette maps were correct and did not communicate

**Outcome:** shipped in v0.9.0. The composition map's most prominent feature is
now in its legend, correctly labelled, and the map has a subject you can see.
Two duplicate issues closed and three consumer repos unblocked along the way.

**The headline defect was a legend that described the layer list, not the map.**
A 397-feature salmon habitat network — the heaviest ink on the figure by a
factor of three, measured — was styled from the registry and absent from the
legend, while the prose directly beneath it described that layer's widths and
dashes. Nothing caught it because building a legend from the layers you listed
answers *"did I list my layers"*, which always says yes. The fix that matters is
not the one-line addition but the test: it parses the map chunk with R's own
parser and fails the build if a layer drawn from the registry is not legended.

**The labels were wrong at source, and had been for three months in three
places.** `ACCESS` was translated through the *barrier-status* vocabulary, so
`ACCESS;ASSESSED` read `"No known barriers; known barrier"`. Already tracked in
bcfishpass#13, and duplicated in gq#33 and gq#37 — which the user remembered
having seen before, and which a search confirmed before any code was written.
The real cost was downstream: **three consumer repos had each independently
hand-rolled the same token decoder**, which is exactly the duplication the
registry exists to prevent. That reversed gq#33's explicit "no gq code change is
expected" and made this Phase 1 rather than vignette polish.

The correction lives in `data-raw/reg_build_main.R`, not in `reg_main.json`
(a build artifact — a hand-edit is reverted on the next rebuild) and not in
`reg_custom.csv` (`gq_reg_custom()` has no per-class width or dash field, so
routing 90 classes through it would silently drop the habitat widths from #16
and the intermittent dashes from #36). It stops the build when it finds nothing
to correct, so it cannot outlive the bug it was written for. Both answers were
tested.

**The editorial cut did more for the map than any styling change.** 130 of 146
crossings are modelled candidates, not surveyed sites; at their correct registry
size they were 89% of the point symbols and buried the network the map exists to
describe. Removing them is what made the habitat visible. Explicitly *not* done:
hand-tuning `size` down for one class, which would have reintroduced the
per-map guessing #16 removed.

**Two placement lessons, both settled by rendering rather than reasoning.**
Top-left looks like the emptier corner for a 19-row legend and is the wrong
answer — hung there it covers the northwest arm and hides the barrier crossings.
And the "~20% dead band" this issue was filed complaining about does not exist
as described: `gq_bbox_aspect()` pads symmetrically, 21.7% above and 21.7%
below, and the lower band is simply hidden under the legend. That was **my own
false claim**, caught as the plan review's sole blocker; acting on it would have
introduced an asymmetry into a correct exported function.

**Three drafts of the coverage guard failed, instructively.** Regex-on-source
read `gq_tmap_style(reg, "name")` out of a markdown code span and swept comment
prose into the legend set. Then `names()` on a call with no named arguments is
`NULL`, and `logical(0) | TRUE` is `logical(0)`, so every unnamed call subset to
nothing. Worst of the three: the first version listed all nine drawn layers as
exemptions with the reason "drawn and legended" — exempting everything and
making the assertion **incapable of failing**. It reads as diligence.

**First real use of `cartography.md`'s "does it communicate" half** (soul#78,
written the same day). All twelve checks pass; two were failing before this
branch. Check 8 — rank the rendered image, then confirm each of the top few is
in the legend — is the one that would have caught this, and it works only
because it says to rank the *image* rather than the layer list.

`gq-intro.Rmd` was split to **#62**: the plan carried it as one checkbox, the
review measured it as a re-composition with no registry legend at all and 87% of
its crossings outside its own AOI.

Commits `1dbe8f8`..`ed2b76f`. PR #63. Closes #33, #37.
