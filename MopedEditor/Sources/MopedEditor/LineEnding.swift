//
//  LineEnding.swift
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
//  Lives in the editor package rather than beside the document model so it can be tested:
//  every operation here is a trap for Swift's grapheme-cluster string semantics, where
//  "\r\n" is one Character and so does not contain "\r" at all.
//

import Foundation

/// How a document separates its lines on disk.
///
/// The editor works exclusively in `\n`: a file is normalized on read and converted back on
/// write. Anything else means a Windows file gains a stray `\n` for every line the user
/// types, because the text view has no notion of the file's convention and always inserts
/// `\n` — which is the mixed-endings bug this type exists to prevent.
public enum LineEnding: String, CaseIterable, Identifiable, Sendable {
	case unix = "\n"
	case windows = "\r\n"
	case classicMac = "\r"

	public var id: String { rawValue }

	/// Not localized, deliberately: these are the names the formats go by everywhere, the
	/// same reasoning that leaves the language picker showing `swift` and `cpp`.
	public var displayName: String {
		switch self {
		case .unix: return "LF"
		case .windows: return "CRLF"
		case .classicMac: return "CR"
		}
	}

	/// The convention the majority of `text`'s existing breaks follow. A file with none —
	/// empty, or a single line — is LF, which is also what a new document gets.
	///
	/// Counts UTF-16 units rather than `Character`s on purpose: a `\r\n` pair is a single
	/// grapheme cluster, so iterating Characters cannot tell it from a lone `\r`.
	public static func detected(in text: String) -> LineEnding {
		let nsText = text as NSString
		var crlfCount = 0
		var lfCount = 0
		var crCount = 0
		var index = 0
		while index < nsText.length {
			switch nsText.character(at: index) {
			case 0x0D:
				if index + 1 < nsText.length && nsText.character(at: index + 1) == 0x0A {
					crlfCount += 1
					index += 1
				} else {
					crCount += 1
				}
			case 0x0A:
				lfCount += 1
			default:
				break
			}
			index += 1
		}
		if crlfCount > 0 && crlfCount >= lfCount && crlfCount >= crCount {
			return .windows
		}
		return crCount > lfCount ? .classicMac : .unix
	}

	/// Rewrites every break as `\n`, leaving `text` untouched when there is nothing to do —
	/// the common case, and worth not allocating a copy of a 16 MB document for.
	///
	/// The early-out tests UTF-16 units because `text.contains("\r")` is **false** for a
	/// string full of `\r\n`: Swift matches whole grapheme clusters, and `\r\n` is one. That
	/// mistake shipped a normalization that silently did nothing and wrote `\r\r\n` back.
	public static func normalizedToLF(_ text: String) -> String {
		guard text.utf16.contains(0x0D) else {
			return text
		}
		let mutable = NSMutableString(string: text)
		mutable.replaceOccurrences(
			of: "\r\n", with: "\n", options: .literal,
			range: NSRange(location: 0, length: mutable.length)
		)
		mutable.replaceOccurrences(
			of: "\r", with: "\n", options: .literal,
			range: NSRange(location: 0, length: mutable.length)
		)
		return mutable as String
	}

	/// Rewrites `\n` back to this convention for writing. `.literal` and `NSMutableString`
	/// again, for the same grapheme reason as above.
	public func applied(to text: String) -> String {
		guard self != .unix else {
			return text
		}
		let mutable = NSMutableString(string: text)
		mutable.replaceOccurrences(
			of: "\n", with: rawValue, options: .literal,
			range: NSRange(location: 0, length: mutable.length)
		)
		return mutable as String
	}
}
