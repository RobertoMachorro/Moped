//
//  WhitespaceLayoutManager.swift
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

/// One whitespace marker to paint, in text container coordinates.
struct WhitespaceMarker: Equatable {
	enum Kind {
		case space
		case tab
	}

	let kind: Kind

	/// Top-left of the marker's own line box — the point `NSAttributedString.draw(at:)`
	/// takes in the editor's flipped coordinates.
	let origin: NSPoint
}

/// The editor's layout manager. On top of the text it has just painted it draws
/// whitespace markers — `·` for every space, `»` for every tab — when the setting is on.
///
/// A layout manager subclass rather than a `draw(_:)` override on the text view: the
/// glyph range and the container origin both arrive as parameters, so markers land
/// wherever TextKit actually put the glyphs, on every path that repaints, with no second
/// invalidation story to keep in sync. It also avoids the gutter's `ensureLayout` dance —
/// anything being drawn is by definition already laid out.
final class WhitespaceLayoutManager: NSLayoutManager {
	private static let spaceSymbol = "·"
	private static let tabSymbol = "»"

	var showsWhitespaceMarkers = false

	/// Pushed in from `MopedTextView.applyTheme()`: the layout manager cannot see
	/// `resolvedTheme` and has no way to ask for it.
	var markerColor: NSColor {
		didSet { rebuildMarkers() }
	}

	var markerFont: NSFont {
		didSet { rebuildMarkers() }
	}

	private var spaceMarker = NSAttributedString()
	private var tabMarker = NSAttributedString()

	/// Half the difference between a space's advance and the dot's, so the dot sits in the
	/// middle of the cell it stands for rather than against its left edge. Zero for a
	/// monospaced face; it earns its keep for the proportional fonts the picker still
	/// offers.
	private var spaceMarkerInset: CGFloat = 0

	init(font: NSFont, color: NSColor) {
		self.markerFont = font
		self.markerColor = color
		super.init()
		rebuildMarkers()
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
		super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
		guard showsWhitespaceMarkers else {
			return
		}
		// After `super`, never before: selection and find-bar highlights are painted in
		// `drawBackground(forGlyphRange:at:)`, so drawing here is what keeps markers
		// visible inside a selection rather than buried under it.
		for marker in whitespaceMarkers(forGlyphRange: glyphsToShow) {
			let symbol = marker.kind == .space ? spaceMarker : tabMarker
			symbol.draw(at: NSPoint(x: marker.origin.x + origin.x, y: marker.origin.y + origin.y))
		}
	}

	/// Markers to paint for `glyphRange`, in glyph order.
	///
	/// Split out of `drawGlyphs` for the reason `LineNumberRulerView.visibleLineNumbers(for:)`
	/// was split out of the gutter's draw: geometry only ever exercised inside a graphics
	/// context is geometry nothing can assert on.
	func whitespaceMarkers(forGlyphRange glyphRange: NSRange) -> [WhitespaceMarker] {
		guard glyphRange.length > 0, let content = textStorage?.string as NSString? else {
			return []
		}
		let textRange = characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
		guard textRange.length > 0 else {
			return []
		}
		var characters = [unichar](repeating: 0, count: textRange.length)
		content.getCharacters(&characters, range: textRange)

		let baseline = defaultBaselineOffset(for: markerFont)
		var markers: [WhitespaceMarker] = []
		var fragment = NSRect.zero
		var fragmentGlyphs = NSRange(location: NSNotFound, length: 0)

		for offset in 0..<characters.count {
			guard let kind = Self.markerKind(for: characters[offset]) else {
				continue
			}
			let glyphIndex = glyphIndexForCharacter(at: textRange.location + offset)
			guard NSLocationInRange(glyphIndex, glyphRange) else {
				continue
			}
			// One fragment lookup per line rather than one per marker: an indented line is
			// a run of adjacent spaces that all share a fragment. `withoutAdditionalLayout`
			// because this runs inside a draw, where forcing layout re-enters TextKit.
			if !NSLocationInRange(glyphIndex, fragmentGlyphs) {
				fragment = lineFragmentRect(
					forGlyphAt: glyphIndex,
					effectiveRange: &fragmentGlyphs,
					withoutAdditionalLayout: true
				)
			}
			// `location(forGlyphAt:)` is relative to the fragment, and its `y` is the
			// baseline. Expressing everything against the fragment the glyph is actually in
			// is what makes a wrapped line need no special case.
			let position = location(forGlyphAt: glyphIndex)
			let inset = kind == .space ? spaceMarkerInset : 0
			markers.append(
				WhitespaceMarker(
					kind: kind,
					origin: NSPoint(
						x: fragment.minX + position.x + inset,
						y: fragment.minY + position.y - baseline
					)
				)
			)
		}
		return markers
	}

	/// A tab's marker sits at the **leading edge** of its advance, not centred in it:
	/// the advance runs to the next tab stop, so a centred chevron would slide sideways
	/// whenever text ahead of it changed, which reads as a rendering bug.
	private static func markerKind(for character: unichar) -> WhitespaceMarker.Kind? {
		switch character {
		case 0x20:
			return .space
		case 0x09:
			return .tab
		default:
			return nil
		}
	}

	private func rebuildMarkers() {
		let attributes: [NSAttributedString.Key: Any] = [.font: markerFont, .foregroundColor: markerColor]
		spaceMarker = NSAttributedString(string: Self.spaceSymbol, attributes: attributes)
		tabMarker = NSAttributedString(string: Self.tabSymbol, attributes: attributes)

		// Measured off the attributed string rather than off the font's own metrics, so
		// the centring stays right when the editor font has no `·` and AppKit substitutes
		// a face that does.
		let spaceWidth = (" " as NSString).size(withAttributes: [.font: markerFont]).width
		spaceMarkerInset = (spaceWidth - spaceMarker.size().width) / 2.0
	}
}
