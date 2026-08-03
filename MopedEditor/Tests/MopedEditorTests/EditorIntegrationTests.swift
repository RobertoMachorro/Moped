//
//  EditorIntegrationTests.swift
//
//  MopedEditor - The homegrown text editor core and syntax highlighter used by Moped.
//  Copyright © 2019-2026 Roberto Machorro. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import AppKit
import XCTest
@testable import MopedEditor

/// Checks the colors that actually reach the layout manager when a real
/// `MopedTextView` is driven the way the app drives it.
@MainActor
final class EditorIntegrationTests: EditorTestCase {
	func testHighlightsSwiftAfterSettingText() {
		let (_, textView) = makeEditor()
		textView.language = "swift"
		textView.setPlainText("import AppKit\nlet x = 42 // note\n")
		drainHighlightPasses()

		let text = textView.string as NSString
		let theme = MopedTheme.defaultLightPalette
		XCTAssertEqual(color(at: text.range(of: "import").location, in: textView), theme.color(for: .include))
		XCTAssertEqual(color(at: text.range(of: "let").location, in: textView), theme.color(for: .keyword))
		XCTAssertEqual(color(at: text.range(of: "42").location, in: textView), theme.color(for: .number))
		XCTAssertEqual(color(at: text.range(of: "// note").location, in: textView), theme.color(for: .comment))
	}

	/// `.xml`, `.plist` and `.svg` files all resolve to the language name "xml" via
	/// LanguagesUTI.plist; this is the path that used to render them plain.
	func testHighlightsXMLDocument() {
		let (_, textView) = makeEditor()
		textView.language = "xml"
		textView.setPlainText("<?xml version=\"1.0\"?>\n<plist version=\"1.0\">\n<key>a</key>\n</plist>\n")
		drainHighlightPasses()

		let text = textView.string as NSString
		let theme = MopedTheme.defaultLightPalette
		XCTAssertEqual(color(at: text.range(of: "<?xml").location, in: textView), theme.color(for: .keyword))
		XCTAssertEqual(color(at: text.range(of: "\"1.0\"").location, in: textView), theme.color(for: .string))
		XCTAssertEqual(color(at: text.range(of: "key").location, in: textView), theme.color(for: .keyword))
	}

	func testPlainTextLanguageAppliesNoColors() {
		let (_, textView) = makeEditor()
		textView.language = "plaintext"
		textView.setPlainText("import AppKit\nlet x = 42\n")
		drainHighlightPasses()

		XCTAssertNil(color(at: 0, in: textView))
	}

	func testTypingRehighlightsIncrementally() {
		let (_, textView) = makeEditor()
		textView.language = "swift"
		textView.setPlainText("let a = 1\n")
		drainHighlightPasses()

		// Type a comment opener at the end, as a user would.
		textView.setSelectedRange(NSRange(location: textView.string.utf16.count, length: 0))
		textView.insertText("var b = 2 // tail", replacementRange: textView.selectedRange())
		drainHighlightPasses()

		let text = textView.string as NSString
		let theme = MopedTheme.defaultLightPalette
		XCTAssertEqual(color(at: text.range(of: "var").location, in: textView), theme.color(for: .keyword))
		XCTAssertEqual(color(at: text.range(of: "// tail").location, in: textView), theme.color(for: .comment))
		// The untouched first line keeps its coloring.
		XCTAssertEqual(color(at: text.range(of: "let").location, in: textView), theme.color(for: .keyword))
	}

	func testOpeningBlockCommentCascadesToFollowingLines() {
		let (_, textView) = makeEditor()
		textView.language = "swift"
		textView.setPlainText("let a = 1\nlet b = 2\nlet c = 3\n")
		drainHighlightPasses()

		textView.setSelectedRange(NSRange(location: 0, length: 0))
		textView.insertText("/*\n", replacementRange: textView.selectedRange())
		drainHighlightPasses()

		let text = textView.string as NSString
		let theme = MopedTheme.defaultLightPalette
		for fragment in ["let a", "let b", "let c"] {
			XCTAssertEqual(
				color(at: text.range(of: fragment).location, in: textView),
				theme.color(for: .comment),
				"\(fragment) should be commented out by the unterminated /*"
			)
		}
	}

	func testThemeChangeRecolorsInPlace() {
		let (_, textView) = makeEditor()
		textView.language = "swift"
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()

		let keywordLocation = (textView.string as NSString).range(of: "let").location
		XCTAssertEqual(color(at: keywordLocation, in: textView), MopedTheme.defaultLightPalette.color(for: .keyword))

		textView.theme = .solarizedDarkPalette
		drainHighlightPasses()

		XCTAssertEqual(color(at: keywordLocation, in: textView), MopedTheme.solarizedDarkPalette.color(for: .keyword))
		XCTAssertEqual(textView.backgroundColor, MopedTheme.solarizedDarkPalette.background)
		XCTAssertEqual(textView.string, "let x = 1\n", "Re-theming must not disturb the text")
	}

