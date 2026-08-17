#!/usr/bin/env bash
# scripts/render_all.sh
#
# One command = the whole course, freshly built: the book (index.qmd +
# every chapters/*.qmd), the single-file HTML version of the book
# (full-book.qmd), AND every slide deck in decks/.
#
# Why this script exists: in a Quarto *book* project, a bare
# `quarto render` only renders the book's own chapter list — it silently
# skips "loose" files like decks/*.qmd even though they're valid targets
# (this is documented Quarto behaviour, not a bug in this setup). So we
# render the book, then explicitly render each deck in turn.
#
# Before any of that, we run scripts/sync_chapters.R, which regenerates
# _quarto.yml's book: chapters: list, full-book.qmd, and
# decks/full-deck.qmd from whatever .qmd files currently exist in
# chapters/ - Quarto has no wildcard support for book: chapters:, so
# this is what keeps those three files from ever going stale relative
# to chapters/ again.
#
# Every one of these `quarto render` calls also triggers this project's
# `post-render:` hook (scripts/post-render-push.R), so each step commits
# and pushes anything that changed — that's what makes "every knit
# pushes to GitHub" true even if you run this script, not just when you
# render a single file by hand.
#
# Usage (from this course's folder):
#   ./scripts/render_all.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Syncing chapters/*.qmd into _quarto.yml, full-book.qmd, decks/full-deck.qmd =="
Rscript scripts/sync_chapters.R

echo "== Rendering book =="
quarto render

echo "== Rendering single-file book (full-book.qmd) =="
quarto render full-book.qmd

shopt -s nullglob
for deck in decks/*.qmd; do
  echo "== Rendering deck: $deck =="
  quarto render "$deck"
done

echo "== Done. Book + full-book.html + all decks rendered, each push handled by post-render. =="


set -e

Rscript scripts/build_full_book.R

quarto render

quarto render full-book.qmd

for f in decks/*.qmd; do
    quarto render "$f"
done