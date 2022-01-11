//
//  AboutViewController.swift
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

class AboutViewController: NSViewController {
	@IBOutlet var versionLabel: NSTextField!

	override func viewDidLoad() {
		super.viewDidLoad()
		title = ""

		let versionNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
		let buildNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
		versionLabel.stringValue = "v\(versionNumber) (\(buildNumber))"
	}

	override func viewDidAppear() {
		super.viewDidAppear()
		view.window?.styleMask.remove(.resizable)
	}
}
