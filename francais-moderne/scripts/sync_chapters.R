# scripts/sync_chapters.R
#
# Regenerates every place that has to list the course's chapters, from
# whatever .qmd files currently exist in chapters/ - so adding, renaming,
# or removing a chapter file is the ONLY manual step:
#
#   - _quarto.yml         -> book: chapters: list (flat, filename order)
#   - full-book.qmd        -> the {{< include >}} block
#   - decks/full-deck.qmd   -> the {{< include >}} block
#
# WHY THIS SCRIPT EXISTS: Quarto does NOT support wildcards/globs in
# book: chapters: (only project: render: supports globs) - this is a
# documented Quarto limitation
# (https://github.com/quarto-dev/quarto-cli/issues/1917), not a bug in
# this repo. This script exists specifically to compensate for that
# missing feature, so you never again hit the
# "Book chapter '...' not found" error from a stale/leftover entry.
#
# NOTE on parts (book: chapters: - part: "..."): if you've grouped
# chapters into parts by hand, this script does NOT try to preserve that
# grouping (too fragile to infer automatically from filenames alone) -
# it flattens book: chapters: to a single ordered list every time it
# runs. Add part: grouping back by hand afterward if you want it; just
# don't re-run this script afterward, or it'll flatten it again.
#
# Chapters are sorted alphabetically, so the existing NNN-name.qmd
# numbering convention controls the order.
#
# Usage (from this course's project root):
#   Rscript scripts/sync_chapters.R
# or from an R console:
#   source("scripts/sync_chapters.R"); sync_chapters()
#
# It also runs automatically as the first step of scripts/render_all.sh.

list_chapters <- function(dir = "chapters") {
  files <- list.files(dir, pattern = "\\.qmd$", full.names = FALSE)
  sort(files)
}

sync_chapters <- function(chapters_dir = "chapters",
                           quarto_yml  = "_quarto.yml",
                           full_book   = "full-book.qmd",
                           full_deck   = "decks/full-deck.qmd") {

  chapters <- list_chapters(chapters_dir)
  if (length(chapters) == 0) {
    stop(
      "No .qmd files found in '", chapters_dir, "'.\n",
      "  R's working directory is: ", getwd(), "\n",
      "  Contents of that directory: ",
      paste(list.files("."), collapse = ", "), "\n",
      "  -> Run this script from the course's project root (the folder\n",
      "     containing _quarto.yml and chapters/), e.g. via\n",
      "     ./scripts/render_all.sh, or check for a stray .Rprofile that\n",
      "     changes the working directory on startup."
    )
  }

  update_quarto_yml(quarto_yml, chapters_dir, chapters)
  update_includes(full_book, chapters_dir, chapters, prefix = "")
  update_includes(full_deck, chapters_dir, chapters, prefix = "../")

  message("Synced ", length(chapters), " chapter(s) from ", chapters_dir, "/:")
  message(paste0("  - ", chapters, collapse = "\n"))
  message("-> ", quarto_yml, ", ", full_book, ", ", full_deck)

  invisible(chapters)
}

# Rewrites only the `book: chapters:` block inside _quarto.yml, leaving
# every comment and every other section of the file untouched. Doing a
# full YAML parse+rewrite would silently strip all of this file's
# explanatory comments, so this works on the raw text instead.
update_quarto_yml <- function(file, chapters_dir, chapters) {
  if (!file.exists(file)) {
    warning(file, " not found - skipping.")
    return(invisible())
  }
  lines <- readLines(file, warn = FALSE)

  book_line <- grep("^book:\\s*$", lines)
  if (length(book_line) == 0) stop("Couldn't find a top-level 'book:' key in ", file)
  book_line <- book_line[1]

  chapters_candidates <- grep("^\\s*chapters:\\s*$", lines)
  chapters_candidates <- chapters_candidates[chapters_candidates > book_line]
  if (length(chapters_candidates) == 0) {
    stop("Couldn't find a 'chapters:' key under 'book:' in ", file)
  }
  start <- chapters_candidates[1]
  indent <- sub("chapters:.*", "", lines[start])
  item_indent <- paste0(indent, "  ")

  # Block ends at the last actual list item (a line starting at
  # item_indent). Blank lines and comments in between are skipped over
  # without extending `end`, so a trailing comment that belongs to the
  # NEXT section (e.g. explaining format: below) is correctly left alone
  # instead of being swallowed into the chapters: block.
  end <- start
  i <- start + 1
  while (i <= length(lines)) {
    ln <- lines[i]
    if (startsWith(ln, item_indent)) {
      end <- i
      i <- i + 1
    } else if (trimws(ln) == "" || grepl("^\\s*#", ln)) {
      i <- i + 1
    } else {
      break
    }
  }

  new_block <- c(
    paste0(indent, "chapters:"),
    paste0(item_indent, "- index.qmd"),
    paste0(item_indent, "- ", chapters_dir, "/", chapters)
  )

  lines <- c(
    lines[seq_len(start - 1)],
    new_block,
    if (end < length(lines)) lines[(end + 1):length(lines)] else character(0)
  )
  writeLines(lines, file)
}

# Rewrites the {{< include ... >}} block in a decks-style file (anything
# using the same "one include per chapter" pattern as full-book.qmd and
# decks/full-deck.qmd), preserving everything else in the file.
update_includes <- function(file, chapters_dir, chapters, prefix) {
  if (!file.exists(file)) {
    warning(file, " not found - skipping.")
    return(invisible())
  }
  txt <- readLines(file, warn = FALSE)
  include_idx <- grep("^\\{\\{< include ", txt)
  if (length(include_idx) == 0) {
    warning("No {{< include >}} lines found in ", file, " - leaving it untouched.")
    return(invisible())
  }

  new_includes <- paste0("{{< include ", prefix, chapters_dir, "/", chapters, " >}}")
  new_block <- character(0)
  for (inc in new_includes) new_block <- c(new_block, inc, "")
  new_block <- new_block[-length(new_block)]  # drop trailing blank line

  first <- min(include_idx)
  last  <- max(include_idx)
  txt <- c(
    txt[seq_len(first - 1)],
    new_block,
    if (last < length(txt)) txt[(last + 1):length(txt)] else character(0)
  )
  writeLines(txt, file)
}

if (sys.nframe() == 0) {
  sync_chapters()
}
