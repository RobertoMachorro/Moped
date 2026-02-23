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

		let scrollView = NSScrollView()
		scrollView.borderType = .noBorder
		scrollView.drawsBackground = true
		scrollView.wantsLayer = true
		scrollView.layer?.masksToBounds = true
		scrollView.hasVerticalScroller = true
		scrollView.documentView = textView
		scrollView.findBarPosition = .aboveContent

		// Mark large-file mode before configuring so we don't attach Highlightr storage
		if model.isLargeFile {
			state.prepareForLargeFileMode()
		}

		state.configure(textView: textView, scrollView: scrollView)

		// Only apply language when highlighting is enabled (non-large files)
		if !model.isLargeFile {
			state.applyLanguage(model.docTypeLanguage)
		}

		textView.layoutManager?.allowsNonContiguousLayout = true
		textView.textStorage?.beginEditing()
		textView.string = model.content
		textView.textStorage?.endEditing()
		
		if model.isLargeFile {
			state.forceLineNumberRulerVisible(false)
		}

		state.refreshLineNumberRuler()
		context.coordinator.observeWindowFocusIfNeeded(for: textView)
		context.coordinator.requestInitialFocusIfNeeded(for: textView)

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

		context.coordinator.observeWindowFocusIfNeeded(for: textView)
		context.coordinator.requestInitialFocusIfNeeded(for: textView)
	}

	final class Coordinator: NSObject, NSTextViewDelegate {
		private let model: TextFileModel
		private let state: EditorState
		private var didSetInitialFocus = false
		private var appFocusObserver: NSObjectProtocol?

		init(model: TextFileModel, state: EditorState) {
			self.model = model
			self.state = state
		}

		deinit {
			if let appFocusObserver {
				NotificationCenter.default.removeObserver(appFocusObserver)
			}
		}

		func requestInitialFocusIfNeeded(for textView: NSTextView) {
			requestInitialFocusIfNeeded(for: textView, attempt: 0)
		}

		private func requestInitialFocusIfNeeded(for textView: NSTextView, attempt: Int) {
			guard !didSetInitialFocus else {
				return
			}

			DispatchQueue.main.async { [weak self, weak textView] in
				guard let self, let textView, !self.didSetInitialFocus else {
					return
				}
				guard let window = textView.window else {
					if attempt < 10 {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak textView] in
							guard let self, let textView else {
								return
							}
							self.requestInitialFocusIfNeeded(for: textView, attempt: attempt + 1)
						}
					}
					return
				}
				self.observeWindowFocus(for: textView, window: window)

				if window.makeFirstResponder(textView) {
					self.didSetInitialFocus = true
				}
			}
		}

		func observeWindowFocusIfNeeded(for textView: NSTextView) {
			guard let window = textView.window else {
				return
			}

			observeWindowFocus(for: textView, window: window)
		}

		private func observeWindowFocus(for textView: NSTextView, window: NSWindow) {
			guard appFocusObserver == nil else {
				return
			}

			appFocusObserver = NotificationCenter.default.addObserver(
				forName: NSApplication.didBecomeActiveNotification,
				object: NSApp,
				queue: .main
			) { [weak textView] _ in
				guard let textView, let window = textView.window, window.isKeyWindow else {
					return
				}
				if let responder = window.firstResponder as? NSTextView, responder.isFieldEditor {
					return
				}
				guard window.firstResponder !== textView else {
					return
				}

				window.makeFirstResponder(textView)
			}
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

