//
//  ThemeFileTests.swift
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

import XCTest
@testable import MopedEditor

/// Decoding takes `Data`, so none of this needs the filesystem or a fixture file.
final class ThemeFileTests: XCTestCase {
	// MARK: - Decoding

	/// The smallest file that loads: the five required chrome colors and nothing else.
	func testMinimalFile() throws {
		let theme = try MopedTheme(data: Self.json(
			"""
			"version": 1, "name": "Tiny",
			"colors": {
				"background": "#FFFFFF", "foreground": "#101010",
				"gutterBackground": "#F5F5F5", "gutterForeground": "#888888",
				"selection": "#BFD7FF"
			}
			"""
		))

		XCTAssertEqual(theme.name, "Tiny")
		XCTAssertNil(theme.darkVariant)
		XCTAssertEqual(theme.background, NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))

		for kind in TokenKind.allCases {
			XCTAssertEqual(
				theme.color(for: kind), theme.foreground,
				"a file with no tokens should leave every kind on the foreground"
			)
		}
	}

	/// `caret` is the one optional chrome color, and omitting it must land on the same
	/// inversion the memberwise initializer applies.
	func testCaretDefaultsToTheInvertedBackground() throws {
		let theme = try MopedTheme(data: Self.json(Self.minimalBody))
		let caret = try XCTUnwrap(theme.caret.usingColorSpace(.sRGB))

		XCTAssertEqual(caret.redComponent, 0, accuracy: 0.001)
		XCTAssertEqual(caret.greenComponent, 0, accuracy: 0.001)
		XCTAssertEqual(caret.blueComponent, 0, accuracy: 0.001)
	}

	func testCaretIsReadWhenPresent() throws {
		let theme = try MopedTheme(data: Self.json(
			"""
			"version": 1, "name": "Tiny",
			"colors": {
				"background": "#FFFFFF", "foreground": "#101010",
				"gutterBackground": "#F5F5F5", "gutterForeground": "#888888",
				"selection": "#BFD7FF", "caret": "#FF0000"
			}
			"""
		))
		XCTAssertEqual(theme.caret, NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
	}

	func testEveryTokenKindCanBeColored() throws {
		let tokens = TokenKind.allCases
			.map { "\"\($0.rawValue)\": \"#123456\"" }
			.joined(separator: ", ")
		let theme = try MopedTheme(data: Self.json(Self.minimalBody + ", \"tokens\": {\(tokens)}"))

		let expected = NSColor(srgbRed: 0x12 / 255, green: 0x34 / 255, blue: 0x56 / 255, alpha: 1)
		for kind in TokenKind.allCases {
			XCTAssertEqual(theme.color(for: kind), expected, "\(kind.rawValue) did not decode")
		}
	}

	/// Forward compatibility: a file written for a later Moped names token kinds this
	/// build has never heard of, and must still load the ones it does know.
	func testUnknownTokenKeysAreIgnored() throws {
		let theme = try MopedTheme(data: Self.json(
			Self.minimalBody + ##", "tokens": {"keyword": "#00FF00", "not.a.real.kind": "#FF00FF"}"##
		))
		XCTAssertEqual(theme.color(for: .keyword), NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1))
	}

	// MARK: - Hex

	func testAcceptedHexForms() throws {
		let cases: [(String, NSColor)] = [
			("#F0A", NSColor(srgbRed: 1, green: 0, blue: 0xAA / 255, alpha: 1)),
			("F0A", NSColor(srgbRed: 1, green: 0, blue: 0xAA / 255, alpha: 1)),
			("#ff00aa", NSColor(srgbRed: 1, green: 0, blue: 0xAA / 255, alpha: 1)),
			("#FF00AA", NSColor(srgbRed: 1, green: 0, blue: 0xAA / 255, alpha: 1)),
			("#FF00AA80", NSColor(srgbRed: 1, green: 0, blue: 0xAA / 255, alpha: 0x80 / 255))
		]

		for (hex, expected) in cases {
			let theme = try MopedTheme(data: Self.json(Self.body(background: hex)))
			XCTAssertEqual(theme.background, expected, "\(hex) did not parse")
		}
	}

	/// An empty value is deliberately absent from this list: it is reported as a missing
	/// key, which is what a user who deleted a color rather than mistyping one expects.
	func testRejectsMalformedHex() {
		for bad in ["#GGGGGG", "#FFFF", "blue", "#1234567"] {
			XCTAssertThrowsError(try MopedTheme(data: Self.json(Self.body(background: bad)))) { error in
				guard case MopedThemeFileError.badColor(let key, _)? = error as? MopedThemeFileError else {
					return XCTFail("\(bad) should be rejected as a bad color, got \(error)")
				}
				XCTAssertEqual(key, "colors.background", "the error should name the offending key")
			}
		}
	}

	// MARK: - Rejections

	func testRejectsMissingRequiredKeys() {
		let bodies: [String: String] = [
			"version": ##""name": "X", "colors": {"background": "#FFFFFF"}"##,
			"name": ##""version": 1, "colors": {"background": "#FFFFFF"}"##,
			"colors": ##""version": 1, "name": "X""##,
			"colors.foreground": ##""version": 1, "name": "X", "colors": {"background": "#FFFFFF"}"##
		]

		for (expectedKey, body) in bodies {
			XCTAssertThrowsError(try MopedTheme(data: Self.json(body))) { error in
				guard case MopedThemeFileError.missingKey(let key)? = error as? MopedThemeFileError else {
					return XCTFail("expected a missingKey error for \(expectedKey), got \(error)")
				}
				XCTAssertEqual(key, expectedKey)
			}
		}
	}

	func testRejectsBlankName() {
		XCTAssertThrowsError(
			try MopedTheme(data: Self.json(##""version": 1, "name": "  ", "colors": {}"##))
		) { error in
			XCTAssertEqual((error as? MopedThemeFileError)?.description, "missing required key \"name\"")
		}
	}

	func testRejectsUnknownVersion() {
		XCTAssertThrowsError(
			try MopedTheme(data: Self.json(##""version": 99, "name": "X", "colors": {}"##))
		) { error in
			guard case MopedThemeFileError.unsupportedVersion(let version)? = error as? MopedThemeFileError else {
				return XCTFail("expected unsupportedVersion, got \(error)")
			}
			XCTAssertEqual(version, 99)
		}
	}

	// MARK: - Dark section

	func testDarkSectionProducesAPairedTheme() throws {
		let theme = try MopedTheme(data: Self.json(
			Self.minimalBody + """
			, "dark": {"colors": {
				"background": "#1E2128", "foreground": "#EAEAEE",
				"gutterBackground": "#262932", "gutterForeground": "#7A7D85",
				"selection": "#3D578C"
			}}
			"""
		))

		let light = try XCTUnwrap(NSAppearance(named: .aqua))
		let dark = try XCTUnwrap(NSAppearance(named: .darkAqua))

		XCTAssertEqual(theme.resolved(for: light).background, NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1))
		XCTAssertEqual(
			theme.resolved(for: dark).background,
			NSColor(srgbRed: 0x1E / 255, green: 0x21 / 255, blue: 0x28 / 255, alpha: 1)
		)
		XCTAssertEqual(theme.resolved(for: dark).name, "Tiny", "both palettes answer to the file's name")
	}

	/// The "same syntax colors, different chrome" case: a `dark` section with no
	/// `tokens` of its own inherits the top-level ones.
	func testDarkSectionInheritsTopLevelTokens() throws {
		let theme = try MopedTheme(data: Self.json(
			Self.minimalBody + """
			, "tokens": {"keyword": "#AA00AA"}
			, "dark": {"colors": {
				"background": "#1E2128", "foreground": "#EAEAEE",
				"gutterBackground": "#262932", "gutterForeground": "#7A7D85",
				"selection": "#3D578C"
			}}
			"""
		))

		let dark = try XCTUnwrap(theme.darkVariant)
		XCTAssertEqual(dark.color(for: .keyword), theme.color(for: .keyword))
	}

	func testDarkSectionTokensOverrideTopLevelOnes() throws {
		let theme = try MopedTheme(data: Self.json(
			Self.minimalBody + """
			, "tokens": {"keyword": "#AA00AA"}
			, "dark": {
				"colors": {
					"background": "#1E2128", "foreground": "#EAEAEE",
					"gutterBackground": "#262932", "gutterForeground": "#7A7D85",
					"selection": "#3D578C"
				},
				"tokens": {"keyword": "#00AAAA"}
			}
			"""
		))

		let dark = try XCTUnwrap(theme.darkVariant)
		XCTAssertEqual(dark.color(for: .keyword), NSColor(srgbRed: 0, green: 0xAA / 255, blue: 0xAA / 255, alpha: 1))
	}

	/// Errors inside `dark` have to be distinguishable from top-level ones, or a
	/// hand-editing user cannot tell which half of the file is wrong.
	func testDarkSectionErrorsNameTheDarkKey() {
		XCTAssertThrowsError(
			try MopedTheme(data: Self.json(Self.minimalBody + ##", "dark": {"colors": {"background": "#000000"}}"##))
		) { error in
			XCTAssertEqual((error as? MopedThemeFileError)?.description, "missing required key \"dark.colors.foreground\"")
		}
	}

	// MARK: - Helpers

	/// The five required chrome colors and nothing else — the baseline every test above
	/// adds its one interesting key to.
	private static let minimalBody = """
		"version": 1, "name": "Tiny",
		"colors": {
			"background": "#FFFFFF", "foreground": "#101010",
			"gutterBackground": "#F5F5F5", "gutterForeground": "#888888",
			"selection": "#BFD7FF"
		}
		"""

	private static func body(background: String) -> String {
		"""
		"version": 1, "name": "Tiny",
		"colors": {
			"background": "\(background)", "foreground": "#101010",
			"gutterBackground": "#F5F5F5", "gutterForeground": "#888888",
			"selection": "#BFD7FF"
		}
		"""
	}

	private static func json(_ body: String) -> Data {
		Data("{\(body)}".utf8)
	}
}

/// Writing is what puts the themes Moped ships into the themes folder, so it is held to
/// the same standard as reading.
final class ThemeFileEncodingTests: XCTestCase {
	/// The themes Moped ships are written to disk through `fileData()`, so a round trip
	/// has to preserve them. Hex quantizes to 1/255, hence the tolerance.
	func testBuiltInThemesSurviveARoundTrip() throws {
		for original in MopedTheme.allBuiltIn {
			let restored = try MopedTheme(data: original.fileData())

			XCTAssertEqual(restored.name, original.name)
			XCTAssertEqual(restored.darkVariant != nil, original.darkVariant != nil)

			try assertSameColors(restored, original)
			if let darkOriginal = original.darkVariant, let darkRestored = restored.darkVariant {
				try assertSameColors(darkRestored, darkOriginal)
			}
		}
	}

	/// Encoding is `sortedKeys`, so the files Moped writes are byte-stable — otherwise
	/// dictionary ordering would rewrite the token list differently on every launch.
	func testEncodingIsDeterministic() throws {
		for theme in MopedTheme.allBuiltIn {
			let once = try theme.fileData()
			XCTAssertEqual(once, try theme.fileData())
			XCTAssertEqual(once, try MopedTheme(data: once).fileData(), "a round trip must be a fixed point")
		}
	}

	/// The `Sendable` contract on `MopedTheme` requires plain component colours. Hex is
	/// the only notation the format accepts, so this holds by construction — this test
	/// is what keeps it that way.
	func testDecodedColorsAreFlattenedToSRGB() throws {
		let theme = try MopedTheme(data: MopedTheme.default.fileData())
		for palette in [theme, try XCTUnwrap(theme.darkVariant)] {
			for color in [
				palette.background, palette.foreground, palette.gutterBackground,
				palette.gutterForeground, palette.selection, palette.caret
			] + Array(palette.tokenColors.values) {
				XCTAssertEqual(color.colorSpace, .sRGB, "\(color) was not flattened to sRGB")
			}
		}
	}

	// MARK: - Helpers

	private func assertSameColors(
		_ restored: MopedTheme, _ original: MopedTheme, file: StaticString = #filePath, line: UInt = #line
	) throws {
		let expected = Self.allColors(of: original)
		let actual = Self.allColors(of: restored)
		XCTAssertEqual(Set(actual.keys), Set(expected.keys), "\(original.name)", file: file, line: line)

		for (key, color) in expected {
			let left = try XCTUnwrap(actual[key]?.usingColorSpace(.sRGB))
			let right = try XCTUnwrap(color.usingColorSpace(.sRGB))
			let leftChannels = [left.redComponent, left.greenComponent, left.blueComponent, left.alphaComponent]
			let rightChannels = [right.redComponent, right.greenComponent, right.blueComponent, right.alphaComponent]

			for (index, channel) in ["red", "green", "blue", "alpha"].enumerated() {
				XCTAssertEqual(
					leftChannels[index], rightChannels[index], accuracy: 1.0 / 255,
					"\(original.name) \(key) \(channel)", file: file, line: line
				)
			}
		}
	}

	private static func allColors(of theme: MopedTheme) -> [String: NSColor] {
		var colors: [String: NSColor] = [
			"background": theme.background,
			"foreground": theme.foreground,
			"gutterBackground": theme.gutterBackground,
			"gutterForeground": theme.gutterForeground,
			"selection": theme.selection,
			"caret": theme.caret
		]
		for (key, color) in theme.tokenColors {
			colors["tokens.\(key)"] = color
		}
		return colors
	}

}
