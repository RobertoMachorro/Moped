//
//  CSharpLanguage.swift
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
	static let csharpLanguage = LanguageDefinition(
		id: "cs",
		keywords: [
			"abstract", "as", "async", "await", "break", "case", "catch", "checked",
			"class", "const", "continue", "default", "delegate", "do", "else", "enum",
			"event", "explicit", "extern", "finally", "fixed", "for", "foreach",
			"get", "goto", "if", "implicit", "in", "init", "interface", "internal",
			"is", "lock", "nameof", "namespace", "new", "operator", "out", "override",
			"params", "partial", "private", "protected", "public", "readonly",
			"record", "ref", "required", "sealed", "set", "sizeof", "stackalloc",
			"static", "struct", "switch", "throw", "try", "typeof", "unchecked",
			"unsafe", "value", "var", "virtual", "volatile", "when", "where",
			"while", "yield"
		],
		returnKeywords: ["return"],
		includeKeywords: ["using"],
		typeKeywords: [
			"bool", "byte", "char", "decimal", "double", "dynamic", "float", "int",
			"long", "nint", "nuint", "object", "sbyte", "short", "string", "uint",
			"ulong", "ushort", "void"
		],
		builtins: ["this", "base", "null"],
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: [
			StringRule(
				delimiter: "$@\"", terminator: "\"", multiline: true, escape: nil,
				interpolation: InterpolationRule(open: "{", nestOpen: "{", nestClose: "}")
			),
			StringRule(
				delimiter: "@$\"", terminator: "\"", multiline: true, escape: nil,
				interpolation: InterpolationRule(open: "{", nestOpen: "{", nestClose: "}")
			),
			StringRule(delimiter: "@\"", terminator: "\"", multiline: true, escape: nil),
			StringRule(
				delimiter: "$\"", terminator: "\"",
				interpolation: InterpolationRule(open: "{", nestOpen: "{", nestClose: "}")
			),
			StringRule(delimiter: "\""),
			StringRule(delimiter: "'")
		],
		capitalizedTypesHeuristic: true,
		prePassRules: [
			RegexRule(lineStartPattern: "^[\t ]*(#[\t ]*\\w+)", kind: .keyword)
		]
	)
}
