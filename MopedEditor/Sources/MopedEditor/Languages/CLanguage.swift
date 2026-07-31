//
//  CLanguage.swift
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
	static let cLanguage = LanguageDefinition(
		id: "c",
		keywords: [
			"auto", "break", "case", "const", "continue", "default", "do", "else",
			"enum", "extern", "for", "goto", "if", "inline", "register", "restrict",
			"sizeof", "static", "struct", "switch", "typedef", "union", "volatile",
			"while"
		],
		returnKeywords: ["return"],
		typeKeywords: [
			"bool", "char", "double", "float", "int", "long", "short", "signed",
			"unsigned", "void", "size_t", "ssize_t", "wchar_t", "_Bool",
			"int8_t", "int16_t", "int32_t", "int64_t",
			"uint8_t", "uint16_t", "uint32_t", "uint64_t",
			"intptr_t", "uintptr_t", "ptrdiff_t"
		],
		builtins: ["NULL"],
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: [
			StringRule(delimiter: "\""),
			StringRule(delimiter: "'")
		],
		prePassRules: [
			RegexRule(lineStartPattern: "^[\t ]*(#[\t ]*(?:include|import)\\b)", kind: .include),
			RegexRule(lineStartPattern: "^[\t ]*(#[\t ]*\\w+)", kind: .keyword)
		]
	)
}
