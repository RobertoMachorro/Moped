//
//  BashLanguage.swift
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
	static let bashLanguage = LanguageDefinition(
		id: "bash",
		aliases: ["shell"],
		keywords: [
			"alias", "break", "case", "continue", "coproc", "declare", "do",
			"done", "elif", "else", "esac", "eval", "exec", "exit", "export",
			"fi", "for", "if", "in", "local", "readonly", "select", "set",
			"shift", "then", "time", "trap", "typeset", "unset", "until", "while"
		],
		functionDeclKeywords: ["function"],
		returnKeywords: ["return"],
		includeKeywords: ["source"],
		lineCommentPrefixes: ["#"],
		strings: [
			StringRule(delimiter: "\"", embedded: expansionRules),
			StringRule(delimiter: "'", escape: nil)
		],
		prePassRules: expansionRules,
		heredoc: HeredocRule(trigger: "<", pattern: "<<-?[\t ]*[\"']?([A-Za-z_]\\w*)[\"']?")
	)

	/// Parameter expansions, highlighted both in code and inside double-quoted
	/// strings (where shell scripts use them constantly).
	private static let expansionRules: [RegexRule] = [
		RegexRule(trigger: "$", pattern: "\\$\\{[^}]*\\}?", kind: .variableBuiltin),
		RegexRule(trigger: "$", pattern: "\\$(?:\\w+|[-@#?*!$0-9])", kind: .variableBuiltin)
	]
}
