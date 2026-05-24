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

* Run SwiftLint for verification; SwiftLint must be clean for the changed lines/files only, not the whole project

## Coding Guidelines

* Preserve SwiftUI view hierarchy and structure when editing UI
* Match existing Swift style and keep indentation as tabs
* Keep SwiftLint rules in mind; avoid adding long lines even while `line_length` is disabled
* Prefer small, focused changes that match existing patterns
