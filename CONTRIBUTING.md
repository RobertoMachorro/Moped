# Contributing to Moped

Thanks for helping out. Moped is a small, deliberately simple macOS text editor, and the
bar for changes is "does this keep it simple and native".

## Before you start

- **Requirements:** macOS 14.0 or later, and a recent Xcode. Open `Moped.xcodeproj`; there
  is nothing to install first — Moped has no third-party dependencies, and the editor core
  lives in the local `MopedEditor` Swift package.
- **Read [AGENTS.md](AGENTS.md) and [10-RULES.md](10-RULES.md).** They are written for AI
  coding agents but they are the project's actual working rules, and they apply to people
  too: tabs not spaces, surgical changes, match the surrounding style.

## The three gates

CI runs exactly these three on every pull request, and a change is not done until all
three pass locally:

```bash
swiftlint --strict
```

```bash
swift test --package-path MopedEditor
```

```bash
./scripts/check_localized_strings.sh
```

`swiftlint --strict` fails on warnings, and CI pins the SwiftLint version so local and CI
agree — see the comment in [.github/workflows/build.yaml](.github/workflows/build.yaml)
before bumping it. The localization script needs [ripgrep](https://github.com/BurntSushi/ripgrep)
(`brew install ripgrep`).

**Note:** ⌘U in Xcode currently runs **no tests** — the shared scheme's test list is empty
and the package tests are not wired into it. Run `swift test --package-path MopedEditor`
instead; that is what CI does. Don't read a green ⌘U as a passing test run.

## Localization

Every user-facing string needs a key in `Moped/Localizable.xcstrings`, translated into all
supported languages. The check script catches string literals in the common SwiftUI call
sites (`Text`, `Button`, `Toggle`, `Label`, `Picker`, `.navigationTitle`, alert fields), but
it cannot see a string that reaches the UI through a variable — verify those by hand.

Moped ships in German, English, Spanish, Finnish, French, Hebrew, Hindi, Italian, Japanese,
Dutch, Portuguese, Brazilian Portuguese and Ukrainian. Translation help is very welcome; a
pull request touching only `Localizable.xcstrings` is a perfectly good contribution.

## Testing your change

The automated tests cover the editor package. The app target has no unit tests, so anything
touching documents, preferences, printing or the CLI needs a manual pass —
[manual-checklist.md](manual-checklist.md) lists the cases, and `TestFiles/` has fixtures to
open.

## Adding a language

Add a `LanguageDefinition` under `MopedEditor/Sources/MopedEditor/Languages/`, register it in
`LanguageRegistry`, map the file type in `Moped/LanguagesUTI.plist`, add its comment marker to
`Moped/LanguageComments.plist`, and add a `TestFiles/Languages/Sample.<ext>` that exercises
strings, escapes, comments and numbers — the constructs that actually break tokenizers.

## Reporting a bug

Open an [issue](https://github.com/RobertoMachorro/Moped/issues). If a file isn't highlighted
or opens as the wrong type, include the output of:

```bash
mdls -name kMDItemContentType -name kMDItemContentTypeTree -name kMDItemKind YOURFILE
```

That one command answers most "why isn't my file recognized" reports.

## License

Moped is [GNU GPLv3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html). By contributing
you agree your work is licensed the same way.
