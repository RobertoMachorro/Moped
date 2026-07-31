//
//  CppLanguage.swift
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
	/// Also serves Objective-C sources (the `objectivec` alias): the `@word` pre-pass
	/// rule picks up `@interface`/`@property`/….
	static let cppLanguage = LanguageDefinition(
		id: "cpp",
		aliases: ["objectivec"],
		keywords: [
			"alignas", "alignof", "auto", "break", "case", "catch", "class",
			"concept", "const", "consteval", "constexpr", "constinit", "const_cast",
			"continue", "co_await", "co_return", "co_yield", "decltype", "default",
			"delete", "do", "dynamic_cast", "else", "enum", "explicit", "export",
			"extern", "final", "for", "friend", "goto", "if", "inline", "mutable",
			"namespace", "new", "noexcept", "operator", "override", "private",
			"protected", "public", "register", "reinterpret_cast", "requires",
			"restrict", "sizeof", "static", "static_assert", "static_cast", "struct",
			"switch", "template", "throw", "try", "typedef", "typeid", "typename",
			"union", "using", "virtual", "volatile", "while"
		],
		returnKeywords: ["return"],
		typeKeywords: [
			"bool", "char", "char8_t", "char16_t", "char32_t", "double", "float",
			"int", "long", "short", "signed", "unsigned", "void", "wchar_t",
			"size_t", "ssize_t", "int8_t", "int16_t", "int32_t", "int64_t",
			"uint8_t", "uint16_t", "uint32_t", "uint64_t", "intptr_t", "uintptr_t",
			"ptrdiff_t", "id", "instancetype", "BOOL", "NSInteger", "NSUInteger"
		],
		booleans: ["true", "false", "YES", "NO"],
		builtins: ["this", "nullptr", "NULL", "nil", "self", "super"],
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: [
			StringRule(delimiter: "\""),
			StringRule(delimiter: "'")
		],
		capitalizedTypesHeuristic: true,
		prePassRules: [
			RegexRule(lineStartPattern: "^[\t ]*(#[\t ]*(?:include|import)\\b)", kind: .include),
			RegexRule(lineStartPattern: "^[\t ]*(#[\t ]*\\w+)", kind: .keyword),
			RegexRule(trigger: "@", pattern: "@\\w+", kind: .punctuationSpecial)
		]
	)
}
