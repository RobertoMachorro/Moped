//
//  LineIndex.swift
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

/// Character offsets of line starts, and the lookup back from an offset to a line.
/// Shared by the highlighter's `LineStore` and the gutter's `LineNumberRulerView`,
/// which previously carried identical private copies of both routines.
enum LineIndex {
	/// Offsets where each line begins. Always starts with 0, so a document with no
	/// line breaks (including an empty one) yields `[0]`. A trailing terminator does
	/// not produce a phantom final entry.
	static func lineStarts(of text: NSString) -> [Int] {
		var starts: [Int] = [0]
		var location = 0
		while location < text.length {
			var lineStart = 0
			var lineEnd = 0
			var contentsEnd = 0
			text.getLineStart(
				&lineStart, end: &lineEnd, contentsEnd: &contentsEnd,
				for: NSRange(location: location, length: 0)
			)
			if lineEnd < text.length {
				starts.append(lineEnd)
			}
			location = lineEnd
		}
		return starts
	}

	/// Index of the line containing `location`, clamped to the last line. `starts` must
	/// be ascending, as produced by `lineStarts(of:)`.
	static func index(containing location: Int, in starts: [Int]) -> Int {
		var low = 0
		var high = starts.count - 1
		while low < high {
			let mid = (low + high + 1) / 2
			if starts[mid] <= location {
				low = mid
			} else {
				high = mid - 1
			}
		}
		return low
	}
}
