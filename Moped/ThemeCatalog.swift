//
//  ThemeCatalog.swift
//
//  Moped - A general purpose text editor, small and light.
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

import MopedEditor

/// Resolves the stored theme preference to a `MopedEditor` theme. The themes
/// themselves live in the editor package; only the mapping from legacy preference
/// values belongs to the app.
enum ThemeCatalog {
	/// Look up a theme by name, resolving legacy Highlightr theme strings to the closest
	/// built-in. Returns the default theme when nothing matches so existing preferences
	/// don't reset users on first launch.
	static func theme(named name: String) -> MopedTheme {
		let key = name.lowercased()
		if let direct = MopedTheme.allBuiltIn.first(where: { $0.name.lowercased() == key }) {
			return direct
		}
		if let aliasName = legacyAliases[key],
		   let aliased = MopedTheme.allBuiltIn.first(where: { $0.name == aliasName }) {
			return aliased
		}
		return .defaultLight
	}

	private static let legacyAliases: [String: String] = [
		"xcode": MopedTheme.xcodeLike.name,
		"default": MopedTheme.defaultLight.name,
		"github": MopedTheme.defaultLight.name,
		"github-gist": MopedTheme.defaultLight.name,
		"vs": MopedTheme.defaultLight.name,
		"atom-one-light": MopedTheme.defaultLight.name,
		"solarized-light": MopedTheme.solarizedLight.name,
		"solarized": MopedTheme.solarizedLight.name,
		"solarized-dark": MopedTheme.solarizedDark.name,
		"monokai": MopedTheme.defaultDark.name,
		"monokai-sublime": MopedTheme.defaultDark.name,
		"dracula": MopedTheme.defaultDark.name,
		"tomorrow-night": MopedTheme.defaultDark.name,
		"atom-one-dark": MopedTheme.defaultDark.name,
		"agate": MopedTheme.defaultDark.name
	]
}
