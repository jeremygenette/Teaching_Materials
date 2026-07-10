# _shared/scripts/push_to_github.R
#
# One shared "commit + push everything that changed" helper, used by every
# course instead of pasting the same gert block into each .qmd's YAML.
#
# Requirements:
#   - install.packages("gert")
#   - the repo has an "origin" remote configured
#   - git has non-interactive push credentials available (a PAT stored via
#     the system credential manager, or a passphrase-less SSH key)
#
# This is meant to be called from a course's scripts/post-render-push.R,
# which Quarto runs automatically once per `quarto render` via the
# project's `post-render:` hook in _quarto.yml — NOT from a per-chapter
# knitr hook. That matters because most chapters are plain markdown with
# no R code chunks, so a knitr document hook would simply never fire on
# them. A project-level post-render script always fires exactly once,
# after every format in the project has finished rendering (book html +
# all revealjs decks), which is also why it's a better fit than the old
# per-.qmd approach: one push per `quarto render`, not one per format.
#
# `paths` are the files/folders (relative to the course's project root)
# to git-add before committing. "." stages the whole course folder
# (chapters, decks, rendered html, images), which is the simplest safe
# default.

push_to_github <- function(paths = ".", course_label = NULL, remote = "origin", branch = "main") {
  message("--- Auto-Pushing to GitHub", if (!is.null(course_label)) paste0(" [", course_label, "]") else "", " ---")
  try({
    if (!requireNamespace("gert", quietly = TRUE)) {
      stop("Package 'gert' is not installed — skipping auto-push. Run install.packages('gert').")
    }

    gert::git_add(paths)
    status <- gert::git_status()

    if (nrow(status) == 0) {
      message("Nothing to commit.")
    } else {
      label <- if (!is.null(course_label)) paste0(course_label, ": ") else ""
      gert::git_commit(paste0(label, "Auto-update ", Sys.Date()))
      gert::git_push(remote = remote, refspec = paste0("refs/heads/", branch))
      message("--- Push complete! ---")
    }
  })
}
