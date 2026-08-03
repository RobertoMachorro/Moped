//
//  LineNumberRulerView.swift
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

/// Line number gutter. Numbers logical lines (a wrapped line is numbered once, on
/// its first fragment) and highlights the line holding the caret.
final class LineNumberRulerView: NSRulerView {
	private static let horizontalPadding: CGFloat = 6.0

	var theme: MopedTheme {
		didSet { needsDisplay = true }
	}

	var numberFont: NSFont {
		didSet {
			lineStartsAreStale = true
			needsDisplay = true
		}
	}

	/// Character offsets where each line starts. Spliced on edits, rebuilt lazily when
	/// there is no edited range to splice against.
	private var lineStarts: [Int] = [0]
	private var lineStartsAreStale = true

	/// Line count the gutter would draw, performing the pending rebuild if there is one.
	/// Exposed for tests, which otherwise have no way to observe the offset array
	/// without a live graphics context.
	var knownLineCount: Int {
		guard let content = (clientView as? NSTextView)?.string as NSString? else {
			return lineStarts.count
		}
		return currentLineStarts(for: content).count
	}

	init(textView: NSTextView, theme: MopedTheme, numberFont: NSFont) {
		self.theme = theme
		self.numberFont = numberFont
		super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
		clientView = textView
		ruleThickness = 40.0

		// The storage notification rather than `NSText.didChangeNotification`: only this
		// one carries the edited range and length delta the splice needs.
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(storageDidProcessEditing(_:)),
			name: NSTextStorage.didProcessEditingNotification,
			object: textView.textStorage
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(selectionDidChange(_:)),
			name: NSTextView.didChangeSelectionNotification,
			object: textView
		)

