//
//  MopedTextView+Comments.swift
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

import AppKit

extension MopedTextView {
	/// Comments or uncomments the lines covered by the selection using
	/// `lineCommentMarker`, choosing the direction from whether every non-blank
	/// line is already commented.
	func toggleLineComment() -> Bool {
		guard isEditable else {
			return false
		}
		guard let marker = lineCommentMarker else {
			NSSound.beep()
			return false
		}

		let source = string as NSString
		let originalSelection = selectedRange()
		let lineRange = normalizedLineRange(for: originalSelection, in: source)
		let originalBlock = source.substring(with: lineRange)
		let lines = splitBlockIntoLines(originalBlock)
		let nonEmptyIndices = Set(
			lines.indices.filter { index in
				!lines[index].content.allSatisfy(\.isWhitespace)
			}
		)

		guard !nonEmptyIndices.isEmpty else {
			NSSound.beep()
			return false
		}

		let allCommented = nonEmptyIndices.allSatisfy { idx in
			lines[idx].content.drop(while: { $0 == " " || $0 == "\t" }).hasPrefix(marker)
		}

		let transformedBlock = allCommented
			? uncommentedBlock(lines: lines, nonEmptyIndices: nonEmptyIndices, marker: marker)
			: commentedBlock(lines: lines, nonEmptyIndices: nonEmptyIndices, marker: marker)

		return replaceBlock(
			in: lineRange, with: transformedBlock, original: originalBlock, selection: originalSelection
		)
	}

	private func commentedBlock(
		lines: [(content: String, ending: String)],
		nonEmptyIndices: Set<Int>,
		marker: String
	) -> String {
		let prefix = commonLeadingWhitespace(in: nonEmptyIndices.map { lines[$0].content })
		let insertionOffset = prefix.count
		var result = ""
		for (idx, line) in lines.enumerated() {
			guard nonEmptyIndices.contains(idx) else {
				result += line.content + line.ending
				continue
			}
			let splitAt = line.content.index(line.content.startIndex, offsetBy: insertionOffset)
			result += String(line.content[..<splitAt]) + marker + " " + String(line.content[splitAt...]) + line.ending
		}
		return result
	}

	private func uncommentedBlock(
		lines: [(content: String, ending: String)],
		nonEmptyIndices: Set<Int>,
		marker: String
	) -> String {
		var result = ""
		for (idx, line) in lines.enumerated() {
			guard nonEmptyIndices.contains(idx) else {
				result += line.content + line.ending
				continue
			}
			let leadingCount = line.content.prefix(while: { $0 == " " || $0 == "\t" }).count
			let leadingEnd = line.content.index(line.content.startIndex, offsetBy: leadingCount)
			var rest = String(line.content[leadingEnd...])
			if rest.hasPrefix(marker) {
				rest = String(rest.dropFirst(marker.count))
				if rest.first == " " {
					rest = String(rest.dropFirst())
				}
			}
			result += String(line.content[..<leadingEnd]) + rest + line.ending
		}
		return result
	}

	/// Splits a block into lines paired with their exact terminators, so a rewrite can
	/// reassemble it without normalizing `\r\n` or losing a missing final newline.
	/// Shared with `transformLines` in `MopedTextView+Editing`.
	func splitBlockIntoLines(_ block: String) -> [(content: String, ending: String)] {
		let blockText = block as NSString
		let blockRange = NSRange(location: 0, length: blockText.length)
		var result: [(content: String, ending: String)] = []
		blockText.enumerateSubstrings(
			in: blockRange,
			options: [.byLines, .substringNotRequired]
		) { _, lineRange, enclosingRange, _ in
			let line = blockText.substring(with: lineRange)
			let suffixRange = NSRange(
				location: NSMaxRange(lineRange),
				length: enclosingRange.length - lineRange.length
			)
			let ending = blockText.substring(with: suffixRange)
			result.append((line, ending))
		}
		return result
	}

	private func commonLeadingWhitespace(in lines: [String]) -> String {
		guard let first = lines.first else {
			return ""
		}
		var prefix = String(first.prefix(while: { $0 == " " || $0 == "\t" }))
		for line in lines.dropFirst() {
			var updated = ""
			for (lhs, rhs) in zip(prefix, line) {
				guard lhs == rhs, lhs == " " || lhs == "\t" else {
					break
				}
				updated.append(lhs)
			}
			prefix = updated
			if prefix.isEmpty {
				break
			}
		}
		return prefix
	}
}
