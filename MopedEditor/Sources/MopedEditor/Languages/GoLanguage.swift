//
//  GoLanguage.swift
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
	static let goLanguage = LanguageDefinition(
		id: "go",
		keywords: [
			"break", "case", "chan", "const", "continue", "default", "defer",
			"else", "fallthrough", "for", "go", "goto", "if", "interface", "map",
			"range", "select", "struct", "switch", "type", "var"
		],
		functionDeclKeywords: ["func"],
		returnKeywords: ["return"],
		includeKeywords: ["import", "package"],
		typeKeywords: [
			"any", "bool", "byte", "complex64", "complex128", "error", "float32",
			"float64", "int", "int8", "int16", "int32", "int64", "rune", "string",
			"uint", "uint8", "uint16", "uint32", "uint64", "uintptr"
		],
		builtins: [
			"nil", "iota", "append", "cap", "clear", "close", "copy", "delete",
			"len", "make", "new", "panic", "print", "println", "recover"
		],
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: [
			StringRule(delimiter: "`", multiline: true, escape: nil),
			StringRule(delimiter: "\""),
			StringRule(delimiter: "'")
		],
		capitalizedTypesHeuristic: true
	)
}
