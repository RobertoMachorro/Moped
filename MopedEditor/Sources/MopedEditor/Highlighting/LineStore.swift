//
//  LineStore.swift
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

/// Incremental highlighting state: per-line carry-out states plus line offsets.
/// After an edit, only lines from the first dirty line until the carry state
/// stabilizes are re-tokenized.
public struct LineStore {
	let tokenizer: any LineTokenizer
	private var lineStarts: [Int] = [0]
	/// Carry-out state per line; nil marks a line that needs re-tokenizing.
	private var carryOuts: [LineState?] = [nil]
	/// Number of nil entries in `carryOuts`, maintained rather than recounted so
	/// `hasDirtyLines` (checked after every pass) doesn't scan the whole document.
	private var dirtyCount = 1

	public init(tokenizer: any LineTokenizer) {
		self.tokenizer = tokenizer
	}

	/// Full reset: every line becomes dirty. Call on load and on language change.
	public mutating func reset(text: NSString) {
		lineStarts = LineIndex.lineStarts(of: text)
		carryOuts = Array(repeating: nil, count: lineStarts.count)
		dirtyCount = carryOuts.count
	}

	/// Splices line bookkeeping after an edit. `editedRange` is the post-edit range
	/// (as reported by `NSTextStorage.didProcessEditing`).
	public mutating func noteEdit(in newText: NSString, editedRange: NSRange) {
		let newStarts = LineIndex.lineStarts(of: newText)
		let lineDelta = newStarts.count - lineStarts.count
		let firstDirty = LineIndex.index(containing: editedRange.location, in: newStarts)
		let lastDirty = LineIndex.index(containing: max(editedRange.location, NSMaxRange(editedRange) - 1), in: newStarts)

		var newCarryOuts: [LineState?] = []
		newCarryOuts.reserveCapacity(newStarts.count)
		newCarryOuts.append(contentsOf: carryOuts.prefix(min(firstDirty, carryOuts.count)))
		while newCarryOuts.count < min(lastDirty + 1, newStarts.count) {
			newCarryOuts.append(nil)
		}
		var oldIndex = lastDirty + 1 - lineDelta
		while newCarryOuts.count < newStarts.count {
			newCarryOuts.append(oldIndex >= 0 && oldIndex < carryOuts.count ? carryOuts[oldIndex] : nil)
			oldIndex += 1
		}

		lineStarts = newStarts
		carryOuts = newCarryOuts
		dirtyCount = newCarryOuts.reduce(0) { $1 == nil ? $0 + 1 : $0 }
	}

	/// True when at least one line still needs tokenizing.
	public var hasDirtyLines: Bool {
		assert(
			dirtyCount == carryOuts.reduce(0, { $1 == nil ? $0 + 1 : $0 }),
			"dirtyCount drifted from carryOuts"
		)
		return dirtyCount > 0
	}

	/// Re-tokenizes dirty regions until carry states stabilize, processing at most
	/// `limit` lines so a large cascade can be spread over several runloop turns
	/// (leftover lines stay dirty). Returns the document range that must be
	/// recolored and its tokens (document coordinates), or nil when nothing is dirty.
	public mutating func highlightPass(text: NSString, limit: Int = .max) -> (recolored: NSRange, tokens: [Token])? {
		guard carryOuts.count == lineStarts.count else {
			reset(text: text)
			return highlightPass(text: text, limit: limit)
		}
		var tokens: [Token] = []
		var recoloredStart = Int.max
		var recoloredEnd = 0
		var processed = 0

		var index = 0
		while processed < limit, let dirty = carryOuts[index...].firstIndex(where: { $0 == nil }) {
			index = dirty
			var state = dirty == 0 ? tokenizer.initialState : (carryOuts[dirty - 1] ?? tokenizer.initialState)
			while index < lineStarts.count {
				let content = lineContentRange(at: index, in: text)
				let previous = carryOuts[index]
				let (lineTokens, carryOut) = tokenizer.tokenize(line: text.substring(with: content), carryIn: state)
				for var token in lineTokens {
					token.range.location += content.location
					tokens.append(token)
				}
				if previous == nil {
					dirtyCount -= 1
				}
				carryOuts[index] = carryOut
				recoloredStart = min(recoloredStart, lineStarts[index])
				recoloredEnd = max(recoloredEnd, lineEnd(at: index, in: text))
				state = carryOut
				index += 1
				processed += 1
				if let previous, previous == carryOut {
					break
				}
				if processed >= limit {
					break
				}
			}
			if index >= lineStarts.count {
				break
			}
		}

		guard recoloredStart < Int.max else {
			return nil
		}
		let range = NSRange(location: recoloredStart, length: recoloredEnd - recoloredStart)
		return (range, tokens)
	}
}

// MARK: - Line geometry

private extension LineStore {
	/// End of the line including its terminator.
	func lineEnd(at index: Int, in text: NSString) -> Int {
		index + 1 < lineStarts.count ? lineStarts[index + 1] : text.length
	}

	/// Content range of the line, excluding the terminator.
	func lineContentRange(at index: Int, in text: NSString) -> NSRange {
		let start = lineStarts[index]
		var end = lineEnd(at: index, in: text)
		// Strip \n, \r, \r\n, or Unicode separators from the end.
		if end > start {
			let last = text.character(at: end - 1)
			if last == 0x0A {
				end -= 1
				if end > start && text.character(at: end - 1) == 0x0D {
					end -= 1
				}
			} else if last == 0x0D || last == 0x2028 || last == 0x2029 || last == 0x85 {
				end -= 1
			}
		}
		return NSRange(location: start, length: end - start)
	}
}
