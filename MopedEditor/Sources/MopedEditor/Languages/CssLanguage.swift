//
//  CssLanguage.swift
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

extension LanguageDefinition {
	/// Also serves `scss`/`less` (hence the `//` line comments, harmless for CSS).
	static let cssLanguage = LanguageDefinition(
		id: "css",
		aliases: ["scss", "less"],
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: [
			StringRule(delimiter: "\""),
			StringRule(delimiter: "'")
		],
		prePassRules: [
			// Property names (`color:`); selectors like `a:hover` are a declared
			// near-miss of the same shape.
			RegexRule(lineStartPattern: "^[\t ]*(-{0,2}[a-zA-Z][-\\w]*)(?=[\t ]*:)", kind: .variableBuiltin),
			RegexRule(trigger: "#", pattern: "#[0-9a-fA-F]{3,8}\\b", kind: .number),
			RegexRule(trigger: "#", pattern: "#[a-zA-Z][-\\w]*", kind: .type),
			RegexRule(trigger: ".", pattern: "\\.[a-zA-Z][-\\w]*", kind: .type),
			RegexRule(trigger: "@", pattern: "@[\\w-]+", kind: .include),
			RegexRule(trigger: "!", pattern: "![\t ]*important\\b", kind: .keyword),
			RegexRule(trigger: "$", pattern: "\\$[-\\w]+", kind: .variable)
		]
	)
}
