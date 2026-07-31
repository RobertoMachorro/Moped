//
//  PythonLanguage.swift
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
	static let pythonLanguage = LanguageDefinition(
		id: "python",
		keywords: [
			"and", "as", "assert", "async", "await", "break", "case", "class",
			"continue", "del", "elif", "else", "except", "finally", "for", "global",
			"if", "in", "is", "lambda", "match", "nonlocal", "not", "or", "pass",
			"raise", "try", "while", "with", "yield"
		],
		functionDeclKeywords: ["def"],
		returnKeywords: ["return"],
		includeKeywords: ["import", "from"],
		booleans: ["True", "False"],
		builtins: [
			"self", "cls", "None", "NotImplemented", "Ellipsis", "print", "len",
			"range", "str", "int", "float", "bool", "list", "dict", "set", "tuple",
			"type", "isinstance", "issubclass", "super", "open", "enumerate", "zip",
			"map", "filter", "sorted", "reversed", "sum", "min", "max", "abs",
			"repr", "hash", "id", "input", "iter", "next", "vars", "getattr",
			"setattr", "hasattr"
		],
		lineCommentPrefixes: ["#"],
		strings: [
			StringRule(delimiter: "\"\"\"", multiline: true),
			StringRule(delimiter: "'''", multiline: true),
			StringRule(delimiter: "\""),
			StringRule(delimiter: "'")
		],
		capitalizedTypesHeuristic: true,
		prePassRules: [
			RegexRule(trigger: "@", pattern: "@[\\w.]+", kind: .include)
		]
	)
}
