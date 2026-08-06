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
import MopedEditor
import SwiftUI

struct MopedCommands: Commands {
	@FocusedValue(\.documentContent) private var documentContent

	var body: some Commands {
		CommandGroup(replacing: .appInfo) {
			Button("menu.app.about") {
				AppActions.shared.showAboutWindow()
			}
		}

		CommandGroup(after: .appInfo) {
			Button("menu.app.setup_cli") {
				AppActions.shared.setupMopedCLI()
			}
		}

		CommandGroup(replacing: .printItem) {
			Button("menu.file.print") {
				printDocument()
			}
			.keyboardShortcut("p")
		}

		CommandMenu("menu.find.title") {
			Button("menu.find.find") {
				showFindPanel(action: .showFindInterface)
			}
			.keyboardShortcut("f")

			Button("menu.find.find_and_replace") {
				showFindPanel(action: .showReplaceInterface)
			}
			.keyboardShortcut("f", modifiers: [.command, .option])

			Button("menu.find.jump_to_line") {
				jumpToLine()
			}
			.keyboardShortcut("l")
		}

		CommandMenu("menu.editor.title") {
			Button("menu.editor.toggle_comment") {
				NSApp.sendAction(
					#selector(MopedTextView.toggleLineCommentMenuItemSelected(_:)),
					to: nil,
					from: nil
				)
			}
			.keyboardShortcut("/")

			Divider()

			Button("menu.editor.increase") {
				NSApp.sendAction(
					#selector(MopedTextView.fontSizeIncreaseMenuItemSelected(_:)),
					to: nil,
					from: nil
				)
			}
			.keyboardShortcut("+")

			Button("menu.editor.decrease") {
				NSApp.sendAction(
					#selector(MopedTextView.fontSizeDecreaseMenuItemSelected(_:)),
					to: nil,
					from: nil
				)
			}
			.keyboardShortcut("-")

			Divider()

			Button("menu.editor.reset") {
				NSApp.sendAction(
					#selector(MopedTextView.fontSizeResetMenuItemSelected(_:)),
					to: nil,
					from: nil
				)
			}
			.keyboardShortcut("0")
		}

		CommandGroup(replacing: .help) {
			Button("menu.help.read_license") {
				AppActions.shared.linkToLicense()
			}
			Button("menu.help.get_source") {
				AppActions.shared.linkToSources()
			}
			Button("menu.help.report_issue") {
				AppActions.shared.linkToIssues()
			}
			Button("menu.help.logo_credit") {
				AppActions.shared.linkToIconSite()
			}
			Divider()
			Button("menu.help.moped_help") {
				AppActions.shared.linkToDocumentation()
			}
			.keyboardShortcut("?")
		}
	}

	private func printDocument() {
		guard let content = documentContent?.wrappedValue else {
			NSSound.beep()
			return
		}

		// Copied from the shared instance rather than built fresh, so the printer, paper size
		// and orientation the user picked last time are already selected. Installing the copy
		// back as `shared` before running is what makes *this* run's choices stick: the print
		// panel mutates the very object handed to the operation, and the sheet is
		// asynchronous, so there is no "after" in which to read the settings back.
		//
		// Margins are deliberately re-applied every time and so do not persist; one inch is
		// documented behaviour, not a preference.
		let printInfo = NSPrintInfo.shared.copy() as? NSPrintInfo ?? NSPrintInfo()
		printInfo.horizontalPagination = .automatic
		printInfo.verticalPagination = .automatic
		printInfo.isHorizontallyCentered = false
		printInfo.isVerticallyCentered = false
		printInfo.leftMargin = 72.0
		printInfo.rightMargin = 72.0
		printInfo.topMargin = 72.0
		printInfo.bottomMargin = 72.0

		// Print in the font the document is being edited in. A hardcoded system fixed-pitch
		// font meant the printout could not be read back against the screen line for line.
		let preferences = Preferences.userShared
		let size = preferences.fontSizeFloat
		let font = NSFont(name: preferences.font, size: size)
			?? NSFont.userFixedPitchFont(ofSize: size)
			?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)

		NSPrintInfo.shared = printInfo

		let printView = SourcePrintView(content: content, printInfo: printInfo, font: font)
		let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
		var exceptionReason: NSString?
		// With a key window this means "the print sheet was presented", not "printing
		// finished" — the sheet path is asynchronous and the guard covers setup and
		// presentation only (see PrintOperationGuard.mm). False is a failure to even
		// start, which is what the alert below reports.
		let didStart = PrintOperationGuard.run(
			printOperation,
			in: NSApp.keyWindow,
			exceptionReason: &exceptionReason
		)
		if !didStart {
			if let reason = exceptionReason as String? {
				NSLog("Printing failed: %@", reason)
			}
			let alert = NSAlert()
			alert.alertStyle = .warning
			alert.messageText = String(localized: "alert.printing_failed.title")
			alert.informativeText = String(localized: "alert.printing_failed.message")
			alert.runModal()
		}
	}

	private func showFindPanel(action: NSTextFinder.Action) {
		if let textView = activeTextView() {
			textView.window?.makeFirstResponder(textView)

			// `showReplaceInterface` only toggles the replace row on an already-visible
			// bar, so bring the bar up first for a cold Cmd-Option-F.
			if action == .showReplaceInterface {
				let showItem = NSMenuItem()
				showItem.tag = NSTextFinder.Action.showFindInterface.rawValue
				textView.performTextFinderAction(showItem)
			}

			let textFinderItem = NSMenuItem()
			textFinderItem.tag = action.rawValue
			textView.performTextFinderAction(textFinderItem)
			return
		}

		let textFinderItem = NSMenuItem()
		textFinderItem.tag = action.rawValue
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
		alert.messageText = String(localized: "alert.jump_to_line.title")
		alert.informativeText = String(localized: "alert.jump_to_line.message")
		alert.alertStyle = .informational
		alert.addButton(withTitle: String(localized: "alert.jump_to_line.button_jump"))
		alert.addButton(withTitle: String(localized: "alert.jump_to_line.button_cancel"))

		let inputField = NSTextField(frame: NSRect(x: 0.0, y: 0.0, width: 180.0, height: 24.0))
		inputField.placeholderString = String(localized: "alert.jump_to_line.placeholder")
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
}

// MARK: - Private helpers

private extension MopedCommands {
	func activeTextView() -> NSTextView? {
		guard let window = NSApp.keyWindow else {
			return nil
		}

		if let textView = window.firstResponder as? NSTextView, !textView.isFieldEditor {
			return textView
		}

		return window.contentView?.firstDescendantTextView()
	}

	func currentLineNumber(in textView: NSTextView) -> Int {
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

	func locationForLine(_ lineNumber: Int, in text: NSString) -> Int? {
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
}
