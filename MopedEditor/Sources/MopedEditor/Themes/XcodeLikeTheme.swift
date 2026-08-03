//
//  XcodeLikeTheme.swift
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
	static let xcodeLikeLightPalette = MopedTheme(
		name: "Xcode-like",
		background: NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.00, green: 0.00, blue: 0.00, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.94, green: 0.94, blue: 0.94, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.51, green: 0.51, blue: 0.51, alpha: 1.0),
		selection: NSColor(srgbRed: 0.71, green: 0.83, blue: 1.00, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.00, green: 0.45, blue: 0.18, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.59, green: 0.05, blue: 0.40, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.59, green: 0.05, blue: 0.40, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.59, green: 0.05, blue: 0.40, alpha: 1.0),
			"include": NSColor(srgbRed: 0.40, green: 0.16, blue: 0.62, alpha: 1.0),
			"string": NSColor(srgbRed: 0.77, green: 0.10, blue: 0.09, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.77, green: 0.10, blue: 0.09, alpha: 1.0),
			"number": NSColor(srgbRed: 0.11, green: 0.00, blue: 0.81, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.11, green: 0.00, blue: 0.81, alpha: 1.0),
			"type": NSColor(srgbRed: 0.04, green: 0.32, blue: 0.74, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.04, green: 0.32, blue: 0.74, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.30, green: 0.43, blue: 0.55, alpha: 1.0),
			"method": NSColor(srgbRed: 0.30, green: 0.43, blue: 0.55, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.20, green: 0.21, blue: 0.24, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.40, green: 0.16, blue: 0.62, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.20, green: 0.21, blue: 0.24, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.00, green: 0.00, blue: 0.00, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.40, green: 0.16, blue: 0.62, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.40, green: 0.16, blue: 0.62, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.09, green: 0.51, blue: 0.24, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 0.72, green: 0.11, blue: 0.11, alpha: 1.0)
		]
	)

	/// Xcode's own Default (Dark) palette, mapped onto Moped's token vocabulary the same
	/// way the light one approximates Default (Light). The mapping is not one to one:
	/// Xcode splits identifiers into project and system halves that the tokenizer does
	/// not distinguish, so `type`/`constructor` take Xcode's project class blue and
	/// `variable.builtin`/`text.title` take its other-class purple.
	///
	/// The diff colours have no Xcode counterpart — it colours diffs in the gutter, not
	/// the text — so they are picked for legibility on this background, as in the light
	/// palette.
	static let xcodeLikeDarkPalette = MopedTheme(
		name: "Xcode-like",
		background: NSColor(srgbRed: 0.12, green: 0.12, blue: 0.14, alpha: 1.0),
		foreground: NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.16, green: 0.16, blue: 0.19, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.50, green: 0.55, blue: 0.60, alpha: 1.0),
		selection: NSColor(srgbRed: 0.32, green: 0.36, blue: 0.44, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.42, green: 0.47, blue: 0.53, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.99, green: 0.37, blue: 0.64, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.99, green: 0.37, blue: 0.64, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.99, green: 0.37, blue: 0.64, alpha: 1.0),
			"include": NSColor(srgbRed: 0.99, green: 0.56, blue: 0.25, alpha: 1.0),
			"string": NSColor(srgbRed: 0.99, green: 0.42, blue: 0.36, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.99, green: 0.42, blue: 0.36, alpha: 1.0),
			"number": NSColor(srgbRed: 0.82, green: 0.75, blue: 0.41, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.82, green: 0.75, blue: 0.41, alpha: 1.0),
			"type": NSColor(srgbRed: 0.36, green: 0.85, blue: 1.00, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.36, green: 0.85, blue: 1.00, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.40, green: 0.72, blue: 0.64, alpha: 1.0),
			"method": NSColor(srgbRed: 0.40, green: 0.72, blue: 0.64, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.85, green: 0.85, blue: 0.87, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.82, green: 0.66, blue: 1.00, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.85, green: 0.85, blue: 0.87, alpha: 1.0),
			"operator": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.82, green: 0.66, blue: 1.00, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.82, green: 0.66, blue: 1.00, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.49, green: 0.91, blue: 0.53, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 1.00, green: 0.48, blue: 0.45, alpha: 1.0)
		]
	)
}
