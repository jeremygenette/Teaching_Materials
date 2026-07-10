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

  # `up` already gets back to the course's project root (e.g. "..") - one
  # more level reaches _shared/, which sits next to the course folder, not
  # inside it. Full options are embedded directly in the deck's own YAML
  # (rather than relying on decks/_metadata.yml or ../_quarto.yml) because
  # Quarto book projects don't reliably merge project- or directory-level
  # metadata into files that aren't listed book chapters - see the notes in
  # decks/_metadata.yml and ../_quarto.yml for the full story.
  shared <- paste0(up, "/../_shared")

  yaml_format <- sprintf(
    'format:\n  revealjs:\n    embed-resources: true\n    theme: [simple, %s/styles/kuleuven-reveal.scss]\n    slide-number: true\n    incremental: true\n    number-sections: true\n    transition: fade\n    loop: true\n    hide-inactive-cursor: true\n    preview-links: true\n    pdf-separate-fragments: true\n    scrollable: true\n    width: 1100\n    height: 700\n    margin: 0.08\n    min-scale: 0.2\n    max-scale: 1.5\n    auto-stretch: true\n    footer: "<span id=\'slide-path\'>\U0001F4C1 Root</span>"\n    include-after-body:\n      - %s/styles/after-body.html',
    shared, shared
  )

  content <- sprintf(
    '---\ntitle: "%s"\n%s\n---\n\n```{=html}\n<style>:root{ --course-title: "%s"; }</style>\n```\n\n%s\n',
    title, yaml_format, title, includes
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
