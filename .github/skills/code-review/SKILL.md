---
name: code-review
description: Review guidance for Moped, a sandboxed macOS SwiftUI text editor with a homegrown TextKit 1 editor core in the local MopedEditor package. Use when reviewing pull requests in this repository — it carries the invariants that a generic Swift review misses, and the suggestions this project does not want.
---

# Reviewing Moped

Moped is a document-based macOS app: SwiftUI shell, AppKit editor. The editor is
`MopedEditor`, a **local** Swift package with **zero external dependencies** — 3.0.0
deliberately replaced Highlightr and STTextView/Neon with in-house code. Adding a
third-party dependency is a design change, not a cleanup; flag any PR that introduces one
unless the PR is explicitly about that.

Bias the review toward **invariants that are load-bearing but invisible** — the ones below
have each already caused a real bug here. Ordinary style nits are handled by
`swiftlint --strict`; do not spend the review on them.

## The three gates

CI (`.github/workflows/build.yaml`) runs all of these on every PR, in this order:

1. `./scripts/check_localized_strings.sh`
2. `swiftlint --strict` over the whole project
3. `swift test --package-path MopedEditor`
4. the Xcode build

A change is not done until all pass. If a PR touches behavior covered by the package
tests and adds none, say so.

## Localization

Every user-facing string needs a key in `Moped/Localizable.xcstrings`. The catalog is at
**100% coverage across 13 locales** (de, en, es, fi, fr, he, hi, it, ja, nl, pt, pt-BR,
uk) — a new key with only English in it silently breaks that, and the check script will
not catch it.

Key naming: `pref.<setting>.title`, `pref.section.<section>`, `option.<group>.<value>`,
`menu.*`, `alert.*`, `window.*`, `status.*`, `error.*`, `about.*`, `default_editor.*`.
The script's allowlist (`scripts/check_localized_strings.sh`) rejects anything else.

**Where the script is blind, and you should look by hand:**

- A string reaching the UI through a *variable* rather than a literal at the call site.
- A literal passed to a *helper* rather than to `Toggle`/`Button`/`Text` directly —
  `PreferencesView.checkbox("pref.…", …)` is the standing example. The script's patterns
  never see it, so a missing catalog key ships as a raw key on screen.

## Adding a preference: three legs, and the one that gets forgotten

`Preferences` (`Moped/Preferences.swift`) is `@unchecked Sendable` **because it holds no
mutable stored state** — every property reads and writes `UserDefaults`. A stored property
added to it invalidates that annotation. Flag one.

Booleans are stored as the strings `"Yes"` / `"No"` with a `do…`-prefixed `Bool` reader.
This is deliberate and long-standing; do not suggest converting them to `Bool` or
`@AppStorage`.

A new editor-affecting preference must be wired in **all** of:

1. `Preferences` — the `@objc dynamic var` plus its `do…` reader.
2. `EditorState.makeEditor(model:delegate:)` — the initial build.
3. `EditorState.applyPreferences()` — the `.preferencesChanged` observer.
4. `PreferencesView` — the row, with a catalog key.

**Legs 2 and 3 are separate call sites with no shared helper.** Missing #3 means the
setting only takes effect when some *other* preference is later written; missing #2 means
it only takes effect on an already-open window. Check for both explicitly — this is the
single most likely defect in a settings PR.

## The editor core

`MopedTextView` is an `NSTextView` on an **explicit TextKit 1 stack**. Temporary
attributes and the `NSRulerView` gutter both depend on `NSLayoutManager`; "why not
TextKit 2" is not a useful review comment.

- **Never write rendering state into `NSTextStorage`.** Token colors live as layout-manager
  *temporary attributes* precisely so they cannot enter the text, land on the undo stack,
  or mark the document dirty. A PR that adds an attribute to the storage for display
  purposes is a bug, however well it renders.
- **`SyntaxHighlighter` owns two exclusive resources**: `textStorage.delegate` (one slot
  only) and the `.foregroundColor` temporary attribute, which it clears and rewrites over
  the whole edited range on every pass. Anything else writing that attribute will be
  silently wiped.
