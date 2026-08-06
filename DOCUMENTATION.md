# Moped Documentation

*Moped* is a small, light, native plain-text editor for macOS. It opens fast, stays out of
the way, and does not try to be a word processor: no rich text, no fonts embedded in your
file, no layout — just the characters you typed, saved exactly as you typed them.

This document describes everything Moped does, from a user's point of view.

* **Requires** macOS 14.0 or later
* **License** [GNU GPLv3 or later](https://www.gnu.org/licenses/gpl-3.0.html)
* **Download** [Mac App Store](https://apps.apple.com/us/app/moped-text-editor/id1477419086?mt=12)
  or [GitHub Releases](https://github.com/RobertoMachorro/Moped/releases)

---

## Contents

1. [Getting started](#getting-started)
2. [The editor window](#the-editor-window)
3. [Editing text](#editing-text)
4. [Finding and navigating](#finding-and-navigating)
5. [Syntax highlighting](#syntax-highlighting)
6. [Themes and appearance](#themes-and-appearance)
7. [Settings reference](#settings-reference)
8. [Working with files](#working-with-files)
9. [Making Moped the default editor](#making-moped-the-default-editor)
10. [Printing](#printing)
11. [The `moped` command line tool](#the-moped-command-line-tool)
12. [Keyboard shortcuts](#keyboard-shortcuts)
13. [Languages and translations](#languages-and-translations)
14. [Troubleshooting](#troubleshooting)
15. [Getting help](#getting-help)

---

## Getting started

Install Moped from the Mac App Store, or download the release from GitHub and drag
`Moped.app` into your *Applications* folder.

Moped is a standard macOS document-based app. **File ▸ New** (⌘N) creates an empty
document, **File ▸ Open…** (⌘O) opens an existing one, **File ▸ Open Recent** lists what
you worked on last, and ⌘S saves. Duplicate, Revert, and window tabbing all behave the way
they do in any other macOS app.

### What happens when you launch

*Settings ▸ General ▸ At startup* controls what you see when you open Moped without
double-clicking a file:

| Option | Behavior |
|---|---|
| **File Open Dialog** | Shows the Open panel so you can pick a file. This is the default. |
| **Empty Editor** | Opens one new, empty, untitled document. |
| **Reopen Previous** | Restores the documents that were open when you last quit, each at the window size and position it had. |

This setting only applies to a *plain* launch. If you start Moped by double-clicking a
file, dropping a file on its icon, or running `moped somefile.txt`, that file opens and
nothing else — you never get an unwanted extra window on top of it.

**Reopen Previous** remembers your documents using macOS security-scoped bookmarks, so it
keeps working across restarts without asking for permission again. A window is only
restored to its saved position if that position still lands on a connected display;
otherwise macOS places it normally. If none of the previous documents can be reopened —
they were deleted, renamed, or you closed them all before quitting — Moped opens a single
untitled window instead.

---

## The editor window

The window is deliberately plain: a text area, an optional line-number gutter down the
left, and a thin status bar along the bottom.

### The line-number gutter

Toggle it with *Settings ▸ Editing ▸ Show line numbers* (on by default).

The gutter numbers **logical lines**, not visual rows. When *Wrap long lines* is on and a
long line wraps across three rows on screen, it still gets exactly one number, printed
beside its first row — so the numbers in the gutter always match the line numbers your
compiler, your linter, or `git diff` will quote at you.

The number for the line containing the cursor is highlighted, and the line itself is given
a faint tint using the current theme's selection color. That tint is only drawn when there
is no selection, so it never competes with highlighted text.

### The status bar

| Position | Shows |
|---|---|
| Left | The document's type identifier, as macOS understands it. |
| Right | The cursor's position as `line:column`, in monospaced digits so it does not jitter as you move around. |
| Far right | A language picker. |

The **language picker** is the quickest way to fix a file whose type Moped guessed wrong,
or to color a file that has no extension at all. Pick a language and the document re-colors
immediately. This choice overrides automatic detection for that document, and it also
updates the document's file type, so it is preserved when you save.

---

## Editing text

Moped is a *plain text* editor, and it takes that seriously. The following macOS text
conveniences are deliberately switched off, because in source code and configuration files
they corrupt your content:

* Smart quotes and smart dashes
* Automatic text replacement
* Spelling autocorrection
* Grammar checking

Rich text is off too, and images cannot be dragged into a document.

### Pasting and dragging

**Paste always pastes plain text.** Copy a styled paragraph out of a web page or a Word
document and Moped takes the characters and discards the styling — you never end up with
invisible formatting in a config file. Text dragged in from another application arrives as
plain text for the same reason. Dragging a selection *within* a document still moves it
normally.

### Indentation

Moped works out how the document you opened is already indented rather than imposing a
house style on it. It analyzes up to the first 1000 lines, testing soft-tab widths of 2, 4,
and 8 spaces against what it finds. If the file gives no evidence either way — a new,
empty, or unindented document — it falls back to *Settings ▸ Editing ▸ Indentation*, which
offers `Tab`, `2 Spaces`, or `4 Spaces`.

With that established:

* **Tab** with no selection inserts one real tab character in a tab-indented file, or
  enough spaces to reach the next column stop in a space-indented one.
* **Tab** with a selection indents every line in the selection by one level.
* **Shift-Tab** outdents the selected lines.
* **⌘]** and **⌘[** indent and outdent, with or without a selection.
* **Return** copies the leading whitespace of the line you are leaving onto the new line,
  so a nested block stays nested.

Indenting or outdenting a block is a single undo step, not one per line.

### Commenting

**Editor ▸ Comment Selection** (⌘/) comments or uncomments the selected lines using the
right marker for the document's language — `//` for Swift and C, `#` for Python and shell,
`--` for SQL, and so on, for over 80 languages.

It decides which way to go by looking at what is already there: if every non-blank line in
the selection is already commented, it removes the markers; otherwise it adds them. Markers
are inserted at the common indentation of the block rather than at column zero, so
commented code keeps its shape.

If the document is set to `plaintext`, or its language has no known comment marker, Moped
beeps rather than guessing.

### Zooming

**Editor ▸ Increase** (⌘+), **Decrease** (⌘−), and **Reset** (⌘0) change the text size in
the current window. Decrease stops at 3pt and beeps rather than shrinking further. Reset
returns to the size set in *Settings ▸ Appearance ▸ Font size*.

Zoom is per window and temporary; it does not change your saved preference.

### Word wrap

*Settings ▸ Editing ▸ Wrap long lines* (on by default) reflows long lines to the width of
the window. Turn it off and long lines run off the edge, with a horizontal scroll bar to
follow them. Wrapping is a display choice only — no line breaks are ever added to your file.

---

## Finding and navigating

| Command | Shortcut |
|---|---|
| **Find ▸ Find…** | ⌘F |
| **Find ▸ Find and Replace…** | ⌘⌥F |
| **Find ▸ Jump to Line…** | ⌘L |

Find uses the standard macOS find bar, which appears **above** the text rather than
floating over it, so it never covers the line you are looking at. It searches as you type,
and its options menu gives you the usual controls — ignore case, whole words, wrap around,
and full **regular expression** matching. Press **Esc** to dismiss it.

⌘⌥F opens the bar with the replace field already showing, even from a cold start, so
replacing does not take two keystrokes.

**Jump to Line** (⌘L) asks for a line number and takes you there, scrolling it into view
and placing the cursor at its start. The field is pre-filled with the line you are
currently on, which makes it easy to see where you are before typing where you want to go.
Moped beeps if you enter something that is not a positive line number, or a line number
past the end of the document.

---

## Syntax highlighting

Moped's syntax highlighter is homegrown — there are no third-party dependencies anywhere in
the app. It ships tokenizers for two dozen languages and offers 35 entries in its
language pickers once common aliases are counted.

### How a language is chosen

1. macOS identifies the file's type when it is opened, usually from its extension.
2. Moped maps that type to one of its languages.
3. If the type has no tokenizer, the document opens as `plaintext` — readable and fully
   editable, just not colored.
4. You can override all of that at any time with the language picker in the status bar.

*Settings ▸ Editing ▸ Syntax language* sets the language for documents whose type says
nothing useful — new untitled documents, and files with no extension. It defaults to
`plaintext`.

### Available languages

`plaintext` · `asciidoc` · `bash` · `c` · `cpp` · `cs` · `css` · `diff` · `erb` · `go` ·
`groovy` · `handlebars` · `html` · `java` · `javascript` · `json` · `jsx` · `kotlin` ·
`less` · `markdown` · `objectivec` · `php` · `python` · `ruby` · `rust` · `scss` ·
`shell` · `sql` · `swift` · `toml` · `tsx` · `twig` · `typescript` · `xml` · `yaml`

Several of these share a tokenizer with a close relative — `kotlin` and `groovy` are
colored by the Java tokenizer, `scss` and `less` by the CSS one, `objectivec` by the C++
one, `asciidoc` by the Markdown one, and the template formats (`erb`, `twig`,
`handlebars`) by the HTML one. They are listed under their own names because those are the
names you know your files by.

**Markdown** colors headings, fenced code blocks, blockquotes, list markers, inline code,
emphasis, and links. The contents of a fenced code block are rendered as literal text —
Moped does not highlight the embedded language inside the fence.

**HTML and XML** color tag names, attribute names and values, comments, doctypes,
processing instructions, `CDATA` payloads, and entities. The bodies of `<script>` and
`<style>` elements render as plain text.

**JSX and TSX** are JavaScript and TypeScript plus element names, so `<Card>` and
`</Card>` stand out from the code around them. Attribute names are not colored separately.

**Diff** colors whole lines rather than code: added lines green, removed lines red, hunk
headers and file headers picked out, and the unchanged context left plain so the changes
are what you see. It applies to `.diff` and `.patch` files.

Highlighting is applied as a display layer, never as part of your text. It is never written
to disk, it never marks a document as edited, and it never lands on the undo stack —
switching themes or languages will not consume an undo step, and undo after heavy editing
undoes only your edits.

### Large files

Above **256 KB**, syntax highlighting switches off automatically so that scrolling and
typing stay fast. Everything else about the document works normally. If a file crosses that
threshold while you have it open and you reload it, the change takes effect in whichever
direction applies.

---

## Themes and appearance

*Settings ▸ Appearance ▸ Theme* ships with eight themes, and lists any you add yourself
alongside them:

| Theme | Notes |
|---|---|
| **System** | No theme: macOS's own text colors. |
| **Default** | Moped's own light and dark palette. |
| **Forest** | Olive and fern greens over warm paper. |
| **Nebula** | Violet and magenta, with mint and cyan accents. |
| **Ocean** | Cool blues and teals, with one warm accent for numbers. |
| **Solarized** | The original low-contrast palette, kept faithful. |
| **Turbo** | Borland's Turbo C++ and Turbo Pascal: yellow on blue. Always dark. |
| **Xcode-like** | The default. Approximates Xcode's own two themes. |

Each theme sets the background, text, gutter, selection, and cursor colors along with a
color for every kind of syntax token.

A theme can carry **two palettes**, one for Light and one for Dark, and switch between
them **live**. Flip your Mac between Light and Dark with a document open and the editor
changes with it — no reopening, no restart. Every theme above does this except **Turbo**,
which reproduces a fixed DOS screen and has no light half to switch to. A theme of your
own follows the appearance only if its file has a `dark` section; without one it stays
pinned to a single palette, exactly as Turbo does — which is how you get an always-dark
editor on a Mac running Light.

**System** is the odd one out: it takes its background, text, and selection colors from
macOS itself rather than from fixed values. It still keeps a hand-tuned set of syntax
colors for each appearance, so you do not lose your highlighting the way a purely
system-colored editor would.

Changing any theme applies to open documents in place, without losing your scroll position.

### Custom themes

Themes are plain JSON files with a `.mopedtheme` extension, and the ones Moped ships are
real files you can read. **Settings ▸ Appearance ▸ Reveal Themes Folder** opens the
folder they live in. Every `.mopedtheme` in there shows up in the theme picker under
whatever `name` it declares. Moped re-reads the folder each time you switch back to it,
so saving a file is enough — no restart.

Moped owns the `.mopedtheme` type, so double-clicking one opens it in Moped with JSON
highlighting already on — Reveal Themes Folder, double-click, edit, save is the whole
loop.

**To change a theme, copy it rather than editing it in place.** Duplicate the file, give
the copy a new filename *and* a new `name`, and edit that. Moped never overwrites a
theme file that already exists, but it does recreate one of its own that has gone
missing — so an edited `Default.mopedtheme` survives, while a deleted one comes back on
the next launch. A copy under your own name is yours for good.

If a file will not parse, Moped skips it and loads the rest; the reason is written to
the system log. If two files claim the same `name`, the one whose filename sorts first
wins.

#### The format

```json
{
  "version": 1,
  "name": "Nord",
  "colors": {
    "background": "#ECEFF4",
    "foreground": "#2E3440",
    "gutterBackground": "#E5E9F0",
    "gutterForeground": "#8FBCBB",
    "selection": "#D8DEE9",
    "caret": "#2E3440"
  },
  "tokens": {
    "comment": "#616E88",
    "keyword": "#81A1C1",
    "string": "#A3BE8C"
  },
  "dark": {
    "colors": {
      "background": "#2E3440",
      "foreground": "#D8DEE9",
      "gutterBackground": "#3B4252",
      "gutterForeground": "#4C566A",
      "selection": "#434C5E"
    }
  }
}
```

| Key | Required | Meaning |
|---|---|---|
| `version` | yes | Format version. Currently always `1`; Moped refuses anything else. |
| `name` | yes | What the theme picker shows, and what gets stored in your preferences. Not the filename. |
| `colors` | yes | The editor chrome — see below. |
| `tokens` | no | Syntax colors. Any kind you leave out is drawn in `colors.foreground`. |
| `dark` | no | A second palette for Dark appearance. Same shape, minus `name` and `version`. |

Inside `colors`:

| Key | Required | Meaning |
|---|---|---|
| `background` | yes | Editor background. |
| `foreground` | yes | Body text, and the fallback for any token you do not color. |
| `gutterBackground` | yes | Line-number gutter background. |
| `gutterForeground` | yes | Line numbers. |
| `selection` | yes | Selection highlight. Also tints the current line, at reduced opacity. |
| `caret` | no | The insertion point. Defaults to the inverse of `background`. |

Colors are hexadecimal and nothing else: `#RGB`, `#RRGGBB`, or `#RRGGBBAA` for
transparency. The `#` is optional and case does not matter, so `#81A1C1`, `81a1c1`, and
`#81A1C1FF` are the same color.

Every key `tokens` accepts:

| | | |
|---|---|---|
| `boolean` | `keyword` | `punctuation.special` |
| `comment` | `keyword.function` | `string` |
| `constructor` | `keyword.return` | `text.literal` |
| `diff.minus` | `method` | `text.title` |
| `diff.plus` | `number` | `type` |
| `function.call` | `operator` | `variable` |
| `include` | `parameter` | `variable.builtin` |

Names Moped does not recognize are ignored rather than treated as errors, so a file
written for a newer version still loads here.

#### Light and dark in one file

Add a `dark` section and the theme follows the macOS appearance: the top level becomes
the Light palette, `dark` is used under Dark. `dark` needs its own `colors`, but its
`tokens` are optional — leave them out and it reuses the top-level ones, which is what
you want when only the chrome should change.

To pin a theme to one appearance instead, give it no `dark` section. That is also how
you get an always-dark editor on a Mac running Light: copy the `dark` block's contents
up to the top level of a new file and delete the `dark` section.

### Font

*Settings ▸ Appearance* lets you pick any installed font and a size between 9 and 24.
The default is **Menlo** at **13**.

**Show only monospaced fonts** filters the picker down to fixed-pitch faces. It affects the
list only — if you have deliberately chosen a proportional font, it stays selected and
stays visible in the picker rather than being silently replaced.

The gutter uses a slightly smaller version of the same font.

### App icon

*Settings ▸ General ▸ App icon* offers **Default**, **Pink**, **Black**, **Red**,
**Rainbow**, and **Beige**. The change applies immediately, in the Dock and everywhere else.

---

## Settings reference

Open with **Moped ▸ Settings…** (⌘,). The window has four sections.

### General

| Setting | Choices | Default |
|---|---|---|
| At startup | File Open Dialog · Empty Editor · Reopen Previous | File Open Dialog |
| App icon | Default · Pink · Black · Red · Rainbow · Beige | Default |

### Appearance

| Setting | Choices | Default |
|---|---|---|
| Theme | System · Default · Forest · Nebula · Ocean · Solarized · Turbo · Xcode-like, plus any custom `.mopedtheme` | Xcode-like |
| Font | Any installed font | Menlo |
| Show only monospaced fonts | Checkbox | Off |
| Font size | 9–24 | 13 |

### Editing

| Setting | Choices | Default |
|---|---|---|
| Syntax language | Any of the 35 supported languages | plaintext |
| Wrap long lines | Checkbox | On |
| Show line numbers | Checkbox | On |
| Indentation | Tab · 2 Spaces · 4 Spaces | Tab |

### Advanced

| Setting | Control |
|---|---|
| File associations | **Manage…**, which opens [Default File Associations](#making-moped-the-default-editor) |

Settings apply to open documents immediately.

---

## Working with files

### What Moped opens

Moped opens plain text. It registers 88 text file types with macOS — everything from
`.swift`, `.py`, and `.json` through `.yaml`, `.toml`, `.ini`, and `.tex` to `.ahk`,
`.gcode`, and `.nix` — and recognizes about forty more type identifiers when opening a
file, including Apple-specific ones such as property lists, AppleScript text, and Xcode
shell scripts.

A file type Moped does not recognize still opens, as plain text without coloring, provided
its contents are actually text.

### Size limit

Moped opens files up to **16 MB**. Larger files are refused with a message naming both the
limit and the actual size of the file:

> Moped opens files up to 16 MB. This file is 24.3 MB.

Files above **256 KB** open normally but without syntax highlighting, as described under
[Large files](#large-files).

### Binary files

Before decoding anything, Moped inspects the first 8 KB of the file. A NUL byte, or more
than 30% control bytes, means the file is not text, and Moped refuses it rather than
showing you a window full of garbage:

> Moped can only open text files, and this file appears to be binary.

UTF-16 and UTF-32 byte-order marks are recognized and exempted from this check, so those
files still open as the text they are.

### Text encoding

Moped detects the file's encoding automatically. If macOS cannot identify it, Moped tries
UTF-8 and then falls back to Mac OS Roman, which maps every possible byte value and so
always succeeds. A text file is therefore never turned away for its encoding — the check
that does turn files away is the binary check described above, which is precisely why it
runs before the decoders.

Files are written back in the encoding they were read in, so opening and saving does not
silently re-encode your file. The exception is when you type something the original
encoding cannot represent — an emoji in an ASCII file, say. Rather than losing the
character, Moped saves the document as UTF-8 and keeps it as UTF-8 for the rest of the
session.

There is currently no way to choose an encoding by hand. That is a known gap, tracked under
*Wanted Features* in the [README](README.md).

### When another app changes the file

Moped watches every open document on disk. If another application writes to, extends,
renames, or replaces the file, you are asked what to do:

> **File Changed on Disk**
> This file was modified by another application. Would you like to reload it?
> **Reload** · **Keep Mine**

**Reload** discards your in-memory copy and re-reads the file. **Keep Mine** leaves your
version alone; the next save overwrites what is on disk.

This handles the atomic saves other editors perform — where the file is replaced rather
than written in place — and it ignores Moped's own writes, so saving your own document
never triggers the prompt.

If a reload cannot proceed, because the file has grown past 16 MB or has become binary or
undecodable, Moped tells you and **leaves your open document untouched**:

> Moped could not reload this file.

---

## Making Moped the default editor

Moped can take over as the default application for the text file types you choose.

Go to **Settings ▸ Advanced ▸ File associations** and click **Manage…** to open the
*Default File Associations* window.

The window lists every text type Moped supports, with each type's extensions and the icon
and name of the application that currently handles it. Types already owned by Moped are
marked *Moped (current)* and cannot be selected again; types nothing handles show
*No app assigned*.

To save you the work of hunting through a long list, the window pre-selects every type
currently handled by **TextEdit** or by nothing at all — which is usually exactly what you
came here to change. Three shortcuts adjust that: **Select All**, **Select TextEdit**, and
**Select None**. A search field filters the list by type name, extension, or the name of
the app that currently owns it.

Click **Apply** to make the change. Note the warning at the top of the window:

> NOTE: macOS will prompt to confirm each selection, as this is a Sandboxed app.

That is a macOS security requirement, not something Moped can skip: because Moped runs
sandboxed, the system asks you to confirm each reassignment individually. Selecting thirty
types means thirty confirmations.

---

## Printing

**File ▸ Print…** (⌘P) prints the document as plain monospaced text with 72pt (one inch)
margins on all four sides. Long lines wrap to the page width.

The printed page is the text and nothing else: no headers, no footers, no line numbers, and
no syntax coloring.

---

## The `moped` command line tool

Moped can install a small `moped` command so you can open files from a terminal.

Choose **Moped ▸ Setup moped CLI**. Moped symlinks its bundled script into
`/usr/local/bin/moped` and confirms:

> **Setup Complete**
> moped is now available at /usr/local/bin/moped.

If it cannot write there — commonly because `/usr/local/bin` does not exist or is not
writable by your account — it tells you and gives you the exact command to run yourself:

> **Unable to install moped.**
> Try running: sudo ln -sf /Applications/Moped.app/Contents/Resources/moped /usr/local/bin/moped

### Usage

```bash
moped [--wait] <file>...
```

Open one or more files:

```bash
moped notes.txt config.yaml
```

Relative paths are resolved before being handed to Moped, so `moped ./notes.txt` works from
any directory.

`moped -h` (or `--help`) prints the usage line above.

### `--wait`

With `--wait`, the command opens the files and then **blocks until you close them**, which
is what tools like `git` need from an editor. It returns as soon as every file you opened
is closed, or immediately if you quit Moped.

Use Moped as your Git commit editor:

```bash
git config --global core.editor "moped --wait"
```

Now `git commit` opens the commit message in Moped and waits for you to save and close the
window before continuing.

---

## Keyboard shortcuts

### Moped's own commands

| Shortcut | Command |
|---|---|
| ⌘P | Print… |
| ⌘F | Find… |
| ⌘⌥F | Find and Replace… |
| ⌘L | Jump to Line… |
| ⌘/ | Comment Selection |
| ⌘+ | Increase font size |
| ⌘− | Decrease font size |
| ⌘0 | Reset font size |
| ⌘] | Indent |
| ⌘[ | Outdent |
| Tab | Indent selection, or insert an indent |
| ⇧Tab | Outdent selection |
| Return | New line, preserving the current indentation |
| Esc | Dismiss the find bar |

### Standard macOS shortcuts

Moped is a normal document-based Mac app, so ⌘N, ⌘O, ⌘S, ⇧⌘S, ⌘W, ⌘Z, ⇧⌘Z, ⌘X, ⌘C, ⌘V, ⌘A,
⌘,, and ⌘Q all behave exactly as they do everywhere else, along with the usual text
navigation and selection keys.

---

## Languages and translations

Moped's interface is translated into 13 languages: German, English, Spanish, Finnish,
French, Hebrew, Hindi, Italian, Japanese, Dutch, Portuguese, Brazilian Portuguese, and
Ukrainian. It follows your macOS language setting automatically.

Want to see another language? Volunteers are welcome — see *Localization Workflow* in the
[README](README.md#localization-workflow) for how translations are handled.

---

## Troubleshooting

**My file opens but isn't colored.**
Either the file's type has no tokenizer yet, or macOS is not identifying the file the way
you expect. Set the language by hand with the picker in the status bar as an immediate fix.
To get it fixed properly, please
[open an issue](https://github.com/RobertoMachorro/Moped/issues) and include the output of:

```bash
mdls -name kMDItemContentType -name kMDItemContentTypeTree -name kMDItemKind YOURFILE
```

**My file won't open at all.**
Moped refuses two kinds of file, and says which applies: it is larger than 16 MB, or it is
binary rather than text. See [Working with files](#working-with-files).

**The text looks like garbage — wrong accents or odd symbols.**
The encoding was detected incorrectly. Moped has no manual encoding override yet; the
workaround is to convert the file first, for example
`iconv -f windows-1252 -t utf-8 old.txt > new.txt`.

**A big file feels slow, and the colors are gone.**
Above 256 KB, highlighting is turned off deliberately to keep editing responsive. This is
expected.

**`moped` isn't found in my terminal.**
Run **Moped ▸ Setup moped CLI**. If it reports a failure, run the `sudo ln -sf` command it
offers. If your shell still cannot find it, confirm `/usr/local/bin` is on your `PATH`.

**Moped keeps asking to reload a file.**
Something else is writing to it — a build tool, a sync client, or another editor. Choose
**Keep Mine** to protect your version.

**I set a proportional font and now the picker looks wrong.**
That is *Show only monospaced fonts* filtering the list. Your font is still selected and
still shown; uncheck the box to see the full list again.

---

## Getting help

The **Help** menu links to:

* [Read License](https://www.gnu.org/licenses/gpl-3.0.html) — the GNU GPL v3
* [Get Source Code](https://github.com/RobertoMachorro/Moped) — the project on GitHub
* [Report an Issue](https://github.com/RobertoMachorro/Moped/issues) — bugs and requests
* Logo by BSGStudio — credit for the scooter artwork
* **Moped Help** (⌘?) — this documentation, online

Bug reports and pull requests are welcome. See *Contributing* in the [README](README.md#contributing).

If Moped is useful to you, you can [support the project on Ko-fi](https://ko-fi.com/T6T3TP9EG).
