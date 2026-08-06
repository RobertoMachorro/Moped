![GitHub](https://img.shields.io/github/license/RobertoMachorro/Moped)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/RobertoMachorro/Moped)
![build](https://github.com/RobertoMachorro/Moped/actions/workflows/build.yaml/badge.svg)
[![StandWithUkraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://vshymanskyy.github.io/StandWithUkraine)

[![SWUbanner](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/banner2-direct.svg)](https://vshymanskyy.github.io/StandWithUkraine)

## Support Moped!

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/T6T3TP9EG)

## License

This FREE software is licensed under [GNU GPLv3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html). Please see the [LICENSE](https://raw.githubusercontent.com/RobertoMachorro/Moped/master/LICENSE) file for details.

![GNU GPLv3 Logo](https://www.gnu.org/graphics/gplv3-127x51.png)

## Language Translations

Proudly supporting the following languages: German, English, Spanish, Finnish, French, Hebrew, Hindi, Italian, Japanese, Dutch, Portuguese, Brazilian Portuguese, and Ukrainian.

Want to see another language? Volunteer to translate!

## Download Binary App

[![Logo](https://github.com/RobertoMachorro/Moped/raw/master/Moped/Assets.xcassets/Logo.imageset/moped-64.png)](https://apps.apple.com/us/app/moped-text-editor/id1477419086?mt=12)

Pre-compiled versions are available directly from [GitHub](https://github.com/RobertoMachorro/Moped/releases) or the [AppStore](https://apps.apple.com/us/app/moped-text-editor/id1477419086?mt=12).

Requires macOS 14.0 (Sonoma) or later.

<img width="1483" height="698" alt="image" src="https://github.com/user-attachments/assets/d3f11bd8-b5d8-49c8-b6e6-5e486ae110de" />

## Features

* **Syntax highlighting** — homegrown, with two dozen languages and eight switchable
  themes, plus any you write yourself as a `.mopedtheme` file
* **Editing essentials** — line numbers, word wrap, auto-indentation, and comment toggling (⌘/)
* **Find & Replace** — system find bar with full regex support (⌘F / ⌘⌥F), plus Jump to Line (⌘L)
* **Status bar** — document type, cursor position, and an inline language picker to override detection on the fly
* **Careful with your files** — encoding auto-detection, binary-file protection, and a prompt to reload when another app changes the file
* **CLI tool** — a `moped` command with a `--wait` mode, so it works as your `git` editor
* **Native macOS** — printing, alternate app icons, session restore, and 13 interface languages

**[Read the full documentation →](DOCUMENTATION.md)**

## Manifesto - General Audience

If you come from the Windows world, you may be missing a small utility: [Notepad](https://en.wikipedia.org/wiki/Microsoft_Notepad), a simple but essential tool for editing plain text files. While macOS counts on its own built-in text editor: [TextEdit](https://support.apple.com/guide/textedit/welcome/mac), it is actually more like a *Rich Text Editor* with full images, fonts and layout support. Similar to the built-in [Windows Write](https://en.wikipedia.org/wiki/Microsoft_Write) or [WordPad](https://en.wikipedia.org/wiki/WordPad).

It kind of feels heavier than it should and in the way. There are [known settings](https://www.techjunkie.com/textedit-plain-text-mode/) to make it look and feel lighter, but inside it's still the same. You can [get the source](https://developer.apple.com/library/archive/samplecode/TextEdit/Introduction/Intro.html) and peek inside. It's bigger and with older code than it needs to be.

*Moped* intends on feeling like Notepad, while being a full native of macOS, with syntax highlighting, themes, line numbers, auto-indenting, and other modern editor conveniences — without getting in the way.

## Manifesto - Advanced Users

While you can install the best text editors on your macOS system ([BBEdit](https://www.barebones.com/products/bbedit), [TextMate](https://macromates.com), [VIM](https://www.vim.org), [Emacs](http://www.gnu.org/software/emacs/), etc) - big and powerful, sometimes, you need just a small and light editor for that one file or note that you need to work on. It has to be light on resources and get out of the way.

*Moped* intends on getting the job done, with all the basics and standard macOS-like keyboard shortcuts.

## Manifesto - Developers

*Moped* intends to be a showcase application and reference for a Document-Based Application built with Swift, SwiftUI, and AppKit. The project deliberately avoids third-party UI frameworks and has no external dependencies at all: the editor core and syntax highlighter live in `MopedEditor`, a local Swift package in this repository that is deliberately kept free of any app-specific types so it could be split out on its own.

If you scroll through the commit history you can see how the pieces fit together. Please check the *Resources* section for references and links.

## Wanted Features

* Code folding support
* Prompt user for Encoding when it is not recognized automatically

## Contributing

Contributions are more than welcome! Please fork the master branch and pull request when ready. Observe formatting and common coding patterns in Swift, for ideological reasons *tabs will remain tabs, not spaces*. Please understand that not all changes will be integrated, in particular they must remain in the ideals of the project.

**See [CONTRIBUTING.md](CONTRIBUTING.md)** for the three checks CI runs and how to run them locally. Release notes are in [CHANGELOG.md](CHANGELOG.md); security reports go through [SECURITY.md](SECURITY.md).

All Pull Requests are automatically evaluated using [GitHub Actions](https://github.com/RobertoMachorro/Moped/actions).

If your document is not being identified and syntax highlighted, please send its content identifier information. It can be obtained with the following command:

```bash
mdls -name kMDItemContentType -name kMDItemContentTypeTree -name kMDItemKind YOURFILE
```

You can check for M1 (ARM) and x86 fat binary support by running lipo:

```
% lipo -archs ~/Library/Developer/Xcode/DerivedData/Moped-*/Build/Products/Release/Moped.app/Contents/MacOS/Moped

x86_64 arm64
```

Use a **Release** build for this. Debug sets `ONLY_ACTIVE_ARCH = YES`, so a Debug build is
single-architecture and prints just `arm64` on Apple Silicon.

Having trouble building / you are new to contributing? Check the following Issue and the video I posted: https://github.com/RobertoMachorro/Moped/issues/36

## Localization Workflow

Moped uses Xcode String Catalogs (`Localizable.xcstrings`) as the source of truth for translations.

To translate without sharing source code:

1. In Xcode, run `Product > Export Localizations...` and generate `.xcloc` packages.
2. Share the `.xcloc` package with translators.
3. Translators edit the package (XLIFF/CAT-tool compatible) and return it.
4. In Xcode, run `Product > Import Localizations...` to apply translated strings.
5. Build and ship the app release with the imported translations.

Adding a new language:

1. Add the language in project localization settings.
2. Export localizations for that language.
3. Import completed translations and release.

## Resources

[Document-Based App Programming Guide for Mac](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/DocBasedAppProgrammingGuideForOSX/Introduction/Introduction.html)
