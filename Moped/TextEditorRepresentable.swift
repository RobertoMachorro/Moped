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

import AppKit
import STTextView
import SwiftUI

struct TextEditorRepresentable: NSViewRepresentable {
	@ObservedObject var model: TextFileModel
	@ObservedObject var state: EditorState

	func makeCoordinator() -> Coordinator {
		Coordinator(model: model, state: state)
	}

	func makeNSView(context: Context) -> NSScrollView {
		let scrollView = NSScrollView()
		scrollView.borderType = .noBorder
		scrollView.drawsBackground = true
		scrollView.hasVerticalScroller = true
		scrollView.hasHorizontalScroller = true
		scrollView.wantsLayer = true
		scrollView.layer?.masksToBounds = true
		scrollView.findBarPosition = .aboveContent

		if model.isLargeFile {
			state.prepareForLargeFileMode()
		}

		state.installEditor(
			into: scrollView,
			model: model,
			delegate: context.coordinator
		)

		context.coordinator.observeWindowFocusIfNeeded(for: state.textView)
		context.coordinator.requestInitialFocusIfNeeded(for: state.textView)

		return scrollView
	}

	func updateNSView(_ nsView: NSScrollView, context: Context) {
		// Track last programmatic change ID to avoid expensive string comparisons
		struct ChangeTracker { static var lastID: Int = -1 }

		let isForceReload = model.isForceReload
		if ChangeTracker.lastID != model.programmaticChangeID,
		   isForceReload || !state.editorIsFirstResponderForUpdate {
			ChangeTracker.lastID = model.programmaticChangeID
			model.isForceReload = false
			state.replaceContent(with: model.content)
		}

		context.coordinator.observeWindowFocusIfNeeded(for: state.textView)
		context.coordinator.requestInitialFocusIfNeeded(for: state.textView)
	}

	@MainActor
	final class Coordinator: NSObject, STTextViewDelegate {
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

		func requestInitialFocusIfNeeded(for textView: STTextView?) {
			guard let textView else { return }
			requestInitialFocusIfNeeded(for: textView, attempt: 0)
		}

		private func requestInitialFocusIfNeeded(for textView: STTextView, attempt: Int) {
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
					textView.textSelection = NSRange(location: 0, length: 0)
					self.didSetInitialFocus = true
				}
			}
		}

		func observeWindowFocusIfNeeded(for textView: STTextView?) {
			guard let textView, let window = textView.window else {
				return
			}

			observeWindowFocus(for: textView, window: window)
		}

		private func observeWindowFocus(for textView: STTextView, window: NSWindow) {
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

		// MARK: STTextViewDelegate

		func textViewDidChangeText(_ notification: Notification) {
			guard let textView = notification.object as? STTextView else {
				return
			}
			model.content = textView.text ?? ""
		}

		func textViewDidChangeSelection(_ notification: Notification) {
			guard let textView = notification.object as? STTextView else {
				return
			}
			state.updateCursorPosition(for: textView)
		}
	}
}
