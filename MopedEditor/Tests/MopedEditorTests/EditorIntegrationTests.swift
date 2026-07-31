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

/// Drives a real `MopedTextView` (storage, layout manager, highlighter) the way the
/// app does, and checks the colors that actually reach the layout manager.
@MainActor
final class EditorIntegrationTests: XCTestCase {
	/// A windowless text view has no responder chain to inherit an undo manager
	/// from, so supply one the way the document window does in the app.
	private final class UndoProvidingDelegate: NSObject, NSTextViewDelegate {
		let manager = UndoManager()

		func undoManager(for view: NSTextView) -> UndoManager? {
			manager
		}
	}

	private var undoDelegate: UndoProvidingDelegate?

	private func makeEditor(
		theme: MopedTheme = .defaultLight
	) -> (scrollView: NSScrollView, textView: MopedTextView) {
		let editor = MopedTextView.scrollableEditor(theme: theme)
		editor.scrollView.frame = NSRect(x: 0, y: 0, width: 600, height: 400)
		let delegate = UndoProvidingDelegate()
		editor.textView.delegate = delegate
		undoDelegate = delegate
		return editor
	}

	/// Lets the highlighter's coalesced main-queue pass run.
	private func drainHighlightPasses() {
		for _ in 0..<10 {
			RunLoop.current.run(until: Date().addingTimeInterval(0.02))
		}
	}

	private func color(at location: Int, in textView: MopedTextView) -> NSColor? {
		textView.layoutManager?.temporaryAttribute(
			.foregroundColor, atCharacterIndex: location, effectiveRange: nil
		) as? NSColor
	}

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

	func testToggleCommentRoundTrips() {
		let (_, textView) = makeEditor()
		textView.language = "swift"
		textView.lineCommentMarker = "//"
		textView.setPlainText("let a = 1\nlet b = 2\n")
		textView.setSelectedRange(NSRange(location: 0, length: (textView.string as NSString).length))

		XCTAssertTrue(textView.toggleLineComment())
		XCTAssertEqual(textView.string, "// let a = 1\n// let b = 2\n")

		XCTAssertTrue(textView.toggleLineComment())
		XCTAssertEqual(textView.string, "let a = 1\nlet b = 2\n")
	}

	func testToggleCommentWithoutMarkerIsRefused() {
		let (_, textView) = makeEditor()
		textView.lineCommentMarker = nil
		textView.setPlainText("plain line\n")
		textView.setSelectedRange(NSRange(location: 0, length: 0))

		XCTAssertFalse(textView.toggleLineComment())
		XCTAssertEqual(textView.string, "plain line\n")
	}

	/// The reported symptom: Tab inserted 2 spaces in a 4-space-indented document
	/// because the width could never be inferred as 4.
	func testTabInsertsFourSpacesInFourSpaceDocument() {
		let (_, textView) = makeEditor()
		textView.setPlainText("def a():\n    x = 1\n    if x:\n        return x\n")
		// Caret at the start of the (empty) last line.
		textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))

		textView.insertTab(nil)

		XCTAssertTrue(
			textView.string.hasSuffix("\n    "),
			"Expected a 4-space indent, got \(textView.string.suffix(8).debugDescription)"
		)
	}

	func testTabInsertsTwoSpacesInTwoSpaceDocument() {
		let (_, textView) = makeEditor()
		textView.setPlainText("function a() {\n  if (x) {\n    go();\n  }\n}\n")
		textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))

		textView.insertTab(nil)

		XCTAssertTrue(
			textView.string.hasSuffix("\n  "),
			"Expected a 2-space indent, got \(textView.string.suffix(8).debugDescription)"
		)
	}

	func testOutdentRemovesFourSpacesInFourSpaceDocument() {
		let (_, textView) = makeEditor()
		textView.setPlainText("def a():\n    x = 1\n        y = 2\n")
		let nsText = textView.string as NSString
		let lastLine = nsText.range(of: "        y = 2")
		textView.setSelectedRange(lastLine)

		textView.adjustIndentation(false)

		XCTAssertTrue(
			textView.string.hasSuffix("\n    y = 2\n"),
			"Expected one 4-space level removed, got \(textView.string.debugDescription)"
		)
	}

	func testIndentAndOutdentSelection() {
		let (_, textView) = makeEditor()
		textView.setPlainText("\ta = 1\n\tb = 2\n")
		textView.setSelectedRange(NSRange(location: 0, length: (textView.string as NSString).length))

		textView.adjustIndentation(true)
		XCTAssertEqual(textView.string, "\t\ta = 1\n\t\tb = 2\n")

		textView.adjustIndentation(false)
		XCTAssertEqual(textView.string, "\ta = 1\n\tb = 2\n")
	}

	func testEditingActionsAreUndoable() {
		let (_, textView) = makeEditor()
		textView.lineCommentMarker = "//"
		textView.setPlainText("let a = 1\n")
		textView.setSelectedRange(NSRange(location: 0, length: 0))

		XCTAssertTrue(textView.toggleLineComment())
		XCTAssertEqual(textView.undoManager?.canUndo, true)

		textView.undoManager?.undo()
		XCTAssertEqual(textView.string, "let a = 1\n", "Toggling a comment must be undoable")
	}

	func testWrapToggleUpdatesContainerAndScroller() {
		let (scrollView, textView) = makeEditor()
		textView.wrapsLines = true
		XCTAssertEqual(textView.textContainer?.widthTracksTextView, true)
		XCTAssertFalse(scrollView.hasHorizontalScroller)

		textView.wrapsLines = false
		XCTAssertEqual(textView.textContainer?.widthTracksTextView, false)
		XCTAssertTrue(scrollView.hasHorizontalScroller)
	}

	func testGutterToggle() {
		let (scrollView, textView) = makeEditor()
		textView.showsLineNumberGutter = true
		XCTAssertTrue(scrollView.rulersVisible)
		XCTAssertTrue(scrollView.verticalRulerView is LineNumberRulerView)

		textView.showsLineNumberGutter = false
		XCTAssertFalse(scrollView.rulersVisible)
	}

	func testFontSizeActions() {
		let (_, textView) = makeEditor()
		textView.defaultFontSize = 13.0
		textView.editorFont = NSFont.monospacedSystemFont(ofSize: 13.0, weight: .regular)

		textView.fontSizeIncreaseMenuItemSelected(nil)
		XCTAssertEqual(textView.editorFont.pointSize, 14.0)

		textView.fontSizeDecreaseMenuItemSelected(nil)
		XCTAssertEqual(textView.editorFont.pointSize, 13.0)

		textView.fontSizeIncreaseMenuItemSelected(nil)
		textView.fontSizeResetMenuItemSelected(nil)
		XCTAssertEqual(textView.editorFont.pointSize, 13.0)
	}
}
