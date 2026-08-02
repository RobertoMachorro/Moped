//
//  TokenKind.swift
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

/// The token vocabulary of the highlighter. Raw values match the tree-sitter capture
/// names the theme `tokenColors` dictionaries have always been keyed by, so the
/// existing themes port unchanged.
public enum TokenKind: String, CaseIterable, Sendable {
	case plain
	case boolean
	case comment
	case constructor
	/// Added and removed lines in a patch. Themes are expected to color these
	/// green and red — without the contrast a diff reads no better than plain text.
	case diffPlus = "diff.plus"
	case diffMinus = "diff.minus"
	case functionCall = "function.call"
	case include
	case keyword
	case keywordFunction = "keyword.function"
	case keywordReturn = "keyword.return"
	case method
	case number
	case `operator`
	case parameter
	case punctuationSpecial = "punctuation.special"
	case string
	case textLiteral = "text.literal"
	case textTitle = "text.title"
	case type
	case variableBuiltin = "variable.builtin"
	case variable
}
