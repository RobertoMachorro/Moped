//
//  GenericTokenizer.swift
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

/// The data-driven scanner shared by every language except Markdown and HTML.
/// Scans one line left to right, dispatching on the current character:
/// comments → pre-pass regex rules → strings/heredocs → numbers → identifiers →
/// operators. Multiline constructs thread through `LineState`.
struct GenericTokenizer: LineTokenizer {
	let language: LanguageDefinition

	var initialState: LineState { language.initialState }

	private static let phpOpenLong: [UInt16] = Array("<?php".utf16)
	private static let phpOpenEcho: [UInt16] = Array("<?=".utf16)
	private static let phpOpenShort: [UInt16] = Array("<?".utf16)
	private static let phpClose: [UInt16] = Array("?>".utf16)

	static let operatorUnits: Set<UInt16> = Set("+-*/%=<>!&|^~".utf16)

	// swiftlint:disable:next force_try
	static let numberRegex = try! NSRegularExpression(pattern:
		"(?:0[xX][0-9a-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+"
		+ "|\\d[\\d_]*(?:\\.\\d[\\d_]*)?(?:[eE][+-]?\\d+)?"
		+ "|\\.\\d[\\d_]*(?:[eE][+-]?\\d+)?)[a-zA-Z]*"
	)

	func tokenize(line: String, carryIn: LineState) -> (tokens: [Token], carryOut: LineState) {
		var scanner = LineScanner(line: line)
		var tokens: [Token] = []

		if case .heredoc(let terminator) = carryIn {
			return tokenizeHeredocBody(line: line, scanner: scanner, terminator: terminator, tokens: &tokens)
		}

		if case .blockComment(let ruleIndex, let depth) = carryIn {
			guard ruleIndex < language.blockComments.count else {
				return (tokens, .none)
			}
			if let carry = continueBlockComment(
				ruleIndex: ruleIndex, depth: depth, tokenStart: 0, scanner: &scanner, tokens: &tokens
			) {
				return (tokens, carry)
			}
		}

		if case .string(let ruleIndex) = carryIn {
			guard ruleIndex < language.strings.count else {
				return (tokens, .none)
			}
			if let carry = scanStringBody(ruleIndex: ruleIndex, tokenStart: 0, scanner: &scanner, tokens: &tokens) {
				return (tokens, carry)
			}
		}

		if case .rawOutside = carryIn {
			guard enterCodeRegion(scanner: &scanner, tokens: &tokens) else {
				return (tokens, .rawOutside)
			}
		}

		return scanCode(scanner: &scanner, tokens: &tokens)
	}
}

// MARK: - Main scan loop

private extension GenericTokenizer {
	func scanCode(scanner: inout LineScanner, tokens: inout [Token]) -> ([Token], LineState) {
		var carry = LineState.none
		var pendingHeredoc: String?

		applyLineStartRules(scanner: &scanner, tokens: &tokens)

		while !scanner.isAtEnd {
			if language.rawBoundaries && scanner.matches(Self.phpClose) {
				appendToken(.punctuationSpecial, from: scanner.pos, length: 2, into: &tokens)
				scanner.pos += 2
				guard enterCodeRegion(scanner: &scanner, tokens: &tokens) else {
					return (tokens, .rawOutside)
				}
				continue
			}
			if scanLineComment(scanner: &scanner, tokens: &tokens) {
				continue
			}
			if scanBlockCommentOpen(scanner: &scanner, tokens: &tokens, carry: &carry) {
				continue
			}
			if scanPrePassRules(scanner: &scanner, tokens: &tokens) {
				continue
			}
			if scanHeredocOpen(scanner: &scanner, tokens: &tokens, pendingHeredoc: &pendingHeredoc) {
				continue
			}
			if scanStringOpen(scanner: &scanner, tokens: &tokens, carry: &carry) {
				continue
			}
			if scanValueToken(scanner: &scanner, tokens: &tokens) {
				continue
			}
			scanner.pos += 1
		}

		if case .none = carry, let terminator = pendingHeredoc {
			carry = .heredoc(terminator: terminator)
		}
		return (tokens, carry)
	}

