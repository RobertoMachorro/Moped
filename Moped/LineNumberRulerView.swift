//
//  LineNumberRulerView.swift
//
//  Moped - A general purpose text editor, small and light.
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

import Cocoa

class LineNumberRulerView: NSRulerView {
	weak var textView: NSTextView?

	var font: NSFont = NSFont.userFixedPitchFont(ofSize: 10) ?? NSFont.systemFont(ofSize: 10) {
		didSet {
			updateRuleThickness()
			needsDisplay = true
		}
	}

	private let padding: CGFloat = 5.0
	private let minimumRuleThickness: CGFloat = 40
	private var cachedLineCount: Int?
	private var deferredRecalcWorkItem: DispatchWorkItem?
	private var hasScheduledInitialThickness = false

	convenience init(textView: NSTextView) {
		self.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
		self.textView = textView
		clientView = textView
		ruleThickness = minimumRuleThickness
		updateRuleThickness()

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(textDidChange),
			name: NSText.didChangeNotification,
			object: textView
		)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(boundsDidChange),
			name: NSView.boundsDidChangeNotification,
			object: textView.enclosingScrollView?.contentView
		)
		
		if !hasScheduledInitialThickness {
			hasScheduledInitialThickness = true
			let work = DispatchWorkItem { [weak self] in
				self?.recalculateThicknessFromFullText()
			}
			deferredRecalcWorkItem = work
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: work)
		}
	}

	override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
		super.init(scrollView: scrollView, orientation: orientation)
	}

	required init(coder: NSCoder) {
		super.init(coder: coder)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	override var isFlipped: Bool {
		return true
	}

	@objc private func textDidChange(_ notification: Notification) {
		cachedLineCount = nil
		updateRuleThickness()
		needsDisplay = true

		deferredRecalcWorkItem?.cancel()
		let work = DispatchWorkItem { [weak self] in
			self?.recalculateThicknessFromFullText()
		}
		deferredRecalcWorkItem = work
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: work)
	}

	@objc private func boundsDidChange(_ notification: Notification) {
		needsDisplay = true
	}

	override func drawHashMarksAndLabels(in rect: NSRect) {
		guard let textView = textView,
			  let scrollView = textView.enclosingScrollView,
			  let layoutManager = textView.layoutManager,
			  let textContainer = textView.textContainer else {
			return
		}

		layoutManager.ensureLayout(for: textContainer)
		drawBackgroundAndDivider()

		let visibleRect = scrollView.contentView.bounds
		let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
		let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

		guard characterRange.location != NSNotFound else {
			return
		}

		let textColor = NSColor.secondaryLabelColor
		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: textColor
		]

		let lineNumber = startingLineNumber(
			in: textView,
			characterRange: characterRange
		)
		drawLineNumbers(
			in: glyphRange,
			layoutManager: layoutManager,
			textView: textView,
			startingLineNumber: lineNumber,
			attributes: attributes
		)
	}

	private func drawBackgroundAndDivider() {
		NSColor.windowBackgroundColor.setFill()
		bounds.fill()

		guard let scrollView = scrollView else {
			return
		}

		let contentRect = convert(scrollView.contentView.frame, from: scrollView).intersection(bounds)
		guard !contentRect.isEmpty else {
			return
		}

		NSColor.separatorColor.setStroke()
		let dividerPath = NSBezierPath()
		dividerPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: contentRect.minY))
		dividerPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: contentRect.maxY))
		dividerPath.lineWidth = 1
		dividerPath.stroke()
	}

	private func startingLineNumber(
		in textView: NSTextView,
		characterRange: NSRange
	) -> Int {
		let textString = textView.string as NSString
		var lineNumber = 1
		var charIndex = 0
		while charIndex < textString.length && charIndex < characterRange.location {
			if textString.character(at: charIndex) == 0x0A {
				lineNumber += 1
			}
			charIndex += 1
		}
		return lineNumber
	}

	private func drawLineNumbers(
		in glyphRange: NSRange,
		layoutManager: NSLayoutManager,
		textView: NSTextView,
		startingLineNumber: Int,
		attributes: [NSAttributedString.Key: Any]
	) {
		guard let scrollView = textView.enclosingScrollView else {
			return
		}

		let visibleRect = scrollView.contentView.bounds
		var lineNumber = startingLineNumber
		var glyphIndex = glyphRange.location
		while glyphIndex < NSMaxRange(glyphRange) {
			var lineRange = NSRange(location: 0, length: 0)
			let lineRect = layoutManager.lineFragmentRect(
				forGlyphAt: glyphIndex,
				effectiveRange: &lineRange
			)
			let yPosition = lineRect.origin.y - visibleRect.origin.y + textView.textContainerOrigin.y

			if yPosition + lineRect.height >= 0 && yPosition <= bounds.height {
				let lineNumberString = String(lineNumber)
				let size = (lineNumberString as NSString).size(withAttributes: attributes)
				let xPosition = ruleThickness - size.width - padding
				let drawPoint = NSPoint(
					x: xPosition,
					y: yPosition + (lineRect.height - size.height) / 2
				)
				(lineNumberString as NSString).draw(at: drawPoint, withAttributes: attributes)
			}

			lineNumber += 1
			glyphIndex = NSMaxRange(lineRange)
		}
	}

	private func updateRuleThickness() {
		guard let textView = textView else {
			return
		}

		let lineCount = cachedLineCount
		let numberOfDigits: Int
		if let lineCount {
			numberOfDigits = max(String(lineCount).count, 2)
		} else {
			// Avoid scanning the entire text during initial layout/typing; use a minimal estimate.
			numberOfDigits = 2
		}

		let widthSample = String(repeating: "8", count: numberOfDigits)
		let labelWidth = (widthSample as NSString).size(withAttributes: [.font: font]).width
		ruleThickness = max(minimumRuleThickness, ceil(labelWidth + (padding * 2)))
	}

	private func recalculateThicknessFromFullText() {
		guard let textView = textView else { return }

		// Use NSString's UTF-16 based scanning for better performance
		let string = textView.string as NSString
		var count = 1
		let length = string.length
		var index = 0

		while index < length {
			if string.character(at: index) == 0x0A {
				count += 1
			}
			index += 1
		}

		cachedLineCount = count
		updateRuleThickness()
	}
}
