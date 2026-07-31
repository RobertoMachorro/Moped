//
//  Token.swift
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

/// A single highlighted run. Ranges are UTF-16 offsets — relative to the line when
/// produced by a `LineTokenizer`, relative to the document once mapped by
/// `DocumentTokenizer`/`LineStore`.
public struct Token: Equatable, Sendable {
	public let kind: TokenKind
	public var range: NSRange

	public init(kind: TokenKind, range: NSRange) {
		self.kind = kind
		self.range = range
	}
}
