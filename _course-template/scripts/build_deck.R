# scripts/build_deck.R
#
# Generate a custom slide deck from any ordered subset of chapters, then
# (optionally) render it with Quarto.
#
# Usage from the course's project root (R console or Rscript):
#
#   source("scripts/build_deck.R")
#
#   list_chapters()   # see what's available
#
#   build_deck(
#     chapters = c("003-topic-a", "001-example-chapter"),
#     title    = "Séance : révision",
#     out_file = "decks/revision-01.qmd",
#     render   = TRUE
#   )
#
# `chapters` are file names (without .qmd) inside chapters/, in the exact
# order you want them to appear.

list_chapters <- function(dir = "chapters") {
  files <- list.files(dir, pattern = "\\.qmd$", full.names = FALSE)
  sub("\\.qmd$", "", files)
}

build_deck <- function(chapters,
                        title,
                        out_file,
                        chapters_dir = "chapters",
                        render = FALSE) {

  stopifnot(length(chapters) > 0)

  missing <- chapters[!file.exists(file.path(chapters_dir, paste0(chapters, ".qmd")))]
  if (length(missing) > 0) {
    stop("Chapter(s) not found in ", chapters_dir, ": ",
         paste(missing, collapse = ", "),
         "\nAvailable chapters: ", paste(list_chapters(chapters_dir), collapse = ", "))
  }

  depth <- length(strsplit(dirname(out_file), "/")[[1]])
  up <- paste(rep("..", depth), collapse = "/")

  includes <- paste0(
    "{{< include ", up, "/", chapters_dir, "/", chapters, ".qmd >}}",
    collapse = "\n\n"
  )

  content <- sprintf(
    '---\ntitle: "%s"\nformat: revealjs\n---\n\n```{=html}\n<style>:root{ --course-title: "%s"; }</style>\n```\n\n%s\n',
    title, title, includes
  )

  dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)
  writeLines(content, out_file)
  message("Wrote deck: ", out_file)

  if (isTRUE(render)) {
    if (!requireNamespace("quarto", quietly = TRUE)) {
      stop("Install the 'quarto' R package (install.packages('quarto')) to auto-render.")
    }
    quarto::quarto_render(out_file)
  }

  invisible(out_file)
}
