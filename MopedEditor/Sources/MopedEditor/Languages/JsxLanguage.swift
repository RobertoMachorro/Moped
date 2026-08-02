//
//  JsxLanguage.swift
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
	/// JavaScript plus element names. The scanner has no markup state, so attribute
	/// names stay plain — but strings, `{…}` expressions and everything else inside a
	/// tag already fall out of the JavaScript rules.
	static let jsxLanguage = LanguageDefinition(
		id: "jsx",
		keywords: javascriptKeywords,
		functionDeclKeywords: ["function"],
		returnKeywords: ["return"],
		includeKeywords: ["import", "export", "from"],
		builtins: javascriptBuiltins,
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: javascriptStrings,
		capitalizedTypesHeuristic: true,
		prePassRules: jsxPrePassRules
	)

	/// TypeScript on the same terms as `jsxLanguage`.
	static let tsxLanguage = LanguageDefinition(
		id: "tsx",
		keywords: typescriptKeywords,
		functionDeclKeywords: ["function"],
		returnKeywords: ["return"],
		includeKeywords: ["import", "export", "from"],
		typeKeywords: typescriptTypeKeywords,
		builtins: javascriptBuiltins,
		lineCommentPrefixes: ["//"],
		blockComments: [
			BlockCommentRule(open: "/*", close: "*/")
		],
		strings: javascriptStrings,
		capitalizedTypesHeuristic: true,
		prePassRules: jsxPrePassRules
	)

	/// Element names in `<Foo …>` and `</Foo>`. The lookahead is what keeps a
	/// comparison from being read as a tag: an element name is always followed by
	/// whitespace, `/` or `>`, so `i<n;` and `a < b` are left alone.
	///
	/// The first two rules exist because `scanOperator` swallows a whole run of
	/// operator characters, and `<` is one of them — without them the `>` of
	/// `</div><span>` and the `/>` of `<Badge /><span>` would take the following `<`
	/// with them and the next tag would never be seen. Splitting the run costs
	/// nothing: both halves are operators either way.
	private static let jsxPrePassRules: [RegexRule] = [
		RegexRule(trigger: ">", pattern: ">(?=</?[A-Za-z])", kind: .operator),
		RegexRule(trigger: "/", pattern: "/>(?=</?[A-Za-z])", kind: .operator),
		RegexRule(trigger: "<", pattern: "</?[A-Za-z][\\w.:-]*(?=[\t />])", kind: .type),
		RegexRule(trigger: "@", pattern: "@\\w+", kind: .punctuationSpecial)
	]
}
