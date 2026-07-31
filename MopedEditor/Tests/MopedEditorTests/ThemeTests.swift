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
}
