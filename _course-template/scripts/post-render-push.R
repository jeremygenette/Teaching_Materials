# scripts/post-render-push.R
#
# Run automatically once per `quarto render` (see the `post-render:` line
# in this course's _quarto.yml). Commits & pushes anything that changed
# in this course folder — chapters, decks, rendered html, images.
#
# Requirements: see _shared/scripts/push_to_github.R

source("../_shared/scripts/push_to_github.R")

push_to_github(paths = ".", course_label = "COURSE TITLE")
