//
//  LineStoreTests.swift
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

/// Covers the line bookkeeping `LineStore` and `LineNumberRulerView` share, and the
/// dirty-line accounting that decides whether another highlight pass is scheduled.
final class LineStoreTests: XCTestCase {
	// MARK: LineIndex

	func testLineStartsAcrossTerminators() {
		XCTAssertEqual(LineIndex.lineStarts(of: "a\nb\nc"), [0, 2, 4])
		XCTAssertEqual(LineIndex.lineStarts(of: "a\r\nb\r\nc"), [0, 3, 6])
		XCTAssertEqual(LineIndex.lineStarts(of: "a\rb\rc"), [0, 2, 4])
	}

	func testLineStartsEdgeCases() {
		XCTAssertEqual(LineIndex.lineStarts(of: ""), [0], "an empty document is still one line")
		XCTAssertEqual(LineIndex.lineStarts(of: "no breaks"), [0])
		XCTAssertEqual(
			LineIndex.lineStarts(of: "a\nb\n"), [0, 2],
			"a trailing terminator must not add a phantom line"
		)
		XCTAssertEqual(LineIndex.lineStarts(of: "\n\n"), [0, 1])
	}

	func testIndexContainingClampsToLastLine() {
		let starts = LineIndex.lineStarts(of: "a\nbb\nccc")
		XCTAssertEqual(starts, [0, 2, 5])
		XCTAssertEqual(LineIndex.index(containing: 0, in: starts), 0)
		XCTAssertEqual(LineIndex.index(containing: 1, in: starts), 0)
		XCTAssertEqual(LineIndex.index(containing: 2, in: starts), 1)
		XCTAssertEqual(LineIndex.index(containing: 4, in: starts), 1)
		XCTAssertEqual(LineIndex.index(containing: 5, in: starts), 2)
		XCTAssertEqual(
			LineIndex.index(containing: 9_999, in: starts), 2,
			"a location past the end clamps to the last line"
		)
	}

	func testIndexContainingMatchesLinearScan() {
		let text = "alpha\nbeta\n\ngamma\r\ndelta" as NSString
		let starts = LineIndex.lineStarts(of: text)
		for location in 0..<text.length {
			let expected = starts.lastIndex(where: { $0 <= location }) ?? 0
			XCTAssertEqual(
				LineIndex.index(containing: location, in: starts), expected,
				"binary search disagreed with a linear scan at \(location)"
			)
		}
	}

	// MARK: Dirty-line accounting

	/// `hasDirtyLines` carries a debug assertion that recounts `carryOuts`, so every
	/// call below also validates the maintained counter against the real state.
	private func makeStore() -> LineStore {
		guard let tokenizer = LanguageRegistry.tokenizer(for: "swift") else {
			preconditionFailure("swift tokenizer is expected to exist")
		}
		return LineStore(tokenizer: tokenizer)
	}

	func testResetMarksEveryLineDirty() {
		var store = makeStore()
		store.reset(text: "let a = 1\nlet b = 2\nlet c = 3")
		XCTAssertTrue(store.hasDirtyLines)
	}

	func testFullPassClearsDirtyLines() {
		var store = makeStore()
		let text = "let a = 1\nlet b = 2\nlet c = 3" as NSString
		store.reset(text: text)
		XCTAssertNotNil(store.highlightPass(text: text))
		XCTAssertFalse(store.hasDirtyLines, "an unlimited pass should settle the document")
		XCTAssertNil(store.highlightPass(text: text), "a settled document has nothing to recolor")
	}

	func testTruncatedPassLeavesLinesDirty() {
		var store = makeStore()
		let text = (0..<50).map { "let value\($0) = \($0)" }.joined(separator: "\n") as NSString
		store.reset(text: text)

		XCTAssertNotNil(store.highlightPass(text: text, limit: 5))
		XCTAssertTrue(store.hasDirtyLines, "a limit-truncated pass must still report dirty lines")

		var guardCount = 0
		while store.hasDirtyLines, guardCount < 100 {
			_ = store.highlightPass(text: text, limit: 5)
			guardCount += 1
		}
		XCTAssertFalse(store.hasDirtyLines, "repeated passes should eventually settle")
	}

	func testDisjointDirtyRegionsAreRecoloredInSeparateRuns() {
		var store = makeStore()
		let text = (0..<50).map { "let value\($0) = \($0)" }.joined(separator: "\n") as NSString
		store.reset(text: text)

		// Settle the first five lines only; lines 5-49 stay dirty.
		XCTAssertNotNil(store.highlightPass(text: text, limit: 5))
		XCTAssertTrue(store.hasDirtyLines)

		// Retype the first character: line 0 is dirty again while lines 1-4 stay
		// clean, so the store now holds two disjoint dirty regions.
		store.noteEdit(in: text, editedRange: NSRange(location: 0, length: 1), changeInLength: 0)

		guard let result = store.highlightPass(text: text) else {
			return XCTFail("a dirty store must produce a pass result")
		}
		let starts = LineIndex.lineStarts(of: text)
		XCTAssertLessThanOrEqual(
			NSMaxRange(result.recolored), starts[5],
			"a pass must not clear colors across clean lines it returns no tokens for"
		)
		XCTAssertTrue(store.hasDirtyLines, "the second dirty region is left for the next pass")

		var guardCount = 0
		while store.hasDirtyLines, guardCount < 100 {
			_ = store.highlightPass(text: text)
			guardCount += 1
		}
		XCTAssertFalse(store.hasDirtyLines, "repeated passes should settle both regions")
	}

	func testEditReintroducesDirtyLines() {
		var store = makeStore()
		let original = "let a = 1\nlet b = 2\nlet c = 3" as NSString
		store.reset(text: original)
		_ = store.highlightPass(text: original)
		XCTAssertFalse(store.hasDirtyLines)

		let edited = "let a = 1\nlet b = 22\nlet c = 3" as NSString
		store.noteEdit(in: edited, editedRange: NSRange(location: 18, length: 1), changeInLength: 1)
		XCTAssertTrue(store.hasDirtyLines, "an edit must mark the touched line dirty again")

		_ = store.highlightPass(text: edited)
		XCTAssertFalse(store.hasDirtyLines)
	}

	func testEditAddingLinesKeepsAccountingConsistent() {
		var store = makeStore()
		let original = "let a = 1\nlet c = 3" as NSString
		store.reset(text: original)
		_ = store.highlightPass(text: original)

		let edited = "let a = 1\nlet b = 2\nlet c = 3" as NSString
		store.noteEdit(in: edited, editedRange: NSRange(location: 10, length: 10), changeInLength: 10)
		XCTAssertTrue(store.hasDirtyLines)

		_ = store.highlightPass(text: edited)
		XCTAssertFalse(store.hasDirtyLines)
	}
}
