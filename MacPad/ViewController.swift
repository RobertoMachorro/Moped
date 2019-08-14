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

	@IBOutlet var textView: NSTextView!

	let highlightrTextStorage = CodeAttributedString()

	override func viewDidLoad() {
		super.viewDidLoad()

		textView.isAutomaticQuoteSubstitutionEnabled = false
		highlightrTextStorage.addLayoutManager(textView.layoutManager!)

		highlightrTextStorage.language = "Swift"
		highlightrTextStorage.highlightr.setTheme(to: "Docco")
		highlightrTextStorage.highlightr.theme.codeFont = NSFont(name: "Menlo", size: 12)
		textView.backgroundColor = (highlightrTextStorage.highlightr.theme.themeBackgroundColor)!
		textView.insertionPointColor = NSColor.white
	}

	override var representedObject: Any? {
		didSet {
			// Pass down ContentModel to all of the child view controllers
			for child in children {
				child.representedObject = representedObject
			}
		}
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
