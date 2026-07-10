# Teaching

One GitHub repo, one folder per course. Each course is an independent
Quarto **book** project — same idea as
[experimentology](https://github.com/langcog/experimentology) (a real
chapter-by-chapter website with sidebar + search), but every course also
gets matching **KU Leuven-themed slide decks** (revealjs) built from the
exact same chapter files, so nothing is ever written twice.

```
Teaching/
├── README.md                 ← you are here
├── _shared/                  ← used by EVERY course — edit once, applies everywhere
│   ├── styles/
│   │   ├── kuleuven-reveal.scss   ← slide theme (banner, colors, fonts…)
│   │   ├── kuleuven-book.scss     ← matching book/html theme
│   │   └── after-body.html        ← slide breadcrumb + scroll-progress JS
│   └── scripts/
│       └── push_to_github.R       ← shared gert commit+push helper
├── _course-template/         ← duplicate this to start a new course
│   ├── _quarto.yml
│   ├── index.qmd
│   ├── references.bib
│   ├── chapters/
│   ├── decks/
│   ├── images/
│   ├── scripts/
│   └── README.md
└── francais-moderne/         ← an actual course, built from the template
    └── ... (same skeleton, see francais-moderne/README.md)
```

## Why one book project per course, not one giant Quarto project?

Quarto's `book` project type expects a single `_quarto.yml` at its root
defining one table of contents. Two courses can't share that — so each
course folder is its own self-contained Quarto project (its own
`_quarto.yml`, own `book:` config, own render/preview commands run *from
inside that folder*). What they share is the theme and the git-push
script, pulled in from `_shared/` via relative paths (`../_shared/...`).
This mirrors how you'd keep two real textbooks apart while reusing one
publisher's cover template.

## Migrating your existing `Teaching` repo into this structure

Your current `jeremygenette/Teaching` repo has `francais-moderne`'s files
sitting at the repo root (not in a subfolder), with real commit history
you'll want to keep. Do the move with `git mv` so history follows the
files, from the root of your existing local clone:

```bash
mkdir francais-moderne _shared
git mv _chapters   francais-moderne/chapters   # then rename each _0X-*.qmd → 0X-*.qmd
git mv decks       francais-moderne/decks
git mv images      francais-moderne/images
git mv scripts     francais-moderne/scripts
git mv references.bib francais-moderne/references.bib
git mv styles/kuleuven-reveal.scss styles/after-body.html _shared/styles/
git mv styles      francais-moderne/  # if anything course-specific remains
git rm Cours_Complet.qmd Cours_Complet.html -r Cours_Complet_files
git commit -m "Restructure into multi-course monorepo"
```

Then drop in the new `_quarto.yml`, `index.qmd`, `README.md` (both
levels), `_shared/styles/kuleuven-book.scss`, and the `scripts/*.R`
files from this restructure — those are new, so a plain copy (not
`git mv`) is right for them. Delete the old `ressources/` folder (the
misspelled, broken theme path) once `kuleuven-book.scss` replaces it.

## Starting a new course

```bash
cp -r _course-template my-new-course
cd my-new-course
```

Then:
1. Edit `_quarto.yml` — set `book: title:`, `author:`, and build up the
   `book: chapters:` list as you add chapters (grouped into `part:`
   sections if useful, exactly like `francais-moderne/_quarto.yml`).
2. Edit `index.qmd` — the book's landing page.
3. Edit `scripts/post-render-push.R` — set `course_label` to your course
   name (purely cosmetic, shows up in commit messages).
4. Replace `chapters/001-example-chapter.qmd` with your first real
   chapter, and `decks/full-deck.qmd`'s `{{< include >}}` line to match.
5. Read `my-new-course/README.md` (copied from the template) for the
   exact, course-specific "how to add a chapter" steps.

## Adding a chapter to an existing course

This is course-specific — open that course's own `README.md`
(`francais-moderne/README.md`, or `_course-template/README.md` as the
generic version) for the exact steps. Short version, true for every
course: add `chapters/00X-topic.qmd` with one `# H1` heading, list it in
that course's `_quarto.yml` under `book: chapters:`, optionally
`{{< include >}}` it into a deck, then `quarto render`.

## Rendering & auto-push to GitHub

Run from **inside a course folder**, not the repo root (there's no
single top-level `_quarto.yml` — each course is its own project):

```bash
cd francais-moderne
./scripts/render_all.sh   # book + every deck, in one command
```

A bare `quarto render` only builds a book project's own chapter list —
Quarto doesn't auto-render "loose" files like `decks/*.qmd` the way a
website project would, even though they're registered under
`project: render:`. `render_all.sh` works around that by explicitly
rendering the book, then every file in `decks/`, so one command really
does produce everything.

**Every knit pushes automatically.** Each course's `_quarto.yml` has a
`post-render:` hook that runs `scripts/post-render-push.R` after *every*
render Quarto does inside that project — `render_all.sh`, a bare
`quarto render`, a single `quarto render decks/x.qmd`, even
`quarto preview`. Each run stages, commits, and pushes whatever changed
via the shared `_shared/scripts/push_to_github.R`; if nothing changed
it's a harmless no-op. One-time setup per machine:

- `install.packages("gert")`
- this repo has a git `origin` remote configured
- git has non-interactive push credentials (a PAT stored in the system
  credential manager, or a passphrase-less SSH key)

If that's not set up yet, the push step fails gracefully and just prints
a message — it never breaks a render.

### One-click render + push from RStudio (no Terminal needed)

`_shared/rstudio-addin/teachingAddins/` is a tiny local R package with a
single Addin, **"Render + Push Course"**, that runs a course's
`scripts/render_all.sh` for you and streams the output in a terminal tab.
One-time setup:

```r
install.packages(c("devtools", "rstudioapi"))
devtools::install_local("_shared/rstudio-addin/teachingAddins", force = TRUE)
```

Restart RStudio, then open a course folder as your project and use
**Addins → "Render + Push Course"** (optionally bind it to a keyboard
shortcut via `Tools > Modify Keyboard Shortcuts...`). Full details in
`_shared/rstudio-addin/teachingAddins/README.md`.

**Teaching materials are self-contained.** Every course's `_quarto.yml`
sets `embed-resources: true` on both `html` and `revealjs` — every
rendered page (book chapter or slide deck) is a single standalone
`.html` file with no companion `_files/`/`site_libs/` folder, so a deck
can be emailed, dropped on a shared drive, or opened straight from disk
and it just works. Trade-off: bigger individual files, since JS/CSS/fonts
are embedded into every page rather than shared across the site — worth
knowing if a course ever grows to hundreds of chapters, but a non-issue
at the size these courses are.

## Changing the shared look

Edit `_shared/styles/kuleuven-reveal.scss` (slides) and
`_shared/styles/kuleuven-book.scss` (book) — keep their `$kul-*` color
variables in sync between the two files. Every course picks up the
change on its next render, nothing per-course to touch. Each individual
deck can still override its own banner text with the one-line
`<style>:root{ --course-title: "..."; }</style>` right after its YAML.
