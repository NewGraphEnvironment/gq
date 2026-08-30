# Code review — round 1

Staged diff on `64-three-local-layers-no-registry-entry`: vendors the rfp form-type
roster into `inst/registry/form_types.csv`, adds `data-raw/reg_extract_form_types.R`,
`gq_form_types()`, and `tests/testthat/test-gq_forms.R`.

Every claim below was probed, not reasoned about. Probe transcripts are summarised
inline. An rfp source checkout was available at
`/Users/airvine/Projects/repo/rfp/inst/lookups/rfp_form_types.csv`, so the upstream
side is measured rather than assumed.

---

## Findings

### 1. [fragile] `data-raw/reg_extract_form_types.R:82` — `dirty` fails toward "clean"

```r
git <- function(...) suppressWarnings(
  system2("git", c("-C", dir, ...), stdout = TRUE, stderr = FALSE)
)
dirty <- length(git("status", "--porcelain", "--", file)) > 0L
```

`stdout = TRUE` returns stdout only; the exit status is available solely as a
`"status"` attribute, and only alongside a warning that `suppressWarnings()` eats.
`stderr = FALSE` discards the diagnostic. So **a failed `git status` and a clean
file are the same value** — `character(0)` — and the failure reads as `dirty = FALSE`.

Measured (`/tmp/probe3.R`): a `git status --porcelain -- <path outside the repo>`
exits non-zero, prints nothing to stdout, and produces `dirty = FALSE`.

This is load-bearing rather than cosmetic, because the script's own header (line 47)
says the printed status *is* the mechanism:

> Point it at a CLEAN checkout. Generating from a working tree copies whatever a
> parallel session has half-finished into a gq commit, and the git status printed
> below is what tells you that happened.

A silently-false "clean" defeats exactly that. Same shape as CLAUDE.md's
*"A guard must not fail toward 'skip'"* — assign first, test the exit status, then
test the value.

Reachable trigger beyond the pathspec case: with `RFP_LOOKUPS_DIR` unset, `src` is
`system.file("lookups", package = "rfp")`. If that library path sits inside some
*other* git repo (an `renv` project library is the common case), `rev-parse`
succeeds against the unrelated repo and the function prints confident provenance —
commit, branch, "roster matches origin/main" — about the wrong repository.

Fix shape:

```r
git <- function(...) {
  err <- tempfile(); on.exit(unlink(err), add = TRUE)
  out <- suppressWarnings(
    system2("git", c("-C", shQuote(dir), ...), stdout = TRUE, stderr = err)
  )
  st <- attr(out, "status"); list(out = out, ok = is.null(st) || st == 0L)
}
```

and report a non-zero status as *unverifiable*, never as clean. `has_main`
(line 86) has the same shape but degrades honestly — it reports
`"(no origin/main to compare against)"`, which is an absence, not a pass.

---

### 2. [fragile] `data-raw/reg_extract_form_types.R:74` — `system2()` does not quote its args; a path containing a space misreports as "not a git checkout"

Confirmed from `system2`'s body (`/tmp/probe4.R`):

```r
command <- paste(c(env, shQuote(command), args), collapse = " ")
```

Only the **command** is quoted. `dir` and `file` are interpolated raw into a shell
string. `dir` comes from `RFP_LOOKUPS_DIR` or `system.file()`; `file` is
`file.path(src, "rfp_form_types.csv")`.

Measured, against a real repo created under a directory containing a space:

```
unquoted dir -> sha length: 0   => reports 'not a git checkout': TRUE
quoted   dir -> sha length: 1
```

So a perfectly good checkout under `.../My Drive/rfp` prints
`"rfp source is not a git checkout — provenance unverifiable"` and the whole
provenance block is skipped. Shell metacharacters in the path would be interpreted
by the shell rather than passed through. `shQuote(dir)` and `shQuote(file)` fix
both; note that `file` needs it too, since it is passed as a pathspec.

None of the three sibling generators (`reg_extract_themes.R`,
`reg_extract_template_groups.R`, `styles_vendor.R`) shell out at all, so this is
new surface in the family.

---

### 3. [bug] `R/gq_forms.R:19,23,44` (+ `man/gq_form_types.Rd:23,27,44`, script header lines 13–15) — "two forms" is contradicted by the shipped data

`gq_group_layers("Forms")` returns **four** rows, measured:

```
form_pscis, form_fiss_site, form_edna, form_monitoring
```

