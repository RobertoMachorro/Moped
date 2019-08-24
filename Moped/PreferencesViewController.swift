//
//  PreferencesViewController.swift
//
//  Moped - A general purpose text editor, small and light.
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

class PreferencesViewController: NSViewController {

	@IBOutlet weak var languages: NSPopUpButton!
	@IBOutlet weak var themes: NSPopUpButton!
	@IBOutlet weak var fonts: NSPopUpButton!
	@IBOutlet weak var fontSizes: NSPopUpButton!

	@objc let userPreferences = Preferences.userShared

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Preferences"

		let highlightrTextStorage = CodeAttributedString()

		languages.addItems(withTitles: highlightrTextStorage.highlightr.supportedLanguages().sorted())
		themes.addItems(withTitles: highlightrTextStorage.highlightr.availableThemes().sorted())
		// FIXME: Pull this from the Font API - get all monospaced fonts
		fonts.addItems(withTitles: ["Andale Mono", "Courier", "Courier New", "Menlo", "Monaco"])
		fontSizes.addItems(withTitles: ["10", "12", "13", "14", "15"])
	}

	override func viewDidAppear() {
		super.viewDidAppear()
		view.window?.styleMask.remove(.resizable)

		languages.selectItem(withTitle: userPreferences.language)
		themes.selectItem(withTitle: userPreferences.theme)
		fonts.selectItem(withTitle: userPreferences.font)
		fontSizes.selectItem(withTitle: userPreferences.fontSize)
	}

}
