//
//  WhitespaceMarkerTests.swift
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

import XCTest
@testable import MopedEditor

/// The whitespace markers are pure paint, so nothing about them can be observed through
/// the text or its attributes. These go through `whitespaceMarkers(forGlyphRange:)`, the
/// list the draw loop iterates — the same seam `visibleLineNumbers(for:)` opened for the
/// gutter.
final class WhitespaceMarkerTests: EditorTestCase {
	private func manager(of textView: MopedTextView) throws -> WhitespaceLayoutManager {
		try XCTUnwrap(textView.layoutManager as? WhitespaceLayoutManager)
	}

	/// `whitespaceMarkers` reads geometry without forcing layout, because in the app it
	/// only ever runs inside a draw. Outside one, layout has to be forced first or every
	/// rect comes back zero.
	private func markers(in textView: MopedTextView) throws -> [WhitespaceMarker] {
		let layoutManager = try manager(of: textView)
		let textContainer = try XCTUnwrap(textView.textContainer)
		layoutManager.ensureLayout(for: textContainer)
		return layoutManager.whitespaceMarkers(
			forGlyphRange: layoutManager.glyphRange(for: textContainer)
		)
	}

	/// Pins the "every space and tab, not just the indentation" decision: a marker for the
	/// spaces between words and inside the comment too, and none for anything else.
	func testEverySpaceAndTabGetsAMarker() throws {
		let (_, textView) = makeEditor()
		let content = "\tlet a = 1 // two words\n  b = 2\n"
		textView.showsWhitespaceMarkers = true
		textView.setPlainText(content)

		let expected: [WhitespaceMarker.Kind] = content.compactMap {
			switch $0 {
			case " ": return .space
			case "\t": return .tab
			default: return nil
			}
		}
		let produced = try markers(in: textView).map(\.kind)

		XCTAssertEqual(
			produced, expected,
			"every space and tab in the document should get exactly one marker, in order, "
				+ "and nothing else should get one"
		)
	}

	/// The markers are display-only. Nothing may reach the text, or toggling the setting
	/// would dirty the document and land on the undo stack.
	func testMarkersDoNotTouchTheText() throws {
		let (_, textView) = makeEditor()
		textView.setPlainText("\ta = 1\n")
		textView.showsWhitespaceMarkers = true

		XCTAssertEqual(textView.string, "\ta = 1\n", "drawing markers must not rewrite the text")
		XCTAssertFalse(try markers(in: textView).isEmpty, "the markers should still be produced")
	}

	/// A tab's advance runs to the next tab stop, so a chevron centred in it would slide
	/// sideways whenever text ahead of it changed. It belongs at the leading edge.
	func testTabMarkerSitsAtTheLeadingEdgeOfItsAdvance() throws {
		let (_, textView) = makeEditor()
		textView.showsWhitespaceMarkers = true
		textView.setPlainText("a\tb")

		let layoutManager = try manager(of: textView)
		let textContainer = try XCTUnwrap(textView.textContainer)
		layoutManager.ensureLayout(for: textContainer)

		let tabMarker = try XCTUnwrap(try markers(in: textView).first { $0.kind == .tab })
		let fragment = layoutManager.lineFragmentRect(forGlyphAt: 1, effectiveRange: nil)
		let tabStart = fragment.minX + layoutManager.location(forGlyphAt: 1).x
		let nextCharacter = fragment.minX + layoutManager.location(forGlyphAt: 2).x

		XCTAssertEqual(
			tabMarker.origin.x, tabStart, accuracy: 0.5,
			"the chevron belongs where the tab's advance starts, not at the tab stop it runs to"
		)
		XCTAssertLessThan(
			tabMarker.origin.x, nextCharacter,
			"the chevron must sit inside the tab's own advance, ahead of the character after it"
		)
	}

	/// Markers are placed against the fragment the glyph is actually in, which is the whole
	/// reason a wrapped line needs no special case. If they were placed against the line
	/// they would all pile onto one row.
	func testWrappedLineMarksEveryVisualRow() throws {
		let (_, textView) = makeEditor()
		textView.wrapsLines = true
		textView.showsWhitespaceMarkers = true
		textView.setPlainText(String(repeating: "word ", count: 200))

		let rows = Set(try markers(in: textView).map { $0.origin.y.rounded() })

		XCTAssertGreaterThan(
			rows.count, 1,
			"a line wrapped across the 600pt test viewport should place markers on every "
				+ "visual row it occupies, not all on the first"
		)
	}

