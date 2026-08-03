//
//  EditorTestCase.swift
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
import XCTest
@testable import MopedEditor

/// Shared harness for tests that drive a real `MopedTextView` — storage, layout
/// manager and highlighter — the way the app does.
@MainActor
class EditorTestCase: XCTestCase {
	/// A windowless text view has no responder chain to inherit an undo manager
	/// from, so supply one the way the document window does in the app.
	private final class UndoProvidingDelegate: NSObject, NSTextViewDelegate {
		let manager = UndoManager()

		func undoManager(for view: NSTextView) -> UndoManager? {
			manager
		}
	}

	private var undoDelegate: UndoProvidingDelegate?

	func makeEditor(
		theme: MopedTheme = .defaultLightPalette
	) -> (scrollView: NSScrollView, textView: MopedTextView) {
		let editor = MopedTextView.scrollableEditor(theme: theme)
		editor.scrollView.frame = NSRect(x: 0, y: 0, width: 600, height: 400)
		let delegate = UndoProvidingDelegate()
		editor.textView.delegate = delegate
		undoDelegate = delegate
		return editor
	}

	/// Lets the highlighter's coalesced main-queue pass run.
	func drainHighlightPasses() {
		for _ in 0..<10 {
			RunLoop.current.run(until: Date().addingTimeInterval(0.02))
		}
	}

	func color(at location: Int, in textView: MopedTextView) -> NSColor? {
		textView.layoutManager?.temporaryAttribute(
			.foregroundColor, atCharacterIndex: location, effectiveRange: nil
		) as? NSColor
	}
}
