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

class LineNumberGutterView: NSView {
	weak var textView: NSTextView?
	
	var font: NSFont = NSFont.userFixedPitchFont(ofSize: 10) ?? NSFont.systemFont(ofSize: 10) {
		didSet {
			needsDisplay = true
		}
	}
	
	private let padding: CGFloat = 5.0
	var gutterWidth: CGFloat = 40 {
		didSet {
			invalidateIntrinsicContentSize()
		}
	}
	
	init(textView: NSTextView) {
		self.textView = textView
		super.init(frame: NSRect.zero)
		
		// Make sure the view doesn't block interaction with text view
		// but still draws its content
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(textDidChange),
			name: NSText.didChangeNotification,
			object: textView
		)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(frameDidChange),
			name: NSView.frameDidChangeNotification,
			object: textView
		)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(boundsDidChange),
			name: NSView.boundsDidChangeNotification,
			object: textView.enclosingScrollView?.contentView
		)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override var isFlipped: Bool {
		return true
	}
	
	override var intrinsicContentSize: NSSize {
		return NSSize(width: gutterWidth, height: NSView.noIntrinsicMetric)
	}
	
	@objc private func textDidChange(_ notification: Notification) {
		needsDisplay = true
	}
	
	@objc private func frameDidChange(_ notification: Notification) {
		needsDisplay = true
	}
	
	@objc private func boundsDidChange(_ notification: Notification) {
		needsDisplay = true
	}
	
	override func draw(_ dirtyRect: NSRect) {
		guard let textView = textView,
			  let layoutManager = textView.layoutManager,
			  let textContainer = textView.textContainer else {
			return
		}
		
		// Draw TRANSPARENT background so text shows through
		NSColor.clear.setFill()
		dirtyRect.fill()
		
		// Draw background for gutter area only
		NSColor.controlBackgroundColor.setFill()
		bounds.fill()
		
		// Draw divider line
		NSColor.separatorColor.setStroke()
		let dividerPath = NSBezierPath()
		dividerPath.move(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY))
		dividerPath.line(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
		dividerPath.lineWidth = 1
		dividerPath.stroke()
		
		let visibleRect = textView.visibleRect
		let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
		let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
		
		guard characterRange.location != NSNotFound else {
			return
		}
		
		let textString = textView.string as NSString
		
		// Count lines before visible range
		var lineNumber = 1
		var charIndex = 0
		while charIndex < textString.length && charIndex < characterRange.location {
			if textString.character(at: charIndex) == 0x0A {
				lineNumber += 1
			}
			charIndex += 1
		}
		
		// Draw visible line numbers
		charIndex = characterRange.location
		
		// Use text color from the text view
		let textColor = textView.textColor ?? NSColor.labelColor
		let attributes: [NSAttributedString.Key: Any] = [
			.font: font,
			.foregroundColor: textColor
		]
		
		while charIndex < NSMaxRange(characterRange) {
			let lineRange = textString.lineRange(for: NSRange(location: charIndex, length: 0))
			let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)
			let lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
			
			// Convert textView coordinates to gutter coordinates
			let yPosition = lineRect.origin.y - visibleRect.origin.y + textView.textContainerInset.height
			
			if yPosition >= -lineRect.height && yPosition <= bounds.height {
				let lineNumberString = String(lineNumber)
				let size = (lineNumberString as NSString).size(withAttributes: attributes)
				let xPosition = gutterWidth - size.width - padding
				let drawPoint = NSPoint(x: xPosition, y: yPosition + (lineRect.height - size.height) / 2)
				
				(lineNumberString as NSString).draw(at: drawPoint, withAttributes: attributes)
			}
			
			lineNumber += 1
			charIndex = NSMaxRange(lineRange)
			
			if charIndex >= textString.length {
				break
			}
		}
	}
}
