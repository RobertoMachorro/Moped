//
//  SafeCodeAttributedString.swift
//
//  Moped - A general purpose text editor, small and light.
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
import Highlightr

/// Guards against out-of-bounds attribute lookups triggered by AppKit/layout timing.
final class SafeCodeAttributedString: CodeAttributedString {
	private static let largeInsertCorrectionThreshold = 1024
	private static let fullRehighlightThreshold = 2048
	private static let fullRehighlightMultilineThreshold = 256

	override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
		let length = self.length
		guard length > 0 else {
			range?.pointee = NSRange(location: 0, length: 0)
			return [:]
		}

		let safeLocation = min(max(location, 0), length - 1)
		return super.attributes(at: safeLocation, effectiveRange: range)
	}

	override func replaceCharacters(in range: NSRange, with str: String) {
		super.replaceCharacters(in: range, with: str)

		let insertedLength = (str as NSString).length
		guard insertedLength > 0 else { return }
		let delta = insertedLength - range.length

		// Highlightr reports insertion edits using the pre-edit range (often zero-length),
		// which can limit highlighting to one paragraph. For large or multi-line inserts,
		// emit a corrected character-edit notification so processEditing can rehighlight
		// the full inserted block.
		let shouldCorrect = insertedLength >= Self.largeInsertCorrectionThreshold || str.contains("\n")
		guard shouldCorrect else { return }

		let correctedRange = NSRange(location: range.location, length: insertedLength)
		edited(.editedCharacters, range: correctedRange, changeInLength: 0)

		// Fallback for large/medium multi-line pastes: force a full-document rehighlight
		// because Highlightr incremental range tracking can still miss parts of the insert.
		let shouldForceFullRehighlight = insertedLength >= Self.fullRehighlightThreshold ||
			(str.contains("\n") && insertedLength >= Self.fullRehighlightMultilineThreshold)
		if shouldForceFullRehighlight, let currentLanguage = language {
			DispatchQueue.main.async { [weak self] in
				guard let self else { return }
				self.language = currentLanguage
			}
		}
	}
}
