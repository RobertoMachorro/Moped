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
	override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
		let length = self.length
		guard length > 0 else {
			range?.pointee = NSRange(location: 0, length: 0)
			return [:]
		}

		let safeLocation = min(max(location, 0), length - 1)
		return super.attributes(at: safeLocation, effectiveRange: range)
	}
}
