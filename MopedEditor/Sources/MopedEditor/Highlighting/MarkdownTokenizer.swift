//
//  MarkdownTokenizer.swift
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

import Foundation

/// Line-level Markdown highlighter: headings, fenced code blocks, blockquotes,
/// list markers, inline code, emphasis delimiters, and links. Fence contents are
/// rendered as `text.literal` with no nested language highlighting.
struct MarkdownTokenizer: LineTokenizer {
	// swiftlint:disable force_try
	private static let headingRegex = try! NSRegularExpression(pattern: "^[\t ]{0,3}#{1,6}(?:[\t ]|$)")
	private static let fenceRegex = try! NSRegularExpression(pattern: "^[\t ]{0,3}(`{3,}|~{3,})")
	private static let blockquoteRegex = try! NSRegularExpression(pattern: "^[\t ]{0,3}>")
	private static let ruleRegex = try! NSRegularExpression(pattern: "^[\t ]{0,3}(-{3,}|\\*{3,}|_{3,})[\t ]*$")
	private static let listMarkerRegex = try! NSRegularExpression(pattern: "^[\t ]*([-*+]|\\d{1,9}[.)])[\t ]+")
	private static let autolinkRegex = try! NSRegularExpression(pattern: "<[a-zA-Z][a-zA-Z0-9+.-]*:[^ >]*>")
	// swiftlint:enable force_try

	private static let backtick: UInt16 = 0x60
	private static let star: UInt16 = 0x2A
	private static let underscore: UInt16 = 0x5F
	private static let openBracket: UInt16 = 0x5B
	private static let closeBracket: UInt16 = 0x5D
	private static let bang: UInt16 = 0x21

	func tokenize(line: String, carryIn: LineState) -> (tokens: [Token], carryOut: LineState) {
		var tokens: [Token] = []
		let scanner = LineScanner(line: line)
		let fullRange = NSRange(location: 0, length: scanner.count)

		if case .fencedCode(let fence) = carryIn {
			if let match = scanner.matchLineRegex(Self.fenceRegex),
			   scanner.substring(in: match.range(at: 1)).hasPrefix(fence) {
				tokens.append(Token(kind: .punctuationSpecial, range: match.range))
				return (tokens, .none)
			}
			if fullRange.length > 0 {
				tokens.append(Token(kind: .textLiteral, range: fullRange))
			}
			return (tokens, .fencedCode(fence: fence))
		}

		if let match = scanner.matchLineRegex(Self.fenceRegex) {
			tokens.append(Token(kind: .punctuationSpecial, range: fullRange))
			// The full run is kept so the `hasPrefix` close test above enforces
			// CommonMark's rule that a closer is at least as long as its opener —
			// three backticks must not close a five-backtick block.
			let fence = String(scanner.substring(in: match.range(at: 1)))
			return (tokens, .fencedCode(fence: fence))
		}

		if scanner.matchLineRegex(Self.headingRegex) != nil {
			tokens.append(Token(kind: .textTitle, range: fullRange))
			return (tokens, .none)
		}

		if scanner.matchLineRegex(Self.blockquoteRegex) != nil {
			tokens.append(Token(kind: .comment, range: fullRange))
			return (tokens, .none)
		}

		if scanner.matchLineRegex(Self.ruleRegex) != nil {
			tokens.append(Token(kind: .punctuationSpecial, range: fullRange))
			return (tokens, .none)
		}

		var start = 0
		if let match = scanner.matchLineRegex(Self.listMarkerRegex) {
			tokens.append(Token(kind: .punctuationSpecial, range: match.range(at: 1)))
			start = NSMaxRange(match.range)
		}

		tokenizeInline(scanner: scanner, from: start, tokens: &tokens)
		return (tokens, .none)
	}
}

// MARK: - Inline scanning

