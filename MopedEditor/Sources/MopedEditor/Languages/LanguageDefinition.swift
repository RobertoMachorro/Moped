//
//  LanguageDefinition.swift
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

/// A block comment delimiter pair. `lineAnchoredOpen` restricts the opener to column
/// zero (Ruby's `=begin`).
struct BlockCommentRule: Sendable {
	let open: String
	let close: String
	let nests: Bool
	let lineAnchoredOpen: Bool
	let openUTF16: [UInt16]
	let closeUTF16: [UInt16]

	init(open: String, close: String, nests: Bool = false, lineAnchoredOpen: Bool = false) {
		self.open = open
		self.close = close
		self.nests = nests
		self.lineAnchoredOpen = lineAnchoredOpen
		self.openUTF16 = Array(open.utf16)
		self.closeUTF16 = Array(close.utf16)
	}
}

/// String interpolation delimiters (`\(…)`, `${…}`, `#{…}`, `{…}`). The interior stays
/// string-colored; only the delimiters are emitted as `punctuation.special`.
struct InterpolationRule: Sendable {
	let open: String
	let openUTF16: [UInt16]
	/// Nesting is tracked by counting these two units between open and close.
	let nestOpen: UInt16
	let nestClose: UInt16

	init(open: String, nestOpen: Character, nestClose: Character) {
		self.open = open
		self.openUTF16 = Array(open.utf16)
		self.nestOpen = nestOpen.utf16.first ?? 0
		self.nestClose = nestClose.utf16.first ?? 0
	}
}

/// One string literal form. Rules are tried in declaration order, so list longer
/// delimiters first (`"""` before `"`).
struct StringRule: Sendable {
	let delimiter: String
	let terminator: String
	let multiline: Bool
	let escape: UInt16?
	let interpolation: InterpolationRule?
	/// Patterns highlighted inside the string body — shell/PHP `$variable`
	/// expansions, which real scripts rely on being visible.
	let embedded: [RegexRule]
	let delimiterUTF16: [UInt16]
	let terminatorUTF16: [UInt16]

	init(
		delimiter: String,
		terminator: String? = nil,
		multiline: Bool = false,
		escape: Character? = "\\",
		interpolation: InterpolationRule? = nil,
		embedded: [RegexRule] = []
	) {
		self.delimiter = delimiter
		self.terminator = terminator ?? delimiter
		self.multiline = multiline
		self.escape = escape?.utf16.first
		self.interpolation = interpolation
		self.embedded = embedded
		self.delimiterUTF16 = Array(delimiter.utf16)
		self.terminatorUTF16 = Array(self.terminator.utf16)
	}
}

/// A regex-driven rule the scanner tries before the built-in string/number/identifier
/// handling. `.position` rules fire only when the current character equals `trigger`;
/// `.lineStart` rules run once per line against the whole line (pattern should anchor
/// with `^`) and emit `captureGroup`.
struct RegexRule: @unchecked Sendable {
	enum Anchor: Sendable {
		case position
		case lineStart
	}

	let anchor: Anchor
	let trigger: UInt16
	let regex: NSRegularExpression
	let kind: TokenKind
	let captureGroup: Int

	init(trigger: Character, pattern: String, kind: TokenKind) {
		self.anchor = .position
		self.trigger = trigger.utf16.first ?? 0
		// swiftlint:disable:next force_try
		self.regex = try! NSRegularExpression(pattern: pattern)
		self.kind = kind
		self.captureGroup = 0
	}

	init(lineStartPattern: String, kind: TokenKind, captureGroup: Int = 1) {
		self.anchor = .lineStart
		self.trigger = 0
		// swiftlint:disable:next force_try
		self.regex = try! NSRegularExpression(pattern: lineStartPattern)
		self.kind = kind
		self.captureGroup = captureGroup
	}
}

