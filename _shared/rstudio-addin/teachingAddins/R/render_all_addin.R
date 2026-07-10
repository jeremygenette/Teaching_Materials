#' Render + push the current course (book + every slide deck)
#'
#' RStudio Addin wrapper around a course's \code{scripts/render_all.sh}.
#' It searches (in order) the active RStudio project, the current working
#' directory, and the folder of whatever file you have open in the editor -
#' walking a few levels up each of those for a folder that directly
#' contains \code{scripts/render_all.sh}, and if none of those is a course
#' folder itself, checking one level *down* for course subfolders (so it
#' also works if you have the whole \code{Teaching/} repo open, not just a
#' single course). If more than one course is found that way, you're asked
#' which one to render.
#'
#' Once a course root is found, it opens a terminal tab there and runs
#' \code{./scripts/render_all.sh}. That script renders the book, then every
#' deck in \code{decks/}; each of those render calls fires the course's
#' Quarto \code{post-render:} hook, which commits and pushes anything that
#' changed to GitHub. So one click = render everything + push everything,
#' streaming live in a terminal tab exactly as if you'd typed it yourself.
#'
#' @export
render_all_addin <- function() {
  if (!requireNamespace("rstudioapi", quietly = TRUE)) {
    stop("Package 'rstudioapi' is required. Install it with: install.packages('rstudioapi')")
  }

  found <- .find_course_roots()

  if (length(found) == 0) {
    stop(
      "Couldn't find any course's scripts/render_all.sh.\n\n",
      "Checked (walking upward for a folder that directly contains ",
      "scripts/render_all.sh, then one level down for course subfolders):\n",
      "  active project : ", .fmt(tryCatch(rstudioapi::getActiveProject(), error = function(e) NULL)), "\n",
      "  working dir     : ", .fmt(getwd()), "\n",
      "  open file's dir : ", .fmt(.active_doc_dir()), "\n\n",
      "Make sure either a course folder (the one directly containing ",
      "chapters/, decks/, and scripts/) or the Teaching/ repo root is open ",
      "in RStudio, and/or that a file inside the course is open in the editor."
    )
  }

  root <- if (length(found) == 1) {
    found[[1]]
  } else {
    choice <- utils::menu(basename(found), title = "Multiple courses found - render + push which one?")
    if (choice == 0) {
      message("Cancelled.")
      return(invisible(NULL))
    }
    found[[choice]]
  }

  term_caption <- paste("render + push:", basename(root))
  term <- .find_or_create_terminal(term_caption)
  rstudioapi::terminalActivate(term, show = TRUE)
  rstudioapi::terminalSend(
    term,
    paste0("cd '", root, "' && ./scripts/render_all.sh\n")
  )

  invisible(NULL)
}

# --- internal helpers -------------------------------------------------

.fmt <- function(x) if (is.null(x) || !nzchar(x)) "(none)" else x

.active_doc_dir <- function() {
  doc <- tryCatch(rstudioapi::getSourceEditorContext(), error = function(e) NULL)
  if (is.null(doc) || is.null(doc$path) || !nzchar(doc$path)) return(NULL)
  dirname(doc$path)
}

# Reuse an existing terminal tab with this caption if one is already open
# (this is what a second click on the addin hits), otherwise create a new
# one. terminalCreate() errors if the caption is already taken, so if a
# stale/renamed terminal collides anyway, fall back to a timestamped
# caption rather than failing.
.find_or_create_terminal <- function(caption) {
  ids <- tryCatch(rstudioapi::terminalList(), error = function(e) character(0))
  for (id in ids) {
    ctx <- tryCatch(rstudioapi::terminalContext(id), error = function(e) NULL)
    if (!is.null(ctx) && identical(ctx$caption, caption)) {
      return(id)
    }
  }
  tryCatch(
    rstudioapi::terminalCreate(caption = caption, show = TRUE),
    error = function(e) {
      rstudioapi::terminalCreate(
        caption = paste(caption, format(Sys.time(), "%H:%M:%S")),
        show = TRUE
      )
    }
  )
}

.has_render_script <- function(dir) {
  nzchar(dir) && file.exists(file.path(dir, "scripts", "render_all.sh"))
}

# Returns a character vector of one or more course root directories.
.find_course_roots <- function() {
  starts <- c(
    tryCatch(rstudioapi::getActiveProject(), error = function(e) NULL),
    getwd(),
    .active_doc_dir()
  )
  starts <- unique(starts[!vapply(starts, is.null, logical(1))])
  starts <- starts[nzchar(starts)]

  # 1) walk upward from each starting point (up to 5 levels) for a direct hit
  for (start in starts) {
    d <- start
    for (i in 1:5) {
      if (.has_render_script(d)) return(d)
      parent <- dirname(d)
      if (identical(parent, d)) break
      d <- parent
    }
  }

  # 2) one level down from each starting point (repo-root-open case)
  hits <- character(0)
  for (start in starts) {
    subs <- tryCatch(list.dirs(start, recursive = FALSE, full.names = TRUE), error = function(e) character(0))
    hits <- c(hits, subs[vapply(subs, .has_render_script, logical(1))])
  }
  unique(hits)
}
