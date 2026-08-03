//
//  SolarizedTheme.swift
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
	static let solarizedLightPalette = MopedTheme(
		name: "Solarized",
		background: NSColor(srgbRed: 0.99, green: 0.96, blue: 0.89, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.93, green: 0.91, blue: 0.83, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),
		selection: NSColor(srgbRed: 0.93, green: 0.91, blue: 0.83, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.58, green: 0.63, blue: 0.63, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),
			"include": NSColor(srgbRed: 0.80, green: 0.29, blue: 0.09, alpha: 1.0),
			"string": NSColor(srgbRed: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),
			"number": NSColor(srgbRed: 0.83, green: 0.21, blue: 0.51, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.83, green: 0.21, blue: 0.51, alpha: 1.0),
			"type": NSColor(srgbRed: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
			"method": NSColor(srgbRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.42, green: 0.44, blue: 0.77, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.80, green: 0.29, blue: 0.09, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 0.86, green: 0.20, blue: 0.18, alpha: 1.0)
		]
	)

	static let solarizedDarkPalette = MopedTheme(
		name: "Solarized",
		background: NSColor(srgbRed: 0.00, green: 0.17, blue: 0.21, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.03, green: 0.21, blue: 0.26, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.40, green: 0.48, blue: 0.51, alpha: 1.0),
		selection: NSColor(srgbRed: 0.03, green: 0.21, blue: 0.26, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.35, green: 0.43, blue: 0.46, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),
			"include": NSColor(srgbRed: 0.80, green: 0.29, blue: 0.09, alpha: 1.0),
			"string": NSColor(srgbRed: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.16, green: 0.63, blue: 0.60, alpha: 1.0),
			"number": NSColor(srgbRed: 0.83, green: 0.21, blue: 0.51, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.83, green: 0.21, blue: 0.51, alpha: 1.0),
			"type": NSColor(srgbRed: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.71, green: 0.54, blue: 0.00, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
			"method": NSColor(srgbRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.42, green: 0.44, blue: 0.77, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.51, green: 0.58, blue: 0.59, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.80, green: 0.29, blue: 0.09, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.52, green: 0.60, blue: 0.00, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 0.86, green: 0.20, blue: 0.18, alpha: 1.0)
		]
	)
}