/// Heredoc opener (`<<EOF`, `<<~EOF`, `<<<EOF`). The regex must capture the terminator
/// word in group 1.
struct HeredocRule: @unchecked Sendable {
	let trigger: UInt16
	let regex: NSRegularExpression
	/// Whether the closing line may carry trailing expression punctuation — `SQL;`, `SQL);`,
	/// `SQL],`. True only for PHP, where the heredoc closes as part of the statement and that
	/// is the canonical form. Shells and Ruby terminate on a line holding the identifier and
	/// nothing else, so allowing a suffix there would end a heredoc early on a body line that
	/// happens to read `EOF;`.
	let allowsTerminatorSuffix: Bool

	init(trigger: Character, pattern: String, allowsTerminatorSuffix: Bool = false) {
		self.trigger = trigger.utf16.first ?? 0
		// swiftlint:disable:next force_try
		self.regex = try! NSRegularExpression(pattern: pattern)
		self.allowsTerminatorSuffix = allowsTerminatorSuffix
	}
}

/// Everything the `GenericTokenizer` needs to know about one language. Pure data:
/// adding a language means adding one of these to `LanguageRegistry`.
struct LanguageDefinition: Sendable {
	let id: String
	let aliases: [String]
	let keywords: Set<String>
	let functionDeclKeywords: Set<String>
	let returnKeywords: Set<String>
	let includeKeywords: Set<String>
	let typeKeywords: Set<String>
	let booleans: Set<String>
	let builtins: Set<String>
	let caseInsensitiveKeywords: Bool
	let lineCommentPrefixes: [String]
	/// Require a line comment to start the line or follow whitespace, `{`, `}`, `;` or `,`.
	/// CSS needs it: `//` is carried only for the scss/less aliases, and unguarded it turned
	/// the `//` in `url(http://example.com/a.png)` into a comment to end of line.
	let lineCommentNeedsBoundary: Bool
	let blockComments: [BlockCommentRule]
	let strings: [StringRule]
	let capitalizedTypesHeuristic: Bool
	let prePassRules: [RegexRule]
	let heredoc: HeredocRule?
	/// PHP-style: highlighting only applies between `<?php`/`<?=` and `?>`.
	let rawBoundaries: Bool
	let initialState: LineState
	let lineCommentPrefixesUTF16: [[UInt16]]

	init(
		id: String,
		aliases: [String] = [],
		keywords: Set<String> = [],
		functionDeclKeywords: Set<String> = [],
		returnKeywords: Set<String> = [],
		includeKeywords: Set<String> = [],
		typeKeywords: Set<String> = [],
		booleans: Set<String> = ["true", "false"],
		builtins: Set<String> = [],
		caseInsensitiveKeywords: Bool = false,
		lineCommentPrefixes: [String] = [],
		lineCommentNeedsBoundary: Bool = false,
		blockComments: [BlockCommentRule] = [],
		strings: [StringRule] = [],
		capitalizedTypesHeuristic: Bool = false,
		prePassRules: [RegexRule] = [],
		heredoc: HeredocRule? = nil,
		rawBoundaries: Bool = false
	) {
		self.id = id
		self.aliases = aliases
		self.keywords = keywords
		self.functionDeclKeywords = functionDeclKeywords
		self.returnKeywords = returnKeywords
		self.includeKeywords = includeKeywords
		self.typeKeywords = typeKeywords
		self.booleans = booleans
		self.builtins = builtins
		self.caseInsensitiveKeywords = caseInsensitiveKeywords
		self.lineCommentPrefixes = lineCommentPrefixes
		self.lineCommentNeedsBoundary = lineCommentNeedsBoundary
		self.blockComments = blockComments
		self.strings = strings
		self.capitalizedTypesHeuristic = capitalizedTypesHeuristic
		self.prePassRules = prePassRules
		self.heredoc = heredoc
		self.rawBoundaries = rawBoundaries
		self.initialState = rawBoundaries ? .rawOutside : .none
		self.lineCommentPrefixesUTF16 = lineCommentPrefixes.map { Array($0.utf16) }
	}
}
