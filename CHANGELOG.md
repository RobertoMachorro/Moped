# Changelog

All notable changes to Moped. Versions follow the app's marketing version.

## 3.0.0

Moped's editor is now its own code. The syntax highlighting, line numbering, indentation
and comment handling all moved into a local `MopedEditor` package with no third-party
dependencies, replacing Highlightr and, briefly, STTextView/Neon.

### Added

- **Homegrown syntax highlighting** for 24 languages, offered under 35 names in the
  language picker. New in this release: JSX, TSX, TOML and unified diff.
- **Four new themes** — Ocean, Forest, Nebula and Turbo — alongside Default, Solarized,
  Xcode-like and a System theme that follows your appearance. Every theme except Turbo
  pairs a light and a dark palette and switches with the system.
- **Custom themes.** Write a `.mopedtheme` JSON file, drop it in
  *Application Support ▸ Moped ▸ Themes*, and it appears in the theme picker. The button in
  *Settings ▸ Themes* reveals that folder in Finder.
- **`moped` command-line tool** with a `--wait` mode, so it works as a `git` editor:
  `git config --global core.editor "moped --wait"`.
- **Indentation detection** — Moped notices whether a file uses tabs, 4 spaces or
  8 spaces and matches it.
- **Binary-file protection.** Moped checks the first 8 KB and refuses files that are not
  text instead of opening them as mojibake and re-encoding them on save.
- **Alternate app icons**, session restore, and a redesigned Settings window.
- **XML highlighting**, and Markdown fenced code blocks rendered as literal text.
- Documentation: a full [user manual](DOCUMENTATION.md), reachable from **Help ▸ Moped
  Help**, plus a manual test checklist and sample files under `TestFiles/`.

### Changed

- **Maximum file size is now 16 MB** (was 4 MB). Files over 256 KB open with highlighting
  switched off so typing stays responsive.
- **The language picker only lists languages that actually highlight.** Previously it
  listed every file type Moped could open.
- Find and Replace is a floating panel, with full regex support.
- Requires **macOS 14.0 (Sonoma) or later**.

### Upgrading from 2.x

Your settings carry over, with two translations applied automatically:

- **Themes.** Light and dark variants collapsed into single appearance-following themes, so
  a saved *Default Dark* or *Solarized Dark* now resolves to *Default* or *Solarized* and
  follows your system appearance. Highlightr theme names from 2.x (`monokai`, `dracula`,
  `atom-one-dark` and the rest) map onto the closest built-in; there is no longer a
  pinned-dark built-in to point them at. Pick a new theme in *Settings ▸ Themes* if the
  automatic choice is not what you want.
- **Default language.** A saved default of a language that has no tokenizer — `lua`,
  `haskell`, `perl` and similar — resets to *Plain Text*, because the picker no longer
  offers names that would not highlight. Those files still open; they just open as plain
  text, as they effectively did before.

### Fixed

- Crash on macOS 26 when typing ``` in a Markdown document.
- Runaway highlighting states: an unterminated PHP heredoc, a bash `<<` left-shift, a Rust
  `'"'` char literal, or a `//` inside a CSS `url()` no longer colour the rest of the file.
- A large highlight cascade truncated by its per-pass budget is now resumed instead of
  leaving the rest of the document with stale colours.
- The document type is carried across a save in both directions, so saving an untitled file
  as `.py` switches the picker and the highlighting.
- The line-number gutter repaints when the view scrolls.
- Reload failures leave the open buffer untouched and say why.

[Full commit history since 2.2.0](https://github.com/RobertoMachorro/Moped/compare/v2.2.0...v3.0.0)