Against that, the shipped documentation says:

| location | text | actual |
|---|---|---|
| `R/gq_forms.R:19` / `Rd:23` | "`groups.csv` carries the two forms the templates ship" | four |
| `R/gq_forms.R:23` / `Rd:27` | "report thirteen forms for a template that ships two" | ships four |
| `R/gq_forms.R:44` / `Rd:44` | `# the two the shipped templates actually carry` | prints four |
| script header:13–15 | "13 forms for a template that ships 2 … at six times the scale" | 13 vs 4 ≈ 3× |

The third one is the worst, because it is a **runnable `@examples` line rendered on
pkgdown**: the example's own printed output visibly disagrees with the comment
directly above it.

gq's tree already disagrees with itself here — `data-raw/styles_vendor.R` closes
with *"The 4 forms are owned by `rfp_form_build()`"*.

The architectural decision (separate table, not folded into `groups.csv`) is
unaffected and still correct; only the evidence cited for it is wrong. Note the
likely origin of the "two": `reg_main.json` carries exactly two `form_*` keys
(`form_pscis`, `form_fiss_site`, verified), because those are the two that came
through `gq_qgs_extract()`. `groups.csv` declares four. The doc conflates the two
facts. CLAUDE.md, *"Measure before you characterise"*.

---

### 4. [fragile] `data-raw/reg_extract_form_types.R:190–198` — the round-trip guard cannot catch the failure it names

```r
# Prove the round-trip rather than trusting it. A layer_name whose leading
# space is eaten still looks like a name, and the key it no longer derives to
# reports nothing.
back <- utils::read.csv("inst/registry/form_types.csv", stringsAsFactors = FALSE)
if (!identical(back$layer_name, forms$layer_name) || ...) stop(...)
```

Both halves of that rationale are false, and both were measured:

1. **The writer/reader pair cannot eat a leading space.** `write.csv(quote = TRUE)`
   quotes every character column, and `read.csv` does not strip whitespace inside
   quotes — *even with `strip.white = TRUE`*:
   ```
   leading space preserved: TRUE
   even with strip.white=TRUE: TRUE
   ```
   So the assertion is unfirable for the cause it names. This is the shape CLAUDE.md
   already flags: *"a round-trip guard that compares `read.csv()` against
   `read.csv(strip.white = TRUE)` is structurally incapable of failing"*.

2. **A lost leading space would not change the key anyway.**
   `normalize_layer_name()` (`R/gq_style.R:105`) opens with `trimws()`. Measured:
   ```
   normalize_layer_name(" Form CABIN Visit") -> form_cabin_visit
   normalize_layer_name("Form CABIN Visit")  -> form_cabin_visit   (identical: TRUE)
   ```

The guard is not entirely dead — it *would* fire on a `quote = FALSE` regression,
since `label_expression` carries commas and embedded quotes, which is what the
sibling `reg_extract_template_groups.R` guard is really for. But that is not what
the comment claims, and a reader will trust the claim.

The assertion that *can* fail on a lost space is the one the test file already has
(`test-gq_forms.R:34`, `expect_true(all(startsWith(f$layer_name, " Form ")))`).
The generator wants the same check against `back` — `all(startsWith(back$layer_name,
" Form "))` — rather than a self-comparison, plus a comment naming the quoting as
what the `identical()` half guards.

---

### 5. [fragile] `tests/testthat/test-gq_forms.R:78` — `expect_true(all(nzchar(f$geometry)))` cannot fail

`nzchar(NA)` is `TRUE` (measured), and the reader's `na.strings = c("", "NA")`
means an empty `geometry` field arrives as `NA`, never as `""`. So `geometry` is
either `"point"` or `NA`, and **both give `TRUE`** — there is no reachable state in
which this assertion fires.

```
nzchar(NA): TRUE
all(nzchar(c('point', NA))): TRUE
```

The line immediately above it, `expect_false(anyNA(f$geometry))` (line 77), is what
actually catches a non-spatial row leaking through the filter. CLAUDE.md names this
exact trap (*"`nzchar(NA)` is TRUE — non-empty checks silently pass NA"*). Either
drop line 78 or make it fire:

```r
expect_true(all(!is.na(f$geometry) & nzchar(f$geometry)))
```

---

### 6. [fragile] `data-raw/reg_extract_form_types.R:125` — the "matched everything" tripwire asserts a property of upstream data and misdiagnoses when it changes

