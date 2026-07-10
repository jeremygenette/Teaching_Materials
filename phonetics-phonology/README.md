# COURSE TITLE

This is a self-contained Quarto **book** project. It renders two things
from the same source files:

- a **book** (chapter-by-chapter website with sidebar/search/TOC) — like
  [experimentology](https://github.com/langcog/experimentology)
- one or more **KU Leuven-themed slide decks** (revealjs) built by
  including the same chapter content, so you never write a topic twice

```
COURSE-NAME/
├── _quarto.yml              ← book config + revealjs config, KU Leuven theme
├── index.qmd                ← book landing page
├── references.bib
├── chapters/                ← ONE FILE PER TOPIC — the actual content lives here
│   └── 001-example-chapter.qmd
├── decks/                   ← slide decks assembled FROM chapters/ via {{< include >}}
│   └── full-deck.qmd
├── images/                  ← drop images here, reference as ../images/xxx.png
├── scripts/
│   ├── render_all.sh         ← ONE command: book + every deck
│   ├── build_deck.R         ← generate a new custom deck from a subset of chapters
│   └── post-render-push.R   ← runs automatically after `quarto render`, pushes to GitHub
└── README.md                ← this file
```

Shared theme/scripts (used by every course, not just this one) live one
level up in `../_shared/`. Don't duplicate them here — edit them once,
every course picks it up.

## Adding a new chapter — step by step

1. Create `chapters/00X-my-topic.qmd`. Number it so it sorts where you
   want; the number has no other meaning.
2. Start the file with **exactly one `# Title`** heading at the top —
   that's both the book's chapter title *and* what becomes a horizontal
   section break when the file is pulled into a slide deck. Everything
   under it is normal Quarto markdown (`##`/`###` become slide sections
   when used in a deck).
3. Register the chapter in the book's table of contents — add it to
   `book: chapters:` in `_quarto.yml`:
   ```yaml
   book:
     chapters:
       - index.qmd
       - part: "Some part name"
         chapters:
           - chapters/001-example-chapter.qmd
           - chapters/00X-my-topic.qmd   # ← add this line
   ```
4. If it should also appear in a slide deck, add one line to that deck's
   `.qmd`:
   ```
   {{< include ../chapters/00X-my-topic.qmd >}}
   ```
5. Render (see below). That's it — no other file needs to change.

## Rendering — one command for everything

```bash
./scripts/render_all.sh
```

Builds the book (`index.qmd` + every `chapters/*.qmd`) and every deck in
`decks/`, in one go. It exists because Quarto book projects don't
auto-render "loose" files like `decks/*.qmd` — a bare `quarto render`
only builds the book's chapter list — so this script explicitly renders
each deck too.

Every render call inside this project (this script, `quarto render`
alone, a single-deck render, or `quarto preview`) triggers the
`post-render:` hook and pushes to GitHub — see "Auto-push" below.

```bash
quarto preview                      # live-preview the book
quarto render decks/full-deck.qmd   # (re)build just one deck
quarto preview decks/full-deck.qmd  # live-preview that deck
```

### Self-contained output

Both formats set `embed-resources: true` — every rendered page (book
chapters and slide decks alike) is one standalone `.html` file, no
companion `_files/` folder, so decks can be emailed or opened straight
from disk. Trade-off: larger individual files, since JS/CSS is embedded
per page rather than shared.

## Building a one-off custom deck (e.g. a single session's slides)

```r
source("scripts/build_deck.R")

list_chapters()   # see what's available

build_deck(
  chapters = c("003-topic-a", "001-example-chapter"),
  title    = "Séance : révision",
  out_file = "decks/revision-01.qmd",
  render   = TRUE
)
```

## Auto-push to GitHub

`_quarto.yml`'s `post-render:` hook runs `scripts/post-render-push.R`
after every render inside this project — book, a single deck, or a
`quarto preview` — so anything you knit ends up on GitHub without an
extra step. Requirements, once per machine:

- `install.packages("gert")`
- this course folder is inside a git repo with an `origin` remote
- git has non-interactive push credentials available (a PAT stored in
  the system credential manager, or a passphrase-less SSH key)

If any of that isn't set up, the push step fails gracefully and just
prints a message — it never breaks the render.

## Changing the look

Don't edit anything here — the KU Leuven theme is shared across every
course. Edit `../_shared/styles/kuleuven-reveal.scss` (slides) and
`../_shared/styles/kuleuven-book.scss` (book), and every course updates
at once. Each individual deck can still set its own banner text via the
one-line `<style>:root{ --course-title: "..."; }</style>` right after
its YAML front matter.
