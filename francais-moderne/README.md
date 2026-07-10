# Français Moderne

Self-contained Quarto **book** project. Renders two things from the same
source files:

- the **book** (this website — chapter by chapter, sidebar, search)
- the **KU Leuven slide decks** (revealjs) under `decks/`, built by
  including the same chapter content — you never write a topic twice

```
francais-moderne/
├── _quarto.yml              ← book config (parts/chapters) + revealjs config
├── index.qmd                ← book landing page
├── references.bib
├── chapters/                ← ONE FILE PER SÉANCE — the actual content
│   ├── 000-intro.qmd
│   ├── 001-phonetique-affrication.qmd
│   ├── 002-phonologie-voyelles.qmd
│   ├── 003-phonologie-liaison.qmd
│   ├── 004-morphologie-verlan.qmd
│   ├── 005-morphosyntaxe-participe-passe.qmd
│   └── 006-syntaxe-subjonctif.qmd
├── decks/                   ← slide decks assembled FROM chapters/
│   ├── full-deck.qmd                  the whole course, in order
│   ├── chapter-01-phonetique-only.qmd  a single-topic deck
│   └── custom-sequence-example.qmd    an out-of-order custom mix
├── images/                  ← clipboard-*.png etc., referenced as ../images/...
├── scripts/
│   ├── render_all.sh         ← ONE command: book + every deck
│   ├── build_deck.R         ← generate a new custom deck from a subset of chapters
│   └── post-render-push.R   ← runs after every `quarto render`, pushes to GitHub
└── README.md                ← this file
```

The KU Leuven theme (both slides and book) and the git-push helper are
shared with every other course — they live in `../_shared/`, not here.
See the top-level `../README.md` if you want to change the look.

## Adding a new séance / chapter — step by step

1. Create `chapters/007-my-new-topic.qmd`.
2. Start it with **exactly one `# Title`** heading at the top — this is
   both the book chapter's title and the horizontal section break used
   when the file is included into a slide deck. `##` → vertical slide
   group, `###` → individual slide, same as the existing chapters.
3. Add it to the book's table of contents in `_quarto.yml`:
   ```yaml
   book:
     chapters:
       - index.qmd
       - chapters/000-intro.qmd
       - part: "Phonétique et phonologie"
         chapters: [...]
       - part: "Syntaxe"
         chapters:
           - chapters/006-syntaxe-subjonctif.qmd
           - chapters/007-my-new-topic.qmd   # ← add here (or a new part:)
   ```
4. If it needs its own single-topic deck (like `chapter-01-phonetique-only.qmd`),
   duplicate that file and edit its title + `{{< include >}}` line — or
   add it to `decks/full-deck.qmd` to include it in the full run-through.
5. Render (below). Nothing else needs to change.

## Rendering — one command for everything

```bash
./scripts/render_all.sh
```

This builds the **book** (`index.qmd` + every `chapters/*.qmd`) and then
every deck in `decks/`, one by one. It exists because Quarto book
projects don't auto-render "loose" files like `decks/*.qmd` the way
website projects do — a bare `quarto render` only builds the book's own
chapter list, so this script explicitly renders each deck too.

Every one of those render calls also fires this project's `post-render:`
hook — so **every knit pushes to GitHub automatically**, whether you run
this script, render the book alone (`quarto render`), render one deck
by hand (`quarto render decks/full-deck.qmd`), or just `quarto preview`
something. See "Auto-push to GitHub" below.

Other useful commands:
```bash
quarto preview                      # live-preview the book
quarto render decks/full-deck.qmd   # (re)build just one deck
quarto preview decks/full-deck.qmd  # live-preview that deck
```

### Self-contained output

Both formats set `embed-resources: true`, so every rendered `.html` —
each book chapter page and each slide deck — is a single standalone
file with no companion `_files/`/`site_libs/` folder. That's what makes
them work as "teaching materials": you can email a deck, drop it in a
shared drive, or open it straight from disk, and it just works, fonts
and all. The trade-off is bigger individual files (JS/CSS is duplicated
into every page rather than shared) — a non-issue at this course's
scale, but worth knowing if a course grows to hundreds of chapters.

## Building a one-off custom deck (e.g. this week's révision)

```r
source("scripts/build_deck.R")

list_chapters()   # see what's available

build_deck(
  chapters = c("004-morphologie-verlan", "002-phonologie-voyelles"),
  title    = "Séance : Verlan + Voyelles (révision)",
  out_file = "decks/revision-verlan-voyelles.qmd",
  render   = TRUE
)
```

## Auto-push to GitHub

`_quarto.yml`'s `post-render:` hook runs `scripts/post-render-push.R`
after **every** render Quarto does inside this project — the whole book,
a single chapter/deck rendered by hand, or a `quarto preview` — not just
when you run `render_all.sh`. Each run stages, commits, and pushes
whatever changed; if nothing changed, it's a harmless no-op. So the
short version is: knit anything here, it ends up on GitHub, no extra
step. Requirements, once per machine:

- `install.packages("gert")`
- this folder is inside a git repo with an `origin` remote configured
- git has non-interactive push credentials (a PAT via the system
  credential manager, or a passphrase-less SSH key)

If any of that isn't set up, the push step fails gracefully and just
prints a message — it never breaks the render.

## Changing the look

Don't edit theme files here — `../_shared/styles/kuleuven-reveal.scss`
(slides) and `../_shared/styles/kuleuven-book.scss` (book) are shared
across every course. Retheme once, every course updates. Each deck can
still set its own banner text via the `<style>:root{ --course-title:
"..."; }</style>` line right after its YAML front matter.

The revealjs theme/options are embedded directly in each deck's own YAML
front matter (not `_quarto.yml`, and not `decks/_metadata.yml` either —
Quarto book projects don't reliably apply either of those to files that
aren't listed book chapters). `scripts/build_deck.R` writes this
automatically for any new deck you generate with it. If you ever hand-write
a new deck file instead, copy the `format: revealjs:` block from
`decks/full-deck.qmd` rather than writing just `format: revealjs`.
