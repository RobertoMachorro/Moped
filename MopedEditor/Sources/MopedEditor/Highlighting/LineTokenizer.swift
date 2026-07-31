//
//  LineTokenizer.swift
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

/// A tokenizer that processes one line at a time, threading a `LineState` between
/// lines. `line` never contains the line terminator; token ranges are UTF-16 offsets
/// relative to the start of the line.
public protocol LineTokenizer: Sendable {
	/// Carry-in state for the first line of a document (`.none` for most languages,
	/// `.rawOutside` for PHP).
	var initialState: LineState { get }

	func tokenize(line: String, carryIn: LineState) -> (tokens: [Token], carryOut: LineState)
}

extension LineTokenizer {
	public var initialState: LineState { .none }
}
