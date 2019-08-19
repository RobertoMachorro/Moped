//
//  ViewController.swift
//
//  MacPad - A general purpose text editor, small and light.
//  Copyright © 2019 Roberto Machorro. All rights reserved.
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
	@IBOutlet weak var statusLabel: NSTextFieldCell!
	@IBOutlet weak var languagePopup: NSPopUpButtonCell!
	@IBOutlet weak var themePopup: NSPopUpButtonCell!

	let highlightrTextStorage = CodeAttributedString()

	// TODO: These will go into Preferences
	let defaultLanguage = "plaintext"
	let defaultTheme = "xcode"
	let defaultFont = "Menlo"
	let defaultFontSize = CGFloat(11)

	override func viewDidLoad() {
		super.viewDidLoad()

		textView.isAutomaticSpellingCorrectionEnabled = false
		textView.isAutomaticQuoteSubstitutionEnabled = false
		textView.isAutomaticDashSubstitutionEnabled = false

		statusLabel.stringValue = ""

		highlightrTextStorage.addLayoutManager(textView.layoutManager!)
		highlightrTextStorage.language = defaultLanguage
		highlightrTextStorage.highlightr.setTheme(to: defaultTheme)
		highlightrTextStorage.highlightr.theme.codeFont = NSFont(name: defaultFont, size: defaultFontSize)

		languagePopup.removeAllItems()
		languagePopup.addItems(withTitles: highlightrTextStorage.highlightr.supportedLanguages().sorted())
		languagePopup.selectItem(withTitle: defaultLanguage)

		themePopup.removeAllItems()
		themePopup.addItems(withTitles: highlightrTextStorage.highlightr.availableThemes().sorted())
		themePopup.selectItem(withTitle: defaultTheme)

		updateTextViewColors()
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
		highlightrTextStorage.language = sender.titleOfSelectedItem ?? defaultLanguage
	}

	@IBAction func themePopupAction(_ sender: NSPopUpButtonCell) {
		highlightrTextStorage.highlightr.setTheme(to: sender.titleOfSelectedItem ?? defaultTheme)
		highlightrTextStorage.highlightr.theme.codeFont = NSFont(name: defaultFont, size: defaultFontSize)
		updateTextViewColors()
	}

	func updateTextViewColors() {
		textView.backgroundColor = highlightrTextStorage.highlightr.theme.themeBackgroundColor
		textView.insertionPointColor = invertColor(textView.backgroundColor)
	}

	func invertColor(_ color: NSColor) -> NSColor {
		var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0
		// FIXME: Fix/convert colorspace (not valid for the NSColor Generic Gray Gamma 2.2)
		color.getRed(&r, green: &g, blue: &b, alpha: nil)
		return NSColor(red:1.0-r, green: 1.0-g, blue: 1.0-b, alpha: 1)
	}

	// MARK: - Accessor Helpers

	weak var windowController: WindowController? {
		return view.window?.windowController as? WindowController
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

}
