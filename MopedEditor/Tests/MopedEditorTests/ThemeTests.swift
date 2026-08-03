//
//  ThemeTests.swift
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

final class ThemeTests: XCTestCase {
	func testBuiltInThemes() {
		XCTAssertEqual(MopedTheme.allBuiltIn.count, 3)
		XCTAssertEqual(MopedTheme.allNames, ["Default", "Solarized", "Xcode-like"])
		XCTAssertEqual(MopedTheme.defaultName, "Default")
	}

	/// Every shipped theme carries both appearances. Xcode-like is the one worth
	/// asserting by name: it is the default, so a regression here means the
	/// out-of-the-box editor stops following the system.
	func testEveryBuiltInIsPaired() {
		for theme in MopedTheme.allBuiltIn {
			XCTAssertNotNil(theme.darkVariant, "\(theme.name) should carry a dark palette")
		}
		XCTAssertNotNil(MopedTheme.xcodeLike.darkVariant)
	}

	func testEveryThemeColorsEveryTokenKind() {
		for theme in MopedTheme.allBuiltIn {
			// A paired theme has to colour every kind in both palettes, or flipping the
			// appearance would silently drop half the highlighting.
			for palette in [theme] + [theme.darkVariant].compactMap({ $0 }) {
				for kind in TokenKind.allCases where kind != .plain {
					XCTAssertNotNil(
						palette.tokenColors[kind.rawValue],
						"\(theme.name) is missing a color for \(kind.rawValue)"
					)
				}
			}
		}
	}

	// MARK: - Pairing

	func testPairedThemeResolvesByAppearance() throws {
		let paired = MopedTheme.default
		let light = try XCTUnwrap(NSAppearance(named: .aqua))
		let dark = try XCTUnwrap(NSAppearance(named: .darkAqua))

		XCTAssertEqual(paired.resolved(for: light).background, MopedTheme.defaultLightPalette.background)
		XCTAssertEqual(paired.resolved(for: dark).background, MopedTheme.defaultDarkPalette.background)
	}

	func testXcodeLikeResolvesByAppearance() throws {
		let paired = MopedTheme.xcodeLike
		let light = try XCTUnwrap(NSAppearance(named: .aqua))
		let dark = try XCTUnwrap(NSAppearance(named: .darkAqua))

		XCTAssertEqual(paired.resolved(for: light).background, MopedTheme.xcodeLikeLightPalette.background)
		XCTAssertEqual(paired.resolved(for: dark).background, MopedTheme.xcodeLikeDarkPalette.background)
		XCTAssertGreaterThan(
			try brightness(of: paired.resolved(for: light).background),
			try brightness(of: paired.resolved(for: dark).background)
		)
	}

	/// Callers apply `resolved(for:)` unconditionally, so an unpaired theme — which is
	/// what a `.mopedtheme` with no `dark` section decodes to — has to answer with
	/// itself rather than needing a check first. No built-in is unpaired any more, so
	/// this uses a lone palette.
	func testUnpairedThemeResolvesToItself() throws {
		let dark = try XCTUnwrap(NSAppearance(named: .darkAqua))
		let unpaired = MopedTheme.xcodeLikeLightPalette
		XCTAssertNil(unpaired.darkVariant)
		XCTAssertEqual(unpaired.resolved(for: dark).background, unpaired.background)
	}

	/// `name` is the stored preference value, so both halves of a pair must answer to
	/// the same one — otherwise resolving would hand the editor a theme the picker
	/// cannot match.
	func testPairedThemeSharesOneNameAndDoesNotNest() {
		XCTAssertEqual(MopedTheme.default.darkVariant?.name, "Default")
		XCTAssertNil(MopedTheme.default.darkVariant?.darkVariant)
	}

	func testColorFallsBackToForeground() {
		let theme = MopedTheme.defaultLightPalette
		XCTAssertEqual(theme.color(for: .plain), theme.foreground)
	}

	// MARK: - System theme

