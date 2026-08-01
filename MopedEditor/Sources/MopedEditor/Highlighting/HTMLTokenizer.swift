//
//  HTMLTokenizer.swift
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

/// Markup highlighter, used for both HTML and XML: tag names → `keyword`,
/// attribute names → `variable.builtin`, attribute values → `string`, comments,
/// doctype → `include`, processing instructions → `keyword`, CDATA payloads →
/// `text.literal`, entities → `punctuation.special`. `<script>`/`<style>` bodies
/// render as plain text (no embedded-language highlighting).
struct HTMLTokenizer: LineTokenizer {
	private static let commentOpen: [UInt16] = Array("<!--".utf16)
	private static let commentClose: [UInt16] = Array("-->".utf16)
	private static let cdataOpen: [UInt16] = Array("<![CDATA[".utf16)
	private static let cdataClose: [UInt16] = Array("]]>".utf16)
	// swiftlint:disable:next force_try
	private static let entityRegex = try! NSRegularExpression(pattern: "&#?[a-zA-Z0-9]{1,32};")

	private static let slash: UInt16 = 0x2F
	private static let bang: UInt16 = 0x21
	private static let equals: UInt16 = 0x3D
	private static let doubleQuote: UInt16 = 0x22
	private static let singleQuote: UInt16 = 0x27
	private static let ampersand: UInt16 = 0x26

	func tokenize(line: String, carryIn: LineState) -> (tokens: [Token], carryOut: LineState) {
		var scanner = LineScanner(line: line)
		var tokens: [Token] = []

		if case .htmlComment = carryIn {
			if let carry = continueComment(scanner: &scanner, tokens: &tokens, tokenStart: 0) {
				return (tokens, carry)
			}
		}
		if case .cdata = carryIn {
			if let carry = continueCDATA(scanner: &scanner, tokens: &tokens, tokenStart: 0) {
				return (tokens, carry)
			}
		}
		if case .htmlTag = carryIn {
			if let carry = scanTagAttributes(scanner: &scanner, tokens: &tokens) {
				return (tokens, carry)
			}
		}
		return scanText(scanner: &scanner, tokens: &tokens)
	}
}

private extension HTMLTokenizer {
	func scanText(scanner: inout LineScanner, tokens: inout [Token]) -> ([Token], LineState) {
		while !scanner.isAtEnd {
			let unit = scanner.current
			if unit == UnicodeScalars.lessThan {
				if let carry = scanMarkupOpen(scanner: &scanner, tokens: &tokens) {
					return (tokens, carry)
				}
				continue
			}
			if unit == Self.ampersand,
			   let match = scanner.matchRegex(Self.entityRegex, at: scanner.pos) {
				tokens.append(Token(kind: .punctuationSpecial, range: match.range))
				scanner.pos = NSMaxRange(match.range)
				continue
			}
			scanner.pos += 1
		}
		return (tokens, .none)
	}

	/// Dispatches everything that can follow a `<`. Returns a carry state when the
	/// construct runs past the end of the line, nil when scanning should continue.
	func scanMarkupOpen(scanner: inout LineScanner, tokens: inout [Token]) -> LineState? {
		if scanner.matches(Self.commentOpen) {
			let start = scanner.pos
			scanner.pos += Self.commentOpen.count
			return continueComment(scanner: &scanner, tokens: &tokens, tokenStart: start)
		}
		if scanner.matches(Self.cdataOpen) {
			let start = scanner.pos
			scanner.pos += Self.cdataOpen.count
			return continueCDATA(scanner: &scanner, tokens: &tokens, tokenStart: start)
		}
		if scanner.unit(at: scanner.pos + 1) == UnicodeScalars.questionMark {
			return scanProcessingInstruction(scanner: &scanner, tokens: &tokens)
		}
		if scanner.unit(at: scanner.pos + 1) == Self.bang {
			scanDoctype(scanner: &scanner, tokens: &tokens)
			return nil
		}
		return scanTagOpen(scanner: &scanner, tokens: &tokens)
	}

	/// Returns the carry state when the comment is still open at EOL, nil when closed.
	func continueComment(scanner: inout LineScanner, tokens: inout [Token], tokenStart: Int) -> LineState? {
		while !scanner.isAtEnd {
			if scanner.matches(Self.commentClose) {
				scanner.pos += Self.commentClose.count
				appendToken(.comment, from: tokenStart, to: scanner.pos, into: &tokens)
				return nil
			}
			scanner.pos += 1
		}
		appendToken(.comment, from: tokenStart, to: scanner.count, into: &tokens)
		return .htmlComment
	}

