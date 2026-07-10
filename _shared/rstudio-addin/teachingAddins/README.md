# teachingAddins

One RStudio addin, shared by every course in this repo: **"Render + Push
Course"**. It runs the current course's `scripts/render_all.sh` in a
terminal tab (book + every slide deck), and since every render in that
script fires the course's Quarto `post-render:` hook, the same click also
pushes to GitHub.

## Install (once per machine)

```r
install.packages(c("devtools", "rstudioapi"))
devtools::install_local("_shared/rstudio-addin/teachingAddins", force = TRUE)
```

Then **restart RStudio** so it picks up the new Addins entry.

## Use

1. Open a **course folder** as your RStudio project (e.g. `francais-moderne/`
   via `File > Open Project in New Session... > Existing Directory`) — not
   the `Teaching/` repo root.
2. Click the **Addins** icon in the toolbar (puzzle piece) →
   **"Render + Push Course"**.

   A terminal tab opens and streams `./scripts/render_all.sh` live, exactly
   as if you'd typed it yourself.

## Optional: give it a keyboard shortcut

`Tools > Modify Keyboard Shortcuts...` → search **"Render + Push Course"** →
click the shortcut field → press your combo (e.g. `Ctrl+Alt+Shift+R`, to
avoid clashing with RStudio's built-in `Ctrl+Shift+K` render-file shortcut)
→ Apply.

## Updating the addin later

If you edit `R/render_all_addin.R`, re-run `devtools::install_local(...,
force = TRUE)` and restart RStudio to pick up the change.
