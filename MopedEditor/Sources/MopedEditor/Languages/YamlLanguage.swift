//
//  YamlLanguage.swift
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
	/// Block scalar bodies (`|`/`>`) render plain — declared simplification.
	static let yamlLanguage = LanguageDefinition(
		id: "yaml",
		booleans: [
			"true", "false", "True", "False", "TRUE", "FALSE", "yes", "no", "Yes",
			"No", "YES", "NO", "on", "off", "On", "Off", "ON", "OFF"
		],
		builtins: ["null", "Null", "NULL"],
		lineCommentPrefixes: ["#"],
		strings: [
			StringRule(delimiter: "\""),
			StringRule(delimiter: "'", escape: nil)
		],
		prePassRules: [
			RegexRule(
				lineStartPattern: "^[\t ]*(?:-[\t ]+)*([\\w.-]+)(?=[\t ]*:(?:[\t ]|$))",
				kind: .variable
			),
			RegexRule(trigger: "&", pattern: "&\\w+", kind: .punctuationSpecial),
			RegexRule(trigger: "*", pattern: "\\*\\w+", kind: .punctuationSpecial),
			RegexRule(trigger: "!", pattern: "!!?[\\w/]+", kind: .punctuationSpecial)
		]
	)
}
