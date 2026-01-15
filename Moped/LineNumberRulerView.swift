//
//  LineNumberRulerView.swift
//
//  Moped - A general purpose text editor, small and light.
//  Copyright © 2019-2024 Roberto Machorro. All rights reserved.
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

final class LineNumberRulerView: NSRulerView {
	private weak var textView: NSTextView?

	init(textView: NSTextView) {
		self.textView = textView
		let scrollView = textView.enclosingScrollView
		super.init(scrollView: scrollView, orientation: .verticalRuler)
		clientView = textView
		ruleThickness = 48
		setupObservers()
	}

	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	private func setupObservers() {
		guard let textView, let scrollView = textView.enclosingScrollView else {
			return
		}

		scrollView.contentView.postsBoundsChangedNotifications = true
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(handleBoundsDidChange),
			name: NSView.boundsDidChangeNotification,
			object: scrollView.contentView
		)

		if let textStorage = textView.textStorage {
			NotificationCenter.default.addObserver(
				self,
				selector: #selector(handleTextStorageDidProcessEditing),
				name: NSTextStorage.didProcessEditingNotification,
				object: textStorage
			)
		}
	}

	@objc private func handleBoundsDidChange() {
		needsDisplay = true
	}

	@objc private func handleTextStorageDidProcessEditing() {
		needsDisplay = true
	}

	override func drawHashMarksAndLabels(in rect: NSRect) {
		guard let textView = self.textView, let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else {
			return
		}

		NSColor.controlBackgroundColor.setFill()
		rect.fill()

		let textInset = textView.textContainerInset
		var visibleRect = textView.visibleRect
		visibleRect.origin.y -= textInset.height
		visibleRect.size.height += textInset.height * 2
		let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
		let visibleCharacterRange = layoutManager.characterRange(forGlyphRange: visibleGlyphRange, actualGlyphRange: nil)

		let font = textView.font ?? NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
		let lineHeight = layoutManager.defaultLineHeight(for: font)
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .right
		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: NSColor.secondaryLabelColor,
			.paragraphStyle: paragraphStyle
		]

		// Cast to NSString for line range methods - performed after visible range calculation for clarity
		let text = textView.string as NSString
		var lineNumber = 1
		if visibleCharacterRange.location > 0 {
			let prefix = text.substring(to: visibleCharacterRange.location)
			lineNumber = prefix.components(separatedBy: "\n").count
		}

		var lastLineStart: Int?
		layoutManager.enumerateLineFragments(forGlyphRange: visibleGlyphRange) { lineFragmentRect, _, _, glyphRange, _ in
			let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
			let lineRange = text.lineRange(for: NSRange(location: characterRange.location, length: 0))
			if lastLineStart == lineRange.location {
				return
			}
			lastLineStart = lineRange.location

			let lineRectInTextView = lineFragmentRect.offsetBy(dx: textView.textContainerOrigin.x, dy: textView.textContainerOrigin.y)
			let lineRectInRuler = convert(lineRectInTextView, from: textView)

			let yPosition = lineRectInRuler.minY + (lineRectInRuler.height - lineHeight) / 2
			let textRect = NSRect(x: 0, y: yPosition, width: bounds.width - 8, height: lineHeight)
			"\(lineNumber)".draw(in: textRect, withAttributes: attributes)
			lineNumber += 1
		}
	}
}
