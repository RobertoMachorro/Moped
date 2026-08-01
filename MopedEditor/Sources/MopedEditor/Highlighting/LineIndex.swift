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

	/// Line starts after an edit, without rescanning the whole document.
	///
	/// Offsets below the edit are untouched, the edited span is rescanned, and the tail
	/// is shifted by `changeInLength`. That last step is still proportional to the line
	/// count, so this is a constant-factor win rather than a complexity change: an
	/// integer add over a contiguous array instead of a `getLineStart` walk over every
	/// character in the document.
	///
	/// - Parameters:
	///   - starts: line starts for the text as it was *before* the edit.
	///   - newText: the text after the edit.
	///   - editedRange: edited range in `newText` coordinates, as
	///     `NSTextStorage.didProcessEditing` reports it.
	///   - changeInLength: `newText.length` minus the old length.
	static func splice(
		_ starts: [Int], in newText: NSString, editedRange: NSRange, changeInLength: Int
	) -> [Int] {
		let result = spliced(starts, in: newText, editedRange: editedRange, changeInLength: changeInLength)
		// Debug-only cross-check against the reference implementation. The randomized
		// edits in IncrementalConsistencyTests run through here, so any divergence trips
		// there rather than as a subtle mis-highlight. It makes splicing O(document) in
		// Debug builds — the speedup is a Release-only effect.
		assert(result == lineStarts(of: newText), "splice diverged from a full recompute")
		return result
	}

	/// The splice itself, without the debug cross-check. Tests call this directly so a
	/// mismatch is reported by the assertion in the test rather than trapping here.
	static func spliced(
		_ starts: [Int], in newText: NSString, editedRange: NSRange, changeInLength: Int
	) -> [Int] {
		// Offsets below the edit keep their values, so the pre-edit array can be indexed
		// with a post-edit location. Their line *starts* are another matter: deleting
		// between a lone CR and a following LF fuses them into one CRLF terminator and
		// removes a line start that sits before the edit. Backing up one line puts any
		// such CR inside the rescanned span. A terminator is at most two units, so one
		// line is always enough.
		let firstAffected = index(containing: editedRange.location, in: starts)
		let rescanFrom = max(firstAffected - 1, 0)
		var result = Array(starts[...rescanFrom])

		// Rescan from there until reaching a line start whose preceding terminator lies
		// beyond the edit, and so is unchanged text.
		let editEnd = NSMaxRange(editedRange)
		var location = starts[rescanFrom]
		var resume: Int?
		while location < newText.length {
			var lineStart = 0
			var lineEnd = 0
			var contentsEnd = 0
			newText.getLineStart(
				&lineStart, end: &lineEnd, contentsEnd: &contentsEnd,
				for: NSRange(location: location, length: 0)
			)
			guard lineEnd < newText.length else {
				break
			}
			result.append(lineEnd)
			if lineEnd > editEnd {
				resume = lineEnd
				break
			}
			location = lineEnd
		}

		// From `resume` on, the text is untouched: reuse the old starts, shifted.
		guard let resume else {
			return result
		}
		let resumeOld = resume - changeInLength
		var index = index(containing: resumeOld, in: starts) + 1
		while index < starts.count {
			result.append(starts[index] + changeInLength)
			index += 1
		}
		return result
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
