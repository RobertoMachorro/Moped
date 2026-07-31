//
//  DocumentTokenizer.swift
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

import Foundation

/// Whole-document tokenization: splits into lines, threads carry state, and maps
/// line-relative token ranges into document coordinates. Used for initial passes and
/// as the reference implementation the incremental `LineStore` is tested against.
public enum DocumentTokenizer {
	public static func tokenize(_ text: String, using tokenizer: any LineTokenizer) -> [Token] {
		let nsText = text as NSString
		var tokens: [Token] = []
		var state = tokenizer.initialState
		var location = 0
		while location < nsText.length {
			var lineStart = 0
			var lineEnd = 0
			var contentsEnd = 0
			nsText.getLineStart(
				&lineStart, end: &lineEnd, contentsEnd: &contentsEnd,
				for: NSRange(location: location, length: 0)
			)
			let content = nsText.substring(with: NSRange(location: lineStart, length: contentsEnd - lineStart))
			let (lineTokens, carryOut) = tokenizer.tokenize(line: content, carryIn: state)
			for var token in lineTokens {
				token.range.location += lineStart
				tokens.append(token)
			}
			state = carryOut
			location = lineEnd
		}
		return tokens
	}
}
