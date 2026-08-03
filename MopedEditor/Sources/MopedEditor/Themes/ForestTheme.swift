//
//  ForestTheme.swift
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
	static let forestLightPalette = MopedTheme(
		name: "Forest",
		background: NSColor(srgbRed: 0.98, green: 0.97, blue: 0.95, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.16, green: 0.20, blue: 0.15, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.94, green: 0.93, blue: 0.88, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.54, green: 0.55, blue: 0.46, alpha: 1.0),
		selection: NSColor(srgbRed: 0.84, green: 0.90, blue: 0.78, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.46, green: 0.52, blue: 0.39, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.30, green: 0.42, blue: 0.07, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.30, green: 0.42, blue: 0.07, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.30, green: 0.42, blue: 0.07, alpha: 1.0),
			"include": NSColor(srgbRed: 0.54, green: 0.35, blue: 0.12, alpha: 1.0),
			"string": NSColor(srgbRed: 0.61, green: 0.25, blue: 0.18, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.61, green: 0.25, blue: 0.18, alpha: 1.0),
			"number": NSColor(srgbRed: 0.42, green: 0.30, blue: 0.58, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.42, green: 0.30, blue: 0.58, alpha: 1.0),
			"type": NSColor(srgbRed: 0.08, green: 0.38, blue: 0.35, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.08, green: 0.38, blue: 0.35, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.18, green: 0.48, blue: 0.24, alpha: 1.0),
			"method": NSColor(srgbRed: 0.18, green: 0.48, blue: 0.24, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.20, green: 0.25, blue: 0.17, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.54, green: 0.35, blue: 0.12, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.20, green: 0.25, blue: 0.17, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.31, green: 0.35, blue: 0.27, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.31, green: 0.35, blue: 0.27, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.08, green: 0.38, blue: 0.35, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.18, green: 0.48, blue: 0.24, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 0.61, green: 0.25, blue: 0.18, alpha: 1.0)
		]
	)

	static let forestDarkPalette = MopedTheme(
		name: "Forest",
		background: NSColor(srgbRed: 0.07, green: 0.10, blue: 0.07, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.86, green: 0.89, blue: 0.82, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.10, green: 0.13, blue: 0.09, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.43, green: 0.49, blue: 0.38, alpha: 1.0),
		selection: NSColor(srgbRed: 0.18, green: 0.27, blue: 0.15, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.43, green: 0.49, blue: 0.38, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.65, green: 0.79, blue: 0.34, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.65, green: 0.79, blue: 0.34, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.65, green: 0.79, blue: 0.34, alpha: 1.0),
			"include": NSColor(srgbRed: 0.82, green: 0.64, blue: 0.36, alpha: 1.0),
			"string": NSColor(srgbRed: 0.89, green: 0.55, blue: 0.42, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.89, green: 0.55, blue: 0.42, alpha: 1.0),
			"number": NSColor(srgbRed: 0.73, green: 0.62, blue: 0.89, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.73, green: 0.62, blue: 0.89, alpha: 1.0),
			"type": NSColor(srgbRed: 0.37, green: 0.80, blue: 0.67, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.37, green: 0.80, blue: 0.67, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.53, green: 0.82, blue: 0.55, alpha: 1.0),
			"method": NSColor(srgbRed: 0.53, green: 0.82, blue: 0.55, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.86, green: 0.89, blue: 0.82, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.82, green: 0.64, blue: 0.36, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.86, green: 0.89, blue: 0.82, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.65, green: 0.71, blue: 0.62, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.65, green: 0.71, blue: 0.62, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.37, green: 0.80, blue: 0.67, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.53, green: 0.82, blue: 0.55, alpha: 1.0),
			"diff.minus": NSColor(srgbRed: 0.89, green: 0.45, blue: 0.42, alpha: 1.0)
		]
	)
}
