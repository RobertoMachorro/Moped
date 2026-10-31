//
//  MopedTextView+CurrentLine.swift
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

/// The caret-line highlight: a tinted band behind the line holding the insertion
/// point, drawn only when there is no selection.
extension MopedTextView {
	/// Band to paint behind the caret's line, or nil when a non-empty selection means
	/// no current-line highlight applies, or when none of the line is inside `area`.
	///
	/// Measured from layout that already exists; this never lays text out. The layout
	/// manager lays out a whole paragraph at a time, so measuring the caret's line
	/// typeset all of it, and in a file that is one long line (minified JSON, a log) that
	/// is the whole file. That ran on every caret move, and at launch inside
	/// `setPlainText(_:)` before the view had its final width, so the work was thrown
	/// away and done again (#106). `drawBackground(in:)` lays out what it is about to
	/// draw before asking.
	///
	/// Where the line carries on past `area`, the band runs to the view's edge on that
	/// side. Painting is clipped to the dirty rect, so that changes nothing drawn, and a
	/// caret move invalidating the band still covers every part of the line.
	func caretLineRect(within area: NSRect) -> NSRect? {
		let selection = selectedRange()
		guard selection.length == 0,
			  !area.isEmpty,
			  let layoutManager,
			  let textContainer,
			  let content = textStorage?.string as NSString?
		else {
			return nil
		}
		let caret = min(selection.location, content.length)
		let lineRange = content.lineRange(for: NSRange(location: caret, length: 0))
		let areaGlyphs = layoutManager.glyphRange(
			forBoundingRectWithoutAdditionalLayout: containerRect(forViewRect: area), in: textContainer
		)
		let areaCharacters = layoutManager.characterRange(forGlyphRange: areaGlyphs, actualGlyphRange: nil)
		let shownRange: NSRange
		var lineRect: NSRect
		if lineRange.length == 0 {
			// The empty line after a trailing newline, drawn as the extra line fragment.
			guard NSMaxRange(areaCharacters) == content.length else {
				return nil
			}
			shownRange = lineRange
			lineRect = layoutManager.extraLineFragmentRect
		} else {
			shownRange = NSIntersectionRange(lineRange, areaCharacters)
			let glyphs = layoutManager.glyphRange(forCharacterRange: shownRange, actualCharacterRange: nil)
			guard glyphs.length > 0 else {
				return nil
			}
			// Line fragments rather than `boundingRect(forGlyphRange:)`, which lays out.
			let first = layoutManager.lineFragmentRect(
				forGlyphAt: glyphs.location, effectiveRange: nil, withoutAdditionalLayout: true
			)
			let last = layoutManager.lineFragmentRect(
				forGlyphAt: NSMaxRange(glyphs) - 1, effectiveRange: nil, withoutAdditionalLayout: true
			)
			lineRect = first.union(last)
		}
		lineRect.origin.x = 0
		lineRect.size.width = bounds.width
		lineRect.origin.y += textContainerInset.height
		if lineRange.location < shownRange.location {
			lineRect = NSRect(x: 0, y: bounds.minY, width: bounds.width, height: lineRect.maxY - bounds.minY)
		}
		if NSMaxRange(lineRange) > NSMaxRange(shownRange) {
			lineRect.size.height = bounds.maxY - lineRect.minY
		}
		return lineRect
	}

	public override func drawBackground(in rect: NSRect) {
		super.drawBackground(in: rect)
		// The visible rect as well as `rect`: a partial repaint must not make the band
		// look cut off, or the next caret move would invalidate the whole view. Only when
		// they touch, though: a rect far from it (a printed page, overdraw) would stretch
		// the union over everything in between.
		let area = rect.intersects(visibleRect) ? visibleRect.union(rect) : rect
		// AppKit calls this before laying out what it draws, so lay that out first. It is
		// the layout this draw does anyway.
		if selectedRange().length == 0, let layoutManager, let textContainer {
			layoutManager.ensureLayout(
				forBoundingRect: containerRect(forViewRect: area), in: textContainer
			)
		}
		guard let lineRect = caretLineRect(within: area) else {
			return
		}
		highlightedCaretLineRect = lineRect
		guard lineRect.intersects(rect) else {
			return
		}
		resolvedTheme.selection.withAlphaComponent(0.35).setFill()
		lineRect.fill()
	}

	public override func setSelectedRanges(
		_ ranges: [NSValue],
		affinity: NSSelectionAffinity,
		stillSelecting: Bool
	) {
		let previous = highlightedCaretLineRect
		super.setSelectedRanges(ranges, affinity: affinity, stillSelecting: stillSelecting)
		// Measured without laying out. Where the arriving line's layout is out of date
		// (an edit, a width change), this can be nil or off, but layout is only
		// invalidated together with display, so that line is repainted anyway and
		// `drawBackground` stores its real band.
		let current = caretLineRect(within: visibleRect)
		highlightedCaretLineRect = current

		// Only the line the caret left and the line it arrived on change appearance.
		// Repainting the whole view here cost a full redraw on every arrow key, which
		// is what made cursor movement scale with document size.
		if let previous {
			setNeedsDisplay(previous)
		}
		if let current, current != previous {
			setNeedsDisplay(current)
		}
	}
}
