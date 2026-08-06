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

	/// A UTF-16 file with no byte-order mark, and which of the two byte orders it is.
	/// `TextFileModel` needs the same answer this type works out, because nothing else in
	/// the decoding chain can tell: UTF-8 fails on these bytes and Mac OS Roman "succeeds"
	/// by turning every other character into a NUL.
	public enum WideEncoding: Sendable {
		case utf16LittleEndian
		case utf16BigEndian

		public var stringEncoding: String.Encoding {
			switch self {
			case .utf16LittleEndian: return .utf16LittleEndian
			case .utf16BigEndian: return .utf16BigEndian
			}
		}
	}

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

		// Same problem without the mark. Such a file used to be refused as binary, which
		// is a confusing thing to be told about a perfectly ordinary text file.
		if unmarkedWideEncoding(of: data) != nil {
			return .text
		}

		let window = data.prefix(inspectionWindow)
		if window.contains(0) {
			return .binary
		}
		return controlByteRatio(of: window) > maxControlByteRatio ? .binary : .text
	}

	/// Detects BOM-less UTF-16 holding mostly-ASCII text, where every character contributes
	/// one NUL and they all land on the same parity of byte offset. Real binaries scatter
	/// their NULs, so requiring *every* NUL in the window to share a parity — and requiring
	/// enough of them to rule out coincidence — keeps this from claiming arbitrary data.
	///
	/// Returns nil for anything it is not confident about, which then falls through to the
	/// ordinary binary scan.
	public static func unmarkedWideEncoding(of data: Data) -> WideEncoding? {
		let window = Array(data.prefix(inspectionWindow))
		// Two full UTF-16 code units, and an odd length cannot be UTF-16 at all.
		guard window.count >= 4, window.count % 2 == 0 else {
			return nil
		}

		var zerosAtEven = 0
		var zerosAtOdd = 0
		for (index, byte) in window.enumerated() where byte == 0 {
			if index % 2 == 0 {
				zerosAtEven += 1
			} else {
				zerosAtOdd += 1
			}
		}
		guard zerosAtEven == 0 || zerosAtOdd == 0 else {
			return nil
		}

		// Every ASCII character in UTF-16 is one NUL plus one non-NUL, so a text file is
		// close to a quarter NUL bytes overall. Well below half, to leave room for
		// non-ASCII characters, which contribute no NUL at all.
		let zeros = zerosAtEven + zerosAtOdd
		guard Double(zeros) / Double(window.count) >= 0.2 else {
			return nil
		}

		// Parity alone is not enough: `01 00 01 00 …` satisfies it and is not text. The
		// bytes carrying the actual characters have to look like characters, so hold them to
		// the same control-byte limit the plain scan uses.
		let characterBytes = Data(window.enumerated().compactMap { index, byte in
			(index % 2 == 0) == (zerosAtOdd > 0) ? byte : nil
		})
		guard controlByteRatio(of: characterBytes) <= maxControlByteRatio else {
			return nil
		}

		// The NULs are the high bytes: at odd offsets that is little-endian.
		return zerosAtOdd > 0 ? .utf16LittleEndian : .utf16BigEndian
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
