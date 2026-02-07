//
//  TextEditorRepresentable.swift
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

import SwiftUI

final class BorderlessScrollView: NSScrollView {
	override func draw(_ dirtyRect: NSRect) {
		// Avoid default bounds/border drawing artifacts around the editor container.
	}
}

struct TextEditorRepresentable: NSViewRepresentable {
	@ObservedObject var model: TextFileModel
	@ObservedObject var state: EditorState

	func makeCoordinator() -> Coordinator {
		Coordinator(model: model, state: state)
	}

	func makeNSView(context: Context) -> NSScrollView {
		let textView = MopedTextView()
		textView.isRichText = false
		textView.isVerticallyResizable = true
		textView.isHorizontallyResizable = true
		textView.allowsUndo = true
		textView.usesFindBar = true
		textView.isAutomaticSpellingCorrectionEnabled = false
		textView.isAutomaticQuoteSubstitutionEnabled = false
		textView.isAutomaticDashSubstitutionEnabled = false
		textView.delegate = context.coordinator

		let scrollView = BorderlessScrollView()
		scrollView.borderType = .noBorder
		scrollView.drawsBackground = false
		scrollView.wantsLayer = true
		scrollView.layer?.masksToBounds = true
		scrollView.hasVerticalScroller = true
		scrollView.documentView = textView
		scrollView.findBarPosition = .aboveContent

		textView.string = model.content
		state.configure(textView: textView, scrollView: scrollView)
		state.refreshLineNumberRuler()

		return scrollView
	}

	func updateNSView(_ nsView: NSScrollView, context: Context) {
		guard let textView = nsView.documentView as? NSTextView else {
			return
		}

		if textView.string != model.content {
			let existingSelection = textView.selectedRange()
			textView.string = model.content
			let textLength = textView.string.utf16.count
			let clampedRange = NSRange(
				location: min(existingSelection.location, textLength),
				length: 0
			)
			textView.setSelectedRange(clampedRange)
		}
	}

	final class Coordinator: NSObject, NSTextViewDelegate {
		private let model: TextFileModel
		private let state: EditorState

		init(model: TextFileModel, state: EditorState) {
			self.model = model
			self.state = state
		}

		func textDidChange(_ notification: Notification) {
			guard let textView = notification.object as? NSTextView else {
				return
			}

			model.content = textView.string
			state.refreshLineNumberRuler()
		}

		func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
			if commandSelector == #selector(NSResponder.insertNewline(_:)) {
				let selectedRange = textView.selectedRange()
				let text = textView.string as NSString
				let caretLocation = min(selectedRange.location, text.length)
				let searchRange = NSRange(location: 0, length: caretLocation)
				let previousNewline = text.range(
					of: "\n",
					options: .backwards,
					range: searchRange
				)
				let lineStart = previousNewline.location == NSNotFound
					? 0
					: previousNewline.location + 1
				var indentEnd = lineStart
				while indentEnd < text.length {
					let character = text.character(at: indentEnd)
					if character != 9 && character != 32 {
						break
					}
					indentEnd += 1
				}
				let indent = text.substring(
					with: NSRange(location: lineStart, length: indentEnd - lineStart)
				)
				textView.insertText(
					"\n" + indent,
					replacementRange: selectedRange
				)
				return true
			}
			return false
		}
	}
}
