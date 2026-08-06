//
//  LineEndingTests.swift
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

final class LineEndingTests: XCTestCase {
	// MARK: Detection

	func testDetectsEachConvention() {
		XCTAssertEqual(LineEnding.detected(in: "one\ntwo\nthree\n"), .unix)
		XCTAssertEqual(LineEnding.detected(in: "one\r\ntwo\r\nthree\r\n"), .windows)
		XCTAssertEqual(LineEnding.detected(in: "one\rtwo\rthree\r"), .classicMac)
	}

	func testDocumentWithNoBreaksIsLF() {
		XCTAssertEqual(LineEnding.detected(in: ""), .unix, "a new document has to start somewhere")
		XCTAssertEqual(LineEnding.detected(in: "single line, no terminator"), .unix)
	}

	func testMixedEndingsTakeTheMajority() {
		XCTAssertEqual(LineEnding.detected(in: "a\r\nb\r\nc\n"), .windows)
		XCTAssertEqual(LineEnding.detected(in: "a\nb\nc\r\n"), .unix)
		XCTAssertEqual(LineEnding.detected(in: "a\rb\rc\n"), .classicMac)
	}

	/// A `\r\n` must count once, as CRLF — not as a CR *and* an LF, which would let a pure
	/// Windows file look like a tie and fall through to something else.
	func testCRLFIsNotCountedTwice() {
		XCTAssertEqual(LineEnding.detected(in: "a\r\nb"), .windows)
		XCTAssertEqual(LineEnding.detected(in: "a\r\nb\rc"), .windows, "one CRLF, one lone CR")
	}

	func testTrailingLoneCarriageReturn() {
		XCTAssertEqual(LineEnding.detected(in: "a\r"), .classicMac, "a CR at the very end")
	}

	// MARK: Normalizing to LF

	/// The regression that shipped: `"a\r\nb".contains("\r")` is false, because `\r\n` is a
	/// single grapheme cluster, so a `contains`-guarded normalizer returned CRLF text
	/// untouched — and the write path then turned every `\r\n` into `\r\r\n`.
	func testNormalizesCRLF() {
		XCTAssertEqual(LineEnding.normalizedToLF("one\r\ntwo\r\n"), "one\ntwo\n")
		XCTAssertFalse(
			LineEnding.normalizedToLF("one\r\ntwo\r\n").utf16.contains(0x0D),
			"no carriage return may survive normalization"
		)
	}

	func testNormalizesLoneCR() {
		XCTAssertEqual(LineEnding.normalizedToLF("one\rtwo\r"), "one\ntwo\n")
	}

	func testNormalizesMixedEndings() {
		XCTAssertEqual(LineEnding.normalizedToLF("a\r\nb\rc\nd"), "a\nb\nc\nd")
	}

	func testLFTextIsReturnedUnchanged() {
		let text = "already\nnormalized\n"
		XCTAssertEqual(LineEnding.normalizedToLF(text), text)
	}

	// MARK: Applying on write

	func testAppliesEachConvention() {
		XCTAssertEqual(LineEnding.unix.applied(to: "a\nb\n"), "a\nb\n")
		XCTAssertEqual(LineEnding.windows.applied(to: "a\nb\n"), "a\r\nb\r\n")
		XCTAssertEqual(LineEnding.classicMac.applied(to: "a\nb\n"), "a\rb\r")
	}

	/// The end-to-end promise: a file read and written back is byte-identical, and no
	/// convention ever doubles up a carriage return.
	func testRoundTripIsLossless() {
		for ending in LineEnding.allCases {
			let onDisk = ending.applied(to: "one\ntwo\nthree\n")
			XCTAssertEqual(LineEnding.detected(in: onDisk), ending)
			let normalized = LineEnding.normalizedToLF(onDisk)
			XCTAssertEqual(normalized, "one\ntwo\nthree\n")
			XCTAssertEqual(
				ending.applied(to: normalized), onDisk,
				"\(ending.displayName) did not survive a read/write round trip"
			)
			XCTAssertFalse(
				ending.applied(to: normalized).contains("\r\r"),
				"\(ending.displayName) doubled a carriage return"
			)
		}
	}

	/// Editing is what actually produced the broken file: the buffer gains LF-terminated
	/// lines from the text view, and those have to come out as the document's convention
	/// alongside the ones that were already there.
	func testAppendingALineKeepsOneConvention() {
		let opened = LineEnding.normalizedToLF("existing\r\nlines\r\n")
		let edited = opened + "appended by the user\n"
		let written = LineEnding.windows.applied(to: edited)
		XCTAssertEqual(written, "existing\r\nlines\r\nappended by the user\r\n")
		XCTAssertFalse(written.contains("\r\r"))
	}

	func testConvertingConventionRewritesEveryLine() {
		let opened = LineEnding.normalizedToLF("one\r\ntwo\r\n")
		XCTAssertEqual(LineEnding.unix.applied(to: opened), "one\ntwo\n")
		XCTAssertEqual(LineEnding.classicMac.applied(to: opened), "one\rtwo\r")
	}

	func testDisplayNamesAreStable() {
		XCTAssertEqual(LineEnding.unix.displayName, "LF")
		XCTAssertEqual(LineEnding.windows.displayName, "CRLF")
		XCTAssertEqual(LineEnding.classicMac.displayName, "CR")
		XCTAssertEqual(LineEnding.allCases.count, 3)
	}
}
