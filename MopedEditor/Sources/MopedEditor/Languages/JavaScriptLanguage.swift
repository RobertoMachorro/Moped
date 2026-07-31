//
//  JavaScriptLanguage.swift
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
	/// Regex literals are not detected (`/re/` renders as operators) — declared
	/// parity simplification.
	static let javascriptLanguage = LanguageDefinition(
		id: "javascript",
		keywords: javascriptKeywords,
		functionDeclKeywords: ["function"],
		returnKeywords: ["return"],
		includeKeywords: ["import", "export", "from"],
		builtins: javascriptBuiltins,
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: javascriptStrings,
		capitalizedTypesHeuristic: true,
		prePassRules: [
			RegexRule(trigger: "@", pattern: "@\\w+", kind: .punctuationSpecial)
		]
	)

	static let javascriptKeywords: Set<String> = [
		"async", "await", "break", "case", "catch", "class", "const", "continue",
		"debugger", "default", "delete", "do", "else", "extends", "finally",
		"for", "get", "if", "in", "instanceof", "let", "new", "of", "set",
		"static", "switch", "throw", "try", "typeof", "var", "void", "while",
		"with", "yield"
	]

	static let javascriptBuiltins: Set<String> = [
		"this", "null", "undefined", "NaN", "Infinity", "globalThis", "window",
		"document", "console", "arguments"
	]

	static let javascriptStrings: [StringRule] = [
		StringRule(
			delimiter: "`", multiline: true,
			interpolation: InterpolationRule(open: "${", nestOpen: "{", nestClose: "}")
		),
		StringRule(delimiter: "\""),
		StringRule(delimiter: "'")
	]
}
