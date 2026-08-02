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
		let theme = MopedTheme.defaultLight
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
		let theme = MopedTheme.defaultLight
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
		let theme = MopedTheme.defaultLight
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
		let theme = MopedTheme.defaultLight
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
		XCTAssertEqual(color(at: keywordLocation, in: textView), MopedTheme.defaultLight.color(for: .keyword))

		textView.theme = .solarizedDark
		drainHighlightPasses()

		XCTAssertEqual(color(at: keywordLocation, in: textView), MopedTheme.solarizedDark.color(for: .keyword))
		XCTAssertEqual(textView.backgroundColor, MopedTheme.solarizedDark.background)
		XCTAssertEqual(textView.string, "let x = 1\n", "Re-theming must not disturb the text")
	}

	/// The System theme is the only one that has to re-resolve itself: its colours are
	/// snapshots of AppKit's, taken against whatever appearance was current when the
	/// snapshot was made.
	func testSystemThemeFollowsTheViewAppearance() throws {
		let (_, textView) = makeEditor(theme: .system(for: try XCTUnwrap(NSAppearance(named: .aqua))))
		textView.appearance = NSAppearance(named: .aqua)
		textView.language = "swift"
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()

		let lightBackground = try XCTUnwrap(textView.backgroundColor.usingColorSpace(.sRGB))
		let keywordLocation = (textView.string as NSString).range(of: "let").location
		XCTAssertEqual(
			color(at: keywordLocation, in: textView),
			MopedTheme.defaultLight.color(for: .keyword),
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
			MopedTheme.defaultDark.color(for: .keyword),
			"token colors are layout-manager temporary attributes, so they only follow "
				+ "the appearance if the highlighter is re-run"
		)
		XCTAssertEqual(textView.string, "let x = 1\n", "Re-resolving must not disturb the text")
	}

	/// A fixed theme must ignore the appearance entirely — picking Solarized Dark and
	/// then switching to Light must not repaint the editor.
	func testFixedThemeIgnoresTheViewAppearance() {
		let (_, textView) = makeEditor(theme: .solarizedDark)
		textView.appearance = NSAppearance(named: .aqua)
		textView.setPlainText("let x = 1\n")
		drainHighlightPasses()

		XCTAssertEqual(textView.backgroundColor, MopedTheme.solarizedDark.background)

		textView.appearance = NSAppearance(named: .darkAqua)
		drainHighlightPasses()

		XCTAssertEqual(textView.backgroundColor, MopedTheme.solarizedDark.background)
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
		XCTAssertEqual(color(at: keywordLocation, in: textView), MopedTheme.defaultLight.color(for: .keyword))

		textView.language = "json"
		drainHighlightPasses()

		XCTAssertNil(color(at: keywordLocation, in: textView), "`let` is not a JSON keyword")
		XCTAssertEqual(
			color(at: text.range(of: "1").location, in: textView),
			MopedTheme.defaultLight.color(for: .number),
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
