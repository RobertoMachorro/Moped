//
//  SwiftTokenizerTests.swift
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

final class SwiftTokenizerTests: XCTestCase {
	let fixture = """
	import AppKit

	/// Doc comment
	struct Point {
		let label: String = "origin \\(x + 1) end"
		var x = 0x1F, y = 2.5e3
		@MainActor func describe() -> Bool {
			// nothing
			return isEmpty(self)
		}
	}
	/* outer /* nested */ still comment */ let after = true
	"""

	func testKeywords() {
		assertKind("import", is: .include, in: fixture, as: "swift")
		assertKind("struct", is: .keyword, in: fixture, as: "swift")
		assertKind("func", is: .keywordFunction, in: fixture, as: "swift")
		assertKind("return", is: .keywordReturn, in: fixture, as: "swift")
		assertKind("true", is: .boolean, in: fixture, as: "swift")
		assertKind("self", is: .variableBuiltin, in: fixture, as: "swift")
	}

	func testTypesAndCalls() {
		assertKind("Point", is: .type, in: fixture, as: "swift")
		assertKind("String", is: .type, in: fixture, as: "swift")
		assertKind("isEmpty", is: .functionCall, in: fixture, as: "swift")
		assertKind("describe", is: .functionCall, in: fixture, as: "swift")
		assertKind("@MainActor", is: .punctuationSpecial, in: fixture, as: "swift")
	}

	func testLiterals() {
		assertKind("0x1F", is: .number, in: fixture, as: "swift")
		assertKind("2.5e3", is: .number, in: fixture, as: "swift")
		assertKind("\"origin ", is: .string, in: fixture, as: "swift")
		assertKind("\\(", is: .punctuationSpecial, in: fixture, as: "swift")
	}

	func testComments() {
		assertKind("// nothing", is: .comment, in: fixture, as: "swift")
		assertKind("/// Doc comment", is: .comment, in: fixture, as: "swift")
		assertKind("/* outer /* nested */ still comment */", is: .comment, in: fixture, as: "swift")
		assertPlain("after", in: fixture, as: "swift")
	}

	func testNestedBlockCommentAcrossLines() {
		let text = "let a = 1\n/* one /* two\nstill */ done */\nlet b = 2"
		let tokens = tokenize(text, as: "swift")
		let nsText = text as NSString
		let bRange = nsText.range(of: "let b")
		XCTAssertTrue(
			tokens.contains { $0.kind == .keyword && NSIntersectionRange($0.range, bRange).length > 0 },
			"Code after a closed nested comment must highlight again"
		)
		let stillRange = nsText.range(of: "still")
		XCTAssertTrue(
			tokens.contains { $0.kind == .comment && NSIntersectionRange($0.range, stillRange).length > 0 },
			"Second line of the block comment must be a comment"
		)
	}

	func testUnterminatedStringDoesNotLeakAcrossLines() {
		let text = "let s = \"oops\nlet t = 1"
		let tokens = tokenize(text, as: "swift")
		let tRange = (text as NSString).range(of: "let t")
		XCTAssertTrue(
			tokens.contains { $0.kind == .keyword && NSIntersectionRange($0.range, tRange).length > 0 },
			"A single-line string must not carry into the next line"
		)
	}

	func testMultilineStringCarries() {
		let text = "let s = \"\"\"\nplain text here\n\"\"\"\nlet t = 2"
		let tokens = tokenize(text, as: "swift")
		let midRange = (text as NSString).range(of: "plain text here")
		XCTAssertTrue(
			tokens.contains { $0.kind == .string && NSIntersectionRange($0.range, midRange).length == midRange.length },
			"Interior of a multiline string must be a string"
		)
	}
}
