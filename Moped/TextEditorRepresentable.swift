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

/// `NSTextFinderBarContainer` whose content view is hosted inside a floating `NSPanel`.
/// Earlier attempts to put the bar in a SwiftUI sibling failed because NSTextFinder
/// only honors a container that is unambiguously in a window — when our SwiftUI host
/// resolved to a zero-height view, AppKit treated the container as window-less and
/// fell back to a window title-bar accessory. Hosting in a panel guarantees the
/// container has a real `.window` whenever NSTextFinder asks, so the bar appears in
/// the panel instead.
@MainActor
final class EditorFindBarContainer: NSView, NSTextFinderBarContainer {
	weak var contentViewReference: NSView?

	var onVisibilityChange: ((Bool) -> Void)?
	var onHeightChange: ((CGFloat) -> Void)?

	private(set) var currentHeight: CGFloat = 0

	var findBarView: NSView? {
		didSet {
			oldValue?.removeFromSuperview()
			if let findBarView {
				findBarView.autoresizingMask = [.width]
				findBarView.frame = NSRect(
					x: 0,
					y: 0,
					width: max(bounds.width, 1),
					height: barHeight(for: findBarView)
				)
				addSubview(findBarView)
			}
			recomputeHeight()
			// NSTextFinder's `_NSBarTextFinder` doesn't reliably set `isFindBarVisible`
			// to pair with `findBarView` — installing a bar is the implicit show signal,
			// clearing it is the implicit hide signal. Drive visibility from that here
			// so the panel actually appears.
			let shouldBeVisible = findBarView != nil
			if isFindBarVisible != shouldBeVisible {
				isFindBarVisible = shouldBeVisible
			}
		}
	}

	var isFindBarVisible: Bool = false {
		didSet {
			guard oldValue != isFindBarVisible else { return }
			recomputeHeight()
			onVisibilityChange?(isFindBarVisible)
		}
	}

	func findBarViewDidChangeHeight() {
		recomputeHeight()
	}

	func contentView() -> NSView? {
		contentViewReference
	}

	override func layout() {
		super.layout()
		if let findBarView, findBarView.superview === self {
			findBarView.frame = NSRect(
				x: 0,
				y: 0,
				width: bounds.width,
				height: barHeight(for: findBarView)
			)
		}
	}

	private func barHeight(for view: NSView) -> CGFloat {
		let fitted = view.fittingSize.height
		if fitted > 0 { return fitted }
		if view.frame.height > 0 { return view.frame.height }
		return 28
	}

	private func recomputeHeight() {
		let newHeight: CGFloat
		if isFindBarVisible, let findBarView {
			newHeight = barHeight(for: findBarView)
		} else {
			newHeight = 0
		}
		if currentHeight != newHeight {
			currentHeight = newHeight
			onHeightChange?(newHeight)
		}
	}
}

/// Owns the floating `NSPanel` that hosts the find bar container. The panel attaches
/// as a child window of the document window so it follows window moves; it sizes
/// itself to the bar's current height and re-positions just below the title bar.
@MainActor
final class FindPanelController {
	let container = EditorFindBarContainer()

	private var panel: NSPanel?
	private weak var hostWindow: NSWindow?

	init() {
		container.onVisibilityChange = { [weak self] visible in
			if visible {
				self?.show()
			} else {
				self?.hide()
			}
		}
		container.onHeightChange = { [weak self] _ in
			self?.refreshFrame()
		}
	}

	func attach(to window: NSWindow?) {
		guard hostWindow !== window else { return }
		if let panel {
			panel.parent?.removeChildWindow(panel)
			panel.orderOut(nil)
		}
		hostWindow = window
		guard let window else { return }
		// Pre-create the panel so the container is parented to a real window the moment
		// NSTextFinder sets `findBarView`. Without this, NSTextFinder asks the container
		// for `.window` during `_loadUI`, gets nil, and falls back to the window's title
		// bar accessory. The child-window relationship is permanent for the lifetime of
		// the host; we toggle visibility via orderFront/orderOut, not addChildWindow/
		// removeChildWindow — the latter caused the bar to not re-appear after Esc.
		let panel = ensurePanel()
		if panel.parent == nil {
			window.addChildWindow(panel, ordered: .above)
		}
		panel.orderOut(nil)
	}

	func present() {
		// Public entry point so the text view can guarantee visibility on Cmd-F /
		// Cmd-Option-F regardless of whether NSTextFinder bothered to call our
		// `isFindBarVisible` setter. Keeps internal state in sync so a subsequent Esc
		// from NSTextFinder still flips us back to hidden.
		if !container.isFindBarVisible {
			container.isFindBarVisible = true
		} else {
			show()
		}
	}

	private func show() {
		guard let panel else { return }
		refreshFrame()
		panel.orderFrontRegardless()
		panel.makeKey()
	}

	private func hide() {
		panel?.orderOut(nil)
	}

	private func ensurePanel() -> NSPanel {
		if let panel { return panel }
		let initialHeight = max(container.currentHeight, 28)
		let initialFrame = NSRect(x: 0, y: 0, width: 480, height: initialHeight)
		let newPanel = NSPanel(
			contentRect: initialFrame,
			styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
			backing: .buffered,
			defer: false
		)
		newPanel.titleVisibility = .hidden
		newPanel.titlebarAppearsTransparent = true
		newPanel.isFloatingPanel = true
		newPanel.hidesOnDeactivate = false
		newPanel.becomesKeyOnlyIfNeeded = false
		newPanel.hasShadow = true
		container.frame = NSRect(origin: .zero, size: initialFrame.size)
		container.autoresizingMask = [.width, .height]
		newPanel.contentView = container
		panel = newPanel
		return newPanel
	}

	private func refreshFrame() {
		guard let panel, let hostWindow else { return }
		let height = max(container.currentHeight, 28)
		let host = hostWindow.frame
		let panelWidth = max(host.width - 40, 320)
		// Place just below the title bar with a small gap.
		let titleBarThickness = host.height - hostWindow.contentRect(forFrameRect: host).height
		let topGap: CGFloat = 8
		let newFrame = NSRect(
			x: host.minX + (host.width - panelWidth) / 2,
			y: host.maxY - titleBarThickness - topGap - height,
			width: panelWidth,
			height: height
		)
		panel.setFrame(newFrame, display: true)
	}
}

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
		// Track last programmatic change ID (per-coordinator, so each open document
		// tracks its own model) to avoid expensive string comparisons.
		let isForceReload = model.isForceReload
		if context.coordinator.lastProgrammaticChangeID != model.programmaticChangeID,
		   isForceReload || !state.editorIsFirstResponderForUpdate {
			context.coordinator.lastProgrammaticChangeID = model.programmaticChangeID
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
		var lastProgrammaticChangeID = -1

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
			state.attachFindPanel(to: window)

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
