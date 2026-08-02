//
//  DiffLanguage.swift
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
	/// Unified diffs are entirely line-oriented, so every rule is line-anchored and
	/// claims the whole line. Only the first matching rule fires per line, which makes
	/// declaration order the precedence: the `---`/`+++` file headers have to come
	/// before the bare `-`/`+` rules or they would read as removed and added lines.
	///
	/// The trailing catch-all is deliberate. Consuming context lines keeps the generic
	/// code scanner from running on them — a patch is arbitrary source, and colouring
	/// its numbers and operators as code only adds noise around the actual changes.
	static let diffLanguage = LanguageDefinition(
		id: "diff",
		booleans: [],
		prePassRules: [
			RegexRule(lineStartPattern: "^(diff[\t ].*)", kind: .textTitle),
			RegexRule(lineStartPattern: "^(index[\t ].*)", kind: .comment),
			RegexRule(lineStartPattern: "^(---[\t ].*)", kind: .textTitle),
			RegexRule(lineStartPattern: "^(\\+\\+\\+[\t ].*)", kind: .textTitle),
			RegexRule(lineStartPattern: "^(@@.*)", kind: .include),
			RegexRule(lineStartPattern: "^(\\+.*)", kind: .diffPlus),
			RegexRule(lineStartPattern: "^(-.*)", kind: .diffMinus),
			// "\ No newline at end of file".
			RegexRule(lineStartPattern: "^(\\\\[\t ].*)", kind: .comment),
			RegexRule(lineStartPattern: "^(.*)", kind: .plain)
		]
	)
}
