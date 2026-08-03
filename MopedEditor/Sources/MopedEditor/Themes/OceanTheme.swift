//
//  OceanTheme.swift
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
	static let oceanLightPalette = MopedTheme(
		name: "Ocean",
		background: NSColor(srgbRed: 0.95, green: 0.97, blue: 0.99, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.06, green: 0.16, blue: 0.23, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.89, green: 0.93, blue: 0.96, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.43, green: 0.56, blue: 0.64, alpha: 1.0),
		selection: NSColor(srgbRed: 0.75, green: 0.86, blue: 0.95, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.42, green: 0.53, blue: 0.60, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.00, green: 0.34, blue: 0.43, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.00, green: 0.34, blue: 0.43, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.00, green: 0.34, blue: 0.43, alpha: 1.0),
			"include": NSColor(srgbRed: 0.36, green: 0.29, blue: 0.62, alpha: 1.0),
			"string": NSColor(srgbRed: 0.11, green: 0.45, blue: 0.33, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.11, green: 0.45, blue: 0.33, alpha: 1.0),
			"number": NSColor(srgbRed: 0.61, green: 0.29, blue: 0.00, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.61, green: 0.29, blue: 0.00, alpha: 1.0),
			"type": NSColor(srgbRed: 0.13, green: 0.40, blue: 0.69, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.13, green: 0.40, blue: 0.69, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.04, green: 0.43, blue: 0.52, alpha: 1.0),
			"method": NSColor(srgbRed: 0.04, green: 0.43, blue: 0.52, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.09, green: 0.22, blue: 0.30, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.54, green: 0.31, blue: 0.66, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.09, green: 0.22, blue: 0.30, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.23, green: 0.35, blue: 0.43, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.23, green: 0.35, blue: 0.43, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.00, green: 0.34, blue: 0.43, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.08, green: 0.42, blue: 0.27, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 0.63, green: 0.15, blue: 0.14, alpha: 1.0)
		]
	)

	static let oceanDarkPalette = MopedTheme(
		name: "Ocean",
		background: NSColor(srgbRed: 0.05, green: 0.12, blue: 0.17, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.84, green: 0.90, blue: 0.95, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.07, green: 0.16, blue: 0.22, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.36, green: 0.49, blue: 0.57, alpha: 1.0),
		selection: NSColor(srgbRed: 0.12, green: 0.30, blue: 0.42, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.36, green: 0.49, blue: 0.56, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.34, green: 0.78, blue: 0.94, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.34, green: 0.78, blue: 0.94, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.34, green: 0.78, blue: 0.94, alpha: 1.0),
			"include": NSColor(srgbRed: 0.66, green: 0.61, blue: 0.94, alpha: 1.0),
			"string": NSColor(srgbRed: 0.50, green: 0.83, blue: 0.65, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.50, green: 0.83, blue: 0.65, alpha: 1.0),
			"number": NSColor(srgbRed: 0.94, green: 0.69, blue: 0.41, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.94, green: 0.69, blue: 0.41, alpha: 1.0),
			"type": NSColor(srgbRed: 0.56, green: 0.73, blue: 0.94, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.56, green: 0.73, blue: 0.94, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.35, green: 0.82, blue: 0.84, alpha: 1.0),
			"method": NSColor(srgbRed: 0.35, green: 0.82, blue: 0.84, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.84, green: 0.90, blue: 0.95, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.83, green: 0.61, blue: 0.91, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.84, green: 0.90, blue: 0.95, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.61, green: 0.71, blue: 0.78, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.61, green: 0.71, blue: 0.78, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.34, green: 0.78, blue: 0.94, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.43, green: 0.83, blue: 0.55, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 0.94, green: 0.54, blue: 0.54, alpha: 1.0)
		]
	)
}
