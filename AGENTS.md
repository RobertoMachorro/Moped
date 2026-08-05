# Agent Guidelines

Refer to the following files for mandatory instructions:

* @10-RULES.md

If there are conflicting rules in this or the documents below, prompt for clarification.

## Project Context

* macOS document-based app written in Swift
* UI is SwiftUI-based
* Formatting uses tabs (no space indentation)
* SwiftLint is enforced; `line_length` is currently disabled

## MUST DO

These are the same three gates CI runs on every pull request. A change is not done
until all three pass.

* Run SwiftLint for verification; CI runs `swiftlint --strict` over the whole project, so it must be clean everywhere
* Run the editor package tests: `swift test --package-path MopedEditor`
* Run the localization check: `./scripts/check_localized_strings.sh` (needs `ripgrep`)

Any user-facing string must have a key in `Moped/Localizable.xcstrings`. The check
script only catches string literals in common call sites, so strings reaching the UI
through a variable have to be verified by hand.

## Coding Guidelines

* Preserve SwiftUI view hierarchy and structure when editing UI
* Match existing Swift style and keep indentation as tabs
* Keep SwiftLint rules in mind; avoid adding long lines even while `line_length` is disabled
* Prefer small, focused changes that match existing patterns