	/// Doubling the font size has to move the markers with the glyphs they annotate,
	/// because the whole placement is derived from live layout rather than from constants.
	///
	/// Measured as the gap between two markers on one line rather than as an absolute x:
	/// an absolute x also carries the text container's line-fragment padding, which is a
	/// fixed 5pt and quite rightly does not scale with the font.
	func testMarkersScaleWithTheEditorFont() throws {
		let (_, textView) = makeEditor()
		textView.showsWhitespaceMarkers = true
		textView.setPlainText("a b c\nd e f\n")

		let small = try markers(in: textView)
		textView.editorFont = NSFontManager.shared.convert(
			textView.editorFont, toSize: textView.editorFont.pointSize * 2
		)
		let large = try markers(in: textView)

		XCTAssertEqual(small.count, 4, "two spaces on each of the two lines")
		XCTAssertEqual(large.count, small.count, "a font change cannot change how many markers there are")

		let smallGap = small[1].origin.x - small[0].origin.x
		let largeGap = large[1].origin.x - large[0].origin.x
		XCTAssertEqual(
			largeGap, smallGap * 2, accuracy: 0.5,
			"two markers a fixed number of characters apart should separate by twice as much "
				+ "at twice the font size"
		)

		let smallSecondLine = try XCTUnwrap(small.last)
		let largeSecondLine = try XCTUnwrap(large.last)
		XCTAssertGreaterThan(
			largeSecondLine.origin.y, smallSecondLine.origin.y,
			"the second line sits lower once the lines are twice as tall"
		)
	}

	/// The seam tests all stop at the list of markers. This is the only one that proves the
	/// draw override paints them: it renders the view and looks at the pixels where a space
	/// is, which stay pure background until markers are turned on.
	func testSpacesArePaintedIntoTheView() throws {
		let (scrollView, textView) = makeEditor(theme: .defaultLightPalette)
		let window = NSWindow(
			contentRect: scrollView.frame, styleMask: [.titled],
			backing: .buffered, defer: false
		)
		window.contentView = scrollView
		textView.setPlainText("a b\n")
		drainHighlightPasses()

		// Locate the cell from the marker's own geometry rather than guessing at
		// coordinates: `origin` is in container space, the view is inset by
		// `textContainerInset`, and a marker is about one line tall.
		let marker = try XCTUnwrap(try markers(in: textView).first)
		let cell = NSRect(
			x: marker.origin.x + textView.textContainerInset.width,
			y: marker.origin.y + textView.textContainerInset.height,
			width: try XCTUnwrap(textView.layoutManager?.defaultLineHeight(for: textView.editorFont)),
			height: try XCTUnwrap(textView.layoutManager?.defaultLineHeight(for: textView.editorFont))
		)

		// Compared against the same region drawn without markers rather than against the
		// theme's background: the caret-line band already tints the whole first line, so
		// "differs from the background" would be true either way. Nothing but the setting
		// changes between the two renders, so any difference is the marker.
		let blank = try render(textView, in: cell)
		textView.showsWhitespaceMarkers = true
		let marked = try render(textView, in: cell)

		XCTAssertNotEqual(
			blank, marked,
			"turning markers on has to actually paint a dot where the space is"
		)
	}

	private func render(_ textView: MopedTextView, in rect: NSRect) throws -> Data {
		let rep = try XCTUnwrap(textView.bitmapImageRepForCachingDisplay(in: rect))
		textView.cacheDisplay(in: rect, to: rep)
		return try XCTUnwrap(rep.tiffRepresentation)
	}

	/// The layout manager cannot see `resolvedTheme`, so the color has to be pushed in from
	/// `applyTheme()`. That is also the funnel a light/dark flip goes through, and a marker
	/// left on the light palette's color would be invisible on a dark background.
	func testMarkerColorFollowsTheThemeAndTheAppearance() throws {
		let (_, textView) = makeEditor(theme: .turboPalette)
		let layoutManager = try manager(of: textView)

		XCTAssertEqual(
			layoutManager.markerColor,
			textView.resolvedTheme.foreground.withAlphaComponent(0.3),
			"markers are drawn from the palette's own foreground, faded back to chrome"
		)

		textView.theme = MopedTheme.defaultLightPalette.paired(withDark: .defaultDarkPalette)
		textView.appearance = NSAppearance(named: .darkAqua)
		textView.viewDidChangeEffectiveAppearance()

		XCTAssertEqual(
			layoutManager.markerColor,
			textView.resolvedTheme.foreground.withAlphaComponent(0.3),
			"flipping to dark has to re-tint the markers along with the rest of the palette"
		)
	}
}
