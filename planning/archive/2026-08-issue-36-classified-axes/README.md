# gq#36 — classified layers lost every axis except colour

**Outcome:** fixed in v0.6.0. `tmap_classified()` mapped colour through a
per-class scale and collapsed width, dash and radius to the *first registry
class*. Each axis now maps through its own `tm_scale_categorical()`, keyed on
the same ordered class vector as colour. `do.call()` callers needed no change.

**Why it mattered more than a wrong number.** The `mapping_code` layers encode
two orthogonal variables in one composite key — habitat use drives width
(spawn 1.7 / rear 1.0 / access 0.4), barrier status drives colour. Colour
rendered correctly, so exactly half the layer's information disappeared while
the map looked entirely plausible. Same "wrong in a way that looks fine" shape
as #53, one axis over.

**Dash was worse.** The map never read `cls$dashes` at all, but
`gq_tmap_legend()` has emitted per-class `lty` since #32 — so the legend drew a
dashed key beside a line the map drew solid, on 15 of 30 stream classes. That
disagreement was invisible to every test in the suite, because each test looked
at one side only. The sweep that catches it renders both and compares them.

**Two of the issue's three items were already resolved.** Unknown class values
no longer abort the render — #54 fixed that as a side effect of passing
`levels`, confirmed by restoring the pre-#53 code and reproducing the exact
error the issue quotes. The `labels`-naming item was split to #55, being a
return-shape question rather than a lost-aesthetic one.

**Traps re-entered deliberately.** `dash_to_lty()` returns `NULL` for an
undashed class, which is right for a scalar and wrong for a vector — in #52 that
produced `lty = c(NA, …, "dashed")` and tmap rejected it at draw time.
`class_ltys()` maps `NULL` to `"solid"`. Numeric axes fall back to a scalar when
the registry defines a value for only some classes, since a half-mapped width
invents a size for the gaps and `gq_reg_custom()` can produce exactly that (#42).

**Coverage:** one existing test was pinning the bug (`expect_equal(args$lwd, 2)`)
and now asserts the scale. Restoring the bug produced 27 failures and 0 errors
across all six new and changed tests.

Commits `a1212c7`..`dc963a0` plus the release. PR #56.
