# gq#53 — classified layers mislabelled a data subset

**Outcome:** fixed in v0.5.1. `tm_scale_categorical()` matches colours by name
but labels by position, and derives its levels from the data — so a layer whose
data carried 3 of the registry's 26 road classes drew the first three labels
whichever classes those were. `gq_tmap_style()` now passes `levels` alongside
`labels` from the same ordered registry vector, making the alignment structural
rather than coincidental. No exported signature changed.

**The planning was worth more than the fix.** Four probes run before writing the
plan disproved two of the issue's own premises. The issue proposed a `present =`
argument mirroring `gq_tmap_legend()`; `levels` made that unnecessary, and an
automatic fix beats one callers must remember. The issue also stated the drawn
layer was wrong while the legend was right — the reverse was true, since
classified layers set `tm_legend(show = FALSE)` and colours already matched by
name, so the drawn map measured `max|diff| = 0` either way. Real impact was a
warning on every classified draw plus a latent legend defect.

**Instrument choice mattered.** Pixel comparison confounded a label change with
legend re-layout and sent three probes down a wrong path, reporting a regression
in the all-present case that did not exist. Reading text and colours out of the
rendered grob tree settled in one run what pixels had muddied across three, and
became the test helper.

**Coverage:** all 11 classified registry layers swept, 10 of which discriminate
between true and positional labels. `crossings_pscis_assessment` — the central
point layer of every fish passage map — would have shown a passable crossing as
"Barrier". Restoring the bug produced 34 failures and 0 errors.

Commits `ff5af9f`..`669b095` plus the release. PR #54.
