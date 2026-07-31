//
//  SwiftLanguage.swift
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
	static let swiftLanguage = LanguageDefinition(
		id: "swift",
		keywords: [
			"actor", "any", "as", "associatedtype", "async", "await", "break", "case",
			"catch", "class", "continue", "convenience", "default", "defer", "deinit",
			"do", "dynamic", "else", "enum", "extension", "fallthrough", "fileprivate",
			"final", "for", "guard", "if", "in", "indirect", "infix", "init", "inout",
			"internal", "is", "lazy", "let", "mutating", "nonisolated", "nonmutating",
			"open", "operator", "optional", "override", "postfix", "prefix", "private",
			"protocol", "public", "repeat", "required", "rethrows", "some", "static",
			"struct", "subscript", "switch", "throw", "throws", "try", "typealias",
			"unowned", "var", "weak", "where", "while"
		],
		functionDeclKeywords: ["func"],
		returnKeywords: ["return"],
		includeKeywords: ["import"],
		builtins: ["self", "Self", "super", "nil"],
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/", nests: true)
		],
		strings: [
			StringRule(
				delimiter: "\"\"\"", multiline: true,
				interpolation: InterpolationRule(open: "\\(", nestOpen: "(", nestClose: ")")
			),
			StringRule(
				delimiter: "\"",
				interpolation: InterpolationRule(open: "\\(", nestOpen: "(", nestClose: ")")
			)
		],
		capitalizedTypesHeuristic: true,
		prePassRules: [
			RegexRule(trigger: "@", pattern: "@\\w+", kind: .punctuationSpecial),
			RegexRule(trigger: "#", pattern: "#\\w+", kind: .punctuationSpecial)
		]
	)
}
