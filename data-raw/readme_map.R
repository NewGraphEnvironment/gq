# Write man/figures/readme-map.png, the README figure.
#
# The figure IS gq-intro's `map-intro` chunk: this renders the vignette and
# copies the PNG knitr wrote for that chunk, rather than restating the map here,
# so the README and the article cannot drift apart. The vignette loads gq with
# library(gq), so install the branch first or the figure shows the installed
# release:
#   Rscript -e 'devtools::install(quick = TRUE, upgrade = "never")'
#   Rscript data-raw/readme_map.R
#
# It fetches basemap tiles, so it needs the network. Check the result at the
# width the README is read at (the pkgdown home page column) before committing.

out_dir <- tempfile("readme_map")
dir.create(out_dir)
rmarkdown::render("vignettes/gq-intro.Rmd", output_dir = out_dir,
                  intermediates_dir = out_dir, clean = FALSE, quiet = TRUE)

png <- file.path(out_dir, "gq-intro_files", "figure-html", "map-intro-1.png")
if (!file.exists(png)) {
  stop("gq-intro rendered no map-intro figure at ", png,
       " - was the chunk renamed?", call. = FALSE)
}
stopifnot(file.copy(png, "man/figures/readme-map.png", overwrite = TRUE))
message("wrote man/figures/readme-map.png")
