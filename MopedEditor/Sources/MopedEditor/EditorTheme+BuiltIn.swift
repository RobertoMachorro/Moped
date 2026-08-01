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
	public static let allBuiltIn: [MopedTheme] = [
		.defaultLight, .defaultDark, .xcodeLike, .solarizedLight, .solarizedDark
	]

	public static let allNames: [String] = allBuiltIn.map(\.name)

	/// Everything the settings picker offers, appearance-following theme first. Kept
	/// separate from `allNames` because `system` is a function of the appearance rather
	/// than a fixed theme, so it cannot join `allBuiltIn`.
	public static let selectableNames: [String] = [systemName] + allNames

	public static let defaultName: String = defaultLight.name
}

extension MopedTheme {
	public static let defaultLight = MopedTheme(
		name: "Default Light",
		background: NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.97, green: 0.97, blue: 0.97, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.55, green: 0.55, blue: 0.55, alpha: 1.0),
		selection: NSColor(srgbRed: 0.74, green: 0.84, blue: 0.99, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.42, green: 0.47, blue: 0.53, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.62, green: 0.13, blue: 0.55, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.62, green: 0.13, blue: 0.55, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.62, green: 0.13, blue: 0.55, alpha: 1.0),
			"include": NSColor(srgbRed: 0.62, green: 0.13, blue: 0.55, alpha: 1.0),
			"string": NSColor(srgbRed: 0.77, green: 0.10, blue: 0.09, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.77, green: 0.10, blue: 0.09, alpha: 1.0),
			"number": NSColor(srgbRed: 0.11, green: 0.00, blue: 0.81, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.11, green: 0.00, blue: 0.81, alpha: 1.0),
			"type": NSColor(srgbRed: 0.04, green: 0.32, blue: 0.74, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.04, green: 0.32, blue: 0.74, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.17, green: 0.42, blue: 0.51, alpha: 1.0),
			"method": NSColor(srgbRed: 0.17, green: 0.42, blue: 0.51, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 0.49, green: 0.27, blue: 0.06, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.12, green: 0.12, blue: 0.12, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.30, green: 0.30, blue: 0.30, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.30, green: 0.30, blue: 0.30, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.04, green: 0.32, blue: 0.74, alpha: 1.0)
		]
	)

	public static let defaultDark = MopedTheme(
		name: "Default Dark",
		background: NSColor(srgbRed: 0.12, green: 0.13, blue: 0.16, alpha: 1.0),
		foreground: NSColor(srgbRed: 0.92, green: 0.92, blue: 0.93, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.15, green: 0.16, blue: 0.19, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.48, green: 0.49, blue: 0.52, alpha: 1.0),
		selection: NSColor(srgbRed: 0.24, green: 0.34, blue: 0.55, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.45, green: 0.52, blue: 0.58, alpha: 1.0),
			"keyword": NSColor(srgbRed: 0.97, green: 0.45, blue: 0.70, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 0.97, green: 0.45, blue: 0.70, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 0.97, green: 0.45, blue: 0.70, alpha: 1.0),
			"include": NSColor(srgbRed: 0.97, green: 0.45, blue: 0.70, alpha: 1.0),
			"string": NSColor(srgbRed: 0.94, green: 0.75, blue: 0.49, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.94, green: 0.75, blue: 0.49, alpha: 1.0),
			"number": NSColor(srgbRed: 0.71, green: 0.67, blue: 0.94, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.71, green: 0.67, blue: 0.94, alpha: 1.0),
			"type": NSColor(srgbRed: 0.54, green: 0.78, blue: 0.99, alpha: 1.0),
			"constructor": NSColor(srgbRed: 0.54, green: 0.78, blue: 0.99, alpha: 1.0),
			"function.call": NSColor(srgbRed: 0.56, green: 0.85, blue: 0.69, alpha: 1.0),
			"method": NSColor(srgbRed: 0.56, green: 0.85, blue: 0.69, alpha: 1.0),
			"variable": NSColor(srgbRed: 0.92, green: 0.92, blue: 0.93, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 1.00, green: 0.70, blue: 0.45, alpha: 1.0),
			"parameter": NSColor(srgbRed: 0.92, green: 0.92, blue: 0.93, alpha: 1.0),
			"operator": NSColor(srgbRed: 0.77, green: 0.78, blue: 0.81, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 0.77, green: 0.78, blue: 0.81, alpha: 1.0),
			"text.title": NSColor(srgbRed: 0.54, green: 0.78, blue: 0.99, alpha: 1.0)
		]
	)

	public static let xcodeLike = MopedTheme(
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
			"text.title": NSColor(srgbRed: 0.40, green: 0.16, blue: 0.62, alpha: 1.0)
		]
	)

	public static let solarizedLight = MopedTheme(
		name: "Solarized Light",
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
			"text.title": NSColor(srgbRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0)
		]
	)

	public static let solarizedDark = MopedTheme(
		name: "Solarized Dark",
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
			"text.title": NSColor(srgbRed: 0.15, green: 0.55, blue: 0.82, alpha: 1.0)
		]
	)
}
