//
//  MopedCommands.swift
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
import SwiftUI

struct MopedCommands: Commands {
	@FocusedValue(\.documentContent) private var documentContent

	var body: some Commands {
		CommandGroup(replacing: .appInfo) {
			Button("About Moped") {
				AppActions.shared.showAboutWindow()
			}
		}

		CommandGroup(after: .appInfo) {
			Button("Setup moped CLI") {
				AppActions.shared.setupMopedCLI()
			}
		}

		CommandGroup(replacing: .printItem) {
			Button("Print…") {
				printDocument()
			}
			.keyboardShortcut("p")
		}

		CommandMenu("Find") {
			Button("Find…") {
				showFindPanel()
			}
			.keyboardShortcut("f")

			Button("Jump to Line…") {
				jumpToLine()
			}
			.keyboardShortcut("l")
		}

		CommandMenu("Editor") {
			Button("Increase") {
				NSApp.sendAction(
					#selector(MopedTextView.fontSizeIncreaseMenuItemSelected(_:)),
					to: nil,
					from: nil
				)
			}
			.keyboardShortcut("+")

			Button("Decrease") {
				NSApp.sendAction(
					#selector(MopedTextView.fontSizeDecreaseMenuItemSelected(_:)),
					to: nil,
					from: nil
				)
			}
			.keyboardShortcut("-")

			Divider()

			Button("Reset") {
				NSApp.sendAction(
					#selector(MopedTextView.fontSizeResetMenuItemSelected(_:)),
					to: nil,
					from: nil
				)
			}
			.keyboardShortcut("0")
		}

		CommandGroup(replacing: .help) {
			Button("Read License") {
				AppActions.shared.linkToLicense()
			}
			Button("Get Source Code") {
				AppActions.shared.linkToSources()
			}
			Button("Report an Issue") {
				AppActions.shared.linkToIssues()
			}
			Button("Logo by BSGStudio") {
				AppActions.shared.linkToIconSite()
			}
			Divider()
			Button("Moped Help") {
				NSApp.sendAction(#selector(NSApplication.showHelp(_:)), to: nil, from: nil)
			}
			.keyboardShortcut("?")
		}
	}

	private func printDocument() {
		guard let content = documentContent?.wrappedValue else {
			NSSound.beep()
			return
		}

		let pageSize = NSSize(
			width: NSPrintInfo.shared.paperSize.width,
			height: NSPrintInfo.shared.paperSize.height
		)
		let textView = NSTextView(
			frame: NSRect(x: 0.0, y: 0.0, width: pageSize.width, height: pageSize.height)
		)
		textView.appearance = NSAppearance(named: .aqua)
		textView.textStorage?.append(NSAttributedString(string: content))

		let printInfo = NSPrintInfo()
		printInfo.horizontalPagination = .fit
		printInfo.isHorizontallyCentered = false
		printInfo.isVerticallyCentered = false
		printInfo.leftMargin = 72.0
		printInfo.rightMargin = 72.0
		printInfo.topMargin = 72.0
		printInfo.bottomMargin = 72.0

		let printOperation = NSPrintOperation(view: textView, printInfo: printInfo)
		if let window = NSApp.keyWindow {
			printOperation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
		} else {
			printOperation.run()
		}
	}

	private func showFindPanel() {
		if let textView = activeTextView() {
			textView.window?.makeFirstResponder(textView)
			textView.usesFindBar = true
			if let scrollView = textView.enclosingScrollView {
				scrollView.findBarPosition = .aboveContent
				scrollView.isFindBarVisible = true
			}

			let textFinderItem = NSMenuItem()
			textFinderItem.tag = NSTextFinder.Action.showFindInterface.rawValue
			textView.performTextFinderAction(textFinderItem)
			if let scrollView = textView.enclosingScrollView {
				applySystemFindBarAppearanceWhenReady(in: scrollView, window: textView.window)
			}
			return
		}

		let textFinderItem = NSMenuItem()
		textFinderItem.tag = NSTextFinder.Action.showFindInterface.rawValue
		if NSApp.sendAction(
			#selector(NSResponder.performTextFinderAction(_:)),
			to: nil,
			from: textFinderItem
		) {
			return
		}

		NSSound.beep()
	}

	private func jumpToLine() {
		guard let textView = activeTextView() else {
			NSSound.beep()
			return
		}

		let alert = NSAlert()
		alert.messageText = "Jump to Line"
		alert.informativeText = "Enter a line number."
		alert.alertStyle = .informational
		alert.addButton(withTitle: "Jump")
		alert.addButton(withTitle: "Cancel")

		let inputField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 180.0, height: 24.0))
		inputField.placeholderString = "Line Number"
		inputField.stringValue = "\(currentLineNumber(in: textView))"
		alert.accessoryView = inputField