- **`allowsNonContiguousLayout` is on.** Any self-computed visible range must call
  `ensureLayout(forBoundingRect:in:)` first, or the glyph range comes back short for a
  region scrolled into for the first time — the gutter shipped that bug once.
- **But never force layout from inside a draw**, and never mutate rendering state inside
  `NSTextStorage.processEditing`. Both re-enter TextKit underneath code that has already
  captured geometry. The established fix is to defer to the next runloop turn
  (`LineNumberRulerView.updateThickness`, `SyntaxHighlighter.schedulePass`).
- **Prefer partial invalidation.** `setNeedsDisplay(rect)` over `needsDisplay = true` where
  a bounded region is knowable — a full redraw on every caret move made cursor movement
  scale with document size. A whole-view invalidation needs a reason in a comment.
- **Drawing order matters.** The layout manager paints selection and find-bar highlights in
  `drawBackground(forGlyphRange:at:)`, before glyphs. Decorations that must survive a
  selection belong after `super.drawGlyphs`, not in a background override.

## Themes

`MopedTheme` is `Sendable` only because every color it carries is a plain **sRGB component
color**. A theme built from `NSColor.controlAccentColor` or any catalog/dynamic system
color reintroduces deferred appearance resolution and breaks the guarantee. Flag it.

Adding a color to `MopedTheme` is not a small change: it touches the struct, `renamed(_:)`,
`paired(withDark:)`, all seven files in `Themes/`, the System theme, the `.mopedtheme`
read/write maps and `fileFormatVersion` in `EditorTheme+File.swift`, plus `ThemeFileTests`.
If a PR can derive its color from an existing one instead (the gutter separator and the
whitespace markers both use the palette's own foreground at 30% alpha), prefer that and
say so.

Painted colors are pushed out from `MopedTextView.applyTheme()`, which is the single funnel
reached by both a theme change and `viewDidChangeEffectiveAppearance()`. A new painted
color set anywhere else will not survive a light/dark flip.

## Conventions

- **Tabs for indentation**, in Swift and in tests. `line_length` is disabled but long lines
  are still unwelcome.
- **Doc comments explain *why*, not *what*.** The house style names the bug or constraint
  that forced the code to be the way it is. A comment restating the signature adds nothing;
  a non-obvious decision with no comment is worth flagging.
- **Tests name the bug they pin down**, and assertion messages are full sentences
  explaining the failure. Logic that would otherwise only run inside a graphics context is
  split into a testable non-drawing method — `LineNumberRulerView.visibleLineNumbers(for:)`
  and `WhitespaceLayoutManager.whitespaceMarkers(forGlyphRange:)` are the precedents.
- Strict concurrency is `complete` in the app target, and the package mirrors it via
  `.enableExperimentalFeature("StrictConcurrency")` so `swift test` checks the same rules.
- **User-visible changes update the docs**: `DOCUMENTATION.md` (including its settings
  tables), `CHANGELOG.md`, and `manual-checklist.md` for anything only a human can verify.
  A feature PR that touches none of them is probably incomplete.
- The Settings window has a **fixed, measured** `.frame(width: 590, height: 246)`, sized
  against the widest locale. The comment above it is a measurement log — a PR that changes
  the frame without extending that comment, or that adds a pane row without saying whether
  it still fits, deserves a question.
- Printing (`SourcePrintView`) is a **separate `CTFramesetter` path** that does not share
  the editor's layout manager. New editor rendering does not print automatically; if a PR
  implies otherwise, check.

## Do not raise these

They are settled decisions, and re-litigating them costs the maintainer time:

- Tabs instead of spaces; the `"Yes"`/`"No"` preference encoding; `@unchecked Sendable` on
  `Preferences`; TextKit 1 instead of TextKit 2.
- "Consider extracting this into a protocol/abstraction" for single-use code. This project
  wants the minimum code that solves the problem — no speculative abstraction.
- Line length, given `line_length` is disabled in `.swiftlint.yml`.
- Suggesting a third-party library for something the package already does by hand.