	func applyLineStartRules(scanner: inout LineScanner, tokens: inout [Token]) {
		for rule in language.prePassRules where rule.anchor == .lineStart {
			guard let match = scanner.matchLineRegex(rule.regex) else {
				continue
			}
			let group = min(rule.captureGroup, match.numberOfRanges - 1)
			let range = match.range(at: group)
			guard range.location != NSNotFound, range.length > 0 else {
				continue
			}
			tokens.append(Token(kind: rule.kind, range: range))
			scanner.pos = max(scanner.pos, NSMaxRange(range))
			return
		}
	}
}

// MARK: - Comments

private extension GenericTokenizer {
	func scanLineComment(scanner: inout LineScanner, tokens: inout [Token]) -> Bool {
		for prefix in language.lineCommentPrefixesUTF16 where scanner.matches(prefix) {
			appendToken(.comment, from: scanner.pos, length: scanner.count - scanner.pos, into: &tokens)
			scanner.pos = scanner.count
			return true
		}
		return false
	}

	func scanBlockCommentOpen(scanner: inout LineScanner, tokens: inout [Token], carry: inout LineState) -> Bool {
		for (index, rule) in language.blockComments.enumerated() {
			if rule.lineAnchoredOpen && scanner.pos != 0 {
				continue
			}
			guard scanner.matches(rule.openUTF16) else {
				continue
			}
			let start = scanner.pos
			scanner.pos += rule.openUTF16.count
			if let state = continueBlockComment(
				ruleIndex: index, depth: 1, tokenStart: start, scanner: &scanner, tokens: &tokens
			) {
				carry = state
			}
			return true
		}
		return false
	}

	/// Scans a block comment body until its close or end of line. Returns the carry
	/// state when the comment is still open at EOL, nil when it closed.
	func continueBlockComment(
		ruleIndex: Int, depth: Int, tokenStart: Int, scanner: inout LineScanner, tokens: inout [Token]
	) -> LineState? {
		let rule = language.blockComments[ruleIndex]
		var depth = depth
		while !scanner.isAtEnd {
			if scanner.matches(rule.closeUTF16) {
				scanner.pos += rule.closeUTF16.count
				depth -= 1
				if depth == 0 {
					appendToken(.comment, from: tokenStart, length: scanner.pos - tokenStart, into: &tokens)
					return nil
				}
			} else if rule.nests && scanner.matches(rule.openUTF16) {
				scanner.pos += rule.openUTF16.count
				depth += 1
			} else {
				scanner.pos += 1
			}
		}
		appendToken(.comment, from: tokenStart, length: scanner.count - tokenStart, into: &tokens)
		return .blockComment(ruleIndex: ruleIndex, depth: depth)
	}
}

// MARK: - PHP-style raw boundaries

private extension GenericTokenizer {
	/// From `rawOutside`, scans for a `<?php`/`<?=`/`<?` opener. Returns true when
	/// code scanning should resume at the current position.
	func enterCodeRegion(scanner: inout LineScanner, tokens: inout [Token]) -> Bool {
		while !scanner.isAtEnd {
			if scanner.current == UnicodeScalars.lessThan,
			   scanner.unit(at: scanner.pos + 1) == UnicodeScalars.questionMark {
				let length: Int
				if scanner.matches(Self.phpOpenLong) {
					length = Self.phpOpenLong.count
				} else if scanner.matches(Self.phpOpenEcho) {
					length = Self.phpOpenEcho.count
				} else {
					length = Self.phpOpenShort.count
				}
				appendToken(.punctuationSpecial, from: scanner.pos, length: length, into: &tokens)
				scanner.pos += length
				return true
			}
			scanner.pos += 1
		}
		return false
	}
}

func appendToken(_ kind: TokenKind, from location: Int, length: Int, into tokens: inout [Token]) {
	guard length > 0 else {
		return
	}
	tokens.append(Token(kind: kind, range: NSRange(location: location, length: length)))
}
