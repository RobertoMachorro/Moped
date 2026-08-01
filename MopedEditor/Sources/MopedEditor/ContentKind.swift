//
//  ContentKind.swift
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
//  Moped is a text-only editor, but the decoders it relies on are not a filter:
//  `NSString.stringEncoding(for:)` will happily label a HEIC image as Cyrillic text,
//  and `.macOSRoman` maps all 256 byte values so it decodes literally anything. A
//  file that gets in this way renders as mojibake and, worse, is re-encoded over the
//  original on save. This is the gate that keeps binary out.
//

import Foundation

/// Whether a blob of bytes looks like text Moped should open.
public enum ContentKind: Sendable {
	case text
	case binary

	/// Bytes inspected before deciding, matching the window git uses. Content past
	/// this point is not examined, so a file whose only NUL sits beyond it reads as
	/// text — the cost of not scanning multi-megabyte files on every open.
	static let inspectionWindow = 8_192

	/// Share of control bytes above which the window is treated as binary. Well above
	/// anything real text produces, so escape-sequence-heavy files still open.
	static let maxControlByteRatio = 0.3

	public static func of(_ data: Data) -> ContentKind {
		guard !data.isEmpty else {
			return .text
		}

		// A UTF-16/UTF-32 byte-order mark has to settle it before anything else:
		// those encodings pad ASCII with NUL bytes, so the scan below would read
		// perfectly good text as binary.
		if hasWideByteOrderMark(data) {
			return .text
		}

		let window = data.prefix(inspectionWindow)
		if window.contains(0) {
			return .binary
		}
		return controlByteRatio(of: window) > maxControlByteRatio ? .binary : .text
	}

	/// True for a UTF-16 or UTF-32 BOM. A UTF-8 BOM is deliberately not included —
	/// UTF-8 text contains no NUL bytes, so it needs no exemption from the scan.
	private static func hasWideByteOrderMark(_ data: Data) -> Bool {
		let bytes = Array(data.prefix(4))
		guard bytes.count >= 2 else {
			return false
		}
		// UTF-32 first: its LE mark starts with the same two bytes as UTF-16 LE.
		if bytes.count >= 4 {
			if bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF {
				return true
			}
			if bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00 {
				return true
			}
		}
		return (bytes[0] == 0xFF && bytes[1] == 0xFE) || (bytes[0] == 0xFE && bytes[1] == 0xFF)
	}

	/// Share of C0 control bytes, excluding the whitespace real text uses and
	/// counting DEL. Catches NUL-free binaries that the scan above misses.
	private static func controlByteRatio(of window: Data) -> Double {
		guard !window.isEmpty else {
			return 0
		}
		let controls = window.reduce(into: 0) { total, byte in
			switch byte {
			case 0x09, 0x0A, 0x0B, 0x0C, 0x0D:
				break
			case ..<0x20, 0x7F:
				total += 1
			default:
				break
			}
		}
		return Double(controls) / Double(window.count)
	}
}