		// Everything this view draws — the background fill, every number's Y, and which
		// lines are in range — is a function of the clip view's scroll offset, but
		// scrolling does not invalidate a ruler on its own. The clip view blits what is
		// already on screen and only repaints the newly exposed strip, so without this
		// the gutter keeps the pixels it drew at offset zero: numbers slide up out of
		// view and the strip revealed at the bottom is never painted at all.
		if let clipView = scrollView?.contentView {
			clipView.postsBoundsChangedNotifications = true
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(clipViewDidScroll(_:)),
				name: NSView.boundsDidChangeNotification,
				object: clipView
			)
		}
	}

	@available(*, unavailable)
	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	/// Call after any programmatic text replacement, which doesn't post
	/// `NSText.didChangeNotification`.
	func invalidateLineNumbers() {
		lineStartsAreStale = true
		needsDisplay = true
	}

	/// Splices the offset array instead of rebuilding it, so an edit costs work
	/// proportional to the edit rather than a full rescan of the document.
	@objc private func storageDidProcessEditing(_ notification: Notification) {
		guard let storage = notification.object as? NSTextStorage,
			  storage.editedMask.contains(.editedCharacters)
		else {
			return
		}
		// Nothing to splice onto when a full rebuild is already pending — and splicing
		// a stale array would be wrong. The rebuild still has to reach the screen,
		// so the redraw is requested either way.
		guard !lineStartsAreStale else {
			needsDisplay = true
			return
		}
		lineStarts = LineIndex.splice(
			lineStarts,
			in: storage.string as NSString,
			editedRange: storage.editedRange,
			changeInLength: storage.changeInLength
		)
		updateThickness(forLineCount: lineStarts.count)
		needsDisplay = true
	}

	@objc private func selectionDidChange(_ notification: Notification) {
		needsDisplay = true
	}

	/// The whole gutter, not a band: the numbers move relative to the ruler on every
	/// scroll, so there is no partial invalidation to make here.
	@objc private func clipViewDidScroll(_ notification: Notification) {
		needsDisplay = true
	}

	override func drawHashMarksAndLabels(in rect: NSRect) {
		theme.gutterBackground.setFill()
		bounds.fill()

		guard let textView = clientView as? NSTextView,
			  let layoutManager = textView.layoutManager,
			  let textContainer = textView.textContainer
		else {
			return
		}

		drawSeparator()

		let visibleRect = scrollView?.contentView.bounds ?? textView.visibleRect
		let starts = currentLineStarts(for: textView.string as NSString)
		let caretLine = LineIndex.index(containing: textView.selectedRange().location, in: starts)
		let inset = textView.textContainerInset.height

		for index in visibleLineNumbers(for: visibleRect) {
			let glyphIndex = layoutManager.glyphIndexForCharacter(at: starts[index])
			let fragment = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
			let originY = fragment.minY + inset - visibleRect.minY
			draw(number: index + 1, atY: originY, height: fragment.height, isCaretLine: index == caretLine)
		}
	}

	/// Zero-based logical line indices the gutter should number for `visibleRect`, which
	/// arrives in the clip view's coordinates.
	///
	/// Split out of `drawHashMarksAndLabels` because a wrong range is invisible until
	/// somebody looks at the screen: drawing needs a graphics context, so nothing could
	/// assert on the range that actually broke.
	func visibleLineNumbers(for visibleRect: NSRect) -> Range<Int> {
		guard let textView = clientView as? NSTextView,
			  let layoutManager = textView.layoutManager,
			  let textContainer = textView.textContainer
		else {
			return 0..<0
		}

		// The clip view's coordinates are the text view's; the container's are inset by
		// `textContainerInset`. Placing the numbers already accounts for that, so the
		// query has to as well or it asks about a band 4pt off from the one it draws.
		let queryRect = visibleRect.offsetBy(dx: 0, dy: -textView.textContainerInset.height)

		// `allowsNonContiguousLayout` is on, so `glyphRange(forBoundingRect:)` reports
		// only what happens to be laid out already. Without this the range comes back
		// short for a region scrolled into for the first time, and numbering stops
		// partway down with nothing to indicate it went wrong.
		layoutManager.ensureLayout(forBoundingRect: queryRect, in: textContainer)

		let visibleGlyphs = layoutManager.glyphRange(forBoundingRect: queryRect, in: textContainer)
		let visibleChars = layoutManager.characterRange(forGlyphRange: visibleGlyphs, actualGlyphRange: nil)
		let starts = currentLineStarts(for: textView.string as NSString)

		let first = LineIndex.index(containing: visibleChars.location, in: starts)
		var last = first
		while last < starts.count, starts[last] <= NSMaxRange(visibleChars) {
			last += 1
		}
		return first..<last
	}

	private func draw(number: Int, atY originY: CGFloat, height: CGFloat, isCaretLine: Bool) {
		let color = isCaretLine ? theme.foreground : theme.gutterForeground
		let label = NSAttributedString(
			string: "\(number)",
			attributes: [.font: numberFont, .foregroundColor: color]
		)
		let size = label.size()
		let originX = ruleThickness - size.width - Self.horizontalPadding
		let centeredY = originY + (numberFont.ascender - numberFont.descender < height
			? (height - size.height) / 2.0
			: 0.0)
		label.draw(at: NSPoint(x: originX, y: centeredY))
	}

	private func drawSeparator() {
		theme.gutterForeground.withAlphaComponent(0.3).setStroke()
		let path = NSBezierPath()
		path.move(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY))
		path.line(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
		path.lineWidth = 1.0
		path.stroke()
	}

	// MARK: Line bookkeeping

	/// Full rebuild, used only when there is no edited range to splice against:
	/// programmatic replacement via `setPlainText`, and font changes.
	private func currentLineStarts(for content: NSString) -> [Int] {
		if lineStartsAreStale {
			lineStarts = LineIndex.lineStarts(of: content)
			lineStartsAreStale = false
			updateThickness(forLineCount: lineStarts.count)
		}
		return lineStarts
	}

	/// Widens the gutter to fit the largest line number, **on a later runloop turn**.
	///
	/// Assigning `ruleThickness` makes the scroll view re-tile. Both callers reach here
	/// from somewhere that must not be re-entered: `currentLineStarts` is called from
	/// inside `drawHashMarksAndLabels`, and `storageDidProcessEditing` runs inside
	/// `NSTextStorage.processEditing`. Re-tiling from either one re-lays out the ruler
	/// and clip view underneath code that has already captured their geometry, and left
	/// the ruler at a stale height — numbering stopped partway down the viewport and the
	/// strip below it never got painted, which was invisible until a theme shipped with
	/// a gutter that did not match `NSRulerView`'s own light background.
	///
	/// Deferring is the same move `SyntaxHighlighter` makes for the same reason.
	private func updateThickness(forLineCount count: Int) {
		let widest = NSAttributedString(string: "\(max(count, 1))", attributes: [.font: numberFont])
		let thickness = max(28.0, widest.size().width + Self.horizontalPadding * 2.0)
		guard abs(thickness - ruleThickness) > 0.5 else {
			return
		}
		DispatchQueue.main.async { [weak self] in
			guard let self, abs(thickness - self.ruleThickness) > 0.5 else {
				return
			}
			self.ruleThickness = thickness
			self.needsDisplay = true
		}
	}
}
