//
//  EditorTheme+BuiltIn.swift
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

extension MopedTheme {
	/// Shipped themes are a light palette paired with a dark one, so they follow the
	/// macOS appearance. Turbo is the exception: it reproduces a fixed 16-colour DOS
	/// screen, which has no light counterpart to switch to, so it stays a lone palette
	/// the way a `.mopedtheme` with no `dark` section does.
	public static let `default` = defaultLightPalette.paired(withDark: defaultDarkPalette)

	public static let forest = forestLightPalette.paired(withDark: forestDarkPalette)

	public static let nebula = nebulaLightPalette.paired(withDark: nebulaDarkPalette)

	public static let ocean = oceanLightPalette.paired(withDark: oceanDarkPalette)

	public static let solarized = solarizedLightPalette.paired(withDark: solarizedDarkPalette)

	/// Unpaired, hence no `paired(withDark:)` — see `turboPalette`.
	public static let turbo = turboPalette

	public static let xcodeLike = xcodeLikeLightPalette.paired(withDark: xcodeLikeDarkPalette)

	/// Alphabetical: this is the order `selectableNames` hands the settings picker, and
	/// a list the user scans is easier to scan sorted than in the order themes happened
	/// to be added.
	public static let allBuiltIn: [MopedTheme] = [
		.default, .forest, .nebula, .ocean, .solarized, .turbo, .xcodeLike
	]

	public static let allNames: [String] = allBuiltIn.map(\.name)

	/// Everything the settings picker offers before any theme files are read,
	/// appearance-following theme first. Kept separate from `allNames` because `system`
	/// takes its chrome from AppKit rather than from fixed values, so it cannot join
	/// `allBuiltIn`.
	public static let selectableNames: [String] = [systemName] + allNames

	public static let defaultName: String = `default`.name
}