	/// Returns the carry state when the section is still open at EOL, nil when closed.
	func continueCDATA(scanner: inout LineScanner, tokens: inout [Token], tokenStart: Int) -> LineState? {
		while !scanner.isAtEnd {
			if scanner.matches(Self.cdataClose) {
				scanner.pos += Self.cdataClose.count
				appendToken(.textLiteral, from: tokenStart, to: scanner.pos, into: &tokens)
				return nil
			}
			scanner.pos += 1
		}
		appendToken(.textLiteral, from: tokenStart, to: scanner.count, into: &tokens)
		return .cdata
	}

	/// `<?xml … ?>` and friends. The target name is a keyword and the rest is scanned
	/// as tag attributes, so quoted values light up; the closing `?` is skipped by
	/// the attribute scanner, which stops on `>`.
	func scanProcessingInstruction(scanner: inout LineScanner, tokens: inout [Token]) -> LineState? {
		let start = scanner.pos
		var nameEnd = start + 2
		while nameEnd < scanner.count, UnicodeScalars.isIdentifierContinue(scanner.units[nameEnd]) || scanner.units[nameEnd] == 0x2D {
			nameEnd += 1
		}
		appendToken(.keyword, from: start, to: nameEnd, into: &tokens)
		scanner.pos = nameEnd
		return scanTagAttributes(scanner: &scanner, tokens: &tokens)
	}

	func scanDoctype(scanner: inout LineScanner, tokens: inout [Token]) {
		let start = scanner.pos
		while !scanner.isAtEnd && scanner.current != UnicodeScalars.greaterThan {
			scanner.pos += 1
		}
		if !scanner.isAtEnd {
			scanner.pos += 1
		}
		appendToken(.include, from: start, to: scanner.pos, into: &tokens)
	}

	/// `<tag` or `</tag`: the name is a keyword, then attributes follow. Returns the
	/// carry state when the tag's `>` is beyond this line.
	func scanTagOpen(scanner: inout LineScanner, tokens: inout [Token]) -> LineState? {
		var nameStart = scanner.pos + 1
		if scanner.unit(at: nameStart) == Self.slash {
			nameStart += 1
		}
		guard let first = scanner.unit(at: nameStart), UnicodeScalars.isLetter(first) else {
			scanner.pos += 1
			return nil
		}
		var nameEnd = nameStart
		while nameEnd < scanner.count,
			  UnicodeScalars.isIdentifierContinue(scanner.units[nameEnd]) || scanner.units[nameEnd] == 0x2D {
			nameEnd += 1
		}
		appendToken(.keyword, from: nameStart, to: nameEnd, into: &tokens)
		scanner.pos = nameEnd
		return scanTagAttributes(scanner: &scanner, tokens: &tokens)
	}

	/// Scans attributes until `>`. Returns the carry state at EOL, nil once closed.
	func scanTagAttributes(scanner: inout LineScanner, tokens: inout [Token]) -> LineState? {
		while !scanner.isAtEnd {
			let unit = scanner.current
			if unit == UnicodeScalars.greaterThan {
				scanner.pos += 1
				return nil
			}
			if unit == Self.doubleQuote || unit == Self.singleQuote {
				scanQuotedValue(quote: unit, scanner: &scanner, tokens: &tokens)
				continue
			}
			if UnicodeScalars.isIdentifierStart(unit) {
				let start = scanner.pos
				while !scanner.isAtEnd,
					  UnicodeScalars.isIdentifierContinue(scanner.current) || scanner.current == 0x2D || scanner.current == 0x3A {
					scanner.pos += 1
				}
				appendToken(.variableBuiltin, from: start, to: scanner.pos, into: &tokens)
				continue
			}
			scanner.pos += 1
		}
		return .htmlTag
	}

	func scanQuotedValue(quote: UInt16, scanner: inout LineScanner, tokens: inout [Token]) {
		let start = scanner.pos
		scanner.pos += 1
		while !scanner.isAtEnd && scanner.current != quote {
			scanner.pos += 1
		}
		if !scanner.isAtEnd {
			scanner.pos += 1
		}
		appendToken(.string, from: start, to: scanner.pos, into: &tokens)
	}
}

private func appendToken(_ kind: TokenKind, from start: Int, to end: Int, into tokens: inout [Token]) {
	guard end > start else {
		return
	}
	tokens.append(Token(kind: kind, range: NSRange(location: start, length: end - start)))
}
