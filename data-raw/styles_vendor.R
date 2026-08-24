# Vendor the QGIS-native QML corpus from rfp into inst/styles/.
#
# The registry (reg_main.json) is the cross-backend abstraction: it models what
# tmap and mapgl can render, which is ~20 symbol properties of the up-to-73 a
# .qgs carries, one symbol layer of up to five. That is the right trade for
# those backends and the wrong one for QGIS, where the full QML is lossless.
# This corpus is the QGIS-native form of the same styles.
#
# gq does NOT lift QML from a .qgs itself, deliberately. The <maplayer> -> .qml
# boundary is positional rather than a filter (`expressionfields` appears in
# both the source and style blocks, so filtering drops the style copy too),
# which means the source-tag list has to be COMPLETE, not merely correct — one
# missing tag and every later source tag leaks into the QML. That was rfp#130,
# and it is pinned there by a QGIS-container oracle (rfp/inst/testdata/nodes/).
# Mirroring the rule here would be two copies of something subtle that must
# agree. gq vendors the committed artifact instead.
#
# Like reg_extract_restoration.R and reg_extract_themes.R, this is a DEV-ONLY /
# build-time dependency on rfp — the committed corpus is the shipped source of
# truth, and gq consumers never need rfp.
#
#   Rscript data-raw/styles_vendor.R

devtools::load_all()

# `RFP_STYLES_DIR` points at inst/extdata/styles in an rfp SOURCE CHECKOUT, for
# the case the corpus is vendored from styles that have not been released yet.
# Without it system.file() resolves to the INSTALLED rfp, which is routinely
# behind. Same rationale as RFP_TEMPLATE_DIR in reg_extract_themes.R.
src <- Sys.getenv("RFP_STYLES_DIR", "")
if (nzchar(src)) {
  if (!dir.exists(src)) {
    stop("RFP_STYLES_DIR does not exist: ", src, call. = FALSE)
  }
  message("Using RFP_STYLES_DIR (source checkout): ", src)
} else {
  src <- system.file("extdata", "styles", package = "rfp")
  if (src == "") {
    stop(
      "rfp not installed — needed only to regenerate this corpus. Install with ",
      "pak::pak('NewGraphEnvironment/rfp'), or set RFP_STYLES_DIR to a ",
      "checkout's inst/extdata/styles.",
      call. = FALSE
    )
  }
  message("Using installed rfp ", as.character(utils::packageVersion("rfp")),
          ": ", src)
}

dest <- "inst/styles"
stem <- function(p) sub("[.]qml$", "", basename(p))

# --- vector: enumerate from the index, never from the filesystem --------------
#
# rfp's store carries vector/osm.trail.qml, which is tracked but has NO index
# row — the gq#41 trail donor, hand-added by rfp#171 the day before the store
# gained an index, superseded by the generated trails.qml. rfp's own guard walks
# index -> file only, so a stray file is invisible to it. Globbing the directory
# would silently vendor a file whose name is not even slug-shaped.
idx <- utils::read.csv(file.path(src, "vector", "index.csv"),
                       stringsAsFactors = FALSE, strip.white = FALSE)

# strip.white = FALSE above is load-bearing: one layer name begins with a space
# (" Biogeoclimatic Ecosystem Classification"), and a trimmed name binds to no
# layer upstream. gq keys past it via normalize_layer_name()'s own trimws().
idx$layer_key <- normalize_layer_name(idx$layer)

# gq keys the corpus with the SAME rule the registry and theme roster use, so a
# caller holding a groups.csv key can reach the QML. rfp derives its filenames
# with an independent slugify(); the two agree on all 53 current layer names,
# but nothing enforces that they keep agreeing. Refuse rather than vendor a file
# under a key that will not resolve.
drift <- idx[idx$layer_key != idx$slug, ]
if (nrow(drift) > 0) {
  stop(
    "normalize_layer_name() disagrees with the rfp slug on ", nrow(drift),
    " layer(s): ",
    paste(sprintf("%s (gq %s / rfp %s)", drift$layer, drift$layer_key,
                  drift$slug), collapse = "; "),
    "\nReconcile the two rules before vendoring.",
    call. = FALSE
  )
}

dupes <- idx[duplicated(idx[c("layer_key", "template")]), ]
if (nrow(dupes) > 0) {
  stop(
    "Duplicate (layer_key, template): ",
    paste(unique(dupes$layer_key), collapse = ", "),
    "\nThe store is keyed per QGIS layer, not per table, so two layers can ",
    "share a key. Resolve deliberately — auto-uniquifying repoints references.",
    call. = FALSE
  )
}