	/// `system` is deliberately absent from `allBuiltIn`: its chrome comes from AppKit
	/// rather than from fixed values, so it is never written to a theme file.
	func testSystemThemeIsSelectableButNotBuiltIn() {
		XCTAssertFalse(MopedTheme.allNames.contains(MopedTheme.systemName))
		XCTAssertEqual(MopedTheme.selectableNames.first, MopedTheme.systemName)
		XCTAssertEqual(MopedTheme.selectableNames.count, MopedTheme.allNames.count + 1)
	}

	func testSystemThemeFollowsAppearance() throws {
		let light = try XCTUnwrap(NSAppearance(named: .aqua))
		let dark = try XCTUnwrap(NSAppearance(named: .darkAqua))

		let lightTheme = MopedTheme.system(for: light)
		let darkTheme = MopedTheme.system(for: dark)

		XCTAssertEqual(lightTheme.name, MopedTheme.systemName)
		XCTAssertEqual(darkTheme.name, MopedTheme.systemName)
		XCTAssertGreaterThan(
			try brightness(of: lightTheme.background),
			try brightness(of: darkTheme.background),
			"the light appearance should produce the lighter editor background"
		)
		XCTAssertLessThan(
			try brightness(of: lightTheme.foreground),
			try brightness(of: darkTheme.foreground),
			"the light appearance should produce the darker editor text"
		)
	}

	/// The theme actually handed to the editor is the paired one, so that it follows the
	/// appearance through the same `resolved(for:)` path every other theme uses.
	func testSystemThemeIsPaired() throws {
		let paired = MopedTheme.system
		let light = try XCTUnwrap(NSAppearance(named: .aqua))
		let dark = try XCTUnwrap(NSAppearance(named: .darkAqua))

		XCTAssertNotNil(paired.darkVariant)
		XCTAssertEqual(paired.resolved(for: light).name, MopedTheme.systemName)
		XCTAssertEqual(paired.resolved(for: dark).name, MopedTheme.systemName)
		XCTAssertGreaterThan(
			try brightness(of: paired.resolved(for: light).background),
			try brightness(of: paired.resolved(for: dark).background)
		)
	}

	/// The `Sendable` contract on `MopedTheme` requires plain component colours, so the
	/// system theme has to have flattened every dynamic colour it started from.
	func testSystemThemeCarriesNoDynamicColors() throws {
		let theme = MopedTheme.system(for: try XCTUnwrap(NSAppearance(named: .darkAqua)))
		for color in [
			theme.background, theme.foreground, theme.gutterBackground,
			theme.gutterForeground, theme.selection, theme.caret
		] {
			XCTAssertEqual(color.colorSpace, .sRGB, "\(color) was not flattened to sRGB")
		}
	}

	/// Picking System gives up opinionated chrome, not syntax highlighting.
	func testSystemThemeColorsEveryTokenKind() throws {
		for appearance in [NSAppearance.Name.aqua, .darkAqua] {
			let theme = MopedTheme.system(for: try XCTUnwrap(NSAppearance(named: appearance)))
			for kind in TokenKind.allCases where kind != .plain {
				XCTAssertNotNil(
					theme.tokenColors[kind.rawValue],
					"System (\(appearance.rawValue)) is missing a color for \(kind.rawValue)"
				)
			}
		}
	}

	/// The caret is the one colour that cannot be derived by inverting the background:
	/// inverting the system text background lands on a near-invisible grey.
	func testSystemThemeCaretIsTheTextColorNotAnInversion() throws {
		let theme = MopedTheme.system(for: try XCTUnwrap(NSAppearance(named: .darkAqua)))
		XCTAssertEqual(theme.caret, theme.foreground)
	}

	func testFixedThemesStillInvertTheirBackgroundForTheCaret() {
		// Default Light is pure white, so its caret must come out pure black.
		let caret = try? XCTUnwrap(MopedTheme.defaultLightPalette.caret.usingColorSpace(.sRGB))
		XCTAssertEqual(caret?.redComponent ?? 1, 0, accuracy: 0.001)
		XCTAssertEqual(caret?.greenComponent ?? 1, 0, accuracy: 0.001)
		XCTAssertEqual(caret?.blueComponent ?? 1, 0, accuracy: 0.001)
	}

	private func brightness(of color: NSColor) throws -> CGFloat {
		try XCTUnwrap(color.usingColorSpace(.sRGB)).brightnessComponent
	}
}
