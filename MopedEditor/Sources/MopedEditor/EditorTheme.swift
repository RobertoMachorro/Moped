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
/// `Sendable` holds here: AppKit declares `NSColor` as `Sendable`, and every colour
/// a built-in theme carries is a plain sRGB component colour. None of them are
/// catalog or dynamic system colours, which are the ones that would resolve lazily
/// against the current appearance. Keep it that way if new themes are added — a
/// theme built from `NSColor.controlAccentColor` and friends would reintroduce
/// exactly that deferred resolution.
public struct MopedTheme: Sendable {
	public let name: String
	public let background: NSColor
	public let foreground: NSColor
	public let gutterBackground: NSColor
	public let gutterForeground: NSColor
	public let selection: NSColor
	public let tokenColors: [String: NSColor]

	public init(
		name: String,
		background: NSColor,
		foreground: NSColor,
		gutterBackground: NSColor,
		gutterForeground: NSColor,
		selection: NSColor,
		tokenColors: [String: NSColor]
	) {
		self.name = name
		self.background = background
		self.foreground = foreground
		self.gutterBackground = gutterBackground
		self.gutterForeground = gutterForeground
		self.selection = selection
		self.tokenColors = tokenColors
	}

	/// Color for a token kind, falling back to the plain foreground.
	public func color(for kind: TokenKind) -> NSColor {
		tokenColors[kind.rawValue] ?? foreground
	}
}