# Where each vector style lives, both sides. scope "shared" sits flat; an
# override sits under its template, which is how rfp records the 3 layers that
# genuinely differ between the two templates.
rel <- ifelse(
  idx$scope == "override",
  file.path("vector", "overrides", idx$template, paste0(idx$slug, ".qml")),
  file.path("vector", paste0(idx$slug, ".qml"))
)
missing <- rel[!file.exists(file.path(src, rel))]
if (length(missing) > 0) {
  stop("Index rows with no file: ", paste(missing, collapse = ", "),
       call. = FALSE)
}

# The direction rfp's guard does not walk. An unindexed file is either a
# leftover (osm.trail.qml) or a style nobody can reach; both want a decision.
on_disk <- c(
  file.path("vector", paste0(stem(Sys.glob(file.path(src, "vector", "*.qml"))),
                             ".qml")),
  sub(paste0("^", src, "/"), "",
      Sys.glob(file.path(src, "vector", "overrides", "*", "*.qml")))
)
# Declared exceptions, each with a reason. An ignored entry without one is a
# backlog note pretending to be a decision, and it gets re-litigated every time
# someone reads this. Anything NOT named here still aborts.
orphans_known <- c(
  # The gq#41 trail donor, lifted from the Roads - DRA symbology and committed
  # by rfp#171 (7caeeeb, 2026-08-22) one day before rfp#174 gave the store an
  # index. Once spliced into both templates the generator re-extracted it as the
  # indexed trails.qml, which is what gq vendors; this one is the superseded
  # input. Not slug-shaped either ("osm.trail", not "osm_trail"). Tracked as
  # rfp#187 — drop this entry once that lands.
  "vector/osm.trail.qml"
)
orphans <- setdiff(setdiff(on_disk, rel), orphans_known)
if (length(orphans) > 0) {
  stop(
    "Files with no index row: ", paste(orphans, collapse = ", "),
    "\nrfp's store guard walks index -> file only, so it cannot see these. ",
    "Index them upstream or delete them; do not vendor an unreachable style. ",
    "If one is a known leftover, add it to orphans_known WITH a reason.",
    call. = FALSE
  )
}
stale <- setdiff(orphans_known, on_disk)
if (length(stale) > 0) {
  message("orphans_known entries no longer present upstream (drop them): ",
          paste(stale, collapse = ", "))
}

# --- raster + services: no index, so resolve against the template roster ------
#
# These carry no index.csv, so an earlier draft globbed the directories and
# asserted each stem was slug-stable. That check catches an osm.trail, but it
# cannot catch a stray file that IS slug-shaped — and two were already getting
# through. Resolve against rfp's roster of what the templates actually contain,
# which is the same "enumerate from a manifest" rule the vector side follows.
#
# The roster lives in rfp's data-raw, which is .Rbuildignore'd, so vendoring
# needs a source checkout rather than an installed rfp. That is already true in
# spirit — the installed copy is routinely behind — so require it outright
# instead of silently emitting a different index depending on the path taken.
roster_path <- file.path(dirname(dirname(dirname(src))),
                         "data-raw", "qgs", "roster", "template_layers.csv")
if (!file.exists(roster_path)) {
  stop(
    "Template roster not found: ", roster_path,
    "\nrfp ships data-raw only in a source checkout, and the roster is what ",
    "names the raster and service layers. Set RFP_STYLES_DIR to a checkout's ",
    "inst/extdata/styles.",
    call. = FALSE
  )
}
roster <- utils::read.csv(roster_path, stringsAsFactors = FALSE,
                          strip.white = FALSE)
roster <- unique(roster[roster$kind %in% c("raster", "service"),
                        c("name", "kind")])
names(roster)[names(roster) == "name"] <- "layer"
roster$layer_key <- normalize_layer_name(roster$layer)

