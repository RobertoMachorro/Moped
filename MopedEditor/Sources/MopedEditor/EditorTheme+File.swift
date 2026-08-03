//
//  EditorTheme+File.swift
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

/// Why a `.mopedtheme` file could not be read. Every case names the exact spot in the
/// file, because the person who has to act on it is hand-editing JSON in a text editor.
public enum MopedThemeFileError: Error, CustomStringConvertible {
	/// Dotted path of a required key that was absent or empty, e.g. `colors.background`.
	case missingKey(String)
	case badColor(key: String, value: String)
	case unsupportedVersion(Int)

	public var description: String {
		switch self {
		case .missingKey(let key):
			return "missing required key \"\(key)\""
		case .badColor(let key, let value):
			return "\"\(key)\" is not a hex color: \"\(value)\""
		case .unsupportedVersion(let version):
			return "unsupported format version \(version)"
		}
	}
}

/// On-disk shape of a `.mopedtheme`. Colors stay as raw strings here so that a bad or
/// absent one is reported by the checks below, naming the key, rather than as a generic
/// decoding failure.
private struct MopedThemeFile: Codable {
	struct Palette: Codable {
		var colors: [String: String]?
		var tokens: [String: String]?
	}

	var version: Int?
	var name: String?
	var colors: [String: String]?
	var tokens: [String: String]?
	var dark: Palette?
}

extension MopedTheme {
	/// The only schema version Moped understands. A file declaring anything else is
	/// refused outright rather than half-read.
	public static let fileFormatVersion = 1

	public static let fileExtension = "mopedtheme"

	/// Chrome colors a file must carry. `caret` is deliberately absent: it defaults to
	/// the inverse of the background, the same as in the memberwise initializer.
	private static let requiredColorKeys = [
		"background", "foreground", "gutterBackground", "gutterForeground", "selection"
	]

	/// Reads a `.mopedtheme`.
	///
	/// A file with a `dark` section becomes a paired theme following the effective
	/// appearance; the top level is then the light palette. A `dark` section without its
	/// own `tokens` inherits the top-level ones, which is the common "same syntax
	/// colors, different chrome" case.
	public init(data: Data) throws {
		let file = try JSONDecoder().decode(MopedThemeFile.self, from: data)

		guard let version = file.version else {
			throw MopedThemeFileError.missingKey("version")
		}
		guard version == Self.fileFormatVersion else {
			throw MopedThemeFileError.unsupportedVersion(version)
		}
		guard let name = file.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
			throw MopedThemeFileError.missingKey("name")
		}

		let light = try MopedTheme(
			name: name, colors: file.colors, tokens: file.tokens, path: ""
		)

