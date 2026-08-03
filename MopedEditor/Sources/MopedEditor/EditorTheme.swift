//
//  EditorTheme.swift
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

/// Editor theme: window-chrome colors plus a token→color map keyed by `TokenKind`
/// raw values.
///
/// A theme is one palette. It may additionally carry a second palette in
/// `darkVariant`, in which case it follows the effective appearance — see
/// `resolved(for:)`. Everything that draws works with a resolved theme, never with the
/// pair.
///
/// `Sendable` holds here: AppKit declares `NSColor` as `Sendable`, and every colour
/// a built-in theme carries is a plain sRGB component colour. None of them are
/// catalog or dynamic system colours, which are the ones that would resolve lazily
/// against the current appearance. Keep it that way if new themes are added — a
/// theme built from `NSColor.controlAccentColor` and friends would reintroduce
/// exactly that deferred resolution. Themes read from a `.mopedtheme` file get this
/// for free: the file format carries hex, which can only parse to component colours.
public struct MopedTheme: Sendable {
	public let name: String
	public let background: NSColor
	public let foreground: NSColor
	public let gutterBackground: NSColor
	public let gutterForeground: NSColor
	public let selection: NSColor
	public let caret: NSColor
	public let tokenColors: [String: NSColor]

	/// A struct cannot store itself, so the dark palette lives behind a reference. The
	/// box is immutable and holds one `Sendable` value, so it is `Sendable` too.
	private final class DarkBox: Sendable {
		let theme: MopedTheme
		init(_ theme: MopedTheme) { self.theme = theme }
	}

	private let darkBox: DarkBox?

	/// The palette to use under a dark appearance, or `nil` for a theme that looks the
	/// same in both. Never itself paired: `paired(withDark:)` unwraps.
	public var darkVariant: MopedTheme? { darkBox?.theme }

	/// `caret` defaults to the inverse of the background, which is what the editor has
	/// always drawn. Themes whose background is a system colour pass it explicitly —
	/// inverting the system text background gives a caret that is wrong in both
	/// appearances.
	public init(
		name: String,
		background: NSColor,
		foreground: NSColor,
		gutterBackground: NSColor,
		gutterForeground: NSColor,
		selection: NSColor,
		caret: NSColor? = nil,
		tokenColors: [String: NSColor]
	) {
		self.name = name
		self.background = background
		self.foreground = foreground
		self.gutterBackground = gutterBackground
		self.gutterForeground = gutterForeground
		self.selection = selection
		self.caret = caret ?? Self.inverse(of: background)
		self.tokenColors = tokenColors
		self.darkBox = nil
	}

	private init(light: MopedTheme, dark: MopedTheme, name: String) {
		self.name = name
		self.background = light.background
		self.foreground = light.foreground
		self.gutterBackground = light.gutterBackground
		self.gutterForeground = light.gutterForeground
		self.selection = light.selection
		self.caret = light.caret
		self.tokenColors = light.tokenColors
		// Renaming the dark palette too keeps `resolved(for:)` from handing the editor a
		// theme whose `name` disagrees with the stored preference.
		self.darkBox = DarkBox(dark.renamed(name))
	}

	/// Pairs this palette, treated as the light one, with a palette for dark
	/// appearances. Both keep `name`; any pairing either side already had is dropped.
	public func paired(withDark dark: MopedTheme) -> MopedTheme {
		MopedTheme(light: self, dark: dark, name: name)
	}

	/// The palette that actually applies under `appearance`. A theme with no dark
	/// variant resolves to itself, so callers never need to check first.
	public func resolved(for appearance: NSAppearance) -> MopedTheme {
		guard let dark = darkVariant else {
			return self
		}
		return appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : self
	}

	/// Color for a token kind, falling back to the plain foreground.
	public func color(for kind: TokenKind) -> NSColor {
		tokenColors[kind.rawValue] ?? foreground
	}

	/// The same palette under a different name, unpaired.
	func renamed(_ name: String) -> MopedTheme {
		MopedTheme(
			name: name,
			background: background,
			foreground: foreground,
			gutterBackground: gutterBackground,
			gutterForeground: gutterForeground,
			selection: selection,
			caret: caret,
			tokenColors: tokenColors
		)
	}

	private static func inverse(of color: NSColor) -> NSColor {
		let resolved = color.usingColorSpace(.sRGB)
			?? color.usingColorSpace(.deviceRGB)
			?? color.usingColorSpace(.genericRGB)

		guard let rgb = resolved else {
			return .black
		}
		var red: CGFloat = 1
		var green: CGFloat = 1
		var blue: CGFloat = 1
		var alpha: CGFloat = 1
		rgb.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
		return NSColor(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
	}
}
