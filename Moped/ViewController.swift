//
//  ViewController.swift
//
//  Moped - A general purpose text editor, small and light.
//  Copyright © 2019-2020 Roberto Machorro. All rights reserved.
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
import Highlightr

class ViewController: NSViewController, NSTextViewDelegate {
	// TextView Editor
	@IBOutlet var textView: NSTextView!
	// Status bar components
	@IBOutlet var statusLabel: NSTextFieldCell!
	@IBOutlet var languagePopup: NSPopUpButtonCell!

	let userPreferences = Preferences.userShared
	let highlightrTextStorage: CodeAttributedString? = CodeAttributedString()

	override func viewDidLoad() {
		super.viewDidLoad()

		textView.isAutomaticSpellingCorrectionEnabled = false
		textView.isAutomaticQuoteSubstitutionEnabled = false
		textView.isAutomaticDashSubstitutionEnabled = false

		setLineWrap(to: userPreferences.doLineWrap)

		statusLabel.stringValue = ""

		if let storage = highlightrTextStorage {
			storage.addLayoutManager(textView.layoutManager!)
			updateViewTo(theme: userPreferences.theme)

			languagePopup.removeAllItems()
			languagePopup.addItems(withTitles: storage.highlightr.supportedLanguages().sorted())
			languagePopup.selectItem(withTitle: userPreferences.language)
		} else {
			textView.font = NSFont(name: userPreferences.font, size: userPreferences.fontSizeFloat)
		}

		setupPreferencesObserver()
	}

	override func viewWillAppear() {
		super.viewWillAppear()
		if let storage = highlightrTextStorage, let language = document?.model.docTypeLanguage {
			languagePopup.selectItem(withTitle: language)
			storage.language = language
		}
	}

	override var representedObject: Any? {
		didSet {
			// Pass down ContentModel to all of the child view controllers
			for child in children {
				child.representedObject = representedObject
			}
		}
	}

	// MARK: - Language / Popup Theme Changes

	@IBAction func languagePopupAction(_ sender: NSPopUpButtonCell) {
		if let storage = highlightrTextStorage {
			storage.language = sender.titleOfSelectedItem ?? userPreferences.language
		}
	}

	// MARK: - Accessor Helpers

	weak var windowController: WindowController? {
		view.window?.windowController as? WindowController
	}

	weak var document: Document? {
		if let window = windowController, let doc = window.document as? Document {
			return doc
		}
		return nil
	}

	// MARK: - NSTextViewDelegate

	func textDidBeginEditing(_ notification: Notification) {
		document?.objectDidBeginEditing(self)
	}

	func textDidEndEditing(_ notification: Notification) {
		document?.objectDidEndEditing(self)
	}

	func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
		/* TODO: Setup Preferences for this option, autodectect from file as well
		 if (commandSelector == #selector(NSResponder.insertTab(_:))) {
		 	textView.insertText("  ", replacementRange: textView.selectedRange())
		 	return true
		 } else if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
		 }
		 */
		false
	}
}

extension ViewController {
	func setupPreferencesObserver() {
		let notificationName = Notification.Name(rawValue: "PreferencesChanged")
		NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
			self.setLineWrap(to: self.userPreferences.doLineWrap)
			// TODO: Check for self referencing ARC leak
			self.updateViewTo(theme: self.userPreferences.theme)
		}
	}

	func updateViewTo(theme: String) {
		if let storage = highlightrTextStorage {
			storage.highlightr.setTheme(to: theme)
			storage.highlightr.theme.codeFont = NSFont(name: userPreferences.font, size: userPreferences.fontSizeFloat)
			textView.backgroundColor = storage.highlightr.theme.themeBackgroundColor
			textView.insertionPointColor = caretColor(for: theme, using: textView.backgroundColor)
		}
	}

	func caretColor(for theme: String, using color: NSColor) -> NSColor {
		var r: CGFloat = 1.0, g: CGFloat = 1.0, b: CGFloat = 1.0
		if color.colorSpace == NSColorSpace.sRGB {
			color.getRed(&r, green: &g, blue: &b, alpha: nil)
		}
		return NSColor(red: 1.0-r, green: 1.0-g, blue: 1.0-b, alpha: 1)
	}

	func setLineWrap(to wrapping: Bool) {
		if wrapping {
			textView.enclosingScrollView?.hasHorizontalScroller = false
			textView.isHorizontallyResizable = false
			//textView.autoresizingMask = [.width, .height]
			let giantValue = Double.greatestFiniteMagnitude // FLT_MAX
			textView.textContainer?.containerSize = .init(width: 480, height: giantValue)
			textView.textContainer?.widthTracksTextView = true
		} else {
			textView.enclosingScrollView?.hasHorizontalScroller = true
			textView.isHorizontallyResizable = true
			textView.autoresizingMask = [.width, .height]
			let giantValue = Double.greatestFiniteMagnitude // FLT_MAX
			textView.textContainer?.containerSize = .init(width: giantValue, height: giantValue)
			textView.textContainer?.widthTracksTextView = false
		}
	}
}