```r
if (nrow(spatial) == n_all) {
  stop("no non-spatial rows found — the has_spatial filter matched everything, ",
       "which means either rfp changed the column's vocabulary or the filter ",
       "is reading the wrong thing", call. = FALSE)
}
```

Verified against the rfp checkout: `cabin_visit_pebble` is the **only**
`has_spatial = false` row of 14. The guard therefore depends on that one upstream
row continuing to exist. The message enumerates two causes and excludes the third
and most likely one — rfp drops the row, or gives it a geometry. When that happens a
correct script refuses to run and blames itself.

Same class as CLAUDE.md's *"A negative-case fixture rots when the positive set
grows"*: assert the premise separately from the property, or downgrade this to a
`message()`.

Worth recording that the **opposite** direction is properly covered: if rfp switched
the vocabulary to `TRUE`/`yes`, the filter would select zero rows, this guard would
not fire — and the oracle at line 168 (`all(known %in% layer_key)`) would, loudly.
That is the right structure.

---

## Verified clean (probed, not assumed)

- **The generator reproduces the committed CSV byte-identically.** Ran
  `RFP_LOOKUPS_DIR=~/Projects/repo/rfp/inst/lookups Rscript data-raw/reg_extract_form_types.R`;
  `diff` against the staged file → IDENTICAL. Output:
  `13 spatial forms of 14 registered (1 non-spatial dropped); 9 carry a declared colour, 4 do not`.
- **Source tree, not installed package.** `pkgload::load_all(quiet = TRUE)` is
  unconditional (no `requireNamespace` guard), and `normalize_layer_name()` /
  `gq_reg_main()` are called unqualified. Matches the `data-raw` convention.
  Live relevance confirmed: installed rfp is at 12 form types, the checkout at 14.
- **`has_spatial == "true"` is a character comparison, not a broken logical one.**
  `read.csv` does *not* type-convert lowercase `true`/`false` to logical (measured),
  so the filter selects 13/14 correctly.
- **NA vs `""` is consistent, though the two sides use different conventions.** The
  script reads rfp's CSV *without* `na.strings`, so empty stays `""` and
  `sum(nzchar(forms$color))` counts 9/4 correctly. The shipped reader uses
  `na.strings = c("", "NA")`, and a *quoted* empty field does come back as `NA`
  (measured), so the tests' `is.na()` assertions are live. They agree today.
  Latent only: if rfp ever wrote a literal `NA` in `color`, `read.csv`'s default
  `na.strings = "NA"` would make it `NA` and `nzchar(NA)` is `TRUE`, over-counting
  "styled" in the closing message. Message-only, no artifact impact.
- **`expect_false("form_cabin_pebbles" %in% f$layer_key)` names the right key.**
  Checked against the rfp source: `cabin_visit_pebble`'s label is literally
  `"CABIN Pebbles"`, so `" Form CABIN Pebbles"` normalises to `form_cabin_pebbles`.
  The assertion is live, not a stale fixture. It does depend on an upstream string
  gq cannot assert at test time, but `expect_false(anyNA(f$geometry))` covers the
  same failure independently.
- **Every other test can fail.** Asked "what edit makes this red" for each:
  the label-not-type test is real (`monitoring_fish_passage` → `form_fish_passage_monitoring`,
  word order genuinely reversed); the oracle test asserts its premise before its
  property; the unstyled-set `expect_setequal` pins four named keys; the
  templates-in-roster join pins the four `groups.csv` forms; `startsWith(" Form ")`
  is the only live leading-space check in the change and it works.
- **Docs in sync.** Re-ran `devtools::document()`; no diff to
  `man/gq_form_types.Rd` or `NAMESPACE`.
- **Full suite green.** `FAIL 0 | WARN 1 | SKIP 0 | PASS 1018`; the single WARN is
  pre-existing in `test-gq_registry_read.R:25`.
- **pkgdown.** `_pkgdown.yml` has no explicit `reference:` index, so the new export
  cannot trip a "topics missing from index" failure.
- **Packaging.** `^data-raw$` is in `.Rbuildignore`; `inst/registry/form_types.csv`
  ships; the filename is portable (no spaces — `R CMD check` treats that as an ERROR).
- **No injection surface from untrusted input** — the git args come from a
  developer-set env var, not user data. Still worth `shQuote`ing per finding 2.
- Working tree left exactly as found (same six staged paths, nothing extra).
