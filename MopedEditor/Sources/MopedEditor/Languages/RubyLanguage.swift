//
//  RubyLanguage.swift
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
	static let rubyLanguage = LanguageDefinition(
		id: "ruby",
		keywords: [
			"alias", "and", "begin", "break", "case", "class", "defined?", "do",
			"else", "elsif", "end", "ensure", "for", "if", "in", "module", "next",
			"not", "or", "redo", "rescue", "retry", "then", "undef", "unless",
			"until", "when", "while", "yield", "raise", "attr_accessor",
			"attr_reader", "attr_writer", "private", "protected", "public"
		],
		functionDeclKeywords: ["def"],
		returnKeywords: ["return"],
		includeKeywords: ["require", "require_relative", "include", "extend", "load"],
		builtins: ["self", "nil", "super", "__FILE__", "__LINE__", "__method__"],
		lineCommentPrefixes: ["#"],
		blockComments: [
			BlockCommentRule(open: "=begin", close: "=end", lineAnchoredOpen: true)
		],
		strings: [
			StringRule(
				delimiter: "\"",
				interpolation: InterpolationRule(open: "#{", nestOpen: "{", nestClose: "}")
			),
			StringRule(delimiter: "'"),
			StringRule(
				delimiter: "`",
				interpolation: InterpolationRule(open: "#{", nestOpen: "{", nestClose: "}")
			)
		],
		capitalizedTypesHeuristic: true,
		prePassRules: [
			RegexRule(trigger: "@", pattern: "@@?\\w+", kind: .variableBuiltin),
			RegexRule(trigger: "$", pattern: "\\$\\w+", kind: .variableBuiltin),
			RegexRule(trigger: ":", pattern: ":\\w+[?!]?", kind: .variableBuiltin)
		],
		heredoc: HeredocRule(trigger: "<", pattern: "<<[~-]?[\"']?([A-Z][A-Za-z0-9_]*)[\"']?")
	)
}
