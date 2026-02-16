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
		let menuItem = NSMenuItem()
		menuItem.tag = NSTextFinder.Action.showFindInterface.rawValue
		NSApp.sendAction(
			#selector(NSTextView.performTextFinderAction(_:)),
			to: nil,
			from: menuItem
		)
	}
}
