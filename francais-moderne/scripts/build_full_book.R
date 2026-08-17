#!/usr/bin/env Rscript

library(yaml)

# ------------------------------------------------------------
# Read the book chapter list from _quarto.yml
# ------------------------------------------------------------

cfg <- yaml::read_yaml("_quarto.yml")

chapters <- cfg$book$chapters

# Flatten parts if present
get_files <- function(x) {
  out <- character()
  
  for (el in x) {
    if (is.character(el)) {
      out <- c(out, el)
    } else if (!is.null(el$chapters)) {
      out <- c(out, get_files(el$chapters))
    }
  }
  
  out
}

chapters <- get_files(chapters)

# ------------------------------------------------------------
# YAML header
# ------------------------------------------------------------

header <- c(
  "---",
  'title: "COURSE TITLE — Livre complet"',
  'subtitle: ""',
  'author: "Jérémy Genette"',
  'date: last-modified',
  "",
  "format:",
  "  html:",
  "    embed-resources: true",
  "    self-contained-math: true",
  "    toc: true",
  "    toc-depth: 3",
  "    number-sections: true",
  "    theme:",
  "      light: [flatly, ../_shared/styles/kuleuven-book.scss]",
  "      dark: [darkly, ../_shared/styles/kuleuven-book.scss]",
  "---",
  ""
)

out <- header

# ------------------------------------------------------------
# Append every chapter
# ------------------------------------------------------------

for (f in chapters) {
  
  cat("Adding", f, "\n")
  
  txt <- readLines(f, warn = FALSE)
  
  ## rewrite image paths
  txt <- gsub(
    "\\]\\(images/",
    "](chapters/images/",
    txt
  )
  
  out <- c(out, "", txt)
}

writeLines(out, "full-book.qmd")

cat("✓ full-book.qmd generated\n")