//
//  TurboTheme.swift
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
	/// Borland's Turbo C++ and Turbo Pascal IDEs: yellow on blue, white reserved words,
	/// cyan strings.
	///
	/// Every colour here comes from the 16-colour EGA/VGA text palette those editors
	/// were limited to — blue `#0000AA` for the window, `#FFFF55` for text, and the six
	/// bright colours for everything else. That constraint is the theme, so resist
	/// "fixing" a value to something off-palette.
	///
	/// It is also why the channels are written to four decimals rather than the two the
	/// other palettes use. `0xAA` and `0x55` are thirds of 255, and at two decimals they
	/// serialize to `#0000AB` and `#FFFF54` — off by one, so the `.mopedtheme` Moped
	/// writes would no longer contain the DOS palette it claims to.
	///
	/// The caret is deliberately not specified: `MopedTheme` defaults it to the inverse
	/// of the background, and the inverse of Turbo blue is exactly Turbo yellow.
	///
	/// Turbo drew a selection as a light block with the text inverted, which the editor
	/// cannot reproduce — it sets a background colour and leaves the text alone. Dark
	/// grey is the palette's only choice that keeps yellow legible on top.
	///
	/// Identifiers, parameters and call sites all take the plain foreground, as they did
	/// in Turbo, which had no notion of colouring them apart.
	static let turboPalette = MopedTheme(
		name: "Turbo",
		background: NSColor(srgbRed: 0.00, green: 0.00, blue: 0.6667, alpha: 1.0),
		foreground: NSColor(srgbRed: 1.00, green: 1.00, blue: 0.3333, alpha: 1.0),
		gutterBackground: NSColor(srgbRed: 0.00, green: 0.00, blue: 0.00, alpha: 1.0),
		gutterForeground: NSColor(srgbRed: 0.6667, green: 0.6667, blue: 0.6667, alpha: 1.0),
		selection: NSColor(srgbRed: 0.3333, green: 0.3333, blue: 0.3333, alpha: 1.0),
		tokenColors: [
			"comment": NSColor(srgbRed: 0.6667, green: 0.6667, blue: 0.6667, alpha: 1.0),
			"keyword": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"keyword.function": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"keyword.return": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"include": NSColor(srgbRed: 1.00, green: 0.3333, blue: 1.00, alpha: 1.0),
			"string": NSColor(srgbRed: 0.3333, green: 1.00, blue: 1.00, alpha: 1.0),
			"text.literal": NSColor(srgbRed: 0.3333, green: 1.00, blue: 1.00, alpha: 1.0),
			"number": NSColor(srgbRed: 0.3333, green: 1.00, blue: 0.3333, alpha: 1.0),
			"boolean": NSColor(srgbRed: 0.3333, green: 1.00, blue: 0.3333, alpha: 1.0),
			"type": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"constructor": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"function.call": NSColor(srgbRed: 1.00, green: 1.00, blue: 0.3333, alpha: 1.0),
			"method": NSColor(srgbRed: 1.00, green: 1.00, blue: 0.3333, alpha: 1.0),
			"variable": NSColor(srgbRed: 1.00, green: 1.00, blue: 0.3333, alpha: 1.0),
			"variable.builtin": NSColor(srgbRed: 1.00, green: 0.3333, blue: 1.00, alpha: 1.0),
			"parameter": NSColor(srgbRed: 1.00, green: 1.00, blue: 0.3333, alpha: 1.0),
			"operator": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"punctuation.special": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"text.title": NSColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
			"diff.plus": NSColor(srgbRed: 0.3333, green: 1.00, blue: 0.3333, alpha: 1.0),
			// The palette's only red, so it wins the semantic argument at 4.2:1 — a
			// shade under AA, and the one place this theme trades contrast for accuracy.
			"diff.minus": NSColor(srgbRed: 1.00, green: 0.3333, blue: 0.3333, alpha: 1.0)
		]
	)
}
