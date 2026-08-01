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
	/// no current-line highlight applies.
	private func caretLineRect() -> NSRect? {
		let selection = selectedRange()
		guard selection.length == 0,
			  let layoutManager,
			  let textContainer,
			  let content = textStorage?.string as NSString?
		else {
			return nil
		}
		let caret = min(selection.location, content.length)
		let lineRange = content.lineRange(for: NSRange(location: caret, length: 0))
		let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
		var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
		lineRect.origin.x = 0
		lineRect.size.width = bounds.width
		lineRect.origin.y += textContainerInset.height
		return lineRect
	}

	public override func drawBackground(in rect: NSRect) {
		super.drawBackground(in: rect)
		guard let lineRect = caretLineRect() else {
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
		let current = caretLineRect()
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
