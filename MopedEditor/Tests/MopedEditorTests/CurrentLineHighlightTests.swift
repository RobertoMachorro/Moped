//
//  CurrentLineHighlightTests.swift
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

import XCTest
@testable import MopedEditor

/// The caret-line band used to be measured over the caret's whole line, which in a file
/// that is one long line meant typesetting the whole file on every caret move (#106). It
/// is now measured from layout the draw has already done; these pin that it still looks
/// the same, and that moving the caret lays nothing out.
final class CurrentLineHighlightTests: EditorTestCase {
	/// The band as it was measured before: over the caret's whole line.
	private func wholeLineBand(in textView: MopedTextView) throws -> NSRect {
		let layoutManager = try XCTUnwrap(textView.layoutManager)
		let textContainer = try XCTUnwrap(textView.textContainer)
		let content = textView.string as NSString
		let lineRange = content.lineRange(for: NSRange(location: textView.selectedRange().location, length: 0))
		let glyphs = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
		var band = layoutManager.boundingRect(forGlyphRange: glyphs, in: textContainer)
		band.origin.x = 0
		band.size.width = textView.bounds.width
		band.origin.y += textView.textContainerInset.height
		return band
	}

	/// Draws the visible rect the way a window would, which is what lays text out.
	private func draw(_ textView: MopedTextView) throws {
		let rep = try XCTUnwrap(textView.bitmapImageRepForCachingDisplay(in: textView.visibleRect))
		textView.cacheDisplay(in: textView.visibleRect, to: rep)
	}

	/// A line wholly on screen, wrapped or not, and the empty line after a trailing
	/// newline, get the band they had before. The one difference is the last line of a
	/// file that ends in a newline: the old band also took in the empty line below it.
	func testDrawnBandMatchesTheWholeLine() throws {
		let (_, textView) = makeEditor()
		let wrapped = String(repeating: "wrap me ", count: 60)
		let text = "first\n\(wrapped)\nlast\n"
		textView.setPlainText(text)
		let length = (text as NSString).length
		let lineHeight = try XCTUnwrap(textView.layoutManager?.defaultLineHeight(for: textView.editorFont))

		for caret in [0, 10, length] {
			textView.setSelectedRange(NSRange(location: caret, length: 0))
			try draw(textView)
			let band = try XCTUnwrap(textView.highlightedCaretLineRect, "caret at \(caret)")
			XCTAssertEqual(band, try wholeLineBand(in: textView), "caret at \(caret)")
			if caret == 10 {
				XCTAssertGreaterThan(band.height, lineHeight * 2, "the long line should wrap onto several rows")
			}
		}

		textView.setSelectedRange(NSRange(location: length - 2, length: 0))
		try draw(textView)
		let band = try XCTUnwrap(textView.highlightedCaretLineRect)
		let wholeLine = try wholeLineBand(in: textView)
		XCTAssertEqual(band.minY, wholeLine.minY)
		XCTAssertEqual(band.height, lineHeight, "the last line's band should cover that line only")
	}

	/// The #106 case: a file that is one long line, with the caret at its end, which is
	/// where inserting the text leaves it. Neither loading it nor moving the caret may
	/// lay it out; drawing does, and the band then runs on to the bottom of the view,
	/// where the line does.
	func testMovingTheCaretLaysNothingOut() throws {
		let (_, textView) = makeEditor()
		let layoutManager = try XCTUnwrap(textView.layoutManager)
		let text = String(repeating: "abc,def:ghi ", count: 50_000)
		let length = (text as NSString).length

		textView.setPlainText(text)
		textView.setSelectedRange(NSRange(location: length, length: 0))
		XCTAssertEqual(
			layoutManager.firstUnlaidCharacterIndex(), 0,
			"loading the text or moving the caret laid the line out"
		)

		try draw(textView)
		let band = try XCTUnwrap(textView.highlightedCaretLineRect)
		XCTAssertEqual(band.minY, textView.textContainerInset.height)
		XCTAssertEqual(band.maxY, textView.bounds.maxY)
	}

	/// A caret whose line is nowhere on screen gets no band, rather than one that would
	/// need the document laid out down to it.
	func testALineOffScreenHasNoBand() throws {
		let (_, textView) = makeEditor()
		let text = (1...500).map { "line \($0)" }.joined(separator: "\n")
		textView.setPlainText(text)
		textView.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))

		XCTAssertNil(textView.caretLineRect(within: textView.visibleRect, layOut: true))
	}
}
