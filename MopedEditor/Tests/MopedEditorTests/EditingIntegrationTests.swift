//
//  EditingIntegrationTests.swift
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

/// Editing behaviors on a live text view: comment toggling, tab and indent
/// handling, undo, and the view-level toggles.
@MainActor
final class EditingIntegrationTests: EditorTestCase {
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

	func testTabInsertsTabInTabIndentedDocument() {
		let (_, textView) = makeEditor()
		textView.setPlainText("func a() {\n\tlet x = 1\n\tif x > 0 {\n\t\treturn x\n\t}\n}\n")
		textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))

		textView.insertTab(nil)

		XCTAssertTrue(
			textView.string.hasSuffix("\n\t"),
			"Expected a hard tab, got \(textView.string.suffix(8).debugDescription)"
		)
		XCTAssertFalse(textView.string.hasSuffix(" "), "A tab document must never get spaces")
	}

	/// Tab mid-line (not just at an indent) still inserts a hard tab.
	func testTabMidLineInTabIndentedDocument() {
		let (_, textView) = makeEditor()
		textView.setPlainText("func a() {\n\tlet x = 1\n\tlet y = 2\n}\n")
		let caret = (textView.string as NSString).range(of: "let x = 1")
		textView.setSelectedRange(NSRange(location: NSMaxRange(caret), length: 0))

		textView.insertTab(nil)

		XCTAssertTrue(
			textView.string.contains("let x = 1\t"),
			"Expected a hard tab mid-line, got \(textView.string.debugDescription)"
		)
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

	/// Deleting content must invalidate the cached indent analysis — a 2-space
	/// document emptied by a delete falls back to the default (tab) indentation
	/// instead of keeping the stale 2-space style.
	func testDeleteInvalidatesIndentStyleCache() {
		let (_, textView) = makeEditor()
		textView.setPlainText("function a() {\n  if (x) {\n    go();\n  }\n}\n")
		XCTAssertEqual(textView.detectIndentStyle(in: textView.string), .softSpaces(2))

		textView.setSelectedRange(NSRange(location: 0, length: (textView.string as NSString).length))
		textView.deleteBackward(nil)
		XCTAssertEqual(textView.string, "")

		textView.insertTab(nil)
		XCTAssertEqual(
			textView.string, "\t",
			"An emptied document must fall back to the default tab indent"
		)
	}

	func testInsertNewlinePreservesLeadingWhitespace() {
		let (_, textView) = makeEditor()
		textView.setPlainText("\tindented line")
		textView.setSelectedRange(NSRange(location: (textView.string as NSString).length, length: 0))

		textView.insertNewline(nil)

		XCTAssertEqual(textView.string, "\tindented line\n\t")
	}

	func testCommandBracketKeyEquivalentsAdjustIndent() {
		let (_, textView) = makeEditor()
		textView.setPlainText("\tline one\n\tline two\n")
		textView.setSelectedRange(NSRange(location: 0, length: 0))

		guard let indentEvent = commandKeyEvent("]"), let outdentEvent = commandKeyEvent("[") else {
			return XCTFail("Could not synthesize key events")
		}

		XCTAssertTrue(textView.performKeyEquivalent(with: indentEvent))
		XCTAssertTrue(
			textView.string.hasPrefix("\t\tline one"),
			"Cmd-] must indent, got \(textView.string.debugDescription)"
		)

		XCTAssertTrue(textView.performKeyEquivalent(with: outdentEvent))
		XCTAssertTrue(
			textView.string.hasPrefix("\tline one"),
			"Cmd-[ must outdent, got \(textView.string.debugDescription)"
		)
	}

	private func commandKeyEvent(_ character: String) -> NSEvent? {
		NSEvent.keyEvent(
			with: .keyDown, location: .zero, modifierFlags: .command, timestamp: 0,
			windowNumber: 0, context: nil, characters: character,
			charactersIgnoringModifiers: character, isARepeat: false, keyCode: 0
		)
	}

	/// Paste must land as plain text in the editor font even when the pasteboard
	/// carries styled content. (Uses the general pasteboard, as `paste` does.)
	func testPasteArrivesAsPlainTextInEditorFont() {
		let (_, textView) = makeEditor()
		textView.setPlainText("")

		let pasteboard = NSPasteboard.general
		pasteboard.clearContents()
		let styled = NSAttributedString(
			string: "styled", attributes: [.font: NSFont.boldSystemFont(ofSize: 32)]
		)
		pasteboard.writeObjects([styled])

		textView.paste(nil)

		XCTAssertEqual(textView.string, "styled")
		let font = textView.textStorage?.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
		XCTAssertEqual(font, textView.editorFont, "Pasted text must use the editor font, not the source's")
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

	/// The flag the draw path actually reads lives on the layout manager, not on the text
	/// view, so a setter that forgot to push it down would leave the setting inert.
	func testWhitespaceMarkerToggle() throws {
		let (_, textView) = makeEditor()
		let layoutManager = try XCTUnwrap(textView.layoutManager as? WhitespaceLayoutManager)

		XCTAssertFalse(textView.showsWhitespaceMarkers, "whitespace markers are off by default")
		XCTAssertFalse(layoutManager.showsWhitespaceMarkers)

		textView.showsWhitespaceMarkers = true
		XCTAssertTrue(layoutManager.showsWhitespaceMarkers, "the toggle has to reach the layout manager")

		textView.showsWhitespaceMarkers = false
		XCTAssertFalse(layoutManager.showsWhitespaceMarkers)
	}

	/// The gutter splices its offset array from the storage notification rather than
	/// rebuilding it. These go through the real editor so a mistake in the wiring — a
	/// missed notification, a stale array — shows up as a wrong line count.
	func testGutterTracksEditsIncrementally() throws {
		let (scrollView, textView) = makeEditor()
		textView.showsLineNumberGutter = true
		let ruler = try XCTUnwrap(scrollView.verticalRulerView as? LineNumberRulerView)

		// A programmatic replacement invalidates rather than splices; reading the count
		// performs the pending rebuild, as drawing would.
		textView.setPlainText("one\ntwo\nthree")
		XCTAssertEqual(ruler.knownLineCount, 3)

		textView.setSelectedRange(NSRange(location: 13, length: 0))
		textView.insertText("\nfour", replacementRange: NSRange(location: 13, length: 0))
		XCTAssertEqual(ruler.knownLineCount, 4, "typing a newline should splice in a line")

		textView.insertText("\nfive\nsix", replacementRange: NSRange(location: 18, length: 0))
		XCTAssertEqual(ruler.knownLineCount, 6)

		// Delete the two newlines added last, collapsing three lines back into one.
		textView.textStorage?.replaceCharacters(in: NSRange(location: 18, length: 9), with: "")
		XCTAssertEqual(ruler.knownLineCount, 4, "deleting newlines should splice them out")

		XCTAssertEqual(
			ruler.knownLineCount,
			LineIndex.lineStarts(of: textView.string as NSString).count,
			"the spliced count must match a full recompute"
		)
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