		guard let dark = file.dark else {
			self = light
			return
		}
		let darkTheme = try MopedTheme(
			name: name, colors: dark.colors, tokens: dark.tokens ?? file.tokens, path: "dark."
		)
		self = light.paired(withDark: darkTheme)
	}

	/// Builds one palette. `path` prefixes the keys in any error so `dark` failures are
	/// distinguishable from top-level ones.
	private init(name: String, colors: [String: String]?, tokens: [String: String]?, path: String) throws {
		guard let colors, !colors.isEmpty else {
			throw MopedThemeFileError.missingKey("\(path)colors")
		}

		func required(_ key: String) throws -> NSColor {
			guard let raw = colors[key], !raw.isEmpty else {
				throw MopedThemeFileError.missingKey("\(path)colors.\(key)")
			}
			return try Self.color(fromHex: raw, key: "\(path)colors.\(key)")
		}

		var resolvedTokens: [String: NSColor] = [:]
		// Unknown keys are skipped rather than rejected: a file written for a later
		// Moped, with token kinds this build has never heard of, still loads.
		let known = Set(TokenKind.allCases.map(\.rawValue))
		for (key, raw) in tokens ?? [:] where known.contains(key) {
			resolvedTokens[key] = try Self.color(fromHex: raw, key: "\(path)tokens.\(key)")
		}

		self.init(
			name: name,
			background: try required("background"),
			foreground: try required("foreground"),
			gutterBackground: try required("gutterBackground"),
			gutterForeground: try required("gutterForeground"),
			selection: try required("selection"),
			caret: try colors["caret"].map { try Self.color(fromHex: $0, key: "\(path)colors.caret") },
			tokenColors: resolvedTokens
		)
	}

	/// Serializes back to `.mopedtheme` bytes. This is what writes the themes Moped
	/// ships into the themes folder, so the files on disk are generated from the same
	/// palettes the editor falls back to rather than being a second copy to keep in sync.
	///
	/// Output is `sortedKeys` so a given theme always produces byte-identical data —
	/// dictionaries would otherwise scramble the token list on every run.
	public func fileData() throws -> Data {
		let encoder = JSONEncoder()
		encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
		let file = MopedThemeFile(
			version: Self.fileFormatVersion,
			name: name,
			colors: Self.colorStrings(of: self),
			tokens: Self.tokenStrings(of: self),
			dark: darkVariant.map {
				MopedThemeFile.Palette(colors: Self.colorStrings(of: $0), tokens: Self.tokenStrings(of: $0))
			}
		)
		return try encoder.encode(file)
	}

	private static func colorStrings(of theme: MopedTheme) -> [String: String] {
		[
			"background": hex(theme.background),
			"foreground": hex(theme.foreground),
			"gutterBackground": hex(theme.gutterBackground),
			"gutterForeground": hex(theme.gutterForeground),
			"selection": hex(theme.selection),
			"caret": hex(theme.caret)
		]
	}

	private static func tokenStrings(of theme: MopedTheme) -> [String: String] {
		theme.tokenColors.mapValues(hex)
	}

	// MARK: - Hex

	/// Accepts `#RGB`, `#RRGGBB` and `#RRGGBBAA`, with or without the leading `#`, in
	/// either case. Hex is the only accepted notation, which is also what keeps the
	/// `Sendable` promise on `MopedTheme`: there is no spelling of a dynamic or catalog
	/// colour a file could reach for.
	private static func color(fromHex hex: String, key: String) throws -> NSColor {
		let digits = hex.trimmingCharacters(in: .whitespaces).hasPrefix("#")
			? String(hex.trimmingCharacters(in: .whitespaces).dropFirst())
			: hex.trimmingCharacters(in: .whitespaces)

		guard digits.allSatisfy(\.isHexDigit), let value = UInt64(digits, radix: 16) else {
			throw MopedThemeFileError.badColor(key: key, value: hex)
		}

		func channel(_ shift: UInt64) -> CGFloat {
			CGFloat((value >> shift) & 0xFF) / 255
		}

		switch digits.count {
		case 3:
			// #RGB expands each digit, so #F0A means #FF00AA.
			func nibble(_ shift: UInt64) -> CGFloat {
				let digit = (value >> shift) & 0xF
				return CGFloat(digit << 4 | digit) / 255
			}
			return NSColor(srgbRed: nibble(8), green: nibble(4), blue: nibble(0), alpha: 1)
		case 6:
			return NSColor(srgbRed: channel(16), green: channel(8), blue: channel(0), alpha: 1)
		case 8:
			return NSColor(
				srgbRed: channel(24), green: channel(16), blue: channel(8), alpha: channel(0)
			)
		default:
			throw MopedThemeFileError.badColor(key: key, value: hex)
		}
	}

	/// Emits the alpha channel only when the colour is not opaque, so the common case
	/// stays a familiar six-digit value.
	private static func hex(_ color: NSColor) -> String {
		guard let rgb = color.usingColorSpace(.sRGB) else {
			return "#000000"
		}
		func channel(_ value: CGFloat) -> Int {
			Int((value * 255).rounded())
		}
		let base = String(
			format: "#%02X%02X%02X",
			channel(rgb.redComponent), channel(rgb.greenComponent), channel(rgb.blueComponent)
		)
		guard rgb.alphaComponent < 1 else {
			return base
		}
		return base + String(format: "%02X", channel(rgb.alphaComponent))
	}
}
