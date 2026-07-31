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

	/// Character offsets where each line starts; rebuilt lazily after edits.
	private var lineStarts: [Int] = [0]
	private var lineStartsAreStale = true

	init(textView: NSTextView, theme: MopedTheme, numberFont: NSFont) {
		self.theme = theme
		self.numberFont = numberFont
		super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
		clientView = textView
		ruleThickness = 40.0

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(textDidChange(_:)),
			name: NSText.didChangeNotification,
			object: textView
		)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(selectionDidChange(_:)),
			name: NSTextView.didChangeSelectionNotification,
			object: textView
		)
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

	@objc private func textDidChange(_ notification: Notification) {
		invalidateLineNumbers()
	}

	@objc private func selectionDidChange(_ notification: Notification) {
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

		let content = textView.string as NSString
		let visibleRect = scrollView?.contentView.bounds ?? textView.visibleRect
		let visibleGlyphs = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
		let visibleChars = layoutManager.characterRange(forGlyphRange: visibleGlyphs, actualGlyphRange: nil)

		let starts = currentLineStarts(for: content)
		let caretLine = LineIndex.index(containing: textView.selectedRange().location, in: starts)
		var index = LineIndex.index(containing: visibleChars.location, in: starts)
		let inset = textView.textContainerInset.height

		while index < starts.count, starts[index] <= NSMaxRange(visibleChars) {
			let glyphIndex = layoutManager.glyphIndexForCharacter(at: starts[index])
			let fragment = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
			let originY = fragment.minY + inset - visibleRect.minY
			draw(number: index + 1, atY: originY, height: fragment.height, isCaretLine: index == caretLine)
			index += 1
		}
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

	/// Rebuilds the whole offset array whenever the text changed. Splicing it the way
	/// `LineStore.noteEdit` does would make this proportional to the edit rather than
	/// the document; that rewrite is why editing cost still grows with file size.
	private func currentLineStarts(for content: NSString) -> [Int] {
		if lineStartsAreStale {
			lineStarts = LineIndex.lineStarts(of: content)
			lineStartsAreStale = false
			updateThickness(forLineCount: lineStarts.count)
		}
		return lineStarts
	}

	private func updateThickness(forLineCount count: Int) {
		let widest = NSAttributedString(string: "\(max(count, 1))", attributes: [.font: numberFont])
		let thickness = max(28.0, widest.size().width + Self.horizontalPadding * 2.0)
		if abs(thickness - ruleThickness) > 0.5 {
			ruleThickness = thickness
		}
	}
}
