//
//  LineIndexSpliceTests.swift
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

/// `LineIndex.splice` must always agree with `LineIndex.lineStarts` — it is only an
/// optimization of it. These tests compare the two directly.
final class LineIndexSpliceTests: XCTestCase {
	/// Applies one edit and checks the spliced result against a full recompute.
	private func check(
		_ original: String,
		replacing range: NSRange,
		with replacement: String,
		file: StaticString = #filePath,
		line: UInt = #line
	) {
		let oldText = original as NSString
		let starts = LineIndex.lineStarts(of: oldText)
		let mutable = NSMutableString(string: original)
		mutable.replaceCharacters(in: range, with: replacement)
		let newText = NSString(string: mutable as String)

		let replacementLength = (replacement as NSString).length
		let delta = replacementLength - range.length
		let edited = NSRange(location: range.location, length: replacementLength)

		let spliced = LineIndex.spliced(
			starts, in: newText, editedRange: edited, changeInLength: delta
		)
		XCTAssertEqual(
			spliced, LineIndex.lineStarts(of: newText),
			"""
			splice diverged
			  original:    \(original.debugDescription)
			  replace:     \(NSStringFromRange(range)) with \(replacement.debugDescription)
			  result:      \((newText as String).debugDescription)
			""",
			file: file, line: line
		)
	}

	// MARK: Targeted cases

	func testInsertWithinALine() {
		check("let a = 1\nlet b = 2\nlet c = 3", replacing: NSRange(location: 14, length: 0), with: "X")
	}

	func testInsertNewline() {
		check("alpha\nbeta\ngamma", replacing: NSRange(location: 8, length: 0), with: "\n")
	}

	func testDeleteNewline() {
		check("alpha\nbeta\ngamma", replacing: NSRange(location: 5, length: 1), with: "")
	}

	func testEditAtVeryStart() {
		check("alpha\nbeta", replacing: NSRange(location: 0, length: 0), with: "zzz\n")
		check("alpha\nbeta", replacing: NSRange(location: 0, length: 6), with: "")
	}

	func testEditAtEndOfDocument() {
		check("alpha\nbeta", replacing: NSRange(location: 10, length: 0), with: "\ngamma")
		check("alpha\nbeta", replacing: NSRange(location: 10, length: 0), with: "!")
	}

	func testDeleteSpanningSeveralLines() {
		check("a\nb\nc\nd\ne\nf", replacing: NSRange(location: 2, length: 6), with: "")
	}

	func testReplaceSpanningSeveralLines() {
		check("a\nb\nc\nd\ne\nf", replacing: NSRange(location: 2, length: 6), with: "X\nY\nZ")
	}

	func testTrailingNewlineHandling() {
		check("a\nb\n", replacing: NSRange(location: 4, length: 0), with: "c")
		check("a\nb\n", replacing: NSRange(location: 3, length: 1), with: "")
		check("a\nb", replacing: NSRange(location: 3, length: 0), with: "\n")
	}

	func testEmptyDocumentEdits() {
		check("", replacing: NSRange(location: 0, length: 0), with: "hello")
		check("", replacing: NSRange(location: 0, length: 0), with: "\n")
		check("abc", replacing: NSRange(location: 0, length: 3), with: "")
	}

	// MARK: CRLF — one terminator made of two units, the easiest thing to get wrong

	func testCRLFInsertions() {
		check("a\r\nb\r\nc", replacing: NSRange(location: 3, length: 0), with: "X")
		check("a\r\nb", replacing: NSRange(location: 1, length: 0), with: "\r\n")
	}

	/// Inserting a lone CR directly before an existing LF merges two terminators into
	/// one CRLF, moving a line start that the naive tail shift would keep.
	func testInsertCarriageReturnBeforeExistingNewline() {
		check("a\nb", replacing: NSRange(location: 1, length: 0), with: "\r")
	}

	/// The mirror case: deleting the CR of a CRLF leaves a bare LF.
	func testDeleteCarriageReturnOfCRLF() {
		check("a\r\nb", replacing: NSRange(location: 1, length: 1), with: "")
	}

	func testSplitCRLFByInsertingBetween() {
		check("a\r\nb", replacing: NSRange(location: 2, length: 0), with: "X")
	}

	/// Found by the property test below. Deleting between a lone CR and a following LF
	/// fuses them into one CRLF, so a line start *below* the edit disappears — the case
	/// that broke the first version of the splice, which trusted every start before the
	/// edit and so kept a stale one.
	func testDeletionFusesCarriageReturnWithFollowingNewline() {
		check("\rx\t\n\n\nbe\nx\na\nb", replacing: NSRange(location: 1, length: 2), with: "")
		check("\rx\n", replacing: NSRange(location: 1, length: 1), with: "")
		check("a\rx\nb", replacing: NSRange(location: 2, length: 1), with: "")
	}

	// MARK: Property test

	func testRandomEditsAlwaysMatchFullRecompute() {
		let fragments = ["\n", "\r\n", "\r", "x", "hello", "\n\n", "a\nb", "", "\u{2028}", "\t"]
		for seed in UInt64(1)...20 {
			var rng = SeededGenerator(seed: seed)
			let mutable = NSMutableString(string: "alpha\nbeta\r\ngamma\ndelta")

			for iteration in 0..<60 {
				let text = NSString(string: mutable as String)
				let starts = LineIndex.lineStarts(of: text)

				let location = Int.random(in: 0...text.length, using: &rng)
				let maxDelete = min(4, text.length - location)
				let deleteLength = maxDelete > 0 ? Int.random(in: 0...maxDelete, using: &rng) : 0
				var range = NSRange(location: location, length: deleteLength)
				// Never split a composed sequence or a surrogate pair.
				range = text.rangeOfComposedCharacterSequences(for: range)
				let replacement = fragments[Int.random(in: 0..<fragments.count, using: &rng)]

				mutable.replaceCharacters(in: range, with: replacement)
				let newText = NSString(string: mutable as String)
				let replacementLength = (replacement as NSString).length

				let spliced = LineIndex.spliced(
					starts,
					in: newText,
					editedRange: NSRange(location: range.location, length: replacementLength),
					changeInLength: replacementLength - range.length
				)
				XCTAssertEqual(
					spliced, LineIndex.lineStarts(of: newText),
					"seed \(seed), iteration \(iteration): replacing \(NSStringFromRange(range)) "
						+ "with \(replacement.debugDescription) in \((text as String).debugDescription)"
				)
				if spliced != LineIndex.lineStarts(of: newText) {
					return
				}
			}
		}
	}
}
