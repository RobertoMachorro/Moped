//
//  PreferencesViewController.swift
//
//  Moped - A general purpose text editor, small and light.
//  Copyright © 2019-2022 Roberto Machorro. All rights reserved.
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
	@IBOutlet var languages: NSPopUpButton!
	@IBOutlet var themes: NSPopUpButton!
	@IBOutlet var fonts: NSPopUpButton!
	@IBOutlet var fontSizes: NSPopUpButton!
	@IBOutlet var wrapping: NSPopUpButton!

	@objc let userPreferences = Preferences.userShared

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Preferences"

		let highlightrTextStorage = CodeAttributedString()

		languages.addItems(withTitles: highlightrTextStorage.highlightr.supportedLanguages().sorted())
		themes.addItems(withTitles: highlightrTextStorage.highlightr.availableThemes().sorted())

		let systemMonospacedFonts = NSFontManager.shared.availableFontNames(with: .fixedPitchFontMask)
		let fallbackMonospacedFonts = ["Andale Mono", "Courier", "Courier New", "Menlo", "Monaco"]
		let availableFontSizes = (9...24).reduce(into: []) { $0.append(String($1)) }

		fonts.addItems(withTitles: systemMonospacedFonts ?? fallbackMonospacedFonts)
		fontSizes.addItems(withTitles: availableFontSizes)
		wrapping.addItems(withTitles: ["Yes", "No"])
	}

	override func viewDidAppear() {
		super.viewDidAppear()
		view.window?.styleMask.remove(.resizable)

		languages.selectItem(withTitle: userPreferences.language)
		themes.selectItem(withTitle: userPreferences.theme)
		fonts.selectItem(withTitle: userPreferences.font)
		fontSizes.selectItem(withTitle: userPreferences.fontSize)
		wrapping.selectItem(withTitle: userPreferences.lineWrap)
	}
}
