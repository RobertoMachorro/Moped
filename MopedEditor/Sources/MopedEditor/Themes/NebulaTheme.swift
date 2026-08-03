//
//  NebulaTheme.swift
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
	static let nebulaLightPalette = MopedTheme(
		name: "Nebula",
		background: NSColor(srgbRed: 0.98, green: 0.97, blue: 0.99, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.14, green: 0.11, blue: 0.20, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.94, green: 0.92, blue: 0.97, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.55, green: 0.50, blue: 0.64, alpha: 1.0),
		selection: NSColor(srgbRed: 0.86, green: 0.82, blue: 0.94, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.49, green: 0.45, blue: 0.57, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.55, green: 0.18, blue: 0.66, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.55, green: 0.18, blue: 0.66, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.55, green: 0.18, blue: 0.66, alpha: 1.0),
			"include": NSColor(srgbRed: 0.69, green: 0.16, blue: 0.47, alpha: 1.0),
			"string": NSColor(srgbRed: 0.06, green: 0.48, blue: 0.43, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.06, green: 0.48, blue: 0.43, alpha: 1.0),
			"number": NSColor(srgbRed: 0.66, green: 0.33, blue: 0.00, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.66, green: 0.33, blue: 0.00, alpha: 1.0),
			"type": NSColor(srgbRed: 0.29, green: 0.29, blue: 0.75, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.29, green: 0.29, blue: 0.75, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.16, green: 0.44, blue: 0.71, alpha: 1.0),
			"method": NSColor(srgbRed: 0.16, green: 0.44, blue: 0.71, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.18, green: 0.14, blue: 0.25, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.69, green: 0.16, blue: 0.47, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.18, green: 0.14, blue: 0.25, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.33, green: 0.29, blue: 0.42, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.33, green: 0.29, blue: 0.42, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.55, green: 0.18, blue: 0.66, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.09, green: 0.45, blue: 0.30, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 0.65, green: 0.16, blue: 0.24, alpha: 1.0)
		]
	)

	static let nebulaDarkPalette = MopedTheme(
		name: "Nebula",
		background: NSColor(srgbRed: 0.04, green: 0.04, blue: 0.07, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.85, green: 0.84, blue: 0.90, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.06, green: 0.06, blue: 0.10, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.34, green: 0.32, blue: 0.43, alpha: 1.0),
		selection: NSColor(srgbRed: 0.16, green: 0.15, blue: 0.27, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.43, green: 0.42, blue: 0.57, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.78, green: 0.55, blue: 0.96, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.78, green: 0.55, blue: 0.96, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.78, green: 0.55, blue: 0.96, alpha: 1.0),
			"include": NSColor(srgbRed: 0.96, green: 0.44, blue: 0.77, alpha: 1.0),
			"string": NSColor(srgbRed: 0.47, green: 0.89, blue: 0.78, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.47, green: 0.89, blue: 0.78, alpha: 1.0),
			"number": NSColor(srgbRed: 1.00, green: 0.71, blue: 0.45, alpha: 1.0),
			"boolean": NSColor(srgbRed: 1.00, green: 0.71, blue: 0.45, alpha: 1.0),
			"type": NSColor(srgbRed: 0.55, green: 0.89, blue: 0.98, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.55, green: 0.89, blue: 0.98, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.64, green: 0.66, blue: 1.00, alpha: 1.0),
			"method": NSColor(srgbRed: 0.64, green: 0.66, blue: 1.00, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.85, green: 0.84, blue: 0.90, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.96, green: 0.44, blue: 0.77, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.85, green: 0.84, blue: 0.90, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.61, green: 0.59, blue: 0.72, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.61, green: 0.59, blue: 0.72, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.78, green: 0.55, blue: 0.96, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.44, green: 0.90, blue: 0.55, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 1.00, green: 0.50, blue: 0.58, alpha: 1.0)
		]
	)
}
