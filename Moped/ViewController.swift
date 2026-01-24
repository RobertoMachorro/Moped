//
//  ViewController.swift
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
	var lineNumberRuler: LineNumberRulerView?

	override func viewDidLoad() {
		super.viewDidLoad()

		textView.isAutomaticSpellingCorrectionEnabled = false
		textView.isAutomaticQuoteSubstitutionEnabled = false
		textView.isAutomaticDashSubstitutionEnabled = false

		statusLabel.stringValue = ""
		textView.usesFindBar = true
		textView.enclosingScrollView?.findBarPosition = .aboveContent

		if let storage = highlightrTextStorage {
			storage.addLayoutManager(textView.layoutManager!)

			languagePopup.removeAllItems()
			languagePopup.addItems(withTitles: storage.highlightr.supportedLanguages().sorted())
			languagePopup.selectItem(withTitle: userPreferences.language)
		} else {
			textView.font = NSFont(name: userPreferences.font, size: userPreferences.fontSizeFloat)
		}
		setLineWrap(to: userPreferences.doLineWrap)
		setTheme(to: userPreferences.theme, fontSize: userPreferences.fontSizeFloat)

		setupLineNumberRuler()
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

	// MARK: - IBActions - menus

	@IBAction func fontSizeIncreaseMenuItemSelected(_ sender: Any) {
		fontSizeIncrease()
	}

	@IBAction func fontSizeDecreaseMenuItemSelected(_ sender: Any) {
		fontSizeDecrease()
	}

	@IBAction func fontSizeResetMenuItemSelected(_ sender: Any) {
		fontSizeReset()
	}

	// MARK: - Language / Popup Theme Changes

	@IBAction func languagePopupAction(_ sender: NSPopUpButtonCell) {
		if let storage = highlightrTextStorage {
			storage.language = sender.titleOfSelectedItem ?? userPreferences.language
		}
	}
}

// MARK: - Accessor Helpers
extension ViewController {
	weak var windowController: WindowController? {
		view.window?.windowController as? WindowController
	}

	weak var document: Document? {
		if let window = windowController, let doc = window.document as? Document {
			return doc
		}
		return nil
	}
}

// MARK: - NSTextViewDelegate
extension ViewController {
	func textDidBeginEditing(_ notification: Notification) {
		// PENDING This call is causing a post-save refresh
		// document?.objectDidBeginEditing(self)
	}

	func textDidEndEditing(_ notification: Notification) {
		// document?.objectDidEndEditing(self)
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

// MARK: - Preferences
extension ViewController {
	func setupLineNumberRuler() {
		guard let scrollView = textView.enclosingScrollView else {
			return
		}

		// Create the ruler view
		lineNumberRuler = LineNumberRulerView(textView: textView)
		guard let ruler = lineNumberRuler else { return }

		scrollView.hasVerticalRuler = true
		scrollView.rulersVisible = true
		scrollView.verticalRulerView = ruler

		// Update ruler font to match editor
		updateLineNumberFont()
	}

	func updateLineNumberFont() {
		guard let ruler = lineNumberRuler else { return }

		if let storage = highlightrTextStorage {
			ruler.font = NSFont.userFixedPitchFont(
				ofSize: storage.highlightr.theme.codeFont.pointSize * 0.9
			) ?? NSFont.systemFont(ofSize: storage.highlightr.theme.codeFont.pointSize * 0.9)
		} else {
			ruler.font = NSFont.userFixedPitchFont(
				ofSize: userPreferences.fontSizeFloat * 0.9
			) ?? NSFont.systemFont(ofSize: userPreferences.fontSizeFloat * 0.9)
		}
	}

	func setupPreferencesObserver() {
		let notificationName = Notification.Name(rawValue: "PreferencesChanged")
		NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
			self.setLineWrap(to: self.userPreferences.doLineWrap)
			self.setTheme(to: self.userPreferences.theme, fontSize: self.userPreferences.fontSizeFloat)
			// TODO: Check for self referencing ARC leak
		}
	}

	func setLineWrap(to wrapping: Bool) {
		if wrapping {
			textView.enclosingScrollView?.hasHorizontalScroller = false
			textView.isHorizontallyResizable = false
			// textView.autoresizingMask = [.width, .height]
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

// MARK: - Themeing
extension ViewController {
	func setTheme(to theme: String, fontSize: CGFloat) {
		if let storage = highlightrTextStorage {
			storage.highlightr.setTheme(to: theme)
			storage.highlightr.theme.codeFont = NSFont(name: userPreferences.font, size: fontSize)
			textView.backgroundColor = storage.highlightr.theme.themeBackgroundColor
			textView.insertionPointColor = caretColor(using: textView.backgroundColor)
			updateLineNumberFont()
		}
	}

	func caretColor(using color: NSColor) -> NSColor {
		// swiftlint:disable:next identifier_name
		var r: CGFloat = 1.0, g: CGFloat = 1.0, b: CGFloat = 1.0
		if color.colorSpace == NSColorSpace.sRGB {
			color.getRed(&r, green: &g, blue: &b, alpha: nil)
		}
		return NSColor(red: 1.0-r, green: 1.0-g, blue: 1.0-b, alpha: 1)
	}

	func fontSizeIncrease() {
		if let storage = highlightrTextStorage {
			let newFontSize = storage.highlightr.theme.codeFont.pointSize + 1.0
			setTheme(to: userPreferences.theme, fontSize: newFontSize)
		}
	}

	func fontSizeDecrease() {
		if let storage = highlightrTextStorage {
			let newFontSize = storage.highlightr.theme.codeFont.pointSize - 1.0
			if newFontSize > 2 {
				setTheme(to: userPreferences.theme, fontSize: newFontSize)
			} else {
				NSSound.beep()
			}
		}
	}

	func fontSizeReset() {
		setTheme(to: userPreferences.theme, fontSize: userPreferences.fontSizeFloat)
	}
}

