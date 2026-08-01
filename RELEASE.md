# Moped v3.0.0 Release Summary

Build 50. The headline of this release is that Moped's editor is now its own code.

## The Editor

- **Homegrown editor and syntax highlighter** — Highlightr, then STTextView and Neon,
  have all been replaced by `MopedEditor`, a local Swift package in this repository
  (3617a3f, 7aaf007). Moped now has **no external dependencies at all**. The package
  is deliberately free of app-specific types so it could be split out on its own.
- **Incremental highlighting** — colors are applied as layout-manager *temporary
  attributes*, so they never enter the text storage, never land on the undo stack, and
  never mark the document dirty. Only the lines affected by an edit are re-tokenized,
  and a document-wide cascade is spread across runloop turns instead of blocking a
  keystroke.
- **About twenty languages**, plus Markdown, HTML, and XML (4ae7496), driven by
  data-only language definitions — adding a language means adding one struct.
- **Line number gutter** rewritten as an `NSRulerView`, with caret-line emphasis
  (e1ae2f9).
- **Five built-in themes**, with legacy Highlightr theme names mapped forward so
  existing preferences keep working.

## New Features

- **Indentation detection** — Moped infers a document's own indent style and matches
  it, including 4- and 8-space documents (f5b79e9), falling back to a new
  *Default Indentation* preference (tab, 2 spaces, or 4 spaces).
- **Find and Find/Replace** are now a floating panel above the content (388f817).
- **Large file mode** — highlighting turns off past 256 KB to keep typing responsive.
- **Files up to 4 MB** can now be opened; past that Moped refuses with its own alert
  naming both the limit and the file's size, rather than the system default (2f1adb0).

## Bug Fixes

- **Fixed a macOS 26 crash** when typing ``` in a Markdown document (08e2470).
- **Fixed "Publishing changes from within view updates"** warnings from the model
  (fd34689) and from cursor-position updates (7819ed5).
- **Programmatic text replacement** is now flagged rather than detected by comparing
  whole strings, which was expensive on large documents (90ba92c).
- **Undecodable files are refused** instead of opening as a placeholder string, which
  a later save could write over the original file.
- **`moped --wait`** now reports completion reliably when Moped is quit, instead of
  relying on the helper's polling fallback.
- **Document type** is applied to the document that owns the editor rather than to
  whichever window happens to be frontmost.
- **Background and text render fixes** (f91bca6).

## Code Quality

- SwiftLint now runs in CI, and the config excludes generated SPM output.
- The shared Xcode scheme is no longer covered by a `.gitignore` rule.
- Removed the discontinued BetterCodeHub config and an unused SwiftFormat config;
  SwiftLint is the single enforced formatter.
- 87 tests cover the editor package, including a randomized consistency check that
  asserts incremental highlighting always matches a from-scratch pass.
- Added `manual-checklist.md` for pre-release integrity testing (556fad3).

## Localization

Still shipping German, English, Spanish, Finnish, French, Hebrew, Hindi, Italian,
Japanese, Dutch, Portuguese, Brazilian Portuguese, and Ukrainian. App icon names and
the new file-size and encoding alerts are now localized; those strings are marked
`needs_review` and want a translator pass before release.
