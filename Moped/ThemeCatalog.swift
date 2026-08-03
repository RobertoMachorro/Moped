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

import AppKit
import MopedEditor

/// Resolves the stored theme preference to a `MopedEditor` theme. The themes
/// themselves come from `ThemeStore`, or from the package when the folder cannot be
/// read; only the name mapping belongs here.
enum ThemeCatalog {
	/// Everything the settings picker offers: System first, then the themes on disk.
	///
	/// Falls back to the package's own list only if the folder produced nothing at all,
	/// so a wiped or unreadable themes folder still leaves a usable picker.
	@MainActor
	static var selectableNames: [String] {
		let installed = ThemeStore.shared.themes.map(\.name)
		return [MopedTheme.systemName] + (installed.isEmpty ? MopedTheme.allNames : installed)
	}

	/// Look up a theme by name, resolving names Moped used to ship — and the Highlightr
	/// theme strings from before Moped had its own editor — to their closest current
	/// equivalent. Returns the default theme when nothing matches, so a preference
	/// naming a deleted theme file degrades instead of leaving the editor unstyled.
	///
	/// `@MainActor` because it reads `ThemeStore`. Both callers live in `EditorState`,
	/// which is already main-actor isolated; `localizedName(for:)` below touches no app
	/// state and stays nonisolated.
	@MainActor
	static func theme(named name: String) -> MopedTheme {
		let key = name.lowercased()
		if key == MopedTheme.systemName.lowercased() {
			// Only an opening value: `MopedTextView` re-resolves it against its own
			// effective appearance, and again whenever that appearance changes.
			return .system
		}
		if let match = installed(key) {
			return match
		}
		if let alias = legacyAliases[key], let match = installed(alias.lowercased()) {
			return match
		}
		return .default
	}

	/// The themes folder wins over the package copy, which is what lets a user retune a
	/// theme Moped ships by editing its file.
	@MainActor
	private static func installed(_ key: String) -> MopedTheme? {
		ThemeStore.shared.themes.first { $0.name.lowercased() == key }
			?? MopedTheme.allBuiltIn.first { $0.name.lowercased() == key }
	}

	/// Display name for the preferences picker.
	///
	/// `MopedTheme.name` is both the stored preference value and file data, and the
	/// package stays free of app types — so the mapping to a translated label belongs
	/// here, the same way `Preferences.AppIcon.localizedLabel` handles icon names.
	/// "Xcode" and "Solarized" are proper nouns and need no key of their own.
	///
	/// Everything else — user-authored themes above all — falls back to its raw name,
	/// which is untranslated but never blank. That fallback is the reason a custom theme
	/// needs no localization work at all.
	static func localizedName(for name: String) -> String {
		switch name {
		case MopedTheme.systemName:     return String(localized: "option.theme.system")
		case MopedTheme.defaultName:    return String(localized: "option.theme.default")
		case MopedTheme.xcodeLike.name: return String(localized: "option.theme.xcode_like")
		default:                        return name
		}
	}

	/// Names Moped used to store, mapped to what replaces them. Without this every user
	/// on a light/dark variant would silently reset when those collapsed into one
	/// appearance-following theme each.
	private static let legacyAliases: [String: String] = [
		"default light": MopedTheme.defaultName,
		"default dark": MopedTheme.defaultName,
		"solarized light": MopedTheme.solarized.name,
		"solarized dark": MopedTheme.solarized.name,
		// Highlightr theme names, from before Moped had its own editor. The dark ones
		// now land on a theme that follows the system appearance — there is no longer a
		// pinned-dark built-in to point them at.
		"xcode": MopedTheme.xcodeLike.name,
		"default": MopedTheme.defaultName,
		"github": MopedTheme.defaultName,
		"github-gist": MopedTheme.defaultName,
		"vs": MopedTheme.defaultName,
		"atom-one-light": MopedTheme.defaultName,
		"solarized-light": MopedTheme.solarized.name,
		"solarized": MopedTheme.solarized.name,
		"solarized-dark": MopedTheme.solarized.name,
		"monokai": MopedTheme.defaultName,
		"monokai-sublime": MopedTheme.defaultName,
		"dracula": MopedTheme.defaultName,
		"tomorrow-night": MopedTheme.defaultName,
		"atom-one-dark": MopedTheme.defaultName,
		"agate": MopedTheme.defaultName
	]
}
