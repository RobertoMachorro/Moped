# Moped v2.2.0 Release Summary

## New Features

- **File change detection** — Moped now detects when an open file has been modified externally and updates accordingly (ecf986b, a653b9f, 934efa1, c41c982).
- **Comment in/out shortcut** — Added keyboard shortcut support for toggling comments (c19251a).
- **Session restore improvements** — Open documents now restore their window position, including across multiple displays (e8ff07e, fa21f75).

## Bug Fixes

- **Auto-Open fix (#83)** — Unrestorable documents are now dropped from saved state instead of breaking the reopen flow (c778148).
- **Reopen reliability** — Initial fixes to document reopen behavior (22cfc3c, f5b7432).
- **macOS target fix** (0c9ede0).
- **Swift compatibility** (516ace4).

## Localization & Code Quality

- New translations for the file-detection feature (c41c982, 934efa1).
- Cleanup of stale/missing localization strings (efcfda1, 00ece80).
- SwiftLint cleanup (3a27c36).
- README updated (b4d5347).

## Build

- Bumped to v2.2.0, build 34 (9cd9107).
