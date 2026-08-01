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
		XCTAssertEqual(MopedTheme.allBuiltIn.count, 5)
		XCTAssertEqual(MopedTheme.allNames, [
			"Default Light", "Default Dark", "Xcode-like", "Solarized Light", "Solarized Dark"
		])
		XCTAssertEqual(MopedTheme.defaultName, "Default Light")
	}

	func testEveryThemeColorsEveryTokenKind() {
		for theme in MopedTheme.allBuiltIn {
			for kind in TokenKind.allCases where kind != .plain {
				XCTAssertNotNil(
					theme.tokenColors[kind.rawValue],
					"\(theme.name) is missing a color for \(kind.rawValue)"
				)
			}
		}
	}

	func testColorFallsBackToForeground() {
		let theme = MopedTheme.defaultLight
		XCTAssertEqual(theme.color(for: .plain), theme.foreground)
	}

	// MARK: - System theme

	/// `system` is deliberately absent from `allBuiltIn`: it is a function of the
	/// appearance, so it cannot be one of the fixed themes.
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
		let caret = try? XCTUnwrap(MopedTheme.defaultLight.caret.usingColorSpace(.sRGB))
		XCTAssertEqual(caret?.redComponent ?? 1, 0, accuracy: 0.001)
		XCTAssertEqual(caret?.greenComponent ?? 1, 0, accuracy: 0.001)
		XCTAssertEqual(caret?.blueComponent ?? 1, 0, accuracy: 0.001)
	}

	private func brightness(of color: NSColor) throws -> CGFloat {
		try XCTUnwrap(color.usingColorSpace(.sRGB)).brightnessComponent
	}
}
