//
//  LineScanner.swift
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

/// Cursor over one line's UTF-16 units with literal- and regex-matching helpers.
struct LineScanner {
	let line: String
	let units: [UInt16]
	var pos: Int = 0

	init(line: String) {
		self.line = line
		self.units = Array(line.utf16)
	}

	var count: Int { units.count }
	var isAtEnd: Bool { pos >= units.count }
	var current: UInt16 { units[pos] }

	func unit(at index: Int) -> UInt16? {
		guard index >= 0 && index < units.count else {
			return nil
		}
		return units[index]
	}

	func matches(_ literal: [UInt16], at index: Int) -> Bool {
		guard !literal.isEmpty, index >= 0, index + literal.count <= units.count else {
			return false
		}
		for (offset, unit) in literal.enumerated() where units[index + offset] != unit {
			return false
		}
		return true
	}

	func matches(_ literal: [UInt16]) -> Bool {
		matches(literal, at: pos)
	}

	/// Anchored regex match starting at `index`.
	func matchRegex(_ regex: NSRegularExpression, at index: Int) -> NSTextCheckingResult? {
		let searchRange = NSRange(location: index, length: units.count - index)
		return regex.firstMatch(in: line, options: [.anchored], range: searchRange)
	}

	/// Unanchored regex match over the whole line (for `.lineStart` rules whose
	/// patterns carry their own `^`).
	func matchLineRegex(_ regex: NSRegularExpression) -> NSTextCheckingResult? {
		regex.firstMatch(in: line, range: NSRange(location: 0, length: units.count))
	}

	/// Next non-whitespace unit at or after `index`.
	func nextNonSpace(from index: Int) -> UInt16? {
		var cursor = index
		while cursor < units.count {
			let unit = units[cursor]
			if unit != UnicodeScalars.space && unit != UnicodeScalars.tab {
				return unit
			}
			cursor += 1
		}
		return nil
	}

	/// Previous non-whitespace unit strictly before `index`.
	func previousNonSpace(before index: Int) -> UInt16? {
		var cursor = index - 1
		while cursor >= 0 {
			let unit = units[cursor]
			if unit != UnicodeScalars.space && unit != UnicodeScalars.tab {
				return unit
			}
			cursor -= 1
		}
		return nil
	}

	func substring(in range: NSRange) -> String {
		String(utf16CodeUnits: Array(units[range.location..<range.location + range.length]), count: range.length)
	}
}

enum UnicodeScalars {
	static let space: UInt16 = 0x20
	static let tab: UInt16 = 0x09
	static let dot: UInt16 = 0x2E
	static let openParen: UInt16 = 0x28
	static let questionMark: UInt16 = 0x3F
	static let greaterThan: UInt16 = 0x3E
	static let lessThan: UInt16 = 0x3C
}

func isDigitUnit(_ unit: UInt16) -> Bool {
	unit >= 0x30 && unit <= 0x39
}

func isUppercaseLetterUnit(_ unit: UInt16) -> Bool {
	unit >= 0x41 && unit <= 0x5A
}

func isLetterUnit(_ unit: UInt16) -> Bool {
	(unit >= 0x41 && unit <= 0x5A) || (unit >= 0x61 && unit <= 0x7A)
}

/// Identifier start: ASCII letter, underscore, or any non-ASCII unit (keeps Unicode
/// identifiers whole without full Unicode classification).
func isIdentifierStartUnit(_ unit: UInt16) -> Bool {
	isLetterUnit(unit) || unit == 0x5F || unit > 0x7F
}

func isIdentifierContinueUnit(_ unit: UInt16) -> Bool {
	isIdentifierStartUnit(unit) || isDigitUnit(unit)
}