private extension MarkdownTokenizer {
	func tokenizeInline(scanner: LineScanner, from start: Int, tokens: inout [Token]) {
		var pos = start
		while pos < scanner.count {
			let unit = scanner.units[pos]
			if unit == Self.backtick {
				pos = scanInlineCode(scanner: scanner, at: pos, tokens: &tokens)
			} else if unit == Self.star || unit == Self.underscore {
				pos = scanEmphasisRun(scanner: scanner, at: pos, unit: unit, tokens: &tokens)
			} else if unit == Self.openBracket
				|| (unit == Self.bang && scanner.unit(at: pos + 1) == Self.openBracket) {
				pos = scanLink(scanner: scanner, at: pos, tokens: &tokens)
			} else if unit == UnicodeScalars.lessThan {
				pos = scanAutolink(scanner: scanner, at: pos, tokens: &tokens)
			} else {
				pos += 1
			}
		}
	}

	/// A backtick run opens inline code closed by a matching-length run.
	func scanInlineCode(scanner: LineScanner, at start: Int, tokens: inout [Token]) -> Int {
		var openEnd = start
		while openEnd < scanner.count && scanner.units[openEnd] == Self.backtick {
			openEnd += 1
		}
		let runLength = openEnd - start
		var pos = openEnd
		while pos < scanner.count {
			if scanner.units[pos] == Self.backtick {
				var closeEnd = pos
				while closeEnd < scanner.count && scanner.units[closeEnd] == Self.backtick {
					closeEnd += 1
				}
				if closeEnd - pos == runLength {
					tokens.append(Token(kind: .textLiteral, range: NSRange(location: start, length: closeEnd - start)))
					return closeEnd
				}
				pos = closeEnd
			} else {
				pos += 1
			}
		}
		return openEnd
	}

	/// Emphasis delimiters (`*`, `**`, `_`, `__`) are marked; the emphasized text keeps
	/// its own styling.
	func scanEmphasisRun(scanner: LineScanner, at start: Int, unit: UInt16, tokens: inout [Token]) -> Int {
		var end = start
		while end < scanner.count && scanner.units[end] == unit && end - start < 3 {
			end += 1
		}
		let adjacent = scanner.unit(at: end)
		let isDelimiter = adjacent != nil
			&& adjacent != UnicodeScalars.space && adjacent != UnicodeScalars.tab
		let precededByText = start > 0
			&& scanner.units[start - 1] != UnicodeScalars.space && scanner.units[start - 1] != UnicodeScalars.tab
		if isDelimiter || precededByText {
			tokens.append(Token(kind: .punctuationSpecial, range: NSRange(location: start, length: end - start)))
		}
		return end
	}

	/// `[text](url)` and `![alt](url)`: brackets and parens are marked, the URL is a string.
	func scanLink(scanner: LineScanner, at start: Int, tokens: inout [Token]) -> Int {
		let bracketStart = scanner.units[start] == Self.bang ? start + 1 : start
		var pos = bracketStart + 1
		var depth = 1
		while pos < scanner.count && depth > 0 {
			if scanner.units[pos] == Self.openBracket {
				depth += 1
			} else if scanner.units[pos] == Self.closeBracket {
				depth -= 1
			}
			pos += 1
		}
		guard depth == 0, scanner.unit(at: pos) == UnicodeScalars.openParen else {
			return start + 1
		}
		let closeBracketAt = pos - 1
		var urlEnd = pos + 1
		while urlEnd < scanner.count && scanner.units[urlEnd] != 0x29 {
			urlEnd += 1
		}
		guard urlEnd < scanner.count else {
			return start + 1
		}
		tokens.append(Token(kind: .punctuationSpecial, range: NSRange(location: start, length: bracketStart + 1 - start)))
		tokens.append(Token(kind: .punctuationSpecial, range: NSRange(location: closeBracketAt, length: 2)))
		if urlEnd > pos + 1 {
			tokens.append(Token(kind: .string, range: NSRange(location: pos + 1, length: urlEnd - pos - 1)))
		}
		tokens.append(Token(kind: .punctuationSpecial, range: NSRange(location: urlEnd, length: 1)))
		return urlEnd + 1
	}

	func scanAutolink(scanner: LineScanner, at start: Int, tokens: inout [Token]) -> Int {
		guard let match = scanner.matchRegex(Self.autolinkRegex, at: start) else {
			return start + 1
		}
		tokens.append(Token(kind: .string, range: match.range))
		return NSMaxRange(match.range)
	}
}
