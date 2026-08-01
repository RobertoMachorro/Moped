//
//  GenericTokenizer+Literals.swift
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

// MARK: - Strings and heredocs

extension GenericTokenizer {
	func scanStringOpen(scanner: inout LineScanner, tokens: inout [Token], carry: inout LineState) -> Bool {
		for (index, rule) in language.strings.enumerated() where scanner.matches(rule.delimiterUTF16) {
			let start = scanner.pos
			scanner.pos += rule.delimiterUTF16.count
			if let state = scanStringBody(ruleIndex: index, tokenStart: start, scanner: &scanner, tokens: &tokens) {
				carry = state
			}
			return true
		}
		return false
	}

	/// Scans a string body from the current position until terminator or EOL.
	/// Returns the carry state when a multiline string is still open, nil otherwise.
	func scanStringBody(
		ruleIndex: Int, tokenStart: Int, scanner: inout LineScanner, tokens: inout [Token]
	) -> LineState? {
		let rule = language.strings[ruleIndex]
		var runStart = tokenStart
		while !scanner.isAtEnd {
			// Interpolation before escape: Swift's `\(` starts with the escape character.
			if let interpolation = rule.interpolation, scanner.matches(interpolation.openUTF16) {
				appendToken(.string, from: runStart, length: scanner.pos - runStart, into: &tokens)
				markInterpolation(interpolation, scanner: &scanner, tokens: &tokens)
				runStart = scanner.pos
				continue
			}
			if let escape = rule.escape, scanner.current == escape {
				scanner.pos = min(scanner.pos + 2, scanner.count)
				continue
			}
			if scanner.matches(rule.terminatorUTF16) {
				scanner.pos += rule.terminatorUTF16.count
				appendToken(.string, from: runStart, length: scanner.pos - runStart, into: &tokens)
				return nil
			}
			if let match = matchEmbedded(rule.embedded, scanner: scanner) {
				appendToken(.string, from: runStart, length: match.range.location - runStart, into: &tokens)
				tokens.append(Token(kind: match.kind, range: match.range))
				scanner.pos = NSMaxRange(match.range)
				runStart = scanner.pos
				continue
			}
			scanner.pos += 1
		}
		appendToken(.string, from: runStart, length: scanner.count - runStart, into: &tokens)
		return rule.multiline ? .string(ruleIndex: ruleIndex) : nil
	}

	func matchEmbedded(_ rules: [RegexRule], scanner: LineScanner) -> (kind: TokenKind, range: NSRange)? {
		for rule in rules where scanner.current == rule.trigger {
			guard let match = scanner.matchRegex(rule.regex, at: scanner.pos), match.range.length > 0 else {
				continue
			}
			return (rule.kind, match.range)
		}
		return nil
	}

	/// Emits `punctuation.special` for the interpolation delimiters and `string` for
	/// the interior, tracking delimiter nesting within the line.
	func markInterpolation(_ rule: InterpolationRule, scanner: inout LineScanner, tokens: inout [Token]) {
		appendToken(.punctuationSpecial, from: scanner.pos, length: rule.openUTF16.count, into: &tokens)
		scanner.pos += rule.openUTF16.count
		var depth = 1
		let interiorStart = scanner.pos
		while !scanner.isAtEnd {
			let unit = scanner.current
			if unit == rule.nestOpen {
				depth += 1
			} else if unit == rule.nestClose {
				depth -= 1
				if depth == 0 {
					break
				}
			}
			scanner.pos += 1
		}
		appendToken(.string, from: interiorStart, length: scanner.pos - interiorStart, into: &tokens)
		if !scanner.isAtEnd {
			appendToken(.punctuationSpecial, from: scanner.pos, length: 1, into: &tokens)
			scanner.pos += 1
		}
	}

	func scanHeredocOpen(scanner: inout LineScanner, tokens: inout [Token], pendingHeredoc: inout String?) -> Bool {
		guard let rule = language.heredoc,
			  pendingHeredoc == nil,
			  scanner.current == rule.trigger,
			  let match = scanner.matchRegex(rule.regex, at: scanner.pos),
			  match.numberOfRanges > 1,
			  match.range(at: 1).location != NSNotFound
		else {
			return false
		}
		tokens.append(Token(kind: .string, range: match.range))
		pendingHeredoc = scanner.substring(in: match.range(at: 1))
		scanner.pos = NSMaxRange(match.range)
		return true
	}