	/// A paired theme has to re-resolve itself against the view's appearance. System is
	/// the extreme case: its colours are snapshots of AppKit's, taken against whatever
	/// appearance was current when the snapshot was made.
	func testSystemThemeFollowsTheViewAppearance() throws {
		let (_, textView) = makeEditor(theme: .system)
		textView.appearance = NSAppearance(named: .aqua)
		textView.language = "swift"
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()

		let lightBackground = try XCTUnwrap(textView.backgroundColor.usingColorSpace(.sRGB))
		let keywordLocation = (textView.string as NSString).range(of: "let").location
		XCTAssertEqual(
			color(at: keywordLocation, in: textView),
			MopedTheme.defaultLightPalette.color(for: .keyword),
			"the light appearance should use the light token palette"
		)

		textView.appearance = NSAppearance(named: .darkAqua)
		drainHighlightPasses()

		let darkBackground = try XCTUnwrap(textView.backgroundColor.usingColorSpace(.sRGB))
		XCTAssertLessThan(
			darkBackground.brightnessComponent,
			lightBackground.brightnessComponent,
			"switching to dark should darken the editor background"
		)
		XCTAssertEqual(
			color(at: keywordLocation, in: textView),
			MopedTheme.defaultDarkPalette.color(for: .keyword),
			"token colors are layout-manager temporary attributes, so they only follow "
				+ "the appearance if the highlighter is re-run"
		)
		XCTAssertEqual(textView.string, "let x = 1\n", "Re-resolving must not disturb the text")
	}

	/// An unpaired theme must ignore the appearance entirely — a theme file with no
	/// `dark` section stays put when the user switches to Light.
	func testFixedThemeIgnoresTheViewAppearance() {
		let (_, textView) = makeEditor(theme: .solarizedDarkPalette)
		textView.appearance = NSAppearance(named: .aqua)
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()

		XCTAssertEqual(textView.backgroundColor, MopedTheme.solarizedDarkPalette.background)

		textView.appearance = NSAppearance(named: .darkAqua)
		drainHighlightPasses()

		XCTAssertEqual(textView.backgroundColor, MopedTheme.solarizedDarkPalette.background)
	}

	/// The user-facing path the built-in themes do not exercise: a theme decoded from a
	/// `.mopedtheme` file, with a `dark` section, has to follow the appearance the same
	/// way `system` does. Nothing else covered decode → pair → live appearance switch.
	func testThemeFromFileWithDarkSectionFollowsTheViewAppearance() throws {
		let json = """
		{
			"version": 1, "name": "Paired",
			"colors": {
				"background": "#FFFFFF", "foreground": "#101010",
				"gutterBackground": "#F5F5F5", "gutterForeground": "#888888",
				"selection": "#BFD7FF"
			},
			"tokens": {"keyword": "#AA00AA"},
			"dark": {
				"colors": {
					"background": "#1F2129", "foreground": "#EAEAEE",
					"gutterBackground": "#262932", "gutterForeground": "#7A7D85",
					"selection": "#3D578C"
				},
				"tokens": {"keyword": "#66DDFF"}
			}
		}
		"""
		let theme = try MopedTheme(data: Data(json.utf8))
		let (_, textView) = makeEditor(theme: theme)
		textView.appearance = NSAppearance(named: .aqua)
		textView.language = "swift"
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()

		let keywordLocation = (textView.string as NSString).range(of: "let").location
		XCTAssertEqual(textView.backgroundColor, NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
		XCTAssertEqual(
			color(at: keywordLocation, in: textView),
			NSColor(srgbRed: 0xAA / 255, green: 0, blue: 0xAA / 255, alpha: 1)
		)

		textView.appearance = NSAppearance(named: .darkAqua)
		drainHighlightPasses()

		XCTAssertEqual(
			textView.backgroundColor,
			NSColor(srgbRed: 0x1F / 255, green: 0x21 / 255, blue: 0x29 / 255, alpha: 1),
			"the dark section's chrome should take over"
		)
		XCTAssertEqual(
			color(at: keywordLocation, in: textView),
			NSColor(srgbRed: 0x66 / 255, green: 0xDD / 255, blue: 1, alpha: 1),
			"token colors are temporary attributes, so they only follow if the highlighter re-runs"
		)
	}

	func testDisablingHighlightingClearsColors() {
		let (_, textView) = makeEditor()
		textView.language = "swift"
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()
		XCTAssertNotNil(color(at: 0, in: textView))

		textView.isHighlightingEnabled = false
		drainHighlightPasses()
		XCTAssertNil(color(at: 0, in: textView), "Large-file mode must clear coloring")

		textView.isHighlightingEnabled = true
		drainHighlightPasses()
		XCTAssertNotNil(color(at: 0, in: textView), "Re-enabling must restore coloring")
	}

	func testLanguageSwitchRecolors() {
		let (_, textView) = makeEditor()
		textView.language = "swift"
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()

		let text = textView.string as NSString
		let keywordLocation = text.range(of: "let").location
		XCTAssertEqual(color(at: keywordLocation, in: textView), MopedTheme.defaultLightPalette.color(for: .keyword))

		textView.language = "json"
		drainHighlightPasses()

		XCTAssertNil(color(at: keywordLocation, in: textView), "`let` is not a JSON keyword")
		XCTAssertEqual(
			color(at: text.range(of: "1").location, in: textView),
			MopedTheme.defaultLightPalette.color(for: .number),
			"Numbers still highlight under JSON"
		)
	}

	func testProgrammaticTextDoesNotRegisterUndo() {
		let (_, textView) = makeEditor()
		textView.language = "swift"
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()

		XCTAssertEqual(textView.undoManager?.canUndo, false, "setPlainText must not create an undo step")
	}
}
