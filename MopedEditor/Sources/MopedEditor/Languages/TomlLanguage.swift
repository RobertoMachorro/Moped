//
//  TomlLanguage.swift
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
	static let tomlLanguage = LanguageDefinition(
		id: "toml",
		lineCommentPrefixes: ["#"],
		strings: [
			StringRule(delimiter: "\"\"\"", multiline: true),
			StringRule(delimiter: "'''", multiline: true, escape: nil),
			StringRule(delimiter: "\""),
			StringRule(delimiter: "'", escape: nil)
		],
		prePassRules: [
			RegexRule(lineStartPattern: "^[\t ]*(\\[[^\\]]*\\])[\t ]*$", kind: .textTitle),
			RegexRule(lineStartPattern: "^[\t ]*([\\w.-]+)(?=[\t ]*=)", kind: .variable)
		]
	)
}
