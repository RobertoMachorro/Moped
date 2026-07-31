//
//  MarkdownAndHTMLTests.swift
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

final class MarkdownAndHTMLTests: XCTestCase {
	func testMarkdownBlocks() {
		let text = "# Title\n\n> quoted\n\n- item one\n\nSome `code` and **bold** text.\n[link](https://example.com)"
		assertKind("# Title", is: .textTitle, in: text, as: "markdown")
		assertKind("> quoted", is: .comment, in: text, as: "markdown")
		assertKind("`code`", is: .textLiteral, in: text, as: "markdown")
		assertKind("**", is: .punctuationSpecial, in: text, as: "markdown")
		assertKind("https://example.com", is: .string, in: text, as: "markdown")
	}

	func testMarkdownFencedCodeBlock() {
		let text = "before\n```swift\nlet x = 1\n```\nafter"
		let tokens = tokenize(text, as: "markdown")
		let nsText = text as NSString
		let code = nsText.range(of: "let x = 1")
		XCTAssertTrue(
			tokens.contains { $0.kind == .textLiteral && NSIntersectionRange($0.range, code).length == code.length },
			"Fence contents must be text.literal"
		)
		let after = nsText.range(of: "after")
		XCTAssertFalse(
			tokens.contains { $0.kind == .textLiteral && NSIntersectionRange($0.range, after).length > 0 },
			"Fence must close"
		)
	}

	/// Regression shape for the macOS 26 crash: a lone ``` fence being typed —
	/// tokenizing must stay sane while the fence is unclosed.
	func testMarkdownUnclosedFenceWhileTyping() {
		for partial in ["`", "``", "```", "```\n", "```\ncode", "```\ncode\n``"] {
			let tokens = tokenize(partial, as: "markdown")
			for token in tokens {
				XCTAssertGreaterThanOrEqual(token.range.location, 0)
				XCTAssertLessThanOrEqual(
					NSMaxRange(token.range), (partial as NSString).length,
					"Token out of bounds for \(partial.debugDescription)"
				)
			}
		}
	}

	func testHTML() {
		let text = "<!DOCTYPE html>\n<!-- note\nspanning -->\n<div class=\"box\" id='main'>Text &amp; more</div>"
		assertKind("<!DOCTYPE html>", is: .include, in: text, as: "html")
		assertKind("div", is: .keyword, in: text, as: "html")
		assertKind("class", is: .variableBuiltin, in: text, as: "html")
		assertKind("\"box\"", is: .string, in: text, as: "html")
		assertKind("&amp;", is: .punctuationSpecial, in: text, as: "html")
		assertKind("<!-- note", is: .comment, in: text, as: "html")
		assertKind("spanning -->", is: .comment, in: text, as: "html")
	}

	func testHTMLMultilineTag() {
		let text = "<div\n\tclass=\"wide\"\n>content</div>"
		assertKind("class", is: .variableBuiltin, in: text, as: "html")
		assertKind("\"wide\"", is: .string, in: text, as: "html")
		assertPlain("content", in: text, as: "html")
	}
}