		let response = alert.runModal()
		guard response == .alertFirstButtonReturn else {
			return
		}

		let input = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
		guard let lineNumber = Int(input), lineNumber > 0 else {
			NSSound.beep()
			return
		}

		guard let targetLocation = locationForLine(lineNumber, in: textView.string as NSString) else {
			NSSound.beep()
			return
		}

		let targetRange = NSRange(location: targetLocation, length: 0)
		textView.window?.makeFirstResponder(textView)
		textView.setSelectedRange(targetRange)
		textView.scrollRangeToVisible(targetRange)
	}

	private func applySystemFindBarAppearanceWhenReady(
		in scrollView: NSScrollView,
		window: NSWindow?,
		attempt: Int = 0
	) {
		let applied = applySystemFindBarAppearance(in: scrollView, window: window)
		guard !applied, attempt < 10 else {
			return
		}

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
			applySystemFindBarAppearanceWhenReady(
				in: scrollView,
				window: window,
				attempt: attempt + 1
			)
		}
	}

	@discardableResult
	private func applySystemFindBarAppearance(in scrollView: NSScrollView, window: NSWindow?) -> Bool {
		guard let findBarView = scrollView.findBarView else {
			return false
		}

		findBarView.clearExplicitAppearanceRecursively()
		let effectiveAppearance = window?.effectiveAppearance ?? NSApp.effectiveAppearance
		let match = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
		let appearanceName: NSAppearance.Name = match == .darkAqua ? .darkAqua : .aqua
		findBarView.appearance = NSAppearance(named: appearanceName)
		findBarView.wantsLayer = true
		findBarView.layer?.backgroundColor = (
			match == .darkAqua
			? NSColor(calibratedWhite: 0.15, alpha: 1.0)
			: NSColor(calibratedWhite: 0.95, alpha: 1.0)
		).cgColor
		findBarView.needsDisplay = true
		return true
	}

	private func activeTextView() -> NSTextView? {
		guard let window = NSApp.keyWindow else {
			return nil
		}

		if let textView = window.firstResponder as? NSTextView, !textView.isFieldEditor {
			return textView
		}

		return window.contentView?.firstDescendantTextView()
	}

	private func currentLineNumber(in textView: NSTextView) -> Int {
		let text = textView.string as NSString
		let selectedLocation = min(textView.selectedRange().location, text.length)

		var lineNumber = 1
		var scanLocation = 0
		while scanLocation < selectedLocation {
			let lineRange = text.lineRange(for: NSRange(location: scanLocation, length: 0))
			let nextLocation = NSMaxRange(lineRange)
			guard nextLocation > scanLocation else {
				break
			}
			scanLocation = nextLocation
			lineNumber += 1
		}

		return lineNumber
	}

	private func locationForLine(_ lineNumber: Int, in text: NSString) -> Int? {
		if lineNumber == 1 {
			return 0
		}

		var currentLine = 1
		var location = 0
		while location < text.length {
			let lineRange = text.lineRange(for: NSRange(location: location, length: 0))
			let nextLocation = NSMaxRange(lineRange)
			guard nextLocation > location else {
				break
			}
			location = nextLocation
			currentLine += 1
			if currentLine == lineNumber {
				return min(location, text.length)
			}
		}

		return nil
	}
}

private extension NSView {
	func firstDescendantTextView() -> NSTextView? {
		if let textView = self as? NSTextView, !textView.isFieldEditor {
			return textView
		}

		for subview in subviews {
			if let textView = subview.firstDescendantTextView() {
				return textView
			}
		}

		return nil
	}

	func clearExplicitAppearanceRecursively() {
		appearance = nil
		for subview in subviews {
			subview.clearExplicitAppearanceRecursively()
		}
	}
}
