# AGENTS Plan

## Project Context
- macOS document-based app written in Swift
- UI is Storyboard-based
- Formatting uses tabs (no space indentation)
- SwiftLint is enforced; `line_length` is currently disabled but will be enabled soon

## Primary References
- Project overview and contributing info: `README.md`
- Lint rules: `.swiftlint.yml`
- Xcode project: `Moped.xcodeproj`

## Coding Guidelines
- Preserve Storyboard wiring and identifiers when editing UI
- Match existing Swift style and keep indentation as tabs
- Keep SwiftLint rules in mind; avoid adding long lines even while `line_length` is disabled
- Prefer small, focused changes that match existing patterns

## Typical Tasks
- Feature tweaks in Swift files under `Moped/`
- Storyboard edits with minimal diff and verified connections
- Updates to assets in `Moped/Assets.xcassets`

## Validation
- Run SwiftLint when making Swift changes (if available)
- Build in Xcode and verify basic app launch
- Recheck Storyboard warnings after UI changes
