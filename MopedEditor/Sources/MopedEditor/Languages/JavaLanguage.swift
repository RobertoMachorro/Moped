//
//  JavaLanguage.swift
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
	/// Also serves the `kotlin` and `groovy` aliases; the extra Kotlin keywords
	/// (`fun`, `val`, `when`, …) are harmless for plain Java sources.
	static let javaLanguage = LanguageDefinition(
		id: "java",
		aliases: ["kotlin", "groovy"],
		keywords: [
			"abstract", "assert", "break", "case", "catch", "class", "const",
			"continue", "default", "do", "else", "enum", "extends", "final",
			"finally", "for", "goto", "if", "implements", "instanceof", "interface",
			"native", "new", "package", "permits", "private", "protected", "public",
			"record", "sealed", "static", "strictfp", "switch", "synchronized",
			"throw", "throws", "transient", "try", "var", "volatile", "while",
			"yield",
			"companion", "data", "in", "init", "internal", "is", "lateinit",
			"object", "open", "out", "override", "suspend", "typealias", "val",
			"when"
		],
		functionDeclKeywords: ["fun"],
		returnKeywords: ["return"],
		includeKeywords: ["import"],
		typeKeywords: [
			"boolean", "byte", "char", "double", "float", "int", "long", "short",
			"void"
		],
		builtins: ["this", "super", "null"],
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: [
			StringRule(delimiter: "\"\"\"", multiline: true),
			StringRule(
				delimiter: "\"",
				interpolation: InterpolationRule(open: "${", nestOpen: "{", nestClose: "}")
			),
			StringRule(delimiter: "'")
		],
		capitalizedTypesHeuristic: true,
		prePassRules: [
			RegexRule(trigger: "@", pattern: "@\\w+", kind: .punctuationSpecial)
		]
	)
}
