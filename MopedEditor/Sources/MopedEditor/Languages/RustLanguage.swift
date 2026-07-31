//
//  RustLanguage.swift
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
	static let rustLanguage = LanguageDefinition(
		id: "rust",
		keywords: [
			"as", "async", "await", "break", "const", "continue", "crate", "dyn",
			"else", "enum", "extern", "for", "if", "impl", "in", "let", "loop",
			"match", "mod", "move", "mut", "pub", "ref", "static", "struct",
			"trait", "type", "union", "unsafe", "where", "while"
		],
		functionDeclKeywords: ["fn"],
		returnKeywords: ["return"],
		includeKeywords: ["use"],
		typeKeywords: [
			"bool", "char", "f32", "f64", "i8", "i16", "i32", "i64", "i128",
			"isize", "str", "u8", "u16", "u32", "u64", "u128", "usize"
		],
		builtins: ["self", "Self", "super"],
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/", nests: true)
		],
		strings: [
			StringRule(delimiter: "r#\"", terminator: "\"#", multiline: true, escape: nil),
			StringRule(delimiter: "r\"", terminator: "\"", multiline: true, escape: nil),
			StringRule(delimiter: "\"", multiline: true)
		],
		capitalizedTypesHeuristic: true,
		prePassRules: [
			// Lifetimes; the negative lookahead keeps char literals ('a') on the
			// string path below.
			RegexRule(trigger: "'", pattern: "'\\w+(?!')", kind: .punctuationSpecial),
			RegexRule(trigger: "#", pattern: "#!?\\[[^\\]]*\\]?", kind: .punctuationSpecial)
		]
	)
}
