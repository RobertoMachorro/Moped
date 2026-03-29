# Moped v2.0.0 Release Notes

## New Features
- **Alternate App Icons** — Choose from multiple icon themes (Beige, Black, Default, Pink, Rainbow, Red) in Preferences
- **Jump to Line** — Jump directly to any line number via command
- **Indent / Outdent Shortcuts** — Keyboard shortcuts for indenting/outdenting selections; auto-detects indent style
- **Optional Line Numbers** — Toggle the line number ruler on/off in Preferences
- **CLI Tool (`moped`)** — New Swift CLI companion for opening files from Terminal, with proper sandboxing and GUI sync
- **Localization** — Full English and Spanish translations via Xcode String Catalogs; CI enforces localized strings

## UI / UX Improvements
- Preferences window migrated from Storyboard to SwiftUI
- Cursor now starts at line 1 (not EOF) when opening a file
- Fixed Find panel appearance in light and dark mode
- Fixed Find panel focus handling
- Removed border artifacts in the editor
- Menu items now use Unicode ellipsis (…) instead of three periods (...)

## Performance
- Syntax highlighting automatically disabled on medium/large files to prevent freezing
- Debounce optimization for large text edits
- Line number ruler optimizations on startup and during editing
- Theme and syntax highlight caching
- Line count uses optimized UTF-16 scanning with caching

## Bug Fixes
- Fixed freezing text area on text selection
- Fixed print background rendering issue
- Fixed syntax highlight corruption after copy/paste
- Fixed print failure alert to use localized message
- Fixed CLI sandboxing issue when launching Moped from Terminal
- Fixed shell injection vulnerability in CLI error message
- Fixed deprecated API usage
- Fixed UTType handling
- Added file size validation in document model

## Infrastructure
- App Sandbox entitlement enabled and tested
- `MopedCLI` target added with its own signing and executable attributes
- CI: ripgrep installed via Homebrew for localization validation