unindexed <- do.call(rbind, lapply(c("raster", "services"), function(dir_name) {
  kind <- if (dir_name == "services") "service" else dir_name
  want <- roster[roster$kind == kind, , drop = FALSE]
  if (nrow(want) == 0) stop("Roster names no ", kind, " layers", call. = FALSE)

  files <- file.path(src, dir_name, paste0(want$layer_key, ".qml"))
  gone <- files[!file.exists(files)]
  if (length(gone) > 0) {
    stop("Roster names ", kind, " layers with no QML: ",
         paste(basename(gone), collapse = ", "), call. = FALSE)
  }

  # Reported rather than fatal: rfp legitimately ships raster styles the
  # templates do not use — dem_hillshade and dem_turbo back rfp_raster_styles(),
  # whose renderer/companion/stretch dimension gq vendors none of. They are also
  # the only files in the store that are QGIS-authored sidecars rather than
  # lifted <maplayer> blocks, which is why they alone open with
  # <map-layer-style-manager> instead of <flags>. Not gq's to ship.
  extra <- setdiff(stem(Sys.glob(file.path(src, dir_name, "*.qml"))),
                   want$layer_key)
  if (length(extra) > 0) {
    message("skipping ", kind, " style(s) no template uses: ",
            paste(extra, collapse = ", "))
  }

  data.frame(
    layer_key = want$layer_key,
    layer     = want$layer,
    template  = "*",
    scope     = "shared",
    kind      = kind,
    rel       = file.path(dir_name, paste0(want$layer_key, ".qml")),
    stringsAsFactors = FALSE
  )
}))

# --- assemble ----------------------------------------------------------------
vector_rows <- data.frame(
  layer_key = idx$layer_key,
  layer     = idx$layer,
  template  = idx$template,
  scope     = idx$scope,
  kind      = "vector",
  rel       = rel,
  stringsAsFactors = FALSE
)
corpus <- rbind(vector_rows, unindexed)

# On the ASSEMBLED corpus, not on the vector index. An earlier draft checked
# only vector-vs-unindexed, so a duplicate WITHIN raster+services would have
# passed here and surfaced instead at call time, in a consumer's session, as
# gq_style_qml()'s "expected exactly one shared style".
clash <- corpus[duplicated(corpus[c("layer_key", "template")]) |
                  duplicated(corpus[c("layer_key", "template")],
                             fromLast = TRUE), ]
if (nrow(clash) > 0) {
  stop("Duplicate (layer_key, template) across kinds: ",
       paste(unique(clash$layer_key), collapse = ", "), call. = FALSE)
}

# Every row is now named, so the guard that pins gq's key rule against rfp's
# covers the whole corpus rather than the vector subset.
if (any(is.na(corpus$layer))) {
  stop("Rows with no layer name: ",
       paste(corpus$layer_key[is.na(corpus$layer)], collapse = ", "),
       call. = FALSE)
}

# --- write -------------------------------------------------------------------
# Rebuild from empty so a style deleted upstream disappears here too. An
# additive copy would leave a withdrawn style shipping forever, which is the
# same class of failure as a pkgdown deploy without clean = true.
if (dir.exists(dest)) unlink(dest, recursive = TRUE)
for (d in unique(dirname(file.path(dest, corpus$rel)))) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}
ok <- file.copy(file.path(src, corpus$rel), file.path(dest, corpus$rel),
                overwrite = TRUE)
if (!all(ok)) {
  stop("Copy failed for: ",
       paste(corpus$rel[!ok], collapse = ", "), call. = FALSE)
}

# Quoted, unlike the registry CSVs. Layer names carry commas ("Crossings -
# PSCIS,  modelled, dams") and a leading space, so an unquoted write would shift
# every later column. read.csv() handles the quoting on the way back in.
corpus <- corpus[order(corpus$kind, corpus$layer_key, corpus$template), ]
utils::write.csv(corpus[c("layer_key", "layer", "template", "scope", "kind")],
                 file.path(dest, "index.csv"), row.names = FALSE)

message("styles vendored: ", nrow(corpus), " files (",
        paste(sprintf("%s %s", table(corpus$kind), names(table(corpus$kind))),
              collapse = ", "), ")")

# Reported, not fatal. The 4 forms are owned by rfp_form_build() and are out of
# scope by design; the rest are genuine gaps worth naming rather than hiding.
group_keys <- unique(utils::read.csv("inst/registry/groups.csv",
                                     stringsAsFactors = FALSE)$layer_key)
gaps <- setdiff(group_keys, corpus$layer_key)
if (length(gaps) > 0) {
  message("groups.csv keys with no QML (", length(gaps), "): ",
          paste(gaps, collapse = ", "))
}
extra <- setdiff(corpus$layer_key, group_keys)
if (length(extra) > 0) {
  message("QML with no groups.csv row (", length(extra), "): ",
          paste(extra, collapse = ", "))
}
