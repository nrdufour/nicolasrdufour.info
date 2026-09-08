# CLAUDE.md

Guidance for Claude Code working in this repository.

## What this is

Personal landing page for nicolasrdufour.info, built with Hugo. A single page:
`layouts/index.html` plus `static/` (favicon, photo, stylesheet). There is no
`content/` directory, so taxonomies, RSS and the sitemap are disabled in
`hugo.toml`. No JavaScript, no third-party requests: one handwritten
stylesheet, self-hosted Merriweather (OFL, in `static/fonts/`) for headings and
a `prefers-color-scheme` dark palette.

## Commands

The flake's dev shell (loaded by direnv) carries every tool. `just` lists the
recipes; `just check` is exactly what CI runs, so a red build reproduces in one
command.

- `just serve` - Hugo dev server with live reload
- `just build` - build into `public/`
- `just check` - fmt-check, lint, build-check, confusables

## Conventions

- **A convention arrives with its gate.** If something matters enough to agree
  on, add the check to `just check` in the same change. An unenforced
  convention decays.
- **ASCII in source, with judgement.** No characters confusable with ASCII or
  invisible: em and en dashes, minus signs, smart quotes, middle dots, ellipses,
  non-breaking and zero-width spaces. Visually distinct symbols are fine and
  wanted - degrees, arrows, `>=`. CI enforces exactly this.
- **Tool versions live in `flake.nix`**, nowhere else. No version numbers in
  workflow YAML.
- **Renovate defaults are shared** (`nemo/renovate-config`). `renovate.json5`
  only carries this repo's exceptions.
