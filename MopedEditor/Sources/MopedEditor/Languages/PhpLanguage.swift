//
//  PhpLanguage.swift
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
	/// Text outside `<?php … ?>` renders plain (no embedded HTML highlighting).
	static let phpLanguage = LanguageDefinition(
		id: "php",
		keywords: [
			"abstract", "and", "array", "as", "break", "callable", "case", "catch",
			"class", "clone", "const", "continue", "declare", "default", "do",
			"echo", "else", "elseif", "empty", "enddeclare", "endfor", "endforeach",
			"endif", "endswitch", "endwhile", "enum", "extends", "final", "finally",
			"for", "foreach", "global", "goto", "if", "implements", "instanceof",
			"insteadof", "interface", "isset", "list", "match", "new", "or",
			"print", "private", "protected", "public", "readonly", "static",
			"switch", "throw", "trait", "try", "unset", "var", "while", "xor",
			"yield"
		],
		functionDeclKeywords: ["function", "fn"],
		returnKeywords: ["return"],
		includeKeywords: [
			"use", "namespace", "require", "require_once", "include", "include_once"
		],
		typeKeywords: [
			"bool", "float", "int", "iterable", "mixed", "never", "object",
			"string", "void"
		],
		caseInsensitiveKeywords: true,
		lineCommentPrefixes: ["//", "#"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: [
			StringRule(
				delimiter: "\"",
				interpolation: InterpolationRule(open: "{$", nestOpen: "{", nestClose: "}"),
				embedded: variableRules
			),
			StringRule(delimiter: "'")
		],
		capitalizedTypesHeuristic: true,
		prePassRules: variableRules + [
			RegexRule(trigger: "@", pattern: "@\\w+", kind: .punctuationSpecial)
		],
		heredoc: HeredocRule(trigger: "<", pattern: "<<<[\"']?(\\w+)[\"']?"),
		rawBoundaries: true
	)

	private static let variableRules: [RegexRule] = [
		RegexRule(trigger: "$", pattern: "\\$this\\b", kind: .variableBuiltin),
		RegexRule(trigger: "$", pattern: "\\$\\w+", kind: .variable)
	]
}
