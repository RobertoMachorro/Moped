//
//  EditorTheme+System.swift
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
	/// Stored preference value and identity of the appearance-following theme. Not a
	/// member of `allBuiltIn`: unlike the fixed themes it cannot be a `static let`,
	/// because its colours depend on the appearance it is asked about.
	public static let systemName = "System"

	/// The editor dressed in AppKit's own text colours, resolved against `appearance`.
	///
	/// The resolution is eager and the result is a plain sRGB theme. That is deliberate:
	/// `MopedTheme` is `Sendable` on the promise that it never carries a dynamic or
	/// catalog colour (see the type's own documentation). Holding `NSColor.textColor`
	/// would break that promise, so callers rebuild this theme when the effective
	/// appearance changes instead of relying on a colour to re-resolve itself.
	///
	/// Token colours still come from the hand-tuned light/dark palettes. Picking
	/// "System" means giving up an opinionated set of chrome colours, not giving up
	/// syntax highlighting.
	public static func system(for appearance: NSAppearance) -> MopedTheme {
		let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
		let fallback: MopedTheme = isDark ? .defaultDark : .defaultLight

		var background = fallback.background
		var foreground = fallback.foreground
		var gutterBackground = fallback.gutterBackground
		var gutterForeground = fallback.gutterForeground
		var selection = fallback.selection
		var caret = fallback.caret

		appearance.performAsCurrentDrawingAppearance {
			background = sRGB(.textBackgroundColor, or: fallback.background)
			foreground = sRGB(.textColor, or: fallback.foreground)
			gutterBackground = sRGB(.controlBackgroundColor, or: fallback.gutterBackground)
			gutterForeground = sRGB(.secondaryLabelColor, or: fallback.gutterForeground)
			selection = sRGB(.selectedTextBackgroundColor, or: fallback.selection)
			caret = sRGB(.textColor, or: fallback.foreground)
		}

		return MopedTheme(
			name: systemName,
			background: background,
			foreground: foreground,
			gutterBackground: gutterBackground,
			gutterForeground: gutterForeground,
			selection: selection,
			caret: caret,
			tokenColors: fallback.tokenColors
		)
	}

	/// Flattens a dynamic system colour to components. Must be called with the target
	/// appearance current, or it resolves against the wrong one.
	private static func sRGB(_ color: NSColor, or fallback: NSColor) -> NSColor {
		color.usingColorSpace(.sRGB) ?? fallback
	}
}
