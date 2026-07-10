#!/usr/bin/env bash
# scripts/render_all.sh
#
# One command = the whole course, freshly built: the book (index.qmd +
# every chapters/*.qmd) AND every slide deck in decks/.
#
# Why this script exists: in a Quarto *book* project, a bare
# `quarto render` only renders the book's own chapter list — it silently
# skips "loose" files like decks/*.qmd even though they're valid targets
# (this is documented Quarto behaviour, not a bug in this setup). So we
# render the book, then explicitly render each deck in turn.
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

echo "== Rendering book =="
quarto render

shopt -s nullglob
for deck in decks/*.qmd; do
  echo "== Rendering deck: $deck =="
  quarto render "$deck"
done

echo "== Done. Book + all decks rendered, each push handled by post-render. =="