	func tokenizeHeredocBody(
		line: String, scanner: LineScanner, terminator: String, tokens: inout [Token]
	) -> ([Token], LineState) {
		if scanner.count > 0 {
			tokens.append(Token(kind: .string, range: NSRange(location: 0, length: scanner.count)))
		}
		let trimmed = line.trimmingCharacters(in: .whitespaces)
		return (tokens, trimmed == terminator ? .none : .heredoc(terminator: terminator))
	}
}

// MARK: - Pre-pass rules, numbers, identifiers, operators

extension GenericTokenizer {
	func scanPrePassRules(scanner: inout LineScanner, tokens: inout [Token]) -> Bool {
		for rule in language.prePassRules
		where rule.anchor == .position && scanner.current == rule.trigger {
			guard let match = scanner.matchRegex(rule.regex, at: scanner.pos), match.range.length > 0 else {
				continue
			}
			tokens.append(Token(kind: rule.kind, range: match.range))
			scanner.pos = NSMaxRange(match.range)
			return true
		}
		return false
	}

	/// The value-shaped scanners, tried in order once comments, pre-pass rules and
	/// string openers have had their chance at the current position.
	func scanValueToken(scanner: inout LineScanner, tokens: inout [Token]) -> Bool {
		if scanNumber(scanner: &scanner, tokens: &tokens) {
			return true
		}
		if scanIdentifier(scanner: &scanner, tokens: &tokens) {
			return true
		}
		return scanOperator(scanner: &scanner, tokens: &tokens)
	}

	func scanNumber(scanner: inout LineScanner, tokens: inout [Token]) -> Bool {
		let unit = scanner.current
		let startsNumber = UnicodeScalars.isDigit(unit)
			|| (unit == UnicodeScalars.dot && UnicodeScalars.isDigit(scanner.unit(at: scanner.pos + 1) ?? 0))
		guard startsNumber,
			  let match = scanner.matchRegex(Self.numberRegex, at: scanner.pos),
			  match.range.length > 0
		else {
			return false
		}
		tokens.append(Token(kind: .number, range: match.range))
		scanner.pos = NSMaxRange(match.range)
		return true
	}

	func scanIdentifier(scanner: inout LineScanner, tokens: inout [Token]) -> Bool {
		guard UnicodeScalars.isIdentifierStart(scanner.current) else {
			return false
		}
		let start = scanner.pos
		while !scanner.isAtEnd && UnicodeScalars.isIdentifierContinue(scanner.current) {
			scanner.pos += 1
		}
		let word = scanner.substring(in: NSRange(location: start, length: scanner.pos - start))
		let kind = classify(word: word, start: start, end: scanner.pos, scanner: scanner)
		if kind != .plain {
			appendToken(kind, from: start, length: scanner.pos - start, into: &tokens)
		}
		return true
	}

	func classify(word: String, start: Int, end: Int, scanner: LineScanner) -> TokenKind {
		let key = language.caseInsensitiveKeywords ? word.lowercased() : word
		if language.booleans.contains(key) {
			return .boolean
		}
		if language.includeKeywords.contains(key) {
			return .include
		}
		if language.returnKeywords.contains(key) {
			return .keywordReturn
		}
		if language.functionDeclKeywords.contains(key) {
			return .keywordFunction
		}
		if language.typeKeywords.contains(key) {
			return .type
		}
		if language.keywords.contains(key) {
			return .keyword
		}
		if language.builtins.contains(key) {
			return .variableBuiltin
		}
		let capitalized = UnicodeScalars.isUppercaseLetter(scanner.units[start])
		if scanner.nextNonSpace(from: end) == UnicodeScalars.openParen {
			if capitalized {
				return .constructor
			}
			return scanner.previousNonSpace(before: start) == UnicodeScalars.dot ? .method : .functionCall
		}
		if capitalized && language.capitalizedTypesHeuristic {
			// CamelCase (or a single-letter generic) reads as a type; SCREAMING_CASE
			// constants stay plain.
			let mixedCase = word.count == 1 || word.contains(where: \.isLowercase)
			return mixedCase ? .type : .plain
		}
		return .plain
	}

	func scanOperator(scanner: inout LineScanner, tokens: inout [Token]) -> Bool {
		guard Self.operatorUnits.contains(scanner.current) else {
			return false
		}
		let start = scanner.pos
		while !scanner.isAtEnd && Self.operatorUnits.contains(scanner.current) {
			scanner.pos += 1
		}
		appendToken(.operator, from: start, length: scanner.pos - start, into: &tokens)
		return true
	}
}
